import 'package:flutter/material.dart';

class NeonText extends StatelessWidget {
  final String text;
  final double fontSize;
  final Color neonColor;
  final FontWeight fontWeight;
  final double letterSpacing;

  const NeonText({
    super.key,
    required this.text,
    this.fontSize = 16,
    this.neonColor = const Color(0xFF00FFFF),
    this.fontWeight = FontWeight.normal,
    this.letterSpacing = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
        color: neonColor,
        shadows: [
          Shadow(
            color: neonColor,
            blurRadius: 10,
          ),
          Shadow(
            color: neonColor,
            blurRadius: 20,
          ),
          Shadow(
            color: neonColor,
            blurRadius: 30,
          ),
        ],
      ),
    );
  }
}

