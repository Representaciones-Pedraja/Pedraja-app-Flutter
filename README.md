# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Flutter-based mobile e-commerce application integrating with PrestaShop REST API (XML format). Uses Provider for state management, supports English/French localization, targets Android primarily with iOS compatibility.

**Tech Stack**: Flutter 3.0+, Dart 3.9+, Provider 6.1.1, HTTP + XML parsing

---

## Essential Commands

### Development
```bash
# Install dependencies
flutter pub get

# Run app in debug mode
flutter run

# Run on specific device
flutter run -d <device-id>

# List available devices
flutter devices

# Enable debug mode (edit .env)
DEBUG_MODE=true
```

### Code Quality
```bash
# Run linter
flutter analyze

# Format code
flutter format lib/

# Check for outdated dependencies
flutter pub outdated
```

### Build & Release
```bash
# Clean build artifacts
flutter clean

# Build APK (release)
flutter build apk --release

# Build App Bundle (for Play Store)
flutter build appbundle --release

# Build for specific flavor
flutter build apk --release --flavor production
```

### Environment Setup
Required `.env` file in project root:
```
PRESTASHOP_BASE_URL=https://your-shop.prestashop.com/
PRESTASHOP_API_KEY=your-api-key-here
DEBUG_MODE=false
```

---

## Project Structure

```
prestashop-mobile-app/
├── lib/                          # Main application source code
│   ├── main.dart                # App entry point and bottom nav setup
│   ├── config/                  # Configuration files
│   │   ├── api_config.dart      # PrestaShop API endpoints & settings
│   │   └── app_theme.dart       # UI theme and design system
│   ├── models/                  # Data models (19 files)
│   │   ├── product.dart         # Product data model
│   │   ├── product_detail.dart  # Detailed product info
│   │   ├── cart_item.dart       # Shopping cart item
│   │   ├── order.dart           # Order and order item models
│   │   ├── customer.dart        # Customer/user model
│   │   ├── address.dart         # Address model
│   │   ├── carrier.dart         # Shipping carrier
│   │   ├── category.dart        # Product category
│   │   ├── cart_rule.dart       # Discount rules/vouchers
│   │   ├── combination.dart     # Product variants
│   │   ├── attribute.dart       # Product attributes
│   │   ├── feature.dart         # Product features
│   │   ├── specific_price.dart  # Special pricing
│   │   └── more...              # (country, manufacturer, etc.)
│   ├── services/                # Business logic & API calls (20 files)
│   │   ├── api_service.dart     # Core HTTP client + XML parsing
│   │   ├── product_service.dart # Product CRUD & filtering
│   │   ├── category_service.dart
│   │   ├── order_service.dart   # Order creation & management
│   │   ├── customer_service.dart# User authentication & profile
│   │   ├── cart_rule_service.dart# Vouchers & discounts
│   │   ├── carrier_service.dart # Shipping options
│   │   └── more...              # (filter, combination, feature, etc.)
│   ├── providers/               # State management (9 files)
│   │   ├── product_provider.dart# Product listing & filtering state
│   │   ├── category_provider.dart
│   │   ├── cart_provider.dart   # Shopping cart state + local storage
│   │   ├── order_provider.dart  # Order management state
│   │   ├── auth_provider.dart   # Authentication & user session
│   │   ├── wishlist_provider.dart
│   │   ├── address_provider.dart
│   │   ├── carrier_provider.dart
│   │   └── location_provider.dart
│   ├── screens/                 # UI screens (11 feature folders)
│   │   ├── home/                # Homepage with products and brands
│   │   ├── catalog/             # Product listing
│   │   ├── product/             # Product detail view
│   │   ├── category/            # Categories browser
│   │   ├── cart/                # Shopping cart
│   │   ├── checkout/            # Checkout flow (payment, addresses)
│   │   ├── wishlist/            # Favorites list
│   │   ├── profile/             # User profile, orders, account
│   │   ├── address/             # Address management (list & form)
│   │   ├── search/              # Product search
│   │   └── tracking/            # Order tracking
│   ├── widgets/                 # Reusable UI components (14 files)
│   │   ├── custom_search_bar.dart
│   │   ├── product_card.dart    # Product display card
│   │   ├── category_chip.dart   # Category selector chip
│   │   ├── cart_item_widget.dart# Cart item display
│   │   ├── loading_widget.dart  # Loading indicator
│   │   ├── error_widget.dart    # Error display
│   │   ├── empty_state_widget.dart
│   │   ├── hero_banner.dart     # Hero image banner
│   │   ├── brand_card.dart      # Brand display
│   │   ├── section_header.dart  # Section title with "View All"
│   │   ├── cart_badge.dart      # Cart count badge
│   │   ├── filter_bottom_sheet.dart# Filter interface
│   │   └── more...
│   ├── utils/                   # Helper utilities (4 files)
│   │   ├── cache_manager.dart   # Image caching
│   │   ├── currency_formatter.dart# Price formatting
│   │   ├── price_calculator.dart# Price computation
│   │   └── language_helper.dart # Multi-language value extraction
│   ├── l10n/                    # Localization
│   │   ├── app_localizations.dart# Localization delegate & loader
│   │   ├── app_en.arb           # English translations
│   │   └── app_fr.arb           # French translations
│
├── android/                      # Android native code
│   ├── app/
│   │   ├── build.gradle.kts     # Android build config
│   │   └── src/
│   │       ├── main/
│   │       ├── debug/
│   │       ├── profile/
│   │       └── release/
│   └── gradle/
│
├── assets/                       # App assets
│   ├── images/                  # Product images, banners
│   ├── icons/                   # App icons
│   └── l10n/                    # Translation files (.arb)
│
├── pubspec.yaml                 # Flutter dependencies
├── pubspec.lock                 # Locked dependency versions
├── analysis_options.yaml        # Dart linter rules
├── devtools_options.yaml        # DevTools config
└── .env                         # Environment variables (ignored)
```

---

## Key Technologies & Dependencies

### Core Framework
- **flutter**: 3.0+ SDK
- **flutter_localizations**: Internationalization (i18n)

### State Management
- **provider**: 6.1.1 - ChangeNotifier-based state management with MultiProvider

### Networking & API
- **http**: 1.1.0 - HTTP client for PrestaShop API calls
- **xml**: 6.5.0 - XML parsing for PrestaShop XML responses
- **flutter_dotenv**: 5.1.0 - Environment variables (.env support)

### Local Storage
- **shared_preferences**: 2.2.2 - Key-value storage (cart, preferences)
- **flutter_secure_storage**: 9.0.0 - Secure storage (auth tokens, sensitive data)

### UI & UX
- **cached_network_image**: 3.3.1 - Image caching and display
- **flutter_spinkit**: 5.2.0 - Loading spinners/skeletons
- **shimmer**: 3.0.0 - Shimmer loading effects
- **pull_to_refresh**: 2.0.0 - Pull-to-refresh gesture
- **cupertino_icons**: 1.0.6 - iOS-style icons
- **intl**: 0.20.2 - Date/number formatting

### Utilities
- **email_validator**: 2.1.17 - Email validation
- **flutter_lints**: 3.0.0 - Code quality & style (dev)

---

## Architecture Patterns

### 1. State Management with Provider
All state is managed using `Provider` with `ChangeNotifier`:

```dart
// provider_file.dart
class CartProvider with ChangeNotifier {
  List<CartItem> _items = [];
  
  List<CartItem> get items => _items;
  
  void addItem(CartItem item) {
    _items.add(item);
    notifyListeners(); // Triggers UI rebuild
  }
}

// Consumed in widgets
Consumer<CartProvider>(
  builder: (context, cart, _) => Text('${cart.items.length} items')
)
```

**All 9 Providers**:
- `ProductProvider` - Product listing, filtering, search
- `CategoryProvider` - Categories and subcategories
- `CartProvider` - Shopping cart, persisted to SharedPreferences
- `OrderProvider` - Order history and order management
- `AuthProvider` - User authentication, session (secure storage)
- `WishlistProvider` - Favorites/wishlist
- `AddressProvider` - User addresses
- `CarrierProvider` - Shipping options
- `LocationProvider` - Location/country data

### 2. Service Layer Architecture
Services encapsulate API calls and business logic:

```dart
class ProductService {
  final ApiService _apiService;
  
  Future<List<Product>> getProducts({...}) async {
    // Handles pagination, filtering, sorting
    // Returns parsed Product objects
  }
}
```

**Service Responsibilities**:
- API communication via `ApiService`
- Data transformation (JSON/XML → Dart models)
- Caching logic
- Error handling

### 3. API Integration Pattern

**XML Format**: PrestaShop API returns XML (configured in `ApiConfig.outputFormat`)

**HTTP Headers**:
```dart
Map<String, String> get _headers => {
  'Authorization': 'Basic ${base64Encode(utf8.encode('$apiKey:'))}',
  'Content-Type': 'application/xml',
  'Accept': 'application/xml',
};
```

**Response Parsing**:
- XML → Map conversion in `ApiService._parseXmlResponse()`
- Handles language arrays: `{ 'language': [{'id': '1', 'value': 'name'}, ...] }`
- Models parse Maps via `fromJson()` factories

**Error Handling**:
```dart
class ApiException implements Exception {
  final String message;
  ApiException(this.message); // Thrown for all API errors
}
```

### 4. Data Model Pattern

All models follow a consistent pattern:

```dart
class Product {
  final String id;
  final String name;
  // ... fields
  
  // JSON parsing with null/type safety
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id']?.toString() ?? '',
      name: LanguageHelper.extractValueOrEmpty(json['name']),
      // Handles: strings, numbers, nulls, language arrays
    );
  }
  
  // Serialization for API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      // ... PrestaShop field names (snake_case)
    };
  }
  
  // Copy constructor for immutability
  Product copyWith({String? id, String? name, ...}) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }
}
```

---

## Configuration & Environment

### API Configuration (lib/config/api_config.dart)
```dart
class ApiConfig {
  static String get baseUrl => dotenv.env['PRESTASHOP_BASE_URL'] ?? '';
  static String get apiKey => dotenv.env['PRESTASHOP_API_KEY'] ?? '';
  static bool get debugMode => dotenv.env['DEBUG_MODE'] == 'true';
  
  // Endpoints
  static const String productsEndpoint = 'api/products';
  static const String ordersEndpoint = 'api/orders';
  // ... 20+ endpoints defined
}
```

### Environment Variables (.env)
```
PRESTASHOP_BASE_URL=https://your-shop.prestashop.com/
PRESTASHOP_API_KEY=your-api-key-here
DEBUG_MODE=false
```

### App Theme (lib/config/app_theme.dart)
**Design System**:
- **Colors**: primaryBlack (#1A1A1A), white backgrounds, soft greys
- **Spacing**: 8px increments (spacing1-5: 8, 16, 24, 32, 40)
- **Border Radius**: Small (8), Medium (12), Large (16), XLarge (24)
- **Shadows**: Soft, Medium, Large with 0.06-0.1 opacity

```dart
class AppTheme {
  static const Color primaryBlack = Color(0xFF1A1A1A);
  static const Color backgroundWhite = Color(0xFFFAFAFA);
  static const double spacing2 = 16.0;
  static const double radiusMedium = 12.0;
  
  static List<BoxShadow> get softShadow => [
    BoxShadow(color: Colors.black.withOpacity(0.06), ...)
  ];
}
```

---

## Common Conventions & Patterns

### Naming Conventions
- **Files**: snake_case (e.g., `product_service.dart`)
- **Classes**: PascalCase (e.g., `ProductProvider`)
- **Methods/Variables**: camelCase (e.g., `getProducts()`)
- **Getters**: nouns (e.g., `get items => _items`)
- **Setters**: verb phrase (e.g., `set isLoading(bool value)`)

### Async/Await Patterns
```dart
Future<void> fetchProducts() async {
  _isLoading = true;
  try {
    _products = await _service.getProducts();
    _error = null;
  } catch (e) {
    _error = e.toString();
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}
```

### Widget Building Patterns

**Provider Consumption**:
```dart
// Read-only (Consumer)
Consumer<ProductProvider>(
  builder: (context, provider, child) => ...
)

// Listen to changes (Selector)
Selector<ProductProvider, List<Product>>(
  selector: (_, provider) => provider.products,
  builder: (context, products, _) => ...
)

// Get without listening
Provider.of<ProductProvider>(context, listen: false)
```

**Screen Structure**:
```dart
class MyScreen extends StatefulWidget {
  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SomeProvider>(context, listen: false).fetch();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      body: Consumer<SomeProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) return LoadingWidget(...);
          if (provider.hasError) return ErrorDisplayWidget(...);
          return ... // Content
        }
      )
    );
  }
}
```

### Local Storage Patterns

**Cart (SharedPreferences)**:
```dart
static const String _cartKey = 'cart_items';

Future<void> loadCart() async {
  final prefs = await SharedPreferences.getInstance();
  final cartData = prefs.getString(_cartKey);
  if (cartData != null) {
    _items = jsonDecode(cartData).map((item) => CartItem.fromJson(item)).toList();
  }
}

Future<void> _saveCart() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_cartKey, jsonEncode(_items.map((item) => item.toJson()).toList()));
}
```

**Auth Token (Secure Storage)**:
```dart
final _secureStorage = const FlutterSecureStorage();
static const String _customerKey = 'customer_data';

Future<void> saveCustomer(Customer customer) async {
  await _secureStorage.write(
    key: _customerKey,
    value: jsonEncode(customer.toJson()),
  );
}
```

---

## API Integration Details

### XML Request Format
```dart
String _mapToXml(Map<String, dynamic> data) {
  final builder = xml.XmlBuilder();
  builder.processing('xml', 'version="1.0" encoding="UTF-8"');
  
  builder.element('prestashop', nest: () {
    _buildXmlFromMap(builder, data);
  });
  
  return builder.buildDocument().toXmlString();
}
```

**Example POST Data**:
```dart
{
  'customer': {
    'firstname': 'John',
    'lastname': 'Doe',
    'email': 'john@example.com',
    'passwd': 'password123',
  }
}
```

### XML Response Parsing
Handles various PrestaShop XML patterns:
1. **Root element wrapping**: `<prestashop><products>...</products></prestashop>`
2. **Language arrays**: Elements with `id` attributes become arrays
3. **List detection**: Multiple children with same name become lists
4. **Attributes**: XML attributes preserved in result maps

### Query Parameters
```dart
final queryParams = <String, String>{
  'display': 'full',              // Full details
  'limit': '0,20',                // offset,limit
  'filter[id_category_default]': '5',
  'filter[active]': '1',
  'sort': '[price_ASC]',
};
```

### Pagination
Products support infinite scroll:
- `offset`: Starting position
- `limit`: Number per page
- Default page size: 20 items

---

## Localization System

### Supported Languages
- English (en)
- French (fr)

### ARB File Format
```json
// assets/l10n/app_en.arb
{
  "@@locale": "en",
  "appTitle": "PrestaShop Mobile",
  "home": "Home",
  // ... 100+ keys
}
```

### Usage in Code
```dart
final l10n = AppLocalizations.of(context);
Text(l10n?.home ?? 'Home')

// Or directly
String value = l10n?.translate('home') ?? 'Home';
```

### Locale Setup
```dart
MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('fr', ''), // Default French
)
```

---

## Key Features by Screen

### Home Screen
- Hero banner with featured products
- Category chips for filtering
- Brand carousel
- "Trending Today", "New Arrivals" sections
- Pull-to-refresh
- Search bar integration

### Product Detail
- Multi-image gallery
- Price, discount %, stock status
- Product attributes/variants (combinations)
- Features and specifications
- Add to cart, add to wishlist
- Related products

### Cart
- Swipe to delete items
- Quantity adjustment
- Subtotal calculation
- Discount/voucher section
- Shipping calculator (carrier options)
- Proceed to checkout

### Checkout
- **Address Selection**: List of saved addresses or new address form
- **Shipping**: Carrier selection with price calculation
- **Payment**: Payment method selection (UI framework ready)
- **Order Confirmation**: Order summary and reference

### Profile/Account
- Login/Register
- User profile edit
- Change password
- View order history
- Track order status

### Address Management
- List saved addresses
- Add new address
- Edit address
- Set default shipping/billing

---

## Error Handling & Debugging

### Debug Mode
Enabled via `.env`:
```
DEBUG_MODE=true
```

When enabled, `ApiService` prints:
- Request URLs and method
- Request/response bodies
- HTTP status codes

### Common Error Patterns
```dart
// Service-level error wrapping
try {
  final response = await _apiService.get(...);
  return Product.fromJson(response['product']);
} catch (e) {
  throw Exception('Failed to fetch product: $e');
}

// Provider error states
catch (e) {
  _error = e.toString();
  notifyListeners();
}

// UI error display
if (provider.hasError) {
  ErrorDisplayWidget(
    message: provider.error ?? 'An error occurred',
    onRetry: () => provider.fetch(),
  )
}
```

### ApiException
Custom exception for API errors:
```dart
class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  
  @override
  String toString() => message;
}
```

## Code Quality Standards

**Linting**: Uses `flutter_lints` package with additional rules:
- `prefer_const_constructors`, `prefer_const_literals_to_create_immutables`
- `prefer_single_quotes`
- `avoid_print` disabled (debug prints allowed)

**Testing**: No test suite currently implemented. Test infrastructure ready via `flutter_test` package.

---

## Important Implementation Notes

### Product Filtering & Search
- `ProductService` and `FilterService` handle complex filtering
- Supports: price range, category, manufacturer, stock status, sorting
- Uses `ProductFilterEngine` for advanced filtering

### Order Creation
Detailed `OrderService` handles:
- Creating orders with cart items
- Calculating totals (products, shipping, discounts)
- Managing order status transitions
- Persisting order metadata

### Cart Rules (Vouchers)
`CartRuleService` manages:
- Parsing voucher/discount rules
- Calculating discount amounts
- Checking free shipping conditions
- Multiple voucher application

### Combination (Variants)
- Products can have combinations (color, size, etc.)
- `CombinationService` and `CombinationModel` handle variants
- Stock tracking per combination

### Image Handling
- `CachedNetworkImage` for caching and performance
- Fallback to placeholder if image unavailable
- Multiple images per product supported

---

## Quick Reference for Common Tasks

### Add New Feature
1. Create model in `lib/models/`
2. Create service in `lib/services/` (extends `ApiService`)
3. Create provider in `lib/providers/` (extends `ChangeNotifier`)
4. Add provider to `MultiProvider` in `main.dart`
5. Create screen/widget in `lib/screens/`
6. Add localization keys to `.arb` files

### Make API Call
```dart
// In service
Future<List<Product>> getProducts() async {
  final response = await _apiService.get(
    ApiConfig.productsEndpoint,
    queryParameters: {'display': 'full'},
  );
  return (response['products'] as List)
    .map((p) => Product.fromJson(p))
    .toList();
}

// In provider
Future<void> fetchProducts() async {
  _isLoading = true;
  try {
    _products = await _service.getProducts();
  } catch (e) {
    _error = e.toString();
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}
```

### Update Localization
1. Add key to `app_en.arb`:
   ```json
   "newKey": "English text"
   ```
2. Add matching key to `app_fr.arb`:
   ```json
   "newKey": "Texte français"
   ```
3. Add getter to `AppLocalizations`:
   ```dart
   String get newKey => translate('newKey');
   ```
4. Use in widget:
   ```dart
   Text(l10n?.newKey ?? 'Default')
   ```

---

## Critical Implementation Details

### PrestaShop XML Parsing Quirks
The API returns XML with complex nested structures that require special handling:

1. **Language Arrays**: Multilingual fields like product names come as:
   ```json
   {"language": [{"id": "1", "value": "English"}, {"id": "2", "value": "French"}]}
   ```
   Use `LanguageHelper.extractValue()` or `extractValueOrEmpty()` to handle these.

2. **List Detection**: XML parser detects lists when multiple children have the same tag name.

3. **Type Coercion**: Always use `.toString()` on numeric IDs from XML as they may parse as int or string.

4. **Root Element Wrapping**: All responses wrapped in `<prestashop>` root element, which the parser strips.

### State Initialization Pattern
Providers that need to load data on app start use this pattern in `main.dart`:
```dart
ChangeNotifierProvider(
  create: (_) => CartProvider(...)..loadCart(),  // Cascade to load immediately
),
ChangeNotifierProvider(
  create: (_) => AuthProvider(...)..checkAuthentication(),
),
```

### Bottom Navigation Setup
Main navigation uses `MainScreen` in `main.dart` (lines 103-175) with 5 tabs:
1. HomeScreen
2. CategoryScreen
3. CartScreen
4. WishlistScreen
5. ProfileScreen

Index managed by `_currentIndex` state variable.

---

## Common Debugging Scenarios

### API Issues
1. Enable debug mode in `.env`: `DEBUG_MODE=true`
2. Check console for request/response logs from `ApiService`
3. Verify API key has correct permissions in PrestaShop admin
4. Check XML response format - PrestaShop sometimes returns HTML errors as XML

### State Not Updating
1. Ensure `notifyListeners()` called after state changes
2. Check widget uses `Consumer` or `context.watch()` not just `Provider.of(listen: false)`
3. Verify provider is in MultiProvider tree in `main.dart`

### XML Parsing Errors
1. Check if field is multilingual - use `LanguageHelper`
2. Verify field exists in API response (not all fields returned by default)
3. Add `'display': 'full'` to query params for complete data
4. Check for null values and provide defaults in model `fromJson()`

---

## Adding New Features

When adding features that interact with PrestaShop API:

1. **Create Model** (`lib/models/`)
   - Follow existing pattern with `fromJson`, `toJson`, `copyWith`
   - Use `LanguageHelper` for multilingual fields
   - Add null safety with defaults

2. **Create Service** (`lib/services/`)
   - Inject `ApiService` via constructor
   - Use appropriate endpoint from `ApiConfig`
   - Handle errors with try/catch, throw `ApiException`

3. **Create Provider** (`lib/providers/`)
   - Extend `ChangeNotifier`
   - Include `_isLoading`, `_error` state
   - Call `notifyListeners()` after state changes

4. **Register Provider** (`lib/main.dart`)
   - Add to `MultiProvider` list (lines 60-89)
   - Initialize service dependency
   - Use cascade `..` for immediate data loading if needed

5. **Add Localization**
   - Add key to `assets/l10n/app_en.arb` and `app_fr.arb`
   - Add getter to `lib/l10n/app_localizations.dart`
   - Use in UI: `AppLocalizations.of(context)?.keyName ?? 'Default'`

---

## Architecture Decisions

**Why XML not JSON?** PrestaShop's default API format. Configured in `ApiConfig.outputFormat`.

**Why Provider not Riverpod/Bloc?** Simple state management sufficient for app complexity. All providers follow ChangeNotifier pattern.

**Why SharedPreferences for Cart?** Cart needs to persist between app sessions but doesn't require encryption. Auth tokens use FlutterSecureStorage for security.

**Why No Tests?** Test infrastructure present but not implemented yet. Manual QA currently used for API integration testing.
