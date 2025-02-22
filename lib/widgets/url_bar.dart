import 'dart:ui';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class UrlBar extends StatefulWidget {
  final bool isDarkMode;
  final TextEditingController urlController;
  final FocusNode urlFocusNode;
  final Function(String) onSubmitted;
  final VoidCallback onRefresh;
  final bool canGoBack;
  final bool canGoForward;
  final Function() onGoBack;
  final Function() onGoForward;
  final Animation<Offset> hideAnimation;

  const UrlBar({
    Key? key,
    required this.isDarkMode,
    required this.urlController,
    required this.urlFocusNode,
    required this.onSubmitted,
    required this.onRefresh,
    required this.canGoBack,
    required this.canGoForward,
    required this.onGoBack,
    required this.onGoForward,
    required this.hideAnimation,
  }) : super(key: key);

  @override
  State<UrlBar> createState() => _UrlBarState();
}

class _UrlBarState extends State<UrlBar> {
  double _slideOffset = 0.0;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: MediaQuery.of(context).padding.bottom + 16,
      child: SlideTransition(
        position: widget.hideAnimation,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: widget.isDarkMode ? Colors.black.withOpacity(0.7) : Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: widget.isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 0,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: GestureDetector(
                onHorizontalDragUpdate: (details) {
                  setState(() {
                    _slideOffset += details.delta.dx;
                    _slideOffset = _slideOffset.clamp(-100.0, 100.0);
                  });
                },
                onHorizontalDragEnd: (details) async {
                  if (_slideOffset.abs() > 50) {
                    if (_slideOffset < 0 && widget.canGoBack) {
                      widget.onGoBack();
                    } else if (_slideOffset > 0 && widget.canGoForward) {
                      widget.onGoForward();
                    }
                  }
                  setState(() {
                    _slideOffset = 0;
                  });
                },
                child: Transform.translate(
                  offset: Offset(_slideOffset, 0),
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: widget.urlController,
                          focusNode: widget.urlFocusNode,
                          style: TextStyle(
                            color: widget.isDarkMode ? Colors.white : Colors.black87,
                            fontSize: 16,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Search or enter address',
                            hintStyle: TextStyle(
                              color: widget.isDarkMode ? Colors.white60 : Colors.black45,
                            ),
                          ),
                          onTap: () {
                            widget.urlController.selection = TextSelection(
                              baseOffset: 0,
                              extentOffset: widget.urlController.text.length,
                            );
                          },
                          onSubmitted: widget.onSubmitted,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.refresh_rounded,
                          color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                          size: 20,
                        ),
                        onPressed: widget.onRefresh,
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 