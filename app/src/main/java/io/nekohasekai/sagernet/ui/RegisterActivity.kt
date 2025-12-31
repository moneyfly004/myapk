package io.nekohasekai.sagernet.ui

import android.os.Bundle
import android.os.CountDownTimer
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

class RegisterActivity : AppCompatActivity() {
    
    private lateinit var authRepository: AuthRepository
    
    private lateinit var usernameLayout: TextInputLayout
    private lateinit var usernameInput: TextInputEditText
    private lateinit var emailLayout: TextInputLayout
    private lateinit var emailInput: TextInputEditText
    private lateinit var passwordLayout: TextInputLayout
    private lateinit var passwordInput: TextInputEditText
    private lateinit var codeLayout: TextInputLayout
    private lateinit var codeInput: TextInputEditText
    private lateinit var sendCodeButton: MaterialButton
    private lateinit var registerButton: MaterialButton
    private lateinit var progressIndicator: CircularProgressIndicator
    
    private var countDownTimer: CountDownTimer? = null
    private var canSendCode = true
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_register)
        
        authRepository = AuthRepository(this)
        
        initViews()
        setupListeners()
    }
    
    private fun initViews() {
        usernameLayout = findViewById(R.id.username_layout)
        usernameInput = findViewById(R.id.username_input)
        emailLayout = findViewById(R.id.email_layout)
        emailInput = findViewById(R.id.email_input)
        passwordLayout = findViewById(R.id.password_layout)
        passwordInput = findViewById(R.id.password_input)
        codeLayout = findViewById(R.id.code_layout)
        codeInput = findViewById(R.id.code_input)
        sendCodeButton = findViewById(R.id.send_code_button)
        registerButton = findViewById(R.id.register_button)
        progressIndicator = findViewById(R.id.progress_indicator)
    }
    
    private fun setupListeners() {
        sendCodeButton.setOnClickListener {
            val email = emailInput.text?.toString()?.trim()
            if (validateEmail(email)) {
                sendVerificationCode(email!!)
            }
        }
        
        registerButton.setOnClickListener {
            val username = usernameInput.text?.toString()?.trim()
            val email = emailInput.text?.toString()?.trim()
            val password = passwordInput.text?.toString()
            val code = codeInput.text?.toString()?.trim()
            
            if (validateInput(username, email, password)) {
                performRegister(username!!, email!!, password!!, code)
            }
        }
    }
    
    private fun validateEmail(email: String?): Boolean {
        if (email.isNullOrEmpty()) {
            emailLayout.error = "请输入邮箱"
            return false
        } else if (!android.util.Patterns.EMAIL_ADDRESS.matcher(email).matches()) {
            emailLayout.error = "邮箱格式不正确"
            return false
        } else {
            emailLayout.error = null
            return true
        }
    }
    
    private fun validateInput(username: String?, email: String?, password: String?): Boolean {
        var isValid = true
        
        if (username.isNullOrEmpty()) {
            usernameLayout.error = "请输入用户名"
            isValid = false
        } else {
            usernameLayout.error = null
        }
        
        if (!validateEmail(email)) {
            isValid = false
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
    
    private fun sendVerificationCode(email: String) {
        if (!canSendCode) return
        
        sendCodeButton.isEnabled = false
        
        lifecycleScope.launch {
            val result = authRepository.sendVerificationCode(email, "register")
            
            result.onSuccess { message ->
                Toast.makeText(this@RegisterActivity, message, Toast.LENGTH_SHORT).show()
                startCountDown()
            }
            
            result.onFailure { error ->
                Toast.makeText(
                    this@RegisterActivity,
                    "发送失败: ${error.message}",
                    Toast.LENGTH_LONG
                ).show()
                sendCodeButton.isEnabled = true
            }
        }
    }
    
    private fun startCountDown() {
        canSendCode = false
        var countdown = 60
        
        countDownTimer = object : CountDownTimer(60000, 1000) {
            override fun onTick(millisUntilFinished: Long) {
                countdown = (millisUntilFinished / 1000).toInt()
                sendCodeButton.text = "${countdown}秒后重试"
            }
            
            override fun onFinish() {
                canSendCode = true
                sendCodeButton.isEnabled = true
                sendCodeButton.text = "发送验证码"
            }
        }.start()
    }
    
    private fun performRegister(username: String, email: String, password: String, code: String?) {
        setLoading(true)
        
        lifecycleScope.launch {
            val result = authRepository.register(username, email, password, code)
            
            result.onSuccess { message ->
                Toast.makeText(this@RegisterActivity, message, Toast.LENGTH_LONG).show()
                setLoading(false)
                finish() // 返回登录页
            }
            
            result.onFailure { error ->
                setLoading(false)
                Toast.makeText(
                    this@RegisterActivity,
                    "注册失败: ${error.message}",
                    Toast.LENGTH_LONG
                ).show()
            }
        }
    }
    
    private fun setLoading(loading: Boolean) {
        registerButton.isEnabled = !loading
        sendCodeButton.isEnabled = !loading && canSendCode
        usernameInput.isEnabled = !loading
        emailInput.isEnabled = !loading
        passwordInput.isEnabled = !loading
        codeInput.isEnabled = !loading
        progressIndicator.visibility = if (loading) View.VISIBLE else View.GONE
    }
    
    override fun onDestroy() {
        super.onDestroy()
        countDownTimer?.cancel()
    }
}

