import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import 'dart:ui';
import 'dart:math';
import 'package:package_info_plus/package_info_plus.dart';
import 'update_screen.dart';
import 'package:simple_animations/simple_animations.dart';
import 'package:supercharged/supercharged.dart';
import 'browser_screen.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';

class WelcomeScreen extends StatefulWidget {
  final Function(String) onLocaleChange;
  final Function(bool) onThemeChange;
  final Function(String) onSearchEngineChange;
  
  const WelcomeScreen({
    Key? key,
    required this.onLocaleChange,
    required this.onThemeChange,
    required this.onSearchEngineChange,
  }) : super(key: key);

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _floatAnimation;
  int _currentPage = 0;
  String _selectedLanguage = 'en';
  bool _isDarkMode = false;
  String _selectedSearchEngine = 'Google';

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
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _floatAnimation = Tween<double>(begin: 0, end: 15)
        .animate(CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeInOut,
        ));
        
    _animationController.forward();
    _animationController.repeat(reverse: true);
    
    // Initialize preferences after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initSystemPreferences();
    });
  }

  void _initSystemPreferences() {
    final window = WidgetsBinding.instance.window;
    
    // Set system theme
    final isDark = window.platformBrightness == Brightness.dark;
    if (isDark != _isDarkMode) {
      setState(() {
        _isDarkMode = isDark;
      });
      widget.onThemeChange(isDark);
    }
    
    // Set system language
    final List<Locale> systemLocales = window.locales;
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
    super.dispose();
  }

  void _handleContinue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('first_start', false);
    
    if (!mounted) return;
    
    final packageInfo = await PackageInfo.fromPlatform();
    final lastShownVersion = prefs.getString('last_shown_version') ?? '0.0.0';
    
    if (packageInfo.version != lastShownVersion) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => UpdateScreen(
            currentVersion: packageInfo.version,
            oldVersion: lastShownVersion,
            onLocaleChange: widget.onLocaleChange,
          ),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => BrowserScreen(
            onLocaleChange: widget.onLocaleChange,
          ),
        ),
      );
    }
  }

  Widget _buildGlassmorphicContainer({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(_isDarkMode ? 0.1 : 0.2),
                Colors.white.withOpacity(_isDarkMode ? 0.05 : 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Colors.white.withOpacity(_isDarkMode ? 0.1 : 0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildParticleBackground() {
    return CustomAnimationBuilder<double>(
      tween: 0.0.tweenTo(2 * 3.14),
      duration: const Duration(seconds: 10),
      builder: (context, value, child) {
        return CustomPaint(
          painter: ParticlePainter(
            angle: value,
            isDarkMode: _isDarkMode,
          ),
          child: child,
        );
      },
      child: Container(),
    );
  }

  Widget _buildWelcomePage() {
    final size = MediaQuery.of(context).size;
    final isLargeScreen = size.width > 600;

    return Stack(
      children: [
        _buildParticleBackground(),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: size.width * 0.08, // Adaptive padding
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _floatAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _floatAnimation.value),
                        child: _buildGlassmorphicContainer(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: size.width * 0.05,
                              vertical: size.height * 0.03,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Hero(
                                  tag: 'logo',
                                  child: Image.asset(
                                    'assets/icon.png',
                                    width: isLargeScreen ? 120 : 80,
                                    height: isLargeScreen ? 120 : 80,
                                  ),
                                ),
                                SizedBox(height: size.height * 0.02),
                                ShaderMask(
                                  shaderCallback: (bounds) => LinearGradient(
                                    colors: _isDarkMode
                                        ? [Colors.white, Colors.white70]
                                        : [Colors.black, Colors.black87],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ).createShader(bounds),
                                  child: Text(
                                    AppLocalizations.of(context)!.welcomeToSolar,
                                    style: TextStyle(
                                      fontSize: isLargeScreen ? 32 : 24,
                                      fontWeight: FontWeight.bold,
                                      color: _isDarkMode ? Colors.white : Colors.black,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                SizedBox(height: size.height * 0.015),
                                Text(
                                  AppLocalizations.of(context)!.welcomeDescription,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: isLargeScreen ? 18 : 14,
                                    color: _isDarkMode ? Colors.white70 : Colors.black87,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: size.height * 0.03),
                  GestureDetector(
                    onTap: () => _showTermsDialog(),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: AppLocalizations.of(context)!.termsOfService,
                            style: TextStyle(
                              fontSize: isLargeScreen ? 16 : 13,
                              color: _isDarkMode ? Colors.white60 : Colors.black54,
                              fontWeight: FontWeight.bold
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showTermsDialog() {
    showGeneralDialog(
      context: context,
      pageBuilder: (context, animation, secondaryAnimation) {
        return Container(); // Placeholder
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );

        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(curvedAnimation),
          child: FadeTransition(
            opacity: animation,
            child: AlertDialog(
              backgroundColor: _isDarkMode 
                ? Colors.grey[900] 
                : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: AppLocalizations.of(context)!.terms_of_use,
                      style: TextStyle(
                        color: _isDarkMode ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    TextSpan(
                      text: ' & ',
                      style: TextStyle(
                        color: _isDarkMode ? Colors.white70 : Colors.black87,
                        fontSize: 18,
                      ),
                    ),
                    TextSpan(
                      text: AppLocalizations.of(context)!.privacy_policy,
                      style: TextStyle(
                        color: _isDarkMode ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
              content: Container(
                width: double.maxFinite,
                constraints: const BoxConstraints(maxHeight: 400),
                child: ListView(
                  children: [
                    Text(
                      AppLocalizations.of(context)!.termsOfService,
                      style: TextStyle(
                        color: _isDarkMode ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.data_collection + ':',
                      style: TextStyle(
                        color: _isDarkMode ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.data_collection_details,
                      style: TextStyle(
                        color: _isDarkMode ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    AppLocalizations.of(context)!.continueText,
                    style: TextStyle(
                      color: _isDarkMode ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  Widget _buildLanguagePage() {
    final size = MediaQuery.of(context).size;
    final isLargeScreen = size.width > 600;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          AppLocalizations.of(context)!.chooseLanguage,
          style: TextStyle(
            fontSize: isLargeScreen ? 32 : 24,
            fontWeight: FontWeight.bold,
            color: _isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        SizedBox(height: size.height * 0.04),
        _buildGlassmorphicContainer(
          child: Container(
            height: size.height * 0.4,
            width: isLargeScreen ? 400 : 280,
            padding: EdgeInsets.symmetric(vertical: size.height * 0.015),
            child: ListView.builder(
              itemCount: _languages.length,
              itemBuilder: (context, index) {
                final language = _languages.keys.elementAt(index);
                final name = _languages[language]!;
                return ListTile(
                  dense: true,
                  visualDensity: const VisualDensity(vertical: -2),
                  title: Text(
                    name,
                    style: TextStyle(
                      color: _isDarkMode ? Colors.white : Colors.black,
                      fontSize: isLargeScreen ? 18 : 15,
                      fontWeight: _selectedLanguage == language ? 
                        FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: _selectedLanguage == language ? 
                    Icon(Icons.check, 
                      color: _isDarkMode ? Colors.white : Colors.black,
                      size: isLargeScreen ? 24 : 20,
                    ) : null,
                  onTap: () {
                    widget.onLocaleChange(language);
                    setState(() {
                      _selectedLanguage = language;
                    });
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildThemePage() {
    final size = MediaQuery.of(context).size;
    final isLargeScreen = size.width > 600;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          AppLocalizations.of(context)!.chooseTheme,
          style: TextStyle(
            fontSize: isLargeScreen ? 32 : 24,
            fontWeight: FontWeight.bold,
            color: _isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        SizedBox(height: size.height * 0.04),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildGlassmorphicContainer(
              child: Container(
                width: isLargeScreen ? size.width * 0.25 : 120,
                height: isLargeScreen ? size.height * 0.25 : 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  border: !_isDarkMode ? Border.all(
                    color: _isDarkMode ? Colors.white70 : Colors.black54,
                    width: 1.5,
                  ) : null,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(30),
                    onTap: () => setState(() {
                      _isDarkMode = false;
                      widget.onThemeChange(false);
                    }),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.light_mode,
                          color: _isDarkMode ? Colors.white70 : Colors.black87,
                          size: isLargeScreen ? 48 : 32,
                        ),
                        SizedBox(height: size.height * 0.02),
                        Text(
                          AppLocalizations.of(context)!.lightTheme,
                          style: TextStyle(
                            color: _isDarkMode ? Colors.white70 : Colors.black87,
                            fontSize: isLargeScreen ? 20 : 16,
                            fontWeight: !_isDarkMode ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: size.width * 0.05),
            _buildGlassmorphicContainer(
              child: Container(
                width: isLargeScreen ? size.width * 0.25 : 120,
                height: isLargeScreen ? size.height * 0.25 : 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  border: _isDarkMode ? Border.all(
                    color: _isDarkMode ? Colors.white70 : Colors.black54,
                    width: 1.5,
                  ) : null,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(30),
                    onTap: () => setState(() {
                      _isDarkMode = true;
                      widget.onThemeChange(true);
                    }),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.dark_mode,
                          color: _isDarkMode ? Colors.white70 : Colors.black87,
                          size: isLargeScreen ? 48 : 32,
                        ),
                        SizedBox(height: size.height * 0.02),
                        Text(
                          AppLocalizations.of(context)!.darkTheme,
                          style: TextStyle(
                            color: _isDarkMode ? Colors.white70 : Colors.black87,
                            fontSize: isLargeScreen ? 20 : 16,
                            fontWeight: _isDarkMode ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchEnginePage() {
    final size = MediaQuery.of(context).size;
    final isLargeScreen = size.width > 600;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          AppLocalizations.of(context)!.chooseSearchEngine,
          style: TextStyle(
            fontSize: isLargeScreen ? 32 : 24,
            fontWeight: FontWeight.bold,
            color: _isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        SizedBox(height: size.height * 0.04),
        _buildGlassmorphicContainer(
          child: Container(
            height: size.height * 0.4,
            width: isLargeScreen ? 400 : 280,
            padding: EdgeInsets.symmetric(vertical: size.height * 0.015),
            child: ListView.builder(
              itemCount: _searchEngines.length,
              itemBuilder: (context, index) {
                final engine = _searchEngines.keys.elementAt(index);
                final name = _searchEngines[engine]!;
                return ListTile(
                  dense: true,
                  visualDensity: const VisualDensity(vertical: -2),
                  title: Text(
                    name,
                    style: TextStyle(
                      color: _isDarkMode ? Colors.white : Colors.black,
                      fontSize: isLargeScreen ? 18 : 15,
                      fontWeight: _selectedSearchEngine == engine ? 
                        FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: _selectedSearchEngine == engine ? 
                    Icon(Icons.check, 
                      color: _isDarkMode ? Colors.white : Colors.black,
                      size: isLargeScreen ? 24 : 20,
                    ) : null,
                  onTap: () {
                    setState(() {
                      _selectedSearchEngine = engine;
                      widget.onSearchEngineChange(engine);
                    });
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isDarkMode ? Colors.black : Colors.white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _isDarkMode 
              ? [
                  Color(0xFF1a1a1a),
                  Color(0xFF0a0a0a),
                ]
              : [
                  Color(0xFFffffff),
                  Color(0xFFf0f0f0),
                ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              PageView(
                controller: _pageController,
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
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildBottomBar(),
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

    return Padding(
      padding: EdgeInsets.only(
        left: size.width * 0.05,
        right: size.width * 0.05,
        bottom: size.height * 0.03,
      ),
      child: _buildGlassmorphicContainer(
        child: Container(
          height: isLargeScreen ? 72 : 56,
          padding: EdgeInsets.symmetric(horizontal: size.width * 0.05),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_currentPage > 0)
                TextButton(
                  onPressed: () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOutCubic,
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size(isLargeScreen ? 80 : 60, isLargeScreen ? 48 : 36),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.back,
                    style: TextStyle(
                      color: _isDarkMode ? Colors.white70 : Colors.black54,
                      fontSize: isLargeScreen ? 18 : 15,
                    ),
                  ),
                )
              else
                SizedBox(width: isLargeScreen ? 80 : 60),
              Row(
                children: List.generate(4, (index) => Padding(
                  padding: EdgeInsets.symmetric(horizontal: isLargeScreen ? 4 : 2),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: _currentPage == index ? (isLargeScreen ? 24 : 16) : (isLargeScreen ? 8 : 6),
                    height: isLargeScreen ? 8 : 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(isLargeScreen ? 4 : 3),
                      color: _currentPage == index
                        ? (_isDarkMode ? Colors.white : Colors.black)
                        : (_isDarkMode ? Colors.white24 : Colors.black12),
                    ),
                  ),
                )),
              ),
              TextButton(
                onPressed: () {
                  if (_currentPage < 3) {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOutCubic,
                    );
                  } else {
                    _handleContinue();
                  }
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size(isLargeScreen ? 80 : 60, isLargeScreen ? 48 : 36),
                ),
                child: Text(
                  _currentPage < 3
                    ? AppLocalizations.of(context)!.next
                    : AppLocalizations.of(context)!.getStarted,
                  style: TextStyle(
                    color: _isDarkMode ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: isLargeScreen ? 18 : 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ParticlePainter extends CustomPainter {
  final double angle;
  final bool isDarkMode;

  ParticlePainter({required this.angle, required this.isDarkMode});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    final particleCount = 50;
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final random = Random(42); // Fixed seed for consistent pattern

    for (var i = 0; i < particleCount; i++) {
      final radius = (i / particleCount) * size.width * 0.8;
      final x = centerX + radius * cos(angle + i * 0.2);
      final y = centerY + radius * sin(angle + i * 0.2);
      
      // Vary particle sizes and opacity
      final baseSize = 1.0 + (i / particleCount) * 4.0;
      final randomSize = baseSize * (0.5 + random.nextDouble());
      final opacity = 0.05 + (random.nextDouble() * 0.1);
      
      paint.color = (isDarkMode ? Colors.white : Colors.black).withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), randomSize, paint);
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => angle != oldDelegate.angle;
} 