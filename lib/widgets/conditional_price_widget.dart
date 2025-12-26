import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../config/app_theme.dart';
import '../utils/currency_formatter.dart';

/// Widget que muestra precios solo a usuarios autenticados
/// Para usuarios no autenticados, muestra un mensaje de login
class ConditionalPriceWidget extends StatelessWidget {
  final double price;
  final double? oldPrice;
  final TextStyle? priceStyle;
  final TextStyle? oldPriceStyle;
  final bool showLoginPrompt;
  final bool isCompact; // Para versiones más pequeñas en cards

  const ConditionalPriceWidget({
    Key? key,
    required this.price,
    this.oldPrice,
    this.priceStyle,
    this.oldPriceStyle,
    this.showLoginPrompt = true,
    this.isCompact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    // Si NO está autenticado, mostrar mensaje
    if (!authProvider.isAuthenticated) {
      return _buildLoginPrompt(context);
    }
    
    // Si está autenticado, mostrar precio
    return _buildPrice(context);
  }
  
  Widget _buildLoginPrompt(BuildContext context) {
    if (!showLoginPrompt) {
      return const SizedBox.shrink();
    }
    
    if (isCompact) {
      // Versión compacta para product cards
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.primaryBlack.withOpacity(0.05),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline,
              size: 12,
              color: AppTheme.primaryBlack.withOpacity(0.6),
            ),
            const SizedBox(width: 4),
            Text(
              'Iniciar sesión',
              style: TextStyle(
                fontSize: 10,
                color: AppTheme.primaryBlack.withOpacity(0.6),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }
    
    // Versión completa para product detail
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlack.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.primaryBlack.withOpacity(0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lock_outline,
            size: 18,
            color: AppTheme.primaryBlack.withOpacity(0.6),
          ),
          const SizedBox(width: 8),
          Text(
            'Inicia sesión para ver precios',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.primaryBlack.withOpacity(0.6),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPrice(BuildContext context) {
    final hasDiscount = oldPrice != null && oldPrice! > price;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        // Precio actual
        Text(
          CurrencyFormatter.formatEUR(price),
          style: priceStyle ?? const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryBlack,
          ),
        ),
        
        // Precio antiguo (si existe descuento)
        if (hasDiscount) ...[
          const SizedBox(width: 6),
          Text(
            CurrencyFormatter.formatEUR(oldPrice!),
            style: oldPriceStyle ?? TextStyle(
              fontSize: 11,
              decoration: TextDecoration.lineThrough,
              color: AppTheme.secondaryGrey,
            ),
          ),
        ],
      ],
    );
  }
}