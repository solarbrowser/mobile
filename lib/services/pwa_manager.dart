import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../utils/browser_utils.dart';
import '../utils/theme_manager.dart';
import '../l10n/app_localizations.dart';

class PWAOfflineCache {
  static const String _cacheKey = 'pwa_offline_cache';
  static const String _cacheMetadataKey = 'pwa_cache_metadata';
  static const int _maxCacheSize = 50 * 1024 * 1024; // 50MB max cache
  static const int _maxCacheAge = 7 * 24 * 60 * 60 * 1000; // 7 days in milliseconds

  // Cache a PWA's essential resources for offline use
  static Future<bool> cachePWAResources(String url, String title) async {
    try {
      final directory = await _getCacheDirectory();
      final urlHash = url.hashCode.abs().toString();
      final pwaDir = Directory(path.join(directory.path, 'pwa_$urlHash'));
      
      if (!await pwaDir.exists()) {
        await pwaDir.create(recursive: true);
      }

      // Cache the main HTML
      final htmlResponse = await http.get(Uri.parse(url));
      if (htmlResponse.statusCode == 200) {
        final htmlFile = File(path.join(pwaDir.path, 'index.html'));
        await htmlFile.writeAsString(htmlResponse.body);

        // Parse and cache critical resources
        await _cacheCriticalResources(htmlResponse.body, url, pwaDir);

        // Update cache metadata
        await _updateCacheMetadata(url, title, pwaDir.path);

        return true;
      }
      return false;
    } catch (e) {
      print('Error caching PWA resources: $e');
      return false;
    }
  }

  // Cache critical resources like CSS, JS, and icons
  static Future<void> _cacheCriticalResources(String html, String baseUrl, Directory cacheDir) async {
    try {
      final Uri baseUri = Uri.parse(baseUrl);
      
      // Simple regex patterns to find resources
      final patterns = [
        RegExp(r'<link[^>]+href=["'"'"']([^"'"'"']+\.css)["'"'"']', caseSensitive: false),
        RegExp(r'<script[^>]+src=["'"'"']([^"'"'"']+\.js)["'"'"']', caseSensitive: false),
        RegExp(r'<link[^>]+href=["'"'"']([^"'"'"']+\.ico)["'"'"']', caseSensitive: false),
        RegExp(r'<link[^>]+href=["'"'"']([^"'"'"']+\.png)["'"'"']', caseSensitive: false),
      ];

      for (final pattern in patterns) {
        final matches = pattern.allMatches(html);
        for (final match in matches) {
          final resourceUrl = match.group(1);
          if (resourceUrl != null) {
            await _cacheResource(resourceUrl, baseUri, cacheDir);
          }
        }
      }
    } catch (e) {
      print('Error caching critical resources: $e');
    }
  }

  // Cache a single resource
  static Future<void> _cacheResource(String resourceUrl, Uri baseUri, Directory cacheDir) async {
    try {
      Uri fullUri;
      if (resourceUrl.startsWith('http')) {
        fullUri = Uri.parse(resourceUrl);
      } else if (resourceUrl.startsWith('//')) {
        fullUri = Uri.parse('${baseUri.scheme}:$resourceUrl');
      } else {
        fullUri = baseUri.resolve(resourceUrl);
      }

      final response = await http.get(fullUri);
      if (response.statusCode == 200) {
        final fileName = path.basename(fullUri.path);
        final file = File(path.join(cacheDir.path, fileName));
        await file.writeAsBytes(response.bodyBytes);
      }
    } catch (e) {
      print('Error caching resource $resourceUrl: $e');
    }
  }

  // Check if PWA has cached content
  static Future<bool> hasCachedContent(String url) async {
    try {
      final directory = await _getCacheDirectory();
      final urlHash = url.hashCode.abs().toString();
      final pwaDir = Directory(path.join(directory.path, 'pwa_$urlHash'));
      final htmlFile = File(path.join(pwaDir.path, 'index.html'));
      return await htmlFile.exists();
    } catch (e) {
      return false;
    }
  }

  // Get cached HTML content
  static Future<String?> getCachedHTML(String url) async {
    try {
      final directory = await _getCacheDirectory();
      final urlHash = url.hashCode.abs().toString();
      final pwaDir = Directory(path.join(directory.path, 'pwa_$urlHash'));
      final htmlFile = File(path.join(pwaDir.path, 'index.html'));
      
      if (await htmlFile.exists()) {
        return await htmlFile.readAsString();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Clear cache for a specific PWA
  static Future<void> clearPWACache(String url) async {
    try {
      final directory = await _getCacheDirectory();
      final urlHash = url.hashCode.abs().toString();
      final pwaDir = Directory(path.join(directory.path, 'pwa_$urlHash'));
      
      if (await pwaDir.exists()) {
        await pwaDir.delete(recursive: true);
      }

      // Remove from metadata
      final prefs = await SharedPreferences.getInstance();
      final metadataJson = prefs.getString(_cacheMetadataKey) ?? '{}';
      final metadata = json.decode(metadataJson) as Map<String, dynamic>;
      metadata.remove(url);
      await prefs.setString(_cacheMetadataKey, json.encode(metadata));
    } catch (e) {
      print('Error clearing PWA cache: $e');
    }
  }

  // Clear all PWA caches
  static Future<void> clearAllCaches() async {
    try {
      final directory = await _getCacheDirectory();
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheMetadataKey);
    } catch (e) {
      print('Error clearing all caches: $e');
    }
  }

  // Get cache size
  static Future<int> getCacheSize() async {
    try {
      final directory = await _getCacheDirectory();
      if (!await directory.exists()) return 0;

      int totalSize = 0;
      await for (final entity in directory.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
      return totalSize;
    } catch (e) {
      return 0;
    }
  }

  // Cleanup old cache entries
  static Future<void> cleanupOldCaches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final metadataJson = prefs.getString(_cacheMetadataKey) ?? '{}';
      final metadata = json.decode(metadataJson) as Map<String, dynamic>;
      
      final now = DateTime.now().millisecondsSinceEpoch;
      final urlsToRemove = <String>[];

      for (final entry in metadata.entries) {
        final cacheData = entry.value as Map<String, dynamic>;
        final timestamp = cacheData['timestamp'] as int? ?? 0;
        
        if (now - timestamp > _maxCacheAge) {
          urlsToRemove.add(entry.key);
        }
      }

      for (final url in urlsToRemove) {
        await clearPWACache(url);
      }
    } catch (e) {
      print('Error during cache cleanup: $e');
    }
  }

  // Get cache directory
  static Future<Directory> _getCacheDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory(path.join(appDir.path, 'pwa_cache'));
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }

  // Update cache metadata
  static Future<void> _updateCacheMetadata(String url, String title, String cachePath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final metadataJson = prefs.getString(_cacheMetadataKey) ?? '{}';
      final metadata = json.decode(metadataJson) as Map<String, dynamic>;
      
      metadata[url] = {
        'title': title,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'cachePath': cachePath,
      };

      await prefs.setString(_cacheMetadataKey, json.encode(metadata));
    } catch (e) {
      print('Error updating cache metadata: $e');
    }
  }

  // Get cached PWAs list
  static Future<List<Map<String, dynamic>>> getCachedPWAs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final metadataJson = prefs.getString(_cacheMetadataKey) ?? '{}';
      final metadata = json.decode(metadataJson) as Map<String, dynamic>;
      
      return metadata.entries.map((entry) => {
        'url': entry.key,
        ...entry.value as Map<String, dynamic>,
      }).toList();
    } catch (e) {
      return [];
    }
  }
}

class PWAManager {
  static const String _pwaShortcutsKey = 'pwa_shortcuts';
  static const platform = MethodChannel('com.vertex.solar/shortcuts');
    // Prompt for PWA name with improved styling and custom animation
  static Future<String?> showNamePrompt(BuildContext context, String title) async {
    final TextEditingController controller = TextEditingController(text: title);
    final localizations = AppLocalizations.of(context);
    
    // Get theme colors
    final primaryColor = ThemeManager.primaryColor();
    final backgroundColor = ThemeManager.backgroundColor();
    final textColor = ThemeManager.textColor();
    final surfaceColor = ThemeManager.surfaceColor();
    
    String? result = await showGeneralDialog<String>(
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
            child: AlertDialog(
              backgroundColor: backgroundColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                localizations?.create_shortcut ?? 'Create Shortcut',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations?.enter_shortcut_name ?? 'Enter a name for this shortcut:',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: primaryColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: controller,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: InputBorder.none,
                        hintText: localizations?.shortcut_name ?? 'Shortcut name',
                        hintStyle: TextStyle(
                          color: textColor.withOpacity(0.5),
                        ),
                      ),
                      autofocus: true,
                    ),
                  ),
                ],
              ),
              contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    localizations?.cancel ?? 'CANCEL',
                    style: TextStyle(
                      color: textColor.withOpacity(0.7),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    final name = controller.text.trim();
                    if (name.isNotEmpty) {
                      Navigator.of(context).pop(name);
                    }
                  },
                  child: Text(
                    localizations?.add ?? 'ADD',
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: textColor.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 200),
    );
    
    return result;
  }
  
  // Store PWA data with URL, title, favicon, and timestamp
  static Future<bool> savePWA(BuildContext context, String url, String title, String? favicon) async {
    try {
      // Special handling for Google search URLs
      String finalUrl = url;
      String finalTitle = title;
      
      // Extract the search query from Google search URLs
      if (url.contains('google.com/search')) {
        try {
          final uri = Uri.parse(url);
          final queryParam = uri.queryParameters['q'];
          if (queryParam != null && queryParam.isNotEmpty) {
            // Set the title to be the search query
            finalTitle = 'Google: $queryParam';
            
            // You can optionally set the URL to be google.com
            // finalUrl = 'https://www.google.com';
          }
        } catch (e) {
          //debugPrint('Error parsing Google search URL: $e');
        }
      }
      
      // Prompt user for custom name
      String? customTitle = await showNamePrompt(context, finalTitle);
      if (customTitle == null) {
        // User cancelled
        return false;
      }
      
      //debugPrint('Saving PWA: $finalUrl, $customTitle, favicon: ${favicon?.substring(0, favicon != null && favicon.length > 30 ? 30 : favicon?.length ?? 0)}...');
      
      final prefs = await SharedPreferences.getInstance();
      
      // Get existing PWAs
      final List<String> pwaJsonList = prefs.getStringList(_pwaShortcutsKey) ?? [];
      final List<Map<String, dynamic>> pwaList = pwaJsonList
          .map((json) => jsonDecode(json) as Map<String, dynamic>)
          .toList();
      
      // Process favicon based on type
      String? finalFavicon = favicon;
      
      // For Google search, always use Google domain favicon
      if (url.contains('google.com/search')) {
        //debugPrint('Google search detected, using Google domain for favicon');
        // Replace with direct Google favicon URL instead of just the domain
        try {
          final googleFaviconUrl = 'https://www.google.com/s2/favicons?domain=www.google.com&sz=128';
          final response = await http.get(Uri.parse(googleFaviconUrl));
          if (response.statusCode == 200) {
            final base64Image = base64Encode(response.bodyBytes);
            finalFavicon = 'data:image/png;base64,$base64Image';
            //debugPrint('Successfully fetched Google favicon as data URL');
          }
        } catch (e) {
          //debugPrint('Error fetching Google favicon, falling back: $e');
          finalFavicon = await _fetchFavicon(finalUrl);
        }
      } 
      // Handle ICO files and HTTPS URLs specially
      else if (finalFavicon != null) {
        if (finalFavicon.endsWith('.ico') || finalFavicon.contains('favicon.ico')) {
          //debugPrint('ICO favicon detected, getting better version');
          try {
            // Always use Google's favicon service for ICO files
            final uri = Uri.parse(url);
            final domain = uri.host;
            final googleFaviconUrl = 'https://www.google.com/s2/favicons?domain=$domain&sz=128';
            final response = await http.get(Uri.parse(googleFaviconUrl));
            if (response.statusCode == 200) {
              final base64Image = base64Encode(response.bodyBytes);
              finalFavicon = 'data:image/png;base64,$base64Image';
              //debugPrint('Successfully converted ICO to Google favicon data URL');
            } else {
              finalFavicon = await _fetchFavicon(finalUrl);
            }
          } catch (e) {
            //debugPrint('Error processing ICO favicon: $e');
            finalFavicon = await _fetchFavicon(finalUrl);
          }
        } else if (finalFavicon.startsWith('https://')) {
          // For HTTPS URLs, convert to data URL
          try {
            final response = await http.get(Uri.parse(finalFavicon));
            if (response.statusCode == 200) {
              // Convert to data URL
              final contentType = response.headers['content-type'] ?? 'image/png';
              finalFavicon = 'data:$contentType;base64,${base64Encode(response.bodyBytes)}';
              //debugPrint('Successfully converted HTTPS favicon to data URL');
            } else {
              finalFavicon = await _fetchFavicon(finalUrl);
            }
          } catch (e) {
            //debugPrint('Error downloading HTTPS favicon: $e');
            finalFavicon = await _fetchFavicon(finalUrl);
          }
        } else if (!finalFavicon.startsWith('data:')) {
          // If the favicon is just a domain name or not a data URL, fetch a proper icon
          if (Uri.tryParse(finalFavicon) == null) {
            //debugPrint('Favicon is domain or text, fetching proper icon');
            try {
              final googleFaviconUrl = 'https://www.google.com/s2/favicons?domain=$finalFavicon&sz=128';
              final response = await http.get(Uri.parse(googleFaviconUrl));
              if (response.statusCode == 200) {
                final base64Image = base64Encode(response.bodyBytes);
                finalFavicon = 'data:image/png;base64,$base64Image';
                //debugPrint('Successfully converted domain to Google favicon data URL');
              } else {
                finalFavicon = await _fetchFavicon(finalUrl);
              }
            } catch (e) {
              //debugPrint('Error converting domain to favicon: $e');
              finalFavicon = await _fetchFavicon(finalUrl);
            }
          }
        }
      } else if (finalFavicon == null || finalFavicon.isEmpty) {
        try {
          finalFavicon = await _fetchFavicon(finalUrl);
        } catch (e) {
          //debugPrint('Failed to fetch favicon: $e');
        }
      }
      
      // Final check - if favicon is still just a domain name or null, use Google's service
      if (finalFavicon == null || finalFavicon.isEmpty || !finalFavicon.startsWith('data:') && !finalFavicon.startsWith('http')) {
        try {
          final uri = Uri.parse(url);
          final domain = uri.host;
          final googleFaviconUrl = 'https://www.google.com/s2/favicons?domain=$domain&sz=128';
          final response = await http.get(Uri.parse(googleFaviconUrl));
          if (response.statusCode == 200) {
            final base64Image = base64Encode(response.bodyBytes);
            finalFavicon = 'data:image/png;base64,$base64Image';
            //debugPrint('Final fallback: successfully fetched Google favicon');
          }
        } catch (e) {
          //debugPrint('Final fallback favicon fetch failed: $e');
        }
      }
      
      // Check if PWA with this URL already exists
      final existingIndex = pwaList.indexWhere((pwa) => pwa['url'] == finalUrl);
      if (existingIndex != -1) {
        // Update existing PWA
        pwaList[existingIndex] = {
          'url': finalUrl,
          'title': customTitle,
          'favicon': finalFavicon,
          'timestamp': DateTime.now().toIso8601String(),
        };
      } else {
        // Add new PWA
        pwaList.add({
          'url': finalUrl,
          'title': customTitle,
          'favicon': finalFavicon,
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
      
      // Save back to preferences
      final updatedJsonList = pwaList.map((pwa) => jsonEncode(pwa)).toList();
      await prefs.setStringList(_pwaShortcutsKey, updatedJsonList);
      
      // Create shortcut on home screen 
      await _createShortcut(finalUrl, customTitle, finalFavicon);
      
      // Cache PWA resources for offline use (run in background)
      Future.microtask(() async {
        try {
          //debugPrint('Starting offline cache for PWA: $customTitle');
          final success = await PWAOfflineCache.cachePWAResources(finalUrl, customTitle);
          if (success) {
            //debugPrint('PWA resources cached successfully for offline use');
          } else {
            //debugPrint('Failed to cache PWA resources');
          }
        } catch (e) {
          //debugPrint('Error caching PWA resources: $e');
        }
      });
      
      return true;
    } catch (e) {
      //debugPrint('Failed to save PWA: $e');
      return false;
    }
  }
  
  // Helper to fetch favicon if not provided
  static Future<String?> _fetchFavicon(String url) async {
    try {
      // Try using browser utils first - now improved with better HTTPS support
      final faviconUrl = await BrowserUtils.getFaviconUrl(url);
      if (faviconUrl != null && faviconUrl.isNotEmpty) {
        //debugPrint('Found favicon via BrowserUtils: $faviconUrl');
        
        // Check if the result is already a data URL
        if (faviconUrl.startsWith('data:')) {
          return faviconUrl;
        }
        
        // If it's a Google favicon URL, download and convert to data URL
        if (faviconUrl.contains('google.com/s2/favicons')) {
          try {
            final response = await http.get(Uri.parse(faviconUrl));
            if (response.statusCode == 200) {
              final base64Image = base64Encode(response.bodyBytes);
              return 'data:image/png;base64,$base64Image';
            }
          } catch (e) {
            //debugPrint('Error fetching Google favicon: $e');
          }
        }
        
        // Otherwise download the image and convert to data URL
        try {
          final response = await http.get(Uri.parse(faviconUrl));
          if (response.statusCode == 200) {
            final contentType = response.headers['content-type'] ?? 'image/x-icon';
            final base64Image = base64Encode(response.bodyBytes);
            return 'data:$contentType;base64,$base64Image';
          }
        } catch (e) {
          //debugPrint('Error converting favicon to data URL: $e');
        }
      }
      
      // Fall back to direct methods
      final uri = Uri.parse(url);
      final baseUrl = '${uri.scheme}://${uri.host}';
      
      // Always try Google's favicon service as a reliable option
      try {
        final googleFaviconUrl = 'https://www.google.com/s2/favicons?domain=${uri.host}&sz=128';
        final response = await http.get(Uri.parse(googleFaviconUrl));
        if (response.statusCode == 200) {
          //debugPrint('Using Google favicon service: $googleFaviconUrl');
          final base64Image = base64Encode(response.bodyBytes);
          return 'data:image/png;base64,$base64Image';
        }
      } catch (e) {
        //debugPrint('Error fetching Google favicon: $e');
      }
      
      // Try standard favicon locations (in order of preference)
      final possibleFaviconUrls = [
        '$baseUrl/manifest.json', // PWA manifest
        '$baseUrl/site.webmanifest', // PWA manifest alternative
        '$baseUrl/apple-touch-icon.png', // Apple touch icons usually higher quality
        '$baseUrl/apple-touch-icon-precomposed.png',
        '$baseUrl/apple-touch-icon-152x152.png',
        '$baseUrl/apple-touch-icon-144x144.png',
        '$baseUrl/apple-touch-icon-120x120.png',
        '$baseUrl/apple-touch-icon-114x114.png',
        '$baseUrl/apple-touch-icon-72x72.png',
        '$baseUrl/apple-touch-icon-57x57.png',
        '$baseUrl/favicon-192x192.png', // New standard larger favicons
        '$baseUrl/favicon-128x128.png',
        '$baseUrl/favicon-96x96.png',
        '$baseUrl/favicon-32x32.png',
        '$baseUrl/favicon.png',
        '$baseUrl/favicon.ico', // Standard ICO as last resort
      ];
      
      // For manifest.json and site.webmanifest, try to extract icon info
      for (int i = 0; i < 2; i++) {
        if (i >= possibleFaviconUrls.length) break;
        
        try {
          final response = await http.get(Uri.parse(possibleFaviconUrls[i]));
          if (response.statusCode == 200 && response.body.contains('icons')) {
            // Very basic check - just confirm it has icons
            // Using Google's service as a reliable fallback since manifest parsing is complex
            final googleFaviconUrl = 'https://www.google.com/s2/favicons?domain=${uri.host}&sz=128';
            final iconResponse = await http.get(Uri.parse(googleFaviconUrl));
            if (iconResponse.statusCode == 200) {
              final base64Image = base64Encode(iconResponse.bodyBytes);
              return 'data:image/png;base64,$base64Image';
            }
          }
        } catch (e) {
          continue;
        }
      }
      
      // Try downloading direct favicon URLs
      for (int i = 2; i < possibleFaviconUrls.length; i++) {
        try {
          final response = await http.head(Uri.parse(possibleFaviconUrls[i]));
          if (response.statusCode == 200) {
            //debugPrint('Found favicon at: ${possibleFaviconUrls[i]}');
            // Convert to data URL
            final imageBytes = await http.get(Uri.parse(possibleFaviconUrls[i])).then((res) => res.bodyBytes);
            final base64Image = base64Encode(imageBytes);
            final contentType = response.headers['content-type'] ?? 'image/x-icon';
            return 'data:$contentType;base64,$base64Image';
          }
        } catch (e) {
          // Continue trying other URLs
          continue;
        }
      }
      
      // Try HTML parsing as last resort - fetch the page and look for favicon link tags
      try {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final html = response.body;
          
          // Match apple-touch-icon links first (higher quality)
          final appleIconRegex = RegExp('<link[^>]*rel=["\']apple-touch-icon["\'][^>]*href=["\'](.*?)["\'][^>]*>');
          final appleIconMatches = appleIconRegex.allMatches(html);
          
          // Match shortcut icon and regular icon links
          final iconRegex = RegExp('<link[^>]*rel=["\'](icon|shortcut icon)["\'][^>]*href=["\'](.*?)["\'][^>]*>');
          final iconMatches = iconRegex.allMatches(html);
          
          // Process matches from more specific to less specific
          final allMatches = [...appleIconMatches, ...iconMatches];
          for (final match in allMatches) {
            String? iconPath;
            
            if (match.groupCount >= 2 && match.group(2) != null) {
              iconPath = match.group(2)!;
            } else if (match.groupCount >= 1 && match.group(1) != null) {
              iconPath = match.group(1)!;
            }
            
            // Skip empty paths
            if (iconPath == null || iconPath.isEmpty) continue;
            
            var fullUrl = iconPath;
            
            // Handle relative URLs
            if (iconPath.startsWith('//')) {
              fullUrl = '${uri.scheme}:$iconPath';
            } else if (iconPath.startsWith('/')) {
              fullUrl = '$baseUrl$iconPath';
            } else if (!iconPath.startsWith('http')) {
              fullUrl = '$baseUrl/$iconPath';
            }
            
            try {
              //debugPrint('Found favicon in HTML: $fullUrl');
              final iconResponse = await http.get(Uri.parse(fullUrl));
              if (iconResponse.statusCode == 200) {
                final imageBytes = iconResponse.bodyBytes;
                final base64Image = base64Encode(imageBytes);
                final contentType = iconResponse.headers['content-type'] ?? 'image/x-icon';
                return 'data:$contentType;base64,$base64Image';
              }
            } catch (e) {
              //debugPrint('Error fetching favicon from HTML link: $e');
              continue;
            }
          }
        }
      } catch (e) {
        //debugPrint('Error parsing HTML for favicon: $e');
      }
      
      // As a final fallback, if everything else failed, use the domain name itself
      return uri.host;
    } catch (e) {
      //debugPrint('Error fetching favicon: $e');
      try {
        final uri = Uri.parse(url);
        // Return domain as last resort fallback
        return uri.host;
      } catch (_) {
        return null;
      }
    }
  }
  
  // Get a better favicon format (preferring PNG over ICO)
  static Future<String?> _getBetterFavicon(String url) async {
    try {
      final uri = Uri.parse(url);
      final domain = uri.host;
      
      // For ICO files, prioritize Google's favicon service which gives good quality icons as PNG
      try {
        final googleFaviconUrl = 'https://www.google.com/s2/favicons?domain=$domain&sz=128';
        //debugPrint('Trying Google favicon service: $googleFaviconUrl');
        
        final response = await http.get(Uri.parse(googleFaviconUrl));
        if (response.statusCode == 200) {
          final contentType = response.headers['content-type'] ?? 'image/png';
          //debugPrint('Got icon from Google favicon service: $contentType, size: ${response.bodyBytes.length} bytes');
          
          // Explicitly set as PNG regardless of what Google returns (usually is PNG but making sure)
          final base64Image = base64Encode(response.bodyBytes);
          return 'data:image/png;base64,$base64Image';
        }
      } catch (e) {
        //debugPrint('Error from Google favicon service: $e');
      }
      
      // Try to get other favicon formats with explicit requests to specific paths
      final baseUrl = '${uri.scheme}://${uri.host}';
      final alternativeFavicons = [
        // Highest quality first
        {
          'url': '$baseUrl/apple-touch-icon.png',
          'type': 'image/png'
        },
        {
          'url': '$baseUrl/apple-touch-icon-precomposed.png',
          'type': 'image/png'
        },
        {
          'url': '$baseUrl/apple-touch-icon-192x192.png',
          'type': 'image/png'
        },
        {
          'url': '$baseUrl/apple-touch-icon-180x180.png',
          'type': 'image/png'
        },
        {
          'url': '$baseUrl/apple-touch-icon-152x152.png',
          'type': 'image/png'
        },
        {
          'url': '$baseUrl/apple-touch-icon-144x144.png',
          'type': 'image/png'
        },
        {
          'url': '$baseUrl/favicon-196x196.png',
          'type': 'image/png'
        },
        {
          'url': '$baseUrl/favicon-192x192.png',
          'type': 'image/png'
        },
        {
          'url': '$baseUrl/favicon-128x128.png',
          'type': 'image/png'
        },
        {
          'url': '$baseUrl/favicon-96x96.png',
          'type': 'image/png'
        },
        {
          'url': '$baseUrl/favicon-64x64.png',
          'type': 'image/png'
        },
        {
          'url': '$baseUrl/favicon-48x48.png',
          'type': 'image/png'
        },
        {
          'url': '$baseUrl/favicon-32x32.png',
          'type': 'image/png'
        },
        {
          'url': '$baseUrl/favicon.png',
          'type': 'image/png'
        }
      ];
      
      for (final favicon in alternativeFavicons) {
        try {
          final response = await http.head(Uri.parse(favicon['url'] as String));
          if (response.statusCode == 200) {
            //debugPrint('Found alternative favicon at: ${favicon['url']}');
            final imageBytes = await http.get(Uri.parse(favicon['url'] as String))
                .then((res) => res.bodyBytes);
            final base64Image = base64Encode(imageBytes);
            final contentType = favicon['type'] as String;
            return 'data:$contentType;base64,$base64Image';
          }
        } catch (e) {
          continue; // Try next URL
        }
      }
      
      // If we have a direct ICO file URL that we couldn't convert or find alternatives for,
      // return the domain as a fallback - the Kotlin side will use this to fetch from Google
      if (url.endsWith('.ico') || url.contains('favicon.ico')) {
        //debugPrint('No PNG alternatives found, returning domain as fallback: $domain');
        return domain;
      }
      
      // Try one more time to convert the original ICO directly - might work for some ICO files
      try {
        //debugPrint('Trying to convert original ICO directly as last resort');
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          // Force content type to image/png
          return 'data:image/png;base64,${base64Encode(response.bodyBytes)}';
        }
      } catch (e) {
        //debugPrint('Failed to convert original ICO directly: $e');
      }
      
      // If all else fails, return domain as fallback
      return domain;
    } catch (e) {
      //debugPrint('Error getting better favicon: $e');
      return null;
    }
  }
  
  // Get all saved PWAs
  static Future<List<Map<String, dynamic>>> getAllPWAs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> pwaJsonList = prefs.getStringList(_pwaShortcutsKey) ?? [];
      
      final List<Map<String, dynamic>> pwaList = pwaJsonList
          .map((json) => jsonDecode(json) as Map<String, dynamic>)
          .toList();
      
      // Sort by timestamp (newest first)
      pwaList.sort((a, b) {
        final aTime = DateTime.parse(a['timestamp'] as String);
        final bTime = DateTime.parse(b['timestamp'] as String);
        return bTime.compareTo(aTime);
      });
      
      return pwaList;
    } catch (e) {
      //debugPrint('Failed to get PWAs: $e');
      return [];
    }
  }
  
  // Delete a PWA by URL
  static Future<bool> deletePWA(String url) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get existing PWAs
      final List<String> pwaJsonList = prefs.getStringList(_pwaShortcutsKey) ?? [];
      final List<Map<String, dynamic>> pwaList = pwaJsonList
          .map((json) => jsonDecode(json) as Map<String, dynamic>)
          .toList();
      
      // Filter out the PWA with the given URL
      final updatedPwaList = pwaList.where((pwa) => pwa['url'] != url).toList();
      
      // Save back to preferences
      final updatedJsonList = updatedPwaList.map((pwa) => jsonEncode(pwa)).toList();
      await prefs.setStringList(_pwaShortcutsKey, updatedJsonList);
      
      // Remove the shortcut from the home screen
      try {
        await platform.invokeMethod('deleteShortcut', {
          'url': url,
        });
        //debugPrint('Shortcut removed from home screen for URL: $url');
      } catch (e) {
        //debugPrint('Error removing shortcut from home screen: $e');
        // Continue even if removing from home screen fails
      }
      
      return true;
    } catch (e) {
      //debugPrint('Failed to delete PWA: $e');
      return false;
    }
  }
  
  // Check if a URL is already saved as PWA
  static Future<bool> isPWA(String url) async {
    try {
      final pwaList = await getAllPWAs();
      return pwaList.any((pwa) => pwa['url'] == url);
    } catch (e) {
      //debugPrint('Failed to check if URL is PWA: $e');
      return false;
    }
  }
  
  // Create a shortcut on the home screen using platform-specific implementation
  static Future<void> _createShortcut(String url, String title, String? favicon) async {
    try {
      String finalFavicon = '';
      
      // Ensure we have a valid favicon format (data URL or URL)
      if (favicon != null && favicon.isNotEmpty) {
        if (favicon.startsWith('data:')) {
          // Data URL is already in the correct format
          finalFavicon = favicon;
        } else if (favicon.startsWith('http')) {
          // HTTP URL - try to download and convert to data URL
          try {
            final response = await http.get(Uri.parse(favicon));
            if (response.statusCode == 200) {
              final contentType = response.headers['content-type'] ?? 'image/png';
              finalFavicon = 'data:$contentType;base64,${base64Encode(response.bodyBytes)}';
            } else {
              // Fallback to Google favicon service
              final uri = Uri.parse(url);
              final domain = uri.host;
              final googleResponse = await http.get(Uri.parse('https://www.google.com/s2/favicons?domain=$domain&sz=128'));
              if (googleResponse.statusCode == 200) {
                finalFavicon = 'data:image/png;base64,${base64Encode(googleResponse.bodyBytes)}';
              }
            }
          } catch (e) {
            //debugPrint('Error converting URL to data URL: $e');
            // Fallback to Google favicon service
            try {
              final uri = Uri.parse(url);
              final domain = uri.host;
              final googleResponse = await http.get(Uri.parse('https://www.google.com/s2/favicons?domain=$domain&sz=128'));
              if (googleResponse.statusCode == 200) {
                finalFavicon = 'data:image/png;base64,${base64Encode(googleResponse.bodyBytes)}';
              }
            } catch (e) {
              //debugPrint('Error in favicon fallback: $e');
            }
          }
        } else {
          // Just a domain or text - use Google favicon service
          try {
            final domain = favicon;
            final googleResponse = await http.get(Uri.parse('https://www.google.com/s2/favicons?domain=$domain&sz=128'));
            if (googleResponse.statusCode == 200) {
              finalFavicon = 'data:image/png;base64,${base64Encode(googleResponse.bodyBytes)}';
            }
          } catch (e) {
            //debugPrint('Error fetching Google favicon from domain: $e');
            // Try one more time with the page URL
            try {
              final uri = Uri.parse(url);
              final domain = uri.host;
              final googleResponse = await http.get(Uri.parse('https://www.google.com/s2/favicons?domain=$domain&sz=128'));
              if (googleResponse.statusCode == 200) {
                finalFavicon = 'data:image/png;base64,${base64Encode(googleResponse.bodyBytes)}';
              }
            } catch (e) {
              //debugPrint('Final error in favicon fallback: $e');
            }
          }
        }
      } else {
        // No favicon provided - use Google favicon service for the page URL
        try {
          final uri = Uri.parse(url);
          final domain = uri.host;
          final googleResponse = await http.get(Uri.parse('https://www.google.com/s2/favicons?domain=$domain&sz=128'));
          if (googleResponse.statusCode == 200) {
            finalFavicon = 'data:image/png;base64,${base64Encode(googleResponse.bodyBytes)}';
          }
        } catch (e) {
          //debugPrint('Error fetching Google favicon: $e');
        }
      }
      
      //debugPrint('Creating shortcut with favicon type: ${finalFavicon.startsWith('data:') ? 'data URL' : (finalFavicon.isEmpty ? 'empty' : 'other')}');
      
      await platform.invokeMethod('createShortcut', {
        'url': url,
        'title': title,
        'favicon': finalFavicon,
      });
    } catch (e) {
      //debugPrint('Error creating shortcut: $e');
    }
  }
  
  // Rename a PWA by URL
  static Future<bool> renamePWA(String url, String newTitle) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get existing PWAs
      final List<String> pwaJsonList = prefs.getStringList(_pwaShortcutsKey) ?? [];
      final List<Map<String, dynamic>> pwaList = pwaJsonList
          .map((json) => jsonDecode(json) as Map<String, dynamic>)
          .toList();
      
      // Find the PWA with the given URL
      final pwaIndex = pwaList.indexWhere((pwa) => pwa['url'] == url);
      if (pwaIndex != -1) {
        final Map<String, dynamic> pwa = Map<String, dynamic>.from(pwaList[pwaIndex]);
        
        // Store the original favicon to reuse it
        final String? originalFavicon = pwa['favicon'] as String?;
        
        // Ensure we have a valid favicon
        String finalFavicon = '';
        if (originalFavicon != null && originalFavicon.isNotEmpty) {
          if (originalFavicon.startsWith('data:')) {
            finalFavicon = originalFavicon;
          } else {
            // Always re-fetch favicon to ensure it's valid
            try {
              final uri = Uri.parse(url);
              final domain = uri.host;
              final googleResponse = await http.get(Uri.parse('https://www.google.com/s2/favicons?domain=$domain&sz=128'));
              if (googleResponse.statusCode == 200) {
                finalFavicon = 'data:image/png;base64,${base64Encode(googleResponse.bodyBytes)}';
              }
            } catch (e) {
              //debugPrint('Error fetching favicon during rename: $e');
              // Use original if fetch fails
              finalFavicon = originalFavicon;
            }
          }
        }
        
        // Create a uniquely modified URL by adding a timestamp suffix
        // This helps Android distinguish the new shortcut from the old one
        final String modifiedUrl = '$url#ts=${DateTime.now().millisecondsSinceEpoch}';
        
        // First create the new shortcut with the modified URL
        try {
          await platform.invokeMethod('createShortcut', {
            'url': modifiedUrl,
            'title': newTitle,
            'favicon': finalFavicon.isEmpty ? (originalFavicon ?? '') : finalFavicon,
          });
          //debugPrint('Created new shortcut with modified URL: $modifiedUrl');
          
          // Wait for the shortcut creation to complete
          await Future.delayed(const Duration(milliseconds: 500));
          
          // Then delete the old shortcut
          try {
            await platform.invokeMethod('deleteShortcut', {
              'url': url,
            });
            //debugPrint('Removed old shortcut during rename process');
          } catch (e) {
            //debugPrint('Error removing old shortcut: $e');
            // Continue even if deletion fails
          }
          
          // Update the stored PWA data
          // Use the original URL for the storage, but keep track of the modified URL for redirects
          pwa['title'] = newTitle;
          pwa['favicon'] = finalFavicon.isEmpty ? (originalFavicon ?? '') : finalFavicon;
          pwa['timestamp'] = DateTime.now().toIso8601String();
          pwa['redirect_url'] = modifiedUrl; // Store the modified URL for redirect purposes
          
          pwaList[pwaIndex] = pwa;
          
          // Save back to preferences
          final updatedJsonList = pwaList.map((pwa) => jsonEncode(pwa)).toList();
          await prefs.setStringList(_pwaShortcutsKey, updatedJsonList);
          
          return true;
        } catch (e) {
          //debugPrint('Error creating new shortcut: $e');
          
          // Try one more time without URL modification as a fallback
          try {
            // Update stored data first
            pwa['title'] = newTitle;
            pwa['timestamp'] = DateTime.now().toIso8601String();
            
            // Save the updated data
            pwaList[pwaIndex] = pwa;
            final updatedJsonList = pwaList.map((pwa) => jsonEncode(pwa)).toList();
            await prefs.setStringList(_pwaShortcutsKey, updatedJsonList);
            
            // Try creating the shortcut directly
            await platform.invokeMethod('createShortcut', {
              'url': url,
              'title': newTitle,
              'favicon': finalFavicon.isEmpty ? (originalFavicon ?? '') : finalFavicon,
            });
            
            return true;
          } catch (e) {
            //debugPrint('Final error in rename process: $e');
            return false;
          }
        }
      }
      
      return false;
    } catch (e) {
      //debugPrint('Failed to rename PWA: $e');
      return false;
    }
  }
  
  // Offline mode utilities
  
  // Check if device is offline
  static Future<bool> isOffline() async {
    try {
      final result = await http.get(Uri.parse('https://www.google.com')).timeout(
        const Duration(seconds: 3),
      );
      return result.statusCode != 200;
    } catch (e) {
      return true; // Assume offline if request fails
    }
  }
  
  // Get offline PWA content if available
  static Future<String?> getOfflinePWAContent(String url) async {
    try {
      final isDeviceOffline = await isOffline();
      if (isDeviceOffline) {
        final cachedContent = await PWAOfflineCache.getCachedHTML(url);
        if (cachedContent != null) {
          //debugPrint('Loading PWA from offline cache');
          return _injectOfflineIndicator(cachedContent);
        }
      }
      return null;
    } catch (e) {
      //debugPrint('Error getting offline PWA content: $e');
      return null;
    }
  }
  
  // Inject offline indicator into cached HTML
  static String _injectOfflineIndicator(String html) {
    const offlineIndicator = '''
      <div id="offline-indicator" style="
        position: fixed;
        top: 0;
        left: 0;
        right: 0;
        background: #ff9800;
        color: white;
        text-align: center;
        padding: 8px;
        font-size: 14px;
        z-index: 9999;
        box-shadow: 0 2px 4px rgba(0,0,0,0.2);
      ">
        📡 Offline Mode - Viewing cached content
      </div>
      <script>
        // Add top margin to body to account for offline indicator
        document.addEventListener('DOMContentLoaded', function() {
          document.body.style.marginTop = '40px';
        });
      </script>
    ''';
    
    // Try to inject before closing head tag, otherwise before closing body tag
    if (html.contains('</head>')) {
      return html.replaceFirst('</head>', '$offlineIndicator</head>');
    } else if (html.contains('</body>')) {
      return html.replaceFirst('</body>', '$offlineIndicator</body>');
    } else {
      return offlineIndicator + html;
    }
  }
  
  // Clear offline cache for specific PWA
  static Future<void> clearPWAOfflineCache(String url) async {
    await PWAOfflineCache.clearPWACache(url);
  }
  
  // Get cache information
  static Future<Map<String, dynamic>> getCacheInfo() async {
    final cacheSize = await PWAOfflineCache.getCacheSize();
    final cachedPWAs = await PWAOfflineCache.getCachedPWAs();
    
    return {
      'totalSize': cacheSize,
      'formattedSize': _formatFileSize(cacheSize),
      'cachedPWAsCount': cachedPWAs.length,
      'cachedPWAs': cachedPWAs,
    };
  }
  
  // Format file size for display
  static String _formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = (bytes.bitLength - 1) ~/ 10;
    if (i >= suffixes.length) i = suffixes.length - 1;
    return '${(bytes / (1 << (i * 10))).toStringAsFixed(1)} ${suffixes[i]}';
  }
  
  // Cleanup old caches
  static Future<void> performCacheCleanup() async {
    await PWAOfflineCache.cleanupOldCaches();
  }
}