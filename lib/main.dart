import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'l10n/app_localizations.dart';
import 'screens/browser_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/pwa_screen.dart';
import 'utils/theme_manager.dart';
import 'utils/performance_optimizer.dart';
import 'services/ai_manager.dart';
import 'services/pwa_manager.dart';
import 'firebase_options.dart';

void main() async {
  // Ensure Flutter is initialized with performance optimizations
  final binding = WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    //print('✅ Firebase initialized in main.dart');
  } catch (e) {
    //print('❌ Firebase initialization failed in main.dart: $e');
    // Don't throw error - app should still work without Firebase
  }
  
  // Optimize image caching for better performance
  binding.deferFirstFrame();
  PaintingBinding.instance.imageCache.maximumSizeBytes = 1024 * 1024 * 100; // 100 MB cache
  
  // Enable performance optimizations
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    // Log errors to analytics service
  };
    // Setup method channel to communicate with the platform
  // final methodChannel = MethodChannel('app.channel.shared.data'); // Currently unused
  
  // Register platform plugins
  final systemLocale = WidgetsBinding.instance.window.locale.languageCode;
  final systemDarkMode = WidgetsBinding.instance.window.platformBrightness == Brightness.dark;
    // Initialize performance optimizer
  final performanceOptimizer = PerformanceOptimizer();
  await performanceOptimizer.initialize();
  
  // Initialize AI Manager
  await AIManager.initialize();
  
  // Load preferences - use memory cache
  final prefs = await SharedPreferences.getInstance();
  
  // Register shared preferences cache for cleanup
  performanceOptimizer.registerCache('sharedPrefs', () {
    // No-op as we want to keep preferences
  });
  
  // Allow frame to be drawn after initial setup
  binding.allowFirstFrame();
  final isFirstStart = prefs.getBool('first_start') ?? true;
  final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
  final packageInfo = await PackageInfo.fromPlatform();
  final currentVersion = packageInfo.version;
  
  // Check for initial deep link
  String? initialUrl;
  try {
    final platform = MethodChannel('com.solar.browser/shortcuts');
    initialUrl = await platform.invokeMethod('getInitialUrl');
  } catch (e) {
    //print('Error getting initial URL: $e');
  }
  
  // Set default preferences if first start
  if (isFirstStart) {
    await prefs.setString('language', systemLocale);
    await prefs.setBool('darkMode', systemDarkMode);
    await prefs.setString('searchEngine', 'google');
    // Don't set first_start to false here - let onboarding handle it
  }
  
  // Load saved theme
  await ThemeManager.loadSavedTheme();
  
  runApp(MyApp(
    isFirstStart: isFirstStart,
    onboardingCompleted: onboardingCompleted,
    currentVersion: currentVersion,
    initialLocale: prefs.getString('language') ?? systemLocale,
    initialDarkMode: prefs.getBool('darkMode') ?? systemDarkMode,
    initialUrl: initialUrl,
  ));
}

class MyApp extends StatefulWidget {
  final bool isFirstStart;
  final bool onboardingCompleted;
  final String currentVersion;
  final String initialLocale;
  final bool initialDarkMode;
  final String? initialUrl;

  const MyApp({
    Key? key,
    required this.isFirstStart,
    required this.onboardingCompleted,
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
  // late String _searchEngine; // Currently unused
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
      // _searchEngine = prefs.getString('searchEngine') ?? 'google'; // Currently unused
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

  void _handleLocaleChange(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  void _handleLocaleChangeString(String localeStr) {
    final parts = localeStr.split('_');
    setState(() {
      _locale = Locale(parts[0], parts.length > 1 ? parts[1] : null);
    });
  }

  void _handleThemeChange(ThemeMode themeMode) {
    setState(() {
      _isDarkMode = themeMode == ThemeMode.dark;
      
      // Force complete rebuild of the app with the new theme
      ThemeManager.setIsDarkMode(_isDarkMode);
    });
    
    // Save the theme preference
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('darkMode', _isDarkMode);
    });
  }

  void _handleThemeChangeBool(bool isDarkMode) {
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
      // _searchEngine = searchEngine; // Currently unused
    });
  }
  // Pre-defined themes for performance
  final ThemeData _lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary: Colors.blue,
      secondary: Colors.blueAccent,
    ),
    // Performance optimizations
    visualDensity: VisualDensity.compact,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
  
  final ThemeData _darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.dark(
      primary: Colors.blue,
      secondary: Colors.blueAccent,
    ),
    // Performance optimizations
    visualDensity: VisualDensity.compact,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );

  @override
  Widget build(BuildContext context) {
    // If we're still checking for PWA deep links, show loading
    if (!_initialCheckDone) {
      return MaterialApp(
        title: 'Solar',
        debugShowCheckedModeBanner: false,
        theme: _lightTheme,
        darkTheme: _darkTheme,
        themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
        home: const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return MaterialApp(
      title: 'Solar',
      debugShowCheckedModeBanner: false,
      theme: _lightTheme,
      darkTheme: _darkTheme,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      // Performance optimizations
      builder: (context, child) {
        // Apply text scaling optimization and force LTR direction
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaleFactor: 1.0, // Fixed text scale for consistent UI
          ),
          child: Directionality(
            textDirection: TextDirection.ltr, // Force LTR direction even for RTL languages like Arabic
            child: child!,
          ),
        );
      },
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
          if (widget.isFirstStart || !widget.onboardingCompleted) {
            return OnboardingScreen(
              onLocaleChange: _handleLocaleChange,
              onThemeChange: _handleThemeChange,
              onSearchEngineChange: _handleSearchEngineChange,
            );
          } else {
            return BrowserScreen(
              onLocaleChange: _handleLocaleChangeString,
              onThemeChange: _handleThemeChangeBool,
              onSearchEngineChange: _handleSearchEngineChange,
            );
          }
        },
      ),
    );
  }
}