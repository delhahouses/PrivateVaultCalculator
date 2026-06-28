import 'dart:ui';
import 'package:flutter/material';

class AppTheme {
  static const Color cardDarkBackground = Color(0x331C1C1E);
  static const Color cardLightBackground = Color(0xCCFFFFFF);

  // Core Accent Colors
  static final Map<String, Color> accentColors = {
    'Classic Blue': const Color(0xFF2F80ED),
    'Deep Purple': const Color(0xFF9B51E0),
    'Teal Wave': const Color(0xFF00B1B0),
    'Amber Gold': const Color(0xFFF2C94C),
    'Emerald Slate': const Color(0xFF27AE60),
    'Rose Luxury': const Color(0xFFEB5757),
  };

  static ThemeData getTheme(String accentName, bool isDark) {
    final Color accentColor = accentColors[accentName] ?? const Color(0xFF2F80ED);
    
    if (isDark) {
      return ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: accentColor,
          brightness: Brightness.dark,
          primary: accentColor,
          surface: const Color(0xFF121214),
          background: const Color(0xFF0B0B0C),
        ),
        cardTheme: const CardTheme(
          color: cardDarkBackground,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w700),
          titleLarge: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600),
          bodyMedium: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w400),
        ),
      );
    } else {
      return ThemeData.light(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: accentColor,
          brightness: Brightness.light,
          primary: accentColor,
          surface: const Color(0xFFF4F6F8),
          background: const Color(0xFFFFFFFF),
        ),
        cardTheme: const CardTheme(
          color: cardLightBackground,
          elevation: 2,
          shadowColor: Color(0x1F000000),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w700),
          titleLarge: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600),
          bodyMedium: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w400),
        ),
      );
    }
  }

  // Premium Glassmorphism Decoration
  static BoxDecoration glassBoxDecoration({
    required bool isDark,
    double radius = 16.0,
    double borderOpacity = 0.1,
  }) {
    return BoxDecoration(
      color: isDark 
          ? const Color(0xFF1E1E22).withOpacity(0.4) 
          : const Color(0xFFFFFFFF).withOpacity(0.7),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: (isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000))
            .withOpacity(borderOpacity),
        width: 1.0,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  // Beautiful Gradient backgrounds
  static LinearGradient bgGradient(bool isDark) {
    if (isDark) {
      return const LinearGradient(
        colors: [Color(0xFF0B0B0C), Color(0xFF1A1A24)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else {
      return const LinearGradient(
        colors: [Color(0xFFF7F9FC), Color(0xFFE8EDF5)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
  }
}
