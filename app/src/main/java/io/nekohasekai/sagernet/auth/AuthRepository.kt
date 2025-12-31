package io.nekohasekai.sagernet.auth

import android.content.Context
import android.content.SharedPreferences
import android.util.Log
import com.google.gson.Gson
import com.google.gson.JsonObject
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import java.util.concurrent.TimeUnit

/**
 * 认证仓库 - 处理所有认证相关的 API 调用
 */
class AuthRepository(private val context: Context) {
    
    private val TAG = "AuthRepository"
    private val BASE_URL = "https://dy.moneyfly.top"
    private val API_BASE = "$BASE_URL/api/v1"
    private val gson = Gson()
    
    private val prefs: SharedPreferences = context.getSharedPreferences(
        "auth_prefs",
        Context.MODE_PRIVATE
    )
    
    private val client = OkHttpClient.Builder()
        .connectTimeout(30, TimeUnit.SECONDS)
        .readTimeout(30, TimeUnit.SECONDS)
        .writeTimeout(30, TimeUnit.SECONDS)
        .build()
    
    /**
     * 登录
     */
    suspend fun login(email: String, password: String): Result<LoginResponse> = withContext(Dispatchers.IO) {
        try {
            val json = JsonObject().apply {
                addProperty("email", email)
                addProperty("password", password)
            }
            
            val request = Request.Builder()
                .url("$API_BASE/auth/login")
                .post(json.toString().toRequestBody("application/json".toMediaType()))
                .build()
            
            val response = client.newCall(request).execute()
            val body = response.body?.string()
            
            Log.d(TAG, "登录请求: ${request.url}")
            Log.d(TAG, "登录响应码: ${response.code}")
            Log.d(TAG, "登录响应体: $body")
            
            if (response.isSuccessful && body != null) {
                val apiResponse = gson.fromJson(body, JsonObject::class.java)
                
                if (apiResponse.get("success")?.asBoolean == true) {
                    val data = apiResponse.getAsJsonObject("data")
                    val user = data.getAsJsonObject("user")
                    val loginResponse = LoginResponse(
                        token = data.get("access_token").asString,
                        email = user.get("email").asString,
                        username = user.get("username")?.asString ?: user.get("email").asString
                    )
                    
                    // 保存 token
                    saveToken(loginResponse.token)
                    saveEmail(loginResponse.email)
                    saveUsername(loginResponse.username)
                    
                    Log.d(TAG, "登录成功: ${loginResponse.email}")
                    Result.success(loginResponse)
                } else {
                    val message = apiResponse.get("message")?.asString ?: "登录失败"
                    Log.e(TAG, "登录失败: $message")
                    Result.failure(Exception(message))
                }
            } else {
                val errorMessage = try {
                    if (body != null) {
                        val apiResponse = gson.fromJson(body, JsonObject::class.java)
                        apiResponse.get("message")?.asString ?: "登录失败，请检查网络连接"
                    } else {
                        "登录失败，请检查网络连接"
                    }
                } catch (e: Exception) {
                    "登录失败，请检查网络连接"
                }
                Log.e(TAG, "登录请求失败: ${response.code}, 错误: $errorMessage")
                Result.failure(Exception(errorMessage))
            }
        } catch (e: Exception) {
            Log.e(TAG, "登录异常: ${e.message}", e)
            val errorMsg = when {
                e.message?.contains("timeout") == true -> "连接超时，请检查网络连接"
                e.message?.contains("SSL") == true -> "SSL 连接错误，请检查网络设置"
                e.message?.contains("failed to connect") == true -> "无法连接到服务器，请检查网络"
                else -> "登录失败: ${e.message ?: "未知错误"}"
            }
            Result.failure(Exception(errorMsg))
        }
    }
    
    /**
     * 注册
     */
    suspend fun register(
        username: String,
        email: String,
        password: String,
        verificationCode: String? = null,
        inviteCode: String? = null
    ): Result<String> = withContext(Dispatchers.IO) {
        try {
            val json = JsonObject().apply {
                addProperty("username", username)
                addProperty("email", email)
                addProperty("password", password)
                verificationCode?.let { addProperty("verification_code", it) }
                inviteCode?.let { addProperty("invite_code", it) }
            }
            
            val request = Request.Builder()
                .url("$API_BASE/auth/register")
                .post(json.toString().toRequestBody("application/json".toMediaType()))
                .build()
            
            val response = client.newCall(request).execute()
            val body = response.body?.string()
            
            if (response.isSuccessful && body != null) {
                val apiResponse = gson.fromJson(body, JsonObject::class.java)
                
                if (apiResponse.get("success")?.asBoolean == true) {
                    val message = apiResponse.get("message")?.asString ?: "注册成功"
                    Log.d(TAG, "注册成功: $email")
                    Result.success(message)
                } else {
                    val message = apiResponse.get("message")?.asString ?: "注册失败"
                    Log.e(TAG, "注册失败: $message")
                    Result.failure(Exception(message))
                }
            } else {
                Log.e(TAG, "注册请求失败: ${response.code}")
                Result.failure(Exception("注册失败，请检查网络连接"))
            }
        } catch (e: Exception) {
            Log.e(TAG, "注册异常", e)
            Result.failure(e)
        }
    }
    
    /**
     * 发送验证码（用于注册）
     */
    suspend fun sendVerificationCode(email: String, type: String = "register"): Result<String> = withContext(Dispatchers.IO) {
        try {
            val json = JsonObject().apply {
                addProperty("email", email)
                addProperty("type", "email") // 后端要求 type 为 "email"
            }
            
            val request = Request.Builder()
                .url("$API_BASE/auth/verification/send")
                .post(json.toString().toRequestBody("application/json".toMediaType()))
                .build()
            
            val response = client.newCall(request).execute()
            val body = response.body?.string()
            
            Log.d(TAG, "验证码请求: ${request.url}")
            Log.d(TAG, "验证码响应码: ${response.code}")
            Log.d(TAG, "验证码响应体: $body")
            
            if (response.isSuccessful && body != null) {
                val apiResponse = gson.fromJson(body, JsonObject::class.java)
                
                if (apiResponse.get("success")?.asBoolean == true) {
                    val message = apiResponse.get("message")?.asString ?: "验证码已发送"
                    Log.d(TAG, "验证码发送成功: $email")
                    Result.success(message)
                } else {
                    val message = apiResponse.get("message")?.asString ?: "发送失败"
                    Log.e(TAG, "验证码发送失败: $message")
                    Result.failure(Exception(message))
                }
            } else {
                val errorMessage = try {
                    if (body != null) {
                        val apiResponse = gson.fromJson(body, JsonObject::class.java)
                        apiResponse.get("message")?.asString ?: "发送失败，请检查网络连接"
                    } else {
                        "发送失败，请检查网络连接"
                    }
                } catch (e: Exception) {
                    "发送失败，请检查网络连接"
                }
                Log.e(TAG, "验证码请求失败: ${response.code}, 错误: $errorMessage")
                Result.failure(Exception(errorMessage))
            }
        } catch (e: Exception) {
            Log.e(TAG, "验证码发送异常: ${e.message}", e)
            val errorMsg = when {
                e.message?.contains("timeout") == true -> "连接超时，请检查网络连接"
                e.message?.contains("SSL") == true -> "SSL 连接错误，请检查网络设置"
                else -> "发送失败: ${e.message ?: "未知错误"}"
            }
            Result.failure(Exception(errorMsg))
        }
    }
    
    /**
     * 忘记密码（发送重置密码验证码）
     */
    suspend fun forgotPassword(email: String): Result<String> = withContext(Dispatchers.IO) {
        try {
            val json = JsonObject().apply {
                addProperty("email", email)
            }
            
            val request = Request.Builder()
                .url("$API_BASE/auth/forgot-password")
                .post(json.toString().toRequestBody("application/json".toMediaType()))
                .build()
            
            val response = client.newCall(request).execute()
            val body = response.body?.string()
            
            Log.d(TAG, "忘记密码请求: ${request.url}")
            Log.d(TAG, "忘记密码响应码: ${response.code}")
            Log.d(TAG, "忘记密码响应体: $body")
            
            if (response.isSuccessful && body != null) {
                val apiResponse = gson.fromJson(body, JsonObject::class.java)
                
                if (apiResponse.get("success")?.asBoolean == true) {
                    val message = apiResponse.get("message")?.asString ?: "验证码已发送"
                    Log.d(TAG, "忘记密码验证码发送成功: $email")
                    Result.success(message)
                } else {
                    val message = apiResponse.get("message")?.asString ?: "发送失败"
                    Log.e(TAG, "忘记密码验证码发送失败: $message")
                    Result.failure(Exception(message))
                }
            } else {
                val errorMessage = try {
                    if (body != null) {
                        val apiResponse = gson.fromJson(body, JsonObject::class.java)
                        apiResponse.get("message")?.asString ?: "发送失败，请检查网络连接"
                    } else {
                        "发送失败，请检查网络连接"
                    }
                } catch (e: Exception) {
                    "发送失败，请检查网络连接"
                }
                Log.e(TAG, "忘记密码请求失败: ${response.code}, 错误: $errorMessage")
                Result.failure(Exception(errorMessage))
            }
        } catch (e: Exception) {
            Log.e(TAG, "忘记密码异常: ${e.message}", e)
            val errorMsg = when {
                e.message?.contains("timeout") == true -> "连接超时，请检查网络连接"
                e.message?.contains("SSL") == true -> "SSL 连接错误，请检查网络设置"
                else -> "发送失败: ${e.message ?: "未知错误"}"
            }
            Result.failure(Exception(errorMsg))
        }
    }
    
    /**
     * 重置密码
     */
    suspend fun resetPassword(email: String, code: String, newPassword: String): Result<String> = withContext(Dispatchers.IO) {
        try {
            val json = JsonObject().apply {
                addProperty("email", email)
                addProperty("verification_code", code)
                addProperty("new_password", newPassword)
            }
            
            val request = Request.Builder()
                .url("$API_BASE/auth/reset-password")
                .post(json.toString().toRequestBody("application/json".toMediaType()))
                .build()
            
            val response = client.newCall(request).execute()
            val body = response.body?.string()
            
            if (response.isSuccessful && body != null) {
                val apiResponse = gson.fromJson(body, JsonObject::class.java)
                
                if (apiResponse.get("success")?.asBoolean == true) {
                    val message = apiResponse.get("message")?.asString ?: "密码重置成功"
                    Log.d(TAG, "密码重置成功: $email")
                    Result.success(message)
                } else {
                    val message = apiResponse.get("message")?.asString ?: "重置失败"
                    Log.e(TAG, "密码重置失败: $message")
                    Result.failure(Exception(message))
                }
            } else {
                Log.e(TAG, "重置密码请求失败: ${response.code}")
                Result.failure(Exception("重置失败，请检查网络连接"))
            }
        } catch (e: Exception) {
            Log.e(TAG, "重置密码异常", e)
            Result.failure(e)
        }
    }
    
    /**
     * 刷新 Token
     */
    suspend fun refreshToken(): Result<String> = withContext(Dispatchers.IO) {
        try {
            val currentToken = getToken()
            if (currentToken == null) {
                return@withContext Result.failure(Exception("无 Token"))
            }
            
            val request = Request.Builder()
                .url("$API_BASE/auth/refresh")
                .header("Authorization", "Bearer $currentToken")
                .post("".toRequestBody())
                .build()
            
            val response = client.newCall(request).execute()
            val body = response.body?.string()
            
            if (response.isSuccessful && body != null) {
                val apiResponse = gson.fromJson(body, JsonObject::class.java)
                
                if (apiResponse.get("success")?.asBoolean == true) {
                    val data = apiResponse.getAsJsonObject("data")
                    val newToken = data.get("token").asString
                    
                    // 保存新 Token
                    saveToken(newToken)
                    
                    Log.d(TAG, "Token 刷新成功")
                    Result.success(newToken)
                } else {
                    val message = apiResponse.get("message")?.asString ?: "Token 刷新失败"
                    Log.e(TAG, "Token 刷新失败: $message")
                    Result.failure(Exception(message))
                }
            } else if (response.code == 401) {
                // Token 已完全失效，需要重新登录
                Log.e(TAG, "Token 已失效，需要重新登录")
                logout()
                Result.failure(Exception("登录已过期，请重新登录"))
            } else {
                Log.e(TAG, "Token 刷新请求失败: ${response.code}")
                Result.failure(Exception("Token 刷新失败"))
            }
        } catch (e: Exception) {
            Log.e(TAG, "Token 刷新异常", e)
            Result.failure(e)
        }
    }
    
    /**
     * 自动刷新 Token（带重试机制）
     * 在 API 调用失败时自动调用
     */
    suspend fun autoRefreshTokenIfNeeded(errorCode: Int): Boolean {
        if (errorCode == 401) {
            // Token 可能过期，尝试刷新
            val result = refreshToken()
            return result.isSuccess
        }
        return false
    }
    
    /**
     * 获取用户订阅
     */
    suspend fun getUserSubscription(): Result<UserSubscription> = withContext(Dispatchers.IO) {
        try {
            val token = getToken()
            if (token == null) {
                Log.e(TAG, "未登录，无法获取订阅")
                return@withContext Result.failure(Exception("未登录"))
            }
            
            val request = Request.Builder()
                .url("$API_BASE/subscriptions/user-subscription")
                .header("Authorization", "Bearer $token")
                .get()
                .build()
            
            val response = client.newCall(request).execute()
            val body = response.body?.string()
            
            if (response.isSuccessful && body != null) {
                val apiResponse = gson.fromJson(body, JsonObject::class.java)
                
                if (apiResponse.get("success")?.asBoolean == true) {
                    val data = apiResponse.getAsJsonObject("data")
                    val subscription = UserSubscription(
                        universalUrl = data.get("universal_url")?.asString ?: "",
                        subscriptionUrl = data.get("subscription_url")?.asString,
                        expireTime = data.get("expire_time")?.asString ?: "未设置",
                        deviceLimit = data.get("device_limit")?.asInt ?: 0,
                        currentDevices = data.get("current_devices")?.asInt ?: 0,
                        uploadTraffic = data.get("upload_traffic")?.asLong ?: 0,
                        downloadTraffic = data.get("download_traffic")?.asLong ?: 0,
                        totalTraffic = data.get("total_traffic")?.asLong ?: 0
                    )
                    
                    Log.d(TAG, "获取订阅成功: ${subscription.expireTime}")
                    Result.success(subscription)
                } else {
                    val message = apiResponse.get("message")?.asString ?: "获取订阅失败"
                    Log.e(TAG, "获取订阅失败: $message")
                    Result.failure(Exception(message))
                }
            } else {
                Log.e(TAG, "订阅请求失败: ${response.code}")
                Result.failure(Exception("获取订阅失败"))
            }
        } catch (e: Exception) {
            Log.e(TAG, "获取订阅异常", e)
            Result.failure(e)
        }
    }
    
    // Token 管理
    fun saveToken(token: String) {
        prefs.edit().putString("auth_token", token).apply()
    }
    
    fun getToken(): String? {
        return prefs.getString("auth_token", null)
    }
    
    fun clearToken() {
        prefs.edit().remove("auth_token").apply()
    }
    
    fun saveEmail(email: String) {
        prefs.edit().putString("user_email", email).apply()
    }
    
    fun getEmail(): String? {
        return prefs.getString("user_email", null)
    }
    
    fun saveUsername(username: String) {
        prefs.edit().putString("user_username", username).apply()
    }
    
    fun getUsername(): String? {
        return prefs.getString("user_username", null)
    }
    
    fun isAuthenticated(): Boolean {
        return getToken() != null
    }
    
    fun logout() {
        prefs.edit().clear().apply()
        Log.d(TAG, "用户已退出登录")
    }
    
    fun getAuthState(): AuthState {
        return AuthState(
            isAuthenticated = isAuthenticated(),
            token = getToken(),
            email = getEmail(),
            username = getUsername()
        )
    }
}

