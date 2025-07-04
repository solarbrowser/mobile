import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import 'dart:ui';
import 'dart:math';
import 'browser_screen.dart';
import '../utils/theme_manager.dart';
import 'package:url_launcher/url_launcher.dart';

/// Extension to convert withOpacity calls to withAlpha
extension ColorExtension on Color {
  /// Converts opacity [value] (0.0 to 1.0) to alpha (0 to 255)
  Color withAlphaFromOpacity(double value) {
    return withAlpha((value.clamp(0.0, 1.0) * 255).round());
  }
}

class WelcomeScreen extends StatefulWidget {
  final Function(String) onLocaleChange;
  final Function(bool) onThemeChange;
  final Function(String) onSearchEngineChange;

  const WelcomeScreen({
    super.key,
    required this.onLocaleChange,
    required this.onThemeChange,
    required this.onSearchEngineChange,
  });

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  late AnimationController _iconAnimationController;
  int _currentPage = 0;
  String _selectedLanguage = 'en';
  String _selectedSearchEngine = 'Google';
  bool _isPageAnimating = false;

  final List<String> _browserIcons = [
    'assets/tab24.png',
    'assets/downloads24.png',
    'assets/search24.png',
    'assets/secure24.png',
    'assets/history24.png',
    'assets/bookmark24.png',
    'assets/settings24.png',
    'assets/reload24.png',
    'assets/share24.png',
    'assets/forward24.png',
    'assets/back24.png',
  ];

  final List<_FloatingIcon> _floatingIcons = [];

  final Map<String, String> _languages = {
    'en': 'English',
    'tr': 'Türkçe',
    'es': 'Español',
    'fr': 'Français',
    'de': 'Deutsch',
    'it': 'Italiano',
    'pt': 'Português',
    'ru': 'Русский',
    'zh': '中文',
    'ja': '日本語',
    'ko': '한국어',
    'ar': 'العربية',
    'hi': 'हिन्दी',
  };

  final Map<String, String> _searchEngines = {
    'Google': 'Google',
    'DuckDuckGo': 'DuckDuckGo',
    'Bing': 'Bing',
    'Yahoo': 'Yahoo',
    'Yandex': 'Yandex',
    'Brave': 'Brave',
  };

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _iconAnimationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _animationController.forward();

    // Generate floating icons with random positions and movements
    _generateFloatingIcons();

    // Initialize preferences after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initSystemPreferences();
    });
  }

  void _generateFloatingIcons() {
    // Create more icons as requested, but still maintain performance
    const int iconCount = 24; // Increased number of icons
    _floatingIcons.clear();

    final themeColors = ThemeManager.getThemeColors(ThemeManager.getCurrentTheme());
    final isDark = ThemeManager.getCurrentTheme().isDark;

    // More distributed positions for better coverage across the screen
    final positions = [
      // Top section
      [0.1, 0.1], [0.3, 0.05], [0.5, 0.1], [0.7, 0.05], [0.9, 0.1],
      // Upper middle
      [0.15, 0.2], [0.4, 0.25], [0.6, 0.25], [0.85, 0.2],
      // Middle section
      [0.05, 0.4], [0.25, 0.45], [0.5, 0.4], [0.75, 0.45], [0.95, 0.4],
      // Lower middle
      [0.15, 0.6], [0.4, 0.65], [0.6, 0.65], [0.85, 0.6],
      // Bottom section
      [0.1, 0.8], [0.3, 0.85], [0.5, 0.8], [0.7, 0.85], [0.9, 0.8],
      [0.5, 0.95],
    ];

    for (int i = 0; i < iconCount; i++) {
      // Pick specific icons instead of random ones for more variety
      final iconIndex = i % _browserIcons.length;
      final iconPath = _browserIcons[iconIndex];

      // Determine if this will be a colored icon
      final bool isColored = i % 3 == 0; // Every third icon is colored

      final icon = _FloatingIcon(
        icon: isDark && iconPath.contains('24.png')
            ? iconPath.replaceAll('24.png', '24w.png')
            : iconPath,
        size: 24.0 + (i % 3) * 8.0, // More consistent sizing
        xPos: positions[i][0],
        yPos: positions[i][1],
        xSpeed: (i % 2 == 0 ? 0.002 : -0.002), // Alternating directions, slower speed
        ySpeed: (i % 3 == 0 ? 0.001 : -0.001), // Very slow vertical drift
        rotationSpeed: 0.005 * (i % 2 == 0 ? 1 : -1), // Slower, alternating rotation
        opacity: 0.15 + (i % 5) * 0.03, // More consistent opacity
        color: isColored ? themeColors.primaryColor : null,
      );

      _floatingIcons.add(icon);
    }
  }

  void _initSystemPreferences() {
    final platformDispatcher = View.of(context).platformDispatcher;

    // Set system theme
    final isDark = platformDispatcher.platformBrightness == Brightness.dark;
    ThemeManager.setIsDarkMode(isDark);
    widget.onThemeChange(isDark);

    // Set system language
    final List<Locale> systemLocales = platformDispatcher.locales;
    for (Locale locale in systemLocales) {
      final languageCode = locale.languageCode;
      if (_languages.containsKey(languageCode) && languageCode != _selectedLanguage) {
        setState(() {
          _selectedLanguage = languageCode;
        });
        widget.onLocaleChange(languageCode);
        break;
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    _iconAnimationController.dispose();
    super.dispose();
  }

  void _handleContinue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('first_start', false);

    if (!mounted) return;

    // Skip update screen and go directly to browser
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => BrowserScreen(
          onLocaleChange: widget.onLocaleChange,
        ),
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  Widget _buildGlassmorphicContainer({
    required Widget child,
    BorderRadius? customBorderRadius,
  }) {
    final themeColors = ThemeManager.getThemeColors(ThemeManager.getCurrentTheme());
    return ClipRRect(
      borderRadius: customBorderRadius ?? BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                themeColors.textColor.withAlpha(38), // 0.15 * 255 = ~38
                themeColors.textColor.withAlpha(13), // 0.05 * 255 = ~13
              ],
            ),
            borderRadius: customBorderRadius ?? BorderRadius.circular(24),
            border: customBorderRadius?.bottomLeft == Radius.zero && customBorderRadius?.bottomRight == Radius.zero
                ? Border(
                    top: BorderSide(color: themeColors.primaryColor.withAlpha(77), width: 1.5),
                    left: BorderSide(color: themeColors.primaryColor.withAlpha(77), width: 1.5),
                    right: BorderSide(color: themeColors.primaryColor.withAlpha(77), width: 1.5),
                  )
                : customBorderRadius?.topLeft == Radius.zero && customBorderRadius?.topRight == Radius.zero
                    ? Border(
                        bottom: BorderSide(color: themeColors.primaryColor.withAlpha(77), width: 1.5),
                        left: BorderSide(color: themeColors.primaryColor.withAlpha(77), width: 1.5),
                        right: BorderSide(color: themeColors.primaryColor.withAlpha(77), width: 1.5),
                      )
                    : Border.all(
                        color: themeColors.primaryColor.withAlpha(77), // 0.3 * 255 = ~77
                        width: 1.5,
                      ),
            boxShadow: [
              BoxShadow(
                color: themeColors.primaryColor.withAlpha(51), // 0.2 * 255 = ~51
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildFloatingIconsBackground() {
    return AnimatedBuilder(
      animation: _iconAnimationController,
      builder: (context, child) {
        final size = MediaQuery.of(context).size;
        return CustomPaint(
          size: Size(size.width, size.height),
          painter: BrowserIconsPainter(
            floatingIcons: _floatingIcons,
            progress: _iconAnimationController.value,
            screenWidth: size.width,
            screenHeight: size.height,
          ),
        );
      },
    );
  }

  Widget _buildWelcomePage() {
    final size = MediaQuery.of(context).size;
    final isLargeScreen = size.width > 600;
    final themeColors = ThemeManager.getThemeColors(ThemeManager.getCurrentTheme());

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.only(
          left: size.width * 0.05, 
          right: size.width * 0.05,
          top: size.height * 0.05,
          bottom: 0, // No bottom padding to connect with indicator
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Icon outside panel and centered
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.8, end: 1.0),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.elasticOut,
              builder: (context, scaleValue, child) {
                return Transform.scale(
                  scale: scaleValue,
                  child: Hero(
                    tag: 'logo',
                    child: Container(
                      width: isLargeScreen ? 120 : 90,
                      height: isLargeScreen ? 120 : 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: themeColors.primaryColor.withAlphaFromOpacity(0.4),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/icon.jpeg',
                        width: isLargeScreen ? 120 : 90,
                        height: isLargeScreen ? 120 : 90,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: size.height * 0.03),

            // Content panel with flat bottom edge
            _buildGlassmorphicContainer(
              customBorderRadius: BorderRadius.vertical(
                top: Radius.circular(24),
                bottom: Radius.zero,
              ),
              child: Container(
                height: size.height * 0.67, // Further increased height to ensure connection with bottom bar
                padding: EdgeInsets.symmetric(
                  horizontal: size.width * 0.05,
                  vertical: size.height * 0.03,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [
                          themeColors.primaryColor,
                          themeColors.textColor,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      child: Text(
                        AppLocalizations.of(context)!.welcomeToSolar,
                        style: TextStyle(
                          fontSize: isLargeScreen ? 32 : 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: size.height * 0.02),
                    Text(
                      AppLocalizations.of(context)!.welcomeDescription,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isLargeScreen ? 18 : 15,
                        color: themeColors.textSecondaryColor,
                        letterSpacing: 0.3,
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: size.height * 0.02),
                    
                    // Terms of Service link moved inside panel
                    GestureDetector(
                      onTap: () async {
                        final uri = Uri.parse('https://browser.solar/terms-of-use');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                      child: Padding(
                        padding: EdgeInsets.only(top: size.height * 0.02),
                        child: Text(
                          AppLocalizations.of(context)!.termsOfService,
                          style: TextStyle(
                            fontSize: isLargeScreen ? 15 : 13,
                            color: themeColors.textSecondaryColor,
                            decoration: TextDecoration.underline,
                            decorationColor: themeColors.textSecondaryColor.withAlphaFromOpacity(0.5),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguagePage() {
    final size = MediaQuery.of(context).size;
    final isLargeScreen = size.width > 600;
    final themeColors = ThemeManager.getThemeColors(ThemeManager.getCurrentTheme());

    // Calculate a more dynamic height based on screen size that connects with bottom bar
    final containerHeight = size.height * 0.67; // Further increased height to ensure connection with bottom bar

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.only(
          left: size.width * 0.05,
          right: size.width * 0.05,
          top: size.height * 0.05,
          bottom: 0, // No padding at bottom to connect with nav bar
        ),
        child: Column(
          children: [
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [
                  themeColors.primaryColor,
                  themeColors.textColor,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: Text(
                AppLocalizations.of(context)!.chooseLanguage,
                style: TextStyle(
                  fontSize: isLargeScreen ? 32 : 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            SizedBox(height: size.height * 0.02),
            Text(
              "Select your preferred language",
              style: TextStyle(
                fontSize: isLargeScreen ? 16 : 14,
                color: themeColors.textSecondaryColor,
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: size.height * 0.02),
            _buildGlassmorphicContainer(
              customBorderRadius: BorderRadius.vertical(
                top: Radius.circular(24),
                bottom: Radius.zero,
              ),
              child: Container(
                height: containerHeight,
                width: isLargeScreen ? 400 : double.infinity,
                padding: EdgeInsets.symmetric(vertical: size.height * 0.015),
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: _languages.length,
                  itemBuilder: (context, index) {
                    final language = _languages.keys.elementAt(index);
                    final name = _languages[language]!;
                    final isSelected = _selectedLanguage == language;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? themeColors.primaryColor.withAlphaFromOpacity(0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? themeColors.primaryColor.withAlphaFromOpacity(0.5)
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: ListTile(
                          dense: !isLargeScreen,
                          visualDensity: VisualDensity(vertical: isLargeScreen ? 0 : -2),
                          title: Text(
                            name,
                            style: TextStyle(
                              color: themeColors.textColor,
                              fontSize: isLargeScreen ? 18 : 16,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          trailing: isSelected
                              ? Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: themeColors.primaryColor,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: themeColors.primaryColor.withAlphaFromOpacity(0.4),
                                        blurRadius: 4,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                )
                              : null,
                          onTap: () {
                            setState(() {
                              _selectedLanguage = language;
                            });
                            widget.onLocaleChange(language);
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemePage() {
    final size = MediaQuery.of(context).size;
    final isLargeScreen = size.width > 600;
    final themeColors = ThemeManager.getThemeColors(ThemeManager.getCurrentTheme());

    // Calculate a more dynamic height based on screen size that connects with bottom bar
    final containerHeight = size.height * 0.67; // Further increased height to ensure connection with bottom bar

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.only(
          left: size.width * 0.05,
          right: size.width * 0.05,
          top: size.height * 0.05,
          bottom: 0, // No padding at bottom to connect with nav bar
        ),
        child: Column(
          children: [
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [
                  themeColors.primaryColor,
                  themeColors.textColor,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: Text(
                AppLocalizations.of(context)!.chooseTheme,
                style: TextStyle(
                  fontSize: isLargeScreen ? 32 : 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            SizedBox(height: size.height * 0.02),
            Text(
              "Personalize your browsing experience",
              style: TextStyle(
                fontSize: isLargeScreen ? 16 : 14,
                color: themeColors.textSecondaryColor,
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: size.height * 0.02),
            _buildGlassmorphicContainer(
              customBorderRadius: BorderRadius.vertical(
                top: Radius.circular(24),
                bottom: Radius.zero,
              ),
              child: Container(
                height: containerHeight,
                width: isLargeScreen ? 400 : double.infinity,
                padding: EdgeInsets.symmetric(vertical: size.height * 0.015),
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: ThemeType.values.length,
                  itemBuilder: (context, index) {
                    final theme = ThemeType.values[index];
                    final themeColors = ThemeManager.getThemeColors(theme);
                    final isSelected = ThemeManager.getCurrentTheme() == theme;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? themeColors.primaryColor.withAlphaFromOpacity(0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? themeColors.primaryColor.withAlphaFromOpacity(0.5)
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: ListTile(
                          dense: !isLargeScreen,
                          visualDensity: VisualDensity(vertical: isLargeScreen ? 0 : -2),
                          title: Text(
                            _getThemeName(theme),
                            style: TextStyle(
                              color: themeColors.textColor,
                              fontSize: isLargeScreen ? 18 : 16,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          leading: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: themeColors.primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          trailing: isSelected
                              ? Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: themeColors.primaryColor,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: themeColors.primaryColor.withAlphaFromOpacity(0.4),
                                        blurRadius: 4,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                )
                              : null,
                          onTap: () {
                            setState(() {
                              ThemeManager.setTheme(theme);
                              _generateFloatingIcons();
                            });
                            widget.onThemeChange(theme.isDark);
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getThemeName(ThemeType theme) {
    switch (theme) {
      case ThemeType.system:
        return AppLocalizations.of(context)!.systemTheme;
      case ThemeType.light:
        return AppLocalizations.of(context)!.lightTheme;
      case ThemeType.dark:
        return AppLocalizations.of(context)!.darkTheme;
      case ThemeType.tokyoNight:
        return AppLocalizations.of(context)!.tokyoNightTheme;
      case ThemeType.solarizedLight:
        return AppLocalizations.of(context)!.solarizedLightTheme;
      case ThemeType.dracula:
        return AppLocalizations.of(context)!.draculaTheme;
      case ThemeType.nord:
        return AppLocalizations.of(context)!.nordTheme;
      case ThemeType.gruvbox:
        return AppLocalizations.of(context)!.gruvboxTheme;
      case ThemeType.oneDark:
        return AppLocalizations.of(context)!.oneDarkTheme;
      case ThemeType.catppuccin:
        return AppLocalizations.of(context)!.catppuccinTheme;
      case ThemeType.nordLight:
        return AppLocalizations.of(context)!.nordLightTheme;
      case ThemeType.gruvboxLight:
        return AppLocalizations.of(context)!.gruvboxLightTheme;
    }
  }

  Widget _buildSearchEnginePage() {
    final size = MediaQuery.of(context).size;
    final isLargeScreen = size.width > 600;
    final themeColors = ThemeManager.getThemeColors(ThemeManager.getCurrentTheme());

    // Calculate a more dynamic height based on screen size that connects with bottom bar
    final containerHeight = size.height * 0.67; // Further increased height to ensure connection with bottom bar

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.only(
          left: size.width * 0.05,
          right: size.width * 0.05,
          top: size.height * 0.05,
          bottom: 0, // No padding at bottom to connect with nav bar
        ),
        child: Column(
          children: [
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [
                  themeColors.primaryColor,
                  themeColors.textColor,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: Text(
                AppLocalizations.of(context)!.chooseSearchEngine,
                style: TextStyle(
                  fontSize: isLargeScreen ? 32 : 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            SizedBox(height: size.height * 0.02),
            Text(
              "Choose your default search engine",
              style: TextStyle(
                fontSize: isLargeScreen ? 16 : 14,
                color: themeColors.textSecondaryColor,
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: size.height * 0.02),
            _buildGlassmorphicContainer(
              customBorderRadius: BorderRadius.vertical(
                top: Radius.circular(24),
                bottom: Radius.zero,
              ),
              child: Container(
                height: containerHeight,
                width: isLargeScreen ? 400 : double.infinity,
                padding: EdgeInsets.symmetric(vertical: size.height * 0.015),
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: _searchEngines.length,
                  itemBuilder: (context, index) {
                    final engine = _searchEngines.keys.elementAt(index);
                    final name = _searchEngines[engine]!;
                    final isSelected = _selectedSearchEngine == engine;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? themeColors.primaryColor.withAlphaFromOpacity(0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? themeColors.primaryColor.withAlphaFromOpacity(0.5)
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: ListTile(
                          dense: !isLargeScreen,
                          visualDensity: VisualDensity(vertical: isLargeScreen ? 0 : -2),
                          title: Text(
                            name,
                            style: TextStyle(
                              fontSize: isLargeScreen ? 18 : 16,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          trailing: isSelected
                              ? Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: themeColors.primaryColor,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: themeColors.primaryColor.withAlphaFromOpacity(0.4),
                                        blurRadius: 4,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                )
                              : null,
                          onTap: () {
                            setState(() {
                              _selectedSearchEngine = engine;
                              widget.onSearchEngineChange(engine);
                            });
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _animateToPage(int page) {
    if (_isPageAnimating) return;

    setState(() {
      _isPageAnimating = true;
    });

    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    ).then((_) {
      setState(() {
        _isPageAnimating = false;
        _currentPage = page;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = ThemeManager.getThemeColors(ThemeManager.getCurrentTheme());

    return Scaffold(
      backgroundColor: themeColors.backgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: ThemeManager.getCurrentTheme().isDark
                ? [
              const Color(0xFF1a1a1a),
              const Color(0xFF0a0a0a),
            ]
                : [
              const Color(0xFFffffff),
              const Color(0xFFf0f0f0),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Floating background icons
              _buildFloatingIconsBackground(),

              // Use Stack instead of Column for better positioning
              Stack(
                children: [
                  // Main content area that fully covers the screen (including behind the bottom bar)
                  Positioned.fill(
                    child: PageView(
                      controller: _pageController,
                      physics: _isPageAnimating
                          ? const NeverScrollableScrollPhysics()
                          : const BouncingScrollPhysics(),
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      children: [
                        _buildWelcomePage(),
                        _buildLanguagePage(),
                        _buildThemePage(),
                        _buildSearchEnginePage(),
                      ],
                    ),
                  ),
                  
                  // Bottom navigation bar positioned at the bottom of the screen
                  // Using the exact same margin as content panels for perfect alignment
                  Positioned(
                    left: MediaQuery.of(context).size.width * 0.05,
                    right: MediaQuery.of(context).size.width * 0.05,
                    bottom: 0,
                    child: _buildBottomBar(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final size = MediaQuery.of(context).size;
    final isLargeScreen = size.width > 600;
    final themeColors = ThemeManager.getThemeColors(ThemeManager.getCurrentTheme());

    // No padding here to ensure seamless connection
    return _buildGlassmorphicContainer(
      customBorderRadius: BorderRadius.vertical(
        top: Radius.zero,
        bottom: Radius.circular(24),
      ),
      child: Container(
        height: isLargeScreen ? 72 : 60,
        width: double.infinity, // Full width
        margin: EdgeInsets.zero, // Remove any margin
        padding: EdgeInsets.symmetric(horizontal: size.width * 0.05),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_currentPage > 0)
                TextButton.icon(
                  onPressed: () => _animateToPage(_currentPage - 1),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    // FIX: Replaced withOpacity with withValues
                    backgroundColor: themeColors.textColor.withAlphaFromOpacity( 0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Icon(
                    Icons.arrow_back_ios_rounded,
                    size: isLargeScreen ? 18 : 16,
                    color: themeColors.textSecondaryColor,
                  ),
                  label: Text(
                    AppLocalizations.of(context)!.back,
                    style: TextStyle(
                      color: themeColors.textSecondaryColor,
                      fontSize: isLargeScreen ? 18 : 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              else
                SizedBox(width: isLargeScreen ? 80 : 60),
              Row(
                children: List.generate(
                  4,
                      (index) => GestureDetector(
                    onTap: () => _animateToPage(index),
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: isLargeScreen ? 4 : 3),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        width: _currentPage == index
                            ? (isLargeScreen ? 24 : 20)
                            : (isLargeScreen ? 8 : 7),
                        height: isLargeScreen ? 8 : 7,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(isLargeScreen ? 4 : 3.5),
                          // FIX: Replaced withOpacity with withValues
                          color: _currentPage == index
                              ? themeColors.primaryColor
                              : themeColors.textSecondaryColor.withAlphaFromOpacity( 0.3),
                          boxShadow: _currentPage == index
                              ? [
                            BoxShadow(
                              // FIX: Replaced withOpacity with withValues
                              color: themeColors.primaryColor.withAlphaFromOpacity( 0.4),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ]
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  if (_currentPage < 3) {
                    _animateToPage(_currentPage + 1);
                  } else {
                    _handleContinue();
                  }
                },
                style: TextButton.styleFrom(
                  // FIX: Replaced withOpacity with withValues
                  backgroundColor: _currentPage == 3
                      ? themeColors.primaryColor
                      : themeColors.primaryColor.withAlphaFromOpacity( 0.2),
                  padding: EdgeInsets.symmetric(
                      horizontal: isLargeScreen ? 16 : 12,
                      vertical: isLargeScreen ? 8 : 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _currentPage < 3
                      ? AppLocalizations.of(context)!.next
                      : AppLocalizations.of(context)!.getStarted,
                  style: TextStyle(
                    color: _currentPage == 3 ? Colors.white : themeColors.textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: isLargeScreen ? 18 : 15,
                  ),
                ),
              ),
            ],
          ),
        ),
    );
  }
}

// Class to represent a floating browser icon
class _FloatingIcon {
  final String icon;
  final double size;
  double xPos;
  double yPos;
  final double xSpeed;
  final double ySpeed;
  final double rotationSpeed;
  final double opacity;
  final Color? color; // Optional color for the icon
  double rotation = 0;
  double scale = 1.0; // For subtle pulsing effect
  double scaleDirection = 0.0005; // Slowed down pulsing (was 0.001)
  double initialXPos; // Store initial positions to limit drift
  double initialYPos;
  double driftLimit = 0.1; // Limit how far icons can drift from initial position

  _FloatingIcon({
    required this.icon,
    required this.size,
    required this.xPos,
    required this.yPos,
    required this.xSpeed,
    required this.ySpeed,
    required this.rotationSpeed,
    required this.opacity,
    this.color,
  })  : initialXPos = xPos,
        initialYPos = yPos;

  void update(double progress) {
    // Update position with drift limits
    final newXPos = xPos + xSpeed;
    final newYPos = yPos + ySpeed;

    // Check if new position would exceed drift limit
    if ((newXPos - initialXPos).abs() < driftLimit) {
      xPos = newXPos;
    } else {
      // Reverse direction when hitting drift limit
      xPos -= xSpeed;
    }

    if ((newYPos - initialYPos).abs() < driftLimit) {
      yPos = newYPos;
    } else {
      // Reverse direction when hitting drift limit
      yPos -= ySpeed;
    }

    // Always keep on screen
    xPos = xPos.clamp(0.0, 1.0);
    yPos = yPos.clamp(0.0, 1.0);

    // Slow, consistent rotation
    rotation += rotationSpeed * 0.5;

    // Gentler pulsing effect
    scale += scaleDirection;
    if (scale > 1.05 || scale < 0.95) {
      scaleDirection = -scaleDirection;
    }
  }
}

// Custom painter for drawing the floating browser icons
class BrowserIconsPainter extends CustomPainter {
  // Note: We're using a private type in a parameter that's not exposed in a public API
  // ignore: library_private_types_in_public_api
  final List<_FloatingIcon> floatingIcons;
  final double progress;
  final double screenWidth;
  final double screenHeight;

  BrowserIconsPainter({
    required this.floatingIcons,
    required this.progress,
    required this.screenWidth,
    required this.screenHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Update and draw each floating icon
    for (var icon in floatingIcons) {
      icon.update(progress);

      final x = icon.xPos * screenWidth;
      final y = icon.yPos * screenHeight;

      // Save canvas state
      canvas.save();

      // Translate, rotate and scale
      canvas.translate(x, y);
      canvas.rotate(icon.rotation);
      canvas.scale(icon.scale);

      final iconRect = Rect.fromCenter(
        center: Offset.zero,
        width: icon.size,
        height: icon.size,
      );

      // Draw a simple shape with the icon's opacity
      final paint = Paint()
        ..color = icon.color?.withAlpha((icon.opacity * 255).round()) ??
            Colors.white.withAlpha((icon.opacity * 255).round())
        ..style = PaintingStyle.fill;

      // Draw a browser icon symbol based on icon index to ensure variety
      final iconIndex = floatingIcons.indexOf(icon) % 8;

      switch (iconIndex) {
        case 0:
          _drawTab(canvas, iconRect, paint);
          break;
        case 1:
          _drawSearch(canvas, iconRect, paint);
          break;
        case 2:
          _drawSpeedGauge(canvas, iconRect, paint);
          break;
        case 3:
          _drawLock(canvas, iconRect, paint);
          break;
        case 4:
          _drawHistory(canvas, iconRect, paint);
          break;
        case 5:
          _drawRocket(canvas, iconRect, paint);
          break;
        case 6:
          _drawBookmark(canvas, iconRect, paint);
          break;
        case 7:
          _drawSettings(canvas, iconRect, paint);
          break;
        default:
          canvas.drawRRect(
            RRect.fromRectAndRadius(iconRect, Radius.circular(iconRect.width / 4)),
            paint,
          );
      }

      // Restore canvas state
      canvas.restore();
    }
  }

  void _drawTab(Canvas canvas, Rect rect, Paint paint) {
    final path = Path();
    path.moveTo(rect.left, rect.bottom);
    path.lineTo(rect.left, rect.top + rect.height * 0.3);
    path.lineTo(rect.left + rect.width * 0.3, rect.top);
    path.lineTo(rect.right - rect.width * 0.3, rect.top);
    path.lineTo(rect.right, rect.top + rect.height * 0.3);
    path.lineTo(rect.right, rect.bottom);
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawSearch(Canvas canvas, Rect rect, Paint paint) {
    // Draw magnifying glass
    final circlePaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = rect.width * 0.15;

    canvas.drawCircle(
      Offset(rect.left + rect.width * 0.4, rect.top + rect.height * 0.4),
      rect.width * 0.25,
      circlePaint,
    );

    // Draw handle
    final handlePaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = rect.width * 0.15
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(rect.left + rect.width * 0.6, rect.top + rect.height * 0.6),
      Offset(rect.left + rect.width * 0.8, rect.top + rect.height * 0.8),
      handlePaint,
    );
  }

  void _drawLock(Canvas canvas, Rect rect, Paint paint) {
    // Draw lock body
    final bodyRect = Rect.fromLTRB(
      rect.left + rect.width * 0.2,
      rect.top + rect.height * 0.45,
      rect.right - rect.width * 0.2,
      rect.bottom - rect.height * 0.1,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, Radius.circular(rect.width * 0.1)),
      paint,
    );

    // Draw lock shackle
    final shacklePaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = rect.width * 0.12;

    final shackleRect = Rect.fromLTRB(
      rect.left + rect.width * 0.3,
      rect.top + rect.height * 0.15,
      rect.right - rect.width * 0.3,
      rect.top + rect.height * 0.5,
    );
    canvas.drawArc(shackleRect, 3.14, 3.14, false, shacklePaint);
  }

  void _drawBookmark(Canvas canvas, Rect rect, Paint paint) {
    final path = Path();
    path.moveTo(rect.left + rect.width * 0.2, rect.top + rect.height * 0.1);
    path.lineTo(rect.left + rect.width * 0.2, rect.bottom - rect.height * 0.1);
    path.lineTo(rect.center.dx, rect.bottom - rect.height * 0.3);
    path.lineTo(rect.right - rect.width * 0.2, rect.bottom - rect.height * 0.1);
    path.lineTo(rect.right - rect.width * 0.2, rect.top + rect.height * 0.1);
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawSettings(Canvas canvas, Rect rect, Paint paint) {
    // Draw gear
    canvas.drawCircle(
      rect.center,
      rect.width * 0.25,
      paint,
    );

    // Draw gear teeth
    for (int i = 0; i < 8; i++) {
      final angle = i * 3.14 / 4;
      final path = Path();
      path.moveTo(
        rect.center.dx + cos(angle) * rect.width * 0.3,
        rect.center.dy + sin(angle) * rect.width * 0.3,
      );
      path.lineTo(
        rect.center.dx + cos(angle) * rect.width * 0.45,
        rect.center.dy + sin(angle) * rect.width * 0.45,
      );
      path.lineTo(
        rect.center.dx + cos(angle + 0.3) * rect.width * 0.45,
        rect.center.dy + sin(angle + 0.3) * rect.width * 0.45,
      );
      path.lineTo(
        rect.center.dx + cos(angle + 0.3) * rect.width * 0.3,
        rect.center.dy + sin(angle + 0.3) * rect.width * 0.3,
      );
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  void _drawSpeedGauge(Canvas canvas, Rect rect, Paint paint) {
    // Draw the gauge circle
    final gaugePaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = rect.width * 0.08;

    // Draw gauge outline
    canvas.drawArc(
      rect,
      3.14 * 0.75,
      3.14 * 1.5,
      false,
      gaugePaint,
    );

    // Draw the needle
    final needlePaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.fill;

    final needlePath = Path();
    needlePath.moveTo(rect.center.dx, rect.center.dy);
    needlePath.lineTo(
      rect.center.dx + cos(3.14 * 1.8) * rect.width * 0.4,
      rect.center.dy + sin(3.14 * 1.8) * rect.width * 0.4,
    );
    needlePath.lineTo(
      rect.center.dx + cos(3.14 * 1.85) * rect.width * 0.2,
      rect.center.dy + sin(3.14 * 1.85) * rect.width * 0.2,
    );
    needlePath.close();
    canvas.drawPath(needlePath, needlePaint);

    // Draw center dot
    canvas.drawCircle(rect.center, rect.width * 0.1, needlePaint);
  }

  void _drawRocket(Canvas canvas, Rect rect, Paint paint) {
    final rocketPath = Path();

    // Rocket body
    rocketPath.moveTo(rect.center.dx, rect.top + rect.height * 0.1);
    rocketPath.lineTo(rect.left + rect.width * 0.3, rect.center.dy + rect.height * 0.1);
    rocketPath.lineTo(rect.left + rect.width * 0.3, rect.bottom - rect.height * 0.2);
    rocketPath.quadraticBezierTo(
        rect.center.dx, rect.bottom,
        rect.right - rect.width * 0.3, rect.bottom - rect.height * 0.2
    );
    rocketPath.lineTo(rect.right - rect.width * 0.3, rect.center.dy + rect.height * 0.1);
    rocketPath.close();

    canvas.drawPath(rocketPath, paint);

    // Window
    final windowPaint = Paint()
      ..color = paint.color.withAlpha(128)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
        Offset(rect.center.dx, rect.center.dy),
        rect.width * 0.12,
        windowPaint
    );

    // Fins
    final finPath = Path();
    finPath.moveTo(rect.left + rect.width * 0.3, rect.center.dy + rect.height * 0.05);
    finPath.lineTo(rect.left, rect.center.dy + rect.height * 0.2);
    finPath.lineTo(rect.left + rect.width * 0.3, rect.center.dy + rect.height * 0.3);

    canvas.drawPath(finPath, paint);

    final finPath2 = Path();
    finPath2.moveTo(rect.right - rect.width * 0.3, rect.center.dy + rect.height * 0.05);
    finPath2.lineTo(rect.right, rect.center.dy + rect.height * 0.2);
    finPath2.lineTo(rect.right - rect.width * 0.3, rect.center.dy + rect.height * 0.3);

    canvas.drawPath(finPath2, paint);
  }

  void _drawHistory(Canvas canvas, Rect rect, Paint paint) {
    final circlePaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = rect.width * 0.08;

    // Draw clock face
    canvas.drawCircle(
        rect.center,
        rect.width * 0.4,
        circlePaint
    );

    // Draw hands
    final handPaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = rect.width * 0.08
      ..strokeCap = StrokeCap.round;

    // Hour hand
    canvas.drawLine(
      rect.center,
      Offset(
        rect.center.dx + cos(3.14 * 1.3) * rect.width * 0.25,
        rect.center.dy + sin(3.14 * 1.3) * rect.width * 0.25,
      ),
      handPaint,
    );

    // Minute hand
    canvas.drawLine(
      rect.center,
      Offset(
        rect.center.dx + cos(3.14 * 0.3) * rect.width * 0.35,
        rect.center.dy + sin(3.14 * 0.3) * rect.width * 0.35,
      ),
      handPaint,
    );

    // Arrow for history
    final arrowPaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = rect.width * 0.08
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: rect.center, radius: rect.width * 0.6),
      3.14 * 0.1,
      3.14 * 0.6,
      false,
      arrowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant BrowserIconsPainter oldDelegate) => true;
}