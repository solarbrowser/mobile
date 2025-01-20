import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
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
  final Function(String) onLocaleChange;
  
  const BrowserScreen({
    super.key,
    required this.onLocaleChange,
  });

  @override
  _BrowserScreenState createState() => _BrowserScreenState();
}

class BrowserTab {
  final String id;
  String url;
  String title;
  String? favicon;
  late WebViewController controller;

  BrowserTab({
    required this.id,
    required this.url,
    required this.title,
    this.favicon,
  });
}

// Top level class for the loading animation
class LoadingBorderPainter extends CustomPainter {
  final double progress;
  final Color color;

  LoadingBorderPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(28),
    );

    final path = Path()
      ..addRRect(rect);

    final pathMetrics = path.computeMetrics().first;
    final length = pathMetrics.length;
    
    // Draw snake-like segment
    final snakeLength = length * 0.3; // Snake takes up 30% of the border
    final start = (progress * length * 2) % length;
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

class _BrowserScreenState extends State<BrowserScreen> with TickerProviderStateMixin {
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
  
  // Download State
  bool isDownloading = false;
  String currentDownloadUrl = '';
  double downloadProgress = 0.0;
  
  // Controllers
  late TextEditingController _urlController;
  late FocusNode _urlFocusNode;
  
  // UI State
  bool isDarkMode = false;
  double textScale = 1.0;
  bool showImages = true;
  String currentSearchEngine = 'google';
  bool isSearchMode = false;
  String _displayUrl = '';
  bool _isUrlBarExpanded = false;
  bool isSecurityPanelVisible = false;
  String securityMessage = '';
  String currentLanguage = 'en';
  double lastScrollPosition = 0;
  bool isScrollingUp = false;
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
  
  // URL Bar State
  bool _isUrlBarCollapsed = false;
  bool _isDragging = false;
  Offset _urlBarPosition = Offset.zero;
  Timer? _autoCollapseTimer;
  double dragStartX = 0;
  Timer? _loadingTimer;
  
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
  List<Map<String, dynamic>> downloads = [];
  
  // Memory Management
  final _debouncer = Debouncer(milliseconds: 300);
  bool _isLowMemory = false;
  int _lastMemoryCheck = 0;
  static const int MEMORY_CHECK_INTERVAL = 30000;

  bool isInitialized = false;

  ThemeColors get _colors => isDarkMode ? _darkModeColors : _lightModeColors;
  
  final _darkModeColors = const ThemeColors(
    background: Colors.black,
    surface: Colors.white10,
    text: Colors.white,
    textSecondary: Colors.white70,
    border: Colors.white24,
  );

  final _lightModeColors = const ThemeColors(
    background: Colors.white,
    surface: Colors.black12,
    text: Colors.black,
    textSecondary: Colors.black54,
    border: Colors.black12,
  );

  late OptimizationEngine _optimizationEngine;

  // Search Engines
  final Map<String, String> searchEngines = {
    'google': 'https://www.google.com/search?q=',
    'bing': 'https://www.bing.com/search?q=',
    'duckduckgo': 'https://duckduckgo.com/?q=',
    'yahoo': 'https://search.yahoo.com/search?p=',
  };

  // Add new state variables
  bool _isUrlBarIconState = false;
  Timer? _urlBarIdleTimer;
  Offset _urlBarOffset = Offset.zero;
  bool _isDraggingUrlBar = false;

  // Add new state variable for fullscreen
  bool _isFullscreen = false;

  void _updateState(VoidCallback update) {
    _debouncer.run(() {
      if (mounted) {
        setState(update);
      }
    });
  }

  BoxDecoration _getGlassmorphicDecoration() {
    return BoxDecoration(
        color: isDarkMode 
        ? Colors.black.withOpacity(0.3) 
          : Colors.white.withOpacity(0.3),
      borderRadius: BorderRadius.circular(28),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
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
    _loadPreferences();
    _homeUrl = 'file:///android_asset/main.html';
    _addNewTab();
    
    _urlFocusNode.addListener(() {
      if (!_urlFocusNode.hasFocus) {
        setState(() {
          _urlController.text = _formatUrl(_displayUrl);
        });
        _startUrlBarIdleTimer();
      }
    });

    // Start initial timer
    _startUrlBarIdleTimer();

    // Initialize system UI
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
      systemNavigationBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
    ));
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  Future<void> _initializeControllers() async {
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

    _urlController = TextEditingController();
    _urlFocusNode = FocusNode();
    _urlFocusNode.addListener(() {
      if (mounted) {
        setState(() {
          _isUrlBarExpanded = _urlFocusNode.hasFocus;
        });
      }
    });

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    );

    await _initializeWebView();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = prefs.getBool('darkMode') ?? false;
      _searchEngine = prefs.getString('searchEngine') ?? 'google';
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', isDarkMode);
    await prefs.setString('homeUrl', _homeUrl);
    await prefs.setString('searchEngine', _searchEngine);
  }

  @override
  void dispose() {
    _autoCollapseTimer?.cancel();
    _loadingTimer?.cancel();
    _slideAnimationController.dispose();
    _urlFocusNode.dispose();
    _urlController.dispose();
    _optimizationEngine.dispose();
    super.dispose();
  }

  Future<void> _initializeOptimizationEngine() async {
    _optimizationEngine = OptimizationEngine(controller);
    await _optimizationEngine.initialize();
  }

  Future<void> _loadDownloads() async {
    final prefs = await SharedPreferences.getInstance();
    final downloadsList = prefs.getStringList('downloads') ?? [];
    setState(() {
      downloads = downloadsList.map((e) => Map<String, dynamic>.from(json.decode(e))).toList();
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
      let ticking = false;
      
      function updateScroll() {
        if (window.flutter_inappwebview) {
          window.flutter_inappwebview.postMessage(JSON.stringify({
            scrollY: window.scrollY,
            isScrollingUp: window.scrollY < lastScrollY
          }));
        }
        lastScrollY = window.scrollY;
        ticking = false;
      }

      window.addEventListener('scroll', function() {
        if (!ticking) {
          window.requestAnimationFrame(function() {
            updateScroll();
            ticking = false;
          });
          ticking = true;
        }
      }, { passive: true });
    ''');

    await controller.addJavaScriptChannel(
      'onScroll',
      onMessageReceived: (JavaScriptMessage message) {
        if (!_urlFocusNode.hasFocus) {
          setState(() {
            _isUrlBarIconState = true;
          });
        }
      },
    );
  }

  Future<WebViewController> _initializeWebViewController() async {
    final webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..enableZoom(true)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) async {
            if (!mounted) return;
                setState(() {
              isLoading = true;
              _displayUrl = url;
            });
            await _optimizationEngine.onPageStartLoad(url);
          },
          onPageFinished: (String url) async {
            if (!mounted) return;
            setState(() {
              isLoading = false;
              if (tabs.isNotEmpty && currentTabIndex >= 0 && currentTabIndex < tabs.length) {
                tabs[currentTabIndex].title = _displayUrl;
                tabs[currentTabIndex].url = url;
              }
            });
            await _optimizationEngine.onPageFinishLoad(url);
          },
          onWebResourceError: (WebResourceError error) {
            if (!mounted) return;
            setState(() {
              isLoading = false;
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            return NavigationDecision.navigate;
          },
        ),
      );

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
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..enableZoom(false)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (String url) async {
          if (!mounted) return;
          setState(() {
            isLoading = true;
            _displayUrl = url;
          });
          
          try {
            final uri = Uri.parse(url);
            setState(() {
              isSecure = uri.scheme == 'https';
            });
          } catch (e) {
            setState(() {
              isSecure = false;
            });
          }
          
          await _updateNavigationState();
          await _optimizationEngine.onPageStartLoad(url);
        },
        onPageFinished: (String url) async {
          if (!mounted) return;
          setState(() {
            isLoading = false;
            if (tabs.isNotEmpty && currentTabIndex >= 0 && currentTabIndex < tabs.length) {
              tabs[currentTabIndex].title = _displayUrl;
              tabs[currentTabIndex].url = url;
            }
          });
          await _updateNavigationState();
          await _optimizationEngine.onPageFinishLoad(url);

          // Add fullscreen change listener
          await controller.runJavaScript('''
            function updateFullscreen() {
              const isFullscreen = document.fullscreenElement !== null || 
                                 document.webkitFullscreenElement !== null ||
                                 document.mozFullScreenElement !== null ||
                                 document.msFullscreenElement !== null;
              window.flutter_inappwebview?.callHandler('onFullscreenChange', isFullscreen);
            }
            
            document.addEventListener('fullscreenchange', updateFullscreen);
            document.addEventListener('webkitfullscreenchange', updateFullscreen);
            document.addEventListener('mozfullscreenchange', updateFullscreen);
            document.addEventListener('MSFullscreenChange', updateFullscreen);
          ''');
        },
      ));

    // Add JavaScript handler for fullscreen
    await controller.addJavaScriptChannel(
      'onFullscreenChange',
      onMessageReceived: (JavaScriptMessage message) {
        final isFullscreen = message.message == 'true';
        _handleFullscreenChange(isFullscreen);
      },
    );

    // Load main.html from assets
    final mainHtmlString = await rootBundle.loadString('assets/main.html');
    await controller.loadHtmlString(mainHtmlString, baseUrl: 'file:///android_asset/');
    
    // Initialize optimization engine
    _optimizationEngine = OptimizationEngine(controller);
    await _optimizationEngine.initialize();
  }

  Future<void> _updateNavigationState() async {
    if (!mounted) return;
    
    final canGoBackValue = await controller.canGoBack();
    final canGoForwardValue = await controller.canGoForward();
    
    setState(() {
      canGoBack = canGoBackValue;
      canGoForward = canGoForwardValue;
    });
  }

  void _setupWebViewCallbacks() {
    controller.setNavigationDelegate(
      NavigationDelegate(
        onPageStarted: (String url) async {
          if (!mounted) return;
          setState(() {
            isLoading = true;
            _displayUrl = url;
          });
          await _optimizationEngine.onPageStartLoad(url);
        },
        onPageFinished: (String url) async {
          if (!mounted) return;
          setState(() {
            isLoading = false;
            if (tabs.isNotEmpty && currentTabIndex >= 0 && currentTabIndex < tabs.length) {
              tabs[currentTabIndex].title = _displayUrl;
            tabs[currentTabIndex].url = url;
            }
          });
          await _optimizationEngine.onPageFinishLoad(url);
        },
        onWebResourceError: (WebResourceError error) {
          if (!mounted) return;
          setState(() {
            isLoading = false;
          });
        },
        onNavigationRequest: (NavigationRequest request) {
          return NavigationDecision.navigate;
        },
      ),
    );

    controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    controller.enableZoom(true);
  }

  Future<void> _saveToHistory(String url, String title) async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList('history') ?? [];
    final entry = json.encode({
      'url': url,
      'title': title,
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    history.insert(0, entry);
    if (history.length > 100) { // Keep last 100 entries
      history.removeLast();
    }
    await prefs.setStringList('history', history);
    
    setState(() {
      downloads = history.map((e) => Map<String, dynamic>.from(json.decode(e))).toList();
    });
  }

  Future<void> _loadUrl(String url) async {
    String formattedUrl = url.trim();
    if (!formattedUrl.startsWith('http://') && !formattedUrl.startsWith('https://')) {
      if (formattedUrl.contains('.') && !formattedUrl.contains(' ')) {
        formattedUrl = 'https://$formattedUrl';
      } else {
        formattedUrl = '${searchEngines[currentSearchEngine]}${Uri.encodeComponent(formattedUrl)}';
      }
    }
    
    setState(() {
      isLoading = true;
      _displayUrl = formattedUrl;
      _urlController.text = _formatUrl(formattedUrl);
    });
    
    await controller.loadRequest(Uri.parse(formattedUrl));
  }

  Future<void> _performSearch({bool searchUp = false}) async {
    final query = _urlController.text;
    if (query.isEmpty) return;

    try {
      final js = '''
        (function() {
          const searchText = '${query.replaceAll("'", "\\'")}';
          const found = window.find(searchText, false, ${searchUp}, true, false, true, false);
          if (!found) {
            window.find(searchText, false, ${searchUp}, true, false, false, false);
          }
          
          let count = 0;
          const element = document.body;
          while (window.find(searchText, false, false, true, false, true, true)) {
            count++;
          }
          window.getSelection().removeAllRanges();
          return count;
        })()
      ''';

      final countResult = await controller.runJavaScriptReturningResult(js);
      
      setState(() {
        totalSearchMatches = int.tryParse(countResult.toString()) ?? 0;
        if (searchUp && currentSearchMatch > 1) {
          currentSearchMatch--;
        } else if (!searchUp && currentSearchMatch < totalSearchMatches) {
          currentSearchMatch++;
        }
      });
    } catch (e) {
      print('Search error: $e');
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

  void _showGeneralSettings() {
    _showDynamicBottomSheet(
      items: [
        _buildSettingsItem(
          title: AppLocalizations.of(context)!.search_engine,
          subtitle: currentSearchEngine.toUpperCase(),
          onTap: () => _showSearchEngineSelection(context),
        ),
        _buildSettingsItem(
          title: AppLocalizations.of(context)!.language,
          subtitle: Localizations.localeOf(context).languageCode.toUpperCase(),
          onTap: () => _showLanguageSelection(context),
        ),
        _buildSettingsItem(
          title: 'Allow HTTP',
          subtitle: 'Load unsecure websites',
          trailing: Switch(
            value: allowHttp,
            onChanged: (value) async {
              setState(() {
                allowHttp = value;
              });
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('allowHttp', value);
            },
          ),
        ),
      ],
      title: AppLocalizations.of(context)!.general,
    );
  }

  Widget _buildSettingsItem({
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    TextStyle? customTextStyle,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Text(
          title,
          style: customTextStyle ?? TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontSize: 16,
          ),
        ),
        subtitle: subtitle != null ? Text(
          subtitle,
          style: TextStyle(
            color: isDarkMode ? Colors.white70 : Colors.black54,
          ),
        ) : null,
        trailing: trailing ?? (onTap != null ? Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: isDarkMode ? Colors.white54 : Colors.black45,
        ) : null),
        onTap: onTap,
      ),
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
      transitionAnimationController: AnimationController(
        duration: const Duration(milliseconds: 200),
        vsync: this,
      ),
      builder: (context) => Container(
        height: height,
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.black : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPanelHeader(title, onBack: () => Navigator.pop(context)),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: items.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(top: 8.0, right: 8.0),
                  child: items[index],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSearchEngineSelection(BuildContext context) {
    final items = searchEngines.keys.map((engine) => Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: _buildSettingsItem(
        title: engine.toUpperCase(),
        trailing: currentSearchEngine == engine
            ? Icon(
                Icons.check,
                color: isDarkMode ? Colors.white : Colors.black,
              )
            : null,
        onTap: () async {
          setState(() {
            currentSearchEngine = engine;
          });
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('searchEngine', engine);
          Navigator.pop(context);
        },
      ),
    )).toList();

    _showDynamicBottomSheet(
      items: items,
      title: AppLocalizations.of(context)!.search_engine,
    );
  }

  void _showLanguageSelection(BuildContext context) {
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
      'ar': 'العربية',
      'hi': 'हिन्दी',
    };

    final items = languages.entries.map((entry) => Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: _buildSettingsItem(
        title: entry.value,
        trailing: currentLanguage == entry.key
          ? Icon(
              Icons.check,
              color: isDarkMode ? Colors.white : Colors.black,
            )
          : null,
        onTap: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('language', entry.key);
          
          if (mounted) {
            // Update state and close dialog
            setState(() {
              currentLanguage = entry.key;
            });
            
            // Update locale
            widget.onLocaleChange(entry.key);
            
            // Close settings
            Navigator.pop(context);

            // Show restart dialog
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                backgroundColor: isDarkMode ? Colors.black : Colors.white,
                title: Text(
                  'Restart Required',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                content: Text(
                  'Please restart the app to apply language changes.',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.black87,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      SystemNavigator.pop();  // Close the app
                    },
                    child: Text(
                      'Restart Now',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
        },
      ),
    )).toList();

    _showDynamicBottomSheet(
      items: items,
      title: AppLocalizations.of(context)!.language,
    );
  }

  void _showDownloadsSettings() {
    _showDynamicBottomSheet(
      items: [
        _buildSettingsItem(
          title: AppLocalizations.of(context)!.download_location,
          subtitle: '/Downloads',
          onTap: () {},
        ),
        _buildSettingsItem(
          title: AppLocalizations.of(context)!.ask_download_location,
          trailing: Switch(
            value: true,
            onChanged: (value) {},
          ),
        ),
      ],
      title: AppLocalizations.of(context)!.downloads,
    );
  }

  void _showAppearanceSettings() {
    _showDynamicBottomSheet(
      items: [
        _buildSettingsItem(
          title: AppLocalizations.of(context)!.dark_mode,
          trailing: Switch(
            value: isDarkMode,
            onChanged: (value) async {
              setState(() {
                isDarkMode = value;
              });
              await _savePreferences();
              // Force rebuild of all widgets that depend on theme
              if (mounted) {
                setState(() {});
                // Rebuild the settings panel to update its appearance
                Navigator.pop(context);
                _showAppearanceSettings();
              }
            },
          ),
        ),
        _buildSettingsItem(
          title: AppLocalizations.of(context)!.text_size,
          subtitle: 'Medium',
          onTap: () {},
        ),
        _buildSettingsItem(
          title: AppLocalizations.of(context)!.show_images,
          trailing: Switch(
            value: showImages,
            onChanged: (value) async {
              setState(() {
                showImages = value;
              });
              await _savePreferences();
              if (mounted) {
                setState(() {});
              }
            },
          ),
        ),
      ],
      title: AppLocalizations.of(context)!.appearance,
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
      controller.loadRequest(Uri.parse('market://details?id=com.solarbrowser.mobile'));
    } else if (Platform.isIOS) {
      controller.loadRequest(Uri.parse('itms-apps://itunes.apple.com/app/idYOUR_APP_ID'));
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

  void _showAboutPage() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.4,
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.black : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPanelHeader('about', onBack: () => Navigator.pop(context)),
            Expanded(
              child: ListView(
                children: [
                  ListTile(
                    title: Text(
                      'Solar Browser Mobile',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Version 0.0.4',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Developed by Ata TÜRKÇÜ',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white70 : Colors.black54,
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

  Widget _buildPanelHeader(String title, {VoidCallback? onBack}) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    
    String getLocalizedTitle() {
      switch (title) {
        case 'general': return AppLocalizations.of(context)!.general;
        case 'downloads': return AppLocalizations.of(context)!.downloads;
        case 'appearance': return AppLocalizations.of(context)!.appearance;
        case 'help': return AppLocalizations.of(context)!.help;
        case 'about': return AppLocalizations.of(context)!.about;
        default: return title;
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: statusBarHeight),
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
              ),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
                onPressed: onBack,
              ),
              Text(
                getLocalizedTitle(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationPanel() {
    return Container(
      height: 50,
      margin: const EdgeInsets.only(bottom: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            decoration: _getGlassmorphicDecoration(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Image.asset(
                    _getAssetPath('assets/back24.png'),
                    width: 24,
                    height: 24,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                  onPressed: canGoBack ? () => controller.goBack() : null,
                ),
                IconButton(
                  icon: Image.asset(
                    _getAssetPath('assets/search24.png'),
                    width: 24,
                    height: 24,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                  onPressed: () {
                    setState(() {
                      isSearchMode = true;
                      isPanelExpanded = false;
                    });
                  },
                ),
                IconButton(
                  icon: Image.asset(
                    _getAssetPath('assets/bookmark24.png'),
                    width: 24,
                    height: 24,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                  onPressed: _addBookmark,
                ),
                IconButton(
                  icon: Image.asset(
                    _getAssetPath('assets/share24.png'),
                    width: 24,
                    height: 24,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                  onPressed: _shareUrl,
                ),
                IconButton(
                  icon: Image.asset(
                    _getAssetPath('assets/forward24.png'),
                    width: 24,
                    height: 24,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                  onPressed: canGoForward ? () => controller.goForward() : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionsPanel() {
    return Container(
          height: 100,
          margin: const EdgeInsets.only(bottom: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                decoration: _getGlassmorphicDecoration(),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                _buildQuickActionButton(
                  AppLocalizations.of(context)!.settings,
                  isDarkMode ? 'assets/settings24w.png' : 'assets/settings24.png',
                  onPressed: () {
                      setState(() {
                        isSettingsVisible = true;
                        isPanelExpanded = false;
                      });
                  },
                ),
                _buildQuickActionButton(
                  AppLocalizations.of(context)!.downloads,
                  isDarkMode ? 'assets/downloads24w.png' : 'assets/downloads24.png',
                  onPressed: () {
                      setState(() {
                        isDownloadsVisible = true;
                        isPanelExpanded = false;
                      });
                  },
                ),
                _buildQuickActionButton(
                  AppLocalizations.of(context)!.tabs,
                  isDarkMode ? 'assets/tab24w.png' : 'assets/tab24.png',
                  onPressed: () {
                      setState(() {
                        isTabsVisible = true;
                        isPanelExpanded = false;
                      });
                  },
                ),
                _buildQuickActionButton(
                  AppLocalizations.of(context)!.bookmarks,
                  isDarkMode ? 'assets/bookmark24w.png' : 'assets/bookmark24.png',
                  onPressed: () {
                    setState(() {
                      isBookmarksVisible = true;
                      isPanelExpanded = false;
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

  Widget _buildQuickActionButton(String label, String iconPath, {VoidCallback? onPressed}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Image.asset(
              iconPath,
              width: 24,
              height: 24,
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchPanel() {
    return Container(
      height: 50,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            decoration: _getGlassmorphicDecoration(),
            child: Row(
              children: [
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _urlController,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.search_in_page,
                      hintStyle: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                      border: InputBorder.none,
                    ),
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
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
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                IconButton(
                  icon: Image.asset(
                    _getAssetPath('assets/up24.png'),
                    width: 24,
                    height: 24,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                  onPressed: () => _performSearch(searchUp: true),
                ),
                IconButton(
                  icon: Image.asset(
                    _getAssetPath('assets/down24.png'),
                    width: 24,
                    height: 24,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                  onPressed: () => _performSearch(),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
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
    if (index != currentTabIndex) {
      // Resume the target tab
      final targetTabId = tabs[index].controller.hashCode.toString();
      _optimizationEngine.resumeTab(targetTabId);
      
      setState(() {
        currentTabIndex = index;
      });
    }
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
              color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Dark Mode',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  value: isDarkMode,
                  onChanged: (value) async {
                    setState(() {
                      isDarkMode = value;
                    });
                    await _savePreferences();
                  },
                ),
                Slider(
                  value: textScale,
                  min: 0.8,
                  max: 1.4,
                  divisions: 6,
                  label: '${(textScale * 100).round()}%',
                  onChanged: (value) async {
                    setState(() {
                      textScale = value;
                    });
                    await _savePreferences();
                  },
                ),
                Text(
                  'Text Size: ${(textScale * 100).round()}%',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Show Images',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
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
      color: isDarkMode ? Colors.black : Colors.white,
      child: Column(
        children: [
          Container(
            height: 56 + MediaQuery.of(context).padding.top,
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.black : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
                ),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                  onPressed: () {
                    setState(() {
                      isDownloadsVisible = false;
                    });
                  },
                ),
                Text(
                  AppLocalizations.of(context)!.downloads,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: downloads.isEmpty
              ? Center(
                    child: Text(
                      'No downloads yet',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: downloads.length,
                  itemBuilder: (context, index) {
                    final download = downloads[index];
                    final fileName = download['fileName'];
                    final timestamp = DateTime.parse(download['timestamp']);
                    final size = download['size'] ?? 0;
                    final formattedSize = _formatFileSize(size);
                    
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Icon(
                          Icons.file_download_done,
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                        title: Text(
                          fileName,
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                          DateFormat.yMMMd().add_jm().format(timestamp),
                          style: TextStyle(
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                            Text(
                              formattedSize,
                              style: TextStyle(
                                color: isDarkMode ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                          icon: Icon(
                            Icons.file_open,
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                          onPressed: () async {
                            final directory = await getApplicationDocumentsDirectory();
                            final filePath = '${directory.path}/$fileName';
                            await OpenFile.open(filePath);
                          },
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete,
                                color: isDarkMode ? Colors.white70 : Colors.black54,
                              ),
                              onPressed: () async {
                                final prefs = await SharedPreferences.getInstance();
                                final downloadsList = prefs.getStringList('downloads') ?? [];
                                downloadsList.removeAt(index);
                                await prefs.setStringList('downloads', downloadsList);
                                
                                final directory = await getApplicationDocumentsDirectory();
                                final filePath = '${directory.path}/$fileName';
                                final file = File(filePath);
                                if (await file.exists()) {
                                  await file.delete();
                                }
                                
                                setState(() {
                                  downloads.removeAt(index);
                                });
                              },
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

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(2)} ${suffixes[i]}';
  }

  Widget _buildBookmarksPanel() {
    return Container(
      color: isDarkMode ? Colors.black : Colors.white,
      child: Column(
        children: [
          Container(
            height: 56 + MediaQuery.of(context).padding.top,
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.black : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
                ),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: isDarkMode ? Colors.white : Colors.black,
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
                    color: isDarkMode ? Colors.white : Colors.black,
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
                      color: isDarkMode ? Colors.white70 : Colors.black54,
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
                        color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
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
                                color: isDarkMode ? Colors.white70 : Colors.black54,
                              ),
                            )
                          : Icon(
                              Icons.web,
                              color: isDarkMode ? Colors.white70 : Colors.black54,
                            ),
                        title: Text(
                          bookmark['title'],
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        subtitle: Text(
                          _getDisplayUrl(bookmark['url']),
                          style: TextStyle(
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            Icons.delete,
                            color: isDarkMode ? Colors.white70 : Colors.black54,
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
    
    if (!isPanelVisible) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: GestureDetector(
        onVerticalDragUpdate: (details) {
          if (details.primaryDelta! > 10) {
            setState(() {
              isTabsVisible = false;
              isSettingsVisible = false;
              isBookmarksVisible = false;
              isDownloadsVisible = false;
            });
          }
        },
        child: Container(
          color: Colors.transparent,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: isDarkMode 
                ? Colors.black.withOpacity(0.3) 
                : Colors.white.withOpacity(0.3),
              child: SafeArea(
                child: Container(
                  margin: EdgeInsets.only(top: 0),
                  child: AnimatedSlide(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOutCubic,
                    offset: isPanelVisible ? Offset.zero : const Offset(0, 1),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOutCubic,
                      opacity: isPanelVisible ? 1.0 : 0.0,
                      child: Container(
                        height: MediaQuery.of(context).size.height,
                        color: isDarkMode ? Colors.black : Colors.white,
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
      ),
    );
  }

  Widget _buildTabsPanel() {
    return Container(
      height: MediaQuery.of(context).size.height,
      color: isDarkMode ? Colors.black : Colors.white,
      child: Column(
        children: [
          Container(
            height: 56 + MediaQuery.of(context).padding.top,
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                  onPressed: () {
                    setState(() {
                      isTabsVisible = false;
                    });
                  },
                ),
                Expanded(
                  child: Text(
                    'Tabs',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.history,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                  onPressed: () {
                    setState(() {
                      isTabsVisible = false;
                      _showHistoryPanel();
                    });
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.add,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                  onPressed: () {
                    _addNewTab();
                    setState(() {
                      isTabsVisible = false;
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: tabs.length,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemBuilder: (context, index) {
                final tab = tabs[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: index == currentTabIndex
                        ? (isDarkMode ? Colors.white24 : Colors.black12)
                        : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Tab Preview
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Container(
                            color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                if (tab.favicon != null)
                                  Image.network(
                                    tab.favicon!,
                                    width: 32,
                                    height: 32,
                                    errorBuilder: (context, error, stackTrace) => Icon(
                                      Icons.public,
                                      size: 32,
                                      color: isDarkMode ? Colors.white24 : Colors.black12,
                                    ),
                                  )
                                else
                                  Icon(
                                    Icons.public,
                                    size: 32,
                                    color: isDarkMode ? Colors.white24 : Colors.black12,
                                  ),
                                Positioned(
                                  bottom: 8,
                                  left: 8,
                                  right: 8,
                                  child: Text(
                                    _formatUrl(tab.url),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: isDarkMode ? Colors.white70 : Colors.black54,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Tab Info
                      ListTile(
                        title: Text(
                          tab.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black,
                            fontWeight: index == currentTabIndex ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          _formatUrl(tab.url),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            Icons.close,
                            size: 20,
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                          onPressed: () => _closeTab(index),
                        ),
                        onTap: () {
                          _switchTab(index);
                          setState(() {
                            isTabsVisible = false;
                          });
                        },
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

  void _showHistoryPanel() {
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
              height: 56 + MediaQuery.of(context).padding.top,
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      'History',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _buildHistoryList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsPanel() {
    return Container(
      color: isDarkMode ? Colors.black : Colors.white,
      child: Column(
        children: [
          _buildPanelHeader(AppLocalizations.of(context)!.settings, 
            onBack: () => setState(() => isSettingsVisible = false)
          ),
          Expanded(
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                _buildSettingsSection(
                  title: AppLocalizations.of(context)!.customize_browser,
                  children: [
                    RepaintBoundary(
                      child: _buildSettingsButton('general', () => _showGeneralSettings()),
                    ),
                    RepaintBoundary(
                      child: _buildSettingsButton('downloads', () => _showDownloadsSettings()),
                    ),
                    RepaintBoundary(
                      child: _buildSettingsButton('appearance', () => _showAppearanceSettings()),
                    ),
                  ],
                ),
                _buildSettingsSection(
                  title: AppLocalizations.of(context)!.learn_more,
                  children: [
                    RepaintBoundary(
                      child: _buildSettingsButton('help', () => _showHelpPage()),
                    ),
                    RepaintBoundary(
                      child: _buildSettingsButton('rate_us', () => _showRateUs()),
                    ),
                    RepaintBoundary(
                      child: _buildSettingsButton('privacy_policy', () => _showPrivacyPolicy()),
                    ),
                    RepaintBoundary(
                      child: _buildSettingsButton('terms_of_use', () => _showTermsOfUse()),
                    ),
                    RepaintBoundary(
                      child: _buildSettingsButton('about', () => _showAboutPage()),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.withOpacity(0.1),
                      foregroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () => _showResetConfirmation(),
                    child: Text(
                      'Reset Browser',
                      style: TextStyle(
                        color: Colors.red,
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

  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        title: Text(
          'Reset Browser',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        content: Text(
          'This will clear all your data including history, bookmarks, and settings. This action cannot be undone.',
          style: TextStyle(
            color: isDarkMode ? Colors.white70 : Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _resetBrowser();
            },
            child: Text(
              'Reset',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
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
    
    // Load Google homepage
    await controller.loadRequest(Uri.parse('https://www.google.com'));
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Browser has been reset')),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
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

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.vertical(
            top: isFirst ? const Radius.circular(12) : Radius.zero,
            bottom: isLast ? const Radius.circular(12) : Radius.zero,
          ),
        ),
        child: Row(
          children: [
            Text(
              getLocalizedLabel(),
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isDarkMode ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.5),
            ),
          ],
        ),
      ),
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

  Future<void> _addBookmark() async {
    final url = await controller.currentUrl();
    final title = await controller.getTitle() ?? 'Untitled';
    final favicon = await BrowserUtils.getFaviconUrl(url ?? '');
    
    final bookmark = {
      'url': url,
      'title': title,
      'favicon': favicon,
      'timestamp': DateTime.now().toIso8601String(),
    };

    final prefs = await SharedPreferences.getInstance();
    final bookmarksList = prefs.getStringList('bookmarks') ?? [];
    
    // Check if URL already exists in bookmarks
    if (!bookmarksList.any((item) => 
      Map<String, dynamic>.from(json.decode(item))['url'] == url)) {
      bookmarksList.insert(0, json.encode(bookmark));
      await prefs.setStringList('bookmarks', bookmarksList);
      
      setState(() {
        bookmarks = bookmarksList.map((e) => 
          Map<String, dynamic>.from(json.decode(e))).toList();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bookmark added')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Already bookmarked')),
      );
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

  void _addNewTab({String? url}) {
    if (tabs.length >= _maxActiveTabs) {
      _suspendTab(tabs.first);
    }

    final newTab = BrowserTab(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      url: url ?? _homeUrl,
      title: 'New Tab',
      favicon: null,
    );

    setState(() {
      tabs.add(newTab);
      currentTabIndex = tabs.length - 1;
    });

    _initializeWebView();
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
            color: isDarkMode ? Colors.white70 : Colors.black54,
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
    final screenWidth = MediaQuery.of(context).size.width;
    final urlBarWidth = _isUrlBarIconState ? 56.0 : screenWidth - 32;
    final maxDragOffset = screenWidth - urlBarWidth - 32;  // Maximum drag distance
    
    // Don't show URL bar in fullscreen mode
    if (_isFullscreen) return const SizedBox.shrink();
    
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      left: _isDraggingUrlBar 
        ? _urlBarOffset.dx.clamp(0.0, maxDragOffset)  // Changed from 16.0 to 0.0
        : (screenWidth - urlBarWidth) / 2,
      bottom: MediaQuery.of(context).padding.bottom + 8,
      child: GestureDetector(
        onPanStart: (details) {
          setState(() {
            _isDraggingUrlBar = true;
          });
        },
        onPanUpdate: (details) {
          if (_isDraggingUrlBar) {
            setState(() {
              _urlBarOffset += details.delta;
              // Clamp the offset to keep the URL bar on screen
              _urlBarOffset = Offset(
                _urlBarOffset.dx.clamp(0.0, maxDragOffset),
                _urlBarOffset.dy
              );
            });
          }
        },
        onPanEnd: (_) {
          setState(() {
            _isDraggingUrlBar = false;
            // Animate back to center if not in icon state
            if (!_isUrlBarIconState) {
              _urlBarOffset = Offset.zero;
            }
          });
        },
        onTap: () {
          setState(() {
            _isUrlBarIconState = false;
            _urlBarOffset = Offset.zero;  // Reset position when expanding
            _urlFocusNode.requestFocus();
          });
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_isUrlBarIconState ? 24 : 28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: urlBarWidth,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(_isUrlBarIconState ? 24 : 28),
                color: isDarkMode 
                  ? Colors.black.withOpacity(0.3) 
                  : Colors.white.withOpacity(0.3),
              ),
              child: _isUrlBarIconState 
                ? _buildUrlBarIconState()
                : _buildUrlBarExpandedState(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUrlBarIconState() {
    return Center(
      child: Container(
        width: 48,
        height: 48,
        child: Icon(
          Icons.search_rounded,
          size: 24,
          color: isDarkMode ? Colors.white70 : Colors.black54,
        ),
      ),
    );
  }

  Widget _buildUrlBarExpandedState() {
    return Row(
      children: [
        const SizedBox(width: 16),
        Icon(
          isSecure ? Icons.shield : Icons.shield_outlined,
          size: 20,
          color: isDarkMode ? Colors.white70 : Colors.black54,
        ),
        Expanded(
          child: TextField(
            controller: _urlController,
            focusNode: _urlFocusNode,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'Search or enter address',
              hintStyle: TextStyle(
                color: isDarkMode ? Colors.white38 : Colors.black38,
              ),
            ),
            onTap: () {
              setState(() {
                _urlController.text = _displayUrl;
                _urlController.selection = TextSelection(
                  baseOffset: 0,
                  extentOffset: _urlController.text.length,
                );
              });
            },
            onSubmitted: (url) {
              _loadUrl(url);
              _urlFocusNode.unfocus();
              setState(() {
                _urlController.text = _formatUrl(url);
              });
              _startUrlBarIdleTimer();
            },
          ),
        ),
        IconButton(
          icon: Image.asset(
            'assets/reload24.png',
            width: 20,
            height: 20,
            color: isDarkMode ? Colors.white70 : Colors.black54,
          ),
          onPressed: () => controller.reload(),
        ),
      ],
    );
  }

  Future<WebViewController> _createWebViewController() async {
    return await _initializeWebViewController();
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).padding;
    final bottomPadding = padding.bottom;
    final bottomSafeArea = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      body: Stack(
        children: [
          // WebView - now fills the entire screen
          WebViewWidget(controller: controller),
          
          // Loading indicator
          if (isLoading)
            Positioned(
              top: padding.top,
              left: 0,
              right: 0,
              child: const LinearProgressIndicator(),
            ),

          // Overlay panel
          if (isTabsVisible || isSettingsVisible || isBookmarksVisible || isDownloadsVisible)
            Positioned.fill(
              child: GestureDetector(
                onVerticalDragUpdate: (details) {
                  if (details.primaryDelta! > 10) {
                    setState(() {
                      isTabsVisible = false;
                      isSettingsVisible = false;
                      isBookmarksVisible = false;
                      isDownloadsVisible = false;
                    });
                  }
                },
                child: Container(
                  color: Colors.transparent,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      color: isDarkMode 
                        ? Colors.black.withOpacity(0.3) 
                        : Colors.white.withOpacity(0.3),
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

          // URL bar and controls
          if (!isTabsVisible && !isSettingsVisible && !isBookmarksVisible && !isDownloadsVisible)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              left: 16,
              right: 16,
              bottom: _isUrlBarHidden ? -80 : bottomPadding + 8 + bottomSafeArea,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onVerticalDragUpdate: (details) {
                  if (details.primaryDelta! < -5 && !isPanelExpanded) {
                    setState(() {
                      isPanelExpanded = true;
                    });
                  } else if (details.primaryDelta! > 5 && isPanelExpanded) {
                    setState(() {
                      isPanelExpanded = false;
                    });
                  }
                },
                onHorizontalDragStart: (details) {
                  dragStartX = details.localPosition.dx;
                },
                onHorizontalDragUpdate: (details) {
                  final delta = details.localPosition.dx - dragStartX;
                  if (delta.abs() > 30) {
                    if ((delta < 0 && canGoBack) || (delta > 0 && canGoForward)) {
                      delta < 0 ? controller.goBack() : controller.goForward();
                      dragStartX = details.localPosition.dx;
                    }
                  }
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isPanelExpanded) ...[
                      _buildQuickActionsPanel(),
                      _buildNavigationPanel(),
                    ] else if (isSearchMode)
                      _buildSearchPanel()
                    else
                      _buildUrlBar(),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Update URL when page changes
  void _updateUrl(String url) {
    if (_urlController.text != url) {
      setState(() {
        _displayUrl = url;
        if (!_urlFocusNode.hasFocus) {
          _urlController.text = _formatUrl(url);
        }
        isSecure = url.startsWith('https://');
      });
      _startUrlBarIdleTimer();
    }
  }

  // Navigation delegate methods
  NavigationDelegate get _navigationDelegate {
    return NavigationDelegate(
      onPageStarted: (String url) {
        setState(() {
          isLoading = true;
          _updateUrl(url);
        });
      },
      onPageFinished: (String url) {
        setState(() {
          isLoading = false;
          _updateUrl(url);
        });
      },
      onUrlChange: (UrlChange change) {
        _updateUrl(change.url ?? '');
      },
    );
  }

  void _startUrlBarIdleTimer() {
    _urlBarIdleTimer?.cancel();
    _urlBarIdleTimer = Timer(const Duration(seconds: 10), () {
      if (mounted && !_urlFocusNode.hasFocus) {
        setState(() {
          _isUrlBarIconState = true;
        });
      }
    });
  }

  void _updateUrlBarState() {
    if (!_urlFocusNode.hasFocus) {
      _startUrlBarIdleTimer();
    }
  }

  String _formatUrl(String url, {bool showFull = false}) {
    if (showFull) return url;
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

  Widget _buildHistoryList() {
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (scrollInfo is ScrollEndNotification) {
          if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 500) {
            _loadMoreHistory();
          }
        }
        return true;
      },
      child: ListView.builder(
        controller: _historyScrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _loadedHistory.length + 1,
        itemBuilder: (context, index) {
          if (index == _loadedHistory.length) {
            return _isLoadingMore
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              : const SizedBox.shrink();
          }

          final item = _loadedHistory[index];
          final timestamp = DateTime.parse(item['timestamp'] as String).toLocal();
          final formattedDate = DateFormat('MMM d, y - h:mm a').format(timestamp);
          
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              title: Text(
                item['title'] as String? ?? item['url'] as String,
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              subtitle: Text(
                formattedDate,
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                  fontSize: 12,
                ),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: isDarkMode ? Colors.white54 : Colors.black45,
              ),
              onTap: () {
                controller.loadRequest(Uri.parse(item['url'] as String));
                Navigator.pop(context);
              },
            ),
          );
        },
      ),
    );
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
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
        systemNavigationBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
      ));
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