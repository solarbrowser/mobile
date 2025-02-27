import 'package:flutter/material.dart';
import '../theme/theme_manager.dart';

class CustomDialog extends StatelessWidget {
  final String title;
  final String? content;
  final List<Widget> actions;
  final Widget? customContent;
  final bool isDarkMode;

  const CustomDialog({
    Key? key,
    required this.title,
    this.content,
    required this.actions,
    this.customContent,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: ThemeManager.backgroundColor(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: ThemeManager.textColor(),
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      content: customContent ?? (content != null ? Text(
        content!,
        style: TextStyle(
          color: ThemeManager.textSecondaryColor(),
          fontSize: 16,
        ),
      ) : null),
      actions: actions,
    );
  }
}

void showCustomDialog({
  required BuildContext context,
  required String title,
  String? content,
  required List<Widget> actions,
  Widget? customContent,
  required bool isDarkMode,
}) {
  showGeneralDialog(
    context: context,
    pageBuilder: (context, animation, secondaryAnimation) => Container(),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
      );

      return ScaleTransition(
        scale: Tween<double>(begin: 0.8, end: 1.0).animate(curvedAnimation),
        child: FadeTransition(
          opacity: animation,
          child: CustomDialog(
            title: title,
            content: content,
            actions: actions,
            customContent: customContent,
            isDarkMode: isDarkMode,
          ),
        ),
      );
    },
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: ThemeManager.textColor().withOpacity(0.5),
    transitionDuration: const Duration(milliseconds: 200),
  );
} 