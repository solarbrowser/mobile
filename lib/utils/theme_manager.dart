import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemeType {
  system,
  light,
  dark,
  tokyoNight,
  solarizedLight,
  dracula,
  nord,
  gruvbox,
  oneDark,
  catppuccin,
  nordLight,
  gruvboxLight;

  bool get isDark {
    switch (this) {
      case ThemeType.system:
        return false;
      case ThemeType.light:
      case ThemeType.solarizedLight:
      case ThemeType.nordLight:
      case ThemeType.gruvboxLight:
        return false;
      case ThemeType.dark:
      case ThemeType.tokyoNight:
      case ThemeType.dracula:
      case ThemeType.nord:
      case ThemeType.gruvbox:
      case ThemeType.oneDark:
      case ThemeType.catppuccin:
        return true;
    }
  }
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
  static ThemeType _currentTheme = ThemeType.system;
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
    ThemeType.nord: ThemeColors(
      backgroundColor: const Color(0xFF2E3440),
      surfaceColor: const Color(0xFF3B4252),
      textColor: const Color(0xFFD8DEE9),
      textSecondaryColor: const Color(0xFF81A1C1),
      primaryColor: const Color(0xFF88C0D0),
      accentColor: const Color(0xFF8FBCBB),
      errorColor: const Color(0xFFBF616A),
      successColor: const Color(0xFFA3BE8C),
      warningColor: const Color(0xFFD08770),
      secondaryColor: const Color(0xFF4C566A),
    ),
    ThemeType.gruvbox: ThemeColors(
      backgroundColor: const Color(0xFF282828),
      surfaceColor: const Color(0xFF3C3836),
      textColor: const Color(0xFFEBDBB2),
      textSecondaryColor: const Color(0xFFD5C4A1),
      primaryColor: const Color(0xFFFE8019),
      accentColor: const Color(0xFFB8BB26),
      errorColor: const Color(0xFFFB4934),
      successColor: const Color(0xFF8EC07C),
      warningColor: const Color(0xFFFABD2F),
      secondaryColor: const Color(0xFF504945),
    ),
    ThemeType.nordLight: ThemeColors(
      backgroundColor: const Color(0xFFE5E9F0),
      surfaceColor: const Color(0xFFD8DEE9),
      textColor: const Color(0xFF2E3440),
      textSecondaryColor: const Color(0xFF4C566A),
      primaryColor: const Color(0xFF5E81AC),
      accentColor: const Color(0xFF81A1C1),
      errorColor: const Color(0xFFBF616A),
      successColor: const Color(0xFFA3BE8C),
      warningColor: const Color(0xFFD08770),
      secondaryColor: const Color(0xFFB48EAD),
    ),
    ThemeType.gruvboxLight: ThemeColors(
      backgroundColor: const Color(0xFFFBF1C7),
      surfaceColor: const Color(0xFFEBDBB2),
      textColor: const Color(0xFF3C3836),
      textSecondaryColor: const Color(0xFF504945),
      primaryColor: const Color(0xFFFE8019),
      accentColor: const Color(0xFFB8BB26),
      errorColor: const Color(0xFFCC241D),
      successColor: const Color(0xFF98971A),
      warningColor: const Color(0xFFD79921),
      secondaryColor: const Color(0xFFD5C4A1),
    ),
    ThemeType.oneDark: ThemeColors(
      backgroundColor: const Color(0xFF282C34),
      surfaceColor: const Color(0xFF21252B),
      textColor: const Color(0xFFABB2BF),
      textSecondaryColor: const Color(0xFF5C6370),
      primaryColor: const Color(0xFF61AFEF),
      accentColor: const Color(0xFFC678DD),
      errorColor: const Color(0xFFE06C75),
      successColor: const Color(0xFF98C379),
      warningColor: const Color(0xFFE5C07B),
      secondaryColor: const Color(0xFF3E4451),
    ),
    ThemeType.catppuccin: ThemeColors(
      backgroundColor: const Color(0xFF1E1E2E),
      surfaceColor: const Color(0xFF302D41),
      textColor: const Color(0xFFD9E0EE),
      textSecondaryColor: const Color(0xFF988BA2),
      primaryColor: const Color(0xFF96CDFB),
      accentColor: const Color(0xFFF5C2E7),
      errorColor: const Color(0xFFF28FAD),
      successColor: const Color(0xFFABE9B3),
      warningColor: const Color(0xFFFAE3B0),
      secondaryColor: const Color(0xFF575268),
    ),
  };

  static Future<void> loadSavedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString('selectedTheme');
    if (savedTheme != null) {
      try {
        final theme = ThemeType.values.firstWhere((t) => t.name == savedTheme);
        _currentTheme = theme;
        _isDarkMode = theme.isDark;
      } catch (e) {
        // If the saved theme is invalid, keep the default
      }
    }
  }

  static Future<void> setTheme(ThemeType theme) async {
    _currentTheme = theme;
    _isDarkMode = theme.isDark;
    // Save theme preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedTheme', theme.name);
  }

  static void setIsDarkMode(bool isDark) {
    _isDarkMode = isDark;
  }

  static ThemeType getCurrentTheme() => _currentTheme;

  static ThemeColors getThemeColors(ThemeType theme) {
    return _themes[theme] ?? _themes[ThemeType.light]!;
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

