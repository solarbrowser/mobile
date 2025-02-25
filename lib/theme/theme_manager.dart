import 'package:flutter/material.dart';

enum ThemeType {
  system,
  light,
  dark,
  tokyoNight,
  solarizedLight,
  dracula,
}

class ThemeColors {
  final Color backgroundColor;
  final Color surfaceColor;
  final Color textColor;
  final Color textSecondaryColor;
  final Color primaryColor;
  final Color accentColor;

  const ThemeColors({
    required this.backgroundColor,
    required this.surfaceColor,
    required this.textColor,
    required this.textSecondaryColor,
    required this.primaryColor,
    required this.accentColor,
  });
}

class ThemeManager {
  static ThemeType _currentTheme = ThemeType.solarizedLight;
  static bool _isDarkMode = false;

  static final Map<ThemeType, ThemeColors> _themes = {
    ThemeType.light: ThemeColors(
      backgroundColor: Colors.white,
      surfaceColor: Colors.grey[100]!,
      textColor: Colors.black,
      textSecondaryColor: Colors.black87,
      primaryColor: Colors.blue,
      accentColor: Colors.blue[700]!,
    ),
    ThemeType.dark: ThemeColors(
      backgroundColor: Colors.black,
      surfaceColor: Colors.grey[900]!,
      textColor: Colors.white,
      textSecondaryColor: Colors.white70,
      primaryColor: Colors.blue,
      accentColor: Colors.blue[300]!,
    ),
    ThemeType.tokyoNight: ThemeColors(
      backgroundColor: const Color(0xFF1A1B26),
      surfaceColor: const Color(0xFF24283B),
      textColor: const Color(0xFFA9B1D6),
      textSecondaryColor: const Color(0xFF787C99),
      primaryColor: const Color(0xFF7AA2F7),
      accentColor: const Color(0xFFBB9AF7),
    ),
    ThemeType.solarizedLight: ThemeColors(
      backgroundColor: const Color(0xFFFDF6E3),
      surfaceColor: const Color(0xFFEEE8D5),
      textColor: const Color(0xFF657B83),
      textSecondaryColor: const Color(0xFF93A1A1),
      primaryColor: const Color(0xFF268BD2),
      accentColor: const Color(0xFF2AA198),
    ),
    ThemeType.dracula: ThemeColors(
      backgroundColor: const Color(0xFF282A36),
      surfaceColor: const Color(0xFF44475A),
      textColor: const Color(0xFFF8F8F2),
      textSecondaryColor: const Color(0xFFBDBDBD),
      primaryColor: const Color(0xFFBD93F9),
      accentColor: const Color(0xFFFF79C6),
    ),
  };

  static void setTheme(ThemeType theme) {
    _currentTheme = theme;
  }

  static void setIsDarkMode(bool isDark) {
    _isDarkMode = isDark;
  }

  static ThemeColors get _currentColors {
    if (_currentTheme == ThemeType.system) {
      return _isDarkMode ? _themes[ThemeType.dark]! : _themes[ThemeType.light]!;
    }
    return _themes[_currentTheme]!;
  }

  static Color backgroundColor() => _currentColors.backgroundColor;
  static Color surfaceColor() => _currentColors.surfaceColor;
  static Color textColor() => _currentColors.textColor;
  static Color textSecondaryColor() => _currentColors.textSecondaryColor;
  static Color primaryColor() => _currentColors.primaryColor;
  static Color accentColor() => _currentColors.accentColor;
} 
