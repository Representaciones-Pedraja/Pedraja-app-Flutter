import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/cart_item_widget.dart';
import '../../widgets/empty_state_widget.dart';
import '../../config/app_theme.dart';
import '../checkout/enhanced_checkout_screen.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/currency_formatter.dart';

/// Modern Cart Screen with clean white minimal UI
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppTheme.pureWhite,
        title: Text(
          l10n?.cart ?? 'Carrito',
          style: const TextStyle(
            color: AppTheme.primaryBlack,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (authProvider.isAuthenticated)
            Consumer<CartProvider>(
              builder: (context, cart, child) {
                if (cart.isEmpty) return const SizedBox.shrink();
                return TextButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        ),
                        title: Text(l10n?.clearCart ?? 'Vaciar carrito'),
                        content: const Text('¿Estás seguro de que quieres vaciar el carrito?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(l10n?.cancel ?? 'Cancelar'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              cart.clearCart();
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.errorRed,
                            ),
                            child: Text(l10n?.delete ?? 'Eliminar'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Text(l10n?.clearCart ?? 'Vaciar'),
                );
              },
            ),
        ],
      ),
      body: _buildBody(context, authProvider, l10n),
    );
  }

  Widget _buildBody(BuildContext context, AuthProvider authProvider, AppLocalizations? l10n) {
    // Si NO está autenticado, mostrar pantalla de login
    if (!authProvider.isAuthenticated) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlack.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_outline,
                  size: 64,
                  color: AppTheme.primaryBlack.withOpacity(0.3),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Inicia sesión para ver tu carrito',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlack,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Necesitas estar registrado para añadir productos al carrito y realizar compras',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.secondaryGrey,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/login');
                  },
                  icon: const Icon(Icons.login, size: 20),
                  label: const Text(
                    'Iniciar sesión',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlack,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/register');
                },
                child: Text(
                  '¿No tienes cuenta? Regístrate',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.accentBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Si está autenticado, mostrar carrito normal
    return Consumer<CartProvider>(
      builder: (context, cart, child) {
        if (cart.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.shopping_cart_outlined,
            title: l10n?.cartEmpty ?? 'Tu carrito está vacío',
            message: 'Añade productos para empezar',
            onAction: () {
              // Navigate to home - handled by bottom nav
            },
            actionLabel: l10n?.startShopping ?? 'Empezar a comprar',
          );
        }

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(AppTheme.spacing2),
                itemCount: cart.items.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppTheme.spacing2),
                    child: CartItemWidget(item: cart.items[index]),
                  );
                },
              ),
            ),

            // Cart Summary Card
            Container(
              padding: const EdgeInsets.all(AppTheme.spacing2),
              decoration: BoxDecoration(
                color: AppTheme.pureWhite,
                boxShadow: AppTheme.mediumShadow,
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    // Subtotal
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${l10n?.subtotal ?? 'Subtotal'}:',
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppTheme.secondaryGrey,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.formatEUR(cart.totalAmount),
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppTheme.secondaryGrey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacing1),

                    // Shipping
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Envío:',
                          style: TextStyle(
                            fontSize: 15,
                            color: AppTheme.secondaryGrey,
                          ),
                        ),
                        Text(
                          l10n?.free ?? 'Gratis',
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppTheme.successGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    const Divider(height: AppTheme.spacing3),

                    // Total
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${l10n?.total ?? 'Total'} (${cart.itemCount} ${l10n?.items ?? 'artículos'}):',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryBlack,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.formatEUR(cart.totalAmount),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryBlack,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppTheme.spacing2),

                    // Checkout Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EnhancedCheckoutScreen(),
                            ),
                          );
                        },
                        child: Text(
                          l10n?.proceedToCheckout ?? 'Proceder al pago',
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
            ),
          ],
        );
      },
    );
  }
}