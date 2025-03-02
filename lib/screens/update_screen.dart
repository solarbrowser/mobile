import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import 'dart:ui';
import 'dart:math';
import 'browser_screen.dart';
import '../utils/theme_manager.dart';
import 'package:simple_animations/simple_animations.dart';
import 'package:supercharged/supercharged.dart';

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
  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _floatAnimation;
  int _currentPage = 0;
  bool _showSkip = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _floatAnimation = Tween<double>(begin: 0, end: 15)
        .animate(CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeInOut,
        ));
        
    _animationController.forward();
    _animationController.repeat(reverse: true);
    
    // Save the current version when update screen is shown
    _saveCurrentVersion();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
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

  Widget _buildGlassmorphicContainer({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                ThemeManager.textColor().withOpacity(0.2),
                ThemeManager.textColor().withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: ThemeManager.textColor().withOpacity(0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: ThemeManager.textColor().withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildParticleBackground() {
    return CustomAnimationBuilder<double>(
      tween: 0.0.tweenTo(2 * 3.14),
      duration: const Duration(seconds: 10),
      builder: (context, value, child) {
        return CustomPaint(
          painter: ParticlePainter(
            angle: value,
            isDarkMode: Theme.of(context).brightness == Brightness.dark,
          ),
          child: child,
        );
      },
      child: Container(),
    );
  }

  Widget _buildWelcomePage() {
    final size = MediaQuery.of(context).size;
    final isLargeScreen = size.width > 600;

    return Stack(
      children: [
        _buildParticleBackground(),
        Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: size.width * 0.08,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isLargeScreen ? 600 : size.width * 0.84,
                  ),
                  child: AnimatedBuilder(
                    animation: _floatAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _floatAnimation.value),
                        child: _buildGlassmorphicContainer(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: size.width * 0.05,
                              vertical: size.height * 0.03,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Hero(
                                  tag: 'logo',
                                  child: Image.asset(
                                    'assets/icon.png',
                                    width: isLargeScreen ? 120 : 80,
                                    height: isLargeScreen ? 120 : 80,
                                  ),
                                ),
                                SizedBox(height: size.height * 0.02),
                                ShaderMask(
                                  shaderCallback: (bounds) => LinearGradient(
                                    colors: [
                                      ThemeManager.textColor(),
                                      ThemeManager.textSecondaryColor(),
                                    ],
                                  ).createShader(bounds),
                                  child: Text(
                                    AppLocalizations.of(context)!.updated,
                                    style: TextStyle(
                                      fontSize: isLargeScreen ? 32 : 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                SizedBox(height: size.height * 0.015),
                                Text(
                                  AppLocalizations.of(context)!.version(widget.currentVersion),
                                  style: TextStyle(
                                    fontSize: isLargeScreen ? 18 : 14,
                                    color: ThemeManager.textSecondaryColor(),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Map<String, String>> _getUpdateNotes() {
    return [
      {
        'title': AppLocalizations.of(context)!.update1,
        'description': AppLocalizations.of(context)!.update1desc,
      },
      {
        'title': AppLocalizations.of(context)!.update2,
        'description': AppLocalizations.of(context)!.update2desc,
      },
      {
        'title': AppLocalizations.of(context)!.update3,
        'description': AppLocalizations.of(context)!.update3desc,
      },
      {
        'title': AppLocalizations.of(context)!.update4,
        'description': AppLocalizations.of(context)!.update4desc,
      },
    ];
  }

  Widget _buildUpdatePage(String title, String description) {
    final size = MediaQuery.of(context).size;
    final isLargeScreen = size.width > 600;

    return Stack(
      children: [
        _buildParticleBackground(),
        Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: size.width * 0.08,
                vertical: size.height * 0.05,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isLargeScreen ? 600 : size.width * 0.84,
                  ),
                  child: _buildGlassmorphicContainer(
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [
                                ThemeManager.textColor(),
                                ThemeManager.textSecondaryColor(),
                              ],
                            ).createShader(bounds),
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: isLargeScreen ? 28 : 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(height: size.height * 0.02),
                          Text(
                            description,
                            style: TextStyle(
                              fontSize: isLargeScreen ? 16 : 14,
                              color: ThemeManager.textColor(),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLargeScreen = size.width > 600;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final updateNotes = _getUpdateNotes();

    return Scaffold(
      backgroundColor: ThemeManager.backgroundColor(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode 
              ? [ThemeManager.backgroundColor(), ThemeManager.backgroundColor().withOpacity(0.87)]
              : [ThemeManager.backgroundColor(), ThemeManager.surfaceColor()],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  _buildWelcomePage(),
                  ...updateNotes.map((note) => _buildUpdatePage(note['title']!, note['description']!)).toList(),
                ],
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: size.width * 0.05,
                    right: size.width * 0.05,
                    bottom: size.height * 0.03,
                  ),
                  child: _buildGlassmorphicContainer(
                    child: Container(
                      height: isLargeScreen ? 72 : 56,
                      padding: EdgeInsets.symmetric(horizontal: size.width * 0.05),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (_currentPage > 0)
                            TextButton(
                              onPressed: () {
                                _pageController.previousPage(
                                  duration: const Duration(milliseconds: 500),
                                  curve: Curves.easeInOutCubic,
                                );
                                setState(() {
                                  _showSkip = true;
                                });
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size(isLargeScreen ? 80 : 60, isLargeScreen ? 48 : 36),
                              ),
                              child: Text(
                                AppLocalizations.of(context)!.back,
                                style: TextStyle(
                                  color: ThemeManager.textSecondaryColor(),
                                  fontSize: isLargeScreen ? 18 : 15,
                                ),
                              ),
                            )
                          else if (_showSkip)
                            TextButton(
                              onPressed: _handleContinue,
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size(isLargeScreen ? 80 : 60, isLargeScreen ? 48 : 36),
                              ),
                              child: Text(
                                'Skip',
                                style: TextStyle(
                                  color: ThemeManager.textSecondaryColor(),
                                  fontSize: isLargeScreen ? 18 : 15,
                                ),
                              ),
                            )
                          else
                            SizedBox(width: isLargeScreen ? 80 : 60),
                          Row(
                            children: List.generate(updateNotes.length + 1, (index) => Padding(
                              padding: EdgeInsets.symmetric(horizontal: isLargeScreen ? 4 : 2),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: _currentPage == index ? (isLargeScreen ? 24 : 16) : (isLargeScreen ? 8 : 6),
                                height: isLargeScreen ? 8 : 6,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(isLargeScreen ? 4 : 3),
                                  color: _currentPage == index
                                    ? ThemeManager.textColor()
                                    : ThemeManager.textSecondaryColor(),
                                ),
                              ),
                            )),
                          ),
                          TextButton(
                            onPressed: () {
                              if (_currentPage < updateNotes.length) {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 500),
                                  curve: Curves.easeInOutCubic,
                                );
                                setState(() {
                                  _showSkip = false;
                                });
                              } else {
                                _handleContinue();
                              }
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size(isLargeScreen ? 80 : 60, isLargeScreen ? 48 : 36),
                            ),
                            child: Text(
                              _currentPage < updateNotes.length
                                ? AppLocalizations.of(context)!.next
                                : AppLocalizations.of(context)!.getStarted,
                              style: TextStyle(
                                color: ThemeManager.textColor(),
                                fontWeight: FontWeight.bold,
                                fontSize: isLargeScreen ? 18 : 15,
                              ),
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
      ),
    );
  }
}

class ParticlePainter extends CustomPainter {
  final double angle;
  final bool isDarkMode;

  ParticlePainter({required this.angle, required this.isDarkMode});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    final particleCount = 50;
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final random = Random(42); // Fixed seed for consistent pattern

    for (var i = 0; i < particleCount; i++) {
      final radius = (i / particleCount) * size.width * 0.8;
      final x = centerX + radius * cos(angle + i * 0.2);
      final y = centerY + radius * sin(angle + i * 0.2);
      
      final baseSize = 1.0 + (i / particleCount) * 4.0;
      final randomSize = baseSize * (0.5 + random.nextDouble());
      final opacity = 0.05 + (random.nextDouble() * 0.1);
      
      paint.color = (isDarkMode ? Colors.white : Colors.black).withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), randomSize, paint);
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => angle != oldDelegate.angle;
} 