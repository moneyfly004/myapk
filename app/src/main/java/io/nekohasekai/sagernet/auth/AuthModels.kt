package io.nekohasekai.sagernet.auth

import kotlinx.coroutines.flow.Flow

/**
 * 认证状态
 */
data class AuthState(
    val isAuthenticated: Boolean = false,
    val token: String? = null,
    val email: String? = null,
    val username: String? = null
)

/**
 * 登录请求
 */
data class LoginRequest(
    val email: String,
    val password: String
)

/**
 * 注册请求
 */
data class RegisterRequest(
    val username: String,
    val email: String,
    val password: String,
    val verificationCode: String? = null,
    val inviteCode: String? = null
)

/**
 * 忘记密码请求
 */
data class ForgotPasswordRequest(
    val email: String,
    val verificationCode: String,
    val newPassword: String
)

/**
 * 验证码请求
 */
data class VerificationCodeRequest(
    val email: String,
    val type: String = "register" // register, reset_password
)

/**
 * 登录响应
 */
data class LoginResponse(
    val token: String,
    val email: String,
    val username: String
)

/**
 * 用户订阅信息
 */
data class UserSubscription(
    val universalUrl: String,
    val subscriptionUrl: String? = null,
    val expireTime: String,
    val deviceLimit: Int = 0,
    val currentDevices: Int = 0,
    val uploadTraffic: Long = 0,
    val downloadTraffic: Long = 0,
    val totalTraffic: Long = 0
)

/**
 * API 响应包装
 */
data class ApiResponse<T>(
    val success: Boolean,
    val message: String,
    val data: T? = null
)

