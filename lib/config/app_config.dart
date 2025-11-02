import 'package:flutter/material.dart';

class AppConfig {
  static const String appName = 'PrestaShop Mobile';
  static const MaterialColor primaryColor = Colors.blue;
  static const String version = '1.0.0';

  // API Configuration
  static const String apiBaseUrl = 'https://yourstore.com/api';
  static const String apiKey = 'YOUR_API_KEY_HERE';
  static const int apiTimeout = 30000; // 30 seconds

  // Pagination
  static const int defaultPageSize = 20;
  static const int searchDebounceMs = 300;

  // Storage Keys
  static const String authTokenKey = 'auth_token';
  static const String userDataKey = 'user_data';
  static const String cartKey = 'cart_data';
  static const String favoritesKey = 'favorites';

  // Image Configuration
  static const String defaultProductImage = 'assets/images/placeholder_product.png';
  static const String defaultCategoryImage = 'assets/images/placeholder_category.png';

  // Currency
  static const String currencySymbol = '\$';
  static const String currencyCode = 'USD';

  // App Dimensions
  static const double cardBorderRadius = 12.0;
  static const double buttonBorderRadius = 8.0;
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;

  // Animation Durations
  static const int defaultAnimationDuration = 300;
  static const int fastAnimationDuration = 150;
  static const int slowAnimationDuration = 500;
}