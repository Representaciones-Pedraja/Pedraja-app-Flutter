// lib/screens/category/category_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prestashop_mobile_app/config/app_theme.dart';
import 'package:prestashop_mobile_app/models/category.dart';
import 'package:prestashop_mobile_app/providers/category_provider.dart';
import 'package:prestashop_mobile_app/widgets/loading_widget.dart';
import 'package:prestashop_mobile_app/widgets/error_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CategoryScreen extends StatefulWidget {
  final String? parentId;
  final String? title;

  const CategoryScreen({
    Key? key,
    this.parentId,
    this.title,
  }) : super(key: key);

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCategories();
    });
  }

  Future<void> _loadCategories() async {
    final provider = Provider.of<CategoryProvider>(context, listen: false);
    
    if (widget.parentId != null) {
      // Cargar subcategorías específicas
      await provider.fetchSubcategories(widget.parentId!);
    } else {
      // Cargar categorías principales
      await provider.fetchRootCategories();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: Text(widget.title ?? 'Categorías'),
        backgroundColor: AppTheme.backgroundWhite,
        foregroundColor: AppTheme.primaryBlack,
        elevation: 0,
      ),
      body: Consumer<CategoryProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const LoadingWidget(message: 'Cargando categorías...');
          }

          if (provider.hasError) {
            return ErrorDisplayWidget(
              message: provider.error ?? 'Error al cargar categorías',
              onRetry: _loadCategories,
            );
          }

          final categories = widget.parentId != null
              ? provider.subcategories
              : provider.rootCategories;

          if (categories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.category_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay subcategorías',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadCategories,
            child: ListView.builder(
              padding: const EdgeInsets.all(AppTheme.spacing2),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                return _buildCategoryCard(categories[index]);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryCard(Category category) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      elevation: 2,
      child: InkWell(
        onTap: () => _onCategoryTap(category),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing2),
          child: Row(
            children: [
              // Imagen de categoría
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                child: CachedNetworkImage(
                  imageUrl: _getCategoryImageUrl(category.id),
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[200],
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[200],
                    child: Icon(
                      Icons.category,
                      size: 40,
                      color: Colors.grey[400],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: AppTheme.spacing2),
              
              // Info de categoría
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryBlack,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (category.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        category.description.replaceAll(RegExp(r'<[^>]*>'), ''),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              
              // Icono de flecha
              const Icon(
                Icons.chevron_right,
                color: AppTheme.primaryBlack,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getCategoryImageUrl(String categoryId) {
    final provider = Provider.of<CategoryProvider>(context, listen: false);
    return provider.getCategoryImageUrl(categoryId);
  }

  Future<void> _onCategoryTap(Category category) async {
    // Verificar si tiene subcategorías
    final provider = Provider.of<CategoryProvider>(context, listen: false);
    final hasChildren = await provider.hasSubcategories(category.id);

    if (hasChildren) {
      // Navegar a subcategorías
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryScreen(
              parentId: category.id,
              title: category.name,
            ),
          ),
        );
      }
    } else {
      // Navegar a productos de esta categoría
      if (mounted) {
        Navigator.pushNamed(
          context,
          '/products',
          arguments: {
            'categoryId': category.id,
            'categoryName': category.name,
          },
        );
      }
    }
  }
}

/// NUEVO: Widget para árbol de categorías expandible
class CategoryTreeWidget extends StatefulWidget {
  final String? rootId;

  const CategoryTreeWidget({
    Key? key,
    this.rootId,
  }) : super(key: key);

  @override
  State<CategoryTreeWidget> createState() => _CategoryTreeWidgetState();
}

class _CategoryTreeWidgetState extends State<CategoryTreeWidget> {
  final Map<String, bool> _expanded = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTree();
    });
  }

  Future<void> _loadTree() async {
    final provider = Provider.of<CategoryProvider>(context, listen: false);
    await provider.fetchCategoryTree(rootId: widget.rootId);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CategoryProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const LoadingWidget(message: 'Cargando árbol...');
        }

        if (provider.hasError) {
          return ErrorDisplayWidget(
            message: provider.error ?? 'Error al cargar árbol',
            onRetry: _loadTree,
          );
        }

        if (provider.categoryTree.isEmpty) {
          return const Center(child: Text('No hay categorías'));
        }

        return ListView.builder(
          itemCount: provider.categoryTree.length,
          itemBuilder: (context, index) {
            return _buildTreeNode(provider.categoryTree[index], 0);
          },
        );
      },
    );
  }

  Widget _buildTreeNode(dynamic node, int level) {
    // node es CategoryNode del servicio
    final category = node.category as Category;
    final children = node.children as List<dynamic>;
    final hasChildren = children.isNotEmpty;
    final isExpanded = _expanded[category.id] ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => _onNodeTap(category, hasChildren),
          child: Padding(
            padding: EdgeInsets.only(
              left: level * 20.0 + 16,
              right: 16,
              top: 12,
              bottom: 12,
            ),
            child: Row(
              children: [
                if (hasChildren)
                  Icon(
                    isExpanded ? Icons.expand_more : Icons.chevron_right,
                    size: 20,
                  ),
                if (!hasChildren)
                  const SizedBox(width: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    category.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: level == 0 ? FontWeight.bold : FontWeight.normal,
                      color: AppTheme.primaryBlack,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
        
        // Hijos expandidos
        if (isExpanded && hasChildren)
          ...children.map((child) => _buildTreeNode(child, level + 1)),
      ],
    );
  }

  void _onNodeTap(Category category, bool hasChildren) {
    if (hasChildren) {
      setState(() {
        _expanded[category.id] = !(_expanded[category.id] ?? false);
      });
    } else {
      // Navegar a productos
      Navigator.pushNamed(
        context,
        '/products',
        arguments: {
          'categoryId': category.id,
          'categoryName': category.name,
        },
      );
    }
  }
}