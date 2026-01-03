import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/cyberpunk_theme.dart';
import '../../../widgets/cyberpunk/neon_card.dart';
import '../../../widgets/cyberpunk/neon_text.dart';
import '../../../widgets/cyberpunk/grid_background.dart';
import '../../../features/settings/providers/settings_provider.dart';

class TrafficPage extends ConsumerStatefulWidget {
  const TrafficPage({super.key});

  @override
  ConsumerState<TrafficPage> createState() => _TrafficPageState();
}

class _TrafficPageState extends ConsumerState<TrafficPage> {
  String _yacdUrl = 'http://127.0.0.1:9090/ui/#/';

  @override
  void initState() {
    super.initState();
    _loadYacdUrl();
  }

  Future<void> _loadYacdUrl() async {
    // TODO: 从设置中加载 YACD URL
        // 默认使用本地 Clash API
    setState(() {
      _yacdUrl = 'http://127.0.0.1:9090/ui/#/';
    });
  }

  void _showSetUrlDialog(BuildContext context) {
    final controller = TextEditingController(text: _yacdUrl);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: CyberpunkTheme.darkerBackground,
        title: const NeonText(text: '设置面板 URL', fontSize: 18),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: CyberpunkTheme.textPrimary),
          decoration: InputDecoration(
            labelText: 'YACD URL',
            labelStyle: const TextStyle(color: CyberpunkTheme.textSecondary),
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
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const NeonText(text: '取消'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _yacdUrl = controller.text;
              });
              Navigator.of(context).pop();
              // TODO: 保存到设置
            },
            child: const NeonText(
              text: '确定',
              neonColor: CyberpunkTheme.primaryNeon,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    if (!settings.enableClashAPI) {
      return Scaffold(
        appBar: AppBar(
          title: const NeonText(
            text: '流量统计',
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
            child: Center(
              child: NeonCard(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.dashboard_customize,
                      size: 64,
                      color: CyberpunkTheme.primaryNeon.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    const NeonText(
                      text: 'Clash API 未启用',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    const SizedBox(height: 8),
                    const NeonText(
                      text: '请在设置中启用 Clash API 以使用流量统计功能',
                      fontSize: 14,
                      neonColor: CyberpunkTheme.textSecondary,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        // TODO: 导航到设置页面
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CyberpunkTheme.primaryNeon,
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('前往设置'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const NeonText(
          text: '流量统计',
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        backgroundColor: CyberpunkTheme.darkerBackground,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: CyberpunkTheme.primaryNeon),
            onPressed: () => _showSetUrlDialog(context),
            tooltip: '设置 URL',
          ),
          IconButton(
            icon: const Icon(Icons.open_in_browser, color: CyberpunkTheme.primaryNeon),
            onPressed: () async {
              final uri = Uri.parse(_yacdUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('无法打开 URL')),
                );
              }
            },
            tooltip: '在浏览器中打开',
          ),
        ],
      ),
      body: GridBackground(
        gridColor: CyberpunkTheme.primaryNeon,
        gridSize: 20.0,
        child: Container(
          decoration: const BoxDecoration(
            gradient: CyberpunkGradients.backgroundGradient,
          ),
          child: Center(
            child: NeonCard(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.dashboard_customize,
                    size: 64,
                    color: CyberpunkTheme.primaryNeon.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  const NeonText(
                    text: '流量统计面板',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  const SizedBox(height: 8),
                  NeonText(
                    text: 'URL: $_yacdUrl',
                    fontSize: 12,
                    neonColor: CyberpunkTheme.textSecondary,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      final uri = Uri.parse(_yacdUrl);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('无法打开 URL')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CyberpunkTheme.primaryNeon,
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('在浏览器中打开'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

