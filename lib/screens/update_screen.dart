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
  late AnimationController _animationController;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    
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
          initialClassicMode: true, // Start with classic mode enabled
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
    return Positioned.fill(
      child: CustomAnimationBuilder<double>(
        tween: 0.0.tweenTo(2 * 3.14),
        duration: const Duration(seconds: 10),
        builder: (context, value, child) {
          return CustomPaint(
            painter: ParticlePainter(
              angle: value,
              isDarkMode: Theme.of(context).brightness == Brightness.dark,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLargeScreen = size.width > 600;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

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
              // Background particles
              _buildParticleBackground(),
              
              // Main content
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: size.width * 0.08,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo
                      AnimatedBuilder(
                        animation: _floatAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, _floatAnimation.value),
                            child: Hero(
                              tag: 'logo',
                              child: Image.asset(
                                'assets/icon.png',
                                width: isLargeScreen ? 150 : 100,
                                height: isLargeScreen ? 150 : 100,
                              ),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: size.height * 0.04),
                      
                      // Localized "Solar Updated!" text
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
                            fontSize: isLargeScreen ? 36 : 28,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(height: size.height * 0.02),
                      
                      // Version number
                      Text(
                        AppLocalizations.of(context)!.version(widget.currentVersion),
                        style: TextStyle(
                          fontSize: isLargeScreen ? 20 : 16,
                          color: ThemeManager.textSecondaryColor(),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: size.height * 0.08),
                      
                      // OK button
                      _buildGlassmorphicContainer(
                        child: ElevatedButton(
                          onPressed: _handleContinue,
                          style: ElevatedButton.styleFrom(
                            foregroundColor: ThemeManager.textColor(),
                            backgroundColor: Colors.transparent,
                            elevation: 0,
                            padding: EdgeInsets.symmetric(
                              horizontal: size.width * 0.15,
                              vertical: isLargeScreen ? 18 : 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),                          child: Text(
                            AppLocalizations.of(context)!.ok,
                            style: TextStyle(
                              fontSize: isLargeScreen ? 20 : 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
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

    final particleCount = 30; // Reduced particle count
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final random = Random(42); // Fixed seed for consistent pattern

    for (var i = 0; i < particleCount; i++) {
      final radius = (i / particleCount) * size.width * 0.8;
      final x = centerX + radius * cos(angle + i * 0.2);
      final y = centerY + radius * sin(angle + i * 0.2);
      
      final baseSize = 0.8 + (i / particleCount) * 3.0; // Smaller particles
      final randomSize = baseSize * (0.5 + random.nextDouble());
      final opacity = 0.03 + (random.nextDouble() * 0.05); // Lower opacity
      
      paint.color = (isDarkMode ? Colors.white : Colors.black).withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), randomSize, paint);
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => angle != oldDelegate.angle;
} 