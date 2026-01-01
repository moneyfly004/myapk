package io.nekohasekai.sagernet.ui

import android.annotation.SuppressLint
import android.content.Intent
import android.graphics.Bitmap
import android.net.Uri
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.webkit.WebResourceRequest
import android.webkit.WebView
import android.webkit.WebViewClient
import android.widget.ImageView
import android.widget.TextView
import android.widget.Toast
import androidx.core.view.ViewCompat
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.google.android.material.button.MaterialButton
import com.google.android.material.card.MaterialCardView
import com.google.android.material.dialog.MaterialAlertDialogBuilder
import com.google.zxing.BarcodeFormat
import com.google.zxing.EncodeHintType
import com.google.zxing.MultiFormatWriter
import com.google.zxing.WriterException
import android.graphics.Color
import android.util.TypedValue
import androidx.core.content.ContextCompat
import java.nio.charset.StandardCharsets
import io.nekohasekai.sagernet.R
import io.nekohasekai.sagernet.auth.AuthRepository
import io.nekohasekai.sagernet.auth.Order
import io.nekohasekai.sagernet.auth.Package
import io.nekohasekai.sagernet.ktx.*
import io.nekohasekai.sagernet.widget.ListListener
import kotlinx.coroutines.*
import java.util.concurrent.TimeUnit
import androidx.lifecycle.lifecycleScope

class PackagePurchaseFragment : ToolbarFragment(R.layout.layout_package_purchase) {

    private lateinit var authRepository: AuthRepository
    private lateinit var packagesRecycler: RecyclerView
    private lateinit var emptyText: TextView
    private var packagesAdapter: PackagesAdapter? = null
    private var packagesList = mutableListOf<Package>()
    private var currentOrder: Order? = null
    private var paymentStatusCheckJob: Job? = null
    private val handler = Handler(Looper.getMainLooper())

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        authRepository = AuthRepository(requireContext())
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        ViewCompat.setOnApplyWindowInsetsListener(view, ListListener)
        toolbar.setTitle("套餐购买")

        packagesRecycler = view.findViewById(R.id.packages_recycler)
        emptyText = view.findViewById(R.id.empty_text)
        packagesRecycler.layoutManager = LinearLayoutManager(requireContext())
        packagesAdapter = PackagesAdapter()
        packagesRecycler.adapter = packagesAdapter

        loadPackages()
    }

    private fun loadPackages() {
        lifecycleScope.launch {
            try {
                val result = authRepository.getPackages()
                result.onSuccess { packages ->
                    packagesList.clear()
                    if (packages.isNotEmpty()) {
                        packagesList.addAll(packages)
                        packagesAdapter?.notifyDataSetChanged()
                        emptyText.visibility = View.GONE
                        packagesRecycler.visibility = View.VISIBLE
                    } else {
                        emptyText.visibility = View.VISIBLE
                        packagesRecycler.visibility = View.GONE
                    }
                }.onFailure { error ->
                    emptyText.visibility = View.VISIBLE
                    emptyText.text = "加载套餐失败: ${error.message}"
                    packagesRecycler.visibility = View.GONE
                    Toast.makeText(requireContext(), "加载套餐失败: ${error.message}", Toast.LENGTH_SHORT).show()
                }
            } catch (e: Exception) {
                Logs.e(e)
                Toast.makeText(requireContext(), "加载套餐失败: ${e.message}", Toast.LENGTH_SHORT).show()
            }
        }
    }

    private fun purchasePackage(pkg: Package) {
        if (!authRepository.isAuthenticated()) {
            Toast.makeText(requireContext(), "请先登录", Toast.LENGTH_SHORT).show()
            return
        }

        MaterialAlertDialogBuilder(requireContext())
            .setTitle("确认购买")
            .setMessage("套餐：${pkg.name}\n价格：¥${pkg.price}\n有效期：${pkg.durationDays}天\n设备限制：${pkg.deviceLimit}个")
            .setPositiveButton("确认购买") { _, _ ->
                createOrder(pkg)
            }
            .setNegativeButton("取消", null)
            .show()
    }

    private fun createOrder(pkg: Package) {
        lifecycleScope.launch {
            try {
                val result = authRepository.createOrder(
                    packageId = pkg.id,
                    paymentMethod = "alipay"
                )
                result.onSuccess { order ->
                    currentOrder = order
                    if (order.status == "paid") {
                        Toast.makeText(requireContext(), "订单已支付成功", Toast.LENGTH_SHORT).show()
                        // 更新订阅信息
                        updateSubscription()
                    } else if (order.paymentUrl != null || order.paymentQrCode != null) {
                        showPaymentDialog(order)
                    } else {
                        Toast.makeText(requireContext(), "支付链接生成失败", Toast.LENGTH_SHORT).show()
                    }
                }.onFailure { error ->
                    Toast.makeText(requireContext(), "创建订单失败: ${error.message}", Toast.LENGTH_SHORT).show()
                }
            } catch (e: Exception) {
                Toast.makeText(requireContext(), "创建订单失败: ${e.message}", Toast.LENGTH_SHORT).show()
            }
        }
    }

    private fun showPaymentDialog(order: Order) {
        val paymentUrl = order.paymentUrl ?: order.paymentQrCode
        if (paymentUrl.isNullOrBlank()) {
            Toast.makeText(requireContext(), "支付链接生成失败，请稍后重试", Toast.LENGTH_LONG).show()
            return
        }

        val dialogView = LayoutInflater.from(requireContext())
            .inflate(R.layout.dialog_payment, null)

        val qrImageView = dialogView.findViewById<ImageView>(R.id.qr_code_image)
        val orderNoText = dialogView.findViewById<TextView>(R.id.order_no_text)
        val amountText = dialogView.findViewById<TextView>(R.id.amount_text)
        val openAlipayBtn = dialogView.findViewById<MaterialButton>(R.id.open_alipay_btn)
        val openWebViewBtn = dialogView.findViewById<MaterialButton>(R.id.open_webview_btn)
        val checkStatusBtn = dialogView.findViewById<MaterialButton>(R.id.check_status_btn)

        orderNoText.text = "订单号：${order.orderNo}"
        amountText.text = "支付金额：¥${order.finalAmount ?: order.amount}"

        // 生成二维码
        val qrBitmap = generateQRCode(paymentUrl)
        if (qrBitmap != null) {
            qrImageView.setImageBitmap(qrBitmap)
        } else {
            Toast.makeText(requireContext(), "二维码生成失败", Toast.LENGTH_SHORT).show()
            qrImageView.visibility = View.GONE
        }

        // 跳转支付宝App（这是跳转到另一个App，不是浏览器）
        openAlipayBtn.setOnClickListener {
            try {
                // 支付宝App跳转URL格式：alipays://platformapi/startapp?saId=10000007&qrcode=支付URL
                val alipayUrl = "alipays://platformapi/startapp?saId=10000007&qrcode=${Uri.encode(paymentUrl)}"
                val intent = Intent(Intent.ACTION_VIEW, Uri.parse(alipayUrl))
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                try {
                    startActivity(intent)
                    // 如果成功跳转，3秒后提示用户返回检查状态
                    handler.postDelayed({
                        Toast.makeText(requireContext(), "如果已完成支付，请返回检查支付状态", Toast.LENGTH_SHORT).show()
                    }, 3000)
                } catch (e: android.content.ActivityNotFoundException) {
                    // 如果没有安装支付宝，提示用户在App内打开
                    Toast.makeText(requireContext(), "未检测到支付宝App，请点击\"在App内打开支付页面\"或扫描二维码", Toast.LENGTH_LONG).show()
                }
            } catch (e: Exception) {
                Logs.e(e)
                Toast.makeText(requireContext(), "无法打开支付宝，请使用App内支付页面或扫描二维码", Toast.LENGTH_SHORT).show()
            }
        }

        // 在App内打开支付页面（使用WebView，不跳转浏览器）
        openWebViewBtn.setOnClickListener {
            showPaymentWebView(paymentUrl, order.orderNo)
        }

        // 检查支付状态
        checkStatusBtn.setOnClickListener {
            checkPaymentStatus(order.orderNo)
        }


        // 开始轮询支付状态
        var dialogRef: androidx.appcompat.app.AlertDialog? = null
        val dialog = MaterialAlertDialogBuilder(requireContext())
            .setTitle("扫码支付")
            .setView(dialogView)
            .setCancelable(false)
            .setNegativeButton("关闭") { d, _ ->
                paymentStatusCheckJob?.cancel()
                d.dismiss()
            }
            .show()
        dialogRef = dialog
        
        startPaymentStatusCheck(order.orderNo) { isPaid ->
            if (isPaid) {
                dialogRef?.dismiss()
                paymentStatusCheckJob?.cancel()
                Toast.makeText(requireContext(), "支付成功！订阅已更新", Toast.LENGTH_LONG).show()
                updateSubscription()
                // 刷新套餐列表
                loadPackages()
            }
        }
    }

    private fun generateQRCode(url: String): Bitmap? {
        return try {
            val size = 512
            val hints = mutableMapOf<EncodeHintType, Any>()
            val iso88591 = StandardCharsets.ISO_8859_1.newEncoder()
            if (!iso88591.canEncode(url)) {
                hints[EncodeHintType.CHARACTER_SET] = StandardCharsets.UTF_8.name()
            }
            
            val bitMatrix = MultiFormatWriter().encode(url, BarcodeFormat.QR_CODE, size, size, hints)
            val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.RGB_565)
            
            for (x in 0 until size) {
                for (y in 0 until size) {
                    bitmap.setPixel(x, y, if (bitMatrix[x, y]) Color.BLACK else Color.WHITE)
                }
            }
            
            bitmap
        } catch (e: WriterException) {
            Logs.e(e)
            null
        } catch (e: Exception) {
            Logs.e(e)
            null
        }
    }

    private fun startPaymentStatusCheck(orderNo: String, onPaid: (Boolean) -> Unit) {
        paymentStatusCheckJob?.cancel()
        paymentStatusCheckJob = lifecycleScope.launch {
            var checkCount = 0
            val maxChecks = 300 // 最多检查10分钟（300次 * 2秒）
            
            while (isActive && checkCount < maxChecks) {
                delay(2000) // 每2秒检查一次
                checkCount++
                
                try {
                    val result = authRepository.getOrderStatus(orderNo)
                    result.onSuccess { status ->
                        if (status.status == "paid") {
                            onPaid(true)
                            cancel()
                        }
                    }.onFailure { error ->
                        // 查询失败时继续轮询，不中断
                        if (checkCount % 10 == 0) { // 每20秒记录一次错误
                            Logs.w("支付状态查询失败: ${error.message}")
                        }
                    }
                } catch (e: Exception) {
                    Logs.e(e)
                }
            }
            
            // 如果达到最大检查次数，停止轮询
            if (checkCount >= maxChecks) {
                Logs.w("支付状态检查超时，已停止轮询")
            }
        }
    }

    private fun checkPaymentStatus(orderNo: String) {
        lifecycleScope.launch {
            try {
                val result = authRepository.getOrderStatus(orderNo)
                result.onSuccess { status ->
                    when (status.status) {
                        "paid" -> {
                            Toast.makeText(requireContext(), "支付成功！订阅已更新", Toast.LENGTH_LONG).show()
                            paymentStatusCheckJob?.cancel()
                            updateSubscription()
                            loadPackages()
                        }
                        "pending" -> {
                            Toast.makeText(requireContext(), "订单待支付，请完成支付", Toast.LENGTH_SHORT).show()
                        }
                        "cancelled" -> {
                            Toast.makeText(requireContext(), "订单已取消", Toast.LENGTH_SHORT).show()
                        }
                        else -> {
                            Toast.makeText(requireContext(), "订单状态：${status.status}", Toast.LENGTH_SHORT).show()
                        }
                    }
                }.onFailure { error ->
                    Toast.makeText(requireContext(), "查询失败: ${error.message}", Toast.LENGTH_SHORT).show()
                }
            } catch (e: Exception) {
                Logs.e(e)
                Toast.makeText(requireContext(), "查询失败: ${e.message}", Toast.LENGTH_SHORT).show()
            }
        }
    }

    @SuppressLint("SetJavaScriptEnabled")
    private fun showPaymentWebView(paymentUrl: String, orderNo: String) {
        val webViewDialogView = LayoutInflater.from(requireContext())
            .inflate(R.layout.dialog_payment_webview, null)

        val webView = webViewDialogView.findViewById<WebView>(R.id.payment_webview)
        val orderInfoText = webViewDialogView.findViewById<TextView>(R.id.order_info_text)
        val checkStatusWebViewBtn = webViewDialogView.findViewById<MaterialButton>(R.id.check_status_webview_btn)
        val closeWebViewBtn = webViewDialogView.findViewById<MaterialButton>(R.id.close_webview_btn)

        orderInfoText.text = "订单号：$orderNo - 请在下方页面完成支付"

        // 配置WebView
        webView.settings.apply {
            javaScriptEnabled = true
            domStorageEnabled = true
            setSupportZoom(true)
            builtInZoomControls = true
            displayZoomControls = false
            loadWithOverviewMode = true
            useWideViewPort = true
            allowFileAccess = true
            allowContentAccess = true
            // 确保所有链接都在App内打开
            javaScriptCanOpenWindowsAutomatically = true
            // 支持混合内容（HTTP和HTTPS）
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.LOLLIPOP) {
                mixedContentMode = android.webkit.WebSettings.MIXED_CONTENT_ALWAYS_ALLOW
            }
        }

        // 设置WebViewClient，确保所有链接都在App内打开，不跳转浏览器
        webView.webViewClient = object : WebViewClient() {
            @SuppressLint("QueryPermissionsNeeded")
            override fun shouldOverrideUrlLoading(view: WebView?, request: WebResourceRequest?): Boolean {
                val url = request?.url?.toString() ?: return false
                
                // 如果是支付宝App链接，尝试跳转（这是跳转到另一个App，不是浏览器）
                if (url.startsWith("alipays://")) {
                    try {
                        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        if (intent.resolveActivity(requireContext().packageManager) != null) {
                            startActivity(intent)
                            return true
                        }
                    } catch (e: Exception) {
                        Logs.e(e)
                    }
                    // 如果无法跳转，继续在WebView中加载
                    return false
                }
                
                // 如果是http/https链接，在WebView中打开，不跳转浏览器
                if (url.startsWith("http://") || url.startsWith("https://")) {
                    view?.loadUrl(url)
                    return true
                }
                
                // 其他链接都在WebView中打开，不跳转浏览器
                return false
            }

            override fun onPageFinished(view: WebView?, url: String?) {
                super.onPageFinished(view, url)
                // 页面加载完成后，可以自动检查支付状态
            }

            override fun onReceivedError(view: WebView?, request: WebResourceRequest?, error: android.webkit.WebResourceError?) {
                super.onReceivedError(view, request, error)
                Toast.makeText(requireContext(), "页面加载失败，请检查网络连接", Toast.LENGTH_SHORT).show()
            }
        }

        // 加载支付页面
        webView.loadUrl(paymentUrl)

        // 检查支付状态按钮
        checkStatusWebViewBtn.setOnClickListener {
            checkPaymentStatus(orderNo)
        }

        // 创建对话框
        var webViewDialogRef: androidx.appcompat.app.AlertDialog? = null
        val webViewDialog = MaterialAlertDialogBuilder(requireContext())
            .setTitle("支付页面")
            .setView(webViewDialogView)
            .setCancelable(false)
            .setOnDismissListener {
                try {
                    webView.onPause()
                    webView.stopLoading()
                    webView.clearHistory()
                    webView.clearCache(true)
                    webView.removeAllViews()
                    webView.destroy()
                } catch (e: Exception) {
                    Logs.e(e)
                }
                paymentStatusCheckJob?.cancel()
            }
            .show()
        webViewDialogRef = webViewDialog

        // 关闭按钮
        closeWebViewBtn.setOnClickListener {
            webViewDialogRef?.dismiss()
        }

        // 开始轮询支付状态
        startPaymentStatusCheck(orderNo) { isPaid ->
            if (isPaid) {
                webViewDialogRef?.dismiss()
                paymentStatusCheckJob?.cancel()
                Toast.makeText(requireContext(), "支付成功！订阅已更新", Toast.LENGTH_LONG).show()
                updateSubscription()
                loadPackages()
            }
        }
    }

    private fun updateSubscription() {
        // 更新订阅信息
        lifecycleScope.launch {
            try {
                val result = authRepository.getUserSubscription()
                result.onSuccess { subscription ->
                    // 保存订阅信息
                    val prefs = requireContext().getSharedPreferences("subscription_prefs", android.content.Context.MODE_PRIVATE)
                    prefs.edit().apply {
                        putBoolean("has_subscription", true)
                        putString("subscription_url", subscription.universalUrl)
                        putString("expire_time", subscription.expireTime)
                        apply()
                    }

                    // 触发订阅更新
                    (requireActivity() as? MainActivity)?.let { mainActivity ->
                        mainActivity.updateSubscriptionOnResume()
                    }

                    Toast.makeText(requireContext(), "订阅已更新", Toast.LENGTH_SHORT).show()
                }
            } catch (e: Exception) {
                Logs.e(e)
            }
        }
    }

    override fun onDestroyView() {
        super.onDestroyView()
        paymentStatusCheckJob?.cancel()
    }

    inner class PackagesAdapter : RecyclerView.Adapter<PackageViewHolder>() {
        override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): PackageViewHolder {
            val view = LayoutInflater.from(parent.context)
                .inflate(R.layout.item_package, parent, false)
            return PackageViewHolder(view)
        }

        override fun onBindViewHolder(holder: PackageViewHolder, position: Int) {
            val pkg = packagesList[position]
            holder.bind(pkg)
        }

        override fun getItemCount(): Int = packagesList.size
    }

    inner class PackageViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        private val packageCard = itemView.findViewById<MaterialCardView>(R.id.package_card)
        private val packageName = itemView.findViewById<TextView>(R.id.package_name)
        private val packagePrice = itemView.findViewById<TextView>(R.id.package_price)
        private val packageDuration = itemView.findViewById<TextView>(R.id.package_duration)
        private val packageDeviceLimit = itemView.findViewById<TextView>(R.id.package_device_limit)
        private val packageDescription = itemView.findViewById<TextView>(R.id.package_description)
        private val purchaseButton = itemView.findViewById<MaterialButton>(R.id.purchase_button)

        fun bind(pkg: Package) {
            packageName.text = pkg.name
            packagePrice.text = "¥${String.format("%.2f", pkg.price)}"
            packageDuration.text = "有效期：${pkg.durationDays}天"
            packageDeviceLimit.text = "设备限制：${pkg.deviceLimit}个"
            packageDescription.text = pkg.description ?: ""

            if (pkg.isRecommended) {
                packageCard.strokeWidth = 4
                // 获取主题颜色
                val typedValue = TypedValue()
                requireContext().theme.resolveAttribute(android.R.attr.colorPrimary, typedValue, true)
                packageCard.strokeColor = typedValue.data
            } else {
                packageCard.strokeWidth = 0
            }

            purchaseButton.setOnClickListener {
                purchasePackage(pkg)
            }
        }
    }
}

