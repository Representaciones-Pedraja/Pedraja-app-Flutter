import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../services/prestashops_api.dart';
import '../services/storage_service.dart';

enum ProductStatus {
  initial,
  loading,
  loaded,
  loadingMore,
  error,
  endOfResults,
}

enum SearchStatus {
  initial,
  searching,
  loaded,
  loadingMore,
  error,
  noResults,
}

class ProductProvider extends ChangeNotifier {
  final PrestaShopAPI _api = prestashopAPI;

  ProductStatus _status = ProductStatus.initial;
  SearchStatus _searchStatus = SearchStatus.initial;
  List<Product> _products = [];
  List<Product> _featuredProducts = [];
  List<Product> _searchResults = [];
  List<Category> _categories = [];
  Category? _selectedCategory;
  Product? _selectedProduct;
  List<Product> _favoriteProducts = [];
  String? _errorMessage;
  String? _searchErrorMessage;

  // Pagination
  int _currentPage = 1;
  int _searchPage = 1;
  bool _hasMoreProducts = true;
  bool _hasMoreSearchResults = true;

  // Sorting and filtering
  String _sortBy = 'name';
  String _sortOrder = 'ASC';
  Map<String, dynamic> _filters = {};
  double _minPrice = 0.0;
  double _maxPrice = 1000.0;

  // Getters
  ProductStatus get status => _status;
  SearchStatus get searchStatus => _searchStatus;
  List<Product> get products => _products;
  List<Product> get featuredProducts => _featuredProducts;
  List<Product> get searchResults => _searchResults;
  List<Category> get categories => _categories;
  Category? get selectedCategory => _selectedCategory;
  Product? get selectedProduct => _selectedProduct;
  List<Product> get favoriteProducts => _favoriteProducts;
  String? get errorMessage => _errorMessage;
  String? get searchErrorMessage => _searchErrorMessage;
  bool get isLoading => _status == ProductStatus.loading;
  bool get isLoadingMore => _status == ProductStatus.loadingMore;
  bool get isSearching => _searchStatus == SearchStatus.searching;
  bool get isLoadingMoreSearch => _searchStatus == SearchStatus.loadingMore;
  bool get hasMoreProducts => _hasMoreProducts;
  bool get hasMoreSearchResults => _hasMoreSearchResults;
  String get sortBy => _sortBy;
  String get sortOrder => _sortOrder;
  Map<String, dynamic> get filters => _filters;
  double get minPrice => _minPrice;
  double get maxPrice => _maxPrice;

  // Initialize product provider
  Future<void> init() async {
    await Future.wait([
      loadCategories(),
      loadFeaturedProducts(),
      loadFavoriteProducts(),
    ]);
  }

  // Load categories
  Future<void> loadCategories({int? parentId}) async {
    try {
      _categories = await _api.getCategories(parentId: parentId);
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load categories: $e');
    }
  }

  // Load featured products
  Future<void> loadFeaturedProducts() async {
    try {
      final products = await _api.getProducts(
        limit: 10,
        sortBy: 'date_add',
        sortOrder: 'DESC',
      );
      _featuredProducts = products;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load featured products: $e');
    }
  }

  // Load products
  Future<void> loadProducts({
    int? categoryId,
    bool refresh = false,
  }) async {
    if (refresh) {
      _currentPage = 1;
      _hasMoreProducts = true;
      _products.clear();
      _setStatus(ProductStatus.loading);
    } else {
      _setStatus(ProductStatus.loadingMore);
    }

    _clearError();

    try {
      final products = await _api.getProducts(
        categoryId: categoryId,
        page: _currentPage,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
        filters: _buildFilters(),
      );

      if (refresh) {
        _products = products;
      } else {
        _products.addAll(products);
      }

      _currentPage++;
      _hasMoreProducts = products.length >= 20; // Assuming page size of 20
      _selectedCategory = categoryId != null ? _categories.firstWhere((cat) => cat.id == categoryId) : null;

      _setStatus(ProductStatus.loaded);
    } catch (e) {
      _setError('Failed to load products: ${e.toString()}');
      _setStatus(ProductStatus.error);
    }
  }

  // Load more products
  Future<void> loadMoreProducts() async {
    if (!hasMoreProducts || isLoadingMore) return;

    await loadProducts();
  }

  // Search products
  Future<void> searchProducts(String query, {bool refresh = false}) async {
    if (query.trim().isEmpty) {
      _searchResults.clear();
      _searchStatus = SearchStatus.initial;
      notifyListeners();
      return;
    }

    if (refresh) {
      _searchPage = 1;
      _hasMoreSearchResults = true;
      _searchResults.clear();
      _setSearchStatus(SearchStatus.searching);
    } else {
      _setSearchStatus(SearchStatus.loadingMore);
    }

    _clearSearchError();

    try {
      final products = await _api.searchProducts(
        query,
        page: _searchPage,
      );

      if (refresh) {
        _searchResults = products;
      } else {
        _searchResults.addAll(products);
      }

      _searchPage++;
      _hasMoreSearchResults = products.length >= 20;

      // Add to search history
      await StorageService.addToSearchHistory(query);

      _setSearchStatus(products.isEmpty ? SearchStatus.noResults : SearchStatus.loaded);
    } catch (e) {
      _setSearchError('Search failed: ${e.toString()}');
      _setSearchStatus(SearchStatus.error);
    }
  }

  // Load more search results
  Future<void> loadMoreSearchResults(String query) async {
    if (!hasMoreSearchResults || isLoadingMoreSearch) return;

    await searchProducts(query);
  }

  // Get product by ID
  Future<Product?> getProductById(int productId) async {
    try {
      final product = await _api.getProductById(productId);
      _selectedProduct = product;
      notifyListeners();
      return product;
    } catch (e) {
      debugPrint('Failed to get product: $e');
      return null;
    }
  }

  // Set selected product
  void setSelectedProduct(Product? product) {
    _selectedProduct = product;
    notifyListeners();
  }

  // Set selected category
  void setSelectedCategory(Category? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  // Sort products
  void sortProducts(String sortBy, String sortOrder) {
    _sortBy = sortBy;
    _sortOrder = sortOrder;
    loadProducts(categoryId: _selectedCategory?.id, refresh: true);
  }

  // Filter products
  void filterProducts({
    double? minPrice,
    double? maxPrice,
    Map<String, dynamic>? filters,
  }) {
    if (minPrice != null) _minPrice = minPrice;
    if (maxPrice != null) _maxPrice = maxPrice;
    if (filters != null) _filters = filters;

    loadProducts(categoryId: _selectedCategory?.id, refresh: true);
  }

  // Clear filters
  void clearFilters() {
    _minPrice = 0.0;
    _maxPrice = 1000.0;
    _filters.clear();
    loadProducts(categoryId: _selectedCategory?.id, refresh: true);
  }

  // Toggle favorite
  Future<void> toggleFavorite(int productId) async {
    try {
      if (StorageService.isFavorite(productId)) {
        await StorageService.removeFromFavorites(productId);
        _favoriteProducts.removeWhere((product) => product.id == productId);
      } else {
        await StorageService.addToFavorites(productId);
        // Add to favorites if product exists in current products
        final product = [..._products, ..._searchResults].firstWhere(
          (p) => p.id == productId,
          orElse: () => _selectedProduct!,
        );
        if (product.id == productId) {
          _favoriteProducts.add(product);
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to toggle favorite: $e');
    }
  }

  // Load favorite products
  Future<void> loadFavoriteProducts() async {
    try {
      final favoriteIds = StorageService.getFavorites();
      if (favoriteIds.isEmpty) {
        _favoriteProducts.clear();
        notifyListeners();
        return;
      }

      // Load favorite products from API
      _favoriteProducts.clear();
      for (final id in favoriteIds) {
        try {
          final product = await _api.getProductById(id);
          if (product != null) {
            _favoriteProducts.add(product);
          }
        } catch (e) {
          debugPrint('Failed to load favorite product $id: $e');
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load favorite products: $e');
    }
  }

  // Check if product is favorite
  bool isFavorite(int productId) {
    return StorageService.isFavorite(productId);
  }

  // Get search history
  List<String> getSearchHistory() {
    return StorageService.getSearchHistory();
  }

  // Clear search history
  Future<void> clearSearchHistory() async {
    await StorageService.clearSearchHistory();
    notifyListeners();
  }

  // Refresh data
  Future<void> refresh() async {
    await Future.wait([
      loadCategories(),
      loadFeaturedProducts(refresh: true),
      loadFavoriteProducts(),
    ]);

    if (_selectedCategory != null) {
      await loadProducts(categoryId: _selectedCategory!.id, refresh: true);
    } else {
      await loadProducts(refresh: true);
    }
  }

  // Clear errors
  void clearError() {
    _clearError();
    notifyListeners();
  }

  void clearSearchError() {
    _clearSearchError();
    notifyListeners();
  }

  // Get products by category
  List<Product> getProductsByCategory(int categoryId) {
    return products.where((product) => product.categoryId == categoryId).toList();
  }

  // Get related products
  List<Product> getRelatedProducts(Product product) {
    return products
        .where((p) => p.id != product.id && p.categoryId == product.categoryId)
        .take(6)
        .toList();
  }

  // Private helper methods
  void _setStatus(ProductStatus status) {
    _status = status;
    notifyListeners();
  }

  void _setSearchStatus(SearchStatus status) {
    _searchStatus = status;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _setSearchError(String error) {
    _searchErrorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void _clearSearchError() {
    _searchErrorMessage = null;
  }

  Map<String, dynamic> _buildFilters() {
    final filters = <String, dynamic>{};

    // Add price filter
    if (_minPrice > 0 || _maxPrice < 1000) {
      filters['price'] = '[$_minPrice,$_maxPrice]';
    }

    // Add custom filters
    filters.addAll(_filters);

    return filters;
  }

  // Get product count by category
  Map<int, int> getProductCountByCategory() {
    final Map<int, int> countMap = {};
    for (final product in _products) {
      countMap[product.categoryId] = (countMap[product.categoryId] ?? 0) + 1;
    }
    return countMap;
  }

  // Get price range for current products
  double getMinPriceInRange() {
    if (_products.isEmpty) return 0.0;
    return _products.map((p) => p.effectivePrice).reduce((a, b) => a < b ? a : b);
  }

  double getMaxPriceInRange() {
    if (_products.isEmpty) return 1000.0;
    return _products.map((p) => p.effectivePrice).reduce((a, b) => a > b ? a : b);
  }

  // Reset provider
  void reset() {
    _status = ProductStatus.initial;
    _searchStatus = SearchStatus.initial;
    _products.clear();
    _featuredProducts.clear();
    _searchResults.clear();
    _categories.clear();
    _selectedCategory = null;
    _selectedProduct = null;
    _favoriteProducts.clear();
    _errorMessage = null;
    _searchErrorMessage = null;
    _currentPage = 1;
    _searchPage = 1;
    _hasMoreProducts = true;
    _hasMoreSearchResults = true;
    _sortBy = 'name';
    _sortOrder = 'ASC';
    _filters.clear();
    _minPrice = 0.0;
    _maxPrice = 1000.0;
    notifyListeners();
  }
}