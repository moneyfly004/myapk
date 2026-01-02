import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/cyberpunk_theme.dart';
import '../../../widgets/cyberpunk/neon_button.dart';
import '../../../widgets/cyberpunk/neon_card.dart';
import '../../../widgets/cyberpunk/grid_background.dart';
import '../../../widgets/cyberpunk/neon_text.dart';
import '../../../widgets/performance/const_widgets.dart';
import '../providers/connection_provider.dart';
import '../providers/routing_provider.dart';
import '../../node/providers/node_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/repositories/auth_repository.dart';
import '../../settings/pages/settings_page.dart';
import '../../group/pages/group_page.dart';
import '../../route/pages/route_page.dart';
import '../../log/pages/log_page.dart';
import '../../traffic/pages/traffic_page.dart';
import '../../tools/pages/tools_page.dart';
import '../../about/pages/about_page.dart';
import '../../package/pages/package_purchase_page.dart';
import '../../subscription/services/subscription_service.dart';
import '../../../services/vpn_service.dart' as vpn;
import '../../../core/utils/debouncer.dart';

class MainPage extends ConsumerStatefulWidget {
  const MainPage({super.key});

  @override
  ConsumerState<MainPage> createState() => _MainPageState();
}

class _MainPageState extends ConsumerState<MainPage> {
  bool _isNodeListExpanded = false;
  final _debouncer = Debouncer(delay: const Duration(milliseconds: 300));
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(context),
      body: Column(
        children: [
          // 自定义标题栏（支持拖拽、关闭、最大化、最小化）
          CustomTitleBar(
            title: 'NekoBox',
            leading: IconButton(
              icon: const Icon(Icons.menu, color: CyberpunkTheme.primaryNeon),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
          ),
          // 主内容
          Expanded(
            child: GridBackground(
              gridColor: CyberpunkTheme.primaryNeon,
              gridSize: 20.0,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: CyberpunkGradients.backgroundGradient,
                ),
                child: SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ConstWidgets.largeSeparator,
                        
                        // 用户信息卡片
                        _buildUserInfoCard(context),
                        
                        ConstWidgets.largeSeparator,
                        
                        // 连接按钮
                        _buildConnectButton(context),
                        
                        ConstWidgets.largeSeparator,
                        
                        // 路由模式选择
                        _buildRoutingModeSelector(context),
                        
                        ConstWidgets.largeSeparator,
                        
                        // 节点选择器
                        _buildNodeSelector(context),
                        
                        ConstWidgets.largeSeparator,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildUserInfoCard(BuildContext context) {
    return NeonCard(
      neonColor: CyberpunkTheme.primaryNeon,
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const NeonText(
            text: '到期时间：未设置',
            fontSize: 16,
            neonColor: CyberpunkTheme.textNeon,
            fontWeight: FontWeight.bold,
          ),
            ConstWidgets.separator,
            Container(
              height: 8,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(4)),
                color: CyberpunkTheme.surfaceBackground,
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(4)),
                child: LinearProgressIndicator(
                  value: 0.5,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    CyberpunkTheme.primaryNeon,
                  ),
                ),
              ),
            ),
            ConstWidgets.smallSeparator,
          const NeonText(
            text: '剩余天数：0',
            fontSize: 12,
            neonColor: CyberpunkTheme.textSecondary,
          ),
            ConstWidgets.separator,
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                NeonText(
                  text: '设备数：0/0',
                  fontSize: 14,
                  neonColor: CyberpunkTheme.textPrimary,
                ),
                NeonText(
                  text: '在线：0',
                  fontSize: 14,
                  neonColor: CyberpunkTheme.accentNeon,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildConnectButton(BuildContext context) {
    // 使用 select 精确监听状态变化，减少重建
    final connectionStatus = ref.watch(
      connectionProvider.select((state) => state.status),
    );
    final isConnected = connectionStatus == ConnectionStatus.connected;
    final isConnecting = connectionStatus == ConnectionStatus.connecting ||
        connectionStatus == ConnectionStatus.disconnecting;

    return NeonButton(
      text: isConnected
          ? '断开连接'
          : isConnecting
              ? '连接中...'
              : '开始连接',
      neonColor: isConnected
          ? CyberpunkTheme.warningNeon
          : CyberpunkTheme.primaryNeon,
      width: 240,
      height: 70,
      isActive: isConnected,
      onPressed: isConnecting
          ? null
          : () async {
              final connectionNotifier = ref.read(connectionProvider.notifier);
              final vpnNotifier = ref.read(vpn.vpnServiceProvider.notifier);
              final nodeState = ref.read(nodeListProvider);
              
              if (isConnected) {
                await vpnNotifier.disconnect();
                await connectionNotifier.disconnect();
              } else {
                // 检查是否有可用节点
                if (nodeState.nodes.isEmpty) {
                  // 显示错误提示
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('没有可用的节点，请先添加节点'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  return;
                }
                
                // 获取选中的节点
                final selectedNode = nodeState.nodes.firstWhere(
                  (node) => node.id == nodeState.selectedNodeId,
                  orElse: () => nodeState.nodes.first,
                );
                
                // 获取路由模式
                final routingMode = ref.read(routingModeProvider);
                final isGlobalMode = routingMode == RoutingMode.global;
                
                // 获取路由规则（规则模式时使用）
                List<Map<String, dynamic>>? rules;
                if (!isGlobalMode) {
                  // TODO: 从数据库加载启用的路由规则
                  // final ruleState = ref.read(ruleListProvider);
                  // rules = ruleState.rules
                  //     .where((r) => r.enabled)
                  //     .map((r) => r.toMap())
                  //     .toList();
                }
                
                // 生成配置
                final config = vpn.generateSingBoxConfig(
                  server: selectedNode.server,
                  port: selectedNode.port,
                  type: selectedNode.type,
                  additionalConfig: selectedNode.config,
                  isGlobalMode: isGlobalMode,
                  rules: rules,
                );
                
                // 连接 VPN（会自动设置系统代理）
                await vpnNotifier.connect(config, isGlobalMode: isGlobalMode);
                await connectionNotifier.connect(nodeState.selectedNodeId);
              }
            },
    );
  }

  Widget _buildRoutingModeSelector(BuildContext context) {
    final routingMode = ref.watch(routingModeProvider);
    final isGlobalMode = routingMode == RoutingMode.global;

    return NeonCard(
      neonColor: CyberpunkTheme.secondaryNeon,
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const NeonText(
            text: '路由模式',
            fontSize: 18,
            neonColor: CyberpunkTheme.secondaryNeon,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
            ConstWidgets.separator,
            Row(
              children: [
                Expanded(
                  child: _buildModeOption(
                    '规则模式',
                    !isGlobalMode,
                    CyberpunkTheme.primaryNeon,
                    () {
                      ref.read(routingModeProvider.notifier).state = RoutingMode.rules;
                    },
                  ),
                ),
                ConstWidgets.separator,
                Expanded(
                  child: _buildModeOption(
                    '全局模式',
                    isGlobalMode,
                    CyberpunkTheme.accentNeon,
                    () {
                      ref.read(routingModeProvider.notifier).state = RoutingMode.global;
                    },
                  ),
                ),
              ],
            ),
            ConstWidgets.smallSeparator,
          const NeonText(
            text: '规则模式：规则内不翻墙，规则外翻墙',
            fontSize: 12,
            neonColor: CyberpunkTheme.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildModeOption(
    String title,
    bool isSelected,
    Color neonColor,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? neonColor
                : neonColor.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          color: isSelected
              ? neonColor.withOpacity(0.1)
              : Colors.transparent,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: neonColor.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: NeonText(
            text: title,
            fontSize: 14,
            neonColor: isSelected ? neonColor : CyberpunkTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildNodeSelector(BuildContext context) {
    // 使用 select 精确监听状态变化，减少重建（性能优化）
    final nodeState = ref.watch(
      nodeListProvider.select((state) => state),
    );
    final selectedNodeId = nodeState.selectedNodeId;
    
    // 检查是否有可用节点
    if (nodeState.nodes.isEmpty) {
      return const NeonCard(
        neonColor: CyberpunkTheme.primaryNeon,
        padding: EdgeInsets.all(20.0),
        child: Center(
          child: NeonText(
            text: '暂无节点',
            fontSize: 14,
            neonColor: CyberpunkTheme.textSecondary,
          ),
        ),
      );
    }
    
    final selectedNode = nodeState.nodes.firstWhere(
      (node) => node.id == selectedNodeId,
      orElse: () => nodeState.nodes.first,
    );

    return NeonCard(
      neonColor: CyberpunkTheme.primaryNeon,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // 标题栏（可点击）
          GestureDetector(
            onTap: () {
              setState(() {
                _isNodeListExpanded = !_isNodeListExpanded;
              });
              // 展开时自动测速（使用防抖优化）
              if (_isNodeListExpanded) {
                _debouncer.call(() {
                  ref.read(nodeListProvider.notifier).autoUrlTest();
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: CyberpunkTheme.primaryNeon.withOpacity(0.3),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  const NeonText(
                    text: '节点选择',
                    fontSize: 18,
                    neonColor: CyberpunkTheme.primaryNeon,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                  const Spacer(),
                  NeonText(
                    text: selectedNode.name,
                    fontSize: 14,
                    neonColor: CyberpunkTheme.accentNeon,
                  ),
                  ConstWidgets.smallSeparator,
                  Icon(
                    _isNodeListExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: CyberpunkTheme.primaryNeon,
                  ),
                ],
              ),
            ),
          ),
          
          // 节点列表
          if (_isNodeListExpanded)
            Container(
              constraints: const BoxConstraints(maxHeight: 300),
              padding: const EdgeInsets.all(8.0),
              child: nodeState.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: nodeState.nodes.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final node = nodeState.nodes[index];
                        return _buildNodeItem(
                          node,
                          node.id == nodeState.selectedNodeId,
                        );
                      },
                    ),
            ),
        ],
      ),
    );
  }

  Widget _buildNodeItem(Node node, bool isSelected) {
    final neonColor = node.id == 'auto'
        ? CyberpunkTheme.accentNeon
        : CyberpunkTheme.primaryNeon;

    return GestureDetector(
      onTap: () {
        ref.read(nodeListProvider.notifier).selectNode(node.id);
      },
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? neonColor
                : neonColor.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
          color: isSelected
              ? neonColor.withOpacity(0.1)
              : Colors.transparent,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: neonColor.withOpacity(0.2),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              Icons.cloud,
              color: neonColor,
              size: 24,
            ),
            ConstWidgets.smallSeparator,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  NeonText(
                    text: node.name,
                    fontSize: 14,
                    neonColor: isSelected ? neonColor : CyberpunkTheme.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  ConstWidgets.smallSeparator,
                  NeonText(
                    text: node.ping != null
                        ? '延迟: ${node.ping}ms'
                        : '测试中...',
                    fontSize: 12,
                    neonColor: CyberpunkTheme.textSecondary,
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: neonColor,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    
    return Drawer(
      backgroundColor: CyberpunkTheme.darkerBackground,
      child: Column(
        children: [
          // 用户信息头部
          Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: CyberpunkTheme.primaryNeon.withOpacity(0.1),
              border: Border(
                bottom: BorderSide(
                  color: CyberpunkTheme.primaryNeon.withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const NeonText(
                  'NekoBox',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                const SizedBox(height: 8),
                if (authState.email != null)
                  NeonText(
                    text: authState.email!,
                    fontSize: 14,
                    neonColor: CyberpunkTheme.textSecondary,
                  ),
              ],
            ),
          ),
          
          // 菜单项
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  context,
                  icon: Icons.dashboard,
                  title: '配置',
                  onTap: () {
                    Navigator.of(context).pop();
                    // 已经在主页
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.group,
                  title: '分组',
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const GroupPage(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.route,
                  title: '路由',
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const RoutePage(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.settings,
                  title: '设置',
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const SettingsPage(),
                      ),
                    );
                  },
                ),
                const Divider(color: CyberpunkTheme.primaryNeon),
                _buildDrawerItem(
                  context,
                  icon: Icons.bug_report,
                  title: '日志',
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const LogPage(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.dashboard_customize,
                  title: '流量统计',
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const TrafficPage(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.build,
                  title: '工具',
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ToolsPage(),
                      ),
                    );
                  },
                ),
                const Divider(color: CyberpunkTheme.primaryNeon),
                _buildDrawerItem(
                  context,
                  icon: Icons.card_giftcard,
                  title: '套餐购买',
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const PackagePurchasePage(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.info,
                  title: '关于',
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const AboutPage(),
                      ),
                    );
                  },
                ),
                const Divider(color: CyberpunkTheme.primaryNeon),
                _buildDrawerItem(
                  context,
                  icon: Icons.logout,
                  title: '退出登录',
                  onTap: () async {
                    Navigator.of(context).pop();
                    final shouldLogout = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: CyberpunkTheme.darkerBackground,
                        title: const NeonText(
                          text: '退出登录',
                          fontSize: 18,
                        ),
                        content: const NeonText(
                          text: '确定要退出登录吗？',
                          fontSize: 14,
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const NeonText(text: '取消'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const NeonText(
                              text: '确定',
                              neonColor: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    );
                    if (shouldLogout == true) {
                      await ref.read(authStateProvider.notifier).logout();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: CyberpunkTheme.primaryNeon,
      ),
      title: NeonText(
        text: title,
        fontSize: 16,
      ),
      onTap: onTap,
      hoverColor: CyberpunkTheme.primaryNeon.withOpacity(0.1),
    );
  }
}
