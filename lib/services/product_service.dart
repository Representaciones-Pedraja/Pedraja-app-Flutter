import '../models/product.dart';
import '../models/combination.dart';
import '../models/feature.dart';
import '../config/api_config.dart';
import 'api_service.dart';
import 'combination_service.dart';
import 'feature_service.dart';

class ProductService {
  final ApiService _apiService;
  late final CombinationService _combinationService;
  late final FeatureService _featureService;

  ProductService(this._apiService) {
    _combinationService = CombinationService(_apiService);
    _featureService = FeatureService(_apiService);
  }

  /// Get products with pagination support for infinite scroll
  /// Optimized: No enrichment, fast loading for lists
  Future<List<Product>> getProducts({
    int? limit,
    int? offset,
    String? categoryId,
    String? searchQuery,
    String? manufacturerId,
    double? minPrice,
    double? maxPrice,
    String? sortBy, // id_DESC, price_ASC, price_DESC, name_ASC, name_DESC
  }) async {
    try {
      final queryParams = <String, String>{
        'display': 'full',
        if (limit != null) 'limit': '${offset ?? 0},$limit',
        if (categoryId != null) 'filter[id_category_default]': categoryId,
        if (searchQuery != null) 'filter[name]': '%$searchQuery%',
        if (manufacturerId != null) 'filter[id_manufacturer]': manufacturerId,
        if (minPrice != null) 'filter[price]': '[$minPrice,${maxPrice ?? 999999}]',
        'filter[visibility]': 'both', // Show all visible products
        'filter[active]': '1', // Only active products
        if (sortBy != null) 'sort': '[$sortBy]',
      };

      final response = await _apiService.get(
        ApiConfig.productsEndpoint,
        queryParameters: queryParams,
      );

      // Handle different response formats from PrestaShop API
      List<Product> products = [];

      // Case 1: Empty array response []
      if (response is List) {
        if (response.isEmpty) {
          return []; // No products found
        }
        // Case 2: Direct array of products (without wrapper)
        products = response
            .map((productJson) => Product.fromJson(productJson))
            .toList();
      }
      // Case 3: Response is a Map with 'products' key
      else if (response is Map && response['products'] != null) {
        final productsData = response['products'];
        if (productsData is List) {
          products = productsData
              .map((productJson) => Product.fromJson(productJson))
              .toList();
        } else if (productsData is Map) {
          // Single product wrapped in products key
          products = [Product.fromJson(productsData as Map<String, dynamic>)];
        }
      }
      // Case 4: Empty result
      else {
        return [];
      }

      // Return products without enrichment for fast loading
      return products;
    } catch (e) {
      throw Exception('Failed to fetch products: $e');
    }
  }

  /// Get single product with full details (combinations, features, etc.)
  /// This is the ONLY method that enriches product data for detail pages
  Future<Product> getProductById(String id) async {
    try {
      print('🔍 Fetching product ID: $id');
      final response = await _apiService.get(
        '${ApiConfig.productsEndpoint}/$id',
      );

      print('📦 Raw response type: ${response.runtimeType}');
      print('📦 Raw response: $response');

      // Handle different response structures from PrestaShop
      Map<String, dynamic>? productData;

      if (response is Map) {
        print('✅ Response is Map');
        print('🔑 Keys: ${response.keys.toList()}');

        if (response['product'] != null) {
          print('✅ Found product key');
          productData = response['product'] as Map<String, dynamic>;
        } else if (response['products'] != null) {
          print('✅ Found products key');
          // Sometimes API returns 'products' wrapper for single product
          final products = response['products'];
          if (products is Map && products['product'] != null) {
            productData = products['product'] as Map<String, dynamic>;
          } else if (products is Map) {
            productData = products as Map<String, dynamic>;
          }
        } else {
          print('⚠️ Using response as product directly');
          // Response might be the product itself
          productData = response as Map<String, dynamic>;
        }
      }

      if (productData == null) {
        print('❌ Product data is null!');
        throw Exception('Product not found');
      }

      print('📋 Product data keys: ${productData.keys.toList()}');
      print('📋 Product name field: ${productData['name']}');
      print('📋 Product price field: ${productData['price']}');

      Product product = Product.fromJson(productData);

      print('✅ Parsed product: ${product.name} - ${product.price} EUR');

      // Return product without enrichment - faster loading
      // Product details from PrestaShop API already include all necessary info
      return product;
    } catch (e) {
      print('❌ Error fetching product: $e');
      throw Exception('Failed to fetch product: $e');
    }
  }

  /// Get product combinations (variants)
  Future<List<Combination>> getProductCombinations(String productId) async {
    return await _combinationService.getCombinationsByProduct(productId);
  }

  /// Get product features
  Future<List<ProductFeature>> getProductFeatures(String productId) async {
    return await _featureService.getProductFeatures(productId);
  }

  /// Get related products (same category, different product)
  Future<List<Product>> getRelatedProducts(
    String productId,
    String categoryId, {
    int limit = 10,
  }) async {
    try {
      final products = await getProducts(
        categoryId: categoryId,
        limit: limit + 5, // Fetch extra in case current product is included
      );

      // Filter out current product
      final relatedProducts = products.where((p) => p.id != productId).toList();

      // Return only requested limit
      return relatedProducts.take(limit).toList();
    } catch (e) {
      throw Exception('Failed to fetch related products: $e');
    }
  }

  /// Search products with pagination
  Future<List<Product>> searchProducts(
    String query, {
    int? limit,
    int? offset,
  }) async {
    return getProducts(
      searchQuery: query,
      limit: limit,
      offset: offset,
    );
  }

  /// Get products by category with pagination
  Future<List<Product>> getProductsByCategory(
    String categoryId, {
    int? limit,
    int? offset,
    String? sortBy,
  }) async {
    return getProducts(
      categoryId: categoryId,
      limit: limit,
      offset: offset,
      sortBy: sortBy,
    );
  }

  /// Get featured products (first X products or by specific logic)
  Future<List<Product>> getFeaturedProducts({
    int limit = 10,
  }) async {
    return getProducts(
      limit: limit,
      sortBy: 'id_DESC',
    );
  }

  /// Get latest products
  Future<List<Product>> getLatestProducts({
    int limit = 10,
  }) async {
    return getProducts(
      limit: limit,
      sortBy: 'id_DESC',
    );
  }

  /// Get products on sale
  /// Note: Without specific_prices enrichment, this returns products with reduced prices set in PrestaShop
  Future<List<Product>> getProductsOnSale({
    int? limit,
    int? offset,
  }) async {
    // Return regular products - PrestaShop's 'on sale' flag will be used
    // Sale products should have their reduced price set in the product itself
    return getProducts(
      limit: limit,
      offset: offset,
      sortBy: 'price_DESC', // Show higher priced items first (potential discounts)
    );
  }

  /// Get products by manufacturer
  Future<List<Product>> getProductsByManufacturer(
    String manufacturerId, {
    int? limit,
    int? offset,
  }) async {
    return getProducts(
      manufacturerId: manufacturerId,
      limit: limit,
      offset: offset,
    );
  }

  /// Get products by price range
  Future<List<Product>> getProductsByPriceRange(
    double minPrice,
    double maxPrice, {
    String? categoryId,
    int? limit,
    int? offset,
  }) async {
    return getProducts(
      minPrice: minPrice,
      maxPrice: maxPrice,
      categoryId: categoryId,
      limit: limit,
      offset: offset,
    );
  }

  /// Get best selling products
  /// Note: PrestaShop tracks sales in orders, this is a simplified version
  /// In production, you'd query order_detail and aggregate by product_id
  Future<List<Product>> getBestSellingProducts({
    int limit = 10,
  }) async {
    return getProducts(
      limit: limit,
      sortBy: 'position_ASC', // Products with better position are often best sellers
    );
  }

  /// Get products with price drops (on sale with significant discount)
  /// Note: Returns products sorted by price, as discount calculations are removed for performance
  Future<List<Product>> getPricesDropProducts({
    int limit = 10,
    double minimumDiscount = 10.0, // Minimum discount percentage (not used)
  }) async {
    // Return products sorted by price descending
    // Products with 'on_sale' flag in PrestaShop will be included
    return getProducts(
      limit: limit,
      sortBy: 'price_DESC',
    );
  }
}
