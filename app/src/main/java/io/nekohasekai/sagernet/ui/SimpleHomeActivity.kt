package io.nekohasekai.sagernet.ui

import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.View
import android.widget.ImageButton
import android.widget.ImageView
import android.widget.TextView
import android.widget.Toast
import androidx.lifecycle.lifecycleScope
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.google.android.material.bottomsheet.BottomSheetDialog
import com.google.android.material.button.MaterialButton
import com.google.android.material.button.MaterialButtonToggleGroup
import com.google.android.material.card.MaterialCardView
import com.google.android.material.progressindicator.CircularProgressIndicator
import com.google.android.material.snackbar.Snackbar
import io.nekohasekai.sagernet.Key
import io.nekohasekai.sagernet.R
import io.nekohasekai.sagernet.SagerNet
import io.nekohasekai.sagernet.aidl.ISagerNetService
import io.nekohasekai.sagernet.aidl.SpeedDisplayData
import io.nekohasekai.sagernet.aidl.TrafficData
import io.nekohasekai.sagernet.auth.AuthRepository
import io.nekohasekai.sagernet.bg.BaseService
import io.nekohasekai.sagernet.bg.SagerConnection
import io.nekohasekai.sagernet.bg.proto.UrlTest
import io.nekohasekai.sagernet.database.DataStore
import io.nekohasekai.sagernet.database.ProfileManager
import io.nekohasekai.sagernet.database.ProxyEntity
import io.nekohasekai.sagernet.database.SagerDatabase
import io.nekohasekai.sagernet.ktx.onMainDispatcher
import io.nekohasekai.sagernet.ktx.runOnDefaultDispatcher
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.*

/**
 * 简洁的主页 Activity - 参考 Hiddify 设计
 */
class SimpleHomeActivity : ThemedActivity(), SagerConnection.Callback {
    
    private lateinit var authRepository: AuthRepository
    
    // Views
    private lateinit var subscriptionInfoRecycler: RecyclerView
    private lateinit var subscriptionInfoAdapter: SubscriptionInfoAdapter
    private lateinit var connectCard: MaterialCardView
    private lateinit var connectIcon: ImageView
    private lateinit var connectProgress: CircularProgressIndicator
    private lateinit var connectText: TextView
    private lateinit var connectHint: TextView
    private lateinit var modeToggleGroup: MaterialButtonToggleGroup
    private lateinit var modeRuleButton: MaterialButton
    private lateinit var modeGlobalButton: MaterialButton
    private lateinit var nodeSelectorCard: MaterialCardView
    private lateinit var currentNodeName: TextView
    private lateinit var currentNodeLatency: TextView
    
    // Data
    private val connection = SagerConnection(SagerConnection.CONNECTION_ID_MAIN_ACTIVITY_FOREGROUND, true)
    private var currentProfiles: List<ProxyEntity> = emptyList()
    private var selectedProfileId: Long = 0L
    private val testingNodes = mutableSetOf<Long>()
    private val handler = Handler(Looper.getMainLooper())
    private var connectionStartTime: Long = 0
    private val updateSpeedRunnable = object : Runnable {
        override fun run() {
            if (DataStore.serviceState.connected) {
                updateConnectionDuration()
                handler.postDelayed(this, 1000)
            }
        }
    }
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // 认证检查
        authRepository = AuthRepository(this)
        if (!authRepository.isAuthenticated()) {
            startActivity(Intent(this, LoginActivity::class.java))
            finish()
            return
        }
        
        setContentView(R.layout.layout_main_simple)
        
        initViews()
        setupListeners()
        loadSubscriptionInfo()
        loadCurrentNode()
        
        // 连接服务
        connection.connect(this, this)
        
        // 自动添加订阅
        checkAndAddSubscription()
        
        // 加载节点列表并开始后台测速
        loadProfilesAndStartTesting()
    }
    
    private fun initViews() {
        subscriptionInfoRecycler = findViewById(R.id.subscription_info_recycler)
        subscriptionInfoAdapter = SubscriptionInfoAdapter(emptyList())
        subscriptionInfoRecycler.adapter = subscriptionInfoAdapter
        connectCard = findViewById(R.id.connect_card)
        connectIcon = findViewById(R.id.connect_icon)
        connectProgress = findViewById(R.id.connect_progress)
        connectText = findViewById(R.id.connect_text)
        connectHint = findViewById(R.id.connect_hint)
        modeToggleGroup = findViewById(R.id.mode_toggle_group)
        modeRuleButton = findViewById(R.id.mode_rule)
        modeGlobalButton = findViewById(R.id.mode_global)
        nodeSelectorCard = findViewById(R.id.node_selector_card)
        currentNodeName = findViewById(R.id.current_node_name)
        currentNodeLatency = findViewById(R.id.current_node_latency)
        
        // 初始化模式状态
        val currentBypass = DataStore.bypass
        if (currentBypass) {
            modeToggleGroup.check(R.id.mode_rule)
        } else {
            modeToggleGroup.check(R.id.mode_global)
        }
        
        // 初始化连接状态
        updateConnectionUI(DataStore.serviceState)
    }
    
    private fun setupListeners() {
        // 连接按钮点击
        connectCard.setOnClickListener {
            if (DataStore.serviceState.canStop) {
                // 断开连接
                SagerNet.stopService()
            } else {
                // 开始连接
                startVpnConnection()
            }
        }
        
        // 模式切换
        modeToggleGroup.addOnButtonCheckedListener { _, checkedId, isChecked ->
            if (isChecked) {
                when (checkedId) {
                    R.id.mode_rule -> {
                        // 规则模式（bypass = true）
                        if (!DataStore.bypass) {
                            DataStore.bypass = true
                            Toast.makeText(this, "已切换到规则模式", Toast.LENGTH_SHORT).show()
                            if (DataStore.serviceState.connected) {
                                // 重新连接以应用新模式
                                reconnectWithNewMode()
                            }
                        }
                    }
                    R.id.mode_global -> {
                        // 全局模式（bypass = false）
                        if (DataStore.bypass) {
                            DataStore.bypass = false
                            Toast.makeText(this, "已切换到全局模式", Toast.LENGTH_SHORT).show()
                            if (DataStore.serviceState.connected) {
                                reconnectWithNewMode()
                            }
                        }
                    }
                }
            }
        }
        
        // 节点选择器点击
        nodeSelectorCard.setOnClickListener {
            showNodeSelector()
        }
        
        // 设置按钮
        findViewById<ImageButton>(R.id.btn_settings)?.setOnClickListener {
            // 打开设置页面（可以使用原有的 SettingsFragment）
            Toast.makeText(this, "设置功能", Toast.LENGTH_SHORT).show()
        }
        
        // 统计按钮
        findViewById<ImageButton>(R.id.btn_stats)?.setOnClickListener {
            Toast.makeText(this, "统计功能", Toast.LENGTH_SHORT).show()
        }
    }
    
    private fun loadSubscriptionInfo() {
        lifecycleScope.launch {
            val result = authRepository.getUserSubscription()
            result.onSuccess { subscription ->
                val items = mutableListOf<SubscriptionInfoAdapter.SubscriptionInfoItem>()
                
                // 官网卡片
                items.add(SubscriptionInfoAdapter.SubscriptionInfoItem(
                    icon = android.R.drawable.ic_dialog_info,
                    text = "官网: https://dy.moneyfly.top",
                    type = "Shadowsocks",
                    status = "超时",
                    showActions = true
                ))
                
                // 到期卡片
                if (subscription.expireTime.isNotEmpty() && subscription.expireTime != "未设置") {
                    items.add(SubscriptionInfoAdapter.SubscriptionInfoItem(
                        icon = android.R.drawable.ic_lock_idle_alarm,
                        text = "到期: ${subscription.expireTime}",
                        type = "Shadowsocks",
                        status = "超时",
                        showActions = true
                    ))
                }
                
                // 设备卡片
                items.add(SubscriptionInfoAdapter.SubscriptionInfoItem(
                    icon = android.R.drawable.ic_menu_myplaces,
                    text = "设备: ${subscription.currentDevices}/${subscription.deviceLimit}",
                    type = "Shadowsocks",
                    status = "超时",
                    showActions = true
                ))
                
                // 客服QQ卡片
                items.add(SubscriptionInfoAdapter.SubscriptionInfoItem(
                    icon = android.R.drawable.ic_dialog_email,
                    text = "客服QQ: 3219904322@qq.com",
                    type = "Shadowsocks",
                    status = "超时",
                    showActions = true
                ))
                
                // 更新适配器
                subscriptionInfoAdapter = SubscriptionInfoAdapter(items)
                subscriptionInfoRecycler.adapter = subscriptionInfoAdapter
            }
            
            result.onFailure { error ->
                // 如果获取失败，显示默认信息
                val items = listOf(
                    SubscriptionInfoAdapter.SubscriptionInfoItem(
                        icon = android.R.drawable.ic_dialog_info,
                        text = "官网: https://dy.moneyfly.top",
                        type = "Shadowsocks",
                        status = "超时",
                        showActions = true
                    )
                )
                subscriptionInfoAdapter = SubscriptionInfoAdapter(items)
                subscriptionInfoRecycler.adapter = subscriptionInfoAdapter
            }
        }
    }
    
    private fun loadCurrentNode() {
        lifecycleScope.launch {
            runOnDefaultDispatcher {
                val currentId = DataStore.selectedProxy
                if (currentId > 0) {
                    val profile = ProfileManager.getProfile(currentId)
                    if (profile != null) {
                        selectedProfileId = currentId
                        onMainDispatcher {
                            currentNodeName.text = profile.displayName()
                            val latency = profile.ping
                            if (latency > 0) {
                                currentNodeLatency.text = "延迟: ${latency}ms"
                                currentNodeLatency.visibility = View.VISIBLE
                            } else {
                                currentNodeLatency.visibility = View.GONE
                            }
                        }
                    }
                } else {
                    onMainDispatcher {
                        currentNodeName.text = "🌐 自动选择"
                        currentNodeLatency.visibility = View.GONE
                    }
                }
            }
        }
    }
    
    private fun loadProfilesAndStartTesting() {
        lifecycleScope.launch {
            runOnDefaultDispatcher {
                // 加载所有配置
                val profiles = SagerDatabase.proxyDao.getAll()
                currentProfiles = profiles
                
                // 如果已连接，开始后台测速
                if (DataStore.serviceState.connected) {
                    startBackgroundTesting()
                }
            }
        }
    }
    
    /**
     * 后台持续测速
     */
    private fun startBackgroundTesting() {
        lifecycleScope.launch {
            runOnDefaultDispatcher {
                while (DataStore.serviceState.connected) {
                    // 对所有节点进行测速
                    currentProfiles.forEach { profile ->
                        if (!testingNodes.contains(profile.id)) {
                            testingNodes.add(profile.id)
                            try {
                                val urlTest = UrlTest()
                                val latency = urlTest.doTest(profile)
                                
                                // 更新延迟数据
                                profile.ping = latency
                                ProfileManager.updateProfile(profile)
                                
                                // 如果是当前节点，更新UI
                                if (profile.id == selectedProfileId) {
                                    onMainDispatcher {
                                        if (latency > 0) {
                                            currentNodeLatency.text = "延迟: ${latency}ms"
                                            currentNodeLatency.visibility = View.VISIBLE
                                        }
                                    }
                                }
                            } catch (e: Exception) {
                                // 测速失败，标记延迟为 -1
                                profile.ping = -1
                                ProfileManager.updateProfile(profile)
                            } finally {
                                testingNodes.remove(profile.id)
                            }
                        }
                    }
                    
                    // 每 30 秒测速一次
                    delay(30000)
                }
            }
        }
    }
    
    private fun startVpnConnection() {
        lifecycleScope.launch {
            runOnDefaultDispatcher {
                // 如果没有选择节点，自动选择最优节点
                if (selectedProfileId == 0L || selectedProfileId == -1L) {
                    val bestProfile = findBestProfile()
                    if (bestProfile != null) {
                        selectedProfileId = bestProfile.id
                        DataStore.selectedProxy = bestProfile.id
                        onMainDispatcher {
                            currentNodeName.text = bestProfile.displayName()
                            Toast.makeText(
                                this@SimpleHomeActivity,
                                "自动选择节点: ${bestProfile.displayName()}",
                                Toast.LENGTH_SHORT
                            ).show()
                        }
                    } else {
                        onMainDispatcher {
                            Toast.makeText(
                                this@SimpleHomeActivity,
                                "没有可用的节点，请先添加订阅",
                                Toast.LENGTH_LONG
                            ).show()
                        }
                        return@runOnDefaultDispatcher
                    }
                }
                
                // 开始连接
                onMainDispatcher {
                    SagerNet.startService()
                    connectionStartTime = System.currentTimeMillis()
                }
            }
        }
    }
    
    /**
     * 查找最优节点（延迟最低的）
     */
    private fun findBestProfile(): ProxyEntity? {
        return currentProfiles
            .filter { it.ping > 0 } // 只选择测速成功的
            .minByOrNull { it.ping }
            ?: currentProfiles.firstOrNull() // 如果都没测速，返回第一个
    }
    
    private fun reconnectWithNewMode() {
        Snackbar.make(
            connectCard,
            "正在应用新模式...",
            Snackbar.LENGTH_SHORT
        ).show()
        
        lifecycleScope.launch {
            SagerNet.reloadService()
        }
    }
    
    private fun showNodeSelector() {
        val dialog = BottomSheetDialog(this)
        val view = layoutInflater.inflate(R.layout.bottom_sheet_node_selector, null)
        dialog.setContentView(view)
        
        val recyclerView = view.findViewById<RecyclerView>(R.id.nodes_recycler_view)
        val refreshButton = view.findViewById<MaterialButton>(R.id.btn_refresh_nodes)
        val closeButton = view.findViewById<ImageButton>(R.id.btn_close_sheet)
        
        recyclerView.layoutManager = LinearLayoutManager(this)
        
        lifecycleScope.launch {
            runOnDefaultDispatcher {
                val profiles = SagerDatabase.proxyDao.getAll()
                    .sortedBy { it.ping.takeIf { p -> p > 0 } ?: Int.MAX_VALUE }
                
                onMainDispatcher {
                    val adapter = NodeListAdapter(
                        profiles,
                        selectedProfileId
                    ) { profile ->
                        // 节点被选中
                        selectNode(profile)
                        dialog.dismiss()
                    }
                    recyclerView.adapter = adapter
                }
            }
        }
        
        refreshButton.setOnClickListener {
            // 手动触发测速
            testAllNodes(recyclerView.adapter as? NodeListAdapter)
        }
        
        closeButton.setOnClickListener {
            dialog.dismiss()
        }
        
        dialog.show()
        
        // 打开时自动测速
        testAllNodes(recyclerView.adapter as? NodeListAdapter)
    }
    
    private fun testAllNodes(adapter: NodeListAdapter?) {
        lifecycleScope.launch {
            runOnDefaultDispatcher {
                currentProfiles.forEach { profile ->
                    try {
                        adapter?.updateNodeTesting(profile.id, true)
                        
                        val urlTest = UrlTest()
                        val latency = urlTest.doTest(profile)
                        
                        profile.ping = latency
                        ProfileManager.updateProfile(profile)
                        
                        adapter?.updateNodeLatency(profile.id, latency)
                        adapter?.updateNodeTesting(profile.id, false)
                        
                        // 重新排序
                        delay(100)
                        adapter?.sortByLatency()
                    } catch (e: Exception) {
                        profile.ping = -1
                        ProfileManager.updateProfile(profile)
                        adapter?.updateNodeLatency(profile.id, -1)
                        adapter?.updateNodeTesting(profile.id, false)
                    }
                }
            }
        }
    }
    
    private fun selectNode(profile: ProxyEntity) {
        selectedProfileId = profile.id
        DataStore.selectedProxy = profile.id
        currentNodeName.text = profile.displayName()
        
        if (profile.ping > 0) {
            currentNodeLatency.text = "延迟: ${profile.ping}ms"
            currentNodeLatency.visibility = View.VISIBLE
        }
        
        if (DataStore.serviceState.connected) {
            // 已连接，切换节点
            Toast.makeText(this, "正在切换到 ${profile.displayName()}...", Toast.LENGTH_SHORT).show()
            lifecycleScope.launch {
                SagerNet.reloadService()
            }
        } else {
            Toast.makeText(this, "已选择 ${profile.displayName()}", Toast.LENGTH_SHORT).show()
        }
    }
    
    private fun updateConnectionUI(state: BaseService.State) {
        when (state) {
            BaseService.State.Idle, BaseService.State.Stopped -> {
                // 未连接
                connectCard.setCardBackgroundColor(getColor(android.R.color.darker_gray))
                connectIcon.visibility = View.VISIBLE
                connectProgress.visibility = View.GONE
                connectText.text = "连接"
                connectText.setTextColor(getColor(android.R.color.white))
                connectHint.text = "点击连接 VPN"
                connectHint.visibility = View.VISIBLE
                
                // 停止时长更新
                handler.removeCallbacks(updateSpeedRunnable)
            }
            BaseService.State.Connecting -> {
                // 连接中
                connectCard.setCardBackgroundColor(getColor(android.R.color.holo_blue_light))
                connectIcon.visibility = View.GONE
                connectProgress.visibility = View.VISIBLE
                connectText.text = "连接中..."
                connectText.setTextColor(getColor(android.R.color.white))
                connectHint.text = "正在连接服务器"
                connectHint.visibility = View.VISIBLE
            }
            BaseService.State.Connected -> {
                // 已连接
                connectCard.setCardBackgroundColor(getColor(android.R.color.holo_green_light))
                connectIcon.visibility = View.VISIBLE
                connectProgress.visibility = View.GONE
                connectText.text = "断开"
                connectText.setTextColor(getColor(android.R.color.white))
                connectHint.visibility = View.VISIBLE
                
                // 开始时长更新
                connectionStartTime = System.currentTimeMillis()
                handler.post(updateSpeedRunnable)
                
                // 开始后台测速
                startBackgroundTesting()
            }
            else -> {}
        }
    }
    
    private fun updateConnectionDuration() {
        if (connectionStartTime > 0) {
            val duration = (System.currentTimeMillis() - connectionStartTime) / 1000
            val hours = duration / 3600
            val minutes = (duration % 3600) / 60
            val seconds = duration % 60
            connectHint.text = String.format("%02d:%02d:%02d", hours, minutes, seconds)
        }
    }
    
    private fun checkAndAddSubscription() {
        val prefs = getSharedPreferences("subscription_prefs", MODE_PRIVATE)
        val hasSubscription = prefs.getBoolean("has_subscription", false)
        val subscriptionUrl = prefs.getString("subscription_url", null)
        
        if (hasSubscription && !subscriptionUrl.isNullOrEmpty()) {
            lifecycleScope.launch {
                try {
                    runOnDefaultDispatcher {
                        val expireTime = prefs.getString("expire_time", "未设置")
                        val groupName = if (expireTime != "未设置") {
                            "到期: $expireTime"
                        } else {
                            "我的订阅"
                        }
                        
                        // 使用原有的导入逻辑
                        // 这里简化处理，实际应该检查是否已存在
                        onMainDispatcher {
                            Snackbar.make(
                                connectCard,
                                "订阅: $groupName",
                                Snackbar.LENGTH_LONG
                            ).show()
                        }
                    }
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }
        }
    }
    
    // SagerConnection.Callback 实现
    override fun stateChanged(state: BaseService.State, profileName: String?, msg: String?) {
        updateConnectionUI(state)
        if (msg != null) {
            Snackbar.make(connectCard, "错误: $msg", Snackbar.LENGTH_LONG).show()
        }
    }
    
    override fun onServiceConnected(service: ISagerNetService) {
        val state = try {
            BaseService.State.values()[service.state]
        } catch (e: Exception) {
            BaseService.State.Idle
        }
        updateConnectionUI(state)
    }
    
    override fun onServiceDisconnected() {
        updateConnectionUI(BaseService.State.Idle)
    }
    
    override fun onBinderDied() {
        connection.disconnect(this)
        connection.connect(this, this)
    }
    
    override fun cbSpeedUpdate(stats: SpeedDisplayData) {
        // 更新速度显示
        // 速度信息已移除，不再显示
    }
    
    override fun cbTrafficUpdate(data: TrafficData) {
        runOnDefaultDispatcher {
            ProfileManager.postUpdate(data)
        }
    }
    
    override fun cbSelectorUpdate(id: Long) {
        DataStore.selectedProxy = id
        DataStore.currentProfile = id
        runOnDefaultDispatcher {
            ProfileManager.postUpdate(id, true)
        }
        loadCurrentNode()
    }
    
    private fun formatSpeed(bytesPerSecond: Long): String {
        return when {
            bytesPerSecond < 1024 -> "${bytesPerSecond}B/s"
            bytesPerSecond < 1024 * 1024 -> "${bytesPerSecond / 1024}KB/s"
            else -> String.format("%.1fMB/s", bytesPerSecond / 1024.0 / 1024.0)
        }
    }
    
    override fun onStart() {
        super.onStart()
        connection.updateConnectionId(SagerConnection.CONNECTION_ID_MAIN_ACTIVITY_FOREGROUND)
    }
    
    override fun onStop() {
        super.onStop()
        connection.updateConnectionId(SagerConnection.CONNECTION_ID_MAIN_ACTIVITY_BACKGROUND)
    }
    
    override fun onDestroy() {
        super.onDestroy()
        connection.disconnect(this)
        handler.removeCallbacks(updateSpeedRunnable)
    }
}

/**
 * 节点列表适配器
 */
class NodeListAdapter(
    private var nodes: List<ProxyEntity>,
    private val selectedId: Long,
    private val onNodeClick: (ProxyEntity) -> Unit
) : RecyclerView.Adapter<NodeViewHolder>() {
    
    private val testingMap = mutableMapOf<Long, Boolean>()
    private val latencyMap = mutableMapOf<Long, Int>()
    
    init {
        nodes.forEach { node ->
            latencyMap[node.id] = node.ping
        }
    }
    
    override fun onCreateViewHolder(parent: android.view.ViewGroup, viewType: Int): NodeViewHolder {
        val view = android.view.LayoutInflater.from(parent.context)
            .inflate(R.layout.item_node, parent, false)
        return NodeViewHolder(view)
    }
    
    override fun onBindViewHolder(holder: NodeViewHolder, position: Int) {
        val node = nodes[position]
        holder.bind(
            node,
            node.id == selectedId,
            testingMap[node.id] == true,
            latencyMap[node.id] ?: node.ping
        )
        holder.itemView.setOnClickListener {
            onNodeClick(node)
        }
    }
    
    override fun getItemCount() = nodes.size
    
    fun updateNodeTesting(nodeId: Long, testing: Boolean) {
        testingMap[nodeId] = testing
        val position = nodes.indexOfFirst { it.id == nodeId }
        if (position >= 0) {
            notifyItemChanged(position)
        }
    }
    
    fun updateNodeLatency(nodeId: Long, latency: Int) {
        latencyMap[nodeId] = latency
        val position = nodes.indexOfFirst { it.id == nodeId }
        if (position >= 0) {
            notifyItemChanged(position)
        }
    }
    
    fun sortByLatency() {
        nodes = nodes.sortedBy { latencyMap[it.id]?.takeIf { l -> l > 0 } ?: Int.MAX_VALUE }
        notifyDataSetChanged()
    }
}

/**
 * 节点列表项 ViewHolder
 */
class NodeViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
    private val nodeFlag: TextView = itemView.findViewById(R.id.node_flag)
    private val nodeName: TextView = itemView.findViewById(R.id.node_name)
    private val nodeLatency: TextView = itemView.findViewById(R.id.node_latency)
    private val fastestBadge: TextView = itemView.findViewById(R.id.fastest_badge)
    private val nodeCheck: ImageView = itemView.findViewById(R.id.node_check)
    private val testProgress: View = itemView.findViewById(R.id.test_progress)
    private val nodeError: TextView = itemView.findViewById(R.id.node_error)
    private val signalViews = listOf(
        itemView.findViewById<View>(R.id.signal_1),
        itemView.findViewById<View>(R.id.signal_2),
        itemView.findViewById<View>(R.id.signal_3),
        itemView.findViewById<View>(R.id.signal_4),
        itemView.findViewById<View>(R.id.signal_5)
    )
    
    fun bind(node: ProxyEntity, isSelected: Boolean, isTesting: Boolean, latency: Int) {
        // 节点名称
        nodeName.text = node.displayName()
        
        // 选中标记
        nodeCheck.visibility = if (isSelected) View.VISIBLE else View.GONE
        
        // 测速状态
        testProgress.visibility = if (isTesting) View.VISIBLE else View.GONE
        
        // 延迟显示
        when {
            latency > 0 -> {
                nodeLatency.text = "${latency}ms"
                nodeLatency.visibility = View.VISIBLE
                nodeError.visibility = View.GONE
                
                // 信号强度
                val strength = calculateSignalStrength(latency)
                updateSignalBars(strength)
                
                // 最快标记（延迟小于20ms）
                fastestBadge.visibility = if (latency < 20) View.VISIBLE else View.GONE
            }
            latency == -1 -> {
                // 测速失败
                nodeLatency.visibility = View.GONE
                nodeError.text = "超时"
                nodeError.visibility = View.VISIBLE
                updateSignalBars(0)
                fastestBadge.visibility = View.GONE
            }
            else -> {
                // 未测速
                nodeLatency.text = "--"
                nodeLatency.visibility = View.VISIBLE
                nodeError.visibility = View.GONE
                updateSignalBars(0)
                fastestBadge.visibility = View.GONE
            }
        }
        
        // 国旗图标（简化处理）
        nodeFlag.text = getCountryFlag(node.displayName())
    }
    
    private fun calculateSignalStrength(latency: Int): Int {
        return when {
            latency <= 0 -> 0
            latency <= 50 -> 5    // 优秀
            latency <= 100 -> 4   // 良好
            latency <= 200 -> 3   // 一般
            latency <= 500 -> 2   // 较慢
            else -> 1             // 很慢
        }
    }
    
    private fun updateSignalBars(strength: Int) {
        signalViews.forEachIndexed { index, view ->
            view.visibility = if (index < strength) View.VISIBLE else View.INVISIBLE
        }
    }
    
    private fun getCountryFlag(name: String): String {
        return when {
            name.contains("香港", ignoreCase = true) || name.contains("HK", ignoreCase = true) -> "🇭🇰"
            name.contains("美国", ignoreCase = true) || name.contains("US", ignoreCase = true) -> "🇺🇸"
            name.contains("日本", ignoreCase = true) || name.contains("JP", ignoreCase = true) -> "🇯🇵"
            name.contains("新加坡", ignoreCase = true) || name.contains("SG", ignoreCase = true) -> "🇸🇬"
            name.contains("台湾", ignoreCase = true) || name.contains("TW", ignoreCase = true) -> "🇹🇼"
            name.contains("韩国", ignoreCase = true) || name.contains("KR", ignoreCase = true) -> "🇰🇷"
            name.contains("英国", ignoreCase = true) || name.contains("UK", ignoreCase = true) -> "🇬🇧"
            name.contains("德国", ignoreCase = true) || name.contains("DE", ignoreCase = true) -> "🇩🇪"
            name.contains("法国", ignoreCase = true) || name.contains("FR", ignoreCase = true) -> "🇫🇷"
            name.contains("加拿大", ignoreCase = true) || name.contains("CA", ignoreCase = true) -> "🇨🇦"
            name.contains("澳大利亚", ignoreCase = true) || name.contains("AU", ignoreCase = true) -> "🇦🇺"
            else -> "🌐"
        }
    }
}

