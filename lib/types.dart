import 'enums.dart';
import 'errors.dart';
export 'enums.dart';
export 'errors.dart'
    show PurchaseError, PurchaseResult, ConnectionResult, getCurrentPlatform;
export 'types_additions.dart';

/// Safely convert any JSON map (possibly Map<dynamic, dynamic>)
/// into Map<String, dynamic>, or return null if not a map.
Map<String, dynamic>? _safeJsonMap(dynamic json) {
  if (json == null) return null;
  if (json is Map<String, dynamic>) return json;
  if (json is Map) return Map<String, dynamic>.from(json);
  return null;
}

/// Coerce a JSON value that may be a number or a string into a string.
/// Returns [fallback] if the value is null or an unsupported type.
String _stringFromNumOrString(dynamic value, {String fallback = '0'}) {
  if (value == null) return fallback;
  if (value is String) return value;
  if (value is num) return value.toString();
  return fallback;
}

// ============================================================================
// CORE TYPES (OpenIAP compliant)
// ============================================================================

/// Change event payload
class ChangeEventPayload {
  final String value;

  ChangeEventPayload({required this.value});
}

/// Product type enum (OpenIAP compliant)
/// 'inapp' for consumables/non-consumables, 'subs' for subscriptions
class ProductType {
  static const String inapp = 'inapp';
  static const String subs = 'subs';
}

// ============================================================================
// PURCHASE OPTIONS (OpenIAP compliant)
// ============================================================================

/// Options for getAvailablePurchases method (OpenIAP compliant)
class PurchaseOptions {
  /// iOS only: Whether to also publish to event listener
  final bool? alsoPublishToEventListenerIOS;

  /// iOS only: Whether to only include active items (default: true)
  /// Set to false to include expired subscriptions
  final bool? onlyIncludeActiveItemsIOS;

  const PurchaseOptions({
    this.alsoPublishToEventListenerIOS,
    this.onlyIncludeActiveItemsIOS,
  });

  Map<String, dynamic> toMap() {
    return {
      if (alsoPublishToEventListenerIOS != null)
        'alsoPublishToEventListenerIOS': alsoPublishToEventListenerIOS,
      if (onlyIncludeActiveItemsIOS != null)
        'onlyIncludeActiveItemsIOS': onlyIncludeActiveItemsIOS,
    };
  }
}

// ============================================================================
// COMMON TYPES (Base types shared across all platforms - OpenIAP compliant)
// ============================================================================

/// Base purchase class (OpenIAP compliant)
class PurchaseCommon {
  final String id; // Transaction identifier - used by finishTransaction
  final String productId; // Product identifier - which product was purchased
  final List<String>?
      ids; // Product identifiers for purchases that include multiple products
  @Deprecated('Use id instead')
  final String? transactionId; // @deprecated - use id instead
  final int transactionDate;
  final String transactionReceipt;
  final String?
      purchaseToken; // Unified purchase token (jwsRepresentation for iOS, purchaseToken for Android)
  final String? platform;

  PurchaseCommon({
    required this.id,
    required this.productId,
    required this.transactionDate,
    required this.transactionReceipt,
    this.ids,
    @Deprecated('Use id instead') this.transactionId,
    this.purchaseToken,
    this.platform,
  });
}

// ============================================================================
// IOS TYPES (OpenIAP compliant)
// ============================================================================

/// iOS subscription period units
class SubscriptionIosPeriod {
  static const String DAY = 'DAY';
  static const String WEEK = 'WEEK';
  static const String MONTH = 'MONTH';
  static const String YEAR = 'YEAR';
  static const String empty = '';
}

/// iOS payment mode
class PaymentModeIOS {
  static const String empty = '';
  static const String FREETRIAL = 'FREETRIAL';
  static const String PAYASYOUGO = 'PAYASYOUGO';
  static const String PAYUPFRONT = 'PAYUPFRONT';
}

/// Android purchase state enum (OpenIAP compliant)
class PurchaseAndroidState {
  static const int UNSPECIFIED_STATE = 0;
  static const int PURCHASED = 1;
  static const int PENDING = 2;
}

/// iOS subscription offer (OpenIAP compliant)
class SubscriptionOfferIOS {
  final String displayPrice;
  final String id;
  final String paymentMode;
  final Map<String, dynamic> period;
  final int periodCount;
  final double price;
  final String type; // 'introductory' | 'promotional'

  SubscriptionOfferIOS({
    required this.displayPrice,
    required this.id,
    required this.paymentMode,
    required this.period,
    required this.periodCount,
    required this.price,
    required this.type,
  });

  factory SubscriptionOfferIOS.fromJson(Map<String, dynamic> json) {
    return SubscriptionOfferIOS(
      displayPrice: json['displayPrice'] as String? ?? '',
      id: json['id'] as String? ?? '',
      paymentMode: json['paymentMode'] as String? ?? '',
      period: json['period'] != null
          ? Map<String, dynamic>.from(json['period'] as Map)
          : {'unit': '', 'value': 0},
      periodCount: json['periodCount'] as int? ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      type: json['type'] as String? ?? '',
    );
  }
}

/// ProductCommon - Base product interface (renamed from BaseProduct for OpenIAP spec alignment)
abstract class ProductCommon {
  // OpenIAP core fields
  final String id;
  final String? title;
  final String? description;
  final String type;
  final String? displayName;
  final String displayPrice;
  final String? currency;
  final double? price;
  final String? debugDescription;
  final String? platform;

  // Backward compatibility fields
  @Deprecated('Use id instead. Will be removed in 6.6.0')
  final String? productId;
  final String? localizedPrice;
  final IapPlatform platformEnum;

  ProductCommon({
    required this.id,
    required this.type,
    required this.displayPrice,
    required this.platformEnum,
    this.title,
    this.description,
    this.displayName,
    this.currency,
    this.price,
    this.debugDescription,
    this.platform,
    // Backward compatibility
    this.productId,
    this.localizedPrice,
  });
}

/// Product class for non-subscription items (OpenIAP compliant)
class Product extends ProductCommon {
  // iOS-specific fields per OpenIAP spec
  final List<DiscountIOS>? discountsIOS;
  final SubscriptionInfo? subscription;
  final String? introductoryPriceNumberOfPeriodsIOS;
  final String? introductoryPriceSubscriptionPeriodIOS;
  final String? subscriptionGroupIdIOS;
  final String? subscriptionPeriodUnitIOS;
  final String? subscriptionPeriodNumberIOS;
  final String? introductoryPricePaymentModeIOS;
  final String? environmentIOS; // "Sandbox" | "Production"
  final List<String>? promotionalOfferIdsIOS;

  // Android-specific fields per OpenIAP spec
  final String? nameAndroid;
  final Map<String, dynamic>? oneTimePurchaseOfferDetailsAndroid;
  final String? originalPrice;
  final double? originalPriceAmount;
  final String? freeTrialPeriod;
  final String? iconUrl;
  final List<OfferDetail>? subscriptionOfferDetailsAndroid;
  final String? subscriptionPeriodAndroid;
  final String? introductoryPriceCyclesAndroid;
  final String? introductoryPricePeriodAndroid;
  final String? freeTrialPeriodAndroid;
  final String? signatureAndroid;
  final List<SubscriptionOfferAndroid>? subscriptionOffersAndroid;

  Product({
    // OpenIAP fields (primary)
    String? id,
    super.title,
    super.description,
    String? type,
    super.displayName,
    String? displayPrice,
    super.currency,
    double? price,
    super.debugDescription,
    String? platform,
    // Backward compatibility fields
    super.productId,
    String? priceString,
    super.localizedPrice,
    IapPlatform? platformEnum,
    // iOS fields per OpenIAP spec
    this.discountsIOS,
    this.subscription,
    this.introductoryPriceNumberOfPeriodsIOS,
    this.introductoryPriceSubscriptionPeriodIOS,
    this.subscriptionGroupIdIOS,
    this.subscriptionPeriodUnitIOS,
    this.subscriptionPeriodNumberIOS,
    this.introductoryPricePaymentModeIOS,
    this.environmentIOS,
    this.promotionalOfferIdsIOS,
    // Android fields per OpenIAP spec
    this.nameAndroid,
    this.oneTimePurchaseOfferDetailsAndroid,
    this.originalPrice,
    this.originalPriceAmount,
    this.freeTrialPeriod,
    this.iconUrl,
    this.subscriptionOfferDetailsAndroid,
    this.subscriptionPeriodAndroid,
    this.introductoryPriceCyclesAndroid,
    this.introductoryPricePeriodAndroid,
    this.freeTrialPeriodAndroid,
    this.signatureAndroid,
    this.subscriptionOffersAndroid,
  }) : super(
          id: id ?? productId ?? '',
          type: type ?? 'inapp',
          displayPrice: displayPrice ?? localizedPrice ?? '0',
          platformEnum: platformEnum ?? IapPlatform.ios,
          price: price ??
              (priceString != null ? double.tryParse(priceString) : null),
          platform:
              platform ?? (platformEnum == IapPlatform.ios ? 'ios' : 'android'),
        );

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      // Use OpenIAP fields primarily, fallback to legacy
      id: json['id'] as String? ?? json['productId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      type: json['type'] as String? ?? 'inapp',
      displayName: json['displayName'] as String?,
      displayPrice: json['displayPrice'] as String? ??
          json['localizedPrice'] as String? ??
          '0',
      currency: json['currency'] as String? ?? '',
      price: (json['price'] is num)
          ? (json['price'] as num).toDouble()
          : (json['price'] is String
              ? double.tryParse(json['price'] as String)
              : null),
      platform: json['platform'] as String?,
      // Backward compatibility fields
      productId: json['productId'] as String?,
      priceString: (json['price'] is String) ? json['price'] as String : null,
      localizedPrice: json['localizedPrice'] as String?,
      platformEnum:
          json['platform'] == 'android' ? IapPlatform.android : IapPlatform.ios,
      discountsIOS: json['discountsIOS'] != null
          ? (json['discountsIOS'] as List)
              .map((item) {
                final map = _safeJsonMap(item);
                return map != null ? DiscountIOS.fromJson(map) : null;
              })
              .whereType<DiscountIOS>()
              .toList()
          : null,
      subscription: json['subscription'] != null
          ? SubscriptionInfo.fromJson(
              Map<String, dynamic>.from(json['subscription'] as Map),
            )
          : null,
      introductoryPriceNumberOfPeriodsIOS:
          json['introductoryPriceNumberOfPeriodsIOS'] as String?,
      introductoryPriceSubscriptionPeriodIOS:
          json['introductoryPriceSubscriptionPeriodIOS'] as String?,
      subscriptionGroupIdIOS: json['subscriptionGroupIdIOS'] as String?,
      subscriptionPeriodUnitIOS: json['subscriptionPeriodUnitIOS'] as String?,
      subscriptionPeriodNumberIOS:
          json['subscriptionPeriodNumberIOS'] as String?,
      introductoryPricePaymentModeIOS:
          json['introductoryPricePaymentModeIOS'] as String?,
      environmentIOS: json['environmentIOS'] as String?,
      promotionalOfferIdsIOS: json['promotionalOfferIdsIOS'] != null
          ? (json['promotionalOfferIdsIOS'] as List).cast<String>()
          : null,
      // Android fields per OpenIAP spec
      nameAndroid: json['nameAndroid'] as String?,
      oneTimePurchaseOfferDetailsAndroid:
          json['oneTimePurchaseOfferDetailsAndroid'] != null
              ? Map<String, dynamic>.from(
                  json['oneTimePurchaseOfferDetailsAndroid'] as Map,
                )
              : null,
      originalPrice: json['originalPrice'] as String?,
      originalPriceAmount: (json['originalPriceAmount'] as num?)?.toDouble(),
      freeTrialPeriod: json['freeTrialPeriod'] as String?,
      iconUrl: json['iconUrl'] as String?,
      // Use new Android suffix field if available, fallback to old field for compatibility
      subscriptionOfferDetailsAndroid:
          json['subscriptionOfferDetailsAndroid'] != null
              ? (json['subscriptionOfferDetailsAndroid'] as List)
                  .map((item) {
                    final map = _safeJsonMap(item);
                    return map != null ? OfferDetail.fromJson(map) : null;
                  })
                  .whereType<OfferDetail>()
                  .toList()
              : null,
      subscriptionPeriodAndroid: json['subscriptionPeriodAndroid'] as String?,
      introductoryPriceCyclesAndroid:
          json['introductoryPriceCyclesAndroid'] as String?,
      introductoryPricePeriodAndroid:
          json['introductoryPricePeriodAndroid'] as String?,
      freeTrialPeriodAndroid: json['freeTrialPeriodAndroid'] as String?,
      signatureAndroid: json['signatureAndroid'] as String?,
      subscriptionOffersAndroid: json['subscriptionOffersAndroid'] != null
          ? (json['subscriptionOffersAndroid'] as List)
              .map(
                (o) => SubscriptionOfferAndroid.fromJson(
                  _safeJsonMap(o) ?? {},
                ),
              )
              .toList()
          : null,
    );
  }

  @override
  String toString() {
    final buffer = StringBuffer('$runtimeType{\n');
    buffer.writeln('  productId: $productId,');
    buffer.writeln('  id: $id,');
    buffer.writeln('  price: $price,');
    buffer.writeln('  currency: $currency,');
    buffer.writeln('  localizedPrice: $localizedPrice,');
    buffer.writeln('  title: $title,');
    if (description != null) {
      final desc = description!;
      final short = desc.length > 100 ? '${desc.substring(0, 100)}...' : desc;
      buffer.writeln('  description: $short,');
    } else {
      buffer.writeln('  description: null,');
    }
    buffer.writeln('  type: $type,');
    buffer.writeln('  platform: $platform,');

    // iOS specific fields (only print non-null)
    if (displayName != null) buffer.writeln('  displayName: $displayName,');
    if (environmentIOS != null) {
      buffer.writeln('  environmentIOS: $environmentIOS,');
    }
    if (subscriptionPeriodUnitIOS != null) {
      buffer.writeln(
        '  subscriptionPeriodUnitIOS: $subscriptionPeriodUnitIOS,',
      );
    }
    if (subscriptionPeriodNumberIOS != null) {
      buffer.writeln(
        '  subscriptionPeriodNumberIOS: $subscriptionPeriodNumberIOS,',
      );
    }
    if (discountsIOS != null && discountsIOS!.isNotEmpty) {
      buffer.writeln('  discountsIOS: ${discountsIOS!.length} discount(s),');
    }

    // Android specific fields (show even if null for Android platform)
    if (platform == 'android') {
      buffer.writeln(
        '  nameAndroid: ${nameAndroid != null ? '"$nameAndroid"' : 'null'},',
      );
      buffer.writeln(
        '  oneTimePurchaseOfferDetailsAndroid: $oneTimePurchaseOfferDetailsAndroid,',
      );
    } else {
      if (nameAndroid != null) buffer.writeln('  nameAndroid: "$nameAndroid",');
      if (oneTimePurchaseOfferDetailsAndroid != null) {
        buffer.writeln(
          '  oneTimePurchaseOfferDetailsAndroid: $oneTimePurchaseOfferDetailsAndroid,',
        );
      }
    }
    if (originalPrice != null) {
      buffer.writeln('  originalPrice: $originalPrice,');
    }
    if (freeTrialPeriod != null) {
      buffer.writeln('  freeTrialPeriod: $freeTrialPeriod,');
    }
    if (subscriptionPeriodAndroid != null) {
      buffer.writeln(
        '  subscriptionPeriodAndroid: $subscriptionPeriodAndroid,',
      );
    }
    if (subscriptionOfferDetailsAndroid != null &&
        subscriptionOfferDetailsAndroid!.isNotEmpty) {
      buffer.writeln(
        '  subscriptionOfferDetailsAndroid: ${subscriptionOfferDetailsAndroid!.length} offer(s),',
      );
    }

    // For Subscription class, add subscription info
    if (this is Subscription) {
      final sub = this as Subscription;
      if (sub.subscription != null) {
        buffer.writeln('  subscription: ${sub.subscription},');
      }
      if (sub.subscriptionGroupIdIOS != null) {
        buffer.writeln(
          '  subscriptionGroupIdIOS: ${sub.subscriptionGroupIdIOS},',
        );
      }
      if (sub.subscriptionOffersAndroid != null &&
          sub.subscriptionOffersAndroid!.isNotEmpty) {
        buffer.writeln(
          '  subscriptionOffersAndroid: ${sub.subscriptionOffersAndroid!.length} offer(s),',
        );
      }
    }

    // Remove last comma and close
    final str = buffer.toString();
    if (str.endsWith(',\n')) {
      return '${str.substring(0, str.length - 2)}\n}';
    }
    return '$str}';
  }

  /// Convert iOS native product types to OpenIAP standard types
  String _convertTypeForOpenIAP(String type, bool isIOS) {
    if (!isIOS) return type; // Android types are already correct

    switch (type.toLowerCase()) {
      case 'consumable':
      case 'nonconsumable':
      case 'nonrenewable':
        return 'inapp';
      case 'autorenewable':
        return 'subs';
      default:
        return type; // Return as-is if not recognized
    }
  }

  Map<String, dynamic> toJson() {
    // Determine if this is iOS or Android
    final isIOS = platformEnum == IapPlatform.ios;

    final json = <String, dynamic>{
      'id': id,
      'title': title ?? '',
      'description': description ?? '',
      'type': _convertTypeForOpenIAP(type, isIOS),
      'currency': currency ?? '',
      'platform': isIOS ? 'ios' : 'android', // Use string literal
    };

    // Price field (as number for iOS type compatibility)
    if (price != null) {
      json['price'] = price;
    }

    // displayPrice field (required for iOS)
    json['displayPrice'] = displayPrice;
    if (localizedPrice != null && displayPrice != localizedPrice) {
      json['localizedPrice'] = localizedPrice; // Include if different
    }

    // Optional displayName field
    if (displayName != null) {
      json['displayName'] = displayName;
    }

    // iOS specific fields with correct naming
    if (isIOS) {
      if (displayName != null) {
        json['displayNameIOS'] = displayName;
      }
      // Add OpenIAP compliant iOS fields for ProductIOS
      if (this is ProductIOS) {
        final productIOS = this as ProductIOS;
        if (productIOS.isFamilyShareableIOS != null) {
          json['isFamilyShareableIOS'] = productIOS.isFamilyShareableIOS;
        }
        if (productIOS.jsonRepresentationIOS != null) {
          json['jsonRepresentationIOS'] = productIOS.jsonRepresentationIOS;
        }
      }
      // Add OpenIAP compliant iOS fields for Subscription
      // Note: In Product class, this check is needed; in Subscription class, it's redundant
      else if (this is Subscription) {
        // Remove unnecessary cast since we know the type
        if ((this as dynamic).isFamilyShareableIOS != null) {
          json['isFamilyShareableIOS'] = (this as dynamic).isFamilyShareableIOS;
        }
        if ((this as dynamic).jsonRepresentationIOS != null) {
          json['jsonRepresentationIOS'] =
              (this as dynamic).jsonRepresentationIOS;
        }
      }
      if (environmentIOS != null) {
        json['environmentIOS'] = environmentIOS;
      }
      if (subscriptionGroupIdIOS != null) {
        json['subscriptionGroupIdIOS'] = subscriptionGroupIdIOS;
      }
      if (promotionalOfferIdsIOS != null &&
          promotionalOfferIdsIOS!.isNotEmpty) {
        json['promotionalOfferIdsIOS'] = promotionalOfferIdsIOS;
      }
      if (discountsIOS != null && discountsIOS!.isNotEmpty) {
        json['discountsIOS'] = discountsIOS!.map((d) => d.toJson()).toList();
      }
      // Add subscriptionInfoIOS with proper structure for OpenIAP
      final subscriptionInfoJson = <String, dynamic>{};

      // Add subscriptionGroupId (convert to string for OpenIAP)
      if (subscriptionGroupIdIOS != null) {
        subscriptionInfoJson['subscriptionGroupId'] =
            subscriptionGroupIdIOS.toString();
      }

      // Add subscriptionPeriod with proper structure
      if (subscriptionPeriodUnitIOS != null &&
          subscriptionPeriodNumberIOS != null) {
        subscriptionInfoJson['subscriptionPeriod'] = {
          'unit': subscriptionPeriodUnitIOS,
          'value': int.tryParse(subscriptionPeriodNumberIOS!) ?? 1,
        };
      }

      // Merge existing subscription info if available
      if (subscription != null) {
        subscriptionInfoJson.addAll(subscription!.toJson());
      }

      if (subscriptionInfoJson.isNotEmpty) {
        json['subscriptionInfoIOS'] = subscriptionInfoJson;
      }

      // Keep these fields for backward compatibility
      if (subscriptionPeriodNumberIOS != null) {
        json['subscriptionPeriodNumberIOS'] = subscriptionPeriodNumberIOS;
      }
      if (subscriptionPeriodUnitIOS != null) {
        json['subscriptionPeriodUnitIOS'] = subscriptionPeriodUnitIOS;
      }
      if (introductoryPriceNumberOfPeriodsIOS != null) {
        json['introductoryPriceNumberOfPeriodsIOS'] =
            introductoryPriceNumberOfPeriodsIOS;
      }
      if (introductoryPriceSubscriptionPeriodIOS != null) {
        json['introductoryPriceSubscriptionPeriodIOS'] =
            introductoryPriceSubscriptionPeriodIOS;
      }
      if (introductoryPricePaymentModeIOS != null) {
        json['introductoryPricePaymentModeIOS'] =
            introductoryPricePaymentModeIOS;
      }
    }

    // Android specific fields
    if (!isIOS) {
      if (nameAndroid != null) json['nameAndroid'] = nameAndroid;
      if (oneTimePurchaseOfferDetailsAndroid != null) {
        json['oneTimePurchaseOfferDetailsAndroid'] =
            oneTimePurchaseOfferDetailsAndroid;
      }
      if (originalPrice != null) json['originalPrice'] = originalPrice;
      if (originalPriceAmount != null) {
        json['originalPriceAmount'] = originalPriceAmount;
      }
      if (freeTrialPeriod != null) json['freeTrialPeriod'] = freeTrialPeriod;
      if (iconUrl != null) json['iconUrl'] = iconUrl;
      // TODO(v6.4.0): Show subscription offer fields only on Android platform
      // Always show Android suffix field (TypeScript compatible)
      if (subscriptionOfferDetailsAndroid != null &&
          subscriptionOfferDetailsAndroid!.isNotEmpty) {
        json['subscriptionOfferDetailsAndroid'] =
            subscriptionOfferDetailsAndroid!.map((o) => o.toJson()).toList();
      }
      if (subscriptionOffersAndroid != null &&
          subscriptionOffersAndroid!.isNotEmpty) {
        json['subscriptionOffersAndroid'] =
            subscriptionOffersAndroid!.map((o) => o.toJson()).toList();
      }
    }

    return json;
  }
}

/// iOS-specific discount information
/// iOS discount (OpenIAP name: Discount)
class DiscountIOS {
  final String identifier;
  final String type;
  final String numberOfPeriods; // Changed to String to match OpenIAP
  final String price;
  final String localizedPrice;
  final String paymentMode;
  final String subscriptionPeriod;

  DiscountIOS({
    required this.identifier,
    required this.type,
    required this.price,
    required this.localizedPrice,
    required this.paymentMode,
    required this.numberOfPeriods,
    required this.subscriptionPeriod,
  });

  factory DiscountIOS.fromJson(Map<String, dynamic> json) {
    return DiscountIOS(
      identifier: json['identifier'] as String? ?? '',
      type: json['type'] as String? ?? '',
      price: _stringFromNumOrString(json['price']),
      localizedPrice: json['localizedPrice'] as String? ?? '',
      paymentMode: json['paymentMode'] as String? ?? '',
      numberOfPeriods: json['numberOfPeriods']?.toString() ?? '0',
      subscriptionPeriod: json['subscriptionPeriod'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'identifier': identifier,
      'type': type,
      'price': price,
      'localizedPrice': localizedPrice,
      'paymentMode': paymentMode,
      'numberOfPeriods': numberOfPeriods,
      'subscriptionPeriod': subscriptionPeriod,
    };
  }

  @Deprecated('[2.0.0] Use DiscountIOS.fromJson instead')
  DiscountIOS.fromJSON(Map<String, dynamic> json)
      : identifier = json['identifier'] as String,
        type = json['type'] as String,
        price = json['price'] as String,
        localizedPrice = json['localizedPrice'] as String,
        paymentMode = json['paymentMode'] as String,
        numberOfPeriods = json['numberOfPeriods']?.toString() ?? '0',
        subscriptionPeriod = json['subscriptionPeriod'] as String;
}

/// Subscription class for subscription items (OpenIAP compliant)
@Deprecated('Use ProductSubscription instead. Will be removed in 6.6.0')
class Subscription extends ProductCommon {
  /// OpenIAP compatibility: ids array containing the productId
  List<String> get ids => [productId ?? ''];

  // iOS fields per OpenIAP spec
  // displayName and displayPrice are inherited from ProductCommon
  final bool? isFamilyShareableIOS;
  final String? jsonRepresentationIOS;
  final List<DiscountIOS>? discountsIOS;
  final SubscriptionInfo? subscription;
  final String? introductoryPriceNumberOfPeriodsIOS;
  final String? introductoryPriceSubscriptionPeriodIOS;
  final String? subscriptionGroupIdIOS;
  final String? subscriptionPeriodUnitIOS;
  final String? subscriptionPeriodNumberIOS;
  final String? introductoryPricePaymentModeIOS;
  final String? environmentIOS; // "Sandbox" | "Production"
  final List<String>? promotionalOfferIdsIOS;

  // Android fields per OpenIAP spec
  final String? nameAndroid;
  final Map<String, dynamic>? oneTimePurchaseOfferDetailsAndroid;
  final String? originalPrice;
  final double? originalPriceAmount;
  final String? freeTrialPeriod;
  final String? iconUrl;
  final List<OfferDetail>? subscriptionOfferDetailsAndroid;
  final String? subscriptionPeriodAndroid;
  final String? introductoryPriceCyclesAndroid;
  final String? introductoryPricePeriodAndroid;
  final String? freeTrialPeriodAndroid;
  final String? signatureAndroid;
  final List<SubscriptionOfferAndroid>? subscriptionOffersAndroid;

  Subscription({
    String? id,
    @Deprecated('Use id instead. Will be removed in 6.6.0')
    String? super.productId,
    required String price,
    required IapPlatform platform,
    super.currency,
    super.localizedPrice,
    super.title,
    super.description,
    String? type,
    super.displayName,
    String? displayPrice,
    // iOS fields per OpenIAP spec
    this.isFamilyShareableIOS,
    this.jsonRepresentationIOS,
    this.discountsIOS,
    this.subscription,
    this.introductoryPriceNumberOfPeriodsIOS,
    this.introductoryPriceSubscriptionPeriodIOS,
    this.subscriptionGroupIdIOS,
    this.subscriptionPeriodUnitIOS,
    this.subscriptionPeriodNumberIOS,
    this.introductoryPricePaymentModeIOS,
    this.environmentIOS,
    this.promotionalOfferIdsIOS,
    // Android fields per OpenIAP spec
    this.nameAndroid,
    this.oneTimePurchaseOfferDetailsAndroid,
    this.originalPrice,
    this.originalPriceAmount,
    this.freeTrialPeriod,
    this.iconUrl,
    this.subscriptionOfferDetailsAndroid,
    this.subscriptionPeriodAndroid,
    this.introductoryPriceCyclesAndroid,
    this.introductoryPricePeriodAndroid,
    this.freeTrialPeriodAndroid,
    this.signatureAndroid,
    this.subscriptionOffersAndroid,
  }) : super(
          id: id ?? productId ?? '',
          type: type ?? 'subs',
          displayPrice: displayPrice ?? (localizedPrice ?? price),
          platformEnum: platform,
          price: double.tryParse(price),
          platform: platform == IapPlatform.ios ? 'ios' : 'android',
        );

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'] as String? ?? '',
      productId: json['productId'] as String? ?? '',
      price: _stringFromNumOrString(json['price']),
      currency: json['currency'] as String?,
      localizedPrice: json['localizedPrice'] as String?,
      title: json['title'] as String?,
      description: json['description'] as String?,
      platform:
          json['platform'] == 'android' ? IapPlatform.android : IapPlatform.ios,
      type: json['type'] as String?,
      // iOS fields per OpenIAP spec
      displayName: json['displayName'] as String?,
      displayPrice: json['displayPrice'] as String?,
      discountsIOS: json['discountsIOS'] != null
          ? (json['discountsIOS'] as List)
              .map((item) {
                final map = _safeJsonMap(item);
                return map != null ? DiscountIOS.fromJson(map) : null;
              })
              .whereType<DiscountIOS>()
              .toList()
          : null,
      subscription: json['subscription'] != null
          ? SubscriptionInfo.fromJson(
              Map<String, dynamic>.from(json['subscription'] as Map),
            )
          : null,
      introductoryPriceNumberOfPeriodsIOS:
          json['introductoryPriceNumberOfPeriodsIOS'] as String?,
      introductoryPriceSubscriptionPeriodIOS:
          json['introductoryPriceSubscriptionPeriodIOS'] as String?,
      subscriptionGroupIdIOS: json['subscriptionGroupIdIOS'] as String?,
      subscriptionPeriodUnitIOS: json['subscriptionPeriodUnitIOS'] as String?,
      subscriptionPeriodNumberIOS:
          json['subscriptionPeriodNumberIOS'] as String?,
      introductoryPricePaymentModeIOS:
          json['introductoryPricePaymentModeIOS'] as String?,
      environmentIOS: json['environmentIOS'] as String?,
      promotionalOfferIdsIOS: json['promotionalOfferIdsIOS'] != null
          ? (json['promotionalOfferIdsIOS'] as List).cast<String>()
          : null,
      // Android fields per OpenIAP spec
      nameAndroid: json['nameAndroid'] as String?,
      oneTimePurchaseOfferDetailsAndroid:
          json['oneTimePurchaseOfferDetailsAndroid'] != null
              ? Map<String, dynamic>.from(
                  json['oneTimePurchaseOfferDetailsAndroid'] as Map,
                )
              : null,
      originalPrice: json['originalPrice'] as String?,
      originalPriceAmount: (json['originalPriceAmount'] as num?)?.toDouble(),
      freeTrialPeriod: json['freeTrialPeriod'] as String?,
      iconUrl: json['iconUrl'] as String?,
      // Use new Android suffix field if available, fallback to old field for compatibility
      subscriptionOfferDetailsAndroid:
          json['subscriptionOfferDetailsAndroid'] != null
              ? (json['subscriptionOfferDetailsAndroid'] as List)
                  .map((item) {
                    final map = _safeJsonMap(item);
                    return map != null ? OfferDetail.fromJson(map) : null;
                  })
                  .whereType<OfferDetail>()
                  .toList()
              : null,
      subscriptionPeriodAndroid: json['subscriptionPeriodAndroid'] as String?,
      introductoryPriceCyclesAndroid:
          json['introductoryPriceCyclesAndroid'] as String?,
      introductoryPricePeriodAndroid:
          json['introductoryPricePeriodAndroid'] as String?,
      freeTrialPeriodAndroid: json['freeTrialPeriodAndroid'] as String?,
      signatureAndroid: json['signatureAndroid'] as String?,
      subscriptionOffersAndroid: json['subscriptionOffersAndroid'] != null
          ? (json['subscriptionOffersAndroid'] as List)
              .map(
                (o) => SubscriptionOfferAndroid.fromJson(
                  _safeJsonMap(o) ?? {},
                ),
              )
              .toList()
          : null,
    );
  }

  @override
  String toString() {
    final buffer = StringBuffer('Subscription{\n');
    buffer.writeln('  productId: $productId,');
    buffer.writeln('  id: $id,');
    buffer.writeln('  title: $title,');
    buffer.writeln('  description: $description,');
    buffer.writeln('  type: $type,');
    buffer.writeln('  price: $price,');
    buffer.writeln('  currency: $currency,');
    buffer.writeln('  localizedPrice: $localizedPrice,');
    buffer.writeln(
      '  platform: ${platform ?? (platformEnum == IapPlatform.ios ? 'ios' : 'android')},',
    );

    // iOS specific fields (only show non-null)
    if (displayName != null) buffer.writeln('  displayName: $displayName,');
    buffer.writeln('  displayPrice: $displayPrice,');
    if (isFamilyShareableIOS != null) {
      buffer.writeln('  isFamilyShareableIOS: $isFamilyShareableIOS,');
    }
    if (jsonRepresentationIOS != null) {
      buffer.writeln(
        '  jsonRepresentationIOS: ${jsonRepresentationIOS!.length > 100 ? '${jsonRepresentationIOS!.substring(0, 100)}...' : jsonRepresentationIOS},',
      );
    }
    if (environmentIOS != null) {
      buffer.writeln('  environmentIOS: $environmentIOS,');
    }
    if (subscriptionGroupIdIOS != null) {
      buffer.writeln('  subscriptionGroupIdIOS: $subscriptionGroupIdIOS,');
    }
    if (subscriptionPeriodUnitIOS != null) {
      buffer.writeln(
        '  subscriptionPeriodUnitIOS: $subscriptionPeriodUnitIOS,',
      );
    }
    if (subscriptionPeriodNumberIOS != null) {
      buffer.writeln(
        '  subscriptionPeriodNumberIOS: $subscriptionPeriodNumberIOS,',
      );
    }
    if (introductoryPriceNumberOfPeriodsIOS != null) {
      buffer.writeln(
        '  introductoryPriceNumberOfPeriodsIOS: $introductoryPriceNumberOfPeriodsIOS,',
      );
    }
    if (introductoryPriceSubscriptionPeriodIOS != null) {
      buffer.writeln(
        '  introductoryPriceSubscriptionPeriodIOS: $introductoryPriceSubscriptionPeriodIOS,',
      );
    }
    if (introductoryPricePaymentModeIOS != null) {
      buffer.writeln(
        '  introductoryPricePaymentModeIOS: $introductoryPricePaymentModeIOS,',
      );
    }
    if (promotionalOfferIdsIOS != null && promotionalOfferIdsIOS!.isNotEmpty) {
      buffer.writeln(
        '  promotionalOfferIdsIOS: ${promotionalOfferIdsIOS!.length} offer(s),',
      );
    }
    if (discountsIOS != null && discountsIOS!.isNotEmpty) {
      buffer.writeln('  discountsIOS: ${discountsIOS!.length} discount(s),');
    }
    if (subscription != null) {
      buffer.writeln('  subscription: ${subscription.toString()},');
    }

    // Android specific fields (only show non-null)
    if (originalPrice != null) {
      buffer.writeln('  originalPrice: $originalPrice,');
    }
    if (originalPriceAmount != null) {
      buffer.writeln('  originalPriceAmount: $originalPriceAmount,');
    }
    if (freeTrialPeriod != null) {
      buffer.writeln('  freeTrialPeriod: $freeTrialPeriod,');
    }
    if (iconUrl != null) buffer.writeln('  iconUrl: $iconUrl,');
    if (subscriptionPeriodAndroid != null) {
      buffer.writeln(
        '  subscriptionPeriodAndroid: $subscriptionPeriodAndroid,',
      );
    }
    if (subscriptionOffersAndroid != null &&
        subscriptionOffersAndroid!.isNotEmpty) {
      buffer.writeln(
        '  subscriptionOffersAndroid: ${subscriptionOffersAndroid!.length} offer(s),',
      );
    }

    // Remove last comma and close
    final str = buffer.toString();
    if (str.endsWith(',\n')) {
      return '${str.substring(0, str.length - 2)}\n}';
    }
    return '$str}';
  }

  /// Convert iOS native product types to OpenIAP standard types
  String _convertTypeForOpenIAP(String type, bool isIOS) {
    if (!isIOS) return type; // Android types are already correct

    switch (type.toLowerCase()) {
      case 'consumable':
      case 'nonconsumable':
      case 'nonrenewable':
        return 'inapp';
      case 'autorenewable':
        return 'subs';
      default:
        return type; // Return as-is if not recognized
    }
  }

  Map<String, dynamic> toJson() {
    // Determine if this is iOS or Android
    final isIOS = platformEnum == IapPlatform.ios;

    final json = <String, dynamic>{
      'id': id,
      'title': title ?? '',
      'description': description ?? '',
      'type': _convertTypeForOpenIAP(type, isIOS),
      'currency': currency ?? '',
      'platform': isIOS ? 'ios' : 'android', // Use string literal
    };

    // Price field (as number for iOS type compatibility)
    if (price != null) {
      json['price'] = price;
    }

    // displayPrice field (required for iOS)
    json['displayPrice'] = displayPrice;
    if (localizedPrice != null && displayPrice != localizedPrice) {
      json['localizedPrice'] = localizedPrice; // Include if different
    }

    // Optional displayName field
    if (displayName != null) {
      json['displayName'] = displayName;
    }

    // iOS specific fields with correct naming
    if (isIOS) {
      if (displayName != null) {
        json['displayNameIOS'] = displayName;
      }
      // Add OpenIAP compliant iOS fields for ProductIOS
      if (this is ProductIOS) {
        final productIOS = this as ProductIOS;
        if (productIOS.isFamilyShareableIOS != null) {
          json['isFamilyShareableIOS'] = productIOS.isFamilyShareableIOS;
        }
        if (productIOS.jsonRepresentationIOS != null) {
          json['jsonRepresentationIOS'] = productIOS.jsonRepresentationIOS;
        }
      }
      // Add OpenIAP compliant iOS fields for Subscription
      // Note: In Product class, this check is needed; in Subscription class, it's redundant
      else // Remove unnecessary cast since we know the type
      if ((this as dynamic).isFamilyShareableIOS != null) {
        json['isFamilyShareableIOS'] = (this as dynamic).isFamilyShareableIOS;
      }
      if ((this as dynamic).jsonRepresentationIOS != null) {
        json['jsonRepresentationIOS'] = (this as dynamic).jsonRepresentationIOS;
      }

      if (environmentIOS != null) {
        json['environmentIOS'] = environmentIOS;
      }
      if (subscriptionGroupIdIOS != null) {
        json['subscriptionGroupIdIOS'] = subscriptionGroupIdIOS;
      }
      if (promotionalOfferIdsIOS != null &&
          promotionalOfferIdsIOS!.isNotEmpty) {
        json['promotionalOfferIdsIOS'] = promotionalOfferIdsIOS;
      }
      if (discountsIOS != null && discountsIOS!.isNotEmpty) {
        json['discountsIOS'] = discountsIOS!.map((d) => d.toJson()).toList();
      }
      // Add subscriptionInfoIOS with proper structure for OpenIAP
      final subscriptionInfoJson = <String, dynamic>{};

      // Add subscriptionGroupId (convert to string for OpenIAP)
      if (subscriptionGroupIdIOS != null) {
        subscriptionInfoJson['subscriptionGroupId'] =
            subscriptionGroupIdIOS.toString();
      }

      // Add subscriptionPeriod with proper structure
      if (subscriptionPeriodUnitIOS != null &&
          subscriptionPeriodNumberIOS != null) {
        subscriptionInfoJson['subscriptionPeriod'] = {
          'unit': subscriptionPeriodUnitIOS,
          'value': int.tryParse(subscriptionPeriodNumberIOS!) ?? 1,
        };
      }

      // Merge existing subscription info if available
      if (subscription != null) {
        subscriptionInfoJson.addAll(subscription!.toJson());
      }

      if (subscriptionInfoJson.isNotEmpty) {
        json['subscriptionInfoIOS'] = subscriptionInfoJson;
      }

      // Keep these fields for backward compatibility
      if (subscriptionPeriodNumberIOS != null) {
        json['subscriptionPeriodNumberIOS'] = subscriptionPeriodNumberIOS;
      }
      if (subscriptionPeriodUnitIOS != null) {
        json['subscriptionPeriodUnitIOS'] = subscriptionPeriodUnitIOS;
      }
      if (introductoryPriceNumberOfPeriodsIOS != null) {
        json['introductoryPriceNumberOfPeriodsIOS'] =
            introductoryPriceNumberOfPeriodsIOS;
      }
      if (introductoryPriceSubscriptionPeriodIOS != null) {
        json['introductoryPriceSubscriptionPeriodIOS'] =
            introductoryPriceSubscriptionPeriodIOS;
      }
      if (introductoryPricePaymentModeIOS != null) {
        json['introductoryPricePaymentModeIOS'] =
            introductoryPricePaymentModeIOS;
      }
    }

    // Android specific fields
    if (!isIOS) {
      if (nameAndroid != null) json['nameAndroid'] = nameAndroid;
      if (oneTimePurchaseOfferDetailsAndroid != null) {
        json['oneTimePurchaseOfferDetailsAndroid'] =
            oneTimePurchaseOfferDetailsAndroid;
      }
      if (originalPrice != null) json['originalPrice'] = originalPrice;
      if (originalPriceAmount != null) {
        json['originalPriceAmount'] = originalPriceAmount;
      }
      if (freeTrialPeriod != null) json['freeTrialPeriod'] = freeTrialPeriod;
      if (iconUrl != null) json['iconUrl'] = iconUrl;
      // TODO(v6.4.0): Show subscription offer fields only on Android platform
      // Always show Android suffix field (TypeScript compatible)
      if (subscriptionOfferDetailsAndroid != null &&
          subscriptionOfferDetailsAndroid!.isNotEmpty) {
        json['subscriptionOfferDetailsAndroid'] =
            subscriptionOfferDetailsAndroid!.map((o) => o.toJson()).toList();
      }
      if (subscriptionOffersAndroid != null &&
          subscriptionOffersAndroid!.isNotEmpty) {
        json['subscriptionOffersAndroid'] =
            subscriptionOffersAndroid!.map((o) => o.toJson()).toList();
      }
    }

    return json;
  }
}

/// Preferred subscription type name (OpenIAP compliant)
/// Use this instead of [Subscription].
typedef ProductSubscription = Subscription;

/// iOS-specific product class (OpenIAP compliant)
class ProductIOS extends Product {
  // OpenIAP compliant iOS fields
  final bool? isFamilyShareableIOS;
  final String? jsonRepresentationIOS;
  // Additional iOS fields
  final String? subscriptionGroupIdentifier;
  final String? subscriptionPeriodUnit;
  final String? subscriptionPeriodNumber;
  final String? introductoryPricePaymentMode;
  final String? environment; // "Sandbox" | "Production"
  final List<String>? promotionalOfferIds;
  final List<DiscountIOS>? discounts;

  ProductIOS({
    String? id,
    @Deprecated('Use id instead. Will be removed in 6.6.0') String? productId,
    required String price,
    super.currency,
    super.localizedPrice,
    super.title,
    super.description,
    super.type,
    super.displayName,
    bool? isFamilyShareable,
    String? jsonRepresentation,
    super.subscription,
    super.introductoryPriceNumberOfPeriodsIOS,
    super.introductoryPriceSubscriptionPeriodIOS,
    // OpenIAP compliant iOS fields
    this.isFamilyShareableIOS,
    this.jsonRepresentationIOS,
    // Additional iOS fields
    this.subscriptionGroupIdentifier,
    this.subscriptionPeriodUnit,
    this.subscriptionPeriodNumber,
    this.introductoryPricePaymentMode,
    this.environment,
    this.promotionalOfferIds,
    this.discounts,
  }) : super(
          id: id ?? productId,
          productId: productId,
          priceString: price,
          platformEnum: IapPlatform.ios,
          subscriptionGroupIdIOS: subscriptionGroupIdentifier,
          subscriptionPeriodUnitIOS: subscriptionPeriodUnit,
          subscriptionPeriodNumberIOS: subscriptionPeriodNumber,
          introductoryPricePaymentModeIOS: introductoryPricePaymentMode,
          environmentIOS: environment,
          promotionalOfferIdsIOS: promotionalOfferIds,
          discountsIOS: discounts,
        );

  factory ProductIOS.fromJson(Map<String, dynamic> json) {
    return ProductIOS(
      id: (json['id'] as String?) ??
          (json['productId'] as String?) ??
          (json['sku'] as String?) ??
          (json['productIdentifier'] as String?),
      productId: json['productId'] as String?,
      price: _stringFromNumOrString(json['price']),
      currency: json['currency'] as String?,
      localizedPrice: json['localizedPrice'] as String?,
      title: json['title'] as String?,
      description: json['description'] as String?,
      type: json['type'] as String?,
      displayName: json['displayName'] as String?,
      // OpenIAP compliant iOS fields
      isFamilyShareableIOS: json['isFamilyShareableIOS'] as bool? ??
          json['isFamilyShareable'] as bool?,
      jsonRepresentationIOS: json['jsonRepresentationIOS'] as String? ??
          json['jsonRepresentation'] as String?,
      // Additional iOS fields
      subscriptionGroupIdentifier:
          json['subscriptionGroupIdentifier'] as String?,
      subscriptionPeriodUnit: json['subscriptionPeriodUnit'] as String?,
      subscriptionPeriodNumber: json['subscriptionPeriodNumber'] as String?,
      introductoryPricePaymentMode:
          json['introductoryPricePaymentMode'] as String?,
      environment: json['environment'] as String?,
      promotionalOfferIds: json['promotionalOfferIds'] != null
          ? (json['promotionalOfferIds'] as List).cast<String>()
          : null,
      discounts: json['discounts'] != null
          ? (json['discounts'] as List)
              .map((item) {
                final map = _safeJsonMap(item);
                return map != null ? DiscountIOS.fromJson(map) : null;
              })
              .whereType<DiscountIOS>()
              .toList()
          : null,
    );
  }
}

/// Android-specific product class (OpenIAP compliant)
class ProductAndroid extends Product {
  final String? subscriptionPeriod;
  final String? introductoryPriceCycles;
  final String? introductoryPricePeriod;
  final String? signature;
  final List<SubscriptionOfferAndroid>? subscriptionOffers;

  ProductAndroid({
    String? id,
    @Deprecated('Use id instead. Will be removed in 6.6.0') String? productId,
    required String price,
    super.currency,
    super.localizedPrice,
    super.title,
    super.description,
    super.type,
    super.originalPrice,
    super.originalPriceAmount,
    super.iconUrl,
    super.freeTrialPeriod,
    super.subscriptionOfferDetailsAndroid,
    this.subscriptionPeriod,
    this.introductoryPriceCycles,
    this.introductoryPricePeriod,
    this.signature,
    this.subscriptionOffers,
  }) : super(
          id: id ?? productId,
          productId: productId,
          priceString: price,
          platformEnum: IapPlatform.android,
          subscriptionPeriodAndroid: subscriptionPeriod,
          introductoryPriceCyclesAndroid: introductoryPriceCycles,
          introductoryPricePeriodAndroid: introductoryPricePeriod,
          freeTrialPeriodAndroid: freeTrialPeriod,
          signatureAndroid: signature,
          subscriptionOffersAndroid: subscriptionOffers,
        );

  factory ProductAndroid.fromJson(Map<String, dynamic> json) {
    return ProductAndroid(
      id: (json['id'] as String?) ?? (json['productId'] as String?),
      productId: json['productId'] as String?,
      price: _stringFromNumOrString(json['price']),
      currency: json['currency'] as String?,
      localizedPrice: json['localizedPrice'] as String?,
      title: json['title'] as String?,
      description: json['description'] as String?,
      type: json['type'] as String?,
      originalPrice: json['originalPrice'] as String?,
      subscriptionPeriod: json['subscriptionPeriod'] as String?,
      introductoryPriceCycles: json['introductoryPriceCycles'] as String?,
      introductoryPricePeriod: json['introductoryPricePeriod'] as String?,
      freeTrialPeriod: json['freeTrialPeriod'] as String?,
      signature: json['signature'] as String?,
      subscriptionOffers: json['subscriptionOffers'] != null
          ? (json['subscriptionOffers'] as List)
              .map(
                (o) => SubscriptionOfferAndroid.fromJson(
                  _safeJsonMap(o) ?? {},
                ),
              )
              .toList()
          : null,
      originalPriceAmount: (json['originalPriceAmount'] as num?)?.toDouble(),
      iconUrl: json['iconUrl'] as String?,
      // Note: subscriptionOfferDetailsAndroid is only in Product class
    );
  }
}

/// Recurrence mode enum (OpenIAP compliant)
enum RecurrenceMode { infiniteRecurring, finiteRecurring, nonRecurring }

/// Subscription info for iOS (OpenIAP compliant)
class SubscriptionInfo {
  final String? subscriptionGroupId;
  final Map<String, dynamic>? subscriptionPeriod;
  final Map<String, dynamic>? introductoryOffer;
  final List<dynamic>? promotionalOffers;
  final String? introductoryPrice;

  SubscriptionInfo({
    this.subscriptionGroupId,
    this.subscriptionPeriod,
    this.introductoryOffer,
    this.promotionalOffers,
    this.introductoryPrice,
  });

  factory SubscriptionInfo.fromJson(Map<String, dynamic> json) {
    return SubscriptionInfo(
      subscriptionGroupId: json['subscriptionGroupId'] as String?,
      subscriptionPeriod: json['subscriptionPeriod'] != null
          ? Map<String, dynamic>.from(json['subscriptionPeriod'] as Map)
          : null,
      introductoryOffer: json['introductoryOffer'] != null
          ? Map<String, dynamic>.from(json['introductoryOffer'] as Map)
          : null,
      promotionalOffers: json['promotionalOffers'] as List<dynamic>?,
      introductoryPrice: json['introductoryPrice'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (subscriptionGroupId != null) {
      json['subscriptionGroupId'] = subscriptionGroupId;
    }
    if (subscriptionPeriod != null) {
      json['subscriptionPeriod'] = subscriptionPeriod;
    }
    if (introductoryOffer != null) {
      json['introductoryOffer'] = introductoryOffer;
    }
    if (promotionalOffers != null) {
      json['promotionalOffers'] = promotionalOffers;
    }
    if (introductoryPrice != null) {
      json['introductoryPrice'] = introductoryPrice;
    }
    return json;
  }
}

/// Introductory price info
class IntroductoryPrice {
  final double priceValue;
  final String priceString;
  final String period;
  final int cycles;
  final String? paymentMode;
  final int? paymentModeValue;

  IntroductoryPrice({
    required this.priceValue,
    required this.priceString,
    required this.period,
    required this.cycles,
    this.paymentMode,
    this.paymentModeValue,
  });
}

/// Promotional offer
class PromotionalOffer {
  final double priceValue;
  final String priceString;
  final int cycles;
  final String period;
  final String? paymentMode;
  final int? paymentModeValue;

  PromotionalOffer({
    required this.priceValue,
    required this.priceString,
    required this.cycles,
    required this.period,
    this.paymentMode,
    this.paymentModeValue,
  });
}

/// Offer detail for Android (OpenIAP compliant)
class OfferDetail {
  final String basePlanId;
  final String? offerId;
  final List<PricingPhase> pricingPhases;
  final String? offerToken;
  final List<String>? offerTags;

  OfferDetail({
    required this.basePlanId,
    required this.pricingPhases,
    this.offerId,
    this.offerToken,
    this.offerTags,
  });

  factory OfferDetail.fromJson(Map<String, dynamic> json) {
    // Handle pricingPhases which can be either:
    // 1. A list of phases directly (legacy)
    // 2. An object with 'pricingPhaseList' property (new Android structure)
    List<PricingPhase> phases;
    final pricingPhasesData = json['pricingPhases'];

    if (pricingPhasesData is List) {
      // Legacy format: direct list
      phases = pricingPhasesData
          .map((item) {
            final map = _safeJsonMap(item);
            return map != null ? PricingPhase.fromJson(map) : null;
          })
          .whereType<PricingPhase>()
          .toList();
    } else if (pricingPhasesData is Map &&
        pricingPhasesData['pricingPhaseList'] != null) {
      // New Android format: object with pricingPhaseList
      phases = (pricingPhasesData['pricingPhaseList'] as List)
          .map((item) {
            final map = _safeJsonMap(item);
            return map != null ? PricingPhase.fromJson(map) : null;
          })
          .whereType<PricingPhase>()
          .toList();
    } else {
      phases = [];
    }

    return OfferDetail(
      basePlanId: json['basePlanId'] as String? ?? '',
      offerId: json['offerId'] as String?,
      pricingPhases: phases,
      offerToken: json['offerToken'] as String?,
      offerTags: (json['offerTags'] as List?)?.cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'basePlanId': basePlanId,
      'offerId': offerId, // Always include offerId (can be null)
      // Use nested structure to match TypeScript type
      'pricingPhases': {
        'pricingPhaseList': pricingPhases.map((p) => p.toJson()).toList(),
      },
      'offerToken': offerToken,
      'offerTags': offerTags ?? [],
    };
    return json;
  }
}

/// Verification result for iOS (OpenIAP compliant)
class VerificationResult {
  final bool isVerified;
  final String? verificationError;
  final Map<String, dynamic>? data;

  VerificationResult({
    required this.isVerified,
    this.verificationError,
    this.data,
  });
}

/// Subscription offer details (kept for compatibility)
class SubscriptionOffer {
  final String sku;
  final String offerToken;
  final List<PricingPhase> pricingPhases;

  SubscriptionOffer({
    required this.sku,
    required this.offerToken,
    required this.pricingPhases,
  });
}

/// Pricing phase for subscriptions (OpenIAP compliant)
class PricingPhase {
  final double priceAmount;
  final String price;
  final String currency;
  final String? billingPeriod;
  final int? billingCycleCount;
  final RecurrenceMode? recurrenceMode;

  PricingPhase({
    required this.priceAmount,
    required this.price,
    required this.currency,
    this.billingPeriod,
    this.billingCycleCount,
    this.recurrenceMode,
  });

  factory PricingPhase.fromJson(Map<String, dynamic> json) {
    // Handle different field names from Android native
    double priceAmount;
    if (json['priceAmount'] != null) {
      priceAmount = (json['priceAmount'] as num).toDouble();
    } else if (json['priceAmountMicros'] != null) {
      // Convert micros to regular amount
      final micros = json['priceAmountMicros'];
      if (micros is String) {
        priceAmount = (int.tryParse(micros) ?? 0) / 1000000.0;
      } else if (micros is num) {
        priceAmount = micros / 1000000.0;
      } else {
        priceAmount = 0.0;
      }
    } else {
      priceAmount = 0.0;
    }

    return PricingPhase(
      priceAmount: priceAmount,
      price:
          json['price'] as String? ?? json['formattedPrice'] as String? ?? '0',
      currency: json['currency'] as String? ??
          json['priceCurrencyCode'] as String? ??
          'USD',
      billingPeriod: json['billingPeriod'] as String?,
      billingCycleCount: json['billingCycleCount'] as int?,
      recurrenceMode: json['recurrenceMode'] != null
          ? RecurrenceMode.values[json['recurrenceMode'] as int]
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      // Use TypeScript-expected field names
      'formattedPrice': price,
      'priceCurrencyCode': currency,
      'priceAmountMicros': (priceAmount * 1000000).toStringAsFixed(0),
    };
    if (billingPeriod != null) json['billingPeriod'] = billingPeriod;
    if (billingCycleCount != null) {
      json['billingCycleCount'] = billingCycleCount;
    }
    if (recurrenceMode != null) json['recurrenceMode'] = recurrenceMode?.index;
    return json;
  }
}

/// Purchase class (OpenIAP compliant)
class Purchase {
  final String productId;
  final String? transactionId;
  final int? transactionDate; // Unix timestamp in milliseconds
  final String? transactionReceipt;
  final String? purchaseToken;
  final String? orderId;
  final String? packageName;
  final PurchaseState? purchaseState;
  final bool? isAcknowledged;
  final bool? autoRenewing;
  final String? originalJson;
  final String? developerPayload;
  final String? originalOrderId;
  final int? purchaseTime;
  final IapPlatform platform;
  // iOS specific fields per OpenIAP spec
  final String? originalTransactionDateIOS;
  final String? originalTransactionIdentifierIOS;
  final bool? isUpgradeIOS;
  final TransactionState? transactionStateIOS;
  final VerificationResult? verificationResultIOS;
  final String? environmentIOS; // "Sandbox" | "Production"
  final DateTime? expirationDateIOS;
  final DateTime? revocationDateIOS;
  final String? revocationReasonIOS;
  final String? appAccountTokenIOS;
  final String? webOrderLineItemIdIOS;
  final String? subscriptionGroupIdIOS;
  final bool? isUpgradedIOS;
  final String? offerCodeRefNameIOS;
  final String? offerIdentifierIOS;
  final int? offerTypeIOS;
  final String? signedDateIOS;
  final String? storeFrontIOS;
  final String? storeFrontCountryCodeIOS;
  final String? currencyCodeIOS;
  final double? priceIOS;
  final String? jsonRepresentationIOS;
  final bool? isFinishedIOS;
  final int? quantityIOS;
  final String? appBundleIdIOS;
  final String? productTypeIOS;
  final String? ownershipTypeIOS;
  final String? transactionReasonIOS;
  final String? reasonIOS;
  final Map<String, dynamic>? offerIOS;
  final String? jwsRepresentationIOS;
  // Android specific fields per OpenIAP spec
  final String? signatureAndroid;
  final bool? autoRenewingAndroid;
  final String? orderIdAndroid;
  final String? packageNameAndroid;
  final String? developerPayloadAndroid;
  final bool? acknowledgedAndroid;
  final bool? isAcknowledgedAndroid;
  final int? purchaseStateAndroid;
  final String? purchaseTokenAndroid;
  final String? dataAndroid;
  final String? obfuscatedAccountIdAndroid;
  final String? obfuscatedProfileIdAndroid;
  final String? originalJsonAndroid;
  final List<String>? productsAndroid; // For multi-SKU purchases
  final List<String>? skusAndroid; // Legacy field
  final bool? isAutoRenewingAndroid; // Duplicate for compatibility
  final String? replacementTokenAndroid;
  final int? priceAmountMicrosAndroid;
  final String? priceCurrencyCodeAndroid;
  final String? countryCodeAndroid;
  // ProductPurchase fields (legacy)
  final bool? isConsumedAndroid;

  /// OpenIAP compatibility: id field maps to transactionId (not productId!)
  /// Returns transactionId if available, otherwise returns empty string
  String get id => transactionId ?? '';

  /// OpenIAP compatibility: ids array containing the productId
  List<String> get ids => [productId];

  /// Common quantity field (OpenIAP compliant)
  /// iOS supports quantity; Android defaults to 1
  int get quantity => quantityIOS ?? 1;

  /// Common auto-renew flag across platforms
  bool get isAutoRenewing =>
      autoRenewing == true ||
      autoRenewingAndroid == true ||
      isAutoRenewingAndroid == true;

  Purchase({
    required this.productId,
    required this.platform,
    this.transactionId,
    this.transactionDate,
    this.transactionReceipt,
    this.purchaseToken,
    this.orderId,
    this.packageName,
    this.purchaseState,
    this.isAcknowledged,
    this.autoRenewing,
    this.originalJson,
    this.developerPayload,
    this.originalOrderId,
    this.purchaseTime,
    // iOS specific per OpenIAP spec
    this.originalTransactionDateIOS,
    this.originalTransactionIdentifierIOS,
    this.isUpgradeIOS,
    this.transactionStateIOS,
    this.verificationResultIOS,
    this.environmentIOS,
    this.expirationDateIOS,
    this.revocationDateIOS,
    this.revocationReasonIOS,
    this.appAccountTokenIOS,
    this.webOrderLineItemIdIOS,
    this.subscriptionGroupIdIOS,
    this.isUpgradedIOS,
    this.offerCodeRefNameIOS,
    this.offerIdentifierIOS,
    this.offerTypeIOS,
    this.signedDateIOS,
    this.storeFrontIOS,
    this.storeFrontCountryCodeIOS,
    this.currencyCodeIOS,
    this.priceIOS,
    this.jsonRepresentationIOS,
    this.isFinishedIOS,
    this.quantityIOS,
    this.appBundleIdIOS,
    this.productTypeIOS,
    this.ownershipTypeIOS,
    this.transactionReasonIOS,
    this.reasonIOS,
    this.offerIOS,
    this.jwsRepresentationIOS,
    // Android specific per OpenIAP spec
    this.signatureAndroid,
    this.autoRenewingAndroid,
    this.orderIdAndroid,
    this.packageNameAndroid,
    this.developerPayloadAndroid,
    this.acknowledgedAndroid,
    this.isAcknowledgedAndroid,
    this.purchaseStateAndroid,
    this.purchaseTokenAndroid,
    this.dataAndroid,
    this.obfuscatedAccountIdAndroid,
    this.obfuscatedProfileIdAndroid,
    this.originalJsonAndroid,
    this.productsAndroid,
    this.skusAndroid,
    this.isAutoRenewingAndroid,
    this.replacementTokenAndroid,
    this.priceAmountMicrosAndroid,
    this.priceCurrencyCodeAndroid,
    this.countryCodeAndroid,
    // ProductPurchase fields
    this.isConsumedAndroid,
  });

  factory Purchase.fromJson(Map<String, dynamic> json) {
    return Purchase(
      productId: json['productId'] as String? ?? '',
      transactionId: json['transactionId'] as String?,
      transactionDate: json['transactionDate'] is int
          ? json['transactionDate'] as int
          : json['transactionDate'] is String
              ? int.tryParse(json['transactionDate'] as String)
              : null,
      transactionReceipt: json['transactionReceipt'] as String?,
      purchaseToken: json['purchaseToken'] as String?,
      orderId: json['orderId'] as String?,
      packageName: json['packageName'] as String?,
      purchaseState: json['purchaseState'] != null
          ? PurchaseState.values[json['purchaseState'] as int]
          : null,
      isAcknowledged: json['isAcknowledged'] as bool?,
      autoRenewing: json['autoRenewing'] as bool?,
      originalJson: json['originalJson'] as String?,
      developerPayload: json['developerPayload'] as String?,
      originalOrderId: json['originalOrderId'] as String?,
      purchaseTime: json['purchaseTime'] as int?,
      // Infer platform from JSON when available to allow tests on non-mobile hosts.
      platform: (json['platform'] is String)
          ? ((json['platform'] as String).toLowerCase() == 'android'
              ? IapPlatform.android
              : IapPlatform.ios)
          : getCurrentPlatform(),
      // iOS specific per OpenIAP spec
      originalTransactionDateIOS: json['originalTransactionDateIOS'] as String?,
      originalTransactionIdentifierIOS:
          json['originalTransactionIdentifierIOS'] as String?,
      isUpgradeIOS: json['isUpgradeIOS'] as bool?,
      transactionStateIOS: json['transactionStateIOS'] != null
          ? TransactionState.values[json['transactionStateIOS'] as int]
          : null,
      verificationResultIOS: json['verificationResultIOS'] != null
          ? VerificationResult(
              isVerified: json['verificationResultIOS']['isVerified'] as bool,
              verificationError:
                  json['verificationResultIOS']['verificationError'] as String?,
              data: _safeJsonMap(json['verificationResultIOS']['data']),
            )
          : null,
      environmentIOS: json['environmentIOS'] as String?,
      expirationDateIOS: json['expirationDateIOS'] != null
          ? DateTime.tryParse(json['expirationDateIOS'] as String)
          : null,
      revocationDateIOS: json['revocationDateIOS'] != null
          ? DateTime.tryParse(json['revocationDateIOS'] as String)
          : null,
      revocationReasonIOS: json['revocationReasonIOS'] as String?,
      appAccountTokenIOS: json['appAccountTokenIOS'] as String?,
      webOrderLineItemIdIOS: json['webOrderLineItemIdIOS'] as String?,
      subscriptionGroupIdIOS: json['subscriptionGroupIdIOS'] as String?,
      isUpgradedIOS: json['isUpgradedIOS'] as bool?,
      offerCodeRefNameIOS: json['offerCodeRefNameIOS'] as String?,
      offerIdentifierIOS: json['offerIdentifierIOS'] as String?,
      offerTypeIOS: json['offerTypeIOS'] as int?,
      signedDateIOS: json['signedDateIOS'] as String?,
      storeFrontIOS: json['storeFrontIOS'] as String?,
      storeFrontCountryCodeIOS: json['storeFrontCountryCodeIOS'] as String?,
      currencyCodeIOS: json['currencyCodeIOS'] as String?,
      priceIOS: (json['priceIOS'] as num?)?.toDouble(),
      jsonRepresentationIOS: json['jsonRepresentationIOS'] as String?,
      isFinishedIOS: json['isFinishedIOS'] as bool?,
      quantityIOS: json['quantityIOS'] as int?,
      appBundleIdIOS: json['appBundleIdIOS'] as String?,
      productTypeIOS: json['productTypeIOS'] as String?,
      ownershipTypeIOS: json['ownershipTypeIOS'] as String?,
      transactionReasonIOS: json['transactionReasonIOS'] as String?,
      reasonIOS: json['reasonIOS'] as String?,
      offerIOS: json['offerIOS'] != null
          ? Map<String, dynamic>.from(json['offerIOS'] as Map)
          : null,
      jwsRepresentationIOS: json['jwsRepresentationIOS'] as String?,
      // Android specific per OpenIAP spec
      signatureAndroid: json['signatureAndroid'] as String?,
      autoRenewingAndroid: json['autoRenewingAndroid'] as bool?,
      orderIdAndroid: json['orderIdAndroid'] as String?,
      packageNameAndroid: json['packageNameAndroid'] as String?,
      developerPayloadAndroid: json['developerPayloadAndroid'] as String?,
      acknowledgedAndroid: json['acknowledgedAndroid'] as bool?,
      isAcknowledgedAndroid: json['isAcknowledgedAndroid'] as bool?,
      purchaseStateAndroid: json['purchaseStateAndroid'] as int?,
      purchaseTokenAndroid: json['purchaseTokenAndroid'] as String?,
      dataAndroid: json['dataAndroid'] as String?,
      obfuscatedAccountIdAndroid: json['obfuscatedAccountIdAndroid'] as String?,
      obfuscatedProfileIdAndroid: json['obfuscatedProfileIdAndroid'] as String?,
      originalJsonAndroid: json['originalJsonAndroid'] as String?,
      productsAndroid: json['productsAndroid'] != null
          ? (json['productsAndroid'] as List).cast<String>()
          : null,
      skusAndroid: json['skusAndroid'] != null
          ? (json['skusAndroid'] as List).cast<String>()
          : null,
      isAutoRenewingAndroid: json['isAutoRenewingAndroid'] as bool?,
      replacementTokenAndroid: json['replacementTokenAndroid'] as String?,
      priceAmountMicrosAndroid: json['priceAmountMicrosAndroid'] as int?,
      priceCurrencyCodeAndroid: json['priceCurrencyCodeAndroid'] as String?,
      countryCodeAndroid: json['countryCodeAndroid'] as String?,
      // ProductPurchase fields
      isConsumedAndroid: json['isConsumedAndroid'] as bool?,
    );
  }

  @override
  String toString() {
    // Helper function to truncate long strings
    String? truncate(String? str, [int maxLength = 100]) {
      if (str == null) return null;
      if (str.length <= maxLength) return str;
      return '${str.substring(0, maxLength)}... (${str.length} chars)';
    }

    final buffer = StringBuffer('Purchase{\n');
    // Core fields
    buffer.writeln('  productId: $productId,');
    buffer.writeln('  id: "$id",'); // Show as string with quotes
    buffer.writeln(
      '  transactionId: "$transactionId",',
    ); // Show as string with quotes
    buffer.writeln(
      '  platform: \'${platform == IapPlatform.ios ? 'ios' : 'android'}\',',
    ); // Show as string literal
    buffer.writeln('  ids: $ids,'); // Show ids array
    buffer.writeln('  purchaseToken: ${truncate(purchaseToken)},');
    buffer.writeln('  transactionReceipt: ${truncate(transactionReceipt)},');
    buffer.writeln('  orderId: $orderId,');
    buffer.writeln('  purchaseState: $purchaseState,');
    buffer.writeln('  isAcknowledged: $isAcknowledged,');
    buffer.writeln('  autoRenewing: $autoRenewing,');
    buffer.writeln('  transactionDate: $transactionDate,');

    // iOS specific fields (only print non-null values for iOS platform)
    if (platform == IapPlatform.ios) {
      if (originalTransactionDateIOS != null) {
        buffer.writeln(
          '  originalTransactionDateIOS: $originalTransactionDateIOS,',
        );
      }
      if (originalTransactionIdentifierIOS != null) {
        buffer.writeln(
          '  originalTransactionIdentifierIOS: "$originalTransactionIdentifierIOS",',
        ); // Show as string with quotes
      }
      if (transactionStateIOS != null) {
        buffer.writeln('  transactionStateIOS: $transactionStateIOS,');
      }
      if (quantityIOS != null) {
        buffer.writeln('  quantityIOS: $quantityIOS,');
      }
      if (expirationDateIOS != null) {
        buffer.writeln(
          '  expirationDateIOS: ${expirationDateIOS!.millisecondsSinceEpoch},',
        );
      }
      if (environmentIOS != null) {
        buffer.writeln('  environmentIOS: "$environmentIOS",');
      }
      if (subscriptionGroupIdIOS != null) {
        buffer.writeln('  subscriptionGroupIdIOS: "$subscriptionGroupIdIOS",');
      }
      if (productTypeIOS != null) {
        buffer.writeln('  productTypeIOS: "$productTypeIOS",');
      }
      if (transactionReasonIOS != null) {
        buffer.writeln('  transactionReasonIOS: "$transactionReasonIOS",');
      }
      if (currencyCodeIOS != null) {
        buffer.writeln('  currencyCodeIOS: "$currencyCodeIOS",');
      }
      if (storeFrontCountryCodeIOS != null) {
        buffer.writeln(
          '  storefrontCountryCodeIOS: "$storeFrontCountryCodeIOS",',
        );
      }
      if (appAccountTokenIOS != null) {
        buffer.writeln('  appAccountTokenIOS: $appAccountTokenIOS,');
      }
      if (appBundleIdIOS != null) {
        buffer.writeln('  appBundleIdIOS: "$appBundleIdIOS",');
      }
      if (productTypeIOS != null) {
        buffer.writeln('  productTypeIOS: "$productTypeIOS",');
      }
      if (subscriptionGroupIdIOS != null) {
        buffer.writeln('  subscriptionGroupIdIOS: "$subscriptionGroupIdIOS",');
      }
      if (isUpgradedIOS != null) {
        buffer.writeln('  isUpgradedIOS: $isUpgradedIOS,');
      }
      if (ownershipTypeIOS != null) {
        buffer.writeln('  ownershipTypeIOS: "$ownershipTypeIOS",');
      }
      if (webOrderLineItemIdIOS != null) {
        buffer.writeln('  webOrderLineItemIdIOS: "$webOrderLineItemIdIOS",');
      }
      if (storeFrontCountryCodeIOS != null) {
        buffer.writeln(
          '  storeFrontCountryCodeIOS: $storeFrontCountryCodeIOS,',
        );
      }
      if (reasonIOS != null) {
        buffer.writeln('  reasonIOS: "$reasonIOS",');
      }
      if (offerIOS != null) {
        buffer.writeln('  offerIOS: $offerIOS,');
      }
      if (priceIOS != null) {
        buffer.writeln('  priceIOS: $priceIOS,');
      }
      if (currencyCodeIOS != null) {
        buffer.writeln('  currencyCodeIOS: "$currencyCodeIOS",');
      }
      if (expirationDateIOS != null) {
        buffer.writeln('  expirationDateIOS: $expirationDateIOS,');
      }
      if (revocationDateIOS != null) {
        buffer.writeln('  revocationDateIOS: $revocationDateIOS,');
      }
      if (revocationReasonIOS != null) {
        buffer.writeln('  revocationReasonIOS: $revocationReasonIOS,');
      }
      if (jwsRepresentationIOS != null) {
        buffer.writeln(
          '  jwsRepresentationIOS: ${truncate(jwsRepresentationIOS)},',
        );
      }
    }

    // Android specific fields (only print non-null values for Android platform)
    if (platform == IapPlatform.android) {
      if (originalJsonAndroid != null) {
        buffer.writeln(
          '  originalJsonAndroid: ${truncate(originalJsonAndroid)},',
        );
      }
      if (signatureAndroid != null) {
        buffer.writeln('  signatureAndroid: ${truncate(signatureAndroid)},');
      }
      if (dataAndroid != null) {
        buffer.writeln('  dataAndroid: ${truncate(dataAndroid)},');
      }
      if (orderIdAndroid != null) {
        buffer.writeln('  orderIdAndroid: $orderIdAndroid,');
      }
      if (packageNameAndroid != null) {
        buffer.writeln('  packageNameAndroid: $packageNameAndroid,');
      }
      if (developerPayloadAndroid != null) {
        buffer.writeln('  developerPayloadAndroid: $developerPayloadAndroid,');
      }
      if (purchaseStateAndroid != null) {
        buffer.writeln('  purchaseStateAndroid: $purchaseStateAndroid,');
      }
      if (isAcknowledgedAndroid != null) {
        buffer.writeln('  isAcknowledgedAndroid: $isAcknowledgedAndroid,');
      }
      if (autoRenewingAndroid != null) {
        buffer.writeln('  autoRenewingAndroid: $autoRenewingAndroid,');
      }
      if (obfuscatedAccountIdAndroid != null) {
        buffer.writeln(
          '  obfuscatedAccountIdAndroid: $obfuscatedAccountIdAndroid,',
        );
      }
      if (obfuscatedProfileIdAndroid != null) {
        buffer.writeln(
          '  obfuscatedProfileIdAndroid: $obfuscatedProfileIdAndroid,',
        );
      }
    }

    // Remove last comma if present
    final str = buffer.toString();
    if (str.endsWith(',\n')) {
      return '${str.substring(0, str.length - 2)}\n}';
    }
    return '$str}';
  }
}

// ============================================================================
// New Platform-Specific Request Types (v2.7.0+)
// ============================================================================

/// iOS-specific purchase request parameters
class IosRequestPurchaseProps {
  final String sku;
  final bool? andDangerouslyFinishTransactionAutomaticallyIOS;
  final String? appAccountToken;
  final int? quantity;
  final PaymentDiscount? withOffer;

  IosRequestPurchaseProps({
    required this.sku,
    this.andDangerouslyFinishTransactionAutomaticallyIOS,
    this.appAccountToken,
    this.quantity,
    this.withOffer,
  });
}

/// Android-specific purchase request parameters (OpenIAP compliant)
class AndroidRequestPurchaseProps {
  final List<String> skus;
  final String? obfuscatedAccountIdAndroid;
  final String? obfuscatedProfileIdAndroid;
  final bool? isOfferPersonalized;

  AndroidRequestPurchaseProps({
    required this.skus,
    this.obfuscatedAccountIdAndroid,
    this.obfuscatedProfileIdAndroid,
    this.isOfferPersonalized,
  });
}

/// Android-specific subscription request parameters (OpenIAP compliant)
class AndroidRequestSubscriptionProps extends AndroidRequestPurchaseProps {
  final String? purchaseTokenAndroid;
  final int? replacementModeAndroid;
  final List<SubscriptionOfferAndroid> subscriptionOffers;

  AndroidRequestSubscriptionProps({
    required super.skus,
    required this.subscriptionOffers,
    super.obfuscatedAccountIdAndroid,
    super.obfuscatedProfileIdAndroid,
    super.isOfferPersonalized,
    this.purchaseTokenAndroid,
    this.replacementModeAndroid,
  });
}

/// Modern platform-specific request structure (v2.7.0+)
/// Allows clear separation of iOS and Android parameters
class PlatformRequestPurchaseProps {
  final IosRequestPurchaseProps? ios;
  final AndroidRequestPurchaseProps? android;

  PlatformRequestPurchaseProps({this.ios, this.android});
}

/// Modern platform-specific subscription request structure (v2.7.0+)
class PlatformRequestSubscriptionProps {
  final IosRequestPurchaseProps? ios;
  final AndroidRequestSubscriptionProps? android;

  PlatformRequestSubscriptionProps({this.ios, this.android});
}

/// Request purchase parameters
class RequestPurchase {
  final RequestPurchaseIOS? ios;
  final RequestPurchaseAndroid? android;

  RequestPurchase({this.ios, this.android});
}

/// Unified request properties for inapp purchases
class RequestPurchaseProps {
  final String sku;
  final bool? andDangerouslyFinishTransactionAutomaticallyIOS;
  final String? appAccountToken;
  final int? quantity;
  final PaymentDiscount? withOffer;
  final List<String>? skus;
  final String? obfuscatedAccountIdAndroid;
  final String? obfuscatedProfileIdAndroid;
  final bool? isOfferPersonalized;

  RequestPurchaseProps({
    required this.sku,
    this.andDangerouslyFinishTransactionAutomaticallyIOS,
    this.appAccountToken,
    this.quantity,
    this.withOffer,
    this.skus,
    this.obfuscatedAccountIdAndroid,
    this.obfuscatedProfileIdAndroid,
    this.isOfferPersonalized,
  });
}

/// Unified request properties for subscriptions
class RequestSubscriptionProps extends RequestPurchaseProps {
  final String? purchaseTokenAndroid;
  final int? replacementModeAndroid;
  final List<SubscriptionOfferAndroid>? subscriptionOffers;

  RequestSubscriptionProps({
    required super.sku,
    super.andDangerouslyFinishTransactionAutomaticallyIOS,
    super.appAccountToken,
    super.quantity,
    super.withOffer,
    super.skus,
    super.obfuscatedAccountIdAndroid,
    super.obfuscatedProfileIdAndroid,
    super.isOfferPersonalized,
    this.purchaseTokenAndroid,
    this.replacementModeAndroid,
    this.subscriptionOffers,
  });
}

/// Discriminated union for purchase requests
/// Following the TypeScript pattern:
/// type PurchaseRequest =
///   | { request: RequestPurchaseProps; type?: 'inapp'; }
///   | { request: RequestSubscriptionProps; type: 'subs'; }
class PurchaseRequest {
  final dynamic request;
  final String? type;

  /// Constructor for in-app purchase (type is optional, defaults to 'inapp')
  PurchaseRequest.inapp(RequestPurchaseProps props)
      : request = props,
        type = null; // type is optional for inapp

  /// Constructor for subscription (type is required and must be 'subs')
  PurchaseRequest.subscription(RequestSubscriptionProps props)
      : request = props,
        type = 'subs';

  /// Check if this is a subscription purchase
  bool get isSubscription => type == 'subs';

  /// Check if this is an in-app purchase
  bool get isInapp => type == null || type == 'inapp';

  /// Get the request as RequestPurchaseProps if it's an in-app purchase
  RequestPurchaseProps? get inappRequest =>
      isInapp ? request as RequestPurchaseProps : null;

  /// Get the request as RequestSubscriptionProps if it's a subscription
  RequestSubscriptionProps? get subscriptionRequest =>
      isSubscription ? request as RequestSubscriptionProps : null;
}

/// iOS specific purchase request
class RequestPurchaseIOS {
  final String sku;
  final bool? andDangerouslyFinishTransactionAutomaticallyIOS;
  final String? applicationUsername;
  final String? appAccountToken;
  final bool? simulatesAskToBuyInSandbox;
  final String? discountIdentifier;
  final String? discountTimestamp;
  final String? discountNonce;
  final String? discountSignature;
  final int? quantity;
  final PaymentDiscount? withOffer;

  RequestPurchaseIOS({
    required this.sku,
    this.andDangerouslyFinishTransactionAutomaticallyIOS,
    this.applicationUsername,
    this.appAccountToken,
    this.simulatesAskToBuyInSandbox,
    this.discountIdentifier,
    this.discountTimestamp,
    this.discountNonce,
    this.discountSignature,
    this.quantity,
    this.withOffer,
  });
}

/// Payment discount (iOS)
class PaymentDiscount {
  final String identifier;
  final String keyIdentifier;
  final String nonce;
  final String signature;
  final String timestamp;

  PaymentDiscount({
    required this.identifier,
    required this.keyIdentifier,
    required this.nonce,
    required this.signature,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'identifier': identifier,
      'keyIdentifier': keyIdentifier,
      'nonce': nonce,
      'signature': signature,
      'timestamp': timestamp,
    };
  }

  Map<String, dynamic> toJson() => toMap();
}

/// Android specific purchase request (OpenIAP compliant)
class RequestPurchaseAndroid {
  final List<String> skus;
  final String? obfuscatedAccountIdAndroid;
  final String? obfuscatedProfileIdAndroid;
  final bool? isOfferPersonalized;

  RequestPurchaseAndroid({
    required this.skus,
    this.obfuscatedAccountIdAndroid,
    this.obfuscatedProfileIdAndroid,
    this.isOfferPersonalized,
  });

  /// Convenience getter for single SKU
  String get sku => skus.isNotEmpty ? skus.first : '';
}

/// Android specific subscription request (OpenIAP compliant)
///
/// When upgrading/downgrading a subscription (using replacementModeAndroid),
/// you MUST provide the purchaseTokenAndroid from the existing subscription.
///
/// Example:
/// ```dart
/// // Get existing subscription's purchase token
/// final purchases = await FlutterInappPurchase.instance.getAvailablePurchases();
/// final existingSubscription = purchases.firstWhere((p) => p.productId == 'current_subscription');
///
/// // Upgrade/downgrade with proration mode
/// await FlutterInappPurchase.instance.requestPurchase(
///   request: RequestPurchase(
///     android: RequestSubscriptionAndroid(
///       skus: ['new_subscription_id'],
///       purchaseTokenAndroid: existingSubscription.purchaseToken, // Required!
///       replacementModeAndroid: AndroidReplacementMode.deferred.value,
///       subscriptionOffers: [...],
///     ),
///   ),
///   type: ProductType.subs,
/// );
/// ```
class RequestSubscriptionAndroid extends RequestPurchaseAndroid {
  /// The purchase token from the existing subscription that is being replaced.
  /// REQUIRED when using replacementModeAndroid (replacement mode).
  final String? purchaseTokenAndroid;

  /// The replacement mode for subscription replacement.
  /// When set, purchaseTokenAndroid MUST be provided.
  /// Use values from AndroidReplacementMode class.
  final int? replacementModeAndroid;

  final List<SubscriptionOfferAndroid> subscriptionOffers;

  RequestSubscriptionAndroid({
    required super.skus,
    required this.subscriptionOffers,
    super.obfuscatedAccountIdAndroid,
    super.obfuscatedProfileIdAndroid,
    super.isOfferPersonalized,
    this.purchaseTokenAndroid,
    this.replacementModeAndroid,
  }) {
    // Add assertion for development time validation
    assert(
      replacementModeAndroid == null ||
          replacementModeAndroid == -1 ||
          (purchaseTokenAndroid != null && purchaseTokenAndroid!.isNotEmpty),
      'purchaseTokenAndroid is required when using replacementModeAndroid (replacement mode)',
    );
  }
}

/// Subscription offer for Android
class SubscriptionOfferAndroid {
  final String sku;
  final String offerToken;

  SubscriptionOfferAndroid({required this.sku, required this.offerToken});

  SubscriptionOfferAndroid.fromJSON(Map<String, dynamic> json)
      : sku = json['sku'] as String,
        offerToken = json['offerToken'] as String;

  SubscriptionOfferAndroid.fromJson(Map<String, dynamic> json)
      : sku = json['sku'] as String? ?? '',
        offerToken = json['offerToken'] as String? ?? '';

  Map<String, dynamic> toJson() => {'sku': sku, 'offerToken': offerToken};

  @override
  String toString() {
    return 'SubscriptionOfferAndroid{sku: $sku, offerToken: $offerToken}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SubscriptionOfferAndroid &&
        other.sku == sku &&
        other.offerToken == offerToken;
  }

  @override
  int get hashCode => sku.hashCode ^ offerToken.hashCode;
}

/// Request subscription parameters
class RequestSubscription {
  final String sku;
  final bool? andDangerouslyFinishTransactionAutomaticallyIOS;

  RequestSubscription({
    required this.sku,
    this.andDangerouslyFinishTransactionAutomaticallyIOS,
  });
}

/// Unified request purchase props
class UnifiedRequestPurchaseProps {
  final String productId;
  final bool? autoFinishTransaction;
  final String? accountId;
  final String? profileId;
  final String? applicationUsername;
  final bool? simulatesAskToBuyInSandbox;
  final PaymentDiscount? paymentDiscount;
  final Map<String, dynamic>? additionalOptions;

  UnifiedRequestPurchaseProps({
    required this.productId,
    this.autoFinishTransaction,
    this.accountId,
    this.profileId,
    this.applicationUsername,
    this.simulatesAskToBuyInSandbox,
    this.paymentDiscount,
    this.additionalOptions,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      if (autoFinishTransaction != null)
        'autoFinishTransaction': autoFinishTransaction,
      if (accountId != null) 'accountId': accountId,
      if (profileId != null) 'profileId': profileId,
      if (applicationUsername != null)
        'applicationUsername': applicationUsername,
      if (simulatesAskToBuyInSandbox != null)
        'simulatesAskToBuyInSandbox': simulatesAskToBuyInSandbox,
      if (paymentDiscount != null) 'paymentDiscount': paymentDiscount!.toMap(),
      if (additionalOptions != null) ...additionalOptions!,
    };
  }
}

/// Unified subscription request props
class UnifiedRequestSubscriptionProps extends UnifiedRequestPurchaseProps {
  final String? offerToken;
  final List<String>? offerTokens;
  final String? replacementMode;
  final String? replacementProductId;
  final String? replacementPurchaseToken;
  final int? replacementModeAndroid;

  UnifiedRequestSubscriptionProps({
    required super.productId,
    super.autoFinishTransaction,
    super.accountId,
    super.profileId,
    super.applicationUsername,
    super.simulatesAskToBuyInSandbox,
    super.paymentDiscount,
    super.additionalOptions,
    this.offerToken,
    this.offerTokens,
    this.replacementMode,
    this.replacementProductId,
    this.replacementPurchaseToken,
    this.replacementModeAndroid,
  });

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    if (offerToken != null) map['offerToken'] = offerToken;
    if (offerTokens != null) map['offerTokens'] = offerTokens;
    if (replacementMode != null) map['replacementMode'] = replacementMode;
    if (replacementProductId != null) {
      map['replacementProductId'] = replacementProductId;
    }
    if (replacementPurchaseToken != null) {
      map['replacementPurchaseToken'] = replacementPurchaseToken;
    }
    if (replacementModeAndroid != null) {
      map['replacementMode'] = replacementModeAndroid;
    }
    return map;
  }
}

/// Request products parameters

/// Unified purchase request (OpenIAP compliant)
class UnifiedPurchaseRequest {
  final String productId;
  final IOSPurchaseOptions? iosOptions;
  final AndroidPurchaseOptions? androidOptions;
  final ValidationOptions? validationOptions;
  final DeepLinkOptions? deepLinkOptions;

  UnifiedPurchaseRequest({
    required this.productId,
    this.iosOptions,
    this.androidOptions,
    this.validationOptions,
    this.deepLinkOptions,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      if (iosOptions != null) 'iosOptions': iosOptions!.toMap(),
      if (androidOptions != null) 'androidOptions': androidOptions!.toMap(),
      if (validationOptions != null)
        'validationOptions': validationOptions!.toMap(),
      if (deepLinkOptions != null) 'deepLinkOptions': deepLinkOptions!.toMap(),
    };
  }
}

/// Platform purchase request (OpenIAP compliant)
class PlatformPurchaseRequest {
  final String productId;
  final Map<String, dynamic> options;

  PlatformPurchaseRequest({required this.productId, required this.options});
}

/// iOS purchase options (OpenIAP compliant)
class IOSPurchaseOptions {
  final bool? autoFinishTransaction;
  final String? applicationUsername;
  final bool? simulatesAskToBuyInSandbox;
  final PaymentDiscount? paymentDiscount;

  IOSPurchaseOptions({
    this.autoFinishTransaction,
    this.applicationUsername,
    this.simulatesAskToBuyInSandbox,
    this.paymentDiscount,
  });

  Map<String, dynamic> toMap() {
    return {
      if (autoFinishTransaction != null)
        'autoFinishTransaction': autoFinishTransaction,
      if (applicationUsername != null)
        'applicationUsername': applicationUsername,
      if (simulatesAskToBuyInSandbox != null)
        'simulatesAskToBuyInSandbox': simulatesAskToBuyInSandbox,
      if (paymentDiscount != null) 'paymentDiscount': paymentDiscount!.toMap(),
    };
  }
}

/// Android purchase options (OpenIAP compliant)
class AndroidPurchaseOptions {
  final String? accountId;
  final String? profileId;
  final String? offerToken;
  final List<String>? offerTokens;
  final ReplacementMode? replacementMode;
  final String? replacementProductId;
  final String? replacementPurchaseToken;
  final int? replacementModeAndroid;

  AndroidPurchaseOptions({
    this.accountId,
    this.profileId,
    this.offerToken,
    this.offerTokens,
    this.replacementMode,
    this.replacementProductId,
    this.replacementPurchaseToken,
    this.replacementModeAndroid,
  });

  Map<String, dynamic> toMap() {
    return {
      if (accountId != null) 'accountId': accountId,
      if (profileId != null) 'profileId': profileId,
      if (offerToken != null) 'offerToken': offerToken,
      if (offerTokens != null) 'offerTokens': offerTokens,
      if (replacementMode != null)
        'replacementMode': replacementMode.toString().split('.').last,
      if (replacementProductId != null)
        'replacementProductId': replacementProductId,
      if (replacementPurchaseToken != null)
        'replacementPurchaseToken': replacementPurchaseToken,
      if (replacementModeAndroid != null)
        'replacementMode': replacementModeAndroid,
    };
  }
}

/// Validation options (OpenIAP compliant)
class ValidationOptions {
  final bool? validateOnPurchase;
  final String? validationUrl;
  final Map<String, String>? headers;
  final IOSReceiptBody? iosReceiptBody;

  ValidationOptions({
    this.validateOnPurchase,
    this.validationUrl,
    this.headers,
    this.iosReceiptBody,
  });

  Map<String, dynamic> toMap() {
    return {
      if (validateOnPurchase != null) 'validateOnPurchase': validateOnPurchase,
      if (validationUrl != null) 'validationUrl': validationUrl,
      if (headers != null) 'headers': headers,
      if (iosReceiptBody != null) 'iosReceiptBody': iosReceiptBody!.toMap(),
    };
  }
}

/// iOS receipt body (OpenIAP compliant)
class IOSReceiptBody {
  final String? password;
  final bool? excludeOldTransactions;

  IOSReceiptBody({this.password, this.excludeOldTransactions});

  Map<String, dynamic> toMap() {
    return {
      if (password != null) 'password': password,
      if (excludeOldTransactions != null)
        'excludeOldTransactions': excludeOldTransactions,
    };
  }
}

/// Validation result (OpenIAP compliant)
class ValidationResult {
  final bool isValid;
  final String? errorMessage;
  final Map<String, dynamic>? receipt;
  final Map<String, dynamic>? parsedReceipt;
  final String? originalResponse;

  ValidationResult({
    required this.isValid,
    this.errorMessage,
    this.receipt,
    this.parsedReceipt,
    this.originalResponse,
  });

  factory ValidationResult.fromJson(Map<String, dynamic> json) {
    return ValidationResult(
      isValid: json['isValid'] as bool? ?? false,
      errorMessage: json['errorMessage'] as String?,
      receipt: json['receipt'] != null
          ? Map<String, dynamic>.from(json['receipt'] as Map)
          : null,
      parsedReceipt: json['parsedReceipt'] != null
          ? Map<String, dynamic>.from(json['parsedReceipt'] as Map)
          : null,
      originalResponse: json['originalResponse'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isValid': isValid,
      if (errorMessage != null) 'errorMessage': errorMessage,
      if (receipt != null) 'receipt': receipt,
      if (parsedReceipt != null) 'parsedReceipt': parsedReceipt,
      if (originalResponse != null) 'originalResponse': originalResponse,
    };
  }

  @override
  String toString() {
    return 'ValidationResult{isValid: $isValid, errorMessage: $errorMessage}';
  }
}

// ReplacementMode enum is defined in enums.dart to avoid duplication

/// Receipt validation properties (OpenIAP compliant)
class ReceiptValidationProps {
  /// Product SKU to validate (required for both iOS and Android)
  final String sku;

  /// Android-specific validation options
  final AndroidValidationOptions? androidOptions;

  ReceiptValidationProps({required this.sku, this.androidOptions});

  Map<String, dynamic> toJson() {
    return {
      'productId': sku, // Use productId for backward compatibility
      'sku': sku,
      if (androidOptions != null) 'androidOptions': androidOptions!.toJson(),
    };
  }

  factory ReceiptValidationProps.fromJson(Map<String, dynamic> json) {
    final sku = json['sku'] as String? ?? json['productId'] as String?;
    if (sku == null) {
      throw ArgumentError('Either sku or productId must be provided');
    }
    return ReceiptValidationProps(
      sku: sku,
      androidOptions: json['androidOptions'] != null
          ? AndroidValidationOptions.fromJson(
              Map<String, dynamic>.from(json['androidOptions'] as Map),
            )
          : null,
    );
  }
}

/// Android-specific validation options for receipt validation
class AndroidValidationOptions {
  /// Package name of your Android app
  final String packageName;

  /// Purchase token for validation (from the purchase)
  final String productToken;

  /// OAuth access token with androidpublisher scope
  /// WARNING: Including this in production builds is dangerous!
  final String accessToken;

  /// Whether this is a subscription (true) or in-app product (false)
  final bool isSub;

  AndroidValidationOptions({
    required this.packageName,
    required this.productToken,
    required this.accessToken,
    this.isSub = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'packageName': packageName,
      'productToken': productToken,
      // Do not include accessToken in toJson for security reasons
      // accessToken should only be used server-side
      'isSub': isSub,
    };
  }

  factory AndroidValidationOptions.fromJson(Map<String, dynamic> json) {
    return AndroidValidationOptions(
      packageName: json['packageName'] as String,
      productToken: json['productToken'] as String,
      accessToken: json['accessToken'] as String,
      isSub: json['isSub'] as bool? ?? false,
    );
  }
}

/// Receipt validation result (OpenIAP compliant)
class ReceiptValidationResult {
  /// Whether the receipt is valid
  final bool isValid;

  /// Error message if validation failed
  final String? errorMessage;

  /// Base64 encoded receipt data (iOS legacy)
  final String? receiptData;

  /// Unified purchase token field (JWS for iOS, purchase token for Android)
  final String? purchaseToken;

  /// JWS representation (iOS StoreKit 2) - DEPRECATED: Use purchaseToken instead
  @Deprecated('Use purchaseToken instead. Will be removed in 6.6.0')
  final String? jwsRepresentation;

  /// Latest transaction information (StoreKit 2)
  final Map<String, dynamic>? latestTransaction;

  /// Raw validation response from platform
  final Map<String, dynamic>? rawResponse;

  /// Platform that performed the validation
  final IapPlatform? platform;

  ReceiptValidationResult({
    required this.isValid,
    this.errorMessage,
    this.receiptData,
    this.purchaseToken,
    this.jwsRepresentation,
    this.latestTransaction,
    this.rawResponse,
    this.platform,
  });

  factory ReceiptValidationResult.fromJson(Map<String, dynamic> json) {
    return ReceiptValidationResult(
      isValid: json['isValid'] as bool? ?? false,
      errorMessage: json['errorMessage'] as String?,
      receiptData: json['receiptData'] as String?,
      purchaseToken: json['purchaseToken'] as String?,
      jwsRepresentation: json['jwsRepresentation']
          as String?, // Kept for backward compatibility
      latestTransaction: json['latestTransaction'] != null
          ? Map<String, dynamic>.from(json['latestTransaction'] as Map)
          : null,
      rawResponse: json['rawResponse'] != null
          ? Map<String, dynamic>.from(json['rawResponse'] as Map)
          : null,
      platform: json['platform'] != null
          ? (json['platform'] == 'ios' ? IapPlatform.ios : IapPlatform.android)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isValid': isValid,
      if (errorMessage != null) 'errorMessage': errorMessage,
      if (receiptData != null) 'receiptData': receiptData,
      if (purchaseToken != null) 'purchaseToken': purchaseToken,
      if (jwsRepresentation != null)
        'jwsRepresentation':
            jwsRepresentation, // Kept for backward compatibility
      if (latestTransaction != null) 'latestTransaction': latestTransaction,
      if (rawResponse != null) 'rawResponse': rawResponse,
      if (platform != null)
        'platform': platform == IapPlatform.ios ? 'ios' : 'android',
    };
  }

  @override
  String toString() {
    final platformStr = platform == null
        ? 'unknown'
        : (platform == IapPlatform.ios ? 'ios' : 'android');
    return 'ReceiptValidationResult{isValid: $isValid, errorMessage: $errorMessage, platform: $platformStr}';
  }
}

/// Deep link options (OpenIAP compliant)
class DeepLinkOptions {
  final String? scheme;
  final String? host;
  final String? path;

  DeepLinkOptions({this.scheme, this.host, this.path});

  Map<String, dynamic> toMap() {
    return {
      if (scheme != null) 'scheme': scheme,
      if (host != null) 'host': host,
      if (path != null) 'path': path,
    };
  }
}
