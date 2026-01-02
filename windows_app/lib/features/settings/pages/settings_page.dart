import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import '../../../core/theme/cyberpunk_theme.dart';
import '../../../widgets/cyberpunk/neon_card.dart';
import '../../../widgets/cyberpunk/neon_text.dart';
import '../../../widgets/cyberpunk/grid_background.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const NeonText(
          text: '设置',
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        backgroundColor: CyberpunkTheme.darkerBackground,
        elevation: 0,
      ),
      body: GridBackground(
        gridColor: CyberpunkTheme.primaryNeon,
        gridSize: 20.0,
        child: Container(
          decoration: const BoxDecoration(
            gradient: CyberpunkGradients.backgroundGradient,
          ),
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // 通用设置
              _buildCategory(
                context,
                title: '通用设置',
                children: [
                  _buildSwitchTile(
                    context,
                    title: '自动连接',
                    value: settings.isAutoConnect,
                    onChanged: (value) => settingsNotifier.updateSetting(
                      SettingsKeys.isAutoConnect,
                      value,
                    ),
                  ),
                  _buildDropdownTile<int>(
                    context,
                    title: '主题',
                    value: settings.appTheme,
                    items: const [
                      DropdownMenuItem(value: 0, child: Text('默认')),
                      DropdownMenuItem(value: 1, child: Text('红色')),
                      DropdownMenuItem(value: 2, child: Text('粉色')),
                      DropdownMenuItem(value: 3, child: Text('紫色')),
                      DropdownMenuItem(value: 4, child: Text('蓝色')),
                      DropdownMenuItem(value: 5, child: Text('绿色')),
                    ],
                    onChanged: (value) => settingsNotifier.updateSetting(
                      SettingsKeys.appTheme,
                      value!,
                    ),
                  ),
                  _buildDropdownTile<int>(
                    context,
                    title: '夜间模式',
                    value: settings.nightTheme,
                    items: const [
                      DropdownMenuItem(value: 0, child: Text('跟随系统')),
                      DropdownMenuItem(value: 1, child: Text('开启')),
                      DropdownMenuItem(value: 2, child: Text('关闭')),
                    ],
                    onChanged: (value) => settingsNotifier.updateSetting(
                      SettingsKeys.nightTheme,
                      value!,
                    ),
                  ),
                  _buildDropdownTile<String>(
                    context,
                    title: '服务模式',
                    value: settings.serviceMode,
                    items: const [
                      DropdownMenuItem(value: 'vpn', child: Text('VPN')),
                      DropdownMenuItem(value: 'proxy', child: Text('代理')),
                    ],
                    onChanged: (value) => settingsNotifier.updateSetting(
                      SettingsKeys.serviceMode,
                      value!,
                    ),
                  ),
                  _buildTextFieldTile(
                    context,
                    title: 'MTU',
                    value: settings.mtu.toString(),
                    onChanged: (value) {
                      final intValue = int.tryParse(value) ?? 9000;
                      settingsNotifier.updateSetting(SettingsKeys.mtu, intValue);
                    },
                  ),
                  _buildTextFieldTile(
                    context,
                    title: '速度更新间隔 (ms)',
                    value: settings.speedInterval.toString(),
                    onChanged: (value) {
                      final intValue = int.tryParse(value) ?? 1000;
                      settingsNotifier.updateSetting(SettingsKeys.speedInterval, intValue);
                    },
                  ),
                  _buildSwitchTile(
                    context,
                    title: '流量统计',
                    value: settings.profileTrafficStatistics,
                    onChanged: (value) => settingsNotifier.updateSetting(
                      SettingsKeys.profileTrafficStatistics,
                      value,
                    ),
                  ),
                  _buildSwitchTile(
                    context,
                    title: '显示直连速度',
                    value: settings.showDirectSpeed,
                    onChanged: (value) => settingsNotifier.updateSetting(
                      SettingsKeys.showDirectSpeed,
                      value,
                    ),
                  ),
                  _buildDropdownTile<int>(
                    context,
                    title: '日志级别',
                    value: settings.logLevel,
                    items: const [
                      DropdownMenuItem(value: 0, child: Text('无')),
                      DropdownMenuItem(value: 1, child: Text('错误')),
                      DropdownMenuItem(value: 2, child: Text('警告')),
                      DropdownMenuItem(value: 3, child: Text('信息')),
                      DropdownMenuItem(value: 4, child: Text('调试')),
                    ],
                    onChanged: (value) => settingsNotifier.updateSetting(
                      SettingsKeys.logLevel,
                      value!,
                    ),
                  ),
                  _buildTextFieldTile(
                    context,
                    title: '自定义配置',
                    value: settings.globalCustomConfig,
                    onChanged: (value) => settingsNotifier.updateSetting(
                      SettingsKeys.globalCustomConfig,
                      value,
                    ),
                    maxLines: 5,
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // 路由设置
              _buildCategory(
                context,
                title: '路由设置',
                children: [
                  _buildSwitchTile(
                    context,
                    title: '代理应用',
                    value: settings.proxyApps,
                    onChanged: (value) => settingsNotifier.updateSetting(
                      SettingsKeys.proxyApps,
                      value,
                    ),
                  ),
                  _buildSwitchTile(
                    context,
                    title: '绕过局域网',
                    value: settings.bypassLan,
                    onChanged: (value) => settingsNotifier.updateSetting(
                      SettingsKeys.bypassLan,
                      value,
                    ),
                  ),
                  _buildSwitchTile(
                    context,
                    title: '在核心中绕过局域网',
                    value: settings.bypassLanInCore,
                    onChanged: (value) => settingsNotifier.updateSetting(
                      SettingsKeys.bypassLanInCore,
                      value,
                    ),
                  ),
                  _buildDropdownTile<int>(
                    context,
                    title: '流量嗅探',
                    value: settings.trafficSniffing,
                    items: const [
                      DropdownMenuItem(value: 0, child: Text('禁用')),
                      DropdownMenuItem(value: 1, child: Text('启用')),
                      DropdownMenuItem(value: 2, child: Text('仅嗅探域名')),
                    ],
                    onChanged: (value) => settingsNotifier.updateSetting(
                      SettingsKeys.trafficSniffing,
                      value!,
                    ),
                  ),
                  _buildSwitchTile(
                    context,
                    title: '解析目标',
                    value: settings.resolveDestination,
                    onChanged: (value) => settingsNotifier.updateSetting(
                      SettingsKeys.resolveDestination,
                      value,
                    ),
                  ),
                  _buildDropdownTile<int>(
                    context,
                    title: 'IPv6 模式',
                    value: settings.ipv6Mode,
                    items: const [
                      DropdownMenuItem(value: 0, child: Text('禁用')),
                      DropdownMenuItem(value: 1, child: Text('启用')),
                      DropdownMenuItem(value: 2, child: Text('仅直连')),
                    ],
                    onChanged: (value) => settingsNotifier.updateSetting(
                      SettingsKeys.ipv6Mode,
                      value!,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // DNS设置
              _buildCategory(
                context,
                title: 'DNS 设置',
                children: [
                  _buildTextFieldTile(
                    context,
                    title: '远程 DNS',
                    value: settings.remoteDns,
                    onChanged: (value) => settingsNotifier.updateSetting(
                      SettingsKeys.remoteDns,
                      value,
                    ),
                  ),
                  _buildTextFieldTile(
                    context,
                    title: '直连 DNS',
                    value: settings.directDns,
                    onChanged: (value) => settingsNotifier.updateSetting(
                      SettingsKeys.directDns,
                      value,
                    ),
                  ),
                  _buildSwitchTile(
                    context,
                    title: '启用 DNS 路由',
                    value: settings.enableDnsRouting,
                    onChanged: (value) => settingsNotifier.updateSetting(
                      SettingsKeys.enableDnsRouting,
                      value,
                    ),
                  ),
                  _buildSwitchTile(
                    context,
                    title: '启用 FakeDNS',
                    value: settings.enableFakeDns,
                    onChanged: (value) => settingsNotifier.updateSetting(
                      SettingsKeys.enableFakeDns,
                      value,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // 入站设置
              _buildCategory(
                context,
                title: '入站设置',
                children: [
                  _buildTextFieldTile(
                    context,
                    title: '混合端口',
                    value: settings.mixedPort.toString(),
                    onChanged: (value) {
                      final intValue = int.tryParse(value) ?? 2080;
                      settingsNotifier.updateSetting(SettingsKeys.mixedPort, intValue);
                    },
                  ),
                  _buildSwitchTile(
                    context,
                    title: '追加 HTTP 代理',
                    value: settings.appendHttpProxy,
                    onChanged: (value) => settingsNotifier.updateSetting(
                      SettingsKeys.appendHttpProxy,
                      value,
                    ),
                  ),
                  _buildSwitchTile(
                    context,
                    title: '允许访问',
                    value: settings.allowAccess,
                    onChanged: (value) => settingsNotifier.updateSetting(
                      SettingsKeys.allowAccess,
                      value,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // 其他设置
              _buildCategory(
                context,
                title: '其他设置',
                children: [
                  _buildTextFieldTile(
                    context,
                    title: '连接测试 URL',
                    value: settings.connectionTestURL,
                    onChanged: (value) => settingsNotifier.updateSetting(
                      SettingsKeys.connectionTestURL,
                      value,
                    ),
                  ),
                  _buildSwitchTile(
                    context,
                    title: '启用 Clash API',
                    value: settings.enableClashAPI,
                    onChanged: (value) => settingsNotifier.updateSetting(
                      SettingsKeys.enableClashAPI,
                      value,
                    ),
                  ),
                  _buildSwitchTile(
                    context,
                    title: '网络变化重置连接',
                    value: settings.networkChangeResetConnections,
                    onChanged: (value) => settingsNotifier.updateSetting(
                      SettingsKeys.networkChangeResetConnections,
                      value,
                    ),
                  ),
                  _buildSwitchTile(
                    context,
                    title: '唤醒重置连接',
                    value: settings.wakeResetConnections,
                    onChanged: (value) => settingsNotifier.updateSetting(
                      SettingsKeys.wakeResetConnections,
                      value,
                    ),
                  ),
                  _buildSwitchTile(
                    context,
                    title: '全局允许不安全',
                    value: settings.globalAllowInsecure,
                    onChanged: (value) => settingsNotifier.updateSetting(
                      SettingsKeys.globalAllowInsecure,
                      value,
                    ),
                  ),
                  _buildSwitchTile(
                    context,
                    title: '请求时允许不安全',
                    value: settings.allowInsecureOnRequest,
                    onChanged: (value) => settingsNotifier.updateSetting(
                      SettingsKeys.allowInsecureOnRequest,
                      value,
                    ),
                  ),
                  _buildDropdownTile<String>(
                    context,
                    title: 'TLS 版本',
                    value: settings.appTLSVersion,
                    items: const [
                      DropdownMenuItem(value: '1.0', child: Text('1.0')),
                      DropdownMenuItem(value: '1.1', child: Text('1.1')),
                      DropdownMenuItem(value: '1.2', child: Text('1.2')),
                      DropdownMenuItem(value: '1.3', child: Text('1.3')),
                    ],
                    onChanged: (value) => settingsNotifier.updateSetting(
                      SettingsKeys.appTLSVersion,
                      value!,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategory(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return NeonCard(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NeonText(
            text: title,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            neonColor: CyberpunkTheme.primaryNeon,
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      title: NeonText(
        text: title,
        fontSize: 14,
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: CyberpunkTheme.primaryNeon,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  Widget _buildDropdownTile<T>(
    BuildContext context, {
    required String title,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return ListTile(
      title: NeonText(
        text: title,
        fontSize: 14,
      ),
      trailing: DropdownButton<T>(
        value: value,
        items: items,
        onChanged: onChanged,
        dropdownColor: CyberpunkTheme.darkerBackground,
        style: const TextStyle(color: CyberpunkTheme.textPrimary),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  Widget _buildTextFieldTile(
    BuildContext context, {
    required String title,
    required String value,
    required ValueChanged<String> onChanged,
    int maxLines = 1,
  }) {
    return ListTile(
      title: NeonText(
        text: title,
        fontSize: 14,
      ),
      subtitle: TextField(
        controller: TextEditingController(text: value),
        onChanged: onChanged,
        maxLines: maxLines,
        style: const TextStyle(color: CyberpunkTheme.textPrimary),
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: CyberpunkTheme.primaryNeon.withOpacity(0.5),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: CyberpunkTheme.primaryNeon.withOpacity(0.5),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: CyberpunkTheme.primaryNeon,
              width: 2,
            ),
          ),
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
}

