// lib/models/product_detail.dart
import 'package:prestashop_mobile_app/utils/language_helper.dart';

class ProductDetail {
  final String id;
  final String name;
  final String description;
  final String descriptionShort;
  final String price;
  final String wholesalePrice;
  final String unity;
  final String unitPriceRatio;
  final String additionalShippingCost;
  final String reference;
  final String supplierReference;
  final String location;
  final String width;
  final String height;
  final String depth;
  final String weight;
  final String ean13;
  final String isbn;
  final String upc;
  final String mpn;
  final String cacheDefaultAttribute;
  final String idCategoryDefault;
  final String idShopDefault;
  final String idManufacturer;
  final String idSupplier;
  final String idTaxRulesGroup;
  final String condition;
  final String showPrice;
  final String active;
  final String available;
  final String visibility;
  final String onSale;
  final String isVirtual;
  final String quantity;
  final String outOfStock;
  final String customizable;
  final String uploadableFiles;
  final String textFields;
  final String advancedStockManagement;
  final String dateAdd;
  final String dateUpd;
  final String packStockType;
  final String metaDescription;
  final String metaKeywords;
  final String metaTitle;
  final String linkRewrite;
  final String availableForOrder;
  final String availableDate;
  final String showCondition;
  final String lowStockThreshold;
  final String lowStockAlert;

  // NUEVOS CAMPOS PARA CANTIDADES MÍNIMAS Y MÚLTIPLOS
  final String minimalQuantity; // Cantidad mínima
  final String?
  minimalPurchaseQuantity; // Cantidad mínima de compra (PrestaShop 1.7+)
  final String? quantityStep; // Paso/múltiplo (ej: de 6 en 6)

  final List<String> imageUrls;
  final List<ProductFeature> features;
  final List<ProductAttribute> attributes;
  final List<SpecificPrice> specificPrices;

  // NUEVO: Precios según grupos
  final List<GroupPrice> groupPrices;

  ProductDetail({
    required this.id,
    required this.name,
    required this.description,
    required this.descriptionShort,
    required this.price,
    required this.wholesalePrice,
    required this.unity,
    required this.unitPriceRatio,
    required this.additionalShippingCost,
    required this.reference,
    required this.supplierReference,
    required this.location,
    required this.width,
    required this.height,
    required this.depth,
    required this.weight,
    required this.ean13,
    required this.isbn,
    required this.upc,
    required this.mpn,
    required this.cacheDefaultAttribute,
    required this.idCategoryDefault,
    required this.idShopDefault,
    required this.idManufacturer,
    required this.idSupplier,
    required this.idTaxRulesGroup,
    required this.condition,
    required this.showPrice,
    required this.active,
    required this.available,
    required this.visibility,
    required this.onSale,
    required this.isVirtual,
    required this.quantity,
    required this.outOfStock,
    required this.customizable,
    required this.uploadableFiles,
    required this.textFields,
    required this.advancedStockManagement,
    required this.dateAdd,
    required this.dateUpd,
    required this.packStockType,
    required this.metaDescription,
    required this.metaKeywords,
    required this.metaTitle,
    required this.linkRewrite,
    required this.availableForOrder,
    required this.availableDate,
    required this.showCondition,
    required this.lowStockThreshold,
    required this.lowStockAlert,
    required this.minimalQuantity,
    this.minimalPurchaseQuantity,
    this.quantityStep,
    required this.imageUrls,
    required this.features,
    required this.attributes,
    required this.specificPrices,
    required this.groupPrices,
  });

  // GETTER: Obtiene la cantidad mínima efectiva
  int get effectiveMinimalQuantity {
    if (minimalPurchaseQuantity != null &&
        minimalPurchaseQuantity!.isNotEmpty) {
      return int.tryParse(minimalPurchaseQuantity!) ??
          int.tryParse(minimalQuantity) ??
          1;
    }
    return int.tryParse(minimalQuantity) ?? 1;
  }

  // GETTER: Obtiene el paso/múltiplo
  int get effectiveQuantityStep {
    return int.tryParse(quantityStep ?? '') ?? 1;
  }

  // MÉTODO: Valida si una cantidad es válida según los múltiplos
  bool isValidQuantity(int qty) {
    final minQty = effectiveMinimalQuantity;
    final step = effectiveQuantityStep;

    if (qty < minQty) return false;
    if (step <= 1) return true;

    // Verifica que la cantidad sea un múltiplo válido desde la cantidad mínima
    return (qty - minQty) % step == 0;
  }

  // MÉTODO: Ajusta la cantidad al múltiplo más cercano válido
  int adjustToValidQuantity(int qty) {
    final minQty = effectiveMinimalQuantity;
    final step = effectiveQuantityStep;

    if (qty < minQty) return minQty;
    if (step <= 1) return qty;

    // Ajusta al múltiplo más cercano
    final diff = (qty - minQty) % step;
    if (diff == 0) return qty;

    // Redondea hacia arriba al siguiente múltiplo válido
    return qty + (step - diff);
  }

  // MÉTODO: Obtiene el precio para un grupo específico
  double getPriceForGroup(String groupId, {bool withTax = true}) {
    // Busca precio específico para el grupo
    for (final groupPrice in groupPrices) {
      if (groupPrice.idGroup == groupId) {
        return withTax ? groupPrice.priceWithTax : groupPrice.priceWithoutTax;
      }
    }

    // Busca en precios específicos
    for (final sp in specificPrices) {
      if (sp.idGroup == groupId) {
        if (sp.price != '0.000000' && sp.price.isNotEmpty) {
          return double.tryParse(sp.price) ?? double.tryParse(price) ?? 0.0;
        }
      }
    }

    // Precio por defecto
    return double.tryParse(price) ?? 0.0;
  }

  factory ProductDetail.fromJson(Map<String, dynamic> json) {
    // Parsear imágenes
    List<String> images = [];
    if (json['associations'] != null &&
        json['associations']['images'] != null) {
      final imageData = json['associations']['images'];
      if (imageData is List) {
        images = imageData
            .map((img) => img['id']?.toString() ?? '')
            .where((id) => id.isNotEmpty)
            .toList();
      }
    }

    // Parsear features
    List<ProductFeature> features = [];
    if (json['associations'] != null &&
        json['associations']['product_features'] != null) {
      final featureData = json['associations']['product_features'];
      if (featureData is List) {
        features = featureData.map((f) => ProductFeature.fromJson(f)).toList();
      }
    }

    // Parsear attributes (para combinaciones)
    List<ProductAttribute> attributes = [];
    if (json['associations'] != null &&
        json['associations']['product_option_values'] != null) {
      final attrData = json['associations']['product_option_values'];
      if (attrData is List) {
        attributes = attrData.map((a) => ProductAttribute.fromJson(a)).toList();
      }
    }

    // Parsear precios específicos
    List<SpecificPrice> specificPrices = [];
    if (json['associations'] != null &&
        json['associations']['specific_prices'] != null) {
      final spData = json['associations']['specific_prices'];
      if (spData is List) {
        specificPrices = spData
            .map((sp) => SpecificPrice.fromJson(sp))
            .toList();
      }
    }

    // NUEVO: Parsear precios por grupo
    List<GroupPrice> groupPrices = [];
    if (json['associations'] != null &&
        json['associations']['group_prices'] != null) {
      final gpData = json['associations']['group_prices'];
      if (gpData is List) {
        groupPrices = gpData.map((gp) => GroupPrice.fromJson(gp)).toList();
      }
    }

    return ProductDetail(
      id: json['id']?.toString() ?? '',
      name: LanguageHelper.extractValueOrEmpty(json['name']),
      description: LanguageHelper.extractValueOrEmpty(json['description']),
      descriptionShort: LanguageHelper.extractValueOrEmpty(
        json['description_short'],
      ),
      price: json['price']?.toString() ?? '0',
      wholesalePrice: json['wholesale_price']?.toString() ?? '0',
      unity: json['unity']?.toString() ?? '',
      unitPriceRatio: json['unit_price_ratio']?.toString() ?? '0',
      additionalShippingCost:
          json['additional_shipping_cost']?.toString() ?? '0',
      reference: json['reference']?.toString() ?? '',
      supplierReference: json['supplier_reference']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      width: json['width']?.toString() ?? '0',
      height: json['height']?.toString() ?? '0',
      depth: json['depth']?.toString() ?? '0',
      weight: json['weight']?.toString() ?? '0',
      ean13: json['ean13']?.toString() ?? '',
      isbn: json['isbn']?.toString() ?? '',
      upc: json['upc']?.toString() ?? '',
      mpn: json['mpn']?.toString() ?? '',
      cacheDefaultAttribute: json['cache_default_attribute']?.toString() ?? '0',
      idCategoryDefault: json['id_category_default']?.toString() ?? '',
      idShopDefault: json['id_shop_default']?.toString() ?? '',
      idManufacturer: json['id_manufacturer']?.toString() ?? '',
      idSupplier: json['id_supplier']?.toString() ?? '',
      idTaxRulesGroup: json['id_tax_rules_group']?.toString() ?? '',
      condition: json['condition']?.toString() ?? 'new',
      showPrice: json['show_price']?.toString() ?? '1',
      active: json['active']?.toString() ?? '1',
      available: json['available_for_order']?.toString() ?? '1',
      visibility: json['visibility']?.toString() ?? 'both',
      onSale: json['on_sale']?.toString() ?? '0',
      isVirtual: json['is_virtual']?.toString() ?? '0',
      quantity: json['quantity']?.toString() ?? '0',
      outOfStock: json['out_of_stock']?.toString() ?? '2',
      customizable: json['customizable']?.toString() ?? '0',
      uploadableFiles: json['uploadable_files']?.toString() ?? '0',
      textFields: json['text_fields']?.toString() ?? '0',
      advancedStockManagement:
          json['advanced_stock_management']?.toString() ?? '0',
      dateAdd: json['date_add']?.toString() ?? '',
      dateUpd: json['date_upd']?.toString() ?? '',
      packStockType: json['pack_stock_type']?.toString() ?? '3',
      metaDescription: LanguageHelper.extractValueOrEmpty(
        json['meta_description'],
      ),
      metaKeywords: LanguageHelper.extractValueOrEmpty(json['meta_keywords']),
      metaTitle: LanguageHelper.extractValueOrEmpty(json['meta_title']),
      linkRewrite: LanguageHelper.extractValueOrEmpty(json['link_rewrite']),
      availableForOrder: json['available_for_order']?.toString() ?? '1',
      availableDate: json['available_date']?.toString() ?? '',
      showCondition: json['show_condition']?.toString() ?? '1',
      lowStockThreshold: json['low_stock_threshold']?.toString() ?? '',
      lowStockAlert: json['low_stock_alert']?.toString() ?? '0',

      // NUEVOS CAMPOS
      minimalQuantity: json['minimal_quantity']?.toString() ?? '1',
      minimalPurchaseQuantity: json['minimal_purchase_quantity']?.toString(),
      quantityStep: json['quantity_step']?.toString(),

      imageUrls: images,
      features: features,
      attributes: attributes,
      specificPrices: specificPrices,
      groupPrices: groupPrices,
    );
  }
}

// Modelo para precios por grupo
class GroupPrice {
  final String idGroup;
  final String groupName;
  final double priceWithTax;
  final double priceWithoutTax;
  final String? reduction;
  final String? reductionType; // 'percentage' o 'amount'

  GroupPrice({
    required this.idGroup,
    required this.groupName,
    required this.priceWithTax,
    required this.priceWithoutTax,
    this.reduction,
    this.reductionType,
  });

  factory GroupPrice.fromJson(Map<String, dynamic> json) {
    return GroupPrice(
      idGroup: json['id_group']?.toString() ?? '',
      groupName: json['group_name']?.toString() ?? '',
      priceWithTax:
          double.tryParse(json['price_with_tax']?.toString() ?? '0') ?? 0.0,
      priceWithoutTax:
          double.tryParse(json['price_without_tax']?.toString() ?? '0') ?? 0.0,
      reduction: json['reduction']?.toString(),
      reductionType: json['reduction_type']?.toString(),
    );
  }
}

class ProductFeature {
  final String id;
  final String idFeatureValue;

  ProductFeature({required this.id, required this.idFeatureValue});

  factory ProductFeature.fromJson(Map<String, dynamic> json) {
    return ProductFeature(
      id: json['id']?.toString() ?? '',
      idFeatureValue: json['id_feature_value']?.toString() ?? '',
    );
  }
}

class ProductAttribute {
  final String id;

  ProductAttribute({required this.id});

  factory ProductAttribute.fromJson(Map<String, dynamic> json) {
    return ProductAttribute(id: json['id']?.toString() ?? '');
  }
}

class SpecificPrice {
  final String id;
  final String idProduct;
  final String idShop;
  final String idCurrency;
  final String idCountry;
  final String idGroup;
  final String idCustomer;
  final String price;
  final String fromQuantity;
  final String reduction;
  final String reductionType;
  final String from;
  final String to;

  SpecificPrice({
    required this.id,
    required this.idProduct,
    required this.idShop,
    required this.idCurrency,
    required this.idCountry,
    required this.idGroup,
    required this.idCustomer,
    required this.price,
    required this.fromQuantity,
    required this.reduction,
    required this.reductionType,
    required this.from,
    required this.to,
  });

  factory SpecificPrice.fromJson(Map<String, dynamic> json) {
    return SpecificPrice(
      id: json['id']?.toString() ?? '',
      idProduct: json['id_product']?.toString() ?? '',
      idShop: json['id_shop']?.toString() ?? '',
      idCurrency: json['id_currency']?.toString() ?? '',
      idCountry: json['id_country']?.toString() ?? '',
      idGroup: json['id_group']?.toString() ?? '',
      idCustomer: json['id_customer']?.toString() ?? '',
      price: json['price']?.toString() ?? '-1',
      fromQuantity: json['from_quantity']?.toString() ?? '1',
      reduction: json['reduction']?.toString() ?? '0',
      reductionType: json['reduction_type']?.toString() ?? 'amount',
      from: json['from']?.toString() ?? '',
      to: json['to']?.toString() ?? '',
    );
  }
}