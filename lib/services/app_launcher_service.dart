import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

class AppLauncherService {
  // Only handle market scheme - no app mappings, no popups
  static const Set<String> _systemSchemes = {
    'market',  // Google Play Store links only
  };

  /// Check if a URL can be opened in a native app
  static bool canOpenInApp(String url) {
    // Only return true for market schemes, no other apps
    return isSystemScheme(url);
  }

  /// Get app info for a given URL
  static Map<String, String>? getAppInfo(String url) {
    // No app info needed - only handling market scheme
    return null;
  }

  /// Launch app if available, return true if app was launched
  static Future<bool> tryLaunchApp(String url) async {
    try {
      // Only handle market scheme - no platform channel, no popups
      if (isSystemScheme(url)) {
        return await tryLaunchSystemScheme(url);
      }
      
      // No other apps supported
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Get list of all supported apps
  static List<Map<String, String>> getSupportedApps() {
    // No apps supported anymore
    return [];
  }

  /// Get supported domains
  static List<String> getSupportedDomains() {
    // No domains supported anymore
    return [];
  }

  /// Check if a URL uses a system scheme that can be handled directly
  static bool isSystemScheme(String url) {
    try {
      final uri = Uri.parse(url);
      return _systemSchemes.contains(uri.scheme.toLowerCase());
    } catch (e) {
      return false;
    }
  }

  /// Launch a system URL scheme directly using url_launcher
  static Future<bool> tryLaunchSystemScheme(String url) async {
    try {
      if (!isSystemScheme(url)) return false;
      
      final uri = Uri.parse(url);
      
      // For system schemes, try to launch directly with system chooser
      // Don't check canLaunchUrl first as it may return false even when the system can handle it
      return await launchUrl(
        uri, 
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      // If direct launch fails, try with platform default mode
      try {
        final uri = Uri.parse(url);
        return await launchUrl(
          uri,
          mode: LaunchMode.platformDefault,
        );
      } catch (e2) {
        return false;
      }
    }
  }
}
