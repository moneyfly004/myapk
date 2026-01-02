import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../../core/theme/cyberpunk_theme.dart';
import '../../../widgets/cyberpunk/neon_card.dart';
import '../../../widgets/cyberpunk/neon_text.dart';
import '../../../widgets/cyberpunk/grid_background.dart';
import '../../../widgets/cyberpunk/neon_button.dart';

class BackupPage extends StatefulWidget {
  const BackupPage({super.key});

  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  bool _backupConfigurations = true;
  bool _backupRules = true;
  bool _backupSettings = true;

  Future<void> _exportBackup() async {
    try {
      // TODO: 实现实际的备份导出
      final result = await FilePicker.platform.saveFile(
        dialogTitle: '保存备份文件',
        fileName: 'nekobox_backup_${DateTime.now().toIso8601String()}.json',
      );

      if (result != null) {
        // TODO: 生成备份文件并保存
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('备份导出功能开发中...')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导出失败: $e')),
      );
    }
  }

  Future<void> _importBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        // TODO: 实现实际的备份导入
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('备份导入功能开发中...')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导入失败: $e')),
      );
    }
  }

  void _resetSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: CyberpunkTheme.darkerBackground,
        title: const NeonText(text: '重置设置', fontSize: 18),
        content: const Text(
          '确定要重置所有设置吗？此操作不可恢复！',
          style: TextStyle(color: CyberpunkTheme.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const NeonText(text: '取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: 重置设置
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('重置功能开发中...')),
              );
            },
            child: const NeonText(
              text: '确定',
              neonColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const NeonText(
          text: '备份与恢复',
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const NeonText(
                      text: '导出备份',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      title: const NeonText(text: '配置', fontSize: 14),
                      value: _backupConfigurations,
                      onChanged: (value) {
                        setState(() {
                          _backupConfigurations = value ?? true;
                        });
                      },
                      activeColor: CyberpunkTheme.primaryNeon,
                    ),
                    CheckboxListTile(
                      title: const NeonText(text: '规则', fontSize: 14),
                      value: _backupRules,
                      onChanged: (value) {
                        setState(() {
                          _backupRules = value ?? true;
                        });
                      },
                      activeColor: CyberpunkTheme.primaryNeon,
                    ),
                    CheckboxListTile(
                      title: const NeonText(text: '设置', fontSize: 14),
                      value: _backupSettings,
                      onChanged: (value) {
                        setState(() {
                          _backupSettings = value ?? true;
                        });
                      },
                      activeColor: CyberpunkTheme.primaryNeon,
                    ),
                    const SizedBox(height: 16),
                    NeonButton(
                      onPressed: _exportBackup,
                      child: const Text('导出备份'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              NeonCard(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const NeonText(
                      text: '导入备份',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    const SizedBox(height: 16),
                    NeonButton(
                      onPressed: _importBackup,
                      child: const Text('选择备份文件'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              NeonCard(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const NeonText(
                      text: '重置',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    const SizedBox(height: 8),
                    const NeonText(
                      text: '重置所有设置到默认值',
                      fontSize: 12,
                      neonColor: CyberpunkTheme.textSecondary,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _resetSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('重置设置'),
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

