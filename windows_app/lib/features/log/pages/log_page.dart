import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../../core/theme/cyberpunk_theme.dart';
import '../../../widgets/cyberpunk/neon_text.dart';
import '../../../widgets/cyberpunk/grid_background.dart';

class LogPage extends ConsumerStatefulWidget {
  const LogPage({super.key});

  @override
  ConsumerState<LogPage> createState() => _LogPageState();
}

class _LogPageState extends ConsumerState<LogPage> {
  final ScrollController _scrollController = ScrollController();
  final List<String> _logs = [];
  Timer? _refreshTimer;
  bool _autoScroll = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
    // 每 2 秒刷新一次日志
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _loadLogs();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadLogs() {
    // TODO: 从实际的日志系统加载日志
    // 目前使用模拟数据
    setState(() {
      // 保持最新的 100 条日志
      if (_logs.length > 100) {
        _logs.removeRange(0, _logs.length - 100);
      }
    });

    if (_autoScroll && _scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void _clearLogs() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: CyberpunkTheme.darkerBackground,
        title: const NeonText(text: '清除日志', fontSize: 18),
        content: const Text(
          '确定要清除所有日志吗？',
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
              setState(() {
                _logs.clear();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('日志已清除')),
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

  Color _getLogColor(String log) {
    if (log.contains('ERROR') || log.contains('Error')) {
      return Colors.red;
    } else if (log.contains('WARN') || log.contains('Warning')) {
      return Colors.orange;
    } else if (log.contains('INFO') || log.contains('Info')) {
      return Colors.green;
    } else if (log.contains('DEBUG') || log.contains('Debug')) {
      return Colors.blue;
    }
    return CyberpunkTheme.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const NeonText(
          text: '日志',
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        backgroundColor: CyberpunkTheme.darkerBackground,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _autoScroll ? Icons.vertical_align_bottom : Icons.vertical_align_center,
              color: CyberpunkTheme.primaryNeon,
            ),
            onPressed: () {
              setState(() {
                _autoScroll = !_autoScroll;
              });
            },
            tooltip: _autoScroll ? '关闭自动滚动' : '开启自动滚动',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: CyberpunkTheme.primaryNeon),
            onPressed: _loadLogs,
            tooltip: '刷新',
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: _clearLogs,
            tooltip: '清除日志',
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
          child: _logs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.bug_report,
                        size: 64,
                        color: CyberpunkTheme.primaryNeon.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      NeonText(
                        text: '暂无日志',
                        fontSize: 16,
                        neonColor: CyberpunkTheme.textSecondary,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    final log = _logs[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: SelectableText(
                        log,
                        style: TextStyle(
                          color: _getLogColor(log),
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

