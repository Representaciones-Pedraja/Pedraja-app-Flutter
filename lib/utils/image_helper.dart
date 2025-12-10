import 'dart:convert';
import '../config/api_config.dart';

/// Helper class for handling PrestaShop image authentication
class ImageHelper {
  /// Get authentication headers for image requests
  /// PrestaShop API requires Basic authentication for all endpoints including images
  static Map<String, String> get authHeaders {
    final apiKey = ApiConfig.apiKey;
    final credentials = base64Encode(utf8.encode('$apiKey:'));

    return {
      'Authorization': 'Basic $credentials',
    };
  }

  /// Check if an image URL is from PrestaShop API
  static bool isPrestaShopImage(String url) {
    return url.contains('/api/images/');
  }

  /// Get headers for a specific image URL
  /// Returns auth headers for PrestaShop images, empty map for other images
  static Map<String, String> getHeadersForUrl(String url) {
    if (isPrestaShopImage(url)) {
      return authHeaders;
    }
    return {};
  }
}
