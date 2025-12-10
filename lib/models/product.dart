import '../utils/language_helper.dart';
import '../config/api_config.dart';

class Product {
  final String id;
  final String name;
  final String description;
  final String shortDescription;
  final double price;
  final double? reducedPrice;
  final String? imageUrl;
  final List<String> images;
  final int quantity;
  final String? reference;
  final bool active;
  final String categoryId;
  final String? manufacturerId;
  final String? manufacturerName;
  final String? defaultCombinationId;
  final List<ProductVariant>? variants;
  final bool onSale;
  final double? discountPercentage;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.shortDescription,
    required this.price,
    this.reducedPrice,
    this.imageUrl,
    this.images = const [],
    required this.quantity,
    this.reference,
    this.active = true,
    required this.categoryId,
    this.manufacturerId,
    this.manufacturerName,
    this.defaultCombinationId,
    this.variants,
    this.onSale = false,
    this.discountPercentage,
  });

  bool get isOnSale =>
      onSale || (reducedPrice != null && reducedPrice! < price);
  double get calculatedDiscountPercentage =>
      discountPercentage ??
      (isOnSale && reducedPrice != null
          ? ((price - reducedPrice!) / price * 100)
          : 0);
  double get finalPrice => reducedPrice ?? price;
  bool get inStock => quantity > 0;

  factory Product.fromJson(Map<String, dynamic> json) {
    try {
      final product = json['product'] ?? json;

      // Handle price - could be string or number
      double parsePrice(dynamic value) {
        if (value == null) return 0.0;
        if (value is num) return value.toDouble();
        final parsed = double.tryParse(value.toString());
        return parsed ?? 0.0;
      }

      // Handle quantity - always default to 1 for list display
      int parseQuantity(dynamic value) {
        if (value == null) return 1; // Default to 1 (in stock)
        if (value is int) return value;
        return int.tryParse(value.toString()) ?? 1;
      }

      // Get product name
      String getName() {
        if (product['name'] != null) {
          final name = LanguageHelper.extractValueOrEmpty(product['name']);
          return name.isNotEmpty ? name : 'Product';
        }
        return 'Product'; // Fallback
      }

      // Get product price (PrestaShop uses different field names)
      double getPrice() {
     
        // Try different price fields in PrestaShop
        if (product['price'] != null &&
            product['price'].toString() != '0' &&
            product['price'].toString() != '0.000000') {
          return parsePrice(product['price']);
        }
        if (product['price_tax_exc'] != null &&
            product['price_tax_exc'].toString() != '0' &&
            product['price_tax_exc'].toString() != '0.000000') {
          return parsePrice(product['price_tax_exc']);
        }
        if (product['wholesale_price'] != null &&
            product['wholesale_price'].toString() != '0' &&
            product['wholesale_price'].toString() != '0.000000') {
          return parsePrice(product['wholesale_price']);
        }
        return 0.0;
      }

    
      final description = LanguageHelper.extractValueOrEmpty(
          product['description'] ?? product['description_short']);
      final shortDescription =
          LanguageHelper.extractValueOrEmpty(product['description_short']);

   
      return Product(
        id: product['id']?.toString() ?? '',
        name: getName(),
        description: description,
        shortDescription: shortDescription,
        price: getPrice(),
        reducedPrice: product['price_final'] != null
            ? parsePrice(product['price_final'])
            : null,
        imageUrl: _constructImageUrl(
            product['id']?.toString(),
            product['id_default_image']?.toString()),
        images: _extractImageIds(product),
        quantity: parseQuantity(product['quantity']),
        reference: product['reference']?.toString(),
        active: product['active'] == '1' || product['active'] == true,
        categoryId: product['id_category_default']?.toString() ?? '0',
        manufacturerId: product['id_manufacturer']?.toString(),
        manufacturerName: product['manufacturer_name']?.toString(),
        defaultCombinationId: product['cache_default_attribute']?.toString() ??
            product['id_default_combination']?.toString(),
        variants: product['variants'] != null
            ? (product['variants'] as List)
                .map((v) => ProductVariant.fromJson(v))
                .toList()
            : null,
        onSale: product['on_sale'] == '1' || product['on_sale'] == true,
        discountPercentage: product['discount_percentage'] != null
            ? parsePrice(product['discount_percentage'])
            : null,
      );
    } catch (e) {
      print('Error parsing product: $e');
      print('Product data: $json');
      throw Exception('Failed to parse product: $e');
    }
  }

  /// Constructs the full image URL from product ID and image ID
  static String? _constructImageUrl(String? productId, String? imageId) {
    if (productId == null ||
        productId.isEmpty ||
        imageId == null ||
        imageId.isEmpty ||
        imageId == '0') {
      print('🖼️ No image URL - productId: $productId, imageId: $imageId');
      return null;
    }
    final imageUrl = '${ApiConfig.baseUrl}api/images/products/$productId/$imageId';
    print('🖼️ Product image URL constructed: $imageUrl');
    return imageUrl;
  }

  /// Extracts image IDs from product associations
  static List<String> _extractImageIds(Map<String, dynamic> product) {
    try {
      final productId = product['id']?.toString() ?? 'unknown';

      // Try to get images from associations
      if (product['associations'] != null) {
        final associations = product['associations'];
        if (associations['images'] != null) {
          final images = associations['images'];

          // Handle both single image and array of images
          if (images is List) {
            final imageIds = images
                .map((img) {
                  if (img is Map<String, dynamic>) {
                    return img['id']?.toString() ?? '';
                  }
                  return img.toString();
                })
                .where((id) => id.isNotEmpty && id != '0')
                .toList();

            if (imageIds.isNotEmpty) {
              print('🖼️ Product $productId - Found ${imageIds.length} additional image IDs: $imageIds');
              // Construct and print full URLs
              for (var imageId in imageIds) {
                final url = '${ApiConfig.baseUrl}api/images/products/$productId/$imageId';
                print('   📸 Additional image URL: $url');
              }
            }
            return imageIds;
          } else if (images is Map<String, dynamic>) {
            final id = images['id']?.toString() ?? '';
            if (id.isNotEmpty && id != '0') {
              print('🖼️ Product $productId - Found 1 additional image ID: $id');
              final url = '${ApiConfig.baseUrl}api/images/products/$productId/$id';
              print('   📸 Additional image URL: $url');
            }
            return id.isNotEmpty && id != '0' ? [id] : [];
          }
        }
      }

      // Fallback: try direct 'images' field
      if (product['images'] != null) {
        final images = product['images'];
        if (images is List) {
          final imageIds = images
              .map((img) {
                if (img is Map<String, dynamic>) {
                  return img['id']?.toString() ?? img.toString();
                }
                return img.toString();
              })
              .where((id) => id.isNotEmpty && id != '0')
              .toList();

          if (imageIds.isNotEmpty) {
            print('🖼️ Product $productId - Found ${imageIds.length} image IDs (direct): $imageIds');
            for (var imageId in imageIds) {
              final url = '${ApiConfig.baseUrl}api/images/products/$productId/$imageId';
              print('   📸 Image URL: $url');
            }
          }
          return imageIds;
        }
      }

      print('🖼️ Product $productId - No additional images found');
      return [];
    } catch (e) {
      print('❌ Error extracting image IDs: $e');
      return [];
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'description_short': shortDescription,
      'price': price,
      'price_final': reducedPrice,
      'image_url': imageUrl,
      'images': images,
      'quantity': quantity,
      'reference': reference,
      'active': active,
      'id_category_default': categoryId,
      'id_manufacturer': manufacturerId,
      'manufacturer_name': manufacturerName,
      'id_default_combination': defaultCombinationId,
      'variants': variants?.map((v) => v.toJson()).toList(),
      'on_sale': onSale,
      'discount_percentage': discountPercentage,
    };
  }

  // Copy with method for easier updates
  Product copyWith({
    String? id,
    String? name,
    String? description,
    String? shortDescription,
    double? price,
    double? reducedPrice,
    String? imageUrl,
    List<String>? images,
    int? quantity,
    String? reference,
    bool? active,
    String? categoryId,
    String? manufacturerId,
    String? manufacturerName,
    String? defaultCombinationId,
    List<ProductVariant>? variants,
    bool? onSale,
    double? discountPercentage,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      shortDescription: shortDescription ?? this.shortDescription,
      price: price ?? this.price,
      reducedPrice: reducedPrice ?? this.reducedPrice,
      imageUrl: imageUrl ?? this.imageUrl,
      images: images ?? this.images,
      quantity: quantity ?? this.quantity,
      reference: reference ?? this.reference,
      active: active ?? this.active,
      categoryId: categoryId ?? this.categoryId,
      manufacturerId: manufacturerId ?? this.manufacturerId,
      manufacturerName: manufacturerName ?? this.manufacturerName,
      defaultCombinationId: defaultCombinationId ?? this.defaultCombinationId,
      variants: variants ?? this.variants,
      onSale: onSale ?? this.onSale,
      discountPercentage: discountPercentage ?? this.discountPercentage,
    );
  }
}

class ProductVariant {
  final String id;
  final String name;
  final double priceImpact;
  final int quantity;

  ProductVariant({
    required this.id,
    required this.name,
    required this.priceImpact,
    required this.quantity,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      priceImpact: json['price_impact'] is num
          ? (json['price_impact'] as num).toDouble()
          : double.tryParse(json['price_impact']?.toString() ?? '0') ?? 0.0,
      quantity: json['quantity'] is int
          ? json['quantity']
          : int.tryParse(json['quantity']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price_impact': priceImpact,
      'quantity': quantity,
    };
  }
}
