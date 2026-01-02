import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 优化的霓虹按钮（使用 const 和缓存）
class OptimizedNeonButton extends ConsumerStatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color neonColor;
  final double width;
  final double height;
  final bool isActive;

  const OptimizedNeonButton({
    super.key,
    required this.text,
    this.onPressed,
    this.neonColor = const Color(0xFF00FFFF),
    this.width = 200,
    this.height = 60,
    this.isActive = false,
  });

  @override
  ConsumerState<OptimizedNeonButton> createState() => _OptimizedNeonButtonState();
}

class _OptimizedNeonButtonState extends ConsumerState<OptimizedNeonButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return GestureDetector(
          onTap: widget.onPressed,
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.neonColor.withOpacity(
                  widget.isActive ? _glowAnimation.value : 0.5,
                ),
                width: 2,
              ),
              boxShadow: widget.isActive
                  ? [
                      BoxShadow(
                        color: widget.neonColor.withOpacity(
                          _glowAnimation.value * 0.6,
                        ),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: widget.neonColor.withOpacity(
                          _glowAnimation.value * 0.3,
                        ),
                        blurRadius: 40,
                        spreadRadius: 4,
                      ),
                    ]
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: widget.isActive
                          ? [
                              widget.neonColor.withOpacity(0.2),
                              widget.neonColor.withOpacity(0.1),
                            ]
                          : const [
                              Color(0x4D000000),
                              Color(0x1A000000),
                            ],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      widget.text,
                      style: TextStyle(
                        color: widget.neonColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        shadows: widget.isActive
                            ? [
                                Shadow(
                                  color: widget.neonColor,
                                  blurRadius: 10,
                                ),
                                Shadow(
                                  color: widget.neonColor,
                                  blurRadius: 20,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

