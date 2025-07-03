import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart' as webview_flutter_android;
import 'package:webview_flutter_android/webview_flutter_android.dart' show FileSelectorParams;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';
import '../l10n/app_localizations.dart';
import '../models/tab_group.dart';
import '../utils/browser_utils.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import '../utils/optimization_engine.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../widgets/custom_dialog.dart';
import '../widgets/custom_notification.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:solar/theme/theme_manager.dart';
import 'package:solar/services/notification_service.dart';
import 'package:solar/services/ai_manager.dart';
import 'package:solar/services/pwa_manager.dart';
import 'package:solar/screens/pwa_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../firebase_options.dart';

class Debouncer {
  final int milliseconds;
  Timer? _timer;

  Debouncer({required this.milliseconds});  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
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

// <----LOADING ANIMATION---->
class LoadingBorderPainter extends CustomPainter {
  final double progress;
  final Color color;

  LoadingBorderPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height), 
      const Radius.circular(24)
    );
    final borderPath = Path()..addRRect(rect);
    
    final pathMetric = borderPath.computeMetrics().first;
    final totalLength = pathMetric.length;
    
    final snakeLength = totalLength * 0.12;
    final currentPosition = (progress * totalLength) % totalLength;
    
    Path snakePath;
    if (currentPosition + snakeLength <= totalLength) {
      snakePath = pathMetric.extractPath(currentPosition, currentPosition + snakeLength);
    } else {
      final firstPart = pathMetric.extractPath(currentPosition, totalLength);
      final secondPartLength = snakeLength - (totalLength - currentPosition);
      final secondPart = pathMetric.extractPath(0, secondPartLength);
      
      snakePath = Path()
        ..addPath(firstPart, Offset.zero)
        ..addPath(secondPart, Offset.zero);
    }
    
    final gradientPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          color.withOpacity(0.2),
          color.withOpacity(0.6),
          color,
        ],
        stops: const [0.0, 0.7, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    
    canvas.drawPath(snakePath, gradientPaint);
    
    final headPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;
    
    final headLength = snakeLength * 0.15;
    final headPosition = (currentPosition + snakeLength - headLength) % totalLength;
    
    Path headPath;
    if (headPosition + headLength <= totalLength) {
      headPath = pathMetric.extractPath(headPosition, headPosition + headLength);
    } else {
      final firstPart = pathMetric.extractPath(headPosition, totalLength);
      final secondPartLength = headLength - (totalLength - headPosition);
      final secondPart = pathMetric.extractPath(0, secondPartLength);
      
      headPath = Path()
        ..addPath(firstPart, Offset.zero)
        ..addPath(secondPart, Offset.zero);
    }
    
    canvas.drawPath(headPath, headPaint);
  }

  @override
  bool shouldRepaint(LoadingBorderPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _BrowserScreenState extends State<BrowserScreen> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  // <----WEBVIEW AND NAVIGATION---->
  final List<WebViewController> _controllers = [];
  late WebViewController controller;
  int currentTabIndex = 0;
  final List<Map<String, dynamic>> _suspendedTabs = [];
  static const int _maxActiveTabs = 5;
  List<Map<String, dynamic>> tabs = [];
  bool canGoBack = false;
  bool canGoForward = false;
  bool isSecure = false;
  bool allowHttp = true;
  bool isLoading = false;
  String? _currentFaviconUrl;
  
  // <----PLATFORM COMMUNICATION---->
  final MethodChannel _platform = const MethodChannel('com.solar.browser/shortcuts');
  
  // <----INTENT HANDLING---->
  String? _lastProcessedIntentUrl;
  bool _isLoadingIntentUrl = false;

  // <----URL BAR ANIMATION---->
  late AnimationController _hideUrlBarController;
  late Animation<Offset> _hideUrlBarAnimation;
  bool _hideUrlBar = false;
  double _lastScrollPosition = 0;
  bool _isScrollingUp = false;
  bool _isUpdatingState = false;
  
  // <----DOWNLOAD STATE---->
  bool isDownloading = false;
  String currentDownloadUrl = '';
  double downloadProgress = 0.0;
  String? _currentFileName;
  int? _currentDownloadSize;
  List<Map<String, dynamic>> downloads = [];

  // <----PERMISSION CACHING---->
  bool? _cachedPermissionState;
  DateTime? _lastPermissionCheck;
  static const Duration _permissionCacheTimeout = Duration(seconds: 30);

  // <----GETTERS---->
  String? get currentFileName => _currentFileName;
  int? get currentDownloadSize => _currentDownloadSize;
  
  // <----CONTROLLERS---->
  late TextEditingController _urlController;
  late FocusNode _urlFocusNode;
  
  // <----FIREBASE CLOUD FUNCTIONS---->
  FirebaseFunctions? _firebaseFunctions;
  
  // <----NEWS CACHING---->
  static List<Map<String, dynamic>>? _cachedArticles;
  static int? _cachedLanguage;
  static Map<String, String> _cachedCoverImages = {};

  // <----UI STATE---->
  bool isDarkMode = false;  // <----ADDITIONAL STATE VARIABLES---->
  bool isSearchMode = false;
  String _displayUrl = '';
  bool _isUrlBarExpanded = false;
  bool isSecurityPanelVisible = false;
  bool _isClassicMode = false;
  bool _keepTabsOpen = false;
  String securityMessage = '';
  DateTime lastScrollEvent = DateTime.now();
  int currentSearchMatch = 0;
  int totalSearchMatches = 0;
  Timer? _hideTimer;
  bool _isUrlBarMinimized = false;
  bool _isUrlBarHidden = false;
  int selectedSettingsTab = 0;

  // <----PANEL VISIBILITY---->
  bool isTabsVisible = false;
  bool isSettingsVisible = false;
  bool isBookmarksVisible = false;
  bool isDownloadsVisible = false;  bool isHistoryVisible = false;
  bool isPanelExpanded = false;
  bool isPanelVisible = true;
  bool _isLoading = false;
    // <----INCOGNITO MODE---->
  bool _isIncognitoModeActive = false;
  
  // <----HISTORY ENCRYPTION---->
  bool _isHistoryLocked = false;
  bool _isHistoryEncrypted = false;
  String? _historyPassword;
  bool _showHistoryPasswordSetup = true;
  
  // <----URL BAR STATE---->
  bool _isUrlBarCollapsed = false;
  bool _isDragging = false;
  Offset _urlBarPosition = Offset.zero;
  Timer? _autoCollapseTimer;
  double dragStartX = 0;
  Timer? _loadingTimer;
  
  // <----DEVELOPER OPTIONS---->
  bool _isDeveloperMode = false;
  int _developerModeClickCount = 0;
  bool _showDeveloperOptions = false;
  String _debugLog = '';
  Timer? _developerModeTimer;
  
  // <----HOME PAGE SETTINGS---->
  String _homeUrl = 'file:///android_asset/main.html';
  String _searchEngine = 'Google';
  bool _syncHomePageSearchEngine = true;
  String _homePageSearchEngine = 'Google';
  List<Map<String, String>> _homePageShortcuts = [];
  
  // <----HISTORY LOADING---->
  final ScrollController _historyScrollController = ScrollController();
  bool _isLoadingMore = false;
  int _currentHistoryPage = 0;
  final int _historyPageSize = 20;
  List<Map<String, dynamic>> _loadedHistory = [];

  // <----ANIMATION CONTROLLERS---->
  late final AnimationController _slideAnimationController;
  late final Animation<Offset> _slideAnimation;
  late AnimationController _animationController;
  late Animation<double> _animation;
  late AnimationController _slideUpController;
  late AnimationController _panelSlideController;
  late Animation<Offset> _panelSlideAnimation;
  late Animation<Offset> _panelSlideOutAnimation;
  bool _isPanelClosing = false;

  // <----DATA---->
  List<Map<String, dynamic>> bookmarks = [];
  double textScale = 1.0;
  bool showImages = true;
  String currentLanguage = 'en';
  String currentSearchEngine = 'Google';
  String customHomeUrl = ''; // Custom home page URL
  bool useCustomHomePage = false; // Whether to use custom home page
  
  // <----TAB GROUPING---->
  List<TabGroup> _tabGroups = [];
  // <----NAVIGATION BAR CUSTOMIZATION---->
  List<String> _customNavButtons = ['back', 'forward', 'bookmark', 'share', 'menu'];
  bool _navBarAnimationEnabled = true;
  
  // <----AI ACTION BAR---->
  bool _isAiActionBarVisible = false;
  late AnimationController _aiActionBarController;
  late Animation<double> _aiActionBarAnimation;
  late Animation<double> _aiActionBarHeightAnimation;
  
    // Simple border animation for URL bar (summary panel removed)
  late Animation<BorderRadius> _urlBarBorderAnimation;
  
  // Summary panel permanently disabled
  bool _isSummaryPanelVisible = false;
  
  // <----MEMORY MANAGEMENT---->
  final _debouncer = Debouncer(milliseconds: 100);
  final _scrollThrottle = Debouncer(milliseconds: 16);
  bool _isLowMemory = false;
  int _lastMemoryCheck = 0;
  static const int MEMORY_CHECK_INTERVAL = 30000;

  // <----CONTEXT MENU TIMER---->
  Timer? _contextMenuTimer;
  Map<String, dynamic>? _pendingContextData;
  bool _touchMoved = false;
  DateTime? _touchStartTime;
  bool _longPressTriggered = false;

// --- CONTEXT MENU TIMER LOGIC REWRITE ---
// Handles long-press detection for image/text context menu
void _handleTouchStart(Map<String, dynamic> data) {
  if (!mounted) return;
  
  print('🔍 _handleTouchStart called with data type: ${data['type']}');
  
  final type = data['type'] as String;
    if (type == 'image_touch_start') {
    print('📸 Showing image context menu immediately');
    // Show image context menu without any delay or conditions
    _showImageContextMenu(data);
  }
  
  // For text selection, we don't need to do anything special
  // The native text selection will work automatically
}

  // Variables for long press detection
  Offset? _pointerDownPosition;
  DateTime? _pointerDownTime;
  bool _isPointerMoved = false;
  Timer? _longPressTimer;
  
  // Check if there's an image or text at the given position and handle accordingly
  Future<void> _checkForImageAtPosition(Offset position) async {
    try {
      // Convert position to web coordinates
      final x = position.dx;
      final y = position.dy;
      
      print('🔍 Checking for content at position ($x, $y)');
      
      // Add haptic feedback for better user experience
      HapticFeedback.mediumImpact();
      
      // Get the element at this position and handle it directly
      final result = await controller.runJavaScriptReturningResult('''
        (function() {
          try {
            console.log('🔍 Checking for elements at position ($x, $y)');
            
            // Try to find any element at this position
            let element = document.elementFromPoint($x, $y);
            if (!element) {
              console.log('🔍 No element found at position');
              return JSON.stringify({"found": false});
            }
            
            console.log('🔍 Found element: ' + element.tagName);
            
            // Determine if this is text or an image
            // First check if we're dealing with an image
            let img = null;
            let parentLink = null;
            let isTextElement = false;
            
            // Check if the element is a text node or contains primarily text
            const tagName = element.tagName.toLowerCase();
            const textTags = ['p', 'span', 'div', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'li', 'td', 'th', 'a', 'label', 'button'];
            
            if (textTags.includes(tagName) && element.innerText && element.innerText.trim().length > 0) {
              // This is likely a text element
              isTextElement = true;
              
              // Check if it's inside a link
              let parent = element;
              while (parent) {
                if (parent.tagName === 'A') {
                  parentLink = parent.href;
                  break;
                }
                parent = parent.parentElement;
              }
            }
            
            // First check if the element itself is an image (only if not already identified as text)
            if (!isTextElement && element.tagName === 'IMG') {
              img = element;
              // Check if image is inside a link
              let parent = element.parentElement;
              while (parent && !parentLink) {
                if (parent.tagName === 'A') {
                  parentLink = parent.href;
                  break;
                }
                parent = parent.parentElement;
              }
            }
            
            // If not text or image yet, check if any of its parents or children are images
            if (!isTextElement && !img) {
              // Check parents (for cases where the image might be wrapped in a link or div)
              let parent = element.parentElement;
              for (let i = 0; i < 3 && parent; i++) { // Check up to 3 levels up
                if (parent.tagName === 'IMG') {
                  img = parent;
                  break;
                }
                const childImg = parent.querySelector('img');
                if (childImg) {
                  img = childImg;
                  break;
                }
                parent = parent.parentElement;
              }
              
              // Check children
              if (!img) {
                const childImg = element.querySelector('img');
                if (childImg) {
                  img = childImg;
                }
              }
              
              // If we found an image, check if it's in a link
              if (img) {
                let parent = img.parentElement;
                while (parent && !parentLink) {
                  if (parent.tagName === 'A') {
                    parentLink = parent.href;
                    break;
                  }
                  parent = parent.parentElement;
                }
              }
            }
            
            // If we found an image, return its data
            if (img) {
              console.log('🖼️ Found image: ' + img.src);
              return JSON.stringify({
                "found": true,
                "type": "image",
                "src": img.src,
                "alt": img.alt || "",
                "width": img.naturalWidth || img.width,
                "height": img.naturalHeight || img.height,
                "linkUrl": parentLink || null
              });
            }
            
            // If we identified this as a text element, handle text selection
            if (isTextElement) {
              console.log('📝 Found text element, selecting text');
            
            // Try to enable text selection mode
            const range = document.createRange();
            const selection = window.getSelection();
            
            try {
              // Try to select all text in the element
              range.selectNodeContents(element);
              selection.removeAllRanges();
              selection.addRange(range);
              
              const selectedText = selection.toString();
              console.log('📝 Selected text: ' + selectedText);
              
              if (selectedText && selectedText.trim().length > 0) {
                return JSON.stringify({
                  "found": true,
                  "type": "text",
                  "text": selectedText,
                  "linkUrl": parentLink || null
                });
              }
            } catch (e) {
              console.error('Error selecting text: ' + e);
            }
            }
            
            return JSON.stringify({"found": false});
          } catch (e) {
            console.error('Error in element detection: ' + e);
            return JSON.stringify({"error": e.toString()});
          }
        })();
      ''');
      
      // Parse the result
      try {
        final String resultString = result.toString();
        print('🔍 Raw result from JavaScript: $resultString');
        
        // Handle potential string results that aren't valid JSON
        if (resultString == "null" || resultString.isEmpty) {
          print('❌ Empty or null result from JavaScript');
          return;
        }
        
        // Remove any quotes that might be wrapping the JSON string
        String jsonString = resultString;
        if (jsonString.startsWith('"') && jsonString.endsWith('"')) {
          jsonString = jsonString.substring(1, jsonString.length - 1);
          // Unescape any escaped quotes
          jsonString = jsonString.replaceAll('\\"', '"');
        }
        
        final Map<String, dynamic> data = json.decode(jsonString);
        
        if (data['found'] == true) {
          if (data['type'] == 'image') {
            print('🖼️ Found image: ${data['src']}');
            _showImageContextMenu(data);
          } else if (data['type'] == 'text') {
            print('📝 Selected text: ${data['text']}');
            // Text is already selected in the WebView, no need to do anything else
            
            // If the text is inside a link, we could show a special context menu here
            if (data['linkUrl'] != null) {
              print('🔗 Text is inside a link: ${data['linkUrl']}');
              // For now we'll let the default text selection handle this
            }
          }
        } else {
          print('❌ No content found at position');
        }
      } catch (e) {
        print('❌ Error parsing JavaScript result: $e');
      }
    } catch (e) {
      print('❌ Error checking for content at position: $e');
    }
  }

  // These methods are kept for compatibility 
void _handleTouchMoved() {
    print('📱 Touch moved event received');
}

void _handleTouchEnd() {
    print('📱 Touch end event received');
  }
  
  // Test method to manually trigger the image context menu
  Future<void> _testImageContextMenu() async {
    print('🧪 Testing image context menu manually');
    try {
      await controller.runJavaScript('''
        if (typeof showImageContextMenu === 'function') {
          showImageContextMenu('https://example.com/test-image.jpg');
          console.log('🧪 Test image context menu triggered');
        } else {
          console.error('🧪 showImageContextMenu function not found');
        }
      ''');
    } catch (e) {
      print('🧪 Error testing image context menu: $e');
    }
  }
  // Text selection is handled by the native system
  // No custom text context menu is needed

  bool isInitialized = false;

  // <----DOWNLOAD SETTINGS---->
  bool _askDownloadLocation = false;
  bool _autoOpenDownloads = false;
  late OptimizationEngine _optimizationEngine;
  late Animation<double> _loadingAnimation;
  Timer? _urlBarIdleTimer;
  Timer? _urlSyncTimer; // Timer for periodic URL sync
  bool _isFullscreen = false;
  late AnimationController _loadingAnimationController;
    // Smooth scrolling controller
  final ScrollController _smoothScrollController = ScrollController();
  
  // Optimization flags
  bool _isOptimizingPerformance = false;
  
  // Animation durations and curves for dropdowns
  final Duration _dropdownDuration = const Duration(milliseconds: 200);
  final Curve _dropdownCurve = Curves.easeOutCubic;
  
  // Smooth transition controller
  late final AnimationController _transitionController = AnimationController(
    duration: const Duration(milliseconds: 300),
    vsync: this,
  );
  
  // Transition animations
  late final Animation<double> _fadeTransition = CurvedAnimation(
    parent: _transitionController,
    curve: Curves.easeInOut,
  );

  // Slide transition animation
  late final Animation<Offset> _slideTransition = Tween<Offset>(
    begin: const Offset(0, 0.1),
    end: Offset.zero,
  ).animate(CurvedAnimation(
    parent: _transitionController,
    curve: Curves.easeOutCubic,
  ));
  
  bool mounted = true;

  // <----URL BAR DRAGGING---->
  Offset _urlBarOffset = const Offset(0.0, 0.0);
  bool _isDraggingUrlBar = false;
  
  // <----THEME COLORS---->
  ThemeColors? _cachedDarkColors;
  ThemeColors? _cachedLightColors;
  
  ThemeColors get _colors {
    if (isDarkMode) {
      return _cachedDarkColors ??= ThemeColors(
        background: ThemeManager.backgroundColor(),
        surface: ThemeManager.surfaceColor(),
        text: ThemeManager.textColor(),
        textSecondary: ThemeManager.textSecondaryColor(),
        border: ThemeManager.textColor().withOpacity(0.24),
      );
    } else {
      return _cachedLightColors ??= ThemeColors(
        background: ThemeManager.backgroundColor(),
        surface: ThemeManager.surfaceColor(),
        text: ThemeManager.textColor(),
        textSecondary: ThemeManager.textSecondaryColor(),
        border: ThemeManager.textColor().withValues(alpha: 0.12),
      );
    }
  }  // <----SEARCH ENGINES---->
  final Map<String, String> searchEngines = {
    'Google': 'https://www.google.com/search?q={query}',
    'Bing': 'https://www.bing.com/search?q={query}',
    'DuckDuckGo': 'https://duckduckgo.com/?q={query}',
    'Brave': 'https://search.brave.com/search?q={query}',
    'Yahoo': 'https://search.yahoo.com/search?p={query}',
    'Yandex': 'https://yandex.com/search/?text={query}',
    'Solar Search': 'https://search.browser.solar/search?q={query}',
  };
  // <----TAB PERSISTENCE METHODS---->
  Future<void> _saveTabs() async {
    try {
      final keepTabsOpen = await _getKeepTabsOpenSetting();
      if (!keepTabsOpen) return;

      final prefs = await SharedPreferences.getInstance();
      
      final tabsData = tabs
          .where((tab) => !tab['isIncognito'])
          .map((tab) => {
                'id': tab['id'],
                'url': tab['url'],
                'title': tab['title'],
                'favicon': tab['favicon'],
                'groupId': tab['groupId'],
              })
          .toList();

      await prefs.setString('saved_tabs', json.encode({
        'tabs': tabsData,
        'currentTabIndex': currentTabIndex < tabs.length ? currentTabIndex : 0,
        'savedAt': DateTime.now().toIso8601String(),
      }));
      
      print('Saved ${tabsData.length} tabs to preferences');
    } catch (e) {
      print('Error saving tabs: $e');
    }
  }
  Future<void> _loadSavedTabs() async {
    try {
      final keepTabsOpen = await _getKeepTabsOpenSetting();
      if (!keepTabsOpen) return;

      final prefs = await SharedPreferences.getInstance();
      final savedTabsJson = prefs.getString('saved_tabs');
      
      if (savedTabsJson == null || savedTabsJson.isEmpty) return;

      final savedData = json.decode(savedTabsJson) as Map<String, dynamic>;
      final tabsData = savedData['tabs'] as List<dynamic>?;
      final savedCurrentTabIndex = savedData['currentTabIndex'] as int? ?? 0;
      
      if (tabsData == null || tabsData.isEmpty) return;

      setState(() {
        tabs.clear();
      });

      for (int i = 0; i < tabsData.length; i++) {
        final tabData = tabsData[i] as Map<String, dynamic>;
        final restoredTab = {
          'id': tabData['id'] as String,
          'url': tabData['url'] as String,
          'title': tabData['title'] as String? ?? AppLocalizations.of(context)!.restored_tab,
          'favicon': tabData['favicon'] as String?,
          'groupId': tabData['groupId'] as String?,
          'controller': WebViewController(),
          'isIncognito': false,
          'canGoBack': false,
          'canGoForward': false,
          'lastActiveTime': DateTime.now(),        };
          _initializeTab(restoredTab).then((_) {
          // <----URL RESTORATION---->
          // Load the saved URL into the WebViewController AFTER initialization
          final savedUrl = restoredTab['url'] as String;
          if (savedUrl.isNotEmpty && savedUrl != 'about:blank') {
            final webController = restoredTab['controller'] as WebViewController;
            webController.loadRequest(Uri.parse(savedUrl));
            print('Restored tab with URL: $savedUrl');
            
            // Send theme to main.html if it's the home page
            if (savedUrl == _homeUrl || savedUrl.contains('main.html')) {
              Future.delayed(const Duration(milliseconds: 500), () {
                _sendThemeToMainHtml();
              });
            }
          }
        });
        
        tabs.add(restoredTab);
      }

      setState(() {
        currentTabIndex = savedCurrentTabIndex.clamp(0, tabs.length - 1);
        if (tabs.isNotEmpty) {
          controller = tabs[currentTabIndex]['controller'];
          _displayUrl = tabs[currentTabIndex]['url'];
          _urlController.text = _formatUrl(tabs[currentTabIndex]['url']);
          isSecure = _isSecureUrl(tabs[currentTabIndex]['url']);
        }
      });

      print('Restored ${tabs.length} tabs from preferences');
      
      await prefs.remove('saved_tabs');
    } catch (e) {
      print('Error loading saved tabs: $e');
      if (tabs.isEmpty) {
        _addNewTab();
      }
    }
  }
  // <----LOADING TIMER MANAGEMENT---->
  Timer? _loadingTimeoutTimer;

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(2)} ${suffixes[i]}';
  }
  
  // Helper method to parse data URLs (base64)
  Map<String, dynamic> _parseDataUrl(String dataUrl) {
    try {
      // Format: data:[<mediatype>][;base64],<data>
      final parts = dataUrl.split(',');
      if (parts.length < 2) {
        return {'mimeType': 'application/octet-stream', 'bytes': <int>[]};
      }
      
      final metadata = parts[0];
      final data = parts[1];
      
      // Extract mime type
      final mimeType = metadata.contains(':') 
          ? metadata.split(':')[1].split(';')[0] 
          : 'application/octet-stream';
      
      // Decode base64 data
      List<int> bytes;
      if (metadata.contains(';base64')) {
        bytes = base64Decode(data);
      } else {
        // Handle URL encoded data
        bytes = utf8.encode(Uri.decodeFull(data));
      }
      
      return {
        'mimeType': mimeType,
        'bytes': bytes,
      };
    } catch (e) {
      print('Error parsing data URL: $e');
      return {'mimeType': 'application/octet-stream', 'bytes': <int>[]};
    }
  }
  
  // Helper method to get file extension from data URL
  String _getExtensionFromDataUrl(String dataUrl) {
    try {
      // Extract mime type from data URL
      final parts = dataUrl.split(',');
      if (parts.isEmpty) return '.jpg'; // Default to jpg
      
      final metadata = parts[0];
      final mimeTypePart = metadata.contains(':') ? metadata.split(':')[1].split(';')[0] : '';
      
      // Map mime type to extension
      switch (mimeTypePart) {
        case 'image/jpeg': return '.jpg';
        case 'image/png': return '.png';
        case 'image/gif': return '.gif';
        case 'image/webp': return '.webp';
        case 'image/svg+xml': return '.svg';
        case 'image/bmp': return '.bmp';
        case 'image/tiff': return '.tiff';
        case 'application/pdf': return '.pdf';
        case 'text/plain': return '.txt';
        case 'text/html': return '.html';
        case 'text/css': return '.css';
        case 'text/javascript': return '.js';
        case 'audio/mpeg': return '.mp3';
        case 'audio/wav': return '.wav';
        case 'video/mp4': return '.mp4';
        case 'video/webm': return '.webm';
        default:
          // If it contains image/ but not recognized above, default to jpg
          if (mimeTypePart.startsWith('image/')) return '.jpg';
          return '.bin'; // Default for unknown types
      }
    } catch (e) {
      print('Error getting extension from data URL: $e');
      return '.jpg'; // Default fallback
    }
  }

  void _updateState(VoidCallback update) {
    if (mounted && !_isUpdating) {
      _isUpdating = true;
      _debouncer.run(() {
        if (mounted) {
          setState(update);
          _isUpdating = false;
        }
      });
    }
  }
  
  bool _isUpdating = false;  // <----LOADING STATE MANAGEMENT---->
  void _setLoadingState(bool loading) {
    if (!mounted) return;
    
    setState(() {
      isLoading = loading;
    });

    _loadingTimeoutTimer?.cancel();
    
    if (loading) {
      // Start the loading animation
      _loadingAnimationController.reset();
      _loadingAnimationController.repeat();
      
      // Set a more aggressive timeout for stuck loading states
      _loadingTimeoutTimer = Timer(const Duration(seconds: 15), () {
        if (mounted && isLoading) {
          print('⚠️ Loading timeout - forcing loading state to false');
          setState(() {
            isLoading = false;
          });
          _loadingAnimationController.stop();
        }
      });
    } else {
      // Ensure animation is stopped when loading finishes
      _loadingAnimationController.stop();
      _loadingAnimationController.reset();
    }
  }// <----GLASSMORPHIC DECORATION---->
  BoxDecoration? _cachedGlassDecoration;
  
  BoxDecoration _getGlassmorphicDecoration() {
    return _cachedGlassDecoration ??= BoxDecoration(
      color: ThemeManager.backgroundColor().withOpacity(0.7),
      borderRadius: BorderRadius.circular(28),
      border: Border.all(
        color: ThemeManager.textColor().withOpacity(0.2),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: ThemeManager.textColor().withOpacity(0.1),
          blurRadius: 20,
          spreadRadius: 2,
        ),
      ],
    );
  }
  // <----FIREBASE INITIALIZATION---->
  Future<void> _initializeFirebase() async {
    try {
      // Initialize Firebase if not already initialized
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      
      // Initialize Firebase Functions
      _firebaseFunctions = FirebaseFunctions.instance;
      
      print('✅ Firebase initialized successfully');
    } catch (e) {
      print('❌ Firebase initialization failed: $e');
      // Don't throw error - app should still work without Firebase
    }
  }
  
  @override
  void initState() {
    super.initState();
    
    print("BrowserScreen initState called");

    WidgetsBinding.instance.addObserver(this);
    
    _isClassicMode = widget.initialClassicMode;
    
    // Initialize Firebase Functions
    _initializeFirebase();
    
    _initializeControllers();

    // Initialize tabs (will be properly set after preferences are loaded)
    tabs = [{
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'url': 'file:///android_asset/main.html', // This will be updated after preferences are loaded
      'title': AppLocalizations.of(context)?.new_tab ?? 'New Tab',
      'controller': WebViewController(),
      'isIncognito': false,
      'canGoBack': false,
      'canGoForward': false,
      'favicon': null,
      'groupId': null,
      'lastActiveTime': DateTime.now(),
    }];
    
    _urlController = TextEditingController();
    _urlFocusNode = FocusNode();
    
    const platform = MethodChannel('app.channel.shared.data');
    platform.setMethodCallHandler((call) async {
      print("Received method call: ${call.method}");
      
      if (!mounted) {
        print("Widget not mounted, ignoring method call");
        return;
      }
      
      switch (call.method) {
        case 'loadUrl':
          try {
            final url = call.arguments as String;
            print("Received URL to load: $url");
            
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
            print("Received search query: $query");
            if (query != null && query.isNotEmpty) {
              final engine = searchEngines[currentSearchEngine] ?? searchEngines['Google']!;
              final searchUrl = engine.replaceAll('{query}', Uri.encodeComponent(query));
              print("Opening new tab with search URL: $searchUrl");
              _addNewTab(url: searchUrl);
            }
          } catch (e) {
            print("Error processing search query: $e");
          }
          break;
      }
    });
    
    _platform.setMethodCallHandler((call) async {
      if (call.method == 'openPwaDirectly') {
        final pwaUrl = call.arguments as String;
        await _openPwaDirectly(pwaUrl);
        return true;
      }
      return null;
    });

    _loadPreferences().then((_) {
      _loadBookmarks();
        Future.microtask(() => _loadDownloads());
      Future.microtask(() => _loadHistory());
      Future.microtask(() => _loadUrlBarPosition());
      Future.microtask(() => _loadSettings());
      Future.microtask(() => _loadSearchEngines());
      Future.microtask(() => _loadNavigationBarSettings());
      
      Future.microtask(() => _loadSavedTabs().then((_) {
        if (mounted) {
          setState(() {
            isInitialized = true;
            print("BrowserScreen initialization completed");
          });
        }
        
        _checkForSharedUrl();
      }));
    });

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _panelSlideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );    _panelSlideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _panelSlideController,
      curve: Curves.easeInOut,
    ));

    // Simple URL bar border animation (summary panel removed)
    _urlBarBorderAnimation = Tween<BorderRadius>(
      begin: BorderRadius.circular(24),
      end: BorderRadius.circular(24), // Keep it simple since summary panel is removed
    ).animate(const AlwaysStoppedAnimation(0.0));

    _loadingAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    
    _loadingAnimation = CurvedAnimation(
      parent: _loadingAnimationController,
      curve: Curves.linear,
    );
      _smoothScrollController.addListener(_handleScroll);
    
    _optimizationEngine = OptimizationEngine();
  }
  
  void _handleScroll() {
    _scrollThrottle.run(() {
      if (!mounted) return;
      
      final currentPosition = _smoothScrollController.position.pixels;
      final scrollDelta = currentPosition - _lastScrollPosition;
      
      if (scrollDelta.abs() > 2) {
        _lastScrollPosition = currentPosition;
        
        setState(() {
          _isScrollingUp = scrollDelta < 0;
          _hideUrlBar = !_isScrollingUp && currentPosition > 100;
        });
      }
    });
  }
  

  
    void _showImageContextMenu(Map<String, dynamic> imageData) {
    if (!mounted) return;
    
    print('📸 _showImageContextMenu called with data: $imageData');
    
    final imageUrl = imageData['src'] as String? ?? '';
    final imageAlt = imageData['alt'] as String? ?? '';
    final width = imageData['width'] as int? ?? 0;
    final height = imageData['height'] as int? ?? 0;
    final linkUrl = imageData['linkUrl'] as String?;
    
    print('📸 Image URL: $imageUrl, Alt: $imageAlt, Size: ${width}x${height}, Link: $linkUrl');
    
    if (imageUrl.isEmpty) {
      print('📸 Empty image URL, skipping context menu');
      return;
    }
    
    // Extract filename from URL for download
    String fileName = imageUrl.split('/').last.split('?').first;
    if (fileName.isEmpty || !fileName.contains('.')) {
      fileName = 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
    }
    
    // Show a modern, clean modal dialog with animation
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: ThemeManager.textColor().withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Container(); // This is a placeholder, actual content is in transitionBuilder
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );
        
        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(curvedAnimation),
          child: FadeTransition(
            opacity: animation,
            child: AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              backgroundColor: ThemeManager.backgroundColor(),
              elevation: 8,
              title: Text(
                AppLocalizations.of(context)!.image_options,
                style: TextStyle(
                  color: ThemeManager.textColor(),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Image preview (small)
                  Container(
                    height: 150,
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: ThemeManager.surfaceColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                  : null,
                              color: ThemeManager.primaryColor(),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          print('📸 Error loading image preview: $error');
                          return Center(
                            child: Icon(
                              Icons.image_not_supported,
                              color: ThemeManager.textSecondaryColor(),
                              size: 40,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  
                                      // Download Image button
                  ListTile(
                    leading: Icon(Icons.download, color: ThemeManager.primaryColor()),
                    title: Text(AppLocalizations.of(context)!.download_image, style: TextStyle(color: ThemeManager.textColor())),
                    onTap: () {
                      print('📸 Download image button tapped for: $imageUrl');
                      Navigator.pop(context);
                      
                      String filename;
                      
                      // Handle base64 images differently
                      if (imageUrl.startsWith('data:')) {
                        // For base64 images, get extension from mime type
                        final extension = _getExtensionFromDataUrl(imageUrl);
                        filename = 'image_${DateTime.now().millisecondsSinceEpoch}$extension';
                      } else {
                        // Extract proper filename with extension for regular URLs
                        filename = imageUrl.split('/').last.split('?').first;
                        if (!filename.contains('.') || filename.isEmpty) {
                          final extension = imageUrl.contains('.jpg') ? '.jpg' : 
                                          imageUrl.contains('.png') ? '.png' :
                                          imageUrl.contains('.gif') ? '.gif' :
                                          imageUrl.contains('.webp') ? '.webp' : '.jpg';
                          filename = 'image_${DateTime.now().millisecondsSinceEpoch}$extension';
                        }
                      }
                      
                      // Show download starting notification
                      _showCustomNotification(
                        icon: Icons.download_rounded,
                        title: AppLocalizations.of(context)!.download_started,
                        message: filename,
                        progress: 0.0,
                        isDownload: true
                      );
                      
                      // Start the download using the app's existing download system
                      setState(() {
                        isDownloading = true;
                        currentDownloadUrl = imageUrl;
                        _currentFileName = filename;
                        downloadProgress = 0.0;
                      });
                      
                      // Use the existing download method
                      _downloadFile(imageUrl, filename);
                    },
                  ),
                  
                  // Copy Image Link button
                  ListTile(
                    leading: Icon(Icons.link, color: ThemeManager.primaryColor()),
                    title: Text(AppLocalizations.of(context)!.copy_image_link, style: TextStyle(color: ThemeManager.textColor())),
                    onTap: () {
                      print('📸 Copy image link button tapped');
                      Clipboard.setData(ClipboardData(text: imageUrl));
                      Navigator.pop(context);
                      _showCustomNotification(
                        message: AppLocalizations.of(context)!.image_link_copied,
                        icon: Icons.link,
                        iconColor: ThemeManager.successColor(),
                        duration: const Duration(seconds: 2),
                      );
                    },
                  ),
                  
                  // Open in New Tab button
                  ListTile(
                    leading: Icon(Icons.open_in_new, color: ThemeManager.primaryColor()),
                    title: Text(AppLocalizations.of(context)!.open_image_in_new_tab, style: TextStyle(color: ThemeManager.textColor())),
                    onTap: () {
                      print('📸 Open in new tab button tapped');
                      Navigator.pop(context);
                      
                      // Create a new tab with the image URL
                      // For asset URLs, we need special handling
                      if (imageUrl.startsWith('file:///android_asset/')) {
                        // For asset files, we need to use the home URL
                        _addNewTab();
                      } else {
                        // For external URLs, make sure we have a proper URL
                        final fullUrl = imageUrl.startsWith('http') ? imageUrl : 'https://$imageUrl';
                        _addNewTab(url: fullUrl);
                      }
                    },
                  ),
                  
                  // If the image is inside a link, show option to open link
                  if (linkUrl != null && linkUrl.isNotEmpty)
                    ListTile(
                      leading: Icon(Icons.link_rounded, color: ThemeManager.primaryColor()),
                      title: Text(AppLocalizations.of(context)!.open_link, style: TextStyle(color: ThemeManager.textColor())),
                      onTap: () {
                        print('📸 Open link button tapped: $linkUrl');
                        Navigator.pop(context);
                        
                        // Load the link in the current tab
                        _loadUrl(linkUrl);
                      },
                    ),
                    
                  // If the image is inside a link, show option to open link in new tab
                  if (linkUrl != null && linkUrl.isNotEmpty)
                    ListTile(
                      leading: Icon(Icons.tab, color: ThemeManager.primaryColor()),
                      title: Text(AppLocalizations.of(context)!.open_link_in_new_tab, style: TextStyle(color: ThemeManager.textColor())),
                      onTap: () {
                        print('📸 Open link in new tab button tapped: $linkUrl');
                        Navigator.pop(context);
                        
                        // Create a new tab with the link URL
                        // For asset URLs, we need special handling
                        if (linkUrl.startsWith('file:///android_asset/')) {
                          // For asset files, we need to use the home URL
                          _addNewTab();
                        } else {
                          // For external URLs, make sure we have a proper URL
                          final fullUrl = linkUrl.startsWith('http') ? linkUrl : 'https://$linkUrl';
                          _addNewTab(url: fullUrl);
                        }
                      },
                    ),
                    
                  // If the image is inside a link, show option to copy link
                  if (linkUrl != null && linkUrl.isNotEmpty)
                    ListTile(
                      leading: Icon(Icons.content_copy, color: ThemeManager.primaryColor()),
                      title: Text(AppLocalizations.of(context)!.copy_link_address, style: TextStyle(color: ThemeManager.textColor())),
                      onTap: () {
                        print('📸 Copy link address button tapped');
                        Clipboard.setData(ClipboardData(text: linkUrl));
                        Navigator.pop(context);
                        _showCustomNotification(
                                                  message: AppLocalizations.of(context)!.link_copied,
                        icon: Icons.link,
                        iconColor: ThemeManager.successColor(),
                        duration: const Duration(seconds: 2),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  

  
  // This method has been removed as we now handle context menu directly
  
  Widget _buildContextMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              color: ThemeManager.textColor(),
              size: 24,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                color: ThemeManager.textColor(),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildContextMenuButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Material(
        color: ThemeManager.surfaceColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: ThemeManager.primaryColor(),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: ThemeManager.textColor(),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
            ),
          ),
        );
      }
      
  // Initialize a new tab's WebView controller
  Future<void> _initializeTabController(Map<String, dynamic> tab) async {
    if (!mounted) return;
    
    final WebViewController tabController = tab['controller'] as WebViewController;
    
    // Configure the WebView controller
    tabController
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..enableZoom(true);
    
    // Set up navigation delegate
    tabController.setNavigationDelegate(await _navigationDelegate);
    
    // Enable file access for Android WebView
    if (tabController.platform is webview_flutter_android.AndroidWebViewController) {
      final androidController = tabController.platform as webview_flutter_android.AndroidWebViewController;
      // Only allow access to specific files/assets needed by the app
      // This restricts WebView to only access downloaded files from this app
      await androidController.setAllowFileAccess(true);
      await androidController.setAllowContentAccess(true);
      // Note: Additional security methods not available in current WebView version
      // Security is still maintained through proper file handling
      // Enable text zoom
      await androidController.setTextZoom(100);
    }
    
    // Set up JavaScript channels and context menu handlers
    await _setupTabControllerChannels(tabController);
    
    // Load the URL
    final url = tab['url'] as String;
    if (url.isNotEmpty) {
      await tabController.loadRequest(Uri.parse(url));
    }
  }
  
  // Set up JavaScript channels for a tab's WebView controller
  Future<void> _setupTabControllerChannels(WebViewController controller) async {
    // Add the context menu JavaScript channel
    await controller.addJavaScriptChannel(
      'SolarContextMenu',
      onMessageReceived: (JavaScriptMessage message) {
        if (!mounted) return;
        try {
          print('📱 SolarContextMenu message received: ${message.message}');
          final data = json.decode(message.message) as Map<String, dynamic>;
          final type = data['type'] as String;
          
          print('📱 Parsed message type: $type');
          
          switch (type) {
            case 'image_touch_start':
              print('📱 Handling image touch start');
              _handleTouchStart(data);
              break;
            case 'text_touch_start':
              print('📱 Handling text touch start');
              _handleTouchStart(data);
              break;
            case 'touch_moved':
              print('📱 Handling touch moved');
              _handleTouchMoved();
              break;
            case 'touch_end':
              print('📱 Handling touch end');
              _handleTouchEnd();
              break;
          }
    } catch (e) {
          print('❌ Error processing context menu message: $e');
          print('❌ Error details: ${e.toString()}');
        }
      },
    );
    
    // Inject the context menu JavaScript
    await _setupScrollHandlingForController(controller);
  }
  
  // Set up scroll handling and context menu JavaScript for a specific controller
  Future<void> _setupScrollHandlingForController(WebViewController controller) async {
    try {
      // Inject the same JavaScript code as in _setupScrollHandling
      await controller.runJavaScript('''
        (function() {
          console.log('🔧 Setting up DIRECT context menu handling...');
          
          // Clean up any existing handlers
          if (window.solarContextMenuCleanup) {
            window.solarContextMenuCleanup();
          }
          
          // --- SCROLL HANDLING ---
          let lastScrollY = window.scrollY;
          let scrollThrottle = null;
          
          function handleScroll() {
            const currentScrollY = window.scrollY;
            const delta = currentScrollY - lastScrollY;
            if (Math.abs(delta) > 5) {
              if (window.onScroll && window.onScroll.postMessage) {
                  window.onScroll.postMessage(JSON.stringify({ "delta": delta }));
              }
              lastScrollY = currentScrollY;
            }
          }
          
          window.addEventListener('scroll', () => {
            if (scrollThrottle) clearTimeout(scrollThrottle);
            scrollThrottle = setTimeout(handleScroll, 50);
          }, { passive: true });
          
          // --- DIRECT CONTEXT MENU OVERRIDE ---
          // This is a more aggressive approach that should definitely work
          
          // Override the contextmenu event on all images
          document.addEventListener('contextmenu', function(e) {
            const target = e.target;
            
            if (target.tagName === 'IMG') {
              console.log('🖼️ Context menu on image: ' + target.src);
              e.preventDefault();
              e.stopPropagation();
              
              if (window.SolarContextMenu) {
                const data = {
                  type: 'image_touch_start',
                  src: target.src,
                  alt: target.alt || ''
                };
                console.log('🖼️ Sending image data to Flutter: ', data);
                window.SolarContextMenu.postMessage(JSON.stringify(data));
              } else {
                console.error('SolarContextMenu channel not available');
              }
              
              return false;
            }
          }, false);
          
          // Track long press on all images
          const LONG_PRESS_DURATION = 500;
          let longPressTimer = null;
          let touchStartElement = null;
          
          // Function to handle image long press
          function handleImageLongPress(img) {
            console.log('🖼️ Long press detected on image: ' + img.src);
            
            if (window.SolarContextMenu) {
              const data = {
                type: 'image_touch_start',
                src: img.src,
                alt: img.alt || ''
              };
              console.log('🖼️ Sending image data to Flutter: ', data);
              window.SolarContextMenu.postMessage(JSON.stringify(data));
            } else {
              console.error('SolarContextMenu channel not available');
            }
          }
          
          // Touch start handler
          document.addEventListener('touchstart', function(e) {
            if (e.touches.length !== 1) return;
            
            const target = e.target;
            if (target.tagName === 'IMG') {
              console.log('🖼️ Touch start on image: ' + target.src);
              
              // Cancel any existing timer
              if (longPressTimer) {
                clearTimeout(longPressTimer);
              }
              
              // Set the touched element
              touchStartElement = target;
              
              // Start a new timer for long press
              longPressTimer = setTimeout(() => {
                if (touchStartElement === target) {
                  handleImageLongPress(target);
                }
              }, LONG_PRESS_DURATION);
            }
          }, false);
          
          // Touch end handler
          document.addEventListener('touchend', function() {
            if (longPressTimer) {
              clearTimeout(longPressTimer);
              longPressTimer = null;
            }
            touchStartElement = null;
          }, false);
          
          // Touch cancel handler
          document.addEventListener('touchcancel', function() {
            if (longPressTimer) {
              clearTimeout(longPressTimer);
              longPressTimer = null;
            }
            touchStartElement = null;
          }, false);
          
          // Touch move handler
          document.addEventListener('touchmove', function() {
            if (longPressTimer) {
              clearTimeout(longPressTimer);
              longPressTimer = null;
            }
            touchStartElement = null;
          }, false);
          
          // Create a function to manually trigger the context menu for testing
          window.showImageContextMenu = function(imgSrc) {
            if (window.SolarContextMenu) {
              const data = {
                type: 'image_touch_start',
                src: imgSrc || 'https://example.com/test.jpg',
                alt: 'Test image'
              };
              console.log('🖼️ Manually triggering image context menu: ', data);
              window.SolarContextMenu.postMessage(JSON.stringify(data));
              return true;
            } else {
              console.error('SolarContextMenu channel not available');
              return false;
            }
          };
          
          // Add test button for debugging
          function addTestButton() {
            const existingButton = document.getElementById('solar-test-button');
            if (existingButton) return;
            
            const button = document.createElement('button');
            button.id = 'solar-test-button';
            button.textContent = 'Test Image Menu';
            button.style.position = 'fixed';
            button.style.bottom = '10px';
            button.style.right = '10px';
            button.style.zIndex = '9999';
            button.style.padding = '10px';
            button.style.backgroundColor = '#268bd2';
            button.style.color = 'white';
            button.style.border = 'none';
            button.style.borderRadius = '5px';
            
            button.addEventListener('click', function() {
              window.showImageContextMenu();
            });
            
            document.body.appendChild(button);
          }
          
          // Add the test button in development mode
          if (window.location.href.includes('localhost') || window.location.href.includes('127.0.0.1')) {
            addTestButton();
          }
          
          // Create cleanup function
          window.solarContextMenuCleanup = function() {
            console.log('🧹 Cleaning up context menu handlers');
            if (longPressTimer) {
              clearTimeout(longPressTimer);
              longPressTimer = null;
            }
          };
          
          console.log('✅ Context menu setup complete');
        })();
      ''');
    } catch (e) {
      print('Error setting up scroll handling for tab: $e');
    }
  }
  
  // This method has been removed as we now use _startDownload directly
  
  Future<void> _downloadImage(String imageUrl) async {
    try {
      // Extract filename from URL or create one
      String filename = imageUrl.split('/').last.split('?').first;
      if (!filename.contains('.')) {
        filename = 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
      }
      
      // Start download using the existing download system
      setState(() {
        isDownloading = true;
        currentDownloadUrl = imageUrl;
        _currentFileName = filename;
        downloadProgress = 0.0;
      });
      
      // Use the existing download method
      await _downloadFile(imageUrl, filename);
      
    } catch (e) {
      print('Error downloading image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
                            content: Text('${AppLocalizations.of(context)!.failed_to_download_image}: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isDownloading = false;
          currentDownloadUrl = '';
          _currentFileName = null;
          downloadProgress = 0.0;
        });
      }
    }
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
      systemNavigationBarDividerColor: Colors.transparent,    ));
  }
  
  void _toggleTheme(bool darkMode) async {
    final theme = darkMode ? ThemeType.dark : ThemeType.light;
    await ThemeManager.setTheme(theme);
    
    _cachedDarkColors = null;
    _cachedLightColors = null;
    _cachedGlassDecoration = null;
    
    setState(() {
      isDarkMode = darkMode;
    });
    
    _updateSystemBars();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', darkMode);
    await prefs.setString('selectedTheme', theme.name);
    
    print('Theme toggled to: ${theme.name}, isDark: $darkMode');
    
    if (widget.onThemeChange != null) {
      widget.onThemeChange!(darkMode);
    }
  }
  // Helper method for efficient theme sending to WebView
  void _sendThemeToWebView() {
    try {
      final currentTheme = ThemeManager.getCurrentTheme();
      final themeColors = ThemeManager.getThemeColors(currentTheme);
      
      // Efficient color conversion
      String colorToHex(Color color) => '#${color.value.toRadixString(16).substring(2)}';
      
      final themeJson = json.encode({
        'type': 'fullTheme',
        'themeName': currentTheme.name,
        'isDark': currentTheme.isDark,
        'colors': {
          'backgroundColor': colorToHex(themeColors.backgroundColor),
          'surfaceColor': colorToHex(themeColors.surfaceColor),
          'textColor': colorToHex(themeColors.textColor),
          'textSecondaryColor': colorToHex(themeColors.textSecondaryColor),
          'primaryColor': colorToHex(themeColors.primaryColor),
          'accentColor': colorToHex(themeColors.accentColor),
          'errorColor': colorToHex(themeColors.errorColor),
          'successColor': colorToHex(themeColors.successColor),
          'warningColor': colorToHex(themeColors.warningColor),
          'secondaryColor': colorToHex(themeColors.secondaryColor),
        }
      });
      
      print('Sending theme to WebView: $themeJson'); // Debug log
      
      controller.runJavaScript('''
        try {
          console.log('Received theme from Flutter:', '$themeJson');
          window.postMessage($themeJson, "*");
        } catch (e) {
          console.error('Theme application error:', e);
        }
      ''');    } catch (e) {
      print('Error sending theme to WebView: $e');
    }
  }
  
  void _toggleClassicMode(bool classicMode) async {
    // Close AI action bar with animation when entering classic mode FIRST
    if (classicMode && _isAiActionBarVisible) {
      _closeAiActionBar();
      // Wait for animation to complete
      await Future.delayed(const Duration(milliseconds: 250));
    }
    
    // Then update state
    setState(() {
      _isClassicMode = classicMode;
      // When toggling classic mode, always make sure the URL bar is visible
      _hideUrlBar = false;
      _hideUrlBarController.reverse();
    });
    
    // If classic mode is being turned off, additional steps to ensure complete cleanup
    if (!classicMode) {
      // Force a rebuild by setting state and ensure slide panel is reset
      setState(() {
        _slideUpController.value = 0.0;
        _isSlideUpPanelVisible = false;
        _hideUrlBar = false;
        _hideUrlBarController.value = 0.0;
      });
      
      // Add a small delay to ensure the UI fully refreshes and the background is hidden
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          setState(() {
            // Force a layout rebuild to ensure background panel is completely removed
          });
        }
      });
    }
    
    await _savePreferences();
  }

  // Summary panel methods (disabled - do nothing)
  void _closeSummaryPanel() {
    // Summary panel removed - this method does nothing
  }
  
  Widget _buildSummaryPanel() {
    // Summary panel removed - return empty container
    return const SizedBox.shrink();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (tabs.isEmpty) {
      _addNewTab();
    }
  }  @override
  void dispose() {
    // Save tabs before disposing
    _saveTabs();
    
    // Remove app lifecycle observer
    WidgetsBinding.instance.removeObserver(this);
      // Clean up all timers for better performance
    _loadingTimeoutTimer?.cancel();
    _autoCollapseTimer?.cancel();
    _loadingTimer?.cancel();
    _hideTimer?.cancel();
    _urlBarIdleTimer?.cancel();
    _urlSyncTimer?.cancel(); // Clean up URL sync timer
    _developerModeTimer?.cancel();
    _contextMenuTimer?.cancel(); // Clean up context menu timer
    
    // Clean up debouncers
    _debouncer.dispose();
    _scrollThrottle.dispose();      // Dispose animation controllers
    _panelSlideController.dispose();
    _animationController.dispose();
    _loadingAnimationController.dispose();
    _slideAnimationController.dispose();    _slideUpController.dispose();
    _hideUrlBarController.dispose();
    _aiActionBarController.dispose();
    
    // Dispose text controllers and focus nodes
    _urlController.dispose();
    _urlFocusNode.dispose();
    _historyScrollController.dispose();
    _smoothScrollController.dispose();
    
    super.dispose();
  }

  // App lifecycle handler for tab persistence
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Save tabs when app is paused or detached
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _saveTabs();
    }
  }
  
  Future<void> _initializeControllers() async {
    // Initialize all animation controllers with M12 optimizations
    _slideUpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200)
    );
    
    _slideAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180), // Further reduced for M12
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideAnimationController,
      curve: Curves.easeOut, // Simpler curve for better performance
    ));    _loadingAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500), // Optimized for M12
    );
    _loadingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _loadingAnimationController,
      curve: Curves.linear,
    ));
    // Don't auto-start the animation here - let _setLoadingState handle it

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200), // Reduced for M12
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut, // Simpler curve
    );
      // Initialize URL bar animation controller
    _hideUrlBarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180), // Reduced for M12 responsiveness
    );    _hideUrlBarAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, 1.5),
    ).animate(CurvedAnimation(
      parent: _hideUrlBarController,
      curve: Curves.easeOut, // Simpler curve for M12
    ));
    
    // Initialize AI action bar animation controller
    _aiActionBarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _aiActionBarAnimation = CurvedAnimation(
      parent: _aiActionBarController,
      curve: Curves.easeOutCubic,
    );
    _aiActionBarHeightAnimation = Tween<double>(
      begin: 0.0,
      end: 60.0, // Height of the expanded AI action bar
    ).animate(_aiActionBarAnimation);

    // Panel animation controllers initialized earlier    // Initialize other controllers
    _urlController = TextEditingController();
    _urlFocusNode = FocusNode();
    
    // FIXED: Improved focus listener for proper URL formatting
    _urlFocusNode.addListener(() {
      if (mounted) {
        setState(() {
          _isUrlBarExpanded = _urlFocusNode.hasFocus;
            // Close AI action bar when URL bar gains focus
          if (_urlFocusNode.hasFocus && _isAiActionBarVisible) {
            _closeAiActionBar();
          }
          
          // When focus gained, show the full URL
          if (_urlFocusNode.hasFocus) {
            if (tabs.isNotEmpty && currentTabIndex >= 0 && currentTabIndex < tabs.length) {
              // Get the current tab's full URL and show it
              final fullUrl = _displayUrl; // Use _displayUrl which is most current
              _urlController.text = fullUrl;
              
              // Select all text for easy editing
              _urlController.selection = TextSelection(
                baseOffset: 0,
                extentOffset: _urlController.text.length,
              );
            }          
          } else {
            // FIXED: When focus is lost, reformat to domain-only using the most current URL
            if (tabs.isNotEmpty && currentTabIndex >= 0 && currentTabIndex < tabs.length) {
              // Use _displayUrl which has the most current URL
              final formattedUrl = _formatUrl(_displayUrl);
              _urlController.text = formattedUrl;
              
              // Position cursor at the end
              _urlController.selection = TextSelection.fromPosition(
                TextPosition(offset: _urlController.text.length),
              );
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
        print('Loaded saved theme: ${theme.name}');
      } catch (_) {
        theme = ThemeType.light;
        print('Failed to load saved theme, using light theme');
      }
    } else {
      // Fallback to darkMode preference if no theme is saved
      final isDark = prefs.getBool('darkMode') ?? false;
      theme = isDark ? ThemeType.dark : ThemeType.light;
      print('No saved theme, using fallback: ${theme.name}');
    }
    
    // Apply theme
    await ThemeManager.setTheme(theme);
    print('Applied theme: ${theme.name}, isDark: ${theme.isDark}');
    
    setState(() {
      isDarkMode = theme.isDark;
      textScale = prefs.getDouble('textScale') ?? 1.0;
      showImages = prefs.getBool('showImages') ?? true;
      currentSearchEngine = prefs.getString('searchEngine') ?? 'Google';
      currentLanguage = prefs.getString('language') ?? 'en';
      _keepTabsOpen = prefs.getBool('keepTabsOpen') ?? false;
      useCustomHomePage = prefs.getBool('useCustomHomePage') ?? false;
      customHomeUrl = prefs.getString('customHomeUrl') ?? '';
      
      // Use widget parameter for classic mode or fall back to preference
      if (widget.initialClassicMode) {
        _isClassicMode = true;
      } else {
        _isClassicMode = prefs.getBool('isClassicMode') ?? false;
      }
      
      // Update initial tab URL if custom homepage is enabled
      if (tabs.isNotEmpty && useCustomHomePage && customHomeUrl.isNotEmpty) {
        // Only update if we're on the home page
        if (tabs[0]['url'] == _homeUrl || tabs[0]['url'] == 'file:///android_asset/main.html') {
          tabs[0]['url'] = customHomeUrl;
          _displayUrl = customHomeUrl;
          if (!_urlFocusNode.hasFocus) {
            _urlController.text = _formatUrl(customHomeUrl);
          }
        }
      }
    });
    
    print('Set isDarkMode to: $isDarkMode for theme: ${theme.name}');
    
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
    await prefs.setBool('useCustomHomePage', useCustomHomePage);
    await prefs.setString('customHomeUrl', customHomeUrl);
  }
  
  void _showCustomHomeUrlDialog() {
    final TextEditingController _urlController = TextEditingController(text: customHomeUrl);
    
    showCustomDialog(
      context: context,
      title: AppLocalizations.of(context)!.set_home_page_url,
      isDarkMode: isDarkMode,
      customContent: Container(
        decoration: BoxDecoration(
          color: ThemeManager.surfaceColor(),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: ThemeManager.primaryColor().withOpacity(0.3),
            width: 1,
          ),
        ),
        child: TextField(
          controller: _urlController,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: InputBorder.none,
            hintText: 'https://example.com',
            hintStyle: TextStyle(
              color: ThemeManager.textColor().withOpacity(0.5),
            ),
          ),
          style: TextStyle(color: ThemeManager.textColor()),
          keyboardType: TextInputType.url,
          autofocus: true,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            AppLocalizations.of(context)!.cancel,
            style: TextStyle(color: ThemeManager.textSecondaryColor()),
          ),
        ),
        TextButton(
          onPressed: () async {
            String url = _urlController.text.trim();
            
            // Ensure URL has proper protocol and www if needed
            if (!url.startsWith('http://') && !url.startsWith('https://')) {
              url = 'https://$url';
            }
            
            // Add www if domain doesn't have it and doesn't have a subdomain
            if (url.startsWith('https://') && !url.startsWith('https://www.')) {
              // Check if it's a simple domain without subdomain
              final domainPart = url.substring(8); // after https://
              if (!domainPart.contains('/') && !domainPart.contains('.', domainPart.indexOf('.')+1)) {
                url = url.replaceFirst('https://', 'https://www.');
              }
            }
            
            setState(() {
              customHomeUrl = url;
              // Enable custom home page if URL is set
              if (customHomeUrl.isNotEmpty) {
                useCustomHomePage = true;
              }
            });
            
            await _savePreferences();
            Navigator.pop(context);
            
            // Apply the custom home page immediately if we're on the home page
            if (tabs.isNotEmpty && currentTabIndex >= 0 && currentTabIndex < tabs.length) {
              final currentUrl = tabs[currentTabIndex]['url'];
              if (currentUrl == _homeUrl || currentUrl == 'file:///android_asset/main.html') {
                // Update tab data
                tabs[currentTabIndex]['url'] = customHomeUrl;
                
                // Update UI
                setState(() {
                  _displayUrl = customHomeUrl;
                  _urlController.text = _formatUrl(customHomeUrl);
                  isSecure = customHomeUrl.startsWith('https://');
                });
                
                // Load the custom home page
                try {
                  print('Loading custom homepage: $customHomeUrl');
                  await controller.loadRequest(Uri.parse(customHomeUrl));
                } catch (e) {
                  print('Error loading custom homepage: $e');
                  _showCustomNotification(
                              message: '${AppLocalizations.of(context)!.error_loading_page}: $e',
          icon: Icons.error,
          iconColor: Colors.red,
                  );
                }
              }
            }
          },
          child: Text(
            AppLocalizations.of(context)!.save,
            style: TextStyle(color: ThemeManager.primaryColor()),
          ),
        ),
      ],
    );
  }
  Future<void> _initializeOptimizationEngine() async {
    // Lazy initialization to improve startup performance on M12
    _optimizationEngine = OptimizationEngine(controller);
    // Defer initialization to prevent blocking main thread
    Future.microtask(() async {
      try {
        await _optimizationEngine.initialize();
      } catch (e) {
        print('Optimization engine init error: $e');
      }
    });
  }
  Future<void> _loadDownloads() async {
    // Defer heavy operations to improve startup on M12
    Future.microtask(() async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final downloadsList = prefs.getStringList('downloads') ?? [];
        
        // Process in smaller chunks to prevent UI blocking
        final List<Map<String, dynamic>> parsedDownloads = [];
        for (int i = 0; i < downloadsList.length; i += 10) {
          final chunk = downloadsList.skip(i).take(10);
          for (final e in chunk) {
            try {
              final map = Map<String, dynamic>.from(json.decode(e));
              // Quick validation for required fields
              if (map.containsKey('url') && map.containsKey('filename') && 
                  map.containsKey('path') && map.containsKey('size') && 
                  map.containsKey('timestamp')) {
                parsedDownloads.add({
                  'url': map['url'] as String,
                  'filename': map['filename'] as String,
                  'path': map['path'] as String,
                  'size': (map['size'] as num).toInt(),
                  'timestamp': map['timestamp'] as String,
                  'mimeType': map['mimeType'] as String? ?? 'application/octet-stream',
                });
              }
            } catch (e) {
              // Silently skip corrupted entries to avoid log spam
              continue;
            }
          }
          // Yield control to UI thread between chunks
          if (i + 10 < downloadsList.length) {
            await Future.delayed(Duration.zero);
          }
        }
        
        if (mounted) {
          setState(() {
            downloads = parsedDownloads;
          });
        }
      } catch (e) {
        print('Downloads loading error: $e');
      }
    });
  }
  void _initializeAnimations() {    // Animation durations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200), // Reduced from 300ms
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2), // Reduced distance for smoother animation
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideAnimationController,
      curve: Curves.easeOut, // Simpler curve
    ));
  }

Future<void> _setupScrollHandling() async {
  try {
    // Inject JavaScript code for scroll handling and context menu
    await controller.runJavaScript('''
      (function() {
        console.log('🔧 Setting up DIRECT context menu handling...');
        
        // Clean up any existing handlers
        if (window.solarContextMenuCleanup) {
          window.solarContextMenuCleanup();
      }

      // --- SCROLL HANDLING ---
      let lastScrollY = window.scrollY;
      let scrollThrottle = null;
        
      function handleScroll() {
        const currentScrollY = window.scrollY;
        const delta = currentScrollY - lastScrollY;
        if (Math.abs(delta) > 5) {
          if (window.onScroll && window.onScroll.postMessage) {
              window.onScroll.postMessage(JSON.stringify({ "delta": delta }));
          }
          lastScrollY = currentScrollY;
        }
      }
        
      window.addEventListener('scroll', () => {
        if (scrollThrottle) clearTimeout(scrollThrottle);
        scrollThrottle = setTimeout(handleScroll, 50);
      }, { passive: true });

        // --- DIRECT CONTEXT MENU OVERRIDE ---
        // Store event listeners for cleanup
        const eventListeners = [];
        
        // Helper function to add event listeners and track them for cleanup
        function addTrackedEventListener(element, type, listener, options) {
          element.addEventListener(type, listener, options);
          eventListeners.push({ element, type, listener });
        }
        
        // Override the contextmenu event on all images
        const contextMenuHandler = function(e) {
          const target = e.target;
          
          if (target.tagName === 'IMG') {
            console.log('🖼️ Context menu on image: ' + target.src);
            e.preventDefault();
            e.stopPropagation();
            
            if (window.SolarContextMenu) {
              const data = {
                type: 'image_touch_start',
                src: target.src,
                alt: target.alt || ''
              };
              console.log('🖼️ Sending image data to Flutter: ', data);
              window.SolarContextMenu.postMessage(JSON.stringify(data));
            } else {
              console.error('SolarContextMenu channel not available');
            }
            
            return false;
          }
        };
        
        addTrackedEventListener(document, 'contextmenu', contextMenuHandler, false);
        
        // Track long press on all images
        const LONG_PRESS_DURATION = 500;
        let longPressTimer = null;
        let touchStartElement = null;
        
        // Function to handle image long press
        function handleImageLongPress(img) {
          console.log('🖼️ Long press detected on image: ' + img.src);
          
          if (window.SolarContextMenu) {
            const data = {
              type: 'image_touch_start',
              src: img.src,
              alt: img.alt || ''
            };
            console.log('🖼️ Sending image data to Flutter: ', data);
            window.SolarContextMenu.postMessage(JSON.stringify(data));
          } else {
            console.error('SolarContextMenu channel not available');
          }
        }
        
        // Touch start handler
        const touchStartHandler = function(e) {
          if (e.touches.length !== 1) return;
          
          const target = e.target;
        if (target.tagName === 'IMG') {
            console.log('🖼️ Touch start on image: ' + target.src);
            
            // Cancel any existing timer
            if (longPressTimer) {
              clearTimeout(longPressTimer);
            }
            
            // Set the touched element
            touchStartElement = target;
            
            // Start a new timer for long press
            longPressTimer = setTimeout(() => {
              if (touchStartElement === target) {
                handleImageLongPress(target);
              }
            }, LONG_PRESS_DURATION);
          }
        };
        
        addTrackedEventListener(document, 'touchstart', touchStartHandler, false);
        
        // Touch end handler
        const touchEndHandler = function() {
          if (longPressTimer) {
            clearTimeout(longPressTimer);
            longPressTimer = null;
          }
          touchStartElement = null;
        };
        
        addTrackedEventListener(document, 'touchend', touchEndHandler, false);
        
        // Touch cancel handler
        const touchCancelHandler = function() {
          if (longPressTimer) {
            clearTimeout(longPressTimer);
            longPressTimer = null;
          }
          touchStartElement = null;
        };
        
        addTrackedEventListener(document, 'touchcancel', touchCancelHandler, false);
        
        // Touch move handler
        const touchMoveHandler = function() {
          if (longPressTimer) {
            clearTimeout(longPressTimer);
            longPressTimer = null;
          }
          touchStartElement = null;
        };
        
        addTrackedEventListener(document, 'touchmove', touchMoveHandler, false);
        
        // Create a function to manually trigger the context menu for testing
        window.showImageContextMenu = function(imgSrc) {
          if (window.SolarContextMenu) {
            const data = {
              type: 'image_touch_start',
              src: imgSrc || 'https://example.com/test.jpg',
              alt: 'Test image'
            };
            console.log('🖼️ Manually triggering image context menu: ', data);
            window.SolarContextMenu.postMessage(JSON.stringify(data));
            return true;
          } else {
            console.error('SolarContextMenu channel not available');
            return false;
          }
        };
        
        // Add test button for debugging
        function addTestButton() {
          const existingButton = document.getElementById('solar-test-button');
          if (existingButton) return;
          
          const button = document.createElement('button');
          button.id = 'solar-test-button';
          button.textContent = 'Test Image Menu';
          button.style.position = 'fixed';
          button.style.bottom = '10px';
          button.style.right = '10px';
          button.style.zIndex = '9999';
          button.style.padding = '10px';
          button.style.backgroundColor = '#268bd2';
          button.style.color = 'white';
          button.style.border = 'none';
          button.style.borderRadius = '5px';
          
          button.addEventListener('click', function() {
            window.showImageContextMenu();
          });
          
          document.body.appendChild(button);
        }
        
        // Add the test button in development mode
        if (window.location.href.includes('localhost') || window.location.href.includes('127.0.0.1')) {
          addTestButton();
        }
        
        // Create cleanup function
        window.solarContextMenuCleanup = function() {
          console.log('🧹 Cleaning up context menu handlers');
          if (longPressTimer) {
            clearTimeout(longPressTimer);
            longPressTimer = null;
          }
          
          // Remove all tracked event listeners
          eventListeners.forEach(({ element, type, listener }) => {
            element.removeEventListener(type, listener);
          });
          eventListeners.length = 0;
        };
        
        // Function to reinitialize context menu after use
        window.reinitializeContextMenu = function() {
          console.log('🔄 Reinitializing context menu');
          if (window.solarContextMenuCleanup) {
            window.solarContextMenuCleanup();
          }
          
          // Re-add all event listeners
          addTrackedEventListener(document, 'contextmenu', contextMenuHandler, false);
          addTrackedEventListener(document, 'touchstart', touchStartHandler, false);
          addTrackedEventListener(document, 'touchend', touchEndHandler, false);
          addTrackedEventListener(document, 'touchcancel', touchCancelHandler, false);
          addTrackedEventListener(document, 'touchmove', touchMoveHandler, false);
        };
        
        console.log('✅ Context menu setup complete');
      })();
    ''');
    
    // --- DART KANAL DİNLEYİCİLERİ ---
    
    // Scroll Kanalı
    await controller.addJavaScriptChannel(
      'onScroll',
      onMessageReceived: (JavaScriptMessage message) {
        if (!mounted) return;
        _scrollThrottle.run(() {
          try {
            final data = json.decode(message.message);
            final delta = (data['delta'] as num).toDouble();
            
            if (delta.abs() > 3) {
              if (delta < 0) {
                if (!_hideUrlBar && !_isUpdatingState) {
                  _isUpdatingState = true;
                  setState(() { _hideUrlBar = true; _hideUrlBarController.forward(); });
                  Future.delayed(const Duration(milliseconds: 300), () { _isUpdatingState = false; });
                }
              } else {
                if (_hideUrlBar && !_isUpdatingState) {
                  _isUpdatingState = true;
                  setState(() { _hideUrlBar = false; _hideUrlBarController.reverse(); });
                  Future.delayed(const Duration(milliseconds: 300), () { _isUpdatingState = false; });
                }
              }
            }
          } catch (e) {
            // Hataları sessizce işle
          }
        });
      },
    );

    // ContextMenu Kanalı
    await controller.addJavaScriptChannel(
      'SolarContextMenu',
      onMessageReceived: (JavaScriptMessage message) {
        if (!mounted) return;
        try {
          final data = json.decode(message.message) as Map<String, dynamic>;
          final type = data['type'] as String;
          
          switch (type) {
            case 'image_touch_start':
            case 'text_touch_start':
              _handleTouchStart(data);
              break;
            case 'touch_moved':
              _handleTouchMoved();
              break;
            case 'touch_end':
              _handleTouchEnd();
              break;
          }
        } catch (e) {
          print('❌ [V7] Error processing context menu message: $e');
        }
      },
    );

    print('✅ [V7] _setupScrollHandling completed successfully');
  } catch (e) {
    print('❌ [V7] Error in _setupScrollHandling: $e');
  }
}
  
  
  Future<WebViewController> _initializeWebViewController() async {
    final webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..enableZoom(true);
    
    Future.microtask(() async {
      webViewController.setNavigationDelegate(await _navigationDelegate);
    });
    
    if (webViewController.platform is webview_flutter_android.AndroidWebViewController) {
      final androidController = webViewController.platform as webview_flutter_android.AndroidWebViewController;
        await Future.wait([
        androidController.setMediaPlaybackRequiresUserGesture(false),
        androidController.setBackgroundColor(Colors.transparent),
        androidController.setAllowFileAccess(true),
        androidController.setAllowContentAccess(true),
        androidController.setUserAgent(
          'Mozilla/9999.9999 (Linux; Android 9999; Solar 0.3.0) AppleWebKit/9999.9999 (KHTML, like Gecko) Chrome/9999.9999 Mobile Safari/9999.9999'
        ),
      ]);
        // Add context menu handler for images and text
      await androidController.setOnShowFileSelector((params) async {
        return await _onFileSelector(params);
      });
      
      // Note: setOnContextMenuCallback doesn't exist in current WebView API
      // Context menu will be handled via JavaScript injection and gesture detection
      
      Future.microtask(() async {
        try {
          await webViewController.runJavaScript('''
            document.body.style.setProperty('-webkit-transform', 'translate3d(0,0,0)');
            document.body.style.setProperty('transform', 'translate3d(0,0,0)');
            document.body.style.setProperty('will-change', 'transform');
            document.body.style.setProperty('backface-visibility', 'hidden');
          ''');
        } catch (e) {
          // Handle errors silently
        }
      });
    }

    Future.microtask(() async {
      try { 
        await webViewController.runJavaScript('''
          Object.defineProperty(navigator, 'vendor', {
            get: function() { return 'Google Inc.'; }
          });
          Object.defineProperty(window, 'chrome', {
            value: { app: { isInstalled: false }, runtime: {} },
            writable: true
          });
        ''');
      } catch (e) {
        // Handle errors silently
      }
    });

    return webViewController;
  }
  Future<void> _loadHomePageSettings() async {
    // Defer to prevent blocking startup on M12
    Future.microtask(() async {
      try {
        final prefs = await SharedPreferences.getInstance();
        if (mounted) {
          setState(() {
            _syncHomePageSearchEngine = prefs.getBool('syncHomePageSearchEngine') ?? true;
            _homePageSearchEngine = prefs.getString('homePageSearchEngine') ?? 'google';
            final shortcutsList = prefs.getStringList('homePageShortcuts') ?? [];
            _homePageShortcuts = shortcutsList.map((e) => 
              Map<String, String>.from(json.decode(e))
            ).toList();
          });
        }
      } catch (e) {
        // Silently handle errors
      }
    });
  }
  
  Future<void> _initializeWebView() async {
    print("Initializing WebView for optimal stability..."); // Debug print
    
    // Initialize optimization engine
    _optimizationEngine = OptimizationEngine();
      // Modern user agent for best compatibility
    final userAgent = 'Mozilla/9999.9999 (Linux; Android 9999; Solar 0.3.0) AppleWebKit/9999.9999 (KHTML, like Gecko) Chrome/9999.9999 Mobile Safari/9999.9999';
      controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted) // CRITICAL: ENABLE JAVASCRIPT      ..setBackgroundColor(Colors.transparent)
      ..enableZoom(true)
      ..setUserAgent(userAgent);
      
    print("JAVASCRIPT ENABLED: ${JavaScriptMode.unrestricted}");  // Configure Android WebView settings with restricted file access
    if (controller.platform is webview_flutter_android.AndroidWebViewController) {
      final androidController = controller.platform as webview_flutter_android.AndroidWebViewController;
      // Only allow access to specific files/assets needed by the app
      // This restricts WebView to only access downloaded files from this app
      await androidController.setAllowFileAccess(true);
      await androidController.setAllowContentAccess(true);
      // Note: Additional security methods not available in current WebView version
      // Security is still maintained through proper file handling
      // Enable text zoom
      await androidController.setTextZoom(100);
    }    // JavaScript channels for dialog handling
    await controller.addJavaScriptChannel(
      'DialogHandler',
      onMessageReceived: (JavaScriptMessage message) async {
        if (mounted) {
          try {
            final data = jsonDecode(message.message);
            final String type = data['type'];
            final String id = data['id'];
            final String messageText = data['message'] ?? '';
            final String defaultValue = data['defaultValue'] ?? '';
            
            if (type == 'prompt') {
              // FIXED: Use existing prompt dialog method with custom animation
              _showPromptDialog(messageText, defaultValue, id);
            } else if (type == 'alert') {
              // FIXED: Use existing alert dialog method with custom animation
              _showAlertDialog(messageText, id);
            } else if (type == 'confirm') {
              // FIXED: Use existing confirm dialog method with custom animation
              _showConfirmDialog(messageText, id);
            }
          } catch (e) {
            print('DialogHandler error: $e');
          }
        }
      },
    );

    // <----THEME HANDLER CHANNEL---->    // <----THEME HANDLER CHANNEL---->
    // JavaScript channel for theme communication with main.html
    await controller.addJavaScriptChannel(
      'ThemeHandler',
      onMessageReceived: (JavaScriptMessage message) async {
        if (mounted && message.message == 'getTheme') {
          // Send current theme to main.html
          await _sendThemeToMainHtml();
        }
      },
    );

    // <----LANGUAGE HANDLER CHANNEL---->
    // JavaScript channel for language communication with main.html
    await controller.addJavaScriptChannel(
      'LanguageHandler',
      onMessageReceived: (JavaScriptMessage message) async {
        if (mounted && message.message == 'getLanguage') {
          // Send current language to main.html
          await _sendLanguageToMainHtml();
        }
      },
    );

    // <----SEARCH HANDLER CHANNEL---->
    // JavaScript channel for search functionality from main.html
    await controller.addJavaScriptChannel(
      'SearchHandler',
      onMessageReceived: (JavaScriptMessage message) {
        if (mounted && message.message.isNotEmpty) {
          final engine = searchEngines[currentSearchEngine] ?? searchEngines['Google']!;
          final searchUrl = engine.replaceAll('{query}', Uri.encodeComponent(message.message));
          
          // Update URL bar to show the search query
          setState(() {
            _urlController.text = message.message;
            _displayUrl = searchUrl;
          });
          
          controller.loadRequest(Uri.parse(searchUrl));
        }
      },
    );

    // <----SEARCH ENGINE HANDLER CHANNEL---->
    // JavaScript channel for search engine communication with main.html
    await controller.addJavaScriptChannel(
      'SearchEngineHandler',
      onMessageReceived: (JavaScriptMessage message) async {
        if (mounted && message.message == 'getSearchEngine') {
          // Send current search engine to main.html
          await _sendSearchEngineToMainHtml();
        }
      },
    );    // <----NEWS HANDLER CHANNEL---->
    // JavaScript channel for news fetching communication with main.html
    await controller.addJavaScriptChannel(
      'NewsHandler',
      onMessageReceived: (JavaScriptMessage message) async {
        if (mounted && message.message == 'fetchNews') {
          print('📰 Received fetchNews request from main.html');
          await _fetchNewsFromFirebase();
        }
      },
    );

    // <----DEBUG HANDLER CHANNEL---->
    // JavaScript channel for debug messages
    await controller.addJavaScriptChannel(
      'DebugHandler',
      onMessageReceived: (JavaScriptMessage message) {
        print('🐛 JS Debug: ${message.message}');
      },
    );

    // FIXED: Set navigation delegate BEFORE loading initial content
    controller.setNavigationDelegate(await _navigationDelegate);

    // Setup scroll handling and context menu JavaScript
    await _setupScrollHandling();

// Load initial tab content efficiently with proper loading animation
    if (tabs.isNotEmpty && currentTabIndex >= 0 && currentTabIndex < tabs.length) {
      // Check if we should use the custom homepage
      String initialUrl = tabs[currentTabIndex]['url'];
      
      // If this is the home page and custom homepage is enabled, use it instead
      if ((initialUrl == _homeUrl || initialUrl == 'file:///android_asset/main.html') && 
          useCustomHomePage && customHomeUrl.isNotEmpty) {
        print('Using custom homepage on startup: $customHomeUrl');
        initialUrl = customHomeUrl;
        tabs[currentTabIndex]['url'] = initialUrl;
        _displayUrl = initialUrl;
        _urlController.text = _formatUrl(initialUrl);
        isSecure = initialUrl.startsWith('https://');
      }
      
      if (initialUrl.isNotEmpty && initialUrl != 'about:blank') {
        // FIXED: Trigger loading animation for initial page load
        _setLoadingState(true);
        
        try {
          print('Loading initial URL: $initialUrl');
        controller.loadRequest(Uri.parse(initialUrl));
        } catch (e) {
          print('Error loading initial URL: $e');
        }
        
        // Initialize theme for home page if needed
        if (initialUrl.contains('main.html') || initialUrl == _homeUrl) {
          Future.delayed(const Duration(milliseconds: 300), _initializeThemeForHomePage);
        }
      }
    }// Setup URL monitoring last to avoid conflicts
    Future.microtask(() => _setupUrlMonitoring());
    
    // Start URL sync to ensure URL bar is always accurate
    _startUrlSync();
  }
  // Optimized download URL detection for M12
  bool _isDownloadUrl(String url) {
    // Quick checks first for performance
    if (url.startsWith('blob:') || 
        url.startsWith('data:') && !url.contains('text/html') ||
        url.contains('download=') || 
        url.contains('attachment')) {
      return true;
    }
    
    // Check extensions only if needed
    const downloadExtensions = [
      '.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx',
      '.zip', '.rar', '.7z', '.tar', '.gz',
      '.mp3', '.mp4', '.wav', '.avi', '.mov', '.wmv',
      '.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp',
      '.apk', '.exe', '.dmg', '.iso'
    ];

    final lowerUrl = url.toLowerCase();
    return downloadExtensions.any((ext) => lowerUrl.endsWith(ext)) ||
           lowerUrl.contains('/download/') ||
           lowerUrl.contains('downloadfile') ||
           lowerUrl.contains('getfile');
  }
  
  Future<void> _setupUrlMonitoring() async {
    // Enhanced URL monitoring for better compatibility with modern websites like Google
    await controller.runJavaScript('''
      (function() {
        // Clean up any existing monitoring first
        if (window.cleanupUrlMonitoring) {
          window.cleanupUrlMonitoring();
        }
        
        let lastUrl = window.location.href;
        let lastTitle = document.title;
        let notifyThrottle = null;
        let checkInterval = null;
        let isMonitoring = true;
        
        function notifyUrlChanged() {
          if (!isMonitoring || notifyThrottle) return; // Prevent spam
          
          const currentUrl = window.location.href;
          const currentTitle = document.title || document.querySelector('title')?.textContent || 'Untitled';
          
          // Only notify on actual changes
          if (currentUrl !== lastUrl || currentTitle !== lastTitle) {
            console.log('🔄 URL changed from', lastUrl, 'to', currentUrl);
            console.log('🔄 Title changed from', lastTitle, 'to', currentTitle);
            
            if (window.UrlChanged && window.UrlChanged.postMessage) {
              try {
                window.UrlChanged.postMessage(JSON.stringify({
                  url: currentUrl,
                  title: currentTitle,
                  timestamp: Date.now()
                }));
              } catch(e) {
                console.error('Failed to send URL update:', e);
              }
            }
            
            lastUrl = currentUrl;
            lastTitle = currentTitle;
            
            // Throttle notifications to prevent spam
            notifyThrottle = setTimeout(() => {
              notifyThrottle = null;
            }, 100);
          }
        }

        // Enhanced event listeners for comprehensive coverage
        const events = ['load', 'popstate', 'hashchange', 'DOMContentLoaded'];
        events.forEach(event => {
          window.addEventListener(event, () => {
            setTimeout(notifyUrlChanged, 50);
          }, { passive: true });
        });
        
        // Monitor for DOM changes that indicate navigation (especially for SPAs like Google)
        let titleObserver = null;
        let headObserver = null;
        
        try {
          // Watch for title changes specifically
          const titleElement = document.querySelector('title');
          if (titleElement) {
            titleObserver = new MutationObserver(() => {
              setTimeout(notifyUrlChanged, 50);
            });
            titleObserver.observe(titleElement, { childList: true, characterData: true });
          }
          
          // Watch for head changes (new scripts, meta tags, etc.)
          headObserver = new MutationObserver((mutations) => {
            let significantChange = false;
            mutations.forEach((mutation) => {
              if (mutation.type === 'childList') {
                mutation.addedNodes.forEach(node => {
                  if (node.nodeName === 'TITLE' || node.nodeName === 'META' || node.nodeName === 'LINK') {
                    significantChange = true;
                  }
                });
              }
            });
            if (significantChange) {
              setTimeout(notifyUrlChanged, 100);
            }
          });
          headObserver.observe(document.head, { childList: true, subtree: true });
        } catch(e) {
          console.log('MutationObserver setup failed:', e);
        }
        
        // Monitor clicks on links with enhanced targeting
        document.addEventListener('click', function(e) {
          const link = e.target.closest('a, button[onclick], [data-href]');
          if (link) {
            // Check various ways a navigation might be triggered
            const href = link.href || link.getAttribute('data-href') || link.getAttribute('onclick');
            if (href && href !== 'javascript:void(0)' && !href.includes('void(0)')) {
              setTimeout(notifyUrlChanged, 200);
            }
          }
        }, { passive: true });
        
        // Override history methods comprehensively for SPA navigation
        const originalPushState = history.pushState;
        const originalReplaceState = history.replaceState;
        
        history.pushState = function() {
          originalPushState.apply(this, arguments);
          setTimeout(notifyUrlChanged, 25);
        };
        
        history.replaceState = function() {
          originalReplaceState.apply(this, arguments);
          setTimeout(notifyUrlChanged, 25);
        };
        
        // Regular monitoring with adaptive frequency (reduced for better performance)
        checkInterval = setInterval(() => {
          if (isMonitoring) {
            notifyUrlChanged();
          }
        }, 200);
        
        // Monitor page visibility changes (important for Google and other SPAs)
        document.addEventListener('visibilitychange', () => {
          if (!document.hidden) {
            setTimeout(notifyUrlChanged, 100);
          }
        });
        
        // Monitor for focus events that might trigger navigation updates
        window.addEventListener('focus', () => {
          setTimeout(notifyUrlChanged, 100);
        }, { passive: true });
        
        // Initial check after a short delay
        setTimeout(notifyUrlChanged, 150);
        
        // Cleanup function
        window.cleanupUrlMonitoring = function() {
          isMonitoring = false;
          if (checkInterval) clearInterval(checkInterval);
          if (titleObserver) titleObserver.disconnect();
          if (headObserver) headObserver.disconnect();
          console.log('🧹 URL monitoring cleaned up');
        };
        
        console.log('🚀 Enhanced URL monitoring initialized for:', window.location.href);      })();
    ''');

    await controller.addJavaScriptChannel(
      'UrlChanged',
      onMessageReceived: (JavaScriptMessage message) {
        if (!mounted) return;
        
        try {
          final data = json.decode(message.message);
          final url = data['url'] as String;
          final title = data['title'] as String;
          
          // Use central helper method for consistent URL handling
          if (url.isNotEmpty && url != _displayUrl) {
            _handleUrlUpdate(url, title: title.isNotEmpty ? title : null);
            
            // Defer navigation state update
            Future.microtask(_updateNavigationState);
          }
        } catch (e) {
          // Silently handle errors
        }
      },
    );  }
  
  // Optimized theme initialization for home page
  Future<void> _initializeThemeForHomePage() async {
    // Shorter delay for better responsiveness
    await Future.delayed(const Duration(milliseconds: 300));
    
    if (!mounted) return;
      try {
      // Send theme specifically to main.html
      await _sendThemeToMainHtml();
      
      // Also send search engine and language information
      await _sendSearchEngineToMainHtml();
      await _sendLanguageToMainHtml();
      
      // Additional initialization with retry for stability
      await controller.runJavaScript('''
        if (document.readyState === 'complete' || document.readyState === 'interactive') {
          window.dispatchEvent(new Event('themeready'));
        } else {
          document.addEventListener('DOMContentLoaded', () => {
            window.dispatchEvent(new Event('themeready'));
          });
        }
      ''');
      
    } catch (e) {      // Silently handle errors
    }  }
  // Send theme data specifically to main.html
  Future<void> _sendThemeToMainHtml() async {
    if (!mounted) return;
    
    try {
      // Get current theme colors from ThemeManager
      final currentTheme = ThemeManager.getCurrentTheme();
      final themeColors = ThemeManager.getThemeColors(currentTheme);
      
      // Convert colors to hex
      String colorToHex(Color color) => '#${color.value.toRadixString(16).substring(2)}';
      
      final themeData = {
        'type': 'fullTheme',
        'themeName': currentTheme.name,
        'isDark': currentTheme.isDark,
        'colors': {
          'backgroundColor': colorToHex(themeColors.backgroundColor),
          'surfaceColor': colorToHex(themeColors.surfaceColor),
          'textColor': colorToHex(themeColors.textColor),
          'textSecondaryColor': colorToHex(themeColors.textSecondaryColor),
          'primaryColor': colorToHex(themeColors.primaryColor),
          'accentColor': colorToHex(themeColors.accentColor),
          'errorColor': colorToHex(themeColors.errorColor),
          'successColor': colorToHex(themeColors.successColor),
          'warningColor': colorToHex(themeColors.warningColor),
          'secondaryColor': colorToHex(themeColors.secondaryColor),
        }
      };
      
      // Convert to proper JSON string
      final themeJson = json.encode(themeData);
      
      print('Sending theme to main.html: $themeJson'); // Debug log        // Send theme via multiple methods for compatibility
      await controller.runJavaScript('''
        try {
          console.log('🎨 Sending theme data to main.html...');
          
          // Parse the theme data (it's already a JSON string)
          const themeData = JSON.parse('$themeJson');
          
          // Method 1: window.postMessage
          if (window.postMessage) {
            window.postMessage(themeData, '*');
            console.log('✅ Theme sent via postMessage');
          }
          
          // Method 2: Direct function call if available
          if (typeof applyTheme === 'function') {
            applyTheme(themeData);
            console.log('✅ Theme applied via applyTheme function');
          }
          
          // Method 3: Custom event
          window.dispatchEvent(new CustomEvent('themeUpdate', { detail: themeData }));
          console.log('✅ Theme update event dispatched');
          
        } catch (e) {
          console.error('❌ Error sending theme:', e);
        }
      ''');
      
      // Also send current search engine information
      await _sendSearchEngineToMainHtml();
      
      // And send language information
      await _sendLanguageToMainHtml();
        } catch (e) {
      print('Error sending theme to main.html: $e');
    }
  }

  // Fetch news from Firebase Storage using Cloud Functions (updated to match Unity version)
  Future<void> _fetchNewsFromFirebase() async {
    if (!mounted) return;
    
    try {
      print('📰 Fetching news using Firebase Cloud Functions...');
      
      // Check if Firebase Functions is initialized
      if (_firebaseFunctions == null) {
        print('❌ Firebase Functions not initialized');
        await _sendNewsErrorToWebView('Firebase not initialized');
        return;
      }
      
      // Get current language (align with Unity: 1 = Turkish, 0 = English)
      final prefs = await SharedPreferences.getInstance();
      final currentLang = prefs.getString('language') ?? 'en';
      final languageIndex = currentLang == 'tr' ? 1 : 0;
      
      // Check cache first
      if (_cachedArticles != null && _cachedLanguage == languageIndex) {
        print('📰 Using cached news data');
        await _sendNewsToWebView(_cachedArticles!);
        return;
      }
      
      // Step 1: Get signed URL for news.json from Cloud Function
      final HttpsCallable callable = _firebaseFunctions!.httpsCallable('getNewsCacheUrl');
      final HttpsCallableResult result = await callable.call();
      
      final Map<String, dynamic> data = Map<String, dynamic>.from(result.data);
      final String? signedUrl = data['signedUrl'] as String?;
      
      if (signedUrl == null || signedUrl.isEmpty) {
        print('❌ Failed to get signed URL for news cache');
        await _sendNewsErrorToWebView('Could not get news data link from server');
        return;
      }
      
      print('📰 Got signed URL for news cache: $signedUrl');
      
      // Step 2: Fetch news from the signed URL
      final response = await http.get(Uri.parse(signedUrl));
      
      if (response.statusCode == 200) {
        // Parse the JSON response
        final List<dynamic> articlesJson = json.decode(response.body);
        final List<Map<String, dynamic>> articles = articlesJson.cast<Map<String, dynamic>>();
        
        print('📰 Successfully fetched ${articles.length} news articles');
        
        // Cache the articles
        _cachedArticles = articles;
        _cachedLanguage = languageIndex;
        
        // Send to WebView
        await _sendNewsToWebView(articles);
        
      } else {
        print('❌ Failed to fetch news from signed URL: ${response.statusCode}');
        await _sendNewsErrorToWebView('Failed to load news from server');
      }
      
    } catch (e) {
      print('❌ Error fetching news: $e');
      await _sendNewsErrorToWebView('Network error while loading news');
    }
  }
  
  // Send news data to WebView
  Future<void> _sendNewsToWebView(List<Map<String, dynamic>> articles) async {
    if (!mounted) return;
    
    try {
      // Get current language for proper article selection
      final prefs = await SharedPreferences.getInstance();
      final currentLang = prefs.getString('language') ?? 'en';
      final isCurrentlyTurkish = currentLang == 'tr';
      
      // Process articles for WebView consumption
      final processedArticles = <Map<String, dynamic>>[];
      
      // Create a directory for storing news data if it doesn't exist
      final appDir = await getApplicationDocumentsDirectory();
      final newsDir = Directory('${appDir.path}/news');
      if (!await newsDir.exists()) {
        await newsDir.create(recursive: true);
      }
      
      for (final article in articles) {
        try {
          // Extract translations
          final translations = article['translations'] as Map<String, dynamic>?;
          if (translations == null) continue;
          
          final currentTranslation = isCurrentlyTurkish 
              ? translations['tr'] as Map<String, dynamic>?
              : translations['en'] as Map<String, dynamic>?;
          
          if (currentTranslation == null) continue;
          
          // Extract cover image path
          final cover = article['cover'] as Map<String, dynamic>?;
          final coverPath = cover != null 
              ? (isCurrentlyTurkish ? cover['tr'] : cover['en']) as String?
              : null;
          
          // Get signed URL for cover image if available
          String? coverUrl;
          if (coverPath != null && coverPath.isNotEmpty) {
            // Check cache first
            if (_cachedCoverImages.containsKey(coverPath)) {
              coverUrl = _cachedCoverImages[coverPath];
            } else {
              // Get signed URL for cover image
              coverUrl = await _getSignedUrlForCover(coverPath);
              if (coverUrl != null) {
                _cachedCoverImages[coverPath] = coverUrl;
              }
            }
          }
          
          // Create processed article with full content
          final processedArticle = {
            'id': article['id'] ?? '',
            'title': currentTranslation['title'] ?? '',
            'summary': currentTranslation['summary'] ?? '',
            'content': currentTranslation['content'] ?? currentTranslation['summary'] ?? '',
            'image': coverUrl, // This is the field name expected in createNewsItem
            'references': article['references'] ?? [],
            'publishedAt': article['publishedAt'] ?? '',
            'url': 'news://${article['id'] ?? ''}', // Add custom URL scheme
          };
          
          processedArticles.add(processedArticle);
        } catch (e) {
          print('❌ Error processing article: $e');
        }
      }
      
      print('📰 Calling renderNews with ${processedArticles.length} news items');
      
      // Call the existing renderNews function in main.html with our processed articles
      // This uses the format expected by the function in android/app/src/main/assets/main.html
      final jsonArticles = jsonEncode(processedArticles);
      await controller.runJavaScript('''
        (function() {
          try {
            console.log('📰 Calling renderNews with articles: ${processedArticles.length}');
            if (typeof renderNews === 'function') {
              renderNews(${jsonArticles});
              console.log('✅ renderNews function called successfully');
            } else {
              console.error('❌ renderNews function not found in page');
            }
          } catch (e) {
            console.error('❌ Error calling renderNews:', e);
          }
        })();
      ''');
      
    } catch (e) {
      print('❌ Error sending news to WebView: $e');
      await _sendNewsErrorToWebView('Error displaying news');
    }
  }
  
  // Get signed URL for cover image
  Future<String?> _getSignedUrlForCover(String filePath) async {
    try {
      if (_firebaseFunctions == null) return null;
      
      final HttpsCallable callable = _firebaseFunctions!.httpsCallable('getCoverDownloadUrl');
      final HttpsCallableResult result = await callable.call({'filePath': filePath});
      
      final Map<String, dynamic> data = Map<String, dynamic>.from(result.data);
      return data['signedUrl'] as String?;
    } catch (e) {
      print('❌ Error getting signed URL for cover $filePath: $e');
      return null;
    }
  }
  
  // Send error message to WebView
  Future<void> _sendNewsErrorToWebView(String errorMessage) async {
    if (!mounted) return;
    
    try {
      await controller.runJavaScript('''
        (function() {
          try {
            console.error('❌ News fetch error: $errorMessage');
            
            // Find the news container with fallbacks
            let container = document.getElementById('newsContainer');
            if (!container) {
              console.log('📰 newsContainer not found by ID for error, looking for alternatives');
              
              // Try to find by class
              const newsContainers = document.getElementsByClassName('news-container');
              if (newsContainers.length > 0) {
                // Create a new container inside the news-container
                const newsSection = newsContainers[0];
                newsSection.innerHTML = '<h2 class="news-title">Latest News</h2><div id="newsContainer"></div>';
                container = document.getElementById('newsContainer');
              } else {
                // Create container from scratch
                const main = document.querySelector('.container') || document.body;
                const newsSection = document.createElement('div');
                newsSection.className = 'news-container';
                newsSection.innerHTML = '<h2 class="news-title">Latest News</h2><div id="newsContainer"></div>';
                main.appendChild(newsSection);
                container = document.getElementById('newsContainer');
              }
            }
            
            if (container) {
              container.innerHTML = '<div class="news-item"><div class="news-item-title">Error loading news</div><div class="news-item-summary">' + '$errorMessage' + '</div></div>';
              console.log('✅ Error message displayed in news container');
            } else {
              console.error('❌ Failed to find or create news container for error message');
              
              // Last resort - add to body
              document.body.insertAdjacentHTML('beforeend', 
                '<div class="news-container"><h2 class="news-title">Latest News</h2><div id="newsContainer"><div class="news-item"><div class="news-item-title">Error loading news</div><div class="news-item-summary">' + '$errorMessage' + '</div></div></div></div>'
              );
            }
          } catch (e) {
            console.error('❌ Error handling news fetch error:', e);
          }
        })();
      ''');
    } catch (e) {
      print('❌ Error sending error message to WebView: $e');
    }
  }

  // Send search engine data to main.html
  Future<void> _sendSearchEngineToMainHtml() async {
    if (!mounted) return;
    
    try {
      final searchEngineData = {
        'type': 'searchEngine',
        'engine': currentSearchEngine,
      };
      
      final searchEngineJson = json.encode(searchEngineData);
        await controller.runJavaScript('''
        try {
          console.log('🔍 Sending search engine data to main.html...');
          
          // Parse the search engine data
          const searchEngineData = JSON.parse('$searchEngineJson');
          
          if (window.postMessage) {
            window.postMessage(searchEngineData, '*');
            console.log('✅ Search engine sent via postMessage');
          }
          
          // Update current search engine and logo directly
          if (typeof updateSearchEngineLogo === 'function') {
            currentSearchEngine = '${currentSearchEngine}';
            updateSearchEngineLogo();
            console.log('✅ Search engine updated directly to: ${currentSearchEngine}');
          }
          
          // Also dispatch a custom event
          window.dispatchEvent(new CustomEvent('searchEngineUpdate', { 
            detail: { engine: '${currentSearchEngine}' } 
          }));
          
        } catch (e) {
          console.error('❌ Error sending search engine:', e);
        }
      ''');
      
    } catch (e) {
      print('Error sending search engine to main.html: $e');
    }  }

  // Send language data to main.html
  Future<void> _sendLanguageToMainHtml() async {
    if (!mounted) return;
    
    try {
      // Get current language from the stored locale
      String currentLang = _currentLocale;
      
      final languageData = {
        'type': 'language',
        'language': currentLang,
      };
      
      final languageJson = json.encode(languageData);
      
      await controller.runJavaScript('''
        try {
          console.log('Sending language data to main.html...');
          
          if (window.postMessage) {
            window.postMessage($languageJson, '*');
            console.log('Language sent via postMessage');
          }
          
          if (typeof updateLocalizedUI === 'function') {
            currentLanguage = '${currentLang}';
            updateLocalizedUI();
            console.log('Language updated directly');
          }
          
        } catch (e) {
          console.error('Error sending language:', e);
        }
      ''');      
    } catch (e) {
      print('Error sending language to main.html: $e');
    }
  }

  // Send theme data to restored tabs
  Future<void> _sendThemeToRestoredTab() async {
    if (!mounted) return;
    
    try {
      // Get current theme colors from ThemeManager
      final currentTheme = ThemeManager.getCurrentTheme();
      final themeColors = ThemeManager.getThemeColors(currentTheme);
      
      // Convert colors to hex
      String colorToHex(Color color) => '#${color.value.toRadixString(16).substring(2)}';
      
      final themeData = {
        'type': 'fullTheme',
        'themeName': currentTheme.name,
        'isDark': currentTheme.isDark,
        'colors': {
          'backgroundColor': colorToHex(themeColors.backgroundColor),
          'surfaceColor': colorToHex(themeColors.surfaceColor),
          'textColor': colorToHex(themeColors.textColor),
          'textSecondaryColor': colorToHex(themeColors.textSecondaryColor),
          'primaryColor': colorToHex(themeColors.primaryColor),
          'accentColor': colorToHex(themeColors.accentColor),
          'errorColor': colorToHex(themeColors.errorColor),
          'successColor': colorToHex(themeColors.successColor),
          'warningColor': colorToHex(themeColors.warningColor),
          'secondaryColor': colorToHex(themeColors.secondaryColor),
        }
      };
      
      // Convert to proper JSON string
      final themeJson = json.encode(themeData);
      
      // Send theme via multiple methods for restored tabs
      await controller.runJavaScript('''
        try {
          console.log('Sending theme to restored tab...');
          
          // Check if this is main.html
          const isMainHtml = window.location.href.includes('main.html') || 
                            window.location.pathname.includes('main.html');
          
          if (isMainHtml) {
            // For main.html, use specific methods
            if (window.postMessage) {
              window.postMessage($themeJson, '*');
            }
            
            if (typeof applyTheme === 'function') {
              applyTheme($themeJson);
            }
          }
          
          // For all pages, dispatch theme event
          window.dispatchEvent(new CustomEvent('themeUpdate', { detail: $themeJson }));
          console.log('Theme sent to restored tab');
        } catch (e) {
          console.error('Restored tab theme update error:', e);
        }
      ''');
    } catch (e) {
      print('Error sending theme to restored tab: $e');
    }
  }

  Future<void> _updateNavigationState() async {
    if (!mounted) return;
    
    try {
      // Batch navigation queries for efficiency
      final results = await Future.wait([
        controller.canGoBack(),
        controller.canGoForward(),
        controller.currentUrl(),
      ]);
      
      final canGoBackValue = results[0] as bool;
      final canGoForwardValue = results[1] as bool;
      final currentUrl = results[2] as String? ?? '';
      
      if (mounted) {
        setState(() {
          canGoBack = canGoBackValue;
          canGoForward = canGoForwardValue;
          
          // Update current tab's navigation state
          if (tabs.isNotEmpty && currentTabIndex >= 0 && currentTabIndex < tabs.length) {            tabs[currentTabIndex]['canGoBack'] = canGoBackValue;
            tabs[currentTabIndex]['canGoForward'] = canGoForwardValue;
          }
        });
        
        // Update URL if it has changed
        if (currentUrl.isNotEmpty && currentUrl != _displayUrl) {
          _handleUrlUpdate(currentUrl);
        }
      }
    } catch (e) {
      // Silently handle errors
    }
  }

  Future<void> _setupWebViewCallbacks() async {
    // Add JavaScript for handling long press with text selection support
    await controller.runJavaScript('''
      (function() {
        let longPressTimer;
        let isLongPress = false;
        let startX, startY;
          document.addEventListener('touchstart', function(e) {
          console.log('👆 Touch start detected at:', e.touches[0].clientX, e.touches[0].clientY);
          startX = e.touches[0].clientX;
          startY = e.touches[0].clientY;
          isLongPress = false;
            longPressTimer = setTimeout(() => {
            console.log('🔥 Long press timer triggered!');
            isLongPress = true;
            
            // Get the element under touch
            const element = document.elementFromPoint(startX, startY);
            console.log('🔍 Element at point:', element, element ? element.tagName : 'null');
              // Check if the target is an image
            if (element && element.tagName === 'IMG') {
              console.log('📸 Image detected:', element.src);
              const rect = element.getBoundingClientRect();
              const imageUrl = element.src;
              ImageLongPress.postMessage(JSON.stringify({
                type: 'image',
                url: imageUrl,
                x: startX,
                y: startY + window.scrollY
              }));
              e.preventDefault();
              return;
            }
            
            // Check if there's selected text or if we're touching text content
            const selection = window.getSelection();
            const hasSelectedText = selection && selection.toString().trim().length > 0;
            
            // Check if the touched element contains text
            const hasTextContent = element && (
              element.tagName === 'P' ||
              element.tagName === 'DIV' ||
              element.tagName === 'SPAN' ||
              element.tagName === 'A' ||
              element.tagName === 'H1' ||
              element.tagName === 'H2' ||
              element.tagName === 'H3' ||
              element.tagName === 'H4' ||
              element.tagName === 'H5' ||
              element.tagName === 'H6' ||
              element.tagName === 'LI' ||
              element.tagName === 'TD' ||
              element.tagName === 'TH' ||
              (element.nodeType === Node.TEXT_NODE) ||
              (element.textContent && element.textContent.trim().length > 0)
            );
              // If there's selected text or we're touching text content, show text context menu
            if (hasSelectedText || hasTextContent) {
              console.log('Text detected, showing text context menu');
              TextLongPress.postMessage(JSON.stringify({
                text: hasSelectedText ? selection.toString().trim() : '',
                x: startX,
                y: startY + window.scrollY,
                isInput: element.isContentEditable || element.tagName === 'INPUT' || element.tagName === 'TEXTAREA'
              }));
              return;
            }
            
            // Show custom context menu for empty space
            GeneralLongPress.postMessage(JSON.stringify({
              type: 'general',
              x: startX,
              y: startY + window.scrollY
            }));
          }, 500);
        }, true);
        
        document.addEventListener('touchend', function(e) {
          if (longPressTimer) {
            clearTimeout(longPressTimer);
          }
        }, true);
        
        document.addEventListener('touchmove', function(e) {
          // Cancel long press if user moves finger too much
          const currentX = e.touches[0].clientX;
          const currentY = e.touches[0].clientY;
          const deltaX = Math.abs(currentX - startX);
          const deltaY = Math.abs(currentY - startY);
          
          if (deltaX > 10 || deltaY > 10) {
            if (longPressTimer) {
              clearTimeout(longPressTimer);
            }
          }
        }, true);      })();
    ''');

    await controller.addJavaScriptChannel(      'ImageLongPress',
      onMessageReceived: (JavaScriptMessage message) {
        if (!mounted) return;
        print('ImageLongPress received: ${message.message}');
        
        try {
          final data = json.decode(message.message) as Map<String, dynamic>;
          final type = data['type'] as String;
          
          if (type == 'image') {
            final imageUrl = data['url'] as String;
            final x = (data['x'] as num).toDouble();
            final y = (data['y'] as num).toDouble();
            
            print('Showing image context menu for: $imageUrl at ($x, $y)');
            
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              setState(() {
                _tapPosition = Offset(x, y);
              });
              _showImageContextMenu({
                'src': imageUrl,
                'alt': '',
              });
            });
          }
        } catch (e) {
          print('Error handling image long press: $e');
        }
      },
    );

    await controller.addJavaScriptChannel(
      'GeneralLongPress',
      onMessageReceived: (JavaScriptMessage message) {
        if (!mounted) return;
        
        try {
          final data = json.decode(message.message) as Map<String, dynamic>;
          final type = data['type'] as String;
          
          if (type == 'general') {
            final x = (data['x'] as num).toDouble();
            final y = (data['y'] as num).toDouble();
            
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              setState(() {
                _tapPosition = Offset(x, y);
              });
              _showGeneralContextMenu(_tapPosition);
            });
          }        } catch (e) {
          print('Error handling general long press: $e');
        }
      },
    );

    await controller.addJavaScriptChannel(      'TextLongPress',
      onMessageReceived: (JavaScriptMessage message) {
        if (!mounted) return;
        print('TextLongPress received: ${message.message}');
        
        try {
          final data = json.decode(message.message) as Map<String, dynamic>;
          final text = data['text'] as String? ?? '';
          final x = (data['x'] as num).toDouble();
          final y = (data['y'] as num).toDouble();
          final isInput = data['isInput'] as bool? ?? false;
          
          print('Text context menu received but ignored - using native Android selection instead');
          // Note: Custom text context menu disabled - using native Android text selection
        } catch (e) {
          print('Error handling text long press: $e');
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
      onPageStarted: _handlePageStarted,      onPageFinished: (String url) async {
        if (!mounted) return;
        print('=== PAGE FINISHED LOADING ==='); // Debug log
        print('URL: $url'); // Debug log
        
        // Get title with fallback
        String? title;
        try {
          title = await controller.getTitle();
          if (title == null || title.isEmpty) {
            title = _extractDomainFromUrl(url);
          }
        } catch (e) {
          print('Error getting title: $e');
          title = _extractDomainFromUrl(url);
        }        print('Title: $title'); // Debug log
        
        // FIXED: Stop loading state and animation using centralized method
        _setLoadingState(false);
        
        // Update URL and title using the centralized method
        _handleUrlUpdate(url, title: title);
        
        // Update navigation state and favicon
        await _updateNavigationState();
        await _optimizationEngine.onPageFinishLoad(url);
        await _updateFavicon(url);
        
        // Setup URL monitoring for dynamic content changes
        Future.microtask(() => _setupUrlMonitoring());
        
        print('Calling _saveToHistory...'); // Debug log
        try {
          await _saveToHistory(url, title);
          print('_saveToHistory completed'); // Debug log
        } catch (e) {
          print('Error in _saveToHistory: $e'); // Debug log          print(e.toString());
          print('Stack trace:');
          print('${StackTrace.current}');
        }
          // Context menu is now handled by _setupScrollHandling() - no need for separate injection
          // await _injectImageContextMenuJS();
          // Initialize theme if this is the home page
        if (url.startsWith('file:///android_asset/main.html') || url == _homeUrl) {
          // Send theme immediately and with retries for better reliability
          _sendThemeToWebView();
          await Future.delayed(const Duration(milliseconds: 100));
          _sendThemeToWebView();
          await _initializeThemeForHomePage();
        }
        
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
    // Skip saving history for special cases - optimized checks for M12
    if (url.isEmpty || 
        url == 'about:blank' ||
        url.startsWith('file://') ||
        url.contains('ERR_') ||
        !url.startsWith('http')) {
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Create simplified history entry
      final newEntry = {
        'url': url,
        'title': title.isNotEmpty ? title : url,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      // Get existing history efficiently
      List<String> history = prefs.getStringList('history') ?? [];
      
      // Remove duplicates efficiently
      history.removeWhere((item) {
        try {
          final existingEntry = json.decode(item);
          return existingEntry['url'] == url;
        } catch (e) {
          return false;
        }
      });
      
      // Add new entry and limit history size for M12 memory management
      history.insert(0, json.encode(newEntry));
      if (history.length > 500) { // Reduced from potentially unlimited
        history = history.take(500).toList();
      }
      
      // Save updated history
      await prefs.setStringList('history', history);

    } catch (e) {
      // Silently handle errors
    }
  }  Future<void> _loadHistory() async {
    // Defer history loading to improve startup performance
    Future.microtask(() async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final history = prefs.getStringList('history') ?? [];
        
        // Process history in chunks to prevent UI blocking on M12
        final List<Map<String, dynamic>> loadedHistory = [];
        for (int i = 0; i < history.length; i += 20) {
          final chunk = history.skip(i).take(20);
          for (final e in chunk) {
            try {
              final parsed = Map<String, dynamic>.from(json.decode(e));
              loadedHistory.add(parsed);
            } catch (e) {
              // Skip corrupted entries silently
              continue;
            }
          }
          
          // Yield control to UI thread between chunks
          if (i + 20 < history.length) {
            await Future.delayed(Duration.zero);
          }
        }
        
        if (mounted) {
          setState(() {
            _loadedHistory = loadedHistory;
            _currentHistoryPage = 0;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _loadedHistory = [];
          });
        }
      }
    });
  }

  void _updateHistory(String url, String title) {
    // Skip updating history for special cases
    if (tabs[currentTabIndex]['isIncognito'] ||  // Skip incognito
        url.isEmpty || title.isEmpty ||        // Skip empty entries
        url == 'about:blank' ||               // Skip blank pages
        url.startsWith('file://') ||          // Skip file URLs
        url.contains('file:///') ||           // Skip file URLs (alternate format)
        url.endsWith('main.html') ||          // Skip main.html
        title == AppLocalizations.of(context)?.new_tab ||                 // Skip new tabs
        title == 'Webpage not available' ||    // Skip error pages
        title == 'Solar Home Page' ||         // Skip Solar home
        title.toLowerCase().contains('not available') || // Skip all error variations
        title.toLowerCase().contains('solar') ||        // Skip all Solar pages
        title.toLowerCase().contains('webpage') ||      // Skip webpage messages
        title == tabs[currentTabIndex]['title']) {        // Skip if title hasn't changed
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
          'favicon': tabs[currentTabIndex]['favicon'],
          'timestamp': DateTime.now().toIso8601String(),
        });
      });
      _saveHistory();
    }
  }  Future<void> _loadUrl(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return;
    
    _setLoadingState(true);
    
    // Optimized panel hiding for M12
    if (_isClassicMode && mounted) {
      setState(() {
        _hideUrlBar = true;
      });
      // Delayed restoration with reduced duration
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          setState(() {
            _hideUrlBar = false;
          });
        }
      });
    }
    
    // Efficient URL processing
    String urlToLoad;
    
    if (trimmedQuery.startsWith('search://')) {
      // Handle search protocol
      final searchTerm = trimmedQuery.substring(9).trim();
      if (searchTerm.isEmpty) {
        _setLoadingState(false);
        return;
      }
      final engine = searchEngines[currentSearchEngine] ?? searchEngines['Google']!;
      urlToLoad = engine.replaceAll('{query}', Uri.encodeComponent(searchTerm));
    } else if (trimmedQuery.startsWith('http://') || trimmedQuery.startsWith('https://')) {
      // Direct URL
      urlToLoad = trimmedQuery;
    } else if (trimmedQuery.contains('.') && !trimmedQuery.contains(' ')) {
      // Domain - add https://
      urlToLoad = 'https://$trimmedQuery';
    } else {
      // Search query
      final engine = searchEngines[currentSearchEngine] ?? searchEngines['Google']!;
      urlToLoad = engine.replaceAll('{query}', Uri.encodeComponent(trimmedQuery));
    }
    
    // Update URL state
    _handleUrlUpdate(urlToLoad);
      // Load URL with error handling
    try {
      await controller.loadRequest(Uri.parse(urlToLoad));
    } catch (e) {
      // FIXED: Use centralized loading state method for proper animation handling
      _setLoadingState(false);
    }
  }
  Future<void> _confirmUrlLoaded(String url, bool success) async {
    // Simplified confirmation for M12 performance
    try {
      const platform = MethodChannel('app.channel.shared.data');
      await platform.invokeMethod('confirmUrlLoaded', {'url': url, 'success': success});
    } catch (e) {
      // Silently handle errors
    }
  }

  void _performSearch({bool searchUp = false}) async {
    final query = _urlController.text.trim();
    if (query.isEmpty) return;

    // Efficient URL processing
    if (query.startsWith('http://') || query.startsWith('https://')) {
      controller.loadRequest(Uri.parse(query));
    } else {
      final engine = searchEngines[currentSearchEngine] ?? searchEngines['google']!;
      final searchUrl = engine.replaceAll('{query}', query);
      controller.loadRequest(Uri.parse(searchUrl));
    }
  }
  Future<void> _shareUrl() async {
    try {
      final url = await controller.currentUrl();
      if (url != null && url.isNotEmpty) {
        // Use native share instead of JavaScript for better M12 performance
        await Share.share(url);
      }
    } catch (e) {
      // Silently handle errors
    }
  }
  // Cached language data for M12 performance
  Map<String, String>? _cachedLanguages;
  
  Future<String> _getCurrentLanguageName() async {
    // Use cached languages to avoid recreating map
    _cachedLanguages ??= {
      'en': 'English', 'tr': 'Türkçe', 'es': 'Español', 'ar': 'العربية',
      'de': 'Deutsch', 'fr': 'Français', 'it': 'Italiano', 'ja': '日本語',
      'ko': '한국어', 'pt': 'Português', 'ru': 'Русский', 'zh': '中文', 'hi': 'हिन्दी',
    };
    
    final prefs = await SharedPreferences.getInstance();
    final currentLocale = prefs.getString('language') ?? 'en';
    return _cachedLanguages![currentLocale] ?? 'English';
  }
  Future<String> _getCurrentSearchEngine() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('searchEngine') ?? currentSearchEngine;
  }
  Future<bool> _getKeepTabsOpenSetting() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('keepTabsOpen') ?? false;
  }
  Future<void> _setKeepTabsOpenSetting(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('keepTabsOpen', value);  }

  // <----NAVIGATION BAR CUSTOMIZATION METHODS---->
  Future<List<String>> _getCustomNavButtons() async {
    final prefs = await SharedPreferences.getInstance();
    final buttonsJson = prefs.getString('customNavButtons');
    if (buttonsJson != null) {
      List<String> buttons = List<String>.from(json.decode(buttonsJson));
      // Ensure menu button is always present to prevent users from being locked out
      if (!buttons.contains('menu')) {
        buttons.add('menu');
      }
      return buttons;
    }
    return ['back', 'forward', 'bookmark', 'share', 'menu']; // Default buttons
  }

  Future<void> _saveCustomNavButtons(List<String> buttons) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('customNavButtons', json.encode(buttons));
    setState(() {
      _customNavButtons = buttons;
    });
  }

  Future<bool> _getNavBarAnimationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('navBarAnimationEnabled') ?? true;
  }

  Future<void> _setNavBarAnimationEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('navBarAnimationEnabled', value);
    setState(() {
      _navBarAnimationEnabled = value;
    });
  }

  Future<void> _resetWelcomeScreen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('first_start', true);
    
    // Show confirmation dialog
    showCustomDialog(
      context: context,      title: AppLocalizations.of(context)!.welcome_screen_reset,
      content: AppLocalizations.of(context)!.welcome_screen_reset_message,
      isDarkMode: ThemeManager.getCurrentTheme().isDark,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            AppLocalizations.of(context)!.ok,
            style: TextStyle(
              color: ThemeManager.getThemeColors(ThemeManager.getCurrentTheme()).textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }  // Optimized settings route creation for M12
  PageRoute _createSettingsRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Simplified transition for better M12 performance
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut, // Simpler curve
          )),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 200), // Faster transition
    );
  }

  void _showGeneralSettings() {
    Navigator.of(context).push(
      _createSettingsRoute(
        Scaffold(
          backgroundColor: ThemeManager.backgroundColor(),
          appBar: AppBar(
            backgroundColor: ThemeManager.backgroundColor(),
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: Icon(
                Icons.chevron_left,
                color: ThemeManager.textColor(),
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              AppLocalizations.of(context)!.general,
              style: TextStyle(
                color: ThemeManager.textColor(),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          body: FutureBuilder<Map<String, dynamic>>(
            future: _getGeneralSettingsInfo(),
            builder: (context, snapshot) {
              final data = snapshot.data ?? {'language': 'English', 'searchEngine': 'Google', 'keepTabsOpen': true};
              
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
                  ),                  _buildSettingsSection(
                    title: AppLocalizations.of(context)!.tabs,
                    children: [                      _buildSettingsToggle(
                        title: AppLocalizations.of(context)!.keep_tabs_open,
                        subtitle: AppLocalizations.of(context)!.keep_tabs_open_description,
                        value: data['keepTabsOpen'] ?? false,
                        onChanged: (value) async {
                          await _setKeepTabsOpenSetting(value);
                          setState(() {});
                        },
                        isFirst: false,
                        isLast: true,
                      ),
                    ],
                  ),
                  _buildSettingsSection(
                    title: AppLocalizations.of(context)!.developer,
                    children: [
                      _buildSettingsItem(
                        title: AppLocalizations.of(context)!.reset_welcome_screen,
                        subtitle: AppLocalizations.of(context)!.show_welcome_screen_next_launch,
                        onTap: () => _resetWelcomeScreen(),
                        isFirst: true,
                        isLast: true,
                      ),
                    ],
                  ),
                ],
              );
            }
          ),
        ),
      ),
    );
  }
  Future<Map<String, dynamic>> _getGeneralSettingsInfo() async {
    final languageName = await _getCurrentLanguageName();
    final searchEngine = await _getCurrentSearchEngine();
    final keepTabsOpen = await _getKeepTabsOpenSetting();
    return {
      'language': languageName,
      'searchEngine': searchEngine,
      'keepTabsOpen': keepTabsOpen,
    };
  }
  void _showClearBrowserDataDialog() {
    bool clearHistory = true;
    bool clearCookies = true;
    bool clearCache = true;

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
                style: TextStyle(color: ThemeManager.textColor()),
              ),
            ),
            CheckboxListTile(
              value: clearCookies,
              onChanged: (value) => setState(() => clearCookies = value!),
              title: Text(
                AppLocalizations.of(context)!.cookies,
                style: TextStyle(color: ThemeManager.textColor()),
              ),
            ),
            CheckboxListTile(
              value: clearCache,
              onChanged: (value) => setState(() => clearCache = value!),
              title: Text(
                AppLocalizations.of(context)!.cache,
                style: TextStyle(color: ThemeManager.textColor()),
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
            style: TextStyle(color: ThemeManager.textSecondaryColor()),
          ),
        ),
        TextButton(
          onPressed: () async {
            // Batch clear operations for M12 efficiency
            final futures = <Future>[];
            if (clearCache) futures.add(controller.clearCache());
            if (clearCookies) futures.add(controller.clearLocalStorage());
            
            await Future.wait(futures);
            
            if (clearHistory) {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('history');
              if (mounted) {
                setState(() {
                  _loadedHistory.clear();
                  _currentHistoryPage = 0;
                });
              }
            }
            
            if (mounted) {
              Navigator.pop(context);              showCustomNotification(
                context: context,
                message: AppLocalizations.of(context)!.browser_data_cleared,
                isDarkMode: isDarkMode,
              );
            }
          },          child: Text(
            AppLocalizations.of(context)!.clear,
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
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
    // Simplified calculations for M12 performance
    final itemHeight = 72.0;
    final headerHeight = 56.0;
    final screenHeight = MediaQuery.of(context).size.height;
    final totalHeight = items.length * itemHeight + headerHeight + 32;
    final maxHeight = screenHeight * 0.7;
    final height = fixedHeight ?? (totalHeight > maxHeight ? maxHeight : totalHeight);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: ThemeManager.textColor().withOpacity(0.1),
      isDismissible: true,
      enableDrag: true,
      builder: (context) => Container(
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
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: items[index],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  void _showLanguageSelection(BuildContext context) {
    Navigator.of(context).push(
      _createSettingsRoute(
        StatefulBuilder(
          builder: (BuildContext context, StateSetter setLanguageScreenState) {
            return Scaffold(
              backgroundColor: ThemeManager.backgroundColor(),
              appBar: AppBar(
                backgroundColor: ThemeManager.backgroundColor(),
                elevation: 0,
                centerTitle: true,
                leading: IconButton(
                  icon: Icon(Icons.chevron_left, color: ThemeManager.textColor(), size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  AppLocalizations.of(context)!.language,
                  style: TextStyle(
                    color: ThemeManager.textColor(),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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
                          _buildAnimatedLanguageItem('English', 'en', currentLanguage, setLanguageScreenState, isFirst: true),
                          _buildAnimatedLanguageItem('Türkçe', 'tr', currentLanguage, setLanguageScreenState),
                          _buildAnimatedLanguageItem('Español', 'es', currentLanguage, setLanguageScreenState),
                          _buildAnimatedLanguageItem('العربية', 'ar', currentLanguage, setLanguageScreenState),
                          _buildAnimatedLanguageItem('Deutsch', 'de', currentLanguage, setLanguageScreenState),
                          _buildAnimatedLanguageItem('Français', 'fr', currentLanguage, setLanguageScreenState),
                          _buildAnimatedLanguageItem('Italiano', 'it', currentLanguage, setLanguageScreenState),
                          _buildAnimatedLanguageItem('日本語', 'ja', currentLanguage, setLanguageScreenState),
                          _buildAnimatedLanguageItem('한국어', 'ko', currentLanguage, setLanguageScreenState),
                          _buildAnimatedLanguageItem('Português', 'pt', currentLanguage, setLanguageScreenState),
                          _buildAnimatedLanguageItem('Русский', 'ru', currentLanguage, setLanguageScreenState),
                          _buildAnimatedLanguageItem('中文', 'zh', currentLanguage, setLanguageScreenState, isLast: true),
                        ],
                      ),
                    ],
                  );
                },
              ),
            );
          }
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
                centerTitle: true,
                leading: IconButton(
                  icon: Icon(Icons.chevron_left, color: ThemeManager.textColor(), size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  AppLocalizations.of(context)!.search_engine,
                  style: TextStyle(
                    color: ThemeManager.textColor(),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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
                          final isFirst = engine == searchEngines.keys.first;
                          final isLast = engine == searchEngines.keys.last;
                          return _buildAnimatedSearchEngineItem(engine, currentSearchEngine, setSearchEngineScreenState, isFirst: isFirst, isLast: isLast);
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
    
    // Save efficiently without await
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('searchEngine', engine);
    });
    
    // Send updated search engine to main.html if it's currently loaded
    if (_isHomePage(_displayUrl)) {
      _sendSearchEngineToMainHtml();
    }
    
    // Callback optimization
    widget.onSearchEngineChange?.call(engine);
    
    // Update screens efficiently
    setSearchEngineScreenState?.call(() {});
  }

  String _getSearchUrl(String query) {
    final engine = searchEngines[currentSearchEngine] ?? searchEngines['google']!;
    return engine.replaceAll('{query}', query);
  }
  Widget _buildAnimatedSearchEngineItem(String engine, String currentSearchEngine, StateSetter setSearchEngineScreenState, {bool isFirst = false, bool isLast = false}) {
    final isSelected = engine == currentSearchEngine;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: EdgeInsets.only(bottom: isLast ? 0 : 1),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _setSearchEngineWithAnimation(engine, setSearchEngineScreenState),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    engine,
                    style: TextStyle(
                      fontSize: 15,
                      color: ThemeManager.textColor(),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
                // Animated tick mark with expanding animation
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.elasticOut,
                  width: isSelected ? 24 : 0,
                  height: isSelected ? 24 : 0,
                  child: isSelected 
                    ? TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.elasticOut,
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        builder: (context, scale, child) {
                          return Transform.scale(
                            scale: scale,
                            child: Icon(
                              Icons.check_circle,
                              color: ThemeManager.primaryColor(),
                              size: 24,
                            ),
                          );
                        },
                      )
                    : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _setSearchEngineWithAnimation(String engine, StateSetter setSearchEngineScreenState) {
    // Update state with animation
    setSearchEngineScreenState(() {
      currentSearchEngine = engine;
      if (_syncHomePageSearchEngine) {
        _homePageSearchEngine = engine;
      }
    });
    
    // Update main state
    setState(() {
      currentSearchEngine = engine;
      if (_syncHomePageSearchEngine) {
        _homePageSearchEngine = engine;
      }
    });
    
    // Save efficiently without await
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('searchEngine', engine);
    });
    
    // Send updated search engine to main.html if it's currently loaded
    if (_isHomePage(_displayUrl)) {
      _sendSearchEngineToMainHtml();
    }
    
    // Callback optimization
    widget.onSearchEngineChange?.call(engine);
  }
  void _showAppearanceSettings() {
    Navigator.of(context).push(
      _createSettingsRoute(
        StatefulBuilder(          builder: (BuildContext context, StateSetter setAppearanceState) {
            // Get current theme name dynamically
            final currentTheme = ThemeManager.getCurrentTheme();
            final currentThemeName = _getThemeName(currentTheme);
            
            print('Appearance Settings - Current theme: ${currentTheme.name}, Display name: $currentThemeName');
            
            return Scaffold(
              backgroundColor: ThemeManager.backgroundColor(),              appBar: AppBar(
                backgroundColor: ThemeManager.backgroundColor(),
                elevation: 0,
                centerTitle: true,
                leading: IconButton(
                  icon: Icon(
                    Icons.chevron_left,
                    color: ThemeManager.textColor(),
                    size: 20,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  AppLocalizations.of(context)!.appearance,
                  style: TextStyle(
                    color: ThemeManager.textColor(),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              body: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  _buildSettingsSection(
                    title: AppLocalizations.of(context)!.appearance,
                    children: [                      _buildSettingsItem(
                        title: AppLocalizations.of(context)!.theme,
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
                    children: [                      _buildSettingsItem(
                        title: AppLocalizations.of(context)!.classic_navigation,
                        subtitle: AppLocalizations.of(context)!.classic_navigation_description,                        trailing: Switch(
                          value: _isClassicMode,
                          onChanged: (value) {
                            _toggleClassicMode(value);
                            setAppearanceState(() {});
                          },
                          activeColor: ThemeManager.primaryColor(),
                        ),                        onTap: () {
                          _toggleClassicMode(!_isClassicMode);
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
              backgroundColor: ThemeManager.backgroundColor(),              appBar: AppBar(
                backgroundColor: ThemeManager.backgroundColor(),
                elevation: 0,
                centerTitle: true,
                systemOverlayStyle: _transparentNavBar,
                leading: IconButton(
                  icon: Icon(
                    Icons.chevron_left,
                    color: ThemeManager.textColor(),
                    size: 20,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),                title: Text(
                  AppLocalizations.of(context)!.appearance,
                  style: TextStyle(
                    color: ThemeManager.textColor(),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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
                        ),                        onTap: () async {
                          print('Theme selected: ${theme.name}, isDark: ${theme.isDark}');
                          
                          // Save and apply theme
                          await ThemeManager.setTheme(theme);
                          print('Theme applied via ThemeManager: ${theme.name}');
                          
                          // Update both UIs immediately
                          setState(() {
                            isDarkMode = theme.isDark;
                          });
                          print('Updated isDarkMode to: $isDarkMode');
                          
                          // Update theme selection screen to show new selection
                          setThemeScreenState(() {
                            // This rebuilds the theme selection screen with new selected theme
                          });
                          print('Updated theme selection screen');
                          
                          // Update appearance settings screen to show new theme name
                          if (setAppearanceState != null) {
                            setAppearanceState(() {
                              // This rebuilds the appearance settings screen with new theme name
                            });
                            print('Updated appearance settings screen');
                          }
                          
                          // Update system bars to match new theme
                          _updateSystemBars();
                          
                          // Save theme preference for persistence
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString('selectedTheme', theme.name);
                          await prefs.setBool('darkMode', theme.isDark);
                          print('Saved theme preferences: ${theme.name}, isDark: ${theme.isDark}');
                          
                          // Clear theme cache to force refresh
                          _cachedDarkColors = null;
                          _cachedLightColors = null;
                          _cachedGlassDecoration = null;
                          
                          // Notify parent widget of theme change
                          if (widget.onThemeChange != null) {
                            widget.onThemeChange!(theme.isDark);
                          }
                          
                          // Send new theme to WebView
                          _sendThemeToWebView();
                          
                          // Force complete rebuild of main app
                          if (mounted) {
                            setState(() {
                              // This triggers a complete rebuild with the new theme
                            });
                          }
                          
                          print('Theme change completed for: ${theme.name}');
                          
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
        return AppLocalizations.of(context)!.systemTheme;
      case ThemeType.light:
        return AppLocalizations.of(context)!.lightTheme;
      case ThemeType.dark:
        return AppLocalizations.of(context)!.darkTheme;
      case ThemeType.tokyoNight:
        return AppLocalizations.of(context)!.tokyoNightTheme;
      case ThemeType.solarizedLight:
        return AppLocalizations.of(context)!.solarizedLightTheme;
      case ThemeType.dracula:
        return AppLocalizations.of(context)!.draculaTheme;
      case ThemeType.nord:
        return AppLocalizations.of(context)!.nordTheme;
      case ThemeType.gruvbox:
        return AppLocalizations.of(context)!.gruvboxTheme;
      case ThemeType.oneDark:
        return AppLocalizations.of(context)!.oneDarkTheme;
      case ThemeType.catppuccin:
        return AppLocalizations.of(context)!.catppuccinTheme;
      case ThemeType.nordLight:
        return AppLocalizations.of(context)!.nordLightTheme;
      case ThemeType.gruvboxLight:
        return AppLocalizations.of(context)!.gruvboxLightTheme;
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
              backgroundColor: ThemeManager.backgroundColor(),              appBar: AppBar(
                backgroundColor: ThemeManager.backgroundColor(),
                elevation: 0,
                centerTitle: true,
                leading: IconButton(
                  icon: Icon(
                    Icons.chevron_left,
                    color: ThemeManager.textColor(),
                    size: 20,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  AppLocalizations.of(context)!.text_size,
                  style: TextStyle(
                    color: ThemeManager.textColor(),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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
        ),      ),
    );
  }

  // Helper method for creating slide transitions for settings pages
  PageRouteBuilder<dynamic> _createSettingsRoute2(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 50),
      reverseTransitionDuration: const Duration(milliseconds: 50),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Forward animation (right to left) - consistent with requirement
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);
          // Reverse animation (slide to right) with fade effect
        if (secondaryAnimation.status == AnimationStatus.forward) {
          return FadeTransition(
            opacity: Tween<double>(begin: 1.0, end: 0.8).animate(
              CurvedAnimation(parent: secondaryAnimation, curve: curve)
            ),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: Offset.zero,
                end: const Offset(0.3, 0.0), // Slide right
              ).animate(CurvedAnimation(parent: secondaryAnimation, curve: curve)),
              child: child,
            ),
          );
        }
        
        return SlideTransition(
          position: offsetAnimation, 
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
  }

  void _showDownloadsSettings() {
    Navigator.of(context).push(
      _createSettingsRoute(
        Scaffold(
          backgroundColor: ThemeManager.backgroundColor(),          appBar: AppBar(
            backgroundColor: ThemeManager.backgroundColor(),
            elevation: 0,
            centerTitle: true,
            systemOverlayStyle: _transparentNavBar,
            leading: IconButton(
              icon: Icon(
                Icons.chevron_left,
                color: ThemeManager.textColor(),
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              AppLocalizations.of(context)!.downloads,
              style: TextStyle(
                color: ThemeManager.textColor(),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              _buildSettingsSection(
                title: AppLocalizations.of(context)!.downloads,
                children: [                  _buildSettingsToggle(
                    title: AppLocalizations.of(context)!.auto_open_downloads,
                    subtitle: AppLocalizations.of(context)!.automatically_open_downloaded_files,
                    value: _autoOpenDownloads,
                    onChanged: (value) async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('autoOpenDownloads', value);
                      setState(() {
                        _autoOpenDownloads = value;
                      });
                    },
                    isFirst: true,
                  ),
                  _buildSettingsToggle(
                    title: AppLocalizations.of(context)!.ask_download_location,
                    subtitle: AppLocalizations.of(context)!.ask_where_to_save_files,
                    value: _askDownloadLocation,
                    onChanged: (value) async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('askDownloadLocation', value);
                      setState(() {
                        _askDownloadLocation = value;
                      });
                    },
                  ),                  FutureBuilder<String>(
                    future: _getDownloadLocation(),
                    builder: (context, snapshot) {
                      final downloadLocation = snapshot.data ?? "Default location";
                      return _buildSettingsItem(
                        title: AppLocalizations.of(context)!.download_location,
                        subtitle: downloadLocation,
                        onTap: _showDownloadLocationPicker,
                      );
                    },
                  ),
                  _buildSettingsItem(
                    title: AppLocalizations.of(context)!.open_downloads_folder,
                    onTap: () async {
                      final downloadLocation = await _getDownloadLocation();
                      await OpenFile.open(downloadLocation);
                    },
                  ),
                  _buildSettingsItem(
                    title: AppLocalizations.of(context)!.clear_downloads_history,
                    onTap: () => _showClearDownloadsConfirmation(),
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

  // <----NAVIGATION BAR CUSTOMIZATION DIALOG---->
  void _showNavigationCustomization() {    showCustomDialog(
      context: context,
      title: AppLocalizations.of(context)!.customize_navigation,
      isDarkMode: isDarkMode,
      customContent: StatefulBuilder(
        builder: (context, setState) {          final availableButtons = {
            'back': {'icon': Icons.chevron_left_rounded, 'label': AppLocalizations.of(context)!.button_back},
            'forward': {'icon': Icons.chevron_right_rounded, 'label': AppLocalizations.of(context)!.button_forward},
            'home': {'icon': Icons.home_rounded, 'label': AppLocalizations.of(context)!.home},
            'new_tab': {'icon': Icons.add_rounded, 'label': AppLocalizations.of(context)!.new_tab},
            'tabs': {'icon': Icons.tab_rounded, 'label': AppLocalizations.of(context)!.tabs},
            'bookmark': {'icon': isCurrentPageBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, 'label': AppLocalizations.of(context)!.button_bookmark},
            'bookmarks': {'icon': Icons.bookmark_border_rounded, 'label': AppLocalizations.of(context)!.button_bookmarks},
            'share': {'icon': Icons.ios_share_rounded, 'label': AppLocalizations.of(context)!.button_share},
            'settings': {'icon': Icons.settings_rounded, 'label': AppLocalizations.of(context)!.settings},
            'downloads': {'icon': Icons.download_rounded, 'label': AppLocalizations.of(context)!.downloads},
            'menu': {'icon': Icons.menu, 'label': AppLocalizations.of(context)!.button_menu},
          };

          return Container(
            width: double.maxFinite,
            constraints: BoxConstraints(maxHeight: 500),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [                Text(
                  AppLocalizations.of(context)!.current_navigation_bar,
                  style: TextStyle(
                    color: ThemeManager.textColor(),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 12),
                Container(
                  height: 60,
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: ThemeManager.surfaceColor().withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: ThemeManager.textColor().withOpacity(0.1),
                    ),
                  ),                  child: ReorderableListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _customNavButtons.length,
                    buildDefaultDragHandles: false, // We'll add custom drag handles
                    proxyDecorator: (child, index, animation) {
                      return AnimatedBuilder(
                        animation: animation,
                        builder: (BuildContext context, Widget? child) {
                          final double animValue = Curves.easeInOut.transform(animation.value);
                          final double elevation = lerpDouble(0, 6, animValue)!;
                          final double scale = lerpDouble(1, 1.1, animValue)!;
                          return Transform.scale(
                            scale: scale,
                            child: Material(
                              elevation: elevation,
                              borderRadius: BorderRadius.circular(8),
                              child: child,
                            ),
                          );
                        },
                        child: child,
                      );
                    },onReorder: (oldIndex, newIndex) {
                      setState(() {
                        if (newIndex > oldIndex) newIndex--;
                        
                        final movedItem = _customNavButtons[oldIndex];
                        
                        // Special handling for menu button - it moves the entire bar as a block
                        if (movedItem == 'menu') {
                          // Remove menu button from current position
                          _customNavButtons.removeAt(oldIndex);
                          
                          // If moving to the first half, put menu at start
                          // If moving to the second half, put menu at end
                          final midPoint = _customNavButtons.length / 2;
                          if (newIndex <= midPoint) {
                            // Put menu at the beginning
                            _customNavButtons.insert(0, 'menu');
                          } else {
                            // Put menu at the end
                            _customNavButtons.add('menu');
                          }
                        } else {
                          // Normal reordering for non-menu buttons
                          // But ensure we don't displace the menu button
                          final menuIndex = _customNavButtons.indexOf('menu');
                          
                          // Remove the item being moved
                          _customNavButtons.removeAt(oldIndex);
                          
                          // Adjust newIndex if menu button affects positioning
                          int adjustedNewIndex = newIndex;
                          if (menuIndex != -1) {
                            if (oldIndex < menuIndex && newIndex >= menuIndex) {
                              // Moving from before menu to after menu position
                              adjustedNewIndex = newIndex;
                            } else if (oldIndex > menuIndex && newIndex <= menuIndex) {
                              // Moving from after menu to before menu position  
                              adjustedNewIndex = newIndex;
                            }
                          }
                          
                          _customNavButtons.insert(adjustedNewIndex, movedItem);
                        }
                      });
                    },                    itemBuilder: (context, index) {
                      final buttonType = _customNavButtons[index];
                      final buttonInfo = availableButtons[buttonType];
                      return Container(
                        key: ValueKey(buttonType),
                        margin: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                        child: ReorderableDragStartListener(
                          index: index,
                          child: Material(
                            color: ThemeManager.surfaceColor(),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: ThemeManager.primaryColor().withOpacity(0.3),
                                ),
                              ),
                              child: Icon(
                                buttonInfo?['icon'] as IconData? ?? Icons.help,
                                color: ThemeManager.textColor(),                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  AppLocalizations.of(context)!.available_buttons,
                  style: TextStyle(
                    color: ThemeManager.textColor(),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 12),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 2.5,
                    ),
                    itemCount: availableButtons.length,
                    itemBuilder: (context, index) {                      final buttonType = availableButtons.keys.elementAt(index);
                      final buttonInfo = availableButtons[buttonType]!;
                      final isInNavBar = _customNavButtons.contains(buttonType);
                      final isMenuButton = buttonType == 'menu';
                      final canRemove = isInNavBar && !isMenuButton;
                      
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),                          onTap: () {
                            setState(() {
                              if (canRemove) {
                                _customNavButtons.remove(buttonType);
                              } else if (!isInNavBar) {
                                if (_customNavButtons.length < 6) {
                                  _customNavButtons.add(buttonType);
                                }
                              }
                            });
                          },
                          child: Container(                            decoration: BoxDecoration(
                              color: isInNavBar 
                                ? (isMenuButton 
                                    ? ThemeManager.primaryColor().withOpacity(0.15)
                                    : ThemeManager.primaryColor().withOpacity(0.1))
                                : ThemeManager.surfaceColor().withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isInNavBar 
                                  ? (isMenuButton
                                      ? ThemeManager.primaryColor().withOpacity(0.5)
                                      : ThemeManager.primaryColor().withOpacity(0.3))
                                  : ThemeManager.textColor().withOpacity(0.1),
                              ),
                            ),                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  buttonInfo['icon'] as IconData,
                                  color: isInNavBar 
                                    ? ThemeManager.primaryColor()
                                    : ThemeManager.textColor(),
                                  size: 16,
                                ),
                                if (isMenuButton && isInNavBar) ...[
                                  SizedBox(width: 2),
                                  Icon(
                                    Icons.lock_rounded,
                                    color: ThemeManager.primaryColor(),
                                    size: 10,
                                  ),
                                ],
                                SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    buttonInfo['label'] as String,
                                    style: TextStyle(
                                      color: isInNavBar 
                                        ? ThemeManager.primaryColor()
                                        : ThemeManager.textColor(),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () {
            setState(() {
              _customNavButtons = ['back', 'forward', 'bookmark', 'share', 'menu'];
            });
            Navigator.pop(context);
          },          child: Text(
            AppLocalizations.of(context)!.reset,
            style: TextStyle(color: ThemeManager.textSecondaryColor()),
          ),
        ),        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            AppLocalizations.of(context)!.cancel,
            style: TextStyle(color: ThemeManager.textSecondaryColor()),
          ),
        ),
        TextButton(
          onPressed: () async {
            await _saveCustomNavButtons(_customNavButtons);
            Navigator.pop(context);
          },
          child: Text(
            AppLocalizations.of(context)!.add,
            style: TextStyle(color: ThemeManager.primaryColor()),
          ),
        ),
      ],
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
    } else if (Platform.isIOS) {      controller.loadRequest(Uri.parse('itms-apps://itunes.apple.com/app/'));
    }
    setState(() {
      isSettingsVisible = false;
    });
  }

  void _showPrivacyPolicy() {
    _loadUrl('https://browser.solar/privacy-policy');
    setState(() {
      isSettingsVisible = false;
    });
  }

  void _showTermsOfUse() {
    _loadUrl('https://browser.solar/terms-of-use');
    setState(() {
      isSettingsVisible = false;
    });
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
                    subtitle: AppLocalizations.of(context)!.version('0.2.1'),
                    isFirst: true,
                    isLast: false,
                  ),
                  _buildSettingsItem(
                    title: AppLocalizations.of(context)!.flutter_version,
                    subtitle: 'Flutter 3.32.0',
                    isFirst: false,
                    isLast: false,
                  ),
                  _buildSettingsItem(
                    title: AppLocalizations.of(context)!.photoncore_version,
                    subtitle: 'Photoncore 0.1.0',
                    isFirst: false,
                    isLast: false,
                  ),
                  _buildSettingsItem(
                    title: AppLocalizations.of(context)!.engine_version,
                    subtitle: '4.7.0',
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
      height: 46 + statusBarHeight, // Match tabs header height exactly
      padding: EdgeInsets.only(top: statusBarHeight),
      decoration: BoxDecoration(
        color: ThemeManager.backgroundColor(),
        boxShadow: [
          BoxShadow(
            color: ThemeManager.textColor().withOpacity(0.08),
            blurRadius: 6,
            offset: Offset(0, 1),
            spreadRadius: 0.5,
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            padding: EdgeInsets.all(12), // Same padding as tabs header
            icon: Icon(
              Icons.chevron_left,
              color: ThemeManager.textColor(),
              size: 20, // Same size as tabs header
            ),
            onPressed: onBack,
          ),
          Expanded(
            child: Text(
              getLocalizedTitle(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16, // Same font size as tabs header
                fontWeight: FontWeight.w600,
                color: ThemeManager.textColor(),
              ),
            ),
          ),
          SizedBox(
            width: 48,
            child: trailing,
          ),
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
    final width = MediaQuery.of(context).size.width - 32; // Match URL bar width calculation
    
    return GestureDetector(
      // Ensure touch events are properly handled
      behavior: HitTestBehavior.opaque,
      // Add tap handler for dismissing by tapping outside
      onTap: () {
        // Absorb tap events to prevent them from going to WebView underneath
      },
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
        width: width, // Use same width as URL bar
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
                children: [                  _buildQuickActionButton(
                    AppLocalizations.of(context)!.settings,
                    Icons.settings_rounded,
                    onPressed: () {
                      _showPanelWithAnimation('settings');
                      setState(() {
                        _isSlideUpPanelVisible = false;
                        _slideUpController.reverse();
                      });
                    },
                  ),                  _buildQuickActionButton(
                    AppLocalizations.of(context)!.downloads,
                    Icons.download_rounded,
                    onPressed: () {
                      _showPanelWithAnimation('downloads');
                      setState(() {
                        _isSlideUpPanelVisible = false;
                        _slideUpController.reverse();
                      });
                    },
                  ),                  _buildQuickActionButton(
                    AppLocalizations.of(context)!.tabs,
                    Icons.tab_rounded,
                    onPressed: () {
                      _showPanelWithAnimation('tabs');
                      setState(() {
                        _isSlideUpPanelVisible = false;
                        _slideUpController.reverse();
                      });
                    },
                  ),
                  _buildQuickActionButton(
                    AppLocalizations.of(context)!.bookmarks,
                    Icons.bookmark_rounded,
                    onPressed: () {
                      _showPanelWithAnimation('bookmarks');                      setState(() {
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
      return url;    }
  }
  
  void _switchTab(int index) {
    if (index < 0 || index >= tabs.length) return;
    
    setState(() {
      currentTabIndex = index;      
      controller = tabs[index]['controller'];
      _displayUrl = tabs[index]['url'];
      
      // Update URL bar text properly
      if (!_urlFocusNode.hasFocus) {
        _urlController.text = _formatUrl(tabs[index]['url']);
      }
      
      // Update navigation state from the tab's stored state
      canGoBack = tabs[index]['canGoBack'];
      canGoForward = tabs[index]['canGoForward'];
      
      // Update security indicator for the switched tab
      isSecure = _isSecureUrl(tabs[index]['url']);
    });
    
    // Update navigation state after switching tabs to ensure accuracy
    _updateNavigationState();
    
    // Reinitialize JavaScript handlers for the tab
    _setupScrollHandlingForController(controller);
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
        children: [          _buildPanelHeader(
            AppLocalizations.of(context)!.downloads,
            onBack: () => _hidePanelWithAnimation(),
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
                                      ),                                      label: Text(
                                        AppLocalizations.of(context)!.cancel,
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
        children: [          _buildPanelHeader(
            AppLocalizations.of(context)!.bookmarks,
            onBack: () => _hidePanelWithAnimation(),
          ),
          Expanded(
            child: bookmarks.isEmpty                ? _buildEmptyState(
                    AppLocalizations.of(context)!.no_bookmarks,
                    Icons.bookmark_outline,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    physics: const BouncingScrollPhysics(),
                    itemCount: bookmarks.length,
                    itemBuilder: (context, index) {
                      final bookmark = bookmarks[index];
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: ThemeManager.surfaceColor().withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: ThemeManager.surfaceColor().withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: bookmark['favicon'] != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      bookmark['favicon'],
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Icon(
                                        Icons.web,
                                        color: ThemeManager.textColor(),
                                        size: 20,
                                      ),
                                    ),
                                  )
                                : Icon(
                                    Icons.web,
                                    color: ThemeManager.textColor(),
                                    size: 20,
                                  ),
                          ),
                          title: Text(
                            bookmark['title'],
                            style: TextStyle(
                              color: ThemeManager.textColor(),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            _getDisplayUrl(bookmark['url']),
                            style: TextStyle(
                              color: ThemeManager.textSecondaryColor(),
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: PopupMenuButton(
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
                                onTap: () {
                                  controller.loadRequest(Uri.parse(bookmark['url']));
                                  setState(() {
                                    isBookmarksVisible = false;
                                  });
                                },
                              ),
                              PopupMenuItem(
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete,
                                      size: 20,
                                      color: Colors.red,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      AppLocalizations.of(context)!.delete,
                                      style: TextStyle(
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () async {
                                  final prefs = await SharedPreferences.getInstance();
                                  final bookmarksList = prefs.getStringList('bookmarks') ?? [];
                                  bookmarksList.removeAt(index);
                                  await prefs.setStringList('bookmarks', bookmarksList);
                                  setState(() {
                                    bookmarks.removeAt(index);
                                  });
                                },
                              ),
                            ],
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
  }  Future<void> _optimizeWebView() async {
    const duration = Duration(minutes: 5);
    Timer.periodic(duration, (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      if (tabs.length > 3) {
        await _checkMemoryAndOptimize();
      }
      
      final now = DateTime.now();
      try {
        for (var i = 0; i < tabs.length; i++) {
          if (i != currentTabIndex) {
            final lastActive = tabs[i]['lastActiveTime'] ?? now;
            final inactiveFor = now.difference(lastActive);
            
            if (inactiveFor.inMinutes > 10) {
              await tabs[i]['controller'].clearCache();
              await tabs[i]['controller'].clearLocalStorage();
            }
          } else {
            tabs[i]['lastActiveTime'] = now;
          }
        }
      } catch (e) {
        // Handle controller errors
      }
    });
    
    try {
      await controller.runJavaScript('''
        document.querySelectorAll('img').forEach(img => {
          img.loading = 'lazy';
          img.decoding = 'async';
        });
        
        document.addEventListener('touchstart', function(){}, {passive: true});
        document.addEventListener('touchmove', function(){}, {passive: true});
        
        document.documentElement.style.transform = 'translateZ(0)';
        document.documentElement.style.backfaceVisibility = 'hidden';
      ''');
      
      await controller.runJavaScript('''
        document.documentElement.style.setProperty('content-visibility', 'auto');
        document.documentElement.style.setProperty('contain', 'layout style');
        document.body.style.setProperty('transform', 'translate3d(0,0,0)');
        
        let scrollTicking = false;
        document.addEventListener('scroll', function() {
          if (!scrollTicking) {
            requestAnimationFrame(() => {
              document.body.style.transform = 'translate3d(0,0,0)';
              scrollTicking = false;
            });
            scrollTicking = true;
          }
        }, { passive: true });
        
        function optimizeImages() {
          const images = document.getElementsByTagName('img');
          for (let img of images) {
            img.loading = 'lazy';
            img.decoding = 'async';
            if (img.naturalWidth > window.innerWidth * 1.5) {
              img.style.maxWidth = '100%';
              img.style.height = 'auto';
            }
          }
        }
        
        const observer = new MutationObserver(() => {
          requestAnimationFrame(optimizeImages);
        });
        
        observer.observe(document.body, {
          childList: true,
          subtree: true
        });
        
        window.addEventListener('load', optimizeImages);
      ''');

      if (Platform.isAndroid) {
        final androidController = controller.platform as webview_flutter_android.AndroidWebViewController;
        await androidController.setMediaPlaybackRequiresUserGesture(false);
        
        await controller.runJavaScript('''
          document.documentElement.style.setProperty('-webkit-transform', 'translate3d(0,0,0)');
          document.documentElement.style.setProperty('-webkit-backface-visibility', 'hidden');
        ''');
      }
    } catch (e) {
      // Handle JavaScript errors
    }
  }  Future<void> _checkMemoryAndOptimize() async {
    try {
      if (tabs.length > 5) {
        for (var i = 0; i < tabs.length; i++) {
          if (i != currentTabIndex) {
            final lastActive = tabs[i]['lastActiveTime'] ?? DateTime.now();
            final inactiveFor = DateTime.now().difference(lastActive);
            
            if (inactiveFor.inMinutes > 15) {
              try {
                await tabs[i]['controller'].runJavaScript('''
                  for (let i = 1; i < 100; i++) {
                    window.clearTimeout(i);
                    window.clearInterval(i);
                  }
                  
                  if (window.performance) {
                    window.performance.clearResourceTimings?.();
                  }
                ''');
              } catch (e) {
                // Handle errors
              }
            }
          }
        }
      }
      
      _lastMemoryCheck = DateTime.now().millisecondsSinceEpoch;
    } catch (e) {
      // Handle errors
    }
  }
  Future<void> _initializeWebViewOptimizations() async {
    // Streamlined WebView optimizations for M12
    try {
      await controller.runJavaScript('''
        // Essential rendering optimization
        document.documentElement.style.setProperty('scroll-behavior', 'auto');
        document.documentElement.style.setProperty('touch-action', 'manipulation');
        
        // Optimized scroll performance
        let scrollTimeout;
        document.addEventListener('scroll', () => {
          document.body.style.willChange = 'transform';
          clearTimeout(scrollTimeout);
          scrollTimeout = setTimeout(() => {
            document.body.style.willChange = 'auto';
          }, 100);
        }, { passive: true });
        
        // Basic image optimization
        document.addEventListener('DOMContentLoaded', () => {
          document.querySelectorAll('img').forEach(img => {
            img.loading = 'lazy';
            img.decoding = 'async';
          });
          
          document.querySelectorAll('iframe').forEach(iframe => {
            iframe.loading = 'lazy';
          });
        });
        
        // Essential hardware acceleration
        document.documentElement.style.setProperty('-webkit-transform', 'translate3d(0,0,0)');
        document.body.style.setProperty('backface-visibility', 'hidden');
      ''');      if (Platform.isAndroid) {
        final androidController = controller.platform as webview_flutter_android.AndroidWebViewController;
        await androidController.setMediaPlaybackRequiresUserGesture(true);
      }
    } catch (e) {      // Silently handle JavaScript errors
    }
  }

  Widget _buildOverlayPanel() {
    final bool isPanelVisible = isTabsVisible || isSettingsVisible || isBookmarksVisible || isDownloadsVisible || isHistoryVisible;
    
    if (!isPanelVisible) return const SizedBox.shrink();
    
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      bottom: 0,
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: () {
            // Close panel when tapping on backdrop
            _hidePanelWithAnimation();          },
          child: Container(
            color: ThemeManager.backgroundColor().withOpacity(0.85),
            child: SlideTransition(
              position: _panelSlideAnimation,
              child: GestureDetector(
                onTap: () {
                  // Prevent closing when tapping on the panel content itself
                },                onVerticalDragUpdate: (details) {
                  if (details.delta.dy > 8) {
                    _hidePanelWithAnimation();
                  }
                },
                child: isTabsVisible 
                    ? _buildTabsPanel()
                    : isSettingsVisible
                      ? _buildSettingsPanel()
                    : isBookmarksVisible
                      ? _buildBookmarksPanel()
                    : isHistoryVisible
                      ? _buildHistoryPanel()
                    : isDownloadsVisible
                        ? _buildDownloadsPanel()
                        : Container(),
                ),
              ),
            ),
          ),
        ),
      );
    
  }
  
  Widget _buildTabsPanel() {
    final displayTabs = tabs.where((tab) => 
      !tab['url'].startsWith('file:///') && 
      !tab['url'].startsWith('about:blank') && 
      tab['url'] != _homeUrl
    ).toList();

    return Container(
      height: MediaQuery.of(context).size.height,
      color: ThemeManager.backgroundColor(),
      child: Column(
        children: [
          // Compact header optimized for M12
          Container(
            height: 44 + MediaQuery.of(context).padding.top, // Further reduced
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            decoration: BoxDecoration(
              color: ThemeManager.backgroundColor(),
              boxShadow: [
                BoxShadow(
                  color: ThemeManager.textColor().withOpacity(0.06),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  padding: EdgeInsets.all(10),
                  icon: Icon(
                    Icons.chevron_left,
                    color: ThemeManager.textColor(),
                    size: 18,
                  ),
                  onPressed: () => _hidePanelWithAnimation(),
                ),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.tabs,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: ThemeManager.textColor(),
                    ),
                  ),
                ),
                SizedBox(width: 44), // Balance
              ],
            ),
          ),
          // Content area
          Expanded(
            child: displayTabs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.tab_unselected_rounded,
                        size: 40,
                        color: ThemeManager.surfaceColor().withOpacity(0.2),
                      ),
                      SizedBox(height: 12),
                      Text(
                        AppLocalizations.of(context)!.no_tabs_open,
                        style: TextStyle(
                          fontSize: 14,
                          color: ThemeManager.textSecondaryColor(),
                        ),
                      ),
                    ],
                  ),
                )
              : _buildVerticalTabsList(displayTabs),
          ),
          // Bottom action bar
          _buildBottomActionBar(),
        ],
      ),
    );
  }  // Simplified vertical tabs list for M12 performance
  Widget _buildVerticalTabsList(List<Map<String, dynamic>> displayTabs) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      physics: BouncingScrollPhysics(),
      itemCount: displayTabs.length,
      itemBuilder: (context, index) {
        final tab = displayTabs[index];
        return _buildSimpleTabItem(tab);
      },
    );
  }

  // Simplified tab item without grouping for M12 performance
  Widget _buildSimpleTabItem(Map<String, dynamic> tab) {
    final isCurrentTab = tab == tabs[currentTabIndex];
    
    return Container(
      margin: EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
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
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: ThemeManager.surfaceColor().withOpacity(isCurrentTab ? 0.12 : 0.04),
              borderRadius: BorderRadius.circular(12),
              border: isCurrentTab ? Border.all(
                color: ThemeManager.primaryColor().withOpacity(0.3),
                width: 1,
              ) : null,
            ),
            child: Row(
              children: [
                // Active indicator
                if (isCurrentTab) ...[
                  Container(
                    width: 3,
                    height: 32,
                    decoration: BoxDecoration(
                      color: ThemeManager.primaryColor(),
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),
                  SizedBox(width: 10),
                ] else
                  SizedBox(width: 13),
                
                // Favicon
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: ThemeManager.surfaceColor().withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(                    child: tab['favicon'] != null && !tab['isIncognito']
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            tab['favicon'],
                            width: 20,
                            height: 20,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              tab['isIncognito'] ? Icons.visibility_off_rounded : Icons.language_rounded,
                              size: 16,
                              color: ThemeManager.textSecondaryColor(),
                            ),
                          ),
                        )
                      : Icon(
                          tab['isIncognito'] ? Icons.visibility_off_rounded : Icons.language_rounded,
                          size: 16,
                          color: ThemeManager.textSecondaryColor(),
                        ),
                  ),
                ),
                
                SizedBox(width: 16),
                
                // Tab title and URL
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [                      Text(
                        tab['title'].isEmpty ? _getDisplayUrl(tab['url']) : tab['title'],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isCurrentTab ? FontWeight.w600 : FontWeight.w500,
                          color: ThemeManager.textColor(),
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          if (tab['isIncognito']) ...[
                            Icon(
                              Icons.visibility_off_rounded,
                              size: 14,
                              color: ThemeManager.textSecondaryColor(),
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Incognito',
                              style: TextStyle(
                                fontSize: 12,
                                color: ThemeManager.textSecondaryColor(),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              '•',
                              style: TextStyle(
                                fontSize: 12,
                                color: ThemeManager.textSecondaryColor(),
                              ),
                            ),
                            SizedBox(width: 8),
                          ],
                          Expanded(
                            child: Text(
                              _getDisplayUrl(tab['url']),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: ThemeManager.textSecondaryColor(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                SizedBox(width: 16),
                
                // Close button
                Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => _closeTab(tabs.indexOf(tab)),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: ThemeManager.surfaceColor().withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: ThemeManager.textColor().withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: ThemeManager.textSecondaryColor(),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _closeGroup(TabGroup group) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: ThemeManager.surfaceColor(),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),          title: Text(
            AppLocalizations.of(context)!.close_group,
            style: TextStyle(
              color: ThemeManager.textColor(),
              fontWeight: FontWeight.w600,
            ),
          ),content: Text(
            AppLocalizations.of(context)!.close_all_tabs_in_group(group.name),
            style: TextStyle(
              color: ThemeManager.textSecondaryColor(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),              child: Text(
                AppLocalizations.of(context)!.cancel,
                style: TextStyle(
                  color: ThemeManager.textSecondaryColor(),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  tabs.removeWhere((tab) => tab['groupId'] == group.id);
                  if (tabs.isEmpty) {
                    _addNewTab();
                  } else if (currentTabIndex >= tabs.length) {
                    currentTabIndex = tabs.length - 1;                    controller = tabs[currentTabIndex]['controller'];
                    _displayUrl = tabs[currentTabIndex]['url'];
                    _urlController.text = _formatUrl(tabs[currentTabIndex]['url']);
                  }
                });
              },              child: Text(
                AppLocalizations.of(context)!.close_group,
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
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
  
  Widget _buildHistoryPanel() {
    print('Building history panel with ${_loadedHistory.length} items');
    print('History panel theme colors - bg: ${ThemeManager.backgroundColor()}, text: ${ThemeManager.textColor()}');
    
    return Container(
      height: MediaQuery.of(context).size.height,
      color: ThemeManager.backgroundColor(),
      child: Column(
        children: [
          // Modernized compact header with just back button and title
          Container(
            height: 46 + MediaQuery.of(context).padding.top, // Reduced height from 56 to 46
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
              decoration: BoxDecoration(
                color: ThemeManager.backgroundColor(),
                boxShadow: [
                  BoxShadow(
                    color: ThemeManager.textColor().withOpacity(0.08),
                    blurRadius: 6,
                    offset: Offset(0, 1),
                    spreadRadius: 0.5,
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    padding: EdgeInsets.all(12),
                    icon: Icon(
                      Icons.chevron_left,
                      color: ThemeManager.textColor(),
                      size: 20,
                    ),                    onPressed: () {
                      _hidePanelWithAnimation();
                    },
                  ),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.history,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: ThemeManager.textColor(),
                      ),
                    ),
                  ),                  IconButton(
                    padding: EdgeInsets.all(12),
                    icon: Icon(
                      Icons.delete_outline,
                      color: ThemeManager.textColor(),
                      size: 20,
                    ),
                    onPressed: () => _showClearHistoryDialog(),
                    tooltip: AppLocalizations.of(context)!.clear_all_history,
                  ),
                ],
              ),
            ),
            // Content area
            Expanded(
              child: _loadedHistory.isEmpty
                ? _buildEmptyState(AppLocalizations.of(context)!.no_history, Icons.history)
                : _buildHistoryList(),
            ),
          ],
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
              size: 40,
              color: ThemeManager.surfaceColor().withOpacity(0.2),
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!.no_history,
              style: TextStyle(
                fontSize: 14,
                color: ThemeManager.textSecondaryColor(),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _historyScrollController,
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      itemCount: _loadedHistory.length,
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        final historyItem = _loadedHistory[index];
        final url = historyItem['url'] as String;
        final title = historyItem['title'] as String;
        final favicon = historyItem['favicon'] as String?;
        final timestamp = DateTime.parse(historyItem['timestamp'] as String);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          decoration: BoxDecoration(
            color: ThemeManager.surfaceColor().withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            leading: SizedBox(
              width: 20,
              height: 20,
              child: favicon != null
                  ? Image.network(
                      favicon,
                      width: 16,
                      height: 16,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.public,
                        size: 12,
                        color: ThemeManager.textSecondaryColor(),
                      ),
                    )
                  : Icon(
                      Icons.public,
                      size: 12,
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
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  url.length > 40 ? '${url.substring(0, 40)}...' : url,
                  style: TextStyle(
                    color: ThemeManager.textSecondaryColor(),
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _formatHistoryDate(timestamp),
                  style: TextStyle(
                    color: ThemeManager.textSecondaryColor(),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            trailing: IconButton(
              icon: Icon(
                Icons.delete_outline,
                color: ThemeManager.textSecondaryColor(),
                size: 18,
              ),
              onPressed: () => _removeHistoryItem(index),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            onTap: () {
              // Optimized tap handling for M12
              setState(() {
                isHistoryVisible = false;
              });
              // Immediate load without delay for better responsiveness
              _loadUrl(url);
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
          return AppLocalizations.of(context)!.just_now;
        }
        return AppLocalizations.of(context)!.min_ago(difference.inMinutes);
      }
      return AppLocalizations.of(context)!.hr_ago(difference.inHours);
    } else if (difference.inDays == 1) {
      return AppLocalizations.of(context)!.yesterday;
    } else if (difference.inDays < 7) {
      return AppLocalizations.of(context)!.days_ago(difference.inDays);
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
            onBack: () => _hidePanelWithAnimation()
          ),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              children: [
                // General Section
                _buildSettingsSection(
                  title: AppLocalizations.of(context)!.general,
                  children: [
                    _buildSettingsItem(
                      title: AppLocalizations.of(context)!.language,
                      subtitle: _getLanguageName(currentLanguage),
                      onTap: () => _showLanguageSelection(context),
                    ),
                    _buildSettingsItem(
                      title: AppLocalizations.of(context)!.search_engine,
                      subtitle: currentSearchEngine,
                      onTap: () => _showSearchEngineSelection(context),
                    ),
                    _buildSettingsItem(
                      title: AppLocalizations.of(context)!.keep_tabs_open,
                      trailing: Switch(
                        value: _keepTabsOpen,
                        onChanged: (value) {
                          setState(() {
                            _keepTabsOpen = value;
                          });
                          _setKeepTabsOpenSetting(value);
                        },
                        activeColor: ThemeManager.primaryColor(),
                      ),
                    ),
                    _buildSettingsItem(
                      title: AppLocalizations.of(context)!.custom_home_page,
                      trailing: Switch(
                        value: useCustomHomePage,
                        onChanged: (value) {
                          setState(() {
                            useCustomHomePage = value;
                            if (value && customHomeUrl.isEmpty) {
                              _showCustomHomeUrlDialog();
                            }
                          });
                          _savePreferences();
                        },
                        activeColor: ThemeManager.primaryColor(),
                      ),
                    ),
                    _buildSettingsItem(
                      title: AppLocalizations.of(context)!.set_home_page_url,
                      subtitle: customHomeUrl.isEmpty ? 
                        AppLocalizations.of(context)!.not_set : 
                        customHomeUrl,
                      onTap: () => _showCustomHomeUrlDialog(),
                      isLast: true,
                    ),
                  ],
                ),                // Appearance Section
                _buildSettingsSection(
                  title: AppLocalizations.of(context)!.appearance,
                  children: [                    _buildSettingsItem(
                      title: AppLocalizations.of(context)!.chooseTheme,
                      subtitle: _getThemeName(ThemeManager.getCurrentTheme()),
                      onTap: () => _showThemeSelection(context),
                    ),
                    _buildSettingsItem(
                      title: AppLocalizations.of(context)!.text_size,
                      subtitle: _getTextSizeLabel(),
                      onTap: () => _showTextSizeSelection(context),
                    ),                    _buildSettingsItem(
                      title: AppLocalizations.of(context)!.classic_navigation,
                      trailing: Switch(
                        value: _isClassicMode,
                        onChanged: (value) => _toggleClassicMode(value),
                        activeColor: ThemeManager.primaryColor(),
                      ),
                    ),
                    // Always show navigation customization (synchronized with classic mode)
                    _buildSettingsItem(
                      title: AppLocalizations.of(context)!.customize_navigation,
                      subtitle: AppLocalizations.of(context)!.rearrange_navigation_buttons,
                      onTap: () => _showNavigationCustomization(),
                      isLast: true,
                    ),
                  ],
                ),                // AI Section
                _buildSettingsSection(
                  title: AppLocalizations.of(context)!.ai,
                  children: [
                    _buildSettingsItem(
                      title: AppLocalizations.of(context)!.summary_length,
                      subtitle: _getCurrentSummaryLengthLabel(),
                      onTap: () => _showSummaryLengthSelection(),
                    ),
                    _buildSettingsItem(
                      title: AppLocalizations.of(context)!.summary_language,
                      subtitle: _getCurrentSummaryLanguageLabel(),
                      onTap: () => _showSummaryLanguageSelection(),
                      isLast: true,
                    ),
                  ],
                ),                // Other Section
                _buildSettingsSection(
                  title: AppLocalizations.of(context)!.other,
                  children: [
                    _buildSettingsButton('help', () => _showHelpPage()),
                    _buildSettingsButton('rate_us', () => _showRateUs()),
                    _buildSettingsButton('privacy_policy', () => _showPrivacyPolicy()),
                    _buildSettingsButton('terms_of_use', () => _showTermsOfUse()),
                    _buildSettingsButton('about', () => _showAboutPage(), isLast: true),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionBanner() {
    // Manual permission checking only - no automatic checks for better UI performance
    if (_cachedPermissionState == null) {
      // Show manual check button instead of automatic checking
      return Container(
        margin: const EdgeInsets.all(12),
        height: 110,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [Colors.blue.withValues(alpha: 0.8), Colors.blue.withValues(alpha: 0.6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                // Manual permission check when user taps
                await _checkAllPermissions();
                if (mounted) setState(() {});
              },
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
                            AppLocalizations.of(context)!.storage_permission_required,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),                          Text(
                            AppLocalizations.of(context)!.tap_to_check_permission_status,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        await _checkAllPermissions();
                        if (mounted) setState(() {});
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      child: Text(AppLocalizations.of(context)!.check),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final bool hasAllPermissions = _cachedPermissionState!;

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
                          ),                        ),
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
  }

  Future<bool> _checkAllPermissions() async {
    // Use cached result if available and not expired
    if (_cachedPermissionState != null && 
        _lastPermissionCheck != null &&
        DateTime.now().difference(_lastPermissionCheck!) < _permissionCacheTimeout) {
      return _cachedPermissionState!;
    }

    final androidInfo = await DeviceInfoPlugin().androidInfo;
    final sdkInt = androidInfo.version.sdkInt;
    
    bool result;
    if (sdkInt >= 33) {
      final photos = await Permission.photos.status;
      final videos = await Permission.videos.status;
      final audio = await Permission.audio.status;
      final notifications = await Permission.notification.status;
      result = photos.isGranted && videos.isGranted && audio.isGranted && notifications.isGranted;
    } else {
      final storage = await Permission.storage.status;
      final notifications = await Permission.notification.status;
      result = storage.isGranted && notifications.isGranted;
    }

    // Cache the result
    _cachedPermissionState = result;
    _lastPermissionCheck = DateTime.now();
    
    return result;
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
      ].request();    }
    
    // Invalidate permission cache after request
    _cachedPermissionState = null;
    _lastPermissionCheck = null;
    
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
    );  }  Future<void> _showClearDownloadsConfirmation() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ThemeManager.backgroundColor(),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          AppLocalizations.of(context)!.clear_downloads_history,
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
              await prefs.setStringList('downloads', []);
              setState(() {
                downloads.clear();
              });
              Navigator.pop(context);
              _showNotification(
                Text(AppLocalizations.of(context)!.downloads_history_cleared),
                duration: const Duration(seconds: 2),
              );
            },
            child: Text(
              AppLocalizations.of(context)!.clear,
              style: TextStyle(
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );  }  Future<void> _showClearHistoryDialog() async {
    showCustomDialog(
      context: context,
      title: AppLocalizations.of(context)!.clear_all_history,
      isDarkMode: ThemeManager.getCurrentTheme().isDark,
      content: AppLocalizations.of(context)!.clear_all_history_confirm,
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
            await prefs.setStringList('history', []);
            setState(() {
              _loadedHistory.clear();
            });
            Navigator.pop(context);
            _showNotification(
              Text(AppLocalizations.of(context)!.history_cleared),
              duration: const Duration(seconds: 2),
            );
          },          child: Text(
            AppLocalizations.of(context)!.clear,
            style: TextStyle(
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
              AppLocalizations.of(context)!.bookmark_removed,
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
    
    final title = await controller.getTitle() ?? AppLocalizations.of(context)!.untitled;
    
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

  Future<void> _suspendTab(Map<String, dynamic> tab) async {
    await tab['controller'].clearCache();
    await tab['controller'].clearLocalStorage();
    _suspendedTabs.add(tab);
    tabs.remove(tab);
  }

  void _resumeTab(Map<String, dynamic> tab) {
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
            tabs[currentTabIndex]['title'] = title;
          });
        }
      });

      controller.currentUrl().then((url) {
        if (mounted && url != null) {
          setState(() {
            tabs[currentTabIndex]['url'] = url;
            _displayUrl = url;
          });
        }
      });    }
  }
  
  void _addNewTab({String? url, bool isIncognito = false, String? groupId}) {
    // Use custom home page if enabled and url is empty or default home
    String targetUrl;
    if ((url == null || url == _homeUrl || url == 'file:///android_asset/main.html') && 
        useCustomHomePage && customHomeUrl.isNotEmpty) {
      print('Using custom home page URL: $customHomeUrl');
      targetUrl = customHomeUrl;
    } else {
      targetUrl = url ?? (useCustomHomePage && customHomeUrl.isNotEmpty ? customHomeUrl : _homeUrl);
    }
    final newTab = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'url': targetUrl,
      'title': isIncognito ? AppLocalizations.of(context)!.new_incognito_tab : AppLocalizations.of(context)!.new_tab,
      'favicon': null,
      'isIncognito': isIncognito,
      'groupId': groupId,
      'controller': WebViewController(),
      'canGoBack': false,
      'canGoForward': false,
      'lastActiveTime': DateTime.now(),
    };    setState(() {
      tabs.add(newTab);
      currentTabIndex = tabs.length - 1;
      controller = newTab['controller'] as WebViewController;
      
      // Properly update URL display for new tab
      _displayUrl = targetUrl;
      
      // Update navigation state
      canGoBack = false; // New tabs can't go back initially
      canGoForward = false; // New tabs can't go forward initially
      
      // Update security status based on the new tab's URL
      isSecure = _isSecureUrl(targetUrl);
      
      // Update URL bar text properly
      if (!_urlFocusNode.hasFocus) {
        _urlController.text = _formatUrl(targetUrl);
      }
    });

    _initializeTab(newTab).then((_) async {
      // <----ACTUALLY LOAD THE URL INTO THE WEBVIEW---->
      // CRITICAL: Load the URL into the WebViewController AFTER initialization
      try {
        await controller.loadRequest(Uri.parse(targetUrl));
        print('New tab loaded with URL: $targetUrl');
        
        // Send theme to main.html if it's the home page
        if (targetUrl == _homeUrl || targetUrl.contains('main.html')) {
          await Future.delayed(const Duration(milliseconds: 500));
          await _sendThemeToMainHtml();
        }
      } catch (e) {
        print('Error loading URL in new tab: $e');
      }
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
      duration: const Duration(milliseconds: 900), // Reduced from 1 second to 900ms for a snappier feel
      curve: Curves.easeInOutCubic, // Added easing curve for smoother animation
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
    final isHomePage = _isHomePage(_displayUrl);
    
    return Container(
      width: width,
      margin: EdgeInsets.only(bottom: _isClassicMode ? 0 : 6),
      child: SlideTransition(
        position: _hideUrlBarAnimation,        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [            // URL bar and background logic
            _isClassicMode 
              ? AnimatedBuilder(
                  animation: _aiActionBarAnimation,
                  builder: (context, child) {
                    final isExpanded = _isAiActionBarVisible && !isHomePage;
                    final expandedHeight = isExpanded ? _aiActionBarHeightAnimation.value : 0;                    final animationProgress = _aiActionBarAnimation.value;
                      return Container(
                      width: width,
                      height: 44 + expandedHeight.toDouble(),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        color: (keyboardVisible) 
                            ? ThemeManager.surfaceColor().withOpacity(0.9)
                            : ThemeManager.surfaceColor().withOpacity(0.8),
                        border: Border.all(
                          color: ThemeManager.textColor().withOpacity(0.08),
                          width: 1,
                        ),
                      ),
                      child: Stack(
                        children: [
                          // AI action bar content at top (inside the container)
                          if (expandedHeight > 0)
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              height: expandedHeight.toDouble(),
                              child: Opacity(
                                opacity: animationProgress,
                                child: _buildAiActionBarContent(width),
                              ),
                            ),
                          // URL bar content at bottom with dynamic border radius
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: _buildUrlBarContent(width, keyboardVisible, isExpanded),
                          ),
                          // Loading animation border overlay
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
                    );
                  },
                )
              : GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragUpdate: (details) {
                    setState(() {
                      _urlBarSlideOffset += details.delta.dx;
                    });
                  },
                  onHorizontalDragEnd: (details) async {
                    const threshold = 40.0; // Reduced threshold for M12
                    const velocity = 600.0; // Reduced velocity for M12
                    
                    if (_urlBarSlideOffset.abs() > threshold || details.primaryVelocity!.abs() > velocity) {
                      if ((_urlBarSlideOffset < 0 || details.primaryVelocity! < -velocity) && canGoBack) {
                        setState(() {
                          _urlBarSlideOffset = -MediaQuery.of(context).size.width;
                        });
                        await Future.delayed(const Duration(milliseconds: 100)); // Reduced delay
                        await _goBack();
                      } else if ((_urlBarSlideOffset > 0 || details.primaryVelocity! > velocity) && canGoForward) {
                        setState(() {
                          _urlBarSlideOffset = MediaQuery.of(context).size.width;
                        });
                        await Future.delayed(const Duration(milliseconds: 100)); // Reduced delay
                        await _goForward();
                      }
                    }
                    
                    setState(() {
                      _urlBarSlideOffset = 0;
                    });
                  },                  child: AnimatedBuilder(
                    animation: _aiActionBarAnimation,
                    builder: (context, child) {
                      final isExpanded = _isAiActionBarVisible && !isHomePage;
                      final expandedHeight = isExpanded ? _aiActionBarHeightAnimation.value : 0;
                      final animationProgress = _aiActionBarAnimation.value;
                      
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        transform: Matrix4.translationValues(_urlBarSlideOffset, 0, 0),
                        height: 44 + expandedHeight.toDouble(),                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          color: (keyboardVisible) 
                              ? ThemeManager.surfaceColor().withOpacity(0.9)
                              : ThemeManager.surfaceColor().withOpacity(0.8),
                          border: Border.all(
                            color: ThemeManager.textColor().withOpacity(0.08),
                            width: 1,
                          ),
                        ),child: Stack(
                          children: [
                            // AI action bar content at top (inside the container)
                            if (expandedHeight > 0)
                              Positioned(
                                top: 0,
                                left: 0,
                                right: 0,
                                height: expandedHeight.toDouble(),
                                child: Opacity(
                                  opacity: animationProgress,
                                  child: _buildAiActionBarContent(width),
                                ),
                              ),
                            // URL bar content at bottom with dynamic border radius
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: _buildUrlBarContent(width, keyboardVisible, isExpanded),
                            ),
                            // Loading animation border overlay
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
                      );
                    },
                  ),
                ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildUrlBarContent(double width, bool keyboardVisible, [bool isExpanded = false]) {
    final isHomePage = _isHomePage(_displayUrl); // Use the centralized homepage detection
    final urlStatus = _getUrlBarStatus(_displayUrl);
    
    // Dynamic border radius based on AI Action Bar expansion
    final borderRadius = isExpanded 
        ? const BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
            topLeft: Radius.circular(0),
            topRight: Radius.circular(0),
          )
        : BorderRadius.circular(24);
      return AnimatedBuilder(
      animation: _urlBarBorderAnimation,
      builder: (context, child) {
        return ClipRRect(
          borderRadius: borderRadius,
          child: Container(
            width: width,
            height: 44, // Fixed height for URL bar content only
            child: Material(
              type: MaterialType.transparency,
              child: Row(
                children: [
                  const SizedBox(width: 14),                  // FIXED: Proper status indicator based on URL type with theme colors
                  Icon(
                    urlStatus == 'home' ? Icons.home_rounded :
                    urlStatus == 'secure' ? Icons.shield : Icons.warning_amber_rounded,
                    size: 14,
                    color: urlStatus == 'home' ? ThemeManager.primaryColor() :
                           urlStatus == 'secure' ? ThemeManager.primaryColor() : ThemeManager.textSecondaryColor(),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _urlController,
                      focusNode: _urlFocusNode,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: ThemeManager.textColor(),
                        fontSize: 15,
                      ),
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.search_or_type_url,
                        hintStyle: TextStyle(
                          color: ThemeManager.textColor().withOpacity(0.4),
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      onTap: () {
                        if (!_urlFocusNode.hasFocus) {                          setState(() {
                            if (_isHomePage(_displayUrl)) {
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
                        _urlFocusNode.requestFocus();
                      },
                      onSubmitted: (value) {
                        _loadUrl(value);
                        _urlFocusNode.unfocus();                      },
                    ),                  ),                  // Hide AI/Awesome button on home page
                  if (!isHomePage)
                    Padding(
                      padding: const EdgeInsets.only(left: 1.0),
                      child: IconButton(
                        icon: Icon(
                          Icons.auto_awesome,
                          size: 18,
                          color: _isAiActionBarVisible 
                            ? ThemeManager.primaryColor()
                            : ThemeManager.textColor(),
                        ),
                        onPressed: _toggleAiActionBar,
                      ),
                    ),
                  IconButton(
                    icon: Icon(
                      _urlFocusNode.hasFocus ? Icons.close : Icons.refresh,
                      size: 18,
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
                          controller.reload();                        },                  ),                ],
              ),
            ),
          ),
        );
      },
    );
  }
  // <----AI ACTION BAR METHODS---->
  void _toggleAiActionBar() {
    setState(() {
      _isAiActionBarVisible = !_isAiActionBarVisible;
    });
    
    if (_isAiActionBarVisible) {
      _aiActionBarController.forward();
    } else {
      _aiActionBarController.reverse();
    }
  }
  void _closeAiActionBar() {
    if (_isAiActionBarVisible) {
      // Mark as not visible immediately to prevent further interactions
      setState(() {
        _isAiActionBarVisible = false;
      });
      
      // Run the animation to hide it smoothly
      _aiActionBarController.reverse();
    }
  }
  void _handleSummarize() async {
    try {
      // Close the action bar first
      _closeAiActionBar();
      
      // Get current page URL and content
      final currentUrl = await controller.currentUrl();
      if (currentUrl == null || currentUrl.isEmpty) {        showCustomNotification(
          context: context,
          message: AppLocalizations.of(context)!.no_page_to_summarize,
          icon: Icons.warning,
          iconColor: Colors.orange,
          isDarkMode: isDarkMode,
        );
        return;
      }
      
      // Extract page content for summarization
      String pageContent = '';
      try {
        pageContent = await controller.runJavaScriptReturningResult(
          'document.body.innerText || document.body.textContent || ""'
        ) as String;
      } catch (e) {
        // Fallback - try to get any text content
        try {
          pageContent = await controller.runJavaScriptReturningResult(
            'document.documentElement.innerText || document.documentElement.textContent || ""'
          ) as String;
        } catch (e2) {
          pageContent = '';
        }
      }
      
      if (pageContent.trim().isEmpty) {        showCustomNotification(
          context: context,
          message: AppLocalizations.of(context)!.no_content_found_to_summarize,
          icon: Icons.warning,
          iconColor: Colors.orange,
          isDarkMode: isDarkMode,
        );
        return;
      }
      
      // Show summary modal with actual content
      _showSummaryModal(currentUrl, pageContent);
      
    } catch (e) {      showCustomNotification(
        context: context,
        message: AppLocalizations.of(context)!.failed_to_generate_summary,
        icon: Icons.error,
        iconColor: Colors.red,
        isDarkMode: isDarkMode,
      );
    }
  }
  void _handlePreviousSummaries() {
    // Close the action bar first
    _closeAiActionBar();
    
    // Show previous summaries modal
    _showPreviousSummariesModal();
  }

  void _handleOutsideTap() {
    // Only hide AI action bar if it's visible
    if (_isAiActionBarVisible) {
      _closeAiActionBar();
    }
  }

  // Helper method to get favicon URL
  Future<String?> _getFaviconUrl(String pageUrl) async {
    try {
      final faviconUrl = await controller.runJavaScriptReturningResult('''
        (function() {
          var link = document.querySelector("link[rel*='icon']");
          if (link && link.href) {
            return link.href;
          }
          // Fallback to standard favicon.ico
          var url = new URL(window.location.href);
          return url.origin + '/favicon.ico';
        })();
      ''') as String?;
      return faviconUrl?.isNotEmpty == true ? faviconUrl : null;
    } catch (e) {
      // Return standard favicon path as fallback
      try {
        final uri = Uri.parse(pageUrl);
        return '${uri.scheme}://${uri.host}/favicon.ico';
      } catch (e2) {
        return null;
      }    }
  }
  
  void _handlePWA() async {
    try {
      // Close the action bar first
      _closeAiActionBar();
      
      final currentUrl = await controller.currentUrl();
      if (currentUrl == null || currentUrl.isEmpty) {
        showCustomNotification(
          context: context,
          message: AppLocalizations.of(context)!.no_page_to_install,
          isDarkMode: ThemeManager.getCurrentTheme().isDark,
        );
        return;
      }
      
      // Get page title for PWA name
      String pageTitle = await controller.getTitle() ?? "Web App";
      
      // Get favicon for better PWA experience
      String? faviconUrl = await _getFaviconUrl(currentUrl);
      
      // Direct PWA installation using the correct method
      final success = await PWAManager.savePWA(
        context,
        currentUrl,
        pageTitle,
        faviconUrl,
      );
      
      if (success) {
        showCustomNotification(
          context: context,
          message: "${AppLocalizations.of(context)!.pwa_installed}: $pageTitle",
          icon: Icons.check_circle,
          iconColor: Colors.green,
          isDarkMode: ThemeManager.getCurrentTheme().isDark,
        );
      } else {
        showCustomNotification(
          context: context,
          message: AppLocalizations.of(context)!.failed_to_install_pwa,
          icon: Icons.error,
          iconColor: Colors.red,
          isDarkMode: ThemeManager.getCurrentTheme().isDark,
        );
      }
      
    } catch (e) {
      showCustomNotification(
        context: context,
        message: "${AppLocalizations.of(context)!.failed_to_install_pwa}: ${e.toString()}",
        icon: Icons.error,
        iconColor: Colors.red,
        isDarkMode: ThemeManager.getCurrentTheme().isDark,
      );
    }
  }Widget _buildAiActionBarContent(double width) {
    return AnimatedBuilder(
      animation: _aiActionBarHeightAnimation,
      builder: (context, child) {
        return Container(
          width: width,
          height: _aiActionBarHeightAnimation.value,
          // Remove decoration - let parent handle all styling
          padding: const EdgeInsets.all(8), // Add padding inside the container
          child: _aiActionBarHeightAnimation.value > 30 
            ? Row(
                children: [
                  Expanded(                    child: _buildAiActionButton(
                      icon: Icons.summarize_outlined,
                      label: AppLocalizations.of(context)!.summarize,
                      onTap: _handleSummarize,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: ThemeManager.textColor().withOpacity(0.1),
                  ),
                  Expanded(                    child: _buildAiActionButton(
                      icon: Icons.history_outlined,
                      label: AppLocalizations.of(context)!.previous_summaries,
                      onTap: _handlePreviousSummaries,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: ThemeManager.textColor().withOpacity(0.1),
                  ),
                  Expanded(                    child: _buildAiActionButton(
                      icon: Icons.install_mobile_outlined,
                      label: AppLocalizations.of(context)!.pwa,
                      onTap: _handlePWA,
                    ),
                  ),
                ],
              )
            : const SizedBox.shrink(),
        );
      },
    );
  }

  Widget _buildAiActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: ThemeManager.textColor(),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: ThemeManager.textColor(),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
  Future<WebViewController> _createWebViewController() async {
    final controller = await _initializeWebViewController();
    
    // Simplified initialization for M12
    try {
      // Context menu is now handled by _setupScrollHandling() - no need for separate injection
      // await _injectImageContextMenuJS();
    } catch (e) {
      // Silently handle errors
    }
    
    return controller;
  }  DateTime? _lastBackPressTime;
  Future<bool> _onWillPop() async {
    // Close AI action bar first if it's visible
    if (_isAiActionBarVisible) {
      _toggleAiActionBar();
      return false;
    }
    
    // Fast panel check - only check visible panels
    if (isTabsVisible || isSettingsVisible || isBookmarksVisible || isDownloadsVisible || isHistoryVisible) {
      _hidePanelWithAnimation();
      return false;
    }

    if (await controller.canGoBack()) {
      await _goBack();
      return false;
    }

    if (_lastBackPressTime == null || 
        DateTime.now().difference(_lastBackPressTime!) > const Duration(seconds: 2)) {      showCustomNotification(
        context: context,
        message: AppLocalizations.of(context)!.press_back_to_exit,
        isDarkMode: isDarkMode,
      );
      
      _lastBackPressTime = DateTime.now();
      return false;    }
    return true;
  }

  // Context menu functionality for images and text selection
  Future<void> _showContextMenu(Map<String, dynamic> hitTestResult, WebViewController webViewController) async {
    final BuildContext? context = this.context;
    if (context == null || !mounted) return;

    try {
      // Get hit test information from JavaScript
      final String jsResult = await webViewController.runJavaScriptReturningResult('''
        (function() {
          const selection = window.getSelection();
          const selectedText = selection.toString().trim();
          
          // Check if user clicked on an image
          const elementFromPoint = document.elementFromPoint(
            window.lastTouchX || 0,
            window.lastTouchY || 0
          );
          
          let isImage = false;
          let imageUrl = '';
          
          if (elementFromPoint) {
            if (elementFromPoint.tagName === 'IMG') {
              isImage = true;
              imageUrl = elementFromPoint.src;
            } else {
              // Check if element has background image
              const style = window.getComputedStyle(elementFromPoint);
              const bgImage = style.backgroundImage;
              if (bgImage && bgImage !== 'none') {
                const match = bgImage.match(/url\\(["']?([^"'\\)]+)["']?\\)/);
                if (match) {
                  isImage = true;
                  imageUrl = match[1];
                }
              }
            }
          }
          
          return JSON.stringify({
            isImage: isImage,
            imageUrl: imageUrl,
            hasSelectedText: selectedText.length > 0,
            selectedText: selectedText
          });
        })();
      ''') as String;

      final Map<String, dynamic> result = jsonDecode(jsResult.replaceAll('"', ''));
      final bool isImage = result['isImage'] ?? false;
      final String imageUrl = result['imageUrl'] ?? '';
      final bool hasSelectedText = result['hasSelectedText'] ?? false;
      final String selectedText = result['selectedText'] ?? '';

      if (isImage && imageUrl.isNotEmpty) {
        _showImageContextMenu({
          'src': imageUrl,
          'alt': '',
        });
      } else if (hasSelectedText) {
        // Note: Text context menu disabled - using native Android text selection instead
        print('Text selection detected but using native Android menu instead');
      }
    } catch (e) {
      print('Error showing context menu: $e');
    }
  }

  // Context menu actions - using existing download system
  bool get _hasClipboardContent {
    // This should be updated to check actual clipboard content
    // For now, we'll assume there might be content available
    return true;
  }

  Future<void> _copyText(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    _showNotification(Text(_getLocalizedContextText('textCopied', 'Text copied to clipboard')));
  }

  Future<void> _pasteText(WebViewController webViewController) async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData?.text != null && clipboardData!.text!.isNotEmpty) {
        // Escape the text to prevent JavaScript injection
        final escapedText = clipboardData.text!
            .replaceAll('\\', '\\\\')
            .replaceAll('"', '\\"')
            .replaceAll('\n', '\\n')
            .replaceAll('\r', '\\r');
            
        await webViewController.runJavaScript('''
          const activeElement = document.activeElement;
          if (activeElement && (activeElement.tagName === 'INPUT' || activeElement.tagName === 'TEXTAREA' || activeElement.contentEditable === 'true')) {
            const text = "$escapedText";
            if (activeElement.tagName === 'INPUT' || activeElement.tagName === 'TEXTAREA') {
              const start = activeElement.selectionStart || 0;
              const end = activeElement.selectionEnd || 0;
              const value = activeElement.value || '';
              activeElement.value = value.substring(0, start) + text + value.substring(end);
              activeElement.selectionStart = activeElement.selectionEnd = start + text.length;
              
              // Trigger input event for frameworks
              activeElement.dispatchEvent(new Event('input', { bubbles: true }));
            } else if (activeElement.contentEditable === 'true') {
              document.execCommand('insertText', false, text);
            }
          }
        ''');        _showNotification(Text(_getLocalizedContextText('textPasted', 'Text pasted')));
      } else {
        _showNotification(Text(_getLocalizedContextText('clipboardEmpty', 'Clipboard is empty')));
      }
    } catch (e) {
      _showNotification(Text(_getLocalizedContextText('pasteError', 'Error pasting text')));
      print('Paste error: $e');
    }
  }

  Future<void> _cutText(String selectedText, WebViewController webViewController) async {
    try {
      await Clipboard.setData(ClipboardData(text: selectedText));
      
      // Remove the selected text from the input field
      await webViewController.runJavaScript('''
        const selection = window.getSelection();
        const activeElement = document.activeElement;
        
        if (activeElement && (activeElement.tagName === 'INPUT' || activeElement.tagName === 'TEXTAREA')) {
          const start = activeElement.selectionStart || 0;
          const end = activeElement.selectionEnd || 0;
          const value = activeElement.value || '';
          activeElement.value = value.substring(0, start) + value.substring(end);
          activeElement.selectionStart = activeElement.selectionEnd = start;
          
          // Trigger input event for frameworks
          activeElement.dispatchEvent(new Event('input', { bubbles: true }));
        } else if (selection && selection.toString().trim() === "$selectedText") {
          selection.deleteFromDocument();
        }
      ''');        _showNotification(Text(_getLocalizedContextText('textCut', 'Text cut to clipboard')));
    } catch (e) {
      _showNotification(Text(_getLocalizedContextText('cutError', 'Error cutting text')));
      print('Cut error: $e');
    }  }

  // Helper method for context menu localization with fallback
  String _getLocalizedContextText(String key, String fallback) {
    try {
      final localizations = AppLocalizations.of(context);
      if (localizations == null) return fallback;
      
      // Map new context menu keys to existing localization keys where possible
      switch (key) {
        // Image context menu - use existing keys or fallback
        case 'downloadImage':
          return localizations.download_image;
        case 'copyImage':
          return localizations.copy_image;
        case 'openImageNewTab':
          return localizations.open_image_in_new_tab;
        
        // Text context menu
        case 'copyText':
          return localizations.copy;
        case 'pasteText':
          return localizations.paste;
        case 'cutText':
          return localizations.cut;
        
        // Notifications - use existing keys or fallback
        case 'storagePermissionRequired':
          return localizations.permission_denied;
        case 'downloadingImage':
          return localizations.downloading;
        case 'imageDownloaded':
          return localizations.download_completed;
        case 'downloadFailed':
          return localizations.download_failed;
        case 'downloadError':
          return localizations.download_failed;
        case 'imageUrlCopied':
          return localizations.image_url_copied;
        case 'imageOpenedNewTab':
          return localizations.opened_in_new_tab;
        case 'textCopied':
          return localizations.text_copied;
        case 'textPasted':
          return localizations.text_pasted;
        case 'textCut':
          return localizations.text_cut;
        case 'clipboardEmpty':
          return localizations.clipboard_empty;
        case 'pasteError':
          return localizations.paste_error;
        case 'cutError':
          return localizations.cut_error;
        
        default:
          return fallback;
      }
    } catch (e) {
      return fallback;
    }
  }

  Future<List<String>> _onFileSelector(FileSelectorParams params) async {
    // Handle file selection if needed for web file inputs
    try {
      // Extract the accept types from the parameters if available
      final List<String> acceptTypes = params.acceptTypes ?? [];
      FileType fileType = FileType.any;
      
      // Determine file type based on accepted types
      if (acceptTypes.isNotEmpty) {
        if (acceptTypes.any((type) => type.contains('image') || type.contains('.jpg') || type.contains('.png') || type.contains('.gif'))) {
          fileType = FileType.image;
        } else if (acceptTypes.any((type) => type.contains('video'))) {
          fileType = FileType.video;
        } else if (acceptTypes.any((type) => type.contains('audio'))) {
          fileType = FileType.audio;
        } else if (acceptTypes.any((type) => type.contains('.pdf') || type.contains('application/pdf'))) {
          fileType = FileType.custom;
        } else if (acceptTypes.any((type) => type.contains('.doc') || type.contains('.docx') || type.contains('.xls') || 
                                type.contains('.xlsx') || type.contains('.ppt') || type.contains('.pptx') || 
                                type.contains('application/msword') || type.contains('application/vnd.ms-excel'))) {
          fileType = FileType.custom;
        }
      }
      
      // Customize file extensions based on accept types
      List<String> allowedExtensions = [];
      if (fileType == FileType.custom) {
        for (final type in acceptTypes) {
          if (type.startsWith('.')) {
            // Remove the dot and add to extensions
            allowedExtensions.add(type.substring(1));
          } else if (type.contains('/')) {
            // For MIME types, extract potential extensions
            if (type.contains('pdf')) allowedExtensions.add('pdf');
            if (type.contains('msword')) allowedExtensions.addAll(['doc', 'docx']);
            if (type.contains('excel')) allowedExtensions.addAll(['xls', 'xlsx']);
            if (type.contains('powerpoint')) allowedExtensions.addAll(['ppt', 'pptx']);
            if (type.contains('text')) allowedExtensions.addAll(['txt', 'rtf']);
          }
        }
      }

      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false, // Default to single file selection since params doesn't expose this
        type: fileType,
        allowedExtensions: allowedExtensions.isNotEmpty ? allowedExtensions : null,
      );
      
      if (result != null && result.files.isNotEmpty) {
        return result.files
            .where((file) => file.path != null)
            .map((file) => file.path!)
            .toList();
      }
    } catch (e) {
      print('File selector error: $e');
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;    // Force show URL bar when any panel is visible or when classic mode is toggled
    if ((isTabsVisible || isSettingsVisible || isBookmarksVisible || isDownloadsVisible || isHistoryVisible) && _hideUrlBar) {
      _hideUrlBar = false;
      _hideUrlBarController.reverse();
    }
    
    // Ensure standard UI elements are visible when classic mode is off
    final bool showStandardControls = !_isClassicMode || (_isClassicMode && (_hideUrlBar || isTabsVisible || isSettingsVisible || isBookmarksVisible || isDownloadsVisible || isHistoryVisible));
    
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
                ignoring: keyboardVisible,                child: GestureDetector(
                  onTap: () {
                    // Handle outside tap for AI action bar
                    _handleOutsideTap();
                    
                    if (_isSlideUpPanelVisible) {
                      setState(() {
                        _isSlideUpPanelVisible = false;
                        _slideUpController.reverse();
                        _hideUrlBar = false;
                        _hideUrlBarController.reverse();
                      });
                    }
                  },onLongPressStart: (details) async {
                    // Long press functionality removed
                  },child: Container(
                    // Use Container with color to cover entire area including where keyboard would be
                    color: ThemeManager.backgroundColor(),
                    child: WebViewWidget(
                      key: ValueKey('webview_$currentTabIndex'),
                      controller: controller,
                    ),
                  ),
                ),
              ),
            ),            // WebView scroll detector with padding - Fixed position
            if (!isTabsVisible && !isSettingsVisible && !isBookmarksVisible && !isDownloadsVisible)
              Positioned(
                top: statusBarHeight,
                left: 0,
                right: 0,              // Adjust bottom position to account for keyboard and buttons
                bottom: keyboardVisible 
                  ? keyboardHeight + 120 // Ensure enough space for URL bar and buttons when keyboard is visible
                  : (_isClassicMode ? 116 : 60), // Fixed bottom padding based on mode
                child: IgnorePointer(
                  ignoring: _isSlideUpPanelVisible || keyboardVisible,
                  child: Listener(
                    behavior: HitTestBehavior.translucent,
                                         onPointerDown: (PointerDownEvent event) {
                      // Store the pointer down position and time for long press detection
                      _pointerDownPosition = event.position;
                      _pointerDownTime = DateTime.now();
                      _isPointerMoved = false;
                      
                      // Start long press timer with shorter duration for better responsiveness
                      _longPressTimer?.cancel();
                      _longPressTimer = Timer(const Duration(milliseconds: 400), () {
                        if (_isPointerMoved) return;
                        
                        // Vibrate to provide haptic feedback for long press
                        HapticFeedback.mediumImpact();
                        
                        // Check if the pointer is still down and hasn't moved much
                        if (_pointerDownPosition != null) {
                          print('🖐️ Long press detected at ${_pointerDownPosition!}');
                          
                          // Trigger JavaScript to check if there's an image or text at this position
                          _checkForImageAtPosition(_pointerDownPosition!);
                        }
                      });
                    },
                    onPointerMove: (PointerMoveEvent event) {
                      // Don't allow URL bar hide/show when keyboard is visible
                      if (keyboardVisible) return;
                      
                      // Check if we've moved enough to cancel long press
                      if (_pointerDownPosition != null) {
                        final distance = (event.position - _pointerDownPosition!).distance;
                        if (distance > 10) {
                          _isPointerMoved = true;
                          _longPressTimer?.cancel();
                        }
                      }
                      
                      // Handle scroll events for both classic and non-classic modes
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
                    onPointerUp: (PointerUpEvent event) {
                      // Cancel long press detection
                      _longPressTimer?.cancel();
                      _pointerDownPosition = null;
                    },
                    onPointerCancel: (PointerCancelEvent event) {
                      // Cancel long press detection
                      _longPressTimer?.cancel();
                      _pointerDownPosition = null;
                    },
                  ),
                ),
              ),
            
            // Overlay panels (tabs, settings, etc.)
            if (isTabsVisible || isSettingsVisible || isBookmarksVisible || isDownloadsVisible || isHistoryVisible)
              _buildOverlayPanel(),
                // Classic mode navigation panel with background that extends up to the URL bar
            if (_isClassicMode)
              AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                opacity: (_hideUrlBar || isTabsVisible || isSettingsVisible || isBookmarksVisible || isDownloadsVisible || isHistoryVisible) ? 0.0 : 1.0,                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                  offset: (_hideUrlBar || isTabsVisible || isSettingsVisible || isBookmarksVisible || isDownloadsVisible || isHistoryVisible) ? const Offset(0, 1) : Offset.zero,
                  child: Stack(
                    children: [
                      // Create a seamless background that visually connects with the URL bar
                      Positioned(
                        bottom: keyboardVisible ? keyboardHeight : 0, // Position above keyboard when visible
                        left: 0,
                        right: 0,
                        height: 48 + MediaQuery.of(context).padding.bottom + 8 + 60, // Extended height to connect with URL bar
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)), // Smooth rounded top
                          child: Container(
                            decoration: BoxDecoration(
                              color: ThemeManager.backgroundColor(),
                              border: Border(
                                top: BorderSide(
                                  color: ThemeManager.textColor().withOpacity(0.08),
                                  width: 1,
                                ),
                              ),
                            ),
                          ),
                        ),                      ),
                      // Add the navigation buttons
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: _buildClassicModePanel(),
                      ),
                    ],
                  ),
                ),
              ),
                // Bottom controls (URL bar and panels) - show when no panels are visible or classic mode is off
            if (!isTabsVisible && !isSettingsVisible && !isBookmarksVisible && !isDownloadsVisible && !isHistoryVisible)
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                // Position from top to bottom to allow slide panel to cover full screen
                bottom: 0,                child: Stack(
                  children: [
                    // Quick actions and navigation panels - hide when keyboard is visible
                    if (!keyboardVisible)
                      AnimatedBuilder(
                        animation: _slideUpController,
                        builder: (context, child) {
                          // Using CurvedAnimation for smoother transitions
                          final slideValue = CurvedAnimation(
                            parent: _slideUpController,
                            curve: Curves.easeOutQuint, // More modern animation curve
                          ).value;
                          return Visibility(
                            visible: slideValue > 0,
                            maintainState: false,
                            child: Stack(
                              children: [
                                // Backdrop - tapping here dismisses panel
                                Positioned.fill(
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.translucent,
                                    onTap: () {
                                      _handleSlideUpPanelVisibility(false);
                                    },
                                    child: Container(
                                      color: Colors.black.withOpacity(0.05 * slideValue),
                                    ),
                                  ),
                                ),
                                // Panel content positioned at bottom
                                Positioned(
                                  left: 16,
                                  right: 16,
                                  bottom: keyboardVisible 
                                     ? (_isClassicMode 
                                        ? keyboardHeight + 56 // Classic mode - reduced from 65 to 56
                                        : keyboardHeight + 8) // Non-classic mode - small spacing above keyboard
                                     : (_isClassicMode 
                                        ? 56 + MediaQuery.of(context).padding.bottom // Classic mode fixed position - reduced from 70 to 56
                                        : MediaQuery.of(context).padding.bottom + 16), // Regular mode fixed position
                                  child: Transform.translate(
                                    offset: Offset(0, (1 - slideValue) * 200), // Slide from bottom of screen
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
                                ),
                              ],
                            ),
                          );
                        },
                      ),                    // URL bar positioned at bottom
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: keyboardVisible 
                         ? (_isClassicMode 
                            ? keyboardHeight + 56 // Classic mode - reduced from 65 to 56
                            : keyboardHeight + 8) // Non-classic mode - small spacing above keyboard
                         : (_isClassicMode 
                            ? 56 + MediaQuery.of(context).padding.bottom // Classic mode fixed position - reduced from 70 to 56
                            : MediaQuery.of(context).padding.bottom + 16), // Regular mode fixed position
                      child: AnimatedOpacity(
                        opacity: 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
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
                                      
                                      if (details.primaryVelocity != null) {                                        if (!_isSlideUpPanelVisible && details.primaryVelocity! < -100) {
                                          _handleSlideUpPanelVisibility(true);
                                        } else if (_isSlideUpPanelVisible && details.primaryVelocity! > 100) {
                                          _handleSlideUpPanelVisibility(false);
                                        }
                                      }
                                    },
                                    child: _buildUrlBar(),
                                  ),
                            ),
                            // Summary panel for Task 3
                            if (_isSummaryPanelVisible)
                              _buildSummaryPanel(),
                          ],
                        ),
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
  void didUpdateWidget(BrowserScreen oldWidget) {
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
  }  // Update URL when page changes
  void _updateUrl(String url) {
    if (!mounted) return;
    
    // Use the centralized URL update method for consistency
    _handleUrlUpdate(url);
  }

// New helper method to handle page start logic consistently  
Future<void> _handlePageStarted(String url) async {
    if (!mounted) return;
    print('=== PAGE STARTED LOADING ==='); // Debug log
    print('URL: $url'); // Debug log
    
    // Use the centralized loading state method (this will start the animation)
    _setLoadingState(true);
    
    // Update URL immediately on start (for instant feedback)
    _handleUrlUpdate(url);
    
    await _updateNavigationState();
    await _optimizationEngine.onPageStartLoad(url);    // Send theme early for home page
    if (url.startsWith('file:///android_asset/main.html') || url == _homeUrl) {
      _sendThemeToWebView();
      _sendLanguageToMainHtml();
      _sendSearchEngineToMainHtml();
    }
  }

  // Navigation delegate methods
  Future<NavigationDelegate> get _navigationDelegate async {
    return NavigationDelegate(      onNavigationRequest: (NavigationRequest request) async {
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
        
        // FIXED: Update URL immediately when navigation starts (for immediate feedback)
        print('🚀 Navigation request to: ${request.url}');
        _handleUrlUpdate(request.url);
        
        // Allow navigation for all other URLs
        return NavigationDecision.navigate;
      },      onPageStarted: (String url) async {
        if (!mounted) return;
        
        print('DEBUG: onPageStarted called with URL: $url');
        _setLoadingState(true);
        
        // FIXED: Always update URL immediately on page start for better responsiveness
        print('🚀 Page started, updating URL to: $url');
        _handleUrlUpdate(url);
        
        await _updateNavigationState();
        await _optimizationEngine.onPageStartLoad(url);      },      onPageFinished: (String url) async {
        if (!mounted) return;
        
        print('DEBUG: onPageFinished called with URL: $url');
        final title = await controller.getTitle() ?? _displayUrl;
        
        // FIXED: Use centralized loading state method for proper animation handling
        _setLoadingState(false);
        
        // Force URL update on page finish - this ensures we always get the final URL
        print('DEBUG: Forcing URL update from onPageFinished to: $url');
        _displayUrl = url; // Update display URL first
        _handleUrlUpdate(url, title: title);
        
        // Always ensure URL bar and classic mode panel are visible when page finishes loading
        setState(() {
          _hideUrlBar = false;
        });
        _hideUrlBarController.reverse();
          await _updateNavigationState();
        await _optimizationEngine.onPageFinishLoad(url);
        await _updateFavicon(url);
        await _saveToHistory(url, title);        
        
        // Re-inject context menu JavaScript on every page load since JS context resets
        await _setupScrollHandling();
      },      onUrlChange: (UrlChange change) {
        if (mounted && change.url != null) {
          final url = change.url!;
          print('DEBUG: onUrlChange called with URL: $url');
          print('🔄 URL changed in browser, updating to: $url');
          // FIXED: Immediate URL update for better responsiveness during navigation
          _handleUrlUpdate(url);
        }
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
          !isPanelExpanded &&          !isTabsVisible && 
          !isSettingsVisible && 
          !isBookmarksVisible && 
          !isDownloadsVisible && 
          !isHistoryVisible && 
          !isSearchMode) {
        setState(() {
          _urlBarOffset = const Offset(16.0, 0.0);
        });
      }
    });
  }
  
  // Start periodic URL sync to ensure URL bar is always accurate
  void _startUrlSync() {
    _urlSyncTimer?.cancel();
    _urlSyncTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      try {
        final currentUrl = await controller.currentUrl();
        if (currentUrl != null && currentUrl != _displayUrl && !_urlFocusNode.hasFocus) {
          print('🔄 URL sync detected change: $_displayUrl -> $currentUrl');
          _handleUrlUpdate(currentUrl);
        }
      } catch (e) {
        // Silently handle errors
      }
    });
  }
  
  // Stop URL sync timer
  void _stopUrlSync() {
    _urlSyncTimer?.cancel();
  }
  void _updateUrlBarState() {
    if (!_urlFocusNode.hasFocus && !isPanelExpanded) {
      setState(() {
        _urlBarOffset = Offset(16.0, _urlBarOffset.dy);
      });
    }
  }
  String _formatUrl(String url, {bool showFull = false}) {
    // For home page URL, show empty URL bar
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
      
      // When not focused, show formatted domain with proper formatting
      String domain = uri.host;
      
      // Remove www. prefix for cleaner display
      if (domain.startsWith('www.')) {
        domain = domain.substring(4);
      }
      
      // For common domains, show them nicely formatted
      if (domain.isNotEmpty) {
        return domain;
      }
        // Fallback to showing the full URL if domain extraction fails
      return url;
    } catch (e) {
      // If URL can't be parsed, show as is
      return url;
    }
  }
  // Helper method to check if URL is secure
  bool _isSecureUrl(String url) {
    try {
      final uri = Uri.parse(url);
      // HTTPS is secure
      if (uri.scheme == 'https') return true;
      // Local files are considered secure
      if (uri.scheme == 'file' || url.startsWith('file://')) return true;
      // Everything else is not secure
      return false;
    } catch (e) {
      return false;
    }
  }

  // FIXED: Helper method to check if URL is the homepage
  bool _isHomePage(String url) {
    return url.startsWith('file:///android_asset/main.html') || url == _homeUrl;
  }

  // FIXED: Get appropriate status indicator for URL bar
  String _getUrlBarStatus(String url) {
    if (_isHomePage(url)) {
      return 'home';
    } else if (_isSecureUrl(url)) {
      return 'secure';
    } else {
      return 'insecure';
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
        await prefs.setStringList('downloads', downloadsList);        await _loadDownloads();

        // Trigger media scan for better gallery visibility
        await _triggerMediaScan(finalFilePath);

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
      await prefs.setStringList('downloads', downloadsList);      // Immediately refresh the downloads list
      await _loadDownloads();

      // Trigger media scan for better gallery visibility
      await _triggerMediaScan(finalFilePath);

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

  // Trigger media scan to make downloaded files visible in gallery immediately
  Future<void> _triggerMediaScan(String filePath) async {
    try {
      // Use platform channel to trigger media scan on Android
      const platform = MethodChannel('com.solar.browser/media_scan');
      await platform.invokeMethod('scanFile', {'path': filePath});
    } catch (e) {
      print('Failed to trigger media scan: $e');
      // Fallback: try to trigger using file operations that might trigger automatic scan
      try {
        final file = File(filePath);
        if (await file.exists()) {
          // Touch the file to potentially trigger media scanner
          await file.setLastModified(DateTime.now());
        }
      } catch (e2) {
        print('Fallback media scan also failed: $e2');
      }
    }
  }

  // Save URL bar position for icon state
  Future<void> _saveUrlBarPosition() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('urlBarOffsetX', _urlBarOffset.dx);
  }
  // Load URL bar position for icon state
  Future<void> _loadUrlBarPosition() async {
    final prefs = await SharedPreferences.getInstance();    setState(() {
      _urlBarOffset = const Offset(16.0, 0.0);
    });
  }

  Future<void> _refreshPage() async {
    try {
      if (tabs.isNotEmpty && currentTabIndex >= 0 && currentTabIndex < tabs.length) {
        await tabs[currentTabIndex]['controller'].reload();
      }
    } catch (e) {
      print('Error refreshing page: $e');
    }
  }

  void _showNotification(Widget content, {Duration? duration, SnackBarAction? action}) {
    // Simplified notification extraction for M12 performance
    String message = 'Notification';
    IconData? icon;
    Color? iconColor;
    
    if (content is Text) {
      message = content.data ?? message;
    } else if (content is Row) {
      // Simplified row parsing for M12
      final children = (content as Row).children;
      for (final child in children) {
        if (child is Icon) {
          icon = child.icon;
          iconColor = child.color;
        } else if (child is Text) {
          message = child.data ?? message;
        } else if (child is Expanded && child.child is Text) {
          message = (child.child as Text).data ?? message;
        }
      }
    }

    // Use simplified notification for M12
    showCustomNotification(
      context: context,
      message: message,
      icon: icon,
      iconColor: iconColor,
      duration: duration ?? const Duration(seconds: 2), // Reduced from 3 seconds
      action: action,
      isDarkMode: isDarkMode,
    );
  }
  void _showClearDownloadsDialog() {
    showCustomDialog(
      context: context,
      title: AppLocalizations.of(context)!.clear_downloads_history_title,
      isDarkMode: ThemeManager.getCurrentTheme().isDark,
      content: AppLocalizations.of(context)!.clear_downloads_history_confirm,
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
          },          child: Text(
            AppLocalizations.of(context)!.clear,
            style: TextStyle(
              color: ThemeManager.errorColor(),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
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

  ImageProvider _getFaviconImage() {    if (tabs.isNotEmpty && tabs[currentTabIndex]['favicon'] != null) {
      return NetworkImage(tabs[currentTabIndex]['favicon']!);
    } else if (_currentFaviconUrl != null && _currentFaviconUrl!.isNotEmpty) {
      return NetworkImage(_currentFaviconUrl!);
    }
    return const AssetImage('assets/icons/globe.png');
  }
  // Slide panel state
  bool _isSlideUpPanelVisible = false;
  double _slideUpPanelOffset = 0.0;
  double _slideUpPanelOpacity = 0.0;

  bool get isSlideUpPanelVisible => _isSlideUpPanelVisible;  void _handleSlideUpPanelVisibility(bool show) {
    setState(() {
      _isSlideUpPanelVisible = show;
      if (show) {
        _slideUpController.forward();
        // Always hide URL bar when showing panels, even in classic mode
        // This ensures the classic mode panel also hides when slide-up panel is shown
        _hideUrlBar = true;
        _hideUrlBarController.forward();
      } else {
        _slideUpController.reverse();
        // Always show URL bar when hiding panels
        _hideUrlBar = false;
        _hideUrlBarController.reverse();
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
            tabs[currentTabIndex]['favicon'] = faviconUrl;
          }
        });
      }
    } catch (e) {
      print('Error updating favicon: $e');
    }
  }  Widget _buildNavigationPanel() {
    final width = MediaQuery.of(context).size.width - 32; // Match URL bar width calculation
    
    return GestureDetector(
      // Ensure touch events are properly handled
      behavior: HitTestBehavior.opaque,
      onTap: () {
        // Absorb tap events to prevent them from going to WebView underneath
      },
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
        width: width, // Use same width as URL bar
        height: 44, // Reduced from 48
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24), // Always keep full rounded corners
          border: Border.all(
            color: ThemeManager.textColor().withOpacity(0.08),
            width: 1,
          ),
          color: ThemeManager.backgroundColor().withOpacity(0.8), // Simplified without blur for M12
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded, size: 22), // Reduced size
              color: canGoBack ? ThemeManager.textColor() : ThemeManager.textColor().withOpacity(0.3),
              onPressed: canGoBack ? () {
                _goBack();
              } : null,
            ),
            // FIXED: Added home button with proper navigation
            IconButton(
              icon: const Icon(Icons.home_rounded, size: 22),
              color: _isHomePage(_displayUrl) ? ThemeManager.primaryColor() : ThemeManager.textColor(),
              onPressed: () async {
                try {
                  await controller.loadRequest(Uri.parse(_homeUrl));
                  _handleUrlUpdate(_homeUrl);
                } catch (e) {
                  print('Error navigating to home: $e');
                }
              },
            ),
            IconButton(
              icon: Icon(
                isCurrentPageBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                size: 22, // Reduced size
              ),
              color: ThemeManager.textSecondaryColor(),
              onPressed: () {
                _addBookmark();
              },
            ),
            IconButton(
              icon: const Icon(Icons.ios_share_rounded, size: 22), // Reduced size
              color: ThemeManager.textSecondaryColor(),
              onPressed: () async {
                if (currentUrl.isNotEmpty) {
                  await Share.share(currentUrl);
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded, size: 22), // Reduced size
              color: canGoForward ? ThemeManager.textColor() : ThemeManager.textColor().withOpacity(0.3),
              onPressed: canGoForward ? () {
                _goForward();
              } : null,
            ),
          ],
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
          leading: Icon(Icons.download, color: ThemeManager.textColor()),          title: Text(
            AppLocalizations.of(context)!.downloads, // Use proper localization
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
                const SizedBox(width: 8),                Text(
                  AppLocalizations.of(context)!.downloads, // Use proper localization
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

  void _showGeneralContextMenu(Offset position) {
    final List<Widget> menuItems = [
      // Refresh page
      ListTile(
        leading: Icon(Icons.refresh, color: ThemeManager.textColor()),
        title: Text(
          AppLocalizations.of(context)!.reload,
          style: TextStyle(color: ThemeManager.textColor()),
        ),
        onTap: () {
          Navigator.pop(context);
          _refreshPage();
        },
      ),      // Go back (if possible)
      if (canGoBack)
        ListTile(
          leading: Icon(Icons.chevron_left_rounded, color: ThemeManager.textColor()),
          title: Text(
            AppLocalizations.of(context)!.back,
            style: TextStyle(color: ThemeManager.textColor()),
          ),
          onTap: () {
            Navigator.pop(context);
            _goBack();
          },
        ),
      // Go forward (if possible)
      if (canGoForward)
        ListTile(
          leading: Icon(Icons.chevron_right_rounded, color: ThemeManager.textColor()),
          title: Text(
            AppLocalizations.of(context)!.forward,
            style: TextStyle(color: ThemeManager.textColor()),
          ),
          onTap: () {
            Navigator.pop(context);
            _goForward();
          },
        ),
    ];
    
    // Show the custom menu with scale animation
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
    );  }  Future<void> _goBack() async {
    if (!canGoBack) return;
    
    // Close summary panel on navigation
    _closeSummaryPanel();
    
    // Close AI action bar on navigation
    _closeAiActionBar();
    
    try {
      await controller.goBack();
      
      // Reduced wait time for M12
      await Future.delayed(const Duration(milliseconds: 50));
      
      final url = await controller.currentUrl();
      final title = await controller.getTitle();
      
      if (mounted && url != null) {
        _handleUrlUpdate(url, title: title);
        
        setState(() {
          _hideUrlBar = false;
        });
        _hideUrlBarController.reverse();
        
        await _updateNavigationState();
      }
    } catch (e) {
      // Silently handle errors for M12
    }
  }
  Future<void> _goForward() async {
    if (!canGoForward) return;
    
    // Close summary panel on navigation
    _closeSummaryPanel();
    
    // Close AI action bar on navigation
    _closeAiActionBar();
    
    try {
      await controller.goForward();
      
      // Reduced wait time for M12
      await Future.delayed(const Duration(milliseconds: 50));
      
      final url = await controller.currentUrl();
      final title = await controller.getTitle();
      
      if (mounted && url != null) {
        _handleUrlUpdate(url, title: title);
        
        setState(() {
          _hideUrlBar = false;
        });
        _hideUrlBarController.reverse();
        
        await _updateNavigationState();
      }
    } catch (e) {
      // Silently handle errors for M12
    }
  }
  // Simplified tab switching for M12 performance
  Future<void> _switchToTab(int index) async {
    if (index != currentTabIndex && index >= 0 && index < tabs.length) {
      final tab = tabs[index];
        setState(() {
        currentTabIndex = index;
        controller = tab['controller'];
        _displayUrl = tab['url'];
        _urlController.text = _formatUrl(tab['url']);
      });

      // Simplified reload for M12 - less delay
      await Future.delayed(const Duration(milliseconds: 50));
      try {
        await tab['controller'].loadRequest(Uri.parse(tab['url']));
      } catch (e) {
        // Silently handle errors
      }
    }
  }
  // In the method where you create new tabs
  void _createNewTab(String url) async {
    // Use custom home page if enabled and url is empty (new tab) or default home
    if (useCustomHomePage && customHomeUrl.isNotEmpty && 
        (url.isEmpty || url == 'about:blank' || url == _homeUrl || url == 'file:///android_asset/main.html')) {
      print('Using custom home page URL: $customHomeUrl');
      url = customHomeUrl;
    } else {
      print('Using provided URL: $url');
    }
    
    final newTab = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'url': url,
      'title': AppLocalizations.of(context)?.new_tab ?? 'New Tab',
      'isIncognito': tabs.isNotEmpty ? tabs[currentTabIndex]['isIncognito'] : false,
      'controller': WebViewController(),
      'favicon': null,
      'groupId': null,
      'canGoBack': false,
      'canGoForward': false,
      'lastActiveTime': DateTime.now(),
    };
    // Set up navigation delegate before adding the tab - use the centralized navigation delegate
    await newTab['controller'].setNavigationDelegate(await _navigationDelegate);

    // Add the tab and switch to it
    setState(() {
      tabs.add(newTab);
      currentTabIndex = tabs.length - 1;
      controller = newTab['controller'];
      _displayUrl = url;
      _urlController.text = _formatUrl(url);
    });

        // Ensure the page is loaded
    await Future.delayed(Duration(milliseconds: 100));
    if (url.isNotEmpty) {
      try {
        // Format URL properly if needed
        String formattedUrl = url;
        if (!formattedUrl.startsWith('http://') && !formattedUrl.startsWith('https://')) {
          formattedUrl = 'https://$formattedUrl';
        }
        
        print('Loading URL in new tab: $formattedUrl');
        await newTab['controller'].loadRequest(Uri.parse(formattedUrl));
        
        // Update the tab URL with the formatted version
        if (formattedUrl != url) {
          newTab['url'] = formattedUrl;
        }
      } catch (e) {
        print('Error loading URL in new tab: $e');
      }
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
      _createSettingsRoute(
        Scaffold(
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

  void _showCustomNotification({
    required String message,
    IconData? icon,
    String? title,
    Color? iconColor,
    Duration? duration,
    SnackBarAction? action,
    double? progress,
    bool isDownload = false,
  }) {
    // For downloads, create a more detailed message
    if (isDownload) {
      // Create a formatted message string that includes the title
      String formattedMessage = message;
      if (title != null) {
        formattedMessage = "$title\n$message";
      }
      
      // Add progress indicator as a visual element
      if (progress != null) {
        // We can't include a progress bar in a string, but we'll show it in the UI
        formattedMessage += "\n${(progress * 100).toInt()}% complete";
      }

      // Use the standard custom notification
      showCustomNotification(
        context: context,
        message: formattedMessage,
        icon: icon ?? Icons.download_done,
        iconColor: iconColor ?? ThemeManager.primaryColor(),
        isDarkMode: isDarkMode,
        duration: duration ?? const Duration(seconds: 4),
        action: action ?? SnackBarAction(
          label: 'View',
          onPressed: () {
            setState(() {
              isDownloadsVisible = true;
              isTabsVisible = false;
              isSettingsVisible = false;
              isBookmarksVisible = false;
              isHistoryVisible = false;
            });
          },
        ),
      );
    } else {
      // For regular notifications, use the standard method
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
  }

  void _showBookmarkAddedNotification() {
    _showCustomNotification(
      message: AppLocalizations.of(context)!.bookmark_added,
      icon: Icons.bookmark_added,
      iconColor: Colors.green,
    );
  }
  // Modern dialog methods for JavaScript communication
  void _showConfirmDialog(String message, String? dialogId) {    showCustomDialog(
      context: context,
      title: AppLocalizations.of(context)!.confirm,
      content: message,
      isDarkMode: isDarkMode,
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            _sendDialogResult(dialogId, false);
          },
          child: Text(
            'Cancel',
            style: TextStyle(color: ThemeManager.textSecondaryColor()),
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            _sendDialogResult(dialogId, true);
          },
          child: Text(
            'OK',
            style: TextStyle(color: ThemeManager.primaryColor()),
          ),
        ),
      ],
    );
  }
  void _showPromptDialog(String message, String? defaultText, String? dialogId) {
    final TextEditingController textController = TextEditingController(text: defaultText ?? '');
      showCustomDialog(
      context: context,
      title: AppLocalizations.of(context)!.input_required,
      isDarkMode: isDarkMode,
      customContent: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.isNotEmpty) ...[
            Text(
              message,
              style: TextStyle(
                color: ThemeManager.textColor(),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
          ],
          Container(
            decoration: BoxDecoration(
              color: ThemeManager.surfaceColor(),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: ThemeManager.primaryColor().withOpacity(0.3),
                width: 1,
              ),
            ),
            child: TextField(
              controller: textController,
              style: TextStyle(color: ThemeManager.textColor()),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: InputBorder.none,
                hintText: 'Enter text...',
                hintStyle: TextStyle(
                  color: ThemeManager.textColor().withOpacity(0.5),
                ),
              ),
              autofocus: true,
            ),
          ),
        ],
      ),
      actions: [        TextButton(
          onPressed: () {
            Navigator.pop(context);
            _sendDialogResult(dialogId, null);
          },
          child: Text(
            'Cancel',
            style: TextStyle(color: ThemeManager.textSecondaryColor()),
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            _sendDialogResult(dialogId, textController.text);
          },
          child: Text(
            'OK',
            style: TextStyle(color: ThemeManager.primaryColor()),
          ),
        ),
      ],
    );
  }
  void _showAlertDialog(String message, String? dialogId) {    showCustomDialog(
      context: context,
      title: AppLocalizations.of(context)!.alert,
      content: message,
      isDarkMode: isDarkMode,
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            _sendDialogResult(dialogId, true);
          },
          child: Text(
            'OK',
            style: TextStyle(color: ThemeManager.primaryColor()),
          ),
        ),
      ],
    );
  }
  void _sendDialogResult(String? dialogId, dynamic result) {
    if (dialogId != null) {
      try {
        final resultData = {
          'id': dialogId,
          'result': result,
        };
        
        // Determine the dialog type based on the result
        String dialogType = 'alert';
        if (result is bool) {
          dialogType = 'confirm';
          resultData['confirmed'] = result;
        } else if (result is String) {
          dialogType = 'prompt';
        }
        resultData['type'] = dialogType;
        
        final resultJson = json.encode(resultData);
        controller.runJavaScript('''
          if (typeof handleDialogResult === 'function') {
            handleDialogResult('$resultJson');
          }
        ''');
      } catch (e) {
        print('Error sending dialog result: $e');
      }
    }
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
            size: 40, // Reduced from 48
            color: ThemeManager.surfaceColor().withOpacity(0.2), // Simplified
          ),
          const SizedBox(height: 12), // Reduced from 16
          Text(
            message,
            style: TextStyle(
              color: ThemeManager.textSecondaryColor(), // Use theme manager
              fontSize: 14, // Reduced from 16
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
    await prefs.setString('history', jsonEncode(_loadedHistory));  }
  
  // <----TAB INITIALIZATION---->
  // Simplified tab initialization for M12 performance
  Future<void> _initializeTab(Map<String, dynamic> tab) async {
    // <----WEBVIEW CONTROLLER INITIALIZATION---->
    // CRITICAL: Properly initialize WebViewController with all required settings
    final webViewController = tab['controller'] as WebViewController;
    
    // Modern user agent for best compatibility
    final userAgent = 'Mozilla/9999.9999 (Linux; Android 9999; Solar 0.3.0) AppleWebKit/9999.9999 (KHTML, like Gecko) Chrome/9999.9999 Mobile Safari/9999.9999';
    
    // Set essential WebView settings
    webViewController
      ..setJavaScriptMode(JavaScriptMode.unrestricted) // CRITICAL: ENABLE JAVASCRIPT
      ..setBackgroundColor(Colors.transparent)
      ..enableZoom(true)
      ..setUserAgent(userAgent);
    
    print("TAB INITIALIZATION - JAVASCRIPT ENABLED: ${JavaScriptMode.unrestricted}");
    
    // Configure Android-specific settings FIRST
    if (webViewController.platform is webview_flutter_android.AndroidWebViewController) {
      final androidController = webViewController.platform as webview_flutter_android.AndroidWebViewController;
      try {
        await androidController.setAllowFileAccess(true);
        await androidController.setAllowContentAccess(true);
        await androidController.setTextZoom(100);
        await androidController.setMediaPlaybackRequiresUserGesture(false);
        await androidController.setBackgroundColor(Colors.transparent);
        print('Android WebView settings configured successfully');
      } catch (e) {
        print('Error setting Android WebView settings: $e');
      }
    }
    
    // <----JAVASCRIPT CHANNELS SETUP---->
    // CRITICAL: Set up JavaScript channels BEFORE loading any URL
    try {      // DialogHandler channel
      await webViewController.addJavaScriptChannel(
        'DialogHandler',
        onMessageReceived: (JavaScriptMessage message) async {
          if (mounted) {
            try {
              final data = jsonDecode(message.message);
              final String type = data['type'];
              final String id = data['id'];
              final String messageText = data['message'] ?? '';
              final String defaultValue = data['defaultValue'] ?? '';
              
              if (type == 'prompt') {
                // FIXED: Use existing prompt dialog method with custom animation
                _showPromptDialog(messageText, defaultValue, id);
              } else if (type == 'alert') {
                // FIXED: Use existing alert dialog method with custom animation
                _showAlertDialog(messageText, id);
              } else if (type == 'confirm') {
                // FIXED: Use existing confirm dialog method with custom animation
                _showConfirmDialog(messageText, id);
              }
            } catch (e) {
              print('DialogHandler error in tab: $e');
            }
          }
        },
      );

      // ThemeHandler channel
      await webViewController.addJavaScriptChannel(
        'ThemeHandler',
        onMessageReceived: (JavaScriptMessage message) async {
          if (mounted && message.message == 'getTheme') {
            final tabUrl = tab['url'] as String;
            if (tabUrl == _homeUrl || tabUrl.contains('main.html')) {
              await _sendThemeToMainHtml();
            } else {
              await _sendThemeToRestoredTab();
            }
          }        },
      );

      // LanguageHandler channel
      await webViewController.addJavaScriptChannel(
        'LanguageHandler',
        onMessageReceived: (JavaScriptMessage message) async {
          if (mounted && message.message == 'getLanguage') {
            final tabUrl = tab['url'] as String;
            if (tabUrl == _homeUrl || tabUrl.contains('main.html')) {
              await _sendLanguageToMainHtml();
            }
          }
        },
      );

      // SearchHandler channel
      await webViewController.addJavaScriptChannel(
        'SearchHandler',
        onMessageReceived: (JavaScriptMessage message) {
          if (mounted && message.message.isNotEmpty) {
            final engine = searchEngines[currentSearchEngine] ?? searchEngines['Google']!;
            final searchUrl = engine.replaceAll('{query}', Uri.encodeComponent(message.message));
            
            setState(() {
              _urlController.text = message.message;
              _displayUrl = searchUrl;
            });
            
            webViewController.loadRequest(Uri.parse(searchUrl));
          }
        },      );

      // SearchEngineHandler channel
      await webViewController.addJavaScriptChannel(
        'SearchEngineHandler',
        onMessageReceived: (JavaScriptMessage message) async {
          if (mounted && message.message == 'getSearchEngine') {
            final tabUrl = tab['url'] as String;
            if (tabUrl == _homeUrl || tabUrl.contains('main.html')) {
              await _sendSearchEngineToMainHtml();
            }
          }
        },
      );
      
      print('JavaScript channels set up successfully for tab');
    } catch (e) {
      print('Error setting up JavaScript channels: $e');
    }
    
    // Set the navigation delegate
    webViewController.setNavigationDelegate(await _navigationDelegate);
    
    // Set up context menu handling
    await _setupTabControllerChannels(webViewController);
    await _setupScrollHandlingForController(webViewController);
  }

  Future<void> _downloadFile(String url, String? suggestedFilename) async {
    try {
      // First, check if we have storage permission
      bool hasPermission = false;
      
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt;
      
      if (sdkInt >= 33) {
        // For Android 13+, we need to use the MediaStore API
        // Request notification permission for better UX
        await Permission.notification.request();
        hasPermission = true; // Android 13+ doesn't need explicit storage permission for downloads
      } else {
        // For older Android versions, we need storage permission
        final status = await Permission.storage.request();
        hasPermission = status.isGranted;
      }
      
      if (!hasPermission) {
        _showCustomNotification(
          message: AppLocalizations.of(context)!.permission_denied,
          icon: Icons.error_outline,
          iconColor: ThemeManager.errorColor(),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Settings',
            onPressed: () {
              openAppSettings();
            },
          ),
        );
        return;
      }
      
      // Set download state
      setState(() {
        isLoading = true;
        isDownloading = true;
        currentDownloadUrl = url;
        _currentFileName = suggestedFilename;
        downloadProgress = 0.0;
      });

      // Get file name from URL if not provided
      String fileName = suggestedFilename ?? '';
      if (fileName.isEmpty) {
        // Handle base64 URLs differently
        if (url.startsWith('data:')) {
          final extension = _getExtensionFromDataUrl(url);
          fileName = 'image_${DateTime.now().millisecondsSinceEpoch}$extension';
        } else {
          fileName = url.split('/').last.split('?').first;
          if (fileName.isEmpty || !fileName.contains('.')) {
            // Try to determine file type from URL
            final extension = url.toLowerCase().contains('.jpg') || url.toLowerCase().contains('jpeg') ? '.jpg' : 
                            url.toLowerCase().contains('.png') ? '.png' :
                            url.toLowerCase().contains('.gif') ? '.gif' :
                            url.toLowerCase().contains('.webp') ? '.webp' : '.jpg';
            fileName = 'image_${DateTime.now().millisecondsSinceEpoch}$extension';
          }
        }
      }
      
      // Show download started notification
      _showCustomNotification(
        message: fileName,
        title: AppLocalizations.of(context)!.download_started,
        icon: Icons.download_rounded,
        iconColor: ThemeManager.primaryColor(),
        duration: const Duration(seconds: 4),
        isDownload: true,
        action: SnackBarAction(
          label: 'View',
          onPressed: () {
            setState(() {
              isDownloadsVisible = true;
              isTabsVisible = false;
              isSettingsVisible = false;
              isBookmarksVisible = false;
              isHistoryVisible = false;
            });
          },
        ),
      );
      
      // Get download directory
      final dir = await getExternalStorageDirectory();
      if (dir == null) {
        throw Exception('Could not access storage directory');
      }
      
      // Create download directory if it doesn't exist
      final downloadDir = Directory('${dir.path}/Download');
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }

      // Full path to the file
      final filePath = '${downloadDir.path}/$fileName';
      final file = File(filePath);
      
      List<int> fileBytes;
      String mimeType;
      int fileSize;
      
      // Handle base64/data URLs
      if (url.startsWith('data:')) {
        // Extract mime type and base64 data
        final dataUrlInfo = _parseDataUrl(url);
        mimeType = dataUrlInfo['mimeType'] ?? 'application/octet-stream';
        fileBytes = dataUrlInfo['bytes'] ?? [];
        fileSize = fileBytes.length;
        
        // Write the decoded bytes to file
        await file.writeAsBytes(fileBytes);
      } else {
        // Regular HTTP download
        final response = await http.get(Uri.parse(url), headers: {
          'User-Agent': 'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36'
        });
        
        if (response.statusCode != 200) {
          throw Exception('Failed to download file: ${response.statusCode}');
        }
        
        // Get file size and mime type
        fileSize = response.contentLength ?? 0;
        mimeType = response.headers['content-type'] ?? 'application/octet-stream';
        
        // Write file to storage
        await file.writeAsBytes(response.bodyBytes);
      }

      // Make the file visible to other apps using FileProvider for better security
      try {
        const methodChannel = MethodChannel('com.vertex.solar/browser');
        await methodChannel.invokeMethod('shareDownloadedFile', {
          'path': filePath,
          'mimeType': mimeType,
          'fileName': fileName
        });
      } catch (e) {
        print('Error sharing file: $e');
        // Fallback to older method if needed
        try {
          const methodChannel = MethodChannel('com.vertex.solar/app');
          await methodChannel.invokeMethod('scanFile', {'path': filePath});
        } catch (e2) {
          print('Error scanning file: $e2');
        }
      }
      
      // For base64 URLs, use a cleaned URL for history
      String historyUrl = url;
      if (url.startsWith('data:')) {
        // For data URLs, only store the mime type part to save space
        historyUrl = url.split(',')[0] + ',<data>';
      }
      
      // Save download to history with correct file size
      final downloadInfo = {
        'url': historyUrl,
        'filename': fileName,
        'path': filePath,
        'size': fileSize,
        'timestamp': DateTime.now().toIso8601String(),
        'mimeType': mimeType,
        'isBase64': url.startsWith('data:'),
      };
      
      // Add to downloads list
      setState(() {
        downloads.add(downloadInfo);
      });
      
      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final downloadsList = prefs.getStringList('downloads') ?? [];
      downloadsList.add(json.encode(downloadInfo));
      await prefs.setStringList('downloads', downloadsList);
      
      // Show download completed notification
      _showCustomNotification(
        message: fileName,
        title: AppLocalizations.of(context)!.download_completed,
        icon: Icons.check_circle,
        iconColor: ThemeManager.successColor(),
        duration: const Duration(seconds: 4),
        isDownload: true,
        action: SnackBarAction(
          label: AppLocalizations.of(context)!.open,
          onPressed: () async {
            try {
              await OpenFile.open(filePath);
            } catch (e) {
              _showCustomNotification(
                message: AppLocalizations.of(context)!.error_opening_file_install_app,
                icon: Icons.error,
                iconColor: ThemeManager.errorColor(),
                duration: const Duration(seconds: 4),
              );
            }
          },
        ),
      );

    } catch (e) {
      print('Download error: $e');
      _showCustomNotification(
        message: "${AppLocalizations.of(context)!.download_failed}: ${e.toString()}",
        icon: Icons.error_outline,
        iconColor: ThemeManager.errorColor(),
        duration: const Duration(seconds: 4),
      );
    } finally {
      setState(() {
        isLoading = false;
        isDownloading = false;
        currentDownloadUrl = '';
        _currentFileName = null;
        downloadProgress = 0.0;
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
            Text(AppLocalizations.of(context)!.full_storage_access_needed),
            duration: const Duration(seconds: 6),            action: SnackBarAction(
              label: AppLocalizations.of(context)!.settings,
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
        Text('${AppLocalizations.of(context)!.error_removing_download}: ${e.toString()}'),
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
      textScale = prefs.getDouble('textScale') ?? 1.0;      showImages = prefs.getBool('showImages') ?? true;
      _askDownloadLocation = prefs.getBool('askDownloadLocation') ?? true;
      _autoOpenDownloads = prefs.getBool('autoOpenDownloads') ?? false;
      _currentLocale = prefs.getString('language') ?? 'en';
    });
  }

  Future<void> _loadNavigationBarSettings() async {
    final customButtons = await _getCustomNavButtons();
    final animationEnabled = await _getNavBarAnimationEnabled();
    setState(() {
      _customNavButtons = customButtons;
      _navBarAnimationEnabled = animationEnabled;
    });
  }

  Future<void> _loadSearchEngines() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currentSearchEngine = prefs.getString('searchEngine') ?? 'Google';
    });
  }

  String get currentUrl => tabs[currentTabIndex]['url'];
  bool get isCurrentPageBookmarked => bookmarks.any((bookmark) {
    if (bookmark is Map<String, dynamic>) {
      return bookmark['url'] == currentUrl;
    }
    return false;  });

  // Add these variables at the top with other state variables
  Offset? _longPressPosition;
  String? _selectedImageUrl;

  Widget _buildSettingsToggle({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 1),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => onChanged(!value),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ThemeManager.surfaceColor().withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: ThemeManager.textColor().withOpacity(0.08),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: ThemeManager.textColor(),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: ThemeManager.textSecondaryColor(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Transform.scale(
                  scale: 0.7,
                  child: Switch(
                    value: value,
                    onChanged: onChanged,
                    activeColor: ThemeManager.primaryColor(),
                    activeTrackColor: ThemeManager.primaryColor().withOpacity(0.3),
                    inactiveThumbColor: ThemeManager.textSecondaryColor(),
                    inactiveTrackColor: ThemeManager.textSecondaryColor().withOpacity(0.3),
                  ),
                ),
              ],
            ),
          ),        ),
      ),    );
  }
  
  // Simplified JavaScript injection for M12 - Task 4: Allow native context menus
  Future<void> _injectImageContextMenuJS() async {
    try {
      print('Injecting context menu JavaScript...');
      await controller.runJavaScript('''
        console.log('Context menu JavaScript loaded!');
        
        window.findImageAtPoint = function(x, y) {
          try {
            const element = document.elementFromPoint(x, y);
            if (!element) return null;
            
            if (element.tagName === 'IMG') {
              return element.src;
            }
            
            const img = element.querySelector('img') || element.closest('img');
            if (img) {
              return img.src;
            }
            
            const style = window.getComputedStyle(element);
            if (style.backgroundImage && style.backgroundImage !== 'none') {
              return style.backgroundImage.slice(4, -1).replace(/["']/g, '');
            }
            
            return null;
          } catch (e) {
            return null;
          }
        };        // Improved touch handlers - better scroll tolerance for context menus
        let contextMenuState = {
          isTracking: false,
          startTime: 0,
          startX: 0,
          startY: 0,
          moved: false,
          timer: null,
          target: null
        };
        
        const LONG_PRESS_DURATION = 800; // Increased for better UX
        const MOVEMENT_THRESHOLD = 15; // Allow some movement before canceling
        const SCROLL_THRESHOLD = 25; // Cancel only on significant scroll movement
          document.addEventListener('touchstart', function(e) {
          console.log('🤚 TouchStart detected:', e.touches[0].clientX, e.touches[0].clientY);
          
          // Only track images and text elements
          const target = e.target;
          const isImage = target.tagName === 'IMG' || target.closest('img');
          const isTextNode = target.nodeType === Node.TEXT_NODE || 
                           target.tagName === 'P' || target.tagName === 'DIV' || 
                           target.tagName === 'SPAN' || target.tagName === 'A' ||
                           target.isContentEditable || target.tagName === 'INPUT' || 
                           target.tagName === 'TEXTAREA';
          
          console.log('🎯 Target element:', target.tagName, 'isImage:', isImage, 'isTextNode:', isTextNode);
          
          if (isImage || isTextNode) {
            console.log('✅ Starting context menu tracking...');
            contextMenuState.isTracking = true;
            contextMenuState.startTime = Date.now();
            contextMenuState.startX = e.touches[0].clientX;
            contextMenuState.startY = e.touches[0].clientY;
            contextMenuState.moved = false;
            contextMenuState.target = target;            // Set timer for long press
            contextMenuState.timer = setTimeout(() => {
              if (contextMenuState.isTracking && !contextMenuState.moved) {
                console.log('⏰ Long press timer triggered!', { isImage, isTextNode, target });
                  if (isImage) {
                  const imageUrl = target.tagName === 'IMG' ? target.src : target.closest('img').src;
                  console.log('Image long press:', imageUrl);
                  // Use the correct JavaScript channel call
                  if (window.ImageLongPress && window.ImageLongPress.postMessage) {
                    window.ImageLongPress.postMessage(JSON.stringify({
                      type: 'image',
                      url: imageUrl,
                      x: contextMenuState.startX,
                      y: contextMenuState.startY + window.scrollY
                    }));
                    console.log('✅ Image context menu message sent');
                  } else {
                    console.log('❌ ImageLongPress channel not available');
                  }
                } else if (isTextNode) {
                  // Handle text selection context menu
                  const selection = window.getSelection();
                  const selectedText = selection.toString().trim();
                  console.log('Text long press:', selectedText);
                  // Use the correct JavaScript channel call
                  if (window.TextLongPress && window.TextLongPress.postMessage) {
                    window.TextLongPress.postMessage(JSON.stringify({
                      text: selectedText,
                      x: contextMenuState.startX,
                      y: contextMenuState.startY + window.scrollY,
                      isInput: target.isContentEditable || target.tagName === 'INPUT' || target.tagName === 'TEXTAREA'
                    }));
                    console.log('✅ Text context menu message sent');
                  } else {
                    console.log('❌ TextLongPress channel not available');
                  }
                }
                }
              }
              contextMenuState.isTracking = false;
            }, LONG_PRESS_DURATION);
          }
        }, { passive: true });
        
        document.addEventListener('touchmove', function(e) {
          if (contextMenuState.isTracking) {
            const deltaX = Math.abs(e.touches[0].clientX - contextMenuState.startX);
            const deltaY = Math.abs(e.touches[0].clientY - contextMenuState.startY);
            const totalMovement = Math.sqrt(deltaX * deltaX + deltaY * deltaY);
            
            // Only cancel if movement is significant (scrolling gesture)
            if (totalMovement > SCROLL_THRESHOLD) {
              contextMenuState.moved = true;
              contextMenuState.isTracking = false;
              if (contextMenuState.timer) {
                clearTimeout(contextMenuState.timer);
                contextMenuState.timer = null;
              }
            } else if (totalMovement > MOVEMENT_THRESHOLD) {
              // Small movement - mark as moved but don't cancel yet
              contextMenuState.moved = true;
            }
          }
        }, { passive: true });
        
        document.addEventListener('touchend', function(e) {
          if (contextMenuState.isTracking) {
            contextMenuState.isTracking = false;
            if (contextMenuState.timer) {
              clearTimeout(contextMenuState.timer);
              contextMenuState.timer = null;
            }
          }
        }, { passive: true });
        
        document.addEventListener('touchcancel', function(e) {
          if (contextMenuState.isTracking) {
            contextMenuState.isTracking = false;
            if (contextMenuState.timer) {
              clearTimeout(contextMenuState.timer);
              contextMenuState.timer = null;
            }
          }
        }, { passive: true });
      ''');
    } catch (e) {
      // Silently handle JavaScript injection errors
    }
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
              
              _showSummaryModal(currentUrl);
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
              final success = await PWAManager.savePWA(context, _displayUrl, title, tabs[currentTabIndex]['favicon']);
              
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
      isDismissible: true,
      enableDrag: true,
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
                ? Center(                    child:                    Text(
                      AppLocalizations.of(context)!.no_summaries_available,
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
                          ],                        ),
                      );
                    },
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
    
    return Container(
      height: 48, // Fixed height
      margin: EdgeInsets.only(
        bottom: keyboardVisible ? keyboardHeight + 8 : MediaQuery.of(context).padding.bottom + 8,
        left: 0,
        right: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,        children: _customNavButtons.map((buttonType) => _buildNavButton(buttonType)).toList(),
      ),
    );
  }
  // Custom navigation button builder for Task 2
  Widget _buildNavButton(String buttonType) {
    IconData icon;
    VoidCallback? onPressed;
    bool isEnabled = true;
    
    switch (buttonType) {
      case 'back':
        icon = Icons.chevron_left_rounded;
        onPressed = canGoBack ? () => _goBack() : null;
        isEnabled = canGoBack;
        break;
      case 'forward':
        icon = Icons.chevron_right_rounded;
        onPressed = canGoForward ? () => _goForward() : null;
        isEnabled = canGoForward;
        break;      case 'refresh':
        icon = Icons.refresh;
        onPressed = () => controller.reload();
        isEnabled = true;
        break;      case 'home':
        icon = Icons.home;
        onPressed = () => _loadUrl(_homeUrl);
        isEnabled = true;
        break;
      case 'new_tab':
        icon = Icons.add_rounded;
        onPressed = () => _addNewTab();
        isEnabled = true;
        break;      case 'tabs':
        icon = Icons.tab;
        onPressed = () => _showTabsView();
        isEnabled = true;
        break;
      case 'bookmark':
        icon = isCurrentPageBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded;
        onPressed = () => _addBookmark();
        isEnabled = true;
        break;
      case 'bookmarks':
        icon = Icons.bookmark;
        onPressed = () => _showBookmarksPanel();
        isEnabled = true;
        break;
      case 'downloads':
        icon = Icons.download;
        onPressed = () => _showDownloadsPanel();
        isEnabled = true;
        break;
      case 'settings':
        icon = Icons.settings;
        onPressed = () => _showSettingsPanel();
        isEnabled = true;
        break;      case 'share':
        icon = Icons.ios_share_rounded;
        onPressed = () => _shareUrl();
        isEnabled = true;
        break;case 'menu':
        icon = Icons.menu;
        onPressed = () => _showQuickActionsModal();
        isEnabled = true;
        break;
      default:        icon = Icons.help;
        onPressed = null;
        isEnabled = false;
    }
    
    return IconButton(
      icon: Icon(
        icon,
        color: isEnabled 
          ? ThemeManager.textColor() 
          : ThemeManager.textColor().withOpacity(0.3),
        size: 20,
      ),
      onPressed: onPressed,
    );
  }

  void _showQuickActionsModal() {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final modalHeight = 49 + bottomPadding + 60 + 24; // Match classic mode panel height

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
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
        final String currentUrl = tabs[currentTabIndex]['url'];
        if (initialUrl != currentUrl) {
          // Prevent UI updates if URL bar is in focus
          if (!_urlFocusNode.hasFocus) {
            // Safely update URL display
            _updateUrlBarSafely(initialUrl);
            
            // Update tab URL
            if (mounted) {
              setState(() {
                tabs[currentTabIndex]['url'] = initialUrl;
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

    overlay.insert(overlayEntry);    Future.delayed(duration ?? const Duration(seconds: 2), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  // Central method to handle URL updates consistently for all tabs
  void _handleUrlUpdate(String url, {String? title}) {
    if (!mounted) return;
    
    print('🔄 _handleUrlUpdate START - URL: $url, title: $title');
    print('🔄 Current tab: $currentTabIndex, _displayUrl: $_displayUrl');
    print('🔄 URL focus: ${_urlFocusNode.hasFocus}');
    
    // Check if URL significantly changed BEFORE updating tab data
    final shouldForceUpdate = url != _displayUrl;
    print("🔍 URL Update Debug - URL: $url, old _displayUrl: $_displayUrl, shouldForceUpdate: $shouldForceUpdate, hasFocus: ${_urlFocusNode.hasFocus}");
    
    // Always update the tab data
    if (tabs.isNotEmpty && currentTabIndex >= 0 && currentTabIndex < tabs.length) {
      setState(() {        
        tabs[currentTabIndex]['url'] = url;
        if (title != null) {
          tabs[currentTabIndex]['title'] = title;
        }
      });
    }
    
    // Store the full URL for when focus is gained
    _displayUrl = url;
    
    // Always update security status based on the actual URL
    final isUrlSecure = _isSecureUrl(url);
    
    // Update navigation state for the current tab
    if (tabs.isNotEmpty && currentTabIndex >= 0 && currentTabIndex < tabs.length) {
      _updateNavigationState().then((_) {
        if (mounted) {
          setState(() {            
            tabs[currentTabIndex]['canGoBack'] = canGoBack;
            tabs[currentTabIndex]['canGoForward'] = canGoForward;
          });
        }
      });
    }

    // FIXED: Always update URL bar for navigation changes, but respect focus state for formatting
    if (mounted) {
      final formattedUrl = _urlFocusNode.hasFocus ? url : _formatUrl(url);
      print("🔄 Updating URL bar to: $formattedUrl (focused: ${_urlFocusNode.hasFocus})");
      setState(() {
        // Show full URL when focused, formatted URL when not focused
        _urlController.text = formattedUrl;
        
        // Update secure status
        isSecure = isUrlSecure;
        
        // Position cursor at end if focused
        if (_urlFocusNode.hasFocus) {
          _urlController.selection = TextSelection.fromPosition(
            TextPosition(offset: _urlController.text.length),
          );
        }
      });
    }
  }

  // Helper method to extract domain from URL for fallback title
  String _extractDomainFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host.isNotEmpty ? uri.host : url;
    } catch (e) {
      return url;
    }
  }

  Future<void> _handleWebResourceError(WebResourceError error, String url) async {
    if (!mounted) return;
    
    _setLoadingState(false);
    
    // Log the error details
    print('Web resource error: ${error.description}');
    print('Error code: ${error.errorCode}');
    print('Error type: ${error.errorType}');
    print('Failed URL: $url');
    
    // Update the tab info with error state
    if (tabs.isNotEmpty && currentTabIndex >= 0 && currentTabIndex < tabs.length) {
      setState(() {
        tabs[currentTabIndex]['title'] = 'Error Loading Page';
      });
    }
  }
  // Build animated language selection item with expanding tick mark
  Widget _buildAnimatedLanguageItem(String displayName, String languageCode, String currentLanguage, StateSetter setLanguageScreenState, {bool isFirst = false, bool isLast = false}) {
    final isSelected = currentLanguage == displayName;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: EdgeInsets.only(bottom: isLast ? 0 : 1),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            // Set locale and update immediately
            await _setLocaleWithAnimation(languageCode, setLanguageScreenState);
            
            // Send updated language to main.html immediately
            if (_isHomePage(_displayUrl)) {
              await _sendLanguageToMainHtml();
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    displayName,
                    style: TextStyle(
                      fontSize: 15,
                      color: ThemeManager.textColor(),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
                // Animated tick mark with expanding animation
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.elasticOut,
                  width: isSelected ? 24 : 0,
                  height: isSelected ? 24 : 0,
                  child: isSelected 
                    ? TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.elasticOut,
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        builder: (context, scale, child) {
                          return Transform.scale(
                            scale: scale,
                            child: Icon(
                              Icons.check_circle,
                              color: ThemeManager.primaryColor(),
                              size: 24,
                            ),
                          );
                        },
                      )
                    : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Enhanced setLocale method with animation support
  Future<void> _setLocaleWithAnimation(String languageCode, StateSetter setLanguageScreenState) async {
    final languages = {
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
    
    setState(() {
      _currentLocale = languageCode;
      currentLanguage = languages[languageCode] ?? 'English';
    });
    
    // Update the language selection screen immediately
    setLanguageScreenState(() {});
    
    // Save the selected language to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', languageCode);
    
    // Notify the app about locale change immediately
    if (widget.onLocaleChange != null) {
      widget.onLocaleChange!(languageCode);
    }
    
    // Send updated language to main.html immediately if it's loaded
    if (_isHomePage(_displayUrl)) {
      await _sendLanguageToMainHtml();
    }
  }

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
  // Tab Group Management Methods
  Future<void> _closeAllTabs() async {
    if (tabs.isEmpty) return;
    
    bool? confirm = await showGeneralDialog<bool>(
      context: context,
      pageBuilder: (context, animation, secondaryAnimation) => Container(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );

        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(curvedAnimation),
          child: FadeTransition(
            opacity: animation,            child: CustomDialog(
              title: AppLocalizations.of(context)!.close_all_tabs,
              content: AppLocalizations.of(context)!.close_all_tabs_confirm,
              isDarkMode: isDarkMode,
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: ThemeManager.textSecondaryColor()),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(
                    'Close All',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: ThemeManager.textColor().withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 200),
    );
    
    if (confirm == true) {
      setState(() {
        tabs.clear();
        _addNewTab();
      });
    }
  }
  void _showCreateGroupDialog() {
    final TextEditingController nameController = TextEditingController();
    Color selectedColor = Colors.blue;
      showCustomDialog(
      context: context,
      title: AppLocalizations.of(context)!.create_tab_group,
      isDarkMode: isDarkMode,
      customContent: StatefulBuilder(
        builder: (context, setState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                style: TextStyle(color: ThemeManager.textColor()),                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.group_name,
                  labelStyle: TextStyle(color: ThemeManager.textSecondaryColor()),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: ThemeManager.textSecondaryColor().withOpacity(0.3)),
                  ),
                ),
              ),
              const SizedBox(height: 20),              Text(
                AppLocalizations.of(context)!.color,
                style: TextStyle(
                  color: ThemeManager.textColor(),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  Colors.blue,
                  Colors.red,
                  Colors.green,
                  Colors.orange,
                  Colors.purple,
                  Colors.teal,
                  Colors.pink,
                  Colors.indigo,
                  Colors.amber,
                ].map((color) {
                  return GestureDetector(
                    onTap: () => setState(() => selectedColor = color),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: selectedColor == color 
                          ? Border.all(color: ThemeManager.textColor(), width: 3)
                          : Border.all(color: ThemeManager.textSecondaryColor().withOpacity(0.2), width: 1),
                        boxShadow: selectedColor == color ? [
                          BoxShadow(
                            color: color.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                          )
                        ] : null,
                      ),
                      child: selectedColor == color 
                        ? Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            AppLocalizations.of(context)!.cancel,
            style: TextStyle(color: ThemeManager.textSecondaryColor()),
          ),
        ),
        TextButton(
          onPressed: () {
            if (nameController.text.trim().isNotEmpty) {
              final newGroup = TabGroup(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: nameController.text.trim(),
                color: selectedColor,
                createdAt: DateTime.now(),
              );
              this.setState(() {
                _tabGroups.add(newGroup);
              });
              Navigator.of(context).pop();
              _showAddToGroupDialog(newGroup.id);
            }
          },          child: Text(
            AppLocalizations.of(context)!.create,
            style: TextStyle(color: Theme.of(context).primaryColor),
          ),
        ),
      ],    );
  }
  
  void _showAddToGroupDialog(String groupId) {
    final displayTabs = tabs.where((tab) =>      !tab['url'].startsWith('file:///') && 
      !tab['url'].startsWith('about:blank') && 
      tab['url'] != _homeUrl
    ).toList();
    
    List<bool> selectedTabs = List.filled(displayTabs.length, false);
      showCustomDialog(
      context: context,
      title: AppLocalizations.of(context)!.add_tabs_to_group,
      isDarkMode: isDarkMode,
      customContent: StatefulBuilder(
        builder: (context, setState) {
          return Container(
            width: double.maxFinite,
            constraints: BoxConstraints(maxHeight: 400),
            child: displayTabs.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.tab,
                          size: 48,
                          color: ThemeManager.textSecondaryColor().withOpacity(0.5),
                        ),
                        SizedBox(height: 12),                        Text(
                          AppLocalizations.of(context)!.no_tabs_open,
                          style: TextStyle(
                            color: ThemeManager.textSecondaryColor(),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: displayTabs.length,
                  itemBuilder: (context, index) {
                    final tab = displayTabs[index];
                    
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 4),
                      color: ThemeManager.surfaceColor(),
                      child: CheckboxListTile(
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        title: Text(
                          tab['title'].isEmpty ? (AppLocalizations.of(context)?.new_tab ?? 'New Tab') : tab['title'],
                          style: TextStyle(
                            color: ThemeManager.textColor(),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            tab['url'],
                            style: TextStyle(
                              color: ThemeManager.textSecondaryColor(),
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        value: selectedTabs[index],
                        activeColor: Theme.of(context).primaryColor,
                        onChanged: (bool? value) {
                          setState(() {
                            selectedTabs[index] = value ?? false;
                          });
                        },
                      ),
                    );
                  },
                ),
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(color: ThemeManager.textSecondaryColor()),
          ),
        ),
        TextButton(
          onPressed: () {
            this.setState(() {
              for (int i = 0; i < displayTabs.length; i++) {
                if (selectedTabs[i]) {
                  final originalIndex = tabs.indexOf(displayTabs[i]);
                  if (originalIndex >= 0) {
                    tabs[originalIndex]['groupId'] = groupId;
                  }
                }
              }
            });
            Navigator.of(context).pop();
          },
          child: Text(
            'Add to Group',
            style: TextStyle(color: Theme.of(context).primaryColor),
          ),
        ),
      ],
    );
  }
  void _showManageGroupsDialog() {    showCustomDialog(
      context: context,
      title: AppLocalizations.of(context)!.manage_groups,
      isDarkMode: isDarkMode,
      customContent: Container(
        width: double.maxFinite,
        constraints: BoxConstraints(maxHeight: 400),
        child: _tabGroups.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.folder_outlined,
                      size: 64,
                      color: ThemeManager.textSecondaryColor().withOpacity(0.5),
                    ),
                    SizedBox(height: 16),                    Text(
                      AppLocalizations.of(context)!.no_groups_created_yet,
                      style: TextStyle(
                        color: ThemeManager.textSecondaryColor(),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              shrinkWrap: true,
              itemCount: _tabGroups.length,
              itemBuilder: (context, index) {
                final group = _tabGroups[index];
                final tabCount = tabs.where((tab) => tab['groupId'] == group.id).length;
                
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 4),
                  color: ThemeManager.surfaceColor(),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: group.color,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: group.color.withOpacity(0.3),
                            blurRadius: 6,
                            spreadRadius: 1,
                          )
                        ],
                      ),
                    ),
                    title: Text(
                      group.name,
                      style: TextStyle(
                        color: ThemeManager.textColor(),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '$tabCount tab${tabCount != 1 ? 's' : ''}',
                        style: TextStyle(
                          color: ThemeManager.textSecondaryColor(),
                          fontSize: 12,
                        ),
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.tab_unselected,
                            color: ThemeManager.textSecondaryColor(),
                            size: 20,
                          ),                          tooltip: AppLocalizations.of(context)!.ungroup_tabs,
                          onPressed: () {
                            _ungroupTabs(group);
                            Navigator.of(context).pop();
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                            size: 20,
                          ),                          tooltip: AppLocalizations.of(context)!.delete_group,
                          onPressed: () {
                            _deleteGroup(group);
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),          child: Text(
            AppLocalizations.of(context)!.close,
            style: TextStyle(color: ThemeManager.textColor()),
          ),
        ),
      ],
    );
  }

  void _deleteGroup(TabGroup group) {
    setState(() {
      // Remove group
      _tabGroups.removeWhere((g) => g.id == group.id);      // Ungroup all tabs in this group
      for (var tab in tabs) {
        if (tab['groupId'] == group.id) {
          tab['groupId'] = null;
        }
      }
    });
  }
  void _ungroupTabs(TabGroup group) {
    setState(() {
      for (var tab in tabs) {
        if (tab['groupId'] == group.id) {
          tab['groupId'] = null;
        }
      }
    });
  }
  
  Widget _buildBottomActionBar() {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return Container(
      margin: EdgeInsets.fromLTRB(18, 0, 18, 20 + bottomPadding), // Increased bottom margin from 10 to 20 + safe area
      decoration: BoxDecoration(
        color: ThemeManager.surfaceColor(),
        borderRadius: BorderRadius.circular(28), // Optimized radius
        boxShadow: [
          BoxShadow(
            color: ThemeManager.textColor().withOpacity(0.08), // Further reduced opacity
            blurRadius: 16, // Optimized blur radius
            offset: Offset(0, 1.5),  // More subtle offset
            spreadRadius: 0.2, // More subtle spread
          ),
        ],
        border: Border.all(
          color: ThemeManager.textSecondaryColor().withOpacity(0.05), // Further reduced opacity
          width: 0.5,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2), // Optimized padding
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Changed back to spaceEvenly with optimized child spacing
          children: [
            // Left padding for better spacing
            SizedBox(width: 2),
            
            // 1. Create Group
            _buildFloatingActionButton(
              icon: Icons.tab,
              onTap: _showCreateGroupDialog,
            ),
            
            // 2. Manage Groups
            _buildFloatingActionButton(
              icon: Icons.folder_outlined,
              onTap: _showManageGroupsDialog,
            ),
            
            // 3. New Tab (Center - prominent with incognito mode support)
            _buildCenterNewTabButton(),
            
            // 4. History
            _buildFloatingActionButton(
              icon: Icons.history,
              onTap: () {
                _showHistoryPanel();
              },
            ),
            
            // 5. 3-dots menu (far right)
            _buildFloatingMenuButton(),
            
            // Right padding for better spacing
            SizedBox(width: 2),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFloatingActionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18), // Increased touch area
      onTap: onTap,
      child: TweenAnimationBuilder(
        tween: Tween<double>(begin: 0.92, end: 1.0),
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCirc, // More refined animation curve
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: Container(
              width: 38, // Optimized width for perfect spacing
              height: 38, // Optimized height for perfect spacing
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16), // Optimized radius
                // Subtle highlight effect for depth
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    ThemeManager.surfaceColor().withOpacity(0.7),
                    ThemeManager.surfaceColor(),
                  ],
                ),
              ),
              child: Icon(
                icon,
                size: 19, // Optimized size for visual balance
                color: ThemeManager.textColor().withOpacity(0.9), // Better contrast
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildCenterNewTabButton() {
    bool isIncognitoActive = _isIncognitoModeActive;
    
    return Container(
      width: 48, // Optimized size for better emphasis
      height: 48, // Optimized size for better emphasis
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isIncognitoActive 
              ? [Color(0xFF505050), Color(0xFF3A3A3A)] // Refined incognito colors
              : [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withOpacity(0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16), // Consistent with other elements
        boxShadow: [
          BoxShadow(
            color: (isIncognitoActive ? Colors.grey[700]! : Theme.of(context).primaryColor)
                .withOpacity(0.2), // Perfect shadow opacity
            blurRadius: 12, // Refined blur for smoother shadow
            offset: Offset(0, 1), // Minimal offset for subtle elevation
            spreadRadius: 0, // No spread for cleaner look
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (isIncognitoActive) {
              _addNewTab(isIncognito: true);
            } else {
              _addNewTab();
            }
            setState(() {
              isTabsVisible = false;
            });
          },
          child: Center(
            child: Icon(
              isIncognitoActive ? Icons.visibility_off_rounded : Icons.add,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),      ),
    );
  }

  Widget _buildFloatingMenuButton() {
    return PopupMenuButton<String>(
      icon: Container(
        width: 38, // Matched to other buttons
        height: 38, // Matched to other buttons
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16), // Consistent radius
          // Subtle highlight effect for depth, matching other buttons
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ThemeManager.surfaceColor().withOpacity(0.7),
              ThemeManager.surfaceColor(),
            ],
          ),
        ),        
        child: Icon(
          Icons.more_horiz_rounded, // Better icon choice for menu
          size: 19, // Consistent with other buttons
          color: ThemeManager.textColor().withOpacity(0.9), // Consistent with other buttons
        ),
      ),
      onSelected: (String value) {
        if (value == 'incognito') {
          setState(() {
            _isIncognitoModeActive = !_isIncognitoModeActive;
          });
        } else if (value == 'close_all') {
          _closeAllTabs();
        }
      },
      color: ThemeManager.surfaceColor(),
      elevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: ThemeManager.textSecondaryColor().withOpacity(0.1),
          width: 0.5,
        ),
      ),
      offset: const Offset(0, -100),
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'close_all',
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: Colors.red,
                ),
                SizedBox(width: 12),                Text(
                  AppLocalizations.of(context)!.close_all_tabs,
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        PopupMenuItem<String>(
          value: 'incognito',
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(
                  _isIncognitoModeActive ? Icons.visibility_off : Icons.visibility_off_outlined,
                  size: 20,
                  color: _isIncognitoModeActive ? Colors.purple : ThemeManager.textColor(),
                ),
                SizedBox(width: 12),                Text(
                  _isIncognitoModeActive 
                    ? AppLocalizations.of(context)!.disable_incognito_mode
                    : AppLocalizations.of(context)!.enable_incognito_mode,
                  style: TextStyle(
                    color: _isIncognitoModeActive ? Colors.purple : ThemeManager.textColor(),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),      ],
    );
  }

  // Custom dialog methods for consistent app styling
  Future<String?> _showCustomPromptDialog(String message, String defaultValue) async {
    final TextEditingController textController = TextEditingController(text: defaultValue);
    
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: ThemeManager.surfaceColor(),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            'Input Required',
            style: TextStyle(
              color: ThemeManager.textColor(),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message,
                style: TextStyle(
                  color: ThemeManager.textColor().withOpacity(0.8),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: textController,
                autofocus: true,
                style: TextStyle(color: ThemeManager.textColor()),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: ThemeManager.backgroundColor(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: ThemeManager.textColor().withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: ThemeManager.accentColor(), width: 2),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: Text(
                'Cancel',
                style: TextStyle(color: ThemeManager.textColor().withOpacity(0.7)),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(textController.text),
              child: Text(
                'OK',
                style: TextStyle(color: ThemeManager.accentColor()),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showCustomAlertDialog(String message) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: ThemeManager.surfaceColor(),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            'Notice',
            style: TextStyle(
              color: ThemeManager.textColor(),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            message,
            style: TextStyle(
              color: ThemeManager.textColor().withOpacity(0.8),
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),              child: Text(
                'OK',
                style: TextStyle(color: ThemeManager.accentColor()),
              ),
            ),
          ],
        );
      },
    );
  }
  
  // Panel animation helper methods
  void _showPanelWithAnimation(String panelType) {
    // Close AI action bar when panels are opened
    if (_isAiActionBarVisible) {
      _toggleAiActionBar();
    }
    
    // COMPLETELY NEW IMPLEMENTATION
    // First reset controller to start fresh
    _panelSlideController.reset();
    
    setState(() {
      _isPanelClosing = false;
      // Hide all other panels first
      isTabsVisible = false;
      isSettingsVisible = false;
      isBookmarksVisible = false;
      isDownloadsVisible = false;
      isHistoryVisible = false;
      
      // Show the requested panel
      switch (panelType) {
        case 'tabs':
          isTabsVisible = true;
          break;
        case 'settings':
          isSettingsVisible = true;
          break;
        case 'bookmarks':
          isBookmarksVisible = true;
          break;
        case 'downloads':
          isDownloadsVisible = true;
          break;
        case 'history':
          isHistoryVisible = true;
          break;
      }
    });
      // Start the slide-in animation
    _panelSlideController.forward();
  }
  
  void _hidePanelWithAnimation() {
    setState(() {
      _isPanelClosing = true;
    });
    
    // Close AI action bar when panels are opened
    if (_isAiActionBarVisible) {
      _toggleAiActionBar();
    }
    
    // Use reverse animation to slide out to the right
    _panelSlideController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _isPanelClosing = false;
          isTabsVisible = false;
          isSettingsVisible = false;
          isBookmarksVisible = false;
          isDownloadsVisible = false;
          isHistoryVisible = false;
        });
      }
    });
  }

  void _showTabsPanel() {
    _showPanelWithAnimation('tabs');
  }

  void _showBookmarksPanel() {
    _showPanelWithAnimation('bookmarks');
  }

  void _showDownloadsPanel() {
    _showPanelWithAnimation('downloads');
  }
  void _showHistoryPanel() async {
    _loadHistory(); // Load history when showing the panel
    _showPanelWithAnimation('history');
  }
  
  void _showSettingsPanel() {
    _showPanelWithAnimation('settings');
  }
  
  void _showTabsView() {
    _showPanelWithAnimation('tabs');
  }

  // AI Action Bar Modal Methods
  void _showErrorNotification(String message) {
    showCustomNotification(
      context: context,
      message: message,
      isDarkMode: ThemeManager.getCurrentTheme().isDark,
    );
  }
  
  void _showSummaryModal(String url, [String? content]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => _SummaryModal(
        url: url,
        content: content,
        controller: controller,
        onClose: () => Navigator.pop(context),
      ),
    );
  }
}

// Summary Modal Widget
class _SummaryModal extends StatefulWidget {
  final String url;
  final String? content;
  final VoidCallback onClose;
  final WebViewController controller;

  const _SummaryModal({
    required this.url,
    this.content,
    required this.onClose,
    required this.controller,
  });

  @override
  _SummaryModalState createState() => _SummaryModalState();
}

class _SummaryModalState extends State<_SummaryModal> {
  bool _isLoading = true;
  String? _summary;
  String? _error;

  @override
  void initState() {
    super.initState();
    _generateSummary();
  }

  Future<void> _generateSummary() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Initialize AI Manager
      await AIManager.initialize();
      
      // Get page text content using the existing controller
      final pageContent = await widget.controller.runJavaScriptReturningResult('''
        (function() {
          // Create a clone of the document to avoid modifying the original
          const docClone = document.cloneNode(true);
          
          // Get all elements to remove from the clone
          const elementsToRemove = docClone.querySelectorAll('script, style, link[rel="stylesheet"], nav, footer, header, .nav, .navbar, .sidebar, .ad, .advertisement');
          
          // Remove all unwanted elements
          elementsToRemove.forEach(el => {
            try {
              el.parentNode.removeChild(el);
            } catch (e) {
              // Ignore errors if element can't be removed
            }
          });
          
          // Get main content from the clone
          let content = '';
          try {
            const main = docClone.querySelector('main, article, .content, .post, .entry, .article-content, [role="main"]');
            if (main) {
              content = main.innerText || main.textContent || '';
            } else {
          // Fallback to body content
              content = document.body.innerText || document.body.textContent || '';
            }
          } catch (e) {
            // Fallback to a safer method if the above fails
            content = document.body.innerText || document.body.textContent || '';
          }
          
          return content;
        })();
      ''');

      final content = pageContent.toString().replaceAll('"', '').trim();
      
      if (content.isEmpty || content.length < 50) {
        throw Exception('No sufficient content found to summarize');
      }      // Generate summary using AI Manager
      final summary = await AIManager.summarizeText(content, isFullPage: true);
      
      // Get page title for better metadata
      final title = await widget.controller.getTitle() ?? AppLocalizations.of(context)!.untitled;
      
      // Save summary with metadata
      await AIManager.saveSummary(summary, widget.url, title);

      setState(() {
        _summary = summary;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: ThemeManager.surfaceColor(),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: ThemeManager.textColor().withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.summarize_outlined,
                  color: ThemeManager.textColor(),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child:                  Text(
                    AppLocalizations.of(context)!.page_summary,
                    style: TextStyle(
                      color: ThemeManager.textColor(),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: widget.onClose,
                  icon: Icon(
                    Icons.close,
                    color: ThemeManager.textColor(),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: ThemeManager.textColor().withOpacity(0.1),
          ),
          // Content
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: ThemeManager.primaryColor(),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(context)!.generating_summary,
                          style: TextStyle(
                            color: ThemeManager.textSecondaryColor(),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: ThemeManager.textColor().withOpacity(0.5),
                                size: 48,
                              ),
                              const SizedBox(height: 16),                              Text(
                                AppLocalizations.of(context)!.failed_to_generate_summary,
                                style: TextStyle(
                                  color: ThemeManager.textColor(),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _error ?? '',
                                style: TextStyle(
                                  color: ThemeManager.textSecondaryColor(),
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _generateSummary,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: ThemeManager.primaryColor(),
                                  foregroundColor: Colors.white,
                                ),
                                child: Text(AppLocalizations.of(context)!.try_again),
                              ),
                            ],
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // URL
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: ThemeManager.backgroundColor().withOpacity(0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.link,
                                    color: ThemeManager.textSecondaryColor(),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      widget.url,
                                      style: TextStyle(
                                        color: ThemeManager.textSecondaryColor(),
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),                            ),
                            const SizedBox(height: 16),
                            // Summary
                            Text(
                              _summary ?? '',
                              style: TextStyle(
                                color: ThemeManager.textColor(),
                                fontSize: 16,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Copy button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  if (_summary != null) {
                                    await AIManager.copyToClipboard(_summary!);
                                    // Show feedback
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          AppLocalizations.of(context)!.summary_copied_to_clipboard,
                                          style: TextStyle(color: ThemeManager.textColor()),
                                        ),
                                        backgroundColor: ThemeManager.surfaceColor(),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: ThemeManager.primaryColor(),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                icon: const Icon(Icons.copy, size: 18),
                                label: Text(AppLocalizations.of(context)!.copy_summary),
                              ),
                            ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// Previous Summaries Modal Widget
class _PreviousSummariesModal extends StatefulWidget {
  final VoidCallback onClose;

  const _PreviousSummariesModal({
    required this.onClose,
  });

  @override
  _PreviousSummariesModalState createState() => _PreviousSummariesModalState();
}

class _PreviousSummariesModalState extends State<_PreviousSummariesModal> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _summaries = [];

  @override
  void initState() {
    super.initState();
    _loadPreviousSummaries();
  }

  Future<void> _loadPreviousSummaries() async {
    try {
      await AIManager.initialize();
      final summaries = await AIManager.getPreviousSummaries();
      setState(() {
        _summaries = summaries;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          return '${difference.inMinutes}m ago';
        }
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: ThemeManager.surfaceColor(),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: ThemeManager.textColor().withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.history_outlined,
                  color: ThemeManager.textColor(),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(                  child: Text(
                    AppLocalizations.of(context)!.previous_summaries,
                    style: TextStyle(
                      color: ThemeManager.textColor(),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: widget.onClose,
                  icon: Icon(
                    Icons.close,
                    color: ThemeManager.textColor(),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: ThemeManager.textColor().withOpacity(0.1),
          ),
          // Content
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: ThemeManager.primaryColor(),
                    ),
                  )
                : _summaries.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history_outlined,
                              color: ThemeManager.textColor().withOpacity(0.3),
                              size: 64,
                            ),
                            const SizedBox(height: 16),                            Text(
                              AppLocalizations.of(context)!.no_summaries_available,
                              style: TextStyle(
                                color: ThemeManager.textColor(),
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Start summarizing pages to see them here',
                              style: TextStyle(
                                color: ThemeManager.textSecondaryColor(),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _summaries.length,
                        itemBuilder: (context, index) {
                          final summary = _summaries[index];
                          final siteName = summary['siteName'] ?? 'Unknown Site';
                          final model = summary['model'] ?? 'Unknown Model';
                          final date = summary['date'] ?? '';
                          final text = summary['text'] ?? '';
                          final url = summary['url'] ?? '';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: ThemeManager.backgroundColor(),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: ThemeManager.textColor().withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  // Show summary detail
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    isDismissible: true,
                                    enableDrag: true,
                                    builder: (context) => _SummaryDetailModal(
                                      summary: summary,
                                      onClose: () => Navigator.pop(context),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Header row
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  siteName,
                                                  style: TextStyle(
                                                    color: ThemeManager.textColor(),
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Text(
                                                      model,
                                                      style: TextStyle(
                                                        color: ThemeManager.primaryColor(),
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                    Text(
                                                      ' • ',
                                                      style: TextStyle(
                                                        color: ThemeManager.textSecondaryColor(),
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                    Text(
                                                      _formatDate(date),
                                                      style: TextStyle(
                                                        color: ThemeManager.textSecondaryColor(),
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          Icon(
                                            Icons.chevron_right,
                                            color: ThemeManager.textSecondaryColor(),
                                            size: 20,
                                          ),
                                        ],
                                      ),
                                      if (url.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          url,
                                          style: TextStyle(
                                            color: ThemeManager.textSecondaryColor(),
                                            fontSize: 11,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                      const SizedBox(height: 12),
                                      // Summary preview
                                      Text(
                                        text,
                                        style: TextStyle(
                                          color: ThemeManager.textColor(),
                                          fontSize: 14,
                                          height: 1.4,
                                        ),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
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
}

// Summary Detail Modal Widget
class _SummaryDetailModal extends StatelessWidget {
  final Map<String, dynamic> summary;
  final VoidCallback onClose;

  const _SummaryDetailModal({
    required this.summary,
    required this.onClose,
  });

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final siteName = summary['siteName'] ?? 'Unknown Site';
    final model = summary['model'] ?? 'Unknown Model';
    final date = summary['date'] ?? '';
    final text = summary['text'] ?? '';
    final url = summary['url'] ?? '';

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: ThemeManager.surfaceColor(),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: ThemeManager.textColor().withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        siteName,
                        style: TextStyle(
                          color: ThemeManager.textColor(),
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            model,
                            style: TextStyle(
                              color: ThemeManager.primaryColor(),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            ' • ',
                            style: TextStyle(
                              color: ThemeManager.textSecondaryColor(),
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            _formatDate(date),
                            style: TextStyle(
                              color: ThemeManager.textSecondaryColor(),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: Icon(
                    Icons.close,
                    color: ThemeManager.textColor(),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: ThemeManager.textColor().withOpacity(0.1),
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (url.isNotEmpty) ...[
                    // URL
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: ThemeManager.backgroundColor().withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.link,
                            color: ThemeManager.textSecondaryColor(),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              url,
                              style: TextStyle(
                                color: ThemeManager.textSecondaryColor(),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Summary
                  Text(
                    text,
                    style: TextStyle(
                      color: ThemeManager.textColor(),
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),        ],
      ),
    );
  }

  // FIXED: Standardized dialog animation method for consistent UI
  Future<T?> showStandardDialog<T>({
    required BuildContext context,
    required Widget child,
    bool barrierDismissible = true,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: '',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        // Scale and fade animation similar to tabs dialog
        return ScaleTransition(
          scale: Tween<double>(
            begin: 0.8,
            end: 1.0,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack,
          )),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
  }

  // Helper method for creating standardized alert dialogs
  Widget createStandardAlertDialog({
    required String title,
    required String content,
    required List<Widget> actions,
  }) {
    return AlertDialog(
      backgroundColor: ThemeManager.backgroundColor(),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        title,
        style: TextStyle(color: ThemeManager.textColor()),
      ),
      content: Text(
        content,
        style: TextStyle(color: ThemeManager.textColor()),
      ),
      actions: actions,
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