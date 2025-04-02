import 'package:http/http.dart' as http;

class BrowserUtils {
  static Future<bool> checkFaviconExists(String url) async {
    try {
      final response = await http.head(Uri.parse(url));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<String?> getFaviconUrl(String pageUrl) async {
    try {
      final uri = Uri.parse(pageUrl);
      
      // List of potential favicon locations to check in order of preference
      final potentialIconUrls = [
        // Web app manifest (for PWAs)
        '${uri.scheme}://${uri.host}/manifest.json',
        '${uri.scheme}://${uri.host}/site.webmanifest',
        // Apple touch icons - higher quality
        '${uri.scheme}://${uri.host}/apple-touch-icon.png',
        '${uri.scheme}://${uri.host}/apple-touch-icon-precomposed.png',
        // Standard favicon options
        '${uri.scheme}://${uri.host}/favicon-192x192.png',
        '${uri.scheme}://${uri.host}/favicon-128x128.png',
        '${uri.scheme}://${uri.host}/favicon-96x96.png',
        '${uri.scheme}://${uri.host}/favicon-32x32.png',
        '${uri.scheme}://${uri.host}/favicon.png',
        '${uri.scheme}://${uri.host}/favicon.ico',
      ];
      
      // Check for manifest.json first, which is common for PWAs
      if (await checkFaviconExists(potentialIconUrls[0])) {
        try {
          final manifestResponse = await http.get(Uri.parse(potentialIconUrls[0]));
          if (manifestResponse.statusCode == 200) {
            final manifestJson = manifestResponse.body;
            // If manifest contains icons, return the largest one
            if (manifestJson.contains("icons")) {
              // This is a very basic check - in a complete implementation
              // you would parse the JSON and find the largest icon
              // For now, we'll use Google's favicon service as fallback
              return 'https://www.google.com/s2/favicons?domain=${uri.host}&sz=128';
            }
          }
        } catch (e) {
          // Ignore manifest parsing errors and continue with other methods
        }
      }
      
      // Try all other potential favicon locations
      for (var iconUrl in potentialIconUrls.skip(1)) {
        if (await checkFaviconExists(iconUrl)) {
          return iconUrl;
        }
      }
      
      // If nothing is found, use Google's favicon service which works well for most sites
      return 'https://www.google.com/s2/favicons?domain=${uri.host}&sz=64';
    } catch (e) {
      // If all else fails, return Google's favicon service URL
      try {
        final uri = Uri.parse(pageUrl);
        return 'https://www.google.com/s2/favicons?domain=${uri.host}&sz=64';
      } catch (e) {
        return null;
      }
    }
  }

  static String getDefaultUserAgent(bool isIOS) {
    if (isIOS) {
      return 'Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1';
    } else {
      return 'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.0.0 Mobile Safari/537.36';
    }
  }
} 