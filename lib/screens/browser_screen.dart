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

  const BrowserScreen({
    Key? key,
    this.onLocaleChange,
    this.onThemeChange,
    this.onSearchEngineChange,
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
    _initializeControllers();
    _urlController = TextEditingController();
    _urlFocusNode = FocusNode();
    _loadPreferences();
    _loadBookmarks();
    _loadDownloads();
    _loadHistory();
    _loadUrlBarPosition();
    _loadSettings();
    _loadSearchEngines();
    
    // Load saved theme
    SharedPreferences.getInstance().then((prefs) {
      final savedTheme = prefs.getString('selectedTheme');
      if (savedTheme != null) {
        try {
          final theme = ThemeType.values.firstWhere((t) => t.name == savedTheme);
          setState(() {
            isDarkMode = theme.isDark;
          });
          ThemeManager.setTheme(theme);
          _updateSystemBars();
        } catch (_) {}
      }
    });
    
    // Handle incoming intents
    if (Platform.isAndroid) {
      _handleIncomingIntents();
    }

    // Set up URL focus listener
    _urlFocusNode.addListener(() {
      if (!_urlFocusNode.hasFocus) {
        setState(() {
          _urlController.text = _formatUrl(_displayUrl);
        });
      }
    });

    _updateSystemBars();

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

    _slideUpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    // Initialize scroll detection
    _setupScrollHandling();

    // Add this line after controller initialization
    _injectImageContextMenuJS();
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
    setState(() {
      isDarkMode = darkMode;
    });
    
    _updateSystemBars();
    
    // Save theme preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', darkMode);
    
    if (widget.onThemeChange != null) {
      widget.onThemeChange!(darkMode);
    }
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
    _loadingAnimationController.dispose();
    _slideAnimationController.dispose();
    _slideUpController.dispose();
    _animationController.dispose();
    _hideUrlBarController.dispose();
    _urlFocusNode.dispose();
    _urlController.dispose();
    _historyScrollController.dispose();
    _optimizationEngine.dispose();
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
        });
      }
    });

    await _initializeWebView();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = prefs.getBool('darkMode') ?? false;
      textScale = prefs.getDouble('textScale') ?? 1.0;
      showImages = prefs.getBool('showImages') ?? true;
      currentSearchEngine = prefs.getString('searchEngine') ?? 'Google';
      currentLanguage = prefs.getString('language') ?? 'en';
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', isDarkMode);
    await prefs.setString('homeUrl', _homeUrl);
    await prefs.setString('searchEngine', _searchEngine);
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
      
      // Enable hardware acceleration
      await webViewController.runJavaScript('''
        document.body.style.setProperty('-webkit-transform', 'translate3d(0,0,0)');
        document.body.style.setProperty('transform', 'translate3d(0,0,0)');
        document.body.style.setProperty('will-change', 'transform, opacity');
        document.body.style.setProperty('backface-visibility', 'hidden');
        document.body.style.setProperty('-webkit-backface-visibility', 'hidden');
      ''');
    }

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
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      controller = WebViewController.fromPlatformCreationParams(
        WebKitWebViewControllerCreationParams(
          allowsInlineMediaPlayback: true,
          mediaTypesRequiringUserAction: const {},
        ),
      );
    } else if (WebViewPlatform.instance is AndroidWebViewPlatform) {
      controller = WebViewController();
      final androidController = controller.platform as AndroidWebViewController;
      await androidController.setBackgroundColor(Colors.transparent);
    } else {
      controller = WebViewController();
    }

    await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    await controller.setBackgroundColor(const Color(0x00000000));
    await controller.enableZoom(false);
    
    await controller.setNavigationDelegate(NavigationDelegate(
      onNavigationRequest: (NavigationRequest request) async {
        final url = request.url.toLowerCase();
        if (_isDownloadUrl(url)) {
          await _handleDownload(request.url);
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

        // Save to history first, before any potentially failing operations
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

        // Continue with other operations that might fail
        try {
          await _updateNavigationState();
          await _optimizationEngine.onPageFinishLoad(url);
          await _updateFavicon(url);
          await _injectImageContextMenuJS();
        } catch (e) {
          print('Error in page finish operations: $e');
        }
        
        print('=== PAGE LOAD COMPLETE ==='); // Debug log
      },
      onWebResourceError: (WebResourceError error) {
        if (!mounted) return;
        setState(() {
          isLoading = false;
        });
        print('Web resource error: ${error.description}');
      },
    ));
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
        
        function notifyUrlChanged() {
          const currentUrl = window.location.href;
          if (currentUrl !== lastUrl) {
            lastUrl = currentUrl;
            if (window.UrlChanged && window.UrlChanged.postMessage) {
              window.UrlChanged.postMessage(currentUrl);
            }
          }
        }

        // Monitor navigation events
        window.addEventListener('popstate', notifyUrlChanged);
        window.addEventListener('hashchange', notifyUrlChanged);
        window.addEventListener('load', notifyUrlChanged);
        
        // Monitor programmatic changes
        const originalPushState = history.pushState;
        const originalReplaceState = history.replaceState;
        
        history.pushState = function() {
          originalPushState.apply(this, arguments);
          notifyUrlChanged();
        };
        
        history.replaceState = function() {
          originalReplaceState.apply(this, arguments);
          notifyUrlChanged();
        };
        
        // Check more frequently for URL changes
        setInterval(notifyUrlChanged, 50);
      })();
    ''');

    await controller.addJavaScriptChannel(
      'UrlChanged',
      onMessageReceived: (JavaScriptMessage message) {
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _updateUrl(message.message);
          });
        }
      },
    );
  }

  Future<void> _updateNavigationState() async {
    if (!mounted) return;
    
    try {
      final canGoBackValue = await controller.canGoBack();
      final canGoForwardValue = await controller.canGoForward();
      
      if (mounted) {
        setState(() {
          canGoBack = canGoBackValue;
          canGoForward = canGoForwardValue;
          
          // Update the current tab's navigation state
          if (tabs.isNotEmpty && currentTabIndex >= 0 && currentTabIndex < tabs.length) {
            tabs[currentTabIndex].canGoBack = canGoBackValue;
            tabs[currentTabIndex].canGoForward = canGoForwardValue;
          }
        });
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
            _showImageOptions(imageUrl);
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
          final query = url.substring(9); // Remove 'search://' prefix
          final decodedQuery = Uri.decodeComponent(query);
          final engine = searchEngines[currentSearchEngine] ?? searchEngines['Google']!;
          final searchUrl = engine.replaceAll('{query}', Uri.encodeComponent(decodedQuery));
          await controller.loadRequest(Uri.parse(searchUrl));
          return NavigationDecision.prevent;
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
      onWebResourceError: (WebResourceError error) {
        if (!mounted) return;
        setState(() {
          isLoading = false;
        });
        print('Web resource error: ${error.description}');
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
      final String entry = json.encode({
        'url': url,
        'title': title.isNotEmpty ? title : url,
        'favicon': null,  // Skip favicon for now to avoid errors
        'timestamp': DateTime.now().toIso8601String(),
      });
      print('Entry created: $entry');

      // Get existing history safely
      List<String> history = [];
      try {
        history = prefs.getStringList('history') ?? [];
      } catch (e) {
        print('Error loading existing history: $e');
      }
      print('Current history size: ${history.length}');

      // Add new entry at the beginning
      history.insert(0, entry);
      print('Added new entry to history');

      // Save back to SharedPreferences
      final success = await prefs.setStringList('history', history);
      print('Save to SharedPreferences result: $success');

      // Update in-memory history if still mounted
      if (mounted) {
        setState(() {
          _loadedHistory = history.map((e) {
            try {
              return Map<String, dynamic>.from(json.decode(e));
            } catch (e) {
              print('Error parsing history entry: $e');
              return null;
            }
          }).whereType<Map<String, dynamic>>().toList();
        });
        print('Updated in-memory history. New size: ${_loadedHistory.length}');
      }
    } catch (e) {
      print('❌ Error saving history: $e');
      print(e.toString());
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

  Future<void> _loadUrl(String url) async {
    if (currentSearchEngine.isEmpty) {
      showCustomNotification(
        context: context,
        message: "Please select a search engine in settings first",
        icon: Icons.warning,
        iconColor: ThemeManager.warningColor(),
        isDarkMode: isDarkMode,
      );
      return;
    }

    String formattedUrl = url.trim();
    if (!formattedUrl.startsWith('http://') && !formattedUrl.startsWith('https://')) {
      if (formattedUrl.contains('.') && !formattedUrl.contains(' ')) {
        formattedUrl = 'https://$formattedUrl';
      } else {
        final engine = searchEngines[currentSearchEngine] ?? searchEngines['Google']!;
        formattedUrl = engine.replaceAll('{query}', Uri.encodeComponent(formattedUrl));
      }
    }
    
    setState(() {
      isLoading = true;
      _displayUrl = formattedUrl;
      _urlController.text = _formatUrl(formattedUrl);
    });
    
    try {
      await controller.loadRequest(Uri.parse(formattedUrl));
      // Update URL immediately after load request
      _updateUrl(formattedUrl);
    } catch (e) {
      print('Error loading URL: $e');
      setState(() {
        isLoading = false;
      });
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
    final currentLocale = prefs.getString('locale') ?? 'en';
    final languages = {
      'en': 'English',
      'tr': 'Türkçe',
      'es': 'Español',
      'ar': 'العربية',
      'hi': 'हिन्दी',
      'ru': 'Русский',
      'zh': '中文',
    };
    return languages[currentLocale] ?? 'English';
  }

  Future<String> _getCurrentSearchEngine() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('search_engine') ?? 'Google';
  }

  void _showGeneralSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: ThemeManager.backgroundColor(),
          appBar: AppBar(
            backgroundColor: ThemeManager.backgroundColor(),
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
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
          body: ListView(
            children: [
              _buildSettingsSection(
                title: AppLocalizations.of(context)!.general,
                children: [
                  _buildSettingsItem(
                    title: AppLocalizations.of(context)!.language,
                    trailing: Icon(
                      Icons.chevron_right,
                      color: ThemeManager.textSecondaryColor(),
                      size: 20,
                    ),
                    onTap: () => _showLanguageSelection(context),
                    isFirst: true,
                  ),
                  _buildSettingsItem(
                    title: AppLocalizations.of(context)!.search_engine,
                    trailing: Icon(
                      Icons.chevron_right,
                      color: ThemeManager.textSecondaryColor(),
                      size: 20,
                    ),
                    onTap: () => _showSearchEngineSelection(context),
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
    
    // Only show arrow for main settings items
    if (trailing == null && onTap != null) {
      if (!searchEngines.keys.contains(title) && 
          !title.contains('हिन्दी') && !title.contains('English') && 
          !title.contains('Türkçe') && !title.contains('Español') && 
          !title.contains('Français') && !title.contains('Deutsch') && 
          !title.contains('Italiano') && !title.contains('Português') && 
          !title.contains('Русский') && !title.contains('中文') && 
          !title.contains('日本語') && !title.contains('العربية') &&
          !title.contains('Language') && !title.contains('Search Engine') &&
          !title.contains('한국어')) {
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
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: ThemeManager.backgroundColor(),
          appBar: AppBar(
            backgroundColor: ThemeManager.backgroundColor(),
            elevation: 0,
            systemOverlayStyle: _transparentNavBar,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: ThemeManager.textColor(),
              ),
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
          body: ListView(
            padding: const EdgeInsets.only(top: 8, bottom: 24),
            children: [
              _buildSettingsSection(
                title: AppLocalizations.of(context)!.chooseLanguage,
                children: supportedLocales.map((locale) {
                  final isSelected = Localizations.localeOf(context).languageCode == locale.languageCode;
                  return _buildSettingsItem(
                    title: _getLanguageName(locale.languageCode),
                    trailing: isSelected ? Icon(Icons.check, color: ThemeManager.primaryColor()) : null,
                    onTap: () {
                      setState(() => _currentLocale = locale.languageCode);
                      widget.onLocaleChange?.call(locale.languageCode);
                      Navigator.pop(context);
                    },
                    isFirst: locale == supportedLocales.first,
                    isLast: locale == supportedLocales.last,
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSearchEngineSelection(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: ThemeManager.backgroundColor(),
          appBar: AppBar(
            backgroundColor: ThemeManager.backgroundColor(),
            elevation: 0,
            systemOverlayStyle: _transparentNavBar,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: ThemeManager.textColor(),
              ),
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
          body: ListView(
            padding: const EdgeInsets.only(top: 8, bottom: 24),
            children: [
              _buildSettingsSection(
                title: AppLocalizations.of(context)!.chooseSearchEngine,
                children: [
                  _buildSettingsItem(
                    title: 'Google',
                    onTap: () => _setSearchEngine('Google'),
                    isFirst: true,
                    trailing: currentSearchEngine == 'Google' ? Icon(Icons.check, color: ThemeManager.primaryColor()) : null,
                  ),
                  _buildSettingsItem(
                    title: 'Bing',
                    onTap: () => _setSearchEngine('Bing'),
                    trailing: currentSearchEngine == 'Bing' ? Icon(Icons.check, color: ThemeManager.primaryColor()) : null,
                  ),
                  _buildSettingsItem(
                    title: 'DuckDuckGo',
                    onTap: () => _setSearchEngine('DuckDuckGo'),
                    trailing: currentSearchEngine == 'DuckDuckGo' ? Icon(Icons.check, color: ThemeManager.primaryColor()) : null,
                  ),
                  _buildSettingsItem(
                    title: 'Brave',
                    onTap: () => _setSearchEngine('Brave'),
                    trailing: currentSearchEngine == 'Brave' ? Icon(Icons.check, color: ThemeManager.primaryColor()) : null,
                  ),
                  _buildSettingsItem(
                    title: 'Yahoo',
                    onTap: () => _setSearchEngine('Yahoo'),
                    trailing: currentSearchEngine == 'Yahoo' ? Icon(Icons.check, color: ThemeManager.primaryColor()) : null,
                  ),
                  _buildSettingsItem(
                    title: 'Yandex',
                    onTap: () => _setSearchEngine('Yandex'),
                    isLast: true,
                    trailing: currentSearchEngine == 'Yandex' ? Icon(Icons.check, color: ThemeManager.primaryColor()) : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _setSearchEngine(String engine) {
    setState(() {
      currentSearchEngine = engine;
      if (_syncHomePageSearchEngine) {
        _homePageSearchEngine = engine;
      }
    });
    widget.onSearchEngineChange?.call(engine);
    Navigator.pop(context);
  }

  String _getSearchUrl(String query) {
    final engine = searchEngines[currentSearchEngine] ?? searchEngines['google']!;
    return engine.replaceAll('{query}', query);
  }

  void _showAppearanceSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: ThemeManager.backgroundColor(),
          appBar: AppBar(
            backgroundColor: ThemeManager.backgroundColor(),
            elevation: 0,
            systemOverlayStyle: _transparentNavBar,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
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
            padding: const EdgeInsets.only(top: 8),
            children: [
              _buildSettingsSection(
                title: 'Customize',
                children: [
                  _buildSettingsItem(
                    title: 'Themes',
                    trailing: Icon(
                      Icons.chevron_right,
              color: ThemeManager.textSecondaryColor(),
                      size: 20,
                    ),
                    onTap: () => _showThemeSelection(context),
                    isFirst: true,
                  ),
                  _buildSettingsItem(
                    title: 'App Icon',
                    trailing: Icon(
                      Icons.chevron_right,
                      color: ThemeManager.textSecondaryColor(),
                      size: 20,
                    ),
                    onTap: () {
                      // TODO: Implement app icon selection
                    },
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

  void _showThemeSelection(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => StatefulBuilder(
          builder: (context, setState) => Scaffold(
            backgroundColor: ThemeManager.backgroundColor(),
            appBar: AppBar(
              backgroundColor: ThemeManager.backgroundColor(),
              elevation: 0,
              systemOverlayStyle: _transparentNavBar,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back,
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
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: colors.surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected ? Border.all(
                        color: colors.primaryColor,
                        width: 2,
                      ) : null,
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      title: Text(
                        _getThemeName(theme),
                        style: TextStyle(
                          color: colors.textColor,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
                        
                        // Update dark mode state
                        setState(() {
                          isDarkMode = theme.isDark;
                        });
                        this.setState(() {
                          isDarkMode = theme.isDark;
                        });
                        
                        // Update system bars
                        _updateSystemBars();
                        
                        // Pop both theme selection and appearance settings screens
                        Navigator.of(context)
                          ..pop() // Pop theme selection
                          ..pop(); // Pop appearance settings
                      },
                    ),
                  );
                }).where((widget) => widget is! SizedBox).toList(),
              ],
            ),
          ),
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
    if (_textSize == 0.8) return AppLocalizations.of(context)!.text_size_small;
    if (_textSize == 1.0) return AppLocalizations.of(context)!.text_size_medium;
    if (_textSize == 1.2) return AppLocalizations.of(context)!.text_size_large;
    return AppLocalizations.of(context)!.text_size_very_large;
  }

  Future<void> _showTextSizeSelection(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: ThemeManager.backgroundColor(),
          appBar: AppBar(
            backgroundColor: ThemeManager.backgroundColor(),
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
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
                    trailing: _textSize == 0.8 ? Icon(Icons.check, color: ThemeManager.primaryColor()) : null,
                    onTap: () {
                      setState(() => _textSize = 0.8);
                      Navigator.pop(context);
                    },
                    isFirst: true,
                    isLast: false,
                  ),
                  _buildSettingsItem(
                    title: AppLocalizations.of(context)!.text_size_medium,
                    trailing: _textSize == 1.0 ? Icon(Icons.check, color: ThemeManager.primaryColor()) : null,
                    onTap: () {
                      setState(() => _textSize = 1.0);
                      Navigator.pop(context);
                    },
                    isFirst: false,
                    isLast: false,
                  ),
                  _buildSettingsItem(
                    title: AppLocalizations.of(context)!.text_size_large,
                    trailing: _textSize == 1.2 ? Icon(Icons.check, color: ThemeManager.primaryColor()) : null,
                    onTap: () {
                      setState(() => _textSize = 1.2);
                      Navigator.pop(context);
                    },
                    isFirst: false,
                    isLast: false,
                  ),
                  _buildSettingsItem(
                    title: AppLocalizations.of(context)!.text_size_very_large,
                    trailing: _textSize == 1.4 ? Icon(Icons.check, color: ThemeManager.primaryColor()) : null,
                    onTap: () {
                      setState(() => _textSize = 1.4);
                      Navigator.pop(context);
                    },
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

  void _showDownloadsSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: ThemeManager.backgroundColor(),
          appBar: AppBar(
            backgroundColor: ThemeManager.backgroundColor(),
            elevation: 0,
            systemOverlayStyle: _transparentNavBar,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
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
            padding: EdgeInsets.zero,
            children: [
              _buildSettingsSection(
                title: AppLocalizations.of(context)!.downloads,
                children: [
                  _buildSettingsItem(
                    title: AppLocalizations.of(context)!.ask_download_location,
                    trailing: Transform.scale(
                      scale: 0.7,
                      child: Switch(
                        value: _askDownloadLocation,
                        onChanged: (value) {
                          setState(() => _askDownloadLocation = value);
                        },
                      ),
                    ),
                    isFirst: true,
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
    controller.loadRequest(Uri.parse('https://github.com/solarbrowser/mobile/wiki/privacy-policy'));
    setState(() {
      isSettingsVisible = false;
    });
  }

  void _showTermsOfUse() {
    controller.loadRequest(Uri.parse('https://github.com/solarbrowser/mobile/wiki/terms-of-use'));
    setState(() {
      isSettingsVisible = false;
    });
  }

  Future<dynamic> _showAboutPage() {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
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
            padding: const EdgeInsets.only(top: 8),
            children: [
              _buildSettingsSection(
                title: AppLocalizations.of(context)!.about,
                children: [
                  _buildSettingsItem(
                    title: AppLocalizations.of(context)!.app_name,
                    subtitle: AppLocalizations.of(context)!.version('0.0.7'),
                    isFirst: true,
                    isLast: false,
                  ),
                  _buildSettingsItem(
                    title: AppLocalizations.of(context)!.flutter_version,
                    subtitle: 'Flutter 3.29.0',
                    isFirst: false,
                    isLast: false,
                  ),
                  _buildSettingsItem(
                    title: AppLocalizations.of(context)!.photoncore_version,
                    subtitle: 'Photoncore 0.0.2A',
                    isFirst: false,
                    isLast: false,
                  ),
                  _buildSettingsItem(
                    title: AppLocalizations.of(context)!.engine_version,
                    subtitle: 'MRE4.7.0, ARE4.3.2',
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
                    Icons.arrow_back,
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
                    Icons.arrow_back,
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
                    Icons.arrow_back,
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
                          Navigator.pop(context);
                          _loadUrl(item['url']);
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
              controller.loadRequest(Uri.parse(url));
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
              padding: EdgeInsets.zero,
              children: [
                _buildSettingsSection(
                  title: AppLocalizations.of(context)!.customize_browser,
                  children: [
                    _buildSettingsButton('general', () => _showGeneralSettings()),
                    _buildSettingsButton('appearance', () => _showAppearanceSettings()),
                    _buildSettingsButton('downloads', () => _showDownloadsSettings()),
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ThemeManager.errorColor().withOpacity(0.1),
                      foregroundColor: ThemeManager.errorColor(),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () => _showResetConfirmation(),
                    child: Text(
                      AppLocalizations.of(context)!.reset_browser,
                      style: TextStyle(
                        color: ThemeManager.errorColor(),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
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
    setState(() {
      bookmarks = bookmarksList.map((e) => Map<String, dynamic>.from(json.decode(e))).toList();
    });
    
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
  }

  Future<void> _addBookmark() async {
    final url = await controller.currentUrl();
    final title = await controller.getTitle() ?? 'Untitled';
    final favicon = await BrowserUtils.getFaviconUrl(url ?? '');
    
    final prefs = await SharedPreferences.getInstance();
    final bookmarksList = prefs.getStringList('bookmarks') ?? [];
    
    // Check if URL already exists in bookmarks
    bool isBookmarked = bookmarksList.any((item) => 
      Map<String, dynamic>.from(json.decode(item))['url'] == url);

    if (isBookmarked) {
      await _removeBookmark(url!);
    } else {
    final bookmark = {
      'url': url,
      'title': title,
      'favicon': favicon,
      'timestamp': DateTime.now().toIso8601String(),
    };

      bookmarksList.insert(0, json.encode(bookmark));
      await prefs.setStringList('bookmarks', bookmarksList);
      
      setState(() {
        bookmarks = bookmarksList.map((e) => Map<String, dynamic>.from(json.decode(e))).toList();
      });
      
      _showBookmarkAddedNotification();
    }
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
    
    return Container(
      width: width,
      margin: const EdgeInsets.only(bottom: 8),
      child: SlideTransition(
        position: _hideUrlBarAnimation,
        child: GestureDetector(
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(
                  width: width,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    color: ThemeManager.backgroundColor().withOpacity(0.7),
                    border: Border.all(
                      color: ThemeManager.textColor().withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Material(
                    type: MaterialType.transparency,
                    child: Row(
                      children: [
                        const SizedBox(width: 16),
                        Icon(
                          isSecure ? Icons.shield : Icons.warning_amber_rounded,
                          size: 16,
                          color: ThemeManager.textColor(),
                          semanticLabel: isSecure ? 
                            AppLocalizations.of(context)!.secure_connection : 
                            AppLocalizations.of(context)!.insecure_connection,
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
                              setState(() {
                                _urlController.text = _formatUrl(_displayUrl);
                                _urlController.selection = const TextSelection.collapsed(offset: -1);
                              });
                            },
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            _urlFocusNode.hasFocus ? Icons.close : Icons.refresh,
                            color: ThemeManager.textColor(),
                          ),
                          onPressed: () {
                            if (_urlFocusNode.hasFocus) {
                              _urlFocusNode.unfocus();
                              setState(() {
                                _urlController.clear();
                                _urlController.text = _formatUrl(_displayUrl);
                                _urlController.selection = const TextSelection.collapsed(offset: -1);
                              });
                            } else if (controller != null) {
                              controller.reload();
                            }
                          },
                        ),
                      ],
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
        body: Stack(
          children: [
            // WebView with proper padding
            Positioned(
              top: statusBarHeight,
              left: 0,
              right: 0,
              bottom: 0,
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
                child: WebViewWidget(
                  controller: controller,
                ),
              ),
            ),

            // WebView scroll detector with padding
            if (!isTabsVisible && !isSettingsVisible && !isBookmarksVisible && !isDownloadsVisible)
            Positioned(
              top: statusBarHeight,
              left: 0,
              right: 0,
              bottom: 60, // URL bar height
              child: IgnorePointer(
                ignoring: _isSlideUpPanelVisible,
                child: Listener(
                  behavior: HitTestBehavior.translucent,
                  onPointerMove: (PointerMoveEvent event) {
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

            // Bottom controls (URL bar and panels)
            Positioned(
              left: 0,
              right: 0,
              bottom: MediaQuery.of(context).padding.bottom + 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Quick actions and navigation panels
                  if (!isTabsVisible && !isSettingsVisible && !isBookmarksVisible && !isDownloadsVisible)
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
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onVerticalDragUpdate: (details) {
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

            // Overlay panels (tabs, settings, etc.)
            if (isTabsVisible || isSettingsVisible || isBookmarksVisible || isDownloadsVisible)
              _buildOverlayPanel(),
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
        });
        await _updateNavigationState();
        await _optimizationEngine.onPageFinishLoad(url);
        await _updateFavicon(url);
        await _saveToHistory(url, title);
        await _injectImageContextMenuJS(); // Inject JavaScript after page load
      },
      onWebResourceError: (WebResourceError error) {
        if (!mounted) return;
        setState(() {
          isLoading = false;
        });
        print('Web resource error: ${error.description}');
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
    
    try {
      final uri = Uri.parse(url);
      if (!showFull) {
        String domain = uri.host;
        if (domain.startsWith('www.')) {
          domain = domain.substring(4);
        }
        return domain;
      }
      return url;
    } catch (e) {
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

  void _showImageOptions(String imageUrl) {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect positionRect = RelativeRect.fromRect(
      Rect.fromPoints(
        Offset.zero,
        Offset(40, 40), // Give some space for the menu
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
                AppLocalizations.of(context)!.downloads,
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
                AppLocalizations.of(context)!.downloads,
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