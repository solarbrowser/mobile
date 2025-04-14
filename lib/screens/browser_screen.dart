import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';
import '../l10n/app_localizations.dart';
import '../models/tab_info.dart';
import '../utils/browser_utils.dart';
import '../utils/legal_texts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import '../utils/optimization_engine.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../widgets/custom_dialog.dart';
import '../widgets/custom_notification.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:solar/theme/theme_manager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:solar/services/notification_service.dart';
import 'package:solar/services/ai_manager.dart';
import 'package:solar/services/pwa_manager.dart';
import 'package:solar/screens/pwa_screen.dart';
import 'package:flutter/services.dart'; // For rootBundle

class Debouncer {
  final int milliseconds;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  void dispose() {
    _timer?.cancel();
  }
}

class BrowserScreen extends StatefulWidget {
  final Function(String)? onLocaleChange;
  final Function(bool)? onThemeChange;
  final Function(String)? onSearchEngineChange;
  final bool initialClassicMode;

  const BrowserScreen({
    Key? key,
    this.onLocaleChange,
    this.onThemeChange,
    this.onSearchEngineChange,
    this.initialClassicMode = true,
  }) : super(key: key);

  @override
  _BrowserScreenState createState() => _BrowserScreenState();
}

class BrowserTab {
  final String id;
  String url;
  String title;
  String? favicon;
  late WebViewController controller;
  bool isIncognito = false;
  bool canGoBack = false;
  bool canGoForward = false;

  BrowserTab({
    required this.id,
    required this.url,
    this.title = '',
    this.favicon,
    this.isIncognito = false,
  }) {
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..enableZoom(false);
    
    if (isIncognito) {
      controller.clearCache();
      controller.clearLocalStorage();
      controller.runJavaScript('''
        localStorage.clear();
        sessionStorage.clear();
        document.cookie = '';
        Object.defineProperty(document, 'cookie', { get: () => '', set: () => true });
      ''');
    }
    
    if (url.isNotEmpty && url != 'about:blank') {
      controller.loadRequest(Uri.parse(url));
    }
  }
}

// Top level class for the loading animation
class LoadingBorderPainter extends CustomPainter {
  final double progress;
  final Color color;

  LoadingBorderPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round; // Add rounded ends

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(28),
      ));

    final pathMetrics = path.computeMetrics().first;
    final length = pathMetrics.length;
    
    // Draw snake-like segment
    final snakeLength = length * 0.3; // Snake takes up 30% of the border
    final start = (progress * length) % length;
    final end = (start + snakeLength) % length;
    
    if (start < end) {
      final extractPath = pathMetrics.extractPath(start, end);
      canvas.drawPath(extractPath, paint);
    } else {
      // Handle wrap-around case
      final extractPath1 = pathMetrics.extractPath(start, length);
      final extractPath2 = pathMetrics.extractPath(0, end);
      canvas.drawPath(extractPath1, paint);
      canvas.drawPath(extractPath2, paint);
    }
  }

  @override
  bool shouldRepaint(LoadingBorderPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class _BrowserScreenState extends State<BrowserScreen> with SingleTickerProviderStateMixin {
  // WebView and Navigation
  final List<WebViewController> _controllers = [];
  late WebViewController controller;
  int currentTabIndex = 0;
  final List<BrowserTab> _suspendedTabs = [];
  static const int _maxActiveTabs = 5;
  List<BrowserTab> tabs = [];
  bool canGoBack = false;
  bool canGoForward = false;
  bool isSecure = false;
  bool allowHttp = true;
  bool isLoading = false;
  String? _currentFaviconUrl;
  
  // Platform channel for native communication
  final MethodChannel _platform = const MethodChannel('com.solar.browser/shortcuts');
  
  // Intent data handling
  String? _lastProcessedIntentUrl;
  bool _isLoadingIntentUrl = false;
  
  // URL Bar Animation State
  late AnimationController _hideUrlBarController;
  late Animation<Offset> _hideUrlBarAnimation;
  bool _hideUrlBar = false;
  double _lastScrollPosition = 0;
  bool _isScrollingUp = false;
  
  // Download State
  bool isDownloading = false;
  String currentDownloadUrl = '';
  double downloadProgress = 0.0;
  String? _currentFileName;
  int? _currentDownloadSize;
  List<Map<String, dynamic>> downloads = [];

  // Getters
  String? get currentFileName => _currentFileName;
  int? get currentDownloadSize => _currentDownloadSize;
  
  // Controllers
  late TextEditingController _urlController;
  late FocusNode _urlFocusNode;
  
  // UI State
  bool isDarkMode = false;
  double textScale = 1.0;
  bool showImages = true;
  String currentSearchEngine = 'Google';
  bool isSearchMode = false;
  String _displayUrl = '';
  bool _isUrlBarExpanded = false;
  bool isSecurityPanelVisible = false;
  bool _isClassicMode = false; // Changed to default false
  String securityMessage = '';
  String currentLanguage = 'en';
  DateTime lastScrollEvent = DateTime.now();
  int currentSearchMatch = 0;
  int totalSearchMatches = 0;
  Timer? _hideTimer;
  bool _isUrlBarMinimized = false;
  bool _isUrlBarHidden = false;
  int selectedSettingsTab = 0;
  
  // Panel Visibility
  bool isTabsVisible = false;
  bool isSettingsVisible = false;
  bool isBookmarksVisible = false;
  bool isDownloadsVisible = false;
  bool isPanelExpanded = false;
  bool isPanelVisible = true;
  bool _isLoading = false;  // Add loading state variable
  
  // URL Bar State
  bool _isUrlBarCollapsed = false;
  bool _isDragging = false;
  Offset _urlBarPosition = Offset.zero;
  Timer? _autoCollapseTimer;
  double dragStartX = 0;
  Timer? _loadingTimer;
  
  // Developer Options
  bool _isDeveloperMode = false;
  int _developerModeClickCount = 0;
  bool _showDeveloperOptions = false;
  String _debugLog = '';
  Timer? _developerModeTimer;
  
  // Home Page Settings
  String _homeUrl = 'file:///android_asset/main.html';
  String _searchEngine = 'google';
  bool _syncHomePageSearchEngine = true;
  String _homePageSearchEngine = 'google';
  List<Map<String, String>> _homePageShortcuts = [];
  
  // History Loading
  final ScrollController _historyScrollController = ScrollController();
  bool _isLoadingMore = false;
  int _currentHistoryPage = 0;
  final int _historyPageSize = 20;
  List<Map<String, dynamic>> _loadedHistory = [];
  
  // Animation
  late final AnimationController _slideAnimationController;
  late final Animation<Offset> _slideAnimation;
  late AnimationController _animationController;
  late Animation<double> _animation;
  
  // Data
  List<Map<String, dynamic>> bookmarks = [];
  
  // Memory Management
  final _debouncer = Debouncer(milliseconds: 300);
  bool _isLowMemory = false;
  int _lastMemoryCheck = 0;
  static const int MEMORY_CHECK_INTERVAL = 30000;

  bool isInitialized = false;

  ThemeColors get _colors => isDarkMode ? _darkModeColors : _lightModeColors;
  
  final _darkModeColors = ThemeColors(
    background: ThemeManager.backgroundColor(),
    surface: ThemeManager.surfaceColor(),
    text: ThemeManager.textColor(),
    textSecondary: ThemeManager.textSecondaryColor(),
    border: ThemeManager.textColor().withOpacity(0.24),
  );

  final _lightModeColors = ThemeColors(
    background: ThemeManager.backgroundColor(),
    surface: ThemeManager.surfaceColor(),
    text: ThemeManager.textColor(),
    textSecondary: ThemeManager.textSecondaryColor(),
    border: ThemeManager.textColor().withOpacity(0.12),
  );

  late OptimizationEngine _optimizationEngine;

  // Search Engines
  final Map<String, String> searchEngines = {
    'Google': 'https://www.google.com/search?q={query}',
    'Bing': 'https://www.bing.com/search?q={query}',
    'DuckDuckGo': 'https://duckduckgo.com/?q={query}',
    'Brave': 'https://search.brave.com/search?q={query}',
    'Yahoo': 'https://search.yahoo.com/search?p={query}',
    'Yandex': 'https://yandex.com/search/?text={query}',
  };

  // Add new state variables
  Timer? _urlBarIdleTimer;
  Offset _urlBarOffset = const Offset(16.0, 16.0);
  bool _isDraggingUrlBar = false;
  bool _askDownloadLocation = true;

  // Add new state variable for fullscreen
  bool _isFullscreen = false;

  // Add loading animation controller
  late AnimationController _loadingAnimationController;
  late Animation<double> _loadingAnimation;

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(2)} ${suffixes[i]}';
  }

  void _updateState(VoidCallback update) {
    _debouncer.run(() {
      if (mounted) {
        setState(update);
      }
    });
  }

  BoxDecoration _getGlassmorphicDecoration() {
    return BoxDecoration(
      color: ThemeManager.backgroundColor().withOpacity(0.7),
      borderRadius: BorderRadius.circular(28),
      border: Border.all(
        color: ThemeManager.textColor().withOpacity(0.1),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: ThemeManager.textColor().withOpacity(0.1),
          blurRadius: 20,
          spreadRadius: 0,
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    
    print("BrowserScreen initState called"); // Debug print
    
    // Set classic mode from widget parameter
    _isClassicMode = widget.initialClassicMode;
    
    // Start by initializing controllers
    _initializeControllers();
    
    // Initialize with a default tab
    tabs = [BrowserTab(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      url: 'file:///android_asset/main.html', 
      title: 'New Tab'
    )];
    
    _urlController = TextEditingController();
    _urlFocusNode = FocusNode();
    
    // Set up method channel for handling URLs
    const platform = MethodChannel('app.channel.shared.data');
    platform.setMethodCallHandler((call) async {
      print("Received method call: ${call.method}"); // Debug print
      
      if (!mounted) {
        print("Widget not mounted, ignoring method call"); // Debug print
        return;
      }
      
      switch (call.method) {
        case 'loadUrl':
          try {
            final url = call.arguments as String;
            print("Received URL to load: $url"); // Debug print
            
            // Wait a little to make sure everything is initialized
            Future.delayed(Duration(milliseconds: 500), () {
              if (mounted) {
                _loadUrl(url);
              }
            });
          } catch (e) {
            print("Error processing loadUrl call: $e");
          }
          break;
        case 'openNewTabWithSearch':
          try {
            final query = call.arguments as String;
            print("Received search query: $query"); // Debug print
            if (query != null && query.isNotEmpty) {
              final engine = searchEngines[currentSearchEngine] ?? searchEngines['Google']!;
              final searchUrl = engine.replaceAll('{query}', Uri.encodeComponent(query));
              print("Opening new tab with search URL: $searchUrl"); // Debug print
              _addNewTab(url: searchUrl);
            }
          } catch (e) {
            print("Error processing search query: $e");
          }
          break;
      }
    });
    
    // Listen for PWA direct opening events
    _platform.setMethodCallHandler((call) async {
      if (call.method == 'openPwaDirectly') {
        final pwaUrl = call.arguments as String;
        await _openPwaDirectly(pwaUrl);
        return true;
      }
      return null;
    });
    
    // Load preferences and other data
    _loadPreferences().then((_) {
      _loadBookmarks();
      _loadDownloads();
      _loadHistory();
      _loadUrlBarPosition();
      _loadSettings();
      _loadSearchEngines();
      
      // Mark as initialized at the end of initialization
      setState(() {
        isInitialized = true;
        print("BrowserScreen initialization completed"); // Debug print
      });
      
      // Check for a shared URL after initialization with retry logic
      _checkForSharedUrl();
    });

    // Initialize animation controller for dropdowns
    _animationController = AnimationController(
      vsync: this,
      duration: _dropdownDuration,
    );
    
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: _dropdownCurve,
    );
    
    // Initialize smooth animations
    _loadingAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    
    _loadingAnimation = CurvedAnimation(
      parent: _loadingAnimationController,
      curve: Curves.easeInOut,
    );
    
    // Add scroll listener for smooth animations
    _smoothScrollController.addListener(_handleScroll);
    
    // Initialize the optimization engine with better performance settings
    _optimizationEngine = OptimizationEngine();
  }
  
  void _handleScroll() {
    _scrollThrottle.run(() {
      if (!mounted) return;
      
      final scrollDelta = _smoothScrollController.position.pixels - _lastScrollPosition;
      _lastScrollPosition = _smoothScrollController.position.pixels;
      
      setState(() {
        _isScrollingUp = scrollDelta < 0;
        _hideUrlBar = !_isScrollingUp && _smoothScrollController.position.pixels > 100;
      });
    });
  }
  
  // New helper method to check for shared URL with retries
  void _checkForSharedUrl() {
    print("Checking for pending URLs after initialization"); // Debug print
    
    const platform = MethodChannel('app.channel.shared.data');
    
    // Try up to 3 times to get the shared URL
    int retryCount = 0;
    
    void tryGetUrl() {
      try {
        platform.invokeMethod<String>('getSharedUrl')
          .then((url) {
            print("Got shared URL from platform: $url"); // Debug print
            if (url != null && url.isNotEmpty && mounted) {
              print("Loading shared URL: $url"); // Debug print
              _loadUrl(url);
            }
          })
          .catchError((error) {
            print("Error getting shared URL: $error"); // Debug print
            
            // Retry if needed
            retryCount++;
            if (retryCount < 3) {
              print("Retrying getSharedUrl (attempt $retryCount)"); // Debug print
              Future.delayed(Duration(seconds: 1), tryGetUrl);
            }
          });
      } catch (e) {
        print("Exception when getting shared URL: $e"); // Debug print
      }
    }
    
    // Start the first attempt
    tryGetUrl();
  }
  
  // Open PWA directly from app shortcut
  Future<void> _openPwaDirectly(String url) async {
    try {
      final pwaList = await PWAManager.getAllPWAs();
      final matchingPwa = pwaList.firstWhere(
        (pwa) => pwa['url'] == url,
        orElse: () => <String, dynamic>{},
      );
      
      if (matchingPwa.isNotEmpty && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PWAScreen(
              url: matchingPwa['url'] as String,
              title: matchingPwa['title'] as String,
              favicon: matchingPwa['favicon'] as String?,
            ),
          ),
        );
      }
    } catch (e) {
      print('Error opening PWA directly: $e');
    }
  }

  Future<void> _handleIncomingIntents() async {
    // Handle URLs shared from other apps
    const platform = MethodChannel('app.channel.shared.data');
    String? sharedUrl = await platform.invokeMethod('getSharedUrl');
    
    if (sharedUrl != null && sharedUrl.isNotEmpty) {
      _loadUrl(sharedUrl);
    }
  }

  SystemUiOverlayStyle get _transparentNavBar {
    final backgroundColor = ThemeManager.backgroundColor();
    final isBackgroundDark = backgroundColor.computeLuminance() < 0.5;
    
    return SystemUiOverlayStyle(
      statusBarColor: backgroundColor,
      statusBarIconBrightness: isBackgroundDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isBackgroundDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: isBackgroundDark ? Brightness.light : Brightness.dark,
      systemNavigationBarContrastEnforced: false,
      systemNavigationBarDividerColor: Colors.transparent,
    );
  }

  void _updateSystemBars() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    final backgroundColor = ThemeManager.backgroundColor();
    final isBackgroundDark = backgroundColor.computeLuminance() < 0.5;
    
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: backgroundColor,
      statusBarIconBrightness: isBackgroundDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isBackgroundDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: isBackgroundDark ? Brightness.light : Brightness.dark,
      systemNavigationBarContrastEnforced: false,
      systemNavigationBarDividerColor: Colors.transparent,
    ));
  }

  void _toggleTheme(bool darkMode) async {
    // Set theme in the ThemeManager first for consistent appearance
    final theme = darkMode ? ThemeType.dark : ThemeType.light;
    await ThemeManager.setTheme(theme);
    
    setState(() {
      isDarkMode = darkMode;
    });
    
    _updateSystemBars();
    
    // Save theme preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', darkMode);
    await prefs.setString('selectedTheme', theme.name);
    
    if (widget.onThemeChange != null) {
      widget.onThemeChange!(darkMode);
    }
  }

  void _toggleClassicMode(bool classicMode) async {
    setState(() {
      _isClassicMode = classicMode;
    });
    await _savePreferences();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (tabs.isEmpty) {
      _addNewTab();
    }
  }

  @override
  void dispose() {
    _transitionController.dispose();
    _loadingAnimationController.dispose();
    _smoothScrollController.dispose();
    _scrollThrottle.dispose();
    super.dispose();
  }

  Future<void> _initializeControllers() async {
    // Initialize all animation controllers
    _slideUpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideAnimationController,
      curve: Curves.easeOutCubic,
    ));

    _loadingAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _loadingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _loadingAnimationController,
      curve: Curves.linear,
    ));
    _loadingAnimationController.repeat();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    );

    // Initialize URL bar animation controller
    _hideUrlBarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _hideUrlBarAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, 1.5),
    ).animate(CurvedAnimation(
      parent: _hideUrlBarController,
      curve: Curves.easeOutCubic,
    ));

    // Initialize other controllers
    _urlController = TextEditingController();
    _urlFocusNode = FocusNode();
    _urlFocusNode.addListener(() {
      if (mounted) {
        setState(() {
          _isUrlBarExpanded = _urlFocusNode.hasFocus;
          
          // When focus gained, show the full URL
          if (_urlFocusNode.hasFocus) {
            if (tabs.isNotEmpty && currentTabIndex >= 0 && currentTabIndex < tabs.length) {
              // Get the current tab's full URL and show it
              final fullUrl = tabs[currentTabIndex].url;
              _urlController.text = fullUrl;
              
              // Position cursor at the end
              _urlController.selection = TextSelection.fromPosition(
                TextPosition(offset: _urlController.text.length),
              );
            }
          } else {
            // When focus is lost, reformat to domain-only if we have a current tab
            if (tabs.isNotEmpty && currentTabIndex >= 0 && currentTabIndex < tabs.length) {
              final currentUrl = tabs[currentTabIndex].url;
              _urlController.text = _formatUrl(currentUrl);
            }
          }
        });
      }
    });

    await _initializeWebView();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load theme settings
    final savedThemeName = prefs.getString('selectedTheme');
    ThemeType theme;
    
    if (savedThemeName != null) {
      try {
        theme = ThemeType.values.firstWhere((t) => t.name == savedThemeName);
      } catch (_) {
        theme = ThemeType.light;
      }
    } else {
      // Fallback to darkMode preference if no theme is saved
      final isDark = prefs.getBool('darkMode') ?? false;
      theme = isDark ? ThemeType.dark : ThemeType.light;
    }
    
    // Apply theme
    await ThemeManager.setTheme(theme);
    
    setState(() {
      isDarkMode = theme.isDark;
      textScale = prefs.getDouble('textScale') ?? 1.0;
      showImages = prefs.getBool('showImages') ?? true;
      currentSearchEngine = prefs.getString('searchEngine') ?? 'Google';
      currentLanguage = prefs.getString('language') ?? 'en';
      
      // Use widget parameter for classic mode or fall back to preference
      if (widget.initialClassicMode) {
        _isClassicMode = true;
      } else {
        _isClassicMode = prefs.getBool('isClassicMode') ?? false;
      }
    });
    
    // Save updated classic mode preference
    await prefs.setBool('isClassicMode', _isClassicMode);
    
    // Update UI to reflect theme
    _updateSystemBars();
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', isDarkMode);
    await prefs.setString('homeUrl', _homeUrl);
    await prefs.setString('searchEngine', _searchEngine);
    await prefs.setBool('isClassicMode', _isClassicMode); // Save classic mode preference
  }

  Future<void> _initializeOptimizationEngine() async {
    _optimizationEngine = OptimizationEngine(controller);
    await _optimizationEngine.initialize();
  }

  Future<void> _loadDownloads() async {
    final prefs = await SharedPreferences.getInstance();
    final downloadsList = prefs.getStringList('downloads') ?? [];
    setState(() {
      downloads = downloadsList.map((e) {
        try {
          final map = Map<String, dynamic>.from(json.decode(e));
          // Ensure required fields exist and have correct types
          if (!map.containsKey('url') || 
              !map.containsKey('filename') || 
              !map.containsKey('path') ||
              !map.containsKey('size') ||
              !map.containsKey('timestamp')) {
            return null;
          }
          // Ensure proper types
          return {
            'url': map['url'] as String,
            'filename': map['filename'] as String,
            'path': map['path'] as String,
            'size': (map['size'] as num).toInt(),
            'timestamp': map['timestamp'] as String,
            'mimeType': map['mimeType'] as String? ?? 'application/octet-stream',
          };
        } catch (e) {
          print('Error parsing download: $e');
          return null;
        }
      }).whereType<Map<String, dynamic>>().toList();
    });
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    );

    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideAnimationController,
      curve: Curves.easeInOutCubic,
    ));
  }

  Future<void> _setupScrollHandling() async {
    await controller.runJavaScript('''
      let lastScrollY = window.scrollY;
      let lastScrollTime = Date.now();
      let ticking = false;

      function handleScroll() {
        const currentScrollY = window.scrollY;
        const currentTime = Date.now();
        const delta = currentScrollY - lastScrollY;
        
        // More sensitive scroll detection
        if (Math.abs(delta) > 2) {  // Reduced threshold
          if (window.flutter_inappwebview) {
            window.flutter_inappwebview.callHandler('onScroll', {
              scrollY: currentScrollY,
              delta: delta
            });
          }
          lastScrollTime = currentTime;
          lastScrollY = currentScrollY;
        }
      }

      window.addEventListener('scroll', function() {
        handleScroll();  // Immediate handling
      }, { passive: true });

      // Touch events for smoother mobile detection
      let touchStartY = 0;
      let lastTouchY = 0;

      window.addEventListener('touchstart', function(e) {
        touchStartY = e.touches[0].clientY;
        lastTouchY = touchStartY;
      }, { passive: true });

      window.addEventListener('touchmove', function(e) {
        const currentY = e.touches[0].clientY;
        const delta = lastTouchY - currentY;  // Reversed delta calculation
        
        if (Math.abs(delta) > 2) {  // More sensitive threshold
          if (window.flutter_inappwebview) {
            window.flutter_inappwebview.callHandler('onScroll', {
              scrollY: window.scrollY,
              delta: delta
            });
          }
          lastTouchY = currentY;
        }
      }, { passive: true });
    ''');

    await controller.addJavaScriptChannel(
      'onScroll',
      onMessageReceived: (JavaScriptMessage message) {
        if (!mounted) return;
        
        try {
          final data = json.decode(message.message);
          final delta = data['delta'] as double;
          
          if (delta.abs() > 2) {  // More sensitive threshold
            if (delta > 0) {  // Scrolling up (finger moving up) = hide URL bar
              if (!_hideUrlBar) {
                setState(() {
                  _hideUrlBar = true;
                  _hideUrlBarController.forward();
                });
              }
            } else {  // Scrolling down (finger moving down) = show URL bar
              if (_hideUrlBar) {
                setState(() {
                  _hideUrlBar = false;
                  _hideUrlBarController.reverse();
                });
              }
            }
          }
        } catch (e) {
          print('Error handling scroll: $e');
        }
      },
    );
  }

  Future<WebViewController> _initializeWebViewController() async {
    final webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..enableZoom(true);
    webViewController.setNavigationDelegate(await _navigationDelegate);
  
    if (webViewController.platform is AndroidWebViewController) {
      final androidController = webViewController.platform as AndroidWebViewController;
      await androidController.setMediaPlaybackRequiresUserGesture(false);
      await androidController.setBackgroundColor(Colors.transparent);
      
      // Set Chrome-like user agent to fix Google sign-in issues
      await androidController.setUserAgent(
        'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Mobile Safari/537.36'
      );
      
      // Enable hardware acceleration
      await webViewController.runJavaScript('''
        document.body.style.setProperty('-webkit-transform', 'translate3d(0,0,0)');
        document.body.style.setProperty('transform', 'translate3d(0,0,0)');
        document.body.style.setProperty('will-change', 'transform, opacity');
        document.body.style.setProperty('backface-visibility', 'hidden');
        document.body.style.setProperty('-webkit-backface-visibility', 'hidden');
      ''');
    }

    // Add JavaScript to help with browser verification for Google sign-in
    await webViewController.runJavaScript('''
      function enhanceBrowserVerification() {
        Object.defineProperty(navigator, 'vendor', {
          get: function() { return 'Google Inc.'; }
        });
        
        // Fix for Google's secure browser verification
        Object.defineProperty(window, 'chrome', {
          value: {
            app: {
              isInstalled: false
            },
            runtime: {}
          },
          writable: true
        });
      }
      enhanceBrowserVerification();
    ''');

    return webViewController;
  }

  Future<void> _loadHomePageSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _syncHomePageSearchEngine = prefs.getBool('syncHomePageSearchEngine') ?? true;
      _homePageSearchEngine = prefs.getString('homePageSearchEngine') ?? 'google';
      final shortcutsList = prefs.getStringList('homePageShortcuts') ?? [];
      _homePageShortcuts = shortcutsList.map((e) => Map<String, String>.from(json.decode(e))).toList();
    });
  }

  Future<void> _initializeWebView() async {
    print("Initializing WebView..."); // Debug print
    
    // Initialize a dummy optimization engine to prevent LateInitializationError
    _optimizationEngine = OptimizationEngine();

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..enableZoom(false)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) async {
            final url = request.url.toLowerCase();
            
            // Handle search:// protocol
            if (url.startsWith('search://')) {
              // Extract search term and search directly
              final searchTerm = url.substring(9).trim();
              if (searchTerm.isNotEmpty) {
                // Use search engine directly
                final engine = searchEngines[currentSearchEngine] ?? searchEngines['Google']!;
                final searchUrl = engine.replaceAll('{query}', Uri.encodeComponent(searchTerm));
                
                // Load the search URL directly
                await controller.loadRequest(Uri.parse(searchUrl));
                return NavigationDecision.prevent;
              }
            }
            
            if (_isDownloadUrl(url)) {
              await _handleDownload(request.url);
              return NavigationDecision.prevent;
            }
            
            // Update secure indicator based on URL
            setState(() {
              try {
                final uri = Uri.parse(request.url);
                isSecure = uri.scheme == 'https';
              } catch (e) {
                isSecure = false;
              }
            });
            
            return NavigationDecision.navigate;
          },
          onPageStarted: (String url) async {
            if (!mounted) return;
            setState(() {
              isLoading = true;
              _displayUrl = url;
              _urlController.text = _formatUrl(url);
              // Update secure indicator based on URL
              try {
                final uri = Uri.parse(url);
                isSecure = uri.scheme == 'https';
              } catch (e) {
                isSecure = false;
              }
            });
            await _updateNavigationState();
            // Safely call optimization engine methods
            try {
              await _optimizationEngine.onPageStartLoad(url);
            } catch (e) {
              print("Error in optimization engine: $e");
            }
          },
          onPageFinished: (String url) async {
            if (!mounted) return;
            print('=== PAGE FINISHED LOADING ===');
            final title = await controller.getTitle() ?? _displayUrl;
            
            // Use our central handler to consistently update URLs
            _handleUrlUpdate(url, title: title);
            
            // Update loading state
            setState(() {
              isLoading = false;
            });
            
            await _updateNavigationState();
            await _setupUrlMonitoring();
            
            // Safely call optimization engine
            try {
              await _optimizationEngine.onPageFinishLoad(url);
            } catch (e) {
              print("Error in optimization engine (onPageFinish): $e");
            }
            
            if (!tabs[currentTabIndex].isIncognito) {
              await _saveToHistory(url, title);
            }
          },
          onUrlChange: (UrlChange change) {
            if (!mounted) return;
            final url = change.url ?? '';
            
            // Use central helper method for consistent URL handling
            _handleUrlUpdate(url);
          },
          onWebResourceError: (WebResourceError error) async {
            if (!mounted) return;
            final currentUrl = await controller.currentUrl() ?? _displayUrl;
            await _handleWebResourceError(error, currentUrl);
          },
        ),
      );
    
    // Add JavaScript channel for search handling
    await controller.addJavaScriptChannel(
      'SearchHandler',
      onMessageReceived: (JavaScriptMessage message) {
        if (mounted) {
          final searchQuery = message.message;
          if (searchQuery.isNotEmpty) {
            // Use the search engine to perform the search
            final engine = searchEngines[currentSearchEngine] ?? searchEngines['Google']!;
            final searchUrl = engine.replaceAll('{query}', Uri.encodeComponent(searchQuery));
            
            // Load the search URL
            controller.loadRequest(Uri.parse(searchUrl));
          }
        }
      },
    );

    if (tabs.isNotEmpty && currentTabIndex >= 0 && currentTabIndex < tabs.length) {
      await controller.loadRequest(Uri.parse(tabs[currentTabIndex].url));
    }

    await _setupUrlMonitoring();
  }

  bool _isDownloadUrl(String url) {
    final downloadExtensions = [
      // Documents
      '.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx',
      '.odt', '.ods', '.odp', '.rtf', '.csv', '.txt',
      
      // Archives
      '.zip', '.rar', '.7z', '.tar', '.gz', '.bz2', '.xz',
      
      // Media
      '.mp3', '.mp4', '.wav', '.avi', '.mov', '.wmv', '.flv',
      '.mkv', '.m4a', '.m4v', '.3gp', '.aac', '.ogg', '.webm',
      
      // Images
      '.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp', '.svg',
      '.tiff', '.ico',
      
      // Software
      '.apk', '.exe', '.dmg', '.iso', '.img', '.msi', '.deb',
      '.rpm', '.pkg'
    ];

    // Check for direct download indicators
    return downloadExtensions.any((ext) => url.endsWith(ext)) ||
           url.startsWith('blob:') ||
           (url.startsWith('data:') && !url.contains('text/html')) ||
           url.contains('download=') ||
           url.contains('attachment') ||
           url.contains('/download/') ||
           url.contains('downloadfile') ||
           url.contains('getfile') ||
           url.contains('filedownload') ||
           (url.contains('?') && downloadExtensions.any((ext) => url.contains(ext)));
  }

  Future<void> _setupUrlMonitoring() async {
    await controller.runJavaScript('''
      (function() {
        let lastUrl = window.location.href;
        let lastTitle = document.title;
        
        function notifyUrlChanged() {
          const currentUrl = window.location.href;
          const currentTitle = document.title;
          
          // Always notify on navigation events
          if (window.UrlChanged && window.UrlChanged.postMessage) {
            window.UrlChanged.postMessage(JSON.stringify({
              url: currentUrl,
              title: currentTitle
            }));
          }
          
          lastUrl = currentUrl;
          lastTitle = currentTitle;
        }

        // Monitor all possible navigation events
        window.addEventListener('popstate', notifyUrlChanged, true);
        window.addEventListener('hashchange', notifyUrlChanged, true);
        window.addEventListener('load', notifyUrlChanged, true);
        window.addEventListener('navigate', notifyUrlChanged, true);
        
        // Monitor clicks on all links
        document.addEventListener('click', function(e) {
          const link = e.target.closest('a');
          if (link && link.href) {
            setTimeout(notifyUrlChanged, 100);
          }
        }, true);
        
        // Monitor form submissions
        document.addEventListener('submit', notifyUrlChanged, true);
        
        // Monitor programmatic changes
        const originalPushState = history.pushState;
        const originalReplaceState = history.replaceState;
        
        history.pushState = function() {
          originalPushState.apply(this, arguments);
          setTimeout(notifyUrlChanged, 100);
        };
        
        history.replaceState = function() {
          originalReplaceState.apply(this, arguments);
          setTimeout(notifyUrlChanged, 100);
        };
        
        // Monitor title changes
        const observer = new MutationObserver(() => setTimeout(notifyUrlChanged, 100));
        if (document.querySelector('title')) {
          observer.observe(document.querySelector('title'), { 
            subtree: true, 
            characterData: true, 
            childList: true 
          });
        }
        
        // Check frequently for URL changes
        setInterval(notifyUrlChanged, 300);
        
        // Initial check
        notifyUrlChanged();
      })();
    ''');

    await controller.addJavaScriptChannel(
      'UrlChanged',
      onMessageReceived: (JavaScriptMessage message) {
        if (mounted) {
          try {
            final data = json.decode(message.message);
            final url = data['url'] as String;
            final title = data['title'] as String;
            
            // Use central helper method for consistent URL handling
            _handleUrlUpdate(url, title: title);
            
            _updateNavigationState();
          } catch (e) {
            print('Error handling URL change: $e');
          }
        }
      },
    );
  }

  Future<void> _updateNavigationState() async {
    if (!mounted) return;
    
    try {
      final canGoBackValue = await controller.canGoBack();
      final canGoForwardValue = await controller.canGoForward();
      final currentUrl = await controller.currentUrl() ?? '';
      
      if (mounted) {
        setState(() {
          canGoBack = canGoBackValue;
          canGoForward = canGoForwardValue;
        });
        
        // Use the central helper method to update URLs consistently
        if (currentUrl.isNotEmpty) {
          _handleUrlUpdate(currentUrl);
        }
      }
    } catch (e) {
      print('Error updating navigation state: $e');
    }
  }

  Future<void> _setupWebViewCallbacks() async {
    // Add JavaScript for handling image long press
    await controller.runJavaScript('''
      (function() {
        let longPressTimer;
        let isLongPress = false;
        
        document.addEventListener('touchstart', function(e) {
          if (e.target.tagName === 'IMG') {
            isLongPress = false;
            longPressTimer = setTimeout(() => {
              isLongPress = true;
              const rect = e.target.getBoundingClientRect();
              const imageUrl = e.target.src;
              ImageLongPress.postMessage(JSON.stringify({
                url: imageUrl,
                x: e.touches[0].clientX,
                y: e.touches[0].clientY + window.scrollY
              }));
            }, 500);
          }
        }, true);
        
        document.addEventListener('touchend', function(e) {
          if (longPressTimer) {
            clearTimeout(longPressTimer);
            if (isLongPress && e.target.tagName === 'IMG') {
              e.preventDefault();
              return false;
            }
          }
        }, true);
        
        document.addEventListener('touchmove', function(e) {
          if (longPressTimer) {
            clearTimeout(longPressTimer);
          }
        }, true);
      })();
    ''');

    await controller.addJavaScriptChannel(
      'ImageLongPress',
      onMessageReceived: (JavaScriptMessage message) {
        if (!mounted) return;
        
        try {
          final data = json.decode(message.message) as Map<String, dynamic>;
          final imageUrl = data['url'] as String;
          final x = (data['x'] as num).toDouble();
          final y = (data['y'] as num).toDouble();
          
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() {
              _tapPosition = Offset(x, y);
            });
            _showImageOptions(imageUrl, _tapPosition);
          });
        } catch (e) {
          print('Error handling image long press: $e');
        }
      },
    );

    await controller.setNavigationDelegate(NavigationDelegate(
      onNavigationRequest: (NavigationRequest request) async {
        final url = request.url.toLowerCase();
        
        // Handle search:// protocol
        if (url.startsWith('search://')) {
          // Extract search term and search directly
          final searchTerm = url.substring(9).trim();
          if (searchTerm.isNotEmpty) {
            // Use search engine directly instead of calling _loadUrl
            final engine = searchEngines[currentSearchEngine] ?? searchEngines['Google']!;
            final searchUrl = engine.replaceAll('{query}', Uri.encodeComponent(searchTerm));
            
            // Load the search URL directly
            await controller.loadRequest(Uri.parse(searchUrl));
            return NavigationDecision.prevent;
          }
        }
        
        // Handle downloads
        if (_isDownloadUrl(url)) {
          _handleDownload(request.url);
          return NavigationDecision.prevent;
        }
        
        return NavigationDecision.navigate;
      },
      onPageStarted: _handlePageStarted,
      onPageFinished: (String url) async {
        if (!mounted) return;
        print('=== PAGE FINISHED LOADING ==='); // Debug log
        print('URL: $url'); // Debug log
        final title = await controller.getTitle() ?? _displayUrl;
        print('Title: $title'); // Debug log
        _updateUrl(url);
        setState(() {
          isLoading = false;
          if (tabs.isNotEmpty && currentTabIndex >= 0 && currentTabIndex < tabs.length) {
            tabs[currentTabIndex].title = title;
            tabs[currentTabIndex].url = url;
          }
        });
        await _updateNavigationState();
        await _optimizationEngine.onPageFinishLoad(url);
        await _updateFavicon(url);
        
        print('Calling _saveToHistory...'); // Debug log
        try {
          await _saveToHistory(url, title);
          print('_saveToHistory completed'); // Debug log
        } catch (e) {
          print('Error in _saveToHistory: $e'); // Debug log
          print(e.toString());
          print('Stack trace:');
          print('${StackTrace.current}');
        }
        
        await _injectImageContextMenuJS();
        print('=== PAGE LOAD COMPLETE ==='); // Debug log
      },
      onWebResourceError: (WebResourceError error) async {
        if (!mounted) return;
        final currentUrl = await controller.currentUrl() ?? _displayUrl;
        await _handleWebResourceError(error, currentUrl);
      },
    ));
  }

  Future<void> _saveToHistory(String url, String title) async {
    print('🔍 Attempting to save history...');
    print('URL: $url');
    print('Title: $title');
    
    // Skip saving history for special cases
    if (url.isEmpty || 
        url == 'about:blank' ||
        url.startsWith('file://') ||
        url.contains('file:///') ||
        url.endsWith('main.html') ||
        url == _homeUrl ||  // Explicitly exclude home URL
        url.contains('ERR_') ||  // Skip error pages
        title.toLowerCase().contains('error') ||
        !url.startsWith('http')) {
      print('⚠️ Skipping history save - special URL or error page');
      return;
    }

    try {
      print('📝 Creating history entry...');
      final prefs = await SharedPreferences.getInstance();
      
      // Create history entry with safe fallbacks
      final newEntry = {
        'url': url,
        'title': title.isNotEmpty ? title : url,
        'favicon': null,  // Skip favicon for now to avoid errors
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      // Get existing history safely
      List<String> history = prefs.getStringList('history') ?? [];
      
      // Remove any existing entries with the same URL to prevent duplicates
      history.removeWhere((item) {
        try {
          final Map<String, dynamic> existingEntry = json.decode(item);
          return existingEntry['url'] == url;
        } catch (e) {
          return false;
        }
      });
      
      // Add new entry at the beginning
      history.insert(0, json.encode(newEntry));
      
      // Save updated history
      await prefs.setStringList('history', history);
      print('✅ History saved successfully');

    } catch (e) {
      print('❌ Error saving history: $e');
    }
  }

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = prefs.getStringList('history') ?? [];
      setState(() {
        _loadedHistory = history.map((e) {
          try {
            return Map<String, dynamic>.from(json.decode(e));
          } catch (e) {
            return null;
          }
        }).whereType<Map<String, dynamic>>().toList();
      });
    } catch (e) {
      print('Error loading history: $e');
    }
  }

  void _updateHistory(String url, String title) {
    // Skip updating history for special cases
    if (tabs[currentTabIndex].isIncognito ||  // Skip incognito
        url.isEmpty || title.isEmpty ||        // Skip empty entries
        url == 'about:blank' ||               // Skip blank pages
        url.startsWith('file://') ||          // Skip file URLs
        url.contains('file:///') ||           // Skip file URLs (alternate format)
        url.endsWith('main.html') ||          // Skip main.html
        title == 'New Tab' ||                 // Skip new tabs
        title == 'Webpage not available' ||    // Skip error pages
        title == 'Solar Home Page' ||         // Skip Solar home
        title.toLowerCase().contains('not available') || // Skip all error variations
        title.toLowerCase().contains('solar') ||        // Skip all Solar pages
        title.toLowerCase().contains('webpage') ||      // Skip webpage messages
        title == tabs[currentTabIndex].title) {        // Skip if title hasn't changed
      return;
    }

    // Only save if it's a valid web URL
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      return;
    }

    if (mounted) {
      setState(() {
        _loadedHistory.insert(0, {
          'url': url,
          'title': title,
          'favicon': tabs[currentTabIndex].favicon,
          'timestamp': DateTime.now().toIso8601String(),
        });
      });
      _saveHistory();
    }
  }

  Future<void> _loadUrl(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return;
    
    setState(() {
      isLoading = true;
    });
    
    // Process the URL/query
    String urlToLoad;
    
    // Handle search:// protocol - always treat content after search:// as a search query
    if (trimmedQuery.startsWith('search://')) {
      // Remove the search:// prefix and use as search term
      final searchTerm = trimmedQuery.substring(9).trim();
      if (searchTerm.isNotEmpty) {
        // Use search engine for all search:// URLs
        final engine = searchEngines[currentSearchEngine] ?? searchEngines['Google']!;
        urlToLoad = engine.replaceAll('{query}', Uri.encodeComponent(searchTerm));
      } else {
        // Empty search term, return early
        setState(() {
          isLoading = false;
        });
        return;
      }
    } else if (trimmedQuery.startsWith('http://') || trimmedQuery.startsWith('https://')) {
      // Direct URL loading
      urlToLoad = trimmedQuery;
    } else if (trimmedQuery.contains('.') && !trimmedQuery.contains(' ')) {
      // Likely a domain - add https://
      urlToLoad = 'https://$trimmedQuery';
    } else {
      // Search query - use search engine
      final engine = searchEngines[currentSearchEngine] ?? searchEngines['Google']!;
      urlToLoad = engine.replaceAll('{query}', Uri.encodeComponent(trimmedQuery));
    }
    
    // Update the tab data through our central handler (without UI updates yet)
    _handleUrlUpdate(urlToLoad);
    
    // Load the URL in the webview
    try {
      await controller.loadRequest(Uri.parse(urlToLoad));
    } catch (e) {
      debugPrint('Error loading URL: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _confirmUrlLoaded(String url, bool success) async {
    try {
      const platform = MethodChannel('app.channel.shared.data');
      await platform.invokeMethod('confirmUrlLoaded', {
        'url': url,
        'success': success
      });
      print("Sent URL loading confirmation to Android: $success"); // Debug print
    } catch (e) {
      print("Error sending load confirmation: $e"); // Debug print
    }
  }

  void _performSearch({bool searchUp = false}) async {
    final query = _urlController.text.trim();
    if (query.isEmpty) return;

    if (query.startsWith('http://') || query.startsWith('https://')) {
      await controller.loadRequest(Uri.parse(query));
    } else {
      final engine = searchEngines[currentSearchEngine] ?? searchEngines['google']!;
      final searchUrl = engine.replaceAll('{query}', query);
      await controller.loadRequest(Uri.parse(searchUrl));
    }
  }

  Future<void> _shareUrl() async {
    final url = await controller.currentUrl();
    if (url != null) {
      await controller.runJavaScript('''
        if (navigator.share) {
          navigator.share({
            url: '$url'
          });
        }
      ''');
    }
  }

  Future<String> _getCurrentLanguageName() async {
    final prefs = await SharedPreferences.getInstance();
    final currentLocale = prefs.getString('language') ?? 'en';
    final languages = {
      'en': 'English',
      'tr': 'Türkçe',
      'es': 'Español',
      'ar': 'العربية',
      'de': 'Deutsch',
      'fr': 'Français',
      'it': 'Italiano',
      'ja': '日本語',
      'ko': '한국어',
      'pt': 'Português',
      'ru': 'Русский',
      'zh': '中文',
      'hi': 'हिन्दी',
    };
    return languages[currentLocale] ?? 'English';
  }

  Future<String> _getCurrentSearchEngine() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('searchEngine') ?? currentSearchEngine;
  }

  void _showGeneralSettings() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => Scaffold(
          backgroundColor: ThemeManager.backgroundColor(),
          appBar: AppBar(
            backgroundColor: ThemeManager.backgroundColor(),
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.chevron_left,
                color: ThemeManager.textColor(),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              AppLocalizations.of(context)!.general,
              style: TextStyle(
                color: ThemeManager.textColor(),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: FutureBuilder<Map<String, String>>(
            future: _getGeneralSettingsInfo(),
            builder: (context, snapshot) {
              final data = snapshot.data ?? {'language': 'English', 'searchEngine': 'Google'};
              
              return ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  _buildSettingsSection(
                    title: AppLocalizations.of(context)!.general,
                    children: [
                      _buildSettingsItem(
                        title: AppLocalizations.of(context)!.language,
                        subtitle: data['language'],
                        onTap: () => _showLanguageSelection(context),
                        isFirst: true,
                      ),
                      _buildSettingsItem(
                        title: AppLocalizations.of(context)!.search_engine,
                        subtitle: data['searchEngine'],
                        onTap: () => _showSearchEngineSelection(context),
                        isLast: true,
                      ),
                    ],
                  ),
                ],
              );
            }
          ),
        ),
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;
          
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);
          
          return SlideTransition(position: offsetAnimation, child: child);
        },
      ),
    );
  }

  Future<Map<String, String>> _getGeneralSettingsInfo() async {
    final languageName = await _getCurrentLanguageName();
    final searchEngine = await _getCurrentSearchEngine();
    return {
      'language': languageName,
      'searchEngine': searchEngine,
    };
  }

  void _showClearBrowserDataDialog() {
    bool clearHistory = true;
    bool clearCookies = true;
    bool clearCache = true;
    bool clearPasswords = false;
    bool clearFormData = false;

    showCustomDialog(
      context: context,
      title: AppLocalizations.of(context)!.clear_browser_data,
      isDarkMode: isDarkMode,
      customContent: StatefulBuilder(
        builder: (context, setState) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CheckboxListTile(
              value: clearHistory,
              onChanged: (value) => setState(() => clearHistory = value!),
              title: Text(
                AppLocalizations.of(context)!.browsing_history,
                style: TextStyle(
                  color: ThemeManager.textColor(),
                ),
              ),
            ),
            CheckboxListTile(
              value: clearCookies,
              onChanged: (value) => setState(() => clearCookies = value!),
              title: Text(
                AppLocalizations.of(context)!.cookies,
              style: TextStyle(
                  color: ThemeManager.textColor(),
                ),
              ),
            ),
            CheckboxListTile(
              value: clearCache,
              onChanged: (value) => setState(() => clearCache = value!),
              title: Text(
                AppLocalizations.of(context)!.cache,
                style: TextStyle(
                  color: ThemeManager.textColor(),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            AppLocalizations.of(context)!.cancel,
            style: TextStyle(
              color: ThemeManager.textSecondaryColor(),
            ),
          ),
        ),
        TextButton(
          onPressed: () async {
            if (clearCache) await controller.clearCache();
            if (clearCookies) await controller.clearLocalStorage();
            if (clearHistory) {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('history');
              setState(() {
                _loadedHistory.clear();
                _currentHistoryPage = 0;
              });
            }
            Navigator.pop(context);
            showCustomNotification(
              context: context,
              message: AppLocalizations.of(context)!.browser_data_cleared,
              icon: Icons.check_circle,
              iconColor: ThemeManager.successColor(),
              isDarkMode: isDarkMode,
            );
          },
          child: Text(
            AppLocalizations.of(context)!.clear,
            style: const TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsItem({
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    bool isFirst = false,
    bool isLast = false,
    Widget? trailing,
  }) {
    Widget? trailingWidget = trailing;
    
    // Handle switch widgets
    if (trailing is Switch) {
      trailingWidget = Transform.scale(
        scale: 0.7,
        child: trailing,
      );
    }
    
    // Only show arrow for main settings items in certain cases
    if (trailing == null && onTap != null) {
      // Skip adding chevron_right for individual language options and summary length options
      bool shouldSkipArrow = searchEngines.keys.contains(title) || 
          title.contains('हिन्दी') || title.contains('English') || 
          title.contains('Türkçe') || title.contains('Español') || 
          title.contains('Français') || title.contains('Deutsch') || 
          title.contains('Italiano') || title.contains('Português') || 
          title.contains('Русский') || title.contains('中文') || 
          title.contains('日本語') || title.contains('العربية') ||
          title.contains('한국어') ||
          title.contains(AppLocalizations.of(context)!.summary_length_short) ||
          title.contains(AppLocalizations.of(context)!.summary_length_medium) ||
          title.contains(AppLocalizations.of(context)!.summary_length_long) ||
          title.contains(AppLocalizations.of(context)!.summary_language_english) ||
          title.contains(AppLocalizations.of(context)!.summary_language_turkish);

      if (!shouldSkipArrow) {
        trailingWidget = Icon(
          Icons.chevron_right,
          color: ThemeManager.textColor(),
          size: 18,
        );
      }
    } else if (trailing is Icon && (trailing as Icon).icon == Icons.chevron_right) {
      // Update existing arrow icons to use consistent colors
      trailingWidget = Icon(
        Icons.chevron_right,
        color: ThemeManager.textColor(),
        size: 18,
      );
    }
    
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          color: ThemeManager.textColor(),
        ),
      ),
      subtitle: subtitle != null
        ? Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
                        color: ThemeManager.textSecondaryColor(),
                      ),
                    )
        : null,
      trailing: trailingWidget,
      onTap: onTap,
    );
  }

  void _showDynamicBottomSheet({
    required List<Widget> items,
    required String title,
    double? fixedHeight,
  }) {
    final itemHeight = 72.0;
    final headerHeight = 56.0;
    final spacing = 16.0;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    
    final totalContentHeight = items.length * itemHeight;
    final screenHeight = MediaQuery.of(context).size.height;
    final calculatedHeight = spacing + totalContentHeight + headerHeight + statusBarHeight;
    final maxHeight = screenHeight * 0.7;
    final height = fixedHeight ?? (calculatedHeight > maxHeight ? maxHeight : calculatedHeight);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: ThemeManager.textColor().withOpacity(0.1),
      transitionAnimationController: AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      ),
      builder: (context) => TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutExpo,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, (1 - value) * 100),
            child: Opacity(
              opacity: value,
              child: Container(
        height: height,
        decoration: BoxDecoration(
          color: ThemeManager.backgroundColor(),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: ThemeManager.textColor().withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            _buildPanelHeader(title, onBack: () => Navigator.pop(context)),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: items.length,
                        physics: const BouncingScrollPhysics(),
                        itemBuilder: (context, index) => TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0, end: 1),
                          duration: Duration(milliseconds: 200 + (index * 50)),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return Transform.translate(
                              offset: Offset(50 * (1 - value), 0),
                              child: Opacity(
                                opacity: value,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: items[index],
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
            ),
          );
        },
      ),
    );
  }

  void _showLanguageSelection(BuildContext context) {
    Navigator.of(context).push(
      _createSettingsRoute(
        Scaffold(
          backgroundColor: ThemeManager.backgroundColor(),
          appBar: AppBar(
            backgroundColor: ThemeManager.backgroundColor(),
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.chevron_left, color: ThemeManager.textColor()),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              AppLocalizations.of(context)!.language,
              style: TextStyle(
                color: ThemeManager.textColor(),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: FutureBuilder<String>(
            future: _getCurrentLanguageName(),
            builder: (context, snapshot) {
              final currentLanguage = snapshot.data ?? 'English';
              
              return ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              _buildSettingsSection(
                title: AppLocalizations.of(context)!.chooseLanguage,
                    children: [
                      _buildSettingsItem(
                        title: 'English',
                        trailing: currentLanguage == 'English' 
                          ? Icon(Icons.check, color: ThemeManager.primaryColor()) 
                          : null,
                        onTap: () => _setLocale('en'),
                        isFirst: true,
                      ),
                      _buildSettingsItem(
                        title: 'Türkçe',
                        trailing: currentLanguage == 'Türkçe' 
                          ? Icon(Icons.check, color: ThemeManager.primaryColor()) 
                          : null,
                        onTap: () => _setLocale('tr'),
                      ),
                      _buildSettingsItem(
                        title: 'Español',
                        trailing: currentLanguage == 'Español' 
                          ? Icon(Icons.check, color: ThemeManager.primaryColor()) 
                          : null,
                        onTap: () => _setLocale('es'),
                      ),
                      _buildSettingsItem(
                        title: 'العربية',
                        trailing: currentLanguage == 'العربية' 
                          ? Icon(Icons.check, color: ThemeManager.primaryColor()) 
                          : null,
                        onTap: () => _setLocale('ar'),
                      ),
                      _buildSettingsItem(
                        title: 'Deutsch',
                        trailing: currentLanguage == 'Deutsch' 
                          ? Icon(Icons.check, color: ThemeManager.primaryColor()) 
                          : null,
                        onTap: () => _setLocale('de'),
                      ),
                      _buildSettingsItem(
                        title: 'Français',
                        trailing: currentLanguage == 'Français' 
                          ? Icon(Icons.check, color: ThemeManager.primaryColor()) 
                          : null,
                        onTap: () => _setLocale('fr'),
                      ),
                      _buildSettingsItem(
                        title: 'Italiano',
                        trailing: currentLanguage == 'Italiano' 
                          ? Icon(Icons.check, color: ThemeManager.primaryColor()) 
                          : null,
                        onTap: () => _setLocale('it'),
                      ),
                      _buildSettingsItem(
                        title: '日本語',
                        trailing: currentLanguage == '日本語' 
                          ? Icon(Icons.check, color: ThemeManager.primaryColor()) 
                          : null,
                        onTap: () => _setLocale('ja'),
                      ),
                      _buildSettingsItem(
                        title: '한국어',
                        trailing: currentLanguage == '한국어' 
                          ? Icon(Icons.check, color: ThemeManager.primaryColor()) 
                          : null,
                        onTap: () => _setLocale('ko'),
                      ),
                      _buildSettingsItem(
                        title: 'Português',
                        trailing: currentLanguage == 'Português' 
                          ? Icon(Icons.check, color: ThemeManager.primaryColor()) 
                          : null,
                        onTap: () => _setLocale('pt'),
                      ),
                      _buildSettingsItem(
                        title: 'Русский',
                        trailing: currentLanguage == 'Русский' 
                          ? Icon(Icons.check, color: ThemeManager.primaryColor()) 
                          : null,
                        onTap: () => _setLocale('ru'),
                      ),
                      _buildSettingsItem(
                        title: '中文',
                        trailing: currentLanguage == '中文' 
                          ? Icon(Icons.check, color: ThemeManager.primaryColor()) 
                          : null,
                        onTap: () => _setLocale('zh'),
                        isLast: true,
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _showSearchEngineSelection(BuildContext context) {
    Navigator.of(context).push(
      _createSettingsRoute(
        StatefulBuilder(
          builder: (BuildContext context, StateSetter setSearchEngineScreenState) {
            return Scaffold(
              backgroundColor: ThemeManager.backgroundColor(),
              appBar: AppBar(
                backgroundColor: ThemeManager.backgroundColor(),
                elevation: 0,
                leading: IconButton(
                  icon: Icon(Icons.chevron_left, color: ThemeManager.textColor()),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  AppLocalizations.of(context)!.search_engine,
                    style: TextStyle(
                    color: ThemeManager.textColor(),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              body: FutureBuilder<String>(
                future: _getCurrentSearchEngine(),
                builder: (context, snapshot) {
                  final currentSearchEngine = snapshot.data ?? 'Google';
                  
                  return ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    children: [
                      _buildSettingsSection(
                        title: AppLocalizations.of(context)!.chooseSearchEngine,
                        children: searchEngines.keys.map((engine) {
                          return _buildSettingsItem(
                            title: engine,
                            trailing: currentSearchEngine == engine
                              ? Icon(Icons.check, color: ThemeManager.primaryColor())
                              : null,
                            onTap: () {
                              // Set search engine and update both screens
                              _setSearchEngine(engine, setSearchEngineScreenState);
                            },
                            isFirst: engine == searchEngines.keys.first,
                            isLast: engine == searchEngines.keys.last,
                          );
                        }).toList(),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  void _setSearchEngine(String engine, [StateSetter? setSearchEngineScreenState]) {
    setState(() {
      currentSearchEngine = engine;
      if (_syncHomePageSearchEngine) {
        _homePageSearchEngine = engine;
      }
    });
    
    // Save to SharedPreferences
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('searchEngine', engine);
    });
    
    // Call the callback to update parent widgets
    widget.onSearchEngineChange?.call(engine);
    
    // Update search engine selection screen if available
    if (setSearchEngineScreenState != null) {
      setSearchEngineScreenState(() {});
      // Don't pop - stay on screen to see changes
    } else {
      // If not in StatefulBuilder context, pop as usual
      Navigator.pop(context);
    }
  }

  String _getSearchUrl(String query) {
    final engine = searchEngines[currentSearchEngine] ?? searchEngines['google']!;
    return engine.replaceAll('{query}', query);
  }

  void _showAppearanceSettings() {
    Navigator.of(context).push(
      _createSettingsRoute(
        StatefulBuilder(
          builder: (BuildContext context, StateSetter setAppearanceState) {
            final currentThemeName = _getThemeName(ThemeManager.getCurrentTheme());
            
            return Scaffold(
              backgroundColor: ThemeManager.backgroundColor(),
              appBar: AppBar(
                backgroundColor: ThemeManager.backgroundColor(),
                elevation: 0,
                leading: IconButton(
                  icon: Icon(
                    Icons.chevron_left,
                    color: ThemeManager.textColor(),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  AppLocalizations.of(context)!.appearance,
                  style: TextStyle(
                    color: ThemeManager.textColor(),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              body: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  _buildSettingsSection(
                    title: AppLocalizations.of(context)!.appearance,
                    children: [
                      _buildSettingsItem(
                        title: 'Themes',
                        subtitle: currentThemeName,
                        onTap: () => _showThemeSelection(context, setAppearanceState),
                        isFirst: true,
                        isLast: false,
                      ),
                      _buildSettingsItem(
                        title: AppLocalizations.of(context)!.text_size,
                        subtitle: _getTextSizeLabel(),
                        onTap: () => _showTextSizeSelection(context, setAppearanceState),
                        isLast: true,
                      ),
                    ],
                  ),
                  _buildSettingsSection(
                    title: AppLocalizations.of(context)!.general,
                    children: [
                      _buildSettingsItem(
                        title: AppLocalizations.of(context)!.classic_navigation,
                        subtitle: AppLocalizations.of(context)!.classic_navigation_description,
                        trailing: Switch(
                          value: _isClassicMode,
                          onChanged: (value) {
                            setState(() {
                              _isClassicMode = value;
                              _savePreferences();
                            });
                            setAppearanceState(() {});
                          },
                          activeColor: ThemeManager.primaryColor(),
                        ),
                        onTap: () {
                          setState(() {
                            _isClassicMode = !_isClassicMode;
                            _savePreferences();
                          });
                          setAppearanceState(() {});
                        },
                        isFirst: true,
                        isLast: true,
                      ),
                    ],
                  ),
                ],
              ),
            );
          }
        ),
      ),
    );
  }

  void _showThemeSelection(BuildContext context, [StateSetter? setAppearanceState]) {
    Navigator.of(context).push(
      _createSettingsRoute(
        StatefulBuilder(
          builder: (BuildContext context, StateSetter setThemeScreenState) {
            return Scaffold(
              backgroundColor: ThemeManager.backgroundColor(),
              appBar: AppBar(
                backgroundColor: ThemeManager.backgroundColor(),
                elevation: 0,
                systemOverlayStyle: _transparentNavBar,
                leading: IconButton(
                  icon: Icon(
                    Icons.chevron_left,
                    color: ThemeManager.textColor(),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  'Themes',
                  style: TextStyle(
                    color: ThemeManager.textColor(),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              body: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  ...ThemeType.values.map((theme) {
                    if (theme == ThemeType.system) return const SizedBox.shrink();
                    
                    final colors = ThemeManager.getThemeColors(theme);
                    final isSelected = ThemeManager.getCurrentTheme() == theme;
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: colors.backgroundColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected 
                            ? colors.primaryColor 
                            : colors.textSecondaryColor.withOpacity(0.1),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        title: Text(
                          _getThemeName(theme),
                          style: TextStyle(
                            color: colors.textColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSelected) 
                              Container(
                                margin: const EdgeInsets.only(right: 12),
                                child: Icon(Icons.check, color: colors.primaryColor),
                              ),
                            ...[ 
                              colors.primaryColor,
                              colors.accentColor,
                              colors.textColor,
                              colors.surfaceColor,
                              colors.secondaryColor,
                            ].map((color) => Container(
                              width: 24,
                              height: 24,
                              margin: const EdgeInsets.only(right: 4),
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: colors.textSecondaryColor.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                            )).toList(),
                          ],
                        ),
                        onTap: () async {
                          // Save and apply theme
                          await ThemeManager.setTheme(theme);
                          
                          // Update both UIs
                          setState(() {
                            isDarkMode = theme.isDark;
                          });
                          
                          // Update theme selection screen
                          setThemeScreenState(() {
                            // This rebuilds the theme selection screen
                          });
                          
                          // Update appearance settings screen if it was provided
                          if (setAppearanceState != null) {
                            setAppearanceState(() {
                              // This rebuilds the appearance settings screen
                            });
                          }
                          
                          // Update system bars
                          _updateSystemBars();
                          
                          // Force immediate rebuild of entire app
                          if (mounted) {
                            setState(() {});
                            // Force rebuild of parent widgets
                            if (widget.onThemeChange != null) {
                              widget.onThemeChange!(theme.isDark);
                            }
                          }
                          
                          // Don't pop back to appearance settings - keep user on theme selection screen
                          // so they can see the changes immediately
                          // Navigator.pop(context);
                        },
                      ),
                    );
                  }).whereType<Widget>().toList(),
                ],
              ),
            );
          }
        ),
      ),
    );
  }

  String _getThemeName(ThemeType theme) {
    switch (theme) {
      case ThemeType.system:
        return 'System';
      case ThemeType.light:
        return 'Light';
      case ThemeType.dark:
        return 'Dark';
      case ThemeType.tokyoNight:
        return 'Tokyo Night';
      case ThemeType.solarizedLight:
        return 'Solarized Light';
      case ThemeType.dracula:
        return 'Dracula';
      case ThemeType.nord:
        return 'Nord Dark';
      case ThemeType.gruvbox:
        return 'Gruvbox Dark';
      case ThemeType.oneDark:
        return 'One Dark';
      case ThemeType.catppuccin:
        return 'Catppuccin';
      case ThemeType.nordLight:
        return 'Nord Light';
      case ThemeType.gruvboxLight:
        return 'Gruvbox Light';
    }
  }

  String _getTextSizeLabel() {
    if (textScale == 0.8) return AppLocalizations.of(context)!.text_size_small;
    if (textScale == 1.0) return AppLocalizations.of(context)!.text_size_medium;
    if (textScale == 1.2) return AppLocalizations.of(context)!.text_size_large;
    return AppLocalizations.of(context)!.text_size_very_large;
  }

  Future<void> _showTextSizeSelection(BuildContext context, [StateSetter? setAppearanceState]) async {
    await Navigator.of(context).push(
      _createSettingsRoute(
        StatefulBuilder(
          builder: (BuildContext context, StateSetter setTextSizeState) {
            return Scaffold(
              backgroundColor: ThemeManager.backgroundColor(),
              appBar: AppBar(
                backgroundColor: ThemeManager.backgroundColor(),
                elevation: 0,
                leading: IconButton(
                  icon: Icon(
                    Icons.chevron_left,
                    color: ThemeManager.textColor(),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  AppLocalizations.of(context)!.text_size,
                  style: TextStyle(
                    color: ThemeManager.textColor(),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              body: ListView(
                padding: const EdgeInsets.only(top: 8),
                children: [
                  _buildSettingsSection(
                    title: AppLocalizations.of(context)!.text_size_description,
                    children: [
                      _buildSettingsItem(
                        title: AppLocalizations.of(context)!.text_size_small,
                        trailing: textScale == 0.8 ? Icon(Icons.check, color: ThemeManager.primaryColor()) : null,
                        onTap: () {
                          _updateTextSize(0.8);
                          // Update both screens
                          setTextSizeState(() {});
                          if (setAppearanceState != null) {
                            setAppearanceState(() {});
                          }
                          // Stay on screen to see the changes
                          // Navigator.pop(context);
                        },
                        isFirst: true,
                        isLast: false,
                      ),
                      _buildSettingsItem(
                        title: AppLocalizations.of(context)!.text_size_medium,
                        trailing: textScale == 1.0 ? Icon(Icons.check, color: ThemeManager.primaryColor()) : null,
                        onTap: () {
                          _updateTextSize(1.0);
                          // Update both screens
                          setTextSizeState(() {});
                          if (setAppearanceState != null) {
                            setAppearanceState(() {});
                          }
                          // Stay on screen to see the changes
                          // Navigator.pop(context);
                        },
                        isFirst: false,
                        isLast: false,
                      ),
                      _buildSettingsItem(
                        title: AppLocalizations.of(context)!.text_size_large,
                        trailing: textScale == 1.2 ? Icon(Icons.check, color: ThemeManager.primaryColor()) : null,
                        onTap: () {
                          _updateTextSize(1.2);
                          // Update both screens
                          setTextSizeState(() {});
                          if (setAppearanceState != null) {
                            setAppearanceState(() {});
                          }
                          // Stay on screen to see the changes
                          // Navigator.pop(context);
                        },
                        isFirst: false,
                        isLast: false,
                      ),
                      _buildSettingsItem(
                        title: AppLocalizations.of(context)!.text_size_very_large,
                        trailing: textScale == 1.4 ? Icon(Icons.check, color: ThemeManager.primaryColor()) : null,
                        onTap: () {
                          _updateTextSize(1.4);
                          // Update both screens
                          setTextSizeState(() {});
                          if (setAppearanceState != null) {
                            setAppearanceState(() {});
                          }
                          // Stay on screen to see the changes
                          // Navigator.pop(context);
                        },
                        isFirst: false,
                        isLast: true,
                      ),
                    ],
                  ),
                ],
              ),
            );
          }
        ),
      ),
    );
  }

  // Helper method for creating slide transitions for settings pages
  PageRouteBuilder<dynamic> _createSettingsRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;
        
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);
        
        return SlideTransition(position: offsetAnimation, child: child);
      },
    );
  }

  void _showDownloadsSettings() {
    Navigator.of(context).push(
      _createSettingsRoute(
        Scaffold(
          backgroundColor: ThemeManager.backgroundColor(),
          appBar: AppBar(
            backgroundColor: ThemeManager.backgroundColor(),
            elevation: 0,
            systemOverlayStyle: _transparentNavBar,
            leading: IconButton(
              icon: Icon(
                Icons.chevron_left,
                color: ThemeManager.textColor(),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              AppLocalizations.of(context)!.downloads,
              style: TextStyle(
                color: ThemeManager.textColor(),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              _buildSettingsSection(
                title: "AppLocalizations.of(context)!.downloads",
                children: [
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAISettings() {
    Navigator.of(context).push(
      _createSettingsRoute(
        Scaffold(
          backgroundColor: ThemeManager.backgroundColor(),
          appBar: AppBar(
            backgroundColor: ThemeManager.backgroundColor(),
            elevation: 0,
            systemOverlayStyle: _transparentNavBar,
            leading: IconButton(
              icon: Icon(
                Icons.chevron_left,
                color: ThemeManager.textColor(),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              AppLocalizations.of(context)!.ai_preferences,
              style: TextStyle(
                color: ThemeManager.textColor(),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              _buildSettingsSection(
                title: AppLocalizations.of(context)!.ai_preferences,
                children: [
                  _buildSettingsItem(
                    title: AppLocalizations.of(context)!.summary_length,
                    subtitle: _getCurrentSummaryLengthLabel(),
                    onTap: () => _showSummaryLengthSelection(),
                    isFirst: true,
                  ),
                  _buildSettingsItem(
                    title: AppLocalizations.of(context)!.summary_language,
                    subtitle: _getCurrentSummaryLanguageLabel(),
                    onTap: () => _showSummaryLanguageSelection(),
                    isLast: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getCurrentSummaryLengthLabel() {
    final length = AIManager.getCurrentSummaryLength();
    switch (length) {
      case SummaryLength.short:
        return AppLocalizations.of(context)!.summary_length_short;
      case SummaryLength.medium:
        return AppLocalizations.of(context)!.summary_length_medium;
      case SummaryLength.long:
        return AppLocalizations.of(context)!.summary_length_long;
      default:
        return AppLocalizations.of(context)!.summary_length_medium;
    }
  }

  String _getCurrentSummaryLanguageLabel() {
    final language = AIManager.getCurrentSummaryLanguage();
    switch (language) {
      case SummaryLanguage.english:
        return AppLocalizations.of(context)!.summary_language_english;
      case SummaryLanguage.turkish:
        return AppLocalizations.of(context)!.summary_language_turkish;
      default:
        return AppLocalizations.of(context)!.summary_language_english;
    }
  }

  void _showSummaryLengthSelection() {
    Navigator.of(context).push(
      _createSettingsRoute(
        Scaffold(
          backgroundColor: ThemeManager.backgroundColor(),
          appBar: AppBar(
            backgroundColor: ThemeManager.backgroundColor(),
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.chevron_left,
                color: ThemeManager.textColor(),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              AppLocalizations.of(context)!.summary_length,
              style: TextStyle(
                color: ThemeManager.textColor(),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              _buildSettingsSection(
                title: AppLocalizations.of(context)!.summary_length,
                children: [
                  _buildSettingsItem(
                    title: AppLocalizations.of(context)!.summary_length_short,
                    onTap: () async {
                      await AIManager.setSummaryLength(SummaryLength.short);
                      if (!mounted) return;
                      Navigator.pop(context);
                    },
                    trailing: AIManager.getCurrentSummaryLength() == SummaryLength.short
                      ? Icon(Icons.check, color: ThemeManager.primaryColor())
                      : null,
                    isFirst: true,
                  ),
                  _buildSettingsItem(
                    title: AppLocalizations.of(context)!.summary_length_medium,
                    onTap: () async {
                      await AIManager.setSummaryLength(SummaryLength.medium);
                      if (!mounted) return;
                      Navigator.pop(context);
                    },
                    trailing: AIManager.getCurrentSummaryLength() == SummaryLength.medium
                      ? Icon(Icons.check, color: ThemeManager.primaryColor())
                      : null,
                  ),
                  _buildSettingsItem(
                    title: AppLocalizations.of(context)!.summary_length_long,
                    onTap: () async {
                      await AIManager.setSummaryLength(SummaryLength.long);
                      if (!mounted) return;
                      Navigator.pop(context);
                    },
                    trailing: AIManager.getCurrentSummaryLength() == SummaryLength.long
                      ? Icon(Icons.check, color: ThemeManager.primaryColor())
                      : null,
                    isLast: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSummaryLanguageSelection() {
    Navigator.of(context).push(
      _createSettingsRoute(
        Scaffold(
          backgroundColor: ThemeManager.backgroundColor(),
          appBar: AppBar(
            backgroundColor: ThemeManager.backgroundColor(),
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.chevron_left,
                color: ThemeManager.textColor(),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              AppLocalizations.of(context)!.summary_language,
              style: TextStyle(
                color: ThemeManager.textColor(),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              _buildSettingsSection(
                title: AppLocalizations.of(context)!.summary_language,
                children: [
                  _buildSettingsItem(
                    title: AppLocalizations.of(context)!.summary_language_english,
                    onTap: () async {
                      await AIManager.setSummaryLanguage(SummaryLanguage.english);
                      if (!mounted) return;
                      Navigator.pop(context);
                    },
                    trailing: AIManager.getCurrentSummaryLanguage() == SummaryLanguage.english
                      ? Icon(Icons.check, color: ThemeManager.primaryColor())
                      : null,
                    isFirst: true,
                  ),
                  _buildSettingsItem(
                    title: AppLocalizations.of(context)!.summary_language_turkish,
                    onTap: () async {
                      await AIManager.setSummaryLanguage(SummaryLanguage.turkish);
                      if (!mounted) return;
                      Navigator.pop(context);
                    },
                    trailing: AIManager.getCurrentSummaryLanguage() == SummaryLanguage.turkish
                      ? Icon(Icons.check, color: ThemeManager.primaryColor())
                      : null,
                    isLast: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHelpPage() {
    controller.loadRequest(Uri.parse('https://github.com/solarbrowser/mobile/wiki'));
    setState(() {
      isSettingsVisible = false;
    });
  }

  void _showRateUs() {
    if (Platform.isAndroid) {
      controller.loadRequest(Uri.parse('market://details?id=com.vertex.solar'));
    } else if (Platform.isIOS) {
      controller.loadRequest(Uri.parse('itms-apps://itunes.apple.com/app/'));
    }
    setState(() {
      isSettingsVisible = false;
    });
  }

  void _showPrivacyPolicy() {
    final String currentLocale = Localizations.localeOf(context).languageCode;
    
    showCustomDialog(
      context: context,
      title: AppLocalizations.of(context)!.privacy_policy,
      content: LegalTexts.getPrivacyPolicy(currentLocale),
      isDarkMode: isDarkMode,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            AppLocalizations.of(context)!.close,
            style: TextStyle(
              color: ThemeManager.textColor(),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  void _showTermsOfUse() {
    final String currentLocale = Localizations.localeOf(context).languageCode;
    
    showCustomDialog(
      context: context,
      title: AppLocalizations.of(context)!.terms_of_use,
      content: LegalTexts.getTermsOfUse(currentLocale),
      isDarkMode: isDarkMode,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            AppLocalizations.of(context)!.close,
            style: TextStyle(
              color: ThemeManager.textColor(),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Future<dynamic> _showAboutPage() {
    return Navigator.of(context).push(
      _createSettingsRoute(
        Scaffold(
          backgroundColor: ThemeManager.backgroundColor(),
          appBar: AppBar(
            backgroundColor: ThemeManager.backgroundColor(),
            elevation: 0,
            systemOverlayStyle: _transparentNavBar,
            leading: IconButton(
              icon: Icon(
                Icons.chevron_left,
                color: ThemeManager.textColor(),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              AppLocalizations.of(context)!.about,
              style: TextStyle(
                color: ThemeManager.textColor(),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              _buildSettingsSection(
                title: AppLocalizations.of(context)!.about,
                children: [
                  _buildSettingsItem(
                    title: AppLocalizations.of(context)!.app_name,
                    subtitle: AppLocalizations.of(context)!.version('0.1.2'),
                    isFirst: true,
                    isLast: false,
                  ),
                  _buildSettingsItem(
                    title: AppLocalizations.of(context)!.flutter_version,
                    subtitle: 'Flutter 3.29.2',
                    isFirst: false,
                    isLast: false,
                  ),
                  _buildSettingsItem(
                    title: AppLocalizations.of(context)!.photoncore_version,
                    subtitle: 'Photoncore 0.0.3',
                    isFirst: false,
                    isLast: false,
                  ),
                  _buildSettingsItem(
                    title: AppLocalizations.of(context)!.engine_version,
                    subtitle: 'MRE4.7.0, ARE4.3.3',
                    isFirst: false,
                    isLast: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPanelHeader(String title, {VoidCallback? onBack, Widget? trailing}) {
    final statusBarHeight = MediaQuery.of(context).padding.top;

    String getLocalizedTitle() {
      switch (title) {
        case 'general': return AppLocalizations.of(context)!.general;
        case 'downloads': return AppLocalizations.of(context)!.downloads;
        case 'appearance': return AppLocalizations.of(context)!.appearance;
        case 'help': return AppLocalizations.of(context)!.help;
        case 'about': return AppLocalizations.of(context)!.about;
        case 'quick actions': return 'Quick Actions';
        default: return title;
      }
    }

    return Container(
      padding: EdgeInsets.only(top: statusBarHeight, left: 8, right: 8),
      height: 56 + statusBarHeight,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: ThemeManager.textColor().withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.chevron_left,
              color: ThemeManager.textColor(),
            ),
            onPressed: onBack,
          ),
          Expanded(
            child: Text(
              getLocalizedTitle(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: ThemeManager.textColor(),
              ),
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(String label, IconData icon, {VoidCallback? onPressed}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: SizedBox(
          width: 70,
          height: 80,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: ThemeManager.surfaceColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: ThemeManager.textSecondaryColor(),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: ThemeManager.textColor(),
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionsPanel() {
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        if (details.delta.dy > 2) {
          _handleSlideUpPanelVisibility(false);
        }
      },
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! > 50) {
          _handleSlideUpPanelVisibility(false);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: ThemeManager.textColor().withOpacity(0.1),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              height: 100,
              color: ThemeManager.backgroundColor().withOpacity(0.7),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildQuickActionButton(
                    AppLocalizations.of(context)!.settings,
                    Icons.settings_rounded,
                    onPressed: () {
                      setState(() {
                        _hideUrlBar = false;
                        _hideUrlBarController.reverse();
                        isSettingsVisible = true;
                        _isSlideUpPanelVisible = false;
                        _slideUpController.reverse();
                      });
                    },
                  ),
                  _buildQuickActionButton(
                    AppLocalizations.of(context)!.downloads,
                    Icons.download_rounded,
                    onPressed: () {
                      setState(() {
                        _hideUrlBar = false;
                        _hideUrlBarController.reverse();
                        isDownloadsVisible = true;
                        _isSlideUpPanelVisible = false;
                        _slideUpController.reverse();
                      });
                    },
                  ),
                  _buildQuickActionButton(
                    AppLocalizations.of(context)!.tabs,
                    Icons.tab_rounded,
                    onPressed: () {
                      setState(() {
                        _hideUrlBar = false;
                        _hideUrlBarController.reverse();
                        isTabsVisible = true;
                        _isSlideUpPanelVisible = false;
                        _slideUpController.reverse();
                      });
                    },
                  ),
                  _buildQuickActionButton(
                    AppLocalizations.of(context)!.bookmarks,
                    Icons.bookmark_rounded,
                    onPressed: () {
                      setState(() {
                        _hideUrlBar = false;
                        _hideUrlBarController.reverse();
                        isBookmarksVisible = true;
                        _isSlideUpPanelVisible = false;
                        _slideUpController.reverse();
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchPanel() {
    return Container(
      height: 48,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              color: ThemeManager.backgroundColor().withOpacity(0.7),
              border: Border.all(
                color: ThemeManager.textColor().withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _urlController,
                    decoration: InputDecoration(
                      hintStyle: TextStyle(
                        color: ThemeManager.textSecondaryColor().withOpacity(0.5),
                      ),
                      border: InputBorder.none,
                    ),
                    style: TextStyle(
                      color: ThemeManager.textColor(),
                    ),
                    onSubmitted: (_) => _performSearch(),
                  ),
                ),
                if (totalSearchMatches > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '${currentSearchMatch + 1}/$totalSearchMatches',
                      style: TextStyle(
                        color: ThemeManager.textColor(),
                      ),
                    ),
                  ),
                IconButton(
                  icon: Icon(
                    Icons.keyboard_arrow_up_rounded,
                    color: ThemeManager.textSecondaryColor(),
                  ),
                  onPressed: () => _performSearch(searchUp: true),
                ),
                IconButton(
                  icon: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: ThemeManager.textSecondaryColor(),
                  ),
                  onPressed: () => _performSearch(),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: ThemeManager.textSecondaryColor(),
                  ),
                  onPressed: () {
                    setState(() {
                      isSearchMode = false;
                      _urlController.clear();
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getDisplayUrl(String url) {
    try {
      if (url == 'Home page') return url;
      final uri = Uri.parse(url);
      String host = uri.host;
      return host.startsWith('www.') ? host.substring(4) : host;
    } catch (e) {
      return url;
    }
  }

  void _switchTab(int index) {
    if (index < 0 || index >= tabs.length) return;
    
    setState(() {
      currentTabIndex = index;
      controller = tabs[index].controller;
      _displayUrl = tabs[index].url;
      if (!_urlFocusNode.hasFocus) {
        _urlController.text = _formatUrl(tabs[index].url);
      }
      canGoBack = tabs[index].canGoBack;
      canGoForward = tabs[index].canGoForward;
    });
    
    // Update navigation state after switching tabs
    _updateNavigationState();
  }

  Widget _buildAppearanceSettings() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.symmetric(vertical: 8),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ThemeManager.surfaceColor(),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    AppLocalizations.of(context)!.dark_mode,
                    style: TextStyle(
                      color: ThemeManager.textColor(),
                    ),
                  ),
                  value: isDarkMode,
                  onChanged: _toggleTheme,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        AppLocalizations.of(context)!.text_size,
                        style: TextStyle(
                          color: ThemeManager.textColor(),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Text('A', 
                          style: TextStyle(
                            fontSize: 14,
                            color: ThemeManager.textColor(),
                          )
                        ),
                        Expanded(
                          child: Slider(
                            value: textScale,
                            min: 0.8,
                            max: 1.4,
                            divisions: 6,
                            label: '${((textScale - 0.8) * 100 / 0.6).round()}%',
                            onChanged: (value) {
                              _updateTextSize(value);
                            },
                          ),
                        ),
                        Text('A', 
                          style: TextStyle(
                            fontSize: 24,
                            color: ThemeManager.textColor(),
                          )
                        ),
                      ],
                    ),
                  ],
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    AppLocalizations.of(context)!.show_images,
                    style: TextStyle(
                      color: ThemeManager.textColor(),
                    ),
                  ),
                  value: showImages,
                  onChanged: (value) async {
                    setState(() {
                      showImages = value;
                    });
                    await _savePreferences();
                    await controller.reload();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadsPanel() {
    return Container(
      color: ThemeManager.backgroundColor(),
      child: Column(
        children: [
          Container(
            height: 56 + MediaQuery.of(context).padding.top,
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            decoration: BoxDecoration(
              color: ThemeManager.backgroundColor(),
              border: Border(
                bottom: BorderSide(
                  color: ThemeManager.textColor().withOpacity(0.1),
                ),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.chevron_left,
                    color: ThemeManager.textColor(),
                  ),
                  onPressed: () => setState(() => isDownloadsVisible = false),
                ),
                Text(
                  AppLocalizations.of(context)!.downloads,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: ThemeManager.textColor(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: downloads.isEmpty && !isDownloading
                ? _buildEmptyState(
                    AppLocalizations.of(context)!.no_downloads_yet,
                    Icons.download_outlined,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: isDownloading ? downloads.length + 1 : downloads.length,
                    itemBuilder: (context, index) {
                      if (isDownloading && index == 0) {
                        final downloadedSize = (downloadProgress * (currentDownloadSize ?? 0)).toInt();
                        final totalSize = currentDownloadSize ?? 0;
                        final downloadedSizeStr = _formatFileSize(downloadedSize);
                        final totalSizeStr = _formatFileSize(totalSize);
                        
                        return Card(
                          elevation: 0,
                          color: ThemeManager.secondaryColor(),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        CircularProgressIndicator(
                                          value: downloadProgress,
                                          color: ThemeManager.textSecondaryColor(),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            currentFileName ?? AppLocalizations.of(context)!.downloading,
                                            style: TextStyle(
                                              color: ThemeManager.textColor(),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _extractDomain(currentDownloadUrl),
                                            style: TextStyle(
                                              color: ThemeManager.textSecondaryColor(),
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    TextButton.icon(
                                      icon: Icon(
                                        Icons.close,
                                        color: ThemeManager.textColor(),
                                        size: 20,
                                      ),
                                      label: Text(
                                        'Cancel',
                                        style: TextStyle(
                                          color: ThemeManager.textSecondaryColor(),
                                          fontSize: 14,
                                        ),
                                      ),
                                      style: TextButton.styleFrom(
                                        backgroundColor: ThemeManager.surfaceColor().withOpacity(0.05),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          isDownloading = false;
                                          currentDownloadUrl = '';
                                          downloadProgress = 0.0;
                                          _currentFileName = null;
                                          _currentDownloadSize = null;
                                        });
                                        _showNotification(
                                          Row(
                                            children: [
                                              Icon(Icons.info, color: ThemeManager.primaryColor()),
                                              const SizedBox(width: 16),
                                              Text(
                                                AppLocalizations.of(context)!.download_canceled,
                                                style: TextStyle(
                                                  color: ThemeManager.textColor(),
                                                ),
                                              ),
                                            ],
                                          ),
                                          duration: const Duration(seconds: 3),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value: downloadProgress,
                                  backgroundColor: ThemeManager.surfaceColor().withOpacity(0.12),
                                  valueColor: AlwaysStoppedAnimation(
                                    ThemeManager.textSecondaryColor(),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '$downloadedSizeStr / $totalSizeStr',
                                  style: TextStyle(
                                    color: ThemeManager.textSecondaryColor(),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      
                      final downloadIndex = isDownloading ? index - 1 : index;
                      final download = downloads[downloadIndex];
                      final fileName = download['filename']?.toString() ?? AppLocalizations.of(context)!.unknown;
                      final filePath = download['path']?.toString();
                      final fileSize = download['size']?.toString() ?? '0 B';
                      
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: ThemeManager.secondaryColor(),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: ThemeManager.surfaceColor().withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.file_download_done,
                                color: ThemeManager.textColor(),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    fileName,
                                    style: TextStyle(
                                      color: ThemeManager.textColor(),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$fileSize • ${_formatTimestamp(DateTime.parse(download['timestamp'] as String))}',
                                    style: TextStyle(
                                      color: ThemeManager.textSecondaryColor(),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (filePath != null) IconButton(
                              icon: Icon(
                                Icons.open_in_new,
                                color: ThemeManager.textColor(),
                                size: 20,
                              ),
                              onPressed: () => _openDownloadedFile(download),
                            ),
                            PopupMenuButton(
                              icon: Icon(
                                Icons.more_vert,
                                color: ThemeManager.textColor(),
                                size: 20,
                              ),
                              color: ThemeManager.backgroundColor(),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.open_in_new,
                                        size: 20,
                                        color: ThemeManager.textColor(),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        AppLocalizations.of(context)!.open,
                                        style: TextStyle(
                                          color: ThemeManager.textColor(),
                                        ),
                                      ),
                                    ],
                                  ),
                                  onTap: () async {
                                    await OpenFile.open(download['path'] as String);
                                  },
                                ),
                                PopupMenuItem(
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.history,
                                        size: 20,
                                        color: ThemeManager.textColor(),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Remove from History',
                                        style: TextStyle(
                                          color: ThemeManager.textColor(),
                                        ),
                                      ),
                                    ],
                                  ),
                                  onTap: () => _showDeleteDownloadDialog(downloadIndex),
                                ),
                                PopupMenuItem(
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.delete_forever,
                                        size: 20,
                                        color: ThemeManager.errorColor(),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Delete from Device',
                                        style: TextStyle(
                                          color: ThemeManager.errorColor(),
                                        ),
                                      ),
                                    ],
                                  ),
                                  onTap: () async {
                                    final filePath = download['path'] as String; // Use the stored complete path
                                    final file = File(filePath);
                                    if (await file.exists()) {
                                      showDialog(
                                        context: context,
                                        barrierColor: ThemeManager.textColor().withOpacity(0.1),
                                        builder: (context) => AlertDialog(
                                          backgroundColor: ThemeManager.backgroundColor(),
                                          title: Text(
                                            'Delete File',
                                            style: TextStyle(
                                              color: ThemeManager.textColor(),
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          content: Text(
                                            'Are you sure you want to permanently delete this file from your device?',
                                            style: TextStyle(
                                              color: ThemeManager.textColor(),
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: Text(
                                                AppLocalizations.of(context)!.cancel,
                                                style: TextStyle(
                                                  color: ThemeManager.textColor(),
                                                ),
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: () async {
                                                await file.delete();
                                                
                                                // Remove from downloads history
                                                final prefs = await SharedPreferences.getInstance();
                                                final downloadsList = prefs.getStringList('downloads') ?? [];
                                                downloadsList.removeAt(index);
                                                await prefs.setStringList('downloads', downloadsList);
                                                
                                                setState(() {
                                                  downloads.removeAt(index);
                                                });
                                                
                                                Navigator.pop(context);
                                                _showNotification(
                                                  Row(
                                                    children: [
                                                      Icon(Icons.check_circle, color: ThemeManager.successColor()),
                                                      const SizedBox(width: 16),
                                                      Expanded(
                                                        child: Text(
                                                          'File deleted from device',
                                                          style: TextStyle(
                                                            color: ThemeManager.textColor(),
                                                            fontSize: 14,
                                                            fontWeight: FontWeight.w500,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  duration: const Duration(seconds: 4),
                                                );
                                              },
                                              child: Text(
                                                'Delete',
                                                style: TextStyle(
                                                  color: ThemeManager.errorColor(),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookmarksPanel() {
    return Container(
      color: ThemeManager.backgroundColor(),
      child: Column(
        children: [
          Container(
            height: 56 + MediaQuery.of(context).padding.top,
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            decoration: BoxDecoration(
              color: ThemeManager.backgroundColor(),
              border: Border(
                bottom: BorderSide(
                  color: ThemeManager.textColor().withOpacity(0.1),
                ),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.chevron_left,
                    color: ThemeManager.textColor(),
                  ),
                  onPressed: () {
                    setState(() {
                      isBookmarksVisible = false;
                    });
                  },
                ),
                Text(
                  AppLocalizations.of(context)!.bookmarks,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: ThemeManager.textColor(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: bookmarks.isEmpty
              ? Center(
                  child: Text(
                    'No bookmarks yet',
                    style: TextStyle(
                      color: ThemeManager.textSecondaryColor(),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: bookmarks.length,
                  itemBuilder: (context, index) {
                    final bookmark = bookmarks[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: ThemeManager.secondaryColor(),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: bookmark['favicon'] != null
                          ? Image.network(
                              bookmark['favicon'],
                              width: 24,
                              height: 24,
                              errorBuilder: (context, error, stackTrace) => Icon(
                                Icons.web,
                                color: ThemeManager.textColor(),
                              ),
                            )
                          : Icon(
                              Icons.web,
                              color: ThemeManager.textColor(),
                            ),
                        title: Text(
                          bookmark['title'],
                          style: TextStyle(
                            color: ThemeManager.textColor(),
                          ),
                        ),
                        subtitle: Text(
                          _getDisplayUrl(bookmark['url']),
                          style: TextStyle(
                            color: ThemeManager.textColor(),
                          ),
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            Icons.delete,
                            color: ThemeManager.textColor(),
                          ),
                          onPressed: () async {
                            final prefs = await SharedPreferences.getInstance();
                            final bookmarksList = prefs.getStringList('bookmarks') ?? [];
                            bookmarksList.removeAt(index);
                            await prefs.setStringList('bookmarks', bookmarksList);
                            setState(() {
                              bookmarks.removeAt(index);
                            });
                          },
                        ),
                        onTap: () {
                          controller.loadRequest(Uri.parse(bookmark['url']));
                          setState(() {
                            isBookmarksVisible = false;
                          });
                        },
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }

  Future<void> _optimizeWebView() async {
    // Memory optimization
    const duration = Duration(minutes: 5); // More frequent cleanup
    Timer.periodic(duration, (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      await _checkMemoryAndOptimize();
      
      // Aggressive cache clearing for inactive tabs
      for (var i = 0; i < tabs.length; i++) {
        if (i != currentTabIndex) {
          await tabs[i].controller.clearCache();
          await tabs[i].controller.clearLocalStorage();
        }
      }
    });

    // Advanced performance optimizations
      await controller.runJavaScript('''
      // Enable maximum performance mode
      document.documentElement.style.setProperty('content-visibility', 'auto');
      document.documentElement.style.setProperty('contain', 'content');
      document.documentElement.style.setProperty('will-change', 'transform');
      document.documentElement.style.setProperty('transform', 'translateZ(0)');
      document.documentElement.style.setProperty('backface-visibility', 'hidden');
      
      // Optimize paint and layout
      document.body.style.setProperty('paint-order', 'strict');
      document.body.style.setProperty('content-visibility', 'auto');
      document.body.style.setProperty('contain', 'layout style paint');
      
      // Advanced scroll optimization
      let lastKnownScrollPosition = 0;
      let ticking = false;
      
      function optimizeOnScroll(scrollPos) {
        // Disable animations during scroll
        document.body.style.setProperty('animation', 'none');
        document.body.style.setProperty('transition', 'none');
        
        // Enable hardware acceleration
        document.body.style.setProperty('transform', 'translate3d(0,0,0)');
        
        // Re-enable animations after scroll stops
            clearTimeout(window._scrollTimeout);
          window._scrollTimeout = setTimeout(() => {
          document.body.style.removeProperty('animation');
          document.body.style.removeProperty('transition');
          }, 150);
      }
      
      document.addEventListener('scroll', function(e) {
        lastKnownScrollPosition = window.scrollY;
        if (!ticking) {
          window.requestAnimationFrame(function() {
            optimizeOnScroll(lastKnownScrollPosition);
            ticking = false;
          });
          ticking = true;
        }
        }, { passive: true });
        
      // Advanced image optimization
      function optimizeImages() {
          const images = document.getElementsByTagName('img');
          for (let img of images) {
          // Enable lazy loading
            img.loading = 'lazy';
            img.decoding = 'async';
          
          // Optimize image size
          if (img.naturalWidth > window.innerWidth * 2) {
            img.style.setProperty('max-width', '100%');
            img.style.setProperty('height', 'auto');
          }
          
          // Add hardware acceleration
          img.style.setProperty('transform', 'translateZ(0)');
          img.style.setProperty('backface-visibility', 'hidden');
        }
      }
      
      // Optimize DOM updates
      const observer = new MutationObserver((mutations) => {
        requestAnimationFrame(() => {
          optimizeImages();
        });
      });
      
      observer.observe(document.body, {
        childList: true,
        subtree: true
      });
      
      // Optimize resource loading
      function optimizeResources() {
        // Preconnect to origins
        const links = document.getElementsByTagName('a');
        const origins = new Set();
        for (let link of links) {
          try {
            const url = new URL(link.href);
            origins.add(url.origin);
          } catch (e) {}
        }
        
        origins.forEach(origin => {
          const link = document.createElement('link');
          link.rel = 'preconnect';
          link.href = origin;
          document.head.appendChild(link);
        });
        
        // Preload important resources
        const resources = document.querySelectorAll('script[src], link[rel="stylesheet"]');
        resources.forEach(resource => {
          const preload = document.createElement('link');
          preload.rel = 'preload';
          preload.as = resource.tagName === 'SCRIPT' ? 'script' : 'style';
          preload.href = resource.src || resource.href;
          document.head.appendChild(preload);
        });
      }
      
      // Initialize optimizations
      window.addEventListener('load', () => {
        optimizeImages();
        optimizeResources();
        
        // Remove unnecessary event listeners
        const clone = document.body.cloneNode(true);
        document.body.parentNode.replaceChild(clone, document.body);
      });
      
      // Optimize font loading
      document.fonts.ready.then(() => {
        document.documentElement.style.setProperty('font-display', 'optional');
      });
      
      // Clear unnecessary timers and intervals
      for (let i = 1; i < 1000; i++) {
        window.clearTimeout(i);
        window.clearInterval(i);
      }
    ''');

    // Platform-specific optimizations
    if (Platform.isAndroid) {
      final androidController = controller.platform as AndroidWebViewController;
      await androidController.setMediaPlaybackRequiresUserGesture(true);
      
      // Enable hardware acceleration
      await controller.runJavaScript('''
        document.documentElement.style.setProperty('-webkit-transform', 'translate3d(0,0,0)');
        document.documentElement.style.setProperty('-webkit-backface-visibility', 'hidden');
      ''');
    }
  }

  Future<void> _checkMemoryAndOptimize() async {
    try {
      // Aggressive tab suspension
        for (var i = 0; i < tabs.length; i++) {
          if (i != currentTabIndex) {
            await _suspendTab(tabs[i]);
          
          // Clear more resources
          await tabs[i].controller.runJavaScript('''
            // Clear timers and listeners
            for (let i = 1; i < 1000; i++) {
              window.clearTimeout(i);
              window.clearInterval(i);
            }
            
            // Clear event listeners
            const clone = document.body.cloneNode(true);
            document.body.parentNode.replaceChild(clone, document.body);
            
            // Clear memory
            window.performance?.clearResourceTimings();
            window.performance?.clearMarks();
            window.performance?.clearMeasures();
            
            // Clear cache
            if ('caches' in window) {
              caches.keys().then(keys => {
                keys.forEach(key => caches.delete(key));
              });
            }
            
            // Clear storage
            localStorage.clear();
            sessionStorage.clear();
            
            // Clear service workers
            if (navigator.serviceWorker) {
              navigator.serviceWorker.getRegistrations().then(registrations => {
                registrations.forEach(registration => registration.unregister());
              });
            }
          ''');
        }
      }
    } catch (e) {
      print('Memory optimization error: $e');
    }
  }

  Future<void> _initializeWebViewOptimizations() async {
    // Add advanced WebView optimizations
    await controller.runJavaScript('''
      // Optimize rendering performance
      document.documentElement.style.setProperty('scroll-behavior', 'auto');
      document.documentElement.style.setProperty('touch-action', 'manipulation');
      
      // Optimize scroll performance
      let scrollTimeout;
      document.addEventListener('scroll', (e) => {
        if (!document.body.style.willChange) {
          document.body.style.willChange = 'transform';
        }
        clearTimeout(scrollTimeout);
        scrollTimeout = setTimeout(() => {
          document.body.style.willChange = 'auto';
        }, 100);
      }, { passive: true });
      
      // Optimize image loading and rendering
      document.addEventListener('DOMContentLoaded', () => {
        // Add IntersectionObserver for lazy loading
        const observer = new IntersectionObserver((entries) => {
          entries.forEach(entry => {
            if (entry.isIntersecting) {
              const img = entry.target;
              if (img.dataset.src) {
                img.src = img.dataset.src;
                img.removeAttribute('data-src');
                observer.unobserve(img);
              }
            }
          });
        }, {
          rootMargin: '50px 0px',
          threshold: 0.01
        });
        
        // Optimize all images
        document.querySelectorAll('img').forEach(img => {
          if (img.src && !img.loading) {
            img.loading = 'lazy';
            img.decoding = 'async';
            observer.observe(img);
          }
        });
        
        // Optimize iframes
        document.querySelectorAll('iframe').forEach(iframe => {
          iframe.loading = 'lazy';
        });
      });
      
      // Optimize animations and transitions
      document.documentElement.style.setProperty('--webkit-transition', 'transform');
      document.body.style.setProperty('backface-visibility', 'hidden');
      document.body.style.setProperty('-webkit-backface-visibility', 'hidden');
    ''');

    if (Platform.isAndroid) {
      final androidController = controller.platform as AndroidWebViewController;
      await androidController.setMediaPlaybackRequiresUserGesture(true);
      
      // Enable hardware acceleration
      await controller.runJavaScript('''
        document.documentElement.style.setProperty('-webkit-transform', 'translate3d(0,0,0)');
        document.documentElement.style.setProperty('-webkit-backface-visibility', 'hidden');
      ''');
    }
  }

  Widget _buildOverlayPanel() {
    final bool isPanelVisible = isTabsVisible || isSettingsVisible || isBookmarksVisible || isDownloadsVisible;
    
    if (!isPanelVisible) return const SizedBox.shrink();

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      top: 0,
      left: 0,
      right: 0,
      bottom: 0,
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onVerticalDragUpdate: (details) {
            if (details.delta.dy > 10) {
              setState(() {
                isTabsVisible = false;
                isSettingsVisible = false;
                isBookmarksVisible = false;
                isDownloadsVisible = false;
              });
            }
          },
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                color: ThemeManager.backgroundColor().withOpacity(0.7),
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: child,
                    );
                  },
                  child: AnimatedSlide(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    offset: isPanelVisible ? Offset.zero : const Offset(0, 1),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: isPanelVisible ? 1.0 : 0.0,
                      child: isTabsVisible 
                        ? _buildTabsPanel() 
                        : isSettingsVisible
                          ? _buildSettingsPanel()
                          : isBookmarksVisible
                            ? _buildBookmarksPanel()
                            : isDownloadsVisible
                              ? _buildDownloadsPanel()
                              : Container(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabsPanel() {
    final displayTabs = tabs.where((tab) => 
      !tab.url.startsWith('file:///') && 
      !tab.url.startsWith('about:blank') && 
      tab.url != _homeUrl
    ).toList();

    return Container(
      height: MediaQuery.of(context).size.height,
      color: ThemeManager.backgroundColor(),
      child: Column(
        children: [
          Container(
            height: 56 + MediaQuery.of(context).padding.top,
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            decoration: BoxDecoration(
              color: ThemeManager.backgroundColor(),
              boxShadow: [
                BoxShadow(
                  color: ThemeManager.textColor().withOpacity(0.1),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.chevron_left,
                    color: ThemeManager.textColor(),
                    size: 22,
                  ),
                  onPressed: () {
                    setState(() {
                      isTabsVisible = false;
                    });
                  },
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildHeaderButton(
                        title: AppLocalizations.of(context)!.tabs,
                        count: displayTabs.length,
                        isSelected: !isHistoryVisible,
                        onTap: () => setState(() => isHistoryVisible = false),
                      ),
                      SizedBox(width: 16),
                      _buildHeaderButton(
                        title: AppLocalizations.of(context)!.history,
                        count: _loadedHistory.length,
                        isSelected: isHistoryVisible,
                        onTap: () => setState(() => isHistoryVisible = true),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.add_circle_outline_rounded,
                    color: ThemeManager.textColor(),
                    size: 22,
                  ),
                  onSelected: (String value) {
                    if (value == 'normal') {
                      _addNewTab();
                    } else if (value == 'incognito') {
                      _addNewTab(isIncognito: true);
                    }
                    setState(() {
                      isTabsVisible = false;
                    });
                  },
                  color: ThemeManager.surfaceColor(),
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: ThemeManager.textSecondaryColor().withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      value: 'normal',
                      child: Row(
                        children: [
                          Icon(
                            Icons.tab_rounded,
                            size: 20,
                            color: ThemeManager.textColor(),
                          ),
                          SizedBox(width: 12),
                          Text(
                            AppLocalizations.of(context)!.new_tab,
                            style: TextStyle(
                              color: ThemeManager.textColor(),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'incognito',
                      child: Row(
                        children: [
                          Icon(
                            Icons.visibility_off_rounded,
                            size: 20,
                            color: ThemeManager.textColor(),
                          ),
                          SizedBox(width: 12),
                          Text(
                            AppLocalizations.of(context)!.new_incognito_tab,
                            style: TextStyle(
                              color: ThemeManager.textColor(),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: isHistoryVisible
              ? _buildHistoryList()
              : displayTabs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.tab_unselected_rounded,
                          size: 48,
                          color: ThemeManager.surfaceColor().withOpacity(0.24),
                        ),
                        SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(context)!.no_tabs_open,
                          style: TextStyle(
                            fontSize: 16,
                            color: ThemeManager.textSecondaryColor(),
                          ),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: MediaQuery.of(context).orientation == Orientation.portrait ? 2 : 3,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    padding: EdgeInsets.all(8),
                    physics: BouncingScrollPhysics(),
                    itemCount: displayTabs.length,
                    itemBuilder: (context, index) {
                      final tab = displayTabs[index];
                      final isCurrentTab = tab == tabs[currentTabIndex];
                      
                      return GestureDetector(
                        onTap: () async {
                          final tabIndex = tabs.indexOf(tab);
                          if (tabIndex != -1) {
                            await _switchToTab(tabIndex);
                            setState(() {
                              isTabsVisible = false;
                            });
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isCurrentTab 
                              ? ThemeManager.surfaceColor().withOpacity(0.24)
                              : ThemeManager.surfaceColor().withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Container(
                                        color: ThemeManager.surfaceColor().withOpacity(0.05),
                                        child: Center(
                                          child: Container(
                                            width: 24,
                                            height: 24,
                                            child: tab.favicon != null && !tab.isIncognito
                                              ? Image.network(
                                                  tab.favicon!,
                                                  fit: BoxFit.contain,
                                                  errorBuilder: (context, error, stackTrace) => Icon(
                                                    tab.isIncognito ? Icons.visibility_off_rounded : Icons.public_rounded,
                                                    size: 20,
                                                    color: ThemeManager.textSecondaryColor(),
                                                  ),
                                                )
                                              : Icon(
                                                  tab.isIncognito ? Icons.visibility_off_rounded : Icons.public_rounded,
                                                  size: 20,
                                                  color: ThemeManager.textSecondaryColor(),
                                                ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: GestureDetector(
                                          onTap: () => _closeTab(tabs.indexOf(tab)),
                                          child: Container(
                                            padding: EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: ThemeManager.surfaceColor().withOpacity(0.5),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              Icons.close,
                                              size: 18,
                                              color: ThemeManager.textColor(),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tab.title.isEmpty ? _getDisplayUrl(tab.url) : tab.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: ThemeManager.textColor(),
                                        fontWeight: isCurrentTab ? FontWeight.w500 : FontWeight.normal,
                                      ),
                                    ),
                                    if (tab.isIncognito) ...[
                                      SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.visibility_off_rounded,
                                            size: 12,
                                            color: ThemeManager.textSecondaryColor(),
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            AppLocalizations.of(context)!.incognito,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: ThemeManager.textSecondaryColor(),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderButton({
    required String title,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
            ? ThemeManager.primaryColor().withOpacity(0.1)
            : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: ThemeManager.textColor(),
              ),
            ),
            SizedBox(width: 4),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: ThemeManager.primaryColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 12,
                  color: ThemeManager.textSecondaryColor(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Add isHistoryVisible state variable at the top of the class
  bool isHistoryVisible = false;

  void _showHistoryPanel() {
    print('Opening history panel...');
    _loadHistory(); // Refresh history when panel is opened
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.black : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              height: 96 + MediaQuery.of(context).padding.top,
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
              child: Column(
                children: [
                  SizedBox(
                    height: 56,
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.close, color: ThemeManager.textColor()),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Text(
                            'History',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: ThemeManager.textColor(),
                            ),
                          ),
                        ),
                        if (_loadedHistory.isNotEmpty)
                          IconButton(
                            icon: Icon(Icons.delete_outline, color: ThemeManager.textColor()),
                            onPressed: () {
                              _clearHistory();
                              Navigator.pop(context);
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loadedHistory.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history,
                          size: 48,
                          color: ThemeManager.textSecondaryColor(),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No History',
                          style: TextStyle(
                            fontSize: 16,
                            color: ThemeManager.textSecondaryColor(),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _loadedHistory.length,
                    itemBuilder: (context, index) {
                      final item = _loadedHistory[index];
                      return ListTile(
                        leading: item['favicon'] != null
                          ? Image.memory(base64Decode(item['favicon']), width: 16, height: 16)
                          : Icon(Icons.history, size: 16, color: ThemeManager.textSecondaryColor()),
                        title: Text(
                          item['title'] ?? item['url'],
                          style: TextStyle(color: ThemeManager.textColor()),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          item['url'],
                          style: TextStyle(color: ThemeManager.textSecondaryColor()),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Text(
                          _formatDate(DateTime.parse(item['timestamp'])),
                          style: TextStyle(color: ThemeManager.textSecondaryColor()),
                        ),
                        onTap: () {
                          _loadUrl(item['url']);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList() {
    if (_loadedHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 48,
              color: ThemeManager.surfaceColor().withOpacity(0.24),
            ),
            const SizedBox(height: 16),
            Text(
              'No History',
              style: TextStyle(
                fontSize: 16,
                color: ThemeManager.textSecondaryColor(),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _historyScrollController,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _loadedHistory.length,
      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        final historyItem = _loadedHistory[index];
                        final url = historyItem['url'] as String;
                        final title = historyItem['title'] as String;
                        final favicon = historyItem['favicon'] as String?;
                        final timestamp = DateTime.parse(historyItem['timestamp'] as String);

                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: ThemeManager.surfaceColor().withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            leading: SizedBox(
                              width: 24,
                              height: 24,
                              child: favicon != null
                                  ? Image.network(
                                      favicon,
                                      width: 16,
                                      height: 16,
                                      errorBuilder: (context, error, stackTrace) => Icon(
                                        Icons.public,
                                        size: 14,
                    color: ThemeManager.textSecondaryColor(),
                                      ),
                                    )
                                  : Icon(
                                      Icons.public,
                                      size: 14,
                                      color: ThemeManager.textSecondaryColor(),
                                    ),
                            ),
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                Text(
                                  title.isEmpty ? _getDisplayUrl(url) : title,
                  style: TextStyle(
                                    color: ThemeManager.textColor(),
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  url,
                  style: TextStyle(
                    color: ThemeManager.textSecondaryColor(),
                    fontSize: 12,
                                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                                      Text(
                  _formatHistoryDate(timestamp),
                                        style: TextStyle(
                                          color: ThemeManager.textSecondaryColor(),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            trailing: IconButton(
              icon: Icon(
                Icons.delete_outline,
                color: ThemeManager.textSecondaryColor(),
                size: 20,
              ),
              onPressed: () => _removeHistoryItem(index),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            onTap: () {
              _loadUrl(url);
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }

  String _formatHistoryDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes} min ago';
      }
      return '${difference.inHours} hr ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    }

    return DateFormat('MMM d, y').format(date);
  }

  Future<void> _removeHistoryItem(int index) async {
    if (index < 0 || index >= _loadedHistory.length) return;

    final removedItem = _loadedHistory[index];
    setState(() {
      _loadedHistory.removeAt(index);
    });

    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList('history') ?? [];
    
    history.removeWhere((item) {
      try {
        final Map<String, dynamic> decoded = json.decode(item);
        return decoded['url'] == removedItem['url'];
      } catch (e) {
        return false;
      }
    });

    await prefs.setStringList('history', history);
  }

  Widget _buildSettingsPanel() {
    return Material(
      color: ThemeManager.backgroundColor(),
      child: Column(
        children: [
          _buildPanelHeader(AppLocalizations.of(context)!.settings, 
            onBack: () {
              setState(() {
                isSettingsVisible = false;
              });
            }
          ),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _buildPermissionBanner(),
                _buildSettingsSection(
                  title: AppLocalizations.of(context)!.customize_browser,
                  children: [
                    _buildSettingsButton('general', () => _showGeneralSettings()),
                    _buildSettingsButton('appearance', () => _showAppearanceSettings()),
                    _buildSettingsButton('downloads', () => _showDownloadsSettings(), isLast: false),
                    _buildSettingsButton('ai_preferences', () => _showAISettings(), isLast: true),
                  ],
                ),
                _buildSettingsSection(
                  title: AppLocalizations.of(context)!.learn_more,
                  children: [
                    _buildSettingsButton('help', () => _showHelpPage()),
                    _buildSettingsButton('rate_us', () => _showRateUs()),
                    _buildSettingsButton('privacy_policy', () => _showPrivacyPolicy()),
                    _buildSettingsButton('terms_of_use', () => _showTermsOfUse()),
                    _buildSettingsButton('about', () => _showAboutPage()),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionBanner() {
    return FutureBuilder<bool>(
      future: _checkAllPermissions(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final bool hasAllPermissions = snapshot.data!;

        return Container(
          margin: const EdgeInsets.all(12),
          height: 110,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: hasAllPermissions 
                  ? [Colors.green.withOpacity(0.8), Colors.green.withOpacity(0.6)]
                  : [Colors.red.withOpacity(0.8), Colors.red.withOpacity(0.6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: hasAllPermissions ? null : _requestAllPermissions,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              hasAllPermissions 
                                ? AppLocalizations.of(context)!.storage_permission_granted
                                : AppLocalizations.of(context)!.storage_permission_required,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              hasAllPermissions 
                                ? AppLocalizations.of(context)!.app_should_work_normally
                                : AppLocalizations.of(context)!.storage_permission_description,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!hasAllPermissions)
                        ElevatedButton(
                          onPressed: _requestAllPermissions,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          child: Text(AppLocalizations.of(context)!.grant_permission),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<bool> _checkAllPermissions() async {
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    final sdkInt = androidInfo.version.sdkInt;
    
    if (sdkInt >= 33) {
      final photos = await Permission.photos.status;
      final videos = await Permission.videos.status;
      final audio = await Permission.audio.status;
      final notifications = await Permission.notification.status;
      return photos.isGranted && videos.isGranted && audio.isGranted && notifications.isGranted;
    } else {
      final storage = await Permission.storage.status;
      final notifications = await Permission.notification.status;
      return storage.isGranted && notifications.isGranted;
    }
  }

  Future<void> _requestAllPermissions() async {
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    final sdkInt = androidInfo.version.sdkInt;
    
    if (sdkInt >= 33) {
      await [
        Permission.photos,
        Permission.videos,
        Permission.audio,
        Permission.notification,
      ].request();
    } else {
      await [
        Permission.storage,
        Permission.notification,
      ].request();
    }
    
    setState(() {}); // Refresh UI to update permission status
  }

  Widget _buildSettingsButton(String label, VoidCallback onTap, {bool isFirst = false, bool isLast = false}) {
    String getLocalizedLabel() {
      switch (label) {
        case 'general': return AppLocalizations.of(context)!.general;
        case 'downloads': return AppLocalizations.of(context)!.downloads;
        case 'appearance': return AppLocalizations.of(context)!.appearance;
        case 'help': return AppLocalizations.of(context)!.help;
        case 'rate_us': return AppLocalizations.of(context)!.rate_us;
        case 'privacy_policy': return AppLocalizations.of(context)!.privacy_policy;
        case 'terms_of_use': return AppLocalizations.of(context)!.terms_of_use;
        case 'about': return AppLocalizations.of(context)!.about;
        case 'ai_preferences': return AppLocalizations.of(context)!.ai_preferences;
        default: return label;
      }
    }

    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      title: Text(
        getLocalizedLabel(),
        style: TextStyle(
          fontSize: 14,
          color: ThemeManager.textColor(),
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: ThemeManager.textSecondaryColor(),
        size: 20,
      ),
      onTap: onTap,
    );
  }

  void _showResetConfirmation() {
    showCustomDialog(
      context: context,
      title: AppLocalizations.of(context)!.reset_browser,
      content: AppLocalizations.of(context)!.reset_browser_confirm,
      isDarkMode: isDarkMode,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            AppLocalizations.of(context)!.cancel,
            style: TextStyle(
              color: ThemeManager.textSecondaryColor(),
            ),
          ),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(context);
            await _resetBrowser();
          },
          child: Text(
            AppLocalizations.of(context)!.reset,
            style: const TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _resetBrowser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    // Clear WebView data
    await controller.clearCache();
    await controller.clearLocalStorage();
    
    // Clear all tabs except the current one
    setState(() {
      final currentTab = tabs[currentTabIndex];
      tabs.clear();
      tabs.add(currentTab);
      currentTabIndex = 0;
    });
    
    // Load homepage
    await controller.loadRequest(Uri.parse('file:///android_asset/main.html'));
    
    showCustomNotification(
      context: context,
      message: AppLocalizations.of(context)!.reset_complete,
      icon: Icons.check_circle,
      iconColor: ThemeManager.successColor(),
      isDarkMode: isDarkMode,
    );
    
    setState(() {
      isSettingsVisible = false;
    });
  }

  Widget _buildSettingsSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 4, bottom: 4),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: ThemeManager.textColor(),
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: ThemeManager.surfaceColor(),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: ThemeManager.textColor().withOpacity(0.1),
              width: 0.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: children,
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  void _setupHistoryScrollListener() {
    _historyScrollController.addListener(() {
      if (_historyScrollController.position.pixels >= 
          _historyScrollController.position.maxScrollExtent - 500 && !_isLoadingMore) {
        _loadMoreHistory();
      }
    });
  }

  Future<void> _loadMoreHistory() async {
    if (_isLoadingMore) return;
    
    setState(() {
      _isLoadingMore = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList('history') ?? [];
    
    final start = _currentHistoryPage * _historyPageSize;
    if (start >= history.length) {
      setState(() {
        _isLoadingMore = false;
      });
      return;
    }
    
    final end = min(start + _historyPageSize, history.length);
    final newItems = history
      .sublist(start, end)
      .map((e) => Map<String, dynamic>.from(json.decode(e)))
      .toList();
    
    setState(() {
      _loadedHistory.addAll(newItems);
      _currentHistoryPage++;
      _isLoadingMore = false;
    });
  }

  void _startAutoCollapseTimer() {
    _autoCollapseTimer?.cancel();
    _autoCollapseTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && !_isUrlBarExpanded && !_isDragging) {
        setState(() {
          _isUrlBarCollapsed = true;
        });
      }
    });
  }

  void _startLoadingTimer() {
    _loadingTimer?.cancel();
    _loadingTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          isLoading = true;
        });
      }
    });
  }

  void _stopLoadingTimer() {
    _loadingTimer?.cancel();
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarksList = prefs.getStringList('bookmarks') ?? [];
    setState(() {
      bookmarks = bookmarksList.map((e) => Map<String, dynamic>.from(json.decode(e))).toList();
    });
  }

  Future<void> _removeBookmark(String url) async {
    // First update the UI immediately for better responsiveness
    final previousBookmarks = List<Map<String, dynamic>>.from(bookmarks);
    setState(() {
      bookmarks.removeWhere((item) => item['url'] == url);
    });
    
    // Show notification
    _showNotification(
      Row(
        children: [
          Icon(Icons.check_circle, color: ThemeManager.successColor()),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Bookmark removed',
              style: TextStyle(
                color: ThemeManager.textColor(),
              ),
            ),
          ),
        ],
      ),
      duration: const Duration(seconds: 2),
    );
    
    // Then update persistent storage asynchronously
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookmarksList = prefs.getStringList('bookmarks') ?? [];
      
      bookmarksList.removeWhere((item) {
        try {
          final Map<String, dynamic> decoded = json.decode(item);
          return decoded['url'] == url;
        } catch (e) {
          return false;
        }
      });
      
      await prefs.setStringList('bookmarks', bookmarksList);
    } catch (e) {
      // If storage update fails, revert UI
      setState(() {
        bookmarks = previousBookmarks;
      });
    }
  }

  Future<void> _addBookmark() async {
    final url = await controller.currentUrl();
    if (url == null) return;
    
    final title = await controller.getTitle() ?? 'Untitled';
    
    // Check if URL already exists in bookmarks - using local state for speed
    bool isBookmarked = bookmarks.any((item) => item['url'] == url);

    if (isBookmarked) {
      // If already bookmarked, remove it
      await _removeBookmark(url);
      return;
    }

    // Get favicon in background
    BrowserUtils.getFaviconUrl(url).then((favicon) async {
      // Create bookmark object
    final bookmark = {
      'url': url,
      'title': title,
      'favicon': favicon,
      'timestamp': DateTime.now().toIso8601String(),
    };

      // Update UI immediately
      setState(() {
        bookmarks.insert(0, bookmark);
      });
      
      // Show notification
      _showBookmarkAddedNotification();
      
      // Then update storage asynchronously
      try {
        final prefs = await SharedPreferences.getInstance();
        final bookmarksList = prefs.getStringList('bookmarks') ?? [];
        bookmarksList.insert(0, json.encode(bookmark));
        await prefs.setStringList('bookmarks', bookmarksList);
      } catch (e) {
        print("Error saving bookmark: $e");
      }
    });
  }

  Future<void> _suspendTab(BrowserTab tab) async {
    await tab.controller.clearCache();
    await tab.controller.clearLocalStorage();
    _suspendedTabs.add(tab);
    tabs.remove(tab);
  }

  void _resumeTab(BrowserTab tab) {
    _suspendedTabs.remove(tab);
    
    if (tabs.length >= _maxActiveTabs) {
      _suspendTab(tabs.first);
    }

    tabs.add(tab);
    currentTabIndex = tabs.length - 1;
    _initializeWebView();
  }

  void _updateTabInfo() {
    if (currentTabIndex >= 0 && currentTabIndex < tabs.length) {
      controller.getTitle().then((title) {
        if (mounted && title != null) {
          setState(() {
            tabs[currentTabIndex].title = title;
          });
        }
      });

      controller.currentUrl().then((url) {
        if (mounted && url != null) {
          setState(() {
            tabs[currentTabIndex].url = url;
            _displayUrl = url;
          });
        }
      });
    }
  }

  void _addNewTab({String? url, bool isIncognito = false}) {
    final newTab = BrowserTab(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      url: url ?? _homeUrl,
      title: isIncognito ? AppLocalizations.of(context)!.new_incognito_tab : AppLocalizations.of(context)!.new_tab,
      favicon: null,
      isIncognito: isIncognito,
    );
    
    _initializeTab(newTab);
    
    setState(() {
      tabs.add(newTab);
      currentTabIndex = tabs.length - 1;
      controller = newTab.controller;            // Added to update the active controller
      _displayUrl = newTab.url;                   // Added to update the display URL
      _urlController.text = _formatUrl(newTab.url); // Added to update the URL text field
    });
  }

  void _closeTab(int index) {
    if (tabs.isEmpty) return;

    setState(() {
      tabs.removeAt(index);
      if (currentTabIndex >= tabs.length) {
        currentTabIndex = tabs.length - 1;
      }
      if (tabs.isEmpty) {
        _addNewTab();
      } else {
        _switchTab(currentTabIndex);
      }
    });
  }

  String _getAssetPath(String baseName) {
    if (isDarkMode && baseName.endsWith('.png')) {
      final darkVersion = baseName.replaceAll('.png', 'w.png');
      return darkVersion;
    }
    return baseName;
  }

  Widget _buildLoadingBorder() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(seconds: 1),
      builder: (context, double value, child) {
        return CustomPaint(
          painter: LoadingBorderPainter(
            progress: value,
            color: ThemeManager.textColor().withOpacity(0.7),
          ),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
        );
      },
    );
  }

  // Function to extract domain name from URL
  String _extractDomain(String url) {
    try {
      final uri = Uri.parse(url);
      String domain = uri.host;
      if (domain.startsWith('www.')) {
        domain = domain.substring(4);
      }
      return domain;
    } catch (e) {
      return url;
    }
  }

  Widget _buildUrlBar() {
    final displayUrl = _urlFocusNode.hasFocus ? _displayUrl : _formatUrl(_displayUrl);
    final width = MediaQuery.of(context).size.width - 32;
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    
    return Container(
      width: width,
      margin: EdgeInsets.only(bottom: _isClassicMode ? 0 : 8), // Removed 'const' keyword
      child: SlideTransition(
        position: _hideUrlBarAnimation,
        child: _isClassicMode 
          ? Transform.translate(
              offset: Offset(0, 0), // No sliding in classic mode
              child: _buildUrlBarContent(width, keyboardVisible)
            )
          : GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragUpdate: (details) {
                setState(() {
                  _urlBarSlideOffset += details.delta.dx;
                });
              },
              onHorizontalDragEnd: (details) async {
                if (_urlBarSlideOffset.abs() > 50) {
                  if (_urlBarSlideOffset < 0 && canGoBack) {
                    await _goBack();
                  } else if (_urlBarSlideOffset > 0 && canGoForward) {
                    await _goForward();
                  }
                }
                setState(() {
                  _urlBarSlideOffset = 0;
                });
              },
              child: Transform.translate(
                offset: Offset(_urlBarSlideOffset, 0),
                child: _buildUrlBarContent(width, keyboardVisible)
              ),
            ),
      ),
    );
  }

  Widget _buildUrlBarContent(double width, bool keyboardVisible) {
    // Determine if current page is home page
    final isHomePage = _displayUrl == 'file:///android_asset/main.html' || _displayUrl == _homeUrl;
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Stack(
          children: [
            Container(
          width: width,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: (_isClassicMode || keyboardVisible) 
                ? ThemeManager.surfaceColor().withOpacity(0.95) // More opaque when keyboard is visible
                : ThemeManager.backgroundColor().withOpacity(0.7),
            border: Border.all(
              color: ThemeManager.textColor().withOpacity(_isClassicMode ? 0.05 : 0.1),
              width: 1, // Consistent border width regardless of keyboard
            ),
            // No shadow
          ),
          child: Material(
            type: MaterialType.transparency,
            child: Row(
              children: [
                const SizedBox(width: 16),
                Icon(
                  // Show home icon for homepage, otherwise show secure/warning icon
                  isHomePage ? Icons.home_rounded :
                  (isSecure ? Icons.shield : Icons.warning_amber_rounded),
                  size: 16,
                  color: ThemeManager.textColor(),
                  semanticLabel: isHomePage ? 'Home' : 
                    (isSecure ? AppLocalizations.of(context)!.secure_connection : 
                    AppLocalizations.of(context)!.insecure_connection),
                ),
                Expanded(
                  child: TextField(
                    controller: _urlController,
                    focusNode: _urlFocusNode,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: ThemeManager.textColor(),
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.search_or_type_url,
                      hintStyle: TextStyle(
                        color: ThemeManager.textColor().withOpacity(0.5),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onTap: () {
                      if (!_urlFocusNode.hasFocus) {
                        setState(() {
                          if (_displayUrl == 'file:///android_asset/main.html' || _displayUrl == _homeUrl) {
                            _urlController.text = '';
                          } else {
                            _urlController.text = _displayUrl;
                          }
                          _urlController.selection = TextSelection(
                            baseOffset: 0,
                            extentOffset: _urlController.text.length,
                          );
                        });
                      }
                    },
                    onSubmitted: (value) {
                      _loadUrl(value);
                      _urlFocusNode.unfocus();
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 1.0),
                  child: IconButton(
                    icon: Icon(
                      Icons.auto_awesome,
                      size: 20,
                      color: ThemeManager.textColor(),
                    ),
                    onPressed: _showSummaryOptions,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _urlFocusNode.hasFocus ? Icons.close : Icons.refresh,
                    color: ThemeManager.textColor(),
                  ),
                  onPressed: _urlFocusNode.hasFocus
                    ? () {
                        _urlFocusNode.unfocus();
                        setState(() {
                          _urlController.text = _formatUrl(_displayUrl);
                        });
                      }
                    : () {
                        controller.reload();
                      },
                ),
              ],
            ),
          ),
            ),
            // Snake-like loading animation border
            if (isLoading)
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _loadingAnimation,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: LoadingBorderPainter(
                          progress: _loadingAnimation.value,
                          color: ThemeManager.primaryColor(),
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

  Future<WebViewController> _createWebViewController() async {
    final controller = await _initializeWebViewController();
    
    // Initialize JavaScript after controller is ready
    await _injectImageContextMenuJS();
    
    return controller;
  }

  DateTime? _lastBackPressTime;

  Future<bool> _onWillPop() async {
    // First check if any panel is open
    if (isTabsVisible || isSettingsVisible || isBookmarksVisible || isDownloadsVisible) {
      setState(() {
        isTabsVisible = false;
        isSettingsVisible = false;
        isBookmarksVisible = false;
        isDownloadsVisible = false;
      });
      return false;
    }

    if (await controller.canGoBack()) {
      await _goBack();
      return false;
    }

    if (_lastBackPressTime == null || 
        DateTime.now().difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      showCustomNotification(
        context: context,
        message: AppLocalizations.of(context)!.press_back_to_exit,
        icon: Icons.exit_to_app,
        iconColor: ThemeManager.textColor(),
        isDarkMode: isDarkMode,
        duration: const Duration(seconds: 2),
      );
      
      _lastBackPressTime = DateTime.now();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    
    // Force show URL bar when any panel is visible
    if ((isTabsVisible || isSettingsVisible || isBookmarksVisible || isDownloadsVisible) && _hideUrlBar) {
      _hideUrlBar = false;
      _hideUrlBarController.reverse();
    }
    
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: ThemeManager.backgroundColor(),
        extendBody: true,
        extendBodyBehindAppBar: true,
        resizeToAvoidBottomInset: false, // Prevent automatic resizing when keyboard appears
        body: Stack(
          children: [
            // WebView with proper padding - Fixed position regardless of keyboard
            Positioned(
              top: statusBarHeight,
              left: 0,
              right: 0,
              bottom: 0, // Always extend to bottom of screen
              child: IgnorePointer(
                // Ignore pointer events when keyboard is open to prevent WebView from interfering with URL bar
                ignoring: keyboardVisible,
                child: GestureDetector(
                  onTap: () {
                    if (_isSlideUpPanelVisible) {
                      setState(() {
                        _isSlideUpPanelVisible = false;
                        _slideUpController.reverse();
                        _hideUrlBar = false;
                        _hideUrlBarController.reverse();
                      });
                    }
                  },
                  onLongPressStart: (details) async {
                    print("Long press detected at: ${details.globalPosition}");
                    try {
                      final String js = '''
                        (function() {
                          const x = ${details.localPosition.dx};
                          const y = ${details.localPosition.dy};
                          const element = document.elementFromPoint(x, y);
                          if (element && element.tagName === 'IMG') {
                            return element.src;
                          }
                          const img = element ? element.closest('img') : null;
                          return img ? img.src : null;
                        })()
                      ''';
                      
                      final result = await controller.runJavaScriptReturningResult(js);
                      print("JavaScript result: $result");
                      
                      if (result != null && result.toString() != 'null') {
                        final imageUrl = result.toString().replaceAll('"', '');
                        if (imageUrl.isNotEmpty) {
                          print("Found image URL: $imageUrl");
                          _showImageContextMenu(imageUrl, details.globalPosition);
                        }
                      }
                    } catch (e) {
                      print("Error in long press handler: $e");
                    }
                  },
                  child: Container(
                    // Use Container with color to cover entire area including where keyboard would be
                    color: ThemeManager.backgroundColor(),
                    child: WebViewWidget(
                      controller: controller,
                    ),
                  ),
                ),
              ),
            ),

            // WebView scroll detector with padding - Fixed position
            if (!isTabsVisible && !isSettingsVisible && !isBookmarksVisible && !isDownloadsVisible)
            Positioned(
              top: statusBarHeight,
              left: 0,
              right: 0,
              // Adjust bottom position to account for keyboard and buttons
              bottom: keyboardVisible 
                ? keyboardHeight + 120 // Ensure enough space for URL bar and buttons when keyboard is visible
                : (_isClassicMode ? 116 : 60), // Fixed bottom padding based on mode
              child: IgnorePointer(
                ignoring: _isSlideUpPanelVisible || keyboardVisible,
                child: Listener(
                  behavior: HitTestBehavior.translucent,
                  onPointerMove: (PointerMoveEvent event) {
                    // Don't allow URL bar hide/show when keyboard is visible
                    if (keyboardVisible) return;
                    
                    if (!_isSlideUpPanelVisible && event.delta.dy.abs() > 5) {
                      if (event.delta.dx.abs() < event.delta.dy.abs()) {
                        if (event.delta.dy < 0) { // Scrolling up = hide URL bar
                          if (!_hideUrlBar) {
                            setState(() {
                              _hideUrlBar = true;
                              _hideUrlBarController.forward();
                            });
                          }
                        } else { // Scrolling down = show URL bar
                          if (_hideUrlBar) {
                            setState(() {
                              _hideUrlBar = false;
                              _hideUrlBarController.reverse();
                            });
                          }
                        }
                      }
                    }
                  },
                ),
              ),
            ),

            // Overlay panels (tabs, settings, etc.)
            if (isTabsVisible || isSettingsVisible || isBookmarksVisible || isDownloadsVisible)
              _buildOverlayPanel(),
              
            // Classic mode navigation panel with background that extends up to the URL bar
              if (_isClassicMode && !isTabsVisible && !isSettingsVisible && !isBookmarksVisible && !isDownloadsVisible) 
                SlideTransition(
                  position: _hideUrlBarAnimation, // Use the same animation as URL bar
                  child: Stack(
                    children: [
                      // Create a background panel that extends up to include the URL bar
                      Positioned(
                        bottom: keyboardVisible ? keyboardHeight : 0, // Position above keyboard when visible
                        left: 0,
                        right: 0,
                        height: 48 + MediaQuery.of(context).padding.bottom + 60 + 24, // Fixed height
                        child: Container(
                          decoration: BoxDecoration(
                            color: ThemeManager.backgroundColor(), // Fully opaque
                            borderRadius: BorderRadius.vertical(top: Radius.circular(16)), // Rounded top corners
                          ),
                        ),
                      ),
                      // Add the navigation buttons
                      _buildClassicModePanel(),
                    ],
                  ),
                ),
              
            // Bottom controls (URL bar and panels) - only show when no panels are visible
            if (!isTabsVisible && !isSettingsVisible && !isBookmarksVisible && !isDownloadsVisible)
              Positioned(
                left: 0,
                right: 0,
                // Position the URL bar above the keyboard and above navigation buttons when visible
                bottom: keyboardVisible ? 
                   (_isClassicMode ?
                      (keyboardHeight + 65) : // Classic mode - position above keyboard and buttons
                      (keyboardHeight + 8)) : // Non-classic mode - small spacing above keyboard
                   (_isClassicMode ? 
                      70 + MediaQuery.of(context).padding.bottom : // Classic mode fixed position
                      MediaQuery.of(context).padding.bottom + 16), // Regular mode fixed position
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Quick actions and navigation panels - hide when keyboard is visible
                    if (!keyboardVisible)
                      AnimatedBuilder(
                        animation: _slideUpController,
                        builder: (context, child) {
                          final slideValue = _slideUpController.value;
                          return Visibility(
                            visible: slideValue > 0,
                            maintainState: false,
                            child: Transform.translate(
                              offset: Offset(0, 60 + (1 - slideValue) * 60),
                              child: Opacity(
                                opacity: slideValue,
                                child: Material(
                                  color: Colors.transparent,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Handle indicator
                                      GestureDetector(
                                        onVerticalDragUpdate: (details) {
                                          if (details.delta.dy > 2) {
                                            _handleSlideUpPanelVisibility(false);
                                          }
                                        },
                                        onVerticalDragEnd: (details) {
                                          if (details.primaryVelocity != null && details.primaryVelocity! > 50) {
                                            _handleSlideUpPanelVisibility(false);
                                          }
                                        },
                                        child: Container(
                                          width: 32,
                                          height: 4,
                                          margin: const EdgeInsets.only(bottom: 8),
                                          decoration: BoxDecoration(
                                            color: ThemeManager.textColor().withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                        ),
                                      ),
                                      _buildQuickActionsPanel(),
                                      const SizedBox(height: 8),
                                      _buildNavigationPanel(),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                    // URL bar with gesture detection
                    SlideTransition(
                      position: _hideUrlBarAnimation,
                      child: _isClassicMode
                          ? _buildUrlBar() // No gesture detection in classic mode
                          : GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onVerticalDragUpdate: (details) {
                                // Disable vertical drag gestures when keyboard is visible
                                if (keyboardVisible) return;
                                
                                if (!_isSlideUpPanelVisible) {
                                  if (details.delta.dy < -5) {
                                    _handleSlideUpPanelVisibility(true);
                                  }
                                } else {
                                  if (details.delta.dy > 5) {
                                    _handleSlideUpPanelVisibility(false);
                                  }
                                }
                              },
                              onVerticalDragEnd: (details) {
                                // Disable vertical drag gestures when keyboard is visible
                                if (keyboardVisible) return;
                                
                                if (details.primaryVelocity != null) {
                                  if (!_isSlideUpPanelVisible && details.primaryVelocity! < -100) {
                                    _handleSlideUpPanelVisibility(true);
                                  } else if (_isSlideUpPanelVisible && details.primaryVelocity! > 100) {
                                    _handleSlideUpPanelVisibility(false);
                                  }
                                }
                              },
                              child: _buildUrlBar(),
                            ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void didUpdateWidget(covariant BrowserScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Show URL bar when URL changes
    if (_hideUrlBar) {
      setState(() {
        _hideUrlBar = false;
        _hideUrlBarController.reverse();
      });
    }
    // Hide slide-up panel when URL changes
    if (_isSlideUpPanelVisible) {
      setState(() {
        _isSlideUpPanelVisible = false;
        _slideUpController.reverse();
      });
    }
  }

  // Update URL when page changes
  void _updateUrl(String url) {
    if (!mounted) return;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _displayUrl = url;
        if (!_urlFocusNode.hasFocus) {
          _urlController.text = _formatUrl(url);
        }
        
        if (tabs.isNotEmpty && currentTabIndex >= 0 && currentTabIndex < tabs.length) {
          tabs[currentTabIndex].url = url;
        }

        // Update secure indicator based on URL
        try {
          final uri = Uri.parse(url);
          isSecure = uri.scheme == 'https';
        } catch (e) {
          isSecure = false;
        }
      });
      
      // Update navigation state whenever URL changes
      _updateNavigationState();
    });
  }

  // New helper method to handle page start logic without updating the URL bar/secure indicator
  Future<void> _handlePageStarted(String url) async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
    });
    await _updateNavigationState();
    await _optimizationEngine.onPageStartLoad(url);
  }

  // Navigation delegate methods
  Future<NavigationDelegate> get _navigationDelegate async {
    return NavigationDelegate(
      onNavigationRequest: (NavigationRequest request) async {
        final url = request.url.toLowerCase();
        
        // Handle search:// protocol
        if (url.startsWith('search://')) {
          // Extract search term and search directly
          final searchTerm = url.substring(9).trim();
          if (searchTerm.isNotEmpty) {
            // Use search engine directly instead of calling _loadUrl
            final engine = searchEngines[currentSearchEngine] ?? searchEngines['Google']!;
            final searchUrl = engine.replaceAll('{query}', Uri.encodeComponent(searchTerm));
            
            // Load the search URL directly
            await controller.loadRequest(Uri.parse(searchUrl));
            return NavigationDecision.prevent;
          }
        }
        
        // Check if URL is a direct file download
        if (_isDownloadUrl(url)) {
          _handleDownload(request.url);
          return NavigationDecision.prevent;
        }
        
        // Handle blob URLs
        if (url.startsWith('blob:')) {
          _handleDownload(request.url);
          return NavigationDecision.prevent;
        }
        
        // Update URL immediately when navigation starts
        _updateUrl(request.url);
        
        // Allow navigation for all other URLs
        return NavigationDecision.navigate;
      },
      onPageStarted: (String url) async {
        if (!mounted) return;
        setState(() {
          isLoading = true;
          // Update URL when page starts loading
          _displayUrl = url;
          _urlController.text = _formatUrl(url);
          // Update secure indicator based on URL
          try {
            final uri = Uri.parse(url);
            isSecure = uri.scheme == 'https';
          } catch (e) {
            isSecure = false;
          }
        });
        await _updateNavigationState();
        await _optimizationEngine.onPageStartLoad(url);
      },
      onPageFinished: (String url) async {
        if (!mounted) return;
        final title = await controller.getTitle() ?? _displayUrl;
        setState(() {
          isLoading = false;
          // Update URL and title when page finishes loading
          _displayUrl = url;
          _urlController.text = _formatUrl(url);
          if (tabs.isNotEmpty && currentTabIndex >= 0 && currentTabIndex < tabs.length) {
            tabs[currentTabIndex].title = title;
            tabs[currentTabIndex].url = url;
          }
          // Double check secure indicator
          try {
            final uri = Uri.parse(url);
            isSecure = uri.scheme == 'https';
          } catch (e) {
            isSecure = false;
          }
        });
        await _updateNavigationState();
        await _optimizationEngine.onPageFinishLoad(url);
        await _updateFavicon(url);
        await _saveToHistory(url, title);
        await _injectImageContextMenuJS();
      },
      onWebResourceError: (WebResourceError error) async {
        if (!mounted) return;
        final currentUrl = await controller.currentUrl() ?? _displayUrl;
        await _handleWebResourceError(error, currentUrl);
      },
    );
  }

  void _startUrlBarIdleTimer() {
    _urlBarIdleTimer?.cancel();
    _urlBarIdleTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && 
          !_urlFocusNode.hasFocus && 
          !isPanelExpanded && 
          !isTabsVisible && 
          !isSettingsVisible && 
          !isBookmarksVisible && 
          !isDownloadsVisible && 
          !isSearchMode) {
        setState(() {
          _urlBarOffset = const Offset(16.0, 0.0);
        });
      }
    });
  }

  void _updateUrlBarState() {
    if (!_urlFocusNode.hasFocus && !isPanelExpanded) {
      setState(() {
        _urlBarOffset = Offset(16.0, _urlBarOffset.dy);
      });
    }
  }

  String _formatUrl(String url, {bool showFull = false}) {
    // Always hide home page URL, even in edit mode
    if (url.startsWith('file:///android_asset/main.html') || url == _homeUrl) {
      return '';
    }
    
    if (url.startsWith('file:///')) {
      return '';
    }
    
    // Handle search:// protocol
    if (url.startsWith('search://')) {
      // If the URL bar has focus, show the full URL
      if (_urlFocusNode.hasFocus || showFull) {
        return url;
      }
      // Otherwise, remove search:// prefix and format as normal
      return _formatUrl(url.substring(9), showFull: showFull);
    }
    
    // If URL bar has focus or showFull is explicitly requested, show the full URL
    if (_urlFocusNode.hasFocus || showFull) {
      return url;
    }
    
    try {
      final uri = Uri.parse(url);
      
      // When not focused, always show domain only
      String domain = uri.host;
      if (domain.startsWith('www.')) {
        domain = domain.substring(4);
      }
      return domain;
    } catch (e) {
      // If URL can't be parsed, show as is
      return url;
    }
  }

  Future<void> _handleFullscreenChange(bool isFullscreen) async {
    setState(() {
      _isFullscreen = isFullscreen;
    });
    
    if (isFullscreen) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarIconBrightness: Brightness.light,
      ));
    } else {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        statusBarColor: ThemeManager.backgroundColor(),
        statusBarIconBrightness: ThemeManager.textColor().computeLuminance() > 0.5 ? Brightness.light : Brightness.dark,
        statusBarBrightness: ThemeManager.backgroundColor().computeLuminance() > 0.5 ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: ThemeManager.textColor().computeLuminance() > 0.5 ? Brightness.light : Brightness.dark,
        systemNavigationBarContrastEnforced: false,
        systemNavigationBarDividerColor: Colors.transparent,
      ));
    }
  }

  Future<String> _getDownloadLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final directory = await getApplicationDocumentsDirectory();
    return prefs.getString('downloadLocation') ?? directory.path;
  }

  Future<void> _handleDownload(String url) async {
    try {
      final notificationService = NotificationService();
      await notificationService.initialize();
      
      setState(() {
        isDownloading = true;
        currentDownloadUrl = url;
        downloadProgress = 0.0;
      });
    
            // Handle base64 images
      if (url.startsWith('data:image/')) {
        final mimeType = url.split(';')[0].split(':')[1];
        final ext = _getExtensionFromMimeType(mimeType) ?? '.png';
        final fileName = 'image_${DateTime.now().millisecondsSinceEpoch}$ext';
        
        final base64Data = url.split(',')[1];
        final bytes = base64Decode(base64Data);
        
        final downloadsDirectory = Directory('/storage/emulated/0/Download');
        if (!await downloadsDirectory.exists()) {
          await downloadsDirectory.create(recursive: true);
        }
        
        String finalFilePath = '${downloadsDirectory.path}/$fileName';
        String displayFileName = fileName;
        int counter = 1;
        
        while (await File(finalFilePath).exists()) {
          final lastDot = fileName.lastIndexOf('.');
          final nameWithoutExt = fileName.substring(0, lastDot);
          final ext = fileName.substring(lastDot);
          finalFilePath = '${downloadsDirectory.path}/$nameWithoutExt ($counter)$ext';
          displayFileName = '$nameWithoutExt ($counter)$ext';
          counter++;
        }

        final file = File(finalFilePath);
        await file.writeAsBytes(bytes);

        final downloadData = {
          'url': 'base64_image',  // Don't store the full base64 string
          'filename': displayFileName,
          'path': finalFilePath,
          'size': bytes.length,
          'timestamp': DateTime.now().toIso8601String(),
          'mimeType': mimeType
        };

        final prefs = await SharedPreferences.getInstance();
        final downloadsList = prefs.getStringList('downloads') ?? [];
        downloadsList.insert(0, json.encode(downloadData));
        await prefs.setStringList('downloads', downloadsList);

        await _loadDownloads();

        _showNotification(
          Text('${AppLocalizations.of(context)!.download_completed}: $displayFileName'),
          duration: const Duration(seconds: 4),
        );
        await notificationService.showDownloadCompleteNotification(displayFileName);

        setState(() {
          isDownloading = false;
          currentDownloadUrl = '';
          _currentFileName = null;
          _currentDownloadSize = null;
          downloadProgress = 0.0;
        });
        return;
      }

      // Show in-app download started notification
      _showNotification(
        Text('${AppLocalizations.of(context)!.download_started}: ${url.split('/').last}'),
        duration: const Duration(seconds: 2),
      );

      // Show system download started notification
      await notificationService.showDownloadStartedNotification(url.split('/').last);

      // Create HTTP client with redirect following
      final client = HttpClient()
        ..maxConnectionsPerHost = 5
        ..connectionTimeout = const Duration(seconds: 30)
        ..idleTimeout = const Duration(seconds: 30)
        ..autoUncompress = true;

      final request = await client.getUrl(Uri.parse(url));
      
      // Add headers to handle various download scenarios
      request.headers.add('Accept', '*/*');
      request.headers.add('User-Agent', 'Mozilla/5.0');
      request.followRedirects = true;
      request.maxRedirects = 5;
      
      final response = await request.close();
      
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final contentLength = response.contentLength;
      
      // Try to get filename from content disposition header
      String? fileName;
      final contentDisposition = response.headers['content-disposition'];
      if (contentDisposition != null && contentDisposition.isNotEmpty) {
        final match = RegExp(r'filename[^;=\n]*=((["]).*?\2|[^;\n]*)').firstMatch(contentDisposition.first);
        if (match != null) {
          fileName = match.group(1)?.replaceAll('"', '');
        }
      }
      
      // If no filename in header, try to get from URL
      if (fileName == null || fileName.isEmpty) {
        fileName = url.split('/').last.split('?').first;
        if (fileName.isEmpty || !fileName.contains('.')) {
          // Try to determine extension from content-type
          final contentType = response.headers.value('content-type');
          if (contentType != null) {
            final ext = _getExtensionFromMimeType(contentType);
            if (ext != null) {
              fileName = 'download_${DateTime.now().millisecondsSinceEpoch}$ext';
            } else {
              fileName = 'download_${DateTime.now().millisecondsSinceEpoch}';
            }
          } else {
            fileName = 'download_${DateTime.now().millisecondsSinceEpoch}';
          }
        }
      }

      // Clean up the filename
      fileName = fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
      
      setState(() {
        _currentFileName = fileName;
        _currentDownloadSize = contentLength;
      });

      // Always use the system's Download directory
      final downloadsDirectory = Directory('/storage/emulated/0/Download');
      if (!await downloadsDirectory.exists()) {
        await downloadsDirectory.create(recursive: true);
      }
      
      final filePath = '${downloadsDirectory.path}/$fileName';
      
      // Handle duplicate filenames
      String finalFilePath = filePath;
      String displayFileName = fileName;
      int counter = 1;
      while (await File(finalFilePath).exists()) {
        final lastDot = fileName.lastIndexOf('.');
        if (lastDot != -1) {
          final nameWithoutExt = fileName.substring(0, lastDot);
          final ext = fileName.substring(lastDot);
          finalFilePath = '${downloadsDirectory.path}/$nameWithoutExt ($counter)$ext';
          displayFileName = '$nameWithoutExt ($counter)$ext';
        } else {
          finalFilePath = '${downloadsDirectory.path}/$fileName ($counter)';
          displayFileName = '$fileName ($counter)';
        }
        counter++;
      }

      // Update the current filename to match the actual saved filename
      setState(() {
        _currentFileName = displayFileName;
      });

      // Show in-app download started notification with correct filename
      _showNotification(
        Text('${AppLocalizations.of(context)!.download_started}: $displayFileName'),
        duration: const Duration(seconds: 2),
      );

      // Show system download started notification with correct filename
      await notificationService.showDownloadStartedNotification(displayFileName);

      final file = File(finalFilePath);
      final sink = await file.openWrite();
      
      int received = 0;
      await for (final chunk in response) {
        if (!isDownloading) {
          await sink.close();
          if (await file.exists()) {
            await file.delete();
          }
          _showNotification(
            Text(AppLocalizations.of(context)!.download_canceled),
            duration: const Duration(seconds: 2),
          );
          return;
        }

        sink.add(chunk);
        received += chunk.length;
        if (contentLength > 0) {
          final progress = (received / contentLength * 100).round();
          setState(() {
            downloadProgress = received / contentLength;
          });
          // Update download progress notification with correct filename
          await notificationService.updateDownloadProgress(displayFileName, progress);
        }
      }
      
      await sink.close();
      
      final downloadData = {
        'url': url,
        'filename': displayFileName,  // Store the actual filename used
        'path': finalFilePath,       // Store the full path with counter if needed
        'size': received,
        'timestamp': DateTime.now().toIso8601String(),
        'mimeType': response.headers.value('content-type') ?? 'application/octet-stream'
      };

      final prefs = await SharedPreferences.getInstance();
      final downloadsList = prefs.getStringList('downloads') ?? [];
      downloadsList.insert(0, json.encode(downloadData));
      await prefs.setStringList('downloads', downloadsList);

      // Immediately refresh the downloads list
      await _loadDownloads();

      // Show both in-app and system notifications with correct filename
      _showNotification(
        Text('${AppLocalizations.of(context)!.download_completed}: $displayFileName'),
        duration: const Duration(seconds: 4),
      );
      await notificationService.showDownloadCompleteNotification(displayFileName);

      setState(() {
        isDownloading = false;
        currentDownloadUrl = '';
        _currentFileName = null;
        _currentDownloadSize = null;
        downloadProgress = 0.0;
      });

    } catch (e) {
      setState(() {
        isDownloading = false;
        currentDownloadUrl = '';
        _currentFileName = null;
        _currentDownloadSize = null;
      });
      _showNotification(
        Text(AppLocalizations.of(context)!.download_error.toString().replaceAll('{error}', e.toString())),
        duration: const Duration(seconds: 4),
      );
    }
  }

  String? _getExtensionFromMimeType(String mimeType) {
    final mimeToExt = {
      'application/pdf': '.pdf',
      'application/msword': '.doc',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document': '.docx',
      'application/vnd.ms-excel': '.xls',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet': '.xlsx',
      'application/vnd.ms-powerpoint': '.ppt',
      'application/vnd.openxmlformats-officedocument.presentationml.presentation': '.pptx',
      'application/zip': '.zip',
      'application/x-rar-compressed': '.rar',
      'application/x-7z-compressed': '.7z',
      'audio/mpeg': '.mp3',
      'video/mp4': '.mp4',
      'image/jpeg': '.jpg',
      'image/png': '.png',
      'image/gif': '.gif',
      'application/octet-stream': '.bin'
    };
    
    return mimeToExt[mimeType.split(';')[0].trim()];
  }

  // Save URL bar position for icon state
  Future<void> _saveUrlBarPosition() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('urlBarOffsetX', _urlBarOffset.dx);
  }

  // Load URL bar position for icon state
  Future<void> _loadUrlBarPosition() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _urlBarOffset = const Offset(16.0, 0.0);
    });
  }

  void _showNotification(Widget content, {Duration? duration, SnackBarAction? action}) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;
    
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 300),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, -50 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
                color: ThemeManager.backgroundColor(),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: ThemeManager.textColor().withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(child: content),
                  if (action != null) ...[
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        action.onPressed();
                        overlayEntry.remove();
                      },
                      child: Text(
                        action.label,
                        style: TextStyle(
                          color: ThemeManager.primaryColor(),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(duration ?? const Duration(seconds: 4), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  void _showClearDownloadsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ThemeManager.backgroundColor(),
        title: Text(
          AppLocalizations.of(context)!.clear_downloads_history_title,
          style: TextStyle(
            color: ThemeManager.textColor(),
          ),
        ),
        content: Text(
          AppLocalizations.of(context)!.clear_downloads_history_confirm,
          style: TextStyle(
            color: ThemeManager.textSecondaryColor(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.of(context)!.cancel,
              style: TextStyle(
                color: ThemeManager.textSecondaryColor(),
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('downloads');
              setState(() {
                downloads.clear();
              });
              Navigator.pop(context);
              _showNotification(
                Row(
                  children: [
                    Icon(Icons.check_circle, color: ThemeManager.successColor()),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(AppLocalizations.of(context)!.downloads_history_cleared),
                    ),
                  ],
                ),
                duration: const Duration(seconds: 4),
              );
            },
            child: Text(
              AppLocalizations.of(context)!.clear,
              style: TextStyle(
                color: ThemeManager.errorColor(),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDownloadDialog(int index) {
    final download = downloads[index];
    final fileName = download['filename'];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ThemeManager.backgroundColor(),
        title: Text(
          AppLocalizations.of(context)!.delete_download,
          style: TextStyle(
            color: ThemeManager.textColor(),
          ),
        ),
        content: Text(
          AppLocalizations.of(context)!.delete_download_confirm(fileName),
          style: TextStyle(
            color: ThemeManager.textSecondaryColor(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.of(context)!.cancel,
              style: TextStyle(
                color: ThemeManager.textSecondaryColor(),
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              final downloadsList = prefs.getStringList('downloads') ?? [];
              downloadsList.removeAt(index);
              await prefs.setStringList('downloads', downloadsList);
              setState(() {
                downloads.removeAt(index);
              });
              Navigator.pop(context);
              _showNotification(
                Row(
                  children: [
                    Icon(Icons.check_circle, color: ThemeManager.successColor()),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(AppLocalizations.of(context)!.download_removed),
                    ),
                  ],
                ),
                duration: const Duration(seconds: 4),
              );
            },
            child: Text(
              AppLocalizations.of(context)!.delete,
              style: TextStyle(
                color: ThemeManager.errorColor(),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Update text size functionality
  void _updateTextSize(double scale) async {
    setState(() {
      textScale = scale;
    });
    
    // Update text size for the WebView content
    await controller.runJavaScript('''
      document.documentElement.style.fontSize = '${(16 * scale).round()}px';
      document.body.style.fontSize = '${(16 * scale).round()}px';
      
      // Update all text elements
      const elements = document.querySelectorAll('p, span, div, h1, h2, h3, h4, h5, h6, a, li, td, th, input, button, textarea');
      elements.forEach(el => {
        const computedStyle = window.getComputedStyle(el);
        const currentSize = parseFloat(computedStyle.fontSize);
        el.style.fontSize = (currentSize * $scale) + 'px';
      });
    ''');

    // Save the text size preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('textScale', scale);
  }

  Future<void> _showDownloadLocationPicker() async {
    final directory = await getApplicationDocumentsDirectory();
    final prefs = await SharedPreferences.getInstance();
    String currentPath = prefs.getString('downloadLocation') ?? directory.path;

    try {
      // Use FilePicker to select directory
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
      
      if (selectedDirectory != null) {
        await prefs.setString('downloadLocation', selectedDirectory);
        setState(() {});
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.download_location_changed)),
        );
      }
    } catch (e) {
      print('Error picking directory: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.error_changing_location)),
      );
    }
  }

  // Update the URL bar position handling
  void _updateUrlBarPosition(Offset position) {
    setState(() {
      _urlBarOffset = Offset(
        position.dx.clamp(16.0, MediaQuery.of(context).size.width - 64.0),
        _urlBarOffset.dy
      );
    });
  }

  ImageProvider _getFaviconImage() {
    if (tabs.isNotEmpty && tabs[currentTabIndex].favicon != null) {
      return NetworkImage(tabs[currentTabIndex].favicon!);
    } else if (_currentFaviconUrl != null && _currentFaviconUrl!.isNotEmpty) {
      return NetworkImage(_currentFaviconUrl!);
    }
    return const AssetImage('assets/icons/globe.png');
  }

  // Slide panel state
  late AnimationController _slideUpController;
  bool _isSlideUpPanelVisible = false;
  double _slideUpPanelOffset = 0.0;
  double _slideUpPanelOpacity = 0.0;

  bool get isSlideUpPanelVisible => _isSlideUpPanelVisible;

  void _handleSlideUpPanelVisibility(bool show) {
    setState(() {
      _isSlideUpPanelVisible = show;
      if (show) {
        _slideUpController.forward();
        _hideUrlBarController.forward(); // Hide URL bar when showing panels
      } else {
        _slideUpController.reverse();
        _hideUrlBarController.reverse(); // Show URL bar when hiding panels
      }
    });
  }

  void _updateSlideUpPanelOffset(double value) {
    if (mounted) {
      setState(() {
        _slideUpPanelOffset = value;
      });
    }
  }

  void _updateSlideUpPanelOpacity(double value) {
    if (mounted) {
      setState(() {
        _slideUpPanelOpacity = value;
      });
    }
  }

  void _toggleSlideUpPanel(bool show) {
    if (mounted) {
      setState(() {
        _isSlideUpPanelVisible = show;
        if (show) {
          _slideUpController.forward();
        } else {
          _slideUpController.reverse();
        }
      });
    }
  }

  // Update the onTap handler in the URL bar
  void _handleUrlBarTap() {
    _urlFocusNode.requestFocus();
    setState(() {
      _urlController.text = _displayUrl;
      _urlController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _urlController.text.length,
      );
    });
  }

  // Update favicon when page changes
  Future<void> _updateFavicon(String url) async {
    try {
      final faviconUrl = await BrowserUtils.getFaviconUrl(url);
      if (mounted) {
        setState(() {
          _currentFaviconUrl = faviconUrl;
          if (tabs.isNotEmpty && currentTabIndex >= 0 && currentTabIndex < tabs.length) {
            tabs[currentTabIndex].favicon = faviconUrl;
          }
        });
      }
    } catch (e) {
      print('Error updating favicon: $e');
    }
  }

  Widget _buildNavigationPanel() {
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        if (details.delta.dy > 2) {
          _handleSlideUpPanelVisibility(false);
        }
      },
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! > 50) {
          _handleSlideUpPanelVisibility(false);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: ThemeManager.textColor().withOpacity(0.1),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              height: 48,
              color: ThemeManager.backgroundColor().withOpacity(0.7),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, size: 24),
                    color: canGoBack ? ThemeManager.textColor() : ThemeManager.textColor().withOpacity(0.3),
                    onPressed: canGoBack ? () {
                      _goBack();
                      if (_hideUrlBar) {
                        setState(() {
                          _hideUrlBar = false;
                          _hideUrlBarController.reverse();
                        });
                      }
                    } : null,
                  ),
                  IconButton(
                    icon: Icon(
                      isCurrentPageBookmarked ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                      size: 24,
                    ),
                    color: ThemeManager.textSecondaryColor(),
                    onPressed: () {
                      _addBookmark();
                      if (_hideUrlBar) {
                        setState(() {
                          _hideUrlBar = false;
                          _hideUrlBarController.reverse();
                        });
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.ios_share_rounded, size: 24),
                    color: ThemeManager.textSecondaryColor(),
                    onPressed: () async {
                      if (currentUrl.isNotEmpty) {
                        await Share.share(currentUrl);
                      }
                      if (_hideUrlBar) {
                        setState(() {
                          _hideUrlBar = false;
                          _hideUrlBarController.reverse();
                        });
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, size: 24),
                    color: canGoForward ? ThemeManager.textColor() : ThemeManager.textColor().withOpacity(0.3),
                    onPressed: canGoForward ? () {
                      _goForward();
                      if (_hideUrlBar) {
                        setState(() {
                          _hideUrlBar = false;
                          _hideUrlBarController.reverse();
                        });
                      }
                    } : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Add new variables
  bool _isUrlBarVisible = true;
  double _urlBarSlideOffset = 0.0;

  void _showImageOptions(String imageUrl, Offset position) {
    final showCustomMenu = true; // Flag to use custom menu with animations
    
    if (showCustomMenu) {
      // Custom menu with in-to-out animation
      final List<Widget> menuItems = [
        // Open in new tab
        ListTile(
          leading: Icon(Icons.image, color: ThemeManager.textColor()),
          title: Text(
            AppLocalizations.of(context)!.open_in_new_tab,
            style: TextStyle(color: ThemeManager.textColor()),
          ),
          onTap: () {
            Navigator.pop(context);
            _loadUrl(imageUrl);
          },
        ),
        // Download (fixed text)
        ListTile(
          leading: Icon(Icons.download, color: ThemeManager.textColor()),
          title: Text(
            "Download", // Fixed to use "Download" instead of "Downloads"
            style: TextStyle(color: ThemeManager.textColor()),
          ),
          onTap: () {
            Navigator.pop(context);
            _handleDownload(imageUrl);
          },
        ),
        // Share
        ListTile(
          leading: Icon(Icons.share, color: ThemeManager.textColor()),
          title: Text(
            AppLocalizations.of(context)!.share,
            style: TextStyle(color: ThemeManager.textColor()),
          ),
          onTap: () async {
            Navigator.pop(context);
            await Share.share(imageUrl);
          },
        ),
      ];
      
      // Show the custom menu with scale animation (in-to-out)
      Navigator.of(context).push(
        PageRouteBuilder(
          opaque: false,
          barrierDismissible: true,
          barrierColor: Colors.transparent,
          pageBuilder: (BuildContext context, _, __) {
            return StatefulBuilder(
              builder: (context, setState) {
                return GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Material(
                    color: Colors.transparent,
                    child: Stack(
                      children: [
                        Positioned(
                          left: position.dx,
                          top: position.dy,
                          child: TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 150),
                            curve: Curves.easeOutCubic,
                            tween: Tween<double>(begin: 0.8, end: 1.0),
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: value,
                                alignment: Alignment.center,
                                child: child,
                              );
                            },
                            child: Card(
                              color: ThemeManager.backgroundColor(),
                              elevation: 8,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IntrinsicWidth(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: menuItems,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      );
    } else {
      // Original showMenu implementation (fallback)
      final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
      final RelativeRect positionRect = RelativeRect.fromRect(
        Rect.fromPoints(
          position,
          position.translate(40, 40), // Give some space for the menu
        ),
        Offset.zero & overlay.size,
      );

      showMenu(
        context: context,
        color: ThemeManager.backgroundColor(),
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        position: positionRect,
        items: [
          PopupMenuItem(
            child: Row(
              children: [
                Icon(Icons.image, color: ThemeManager.textColor()),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.open_in_new_tab,
                  style: TextStyle(color: ThemeManager.textColor()),
                ),
              ],
            ),
            onTap: () {
              _loadUrl(imageUrl);
            },
          ),
          PopupMenuItem(
            child: Row(
              children: [
                Icon(Icons.download, color: ThemeManager.textColor()),
                const SizedBox(width: 8),
                Text(
                  "Download", // Fixed to use "Download" instead of "Downloads"
                  style: TextStyle(color: ThemeManager.textColor()),
                ),
              ],
            ),
            onTap: () {
              _handleDownload(imageUrl);
            },
          ),
          PopupMenuItem(
            child: Row(
              children: [
                Icon(Icons.share, color: ThemeManager.textColor()),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.share,
                  style: TextStyle(color: ThemeManager.textColor()),
                ),
              ],
            ),
            onTap: () async {
              await Share.share(imageUrl);
            },
          ),
        ],
      );
    }
  }

  // Add tap position tracking
  Offset _tapPosition = Offset.zero;

  Future<void> _goBack() async {
    if (!canGoBack) return;
    
    try {
      await controller.goBack();
      
      // Wait a bit for the navigation to complete
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Update URL and navigation state
      final url = await controller.currentUrl();
      final title = await controller.getTitle();
      
      if (mounted && url != null) {
        setState(() {
          _displayUrl = url;
          _urlController.text = _formatUrl(url);
          if (title != null) {
            tabs[currentTabIndex].title = title;
          }
          tabs[currentTabIndex].url = url;
        });
        
        await _updateNavigationState();
      }
    } catch (e) {
      print('Error navigating back: $e');
    }
  }

  Future<void> _goForward() async {
    if (!canGoForward) return;
    
    try {
      await controller.goForward();
      
      // Wait a bit for the navigation to complete
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Update URL and navigation state
      final url = await controller.currentUrl();
      final title = await controller.getTitle();
      
      if (mounted && url != null) {
        setState(() {
          _displayUrl = url;
          _urlController.text = _formatUrl(url);
          if (title != null) {
            tabs[currentTabIndex].title = title;
          }
          tabs[currentTabIndex].url = url;
        });
        
        await _updateNavigationState();
      }
    } catch (e) {
      print('Error navigating forward: $e');
    }
  }

  // Add new method for switching tabs
  Future<void> _switchToTab(int index) async {
    if (index != currentTabIndex && index >= 0 && index < tabs.length) {
      final tab = tabs[index];
      
      setState(() {
        currentTabIndex = index;
        controller = tab.controller;
        _displayUrl = tab.url;
        _urlController.text = _formatUrl(tab.url);
      });

      // Force reload the page to prevent black screen
      await tab.controller.loadRequest(Uri.parse(tab.url));
    }
  }

  // In the method where you create new tabs
  void _createNewTab(String url) async {
    final newTab = BrowserTab(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      url: url,
      title: 'New Tab',
      isIncognito: tabs.isNotEmpty ? tabs[currentTabIndex].isIncognito : false,
    );

    // Set up navigation delegate before adding the tab
    newTab.controller.setNavigationDelegate(
      NavigationDelegate(
        onPageStarted: (String url) async {
          if (!mounted) return;
          setState(() {
            isLoading = true;
            _displayUrl = url;
            _urlController.text = _formatUrl(url);
          });
        },
        onPageFinished: (String url) async {
          if (!mounted) return;
          final title = await newTab.controller.getTitle() ?? 'New Tab';
          setState(() {
            isLoading = false;
            newTab.title = title;
            newTab.url = url;
          });
          await _saveToHistory(url, title); // Add this line to save history
        },
      ),
    );

    // Add the tab and switch to it
    setState(() {
      tabs.add(newTab);
      currentTabIndex = tabs.length - 1;
      controller = newTab.controller;
      _displayUrl = url;
      _urlController.text = _formatUrl(url);
    });

    // Ensure the page is loaded
    await Future.delayed(Duration(milliseconds: 100));
    if (url.isNotEmpty) {
      await newTab.controller.loadRequest(Uri.parse(url));
    }
  }

  // Add these variables
  String _currentLocale = 'en';
  String _currentSearchEngine = 'google';
  bool _showImages = true;
  double _textSize = 1.0;  // Add this line for text size
  
  final List<Locale> supportedLocales = [
    const Locale('en'),
    const Locale('tr'),
    const Locale('es'),
    const Locale('fr'),
    const Locale('de'),
    const Locale('it'),
    const Locale('pt'),
    const Locale('ru'),
    const Locale('zh'),
    const Locale('ja'),
    const Locale('ko'),
    const Locale('ar'),
    const Locale('hi'),
  ];

  // Add this method
  String _getLanguageName(String languageCode) {
    final Map<String, String> languages = {
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
    return languages[languageCode] ?? languageCode;
  }

  void _showSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: ThemeManager.backgroundColor(),
          appBar: AppBar(
            backgroundColor: ThemeManager.backgroundColor(),
            elevation: 0,
            systemOverlayStyle: SystemUiOverlayStyle(
              statusBarColor: ThemeManager.backgroundColor(),
              statusBarIconBrightness: ThemeManager.textColor().computeLuminance() > 0.5 ? Brightness.light : Brightness.dark,
              statusBarBrightness: ThemeManager.backgroundColor().computeLuminance() > 0.5 ? Brightness.light : Brightness.dark,
              systemNavigationBarColor: Colors.transparent,
              systemNavigationBarIconBrightness: ThemeManager.textColor().computeLuminance() > 0.5 ? Brightness.light : Brightness.dark,
              systemNavigationBarContrastEnforced: false,
              systemNavigationBarDividerColor: Colors.transparent,
            ),
            title: Text(
              AppLocalizations.of(context)!.settings,
              style: TextStyle(
                color: ThemeManager.textColor(),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: ListView(
            padding: EdgeInsets.zero,
            children: [
              _buildSettingsSection(
                title: AppLocalizations.of(context)!.settings,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: ThemeManager.secondaryColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.dark_mode,
                          style: TextStyle(
                            color: ThemeManager.textColor(),
                            fontSize: 16,
                          ),
                        ),
                        Switch(
                          value: isDarkMode,
                          onChanged: _toggleTheme,
                          activeColor: ThemeManager.primaryColor(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCustomDialog({
    required String title,
    required String content,
    required List<Widget> actions,
    Widget? customContent,
  }) {
    showCustomDialog(
      context: context,
      title: title,
      content: content,
      isDarkMode: isDarkMode,
      customContent: customContent,
      actions: actions,
    );
  }

  void _showCustomNotification(String message, {
    IconData? icon,
    Color? iconColor,
    Duration? duration,
    SnackBarAction? action,
  }) {
    showCustomNotification(
      context: context,
      message: message,
      icon: icon,
      iconColor: iconColor,
      isDarkMode: isDarkMode,
      duration: duration,
      action: action,
    );
  }

  void _showBookmarkAddedNotification() {
    showCustomNotification(
      context: context,
      message: AppLocalizations.of(context)!.bookmark_added,
      icon: Icons.bookmark_added,
      iconColor: Colors.green,
      isDarkMode: isDarkMode,
    );
  }

  Widget _buildPanel({
    required Widget header,
    required Widget body,
    double? height,
  }) {
    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      removeBottom: true,
      removeLeft: true,
      removeRight: true,
      child: Container(
        height: height ?? MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.zero,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            header,
            Expanded(child: body),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 48,
            color: Theme.of(context).disabledColor,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Theme.of(context).disabledColor,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return '0m';
        }
        return '${difference.inMinutes}m';
      }
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return DateFormat('MMM d').format(date);
    }
  }

  void _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('history', jsonEncode(_loadedHistory));
  }

  
  void _initializeTab(BrowserTab tab) {
    tab.controller.setNavigationDelegate(
      NavigationDelegate(
        onPageFinished: (String url) async {
          if (mounted) {
            final title = await tab.controller.getTitle() ?? url;
            setState(() {
              tab.title = title;
              tab.url = url;
            });
            // Only save to history if not incognito
            if (!tab.isIncognito) {
              await _saveToHistory(url, title);
            }
          }
        },
        onUrlChange: (UrlChange change) {
          if (mounted) {
            final url = change.url ?? '';
            setState(() {
              tab.url = url;
            });
          }
        },
      ),
    );
  }

  Future<void> _downloadFile(String url, String? suggestedFilename) async {
    try {
      final status = await Permission.storage.status;
      if (!status.isGranted) {
        await Permission.storage.request();
      }

      if (await Permission.storage.isGranted) {
        setState(() {
          isLoading = true;
        });

        final response = await http.get(Uri.parse(url));
        final contentDisposition = response.headers['content-disposition'];
        String fileName = suggestedFilename ?? '';
        
        if (fileName.isEmpty && contentDisposition != null) {
          final match = RegExp(r'filename[^;=\n]*=([\w\.]+)').firstMatch(contentDisposition);
          if (match != null) {
            fileName = match.group(1) ?? '';
          }
        }
        
        if (fileName.isEmpty) {
          fileName = url.split('/').last;
        }

        final dir = await getExternalStorageDirectory();
        if (dir != null) {
          final downloadDir = Directory('${dir.path}/Download');
          if (!await downloadDir.exists()) {
            await downloadDir.create(recursive: true);
          }

          final filePath = '${downloadDir.path}/$fileName';
          final file = File(filePath);
          await file.writeAsBytes(response.bodyBytes);

          // Show download complete notification
          _showNotification(
            Row(
              children: [
                Icon(Icons.check_circle, color: ThemeManager.successColor()),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(AppLocalizations.of(context)!.download_completed + ': $fileName'),
                ),
              ],
            ),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: AppLocalizations.of(context)!.open,
              onPressed: () async {
                try {
                  await OpenFile.open(filePath);
                } catch (e) {
                  _showNotification(
                    Text("Error opening file. Please install a suitable app to open this type of file."),
                    duration: const Duration(seconds: 4),
                  );
                }
              },
            ),
          );

          // Make the file visible to other apps
          const platform = MethodChannel('com.vertex.solar/browser');
          try {
            await platform.invokeMethod('scanFile', {'path': filePath});
          } catch (e) {
            print('Error scanning file: $e');
          }

          // Optionally refresh the media store
          try {
            await platform.invokeMethod('refreshMediaStore');
          } catch (e) {
            print('Error refreshing media store: $e');
          }
        }
      } else {
        _showNotification(
          Text(AppLocalizations.of(context)!.permission_denied),
          duration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      print('Download error: $e');
      _showNotification(
        Text("Download failed: ${e.toString()}"),
        duration: const Duration(seconds: 4),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Add permission monitoring
  void _startPermissionMonitoring() {
    // Removed permission monitoring
  }

  void _showPermissionNotification() {
    // Removed permission notification
  }

  Future<bool> _requestPermissions() async {
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    final sdkInt = androidInfo.version.sdkInt;
    
    List<Permission> permissions = [];
    
    if (sdkInt >= 33) {
      permissions.addAll([
        Permission.photos,
        Permission.videos,
        Permission.audio,
        // Add notification permission for better user experience
        Permission.notification,
      ]);
      
      // For Android 13+, also request all files access for non-media files
      if (await Permission.manageExternalStorage.isGranted == false) {
        final status = await Permission.manageExternalStorage.request();
        if (!status.isGranted) {
          _showNotification(
            Text("Full storage access is needed for downloading non-media files"),
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () => openAppSettings(),
            ),
          );
        }
      }
    } else {
      permissions.add(Permission.storage);
    }

    Map<Permission, PermissionStatus> statuses = await permissions.request();
    return statuses.values.every((status) => status.isGranted);
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return AppLocalizations.of(context)!.just_now;
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, y').format(timestamp);
    }
  }

  Future<void> _openDownloadedFile(Map<String, dynamic> download) async {
    final filePath = download['path']?.toString();
    if (filePath == null) {
      _showNotification(
        Row(
          children: [
            Icon(Icons.error_outline, color: ThemeManager.errorColor()),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Cannot open file: path not found',
                style: TextStyle(
                  color: ThemeManager.textColor(),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 4),
      );
      return;
    }

    try {
      final result = await OpenFile.open(filePath);
      if (result.type != ResultType.done) {
        _showNotification(
          Row(
            children: [
              Icon(Icons.error_outline, color: ThemeManager.errorColor()),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Error opening file: ${result.message}',
                  style: TextStyle(
                    color: ThemeManager.textColor(),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      _showNotification(
        Row(
          children: [
            Icon(Icons.error_outline, color: ThemeManager.errorColor()),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Error opening file: $e',
                style: TextStyle(
                  color: ThemeManager.textColor(),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 4),
      );
    }
  }

  String _getFormattedDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return AppLocalizations.of(context)!.today;
    } else if (difference.inDays == 1) {
      return AppLocalizations.of(context)!.yesterday;
    } else if (difference.inDays < 7) {
      return AppLocalizations.of(context)!.days_ago(difference.inDays);
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return AppLocalizations.of(context)!.weeks_ago(weeks);
    } else {
      final months = (difference.inDays / 30).floor();
      return AppLocalizations.of(context)!.months_ago(months);
    }
  }

  Future<void> _removeDownload(int index) async {
    if (index < 0 || index >= downloads.length) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final downloadsList = prefs.getStringList('downloads') ?? [];
      
      if (index < downloadsList.length) {
        downloadsList.removeAt(index);
        await prefs.setStringList('downloads', downloadsList);
        
        setState(() {
          downloads.removeAt(index);
        });
        
        _showNotification(
          Text(AppLocalizations.of(context)!.download_removed),
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      print('Error removing download: $e');
      _showNotification(
        Text('Error removing download: ${e.toString()}'),
        duration: const Duration(seconds: 4),
      );
    }
  }

  void _showDownloadProgress(String fileName, double progress) {

  }

  Future<bool> _checkStoragePermission() async {
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    final sdkInt = androidInfo.version.sdkInt;
    
    if (sdkInt >= 33) {
      final photos = await Permission.photos.status;
      final videos = await Permission.videos.status;
      final audio = await Permission.audio.status;
      return photos.isGranted && videos.isGranted && audio.isGranted;
    } else {
      final storage = await Permission.storage.status;
      return storage.isGranted;
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = prefs.getBool('darkMode') ?? false;
      textScale = prefs.getDouble('textScale') ?? 1.0;
      showImages = prefs.getBool('showImages') ?? true;
      _askDownloadLocation = prefs.getBool('askDownloadLocation') ?? true;
    });
  }

  Future<void> _loadSearchEngines() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currentSearchEngine = prefs.getString('searchEngine') ?? 'Google';
    });
  }

  String get currentUrl => tabs[currentTabIndex].url;

  bool get isCurrentPageBookmarked => bookmarks.any((bookmark) {
    if (bookmark is Map<String, dynamic>) {
      return bookmark['url'] == currentUrl;
    }
    return false;
  });

  void _showSettingsPanel() {
    setState(() {
      // Hide slide-up panel first
      _isSlideUpPanelVisible = false;
      _slideUpController.reverse();
      // Show URL bar
      _hideUrlBar = false;
      _hideUrlBarController.reverse();
      // Show settings panel
      isSettingsVisible = true;
      isTabsVisible = false;
      isBookmarksVisible = false;
      isDownloadsVisible = false;
    });
  }

  void _showTabsPanel() {
    setState(() {
      // Hide slide-up panel first
      _isSlideUpPanelVisible = false;
      _slideUpController.reverse();
      // Show URL bar
      _hideUrlBar = false;
      _hideUrlBarController.reverse();
      // Show tabs panel
      isTabsVisible = true;
      isSettingsVisible = false;
      isBookmarksVisible = false;
      isDownloadsVisible = false;
    });
  }

  void _showBookmarksPanel() {
    setState(() {
      // Hide slide-up panel first
      _isSlideUpPanelVisible = false;
      _slideUpController.reverse();
      // Show URL bar
      _hideUrlBar = false;
      _hideUrlBarController.reverse();
      // Show bookmarks panel
      isBookmarksVisible = true;
      isTabsVisible = false;
      isSettingsVisible = false;
      isDownloadsVisible = false;
    });
  }

  void _showDownloadsPanel() {
    setState(() {
      // Hide slide-up panel first
      _isSlideUpPanelVisible = false;
      _slideUpController.reverse();
      // Show URL bar
      _hideUrlBar = false;
      _hideUrlBarController.reverse();
      // Show downloads panel
      isDownloadsVisible = true;
      isTabsVisible = false;
      isSettingsVisible = false;
      isBookmarksVisible = false;
    });
  }

  // Add these variables at the top with other state variables
  Offset? _longPressPosition;
  String? _selectedImageUrl;

  // Add this method to inject the JavaScript code
  Future<void> _injectImageContextMenuJS() async {
    await controller.runJavaScript('''
      console.log('Injecting image context menu JS');
      window.findImageAtPoint = function(x, y) {
        console.log('Finding image at point:', x, y);
        try {
          const element = document.elementFromPoint(x, y);
          console.log('Found element:', element);
          if (!element) return null;
          
          if (element.tagName === 'IMG') {
            console.log('Direct image found:', element.src);
            return element.src;
          }
          
          const img = element.querySelector('img') || element.closest('img');
          if (img) {
            console.log('Parent/child image found:', img.src);
            return img.src;
          }
          
          const style = window.getComputedStyle(element);
          if (style.backgroundImage && style.backgroundImage !== 'none') {
            const url = style.backgroundImage.slice(4, -1).replace(/["']/g, '');
            console.log('Background image found:', url);
            return url;
          }
          
          console.log('No image found');
          return null;
        } catch (e) {
          console.error('Error finding image:', e);
          return null;
        }
      };

      // Add touch event handlers
      document.addEventListener('touchstart', function(e) {
        console.log('Touch start event:', e);
        if (e.target.tagName === 'IMG' || e.target.closest('img')) {
          console.log('Touch started on image');
          let startTime = Date.now();
          let moved = false;
          
          const handleTouchEnd = function() {
            const duration = Date.now() - startTime;
            console.log('Touch duration:', duration);
            if (duration > 500 && !moved) {
              console.log('Long press detected');
              const rect = e.target.getBoundingClientRect();
              const imageUrl = e.target.tagName === 'IMG' ? e.target.src : e.target.closest('img').src;
              console.log('Image URL:', imageUrl);
              ImageLongPress.postMessage(JSON.stringify({
                url: imageUrl,
                x: e.touches[0].clientX,
                y: e.touches[0].clientY + window.scrollY
              }));
              e.preventDefault();
            }
          };
          
          const handleTouchMove = function() {
            moved = true;
            cleanup();
          };
          
          const cleanup = function() {
            document.removeEventListener('touchend', handleTouchEnd);
            document.removeEventListener('touchmove', handleTouchMove);
          };
          
          document.addEventListener('touchend', handleTouchEnd, { once: true });
          document.addEventListener('touchmove', handleTouchMove, { once: true });
        }
      }, { passive: false });
    ''');
  }

 void _showImageContextMenu(String imageUrl, Offset position) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final menuWidth = 195.0;
    final menuHeight = imageUrl.startsWith('data:') ? 60.0 : 170.0;

    double adjustedX = position.dx;
    double adjustedY = position.dy;
    
    if (adjustedX + menuWidth > screenWidth) {
      adjustedX = screenWidth - menuWidth - 8;
    }
    if (adjustedX < 8) {
      adjustedX = 8;
    }
    
    if (adjustedY + menuHeight > screenHeight) {
      adjustedY = screenHeight - menuHeight - 8;
    }
    if (adjustedY < 8) {
      adjustedY = 8;
    }
    
     final List<Widget> menuItems = [
      if (!imageUrl.startsWith('data:'))  // Only show open in new tab for non-base64 images
        ListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          leading: Icon(Icons.image, color: ThemeManager.textColor(), size: 20),
          title: Text(
            AppLocalizations.of(context)!.open_in_new_tab,
            style: TextStyle(color: ThemeManager.textColor(), fontSize: 14),
          ),
          onTap: () {
            Navigator.pop(context);
            _loadUrl(imageUrl);
          },
        ),
      ListTile(
        dense: true,
        visualDensity: VisualDensity.compact,
        leading: Icon(Icons.download, color: ThemeManager.textColor(), size: 20),
        title: Text(
          "Download",
          style: TextStyle(color: ThemeManager.textColor(), fontSize: 14),
        ),
        onTap: () {
          Navigator.pop(context);
          _handleDownload(imageUrl);
        },
      ),
      if (!imageUrl.startsWith('data:'))  // Only show share for non-base64 images
        ListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          leading: Icon(Icons.share, color: ThemeManager.textColor(), size: 20),
          title: Text(
            AppLocalizations.of(context)!.share,
            style: TextStyle(color: ThemeManager.textColor(), fontSize: 14),
          ),
          onTap: () async {
            Navigator.pop(context);
            await Share.share(imageUrl);
          },
        ),
    ];
    
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black.withOpacity(0.2),
        pageBuilder: (BuildContext context, _, __) {
          return StatefulBuilder(
            builder: (context, setState) {
              return GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Material(
                  color: Colors.transparent,
                  child: Stack(
                    children: [
                      Positioned(
                        left: adjustedX,
                        top: adjustedY,
                        width: menuWidth,
                        child: TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 150),
                          curve: Curves.easeOutCubic,
                          tween: Tween<double>(begin: 0.8, end: 1.0),
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: value,
                              alignment: Alignment.topLeft,
                              child: child,
                            );
                          },
                          child: Card(
                            color: ThemeManager.backgroundColor(),
                            elevation: 8,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: menuItems,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }
  Future<void> _clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('history', []);
      setState(() {
        _loadedHistory = [];
      });
      print('History cleared successfully');
    } catch (e) {
      print('Error clearing history: $e');
    }
  }

  void _showSummaryOptions() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final menuWidth = 220.0;
    final rightMargin = 20.0;
    final menuHeight = 200.0; // Increased height for the new PWA option
    final urlBarHeight = 60.0;
    final spacing = 8.0;
    
    showMenu(
      context: context,
      color: ThemeManager.backgroundColor(),
      elevation: 8,
      position: RelativeRect.fromLTRB(
        screenWidth - menuWidth - rightMargin,
        screenHeight - menuHeight - urlBarHeight - spacing - MediaQuery.of(context).padding.bottom,
        screenWidth - rightMargin,
        screenHeight - urlBarHeight - MediaQuery.of(context).padding.bottom,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        PopupMenuItem(
          height: 40,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(
                Icons.history_rounded,
                size: 20,
                color: ThemeManager.textColor(),
              ),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context)!.previous_summaries,
                style: TextStyle(
                  color: ThemeManager.textColor(),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          onTap: () async {
            // Wait for menu to close
            await Future.delayed(const Duration(milliseconds: 200));
            if (!mounted) return;
            _showPreviousSummariesModal();
          },
        ),
        PopupMenuItem(
          height: 40,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(
                Icons.description_rounded,
                size: 20,
                color: ThemeManager.textColor(),
              ),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context)!.summarize_page,
                style: TextStyle(
                  color: ThemeManager.textColor(),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          onTap: () async {
            // Wait for menu to close
            await Future.delayed(const Duration(milliseconds: 200));
            if (!mounted) return;
            
            // Get page content and summarize
            final content = await controller.runJavaScriptReturningResult(
              'document.body.innerText'
            ) as String;
            
            try {
              final summary = await AIManager.summarizeText(content, isFullPage: true);
              if (!mounted) return;
              
              _showSummaryModal(summary, url: currentUrl);
            } catch (e) {
              if (!mounted) return;
              _showNotification(
                Text(
                  'Failed to summarize page: ${e.toString()}',
                  style: TextStyle(
                    color: ThemeManager.errorColor(),
                  ),
                ),
                duration: const Duration(seconds: 4),
              );
            }
          },
        ),
        PopupMenuItem(
          height: 40,
          child: FutureBuilder<bool>(
            future: PWAManager.isPWA(_displayUrl),
            builder: (context, snapshot) {
              final isPWA = snapshot.data ?? false;
              return Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(
                    isPWA ? Icons.delete_outline : Icons.add_to_home_screen,
                    size: 20,
                    color: ThemeManager.textColor(),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isPWA 
                      ? AppLocalizations.of(context)?.remove_from_pwa ?? 'Remove from PWA'
                      : AppLocalizations.of(context)?.add_to_pwa ?? 'Add as PWA',
                    style: TextStyle(
                      color: ThemeManager.textColor(),
                      fontSize: 14,
                    ),
                  ),
                ],
              );
            }
          ),
          onTap: () async {
            // Wait for menu to close
            await Future.delayed(const Duration(milliseconds: 200));
            if (!mounted) return;
            
            final isPWA = await PWAManager.isPWA(_displayUrl);
            
            if (isPWA) {
              // Remove from PWA
              final success = await PWAManager.deletePWA(_displayUrl);
              if (success && mounted) {
                _showPWANotification(
                  Row(
                    children: [
                      Icon(Icons.check_circle_outlined, color: Colors.white),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)?.removed_from_pwa ?? 'Removed from PWA',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  duration: const Duration(seconds: 2),
                );
              }
            } else {
              // Add to PWA
              final title = await controller.getTitle() ?? _displayUrl;
              final success = await PWAManager.savePWA(context, _displayUrl, title, tabs[currentTabIndex].favicon);
              
              if (success && mounted) {
                _showPWANotification(
                  Row(
                    children: [
                      Icon(Icons.add_to_home_screen, color: Colors.white),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)?.added_to_pwa ?? 'Added to PWA',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  duration: const Duration(seconds: 2),
                );
              }
            }
          },
        ),
      ],
    );
  }

  void _showPreviousSummariesModal() async {
    final summaries = await AIManager.getPreviousSummaries();
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: ThemeManager.backgroundColor(),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: ThemeManager.textSecondaryColor().withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context)!.previous_summaries,
                    style: TextStyle(
                      color: ThemeManager.textColor(),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (summaries.isNotEmpty)
                    TextButton(
                      onPressed: () async {
                        await AIManager.deleteAllSummaries();
                        if (!mounted) return;
                        Navigator.pop(context);
                      },
                      child: Text(
                        AppLocalizations.of(context)!.clear_all,
                        style: TextStyle(
                          color: ThemeManager.errorColor(),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: summaries.isEmpty
                ? Center(
                    child: Text(
                      'No summaries yet',
                      style: TextStyle(
                        color: ThemeManager.textSecondaryColor(),
                        fontSize: 14,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: summaries.length,
                    itemBuilder: (context, index) {
                      final summary = summaries[index];
                      final date = DateTime.parse(summary['date'] as String);
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: ThemeManager.surfaceColor(),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          summary['url'] != null ? _extractDomain(summary['url'] as String) : 'Unknown Source',
                                          style: TextStyle(
                                            color: ThemeManager.primaryColor(),
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              Icons.copy_rounded,
                                              size: 20,
                                              color: ThemeManager.textSecondaryColor(),
                                            ),
                                            onPressed: () async {
                                              await AIManager.copyToClipboard(summary['text'] as String);
                                              if (!mounted) return;
                                              Navigator.pop(context);
                                              _showNotification(
                                                Text(
                                                  'Summary copied to clipboard',
                                                  style: TextStyle(
                                                    color: ThemeManager.textColor(),
                                                  ),
                                                ),
                                                duration: const Duration(seconds: 2),
                                              );
                                            },
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              Icons.delete_outline,
                                              size: 20,
                                              color: ThemeManager.textSecondaryColor(),
                                            ),
                                            onPressed: () async {
                                              await AIManager.deleteSummary(index);
                                              if (!mounted) return;
                                              Navigator.pop(context);
                                              _showPreviousSummariesModal(); // Refresh the list
                                              _showNotification(
                                                Text(
                                                  'Summary deleted',
                                                  style: TextStyle(
                                                    color: ThemeManager.textColor(),
                                                  ),
                                                ),
                                                duration: const Duration(seconds: 2),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Text(
                                        _formatDate(date),
                                        style: TextStyle(
                                          color: ThemeManager.textSecondaryColor(),
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: ThemeManager.primaryColor().withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          summary['model'] as String,
                                          style: TextStyle(
                                            color: ThemeManager.primaryColor(),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: Text(
                                summary['text'] as String,
                                style: TextStyle(
                                  color: ThemeManager.textColor(),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSummaryModal(String summary, {String? url}) async {
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: ThemeManager.backgroundColor(),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: ThemeManager.textSecondaryColor().withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Page Summary',
                    style: TextStyle(
                      color: ThemeManager.textColor(),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: ThemeManager.surfaceColor(),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      url != null ? _extractDomain(url) : 'Current Page',
                                      style: TextStyle(
                                        color: ThemeManager.primaryColor(),
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          Icons.copy_rounded,
                                          size: 20,
                                          color: ThemeManager.textSecondaryColor(),
                                        ),
                                        onPressed: () async {
                                          await AIManager.copyToClipboard(summary);
                                          if (!mounted) return;
                                          Navigator.pop(context);
                                          _showNotification(
                                            Text(
                                              'Summary copied to clipboard',
                                              style: TextStyle(
                                                color: ThemeManager.textColor(),
                                              ),
                                            ),
                                            duration: const Duration(seconds: 2),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(
                                    _formatDate(DateTime.now()),
                                    style: TextStyle(
                                      color: ThemeManager.textSecondaryColor(),
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: ThemeManager.primaryColor().withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      AIManager.getCurrentProvider() == AIProvider.openai ? 'GPT-3.5 Turbo' : 'Gemini 2.0-Flash',
                                      style: TextStyle(
                                        color: ThemeManager.primaryColor(),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Text(
                            summary,
                            style: TextStyle(
                              color: ThemeManager.textColor(),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassicModePanel() {
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    
    return Positioned(
      // Position above keyboard when keyboard is visible
      bottom: keyboardVisible ? keyboardHeight + 8 : MediaQuery.of(context).padding.bottom + 8,
      left: 0,
      right: 0,
      // Don't let this be covered by the keyboard
      child: Container(
        height: 48, // Fixed height
        decoration: BoxDecoration(
          color: ThemeManager.backgroundColor().withOpacity(0.95), // More opaque for visibility
          // No shadow or border
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded, size: 28),
              color: canGoBack ? ThemeManager.textColor() : ThemeManager.textColor().withOpacity(0.3),
              onPressed: canGoBack ? () {
                _goBack();
                if (_hideUrlBar) {
                  setState(() {
                    _hideUrlBar = false;
                    _hideUrlBarController.reverse();
                  });
                }
              } : null,
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded, size: 28),
              color: canGoForward ? ThemeManager.textColor() : ThemeManager.textColor().withOpacity(0.3),
              onPressed: canGoForward ? () {
                _goForward();
                if (_hideUrlBar) {
                  setState(() {
                    _hideUrlBar = false;
                    _hideUrlBarController.reverse();
                  });
                }
              } : null,
            ),
            IconButton(
              icon: Icon(
                isCurrentPageBookmarked ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                size: 24,
              ),
              color: ThemeManager.textSecondaryColor(),
              onPressed: () => _addBookmark(),
            ),
            IconButton(
              icon: const Icon(Icons.ios_share_rounded, size: 24),
              color: ThemeManager.textSecondaryColor(),
              onPressed: () async {
                if (currentUrl.isNotEmpty) {
                  await Share.share(currentUrl);
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.menu, size: 24),
              color: ThemeManager.textSecondaryColor(),
              onPressed: () {
                _showQuickActionsModal();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickActionsModal() {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final modalHeight = 49 + bottomPadding + 60 + 24; // Match classic mode panel height

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: modalHeight,
        decoration: BoxDecoration(
          color: ThemeManager.backgroundColor(),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: ThemeManager.textSecondaryColor().withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: 16), // Add bottom padding
                child: Center( // Center the row vertically
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildQuickActionButton(
                          AppLocalizations.of(context)!.settings,
                          Icons.settings_rounded,
                          onPressed: () {
                            Navigator.pop(context);
                            _showSettingsPanel();
                          },
                        ),
                        _buildQuickActionButton(
                          AppLocalizations.of(context)!.downloads,
                          Icons.download_rounded,
                          onPressed: () {
                            Navigator.pop(context);
                            _showDownloadsPanel();
                          },
                        ),
                        _buildQuickActionButton(
                          AppLocalizations.of(context)!.tabs,
                          Icons.tab_rounded,
                          onPressed: () {
                            Navigator.pop(context);
                            _showTabsPanel();
                          },
                        ),
                        _buildQuickActionButton(
                          AppLocalizations.of(context)!.bookmarks,
                          Icons.bookmark_rounded,
                          onPressed: () {
                            Navigator.pop(context);
                            _showBookmarksPanel();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Handle focus change to prevent layout shifts with keyboard
  void _handleFocusChange() {
    // When focus changes, we don't need to adjust layouts
    // The fixed positioning will take care of everything
    if (_urlFocusNode.hasFocus) {
      // Keyboard is about to show, make sure UI is ready
      setState(() {
        // Hide any panels that might interfere with typing
        _isSlideUpPanelVisible = false;
        _slideUpController.reverse();
        // Make sure URL bar is visible
        _hideUrlBar = false;
        _hideUrlBarController.reverse();
      });
    }
  }

  Future<void> _handleIntentData() async {
    // If we're already processing an intent or the user is actively typing, don't interrupt
    if (_isLoadingIntentUrl || _urlFocusNode.hasFocus) {
      debugPrint('Ignoring intent while loading or URL bar has focus');
      return;
    }

    try {
      final String? initialUrl = await _platform.invokeMethod('getInitialUrl');
      
      // Ignore if URL is null, empty, or 'null' string
      if (initialUrl == null || initialUrl.isEmpty || initialUrl == 'null') {
        return;
      }
      
      // Compare with the last processed URL - using exact comparison
      if (initialUrl == _lastProcessedIntentUrl) {
        debugPrint('Ignoring duplicate intent URL: $initialUrl');
        return;
      }
      
      // Update the last processed URL
      _lastProcessedIntentUrl = initialUrl;
      
      // Set the loading flag to prevent multiple loads
      _isLoadingIntentUrl = true;
      
      try {
        // Check if this is a PWA launch with specific format
        if (initialUrl.startsWith('pwa://')) {
          // Handle PWA URLs
          String pwaUrl = initialUrl.replaceFirst('pwa://', '');
          
          // Check if this is a redirect URL from a renamed PWA
          if (pwaUrl.contains('#ts=')) {
            // Extract the original URL
            pwaUrl = pwaUrl.split('#ts=')[0];
          }
          
          final pwaList = await PWAManager.getAllPWAs();
          final matchingPwa = pwaList.firstWhere(
            (pwa) => pwa['url'] == pwaUrl || pwa['redirect_url'] == initialUrl,
            orElse: () => <String, dynamic>{},
          );
          
          if (matchingPwa.isNotEmpty) {
            // Launch as PWA
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PWAScreen(
                  url: matchingPwa['url'] as String,
                  title: matchingPwa['title'] as String,
                  favicon: matchingPwa['favicon'] as String?,
                ),
              ),
            );
            return; // Exit early - PWA is handled
          }
        }
        
        // Normal URL handling - only update if different from current URL
        final String currentUrl = tabs[currentTabIndex].url;
        if (initialUrl != currentUrl) {
          // Prevent UI updates if URL bar is in focus
          if (!_urlFocusNode.hasFocus) {
            // Safely update URL display
            _updateUrlBarSafely(initialUrl);
            
            // Update tab URL
            if (mounted) {
              setState(() {
                tabs[currentTabIndex].url = initialUrl;
              });
            }
            
            // Load the URL in WebView
            try {
              await controller.loadRequest(Uri.parse(initialUrl));
              debugPrint('Successfully loaded URL from intent: $initialUrl');
            } catch (e) {
              debugPrint('Error loading URL in WebView: $e');
            }
          } else {
            debugPrint('Not updating URL bar while it has focus');
          }
        } else {
          debugPrint('URL from intent matches current URL, ignoring: $initialUrl');
        }
      } finally {
        // Always reset the loading flag
        _isLoadingIntentUrl = false;
      }
    } catch (e) {
      _isLoadingIntentUrl = false;
      debugPrint('Error handling intent data: $e');
    }
  }
  
  // Safe method to update URL bar without interrupting user typing
  void _updateUrlBarSafely(String url) {
    try {
      // NEVER update if URL bar has focus - this is critical to fix the problem
      if (_urlFocusNode.hasFocus) {
        debugPrint('URL bar has focus, refusing to update text');
        return; // Exit immediately, preserve user input
      }
      
      // When not in focus, always update with formatted URL
      // Update display URL
      _displayUrl = url;
      
      // Format the URL according to rules (domain only when not focused)
      final formattedUrl = _formatUrl(url);
      
      // Always update controller when not in focus
      _urlController.text = formattedUrl;
      
      // Reset selection to end
      _urlController.selection = TextSelection.collapsed(offset: _urlController.text.length);
    } catch (e) {
      debugPrint('Error updating URL bar safely: $e');
    }
  }

  // Show a PWA-specific styled notification
  void _showPWANotification(Widget content, {Duration? duration}) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;
    
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 300),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, -50 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: ThemeManager.primaryColor(),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: ThemeManager.textColor().withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: content,
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(duration ?? const Duration(seconds: 2), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  // Central method to handle URL updates consistently
  void _handleUrlUpdate(String url, {String? title}) {
    // Always update the tab data
    if (tabs.isNotEmpty && currentTabIndex >= 0 && currentTabIndex < tabs.length) {
      setState(() {
        tabs[currentTabIndex].url = url;
        if (title != null) {
          tabs[currentTabIndex].title = title;
        }
      });
    }
    
    // Store the full URL for when focus is gained
    _displayUrl = url;
    
    // Only update URL bar text if not currently focused
    if (!_urlFocusNode.hasFocus && mounted) {
      setState(() {
        // Show domain-only when not focused
        _urlController.text = _formatUrl(url);
        
        // Update secure status
        try {
          final uri = Uri.parse(url);
          isSecure = uri.scheme == 'https';
        } catch (e) {
          isSecure = false;
        }
      });
    }
  }

  Future<void> _handleWebResourceError(WebResourceError error, String url) async {
    if (!mounted) return;
    
    setState(() {
      isLoading = false;
    });
    
    // Log the error details
    print('Web resource error: ${error.description}');
    print('Error code: ${error.errorCode}');
    print('Error type: ${error.errorType}');
    print('Failed URL: $url');
    
    // Update the tab info with error state
    if (tabs.isNotEmpty && currentTabIndex >= 0 && currentTabIndex < tabs.length) {
      setState(() {
        tabs[currentTabIndex].title = 'Error Loading Page';
      });
    }
  }

  // Add method to handle language changes
  Future<void> _setLocale(String languageCode) async {
    setState(() {
      _currentLocale = languageCode;
    });
    
    // Save the selected language to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', languageCode);
    
    // Notify the app about locale change
    if (widget.onLocaleChange != null) {
      widget.onLocaleChange!(languageCode);
    }
    
    // Close the language selection screen
    Navigator.pop(context);
  }

  // Add these animation durations and curves at the class level
  final Duration _dropdownDuration = const Duration(milliseconds: 200);
  final Curve _dropdownCurve = Curves.easeOutCubic;

  // Add this method to show animated dropdown with in-to-out animation
  void _showInToOutDropdown(BuildContext context, Widget child, {required Offset position}) {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return Stack(
            children: [
              // Backdrop
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(color: Colors.transparent),
                ),
              ),
              // Dropdown with scale animation (in-to-out)
              Positioned(
                top: position.dy,
                left: position.dx,
                child: FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(
                      begin: 0.8,
                      end: 1.0,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: _dropdownCurve,
                    )),
                    child: child,
                  ),
                ),
              ),
            ],
          );
        },
        barrierColor: Colors.transparent,
        opaque: false,
        transitionDuration: _dropdownDuration,
      ),
    );
  }

  // Add helper method to show dropdown menu with proper translation
  void _showDropdownMenu(BuildContext context, List<PopupMenuItem<String>> items, {required Offset position}) {
    final ThemeData theme = Theme.of(context);
    
    _showInToOutDropdown(
      context,
      Container(
        decoration: BoxDecoration(
          color: theme.cardColor.withOpacity(0.95),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: IntrinsicWidth(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: items.map((item) {
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      if (item.onTap != null) {
                        item.onTap!();
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: item.child,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
      position: position,
    );
  }

  // Fix the download text translation method to use a fixed string
  String _getDownloadText(BuildContext context) {
    return 'Download'; // Fixed translation that will be the same in all languages
  }

  // Add smooth scrolling controller
  final ScrollController _smoothScrollController = ScrollController();
  
  // Add optimization flags
  bool _isOptimizingPerformance = false;
  final _scrollThrottle = Debouncer(milliseconds: 16); // For 60fps smoothness

  // Add smooth transition controller
  late final AnimationController _transitionController = AnimationController(
    duration: const Duration(milliseconds: 300),
    vsync: this,
  );
  
  // Add transition animations
  late final Animation<double> _fadeTransition = CurvedAnimation(
    parent: _transitionController,
    curve: Curves.easeInOut,
  );

  // Fix the slide transition animation
  late final Animation<Offset> _slideTransition = Tween<Offset>(
    begin: const Offset(0, 0.1),
    end: Offset.zero,
  ).animate(CurvedAnimation(
    parent: _transitionController,
    curve: Curves.easeOutCubic,
  ));

  // Add this method to show optimized dropdown from bottom to top
  void _showBottomToTopDropdown(BuildContext context, Widget child, {required Offset position}) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(color: Colors.transparent),
                ),
              ),
              Positioned(
                top: position.dy,
                left: position.dx,
                child: FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, -0.2),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    )),
                    child: child,
                  ),
                ),
              ),
            ],
          );
        },
        barrierColor: Colors.transparent,
        opaque: false,
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }
}

class ThemeColors {
  final Color background;
  final Color surface;
  final Color text;
  final Color textSecondary;
  final Color border;

  const ThemeColors({
    required this.background,
    required this.surface,
    required this.text,
    required this.textSecondary,
    required this.border,
  });
}

// Add an OptimizedChild widget for better performance
class OptimizedChild extends StatelessWidget {
  final Widget child;
  
  const OptimizedChild({
    Key? key,
    required this.child,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: child,
    );
  }
}