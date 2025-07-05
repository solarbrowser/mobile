import 'dart:io';
import 'package:http/http.dart' as http;

class SecureNetworkService {
  static const Duration _timeout = Duration(seconds: 30);
  
  static Future<http.Response> secureGet(String url, {Map<String, String>? headers}) async {
    // Ensure HTTPS only for external requests
    if (!url.startsWith('https://') && !_isLocalHost(url)) {
      throw ArgumentError('Only HTTPS requests are allowed for external URLs');
    }
    
    try {
      final uri = Uri.parse(url);
      return await http.get(uri, headers: headers).timeout(_timeout);
    } on SocketException {
      throw Exception('Network connection failed');
    } on HttpException {
      throw Exception('HTTP request failed');
    } catch (e) {
      throw Exception('Request failed: $e');
    }
  }
  
  static bool _isLocalHost(String url) {
    return url.contains('localhost') || 
           url.contains('127.0.0.1') || 
           url.contains('10.0.2.2');
  }
}
