import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/customer.dart';
import '../models/cart.dart';

class StorageService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Ensure prefs is initialized
  static SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception('StorageService not initialized. Call init() first.');
    }
    return _prefs!;
  }

  // Generic storage methods
  static Future<void> setString(String key, String value) async {
    await prefs.setString(key, value);
  }

  static String? getString(String key) {
    return prefs.getString(key);
  }

  static Future<void> setInt(String key, int value) async {
    await prefs.setInt(key, value);
  }

  static int? getInt(String key) {
    return prefs.getInt(key);
  }

  static Future<void> setBool(String key, bool value) async {
    await prefs.setBool(key, value);
  }

  static bool? getBool(String key) {
    return prefs.getBool(key);
  }

  static Future<void> setDouble(String key, double value) async {
    await prefs.setDouble(key, value);
  }

  static double? getDouble(String key) {
    return prefs.getDouble(key);
  }

  static Future<void> setStringList(String key, List<String> value) async {
    await prefs.setStringList(key, value);
  }

  static List<String>? getStringList(String key) {
    return prefs.getStringList(key);
  }

  static Future<void> remove(String key) async {
    await prefs.remove(key);
  }

  static Future<void> clear() async {
    await prefs.clear();
  }

  static Future<void> clearAll() async {
    await clear();
  }

  // Authentication storage
  static Future<void> saveAuthToken(String token) async {
    await setString(AppConfig.authTokenKey, token);
  }

  static String? getAuthToken() {
    return getString(AppConfig.authTokenKey);
  }

  static Future<void> removeAuthToken() async {
    await remove(AppConfig.authTokenKey);
  }

  static bool hasAuthToken() {
    return getAuthToken() != null;
  }

  // User data storage
  static Future<void> saveUserData(Customer customer) async {
    final json = jsonEncode(customer.toJson());
    await setString(AppConfig.userDataKey, json);
  }

  static Customer? getUserData() {
    final json = getString(AppConfig.userDataKey);
    if (json == null) return null;

    try {
      final Map<String, dynamic> data = jsonDecode(json);
      return Customer.fromJson(data);
    } catch (e) {
      // If parsing fails, remove corrupted data
      remove(AppConfig.userDataKey);
      return null;
    }
  }

  static Future<void> removeUserData() async {
    await remove(AppConfig.userDataKey);
  }

  static bool hasUserData() {
    return getUserData() != null;
  }

  // Cart storage
  static Future<void> saveCartData(Cart cart) async {
    final json = jsonEncode(cart.toJson());
    await setString(AppConfig.cartKey, json);
  }

  static Cart? getCartData() {
    final json = getString(AppConfig.cartKey);
    if (json == null) return null;

    try {
      final Map<String, dynamic> data = jsonDecode(json);
      return Cart.fromJson(data);
    } catch (e) {
      // If parsing fails, remove corrupted data
      remove(AppConfig.cartKey);
      return null;
    }
  }

  static Future<void> removeCartData() async {
    await remove(AppConfig.cartKey);
  }

  static bool hasCartData() {
    return getCartData() != null;
  }

  // Favorites storage
  static Future<void> saveFavorites(List<int> productIds) async {
    await setStringList(AppConfig.favoritesKey, productIds.map((id) => id.toString()).toList());
  }

  static List<int> getFavorites() {
    final strings = getStringList(AppConfig.favoritesKey);
    if (strings == null) return [];

    try {
      return strings.map((s) => int.parse(s)).toList();
    } catch (e) {
      // If parsing fails, remove corrupted data
      remove(AppConfig.favoritesKey);
      return [];
    }
  }

  static Future<void> addToFavorites(int productId) async {
    final favorites = getFavorites();
    if (!favorites.contains(productId)) {
      favorites.add(productId);
      await saveFavorites(favorites);
    }
  }

  static Future<void> removeFromFavorites(int productId) async {
    final favorites = getFavorites();
    favorites.remove(productId);
    await saveFavorites(favorites);
  }

  static bool isFavorite(int productId) {
    return getFavorites().contains(productId);
  }

  // Search history storage
  static const String _searchHistoryKey = 'search_history';

  static Future<void> saveSearchHistory(List<String> queries) async {
    // Keep only last 10 searches
    if (queries.length > 10) {
      queries = queries.take(10).toList();
    }
    await setStringList(_searchHistoryKey, queries);
  }

  static List<String> getSearchHistory() {
    return getStringList(_searchHistoryKey) ?? [];
  }

  static Future<void> addToSearchHistory(String query) async {
    if (query.trim().isEmpty) return;

    final history = getSearchHistory();
    history.remove(query); // Remove if already exists
    history.insert(0, query); // Add to beginning
    await saveSearchHistory(history);
  }

  static Future<void> clearSearchHistory() async {
    await remove(_searchHistoryKey);
  }

  // App settings storage
  static const String _languageKey = 'app_language';
  static const String _themeKey = 'app_theme';
  static const String _notificationsKey = 'notifications_enabled';

  static Future<void> setLanguage(String languageCode) async {
    await setString(_languageKey, languageCode);
  }

  static String? getLanguage() {
    return getString(_languageKey);
  }

  static Future<void> setTheme(String theme) async {
    await setString(_themeKey, theme);
  }

  static String? getTheme() {
    return getString(_themeKey);
  }

  static Future<void> setNotificationsEnabled(bool enabled) async {
    await setBool(_notificationsKey, enabled);
  }

  static bool getNotificationsEnabled() {
    return getBool(_notificationsKey) ?? true;
  }

  // Cache management
  static Future<void> cacheData(String key, String data, {Duration? expiration}) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final expirationTimestamp = expiration != null
        ? timestamp + expiration.inMilliseconds
        : null;

    final cacheItem = {
      'data': data,
      'timestamp': timestamp,
      'expiration': expirationTimestamp,
    };

    await setString('cache_$key', jsonEncode(cacheItem));
  }

  static String? getCachedData(String key) {
    final json = getString('cache_$key');
    if (json == null) return null;

    try {
      final Map<String, dynamic> cacheItem = jsonDecode(json);
      final expiration = cacheItem['expiration'] as int?;

      if (expiration != null) {
        final now = DateTime.now().millisecondsSinceEpoch;
        if (now > expiration) {
          // Cache expired
          remove('cache_$key');
          return null;
        }
      }

      return cacheItem['data'] as String?;
    } catch (e) {
      remove('cache_$key');
      return null;
    }
  }

  static Future<void> clearCache() async {
    final keys = prefs.getKeys().where((key) => key.startsWith('cache_')).toList();
    for (final key in keys) {
      await remove(key);
    }
  }

  // Storage info
  static Future<void> printStorageInfo() async {
    final keys = prefs.getKeys();
    print('Storage keys: ${keys.length}');
    for (final key in keys) {
      final value = prefs.get(key);
      print('$key: $value');
    }
  }
}