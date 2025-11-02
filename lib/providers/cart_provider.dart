import 'package:flutter/foundation.dart';
import '../models/cart.dart';
import '../models/product.dart';
import '../services/cart_service.dart';

enum CartStatus {
  initial,
  loading,
  loaded,
  updating,
  error,
}

class CartProvider extends ChangeNotifier {
  final CartService _cartService = cartService;

  CartStatus _status = CartStatus.initial;
  Cart? _cart;
  String? _errorMessage;

  // Getters
  CartStatus get status => _status;
  Cart? get cart => _cart;
  String? get errorMessage => _errorMessage;
  List<CartItem> get items => _cart?.items ?? [];
  int get itemCount => _cart?.totalItems ?? 0;
  double get subtotal => _cart?.subtotal ?? 0.0;
  double get total => _calculateTotal();
  double get shipping => _calculateShipping();
  double get tax => _calculateTax();
  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;
  bool get isLoading => _status == CartStatus.loading || _status == CartStatus.updating;
  bool get qualifiesForFreeShipping => _cart != null && _cart!.subtotal >= 100.0;
  double get amountForFreeShipping => _getAmountForFreeShipping();

  // Initialize cart provider
  Future<void> init() async {
    await _loadCart();
  }

  // Load cart from storage
  Future<void> _loadCart() async {
    _setStatus(CartStatus.loading);
    _clearError();

    try {
      _cart = await _cartService.getCurrentCart();
      _setStatus(CartStatus.loaded);
    } catch (e) {
      _setError('Failed to load cart: ${e.toString()}');
      _setStatus(CartStatus.error);
    }
  }

  // Add item to cart
  Future<bool> addToCart(Product product, {int quantity = 1, ProductVariant? variant}) async {
    _setStatus(CartStatus.updating);
    _clearError();

    try {
      _cart = await _cartService.addToCart(product, quantity: quantity, variant: variant);
      _setStatus(CartStatus.loaded);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to add item to cart: ${e.toString()}');
      _setStatus(CartStatus.error);
      return false;
    }
  }

  // Update item quantity
  Future<bool> updateQuantity(String uniqueId, int quantity) async {
    _setStatus(CartStatus.updating);
    _clearError();

    try {
      _cart = await _cartService.updateQuantity(uniqueId, quantity);
      _setStatus(CartStatus.loaded);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update quantity: ${e.toString()}');
      _setStatus(CartStatus.error);
      return false;
    }
  }

  // Remove item from cart
  Future<bool> removeFromCart(String uniqueId) async {
    _setStatus(CartStatus.updating);
    _clearError();

    try {
      _cart = await _cartService.removeFromCart(uniqueId);
      _setStatus(CartStatus.loaded);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to remove item: ${e.toString()}');
      _setStatus(CartStatus.error);
      return false;
    }
  }

  // Clear entire cart
  Future<bool> clearCart() async {
    _setStatus(CartStatus.updating);
    _clearError();

    try {
      await _cartService.clearCart();
      _cart = await _cartService.getCurrentCart();
      _setStatus(CartStatus.loaded);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to clear cart: ${e.toString()}');
      _setStatus(CartStatus.error);
      return false;
    }
  }

  // Check if product is in cart
  Future<bool> isInCart(int productId, {int? variantId}) async {
    try {
      return await _cartService.isInCart(productId, variantId: variantId);
    } catch (e) {
      debugPrint('Failed to check if product is in cart: $e');
      return false;
    }
  }

  // Get quantity of specific item
  Future<int> getItemQuantity(int productId, {int? variantId}) async {
    try {
      return await _cartService.getItemQuantity(productId, variantId: variantId);
    } catch (e) {
      debugPrint('Failed to get item quantity: $e');
      return 0;
    }
  }

  // Validate cart stock
  Future<List<String>> validateStock() async {
    try {
      return await _cartService.validateStock();
    } catch (e) {
      debugPrint('Failed to validate stock: $e');
      return [];
    }
  }

  // Sync cart with server (when logged in)
  Future<void> syncWithServer() async {
    try {
      await _cartService.syncWithServer();
      await _loadCart(); // Reload cart after sync
    } catch (e) {
      debugPrint('Failed to sync cart: $e');
    }
  }

  // Merge with customer cart
  Future<void> mergeWithCustomerCart(int customerId) async {
    _setStatus(CartStatus.updating);

    try {
      _cart = await _cartService.mergeWithCustomerCart(customerId);
      _setStatus(CartStatus.loaded);
      notifyListeners();
    } catch (e) {
      _setError('Failed to merge cart: ${e.toString()}');
      _setStatus(CartStatus.error);
    }
  }

  // Reset cart (for logout)
  Future<void> reset() async {
    try {
      await _cartService.reset();
      _cart = null;
      _setStatus(CartStatus.initial);
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to reset cart: $e');
    }
  }

  // Refresh cart
  Future<void> refresh() async {
    await _loadCart();
  }

  // Get cart for API
  Map<String, dynamic> getCartForApi() {
    return _cartService.getCartForApi();
  }

  // Get item count by product ID
  int getItemCountByProductId(int productId) {
    int count = 0;
    for (final item in items) {
      if (item.productId == productId) {
        count += item.quantity;
      }
    }
    return count;
  }

  // Get item by unique ID
  CartItem? getItemByUniqueId(String uniqueId) {
    try {
      return items.firstWhere((item) => item.uniqueId == uniqueId);
    } catch (e) {
      return null;
    }
  }

  // Get estimated delivery date
  DateTime getEstimatedDeliveryDate() {
    return _cartService.getEstimatedDeliveryDate();
  }

  // Get cart statistics
  CartStats getCartStats() {
    return _cartService.getCartStats();
  }

  // Clear error
  void clearError() {
    _clearError();
    notifyListeners();
  }

  // Set loading state manually
  void setLoading(bool loading) {
    if (loading) {
      _setStatus(CartStatus.loading);
    } else {
      _setStatus(CartStatus.loaded);
    }
  }

  // Private helper methods
  void _setStatus(CartStatus status) {
    _status = status;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  double _calculateTotal() {
    if (_cart == null) return 0.0;
    final subtotal = _cart!.subtotal;
    final shipping = _calculateShipping();
    final tax = _calculateTax();
    return subtotal + shipping + tax;
  }

  double _calculateShipping() {
    if (_cart == null) return 0.0;
    const freeShippingThreshold = 100.0;
    const standardShipping = 9.99;

    return _cart!.subtotal >= freeShippingThreshold ? 0.0 : standardShipping;
  }

  double _calculateTax() {
    if (_cart == null) return 0.0;
    const taxRate = 0.08;
    return _cart!.subtotal * taxRate;
  }

  double _getAmountForFreeShipping() {
    if (_cart == null) return 100.0;
    const freeShippingThreshold = 100.0;
    final needed = freeShippingThreshold - _cart!.subtotal;
    return needed > 0 ? needed : 0.0;
  }

  // Batch operations
  Future<bool> updateMultipleQuantities(Map<String, int> quantities) async {
    _setStatus(CartStatus.updating);
    _clearError();

    try {
      for (final entry in quantities.entries) {
        await _cartService.updateQuantity(entry.key, entry.value);
      }

      await _loadCart(); // Reload cart after all updates
      return true;
    } catch (e) {
      _setError('Failed to update quantities: ${e.toString()}');
      _setStatus(CartStatus.error);
      return false;
    }
  }

  // Export cart data
  Map<String, dynamic> exportCart() {
    return _cartService.exportCart();
  }

  // Get formatted totals
  String get formattedSubtotal => '\$${subtotal.toStringAsFixed(2)}';
  String get formattedShipping => shipping == 0.0 ? 'FREE' : '\$${shipping.toStringAsFixed(2)}';
  String get formattedTax => '\$${tax.toStringAsFixed(2)}';
  String get formattedTotal => '\$${total.toStringAsFixed(2)}';
  String get formattedItemCount => '$itemCount ${itemCount == 1 ? 'item' : 'items'}';

  // Get free shipping progress (0.0 to 1.0)
  double get freeShippingProgress {
    if (_cart == null) return 0.0;
    const freeShippingThreshold = 100.0;
    return (_cart!.subtotal / freeShippingThreshold).clamp(0.0, 1.0);
  }
}