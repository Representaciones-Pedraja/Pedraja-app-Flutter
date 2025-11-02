import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../models/category.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/common/product_card.dart';
import '../../widgets/common/loading_widget.dart';
import '../../config/app_config.dart';
import '../../utils/helpers.dart';

class ProductsScreen extends StatefulWidget {
  final String? categoryId;

  const ProductsScreen({super.key, this.categoryId});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  String _selectedSort = 'name';
  String _selectedOrder = 'ASC';
  RangeValues _priceRange = const RangeValues(0, 1000);
  bool _showFilters = false;

  final List<Map<String, String>> _sortOptions = [
    {'value': 'name', 'label': 'Name'},
    {'value': 'price', 'label': 'Price'},
    {'value': 'date_add', 'label': 'Newest'},
    {'value': 'quantity', 'label': 'Popularity'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProducts();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreProducts();
    }
  }

  Future<void> _loadProducts() async {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final categoryId = widget.categoryId != null ? int.tryParse(widget.categoryId!) : null;

    await productProvider.loadProducts(categoryId: categoryId, refresh: true);
  }

  Future<void> _loadMoreProducts() async {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);

    if (!productProvider.hasMoreProducts || productProvider.isLoadingMore) {
      return;
    }

    final categoryId = widget.categoryId != null ? int.tryParse(widget.categoryId!) : null;
    await productProvider.loadMoreProducts();
  }

  void _onProductTap(Product product) {
    context.push('/product/${product.id}');
  }

  Future<void> _onAddToCart(Product product) async {
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

  void _onSortChanged(String sortValue) {
    setState(() {
      _selectedSort = sortValue;
    });

    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    productProvider.sortProducts(_selectedSort, _selectedOrder);
  }

  void _onOrderChanged(String orderValue) {
    setState(() {
      _selectedOrder = orderValue;
    });

    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    productProvider.sortProducts(_selectedSort, _selectedOrder);
  }

  void _onPriceRangeChanged(RangeValues values) {
    setState(() {
      _priceRange = values;
    });
  }

  void _applyFilters() {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final categoryId = widget.categoryId != null ? int.tryParse(widget.categoryId!) : null;

    productProvider.filterProducts(
      minPrice: _priceRange.start,
      maxPrice: _priceRange.end,
    );

    setState(() {
      _showFilters = false;
    });
  }

  void _clearFilters() {
    setState(() {
      _priceRange = const RangeValues(0, 1000);
    });

    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    productProvider.clearFilters();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildProductsList(),
                _buildCategoriesView(),
                _buildFiltersView(),
                _buildSortView(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _showFilters
          ? FloatingActionButton.extended(
              onPressed: _applyFilters,
              icon: const Icon(Icons.check),
              label: const Text('Apply Filters'),
            )
          : null,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(widget.categoryId != null ? 'Category Products' : 'All Products'),
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 2,
      actions: [
        Consumer<ProductProvider>(
          builder: (context, productProvider, child) {
            if (productProvider.selectedCategory != null) {
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Chip(
                  label: Text(productProvider.selectedCategory!.name),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () {
                    productProvider.setSelectedCategory(null);
                    _loadProducts();
                  },
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      indicatorColor: AppConfig.primaryColor,
      labelColor: AppConfig.primaryColor,
      unselectedLabelColor: Colors.grey,
      tabs: const [
        Tab(text: 'Products'),
        Tab(text: 'Categories'),
        Tab(text: 'Filters'),
        Tab(text: 'Sort'),
      ],
    );
  }

  Widget _buildProductsList() {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        if (productProvider.isLoading && productProvider.products.isEmpty) {
          return const LoadingProductGrid();
        }

        if (productProvider.status == ProductStatus.error) {
          return _buildErrorWidget(productProvider.errorMessage);
        }

        if (productProvider.products.isEmpty) {
          return _buildEmptyWidget();
        }

        return RefreshIndicator(
          onRefresh: _loadProducts,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollEndNotification) {
                _onScroll();
              }
              return false;
            },
            child: ProductGrid(
              products: productProvider.products,
              onProductTap: _onProductTap,
              onAddToCart: _onAddToCart,
              padding: const EdgeInsets.all(AppConfig.defaultPadding),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoriesView() {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        if (productProvider.categories.isEmpty) {
          return const Center(
            child: Text('No categories available'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppConfig.defaultPadding),
          itemCount: productProvider.categories.length,
          itemBuilder: (context, index) {
            final category = productProvider.categories[index];
            return _buildCategoryTile(category, productProvider);
          },
        );
      },
    );
  }

  Widget _buildCategoryTile(Category category, ProductProvider productProvider) {
    final productCount = productProvider.getProductCountByCategory()[category.id] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: AppConfig.defaultPadding),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppConfig.primaryColor.withOpacity(0.1),
          child: category.imageUrl.isNotEmpty
              ? ClipOval(
                  child: Image.network(
                    category.imageUrl,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.category,
                        color: AppConfig.primaryColor,
                        size: 24,
                      );
                    },
                  ),
                )
              : Icon(
                  Icons.category,
                  color: AppConfig.primaryColor,
                  size: 24,
                ),
        ),
        title: Text(category.name),
        subtitle: Text('$productCount products'),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          context.push('/products?category_id=${category.id}');
        },
      ),
    );
  }

  Widget _buildFiltersView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConfig.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Price Range',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConfig.defaultPadding),
          RangeSlider(
            values: _priceRange,
            min: 0,
            max: 1000,
            divisions: 20,
            labels: RangeLabels(
              '\$${_priceRange.start.round()}',
              '\$${_priceRange.end.round()}',
            ),
            onChanged: _onPriceRangeChanged,
          ),
          const SizedBox(height: AppConfig.largePadding),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _clearFilters,
                  child: const Text('Clear Filters'),
                ),
              ),
              const SizedBox(width: AppConfig.defaultPadding),
              Expanded(
                child: ElevatedButton(
                  onPressed: _applyFilters,
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSortView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConfig.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sort By',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConfig.defaultPadding),
          ..._sortOptions.map((option) => RadioListTile<String>(
            title: Text(option['label']!),
            value: option['value']!,
            groupValue: _selectedSort,
            onChanged: (value) {
              if (value != null) {
                _onSortChanged(value);
              }
            },
          )),
          const SizedBox(height: AppConfig.largePadding),
          const Text(
            'Order',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConfig.defaultPadding),
          RadioListTile<String>(
            title: const Text('Ascending'),
            value: 'ASC',
            groupValue: _selectedOrder,
            onChanged: (value) {
              if (value != null) {
                _onOrderChanged(value);
              }
            },
          ),
          RadioListTile<String>(
            title: const Text('Descending'),
            value: 'DESC',
            groupValue: _selectedOrder,
            onChanged: (value) {
              if (value != null) {
                _onOrderChanged(value);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String? errorMessage) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: AppConfig.defaultPadding),
          Text(
            errorMessage ?? 'An error occurred',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.red,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConfig.defaultPadding),
          ElevatedButton(
            onPressed: _loadProducts,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: AppConfig.defaultPadding),
          const Text(
            'No products found',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: AppConfig.defaultPadding),
          ElevatedButton(
            onPressed: () {
              _tabController.animateTo(2); // Go to filters tab
            },
            child: const Text('Adjust Filters'),
          ),
        ],
      ),
    );
  }
}