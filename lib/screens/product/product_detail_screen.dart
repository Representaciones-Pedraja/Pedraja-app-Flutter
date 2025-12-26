// lib/screens/product/product_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prestashop_mobile_app/config/app_theme.dart';
import 'package:prestashop_mobile_app/models/product_detail.dart';
import 'package:prestashop_mobile_app/providers/product_provider.dart';
import 'package:prestashop_mobile_app/providers/cart_provider.dart';
import 'package:prestashop_mobile_app/providers/auth_provider.dart';
import 'package:prestashop_mobile_app/widgets/loading_widget.dart';
import 'package:prestashop_mobile_app/widgets/error_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({
    Key? key,
    required this.productId,
  }) : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _selectedQuantity = 1;
  bool _isAddingToCart = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProduct();
    });
  }

  Future<void> _loadProduct() async {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    await productProvider.fetchProductDetail(
      widget.productId,
      customerId: authProvider.customer?.id,
      customerGroupId: authProvider.customer?.idDefaultGroup,
    );
    
    // Establecer cantidad inicial según el mínimo del producto
    if (productProvider.productDetail != null) {
      setState(() {
        _selectedQuantity = productProvider.productDetail!.effectiveMinimalQuantity;
      });
    }
  }

  // NUEVO: Incrementa cantidad respetando múltiplos
  void _incrementQuantity(ProductDetail product) {
    final step = product.effectiveQuantityStep;
    setState(() {
      _selectedQuantity += step;
    });
  }

  // NUEVO: Decrementa cantidad respetando múltiplos y mínimo
  void _decrementQuantity(ProductDetail product) {
    final step = product.effectiveQuantityStep;
    final minQty = product.effectiveMinimalQuantity;
    
    setState(() {
      final newQty = _selectedQuantity - step;
      if (newQty >= minQty) {
        _selectedQuantity = newQty;
      }
    });
  }

  // NUEVO: Valida y ajusta cantidad ingresada manualmente
  void _onQuantityChanged(ProductDetail product, String value) {
    final qty = int.tryParse(value);
    if (qty == null) return;
    
    setState(() {
      _selectedQuantity = product.adjustToValidQuantity(qty);
    });
  }

  Future<void> _addToCart(ProductDetail product) async {
    // Validar cantidad
    if (!product.isValidQuantity(_selectedQuantity)) {
      _showError(
        'Cantidad no válida',
        'La cantidad mínima es ${product.effectiveMinimalQuantity} '
        'y debe ser múltiplo de ${product.effectiveQuantityStep}',
      );
      return;
    }

    setState(() => _isAddingToCart = true);

    try {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Obtener precio según grupo del cliente
      final customerGroupId = authProvider.customer?.idDefaultGroup ?? '1';
      final price = product.getPriceForGroup(customerGroupId);
      
      await cartProvider.addItem(
        productId: product.id,
        quantity: _selectedQuantity,
        price: price.toString(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product.name} añadido al carrito'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Ver carrito',
              textColor: Colors.white,
              onPressed: () {
                Navigator.pushNamed(context, '/cart');
              },
            ),
          ),
        );
      }
    } catch (e) {
      _showError('Error', 'No se pudo añadir al carrito: $e');
    } finally {
      if (mounted) {
        setState(() => _isAddingToCart = false);
      }
    }
  }

  void _showError(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      body: Consumer<ProductProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const LoadingWidget(message: 'Cargando producto...');
          }

          if (provider.hasError) {
            return ErrorDisplayWidget(
              message: provider.error ?? 'Error al cargar producto',
              onRetry: _loadProduct,
            );
          }

          final product = provider.productDetail;
          if (product == null) {
            return const Center(child: Text('Producto no encontrado'));
          }

          return CustomScrollView(
            slivers: [
              // App Bar con imagen
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: AppTheme.backgroundWhite,
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildProductImage(product),
                ),
              ),

              // Contenido
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProductInfo(product),
                    const Divider(height: 32),
                    _buildQuantitySelector(product),
                    const Divider(height: 32),
                    _buildDescription(product),
                    const SizedBox(height: 100), // Espacio para el botón flotante
                  ],
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: Consumer<ProductProvider>(
        builder: (context, provider, _) {
          final product = provider.productDetail;
          if (product == null) return const SizedBox.shrink();
          
          return _buildAddToCartButton(product);
        },
      ),
    );
  }

  Widget _buildProductImage(ProductDetail product) {
    if (product.imageUrls.isEmpty) {
      return Container(
        color: Colors.grey[200],
        child: const Icon(Icons.image, size: 100, color: Colors.grey),
      );
    }

    return PageView.builder(
      itemCount: product.imageUrls.length,
      itemBuilder: (context, index) {
        final imageUrl = product.imageUrls[index];
        return CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => const Center(
            child: CircularProgressIndicator(),
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey[200],
            child: const Icon(Icons.error, size: 50),
          ),
        );
      },
    );
  }

  Widget _buildProductInfo(ProductDetail product) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final customerGroupId = authProvider.customer?.idDefaultGroup ?? '1';
    final price = product.getPriceForGroup(customerGroupId);

    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacing3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryBlack,
            ),
          ),
          const SizedBox(height: AppTheme.spacing2),
          Text(
            '€${price.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryBlack,
            ),
          ),
          if (product.reference.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacing1),
            Text(
              'Ref: ${product.reference}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
          const SizedBox(height: AppTheme.spacing2),
          _buildStockStatus(product),
        ],
      ),
    );
  }

  Widget _buildStockStatus(ProductDetail product) {
    final quantity = int.tryParse(product.quantity) ?? 0;
    final isAvailable = quantity > 0 && product.availableForOrder == '1';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing2,
        vertical: AppTheme.spacing1,
      ),
      decoration: BoxDecoration(
        color: isAvailable ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAvailable ? Icons.check_circle : Icons.cancel,
            color: isAvailable ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            isAvailable ? 'En stock ($quantity unidades)' : 'Agotado',
            style: TextStyle(
              color: isAvailable ? Colors.green[700] : Colors.red[700],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // NUEVO: Selector de cantidad con múltiplos
  Widget _buildQuantitySelector(ProductDetail product) {
    final minQty = product.effectiveMinimalQuantity;
    final step = product.effectiveQuantityStep;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cantidad',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryBlack,
            ),
          ),
          const SizedBox(height: AppTheme.spacing2),
          
          // Info sobre cantidades
          if (minQty > 1 || step > 1) ...[
            Container(
              padding: const EdgeInsets.all(AppTheme.spacing2),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      minQty > 1
                          ? 'Cantidad mínima: $minQty unidades'
                          : 'Múltiplos de $step unidades',
                      style: const TextStyle(
                        color: Colors.blue,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacing2),
          ],

          // Selector de cantidad
          Row(
            children: [
              // Botón decrementar
              IconButton(
                onPressed: _selectedQuantity > minQty
                    ? () => _decrementQuantity(product)
                    : null,
                icon: const Icon(Icons.remove),
                style: IconButton.styleFrom(
                  backgroundColor: _selectedQuantity > minQty
                      ? AppTheme.primaryBlack
                      : Colors.grey[300],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                ),
              ),

              // Campo de texto con cantidad
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacing2),
                  child: TextField(
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    controller: TextEditingController(text: '$_selectedQuantity'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacing2,
                        vertical: AppTheme.spacing1,
                      ),
                      suffix: Text(
                        step > 1 ? '(×$step)' : '',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    onChanged: (value) => _onQuantityChanged(product, value),
                  ),
                ),
              ),

              // Botón incrementar
              IconButton(
                onPressed: () => _incrementQuantity(product),
                icon: const Icon(Icons.add),
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlack,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDescription(ProductDetail product) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Descripción',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryBlack,
            ),
          ),
          const SizedBox(height: AppTheme.spacing2),
          Text(
            product.description.replaceAll(RegExp(r'<[^>]*>'), ''),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddToCartButton(ProductDetail product) {
    final isInStock = int.tryParse(product.quantity) ?? 0 > 0;
    final canOrder = product.availableForOrder == '1';

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing3),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: AppTheme.mediumShadow,
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: isInStock && canOrder && !_isAddingToCart
              ? () => _addToCart(product)
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryBlack,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            minimumSize: const Size(double.infinity, 54),
          ),
          child: _isAddingToCart
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  isInStock && canOrder
                      ? 'Añadir al carrito ($_selectedQuantity)'
                      : 'No disponible',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
}