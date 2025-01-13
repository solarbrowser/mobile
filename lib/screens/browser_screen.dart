import 'dart:io';
import 'dart:async';
import 'dart:convert';
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
  bool allowHttp = false;

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
    });
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  Future<void> _initializeWebView() async {
    if (Platform.isAndroid) {
      final androidParams = AndroidWebViewControllerCreationParams();
      final androidController = AndroidWebViewController(androidParams);
      await androidController.setJavaScriptMode(JavaScriptMode.unrestricted);
      await androidController.setBackgroundColor(Colors.white);
      controller = WebViewController.fromPlatform(androidController);
    } else if (Platform.isIOS) {
      final webKitParams = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
      );
      final webKitController = WebKitWebViewController(webKitParams);
      await webKitController.setJavaScriptMode(JavaScriptMode.unrestricted);
      await webKitController.setBackgroundColor(Colors.white);
      await webKitController.setAllowsBackForwardNavigationGestures(true);
      controller = WebViewController.fromPlatform(webKitController);
    }

    await controller.setNavigationDelegate(
      NavigationDelegate(
        onNavigationRequest: (request) async {
          if (request.url.startsWith('tel:') || request.url.startsWith('mailto:')) {
            if (await canLaunchUrl(Uri.parse(request.url))) {
              await launchUrl(Uri.parse(request.url));
            }
            return NavigationDecision.prevent;
          }
          
          if (!allowHttp && request.url.startsWith('http://')) {
            final allow = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Unsecure Website'),
                content: Text('This website is not secure. Do you want to proceed?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text('Proceed'),
                  ),
                ],
              ),
            ) ?? false;
            
            if (!allow) {
              return NavigationDecision.prevent;
            }
          }
          
          return NavigationDecision.navigate;
        },
        onPageStarted: (url) {
          setState(() {
            isLoading = true;
            displayUrl = url;
            isSecure = url.startsWith('https://');
          });
        },
        onPageFinished: (url) async {
          final title = await controller.getTitle() ?? 'New Tab';
          final faviconUrl = await BrowserUtils.getFaviconUrl(url);
          
          setState(() {
            isLoading = false;
            displayUrl = url;
            isSecure = url.startsWith('https://');
          });
          
          controller.canGoBack().then((value) => setState(() => canGoBack = value));
          controller.canGoForward().then((value) => setState(() => canGoForward = value));
          
          _saveToHistory(url, title);
        },
      ),
    );

    await controller.loadRequest(Uri.parse('https://www.google.com'));
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
    final items = <Widget>[
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: _buildSettingsItem(
          title: AppLocalizations.of(context)!.search_engine,
          subtitle: currentSearchEngine.toUpperCase(),
          onTap: () => _showSearchEngineSelection(context),
        ),
      ),
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: _buildSettingsItem(
          title: AppLocalizations.of(context)!.language,
          subtitle: Localizations.localeOf(context).languageCode.toUpperCase(),
          onTap: () => _showLanguageSelection(context),
        ),
      ),
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: _buildSettingsItem(
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
      ),
    ];

    _showDynamicBottomSheet(
      items: items,
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
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                itemBuilder: (context, index) => items[index],
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
    final items = <Widget>[
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: _buildSettingsItem(
          title: AppLocalizations.of(context)!.download_location,
          subtitle: '/Downloads',
          onTap: () {},
        ),
      ),
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: _buildSettingsItem(
          title: AppLocalizations.of(context)!.ask_download_location,
          trailing: Switch(
            value: true,
            onChanged: (value) {},
          ),
        ),
      ),
    ];

    _showDynamicBottomSheet(
      items: items,
      title: AppLocalizations.of(context)!.downloads,
    );
  }

  void _showAppearanceSettings() {
    final items = <Widget>[
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: _buildSettingsItem(
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
      ),
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: _buildSettingsItem(
          title: AppLocalizations.of(context)!.text_size,
          subtitle: 'Medium',
          onTap: () {},
        ),
      ),
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: _buildSettingsItem(
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
      ),
    ];

    _showDynamicBottomSheet(
      items: items,
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
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              decoration: _getGlassmorphicDecoration(),
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
                              const SizedBox(height: 4),
                              Text(
                                'Licensed under GPL 3.0',
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
          ),
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
    _animationController.dispose();
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).padding;
    
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Positioned(
            top: padding.top,
            left: 0,
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onHorizontalDragStart: (details) {
                dragStartX = details.localPosition.dx;
              },
              onHorizontalDragUpdate: (details) {
                final delta = details.localPosition.dx - dragStartX;
                if (delta.abs() > 50) {
                  if (delta > 0 && canGoBack) {
                    controller.goBack();
                    dragStartX = details.localPosition.dx;
                  } else if (delta < 0 && canGoForward) {
                    controller.goForward();
                    dragStartX = details.localPosition.dx;
                  }
                }
              },
              child: WebViewWidget(controller: controller),
            ),
          ),
          if (isLoading)
            Positioned(
              top: padding.top,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(),
            ),
          if (!isTabsVisible && !isHistoryVisible && !isSettingsVisible)
            Positioned(
              left: 16,
              right: 16,
              bottom: padding.bottom + 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isPanelExpanded) ...[
                    _buildQuickActionsPanel(),
                    _buildNavigationPanel(),
                  ],
                  if (isSearchMode)
                    _buildSearchPanel()
                  else
                    _buildUrlPanel(),
                ],
              ),
            ),
          if (isTabsVisible || isHistoryVisible || isSettingsVisible)
            GestureDetector(
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
                margin: EdgeInsets.only(top: padding.top),
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 200),
                  offset: isTabsVisible || isHistoryVisible || isSettingsVisible ? Offset.zero : const Offset(0, 1),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
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
            ),
        ],
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
                      isHistoryVisible = false;
                    });
                  },
                ),
                Text(
                  AppLocalizations.of(context)!.history,
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
            child: ListView.builder(
              itemCount: downloads.length,
              itemBuilder: (context, index) {
                final download = downloads[index];
                return ListTile(
                  title: Text(
                    download['title'] as String? ?? download['url'] as String,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  subtitle: Text(
                    DateTime.parse(download['timestamp'] as String).toLocal().toString(),
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  onTap: () {
                    controller.loadRequest(Uri.parse(download['url'] as String));
                    setState(() {
                      isHistoryVisible = false;
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsPanel() {
    return Container(
      height: MediaQuery.of(context).size.height,
      color: isDarkMode ? Colors.black : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPanelHeader(AppLocalizations.of(context)!.settings, onBack: () {
            setState(() {
              isSettingsVisible = false;
            });
          }),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 24, bottom: 8),
                            child: Text(
                              AppLocalizations.of(context)!.customize_browser,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDarkMode ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                _buildSettingsButton('general', () => _showGeneralSettings(), isFirst: true),
                                _buildDivider(),
                                _buildSettingsButton('downloads', () => _showDownloadsSettings()),
                                _buildDivider(),
                                _buildSettingsButton('appearance', () => _showAppearanceSettings(), isLast: true),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 24, bottom: 8),
                            child: Text(
                              AppLocalizations.of(context)!.learn_more,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDarkMode ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                _buildSettingsButton('help', () => _showHelpPage(), isFirst: true),
                                _buildDivider(),
                                _buildSettingsButton('rate_us', () => _showRateUs()),
                                _buildDivider(),
                                _buildSettingsButton('privacy_policy', () => _showPrivacyPolicy()),
                                _buildDivider(),
                                _buildSettingsButton('terms_of_use', () => _showTermsOfUse()),
                                _buildDivider(),
                                _buildSettingsButton('about', () => _showAboutPage(), isLast: true),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(
                    left: 16, 
                    right: 16,
                    bottom: MediaQuery.of(context).padding.bottom + 16,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      onTap: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.remove('history');
                        setState(() {
                          downloads = [];
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Text(
                              'Clear History',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
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

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.vertical(
            top: isFirst ? Radius.circular(12) : Radius.zero,
            bottom: isLast ? Radius.circular(12) : Radius.zero,
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

  Widget _buildDivider() {
    return Container(
      height: 1,
      color: isDarkMode ? Colors.white12 : Colors.black12,
      margin: const EdgeInsets.only(left: 16),
    );
  }

  Widget _buildUrlPanel() {
    return GestureDetector(
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
        if (delta.abs() > 50) {
          if (delta > 0 && canGoBack) {
            controller.goBack();
            dragStartX = details.localPosition.dx;
          } else if (delta < 0 && canGoForward) {
            controller.goForward();
            dragStartX = details.localPosition.dx;
          }
        }
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
                  Image.asset(
                    isSecure ? 'assets/secure24.png' : 'assets/unsecure24.png',
                    width: 24,
                    height: 24,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                  Expanded(
                    child: !isUrlBarExpanded
                      ? GestureDetector(
                          onTap: () async {
                            final currentUrl = await controller.currentUrl() ?? displayUrl;
                            setState(() {
                              isUrlBarExpanded = true;
                              urlController.text = currentUrl;
                            });
                          },
                          child: Center(
                            child: Text(
                              _getDisplayUrl(displayUrl),
                              style: TextStyle(
                                color: isDarkMode ? Colors.white : Colors.black,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                      : TextField(
                          controller: urlController,
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            hintText: 'Search or enter address',
                            hintStyle: TextStyle(
                              color: isDarkMode ? Colors.white70 : Colors.black54,
                            ),
                            border: InputBorder.none,
                          ),
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black,
                            fontSize: 16,
                          ),
                          onSubmitted: (_) {
                            _loadUrl();
                            setState(() {
                              isUrlBarExpanded = false;
                            });
                          },
                          autofocus: true,
                        ),
                  ),
                  IconButton(
                    icon: isUrlBarExpanded 
                      ? Icon(
                          Icons.close,
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                        )
                      : Image.asset(
                          'assets/reload24.png',
                          width: 24,
                          height: 24,
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                    onPressed: () {
                      if (isUrlBarExpanded) {
                        setState(() {
                          isUrlBarExpanded = false;
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

  Future<void> _createNewTab() async {
    if (Platform.isAndroid) {
      final androidParams = AndroidWebViewControllerCreationParams();
      final androidController = AndroidWebViewController(androidParams);
      await androidController.setJavaScriptMode(JavaScriptMode.unrestricted);
      await androidController.setBackgroundColor(Colors.white);
      controller = WebViewController.fromPlatform(androidController);
    } else if (Platform.isIOS) {
      final webKitParams = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
      );
      final webKitController = WebKitWebViewController(webKitParams);
      await webKitController.setJavaScriptMode(JavaScriptMode.unrestricted);
      await webKitController.setBackgroundColor(Colors.white);
      await webKitController.setAllowsBackForwardNavigationGestures(true);
      controller = WebViewController.fromPlatform(webKitController);
    }

    await controller.setNavigationDelegate(
      NavigationDelegate(
        onPageStarted: (url) {
          setState(() {
            isLoading = true;
            displayUrl = url;
            isSecure = url.startsWith('https://');
          });
        },
        onPageFinished: (url) async {
          setState(() {
            isLoading = false;
            displayUrl = url;
            isSecure = url.startsWith('https://');
          });
          controller.canGoBack().then((value) => setState(() => canGoBack = value));
          controller.canGoForward().then((value) => setState(() => canGoForward = value));
        },
      ),
    );

    await controller.loadRequest(Uri.parse('https://www.google.com'));
  }

  void _switchTab(int index) {
    if (index >= 0 && index < tabs.length) {
      setState(() {
        currentTabIndex = index;
        controller = tabs[index].controller;
        displayUrl = tabs[index].url;
        isSecure = tabs[index].url.startsWith('https://');
      });
    }
  }

  void _closeTab(int index) {
    if (tabs.length > 1) {
      setState(() {
        tabs.removeAt(index);
        if (currentTabIndex >= tabs.length) {
          currentTabIndex = tabs.length - 1;
        }
        controller = tabs[currentTabIndex].controller;
        displayUrl = tabs[currentTabIndex].url;
        isSecure = tabs[currentTabIndex].url.startsWith('https://');
      });
    }
  }
} 