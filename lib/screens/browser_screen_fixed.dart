import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
// Other imports would be included here

class BrowserScreen extends StatefulWidget {
  const BrowserScreen({Key? key}) : super(key: key);

  @override
  _BrowserScreenState createState() => _BrowserScreenState();
}

class _BrowserScreenState extends State<BrowserScreen> with TickerProviderStateMixin {
  // All state variables would be properly initialized here
  
  WebViewController? _webViewController;
  bool _isSlideUpPanelVisible = false;
  bool _hideUrlBar = false;
  late AnimationController _slideUpController;
  late AnimationController _hideUrlBarController;
  bool _isClassicMode = false;
  
  bool get isTabsVisible => false; // Placeholder
  bool get isSettingsVisible => false; // Placeholder
  bool get isBookmarksVisible => false; // Placeholder
  bool get isDownloadsVisible => false; // Placeholder
  bool get isHistoryVisible => false; // Placeholder
  
  // onWillPop handler
  Future<bool> _onWillPop() async {
    // Logic for handling back press
    DateTime now = DateTime.now();
    if (_lastBackPressTime == null || 
        DateTime.now().difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      showCustomNotification(
        context: context,
        message: "Press back again to exit",
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

  // Helper method to handle WebView gestures
  Widget _buildWebViewWithGestures(WebViewController controller, bool _isSlideUpPanelVisible, AnimationController _slideUpController, bool _hideUrlBar, AnimationController _hideUrlBarController) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        // Don't respond to gestures when panels are visible
        if (_isSlideUpPanelVisible || isTabsVisible || isSettingsVisible || isBookmarksVisible || isDownloadsVisible) {
          return;
        }
        
        // Handle scroll detection
        if (details.delta.dy.abs() > 2) {
          if (details.delta.dy < 0) {
            // Scrolling up (hide URL bar)
            if (!_hideUrlBar) {
              setState(() {
                _hideUrlBar = true;
                _hideUrlBarController.forward();
              });
            }
          } else {
            // Scrolling down (show URL bar)
            if (_hideUrlBar) {
              setState(() {
                _hideUrlBar = false;
                _hideUrlBarController.reverse();
              });
            }
          }
        }
      },
      // Use Container with color to cover entire area including where keyboard would be
      child: Container(
        color: ThemeManager.backgroundColor(),
        child: WebViewWidget(
          controller: controller,
        ),
      ),
    );
  }
  
  // WebView scroll detector with padding - Fixed position
  Widget _buildWebViewScrollDetector() {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    
    if (!isTabsVisible && !isSettingsVisible && !isBookmarksVisible && !isDownloadsVisible) {
      return Positioned(
        top: statusBarHeight,
        left: 0,
        right: 0,  // Adjust bottom position to account for keyboard and buttons
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
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
  
  // URL Bar builder
  Widget _buildUrlBar() {
    // URL bar implementation would go here
    return Container(
      height: 50,
      color: Colors.grey.shade200,
      child: Center(
        child: Text('URL Bar'),
      ),
    );
  }

  // Overlay Panel builder
  Widget _buildOverlayPanel() {
    // Implementation of overlay panel would go here
    return Container();
  }

  // Classic mode panel builder
  Widget _buildClassicModePanel() {
    // Implementation of classic mode panel would go here
    return Container();
  }
  
  // SlideUp panel visibility handler
  void _handleSlideUpPanelVisibility(bool visible) {
    setState(() {
      _isSlideUpPanelVisible = visible;
      if (visible) {
        _slideUpController.forward();
      } else {
        _slideUpController.reverse();
      }
    });
  }
  
  // Placeholder for ThemeManager
  static class ThemeManager {
    static Color backgroundColor() => Colors.white;
    static Color textColor() => Colors.black;
  }
  
  // Placeholder for notification
  void showCustomNotification({
    required BuildContext context,
    required String message,
    required IconData icon,
    required Color iconColor,
    required bool isDarkMode,
    required Duration duration,
  }) {
    // Implementation would go here
  }
  
  // Other properties
  DateTime? _lastBackPressTime;
  bool get isDarkMode => false; // Placeholder

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: Stack(
          children: [
            // WebView with gesture detection
            _buildWebViewWithGestures(
              _webViewController!,
              _isSlideUpPanelVisible,
              _slideUpController,
              _hideUrlBar,
              _hideUrlBarController
            ),
            
            // Scroll detector overlay
            _buildWebViewScrollDetector(),
            
            // Overlay panels (tabs, settings, etc.)
            if (isTabsVisible || isSettingsVisible || isBookmarksVisible || isDownloadsVisible || isHistoryVisible)
              _buildOverlayPanel(),
                
            // Classic mode navigation panel with background that extends up to the URL bar
            if (_isClassicMode)
              AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                opacity: (_hideUrlBar || isTabsVisible || isSettingsVisible || isBookmarksVisible || isDownloadsVisible || isHistoryVisible) ? 0.0 : 1.0,
                child: AnimatedSlide(
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
                        ),
                      ),
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
                // Position the URL bar above the keyboard and above navigation buttons when visible
                bottom: keyboardVisible 
                   ? (_isClassicMode 
                      ? keyboardHeight + 56 // Classic mode - reduced from 65 to 56
                      : keyboardHeight + 8) // Non-classic mode - small spacing above keyboard
                   : (_isClassicMode 
                      ? 56 + MediaQuery.of(context).padding.bottom // Classic mode fixed position - reduced from 70 to 56
                      : MediaQuery.of(context).padding.bottom + 16), // Regular mode fixed position
                child: Column(
                  mainAxisSize: MainAxisSize.min,
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
                            child: Transform.translate(
                              offset: Offset(0, 50 + (1 - slideValue) * 50), // Reduced offset for subtler animation
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
                                          // Handle indicator UI implementation would go here
                                        ),
                                      ),
                                      // Panel content implementation would go here
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    
                    // URL bar with swipe gestures - always visible
                    GestureDetector(
                      onVerticalDragUpdate: (details) {
                        // Disable vertical drag gestures when keyboard is visible
                        if (keyboardVisible) return;
                        
                        // Different gesture behavior based on current panel visibility
                        if (_isSlideUpPanelVisible) {
                          if (details.delta.dy > 5) {
                            _handleSlideUpPanelVisibility(false);
                          }
                        } else {
                          if (details.delta.dy < -5) {
                            _handleSlideUpPanelVisibility(true);
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
  }
}
