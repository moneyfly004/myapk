import 'package:tray_manager/tray_manager.dart';

class SystemTrayService with TrayListener {
  static final SystemTrayService _instance = SystemTrayService._internal();
  factory SystemTrayService() => _instance;
  SystemTrayService._internal();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    await trayManager.setIcon(
      'assets/icon.ico', // 需要添加图标文件
    );

    final menu = Menu(
      items: [
        MenuItem(
          key: 'show',
          label: '显示窗口',
        ),
        MenuItem(
          key: 'hide',
          label: '隐藏窗口',
        ),
        MenuItem.separator(),
        MenuItem(
          key: 'connect',
          label: '连接',
        ),
        MenuItem(
          key: 'disconnect',
          label: '断开',
        ),
        MenuItem.separator(),
        MenuItem(
          key: 'exit',
          label: '退出',
        ),
      ],
    );

    await trayManager.setContextMenu(menu);
    trayManager.addListener(this);
    
    _isInitialized = true;
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
    switch (menuItem.key) {
      case 'show':
        // TODO: 显示窗口
        break;
      case 'hide':
        // TODO: 隐藏窗口
        break;
      case 'connect':
        // TODO: 连接
        break;
      case 'disconnect':
        // TODO: 断开
        break;
      case 'exit':
        // TODO: 退出应用
        break;
    }
  }

  void dispose() {
    trayManager.removeListener(this);
    _isInitialized = false;
  }
}

