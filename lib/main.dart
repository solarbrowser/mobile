import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/services.dart';
import 'l10n/app_localizations.dart';
import 'screens/browser_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/update_screen.dart';
import 'screens/pwa_screen.dart';
import 'utils/theme_manager.dart';
import 'services/ai_manager.dart';
import 'services/pwa_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Setup method channel to communicate with the platform
  final methodChannel = MethodChannel('app.channel.shared.data');
  
  // Register platform plugins
  final systemLocale = WidgetsBinding.instance.window.locale.languageCode;
  final systemDarkMode = WidgetsBinding.instance.window.platformBrightness == Brightness.dark;
  
  // Initialize AI Manager
  await AIManager.initialize();
  
  // Load preferences
  final prefs = await SharedPreferences.getInstance();
  final isFirstStart = prefs.getBool('first_start') ?? true;
  final lastVersion = prefs.getString('last_version') ?? '0.0.0';
  final packageInfo = await PackageInfo.fromPlatform();
  final currentVersion = packageInfo.version;
  
  // Check for initial deep link
  String? initialUrl;
  try {
    final platform = MethodChannel('com.solar.browser/shortcuts');
    initialUrl = await platform.invokeMethod('getInitialUrl');
  } catch (e) {
    print('Error getting initial URL: $e');
  }
  
  // Set default preferences if first start
  if (isFirstStart) {
    await prefs.setString('language', systemLocale);
    await prefs.setBool('darkMode', systemDarkMode);
    await prefs.setString('searchEngine', 'google');
    await prefs.setBool('first_start', false);
  }

  // Save current version after showing update screen
  if (lastVersion != currentVersion) {
    await prefs.setString('last_version', currentVersion);
  }
  
  // Load saved theme
  await ThemeManager.loadSavedTheme();
  
  runApp(MyApp(
    isFirstStart: isFirstStart,
    lastVersion: lastVersion,
    currentVersion: currentVersion,
    initialLocale: prefs.getString('language') ?? systemLocale,
    initialDarkMode: prefs.getBool('darkMode') ?? systemDarkMode,
    initialUrl: initialUrl,
  ));
}

class MyApp extends StatefulWidget {
  final bool isFirstStart;
  final String lastVersion;
  final String currentVersion;
  final String initialLocale;
  final bool initialDarkMode;
  final String? initialUrl;

  const MyApp({
    Key? key,
    required this.isFirstStart,
    required this.lastVersion,
    required this.currentVersion,
    required this.initialLocale,
    required this.initialDarkMode,
    this.initialUrl,
  }) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Locale _locale;
  late bool _isDarkMode;
  late String _searchEngine;
  bool _initialCheckDone = false;
  String? _initialPwaUrl;
  String? _initialPwaTitle;
  String? _initialPwaFavicon;

  @override
  void initState() {
    super.initState();
    _locale = Locale(widget.initialLocale);
    _isDarkMode = widget.initialDarkMode;
    _loadPreferences();
    _checkForPwaDeepLink();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _searchEngine = prefs.getString('searchEngine') ?? 'google';
    });
  }

  Future<void> _checkForPwaDeepLink() async {
    if (widget.initialUrl != null && widget.initialUrl!.startsWith('pwa://')) {
      final pwaUrl = widget.initialUrl!.replaceFirst('pwa://', '');
      
      // Check if this URL is in our PWA list
      final pwaList = await PWAManager.getAllPWAs();
      final matchingPwa = pwaList.firstWhere(
        (pwa) => pwa['url'] == pwaUrl,
        orElse: () => <String, dynamic>{},
      );
      
      if (matchingPwa.isNotEmpty) {
        // If found, store the values for use in our initial route
        setState(() {
          _initialPwaUrl = matchingPwa['url'] as String;
          _initialPwaTitle = matchingPwa['title'] as String;
          _initialPwaFavicon = matchingPwa['favicon'] as String?;
          _initialCheckDone = true;
        });
      } else {
        setState(() {
          _initialCheckDone = true;
        });
      }
    } else {
      setState(() {
        _initialCheckDone = true;
      });
    }
  }

  void _handleLocaleChange(String localeStr) {
    final parts = localeStr.split('_');
    setState(() {
      _locale = Locale(parts[0], parts.length > 1 ? parts[1] : null);
    });
  }

  void _handleThemeChange(bool isDarkMode) {
    setState(() {
      _isDarkMode = isDarkMode;
      
      // Force complete rebuild of the app with the new theme
      ThemeManager.setIsDarkMode(isDarkMode);
    });
    
    // Save the theme preference
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('darkMode', isDarkMode);
    });
  }

  void _handleSearchEngineChange(String searchEngine) {
    setState(() {
      _searchEngine = searchEngine;
    });
  }

  @override
  Widget build(BuildContext context) {
    // If we're still checking for PWA deep links, show loading
    if (!_initialCheckDone) {
      return MaterialApp(
        title: 'Solar',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.light(
            primary: Colors.blue,
            secondary: Colors.blueAccent,
          ),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.dark(
            primary: Colors.blue,
            secondary: Colors.blueAccent,
          ),
        ),
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return MaterialApp(
      title: 'Solar',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.light(
          primary: Colors.blue,
          secondary: Colors.blueAccent,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.dark(
          primary: Colors.blue,
          secondary: Colors.blueAccent,
        ),
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: _locale,
      home: Builder(
        builder: (context) {
          // Handle PWA deep link if present
          if (_initialPwaUrl != null) {
            return PWAScreen(
              url: _initialPwaUrl!,
              title: _initialPwaTitle!,
              favicon: _initialPwaFavicon,
            );
          }
          
          // Normal app startup flow
          if (widget.isFirstStart) {
            return WelcomeScreen(
              onLocaleChange: _handleLocaleChange,
              onThemeChange: _handleThemeChange,
              onSearchEngineChange: _handleSearchEngineChange,
            );
          } else if (widget.lastVersion != widget.currentVersion) {
            return UpdateScreen(
              currentVersion: widget.currentVersion,
              oldVersion: widget.lastVersion,
              onLocaleChange: _handleLocaleChange,
            );
          } else {
            return BrowserScreen(
              onLocaleChange: _handleLocaleChange,
              onThemeChange: _handleThemeChange,
              onSearchEngineChange: _handleSearchEngineChange,
            );
          }
        },
      ),
    );
  }
}