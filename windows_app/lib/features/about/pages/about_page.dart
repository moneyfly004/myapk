import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus';
import '../../../core/theme/cyberpunk_theme.dart';
import '../../../widgets/cyberpunk/neon_card.dart';
import '../../../widgets/cyberpunk/neon_text.dart';
import '../../../widgets/cyberpunk/grid_background.dart';
import '../../../core/config/version_config.dart';

class AboutPage extends ConsumerStatefulWidget {
  const AboutPage({super.key});

  @override
  ConsumerState<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends ConsumerState<AboutPage> {
  String _version = '1.0.0';
  String _buildNumber = '1';

  @override
  void initState() {
    super.initState();
    _loadVersionInfo();
  }

  Future<void> _loadVersionInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _version = packageInfo.version;
        _buildNumber = packageInfo.buildNumber;
      });
    } catch (e) {
      // 使用默认值
    }
  }

  Future<void> _checkUpdate() async {
    try {
      // TODO: 实现更新检查
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('更新检查功能开发中...')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('检查更新失败: $e')),
      );
    }
  }

  Future<void> _openGitHub() async {
    final uri = Uri.parse('https://github.com/moneyfly004/myapk');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const NeonText(
          text: '关于',
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
              NeonCard(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.vpn_key,
                      size: 64,
                      color: CyberpunkTheme.primaryNeon,
                    ),
                    const SizedBox(height: 16),
                    const NeonText(
                      text: 'NekoBox for Windows',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    const SizedBox(height: 8),
                    NeonText(
                      text: '版本 $_version (Build $_buildNumber)',
                      fontSize: 14,
                      neonColor: CyberpunkTheme.textSecondary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              NeonCard(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const NeonText(
                      text: '项目信息',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(
                        Icons.code,
                        color: CyberpunkTheme.primaryNeon,
                      ),
                      title: const NeonText(text: 'GitHub', fontSize: 14),
                      subtitle: const NeonText(
                        text: 'https://github.com/moneyfly004/myapk',
                        fontSize: 12,
                        neonColor: CyberpunkTheme.textSecondary,
                      ),
                      onTap: _openGitHub,
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.update,
                        color: CyberpunkTheme.primaryNeon,
                      ),
                      title: const NeonText(text: '检查更新', fontSize: 14),
                      onTap: _checkUpdate,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              NeonCard(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const NeonText(
                      text: '版本信息',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    const SizedBox(height: 16),
                    FutureBuilder<String>(
                      future: VersionConfig.instance.getVersion(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return ListTile(
                            leading: const Icon(
                              Icons.layers,
                              color: CyberpunkTheme.primaryNeon,
                            ),
                            title: const NeonText(
                              text: 'sing-box 版本',
                              fontSize: 14,
                            ),
                            subtitle: NeonText(
                              text: snapshot.data ?? '未知',
                              fontSize: 12,
                              neonColor: CyberpunkTheme.textSecondary,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

