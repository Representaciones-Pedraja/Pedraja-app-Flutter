import '../config/app_config.dart';
import '../models/cart.dart';
import '../models/product.dart';
import '../services/storage_service.dart';
import '../utils/helpers.dart';

class CartService {
  static Cart? _currentCart;

  // Get current cart (from storage or memory)
  Future<Cart> getCurrentCart() async {
    if (_currentCart != null) {
      return _currentCart!;
    }

    final cart = await StorageService.getCartData();
    if (cart != null) {
      _currentCart = cart;
      return cart;
    }

    // Create new cart if none exists
    final newCart = Cart(
      guestId: 1,
      currencyId: 1,
    );

    await saveCart(newCart);
    return newCart;
  }

  // Save cart to storage and memory
  Future<void> saveCart(Cart cart) async {
    _currentCart = cart;
    await StorageService.saveCartData(cart);
  }

  // Add item to cart
  Future<Cart> addToCart(Product product, {int quantity = 1, ProductVariant? variant}) async {
    final cart = await getCurrentCart();

    // Check if item already exists
    final existingIndex = _findItemIndex(cart, product.id, variant?.id);

    if (existingIndex != -1) {
      // Update quantity of existing item
      final existingItem = cart.items[existingIndex];
      cart.items[existingIndex] = existingItem.copyWith(
        quantity: existingItem.quantity + quantity,
      );
    } else {
      // Add new item
      final cartItem = product.toCartItem(quantity: quantity, variant: variant);
      cart.associations = cart.associations.copyWith(
        cartRows: [...cart.items, cartItem],
      );
    }

    await saveCart(cart);
    return cart;
  }

  // Update item quantity
  Future<Cart> updateQuantity(String uniqueId, int quantity) async {
    final cart = await getCurrentCart();

    final itemIndex = cart.items.indexWhere((item) => item.uniqueId == uniqueId);
    if (itemIndex == -1) {
      throw Exception('Item not found in cart');
    }

    if (quantity <= 0) {
      // Remove item if quantity is 0 or less
      await removeFromCart(uniqueId);
      return cart;
    }

    cart.items[itemIndex] = cart.items[itemIndex].copyWith(quantity: quantity);
    await saveCart(cart);
    return cart;
  }

  // Remove item from cart
  Future<Cart> removeFromCart(String uniqueId) async {
    final cart = await getCurrentCart();

    final updatedItems = cart.items.where((item) => item.uniqueId != uniqueId).toList();
    cart.associations = cart.associations.copyWith(cartRows: updatedItems);

    await saveCart(cart);
    return cart;
  }

  // Clear entire cart
  Future<void> clearCart() async {
    final cart = await getCurrentCart();
    final emptyCart = cart.copyWith(
      associations: const CartAssociations(cartRows: []),
    );

    await saveCart(emptyCart);
  }

  // Get cart statistics
  CartStats getCartStats() {
    final cart = _currentCart ?? Cart(guestId: 1, currencyId: 1);

    return CartStats(
      itemCount: cart.totalItems,
      subtotal: cart.subtotal,
      total: _calculateTotal(cart),
      shipping: _calculateShipping(cart.subtotal),
      tax: _calculateTax(cart.subtotal),
    );
  }

  // Find item index in cart
  int? _findItemIndex(Cart cart, int productId, int? variantId) {
    for (int i = 0; i < cart.items.length; i++) {
      final item = cart.items[i];
      if (item.productId == productId && item.productAttributeId == variantId) {
        return i;
      }
    }
    return null;
  }

  // Calculate total with shipping and tax
  double _calculateTotal(Cart cart) {
    final subtotal = cart.subtotal;
    final shipping = _calculateShipping(subtotal);
    final tax = _calculateTax(subtotal);

    return subtotal + shipping + tax;
  }

  // Calculate shipping (free shipping over threshold)
  double _calculateShipping(double subtotal) {
    const freeShippingThreshold = 100.0; // Configurable
    const standardShipping = 9.99;

    return subtotal >= freeShippingThreshold ? 0.0 : standardShipping;
  }

  // Calculate tax (8% by default)
  double _calculateTax(double subtotal) {
    const taxRate = 0.08;
    return subtotal * taxRate;
  }

  // Check if product is in cart
  Future<bool> isInCart(int productId, {int? variantId}) async {
    final cart = await getCurrentCart();
    return cart.items.any((item) =>
        item.productId == productId && item.productAttributeId == variantId);
  }

  // Get quantity of specific item in cart
  Future<int> getItemQuantity(int productId, {int? variantId}) async {
    final cart = await getCurrentCart();

    for (final item in cart.items) {
      if (item.productId == productId && item.productAttributeId == variantId) {
        return item.quantity;
      }
    }

    return 0;
  }

  // Validate cart stock
  Future<List<String>> validateStock() async {
    final cart = await getCurrentCart();
    final warnings = <String>[];

    for (final item in cart.items) {
      // In a real implementation, you'd check current stock from API
      // For now, we'll simulate stock validation
      if (item.quantity > 10) {
        warnings.add('${item.productName}: Limited to 10 units per order');
      }
    }

    return warnings;
  }

  // Merge guest cart with customer cart
  Future<Cart> mergeWithCustomerCart(int customerId) async {
    final currentCart = await getCurrentCart();

    // In a real implementation, you'd:
    // 1. Fetch existing customer cart from API
    // 2. Merge items (prefer customer cart items, add guest cart items)
    // 3. Save merged cart to API and local storage

    final mergedCart = currentCart.copyWith(
      customerId: customerId,
      guestId: 0,
    );

    await saveCart(mergedCart);
    return mergedCart;
  }

  // Sync cart with server (when logged in)
  Future<void> syncWithServer() async {
    // In a real implementation, this would sync local cart with server
    // For now, we'll just save to storage
    if (_currentCart != null) {
      await StorageService.saveCartData(_currentCart!);
    }
  }

  // Get cart for API (remove local-only fields)
  Map<String, dynamic> getCartForApi() {
    final cart = _currentCart ?? Cart(guestId: 1, currencyId: 1);

    return {
      'id_customer': cart.customerId ?? 0,
      'id_guest': cart.guestId,
      'id_currency': cart.currencyId,
      'associations': {
        'cart_rows': cart.items.map((item) => {
          'id_product': item.productId,
          'id_product_attribute': item.productAttributeId ?? 0,
          'quantity': item.quantity,
          'price': item.unitPrice,
        }).toList(),
      },
    };
  }

  // Load cart from storage (call on app start)
  Future<void> loadCart() async {
    _currentCart = await StorageService.getCartData();
  }

  // Reset cart service (for logout)
  Future<void> reset() async {
    _currentCart = null;
    await clearCart();
  }

  // Get estimated delivery date
  DateTime getEstimatedDeliveryDate() {
    final now = DateTime.now();
    // Standard delivery is 3-5 business days
    return now.add(const Duration(days: 5));
  }

  // Check if cart qualifies for free shipping
  bool qualifiesForFreeShipping() {
    final cart = _currentCart ?? Cart(guestId: 1, currencyId: 1);
    const freeShippingThreshold = 100.0;
    return cart.subtotal >= freeShippingThreshold;
  }

  // Get amount needed for free shipping
  double getAmountForFreeShipping() {
    final cart = _currentCart ?? Cart(guestId: 1, currencyId: 1);
    const freeShippingThreshold = 100.0;
    final needed = freeShippingThreshold - cart.subtotal;
    return needed > 0 ? needed : 0.0;
  }

  // Export cart for sharing (optional feature)
  Map<String, dynamic> exportCart() {
    final cart = _currentCart ?? Cart(guestId: 1, currencyId: 1);

    return {
      'version': '1.0',
      'timestamp': DateTime.now().toIso8601String(),
      'items': cart.items.map((item) => {
        'product_id': item.productId,
        'product_name': item.productName,
        'quantity': item.quantity,
        'unit_price': item.unitPrice,
        'total_price': item.totalPrice,
      }).toList(),
      'summary': {
        'item_count': cart.totalItems,
        'subtotal': cart.subtotal,
      },
    };
  }
}

// Cart statistics model
class CartStats {
  final int itemCount;
  final double subtotal;
  final double total;
  final double shipping;
  final double tax;

  const CartStats({
    required this.itemCount,
    required this.subtotal,
    required this.total,
    required this.shipping,
    required this.tax,
  });

  @override
  String toString() {
    return 'CartStats(itemCount: $itemCount, subtotal: $subtotal, total: $total)';
  }
}

// Singleton instance
final cartService = CartService();