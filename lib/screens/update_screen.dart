import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import 'dart:ui';
import 'browser_screen.dart';

class UpdateScreen extends StatefulWidget {
  final String currentVersion;
  final String oldVersion;
  
  const UpdateScreen({
    Key? key,
    required this.currentVersion,
    required this.oldVersion,
  }) : super(key: key);

  @override
  State<UpdateScreen> createState() => _UpdateScreenState();
}

class _UpdateScreenState extends State<UpdateScreen> {
  Widget _buildGlassmorphicContainer({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.2),
                Colors.white.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getUpdateNotes() {
    // Add update notes for each version
    return [
      {
        'version': '0.0.39,5',
        'changes': [
          'Added welcome screen for new users',
          'Added update log screen',
          'Added more language options',
          'Improved performance and optimization',
          'Enhanced UI with glassmorphism effects',
          'Added automatic OS theme and language detection',
        ],
      },
      {
        'version': '0.0.3',
        'changes': [
          'Initial release',
          'Basic browsing functionality',
          'Tab management',
          'History tracking',
          'Basic settings',
        ],
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode 
              ? [Colors.black, Colors.black87]
              : [Colors.white, Colors.grey.shade100],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/icon.png',
                        width: 120,
                        height: 120,
                      ),
                      const SizedBox(height: 30),
                      Text(
                        AppLocalizations.of(context)!.updated,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        AppLocalizations.of(context)!.version(widget.currentVersion),
                        style: TextStyle(
                          fontSize: 16,
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 40),
                      _buildChangelogCard(isDarkMode),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDarkMode ? Colors.white : Colors.black,
                    foregroundColor: isDarkMode ? Colors.black : Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => BrowserScreen(
                          onLocaleChange: (String locale) {
                            // Handle locale change
                          },
                        ),
                      ),
                    );
                  },
                  child: Text(
                    AppLocalizations.of(context)!.continueText,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChangelogCard(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What\'s New',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          _buildChangelogItem(
            isDarkMode,
            'Performance Improvements',
            'Faster page loading and smoother scrolling',
          ),
          _buildChangelogItem(
            isDarkMode,
            'New Features',
            'Added bookmarks and improved downloads management',
          ),
          _buildChangelogItem(
            isDarkMode,
            'Bug Fixes',
            'Fixed various issues and improved stability',
          ),
        ],
      ),
    );
  }

  Widget _buildChangelogItem(bool isDarkMode, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
} 