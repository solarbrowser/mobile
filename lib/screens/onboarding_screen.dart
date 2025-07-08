import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../l10n/app_localizations.dart';
import '../utils/theme_manager.dart' as theme_utils;
import 'browser_screen.dart';

class OnboardingScreen extends StatefulWidget {
  final Function(Locale) onLocaleChange;
  final Function(ThemeMode) onThemeChange;
  final Function(String) onSearchEngineChange;

  const OnboardingScreen({
    Key? key,
    required this.onLocaleChange,
    required this.onThemeChange,
    required this.onSearchEngineChange,
  }) : super(key: key);

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  late AnimationController _welcomeAnimationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _indicatorController;
  late Animation<double> _indicatorAnimation;

  int _currentPage = 0;
  bool _showWelcome = true;

  // Settings
  Locale _selectedLocale = const Locale('en');
  theme_utils.ThemeType _selectedTheme = theme_utils.ThemeType.system;
  String _currentSearchEngine = 'Google';
  bool _notificationPermissionHandled = false;

  final List<Map<String, String>> _supportedLocales = [
    {'code': 'en', 'name': 'English', 'flag': '🇺🇸'},
    {'code': 'es', 'name': 'Español', 'flag': '🇪🇸'},
    {'code': 'fr', 'name': 'Français', 'flag': '🇫🇷'},
    {'code': 'de', 'name': 'Deutsch', 'flag': '🇩🇪'},
    {'code': 'it', 'name': 'Italiano', 'flag': '🇮🇹'},
    {'code': 'pt', 'name': 'Português', 'flag': '🇵🇹'},
    {'code': 'tr', 'name': 'Türkçe', 'flag': '🇹🇷'},
    {'code': 'ru', 'name': 'Русский', 'flag': '🇷🇺'},
    {'code': 'ja', 'name': '日本語', 'flag': '🇯🇵'},
    {'code': 'ko', 'name': '한국어', 'flag': '🇰🇷'},
    {'code': 'zh', 'name': '中文', 'flag': '🇨🇳'},
    {'code': 'ar', 'name': 'العربية', 'flag': '🇸🇦'},
    {'code': 'hi', 'name': 'हिन्दी', 'flag': '🇮🇳'},
  ];

  final List<Map<String, dynamic>> _themes = [
    {'type': theme_utils.ThemeType.system, 'name': 'System', 'icon': Icons.brightness_auto, 'descriptionKey': 'systemThemeDesc'},
    {'type': theme_utils.ThemeType.light, 'name': 'Light', 'icon': Icons.light_mode, 'descriptionKey': 'lightThemeDesc'},
    {'type': theme_utils.ThemeType.dark, 'name': 'Dark', 'icon': Icons.dark_mode, 'descriptionKey': 'darkThemeDesc'},
    {'type': theme_utils.ThemeType.solarizedLight, 'name': 'Solarized Light', 'icon': Icons.wb_sunny, 'descriptionKey': 'solarizedLightThemeDesc'},
    {'type': theme_utils.ThemeType.nordLight, 'name': 'Nord Light', 'icon': Icons.ac_unit, 'descriptionKey': 'nordLightThemeDesc'},
    {'type': theme_utils.ThemeType.gruvboxLight, 'name': 'Gruvbox Light', 'icon': Icons.palette, 'descriptionKey': 'gruvboxLightThemeDesc'},
    {'type': theme_utils.ThemeType.tokyoNight, 'name': 'Tokyo Night', 'icon': Icons.nights_stay, 'descriptionKey': 'tokyoNightThemeDesc'},
    {'type': theme_utils.ThemeType.dracula, 'name': 'Dracula', 'icon': Icons.nightlight, 'descriptionKey': 'draculaThemeDesc'},
    {'type': theme_utils.ThemeType.nord, 'name': 'Nord', 'icon': Icons.ac_unit, 'descriptionKey': 'nordThemeDesc'},
    {'type': theme_utils.ThemeType.gruvbox, 'name': 'Gruvbox', 'icon': Icons.palette, 'descriptionKey': 'gruvboxThemeDesc'},
    {'type': theme_utils.ThemeType.oneDark, 'name': 'One Dark', 'icon': Icons.code, 'descriptionKey': 'oneDarkThemeDesc'},
    {'type': theme_utils.ThemeType.catppuccin, 'name': 'Catppuccin', 'icon': Icons.pets, 'descriptionKey': 'catppuccinThemeDesc'},
  ];

  final List<Map<String, dynamic>> _searchEngines = [
    {'name': 'Google', 'icon': Icons.search},
    {'name': 'Bing', 'icon': Icons.search},
    {'name': 'DuckDuckGo', 'icon': Icons.privacy_tip},
    {'name': 'Brave', 'icon': Icons.shield},
    {'name': 'Yahoo', 'icon': Icons.search},
    {'name': 'Yandex', 'icon': Icons.search},
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _welcomeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _indicatorController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _indicatorAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _indicatorController,
      curve: Curves.elasticOut,
    ));

    _loadSettings();
    _startWelcomeAnimation();
  }

  void _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    setState(() {
      final localeCode = prefs.getString('locale') ?? 'en';
      _selectedLocale = Locale(localeCode);
      
      final themeString = prefs.getString('selectedTheme');
      if (themeString != null) {
        try {
          _selectedTheme = theme_utils.ThemeType.values.firstWhere((t) => t.name == themeString);
        } catch (e) {
          _selectedTheme = theme_utils.ThemeType.system;
        }
      } else {
        _selectedTheme = theme_utils.ThemeType.system;
      }
      
      _currentSearchEngine = prefs.getString('search_engine') ?? 'Google';
    });
  }

  void _saveLocalePreference(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', locale.languageCode);
    // Also save as 'language' for consistency with BrowserScreen and app
    await prefs.setString('language', locale.languageCode);
  }

  void _saveThemePreference(theme_utils.ThemeType theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedTheme', theme.name);
    await theme_utils.ThemeManager.setTheme(theme);
  }

  void _saveSearchEnginePreference(String engine) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('search_engine', engine);
  }

  void _startWelcomeAnimation() {
    // No animation needed for the new welcome screen design
  }

  theme_utils.ThemeColors _getCurrentThemeColors() {
    return theme_utils.ThemeManager.getThemeColors(_selectedTheme);
  }

  void _hideWelcome() {
    setState(() {
      _showWelcome = false;
    });
    _animationController.forward();
    _indicatorController.forward();
  }

  void _showPrivacyDialog(BuildContext context) {
    final themeColors = _getCurrentThemeColors();
    final languageCode = _selectedLocale.languageCode;
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return _PrivacyDialogWidget(
          themeColors: themeColors,
          languageCode: languageCode,
          localizations: AppLocalizations.of(context)!,
        );
      },
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    _welcomeAnimationController.dispose();
    _indicatorController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Only allow completion if notification permission was explicitly handled
      if (_notificationPermissionHandled) {
        _completeOnboarding();
      }
      // If not handled, stay on the permissions page
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    await prefs.setBool('first_start', false);
    
    // Apply settings
    widget.onLocaleChange(_selectedLocale);

    // Convert ThemeType to ThemeMode for the callback
    ThemeMode themeMode;
    switch (_selectedTheme) {
      case theme_utils.ThemeType.light:
      case theme_utils.ThemeType.solarizedLight:
      case theme_utils.ThemeType.nordLight:
      case theme_utils.ThemeType.gruvboxLight:
        themeMode = ThemeMode.light;
        break;
      case theme_utils.ThemeType.dark:
      case theme_utils.ThemeType.tokyoNight:
      case theme_utils.ThemeType.dracula:
      case theme_utils.ThemeType.nord:
      case theme_utils.ThemeType.gruvbox:
      case theme_utils.ThemeType.oneDark:
      case theme_utils.ThemeType.catppuccin:
        themeMode = ThemeMode.dark;
        break;
      default:
        themeMode = ThemeMode.system;
        break;
    }
    widget.onThemeChange(themeMode);
    widget.onSearchEngineChange(_currentSearchEngine);

    // Navigate to browser screen, pass selected search engine
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => BrowserScreen(
            onLocaleChange: (String locale) {
              final parts = locale.split('_');
              widget.onLocaleChange(Locale(parts[0], parts.length > 1 ? parts[1] : null));
            },
            onThemeChange: (bool isDarkMode) {
              widget.onThemeChange(isDarkMode ? ThemeMode.dark : ThemeMode.light);
            },
            onSearchEngineChange: widget.onSearchEngineChange,
            initialSearchEngine: _currentSearchEngine,
          ),
        ),
      );
    }
  }

  Widget _buildPageIndicators() {
    final themeColors = _getCurrentThemeColors();
    return AnimatedBuilder(
      animation: _indicatorAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _indicatorAnimation.value,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 8),
                height: 14,
                width: _currentPage == index ? 36 : 14,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(7),
                  color: _currentPage == index 
                    ? themeColors.textColor
                    // FIX 1: Replaced withValues with withOpacity
                    : themeColors.textColor.withOpacity(0.4),
                  boxShadow: _currentPage == index ? [
                    BoxShadow(
                      // FIX 2: Replaced withValues with withOpacity
                      color: themeColors.textColor.withOpacity(0.7),
                      blurRadius: 12,
                      spreadRadius: 3,
                    ),
                  ] : null,
                ),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildComboBox<T>({
    required String title,
    required List<Map<String, dynamic>> items,
    required T selectedValue,
    required Function(T) onChanged,
    required String Function(Map<String, dynamic>) getDisplayText,
    required String Function(Map<String, dynamic>) getSubtext,
    required Widget Function(Map<String, dynamic>) getIcon,
    required String Function(Map<String, dynamic>) getValue,
  }) {
    final themeColors = _getCurrentThemeColors();
    
    // Find the selected item
    Map<String, dynamic> selectedItem;
    try {
      selectedItem = items.firstWhere((item) => 
        getValue(item) == selectedValue.toString() ||
        (selectedValue is theme_utils.ThemeType && item['type'] == selectedValue) ||
        (selectedValue is Locale && item['code'] == selectedValue.languageCode) ||
        (selectedValue is String && item['name'] == selectedValue)
      );
    } catch (e) {
      selectedItem = items.first;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: themeColors.textColor,
          ),
        ),
        const SizedBox(height: 12),
        ExpansionTile(
          backgroundColor: themeColors.surfaceColor,
          collapsedBackgroundColor: themeColors.surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: themeColors.textColor.withOpacity(0.2)),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: themeColors.textColor.withOpacity(0.2)),
          ),
          iconColor: themeColors.textColor,
          collapsedIconColor: themeColors.textColor,
          title: Row(
            children: [
              // Selected item icon (if available)
              if (getIcon(selectedItem) is! SizedBox) ...[
                getIcon(selectedItem),
                const SizedBox(width: 16),
              ],
              // Selected item text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      getDisplayText(selectedItem),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: themeColors.textColor,
                      ),
                      textAlign: TextAlign.start,
                    ),
                    if (getSubtext(selectedItem).isNotEmpty)
                      Text(
                        getSubtext(selectedItem),
                        style: TextStyle(
                          fontSize: 13,
                          color: themeColors.textSecondaryColor,
                        ),
                        textAlign: TextAlign.start,
                      ),
                  ],
                ),
              ),
            ],
          ),
          children: [
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView(
                shrinkWrap: true,
                children: items.where((item) => 
                  getValue(item) != getValue(selectedItem)
                ).map((item) {
                  return GestureDetector(
                    onTap: () {
                      if (selectedValue is Locale) {
                        onChanged(Locale(getValue(item)) as T);
                      } else if (selectedValue is theme_utils.ThemeType) {
                        onChanged(item['type'] as T);
                      } else if (selectedValue is String) {
                        onChanged(item['name'] as T);
                      } else {
                        onChanged(getValue(item) as T);
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: themeColors.backgroundColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          // Icon (if available)
                          if (getIcon(item) is! SizedBox) ...[
                            getIcon(item),
                            const SizedBox(width: 16),
                          ],
                          // Text content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  getDisplayText(item),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: themeColors.textColor,
                                  ),
                                  textAlign: TextAlign.start,
                                ),
                                if (getSubtext(item).isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    getSubtext(item),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: themeColors.textSecondaryColor,
                                    ),
                                    textAlign: TextAlign.start,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getThemeDescription(String key) {
    final localizations = AppLocalizations.of(context)!;
    switch (key) {
      case 'systemThemeDesc': return localizations.systemThemeDesc;
      case 'lightThemeDesc': return localizations.lightThemeDesc;
      case 'darkThemeDesc': return localizations.darkThemeDesc;
      case 'solarizedLightThemeDesc': return localizations.solarizedLightThemeDesc;
      case 'nordLightThemeDesc': return localizations.nordLightThemeDesc;
      case 'gruvboxLightThemeDesc': return localizations.gruvboxLightThemeDesc;
      case 'tokyoNightThemeDesc': return localizations.tokyoNightThemeDesc;
      case 'draculaThemeDesc': return localizations.draculaThemeDesc;
      case 'nordThemeDesc': return localizations.nordThemeDesc;
      case 'gruvboxThemeDesc': return localizations.gruvboxThemeDesc;
      case 'oneDarkThemeDesc': return localizations.oneDarkThemeDesc;
      case 'catppuccinThemeDesc': return localizations.catppuccinThemeDesc;
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = _getCurrentThemeColors();
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [themeColors.backgroundColor, themeColors.surfaceColor],
          ),
        ),
        child: _showWelcome ? _buildWelcomeScreen() : _buildOnboardingContent(),
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    final themeColors = _getCurrentThemeColors();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Top bar with greeting
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                  Text(
                    AppLocalizations.of(context)!.solarKeyToCosmos,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: themeColors.textSecondaryColor,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            
            // Centered content
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Welcome text
                  Text(
                    AppLocalizations.of(context)!.welcome,
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: themeColors.textColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 60),
                  
                  // Language selection
                  _buildComboBox<Locale>(
                    title: AppLocalizations.of(context)!.chooseLanguage,
                    items: _supportedLocales,
                    selectedValue: _selectedLocale,
                    onChanged: (locale) {
                      setState(() {
                        _selectedLocale = locale;
                      });
                      // Apply the locale change immediately
                      widget.onLocaleChange(locale);
                      // Save to preferences
                      _saveLocalePreference(locale);
                      // Rebuild the UI to apply language changes
                      Future.delayed(const Duration(milliseconds: 100), () {
                        if (mounted) setState(() {});
                      });
                    },
                    getDisplayText: (item) => item['name']!,
                    getSubtext: (item) => item['code']!.toUpperCase(),
                    getIcon: (item) => Text(item['flag']!, style: const TextStyle(fontSize: 24)),
                    getValue: (item) => item['code']!,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Privacy policy and TOS text - clickable
                  GestureDetector(
                    onTap: () => _showPrivacyDialog(context),
                    child: Text(
                      AppLocalizations.of(context)!.termsOfService,
                      style: TextStyle(
                        fontSize: 14,
                        color: themeColors.textSecondaryColor,
                        fontWeight: FontWeight.w400,
                        decoration: TextDecoration.underline,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            
            // Continue button - circular with chevron
            Center(
              child: GestureDetector(
                onTap: _hideWelcome,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: themeColors.textColor,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: themeColors.textColor.withOpacity(0.3),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.chevron_right,
                    color: themeColors.backgroundColor,
                    size: 32,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingContent() {
    final themeColors = _getCurrentThemeColors();
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SafeArea(
        child: Column(
          children: [
            // Top bar with close button and indicators
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Close/Back button
                  GestureDetector(
                    onTap: () {
                      if (_currentPage > 0) {
                        _previousPage();
                      } else {
                        // Return to welcome screen instead of exiting
                        setState(() {
                          _showWelcome = true;
                          _currentPage = 0;
                          _notificationPermissionHandled = false; // Reset permission flag
                        });
                        _animationController.reset();
                        _indicatorController.reset();
                      }
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: themeColors.surfaceColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _currentPage > 0 ? Icons.chevron_left : Icons.close,
                        color: themeColors.textColor,
                        size: 20,
                      ),
                    ),
                  ),
                  
                  // Page indicators
                  _buildPageIndicators(),
                  
                  // Empty space for symmetry
                  const SizedBox(width: 32),
                ],
              ),
            ),
            
            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  _buildThemePage(),
                  _buildSearchEnginePage(),
                  _buildPermissionsPage(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemePage() {
    final themeColors = _getCurrentThemeColors();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            AppLocalizations.of(context)!.chooseTheme,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: themeColors.textColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.selectAppearance,
            style: TextStyle(
              fontSize: 16,
              color: themeColors.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          
          _buildComboBox<theme_utils.ThemeType>(
            title: AppLocalizations.of(context)!.appearance,
            items: _themes,
            selectedValue: _selectedTheme,
            onChanged: (theme) {
              setState(() {
                _selectedTheme = theme;
              });
              // Save to preferences and apply theme
              _saveThemePreference(theme);
            },
            getDisplayText: (item) => item['name']!,
            getSubtext: (item) => _getThemeDescription(item['descriptionKey']!),
            getIcon: (item) => Icon(item['icon'], color: themeColors.textColor, size: 24),
            getValue: (item) => item['type'].toString(),
          ),
          
          const SizedBox(height: 32),
          
          // Next button with chevron
          GestureDetector(
            onTap: _nextPage,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: themeColors.textColor,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: themeColors.textColor.withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                Icons.chevron_right,
                color: themeColors.backgroundColor,
                size: 32,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchEnginePage() {
    final themeColors = _getCurrentThemeColors();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            AppLocalizations.of(context)!.chooseSearchEngine,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: themeColors.textColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.selectSearchEngine,
            style: TextStyle(
              fontSize: 16,
              color: themeColors.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          
          _buildComboBox<String>(
            title: AppLocalizations.of(context)!.search_engine,
            items: _searchEngines,
            selectedValue: _currentSearchEngine,
            onChanged: (engine) {
              setState(() {
                _currentSearchEngine = engine;
              });
              // Apply the search engine change immediately  
              widget.onSearchEngineChange(engine);
              // Save to preferences
              _saveSearchEnginePreference(engine);
            },
            getDisplayText: (item) => item['name']!,
            getSubtext: (item) => '', // Hide URL
            getIcon: (item) => const SizedBox.shrink(), // Hide icon
            getValue: (item) => item['name']!,
          ),
          
          const SizedBox(height: 32),
          
          // Next button with chevron
          GestureDetector(
            onTap: _nextPage,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: themeColors.textColor,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: themeColors.textColor.withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                Icons.chevron_right,
                color: themeColors.backgroundColor,
                size: 32,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionsPage() {
    final themeColors = _getCurrentThemeColors();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Large notification icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: themeColors.surfaceColor,
              borderRadius: BorderRadius.circular(60),
              border: Border.all(color: themeColors.textColor.withOpacity(0.2), width: 2),
            ),
            child: Icon(
              Icons.notifications_outlined,
              size: 60,
              color: themeColors.textColor,
            ),
          ),
          const SizedBox(height: 32),
          
          // Title
          Text(
            AppLocalizations.of(context)!.notifications,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: themeColors.textColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          
          // Subtitle
          Text(
            AppLocalizations.of(context)!.notificationDescription,
            style: TextStyle(
              fontSize: 16,
              color: themeColors.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          
          // Allow button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () async {
                setState(() {
                  _notificationPermissionHandled = true;
                });
                await Permission.notification.request();
                _completeOnboarding();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColors.textColor,
                foregroundColor: themeColors.backgroundColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                AppLocalizations.of(context)!.allowNotifications,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Skip button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: TextButton(
              onPressed: () {
                setState(() {
                  _notificationPermissionHandled = true;
                });
                _completeOnboarding();
              },
              style: TextButton.styleFrom(
                foregroundColor: themeColors.textColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: themeColors.textColor.withOpacity(0.3)),
                ),
              ),
              child: Text(
                AppLocalizations.of(context)!.skipForNow,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacyDialogWidget extends StatefulWidget {
  final theme_utils.ThemeColors themeColors;
  final String languageCode;
  final AppLocalizations localizations;

  const _PrivacyDialogWidget({
    required this.themeColors,
    required this.languageCode,
    required this.localizations,
  });

  @override
  _PrivacyDialogWidgetState createState() => _PrivacyDialogWidgetState();
}

class _PrivacyDialogWidgetState extends State<_PrivacyDialogWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late TabController _tabController;
  late WebViewController _webViewController;
  
  int _selectedTab = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _selectedTab = _tabController.index;
          _isLoading = true;
        });
        _loadWebViewContent();
      }
    });
    
    _initializeWebView();
    _animationController.forward();
  }

  void _initializeWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(widget.themeColors.surfaceColor)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
        ),
      );
    
    _loadWebViewContent();
  }

  void _loadWebViewContent() {
    final baseUrl = 'https://browser.solar';
    final languagePath = widget.languageCode != 'en' ? '/${widget.languageCode}' : '';
    final pagePath = _selectedTab == 0 ? '/privacy-policy' : '/terms-of-use';
    final fullUrl = '$baseUrl$languagePath$pagePath';
    
    _webViewController.loadRequest(Uri.parse(fullUrl));
  }

  @override
  void dispose() {
    _animationController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.95,
                height: MediaQuery.of(context).size.height * 0.85,
                decoration: BoxDecoration(
                  color: widget.themeColors.surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      // FIX 3: Replaced withValues with withOpacity
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header with tabs
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: widget.themeColors.backgroundColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Column(
                        children: [
                          // Title and close button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.legalInformation,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: widget.themeColors.textColor,
                                ),
                              ),
                              IconButton(
                                onPressed: () => Navigator.of(context).pop(),
                                icon: Icon(
                                  Icons.close,
                                  color: widget.themeColors.textColor,
                                ),
                              ),
                            ],
                          ),
                          
                          // Tab bar
                          TabBar(
                            controller: _tabController,
                            indicatorColor: widget.themeColors.textColor,
                            labelColor: widget.themeColors.textColor,
                            unselectedLabelColor: widget.themeColors.textSecondaryColor,
                            tabs: [
                              Tab(text: widget.localizations.privacy_policy),
                              Tab(text: widget.localizations.terms_of_use),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // WebView content
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.zero,
                        child: Stack(
                          children: [
                            WebViewWidget(
                              controller: _webViewController,
                            ),
                            if (_isLoading)
                              Container(
                                color: widget.themeColors.surfaceColor,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      widget.themeColors.textColor,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Footer
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: widget.themeColors.backgroundColor,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(
                              AppLocalizations.of(context)!.acceptContinue,
                              style: TextStyle(
                                color: widget.themeColors.textColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}