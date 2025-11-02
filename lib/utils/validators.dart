class Validators {
  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  // Password validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }

    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }

    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }

    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }

    return null;
  }

  // Simple password validation (for login)
  static String? validateSimplePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 1) {
      return 'Password cannot be empty';
    }

    return null;
  }

  // Name validation
  static String? validateName(String? value, {String fieldName = 'Name'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }

    if (value.trim().length < 2) {
      return '$fieldName must be at least 2 characters long';
    }

    if (!RegExp(r'^[a-zA-Z\s\-\'\.]+$').hasMatch(value)) {
      return '$fieldName can only contain letters, spaces, hyphens, and apostrophes';
    }

    return null;
  }

  // First name validation
  static String? validateFirstName(String? value) {
    return validateName(value, fieldName: 'First name');
  }

  // Last name validation
  static String? validateLastName(String? value) {
    return validateName(value, fieldName: 'Last name');
  }

  // Phone validation
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }

    // Remove all non-digit characters for validation
    final digitsOnly = value.replaceAll(RegExp(r'[^0-9+]'), '');

    if (digitsOnly.length < 10) {
      return 'Phone number must be at least 10 digits';
    }

    if (!RegExp(r'^[+]?[0-9]+$').hasMatch(digitsOnly)) {
      return 'Please enter a valid phone number';
    }

    return null;
  }

  // Optional phone validation
  static String? validateOptionalPhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Phone is optional
    }

    return validatePhone(value);
  }

  // Address validation
  static String? validateAddress(String? value, {String fieldName = 'Address'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }

    if (value.trim().length < 5) {
      return '$fieldName must be at least 5 characters long';
    }

    return null;
  }

  // Address line 1 validation
  static String? validateAddress1(String? value) {
    return validateAddress(value, fieldName: 'Address line 1');
  }

  // Optional address line 2 validation
  static String? validateAddress2(String? value) {
    if (value != null && value.trim().isNotEmpty && value.trim().length < 3) {
      return 'Address line 2 must be at least 3 characters long';
    }
    return null;
  }

  // City validation
  static String? validateCity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'City is required';
    }

    if (value.trim().length < 2) {
      return 'City must be at least 2 characters long';
    }

    if (!RegExp(r'^[a-zA-Z\s\-\.]+$').hasMatch(value)) {
      return 'City can only contain letters, spaces, hyphens, and periods';
    }

    return null;
  }

  // Postal code validation
  static String? validatePostalCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Postal code is required';
    }

    // Support multiple formats
    // US: 5 digits or 5-4 digits
    // UK: Letter-letter-digit-digit letter-letter
    // Canadian: Letter-digit-letter digit-letter-digit
    // General: 3-10 alphanumeric characters
    final postalCodeRegex = RegExp(
      r'^[a-zA-Z0-9\s\-]{3,10}$',
    );

    if (!postalCodeRegex.hasMatch(value.trim())) {
      return 'Please enter a valid postal code';
    }

    return null;
  }

  // Required field validation
  static String? validateRequired(String? value, {String fieldName = 'Field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }

    return null;
  }

  // Card number validation
  static String? validateCardNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Card number is required';
    }

    // Remove spaces and dashes
    final cleanValue = value.replaceAll(RegExp(r'[\s\-]'), '');

    if (cleanValue.length < 13 || cleanValue.length > 19) {
      return 'Card number must be between 13 and 19 digits';
    }

    if (!RegExp(r'^[0-9]+$').hasMatch(cleanValue)) {
      return 'Card number can only contain digits';
    }

    // Luhn algorithm check
    if (!_isValidLuhn(cleanValue)) {
      return 'Please enter a valid card number';
    }

    return null;
  }

  // Luhn algorithm for card validation
  static bool _isValidLuhn(String cardNumber) {
    int sum = 0;
    bool alternate = false;

    for (int i = cardNumber.length - 1; i >= 0; i--) {
      int digit = int.parse(cardNumber[i]);

      if (alternate) {
        digit *= 2;
        if (digit > 9) {
          digit = (digit % 10) + 1;
        }
      }

      sum += digit;
      alternate = !alternate;
    }

    return (sum % 10) == 0;
  }

  // CVV validation
  static String? validateCVV(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'CVV is required';
    }

    if (!RegExp(r'^[0-9]{3,4}$').hasMatch(value.trim())) {
      return 'CVV must be 3 or 4 digits';
    }

    return null;
  }

  // Expiry date validation (MM/YY format)
  static String? validateExpiryDate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Expiry date is required';
    }

    // Remove spaces and slashes
    final cleanValue = value.replaceAll(RegExp(r'[\s\/]'), '');

    if (cleanValue.length != 4) {
      return 'Expiry date must be in MM/YY format';
    }

    if (!RegExp(r'^[0-9]+$').hasMatch(cleanValue)) {
      return 'Expiry date can only contain digits';
    }

    final month = int.parse(cleanValue.substring(0, 2));
    final year = int.parse(cleanValue.substring(2, 4));

    if (month < 1 || month > 12) {
      return 'Month must be between 01 and 12';
    }

    final currentYear = DateTime.now().year % 100;
    final currentMonth = DateTime.now().month;

    if (year < currentYear || (year == currentYear && month < currentMonth)) {
      return 'Card has expired';
    }

    return null;
  }

  // Quantity validation (for cart)
  static String? validateQuantity(String? value, {int maxQuantity = 99}) {
    if (value == null || value.trim().isEmpty) {
      return 'Quantity is required';
    }

    final quantity = int.tryParse(value);
    if (quantity == null) {
      return 'Please enter a valid quantity';
    }

    if (quantity < 1) {
      return 'Quantity must be at least 1';
    }

    if (quantity > maxQuantity) {
      return 'Quantity cannot exceed $maxQuantity';
    }

    return null;
  }

  // Price validation
  static String? validatePrice(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Price is required';
    }

    final price = double.tryParse(value);
    if (price == null) {
      return 'Please enter a valid price';
    }

    if (price < 0) {
      return 'Price cannot be negative';
    }

    return null;
  }

  // URL validation
  static String? validateURL(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'URL is required';
    }

    final urlRegex = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
    );

    if (!urlRegex.hasMatch(value)) {
      return 'Please enter a valid URL';
    }

    return null;
  }

  // Search query validation
  static String? validateSearchQuery(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a search term';
    }

    if (value.trim().length < 2) {
      return 'Search term must be at least 2 characters long';
    }

    return null;
  }

  // Birthday validation (YYYY-MM-DD format)
  static String? validateBirthday(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Birthday is optional
    }

    try {
      final date = DateTime.parse(value);
      final now = DateTime.now();
      final age = now.year - date.year;

      if (age < 13) {
        return 'You must be at least 13 years old';
      }

      if (age > 120) {
        return 'Please enter a valid birth date';
      }

      if (date.isAfter(now)) {
        return 'Birth date cannot be in the future';
      }
    } catch (e) {
      return 'Please enter a valid date (YYYY-MM-DD)';
    }

    return null;
  }
}