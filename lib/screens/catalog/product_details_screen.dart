import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/product.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../config/app_config.dart';
import '../../utils/helpers.dart';

class ProductDetailsScreen extends StatefulWidget {
  final int productId;

  const ProductDetailsScreen({super.key, required this.productId});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Product? _product;
  int _selectedImageIndex = 0;
  int _quantity = 1;
  ProductVariant? _selectedVariant;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProduct();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProduct() async {
    try {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      final product = await productProvider.getProductById(widget.productId);

      if (product != null) {
        setState(() {
          _product = product;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Product not found';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load product: $e';
        _isLoading = false;
      });
    }
  }

  void _onImageTap(int index) {
    setState(() {
      _selectedImageIndex = index;
    });
  }

  void _onQuantityChanged(int quantity) {
    setState(() {
      _quantity = quantity.clamp(1, 99);
    });
  }

  void _onVariantChanged(ProductVariant variant) {
    setState(() {
      _selectedVariant = variant;
    });
  }

  Future<void> _addToCart() async {
    if (_product == null || !_product!.inStock) return;

    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    final success = await cartProvider.addToCart(
      _product!,
      quantity: _quantity,
      variant: _selectedVariant,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Added to cart' : 'Failed to add to cart'),
        backgroundColor: success ? Colors.green : Colors.red,
        duration: const Duration(seconds: 2),
        action: success
            ? SnackBarAction(
                label: 'View Cart',
                textColor: Colors.white,
                onPressed: () {
                  context.push('/cart');
                },
              )
            : null,
      ),
    );
  }

  Future<void> _toggleFavorite() async {
    if (_product == null) return;

    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    await productProvider.toggleFavorite(_product!.id);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null || _product == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
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
                _errorMessage ?? 'Product not found',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConfig.defaultPadding),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Consumer2<ProductProvider, CartProvider>(
      builder: (context, productProvider, cartProvider, child) {
        final isFavorite = productProvider.isFavorite(_product!.id);
        final isInCart = cartProvider.items.any((item) =>
            item.productId == _product!.id &&
            item.productAttributeId == _selectedVariant?.id);

        return Scaffold(
          appBar: _buildAppBar(isFavorite, productProvider),
          body: Column(
            children: [
              Expanded(
                child: _buildProductContent(),
              ),
              _buildBottomActionBar(isInCart),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(bool isFavorite, ProductProvider productProvider) {
    return AppBar(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 0,
      actions: [
        IconButton(
          onPressed: _toggleFavorite,
          icon: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            color: isFavorite ? Colors.red : Colors.grey[600],
          ),
        ),
        IconButton(
          onPressed: () {
            // Share functionality
          },
          icon: const Icon(Icons.share),
        ),
      ],
    );
  }

  Widget _buildProductContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProductImages(),
          _buildProductInfo(),
          _buildProductTabs(),
        ],
      ),
    );
  }

  Widget _buildProductImages() {
    final images = _product!.images;

    if (images.isEmpty) {
      return Container(
        height: 300,
        color: Colors.grey[200],
        child: const Icon(
          Icons.image_not_supported,
          size: 64,
          color: Colors.grey,
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 300,
          child: PageView.builder(
            itemCount: images.length,
            onPageChanged: (index) {
              setState(() {
                _selectedImageIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return CachedNetworkImage(
                imageUrl: images[index],
                fit: BoxFit.contain,
                placeholder: (context, url) => Container(
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.image_not_supported),
                ),
              );
            },
          ),
        ),
        if (images.length > 1)
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(8),
              itemCount: images.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => _onImageTap(index),
                  child: Container(
                    width: 50,
                    height: 50,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _selectedImageIndex == index
                            ? AppConfig.primaryColor
                            : Colors.grey[300]!,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: CachedNetworkImage(
                        imageUrl: images[index],
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.image_not_supported, size: 20),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildProductInfo() {
    return Padding(
      padding: const EdgeInsets.all(AppConfig.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _product!.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          if (_product!.brand?.isNotEmpty == true) ...[
            Text(
              _product!.brand!,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              Text(
                Helpers.formatPriceWithSymbol(_selectedVariant?.price ?? _product!.effectivePrice),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppConfig.primaryColor,
                ),
              ),
              if (_product!.hasDiscount) ...[
                const SizedBox(width: 12),
                Text(
                  Helpers.formatPriceWithSymbol(_product!.price),
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[500],
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
              if (_product!.hasDiscount) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    Helpers.formatDiscountPercentage(_product!.discountPercentage),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                _product!.inStock ? Icons.check_circle : Icons.cancel,
                color: _product!.inStock ? Colors.green : Colors.red,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                Helpers.getStockStatus(_product!.quantity, outOfStock: _product!.outOfStock),
                style: TextStyle(
                  fontSize: 16,
                  color: _product!.inStock ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_product!.reference?.isNotEmpty == true) ...[
                const Spacer(),
                Text(
                  'SKU: ${_product!.reference}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          if (_product!.variants.isNotEmpty) _buildVariantSelector(),
          const SizedBox(height: 16),
          _buildQuantitySelector(),
        ],
      ),
    );
  }

  Widget _buildVariantSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Options',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _product!.variants.map((variant) {
            final isSelected = _selectedVariant?.id == variant.id;
            return FilterChip(
              label: Text(variant.name),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  _onVariantChanged(variant);
                } else {
                  setState(() {
                    _selectedVariant = null;
                  });
                }
              },
              backgroundColor: Colors.grey[200],
              selectedColor: AppConfig.primaryColor.withOpacity(0.2),
              checkmarkColor: AppConfig.primaryColor,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildQuantitySelector() {
    return Row(
      children: [
        const Text(
          'Quantity:',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: _quantity > 1 ? () => _onQuantityChanged(_quantity - 1) : null,
                icon: const Icon(Icons.remove),
                iconSize: 20,
              ),
              Container(
                width: 50,
                alignment: Alignment.center,
                child: Text(
                  '$_quantity',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: _quantity < 99 ? () => _onQuantityChanged(_quantity + 1) : null,
                icon: const Icon(Icons.add),
                iconSize: 20,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductTabs() {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Description'),
              Tab(text: 'Specifications'),
              Tab(text: 'Reviews'),
            ],
          ),
          SizedBox(
            height: 200,
            child: TabBarView(
              children: [
                _buildDescriptionTab(),
                _buildSpecificationsTab(),
                _buildReviewsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionTab() {
    return Padding(
      padding: const EdgeInsets.all(AppConfig.defaultPadding),
      child: SingleChildScrollView(
        child: Text(
          _product!.description.isNotEmpty
              ? _product!.description
              : 'No description available for this product.',
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildSpecificationsTab() {
    if (_product!.features.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(AppConfig.defaultPadding),
        child: Text('No specifications available.'),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(AppConfig.defaultPadding),
      child: ListView.builder(
        itemCount: _product!.features.length,
        itemBuilder: (context, index) {
          final feature = _product!.features[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    '${feature.name}:',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    feature.value,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildReviewsTab() {
    return const Padding(
      padding: EdgeInsets.all(AppConfig.defaultPadding),
      child: Column(
        children: [
          Icon(
            Icons.rate_review_outlined,
            size: 48,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'No reviews yet.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(bool isInCart) {
    return Container(
      padding: const EdgeInsets.all(AppConfig.defaultPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  // Add to wishlist
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: AppConfig.primaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Icon(
                  Icons.favorite_border,
                  color: AppConfig.primaryColor,
                ),
              ),
            ),
            const SizedBox(width: AppConfig.defaultPadding),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _product!.inStock ? _addToCart : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _product!.inStock ? AppConfig.primaryColor : Colors.grey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  isInCart ? 'In Cart' : 'Add to Cart',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}