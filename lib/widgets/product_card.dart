import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import '../config/app_theme.dart';
import '../utils/image_helper.dart';
import '../l10n/app_localizations.dart';
import 'conditional_price_widget.dart';

/// Modern Product Card with soft shadows and clean design
class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  final bool showAddToCart;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.showAddToCart = true,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.pureWhite,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image Section
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  // Product Image
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppTheme.radiusMedium),
                    ),
                    child: product.imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: product.imageUrl!,
                            httpHeaders: ImageHelper.authHeaders,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: AppTheme.backgroundWhite,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.secondaryGrey,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) {
                              print('❌ Failed to load image: $url');
                              print('❌ Error: $error');
                              return Container(
                                color: AppTheme.backgroundWhite,
                                child: const Icon(
                                  Icons.image_outlined,
                                  size: 40,
                                  color: AppTheme.lightGrey,
                                ),
                              );
                            },
                          )
                        : Container(
                            color: AppTheme.backgroundWhite,
                            child: const Center(
                              child: Icon(
                                Icons.shopping_bag_outlined,
                                size: 40,
                                color: AppTheme.lightGrey,
                              ),
                            ),
                          ),
                  ),

                  // Sale Badge (solo si está autenticado)
                  if (product.isOnSale && authProvider.isAuthenticated)
                    Positioned(
                      top: AppTheme.spacing1,
                      left: AppTheme.spacing1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacing1,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.errorRed,
                          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                        ),
                        child: Text(
                          '-${product.calculatedDiscountPercentage.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: AppTheme.pureWhite,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Product Info Section
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacing1),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Product Name
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                        color: AppTheme.primaryBlack,
                        height: 1.3,
                      ),
                    ),

                    // Price Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Precio con control de autenticación
                        Flexible(
                          child: ConditionalPriceWidget(
                            price: product.finalPrice,
                            oldPrice: product.isOnSale ? product.price : null,
                            priceStyle: const TextStyle(
                              color: AppTheme.primaryBlack,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            oldPriceStyle: const TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: AppTheme.secondaryGrey,
                              fontSize: 11,
                            ),
                            isCompact: true,
                          ),
                        ),

                        // Quick Add Button (solo si está autenticado)
                        if (showAddToCart && authProvider.isAuthenticated)
                          Consumer<CartProvider>(
                            builder: (context, cart, child) {
                              final isInCart = cart.isInCart(product.id);
                              return GestureDetector(
                                onTap: () {
                                  if (!isInCart) {
                                    cart.addItem(product);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(l10n?.addedToCart ?? 'Añadido al carrito'),
                                        duration: const Duration(seconds: 1),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: isInCart
                                        ? AppTheme.successGreen
                                        : AppTheme.primaryBlack,
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.radiusSmall,
                                    ),
                                  ),
                                  child: Icon(
                                    isInCart
                                        ? Icons.check
                                        : Icons.add_shopping_cart_outlined,
                                    size: 16,
                                    color: AppTheme.pureWhite,
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}