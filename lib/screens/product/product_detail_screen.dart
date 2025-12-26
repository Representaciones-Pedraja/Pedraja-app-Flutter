import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/conditional_price_widget.dart';
import '../../models/product_detail.dart';
import '../../services/api_service.dart';
import '../../services/stock_service.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import '../../config/app_theme.dart';
import '../../config/api_config.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  int _currentImageIndex = 0;
  bool _isDescriptionExpanded = false;
  final PageController _imagePageController = PageController();

  bool? _realStockStatus;
  int? _realStockQuantity;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductProvider>(context, listen: false)
          .fetchProductById(widget.productId);
    });
  }

  @override
  void dispose() {
    _imagePageController.dispose();
    super.dispose();
  }

  Future<void> _checkRealStock(String productId) async {
    try {
      final apiService = ApiService(
        baseUrl: ApiConfig.baseUrl,
        apiKey: ApiConfig.apiKey,
      );
      final stockService = StockService(apiService);

      final stocks = await stockService.getStockByProduct(productId);
      final simpleStock = stocks.first;

      setState(() {
        _realStockQuantity = simpleStock.quantity;
        _realStockStatus = simpleStock.quantity > 0;
      });
    } catch (e) {
      debugPrint('Error checking real stock: $e');
      setState(() {
        _realStockStatus = false;
        _realStockQuantity = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // <-- Cambia aquí a true si el usuario está registrado
    final bool isUserLoggedIn = true;

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _buildCircleButton(
          icon: Icons.arrow_back,
          onTap: () => Navigator.pop(context),
        ),
        actions: [
          _buildCircleButton(icon: Icons.favorite_border, onTap: () {}),
          const SizedBox(width: 8),
          _buildCircleButton(icon: Icons.share_outlined, onTap: () {}),
          const SizedBox(width: 16),
        ],
      ),
      body: Consumer<ProductProvider>(
        builder: (context, productProvider, child) {
          if (productProvider.isLoading) {
            return const LoadingWidget(message: 'Loading product...');
          }
          if (productProvider.hasError) {
            return ErrorDisplayWidget(
              message: productProvider.error ?? 'Unknown error',
              onRetry: () {
                productProvider.fetchProductById(widget.productId);
              },
            );
          }

          final product = productProvider.selectedProduct;
          if (product == null) return const Center(child: Text('Product not found'));

          if (_realStockStatus == null &&
              (product.inStock == false || product.quantity == 0)) {
            _checkRealStock(widget.productId);
          }

          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ProductImageCarousel(
                      imageUrl: product.imageUrl ?? '',
                      images: product.images,
                      productId: product.id,
                      currentIndex: _currentImageIndex,
                      pageController: _imagePageController,
                      onPageChanged: (index) {
                        setState(() => _currentImageIndex = index);
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _PriceBlock(
                            name: product.name,
                            manufacturerName: product.manufacturerName ?? '',
                            price: product.price,
                            showPrice: isUserLoggedIn,
                          ),
                          const SizedBox(height: 24),
                          _DescriptionSection(
                            description: product.shortDescription,
                            isExpanded: _isDescriptionExpanded,
                            onToggle: () {
                              setState(() {
                                _isDescriptionExpanded = !_isDescriptionExpanded;
                              });
                            },
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _AddToCartBar(
                  quantity: _quantity,
                  maxQuantity: _realStockQuantity ?? 1,
                  onQuantityChanged: (newQuantity) {
                    setState(() => _quantity = newQuantity);
                  },
                  onAddToCart: () {
                    if (!isUserLoggedIn) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please log in to buy products')),
                      );
                      return;
                    }

                    final cartProvider =
                        Provider.of<CartProvider>(context, listen: false);
                    cartProvider.addItem(
                      product,
                      quantity: _quantity,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Added to cart'),
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.pureWhite,
          shape: BoxShape.circle,
          boxShadow: AppTheme.softShadow,
        ),
        child: Icon(icon, size: 20, color: AppTheme.primaryBlack),
      ),
    );
  }
}

// ============================================================================
// WIDGETS
// ============================================================================

class _ProductImageCarousel extends StatelessWidget {
  final String imageUrl;
  final List<String>? images;
  final String productId;
  final int currentIndex;
  final PageController pageController;
  final ValueChanged<int> onPageChanged;

  const _ProductImageCarousel({
    required this.imageUrl,
    required this.images,
    required this.productId,
    required this.currentIndex,
    required this.pageController,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final allImages = images ?? [];
    if (!allImages.contains(imageUrl)) allImages.insert(0, imageUrl);

    return SizedBox(
      height: 400,
      child: PageView.builder(
        controller: pageController,
        onPageChanged: onPageChanged,
        itemCount: allImages.length,
        itemBuilder: (context, index) {
          return CachedNetworkImage(
            imageUrl: allImages[index],
            fit: BoxFit.cover,
            placeholder: (_, __) => const Center(child: CircularProgressIndicator()),
            errorWidget: (_, __, ___) => const Icon(Icons.error),
          );
        },
      ),
    );
  }
}

class _PriceBlock extends StatelessWidget {
  final String name;
  final String manufacturerName;
  final double price;
  final bool showPrice;

  const _PriceBlock({
    required this.name,
    required this.manufacturerName,
    required this.price,
    this.showPrice = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(manufacturerName, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (showPrice)
          ConditionalPriceWidget(price: price)
        else
          const Text('Log in to see price', style: TextStyle(color: Colors.red)),
      ],
    );
  }
}

class _DescriptionSection extends StatelessWidget {
  final String description;
  final bool isExpanded;
  final VoidCallback onToggle;

  const _DescriptionSection({
    required this.description,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final displayText = isExpanded
        ? description
        : (description.length > 100 ? '${description.substring(0, 100)}...' : description);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(displayText),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onToggle,
          child: Text(
            isExpanded ? 'Show less' : 'Read more',
            style: const TextStyle(color: Colors.blue),
          ),
        ),
      ],
    );
  }
}

class _AddToCartBar extends StatelessWidget {
  final int quantity;
  final int? maxQuantity;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onAddToCart;

  const _AddToCartBar({
    required this.quantity,
    required this.maxQuantity,
    required this.onQuantityChanged,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          _QuantityButton(
            quantity: quantity,
            maxQuantity: maxQuantity ?? 999,
            onChanged: onQuantityChanged,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: onAddToCart,
              child: const Text('Add to cart'),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final int quantity;
  final int maxQuantity;
  final ValueChanged<int> onChanged;

  const _QuantityButton({
    required this.quantity,
    required this.maxQuantity,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: quantity > 1 ? () => onChanged(quantity - 1) : null,
          icon: const Icon(Icons.remove),
        ),
        Text(quantity.toString()),
        IconButton(
          onPressed: quantity < maxQuantity ? () => onChanged(quantity + 1) : null,
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}
