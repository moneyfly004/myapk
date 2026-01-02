import 'package:flutter/material.dart';
import '../../../core/theme/cyberpunk_theme.dart';
import '../../../widgets/cyberpunk/neon_card.dart';
import '../../../widgets/cyberpunk/neon_text.dart';
import '../../../widgets/cyberpunk/grid_background.dart';
import '../../../widgets/cyberpunk/neon_button.dart';

class NetworkTestPage extends StatefulWidget {
  const NetworkTestPage({super.key});

  @override
  State<NetworkTestPage> createState() => _NetworkTestPageState();
}

class _NetworkTestPageState extends State<NetworkTestPage> {
  bool _isTesting = false;
  String _testResult = '';

  Future<void> _runStunTest() async {
    setState(() {
      _isTesting = true;
      _testResult = '正在测试...';
    });

    // TODO: 实现实际的 STUN 测试
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isTesting = false;
      _testResult = 'STUN 测试功能开发中...';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const NeonText(
          text: '网络测试',
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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const NeonText(
                      text: 'STUN 测试',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    const SizedBox(height: 16),
                    NeonButton(
                      onPressed: _isTesting ? null : _runStunTest,
                      child: _isTesting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  CyberpunkTheme.primaryNeon,
                                ),
                              ),
                            )
                          : const Text('开始测试'),
                    ),
                    if (_testResult.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: CyberpunkTheme.darkerBackground,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: CyberpunkTheme.primaryNeon.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          _testResult,
                          style: const TextStyle(
                            color: CyberpunkTheme.textPrimary,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
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

