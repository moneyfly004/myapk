import 'package:tray_manager/tray_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/node/providers/node_provider.dart';
import '../features/connection/providers/connection_provider.dart';
import '../services/vpn_service.dart' as vpn;
import '../features/connection/providers/routing_provider.dart';
import '../core/utils/logger.dart';

class SystemTrayService with TrayListener {
  static final SystemTrayService _instance = SystemTrayService._internal();
  factory SystemTrayService() => _instance;
  SystemTrayService._internal();

  bool _isInitialized = false;
  WidgetRef? _ref;

  Future<void> initialize(WidgetRef ref) async {
    if (_isInitialized) return;
    
    _ref = ref;

    await trayManager.setIcon(
      'assets/icon.ico', // 需要添加图标文件
    );

    await _updateMenu();
    trayManager.addListener(this);
    
    _isInitialized = true;
  }

  // 更新托盘菜单
  Future<void> _updateMenu() async {
    if (_ref == null) return;
    
    final nodeState = _ref!.read(nodeListProvider);
    final connectionState = _ref!.read(connectionProvider);
    final isConnected = connectionState.status == ConnectionStatus.connected;
    
    final menuItems = <MenuItem>[
      MenuItem(
        key: 'show',
        label: '显示窗口',
      ),
      MenuItem(
        key: 'hide',
        label: '隐藏窗口',
      ),
      MenuItem.separator(),
    ];

    // 节点选择（简化：直接列出节点，不使用子菜单）
    if (nodeState.nodes.isNotEmpty) {
      for (final node in nodeState.nodes.take(8)) { // 最多显示 8 个节点
        final isSelected = node.id == nodeState.selectedNodeId;
        menuItems.add(
          MenuItem(
            key: 'node_${node.id}',
            label: isSelected ? '✓ ${node.name}' : node.name,
          ),
        );
      }
      menuItems.add(MenuItem.separator());
    }

    // 连接/断开按钮
    if (isConnected) {
      menuItems.add(
        MenuItem(
          key: 'disconnect',
          label: '断开连接',
        ),
      );
    } else {
      menuItems.add(
        MenuItem(
          key: 'connect',
          label: nodeState.nodes.isNotEmpty ? '连接' : '连接（无节点）',
        ),
      );
    }

    menuItems.add(MenuItem.separator());
    
    // 路由模式切换（简化：直接列出两个选项）
    final routingMode = _ref!.read(routingModeProvider);
    menuItems.add(
      MenuItem(
        key: 'mode_rules',
        label: routingMode == RoutingMode.rules ? '✓ 规则模式' : '规则模式',
      ),
    );
    menuItems.add(
      MenuItem(
        key: 'mode_global',
        label: routingMode == RoutingMode.global ? '✓ 全局模式' : '全局模式',
      ),
    );

    menuItems.add(MenuItem.separator());
    menuItems.add(
      MenuItem(
        key: 'exit',
        label: '退出',
      ),
    );

    final menu = Menu(items: menuItems);
    await trayManager.setContextMenu(menu);
  }

  Future<void> updateTrayIcon(String iconPath) async {
    await trayManager.setIcon(iconPath);
  }

  Future<void> updateTooltip(String tooltip) async {
    await trayManager.setToolTip(tooltip);
  }

  Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    await trayManager.setTitle('$title: $body');
  }

  @override
  void onTrayIconMouseDown() {
    // 点击托盘图标时的行为
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayIconRightMouseDown() {
    // 右键点击托盘图标
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    if (_ref == null) return;
    
    final key = menuItem.key;
    if (key == null) return;
    
    // 节点选择
    if (key.startsWith('node_')) {
      final nodeId = key.substring(5);
      _ref!.read(nodeListProvider.notifier).selectNode(nodeId);
      _updateMenu();
      return;
    }
    
    switch (key) {
      case 'show':
        // TODO: 显示窗口（需要 window_manager）
        Logger.info('显示窗口');
        break;
      case 'hide':
        // TODO: 隐藏窗口
        Logger.info('隐藏窗口');
        break;
      case 'connect':
        _handleConnect();
        break;
      case 'disconnect':
        _handleDisconnect();
        break;
      case 'mode_rules':
        _ref!.read(routingModeProvider.notifier).state = RoutingMode.rules;
        _updateMenu();
        break;
      case 'mode_global':
        _ref!.read(routingModeProvider.notifier).state = RoutingMode.global;
        _updateMenu();
        break;
      case 'exit':
        // TODO: 退出应用
        Logger.info('退出应用');
        break;
    }
  }

  // 处理连接
  Future<void> _handleConnect() async {
    if (_ref == null) return;
    
    final nodeState = _ref!.read(nodeListProvider);
    if (nodeState.nodes.isEmpty) {
      Logger.warning('没有可用节点');
      return;
    }
    
    final selectedNode = nodeState.nodes.firstWhere(
      (node) => node.id == nodeState.selectedNodeId,
      orElse: () => nodeState.nodes.first,
    );
    
    final routingMode = _ref!.read(routingModeProvider);
    final isGlobalMode = routingMode == RoutingMode.global;
    
    // 生成配置
    final config = vpn.generateSingBoxConfig(
      server: selectedNode.server,
      port: selectedNode.port,
      type: selectedNode.type,
      additionalConfig: selectedNode.config,
      isGlobalMode: isGlobalMode,
    );
    
    // 连接 VPN
    final vpnNotifier = _ref!.read(vpn.vpnServiceProvider.notifier);
    await vpnNotifier.connect(config, isGlobalMode: isGlobalMode);
    
    final connectionNotifier = _ref!.read(connectionProvider.notifier);
    await connectionNotifier.connect(nodeState.selectedNodeId);
    
    await _updateMenu();
  }

  // 处理断开
  Future<void> _handleDisconnect() async {
    if (_ref == null) return;
    
    final vpnNotifier = _ref!.read(vpn.vpnServiceProvider.notifier);
    await vpnNotifier.disconnect();
    
    final connectionNotifier = _ref!.read(connectionProvider.notifier);
    await connectionNotifier.disconnect();
    
    await _updateMenu();
  }

  // 刷新菜单（当状态改变时调用）
  Future<void> refreshMenu() async {
    await _updateMenu();
  }

  void dispose() {
    trayManager.removeListener(this);
    _isInitialized = false;
    _ref = null;
  }
}

