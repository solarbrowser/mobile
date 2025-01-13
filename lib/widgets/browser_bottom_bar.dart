import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class BrowserBottomBar extends StatelessWidget {
  final VoidCallback onTabsTap;
  final VoidCallback onHistoryTap;
  final VoidCallback onSettingsTap;
  final bool isDarkMode;
  final bool isExpanded;
  final bool isMinimized;

  const BrowserBottomBar({
    super.key,
    required this.onTabsTap,
    required this.onHistoryTap,
    required this.onSettingsTap,
    required this.isDarkMode,
    this.isExpanded = false,
    this.isMinimized = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: isMinimized ? 48 : 56,
      child: BottomNavigationBar(
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        selectedItemColor: isDarkMode ? Colors.white : Colors.black,
        unselectedItemColor: isDarkMode ? Colors.white70 : Colors.black54,
        items: [
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/tabs24.png',
              width: isMinimized ? 16 : 20,
              height: isMinimized ? 16 : 20,
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
            label: AppLocalizations.of(context)!.tabs,
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/history24.png',
              width: isMinimized ? 16 : 20,
              height: isMinimized ? 16 : 20,
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
            label: AppLocalizations.of(context)!.history,
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/settings24.png',
              width: isMinimized ? 16 : 20,
              height: isMinimized ? 16 : 20,
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
            label: AppLocalizations.of(context)!.settings,
          ),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              onTabsTap();
              break;
            case 1:
              onHistoryTap();
              break;
            case 2:
              onSettingsTap();
              break;
          }
        },
      ),
    );
  }
} 