package io.nekohasekai.sagernet.ui

import android.content.Intent
import android.os.Bundle
import android.view.View
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import com.google.android.material.button.MaterialButton
import com.google.android.material.progressindicator.CircularProgressIndicator
import com.google.android.material.textfield.TextInputEditText
import com.google.android.material.textfield.TextInputLayout
import io.nekohasekai.sagernet.R
import io.nekohasekai.sagernet.auth.AuthRepository
import kotlinx.coroutines.launch

class LoginActivity : AppCompatActivity() {
    
    private lateinit var authRepository: AuthRepository
    
    private lateinit var emailLayout: TextInputLayout
    private lateinit var emailInput: TextInputEditText
    private lateinit var passwordLayout: TextInputLayout
    private lateinit var passwordInput: TextInputEditText
    private lateinit var loginButton: MaterialButton
    private lateinit var registerButton: MaterialButton
    private lateinit var forgotPasswordButton: MaterialButton
    private lateinit var progressIndicator: CircularProgressIndicator
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_login)
        
        authRepository = AuthRepository(this)
        
        // 检查是否已登录
        if (authRepository.isAuthenticated()) {
            navigateToMain()
            return
        }
        
        initViews()
        setupListeners()
    }
    
    private fun initViews() {
        emailLayout = findViewById(R.id.email_layout)
        emailInput = findViewById(R.id.email_input)
        passwordLayout = findViewById(R.id.password_layout)
        passwordInput = findViewById(R.id.password_input)
        loginButton = findViewById(R.id.login_button)
        registerButton = findViewById(R.id.register_button)
        forgotPasswordButton = findViewById(R.id.forgot_password_button)
        progressIndicator = findViewById(R.id.progress_indicator)
    }
    
    private fun setupListeners() {
        loginButton.setOnClickListener {
            val email = emailInput.text?.toString()?.trim()
            val password = passwordInput.text?.toString()
            
            if (validateInput(email, password)) {
                performLogin(email!!, password!!)
            }
        }
        
        registerButton.setOnClickListener {
            startActivity(Intent(this, RegisterActivity::class.java))
        }
        
        forgotPasswordButton.setOnClickListener {
            startActivity(Intent(this, ForgotPasswordActivity::class.java))
        }
    }
    
    private fun validateInput(email: String?, password: String?): Boolean {
        var isValid = true
        
        if (email.isNullOrEmpty()) {
            emailLayout.error = "请输入邮箱"
            isValid = false
        } else if (!android.util.Patterns.EMAIL_ADDRESS.matcher(email).matches()) {
            emailLayout.error = "邮箱格式不正确"
            isValid = false
        } else {
            emailLayout.error = null
        }
        
        if (password.isNullOrEmpty()) {
            passwordLayout.error = "请输入密码"
            isValid = false
        } else if (password.length < 8) {
            passwordLayout.error = "密码至少8位"
            isValid = false
        } else {
            passwordLayout.error = null
        }
        
        return isValid
    }
    
    private fun performLogin(email: String, password: String) {
        setLoading(true)
        
        lifecycleScope.launch {
            val result = authRepository.login(email, password)
            
            result.onSuccess { loginResponse ->
                Toast.makeText(this@LoginActivity, "登录成功！", Toast.LENGTH_SHORT).show()
                
                // 登录成功后自动获取订阅
                fetchSubscription()
            }
            
            result.onFailure { error ->
                setLoading(false)
                Toast.makeText(
                    this@LoginActivity,
                    "登录失败: ${error.message}",
                    Toast.LENGTH_LONG
                ).show()
            }
        }
    }
    
    private suspend fun fetchSubscription() {
        val result = authRepository.getUserSubscription()
        
        result.onSuccess { subscription ->
            if (subscription.universalUrl.isNotEmpty()) {
                // 保存订阅信息到 SharedPreferences
                val prefs = getSharedPreferences("subscription_prefs", MODE_PRIVATE)
                prefs.edit().apply {
                    putString("subscription_url", subscription.universalUrl)
                    putString("expire_time", subscription.expireTime)
                    putBoolean("has_subscription", true)
                    apply()
                }
                
                Toast.makeText(
                    this@LoginActivity,
                    "订阅已获取！到期: ${subscription.expireTime}",
                    Toast.LENGTH_LONG
                ).show()
            }
            
            setLoading(false)
            navigateToMain()
        }
        
        result.onFailure { error ->
            // 即使订阅获取失败，也允许进入主页
            Toast.makeText(
                this@LoginActivity,
                "提示: ${error.message}",
                Toast.LENGTH_SHORT
            ).show()
            
            setLoading(false)
            navigateToMain()
        }
    }
    
    private fun setLoading(loading: Boolean) {
        loginButton.isEnabled = !loading
        registerButton.isEnabled = !loading
        emailInput.isEnabled = !loading
        passwordInput.isEnabled = !loading
        progressIndicator.visibility = if (loading) View.VISIBLE else View.GONE
    }
    
    private fun navigateToMain() {
        val intent = Intent(this, MainActivity::class.java)
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        startActivity(intent)
        finish()
    }
}

