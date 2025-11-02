import 'package:flutter/foundation.dart';
import '../models/customer.dart';
import '../models/address.dart';
import '../models/order.dart';
import '../services/auth_service.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = authService;

  AuthStatus _status = AuthStatus.initial;
  Customer? _user;
  String? _errorMessage;
  List<Address> _addresses = [];
  List<Order> _orders = [];

  // Getters
  AuthStatus get status => _status;
  Customer? get user => _user;
  String? get errorMessage => _errorMessage;
  List<Address> get addresses => _addresses;
  List<Order> get orders => _orders;
  bool get isAuthenticated => _status == AuthStatus authenticated && _user != null;
  bool get isLoading => _status == AuthStatus.loading;

  // Initialize auth provider
  Future<void> init() async {
    await _authService.init();
    _user = _authService.currentUser;
    _status = _authService.isAuthenticated ? AuthStatus.authenticated : AuthStatus.unauthenticated;
    notifyListeners();
  }

  // Login
  Future<bool> login(String email, String password, {bool rememberMe = false}) async {
    _setStatus(AuthStatus.loading);
    _clearError();

    try {
      final result = await _authService.login(email, password, rememberMe: rememberMe);

      if (result.success) {
        _user = result.data as Customer?;
        _setStatus(AuthStatus.authenticated);

        // Load user data
        await _loadUserData();

        return true;
      } else {
        _setError(result.message ?? 'Login failed');
        _setStatus(AuthStatus.error);
        return false;
      }
    } catch (e) {
      _setError('Login failed: ${e.toString()}');
      _setStatus(AuthStatus.error);
      return false;
    }
  }

  // Register
  Future<bool> register(RegisterRequest request) async {
    _setStatus(AuthStatus.loading);
    _clearError();

    try {
      final result = await _authService.register(request);

      if (result.success) {
        _user = result.data as Customer?;
        _setStatus(AuthStatus.authenticated);

        // Load user data
        await _loadUserData();

        return true;
      } else {
        _setError(result.message ?? 'Registration failed');
        _setStatus(AuthStatus.error);
        return false;
      }
    } catch (e) {
      _setError('Registration failed: ${e.toString()}');
      _setStatus(AuthStatus.error);
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await _authService.logout();
      _user = null;
      _addresses.clear();
      _orders.clear();
      _setStatus(AuthStatus.unauthenticated);
      _clearError();
    } catch (e) {
      _setError('Logout failed: ${e.toString()}');
    }
  }

  // Update profile
  Future<bool> updateProfile(Customer customer) async {
    _clearError();

    try {
      final result = await _authService.updateProfile(customer);

      if (result.success) {
        _user = result.data as Customer?;
        notifyListeners();
        return true;
      } else {
        _setError(result.message ?? 'Profile update failed');
        return false;
      }
    } catch (e) {
      _setError('Profile update failed: ${e.toString()}');
      return false;
    }
  }

  // Change password
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    _clearError();

    try {
      final result = await _authService.changePassword(currentPassword, newPassword);

      if (result.success) {
        return true;
      } else {
        _setError(result.message ?? 'Password change failed');
        return false;
      }
    } catch (e) {
      _setError('Password change failed: ${e.toString()}');
      return false;
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    _clearError();

    try {
      final result = await _authService.resetPassword(email);

      if (result.success) {
        return true;
      } else {
        _setError(result.message ?? 'Password reset failed');
        return false;
      }
    } catch (e) {
      _setError('Password reset failed: ${e.toString()}');
      return false;
    }
  }

  // Refresh user data
  Future<void> refreshUserData() async {
    if (_user == null) return;

    try {
      final result = await _authService.refreshUserData();

      if (result.success) {
        _user = result.data as Customer?;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to refresh user data: $e');
    }
  }

  // Validate session
  Future<bool> validateSession() async {
    try {
      final isValid = await _authService.validateSession();

      if (!isValid && _status == AuthStatus.authenticated) {
        // Session expired
        _user = null;
        _addresses.clear();
        _orders.clear();
        _setStatus(AuthStatus.unauthenticated);
      }

      return isValid;
    } catch (e) {
      debugPrint('Session validation failed: $e');
      return false;
    }
  }

  // Load user addresses
  Future<void> loadAddresses() async {
    if (_user == null) return;

    try {
      _addresses = await _authService.getUserAddresses();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load addresses: $e');
    }
  }

  // Add address
  Future<bool> addAddress(Address address) async {
    _clearError();

    try {
      final result = await _authService.addAddress(address);

      if (result.success) {
        await loadAddresses(); // Reload addresses
        return true;
      } else {
        _setError(result.message ?? 'Failed to add address');
        return false;
      }
    } catch (e) {
      _setError('Failed to add address: ${e.toString()}');
      return false;
    }
  }

  // Update address
  Future<bool> updateAddress(int addressId, Address address) async {
    _clearError();

    try {
      final result = await _authService.updateAddress(addressId, address);

      if (result.success) {
        await loadAddresses(); // Reload addresses
        return true;
      } else {
        _setError(result.message ?? 'Failed to update address');
        return false;
      }
    } catch (e) {
      _setError('Failed to update address: ${e.toString()}');
      return false;
    }
  }

  // Delete address
  Future<bool> deleteAddress(int addressId) async {
    _clearError();

    try {
      final result = await _authService.deleteAddress(addressId);

      if (result.success) {
        await loadAddresses(); // Reload addresses
        return true;
      } else {
        _setError(result.message ?? 'Failed to delete address');
        return false;
      }
    } catch (e) {
      _setError('Failed to delete address: ${e.toString()}');
      return false;
    }
  }

  // Load user orders
  Future<void> loadOrders({int page = 1}) async {
    if (_user == null) return;

    try {
      if (page == 1) {
        _orders = await _authService.getUserOrders(page: page);
      } else {
        // Append more orders for pagination
        final newOrders = await _authService.getUserOrders(page: page);
        _orders.addAll(newOrders);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load orders: $e');
    }
  }

  // Check if email is registered
  Future<bool> isEmailRegistered(String email) async {
    try {
      return await _authService.isEmailRegistered(email);
    } catch (e) {
      debugPrint('Failed to check email registration: $e');
      return false;
    }
  }

  // Clear error
  void clearError() {
    _clearError();
    notifyListeners();
  }

  // Set loading state manually
  void setLoading(bool loading) {
    if (loading) {
      _setStatus(AuthStatus.loading);
    } else if (_user != null) {
      _setStatus(AuthStatus.authenticated);
    } else {
      _setStatus(AuthStatus.unauthenticated);
    }
  }

  // Private helper methods
  void _setStatus(AuthStatus status) {
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

  Future<void> _loadUserData() async {
    if (_user == null) return;

    // Load addresses and orders in parallel
    await Future.wait([
      loadAddresses(),
      loadOrders(),
    ]);
  }

  // Get user display name
  String get userDisplayName => _user?.fullName ?? 'Guest';

  // Get user email
  String get userEmail => _user?.email ?? '';

  // Check if user has addresses
  bool get hasAddresses => _addresses.isNotEmpty;

  // Check if user has orders
  bool get hasOrders => _orders.isNotEmpty;

  // Get primary address (first address)
  Address? get primaryAddress => _addresses.isNotEmpty ? _addresses.first : null;

  // Get order count
  int get orderCount => _orders.length;
}