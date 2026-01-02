import 'package:flutter/material.dart';

class CyberpunkTheme {
  // 赛博朋克配色方案
  static const Color primaryNeon = Color(0xFF00FFFF); // 青色霓虹
  static const Color secondaryNeon = Color(0xFFFF00FF); // 粉色霓虹
  static const Color accentNeon = Color(0xFF00FF00); // 绿色霓虹
  static const Color warningNeon = Color(0xFFFFD700); // 金色霓虹
  
  static const Color darkBackground = Color(0xFF0A0A0F);
  static const Color darkerBackground = Color(0xFF050508);
  static const Color cardBackground = Color(0xFF1A1A2E);
  static const Color surfaceBackground = Color(0xFF16213E);
  
  static const Color textPrimary = Color(0xFFE0E0E0);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textNeon = Color(0xFF00FFFF);

  // 赛博朋克主题数据
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      // 颜色方案
      colorScheme: const ColorScheme.dark(
        primary: primaryNeon,
        secondary: secondaryNeon,
        tertiary: accentNeon,
        surface: cardBackground,
        error: Color(0xFFFF1744),
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: textPrimary,
        onError: Colors.white,
      ),
      
      // 脚手架背景
      scaffoldBackgroundColor: darkBackground,
      
      // 卡片主题
      cardTheme: CardTheme(
        color: cardBackground,
        elevation: 8,
        shadowColor: primaryNeon.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: primaryNeon.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      
      // 按钮主题
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryNeon,
          foregroundColor: Colors.black,
          elevation: 8,
          shadowColor: primaryNeon.withOpacity(0.5),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
      
      // 文本主题
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: textPrimary,
          fontSize: 32,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
        displayMedium: TextStyle(
          color: textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
        displaySmall: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        ),
        headlineMedium: TextStyle(
          color: textNeon,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
        titleLarge: TextStyle(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: textPrimary,
          fontSize: 14,
        ),
        bodyMedium: TextStyle(
          color: textSecondary,
          fontSize: 12,
        ),
      ),
      
      // 输入框主题
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: primaryNeon.withOpacity(0.5),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: primaryNeon.withOpacity(0.3),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: primaryNeon,
            width: 2,
          ),
        ),
        labelStyle: const TextStyle(
          color: textSecondary,
        ),
        hintStyle: TextStyle(
          color: textSecondary.withOpacity(0.7),
        ),
      ),
      
      // 进度条主题
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryNeon,
        linearTrackColor: surfaceBackground,
      ),
      
      // 对话框主题
      dialogTheme: DialogTheme(
        backgroundColor: cardBackground,
        elevation: 16,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: primaryNeon.withOpacity(0.5),
            width: 2,
          ),
        ),
      ),
      
      // 应用栏主题
      appBarTheme: const AppBarTheme(
        backgroundColor: darkerBackground,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textNeon,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
        iconTheme: IconThemeData(
          color: primaryNeon,
        ),
      ),
    );
  }
  
  // 霓虹发光效果装饰
  static BoxDecoration get neonGlowDecoration {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: primaryNeon.withOpacity(0.5),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: primaryNeon.withOpacity(0.3),
          blurRadius: 20,
          spreadRadius: 2,
        ),
      ],
    );
  }
  
  // 网格背景装饰
  static BoxDecoration get gridBackgroundDecoration {
    return BoxDecoration(
      color: darkBackground,
      image: DecorationImage(
        image: _createGridPattern(),
        repeat: ImageRepeat.repeat,
        opacity: 0.1,
      ),
    );
  }
  
  // 创建网格图案
  static ImageProvider _createGridPattern() {
    // 这里返回一个网格图案，实际实现可以使用 CustomPainter
    return const AssetImage('assets/grid_pattern.png');
  }
}

// 赛博朋克风格的渐变
class CyberpunkGradients {
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF00FFFF),
      Color(0xFF0080FF),
      Color(0xFF8000FF),
    ],
  );
  
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF0A0A0F),
      Color(0xFF050508),
      Color(0xFF0A0A0F),
    ],
  );
  
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1A1A2E),
      Color(0xFF16213E),
      Color(0xFF0F3460),
    ],
  );
}

