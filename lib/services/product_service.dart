import '../models/product.dart';
import '../config/api_config.dart';
import 'api_service.dart';

class ProductService {
  final ApiService _apiService;

  ProductService(this._apiService);

  Future<List<Product>> getProducts({
    int? limit,
    int? offset,
    String? categoryId,
    String? searchQuery,
    bool filterInStock = true, // Filter only in-stock products by default
  }) async {
    try {
      final queryParams = <String, String>{
        'display': 'full',
        if (limit != null) 'limit': '$offset,$limit',
        if (categoryId != null) 'filter[id_category_default]': categoryId,
        if (searchQuery != null) 'filter[name]': '%$searchQuery%',
        'limit': '10',
      };

      final response = await _apiService.get(
        ApiConfig.productsEndpoint,
        queryParameters: queryParams,
      );

      // Handle both single product and array of products
      List<Product> products = [];
      if (response['products'] != null) {
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

      // Filter out-of-stock products if requested
      if (filterInStock) {
        products = products.where((product) => product.inStock).toList();
      }

      return products;
    } catch (e) {
      throw Exception('Failed to fetch products: $e');
    }
  }

  Future<Product> getProductById(String id) async {
    try {
      final response = await _apiService.get(
        '${ApiConfig.productsEndpoint}/$id',
        queryParameters: {},
      );

      if (response['product'] != null) {
        return Product.fromJson(response['product']);
      }

      throw Exception('Product not found');
    } catch (e) {
      throw Exception('Failed to fetch product: $e');
    }
  }

  Future<List<Product>> searchProducts(String query, {bool filterInStock = true}) async {
    return getProducts(searchQuery: query, filterInStock: filterInStock);
  }

  Future<List<Product>> getProductsByCategory(String categoryId, {bool filterInStock = true}) async {
    return getProducts(categoryId: categoryId, filterInStock: filterInStock);
  }

  Future<List<Product>> getFeaturedProducts({bool filterInStock = true}) async {
    // Assuming featured products can be filtered by a specific attribute
    // This implementation may vary based on PrestaShop configuration
    return getProducts(limit: 10, filterInStock: filterInStock);
  }
}
