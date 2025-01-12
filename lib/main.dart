import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:ui';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Platform-specific UI configurations
  if (Platform.isIOS) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.dark,
    ));
  } else {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Solar Browser',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const BrowserPage(),
    );
  }
}

class BrowserPage extends StatefulWidget {
  const BrowserPage({super.key});

  @override
  State<BrowserPage> createState() => _BrowserPageState();
}

class TabInfo {
  final WebViewController controller;
  String domain = '';
  String favicon = '';
  String title = '';
  String url = '';

  TabInfo(this.controller);
}

class _BrowserPageState extends State<BrowserPage> with SingleTickerProviderStateMixin {
  late final WebViewController controller;
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
  int selectedSettingsTab = 0;
  bool isDarkMode = false;
  String currentLanguage = 'en';
  String currentSearchEngine = 'google';
  final Map<String, String> searchEngines = {
    'google': 'https://www.google.com/search?q=',
    'duckduckgo': 'https://duckduckgo.com/?q=',
    'bing': 'https://www.bing.com/search?q=',
    'yahoo': 'https://search.yahoo.com/search?p=',
  };

  // Add state variables
  double textScale = 1.0;
  Color themeColor = Colors.blue;
  bool showImages = true;

  // Add language map
  final Map<String, Map<String, String>> translations = {
    'en': {
      'settings': 'Settings',
      'downloads': 'Downloads',
      'tabs': 'Tabs',
      'bookmarks': 'Bookmarks',
      'history': 'History',
      'search_engine': 'Search Engine',
      'language': 'Language',
      'javascript': 'JavaScript',
      'dark_mode': 'Dark Mode',
      'general': 'General',
      'appearance': 'Appearance',
      'about': 'About',
      'select_language': 'Select Language',
      'select_search_engine': 'Select Search Engine',
      'check_updates': 'Check for Updates',
      'version': 'Version',
      'developed_by': 'Developed by',
      'licensed_under': 'Licensed under',
      'support_patreon': 'Support on Patreon',
      'search_in_page': 'Search in page',
      'no_history': 'No history available',
      'text_size': 'Text Size',
      'theme_color': 'Theme Color',
      'show_images': 'Show Images',
      'downloads_title': 'Downloads',
      'no_downloads': 'No downloads yet',
      'clear_history': 'Clear History',
      'clear_history_title': 'Clear History',
      'clear_history_message': 'Are you sure you want to clear your browsing history?',
      'cancel': 'Cancel',
      'clear': 'Clear',
      'history_cleared': 'History cleared',
    },
    'tr': {
      'settings': 'Ayarlar',
      'downloads': 'İndirilenler',
      'tabs': 'Sekmeler',
      'bookmarks': 'Yer İmleri',
      'history': 'Geçmiş',
      'search_engine': 'Arama Motoru',
      'language': 'Dil',
      'javascript': 'JavaScript',
      'dark_mode': 'Karanlık Mod',
      'general': 'Genel',
      'appearance': 'Görünüm',
      'about': 'Hakkında',
      'select_language': 'Dil Seçin',
      'select_search_engine': 'Arama Motoru Seçin',
      'check_updates': 'Güncellemeleri Kontrol Et',
      'version': 'Sürüm',
      'developed_by': 'Geliştiren',
      'licensed_under': 'Lisansı',
      'support_patreon': 'Patreon\'da Destekle',
      'search_in_page': 'Sayfada ara',
      'no_history': 'Geçmiş bulunamadı',
      'text_size': 'Yazı Boyutu',
      'theme_color': 'Tema Rengi',
      'show_images': 'Resimleri Göster',
      'downloads_title': 'İndirilenler',
      'no_downloads': 'Henüz indirme yok',
      'clear_history': 'Geçmişi Temizle',
      'clear_history_title': 'Geçmişi Temizle',
      'clear_history_message': 'Geçmişinizi silmek istediğinize emin misiniz?',
      'cancel': 'İptal',
      'clear': 'Temizle',
      'history_cleared': 'Geçmiş temizlendi',
    },
  };

  String t(String key) {
    return translations[currentLanguage]?[key] ?? translations['en']![key]!;
  }

  // Add download manager state
  bool isDownloading = false;
  String currentDownloadUrl = '';
  double downloadProgress = 0.0;
  List<Map<String, dynamic>> downloads = [];

  // Add persistent storage for history
  Future<void> _saveToHistory(String url) async {
    final title = await controller.getTitle() ?? url;
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
      _browserHistory = history.map((e) => Map<String, String>.from(json.decode(e))).toList();
    });
  }

  Future<List<Map<String, String>>> _getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList('history') ?? [];
    return history.map((e) => Map<String, String>.from(json.decode(e))).toList();
  }

  // Add clear history function
  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('history');
    setState(() {
      _browserHistory = [];
    });
  }

  // Add download notification
  void _showDownloadNotification(String message, {double? progress}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            if (progress != null) ...[
              const SizedBox(height: 4),
              LinearProgressIndicator(value: progress),
            ],
          ],
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: themeColor,
      ),
    );
  }

  // Update handle download
  Future<void> _handleDownload(String url) async {
    if (await Permission.storage.request().isGranted) {
      setState(() {
        isDownloading = true;
        currentDownloadUrl = url;
        downloadProgress = 0.0;
      });

      _showDownloadNotification('Starting download: ${url.split('/').last}', progress: 0.0);

      try {
        final response = await HttpClient().getUrl(Uri.parse(url));
        final httpResponse = await response.close();
        
        final contentLength = httpResponse.contentLength;
        int received = 0;
        
        final fileName = url.split('/').last;
        Directory? directory;
        
        if (Platform.isAndroid) {
          directory = Directory('/storage/emulated/0/Download');
          if (!await directory.exists()) {
            await directory.create(recursive: true);
          }
        } else {
          directory = await getApplicationDocumentsDirectory();
        }
        
        final filePath = '${directory.path}/$fileName';
        
        final file = File(filePath);
        final sink = file.openWrite();
        
        await for (var data in httpResponse) {
          sink.add(data);
          received += data.length;
          final progress = contentLength > 0 ? (received / contentLength).toDouble() : 0.0;
          setState(() {
            downloadProgress = progress;
          });
          
          // Show progress notification every 10%
          if ((progress * 100) % 10 == 0) {
            _showDownloadNotification(
              'Downloading: ${url.split('/').last}',
              progress: progress,
            );
          }
        }
        
        await sink.close();
        
        setState(() {
          downloads.insert(0, {
            'url': url,
            'fileName': fileName,
            'path': filePath,
            'timestamp': DateTime.now().toIso8601String(),
            'progress': 100.0,
          });
        });

        _showDownloadNotification('Download complete: $fileName');
        
        // Save downloads to persistent storage
        final prefs = await SharedPreferences.getInstance();
        final savedDownloads = downloads.map((d) => json.encode(d)).toList();
        await prefs.setStringList('downloads', savedDownloads);
        
      } catch (e) {
        print('Download error: $e');
        _showDownloadNotification('Download failed: ${url.split('/').last}');
      } finally {
        setState(() {
          isDownloading = false;
        });
      }
    } else {
      _showDownloadNotification('Storage permission denied');
    }
  }

  // Load downloads from persistent storage
  Future<void> _loadDownloads() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDownloads = prefs.getStringList('downloads') ?? [];
    setState(() {
      downloads = savedDownloads
          .map((d) => Map<String, dynamic>.from(json.decode(d)))
          .toList();
    });
  }

  // Add this method at the top of the class to reuse the decoration
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
    _initializeWebView();
    _loadDownloads(); // Load saved downloads
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.value = 1.0;
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _animationController.dispose();
    searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeWebView() async {
    late final PlatformWebViewControllerCreationParams params;
    
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }
    
    controller = WebViewController.fromPlatformCreationParams(params);
    
    if (controller.platform is AndroidWebViewController) {
      final androidController = controller.platform as AndroidWebViewController;
      await androidController.setMediaPlaybackRequiresUserGesture(false);
      
      // Enable DOM storage and cookies for Android
      await controller.enableZoom(true);
      await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    } else if (controller.platform is WebKitWebViewController) {
      final webKitController = controller.platform as WebKitWebViewController;
      await webKitController.setAllowsBackForwardNavigationGestures(true);
    }
    
    await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    await controller.enableZoom(true);
    await controller.setBackgroundColor(const Color(0x00000000));
    
    // Add download handler
    await controller.setNavigationDelegate(
      NavigationDelegate(
        onPageStarted: (url) {
          setState(() {
            isLoading = true;
            _updateDisplayUrl(url);
          });
          _updateNavigationState();
          _updateTabInfo();
        },
        onPageFinished: (url) async {
          setState(() {
            isLoading = false;
            _updateDisplayUrl(url);
          });
          urlController.text = url;
          _updateNavigationState();
          _updateTabInfo();
          _saveToHistory(url);
        },
        onNavigationRequest: (request) async {
          final url = request.url;
          if (url.toLowerCase().contains('.pdf') ||
              url.toLowerCase().contains('.doc') ||
              url.toLowerCase().contains('.zip') ||
              url.toLowerCase().contains('.rar') ||
              url.toLowerCase().contains('.mp3') ||
              url.toLowerCase().contains('.mp4')) {
            _handleDownload(url);
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
        onWebResourceError: (WebResourceError error) {
          if (error.errorCode == -1 || error.description.contains('net::ERR_CACHE_MISS')) {
            _handleCacheMissError();
          }
        },
      ),
    );

    // Add JavaScript interface for downloads
    await controller.runJavaScript('''
      document.addEventListener('click', function(e) {
        var link = e.target.closest('a');
        if (link) {
          var href = link.href.toLowerCase();
          if (href.endsWith('.pdf') || href.endsWith('.doc') || href.endsWith('.zip') || 
              href.endsWith('.rar') || href.endsWith('.mp3') || href.endsWith('.mp4')) {
            e.preventDefault();
            window.flutter_inappwebview.callHandler('download', link.href);
          }
        }
      });
    ''');

    final tab = TabInfo(controller);
    tabs.add(tab);
    currentTabIndex = 0;
    
    await controller.loadRequest(Uri.parse('https://www.google.com'));
  }

  Future<void> _updateTabInfo() async {
    if (currentTabIndex >= 0 && currentTabIndex < tabs.length) {
      final tab = tabs[currentTabIndex];
      final url = await controller.currentUrl() ?? '';
      final title = await controller.getTitle() ?? '';
      
      setState(() {
        tab.url = url;
        tab.title = title;
        try {
          final uri = Uri.parse(url);
          tab.domain = uri.host;
          
          // Try multiple favicon formats
          tab.favicon = '${uri.scheme}://${uri.host}/favicon.ico';
          _checkFaviconExists(tab, uri).then((exists) {
            if (!exists && mounted) {
              setState(() {
                tab.favicon = '${uri.scheme}://${uri.host}/favicon.png';
              });
            }
          });
        } catch (e) {
          tab.domain = url;
        }
      });
    }
  }

  Future<bool> _checkFaviconExists(TabInfo tab, Uri uri) async {
    try {
      final response = await HttpClient().getUrl(Uri.parse(tab.favicon));
      final httpResponse = await response.close();
      return httpResponse.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isUrlBarMinimized = true;
        });
        _hideTimer = Timer(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _isUrlBarHidden = true;
            });
          }
        });
      }
    });
  }

  void _resetHideTimer() {
    setState(() {
      _isUrlBarMinimized = false;
      _isUrlBarHidden = false;
    });
    _startHideTimer();
  }

  Future<void> _updateNavigationState() async {
    final back = await controller.canGoBack();
    final forward = await controller.canGoForward();
    if (mounted) {
      setState(() {
        canGoBack = back;
        canGoForward = forward;
      });
    }
  }

  Future<void> _handleCacheMissError() async {
    await controller.clearCache();
    await controller.clearLocalStorage();
    await controller.loadRequest(Uri.parse(urlController.text));
  }

  void _updateDisplayUrl(String url) {
    try {
      final uri = Uri.parse(url);
      displayUrl = uri.host;
      isSecure = uri.scheme == 'https';
    } catch (e) {
      displayUrl = url;
      isSecure = false;
    }
  }

  Future<void> _loadUrl() async {
    String input = urlController.text.trim();
    String url;
    
    bool isUrl = input.startsWith('http://') || 
                 input.startsWith('https://') ||
                 input.contains('.') && !input.contains(' ');
                 
    if (isUrl) {
      if (!input.startsWith('http://') && !input.startsWith('https://')) {
        url = 'https://$input';
      } else {
        url = input;
      }
    } else {
      final searchQuery = Uri.encodeComponent(input);
      url = '${searchEngines[currentSearchEngine]}$searchQuery';
    }
    
    await controller.loadRequest(Uri.parse(url));
    setState(() {
      isUrlBarExpanded = false;
      isSearchMode = false;
    });
  }

  Future<void> _performSearch({bool searchUp = false}) async {
    final query = searchController.text;
    if (query.isNotEmpty) {
      await controller.runJavaScript('''
        var searchText = '${query.replaceAll("'", "\\'")}';
        var found = window.find(searchText, false, ${searchUp}, true, false, true, false);
        if (!found) {
          window.find(searchText, false, ${searchUp}, true, false, false, false);
        }
      ''');

      // Update match count
      final countResult = await controller.runJavaScriptReturningResult('''
        (function() {
          var count = 0;
          var searchText = '${query.replaceAll("'", "\\'")}';
          var element = document.body;
          while (window.find(searchText, false, false, true, false, true, true)) {
            count++;
          }
          window.getSelection().removeAllRanges();
          return count;
        })()
      ''');

      setState(() {
        totalSearchMatches = int.tryParse(countResult.toString()) ?? 0;
        if (searchUp && currentSearchMatch > 1) {
          currentSearchMatch--;
        } else if (!searchUp && currentSearchMatch < totalSearchMatches) {
          currentSearchMatch++;
        }
      });
    }
  }

  void _closeSearch() {
    setState(() {
      isSearchMode = false;
      currentSearchMatch = 0;
      totalSearchMatches = 0;
      searchController.clear();
    });
    controller.runJavaScript('window.getSelection().removeAllRanges();');
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

  void _showSecurityInfo() {
    setState(() {
      securityMessage = isSecure 
        ? 'You securely connected.'
        : 'You didn\'t securely connect.';
      isSecurityPanelVisible = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          isSecurityPanelVisible = false;
        });
      }
    });
  }

  void _switchToTab(int index) {
    if (index >= 0 && index < tabs.length) {
      setState(() {
        currentTabIndex = index;
        controller = tabs[index].controller;
        _updateTabInfo(); // Update tab info immediately after switching
      });
    }
  }

  // Add history storage
  List<Map<String, String>> _browserHistory = [];

  // Add helper method for icon paths
  String _getIconPath(String baseName) {
    return isDarkMode ? baseName.replaceAll('.png', 'w.png') : baseName;
  }

  Widget _buildQuickActionsPanel() {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      offset: Offset(0, isPanelExpanded ? 0 : 1),
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
                  _buildQuickActionButton(t('settings'), 'assets/settings24.png', onPressed: () {
                    setState(() {
                      isSettingsVisible = true;
                      isPanelExpanded = false;
                    });
                  }),
                  _buildQuickActionButton(t('downloads'), 'assets/downloads24.png', onPressed: () {
                    setState(() {
                      isDownloadsVisible = true;
                      isPanelExpanded = false;
                    });
                  }),
                  _buildQuickActionButton(t('tabs'), 'assets/tab24.png', onPressed: () {
                    setState(() {
                      isTabsVisible = true;
                      isPanelExpanded = false;
                    });
                  }),
                  _buildQuickActionButton(t('bookmarks'), 'assets/bookmark24.png'),
                ],
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
            icon: Image.asset(_getIconPath(iconPath), width: 20, height: 20),
            onPressed: onPressed ?? () {},
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

  Widget _buildSecurityPanel() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 1.0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: isSecurityPanelVisible ? Container(
        key: const ValueKey<String>('security_panel'),
        height: 50,
        margin: const EdgeInsets.only(bottom: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              decoration: _getGlassmorphicDecoration(),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Image.asset(
                    isSecure ? 'assets/secure24.png' : 'assets/unsecure24.png',
                    width: 24,
                    height: 24,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      securityMessage,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ) : const SizedBox.shrink(),
    );
  }

  Widget _buildSearchPanel() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                      hintText: t('search_in_page'),
                      hintStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54),
                      border: InputBorder.none,
                    ),
                    style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                    onSubmitted: (_) {
                      _performSearch();
                      // Hide keyboard
                      FocusScope.of(context).unfocus();
                    },
                  ),
                ),
                if (totalSearchMatches > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '$currentSearchMatch/$totalSearchMatches',
                      style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                    ),
                  ),
                IconButton(
                  icon: Image.asset(_getIconPath('assets/up24.png'), width: 24, height: 24),
                  onPressed: () => _performSearch(searchUp: true),
                ),
                IconButton(
                  icon: Image.asset(_getIconPath('assets/down24.png'), width: 24, height: 24),
                  onPressed: () => _performSearch(),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: isDarkMode ? Colors.white : Colors.black),
                  onPressed: () {
                    _closeSearch();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUrlPanel() {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onVerticalDragUpdate: (details) {
        if (details.primaryDelta! < -10 && !isPanelExpanded) {
          setState(() {
            isPanelExpanded = true;
          });
        } else if (details.primaryDelta! > 10 && isPanelExpanded) {
          setState(() {
            isPanelExpanded = false;
          });
        }
      },
      onHorizontalDragUpdate: (details) {
        dragStartX += details.primaryDelta!;
      },
      onHorizontalDragEnd: (details) {
        if (dragStartX.abs() > 30) {
          if (dragStartX > 0 && canGoBack) {
            controller.goBack();
          } else if (dragStartX < 0 && canGoForward) {
            controller.goForward();
          }
        }
        dragStartX = 0;
      },
      child: Container(
        height: 50,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              decoration: _getGlassmorphicDecoration(),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _showSecurityInfo,
                    child: Image.asset(
                      _getIconPath(isSecure ? 'assets/secure24.png' : 'assets/unsecure24.png'),
                      width: 24,
                      height: 24,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: !isUrlBarExpanded
                      ? GestureDetector(
                          onTap: () {
                            setState(() {
                              isUrlBarExpanded = true;
                            });
                          },
                          behavior: HitTestBehavior.opaque,
                          child: Center(
                            child: Text(
                              displayUrl,
                              style: TextStyle(
                                color: isDarkMode ? Colors.white : Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        )
                      : TextField(
                          controller: urlController,
                          decoration: InputDecoration(
                            hintText: 'Enter URL or search',
                            hintStyle: TextStyle(
                              color: isDarkMode ? Colors.white70 : Colors.black54
                            ),
                            border: InputBorder.none,
                          ),
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black
                          ),
                          onSubmitted: (_) => _loadUrl(),
                          autofocus: true,
                        ),
                  ),
                  IconButton(
                    icon: Image.asset(_getIconPath('assets/reload24.png'), width: 24, height: 24),
                    onPressed: () => controller.reload(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
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
                  icon: Image.asset(_getIconPath('assets/back24.png'), width: 24, height: 24),
                  onPressed: canGoBack ? () => controller.goBack() : null,
                ),
                IconButton(
                  icon: Image.asset(_getIconPath('assets/search24.png'), width: 24, height: 24),
                  onPressed: () {
                    setState(() {
                      isSearchMode = true;
                      isPanelExpanded = false;
                    });
                  },
                ),
                IconButton(
                  icon: Image.asset(_getIconPath('assets/reload24.png'), width: 24, height: 24),
                  onPressed: () => controller.reload(),
                ),
                IconButton(
                  icon: Image.asset(_getIconPath('assets/share24.png'), width: 24, height: 24),
                  onPressed: _shareUrl,
                ),
                IconButton(
                  icon: Image.asset(_getIconPath('assets/forward24.png'), width: 24, height: 24),
                  onPressed: canGoForward ? () => controller.goForward() : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabsPanel() {
    return SafeArea(
      child: Container(
        color: isDarkMode ? Colors.black87 : Colors.white,
        child: Column(
          children: [
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      setState(() {
                        isTabsVisible = false;
                      });
                    },
                  ),
                  const Text(
                    'Tabs',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () async {
                      final newController = WebViewController()
                        ..setJavaScriptMode(JavaScriptMode.unrestricted)
                        ..setBackgroundColor(const Color(0x00000000))
                        ..setNavigationDelegate(
                          NavigationDelegate(
                            onPageStarted: (url) {
                              setState(() {
                                isLoading = true;
                                _updateDisplayUrl(url);
                              });
                              _updateNavigationState();
                              _updateTabInfo();
                            },
                            onPageFinished: (url) {
                              setState(() {
                                isLoading = false;
                                _updateDisplayUrl(url);
                              });
                              _updateNavigationState();
                              _updateTabInfo();
                            },
                          ),
                        );
                      
                      await newController.loadRequest(Uri.parse('https://www.google.com'));
                      
                      setState(() {
                        tabs.add(TabInfo(newController));
                        currentTabIndex = tabs.length - 1;
                        controller = newController;
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
                itemBuilder: (context, index) {
                  final tab = tabs[index];
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          spreadRadius: -2,
                        ),
                      ],
                    ),
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          tab.favicon,
                          width: 24,
                          height: 24,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset('assets/tab24.png', width: 24, height: 24);
                          },
                        ),
                      ),
                      title: Text(tab.domain),
                      subtitle: Text(tab.title),
                      selected: currentTabIndex == index,
                      trailing: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            if (tabs.length > 1) {
                              tabs.removeAt(index);
                              if (currentTabIndex == index) {
                                currentTabIndex = index > 0 ? index - 1 : 0;
                                controller = tabs[currentTabIndex].controller;
                              } else if (currentTabIndex > index) {
                                currentTabIndex--;
                              }
                            }
                          });
                        },
                      ),
                      onTap: () {
                        setState(() {
                          currentTabIndex = index;
                          controller = tab.controller;
                          isTabsVisible = false;
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Image.asset('assets/history24.png', width: 24, height: 24),
                    onPressed: () {
                      setState(() {
                        isTabsVisible = false;
                        isHistoryVisible = true;
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryPanel() {
    return SafeArea(
      child: Container(
        color: isDarkMode ? Colors.black87 : Colors.white,
        child: Column(
          children: [
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.black87 : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, 
                      color: isDarkMode ? Colors.white : Colors.black),
                    onPressed: () {
                      setState(() {
                        isHistoryVisible = false;
                      });
                    },
                  ),
                  Text(
                    t('history'),
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
              child: FutureBuilder<List<Map<String, String>>>(
                future: _getHistory(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final history = snapshot.data!;
                    if (history.isEmpty) {
                      return Center(
                        child: Text(
                          t('no_history'),
                          style: TextStyle(
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      itemCount: history.length,
                      itemBuilder: (context, index) {
                        final entry = history[index];
                        return ListTile(
                          title: Text(
                            entry['title'] ?? '',
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          subtitle: Text(
                            entry['url'] ?? '',
                            style: TextStyle(
                              color: isDarkMode ? Colors.white70 : Colors.black54,
                            ),
                          ),
                          onTap: () {
                            controller.loadRequest(Uri.parse(entry['url']!));
                            setState(() {
                              isHistoryVisible = false;
                            });
                          },
                        );
                      },
                    );
                  }
                  return const Center(child: CircularProgressIndicator());
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsPanel() {
    return SafeArea(
      child: DefaultTabController(
        length: 3,
        child: Container(
          color: isDarkMode ? Colors.black87 : Colors.white,
          child: Column(
            children: [
              Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.black87 : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back,
                        color: isDarkMode ? Colors.white : Colors.black),
                      onPressed: () {
                        setState(() {
                          isSettingsVisible = false;
                        });
                      },
                    ),
                    Text(
                      t('settings'),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              TabBar(
                tabs: [
                  Tab(text: t('general')),
                  Tab(text: t('appearance')),
                  Tab(text: t('about')),
                ],
                labelColor: isDarkMode ? Colors.white : Colors.blue,
                unselectedLabelColor: isDarkMode ? Colors.white60 : Colors.grey,
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    // General Settings
                    ListView(
                      children: [
                        ListTile(
                          title: Text(t('search_engine'),
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          subtitle: Text(
                            currentSearchEngine.toUpperCase(),
                            style: TextStyle(
                              color: isDarkMode ? Colors.white70 : Colors.black54,
                            ),
                          ),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: isDarkMode ? Colors.black87 : Colors.white,
                                title: Text(
                                  t('select_search_engine'),
                                  style: TextStyle(
                                    color: isDarkMode ? Colors.white : Colors.black,
                                  ),
                                ),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: searchEngines.keys.map((engine) => ListTile(
                                    title: Text(
                                      engine.toUpperCase(),
                                      style: TextStyle(
                                        color: isDarkMode ? Colors.white : Colors.black,
                                      ),
                                    ),
                                    selected: currentSearchEngine == engine,
                                    onTap: () {
                                      setState(() {
                                        currentSearchEngine = engine;
                                      });
                                      Navigator.pop(context);
                                    },
                                  )).toList(),
                                ),
                              ),
                            );
                          },
                        ),
                        ListTile(
                          title: Text(t('language'),
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          subtitle: Text(currentLanguage.toUpperCase(),
                            style: TextStyle(
                              color: isDarkMode ? Colors.white70 : Colors.black54,
                            ),
                          ),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: isDarkMode ? Colors.black87 : Colors.white,
                                title: Text(
                                  t('select_language'),
                                  style: TextStyle(
                                    color: isDarkMode ? Colors.white : Colors.black,
                                  ),
                                ),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ListTile(
                                      title: Text(
                                        'English',
                                        style: TextStyle(
                                          color: isDarkMode ? Colors.white : Colors.black,
                                        ),
                                      ),
                                      selected: currentLanguage == 'en',
                                      onTap: () {
                                        setState(() {
                                          currentLanguage = 'en';
                                        });
                                        Navigator.pop(context);
                                      },
                                    ),
                                    ListTile(
                                      title: Text(
                                        'Türkçe',
                                        style: TextStyle(
                                          color: isDarkMode ? Colors.white : Colors.black,
                                        ),
                                      ),
                                      selected: currentLanguage == 'tr',
                                      onTap: () {
                                        setState(() {
                                          currentLanguage = 'tr';
                                        });
                                        Navigator.pop(context);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        ListTile(
                          title: Text(t('javascript'),
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          trailing: Switch(
                            value: true,
                            onChanged: (value) {
                              // Handle JavaScript toggle
                            },
                          ),
                        ),
                        ListTile(
                          title: Text(t('clear_history'),
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          leading: Icon(Icons.delete_forever,
                            color: isDarkMode ? Colors.white70 : Colors.black54),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: isDarkMode ? Colors.black87 : Colors.white,
                                title: Text(
                                  t('clear_history_title'),
                                  style: TextStyle(
                                    color: isDarkMode ? Colors.white : Colors.black,
                                  ),
                                ),
                                content: Text(
                                  t('clear_history_message'),
                                  style: TextStyle(
                                    color: isDarkMode ? Colors.white70 : Colors.black54,
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text(t('cancel')),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      _clearHistory();
                                      Navigator.pop(context);
                                      _showDownloadNotification(t('history_cleared'));
                                    },
                                    child: Text(t('clear'),
                                      style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    // Appearance
                    ListView(
                      children: [
                        ListTile(
                          title: Text(t('dark_mode'),
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          trailing: Switch(
                            value: isDarkMode,
                            onChanged: (value) {
                              setState(() {
                                isDarkMode = value;
                              });
                            },
                          ),
                        ),
                        ListTile(
                          title: Text(t('text_size'),
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          subtitle: Slider(
                            value: textScale,
                            min: 0.8,
                            max: 1.4,
                            divisions: 6,
                            label: '${(textScale * 100).round()}%',
                            onChanged: (value) {
                              setState(() {
                                textScale = value;
                                controller.runJavaScript(
                                  'document.body.style.zoom = "$value"'
                                );
                              });
                            },
                          ),
                        ),
                        ListTile(
                          title: Text(t('theme_color'),
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          subtitle: Row(
                            children: [
                              for (final color in [
                                Colors.blue,
                                Colors.red,
                                Colors.green,
                                Colors.purple,
                                Colors.orange,
                              ])
                                Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        themeColor = color;
                                      });
                                    },
                                    child: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: themeColor == color
                                            ? Colors.white
                                            : Colors.transparent,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        SwitchListTile(
                          title: Text(t('show_images'),
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          value: showImages,
                          onChanged: (value) {
                            setState(() {
                              showImages = value;
                              controller.runJavaScript('''
                                document.querySelectorAll('img').forEach(img => {
                                  img.style.display = '${value ? 'block' : 'none'}';
                                });
                              ''');
                            });
                          },
                        ),
                      ],
                    ),
                    // About
                    ListView(
                      children: [
                        ListTile(
                          title: Text('Solar Browser Mobile',
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${t('version')}: 0.0.1',
                                style: TextStyle(
                                  color: isDarkMode ? Colors.white70 : Colors.black54,
                                ),
                              ),
                              Text('Flutter Edition',
                                style: TextStyle(
                                  color: isDarkMode ? Colors.white70 : Colors.black54,
                                ),
                              ),
                              Text('${t('developed_by')}: Ata TÜRKÇÜ',
                                style: TextStyle(
                                  color: isDarkMode ? Colors.white70 : Colors.black54,
                                ),
                              ),
                              Text('${t('licensed_under')}: GPL 3.0',
                                style: TextStyle(
                                  color: isDarkMode ? Colors.white70 : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ListTile(
                          leading: Image.asset('assets/github24.png', width: 24, height: 24),
                          title: Text('GitHub',
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          onTap: () {
                            controller.loadRequest(Uri.parse('https://github.com/solarbrowser/mobile'));
                            setState(() {
                              isSettingsVisible = false;
                            });
                          },
                        ),
                        ListTile(
                          leading: SizedBox(
                            width: 24,
                            height: 24,
                            child: SvgPicture.asset(
                              'assets/patreon.svg',
                              width: 24,
                              height: 24,
                              colorFilter: ColorFilter.mode(
                                isDarkMode ? Colors.white : Colors.black,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                          title: Text(t('support_patreon'),
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          onTap: () {
                            controller.loadRequest(Uri.parse('https://patreon.com/ataturkcu'));
                            setState(() {
                              isSettingsVisible = false;
                            });
                          },
                        ),
                        ListTile(
                          title: Text(t('check_updates'),
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          onTap: () {
                            // Handle update check
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDownloadsPanel() {
    return SafeArea(
      child: Container(
        color: isDarkMode ? Colors.black87 : Colors.white,
        child: Column(
          children: [
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.black87 : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back,
                      color: isDarkMode ? Colors.white : Colors.black),
                    onPressed: () {
                      setState(() {
                        isDownloadsVisible = false;
                      });
                    },
                  ),
                  Text(
                    t('downloads_title'),
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
                      t('no_downloads'),
                      style: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: downloads.length,
                    itemBuilder: (context, index) {
                      final download = downloads[index];
                      return ListTile(
                        leading: Image.asset('assets/downloads24.png'),
                        title: Text(
                          download['fileName'] as String,
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              download['url'] as String,
                              style: TextStyle(
                                color: isDarkMode ? Colors.white70 : Colors.black54,
                              ),
                            ),
                            if (download['progress'] != null)
                              Text(
                                '${download['progress']}%',
                                style: TextStyle(
                                  color: isDarkMode ? Colors.white70 : Colors.black54,
                                ),
                              ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.folder_open,
                            color: isDarkMode ? Colors.white70 : Colors.black54),
                          onPressed: () async {
                            final path = download['path'] as String;
                            if (await File(path).exists()) {
                              if (Platform.isAndroid) {
                                await controller.runJavaScript('''
                                  window.open('file://$path', '_system');
                                ''');
                              }
                            }
                          },
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

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).padding;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom + padding.bottom;
    final bottomSafeArea = Platform.isAndroid ? 24.0 : 0.0;
    
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: themeColor,
          brightness: isDarkMode ? Brightness.dark : Brightness.light,
        ),
        scaffoldBackgroundColor: isDarkMode ? Colors.black : Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: isDarkMode ? Colors.black : Colors.white,
          foregroundColor: isDarkMode ? Colors.white : Colors.black,
        ),
        dialogTheme: DialogTheme(
          backgroundColor: isDarkMode ? Colors.black : Colors.white,
          contentTextStyle: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        ),
      ),
      home: Scaffold(
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        body: Stack(
          children: [
            Positioned(
              top: padding.top,
              left: 0,
              right: 0,
              bottom: bottomPadding + 4,
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification is ScrollUpdateNotification) {
                    if (notification.scrollDelta! < 0) {
                      _resetHideTimer();
                    } else if (notification.scrollDelta! > 0) {
                      setState(() {
                        _isUrlBarMinimized = true;
                        _isUrlBarHidden = true;
                      });
                    }
                  }
                  return false;
                },
                child: WebViewWidget(controller: controller),
              ),
            ),
            if (isLoading)
              Positioned(
                top: padding.top,
                left: 0,
                right: 0,
                child: const LinearProgressIndicator(),
              ),
            if (isDownloading)
              Positioned(
                top: padding.top + (isLoading ? 4 : 0),
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.black87 : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Downloading: ${currentDownloadUrl.split('/').last}',
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(value: downloadProgress),
                    ],
                  ),
                ),
              ),
            if (isDownloadsVisible)
              _buildDownloadsPanel()
            else if (isTabsVisible)
              _buildTabsPanel()
            else if (isHistoryVisible)
              _buildHistoryPanel()
            else if (isSettingsVisible)
              _buildSettingsPanel(),
            if (!isTabsVisible && !isHistoryVisible && !isSettingsVisible && !isDownloadsVisible)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                left: _isUrlBarMinimized ? 16 : 16,
                right: _isUrlBarMinimized ? null : 16,
                bottom: _isUrlBarHidden ? -80 : bottomPadding + 8 + bottomSafeArea,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onVerticalDragUpdate: (details) {
                    if (details.primaryDelta! < -5) {
                      setState(() {
                        isPanelExpanded = true;
                      });
                    } else if (details.primaryDelta! > 5) {
                      setState(() {
                        isPanelExpanded = false;
                      });
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    width: _isUrlBarMinimized ? 50 : null,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isPanelExpanded) ...[
                          _buildQuickActionsPanel(),
                          _buildNavigationPanel(),
                        ] else if (isSecurityPanelVisible)
                          _buildSecurityPanel()
                        else if (isSearchMode)
                          _buildSearchPanel()
                        else if (_isUrlBarMinimized)
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: isDarkMode ? Colors.black.withOpacity(0.9) : Colors.white.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  spreadRadius: -5,
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: Image.asset(_getIconPath('assets/search24.png'), width: 24, height: 24),
                              onPressed: () {
                                setState(() {
                                  _isUrlBarMinimized = false;
                                  _isUrlBarHidden = false;
                                  isUrlBarExpanded = true;
                                });
                              },
                            ),
                          )
                        else
                          _buildUrlPanel(),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
