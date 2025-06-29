import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import '../utils/theme_manager.dart';
import '../l10n/app_localizations.dart';
import '../services/pwa_manager.dart';

class PWAScreen extends StatefulWidget {
  final String url;
  final String title;
  final String? favicon;

  const PWAScreen({
    Key? key,
    required this.url,
    required this.title,
    this.favicon,
  }) : super(key: key);

  @override
  State<PWAScreen> createState() => _PWAScreenState();
}

class _PWAScreenState extends State<PWAScreen> {
  late WebViewController _controller;
  bool _isLoading = true;
  String _title = '';
  bool _canGoBack = false;
  bool _canGoForward = false;

  @override
  void initState() {
    super.initState();
    _title = widget.title;
    _initializeWebView();
    _updateSystemBars();
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

    final webViewController = WebViewController.fromPlatformCreationParams(params);

    webViewController
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..enableZoom(true)      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = true;
              });
            }
          },
          onPageFinished: (String url) async {
            if (mounted) {
              final pageTitle = await webViewController.getTitle() ?? '';
              final canGoBack = await webViewController.canGoBack();
              final canGoForward = await webViewController.canGoForward();
              
              setState(() {
                _isLoading = false;
                if (pageTitle.isNotEmpty) {
                  _title = pageTitle;
                }
                _canGoBack = canGoBack;
                _canGoForward = canGoForward;
              });
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            // You can handle special navigation cases here
            return NavigationDecision.navigate;
          },
        ),
      );

    // Additional Android setup
    if (webViewController.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      final androidController = webViewController.platform as AndroidWebViewController;
      await androidController.setMediaPlaybackRequiresUserGesture(false);
      await androidController.setBackgroundColor(Colors.transparent);
      
      // Set Chrome-like user agent to fix Google sign-in issues
      await androidController.setUserAgent(
        'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Mobile Safari/537.36'
      );
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
    
    // Load the URL
    await webViewController.loadRequest(Uri.parse(widget.url));
    
    setState(() {
      _controller = webViewController;
    });
  }

  void _updateSystemBars() {
    // Use the same system bar styling as browser_screen
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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        // No app bar for PWA mode - full screen experience
        extendBodyBehindAppBar: true,
        extendBody: true,
        body: SafeArea(
          child: Stack(
            children: [
              // Full-screen WebView
              WebViewWidget(controller: _controller),
              
              // Loading indicator
              if (_isLoading)
                Center(
                  child: CircularProgressIndicator(
                    color: ThemeManager.primaryColor(),
                  ),
                ),
            ],
          ),
        ),
        // Simple bottom navigation bar with just back and forward buttons
        bottomNavigationBar: Container(
          height: 60,
          padding: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: ThemeManager.backgroundColor(),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Back button
              IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_rounded,
                  color: _canGoBack 
                      ? ThemeManager.primaryColor()
                      : ThemeManager.textColor().withOpacity(0.3),
                  size: 22,
                ),
                onPressed: _canGoBack
                    ? () => _controller.goBack()
                    : null, // Don't close the PWA when back isn't available
              ),
              // Forward button
              IconButton(
                icon: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: _canGoForward 
                      ? ThemeManager.primaryColor()
                      : ThemeManager.textColor().withOpacity(0.3),
                  size: 22,
                ),
                onPressed: _canGoForward
                    ? () => _controller.goForward()
                    : null,
              ),
              // Refresh button
              IconButton(
                icon: Icon(
                  Icons.refresh,
                  color: ThemeManager.textColor(),
                  size: 24,
                ),
                onPressed: () => _controller.reload(),
              ),
              // Settings button with popup menu
              PopupMenuButton(
                icon: Icon(
                  Icons.settings,
                  color: ThemeManager.textColor(),
                  size: 24,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: ThemeManager.textColor().withOpacity(0.1),
                    width: 1,
                  ),
                ),
                color: ThemeManager.surfaceColor(),
                elevation: 8,
                itemBuilder: (context) => [
                  PopupMenuItem(
                    height: 40,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.edit,
                          size: 20,
                          color: ThemeManager.textColor(),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          AppLocalizations.of(context)!.rename_pwa,
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
                      _showRenamePWADialog();
                    },
                  ),
                  PopupMenuItem(
                    height: 40,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.delete_outline,
                          size: 20,
                          color: ThemeManager.textColor(),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          AppLocalizations.of(context)!.remove_from_pwa,
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
                      _showRemovePWADialog();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    final canGoBack = await _controller.canGoBack();
    if (canGoBack) {
      await _controller.goBack();
      return false;
    }
    return true;
  }

  // Show rename PWA dialog
  Future<void> _showRenamePWADialog() async {
    final TextEditingController controller = TextEditingController(text: widget.title);
    
    // Get theme colors
    final primaryColor = ThemeManager.primaryColor();
    final backgroundColor = ThemeManager.backgroundColor();
    final textColor = ThemeManager.textColor();
    final surfaceColor = ThemeManager.surfaceColor();
    
    final String? newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          AppLocalizations.of(context)!.rename_pwa,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter a new name for this PWA:',
              style: TextStyle(
                color: textColor,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: primaryColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: controller,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: InputBorder.none,
                  hintText: AppLocalizations.of(context)!.pwa_name,
                  hintStyle: TextStyle(
                    color: textColor.withOpacity(0.5),
                  ),
                ),
                autofocus: true,
              ),
            ),
          ],
        ),
        actions: [          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              AppLocalizations.of(context)!.cancel,
              style: TextStyle(
                color: primaryColor,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            onPressed: () => Navigator.of(context).pop(controller.text),            child: Text(
              AppLocalizations.of(context)!.rename,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    
    if (newName != null && newName.isNotEmpty && newName != widget.title && mounted) {
      try {
        // Update the PWA name in shared preferences and home screen shortcut
        final success = await PWAManager.renamePWA(widget.url, newName);
        if (success && mounted) {
          // Update title in the state
          setState(() {
            _title = newName;
          });
          
          // Show success notification
          _showSuccessNotificationWithContent(
            Row(
              children: [
                Icon(Icons.check_circle_outlined, color: Colors.white),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.pwa_renamed,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      } catch (e) {
        debugPrint('Error renaming PWA: $e');
      }
    }
  }

  // Show remove PWA dialog
  Future<void> _showRemovePWADialog() async {
    // Get theme colors
    final primaryColor = ThemeManager.primaryColor();
    final backgroundColor = ThemeManager.backgroundColor();
    final textColor = ThemeManager.textColor();
    
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          AppLocalizations.of(context)!.remove_from_pwa,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to remove this PWA? This will delete the shortcut from your home screen and from the app. This action cannot be undone.',
          style: TextStyle(
            color: textColor,
          ),
        ),
        actions: [          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              AppLocalizations.of(context)!.cancel,
              style: TextStyle(
                color: primaryColor,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            onPressed: () => Navigator.of(context).pop(true),            child: Text(
              AppLocalizations.of(context)!.remove,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    
    if (confirm == true && mounted) {
      try {
        // Remove the PWA from app preferences and delete the shortcut from home screen
        final success = await PWAManager.deletePWA(widget.url);
        if (success && mounted) {
          // Show a notification that the PWA was removed successfully
          _showSuccessNotification(AppLocalizations.of(context)!.pwa_removed);
          
          // Small delay to allow notification to be visible
          await Future.delayed(const Duration(milliseconds: 300));
          
          // Close PWA screen
          if (mounted) {
            Navigator.of(context).pop();
          }
        }
      } catch (e) {
        debugPrint('Error removing PWA: $e');
      }
    }
  }
  
  // Show a notification with custom widget content
  void _showSuccessNotificationWithContent(Widget content) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;
    
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: ThemeManager.primaryColor(),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: content,
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 2), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }
  
  // Show a simple string notification
  void _showSuccessNotification(String message) {
    _showSuccessNotificationWithContent(
      Row(
        children: [
          Icon(Icons.check_circle_outline, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Restore system UI when leaving PWA screen
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
    super.dispose();
  }
} 