import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/category.dart';
import '../../models/product.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/common/product_card.dart';
import '../../widgets/common/loading_widget.dart';
import '../../config/app_config.dart';
import '../../utils/helpers.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    await productProvider.init();
  }

  void _onSearch(String query) {
    if (query.trim().isNotEmpty) {
      context.push('/search?q=${Uri.encodeComponent(query)}');
    }
  }

  void _onCategoryTap(Category category) {
    context.push('/products?category_id=${category.id}');
  }

  void _onProductTap(Product product) {
    context.push('/product/${product.id}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              _buildSliverAppBar(),
              SliverToBoxAdapter(child: _buildSearchBar()),
              SliverToBoxAdapter(child: _buildCategoriesSection()),
              SliverToBoxAdapter(child: _buildFeaturedSection()),
              SliverToBoxAdapter(child: _buildRecentSection()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor: Colors.white,
      elevation: 2,
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppConfig.primaryColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.store,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            AppConfig.appName,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
      actions: [
        Consumer<CartProvider>(
          builder: (context, cartProvider, child) {
            return IconButton(
              onPressed: () => context.push('/cart'),
              icon: Stack(
                children: [
                  const Icon(Icons.shopping_cart_outlined),
                  if (cartProvider.itemCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          cartProvider.itemCount > 99 ? '99+' : cartProvider.itemCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(AppConfig.defaultPadding),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search products...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConfig.cardBorderRadius),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppConfig.defaultPadding,
            vertical: AppConfig.defaultPadding,
          ),
        ),
        onSubmitted: _onSearch,
        onChanged: (value) => setState(() {}),
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Categories', onViewAll: () {
              context.push('/products');
            }),
            SizedBox(
              height: 120,
              child: productProvider.categories.isEmpty
                  ? _buildEmptyCategories()
                  : _buildCategoriesGrid(productProvider.categories),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyCategories() {
    return const Center(
      child: Text(
        'No categories available',
        style: TextStyle(
          color: Colors.grey,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildCategoriesGrid(List<Category> categories) {
    final displayCategories = categories.take(8).toList();

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppConfig.defaultPadding),
      itemCount: displayCategories.length,
      itemBuilder: (context, index) {
        final category = displayCategories[index];
        return _buildCategoryCard(category);
      },
    );
  }

  Widget _buildCategoryCard(Category category) {
    return GestureDetector(
      onTap: () => _onCategoryTap(category),
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: AppConfig.defaultPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppConfig.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: category.imageUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: Image.network(
                        category.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.category,
                            color: AppConfig.primaryColor,
                            size: 30,
                          );
                        },
                      ),
                    )
                  : Icon(
                      Icons.category,
                      color: AppConfig.primaryColor,
                      size: 30,
                    ),
            ),
            const SizedBox(height: 8),
            Text(
              category.name,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedSection() {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Featured Products', onViewAll: () {
              context.push('/products?sort=price&order=DESC');
            }),
            Container(
              height: 280,
              margin: const EdgeInsets.symmetric(horizontal: AppConfig.defaultPadding),
              child: productProvider.featuredProducts.isEmpty
                  ? _buildEmptyFeatured()
                  : _buildFeaturedList(productProvider.featuredProducts),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyFeatured() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.star_outline,
            size: 48,
            color: Colors.grey,
          ),
          SizedBox(height: 8),
          Text(
            'No featured products',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedList(List<Product> products) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return Container(
          width: 200,
          margin: const EdgeInsets.only(right: AppConfig.defaultPadding),
          child: ProductCard(
            product: product,
            onTap: () => _onProductTap(product),
            onAddToCart: () => _addToCart(product),
          ),
        );
      },
    );
  }

  Widget _buildRecentSection() {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        if (productProvider.products.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Recent Products', onViewAll: () {
              context.push('/products');
            }),
            Container(
              margin: const EdgeInsets.all(AppConfig.defaultPadding),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.7,
                  crossAxisSpacing: AppConfig.defaultPadding,
                  mainAxisSpacing: AppConfig.defaultPadding,
                ),
                itemCount: productProvider.products.length.clamp(0, 6),
                itemBuilder: (context, index) {
                  final product = productProvider.products[index];
                  return ProductCard(
                    product: product,
                    onTap: () => _onProductTap(product),
                    onAddToCart: () => _addToCart(product),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onViewAll}) {
    return Padding(
      padding: const EdgeInsets.all(AppConfig.defaultPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          if (onViewAll != null)
            TextButton(
              onPressed: onViewAll,
              child: Text(
                'View All',
                style: TextStyle(
                  color: AppConfig.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _onRefresh() async {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    await productProvider.refresh();
  }

  Future<void> _addToCart(Product product) async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    final success = await cartProvider.addToCart(product);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Added to cart' : 'Failed to add to cart'),
        backgroundColor: success ? Colors.green : Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}