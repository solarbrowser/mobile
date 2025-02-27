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
  final Color textColor;  //for icons and texts
  final Color textSecondaryColor;
  final Color primaryColor;
  final Color accentColor;
  final Color errorColor;
  final Color successColor;
  final Color warningColor;
  final Color secondaryColor;

  const ThemeColors({
    required this.backgroundColor,
    required this.surfaceColor,
    required this.textColor,
    required this.textSecondaryColor,
    required this.primaryColor,
    required this.accentColor,
    required this.errorColor,
    required this.successColor,
    required this.warningColor,
    required this.secondaryColor,
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
      errorColor: Colors.red,
      successColor: Colors.green,
      warningColor: Colors.orange,
      secondaryColor: Colors.grey[200]!,
    ),
    ThemeType.dark: ThemeColors(
      backgroundColor: Colors.black,
      surfaceColor: Colors.grey[900]!,
      textColor: Colors.white,
      textSecondaryColor: Colors.white70,
      primaryColor: Colors.blue,
      accentColor: Colors.blue[300]!,
      errorColor: Colors.red[400]!,
      successColor: Colors.green[400]!,
      warningColor: Colors.orange[400]!,
      secondaryColor: Colors.grey[800]!,
    ),
    ThemeType.tokyoNight: ThemeColors(
      backgroundColor: const Color(0xFF1A1B26),
      surfaceColor: const Color(0xFF24283B),
      textColor: const Color(0xFFA9B1D6),
      textSecondaryColor: const Color(0xFF787C99),
      primaryColor: const Color(0xFF7AA2F7),
      accentColor: const Color(0xFFBB9AF7),
      errorColor: const Color(0xFFF7768E),
      successColor: const Color(0xFF9ECE6A),
      warningColor: const Color(0xFFE0AF68),
      secondaryColor: const Color(0xFF1F2335),
    ),
    ThemeType.solarizedLight: ThemeColors(
      backgroundColor: const Color(0xFFFDF6E3),
      surfaceColor: const Color(0xFFEEE8D5),
      textColor: const Color(0xFF657B83),
      textSecondaryColor: const Color(0xFF93A1A1),
      primaryColor: const Color(0xFF268BD2),
      accentColor: const Color(0xFF2AA198),
      errorColor: const Color(0xFFDC322F),
      successColor: const Color(0xFF859900),
      warningColor: const Color(0xFFB58900),
      secondaryColor: const Color(0xFFE4DECD),
    ),
    ThemeType.dracula: ThemeColors(
      backgroundColor: const Color(0xFF282A36),
      surfaceColor: const Color(0xFF44475A),
      textColor: const Color(0xFFF8F8F2),
      textSecondaryColor: const Color(0xFFBDBDBD),
      primaryColor: const Color(0xFFBD93F9),
      accentColor: const Color(0xFFFF79C6),
      errorColor: const Color(0xFFFF5555),
      successColor: const Color(0xFF50FA7B),
      warningColor: const Color(0xFFFFB86C),
      secondaryColor: const Color(0xFF3B3D4D),
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
  static Color errorColor() => _currentColors.errorColor;
  static Color successColor() => _currentColors.successColor;
  static Color warningColor() => _currentColors.warningColor;
  static Color secondaryColor() => _currentColors.secondaryColor;
} 