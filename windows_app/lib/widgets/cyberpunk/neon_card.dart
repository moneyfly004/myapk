import 'package:flutter/material.dart';
import 'dart:ui';

class NeonCard extends StatelessWidget {
  final Widget child;
  final Color neonColor;
  final EdgeInsets? padding;
  final double? elevation;
  final bool showGlow;

  const NeonCard({
    super.key,
    required this.child,
    this.neonColor = const Color(0xFF00FFFF),
    this.padding,
    this.elevation,
    this.showGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: neonColor.withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: showGlow
            ? [
                BoxShadow(
                  color: neonColor.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: neonColor.withOpacity(0.1),
                  blurRadius: 40,
                  spreadRadius: 4,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14.5),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E).withOpacity(0.8),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  neonColor.withOpacity(0.1),
                  Colors.transparent,
                  Colors.transparent,
                ],
              ),
            ),
            padding: padding ?? const EdgeInsets.all(20.0),
            child: child,
          ),
        ),
      ),
    );
  }
}

