import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import 'dart:ui';
import 'browser_screen.dart';

class UpdateScreen extends StatefulWidget {
  final String currentVersion;
  final String oldVersion;
  final Function(String) onLocaleChange;
  
  const UpdateScreen({
    Key? key,
    required this.currentVersion,
    required this.oldVersion,
    required this.onLocaleChange,
  }) : super(key: key);

  @override
  State<UpdateScreen> createState() => _UpdateScreenState();
}

class _UpdateScreenState extends State<UpdateScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
    
    // Save the current version when update screen is shown
    _saveCurrentVersion();
  }

  Future<void> _saveCurrentVersion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_shown_version', widget.currentVersion);
  }

  void _handleContinue() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => BrowserScreen(
          onLocaleChange: widget.onLocaleChange,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

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
        'version': '0.0.6',
        'changes': [
          AppLocalizations.of(context)!.welcomeDescription,
          AppLocalizations.of(context)!.whats_new,
          AppLocalizations.of(context)!.chooseLanguage,
          AppLocalizations.of(context)!.browser_data_cleared,
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
          child: Stack(
            children: [
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Opacity(
                      opacity: _fadeAnimation.value,
                      child: Column(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(20),
                              physics: const BouncingScrollPhysics(),
                              child: Column(
                                children: [
                                  Hero(
                                    tag: 'logo',
                                    child: Image.asset(
                                      'assets/icon.png',
                                      width: 120,
                                      height: 120,
                                    ),
                                  ),
                                  const SizedBox(height: 30),
                                  ShaderMask(
                                    shaderCallback: (bounds) => LinearGradient(
                                      colors: isDarkMode
                                          ? [Colors.white, Colors.white70]
                                          : [Colors.black, Colors.black87],
                                    ).createShader(bounds),
                                    child: Text(
                                      AppLocalizations.of(context)!.updated,
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                      ),
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
                                  const SizedBox(height: 20),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: _buildGlassmorphicContainer(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _handleContinue,
                                  borderRadius: BorderRadius.circular(30),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    child: Text(
                                      AppLocalizations.of(context)!.continueText,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: isDarkMode ? Colors.white : Colors.black,
                                      ),
                                    ),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChangelogCard(bool isDarkMode) {
    final updateNotes = _getUpdateNotes();
    
    return _buildGlassmorphicContainer(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.whats_new,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            ...updateNotes.map((version) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Version ${version['version']}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(
                    version['changes'].length,
                    (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 6),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDarkMode ? Colors.white60 : Colors.black54,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              version['changes'][index],
                              style: TextStyle(
                                fontSize: 15,
                                color: isDarkMode ? Colors.white60 : Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (version != updateNotes.last) const SizedBox(height: 24),
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
} 