import 'package:json_annotation/json_annotation.dart';
import 'address.dart';

part 'order.g.dart';

@JsonSerializable()
class Order {
  @JsonKey(name: 'id')
  final int id;

  @JsonKey(name: 'reference')
  final String reference;

  @JsonKey(name: 'id_customer')
  final int customerId;

  @JsonKey(name: 'id_address_delivery')
  final int deliveryAddressId;

  @JsonKey(name: 'id_address_invoice')
  final int invoiceAddressId;

  @JsonKey(name: 'id_cart')
  final int cartId;

  @JsonKey(name: 'id_currency')
  final int currencyId;

  @JsonKey(name: 'id_lang')
  final int langId;

  @JsonKey(name: 'id_shop')
  final int shopId;

  @JsonKey(name: 'id_shop_group')
  final int shopGroupId;

  @JsonKey(name: 'current_state')
  final int currentStatusId;

  @JsonKey(name: 'secure_key')
  final String secureKey;

  @JsonKey(name: 'payment')
  final String paymentMethod;

  @JsonKey(name: 'module')
  final String? paymentModule;

  @JsonKey(name: 'total_paid')
  final double totalPaid;

  @JsonKey(name: 'total_paid_real')
  final double totalPaidReal;

  @JsonKey(name: 'total_products')
  final double totalProducts;

  @JsonKey(name: 'total_products_wt')
  final double totalProductsWithTax;

  @JsonKey(name: 'total_shipping')
  final double totalShipping;

  @JsonKey(name: 'total_shipping_tax_incl')
  final double totalShippingTaxIncl;

  @JsonKey(name: 'total_shipping_tax_excl')
  final double totalShippingTaxExcl;

  @JsonKey(name: 'total_wrapping')
  final double totalWrapping;

  @JsonKey(name: 'total_wrapping_tax_incl')
  final double totalWrappingTaxIncl;

  @JsonKey(name: 'total_wrapping_tax_excl')
  final double totalWrappingTaxExcl;

  @JsonKey(name: 'shipping_number')
  final String? shippingNumber;

  @JsonKey(name: 'recyclable', defaultValue: false)
  final bool recyclable;

  @JsonKey(name: 'gift', defaultValue: false)
  final bool gift;

  @JsonKey(name: 'gift_message')
  final String? giftMessage;

  @JsonKey(name: 'mobile_theme', defaultValue: false)
  final bool mobileTheme;

  @JsonKey(name: 'carrier_name')
  final String? carrierName;

  @JsonKey(name: 'delivery_date')
  final String? deliveryDate;

  @JsonKey(name: 'date_add')
  final String dateAdded;

  @JsonKey(name: 'date_upd')
  final String dateUpdated;

  @JsonKey(name: 'associations', defaultValue: {})
  final OrderAssociations associations;

  const Order({
    required this.id,
    required this.reference,
    required this.customerId,
    required this.deliveryAddressId,
    required this.invoiceAddressId,
    required this.cartId,
    required this.currencyId,
    required this.langId,
    required this.shopId,
    required this.shopGroupId,
    required this.currentStatusId,
    required this.secureKey,
    required this.paymentMethod,
    this.paymentModule,
    required this.totalPaid,
    required this.totalPaidReal,
    required this.totalProducts,
    required this.totalProductsWithTax,
    required this.totalShipping,
    required this.totalShippingTaxIncl,
    required this.totalShippingTaxExcl,
    required this.totalWrapping,
    required this.totalWrappingTaxIncl,
    required this.totalWrappingTaxExcl,
    this.shippingNumber,
    this.recyclable = false,
    this.gift = false,
    this.giftMessage,
    this.mobileTheme = false,
    this.carrierName,
    this.deliveryDate,
    required this.dateAdded,
    required this.dateUpdated,
    this.associations = const OrderAssociations(),
  });

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);
  Map<String, dynamic> toJson() => _$OrderToJson(this);

  // Helper methods
  List<OrderItem> get items => associations.orderRows ?? [];

  OrderStatus? _status;
  Address? _deliveryAddress;
  Address? _invoiceAddress;

  OrderStatus? get status => _status;

  set status(OrderStatus? status) => _status = status;

  Address? get deliveryAddress => _deliveryAddress;

  set deliveryAddress(Address? address) => _deliveryAddress = address;

  Address? get invoiceAddress => _invoiceAddress;

  set invoiceAddress(Address? address) => _invoiceAddress = address;

  DateTime get orderDate {
    try {
      return DateTime.parse(dateAdded);
    } catch (e) {
      return DateTime.now();
    }
  }

  String get formattedDate {
    return '${orderDate.day.toString().padLeft(2, '0')}/${orderDate.month.toString().padLeft(2, '0')}/${orderDate.year}';
  }

  String get statusDisplayName {
    return _status?.name ?? 'Unknown';
  }

  bool get isDelivered {
    return _status?.isDelivered ?? false;
  }

  bool get isShipped {
    return _status?.isShipped ?? false;
  }

  bool get isPaid {
    return _status?.isPaid ?? false;
  }

  bool get isProcessing {
    return _status?.isProcessing ?? false;
  }

  bool get isCancelled {
    return _status?.isCancelled ?? false;
  }
}

@JsonSerializable()
class OrderAssociations {
  @JsonKey(name: 'order_rows', defaultValue: [])
  final List<OrderItem>? orderRows;

  @JsonKey(name: 'order_state')
  final OrderStatus? orderStatus;

  @JsonKey(name: 'carrier')
  final OrderCarrier? carrier;

  const OrderAssociations({
    this.orderRows,
    this.orderStatus,
    this.carrier,
  });

  factory OrderAssociations.fromJson(Map<String, dynamic> json) => _$OrderAssociationsFromJson(json);
  Map<String, dynamic> toJson() => _$OrderAssociationsToJson(this);
}

@JsonSerializable()
class OrderItem {
  @JsonKey(name: 'id')
  final int id;

  @JsonKey(name: 'id_order')
  final int orderId;

  @JsonKey(name: 'id_product')
  final int productId;

  @JsonKey(name: 'product_name')
  final String productName;

  @JsonKey(name: 'product_quantity')
  final int quantity;

  @JsonKey(name: 'product_quantity_in_stock')
  final int quantityInStock;

  @JsonKey(name: 'product_price')
  final double unitPrice;

  @JsonKey(name: 'unit_price_tax_incl')
  final double unitPriceTaxIncl;

  @JsonKey(name: 'unit_price_tax_excl')
  final double unitPriceTaxExcl;

  @JsonKey(name: 'product_quantity_discount')
  final double quantityDiscount;

  @JsonKey(name: 'product_quantity_discount_attributable')
  final double quantityDiscountAttributable;

  @JsonKey(name: 'reduction_amount_tax_incl')
  final double reductionAmountTaxIncl;

  @JsonKey(name: 'reduction_amount_tax_excl')
  final double reductionAmountTaxExcl;

  @JsonKey(name: 'group_reduction')
  final double groupReduction;

  @JsonKey(name: 'product_quantity_discount_applied')
  final bool quantityDiscountApplied;

  @JsonKey(name: 'product_ean13')
  final String? ean13;

  @JsonKey(name: 'product_isbn')
  final String? isbn;

  @JsonKey(name: 'product_upc')
  final String? upc;

  @JsonKey(name: 'product_reference')
  final String? reference;

  @JsonKey(name: 'product_supplier_reference')
  final String? supplierReference;

  @JsonKey(name: 'product_weight')
  final double weight;

  @JsonKey(name: 'id_tax_rules_group')
  final int taxRulesGroupId;

  @JsonKey(name: 'id_customization')
  final int customizationId;

  @JsonKey(name: 'product_attribute_id')
  final int? productAttributeId;

  @JsonKey(name: 'image')
  final String? imageUrl;

  const OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.quantityInStock,
    required this.unitPrice,
    required this.unitPriceTaxIncl,
    required this.unitPriceTaxExcl,
    required this.quantityDiscount,
    required this.quantityDiscountAttributable,
    required this.reductionAmountTaxIncl,
    required this.reductionAmountTaxExcl,
    required this.groupReduction,
    required this.quantityDiscountApplied,
    this.ean13,
    this.isbn,
    this.upc,
    this.reference,
    this.supplierReference,
    required this.weight,
    required this.taxRulesGroupId,
    required this.customizationId,
    this.productAttributeId,
    this.imageUrl,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) => _$OrderItemFromJson(json);
  Map<String, dynamic> toJson() => _$OrderItemToJson(this);

  // Helper properties
  double get totalPrice => unitPriceTaxIncl * quantity;

  double get totalTax => (unitPriceTaxIncl - unitPriceTaxExcl) * quantity;

  String get displayName {
    if (reference?.isNotEmpty == true) {
      return '$productName ($reference)';
    }
    return productName;
  }

  String get imageDisplayUrl => imageUrl ?? '';
}

@JsonSerializable()
class OrderStatus {
  @JsonKey(name: 'id')
  final int id;

  @JsonKey(name: 'name')
  final String name;

  @JsonKey(name: 'color')
  final String color;

  @JsonKey(name: 'logable', defaultValue: false)
  final bool logable;

  @JsonKey(name: 'shipped', defaultValue: false)
  final bool shipped;

  @JsonKey(name: 'paid', defaultValue: false)
  final bool paid;

  @JsonKey(name: 'delivery', defaultValue: false)
  final bool delivery;

  @JsonKey(name: 'deleted', defaultValue: false)
  final bool deleted;

  const OrderStatus({
    required this.id,
    required this.name,
    required this.color,
    this.logable = false,
    this.shipped = false,
    this.paid = false,
    this.delivery = false,
    this.deleted = false,
  });

  factory OrderStatus.fromJson(Map<String, dynamic> json) => _$OrderStatusFromJson(json);
  Map<String, dynamic> toJson() => _$OrderStatusToJson(this);

  // Helper properties
  bool get isDelivered => delivery;
  bool get isShipped => shipped;
  bool get isPaid => paid;
  bool get isProcessing => !shipped && !delivery && !deleted;
  bool get isCancelled => deleted;

  String get statusColor {
    if (isDelivered) return '#4CAF50'; // Green
    if (isShipped) return '#2196F3'; // Blue
    if (isPaid) return '#FF9800'; // Orange
    if (isCancelled) return '#F44336'; // Red
    return '#9E9E9E'; // Grey
  }
}

@JsonSerializable()
class OrderCarrier {
  @JsonKey(name: 'id')
  final int id;

  @JsonKey(name: 'name')
  final String name;

  @JsonKey(name: 'url')
  final String? trackingUrl;

  @JsonKey(name: 'delay')
  final String? deliveryDelay;

  const OrderCarrier({
    required this.id,
    required this.name,
    this.trackingUrl,
    this.deliveryDelay,
  });

  factory OrderCarrier.fromJson(Map<String, dynamic> json) => _$OrderCarrierFromJson(json);
  Map<String, dynamic> toJson() => _$OrderCarrierToJson(this);
}

// Order creation request models
@JsonSerializable()
class CreateOrderRequest {
  @JsonKey(name: 'id_customer')
  final int customerId;

  @JsonKey(name: 'id_address_delivery')
  final int deliveryAddressId;

  @JsonKey(name: 'id_address_invoice')
  final int invoiceAddressId;

  @JsonKey(name: 'id_cart')
  final int cartId;

  @JsonKey(name: 'id_currency')
  final int currencyId;

  @JsonKey(name: 'id_lang')
  final int langId;

  @JsonKey(name: 'id_carrier')
  final int carrierId;

  @JsonKey(name: 'payment_module')
  final String paymentModule;

  @JsonKey(name: 'secure_key')
  final String? secureKey;

  const CreateOrderRequest({
    required this.customerId,
    required this.deliveryAddressId,
    required this.invoiceAddressId,
    required this.cartId,
    required this.currencyId,
    required this.langId,
    required this.carrierId,
    required this.paymentModule,
    this.secureKey,
  });

  factory CreateOrderRequest.fromJson(Map<String, dynamic> json) => _$CreateOrderRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateOrderRequestToJson(this);
}