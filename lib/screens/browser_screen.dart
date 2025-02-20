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
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../widgets/custom_dialog.dart';
import '../widgets/custom_notification.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';

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
  bool isLoading;
  bool isIncognito;
  bool isSecure;
  String? favicon;
  WebViewController? controller;

  BrowserTab({
    required this.id,
    required this.url,
    this.title = 'New Tab',
    this.isLoading = false,
    this.isIncognito = false,
    this.isSecure = false,
    this.favicon,
    this.controller,
  });
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

class _BrowserScreenState extends State<BrowserScreen> {
  late WebViewController controller;
  List<BrowserTab> tabs = [];
  int currentTabIndex = 0;
  bool isLoading = false;
  late TextEditingController _urlController;
  late FocusNode _urlFocusNode;
  String _displayUrl = '';
  bool isDarkMode = false;
  late OptimizationEngine _optimizationEngine;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
    _urlController = TextEditingController();
    _urlFocusNode = FocusNode();
    _optimizationEngine = OptimizationEngine(controller);
  }

  Future<void> _initializeWebView() async {
    controller = await _initializeWebViewController();
    if (tabs.isEmpty) {
      final newController = await _initializeWebViewController();
      final newTab = BrowserTab(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        url: 'about:blank',
        title: 'New Tab',
        controller: newController,
      );
      setState(() {
        tabs.add(newTab);
        currentTabIndex = 0;
        controller = newController;
        _displayUrl = 'about:blank';
        _urlController.text = _formatUrl('about:blank');
      });
    }
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
            });
            _updateUrl(url);
            await _optimizationEngine.onPageStartLoad(url);
          },
          onPageFinished: (String url) async {
            if (!mounted) return;
            final title = await webViewController.getTitle() ?? url;
            setState(() {
              isLoading = false;
              if (tabs.isNotEmpty && currentTabIndex >= 0 && currentTabIndex < tabs.length) {
                tabs[currentTabIndex].title = title;
                tabs[currentTabIndex].url = url;
              }
            });
            _updateUrl(url);
            await _updateNavigationState();
            await _optimizationEngine.onPageFinishLoad(url);
            await _updateFavicon(url);
          },
          onUrlChange: (UrlChange change) {
            if (change.url != null) {
              _updateUrl(change.url!);
            }
          },
          onWebResourceError: (WebResourceError error) {
            if (!mounted) return;
            setState(() {
              isLoading = false;
            });
          },
        ),
      );

    return webViewController;
  }

  void _initializeTab(BrowserTab tab) {
    if (tab.controller == null) {
      _initializeWebViewController().then((webViewController) {
        setState(() {
          tab.controller = webViewController;
        });
        tab.controller?.setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) async {
              if (!mounted) return;
              setState(() {
                isLoading = true;
              });
              _updateUrl(url);
              await _optimizationEngine.onPageStartLoad(url);
            },
            onPageFinished: (String url) async {
              if (mounted) {
                final title = await tab.controller?.getTitle() ?? url;
                setState(() {
                  isLoading = false;
                  tab.title = title;
                  tab.url = url;
                });
                if (!tab.isIncognito) {
                  await _saveToHistory(url, title);
                }
                _updateUrl(url);
                await _updateNavigationState();
                await _updateFavicon(url);
              }
            },
            onUrlChange: (UrlChange change) {
              if (mounted && change.url != null) {
                setState(() {
                  tab.url = change.url!;
                  _updateUrl(change.url!);
                });
              }
            },
          ),
        );
      });
    }
  }

  Future<void> _switchToTab(int index) async {
    if (index != currentTabIndex && index >= 0 && index < tabs.length) {
      final tab = tabs[index];
      
      if (tab.controller == null) {
        tab.controller = await _initializeWebViewController();
      }

      if (tab.controller != null) {
        setState(() {
          currentTabIndex = index;
          controller = tab.controller!;
          _displayUrl = tab.url;
          _urlController.text = _formatUrl(tab.url);
        });

        // Force reload the page to prevent black screen
        final targetUrl = await tab.controller?.currentUrl();
        if (targetUrl != tab.url) {
          await tab.controller?.loadRequest(Uri.parse(tab.url));
        }
      }
    }
  }

  Future<void> _setupScrollHandling() async {
    await controller.runJavaScript('''
      let lastScrollY = window.scrollY;
      let ticking = false;
      
      function updateScroll() {
        if (window.flutter_inappwebview) {
          window.onScroll.postMessage(JSON.stringify({
            scrollY: window.scrollY,
            isScrollingDown: window.scrollY > lastScrollY,
            scrollDelta: window.scrollY - lastScrollY
          }));
        }
        lastScrollY = window.scrollY;
        ticking = false;
      }

      window.addEventListener('scroll', function(e) {
        if (!ticking) {
          window.requestAnimationFrame(function() {
            updateScroll();
            ticking = false;
          });
          ticking = true;
        }
      }, { passive: true });
    ''');
  }

  void _updateUrl(String url) {
    if (_urlController.text != url) {
      setState(() {
        _displayUrl = url;
        if (!_urlFocusNode.hasFocus) {
          _urlController.text = _formatUrl(url);
        }
        
        // Update security status
        try {
          final uri = Uri.parse(url);
          if (tabs.isNotEmpty && currentTabIndex >= 0 && currentTabIndex < tabs.length) {
            tabs[currentTabIndex].isSecure = uri.scheme == 'https' || uri.scheme == 'file';
          }
        } catch (e) {
          if (tabs.isNotEmpty && currentTabIndex >= 0 && currentTabIndex < tabs.length) {
            tabs[currentTabIndex].isSecure = false;
          }
        }
      });
      _startUrlBarIdleTimer();
    }
  }

  Future<void> _clearBrowsingData() async {
    for (var i = 0; i < tabs.length; i++) {
      await tabs[i].controller?.clearCache();
      await tabs[i].controller?.clearLocalStorage();
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _urlFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = prefs.getBool('darkMode') ?? false;
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', isDarkMode);
  }

  Future<void> _initializeOptimizationEngine() async {
    _optimizationEngine = OptimizationEngine(controller);
    await _optimizationEngine.initialize();
  }

  Future<void> _loadDownloads() async {
    final prefs = await SharedPreferences.getInstance();
    final downloadsList = prefs.getStringList('downloads') ?? [];
    setState(() {
      downloads = downloadsList.isEmpty ? [] : downloadsList.map((e) => Map<String, dynamic>.from(json.decode(e))).toList();
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
          window.onScroll.postMessage(JSON.stringify({
            scrollY: window.scrollY,
            isScrollingDown: window.scrollY > lastScrollY,
            scrollDelta: window.scrollY - lastScrollY
          }));
        }
        lastScrollY = window.scrollY;
        ticking = false;
      }

      window.addEventListener('scroll', function(e) {
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
        if (!mounted) return;
        final scrollData = json.decode(message.message) as Map<String, dynamic>;
        final scrollY = scrollData['scrollY'] as double;
        final scrollDelta = scrollData['scrollDelta'] as double;
        
        if (scrollDelta.abs() > 10) {  // Only trigger if scroll is significant
          if (scrollDelta > 0 && !_isUrlBarHiddenByScroll) {  // Scrolling down
            _hideUrlBar();
          } else if (scrollDelta < 0 && _isUrlBarHiddenByScroll) {  // Scrolling up
            _showUrlBar();
          }
        }
      },
    );
  }

  void _hideUrlBar() {
    if (!_isUrlBarHiddenByScroll) {
      setState(() {
        _isUrlBarHiddenByScroll = true;
      });
      _urlBarAnimationController.forward();
    }
  }

  void _showUrlBar() {
    if (_isUrlBarHiddenByScroll) {
      setState(() {
        _isUrlBarHiddenByScroll = false;
      });
      _urlBarAnimationController.reverse();
    }
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
          final title = await controller.getTitle() ?? _displayUrl;
          setState(() {
            isLoading = false;
            if (tabs.isNotEmpty && currentTabIndex >= 0 && currentTabIndex < tabs.length) {
              tabs[currentTabIndex].title = title;
            tabs[currentTabIndex].url = url;
            }
            _displayUrl = url;
            _urlController.text = _formatUrl(url);
          });
          await _updateNavigationState();
          await _optimizationEngine.onPageFinishLoad(url);
          await _updateFavicon(url);
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
    // Skip saving history in incognito mode
    if (currentTab.isIncognito) return;

    if (mounted) {
      final prefs = await SharedPreferences.getInstance();
      final String entry = json.encode({
        'url': url,
        'title': title,
        'favicon': currentTab.favicon,
        'timestamp': DateTime.now().toIso8601String(),
      });

      final List<String> history = prefs.getStringList('history') ?? [];
      
      // Check if URL already exists in recent history to avoid duplicates
      history.removeWhere((item) {
        final Map<String, dynamic> decoded = json.decode(item);
        return decoded['url'] == url;
      });

      history.insert(0, entry);

      // Limit history size
      if (history.length > 100) {
        history.removeLast();
      }

      await prefs.setStringList('history', history);
      setState(() {
        _loadedHistory = history.map((e) => Map<String, dynamic>.from(json.decode(e))).toList();
      });
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
        iconColor: Colors.orange,
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
        formattedUrl = engine.replaceAll('{query}', formattedUrl);
      }
    }
    
    setState(() {
      isLoading = true;
      _displayUrl = formattedUrl;
      _urlController.text = _formatUrl(formattedUrl);
    });
    
    await controller.loadRequest(Uri.parse(formattedUrl));
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

  void _showGeneralSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: isDarkMode ? Colors.black : Colors.white,
          appBar: AppBar(
            backgroundColor: isDarkMode ? Colors.black : Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              AppLocalizations.of(context)!.general,
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.only(top: 8),
            children: [
              _buildSettingsSection(
                title: AppLocalizations.of(context)!.general,
                children: [
                  _buildSettingsItem(
                    title: AppLocalizations.of(context)!.language,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showLanguageSelection(context),
                    isFirst: true,
                    isLast: false,
                  ),
                  _buildSettingsItem(
                    title: AppLocalizations.of(context)!.search_engine,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showSearchEngineSelection(context),
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
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ),
            CheckboxListTile(
              value: clearCookies,
              onChanged: (value) => setState(() => clearCookies = value!),
              title: Text(
                AppLocalizations.of(context)!.cookies,
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ),
            CheckboxListTile(
              value: clearCache,
              onChanged: (value) => setState(() => clearCache = value!),
              title: Text(
                AppLocalizations.of(context)!.cache,
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
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
              color: isDarkMode ? Colors.white70 : Colors.black54,
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
              iconColor: Colors.green,
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
          color: isDarkMode ? Colors.white70 : Colors.black45,
          size: 18,
        );
      }
    } else if (trailing is Icon && (trailing as Icon).icon == Icons.chevron_right) {
      // Update existing arrow icons to use consistent colors
      trailingWidget = Icon(
        Icons.chevron_right,
        color: isDarkMode ? Colors.white70 : Colors.black45,
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
          color: isDarkMode ? Colors.white : Colors.black,
        ),
      ),
      subtitle: subtitle != null
        ? Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: isDarkMode ? Colors.white70 : Colors.black54,
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
      barrierColor: isDarkMode ? Colors.white10 : Colors.black12,
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
          color: isDarkMode ? Colors.black : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
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

  SystemUiOverlayStyle get _transparentNavBar => SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
  );

  void _showLanguageSelection(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: isDarkMode ? Colors.black : Colors.white,
          appBar: AppBar(
            backgroundColor: isDarkMode ? Colors.black : Colors.white,
            elevation: 0,
            systemOverlayStyle: _transparentNavBar,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              AppLocalizations.of(context)!.language,
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
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
                    trailing: isSelected ? Icon(Icons.check, color: Colors.blue) : null,
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
          backgroundColor: isDarkMode ? Colors.black : Colors.white,
          appBar: AppBar(
            backgroundColor: isDarkMode ? Colors.black : Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              AppLocalizations.of(context)!.search_engine,
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
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
                    trailing: currentSearchEngine == 'Google' ? Icon(Icons.check, color: Colors.blue) : null,
                  ),
                  _buildSettingsItem(
                    title: 'Bing',
                    onTap: () => _setSearchEngine('Bing'),
                    trailing: currentSearchEngine == 'Bing' ? Icon(Icons.check, color: Colors.blue) : null,
                  ),
                  _buildSettingsItem(
                    title: 'DuckDuckGo',
                    onTap: () => _setSearchEngine('DuckDuckGo'),
                    trailing: currentSearchEngine == 'DuckDuckGo' ? Icon(Icons.check, color: Colors.blue) : null,
                  ),
                  _buildSettingsItem(
                    title: 'Brave',
                    onTap: () => _setSearchEngine('Brave'),
                    trailing: currentSearchEngine == 'Brave' ? Icon(Icons.check, color: Colors.blue) : null,
                  ),
                  _buildSettingsItem(
                    title: 'Yahoo',
                    onTap: () => _setSearchEngine('Yahoo'),
                    trailing: currentSearchEngine == 'Yahoo' ? Icon(Icons.check, color: Colors.blue) : null,
                  ),
                  _buildSettingsItem(
                    title: 'Yandex',
                    onTap: () => _setSearchEngine('Yandex'),
                    isLast: true,
                    trailing: currentSearchEngine == 'Yandex' ? Icon(Icons.check, color: Colors.blue) : null,
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
        builder: (context) => StatefulBuilder(
          builder: (context, setState) => Scaffold(
            backgroundColor: isDarkMode ? Colors.black : Colors.white,
            appBar: AppBar(
              backgroundColor: isDarkMode ? Colors.black : Colors.white,
              elevation: 0,
              systemOverlayStyle: SystemUiOverlayStyle(
                systemNavigationBarColor: Colors.transparent,
                systemNavigationBarDividerColor: Colors.transparent,
              ),
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                AppLocalizations.of(context)!.appearance,
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            body: ListView(
              padding: const EdgeInsets.only(top: 8),
              children: [
                _buildSettingsSection(
                  title: AppLocalizations.of(context)!.chooseTheme,
                  children: [
                    _buildSettingsItem(
                      title: AppLocalizations.of(context)!.dark_mode,
                      trailing: Transform.scale(
                        scale: 0.7,
                        child: Switch(
                          value: isDarkMode,
                          onChanged: (value) {
                            setState(() => isDarkMode = value);
                            this.setState(() {});
                            widget.onThemeChange?.call(value);
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
      ),
    );
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
          backgroundColor: isDarkMode ? Colors.black : Colors.white,
          appBar: AppBar(
            backgroundColor: isDarkMode ? Colors.black : Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              AppLocalizations.of(context)!.text_size,
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
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
                    trailing: _textSize == 0.8 ? Icon(Icons.check, color: Theme.of(context).primaryColor) : null,
                    onTap: () {
                      setState(() => _textSize = 0.8);
                      Navigator.pop(context);
                    },
                    isFirst: true,
                    isLast: false,
                  ),
                  _buildSettingsItem(
                    title: AppLocalizations.of(context)!.text_size_medium,
                    trailing: _textSize == 1.0 ? Icon(Icons.check, color: Theme.of(context).primaryColor) : null,
                    onTap: () {
                      setState(() => _textSize = 1.0);
                      Navigator.pop(context);
                    },
                    isFirst: false,
                    isLast: false,
                  ),
                  _buildSettingsItem(
                    title: AppLocalizations.of(context)!.text_size_large,
                    trailing: _textSize == 1.2 ? Icon(Icons.check, color: Theme.of(context).primaryColor) : null,
                    onTap: () {
                      setState(() => _textSize = 1.2);
                      Navigator.pop(context);
                    },
                    isFirst: false,
                    isLast: false,
                  ),
                  _buildSettingsItem(
                    title: AppLocalizations.of(context)!.text_size_very_large,
                    trailing: _textSize == 1.4 ? Icon(Icons.check, color: Theme.of(context).primaryColor) : null,
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
          backgroundColor: isDarkMode ? Colors.black : Colors.white,
          appBar: AppBar(
            backgroundColor: isDarkMode ? Colors.black : Colors.white,
            elevation: 0,
            systemOverlayStyle: _transparentNavBar,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              AppLocalizations.of(context)!.downloads,
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
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

  Future<dynamic> _showAboutPage() {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: isDarkMode ? Colors.black : Colors.white,
          appBar: AppBar(
            backgroundColor: isDarkMode ? Colors.black : Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.chevron_left,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              AppLocalizations.of(context)!.about,
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
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
                    subtitle: AppLocalizations.of(context)!.version('0.0.6'),
                    isFirst: true,
                    isLast: false,
                  ),
                  _buildSettingsItem(
                    title: AppLocalizations.of(context)!.flutter_version,
                    subtitle: 'Flutter 3.27.3',
                    isFirst: false,
                    isLast: false,
                  ),
                  _buildSettingsItem(
                    title: AppLocalizations.of(context)!.software_team,
                    subtitle: 'Ata TÜRKÇÜ',
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
            color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.chevron_left,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
            onPressed: onBack,
          ),
          Expanded(
            child: Text(
              getLocalizedTitle(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildQuickActionsPanel() {
    final screenWidth = MediaQuery.of(context).size.width;
    final panelWidth = screenWidth - 32;

    return Container(
      width: panelWidth,
      height: 100,
      margin: const EdgeInsets.only(bottom: 0), // Removed bottom margin
      child: Material(
        color: Colors.transparent,
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
                    Icons.settings_rounded,
                    onPressed: () => setState(() {
                      isSettingsVisible = true;
                      _isSlideUpPanelVisible = false;
                      _slideUpController.reverse();
                    }),
                  ),
                  _buildQuickActionButton(
                    AppLocalizations.of(context)!.downloads,
                    Icons.download_rounded,
                    onPressed: () => setState(() {
                      isDownloadsVisible = true;
                      _isSlideUpPanelVisible = false;
                      _slideUpController.reverse();
                    }),
                  ),
                  _buildQuickActionButton(
                    AppLocalizations.of(context)!.tabs,
                    Icons.tab_rounded,
                    onPressed: () => setState(() {
                      isTabsVisible = true;
                      _isSlideUpPanelVisible = false;
                      _slideUpController.reverse();
                    }),
                  ),
                  _buildQuickActionButton(
                    AppLocalizations.of(context)!.bookmarks,
                    Icons.bookmark_rounded,
                    onPressed: () => setState(() {
                      isBookmarksVisible = true;
                      _isSlideUpPanelVisible = false;
                      _slideUpController.reverse();
                    }),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(String label, IconData icon, {VoidCallback? onPressed}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (onPressed != null) {
            setState(() {
              _isSlideUpPanelVisible = false;
              _slideUpController.reverse();
            });
            onPressed();
          }
        },
        child: Column(
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
                icon: Icon(icon),
                onPressed: () {
                  if (onPressed != null) {
                    setState(() {
                      _isSlideUpPanelVisible = false;
                      _slideUpController.reverse();
                    });
                    onPressed();
                  }
                },
                color: isDarkMode ? Colors.white70 : Colors.black54,
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
        ),
      ),
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
                  icon: Icon(
                    Icons.keyboard_arrow_up_rounded,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                  onPressed: () => _performSearch(searchUp: true),
                ),
                IconButton(
                  icon: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                  onPressed: () => _performSearch(),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close_rounded,
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

  void _switchTab(int index) async {
    if (index != currentTabIndex && index >= 0 && index < tabs.length) {
      final tab = tabs[index];
      
      // Store the current tab's URL
      final currentUrl = await controller.currentUrl();
      if (currentUrl != null) {
        tabs[currentTabIndex].url = currentUrl;
      }
      
      setState(() {
        currentTabIndex = index;
        controller = tab.controller;
        _displayUrl = tab.url;
        _urlController.text = _formatUrl(tab.url);
      });

      // Load the URL in the WebView if needed
      final targetUrl = await tab.controller.currentUrl();
      if (targetUrl != tab.url) {
        await controller.loadRequest(Uri.parse(tab.url));
      }
      
      // Resume the target tab
      final targetTabId = tab.controller.hashCode.toString();
      await _optimizationEngine.resumeTab(targetTabId);
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
                    AppLocalizations.of(context)!.dark_mode,
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        AppLocalizations.of(context)!.text_size,
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Text('A', style: TextStyle(fontSize: 14)),
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
                        Text('A', style: TextStyle(fontSize: 24)),
                      ],
                    ),
                  ],
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    AppLocalizations.of(context)!.show_images,
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
    return _buildPanel(
      header: _buildPanelHeader(
        AppLocalizations.of(context)!.downloads,
        onBack: () => setState(() => isDownloadsVisible = false),
      ),
      body: downloads.isEmpty && !isDownloading
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
                    color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
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
                                    color: isDarkMode ? Colors.white70 : Colors.black54,
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
                                        color: isDarkMode ? Colors.white : Colors.black,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _extractDomain(currentDownloadUrl),
                                      style: TextStyle(
                                        color: isDarkMode ? Colors.white54 : Colors.black45,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  setState(() {
                                    isDownloading = false;
                                    currentDownloadUrl = '';
                                    downloadProgress = 0.0;
                                    currentDownloadSize = null;
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: downloadProgress,
                            backgroundColor: isDarkMode ? Colors.white12 : Colors.black12,
                            valueColor: AlwaysStoppedAnimation(
                              isDarkMode ? Colors.white70 : Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$downloadedSizeStr / $totalSizeStr',
                            style: TextStyle(
                              color: isDarkMode ? Colors.white54 : Colors.black45,
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
                final fileName = download['fileName'] as String? ?? AppLocalizations.of(context)!.unknown;
                final timestamp = DateTime.parse(download['timestamp'] as String? ?? DateTime.now().toIso8601String());
                final sizeStr = download['size'] as String? ?? '0';
                final filePath = '/storage/emulated/0/Download/$fileName';
                
                return Card(
                  elevation: 0,
                  color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () async {
                      await OpenFile.open(filePath);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.file_download_done,
                              color: isDarkMode ? Colors.white70 : Colors.black54,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fileName,
                                  style: TextStyle(
                                    color: isDarkMode ? Colors.white : Colors.black,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_formatDate(timestamp)} • $sizeStr',
                                  style: TextStyle(
                                    color: isDarkMode ? Colors.white54 : Colors.black45,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuButton(
                            icon: Icon(
                              Icons.more_vert,
                              color: isDarkMode ? Colors.white70 : Colors.black54,
                            ),
                            color: isDarkMode ? Colors.grey[900] : Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.open_in_new,
                                      size: 20,
                                      color: isDarkMode ? Colors.white70 : Colors.black54,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      AppLocalizations.of(context)!.open,
                                      style: TextStyle(
                                        color: isDarkMode ? Colors.white : Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () async {
                                  await OpenFile.open(filePath);
                                },
                              ),
                              PopupMenuItem(
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.history,
                                      size: 20,
                                      color: isDarkMode ? Colors.white70 : Colors.black54,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Remove from History',
                                      style: TextStyle(
                                        color: isDarkMode ? Colors.white : Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () => _showDeleteDownloadDialog(downloadIndex),
                              ),
                              PopupMenuItem(
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.delete_forever,
                                      size: 20,
                                      color: Colors.red,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Delete from Device',
                                      style: const TextStyle(
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () async {
                                  final file = File(filePath);
                                  if (await file.exists()) {
                                    await file.delete();
                                    _showDeleteDownloadDialog(downloadIndex);
                                  }
                                },
                              ),
                            ],
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
                            color: isDarkMode ? Colors.white70 : Colors.black45,
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
                color: isDarkMode 
                  ? Colors.black.withOpacity(0.7) 
                  : Colors.white.withOpacity(0.7),
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
      color: isDarkMode ? Colors.black : Colors.white,
      child: Column(
        children: [
          _buildPanelHeader(
            isHistoryVisible ? AppLocalizations.of(context)!.browsing_history : AppLocalizations.of(context)!.tabs,
            onBack: () {
              setState(() {
                isTabsVisible = false;
              });
            },
            trailing: isHistoryVisible ? IconButton(
              icon: Icon(
                Icons.delete_outline,
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: isDarkMode ? Colors.black : Colors.white,
                    title: Text(
                      AppLocalizations.of(context)!.clear_browser_data,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    content: Text(
                      AppLocalizations.of(context)!.clear_browsing_history_confirm,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          AppLocalizations.of(context)!.cancel,
                          style: TextStyle(
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _clearHistory();
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
                  ),
                );
              },
            ) : PopupMenuButton<String>(
              icon: Icon(
                Icons.add,
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
              color: isDarkMode ? Colors.black : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'new_tab',
                  child: Row(
                    children: [
                      Icon(
                        Icons.add,
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        AppLocalizations.of(context)!.new_tab,
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'new_incognito_tab',
                  child: Row(
                    children: [
                      Icon(
                        Icons.visibility_off,
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        AppLocalizations.of(context)!.new_incognito_tab,
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'new_tab') {
                  _addNewTab();
                } else if (value == 'new_incognito_tab') {
                  _addNewTab(isIncognito: true);
                }
                setState(() {
                  isTabsVisible = false;
                });
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildHeaderButton(
                  title: AppLocalizations.of(context)!.tabs,
                  count: displayTabs.length,
                  isSelected: !isHistoryVisible,
                  onTap: () => setState(() => isHistoryVisible = false),
                ),
                const SizedBox(width: 16),
                _buildHeaderButton(
                  title: AppLocalizations.of(context)!.browsing_history,
                  count: _loadedHistory.length,
                  isSelected: isHistoryVisible,
                  onTap: () => setState(() => isHistoryVisible = true),
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
                          Icons.tab_unselected,
                          size: 48,
                          color: isDarkMode ? Colors.white38 : Colors.black38,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(context)!.no_active_tabs,
                          style: TextStyle(
                            fontSize: 16,
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: displayTabs.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) => _buildTabListItem(displayTabs[index], index),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabListItem(BrowserTab tab, int index) {
    final isCurrentTab = tab == tabs[currentTabIndex];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
        border: isCurrentTab ? Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.5),
          width: 1,
        ) : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: tab.favicon != null && !tab.isIncognito
            ? Image.network(
                tab.favicon!,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Icon(
                  tab.isIncognito ? Icons.visibility_off : Icons.public,
                  size: 20,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              )
            : Icon(
                tab.isIncognito ? Icons.visibility_off : Icons.public,
                size: 20,
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
        ),
        title: Text(
          tab.title.isEmpty ? tab.url : tab.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        subtitle: Text(
          _formatUrl(tab.url),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            color: isDarkMode ? Colors.white70 : Colors.black54,
          ),
        ),
        trailing: IconButton(
          icon: Icon(
            Icons.close,
            size: 20,
            color: isDarkMode ? Colors.white54 : Colors.black45,
          ),
          onPressed: () => _closeTab(tabs.indexOf(tab)),
        ),
        onTap: () async {
          await _switchToTab(tabs.indexOf(tab));
          setState(() {
            isTabsVisible = false;
          });
        },
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
            ? (isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05))
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
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            SizedBox(width: 4),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
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

  Future<void> _loadHistory() async {
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

  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('history', []);
    setState(() {
      _loadedHistory = [];
    });
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
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: isDarkMode ? Colors.black : Colors.white,
                          title: Text(
                            'Clear History',
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          content: Text(
                            'Are you sure you want to clear all browsing history?',
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
                              onPressed: () {
                                Navigator.pop(context);
                                _clearHistory();
                              },
                              child: Text(
                                'Clear',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
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

  Widget _buildHistoryList() {
    if (_loadedHistory.isEmpty) {
      return _buildEmptyState(
        AppLocalizations.of(context)!.no_browsing_history,
        Icons.history_outlined,
      );
    }

    // Group history items by date
    final groupedHistory = <String, List<Map<String, dynamic>>>{};
    for (var item in _loadedHistory) {
      final date = DateTime.parse(item['timestamp']);
      final key = _getFormattedDate(date);
      groupedHistory.putIfAbsent(key, () => []).add(item);
    }

    return ListView.builder(
      controller: _historyScrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: groupedHistory.length,
      itemBuilder: (context, index) {
        final date = groupedHistory.keys.elementAt(index);
        final items = groupedHistory[date]!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                date,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
            ),
            ...items.map((item) => Dismissible(
              key: Key(item['timestamp']),
              background: Container(
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 16),
                child: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                ),
              ),
              direction: DismissDirection.endToStart,
              onDismissed: (_) {
                final index = _loadedHistory.indexOf(item);
                _removeHistoryItem(index);
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.history,
                      size: 20,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  title: Text(
                    item['title'] ?? item['url'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  subtitle: Text(
                    _formatUrl(item['url']),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      Icons.open_in_new,
                      size: 20,
                      color: isDarkMode ? Colors.white54 : Colors.black45,
                    ),
                    onPressed: () {
                      _addNewTab(initialUrl: item['url']);
                      setState(() {
                        isTabsVisible = false;
                      });
                    },
                  ),
                  onTap: () {
                    _addNewTab(initialUrl: item['url']);
                    setState(() {
                      isTabsVisible = false;
                    });
                  },
                ),
              ),
            )).toList(),
          ],
        );
      },
    );
  }

  String _getFormattedDate(DateTime date) {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return AppLocalizations.of(context)!.today;
    } else if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
      return AppLocalizations.of(context)!.yesterday;
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  // Add method to remove individual history items
  Future<void> _removeHistoryItem(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList('history') ?? [];
    
    if (index >= 0 && index < history.length) {
      history.removeAt(index);
      await prefs.setStringList('history', history);
      setState(() {
        _loadedHistory = history.map((e) => Map<String, dynamic>.from(json.decode(e))).toList();
      });
    }
  }

  Widget _buildSettingsPanel() {
    return Material(
      color: isDarkMode ? Colors.black : Colors.white,
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
              children: [
                _buildSettingsSection(
                  title: AppLocalizations.of(context)!.customize_browser,
                  children: [
                    _buildSettingsButton('general', () => _showGeneralSettings()),
                    _buildSettingsButton('downloads', () => _showDownloadsSettings()),
                    _buildSettingsButton('appearance', () => _showAppearanceSettings()),
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
      iconColor: Colors.green,
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
              width: 0.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: children,
          ),
        ),
        const SizedBox(height: 8),
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

    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      title: Text(
        getLocalizedLabel(),
        style: TextStyle(
          fontSize: 14,
          color: isDarkMode ? Colors.white : Colors.black,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: isDarkMode ? Colors.white54 : Colors.black45,
        size: 20,
      ),
      onTap: onTap,
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
      
      _showBookmarkAddedNotification();
    } else {
      _showNotification(
        Row(
          children: [
            const Icon(Icons.info, color: Colors.blue),
            const SizedBox(width: 16),
            Expanded(
              child: Text(AppLocalizations.of(context)!.bookmark_exists),
            ),
          ],
        ),
        duration: const Duration(seconds: 4),
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

  Future<void> _addNewTab({String? initialUrl, bool isIncognito = false}) async {
    final newTab = BrowserTab(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      url: initialUrl ?? _homeUrl,
      isIncognito: isIncognito,
    );

    final controller = WebViewController();
    newTab.controller = controller;

    await controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..enableZoom(false)
      ..setUserAgent('Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36')
      ..addJavaScriptChannel(
        'ImageHandler',
        onMessageReceived: (JavaScriptMessage message) {
          try {
            final data = json.decode(message.message);
            _tapPosition = Offset(data['x'].toDouble(), data['y'].toDouble());
            _showImageOptions(data['url']);
          } catch (e) {
            _showImageOptions(message.message);
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) async {
            if (!mounted) return;
            setState(() {
              newTab.isLoading = true;
            });
            
            await newTab.controller?.runJavaScript('''
              document.addEventListener('DOMContentLoaded', function() {
                document.querySelectorAll('img').forEach(function(img) {
                  img.addEventListener('contextmenu', function(e) {
                    e.preventDefault();
                    window.ImageHandler.postMessage(JSON.stringify({
                      url: e.target.src,
                      x: e.clientX,
                      y: e.clientY
                    }));
                  });
                });
              });
            ''');
          },
          onPageFinished: (String url) async {
            if (!mounted) return;
            final title = await newTab.controller?.getTitle() ?? url;
            setState(() {
              newTab.isLoading = false;
              newTab.title = title;
              newTab.url = url;
              newTab.isSecure = url.startsWith('https://');
            });
          },
          onUrlChange: (UrlChange change) {
            if (!mounted) return;
            final url = change.url ?? '';
            setState(() {
              newTab.url = url;
              newTab.isSecure = url.startsWith('https://');
            });
          },
        ),
      );

    setState(() {
      tabs.add(newTab);
      currentTabIndex = tabs.length - 1;
    });

    await newTab.controller?.loadRequest(Uri.parse(newTab.url));
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
    final urlBarWidth = screenWidth - 32;
    
    return AnimatedBuilder(
      animation: _urlBarAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 100 * _urlBarAnimation.value), // Changed from -100 * (1 - _urlBarAnimation.value)
          child: GestureDetector(
            onHorizontalDragUpdate: (details) {
              setState(() {
                _urlBarSlideOffset += details.delta.dx;
              });
            },
            onHorizontalDragEnd: (details) {
              if (_urlBarSlideOffset.abs() > 50) {
                if (_urlBarSlideOffset < 0 && canGoBack) {
                  controller.goBack();
                  controller.runJavaScript("animatePageTransition('back')");
                } else if (_urlBarSlideOffset > 0 && canGoForward) {
                  controller.goForward();
                  controller.runJavaScript("animatePageTransition('forward')");
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
                    width: urlBarWidth,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      color: isDarkMode 
                        ? Colors.black.withOpacity(0.7) 
                        : Colors.white.withOpacity(0.7),
                      border: Border.all(
                        color: isDarkMode 
                          ? Colors.white.withOpacity(0.1) 
                          : Colors.black.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 16),
                        Icon(
                          isSecure ? Icons.shield : Icons.shield_outlined,
                          size: 20,
                          color: isDarkMode ? Colors.white70 : Colors.black54,
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
                              color: isDarkMode ? Colors.white : Colors.black,
                              fontSize: 16,
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: AppLocalizations.of(context)!.search_or_type_url,
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
                                _urlBarIdleTimer?.cancel();
                                _startUrlBarIdleTimer();
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
                          icon: Icon(
                            _urlFocusNode.hasFocus ? Icons.close : Icons.refresh,
                            size: 20,
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                          tooltip: _urlFocusNode.hasFocus ? 
                            AppLocalizations.of(context)!.close_search : 
                            AppLocalizations.of(context)!.refresh_page,
                          onPressed: () {
                            if (_urlFocusNode.hasFocus) {
                              _urlFocusNode.unfocus();
                              setState(() {
                                _urlController.text = _formatUrl(_displayUrl);
                              });
                            } else {
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
        );
      },
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
              color: isDarkMode ? Colors.white : Colors.black,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: AppLocalizations.of(context)!.search_or_type_url,
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
                _urlBarIdleTimer?.cancel();
                _startUrlBarIdleTimer();
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
          icon: Icon(
            _urlFocusNode.hasFocus ? Icons.close : Icons.refresh,
            size: 20,
            color: isDarkMode ? Colors.white70 : Colors.black54,
          ),
          tooltip: _urlFocusNode.hasFocus ? 
            AppLocalizations.of(context)!.close_search : 
            AppLocalizations.of(context)!.refresh_page,
          onPressed: () {
            if (_urlFocusNode.hasFocus) {
              _urlFocusNode.unfocus();
              setState(() {
                _urlController.text = _formatUrl(_displayUrl);
              });
            } else {
              controller.reload();
            }
          },
        ),
      ],
    );
  }

  Future<WebViewController> _createWebViewController() async {
    return await _initializeWebViewController();
  }

  DateTime? _lastBackPressTime;

  Future<bool> _onWillPop() async {
    if (await controller.canGoBack()) {
      await _goBack();
      return false;
    }

    if (_lastBackPressTime == null || 
        DateTime.now().difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      // Show modern notification using custom notification
      showCustomNotification(
        context: context,
        message: AppLocalizations.of(context)!.press_back_to_exit,
        icon: Icons.exit_to_app,
        iconColor: isDarkMode ? Colors.white70 : Colors.black54,
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
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            Positioned.fill(
              child: Listener(
                behavior: HitTestBehavior.translucent,
                onPointerMove: (PointerMoveEvent event) {
                  if (event.delta.dy < -2) { // Finger moving up (negative delta)
                    _hideUrlBar();
                  } else if (event.delta.dy > 2) { // Finger moving down (positive delta)
                    _showUrlBar();
                  }
                },
                child: WebViewWidget(controller: controller),
              ),
            ),
            
            if (isTabsVisible || isSettingsVisible || isBookmarksVisible || isDownloadsVisible)
              _buildOverlayPanel(),
            
            Positioned(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).padding.bottom,
              child: GestureDetector(
                onVerticalDragUpdate: (details) {
                  if (details.delta.dy < -10 && !_isSlideUpPanelVisible) {
                    _handleSlideUpPanelVisibility(true);
                  } else if (details.delta.dy > 10 && _isSlideUpPanelVisible) {
                    _handleSlideUpPanelVisibility(false);
                  }
                },
                onVerticalDragEnd: (details) {
                  if (details.primaryVelocity != null) {
                    if (details.primaryVelocity! > 0) { // Dragging down
                      _handleSlideUpPanelVisibility(false);
                    } else if (details.primaryVelocity! < 0) { // Dragging up
                      _handleSlideUpPanelVisibility(true);
                    }
                  }
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isTabsVisible && !isSettingsVisible && !isBookmarksVisible && !isDownloadsVisible)
                      AnimatedBuilder(
                        animation: _slideUpController,
                        builder: (context, child) {
                          final slideValue = _slideUpController.value;
                          return Transform.translate(
                            offset: Offset(0, (1 - slideValue) * 100),
                            child: Opacity(
                              opacity: slideValue,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildQuickActionsPanel(),
                                  const SizedBox(height: 8), // Reduced from 12 to 8
                                  _buildNavigationPanel(),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    if (!_isSlideUpPanelVisible && !isTabsVisible && !isSettingsVisible && !isBookmarksVisible && !isDownloadsVisible)
                      AnimatedBuilder(
                        animation: _slideUpController,
                        builder: (context, child) {
                          final slideValue = _slideUpController.value;
                          return Transform.translate(
                            offset: Offset(0, (1 - slideValue) * -20),
                            child: Opacity(
                              opacity: 1 - slideValue,
                              child: _buildUrlBar(),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Update URL when page changes
 
  // Navigation delegate methods
  Future<NavigationDelegate> get _navigationDelegate async {
    return NavigationDelegate(
      onNavigationRequest: (NavigationRequest request) async {
        final url = request.url.toLowerCase();
        final downloadExtensions = [
          '.pdf', '.doc', '.docx', '.xls', '.xlsx',
          '.zip', '.rar', '.7z', '.tar', '.gz',
          '.mp3', '.mp4', '.avi', '.mov', '.wmv',
          '.apk', '.exe', '.dmg', '.iso', '.img',
          '.csv', '.txt', '.rtf', '.ppt', '.pptx'
        ];
        
        if (downloadExtensions.any((ext) => url.contains(ext)) ||
            request.url.startsWith('blob:') ||
            request.url.startsWith('data:') && !url.contains('text/html')) {
          await _handleDownload(request.url);
          return NavigationDecision.prevent;
        }
        return NavigationDecision.navigate;
      },
      onPageStarted: (String url) async {
        if (!mounted) return;
        setState(() {
          isLoading = true;
          _displayUrl = url;
          _urlController.text = _formatUrl(url);
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
        await _saveToHistory(url, await controller.getTitle() ?? 'Untitled');
      },
      onPageFinished: (String url) async {
        if (!mounted) return;
        final title = await controller.getTitle() ?? _displayUrl;
        setState(() {
          isLoading = false;
          if (tabs.isNotEmpty && currentTabIndex >= 0 && currentTabIndex < tabs.length) {
            tabs[currentTabIndex].title = title;
            tabs[currentTabIndex].url = url;
          }
          _displayUrl = url;
          _urlController.text = _formatUrl(url);
        });
        await _updateNavigationState();
        await _optimizationEngine.onPageFinishLoad(url);
        await _updateFavicon(url);
      },
      onWebResourceError: (WebResourceError error) {
        if (!mounted) return;
        setState(() {
          isLoading = false;
        });
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

  Future<String> _getDownloadLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final directory = await getApplicationDocumentsDirectory();
    return prefs.getString('downloadLocation') ?? directory.path;
  }

  Future<void> _handleDownload(String url) async {
    if (Platform.isAndroid) {
      // Get Android version
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt;
      
      List<Permission> permissions = [];
      
      if (sdkInt >= 33) {
        // Android 13 and above: Request media permissions
        permissions.addAll([
          Permission.photos,
          Permission.videos,
          Permission.audio,
        ]);
      } else {
        // Android 12 and below: Request storage permission
        permissions.add(Permission.storage);
      }

      Map<Permission, PermissionStatus> statuses = await permissions.request();
      bool allGranted = statuses.values.every((status) => status.isGranted);
      
      if (!allGranted) {
        bool anyPermanentlyDenied = statuses.values.any((status) => status.isPermanentlyDenied);
        
        if (anyPermanentlyDenied) {
          // Show dialog to open settings
          if (!mounted) return;
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
              title: Text(
                AppLocalizations.of(context)!.storage_permission_required,
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              content: Text(
                AppLocalizations.of(context)!.storage_permission_description,
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.black87,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    AppLocalizations.of(context)!.cancel,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    openAppSettings();
                  },
                  child: Text(
                    AppLocalizations.of(context)!.settings,
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          // Show notification that permission is required
          if (!mounted) return;
          _showNotification(
            Row(
              children: [
                const Icon(Icons.error, color: Colors.red),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(AppLocalizations.of(context)!.storage_permission_denied),
                ),
              ],
            ),
            duration: const Duration(seconds: 4),
          );
        }
        return;
      }
    }

    HttpClient? client;
    IOSink? sink;
    
    try {
      client = HttpClient();
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      final contentLength = response.contentLength;
      
      final contentDisposition = response.headers['content-disposition'];
      String fileName = url.split('/').last;
      if (contentDisposition != null && contentDisposition.isNotEmpty) {
        final match = RegExp(r'filename[^;=\n]*=([\w\.]+)').firstMatch(contentDisposition.first);
        if (match != null) {
          fileName = match.group(1) ?? fileName;
        }
      }

      setState(() {
        isDownloading = true;
        currentDownloadUrl = url;
        downloadProgress = 0.0;
        currentDownloadSize = contentLength;
        currentFileName = fileName;
      });

      // Get the system's Downloads directory
      final downloadsDirectory = Directory('/storage/emulated/0/Download');
      if (!await downloadsDirectory.exists()) {
        await downloadsDirectory.create(recursive: true);
      }
      
      final filePath = '${downloadsDirectory.path}/$fileName';
      final file = File(filePath);
      sink = file.openWrite();
      
      int received = 0;
      await for (final chunk in response) {
        if (!isDownloading) break;
        sink.add(chunk);
        received += chunk.length;
        if (contentLength > 0) {  // Only update progress if we know the total size
          setState(() {
            downloadProgress = received / contentLength;
          });
        }
      }
      
      await sink.close();
      
      if (!isDownloading) {
        if (await file.exists()) {
          await file.delete();
        }
        return;
      }
      
      final download = {
        'fileName': fileName,
        'url': url,
        'timestamp': DateTime.now().toIso8601String(),
        'size': contentLength?.toString() ?? '0',  // Ensure size is stored as string
      };

      final prefs = await SharedPreferences.getInstance();
      final downloadsList = prefs.getStringList('downloads') ?? [];
      downloadsList.insert(0, json.encode(download));
      await prefs.setStringList('downloads', downloadsList);

      setState(() {
        downloads = downloadsList.map((e) => Map<String, dynamic>.from(json.decode(e))).toList();
        isDownloading = false;
        currentDownloadUrl = '';
        downloadProgress = 0.0;
        currentDownloadSize = null;
        currentFileName = null;
      });

      // Show download complete notification
      _showNotification(
        Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
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

      // Trigger media scanner
      const platform = MethodChannel('com.vertex.solar/browser');
      try {
        await platform.invokeMethod('scanFile', {'path': filePath});
      } catch (e) {
        print('Error scanning file: $e');
      }
    } catch (e) {
      print('Download error: $e');
      client?.close();
      await sink?.close();
      setState(() {
        isDownloading = false;
        currentDownloadUrl = '';
        downloadProgress = 0.0;
        currentDownloadSize = null;
        currentFileName = null;
      });

      // Show error notification
      _showNotification(
        Row(
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 16),
            Expanded(
              child: Text(AppLocalizations.of(context)!.download_failed + ': ${e.toString()}'),
            ),
          ],
        ),
        duration: const Duration(seconds: 4),
      );
    }
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
                color: isDarkMode ? Colors.grey[900] : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
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
                          color: Theme.of(context).primaryColor,
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
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        title: Text(
          AppLocalizations.of(context)!.clear_downloads_history_title,
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        content: Text(
          AppLocalizations.of(context)!.clear_downloads_history_confirm,
          style: TextStyle(
            color: isDarkMode ? Colors.white70 : Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.of(context)!.cancel,
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.black54,
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
                    const Icon(Icons.check_circle, color: Colors.green),
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
                color: Colors.red,
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
    final fileName = download['fileName'];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        title: Text(
          AppLocalizations.of(context)!.delete_download,
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        content: Text(
          AppLocalizations.of(context)!.delete_download_confirm(fileName),
          style: TextStyle(
            color: isDarkMode ? Colors.white70 : Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.of(context)!.cancel,
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.black54,
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
                    const Icon(Icons.check_circle, color: Colors.green),
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
                color: Colors.red,
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

    // Request storage permission
    final status = await Permission.storage.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.permission_denied)),
      );
      return;
    }

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

  void _handleSlideUpPanelVisibility(bool value) {
    if (mounted) {
      setState(() {
        _isSlideUpPanelVisible = value;
        if (value) {
          _slideUpPanelOffset = 0.0;
          _slideUpPanelOpacity = 0.0;
          _slideUpController.forward();
        } else {
          _slideUpController.reverse();
        }
      });
    }
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
    final screenWidth = MediaQuery.of(context).size.width;
    final panelWidth = screenWidth - 32;
    final currentUrl = tabs[currentTabIndex].url;
    final isCurrentPageBookmarked = bookmarks.any((bookmark) {
      if (bookmark is Map<String, dynamic>) {
        return bookmark['url'] == currentUrl;
      }
      return false;
    });

    return Container(
      width: panelWidth,
      height: 48,
      margin: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            decoration: _getGlassmorphicDecoration(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded, size: 24),
                  color: canGoBack ? (isDarkMode ? Colors.white70 : Colors.black54) : (isDarkMode ? Colors.white24 : Colors.black12),
                  onPressed: canGoBack ? _goBack : null,
                ),
                IconButton(
                  icon: Icon(
                    isCurrentPageBookmarked ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                    size: 24
                  ),
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                  onPressed: _addBookmark,
                ),
                IconButton(
                  icon: const Icon(Icons.ios_share_rounded, size: 24),
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                  onPressed: () async {
                    if (currentUrl.isNotEmpty) {
                      await Share.share(currentUrl);
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded, size: 24),
                  color: canGoForward ? (isDarkMode ? Colors.white70 : Colors.black54) : (isDarkMode ? Colors.white24 : Colors.black12),
                  onPressed: canGoForward ? _goForward : null,
                ),
              ],
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
    
    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        _tapPosition & const Size(40, 40),
        Offset.zero & overlay.size
      ),
      color: isDarkMode ? Colors.grey[900] : Colors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        PopupMenuItem(
          child: Row(
            children: [
              Icon(
                Icons.download_rounded,
                color: isDarkMode ? Colors.white70 : Colors.black54,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context)!.download_image,
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          onTap: () => _handleDownload(imageUrl),
        ),
        PopupMenuItem(
          child: Row(
            children: [
              Icon(
                Icons.ios_share_rounded,
                color: isDarkMode ? Colors.white70 : Colors.black54,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context)!.share_image,
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          onTap: () async => await Share.share(imageUrl),
        ),
        PopupMenuItem(
          child: Row(
            children: [
              Icon(
                Icons.open_in_new_rounded,
                color: isDarkMode ? Colors.white70 : Colors.black54,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context)!.open_in_new_tab,
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          onTap: () async {
            Navigator.pop(context);
            
            // Create a simple HTML page that displays the image
            final imageHtml = '''
              <html>
                <head>
                  <meta name="viewport" content="width=device-width, initial-scale=1.0">
                  <style>
                    body {
                      margin: 0;
                      padding: 0;
                      display: flex;
                      justify-content: center;
                      align-items: center;
                      min-height: 100vh;
                      background: ${isDarkMode ? '#1a1a1a' : '#ffffff'};
                    }
                    img {
                      max-width: 100%;
                      max-height: 100vh;
                      object-fit: contain;
                    }
                  </style>
                </head>
                <body>
                  <img src="$imageUrl" alt="Image">
                </body>
              </html>
            ''';
            
            // Create a new WebView controller first
            final newController = WebViewController()
              ..setJavaScriptMode(JavaScriptMode.unrestricted)
              ..setBackgroundColor(Colors.transparent)
              ..enableZoom(true);
            
            // Add the new tab with the controller
            setState(() {
              tabs.add(BrowserTab(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                url: imageUrl,
                title: AppLocalizations.of(context)!.open_in_new_tab,
                favicon: null,
              ));
              currentTabIndex = tabs.length - 1;
              controller = tabs[currentTabIndex].controller;
            });

            // Load the HTML content
            await controller.loadHtmlString(imageHtml);
          },
        ),
      ],
    );
  }

  // Add tap position tracking
  Offset _tapPosition = Offset.zero;

  Future<void> _goBack() async {
    if (await controller.canGoBack()) {
      await controller.goBack();
      final url = await controller.currentUrl();
      if (url != null) {
        _updateUrl(url);
        await _updateNavigationState();
      }
    }
  }

  Future<void> _goForward() async {
    if (await controller.canGoForward()) {
      await controller.goForward();
      final url = await controller.currentUrl();
      if (url != null) {
        _updateUrl(url);
        await _updateNavigationState();
      }
    }
  }

  // Add new method for switching tabs
  Future<void> _switchToTab(int index) async {
    if (index != currentTabIndex && index >= 0 && index < tabs.length) {
      final tab = tabs[index];
      
      if (tab.controller == null) {
        tab.controller = await _initializeWebViewController();
      }

      if (tab.controller != null) {
        setState(() {
          currentTabIndex = index;
          controller = tab.controller!;
          _displayUrl = tab.url;
          _urlController.text = _formatUrl(tab.url);
        });

        // Force reload the page to prevent black screen
        final targetUrl = await tab.controller?.currentUrl();
        if (targetUrl != tab.url) {
          await tab.controller?.loadRequest(Uri.parse(tab.url));
        }
      }
    }
  }

  // In the method where you create new tabs
  void _createNewTab(String url) async {
    final newController = await _initializeWebViewController();
    
    final newTab = BrowserTab(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      url: url,
      title: 'New Tab',
      isIncognito: tabs.isNotEmpty ? tabs[currentTabIndex].isIncognito : false,
      controller: newController,
    );

    setState(() {
      tabs.add(newTab);
      currentTabIndex = tabs.length - 1;
      controller = newController;
      _displayUrl = url;
      _urlController.text = _formatUrl(url);
    });

    // Ensure the page is loaded
    await Future.delayed(Duration(milliseconds: 100));
    if (url.isNotEmpty) {
      await newController.loadRequest(Uri.parse(url));
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
          backgroundColor: isDarkMode ? Colors.black : Colors.white,
          appBar: AppBar(
            backgroundColor: isDarkMode ? Colors.black : Colors.white,
            elevation: 0,
            systemOverlayStyle: _transparentNavBar,
            title: Text(
              AppLocalizations.of(context)!.settings,
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
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
                  _buildSettingsItem(
                    title: AppLocalizations.of(context)!.general,
                    onTap: () => _showGeneralSettings(),
                    isFirst: true,
                    isLast: false,
                  ),
                  _buildSettingsItem(
                    title: AppLocalizations.of(context)!.downloads,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showDownloadsSettings(),
                    isFirst: false,
                    isLast: false,
                  ),
                  _buildSettingsItem(
                    title: AppLocalizations.of(context)!.appearance,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showAppearanceSettings(),
                    isFirst: false,
                    isLast: false,
                  ),
                  _buildSettingsItem(
                    title: AppLocalizations.of(context)!.help,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showHelpPage(),
                    isFirst: false,
                    isLast: false,
                  ),
                  _buildSettingsItem(
                    title: AppLocalizations.of(context)!.rate_us,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showRateUs(),
                    isFirst: false,
                    isLast: false,
                  ),
                  _buildSettingsItem(
                    title: AppLocalizations.of(context)!.privacy_policy,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showPrivacyPolicy(),
                    isFirst: false,
                    isLast: false,
                  ),
                  _buildSettingsItem(
                    title: AppLocalizations.of(context)!.terms_of_use,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showTermsOfUse(),
                    isFirst: false,
                    isLast: false,
                  ),
                  _buildSettingsItem(
                    title: AppLocalizations.of(context)!.about,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showAboutPage(),
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
    if (tab.controller == null) {
      _initializeWebViewController().then((webViewController) {
        setState(() {
          tab.controller = webViewController;
        });
        tab.controller?.setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) async {
              if (!mounted) return;
              setState(() {
                isLoading = true;
              });
              _updateUrl(url);
              await _optimizationEngine.onPageStartLoad(url);
            },
            onPageFinished: (String url) async {
              if (mounted) {
                final title = await tab.controller?.getTitle() ?? url;
                setState(() {
                  isLoading = false;
                  tab.title = title;
                  tab.url = url;
                });
                if (!tab.isIncognito) {
                  await _saveToHistory(url, title);
                }
                _updateUrl(url);
                await _updateNavigationState();
                await _updateFavicon(url);
              }
            },
            onUrlChange: (UrlChange change) {
              if (mounted && change.url != null) {
                setState(() {
                  tab.url = change.url!;
                  _updateUrl(change.url!);
                });
              }
            },
          ),
        );
      });
    }
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
                const Icon(Icons.check_circle, color: Colors.green),
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

  // Add getter for current tab
  BrowserTab get currentTab => tabs[currentTabIndex];

  Future<void> _clearBrowsingData() async {
    for (var i = 0; i < tabs.length; i++) {
      await tabs[i].controller?.clearCache();
      await tabs[i].controller?.clearLocalStorage();
    }
  }

  

  Widget _buildTabIcon(BrowserTab tab) {
    return Container(
      padding: const EdgeInsets.all(4),
      child: tab.favicon != null && !tab.isIncognito
          ? Image.network(
              tab.favicon!,
              width: 16,
              height: 16,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.public,
                size: 16,
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
            )
          : Icon(
              tab.isIncognito ? Icons.private_connectivity : Icons.public,
              size: 16,
              color: isDarkMode ? Colors.white70 : Colors.black54,
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