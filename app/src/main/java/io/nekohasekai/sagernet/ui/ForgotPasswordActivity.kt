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

class ForgotPasswordActivity : AppCompatActivity() {
    
    private lateinit var authRepository: AuthRepository
    
    private lateinit var emailLayout: TextInputLayout
    private lateinit var emailInput: TextInputEditText
    private lateinit var codeLayout: TextInputLayout
    private lateinit var codeInput: TextInputEditText
    private lateinit var newPasswordLayout: TextInputLayout
    private lateinit var newPasswordInput: TextInputEditText
    private lateinit var confirmPasswordLayout: TextInputLayout
    private lateinit var confirmPasswordInput: TextInputEditText
    private lateinit var sendCodeButton: MaterialButton
    private lateinit var resetButton: MaterialButton
    private lateinit var progressIndicator: CircularProgressIndicator
    
    private var countDownTimer: CountDownTimer? = null
    private var canSendCode = true
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_forgot_password)
        
        authRepository = AuthRepository(this)
        
        // 添加返回按钮
        supportActionBar?.setDisplayHomeAsUpEnabled(true)
        
        initViews()
        setupListeners()
    }
    
    private fun initViews() {
        emailLayout = findViewById(R.id.email_layout)
        emailInput = findViewById(R.id.email_input)
        codeLayout = findViewById(R.id.code_layout)
        codeInput = findViewById(R.id.code_input)
        newPasswordLayout = findViewById(R.id.new_password_layout)
        newPasswordInput = findViewById(R.id.new_password_input)
        confirmPasswordLayout = findViewById(R.id.confirm_password_layout)
        confirmPasswordInput = findViewById(R.id.confirm_password_input)
        sendCodeButton = findViewById(R.id.send_code_button)
        resetButton = findViewById(R.id.reset_button)
        progressIndicator = findViewById(R.id.progress_indicator)
    }
    
    private fun setupListeners() {
        sendCodeButton.setOnClickListener {
            val email = emailInput.text?.toString()?.trim()
            if (validateEmail(email)) {
                sendVerificationCode(email!!)
            }
        }
        
        resetButton.setOnClickListener {
            val email = emailInput.text?.toString()?.trim()
            val code = codeInput.text?.toString()?.trim()
            val newPassword = newPasswordInput.text?.toString()
            val confirmPassword = confirmPasswordInput.text?.toString()
            
            if (validateInput(email, code, newPassword, confirmPassword)) {
                performReset(email!!, code!!, newPassword!!)
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
    
    private fun validateInput(
        email: String?,
        code: String?,
        newPassword: String?,
        confirmPassword: String?
    ): Boolean {
        var isValid = true
        
        if (!validateEmail(email)) {
            isValid = false
        }
        
        if (code.isNullOrEmpty()) {
            codeLayout.error = "请输入验证码"
            isValid = false
        } else {
            codeLayout.error = null
        }
        
        if (newPassword.isNullOrEmpty()) {
            newPasswordLayout.error = "请输入新密码"
            isValid = false
        } else if (newPassword.length < 8) {
            newPasswordLayout.error = "密码至少8位"
            isValid = false
        } else {
            newPasswordLayout.error = null
        }
        
        if (confirmPassword.isNullOrEmpty()) {
            confirmPasswordLayout.error = "请确认密码"
            isValid = false
        } else if (confirmPassword != newPassword) {
            confirmPasswordLayout.error = "两次密码不一致"
            isValid = false
        } else {
            confirmPasswordLayout.error = null
        }
        
        return isValid
    }
    
    private fun sendVerificationCode(email: String) {
        if (!canSendCode) return
        
        sendCodeButton.isEnabled = false
        
        lifecycleScope.launch {
            val result = authRepository.forgotPassword(email)
            
            result.onSuccess { message ->
                Toast.makeText(this@ForgotPasswordActivity, message, Toast.LENGTH_SHORT).show()
                startCountDown()
            }
            
            result.onFailure { error ->
                Toast.makeText(
                    this@ForgotPasswordActivity,
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
    
    private fun performReset(email: String, code: String, newPassword: String) {
        setLoading(true)
        
        lifecycleScope.launch {
            val result = authRepository.resetPassword(email, code, newPassword)
            
            result.onSuccess { message ->
                Toast.makeText(
                    this@ForgotPasswordActivity,
                    message,
                    Toast.LENGTH_LONG
                ).show()
                setLoading(false)
                finish() // 返回登录页
            }
            
            result.onFailure { error ->
                setLoading(false)
                Toast.makeText(
                    this@ForgotPasswordActivity,
                    "重置失败: ${error.message}",
                    Toast.LENGTH_LONG
                ).show()
            }
        }
    }
    
    private fun setLoading(loading: Boolean) {
        resetButton.isEnabled = !loading
        sendCodeButton.isEnabled = !loading && canSendCode
        emailInput.isEnabled = !loading
        codeInput.isEnabled = !loading
        newPasswordInput.isEnabled = !loading
        confirmPasswordInput.isEnabled = !loading
        progressIndicator.visibility = if (loading) View.VISIBLE else View.GONE
    }
    
    override fun onDestroy() {
        super.onDestroy()
        countDownTimer?.cancel()
    }
    
    override fun onSupportNavigateUp(): Boolean {
        finish()
        return true
    }
}

