import 'package:flutter/material.dart';

class CustomNotification extends StatelessWidget {
  final dynamic message;
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
        color: isDarkMode ? Colors.grey[900] : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: iconColor ?? Colors.green,
              size: 24,
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: DefaultTextStyle(
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black87,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              child: message is Widget ? message as Widget : Text(
                message.toString(),
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ),
          if (action != null) ...[
            const SizedBox(width: 12),
            TextButton(
              onPressed: action!.onPressed,
              style: TextButton.styleFrom(
                foregroundColor: isDarkMode ? Colors.blue[200] : Colors.blue,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: const Size(0, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                action!.label,
                style: TextStyle(
                  color: isDarkMode ? Colors.blue[200] : Colors.blue,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
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