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
      final iconUrl = '${uri.scheme}://${uri.host}/favicon.ico';
      if (await checkFaviconExists(iconUrl)) {
        return iconUrl;
      }
      
      final pngUrl = '${uri.scheme}://${uri.host}/favicon.png';
      if (await checkFaviconExists(pngUrl)) {
        return pngUrl;
      }
      
      return null;
    } catch (e) {
      return null;
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