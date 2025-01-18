import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/services.dart';
import 'l10n/app_localizations.dart';
import 'screens/browser_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/update_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load preferences
  final prefs = await SharedPreferences.getInstance();
  final isFirstStart = prefs.getBool('first_start') ?? true;
  final lastVersion = prefs.getString('last_version') ?? '0.0.0';
  final packageInfo = await PackageInfo.fromPlatform();
  final currentVersion = packageInfo.version;
  
  // Load system preferences
  final systemLocale = WidgetsBinding.instance.window.locale.languageCode;
  final systemDarkMode = WidgetsBinding.instance.window.platformBrightness == Brightness.dark;
  
  // Set default preferences if first start
  if (isFirstStart) {
    await prefs.setString('language', systemLocale);
    await prefs.setBool('darkMode', systemDarkMode);
    await prefs.setString('searchEngine', 'google');
  }
  
  runApp(MyApp(
    isFirstStart: isFirstStart,
    lastVersion: lastVersion,
    currentVersion: currentVersion,
    initialLocale: prefs.getString('language') ?? systemLocale,
    initialDarkMode: prefs.getBool('darkMode') ?? systemDarkMode,
  ));
}

class MyApp extends StatefulWidget {
  final bool isFirstStart;
  final String lastVersion;
  final String currentVersion;
  final String initialLocale;
  final bool initialDarkMode;

  const MyApp({
    Key? key,
    required this.isFirstStart,
    required this.lastVersion,
    required this.currentVersion,
    required this.initialLocale,
    required this.initialDarkMode,
  }) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late String _locale;
  late bool _isDarkMode;
  late String _searchEngine;

  @override
  void initState() {
    super.initState();
    _locale = widget.initialLocale;
    _isDarkMode = widget.initialDarkMode;
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _searchEngine = prefs.getString('searchEngine') ?? 'google';
    });
  }

  void _handleLocaleChange(String locale) {
    setState(() {
      _locale = locale;
    });
  }

  void _handleThemeChange(bool isDarkMode) {
    setState(() {
      _isDarkMode = isDarkMode;
    });
  }

  void _handleSearchEngineChange(String searchEngine) {
    setState(() {
      _searchEngine = searchEngine;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Solar Browser',
      theme: ThemeData(
        brightness: _isDarkMode ? Brightness.dark : Brightness.light,
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      locale: Locale(_locale),
      supportedLocales: const [
        Locale('en'),
        Locale('tr'),
        Locale('es'),
        Locale('fr'),
        Locale('de'),
        Locale('it'),
        Locale('pt'),
        Locale('ru'),
        Locale('zh'),
        Locale('ja'),
        Locale('ar'),
        Locale('hi'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Builder(
        builder: (context) {
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
            );
          } else {
            return BrowserScreen(
              onLocaleChange: _handleLocaleChange,
            );
          }
        },
      ),
    );
  }
}