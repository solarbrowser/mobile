import 'package:flutter/material.dart';

class CustomNotification extends StatelessWidget {
  final String message;
  final IconData? icon;
  final Color? iconColor;
  final SnackBarAction? action;
  final bool isDarkMode;

  const CustomNotification({
    Key? key,
    required this.message,
    this.icon,
    this.iconColor,
    this.action,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: iconColor ?? Colors.green),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black87,
                fontSize: 14,
              ),
            ),
          ),
          if (action != null) ...[
            const SizedBox(width: 12),
            action!,
          ],
        ],
      ),
    );
  }
}

void showCustomNotification({
  required BuildContext context,
  required String message,
  IconData? icon,
  Color? iconColor,
  Duration? duration,
  SnackBarAction? action,
  required bool isDarkMode,
}) {
  final overlayState = Overlay.of(context);
  late OverlayEntry overlayEntry;
  
  overlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 300),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, -50 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: child,
              ),
            );
          },
          child: CustomNotification(
            message: message,
            icon: icon,
            iconColor: iconColor,
            action: action,
            isDarkMode: isDarkMode,
          ),
        ),
      ),
    ),
  );

  overlayState.insert(overlayEntry);

  Future.delayed(duration ?? const Duration(seconds: 3), () {
    if (overlayEntry.mounted) {
      overlayEntry.remove();
    }
  });
} 