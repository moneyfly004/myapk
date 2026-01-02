import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../../core/theme/cyberpunk_theme.dart';
import '../cyberpunk/neon_text.dart';

/// 自定义标题栏（支持拖拽、关闭、最大化、最小化）
class CustomTitleBar extends StatefulWidget {
  final String title;
  final Widget? leading;
  final List<Widget>? actions;

  const CustomTitleBar({
    super.key,
    required this.title,
    this.leading,
    this.actions,
  });

  @override
  State<CustomTitleBar> createState() => _CustomTitleBarState();
}

class _CustomTitleBarState extends State<CustomTitleBar> {
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    _checkMaximized();
  }

  Future<void> _checkMaximized() async {
    final isMaximized = await windowManager.isMaximized();
    if (mounted) {
      setState(() {
        _isMaximized = isMaximized;
      });
    }
  }

  Future<void> _handleMinimize() async {
    try {
      await windowManager.minimize();
    } catch (e) {
      logger.Logger.error('最小化窗口失败', e);
    }
  }

  Future<void> _handleMaximize() async {
    try {
      if (_isMaximized) {
        await windowManager.restore();
      } else {
        await windowManager.maximize();
      }
      await _checkMaximized();
    } catch (e) {
      logger.Logger.error('最大化/还原窗口失败', e);
    }
  }

  Future<void> _handleClose() async {
    try {
      // 最小化到托盘而不是关闭
      await windowManager.hide();
    } catch (e) {
      logger.Logger.error('隐藏窗口失败', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanStart: (_) {
        // 开始拖拽
        windowManager.startDragging();
      },
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: CyberpunkTheme.darkerBackground,
          border: Border(
            bottom: BorderSide(
              color: CyberpunkTheme.primaryNeon.withOpacity(0.3),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            // 左侧：标题和图标
            if (widget.leading != null) ...[
              widget.leading!,
              const SizedBox(width: 8),
            ],
            Expanded(
              child: NeonText(
                text: widget.title,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            // 中间：自定义操作
            if (widget.actions != null) ...widget.actions!,
            // 右侧：窗口控制按钮
            _buildWindowButton(
              icon: Icons.remove,
              onPressed: _handleMinimize,
              tooltip: '最小化',
            ),
            _buildWindowButton(
              icon: _isMaximized ? Icons.filter_none : Icons.crop_free,
              onPressed: _handleMaximize,
              tooltip: _isMaximized ? '还原' : '最大化',
            ),
            _buildWindowButton(
              icon: Icons.close,
              onPressed: _handleClose,
              tooltip: '关闭',
              isClose: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWindowButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    bool isClose = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 16,
              color: isClose
                  ? Colors.red.withOpacity(0.8)
                  : CyberpunkTheme.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

