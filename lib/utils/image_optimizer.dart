import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

class ImageOptimizer {
  static const int THUMBNAIL_SIZE = 64;
  static const int PREVIEW_QUALITY = 85;
  static const double MAX_VIEWPORT_SCALE = 2.0;

  // Optimize image for viewport
  static Future<Uint8List> optimizeForViewport(String imageUrl, int viewportWidth, int viewportHeight) async {
    try {
      // Download original image
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to load image');
      }

      // Decode image
      final originalImage = img.decodeImage(response.bodyBytes);
      if (originalImage == null) {
        throw Exception('Failed to decode image');
      }

      // Calculate target dimensions
      final double scale = _calculateOptimalScale(
        originalImage.width, 
        originalImage.height,
        viewportWidth,
        viewportHeight
      );

      final targetWidth = (originalImage.width * scale).round();
      final targetHeight = (originalImage.height * scale).round();

      // Resize image
      final resizedImage = img.copyResize(
        originalImage,
        width: targetWidth,
        height: targetHeight,
        interpolation: img.Interpolation.linear
      );

      // Encode with quality optimization
      return Uint8List.fromList(img.encodeJpg(
        resizedImage,
        quality: PREVIEW_QUALITY
      ));
    } catch (e) {
      //print('Error optimizing image: $e');
      rethrow;
    }
  }

  // Create thumbnail
  static Future<Uint8List> createThumbnail(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to load image');
      }

      final originalImage = img.decodeImage(response.bodyBytes);
      if (originalImage == null) {
        throw Exception('Failed to decode image');
      }

      // Create square thumbnail
      final thumbnail = img.copyResize(
        originalImage,
        width: THUMBNAIL_SIZE,
        height: THUMBNAIL_SIZE,
        interpolation: img.Interpolation.average
      );

      return Uint8List.fromList(img.encodeJpg(thumbnail, quality: 90));
    } catch (e) {
      //print('Error creating thumbnail: $e');
      rethrow;
    }
  }

  // Calculate optimal scale based on viewport
  static double _calculateOptimalScale(
    int imageWidth,
    int imageHeight,
    int viewportWidth,
    int viewportHeight
  ) {
    // Calculate scale to fit viewport
    final double widthScale = viewportWidth / imageWidth;
    final double heightScale = viewportHeight / imageHeight;
    
    // Use the smaller scale to ensure image fits viewport
    double scale = widthScale < heightScale ? widthScale : heightScale;
    
    // Apply device pixel ratio scaling up to MAX_VIEWPORT_SCALE
    final deviceScale = MAX_VIEWPORT_SCALE;
    scale = scale * deviceScale;
    
    // Don't upscale images
    if (scale > 1.0) {
      scale = 1.0;
    }
    
    return scale;
  }

  // Progressive image loading
  static Future<List<Uint8List>> loadProgressively(
    String imageUrl,
    int viewportWidth,
    int viewportHeight
  ) async {
    final List<Uint8List> results = [];
    
    // Load thumbnail first
    results.add(await createThumbnail(imageUrl));
    
    // Load optimized version
    results.add(await optimizeForViewport(
      imageUrl,
      viewportWidth,
      viewportHeight
    ));
    
    return results;
  }
} 