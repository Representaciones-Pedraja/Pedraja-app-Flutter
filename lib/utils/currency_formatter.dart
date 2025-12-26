import 'package:intl/intl.dart';

class CurrencyFormatter {
  // Tunisian Dinar currency format
  static const String currencyCode = 'EUR';
  static const String currencySymbol = 'EUR';

  /// Format amount in EUR (Tunisian Dinar)
  /// Example: 1234.56 -> "1 234,560 EUR"
  static String formatEUR(double amount) {
    final formatter = NumberFormat('#,##0.000', 'fr_FR');
    String formattedAmount = formatter.format(amount);
    // Replace default space with non-breaking space for better display
    formattedAmount = formattedAmount.replaceAll(' ', ' ');
    return '$formattedAmount $currencySymbol';
  }

  /// Format amount in EUR with custom decimal places
  static String formatEURWithDecimals(double amount, int decimalPlaces) {
    final pattern = '#,##0.${'0' * decimalPlaces}';
    final formatter = NumberFormat(pattern, 'fr_FR');
    String formattedAmount = formatter.format(amount);
    formattedAmount = formattedAmount.replaceAll(' ', ' ');
    return '$formattedAmount $currencySymbol';
  }

  /// Format amount in EUR without decimals
  /// Example: 1234.56 -> "1 235 EUR"
  static String formatEURWhole(double amount) {
    final formatter = NumberFormat('#,##0', 'fr_FR');
    String formattedAmount = formatter.format(amount.round());
    formattedAmount = formattedAmount.replaceAll(' ', ' ');
    return '$formattedAmount $currencySymbol';
  }

  /// Parse formatted EUR string to double
  static double parseEUR(String formattedAmount) {
    // Remove currency symbol and spaces
    String cleaned = formattedAmount
        .replaceAll(currencySymbol, '')
        .replaceAll(' ', '')
        .replaceAll(' ', '')
        .trim();

    // Replace comma with dot for parsing
    cleaned = cleaned.replaceAll(',', '.');

    return double.tryParse(cleaned) ?? 0.0;
  }

  /// Get currency symbol
  static String getCurrencySymbol() {
    return currencySymbol;
  }

  /// Get currency code
  static String getCurrencyCode() {
    return currencyCode;
  }

  /// Format compact amount (e.g., 1.2K, 1.5M)
  static String formatCompactEUR(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M $currencySymbol';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K $currencySymbol';
    } else {
      return formatEUR(amount);
    }
  }
}
