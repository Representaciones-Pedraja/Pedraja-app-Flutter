import '../utils/language_helper.dart';
import '../config/api_config.dart';

class Category {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final String? parentId;
  final bool active;
  final int position;

  Category({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    this.parentId,
    this.active = true,
    this.position = 0,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    try {
      final category = json['category'] ?? json;

      final categoryId = category['id']?.toString() ?? '';

      return Category(
        id: categoryId,
        name: LanguageHelper.extractValueOrEmpty(category['name']),
        description: LanguageHelper.extractValue(category['description']),
        imageUrl: _constructImageUrl(categoryId),
        parentId: category['id_parent']?.toString(),
        active: category['active'] == '1' || category['active'] == true,
        position: category['position'] is int
            ? category['position']
            : int.tryParse(category['position']?.toString() ?? '0') ?? 0,
      );
    } catch (e) {
      throw Exception('Failed to parse category: $e');
    }
  }

  /// Constructs the full image URL for a category
  static String? _constructImageUrl(String categoryId) {
    if (categoryId.isEmpty || categoryId == '0') {
      print('🖼️ [Category] No image URL - categoryId: $categoryId');
      return null;
    }
    final imageUrl = '${ApiConfig.baseUrl}api/images/categories/$categoryId';
    print('🖼️ [Category] Category image URL constructed: $imageUrl');
    return imageUrl;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image_url': imageUrl,
      'id_parent': parentId,
      'active': active,
      'position': position,
    };
  }
}
