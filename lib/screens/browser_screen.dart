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
  State<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends State<BrowserScreen> with TickerProviderStateMixin {
  late WebViewController controller;
  final TextEditingController urlController = TextEditingController();
  final TextEditingController searchController = TextEditingController();
  bool isLoading = false;
  bool isUrlBarExpanded = false;
  bool isSearchMode = false;
  String displayUrl = '';
  bool canGoBack = false;
  bool canGoForward = false;
  double dragStartX = 0;
  bool isPanelVisible = true;
  bool isSecure = false;
  late AnimationController _animationController;
  late Animation<double> _animation;
  double lastScrollPosition = 0;
  bool isScrollingUp = false;
  DateTime lastScrollEvent = DateTime.now();
  bool isSecurityPanelVisible = false;
  String securityMessage = '';
  bool isPanelExpanded = false;
  int currentSearchMatch = 0;
  int totalSearchMatches = 0;
  bool isTabsVisible = false;
  bool isHistoryVisible = false;
  bool isDownloadsVisible = false;
  List<TabInfo> tabs = [];
  int currentTabIndex = 0;
  Timer? _hideTimer;
  bool _isUrlBarMinimized = false;
  bool _isUrlBarHidden = false;
  bool isSettingsVisible = false;
  bool isDarkMode = false;
  double textScale = 1.0;
  Color themeColor = Colors.blue;
  bool showImages = true;
  String currentSearchEngine = 'google';
  final Map<String, String> searchEngines = {
    'google': 'https://www.google.com/search?q=',
    'duckduckgo': 'https://duckduckgo.com/?q=',
    'bing': 'https://www.bing.com/search?q=',
    'yahoo': 'https://search.yahoo.com/search?p=',
  };
  List<Map<String, dynamic>> downloads = [];
  bool allowHttp = true;
  final int maxTabs = 10; // Maximum number of tabs allowed
  final Map<int, bool> _suspendedTabs = {};
  final _debouncer = Debouncer(milliseconds: 300);
  bool _isLowMemory = false;
  int _lastMemoryCheck = 0;
  static const int MEMORY_CHECK_INTERVAL = 30000; // 30 seconds
  late AnimationController _slideAnimationController;
  late Animation<Offset> _slideAnimation;
  final int _historyPageSize = 20;
  int _currentHistoryPage = 0;
  List<Map<String, dynamic>> _loadedHistory = [];
  bool _isLoadingMore = false;
  final ScrollController _historyScrollController = ScrollController();
  bool _isUrlBarCollapsed = false;
  Offset _urlBarPosition = Offset.zero;
  bool _isDragging = false;
  Timer? _autoCollapseTimer;

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

  void _updateState(VoidCallback update) {
    _debouncer.run(() {
      if (mounted) {
        setState(update);
      }
    });
  }

  BoxDecoration _getGlassmorphicDecoration() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDarkMode 
          ? [Colors.black87.withOpacity(0.7), Colors.black87.withOpacity(0.5)]
          : [Colors.white.withOpacity(0.7), Colors.grey.shade200.withOpacity(0.5)],
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: isDarkMode 
          ? Colors.white.withOpacity(0.1) 
          : Colors.white.withOpacity(0.3),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 15,
          spreadRadius: -8,
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeWebView().then((_) {
      _loadPreferences();
      _animationController.forward();
      _setupScrollHandling();
      _optimizeWebView();
      _initializeWebViewOptimizations();
      _setupHistoryScrollListener();
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
        try {
          if (!_isUrlBarCollapsed) {
            setState(() {
              _isUrlBarCollapsed = true;
              _urlBarPosition = const Offset(16, 0);
            });
            _autoCollapseTimer?.cancel();
          }
        } catch (e) {
          print('Scroll error: $e');
        }
      },
    );
  }

  Future<WebViewController> _createWebViewController() async {
    late final PlatformWebViewControllerCreationParams params;
    
    if (Platform.isAndroid) {
      params = const PlatformWebViewControllerCreationParams();
      final controller = WebViewController.fromPlatformCreationParams(params);
      
      if (controller.platform is AndroidWebViewController) {
        final androidController = controller.platform as AndroidWebViewController;
        await androidController.setMediaPlaybackRequiresUserGesture(true);
        await androidController.setBackgroundColor(Colors.transparent);
        await androidController.setGeolocationEnabled(false);
      }
      
      await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      await controller.addJavaScriptChannel(
        'onScroll',
        onMessageReceived: (JavaScriptMessage message) {
          try {
            final scrollY = double.parse(message.message);
            final now = DateTime.now();
            if (now.difference(lastScrollEvent) > const Duration(milliseconds: 100)) {
              final isScrollingUpNow = scrollY < lastScrollPosition;
              if (isScrollingUpNow != isScrollingUp) {
                setState(() {
                  isScrollingUp = isScrollingUpNow;
                  if (isScrollingUp) {
                    _animationController.forward();
                  } else {
                    _animationController.reverse();
                  }
                });
              }
              lastScrollPosition = scrollY;
              lastScrollEvent = now;
            }
          } catch (e) {
            print('Scroll error: $e');
          }
        },
      );
      
      return controller;
    } else if (Platform.isIOS) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
      );
      final controller = WebViewController.fromPlatformCreationParams(params);
      
      if (controller.platform is WebKitWebViewController) {
        final webKitController = controller.platform as WebKitWebViewController;
        await webKitController.setAllowsBackForwardNavigationGestures(true);
        await webKitController.setBackgroundColor(Colors.transparent);
      }
      
      await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      return controller;
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  Future<void> _initializeWebView() async {
    late final PlatformWebViewControllerCreationParams params;
    
    if (Platform.isAndroid) {
      params = const PlatformWebViewControllerCreationParams();
    } else if (Platform.isIOS) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
      );
    } else {
      throw UnsupportedError('Unsupported platform');
    }

    controller = WebViewController.fromPlatformCreationParams(params);
    
    if (Platform.isAndroid && controller.platform is AndroidWebViewController) {
      final androidController = controller.platform as AndroidWebViewController;
      await androidController.setMediaPlaybackRequiresUserGesture(true);
      await androidController.setBackgroundColor(Colors.transparent);
      await androidController.setGeolocationEnabled(false);
      
      // Enable HTTP support
      await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      await controller.enableZoom(true);
      await controller.loadRequest(Uri.parse('about:blank'));
    } else if (Platform.isIOS && controller.platform is WebKitWebViewController) {
      final webKitController = controller.platform as WebKitWebViewController;
      await webKitController.setAllowsBackForwardNavigationGestures(true);
      await webKitController.setBackgroundColor(Colors.transparent);
    }

    await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    await controller.setNavigationDelegate(
      NavigationDelegate(
        onNavigationRequest: (request) async {
          if (request.url.startsWith('http://')) {
            // Always allow HTTP
            return NavigationDecision.navigate;
          }
          return NavigationDecision.navigate;
        },
      ),
    );

    await _setupWebViewCallbacks(controller);
    await controller.loadRequest(Uri.parse('https://www.google.com'));
    
    tabs.add(TabInfo(
      title: 'New Tab',
      url: 'https://www.google.com',
      controller: controller,
    ));
  }

  Future<void> _setupWebViewCallbacks(WebViewController controller) async {
    await controller.setNavigationDelegate(
      NavigationDelegate(
        onPageStarted: (url) {
          setState(() {
            isLoading = true;
            displayUrl = _getDisplayUrl(url);
            isSecure = url.startsWith('https://');
            // Start in normal state
            _isUrlBarCollapsed = false;
            _urlBarPosition = Offset.zero;
          });
          // Start auto-collapse timer
          _startAutoCollapseTimer();
        },
        onPageFinished: (url) async {
          final title = await controller.getTitle() ?? 'New Tab';
          final faviconUrl = await BrowserUtils.getFaviconUrl(url);
          
          setState(() {
            isLoading = false;
            displayUrl = url;
            isSecure = url.startsWith('https://');
            tabs[currentTabIndex].title = title;
            tabs[currentTabIndex].url = url;
            if (faviconUrl != null) {
              tabs[currentTabIndex].favicon = faviconUrl;
            }
          });
          
          controller.canGoBack().then((value) => setState(() => canGoBack = value));
          controller.canGoForward().then((value) => setState(() => canGoForward = value));
          
          _saveToHistory(url, title);
        },
      ),
    );
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

  Future<void> _loadUrl() async {
    final input = urlController.text.trim();
    if (input.isEmpty) return;

    final url = _formatUrl(input);
    try {
      await controller.loadRequest(Uri.parse(url));
      setState(() {
        isUrlBarExpanded = false;
      });
    } catch (e) {
      print('URL loading error: $e');
    }
  }

  String _formatUrl(String input) {
    if (input.startsWith('http://') || input.startsWith('https://')) {
      return input;
    }
    
    if (input.contains('.') && !input.contains(' ')) {
      return 'https://$input';
    }
    
    final searchQuery = Uri.encodeComponent(input);
    return '${searchEngines[currentSearchEngine]}$searchQuery';
  }

  Future<void> _performSearch({bool searchUp = false}) async {
    final query = searchController.text;
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
    final items = [
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: _buildSettingsItem(
          title: 'English',
          trailing: Localizations.localeOf(context).languageCode == 'en'
              ? Icon(
                  Icons.check,
                  color: isDarkMode ? Colors.white : Colors.black,
                )
              : null,
          onTap: () async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('language', 'en');
            if (mounted) {
              widget.onLocaleChange('en');
              Navigator.pop(context);
            }
          },
        ),
      ),
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: _buildSettingsItem(
          title: 'Türkçe',
          trailing: Localizations.localeOf(context).languageCode == 'tr'
              ? Icon(
                  Icons.check,
                  color: isDarkMode ? Colors.white : Colors.black,
                )
              : null,
          onTap: () async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('language', 'tr');
            if (mounted) {
              widget.onLocaleChange('tr');
              Navigator.pop(context);
            }
          },
        ),
      ),
    ];

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
            onChanged: (value) {
              setState(() {
                isDarkMode = value;
                _savePreferences();
              });
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
            onChanged: (value) {
              setState(() {
                showImages = value;
                _savePreferences();
              });
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
                      'Solar Browser',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Version 0.0.3',
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

  @override
  void dispose() {
    _autoCollapseTimer?.cancel();
    _animationController.dispose();
    _slideAnimationController.dispose();
    _hideTimer?.cancel();
    // Clean up WebView controllers and clear suspended tabs
    for (var tab in tabs) {
      tab.controller.clearCache();
      tab.controller.clearLocalStorage();
    }
    _suspendedTabs.clear();
    urlController.dispose();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(top: statusBarHeight),
            child: RepaintBoundary(
              child: WebViewWidget(
                controller: controller,
              ),
            ),
          ),
          if (isLoading) 
            Positioned(
              top: statusBarHeight,
              left: 0,
              right: 0,
              child: RepaintBoundary(
                child: LinearProgressIndicator(),
              ),
            ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            left: _isUrlBarCollapsed ? _urlBarPosition.dx : 16,
            right: _isUrlBarCollapsed ? null : 16,
            bottom: MediaQuery.of(context).padding.bottom + 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isPanelExpanded) 
                  SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RepaintBoundary(child: _buildQuickActionsPanel()),
                        const SizedBox(height: 8),
                        RepaintBoundary(child: _buildNavigationPanel()),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                if (isSearchMode)
                  RepaintBoundary(child: _buildSearchPanel())
                else
                  GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onVerticalDragUpdate: _isUrlBarCollapsed ? null : (details) {
                      final delta = details.primaryDelta!;
                      if (delta < -2 && !isPanelExpanded || delta > 2 && isPanelExpanded) {
                        setState(() {
                          isPanelExpanded = delta < 0;
                          if (isPanelExpanded) {
                            _slideAnimationController.forward();
                          } else {
                            _slideAnimationController.reverse();
                          }
                        });
                      }
                    },
                    onHorizontalDragStart: (details) {
                      if (_isUrlBarCollapsed) {
                        setState(() => _isDragging = true);
                      }
                      dragStartX = details.localPosition.dx;
                    },
                    onHorizontalDragUpdate: (details) {
                      if (_isUrlBarCollapsed && _isDragging) {
                        setState(() {
                          _urlBarPosition = Offset(
                            _urlBarPosition.dx + details.delta.dx,
                            _urlBarPosition.dy,
                          );
                        });
                      } else if (!_isUrlBarCollapsed) {
                        final delta = details.localPosition.dx - dragStartX;
                        if (delta.abs() > 30) {
                          if ((delta < 0 && canGoBack) || (delta > 0 && canGoForward)) {
                            delta < 0 ? controller.goBack() : controller.goForward();
                            dragStartX = details.localPosition.dx;
                          }
                        }
                      }
                    },
                    onHorizontalDragEnd: (_) {
                      setState(() => _isDragging = false);
                    },
                    onTap: () {
                      if (_isUrlBarCollapsed) {
                        setState(() {
                          _isUrlBarCollapsed = false;
                          _urlBarPosition = Offset.zero;
                        });
                        _startAutoCollapseTimer();
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      height: 50,
                      width: _isUrlBarCollapsed ? 50 : null,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(_isUrlBarCollapsed ? 25 : 20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                          child: Container(
                            decoration: _getGlassmorphicDecoration(),
                            child: _isUrlBarCollapsed 
                              ? _buildCollapsedSearchButton()
                              : Row(
                                  children: [
                                    const SizedBox(width: 8),
                                    _buildSecureIcon(),
                                    Expanded(
                                      child: !isUrlBarExpanded
                                        ? _buildCollapsedUrlBar()
                                        : _buildExpandedUrlBar(),
                                    ),
                                    _buildUrlBarAction(),
                                  ],
                                ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (isTabsVisible || isHistoryVisible || isSettingsVisible)
            RepaintBoundary(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                child: _buildOverlayPanel(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCollapsedSearchButton() {
    return IconButton(
      icon: Image.asset(
        'assets/search24.png',
        width: 24,
        height: 24,
        color: _colors.textSecondary,
      ),
      onPressed: () {
        setState(() {
          _isUrlBarCollapsed = false;
          _urlBarPosition = Offset.zero;
        });
      },
    );
  }

  Widget _buildSecureIcon() {
    return Image.asset(
      isSecure ? 'assets/secure24.png' : 'assets/unsecure24.png',
      width: 24,
      height: 24,
      color: _colors.textSecondary,
    );
  }

  Widget _buildCollapsedUrlBar() {
    return GestureDetector(
      onTap: () async {
        final currentUrl = await controller.currentUrl() ?? displayUrl;
        _updateState(() {
          isUrlBarExpanded = true;
          urlController.text = currentUrl;
        });
      },
      child: Center(
        child: Text(
          _getDisplayUrl(displayUrl),
          style: TextStyle(
            color: _colors.text,
            fontSize: 16,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildExpandedUrlBar() {
    return TextField(
      controller: urlController,
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        hintText: 'Search or enter address',
        hintStyle: TextStyle(color: _colors.textSecondary),
        border: InputBorder.none,
      ),
      style: TextStyle(
        color: _colors.text,
        fontSize: 16,
      ),
      onSubmitted: (_) => _loadUrl(),
      autofocus: true,
    );
  }

  Widget _buildUrlBarAction() {
    return IconButton(
      icon: isUrlBarExpanded 
        ? Icon(Icons.close, color: _colors.textSecondary)
        : Image.asset(
            'assets/reload24.png',
            width: 24,
            height: 24,
            color: _colors.textSecondary,
          ),
      onPressed: () {
        if (isUrlBarExpanded) {
          _updateState(() {
            isUrlBarExpanded = false;
          });
        } else {
          controller.reload();
        }
      },
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
                    'assets/back24.png',
                    width: 24,
                    height: 24,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                  onPressed: canGoBack ? () => controller.goBack() : null,
                ),
                IconButton(
                  icon: Image.asset(
                    'assets/search24.png',
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
                    'assets/reload24.png',
                    width: 24,
                    height: 24,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                  onPressed: () => controller.reload(),
                ),
                IconButton(
                  icon: Image.asset(
                    'assets/share24.png',
                    width: 24,
                    height: 24,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                  onPressed: _shareUrl,
                ),
                IconButton(
                  icon: Image.asset(
                    'assets/forward24.png',
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
    return AnimatedSlide(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      offset: Offset(0, isPanelExpanded ? 0 : 1),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isPanelExpanded ? 1.0 : 0.0,
        child: Container(
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
                    _buildQuickActionButton(AppLocalizations.of(context)!.settings, 'assets/settings24.png', onPressed: () {
                      setState(() {
                        isSettingsVisible = true;
                        isPanelExpanded = false;
                      });
                    }),
                    _buildQuickActionButton(AppLocalizations.of(context)!.downloads, 'assets/downloads24.png', onPressed: () {
                      setState(() {
                        isDownloadsVisible = true;
                        isPanelExpanded = false;
                      });
                    }),
                    _buildQuickActionButton(AppLocalizations.of(context)!.tabs, 'assets/tab24.png', onPressed: () {
                      setState(() {
                        isTabsVisible = true;
                        isPanelExpanded = false;
                      });
                    }),
                    _buildQuickActionButton(AppLocalizations.of(context)!.bookmarks, 'assets/bookmark24.png', onPressed: () {
                      // Handle bookmarks
                    }),
                  ],
                ),
              ),
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
                    controller: searchController,
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
                      '$currentSearchMatch/$totalSearchMatches',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                IconButton(
                  icon: Image.asset(
                    'assets/up24.png',
                    width: 24,
                    height: 24,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                  onPressed: () => _performSearch(searchUp: true),
                ),
                IconButton(
                  icon: Image.asset(
                    'assets/down24.png',
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
                      searchController.clear();
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

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = prefs.getBool('darkMode') ?? false;
      textScale = prefs.getDouble('textScale') ?? 1.0;
      showImages = prefs.getBool('showImages') ?? true;
      currentSearchEngine = prefs.getString('searchEngine') ?? 'google';
      allowHttp = prefs.getBool('allowHttp') ?? false;
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', isDarkMode);
    await prefs.setDouble('textScale', textScale);
    await prefs.setBool('showImages', showImages);
  }

  String _getDisplayUrl(String url) {
    try {
      final uri = Uri.parse(url);
      String host = uri.host;
      if (host.startsWith('www.')) {
        return host;
      } else {
        return 'www.' + host;
      }
    } catch (e) {
      return url;
    }
  }

  void _switchTab(int index) {
    if (index >= 0 && index < tabs.length) {
      // Resume the target tab if it was suspended
      if (_suspendedTabs[index] == true) {
        _resumeTab(index);
      }
      
      setState(() {
        // Suspend tabs that are not adjacent to the current tab
        for (var i = 0; i < tabs.length; i++) {
          if (i != index && i != index - 1 && i != index + 1) {
            _suspendTab(i);
          }
        }
        
        currentTabIndex = index;
        controller = tabs[index].controller;
        displayUrl = tabs[index].url;
        isSecure = tabs[index].url.startsWith('https://');
      });
    }
  }

  Future<void> _suspendTab(int index) async {
    if (index != currentTabIndex && !_suspendedTabs[index]!) {
      final tab = tabs[index];
      final url = await tab.controller.currentUrl() ?? '';
      tab.url = url;
      
      // Clear resources before suspension
      await tab.controller.clearCache();
      await tab.controller.runJavaScript('''
        // Clear unnecessary resources
        window.performance.clearResourceTimings();
        // Remove unused event listeners
        window.onload = null;
        window.onscroll = null;
        window.onresize = null;
      ''');
      
      _suspendedTabs[index] = true;
    }
  }

  Future<void> _resumeTab(int index) async {
    if (_suspendedTabs[index] == true) {
      final tab = tabs[index];
      if (tab.url.isNotEmpty) {
        await tab.controller.loadRequest(Uri.parse(tab.url));
      }
      _suspendedTabs[index] = false;
    }
  }

  Future<void> _createNewTab() async {
    // Check if we've reached the maximum number of tabs
    if (tabs.length >= maxTabs) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Maximum number of tabs reached (${maxTabs})')),
      );
      return;
    }

    final newController = await _createWebViewController();
    await _setupWebViewCallbacks(newController);
    await newController.loadRequest(Uri.parse('https://www.google.com'));

    setState(() {
      // Suspend current tab if we have more than 3 tabs
      if (tabs.length > 2) {
        _suspendTab(currentTabIndex);
      }
      
      final newIndex = tabs.length;
      tabs.add(TabInfo(
        title: 'New Tab',
        url: 'https://www.google.com',
        controller: newController,
      ));
      _suspendedTabs[newIndex] = false;
      currentTabIndex = newIndex;
      controller = newController;
    });
  }

  void _closeTab(int index) {
    if (tabs.length > 1) {
      setState(() {
        // Clean up the tab's resources
        final tab = tabs[index];
        tab.controller.clearCache();
        tab.controller.clearLocalStorage();
        
        tabs.removeAt(index);
        _suspendedTabs.remove(index);
        
        // Adjust indices in _suspendedTabs
        final newSuspendedTabs = <int, bool>{};
        _suspendedTabs.forEach((key, value) {
          if (key > index) {
            newSuspendedTabs[key - 1] = value;
          } else if (key < index) {
            newSuspendedTabs[key] = value;
          }
        });
        _suspendedTabs.clear();
        _suspendedTabs.addAll(newSuspendedTabs);
        
        if (currentTabIndex >= tabs.length) {
          currentTabIndex = tabs.length - 1;
        }
        controller = tabs[currentTabIndex].controller;
        displayUrl = tabs[currentTabIndex].url;
        isSecure = tabs[currentTabIndex].url.startsWith('https://');
        
        // Resume the new current tab if it was suspended
        if (_suspendedTabs[currentTabIndex] == true) {
          _resumeTab(currentTabIndex);
        }
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
                  'Downloads',
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
            child: FutureBuilder<SharedPreferences>(
              future: SharedPreferences.getInstance(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                
                final downloads = snapshot.data!.getStringList('downloads') ?? [];
                if (downloads.isEmpty) {
                  return Center(
                    child: Text(
                      'No downloads yet',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  );
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: downloads.length,
                  itemBuilder: (context, index) {
                    final download = json.decode(downloads[index]);
                    final fileName = download['fileName'];
                    final url = download['url'];
                    final timestamp = DateTime.parse(download['timestamp']);
                    
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        title: Text(
                          fileName,
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        subtitle: Text(
                          DateFormat.yMMMd().add_jm().format(timestamp),
                          style: TextStyle(
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        trailing: IconButton(
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
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _optimizeWebView() async {
    // Optimize memory usage
    const duration = Duration(minutes: 10);
    Timer.periodic(duration, (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      await _checkMemoryAndOptimize();
      
      // Clear unnecessary caches
      for (var i = 0; i < tabs.length; i++) {
        if (i != currentTabIndex) {
          await tabs[i].controller.clearCache();
        }
      }
    });

    // Optimize for Android
    if (Platform.isAndroid) {
      final androidController = controller.platform as AndroidWebViewController;
      await androidController.setGeolocationEnabled(false);
      await androidController.setMediaPlaybackRequiresUserGesture(true);
      
      // Enable hardware acceleration
      await controller.runJavaScript('''
        document.body.style.setProperty('-webkit-transform', 'translate3d(0, 0, 0)');
        document.body.style.setProperty('transform', 'translate3d(0, 0, 0)');
        document.body.style.setProperty('backface-visibility', 'hidden');
      ''');
    }

    // Add performance optimizations
    await controller.runJavaScript('''
      // Optimize scroll performance
      document.addEventListener('scroll', (e) => {
        if (!document.body.style.willChange) {
          document.body.style.willChange = 'transform';
        }
        if (window._scrollTimeout) {
          clearTimeout(window._scrollTimeout);
        }
        window._scrollTimeout = setTimeout(() => {
          document.body.style.willChange = 'auto';
        }, 100);
      }, { passive: true });

      // Optimize image loading
      document.addEventListener('DOMContentLoaded', () => {
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

        document.querySelectorAll('img').forEach(img => {
          if (img.src && !img.loading) {
            img.loading = 'lazy';
            img.decoding = 'async';
            observer.observe(img);
          }
        });
      });

      // Optimize animations
      document.documentElement.style.setProperty('scroll-behavior', 'auto');
      document.documentElement.style.setProperty('touch-action', 'manipulation');
      
      // Disable unnecessary features
      if (navigator.battery) navigator.battery.addEventListener = null;
      if (navigator.deviceMemory) navigator.deviceMemory = undefined;
      if (navigator.hardwareConcurrency) navigator.hardwareConcurrency = undefined;
    ''');
  }

  Future<void> _checkMemoryAndOptimize() async {
    try {
      // Suspend inactive tabs
      for (var i = 0; i < tabs.length; i++) {
        if (i != currentTabIndex && i != currentTabIndex - 1 && i != currentTabIndex + 1) {
          await _suspendTab(i);
        }
      }

      // Clear JavaScript garbage
      await controller.runJavaScript('''
        window.performance?.clearResourceTimings();
        window.performance?.clearMarks();
        window.performance?.clearMeasures();
        
        // Clear unused event listeners
        const clearEvents = () => {
          const clone = document.cloneNode(true);
          document.replaceWith(clone);
        };
        if (document.readyState === 'complete') clearEvents();
        else window.addEventListener('load', clearEvents);
      ''');
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
      await androidController.setGeolocationEnabled(false);
      await androidController.setMediaPlaybackRequiresUserGesture(true);
      
      // Enable hardware acceleration
      await controller.runJavaScript('''
        document.documentElement.style.setProperty('-webkit-transform', 'translateZ(0)');
        document.documentElement.style.setProperty('-webkit-backface-visibility', 'hidden');
      ''');
    }
  }

  Widget _buildOverlayPanel() {
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        if (details.primaryDelta! > 10) {
          setState(() {
            isTabsVisible = false;
            isHistoryVisible = false;
            isSettingsVisible = false;
          });
        }
      },
      child: Container(
        margin: EdgeInsets.only(top: 0),
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          offset: isTabsVisible || isHistoryVisible || isSettingsVisible ? Offset.zero : const Offset(0, 1),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
            opacity: isTabsVisible || isHistoryVisible || isSettingsVisible ? 1.0 : 0.0,
            child: Container(
              color: isDarkMode ? Colors.black : Colors.white,
              child: isTabsVisible 
                ? _buildTabsPanel() 
                : isHistoryVisible 
                  ? _buildHistoryPanel() 
                  : _buildSettingsPanel(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabsPanel() {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    return Container(
      color: isDarkMode ? Colors.black : Colors.white,
      child: Column(
        children: [
          Container(
            height: 56,
            margin: EdgeInsets.only(top: statusBarHeight),
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
                      isTabsVisible = false;
                    });
                  },
                ),
                Text(
                  AppLocalizations.of(context)!.tabs,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Image.asset(
                    'assets/history24.png',
                    width: 24,
                    height: 24,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                  onPressed: () {
                    setState(() {
                      isHistoryVisible = true;
                      isTabsVisible = false;
                    });
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.add,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                  onPressed: () async {
                    await _createNewTab();
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
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: tabs.length,
              itemBuilder: (context, index) {
                final tab = tabs[index];
                final isActive = index == currentTabIndex;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive
                        ? (isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05))
                        : (isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03)),
                    borderRadius: BorderRadius.circular(12),
                    border: isActive
                        ? Border.all(
                            color: isDarkMode ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.1),
                            width: 1,
                          )
                        : null,
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    leading: tab.favicon != null
                        ? Image.network(tab.favicon!, width: 16, height: 16)
                        : Icon(Icons.web, color: isDarkMode ? Colors.white70 : Colors.black54),
                    title: Text(
                      tab.title,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                        fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      _getDisplayUrl(tab.url),
                      style: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    trailing: IconButton(
                      icon: Icon(
                        Icons.close,
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryPanel() {
    return Container(
      color: isDarkMode ? Colors.black : Colors.white,
      child: Column(
        children: [
          _buildPanelHeader(AppLocalizations.of(context)!.history, 
            onBack: () => setState(() => isHistoryVisible = false)
          ),
          Expanded(
            child: NotificationListener<ScrollNotification>(
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
                  
                  return RepaintBoundary(
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
                        ),
                      ),
                      onTap: () {
                        controller.loadRequest(Uri.parse(item['url'] as String));
                        setState(() {
                          isHistoryVisible = false;
                        });
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ],
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
              ],
            ),
          ),
        ],
      ),
    );
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
    _autoCollapseTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && !_isUrlBarCollapsed && !isUrlBarExpanded) {
        setState(() {
          _isUrlBarCollapsed = true;
          _urlBarPosition = const Offset(16, 0);
        });
      }
    });
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