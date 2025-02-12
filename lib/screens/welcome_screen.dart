import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import 'dart:ui';
import 'package:package_info_plus/package_info_plus.dart';
import 'update_screen.dart';

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
  int _currentPage = 0;
  String _selectedLanguage = 'en';
  bool _isDarkMode = false;
  String _selectedSearchEngine = 'google';

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
    'ar': 'العربية',
    'hi': 'हिन्दी',
  };

  final Map<String, String> _searchEngines = {
    'google': 'Google',
    'duckduckgo': 'DuckDuckGo',
    'bing': 'Bing',
    'yahoo': 'Yahoo',
  };

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    _animationController.forward();
    
    // Get system theme
    final window = WidgetsBinding.instance.window;
    _isDarkMode = window.platformBrightness == Brightness.dark;
    
    // Get system language
    final locale = window.locale.languageCode;
    if (_languages.containsKey(locale)) {
      _selectedLanguage = locale;
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
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => UpdateScreen(
          currentVersion: packageInfo.version,
          oldVersion: '0.0.0',
          onLocaleChange: widget.onLocaleChange,
        ),
      ),
    );
  }

  Widget _buildGlassmorphicContainer({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.2),
                Colors.white.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildGlassmorphicContainer(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Image.asset(
                    'assets/icon.png',
                    width: 120,
                    height: 120,
                  ),
                  const SizedBox(height: 30),
                  Text(
                    'Welcome to Solar',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: _isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'A modern, fast, and secure browser',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: _isDarkMode ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguagePage() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Choose Your Language',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: _isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 30),
        _buildGlassmorphicContainer(
          child: Container(
            height: 400,
            width: 300,
            padding: const EdgeInsets.all(20),
            child: ListView.builder(
              itemCount: _languages.length,
              itemBuilder: (context, index) {
                final language = _languages.keys.elementAt(index);
                final name = _languages[language]!;
                return ListTile(
                  title: Text(
                    name,
                    style: TextStyle(
                      color: _isDarkMode ? Colors.white : Colors.black,
                      fontWeight: _selectedLanguage == language ? 
                        FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: _selectedLanguage == language ? 
                    Icon(Icons.check, color: _isDarkMode ? Colors.white : Colors.black) : null,
                  onTap: () {
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Choose Your Theme',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: _isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 30),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildGlassmorphicContainer(
              child: GestureDetector(
                onTap: () => setState(() => _isDarkMode = false),
                child: Container(
                  width: 150,
                  height: 200,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: !_isDarkMode ? Border.all(
                      color: _isDarkMode ? Colors.white : Colors.black,
                      width: 2,
                    ) : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.light_mode,
                        color: _isDarkMode ? Colors.white : Colors.black,
                        size: 40,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Light',
                        style: TextStyle(
                          color: _isDarkMode ? Colors.white : Colors.black,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 20),
            _buildGlassmorphicContainer(
              child: GestureDetector(
                onTap: () => setState(() => _isDarkMode = true),
                child: Container(
                  width: 150,
                  height: 200,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: _isDarkMode ? Border.all(
                      color: _isDarkMode ? Colors.white : Colors.black,
                      width: 2,
                    ) : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.dark_mode,
                        color: _isDarkMode ? Colors.white : Colors.black,
                        size: 40,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Dark',
                        style: TextStyle(
                          color: _isDarkMode ? Colors.white : Colors.black,
                          fontSize: 16,
                        ),
                      ),
                    ],
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Choose Your Search Engine',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: _isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 30),
        _buildGlassmorphicContainer(
          child: Container(
            height: 300,
            width: 300,
            padding: const EdgeInsets.all(20),
            child: ListView.builder(
              itemCount: _searchEngines.length,
              itemBuilder: (context, index) {
                final engine = _searchEngines.keys.elementAt(index);
                final name = _searchEngines[engine]!;
                return ListTile(
                  title: Text(
                    name,
                    style: TextStyle(
                      color: _isDarkMode ? Colors.white : Colors.black,
                      fontWeight: _selectedSearchEngine == engine ? 
                        FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: _selectedSearchEngine == engine ? 
                    Icon(Icons.check, color: _isDarkMode ? Colors.white : Colors.black) : null,
                  onTap: () {
                    setState(() {
                      _selectedSearchEngine = engine;
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
              ? [Colors.black, Colors.black87]
              : [Colors.white, Colors.grey.shade100],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView(
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
              ),
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentPage > 0)
            TextButton(
              onPressed: () {
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: Text(
                AppLocalizations.of(context)!.back,
                style: TextStyle(
                  color: _isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
            )
          else
            const SizedBox(width: 80),
          Row(
            children: List.generate(4, (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentPage == index
                  ? (_isDarkMode ? Colors.white : Colors.black)
                  : (_isDarkMode ? Colors.white24 : Colors.black12),
              ),
            )),
          ),
          TextButton(
            onPressed: () {
              if (_currentPage < 3) {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              } else {
                _handleContinue();
              }
            },
            child: Text(
              _currentPage < 3 
                ? AppLocalizations.of(context)!.next
                : AppLocalizations.of(context)!.getStarted,
              style: TextStyle(
                color: _isDarkMode ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 