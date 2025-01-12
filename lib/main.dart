import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:ui';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter_svg/flutter_svg.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Hide only navigation bar
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [SystemUiOverlay.top]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
  ));
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
      'themes': 'Themes',
      'about': 'About',
      'select_language': 'Select Language',
      'select_search_engine': 'Select Search Engine',
      'check_updates': 'Check for Updates',
      'version': 'Version',
      'developed_by': 'Developed by',
      'support_patreon': 'Support on Patreon',
      'search_in_page': 'Search in page',
      'no_history': 'No history available',
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
      'themes': 'Temalar',
      'about': 'Hakkında',
      'select_language': 'Dil Seçin',
      'select_search_engine': 'Arama Motoru Seçin',
      'check_updates': 'Güncellemeleri Kontrol Et',
      'version': 'Sürüm',
      'developed_by': 'Geliştiren',
      'support_patreon': 'Patreon\'da Destekle',
      'search_in_page': 'Sayfada ara',
      'no_history': 'Geçmiş bulunamadı',
    },
  };

  String t(String key) {
    return translations[currentLanguage]?[key] ?? translations['en']![key]!;
  }

  @override
  void initState() {
    super.initState();
    _initializeWebView();
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
    controller = WebViewController();
    
    if (controller.platform is AndroidWebViewController) {
      final androidController = controller.platform as AndroidWebViewController;
      await androidController.setMediaPlaybackRequiresUserGesture(false);
    }
    
    await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    await controller.enableZoom(true);
    await controller.setBackgroundColor(const Color(0x00000000));
    
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
        },
        onWebResourceError: (WebResourceError error) {
          if (error.errorCode == -1 || error.description.contains('net::ERR_CACHE_MISS')) {
            _handleCacheMissError();
          }
        },
      ),
    );

    await controller.setUserAgent('Mozilla/5.0 (Linux; Android 13; Pixel 6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36');
    
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
        } catch (e) {
          tab.domain = url;
        }
        
        // Get favicon
        if (url.isNotEmpty) {
          final uri = Uri.parse(url);
          tab.favicon = '${uri.scheme}://${uri.host}/favicon.ico';
        }
      });
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
      // First, get total matches (case insensitive)
      final countResult = await controller.runJavaScriptReturningResult('''
        var count = 0;
        var searchText = '${query.replaceAll("'", "\\'")}';
        window.find(searchText, false, false, true, false, true, false);
        var found = true;
        while (found) {
          count++;
          found = window.find(searchText, false, false, true, false, true, false);
        }
        count;
      ''');
      
      setState(() {
        totalSearchMatches = int.tryParse(countResult.toString()) ?? 0;
      });

      // Then perform the actual search
      await controller.runJavaScript('''
        window.find('${query.replaceAll("'", "\\'")}', false, ${searchUp}, true, false, true, false);
      ''');

      // Update current match position
      if (searchUp && currentSearchMatch > 1) {
        setState(() {
          currentSearchMatch--;
        });
      } else if (!searchUp && currentSearchMatch < totalSearchMatches) {
        setState(() {
          currentSearchMatch++;
        });
      }
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

  Future<List<Map<String, String>>> _getHistory() async {
    try {
      final result = await controller.runJavaScriptReturningResult('''
        (function() {
          var history = [];
          var links = document.querySelectorAll('a');
          links.forEach(function(link) {
            if (link.href) {
              history.push({
                url: link.href,
                title: link.textContent || link.href
              });
            }
          });
          return JSON.stringify(history);
        })()
      ''');
      
      final List<dynamic> historyData = json.decode(result.toString());
      return historyData.map((entry) => {
        'url': entry['url'] as String,
        'title': entry['title'] as String,
      }).toList();
    } catch (e) {
      return [];
    }
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
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.black87.withOpacity(0.8) : Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: -5,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildQuickActionButton(t('settings'), 'assets/settings24.png', onPressed: () {
                    setState(() {
                      isSettingsVisible = true;
                      isPanelExpanded = false;
                    });
                  }),
                  _buildQuickActionButton(t('downloads'), 'assets/downloads24.png'),
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
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Image.asset(iconPath, width: 24, height: 24),
            onPressed: onPressed ?? () {
              // Handle button press
            },
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.black,
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
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
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
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.black87.withOpacity(0.8) : Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
            ),
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
                  icon: Image.asset('assets/up24.png', width: 24, height: 24),
                  onPressed: () => _performSearch(searchUp: true),
                ),
                IconButton(
                  icon: Image.asset('assets/down24.png', width: 24, height: 24),
                  onPressed: () => _performSearch(),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: isDarkMode ? Colors.white : Colors.black),
                  onPressed: () {
                    setState(() {
                      isSearchMode = false;
                      currentSearchMatch = 0;
                      totalSearchMatches = 0;
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

  Widget _buildUrlPanel() {
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        if (details.primaryDelta! < -20 && !isPanelExpanded) {
          setState(() {
            isPanelExpanded = true;
          });
        } else if (details.primaryDelta! > 20 && isPanelExpanded) {
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
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: -5,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _showSecurityInfo,
                    child: Image.asset(
                      isSecure ? 'assets/secure24.png' : 'assets/unsecure24.png',
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
                              style: const TextStyle(
                                color: Colors.black,
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
                            hintStyle: TextStyle(color: Colors.black.withOpacity(0.7)),
                            border: InputBorder.none,
                          ),
                          style: const TextStyle(color: Colors.black),
                          onSubmitted: (_) => _loadUrl(),
                          autofocus: true,
                        ),
                  ),
                  IconButton(
                    icon: Image.asset('assets/reload24.png', width: 24, height: 24),
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
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: -5,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Image.asset('assets/back24.png', width: 24, height: 24),
                  onPressed: canGoBack ? () => controller.goBack() : null,
                ),
                IconButton(
                  icon: Image.asset('assets/search24.png', width: 24, height: 24),
                  onPressed: () {
                    setState(() {
                      isSearchMode = true;
                      isPanelExpanded = false;
                    });
                  },
                ),
                IconButton(
                  icon: Image.asset('assets/reload24.png', width: 24, height: 24),
                  onPressed: () => controller.reload(),
                ),
                IconButton(
                  icon: Image.asset('assets/share24.png', width: 24, height: 24),
                  onPressed: _shareUrl,
                ),
                IconButton(
                  icon: Image.asset('assets/forward24.png', width: 24, height: 24),
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
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        color: Colors.white,
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
    return Container(
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
    );
  }

  Widget _buildSettingsPanel() {
    return DefaultTabController(
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
                Tab(text: t('themes')),
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
                    ],
                  ),
                  // Themes
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).padding;
    
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: padding.top, // Add padding for status bar
            left: 0,
            right: 0,
            bottom: 0,
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
              top: padding.top, // Add padding for status bar
              left: 0,
              right: 0,
              child: const LinearProgressIndicator(),
            ),
          if (!isTabsVisible && !isHistoryVisible && !isSettingsVisible)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              left: _isUrlBarMinimized ? 16 : 16,
              right: _isUrlBarMinimized ? null : 16,
              bottom: _isUrlBarHidden ? -80 : 16,
              child: GestureDetector(
                onVerticalDragEnd: (details) {
                  if (details.primaryVelocity! < 0) {
                    // Swipe up
                    setState(() {
                      isPanelExpanded = true;
                    });
                  } else if (details.primaryVelocity! > 0) {
                    // Swipe down
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
                            color: Colors.white.withOpacity(0.8),
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
                            icon: Image.asset('assets/search24.png', width: 24, height: 24),
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
          if (isTabsVisible)
            _buildTabsPanel(),
          if (isHistoryVisible)
            _buildHistoryPanel(),
          if (isSettingsVisible)
            _buildSettingsPanel(),
        ],
      ),
    );
  }
}
