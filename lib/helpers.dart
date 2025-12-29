import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'errors.dart' as iap_err;
import 'flutter_inapp_purchase.dart';
import 'types.dart' as gentype;

String resolveProductType(Object type) {
  if (type is String) {
    return type;
  }
  if (type is TypeInApp) {
    return type.name;
  }
  if (type is gentype.ProductType) {
    return type == gentype.ProductType.InApp
        ? TypeInApp.inapp.name
        : TypeInApp.subs.name;
  }
  if (type is gentype.ProductQueryType) {
    switch (type) {
      case gentype.ProductQueryType.InApp:
        return TypeInApp.inapp.name;
      case gentype.ProductQueryType.Subs:
        return TypeInApp.subs.name;
      case gentype.ProductQueryType.All:
        return 'all';
    }
  }
  return TypeInApp.inapp.name;
}

gentype.ProductCommon parseProductFromNative(
  Map<String, dynamic> json,
  String type, {
  required bool fallbackIsIOS,
}) {
  // Determine platform from JSON data if available, otherwise use heuristics, then runtime
  gentype.IapPlatform platform;
  final dynamic platformRaw = json['platform'];
  if (platformRaw is String) {
    final v = platformRaw.toLowerCase();
    platform = (v == 'android')
        ? gentype.IapPlatform.Android
        : gentype.IapPlatform.IOS;
  } else if (platformRaw is gentype.IapPlatform) {
    platform = platformRaw;
  } else {
    // Heuristics based on well-known platform-specific fields
    final looksAndroid =
        json.containsKey('oneTimePurchaseOfferDetailsAndroid') ||
            json.containsKey('subscriptionOfferDetailsAndroid') ||
            json.containsKey('nameAndroid');
    final looksIOS = json.containsKey('subscriptionGroupIdIOS') ||
        json.containsKey('jsonRepresentationIOS') ||
        json.containsKey('environmentIOS');
    if (looksAndroid && !looksIOS) {
      platform = gentype.IapPlatform.Android;
    } else if (looksIOS && !looksAndroid) {
      platform = gentype.IapPlatform.IOS;
    } else {
      platform =
          fallbackIsIOS ? gentype.IapPlatform.IOS : gentype.IapPlatform.Android;
    }
  }

  double? parsePrice(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  final productId = (json['id']?.toString() ??
          json['productId']?.toString() ??
          json['sku']?.toString() ??
          json['productIdentifier']?.toString() ??
          '')
      .trim();
  final title = json['title']?.toString() ?? productId;
  final description = json['description']?.toString() ?? '';
  final currency = json['currency']?.toString() ?? '';
  final displayPrice = json['displayPrice']?.toString() ??
      json['localizedPrice']?.toString() ??
      '0';
  final priceValue = parsePrice(json['price']);
  final productType = _parseProductType(type);

  if (productType == gentype.ProductType.Subs) {
    if (platform == gentype.IapPlatform.IOS) {
      return gentype.ProductSubscriptionIOS(
        currency: currency,
        description: description,
        displayNameIOS: json['displayNameIOS']?.toString() ?? title,
        displayPrice: displayPrice,
        id: productId,
        isFamilyShareableIOS: json['isFamilyShareableIOS'] as bool? ?? false,
        jsonRepresentationIOS:
            json['jsonRepresentationIOS']?.toString() ?? '{}',
        platform: platform,
        title: title,
        type: productType,
        typeIOS: _parseProductTypeIOS(json['typeIOS']?.toString()),
        debugDescription: json['debugDescription']?.toString(),
        discountsIOS:
            _parseDiscountsIOS(json['discountsIOS'] ?? json['discounts']),
        displayName: json['displayName']?.toString(),
        introductoryPriceAsAmountIOS:
            json['introductoryPriceAsAmountIOS']?.toString(),
        introductoryPriceIOS: json['introductoryPriceIOS']?.toString(),
        introductoryPriceNumberOfPeriodsIOS:
            json['introductoryPriceNumberOfPeriodsIOS']?.toString(),
        introductoryPricePaymentModeIOS:
            _parsePaymentMode(json['introductoryPricePaymentModeIOS']),
        introductoryPriceSubscriptionPeriodIOS: _parseSubscriptionPeriod(
          json['introductoryPriceSubscriptionPeriodIOS'],
        ),
        price: priceValue,
        subscriptionInfoIOS: _parseSubscriptionInfoIOS(
          json['subscriptionInfoIOS'] ?? json['subscription'],
        ),
        subscriptionPeriodNumberIOS:
            json['subscriptionPeriodNumberIOS']?.toString(),
        subscriptionPeriodUnitIOS:
            _parseSubscriptionPeriod(json['subscriptionPeriodUnitIOS']),
      );
    }

    final subscriptionOffers = _parseOfferDetails(
      json['subscriptionOfferDetailsAndroid'],
    );

    return gentype.ProductSubscriptionAndroid(
      currency: currency,
      description: description,
      displayPrice: displayPrice,
      id: productId,
      nameAndroid: json['nameAndroid']?.toString() ?? productId,
      platform: platform,
      subscriptionOfferDetailsAndroid: subscriptionOffers,
      title: title,
      type: productType,
      debugDescription: json['debugDescription']?.toString(),
      displayName: json['displayName']?.toString(),
      oneTimePurchaseOfferDetailsAndroid: _parseOneTimePurchaseOfferDetails(
        json['oneTimePurchaseOfferDetailsAndroid'],
      ),
      price: priceValue,
    );
  }

  if (platform == gentype.IapPlatform.IOS) {
    return gentype.ProductIOS(
      currency: currency,
      description: description,
      displayNameIOS: json['displayNameIOS']?.toString() ?? title,
      displayPrice: displayPrice,
      id: productId,
      isFamilyShareableIOS: json['isFamilyShareableIOS'] as bool? ?? false,
      jsonRepresentationIOS: json['jsonRepresentationIOS']?.toString() ?? '{}',
      platform: platform,
      title: title,
      type: productType,
      typeIOS: _parseProductTypeIOS(json['typeIOS']?.toString()),
      debugDescription: json['debugDescription']?.toString(),
      displayName: json['displayName']?.toString(),
      price: priceValue,
      subscriptionInfoIOS: _parseSubscriptionInfoIOS(
        json['subscriptionInfoIOS'] ?? json['subscription'],
      ),
    );
  }

  final androidOffers = _parseOfferDetails(
    json['subscriptionOfferDetailsAndroid'],
  );

  return gentype.ProductAndroid(
    currency: currency,
    description: description,
    displayPrice: displayPrice,
    id: productId,
    nameAndroid: json['nameAndroid']?.toString() ?? productId,
    platform: platform,
    title: title,
    type: productType,
    debugDescription: json['debugDescription']?.toString(),
    displayName: json['displayName']?.toString(),
    oneTimePurchaseOfferDetailsAndroid: _parseOneTimePurchaseOfferDetails(
      json['oneTimePurchaseOfferDetailsAndroid'],
    ),
    price: priceValue,
    subscriptionOfferDetailsAndroid:
        androidOffers.isEmpty ? null : androidOffers,
  );
}

gentype.Purchase convertToPurchase(
  Map<String, dynamic> itemJson, {
  required bool platformIsAndroid,
  required bool platformIsIOS,
  required Map<String, bool> acknowledgedAndroidPurchaseTokens,
  Map<String, dynamic>? originalJson,
}) {
  final productId = itemJson['productId']?.toString() ?? '';
  final transactionId =
      itemJson['transactionId']?.toString() ?? itemJson['id']?.toString();
  final dynamic quantityValue = itemJson['quantity'];
  int quantity = 1;
  if (quantityValue is num) {
    quantity = quantityValue.toInt();
  } else if (quantityValue is String) {
    final parsedQuantity = int.tryParse(quantityValue.trim());
    if (parsedQuantity != null) {
      quantity = parsedQuantity;
    }
  }

  final String? purchaseId = (transactionId?.isNotEmpty ?? false)
      ? transactionId
      : (productId.isNotEmpty ? productId : null);

  if (purchaseId == null || purchaseId.isEmpty) {
    debugPrint(
      '[flutter_inapp_purchase] Skipping purchase with missing identifiers: $itemJson',
    );
    throw const FormatException('Missing purchase identifier');
  }

  double transactionDate = 0;
  final transactionDateValue = itemJson['transactionDate'];
  if (transactionDateValue is num) {
    transactionDate = transactionDateValue.toDouble();
  } else if (transactionDateValue is String) {
    final parsedDate = DateTime.tryParse(transactionDateValue);
    if (parsedDate != null) {
      transactionDate = parsedDate.millisecondsSinceEpoch.toDouble();
    }
  }

  if (platformIsAndroid) {
    final stateValue = _coerceAndroidPurchaseState(
      itemJson['purchaseStateAndroid'] ?? itemJson['purchaseState'],
    );
    final purchaseState = _mapAndroidPurchaseState(stateValue).toJson();

    // Determine store from input or default based on platform
    final storeValue = itemJson['store']?.toString() ?? 'google';

    final map = <String, dynamic>{
      'id': purchaseId,
      'productId': productId,
      'platform': gentype.IapPlatform.Android.toJson(),
      'store': storeValue,
      'isAutoRenewing': itemJson['isAutoRenewing'] as bool? ??
          itemJson['autoRenewingAndroid'] as bool? ??
          false,
      'purchaseState': purchaseState,
      'quantity': quantity,
      'transactionDate': transactionDate,
      'purchaseToken': itemJson['purchaseToken']?.toString(),
      'autoRenewingAndroid': itemJson['autoRenewingAndroid'] as bool?,
      'dataAndroid': itemJson['originalJsonAndroid']?.toString(),
      'developerPayloadAndroid':
          itemJson['developerPayloadAndroid']?.toString(),
      'ids': (itemJson['ids'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      'isAcknowledgedAndroid': itemJson['isAcknowledgedAndroid'] as bool?,
      'obfuscatedAccountIdAndroid':
          itemJson['obfuscatedAccountIdAndroid']?.toString() ??
              originalJson?['obfuscatedAccountIdAndroid']?.toString(),
      'obfuscatedProfileIdAndroid':
          itemJson['obfuscatedProfileIdAndroid']?.toString() ??
              originalJson?['obfuscatedProfileIdAndroid']?.toString(),
      'packageNameAndroid': itemJson['packageNameAndroid']?.toString(),
      'signatureAndroid': itemJson['signatureAndroid']?.toString(),
      'transactionId': transactionId,
    };

    final purchaseToken = itemJson['purchaseToken']?.toString();
    if (purchaseToken != null && purchaseToken.isNotEmpty) {
      acknowledgedAndroidPurchaseTokens[purchaseToken] =
          itemJson['isAcknowledgedAndroid'] as bool? ?? false;
    }

    return gentype.PurchaseAndroid.fromJson(map);
  }

  if (platformIsIOS) {
    final stateIOS = _parsePurchaseStateIOS(
      itemJson['purchaseState'] ?? itemJson['transactionStateIOS'],
    ).toJson();

    double? originalTransactionDateIOS;
    final originalTransactionDateValue =
        itemJson['originalTransactionDateIOS'] ??
            originalJson?['originalTransactionDateIOS'];
    if (originalTransactionDateValue is num) {
      originalTransactionDateIOS = originalTransactionDateValue.toDouble();
    } else if (originalTransactionDateValue is String) {
      final parsed = DateTime.tryParse(originalTransactionDateValue);
      if (parsed != null) {
        originalTransactionDateIOS = parsed.millisecondsSinceEpoch.toDouble();
      }
    }

    // Determine store from input or default based on platform
    final storeValueIOS = itemJson['store']?.toString() ?? 'apple';

    final map = <String, dynamic>{
      'id': purchaseId,
      'productId': productId,
      'platform': gentype.IapPlatform.IOS.toJson(),
      'store': storeValueIOS,
      'isAutoRenewing': itemJson['isAutoRenewing'] as bool? ?? false,
      'purchaseState': stateIOS,
      'quantity': quantity,
      'transactionDate': transactionDate,
      'purchaseToken': itemJson['transactionReceipt']?.toString() ??
          itemJson['purchaseToken']?.toString(),
      'ids': (itemJson['ids'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      'appAccountToken': itemJson['appAccountToken']?.toString(),
      'appBundleIdIOS': itemJson['appBundleIdIOS']?.toString(),
      'countryCodeIOS': itemJson['countryCodeIOS']?.toString(),
      'currencyCodeIOS': itemJson['currencyCodeIOS']?.toString(),
      'currencySymbolIOS': itemJson['currencySymbolIOS']?.toString(),
      'environmentIOS': itemJson['environmentIOS']?.toString(),
      'expirationDateIOS':
          (originalJson?['expirationDateIOS'] as num?)?.toDouble(),
      'originalTransactionIdentifierIOS':
          itemJson['originalTransactionIdentifierIOS']?.toString(),
      'originalTransactionDateIOS': originalTransactionDateIOS,
      'subscriptionGroupIdIOS': itemJson['subscriptionGroupIdIOS']?.toString(),
      'transactionReasonIOS': itemJson['transactionReasonIOS']?.toString(),
      'webOrderLineItemIdIOS': itemJson['webOrderLineItemIdIOS']?.toString(),
      'offerIOS': originalJson?['offerIOS'],
      'priceIOS': (originalJson?['priceIOS'] as num?)?.toDouble(),
      'revocationDateIOS':
          (originalJson?['revocationDateIOS'] as num?)?.toDouble(),
      'revocationReasonIOS': originalJson?['revocationReasonIOS']?.toString(),
      'transactionId': transactionId ?? purchaseId,
    };

    return gentype.PurchaseIOS.fromJson(map);
  }

  throw const FormatException('Unsupported platform for legacy purchase');
}

iap_err.PurchaseError convertToPurchaseError(
  PurchaseResult result, {
  required gentype.IapPlatform platform,
}) {
  gentype.ErrorCode code = gentype.ErrorCode.Unknown;

  if (result.code != null && result.code!.isNotEmpty) {
    final detected =
        iap_err.ErrorCodeUtils.fromPlatformCode(result.code!, platform);
    if (detected != gentype.ErrorCode.Unknown) {
      code = detected;
    }
  }

  if (code == gentype.ErrorCode.Unknown) {
    switch (result.responseCode) {
      case 0:
        code = gentype.ErrorCode.Unknown;
        break;
      case 1:
        code = gentype.ErrorCode.UserCancelled;
        break;
      case 2:
        code = gentype.ErrorCode.ServiceError;
        break;
      case 3:
        code = gentype.ErrorCode.BillingUnavailable;
        break;
      case 4:
        code = gentype.ErrorCode.ItemUnavailable;
        break;
      case 5:
        code = gentype.ErrorCode.DeveloperError;
        break;
      case 6:
        code = gentype.ErrorCode.Unknown;
        break;
      case 7:
        code = gentype.ErrorCode.AlreadyOwned;
        break;
      case 8:
        code = gentype.ErrorCode.PurchaseError;
        break;
    }
  }

  return iap_err.PurchaseError(
    message: result.message ?? 'Unknown error',
    code: code,
  );
}

List<gentype.Purchase> extractPurchases(
  dynamic result, {
  required bool platformIsAndroid,
  required bool platformIsIOS,
  required Map<String, bool> acknowledgedAndroidPurchaseTokens,
}) {
  List<dynamic> list;
  if (result is String) {
    list = json.decode(result) as List<dynamic>;
  } else if (result is List) {
    list = result;
  } else {
    list = json.decode(result.toString()) as List<dynamic>;
  }

  final purchases = <gentype.Purchase>[];
  for (final dynamic product in list) {
    try {
      if (product is! Map) {
        debugPrint(
          '[flutter_inapp_purchase] Skipping purchase with unexpected type: ${product.runtimeType}',
        );
        continue;
      }
      // Safely convert map keys to strings to handle cases where platform channels
      // return maps with non-string keys (e.g., Map<Object?, Object?>)
      final map = normalizeDynamicMap(product);
      if (map == null) {
        debugPrint(
          '[flutter_inapp_purchase] Skipping purchase: failed to normalize map',
        );
        continue;
      }
      final original = map; // Use normalized data to access additional fields
      purchases.add(
        convertToPurchase(
          map,
          originalJson: original,
          platformIsAndroid: platformIsAndroid,
          platformIsIOS: platformIsIOS,
          acknowledgedAndroidPurchaseTokens: acknowledgedAndroidPurchaseTokens,
        ),
      );
    } catch (error) {
      debugPrint(
        '[flutter_inapp_purchase] Skipping purchase due to parse error: $error',
      );
    }
  }

  return purchases;
}

// Private helper functions --------------------------------------------------

gentype.ProductType _parseProductType(dynamic value) {
  if (value is gentype.ProductType) return value;
  final rawUpper = value?.toString().toUpperCase() ?? 'IN_APP';
  final normalized = rawUpper == 'INAPP' ? 'IN_APP' : rawUpper;
  try {
    return gentype.ProductType.fromJson(normalized);
  } catch (_) {
    return normalized.contains('SUB')
        ? gentype.ProductType.Subs
        : gentype.ProductType.InApp;
  }
}

gentype.ProductTypeIOS _parseProductTypeIOS(String? value) {
  final rawUpper = value?.toString().toUpperCase() ?? 'NON_CONSUMABLE';
  final normalized = rawUpper == 'NONCONSUMABLE' ? 'NON_CONSUMABLE' : rawUpper;
  try {
    return gentype.ProductTypeIOS.fromJson(normalized);
  } catch (_) {
    switch (normalized) {
      case 'CONSUMABLE':
        return gentype.ProductTypeIOS.Consumable;
      case 'AUTO_RENEWABLE_SUBSCRIPTION':
      case 'SUBS':
      case 'SUBSCRIPTION':
        return gentype.ProductTypeIOS.AutoRenewableSubscription;
      case 'NON_RENEWING_SUBSCRIPTION':
        return gentype.ProductTypeIOS.NonRenewingSubscription;
      default:
        return gentype.ProductTypeIOS.NonConsumable;
    }
  }
}

List<gentype.DiscountIOS>? _parseDiscountsIOS(dynamic json) {
  if (json == null) return null;
  final list = json as List<dynamic>;
  return list
      .map(
        (e) => gentype.DiscountIOS.fromJson(
          e is Map<String, dynamic>
              ? e
              : (e as Map).map<String, dynamic>(
                  (key, value) => MapEntry(key.toString(), value)),
        ),
      )
      .toList();
}

List<gentype.ProductSubscriptionAndroidOfferDetails> _parseOfferDetails(
  dynamic json,
) {
  if (json == null) {
    return const <gentype.ProductSubscriptionAndroidOfferDetails>[];
  }

  // Handle both List and String (JSON string from Android)
  List<dynamic> list;
  if (json is String) {
    // Parse JSON string from Android
    try {
      final parsed = jsonDecode(json);
      if (parsed is! List) {
        return const <gentype.ProductSubscriptionAndroidOfferDetails>[];
      }
      list = parsed;
    } catch (e) {
      return const <gentype.ProductSubscriptionAndroidOfferDetails>[];
    }
  } else if (json is List) {
    list = json;
  } else {
    return const <gentype.ProductSubscriptionAndroidOfferDetails>[];
  }

  return list
      .map((item) {
        // Convert Map<Object?, Object?> to Map<String, dynamic>
        final Map<String, dynamic> e;
        if (item is Map<String, dynamic>) {
          e = item;
        } else if (item is Map) {
          e = item.map<String, dynamic>(
              (key, value) => MapEntry(key.toString(), value));
        } else {
          // Skip invalid items
          return null;
        }

        return gentype.ProductSubscriptionAndroidOfferDetails(
          basePlanId: e['basePlanId'] as String? ?? '',
          offerId: e['offerId'] as String?,
          offerToken: e['offerToken'] as String? ?? '',
          offerTags: (e['offerTags'] as List<dynamic>?)
                  ?.map((tag) => tag.toString())
                  .toList() ??
              const <String>[],
          pricingPhases: _parsePricingPhases(e['pricingPhases']),
        );
      })
      .whereType<gentype.ProductSubscriptionAndroidOfferDetails>()
      .toList();
}

gentype.PricingPhasesAndroid _parsePricingPhases(dynamic json) {
  if (json == null) {
    return const gentype.PricingPhasesAndroid(pricingPhaseList: []);
  }

  // Handle nested structure from Android
  List<dynamic>? list;
  if (json is Map && json['pricingPhaseList'] != null) {
    list = json['pricingPhaseList'] as List<dynamic>?;
  } else if (json is List) {
    list = json;
  }

  if (list == null) {
    return const gentype.PricingPhasesAndroid(pricingPhaseList: []);
  }

  final phases = list
      .map((item) {
        // Convert Map<Object?, Object?> to Map<String, dynamic>
        final Map<String, dynamic> e;
        if (item is Map<String, dynamic>) {
          e = item;
        } else if (item is Map) {
          e = item.map<String, dynamic>(
              (key, value) => MapEntry(key.toString(), value));
        } else {
          // Skip invalid items
          return null;
        }

        final priceAmountMicros = e['priceAmountMicros'];
        final recurrenceMode = e['recurrenceMode'];

        return gentype.PricingPhaseAndroid(
          billingCycleCount: (e['billingCycleCount'] as num?)?.toInt() ?? 0,
          billingPeriod: e['billingPeriod']?.toString() ?? '',
          formattedPrice: e['formattedPrice']?.toString() ?? '0',
          priceAmountMicros: priceAmountMicros?.toString() ?? '0',
          priceCurrencyCode: e['priceCurrencyCode']?.toString() ?? 'USD',
          recurrenceMode: recurrenceMode is int ? recurrenceMode : 0,
        );
      })
      .whereType<gentype.PricingPhaseAndroid>()
      .toList();

  return gentype.PricingPhasesAndroid(pricingPhaseList: phases);
}

gentype.SubscriptionInfoIOS? _parseSubscriptionInfoIOS(dynamic value) {
  final normalizedMap = normalizeDynamicMap(value);
  if (normalizedMap != null) {
    return gentype.SubscriptionInfoIOS.fromJson(normalizedMap);
  }
  if (value is List && value.isNotEmpty) {
    for (final candidate in value) {
      final map = normalizeDynamicMap(candidate);
      if (map != null) {
        return gentype.SubscriptionInfoIOS.fromJson(map);
      }
    }
  }
  return null;
}

gentype.SubscriptionPeriodIOS? _parseSubscriptionPeriod(dynamic value) {
  if (value == null) return null;
  final raw = value.toString().toUpperCase();
  try {
    return gentype.SubscriptionPeriodIOS.fromJson(raw);
  } catch (_) {
    return null;
  }
}

Map<String, dynamic>? normalizeDynamicMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value.map<String, dynamic>(
      (key, dynamic val) => MapEntry(key, normalizeDynamicValue(val)),
    );
  }
  if (value is Map) {
    final normalized = <String, dynamic>{};
    value.forEach((dynamic key, dynamic val) {
      if (key == null) {
        return;
      }
      final stringKey = key.toString();
      if (stringKey.isEmpty) {
        return;
      }
      normalized[stringKey] = normalizeDynamicValue(val);
    });
    return normalized;
  }
  return null;
}

dynamic normalizeDynamicValue(dynamic value) {
  if (value is Map || value is Map<dynamic, dynamic>) {
    return normalizeDynamicMap(value);
  }
  if (value is List) {
    return value.map<dynamic>(normalizeDynamicValue).toList();
  }
  return value;
}

gentype.PaymentModeIOS _parsePaymentMode(dynamic value) {
  if (value == null) return gentype.PaymentModeIOS.Empty;
  final raw = value.toString().toUpperCase();
  try {
    return gentype.PaymentModeIOS.fromJson(raw);
  } catch (_) {
    return gentype.PaymentModeIOS.Empty;
  }
}

/// Parses oneTimePurchaseOfferDetailsAndroid - handles both array (new 7.0+)
/// and single object (legacy) for backwards compatibility
List<gentype.ProductAndroidOneTimePurchaseOfferDetail>?
    _parseOneTimePurchaseOfferDetails(dynamic value) {
  if (value == null) return null;

  // New format: array of offers (Android 7.0+)
  if (value is List) {
    return value
        .map((e) => _parseSingleOneTimePurchaseOfferDetail(e))
        .whereType<gentype.ProductAndroidOneTimePurchaseOfferDetail>()
        .toList();
  }

  // Legacy format: single object - wrap in list for compatibility
  final single = _parseSingleOneTimePurchaseOfferDetail(value);
  if (single != null) {
    return [single];
  }

  return null;
}

gentype.ProductAndroidOneTimePurchaseOfferDetail?
    _parseSingleOneTimePurchaseOfferDetail(dynamic value) {
  if (value is Map<String, dynamic>) {
    return gentype.ProductAndroidOneTimePurchaseOfferDetail(
      formattedPrice: value['formattedPrice']?.toString() ?? '0',
      priceAmountMicros: value['priceAmountMicros']?.toString() ?? '0',
      priceCurrencyCode: value['priceCurrencyCode']?.toString() ?? 'USD',
      offerTags: (value['offerTags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      offerToken: value['offerToken']?.toString() ?? '',
      offerId: value['offerId']?.toString(),
      fullPriceMicros: value['fullPriceMicros']?.toString(),
      discountDisplayInfo: value['discountDisplayInfo'] != null
          ? gentype.DiscountDisplayInfoAndroid.fromJson(
              value['discountDisplayInfo'] as Map<String, dynamic>)
          : null,
      limitedQuantityInfo: value['limitedQuantityInfo'] != null
          ? gentype.LimitedQuantityInfoAndroid.fromJson(
              value['limitedQuantityInfo'] as Map<String, dynamic>)
          : null,
      validTimeWindow: _parseValidTimeWindow(value['validTimeWindow']),
      preorderDetailsAndroid: value['preorderDetailsAndroid'] != null
          ? gentype.PreorderDetailsAndroid.fromJson(
              value['preorderDetailsAndroid'] as Map<String, dynamic>)
          : null,
      rentalDetailsAndroid: value['rentalDetailsAndroid'] != null
          ? gentype.RentalDetailsAndroid.fromJson(
              value['rentalDetailsAndroid'] as Map<String, dynamic>)
          : null,
    );
  }
  if (value is Map) {
    final map =
        value.map<String, dynamic>((key, val) => MapEntry(key.toString(), val));
    return gentype.ProductAndroidOneTimePurchaseOfferDetail(
      formattedPrice: map['formattedPrice']?.toString() ?? '0',
      priceAmountMicros: map['priceAmountMicros']?.toString() ?? '0',
      priceCurrencyCode: map['priceCurrencyCode']?.toString() ?? 'USD',
      offerTags: (map['offerTags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      offerToken: map['offerToken']?.toString() ?? '',
      offerId: map['offerId']?.toString(),
      fullPriceMicros: map['fullPriceMicros']?.toString(),
      discountDisplayInfo: map['discountDisplayInfo'] != null
          ? gentype.DiscountDisplayInfoAndroid.fromJson(
              Map<String, dynamic>.from(
                  map['discountDisplayInfo'] as Map<dynamic, dynamic>))
          : null,
      limitedQuantityInfo: map['limitedQuantityInfo'] != null
          ? gentype.LimitedQuantityInfoAndroid.fromJson(
              Map<String, dynamic>.from(
                  map['limitedQuantityInfo'] as Map<dynamic, dynamic>))
          : null,
      validTimeWindow: _parseValidTimeWindow(map['validTimeWindow']),
      preorderDetailsAndroid: map['preorderDetailsAndroid'] != null
          ? gentype.PreorderDetailsAndroid.fromJson(Map<String, dynamic>.from(
              map['preorderDetailsAndroid'] as Map<dynamic, dynamic>))
          : null,
      rentalDetailsAndroid: map['rentalDetailsAndroid'] != null
          ? gentype.RentalDetailsAndroid.fromJson(Map<String, dynamic>.from(
              map['rentalDetailsAndroid'] as Map<dynamic, dynamic>))
          : null,
    );
  }
  return null;
}

gentype.ValidTimeWindowAndroid? _parseValidTimeWindow(dynamic value) {
  if (value == null) return null;
  final map = normalizeDynamicMap(value);
  if (map == null) return null;
  return gentype.ValidTimeWindowAndroid.fromJson({
    'endTimeMillis': map['endTimeMillis']?.toString() ?? '',
    'startTimeMillis': map['startTimeMillis']?.toString() ?? '',
  });
}

gentype.PurchaseState _parsePurchaseStateIOS(dynamic value) {
  if (value is gentype.PurchaseState) return value;
  if (value is String) {
    switch (value.toLowerCase()) {
      case 'purchasing':
      case 'pending':
        return gentype.PurchaseState.Pending;
      case 'purchased':
      case 'restored':
        return gentype.PurchaseState.Purchased;
      // Failed, deferred are no longer valid states in OpenIAP v1.3.11+
      // Both platforms return errors instead of Purchase objects on failure
      // Deferred: iOS StoreKit 2 has no transaction state; Android uses Pending
      default:
        return gentype.PurchaseState.Unknown;
    }
  }
  if (value is num) {
    switch (value.toInt()) {
      case 0:
        return gentype.PurchaseState.Pending;
      case 1:
      case 3: // Restored returns as Purchased
        return gentype.PurchaseState.Purchased;
      // case 2 (Failed) and case 4 (Deferred) now return Unknown
      // as these states are no longer part of PurchaseState enum
      default:
        return gentype.PurchaseState.Unknown;
    }
  }
  return gentype.PurchaseState.Unknown;
}

int _coerceAndroidPurchaseState(dynamic value) {
  if (value == null) {
    return AndroidPurchaseState.Purchased.value;
  }
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    final trimmed = value.trim();
    final parsed = int.tryParse(trimmed);
    if (parsed != null) {
      return parsed;
    }
    switch (trimmed.toLowerCase()) {
      case 'purchased':
      case 'purchase_state_purchased':
        return AndroidPurchaseState.Purchased.value;
      case 'pending':
      case 'purchase_state_pending':
        return AndroidPurchaseState.Pending.value;
      case 'unspecified':
      case 'unknown':
      case 'purchase_state_unspecified':
        return AndroidPurchaseState.Unknown.value;
    }
  }
  return AndroidPurchaseState.Purchased.value;
}

gentype.PurchaseState _mapAndroidPurchaseState(int stateValue) {
  final state = androidPurchaseStateFromValue(stateValue);
  switch (state) {
    case AndroidPurchaseState.Purchased:
      return gentype.PurchaseState.Purchased;
    case AndroidPurchaseState.Pending:
      return gentype.PurchaseState.Pending;
    case AndroidPurchaseState.Unknown:
      return gentype.PurchaseState.Unknown;
  }
}

extension PurchaseInputConversion on gentype.Purchase {
  gentype.PurchaseInput toInput() {
    // PurchaseInput is now just a typedef for Purchase, so return this directly
    return this;
  }
}

List<PurchaseResult>? extractResult(dynamic result) {
  List<dynamic> list;
  if (result is String) {
    list = json.decode(result) as List<dynamic>;
  } else if (result is List) {
    list = result;
  } else {
    list = json.decode(result.toString()) as List<dynamic>;
  }

  final decoded = list
      .map<PurchaseResult>(
        (dynamic product) => PurchaseResult.fromJSON(
          (product as Map).map<String, dynamic>(
              (key, value) => MapEntry(key.toString(), value)),
        ),
      )
      .toList();

  return decoded;
}

class PurchaseResult {
  PurchaseResult({
    this.responseCode,
    this.debugMessage,
    this.code,
    this.message,
    this.purchaseTokenAndroid,
  });

  final int? responseCode;
  final String? debugMessage;
  final String? code;
  final String? message;
  final String? purchaseTokenAndroid;

  factory PurchaseResult.fromJSON(Map<String, dynamic> json) {
    return PurchaseResult(
      responseCode: json['responseCode'] as int?,
      debugMessage: json['debugMessage']?.toString(),
      code: json['code']?.toString(),
      message: json['message']?.toString(),
      purchaseTokenAndroid: json['purchaseTokenAndroid']?.toString(),
    );
  }
}

class ConnectionResult {
  ConnectionResult({this.msg});

  final String? msg;

  factory ConnectionResult.fromJSON(Map<String, dynamic> json) {
    return ConnectionResult(msg: json['msg']?.toString());
  }
}
