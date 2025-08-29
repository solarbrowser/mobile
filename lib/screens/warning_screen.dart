import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';

class WarningScreen extends StatefulWidget {
  final VoidCallback onContinue;

  const WarningScreen({
    Key? key,
    required this.onContinue,
  }) : super(key: key);

  @override
  _WarningScreenState createState() => _WarningScreenState();
}

class _WarningScreenState extends State<WarningScreen> {
  bool _dontShowAgain = false;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.yellow,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.yellow.withOpacity(0.3),
                      spreadRadius: 3,
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.black,
                  size: 40,
                ),
              ),

              const SizedBox(height: 32),

              Text(
                localizations.solarWarningTitle,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white, 
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[900]?.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.yellow,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      localizations.solarWarningMessage,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.6,
                        color: Colors.white, 
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  Checkbox(
                    value: _dontShowAgain,
                    onChanged: (value) {
                      setState(() {
                        _dontShowAgain = value ?? false;
                      });
                    },
                    activeColor: Colors.yellow,
                    checkColor: Colors.black,
                  ),
                  Expanded(
                    child: Text(
                      localizations.dontShowAgain,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70, 
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_dontShowAgain) {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('warning_screen_shown', true);
                    }
                    widget.onContinue();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellow, 
                    foregroundColor: Colors.black, 
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: Text(
                    localizations.continueButton,
                    style: const TextStyle(
                      fontSize: 18,
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
}
