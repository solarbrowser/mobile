import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class UrlBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isSecure;
  final bool isDarkMode;
  final VoidCallback onReload;
  final Function(String) onSubmitted;
  final bool isExpanded;
  final bool isMinimized;

  const UrlBar({
    super.key,
    required this.controller,
    required this.isSecure,
    required this.isDarkMode,
    required this.onReload,
    required this.onSubmitted,
    this.isExpanded = false,
    this.isMinimized = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: isMinimized ? 36 : 48,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.black : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDarkMode ? Colors.white24 : Colors.black12,
          ),
        ),
      ),
      child: Row(
        children: [
          Image.asset(
            isSecure ? 'assets/secure24.png' : 'assets/unsecure24.png',
            width: isMinimized ? 16 : 20,
            height: isMinimized ? 16 : 20,
            color: isDarkMode ? Colors.white70 : Colors.black54,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
                fontSize: isMinimized ? 14 : 16,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintStyle: TextStyle(
                  color: isDarkMode ? Colors.white38 : Colors.black38,
                  fontSize: isMinimized ? 14 : 16,
                ),
              ),
              onSubmitted: onSubmitted,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onReload,
            child: Image.asset(
              'assets/reload24.png',
              width: isMinimized ? 16 : 20,
              height: isMinimized ? 16 : 20,
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
} 