import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'enums.dart';
import 'errors.dart' as iap_err;
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
      oneTimePurchaseOfferDetailsAndroid: _parseOneTimePurchaseOfferDetail(
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
    oneTimePurchaseOfferDetailsAndroid: _parseOneTimePurchaseOfferDetail(
      json['oneTimePurchaseOfferDetailsAndroid'],
    ),
    price: priceValue,
    subscriptionOfferDetailsAndroid:
        androidOffers.isEmpty ? null : androidOffers,
  );
}

gentype.Purchase convertFromLegacyPurchase(
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

    final map = <String, dynamic>{
      'id': purchaseId,
      'productId': productId,
      'platform': gentype.IapPlatform.Android.toJson(),
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

    final map = <String, dynamic>{
      'id': purchaseId,
      'productId': productId,
      'platform': gentype.IapPlatform.IOS.toJson(),
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

gentype.PurchaseError convertToPurchaseError(
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

  return gentype.PurchaseError(
    code: code,
    message: result.message ?? 'Unknown error',
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
      final map = Map<String, dynamic>.from(product);
      final original = Map<String, dynamic>.from(product);
      purchases.add(
        convertFromLegacyPurchase(
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
          e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e as Map),
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
          e = Map<String, dynamic>.from(item);
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
          e = Map<String, dynamic>.from(item);
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
  if (value is Map<String, dynamic>) {
    return gentype.SubscriptionInfoIOS.fromJson(value);
  }
  if (value is Map) {
    return gentype.SubscriptionInfoIOS.fromJson(
      Map<String, dynamic>.from(value),
    );
  }
  if (value is List && value.isNotEmpty) {
    final first = value.first;
    if (first is Map) {
      return gentype.SubscriptionInfoIOS.fromJson(
        Map<String, dynamic>.from(first),
      );
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

gentype.PaymentModeIOS? _parsePaymentMode(dynamic value) {
  if (value == null) return null;
  final raw = value.toString().toUpperCase();
  try {
    return gentype.PaymentModeIOS.fromJson(raw);
  } catch (_) {
    return null;
  }
}

gentype.ProductAndroidOneTimePurchaseOfferDetail?
    _parseOneTimePurchaseOfferDetail(dynamic value) {
  if (value is Map<String, dynamic>) {
    return gentype.ProductAndroidOneTimePurchaseOfferDetail(
      formattedPrice: value['formattedPrice']?.toString() ?? '0',
      priceAmountMicros: value['priceAmountMicros']?.toString() ?? '0',
      priceCurrencyCode: value['priceCurrencyCode']?.toString() ?? 'USD',
    );
  }
  if (value is Map) {
    final map = Map<String, dynamic>.from(value);
    return gentype.ProductAndroidOneTimePurchaseOfferDetail(
      formattedPrice: map['formattedPrice']?.toString() ?? '0',
      priceAmountMicros: map['priceAmountMicros']?.toString() ?? '0',
      priceCurrencyCode: map['priceCurrencyCode']?.toString() ?? 'USD',
    );
  }
  return null;
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
      case 'failed':
        return gentype.PurchaseState.Failed;
      case 'deferred':
        return gentype.PurchaseState.Deferred;
      default:
        return gentype.PurchaseState.Unknown;
    }
  }
  if (value is num) {
    switch (value.toInt()) {
      case 0:
        return gentype.PurchaseState.Pending;
      case 1:
        return gentype.PurchaseState.Purchased;
      case 2:
        return gentype.PurchaseState.Failed;
      case 3:
        return gentype.PurchaseState.Purchased;
      case 4:
        return gentype.PurchaseState.Deferred;
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
    return gentype.PurchaseInput(
      id: id,
      ids: ids,
      isAutoRenewing: isAutoRenewing,
      platform: platform,
      productId: productId,
      purchaseState: purchaseState,
      purchaseToken: purchaseToken,
      quantity: quantity,
      transactionDate: transactionDate,
    );
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
          Map<String, dynamic>.from(product as Map),
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

extension FetchProductsResultX on gentype.FetchProductsResult {
  List<gentype.Product> inAppProducts() {
    if (this is gentype.FetchProductsResultProducts) {
      final products = (this as gentype.FetchProductsResultProducts).value ??
          const <gentype.Product>[];
      return List<gentype.Product>.from(products, growable: false);
    }
    return const <gentype.Product>[];
  }

  List<gentype.ProductSubscription> subscriptionProducts() {
    if (this is gentype.FetchProductsResultSubscriptions) {
      final products =
          (this as gentype.FetchProductsResultSubscriptions).value ??
              const <gentype.ProductSubscription>[];
      return List<gentype.ProductSubscription>.from(products, growable: false);
    }
    return const <gentype.ProductSubscription>[];
  }

  List<gentype.ProductCommon> allProducts() {
    if (this is gentype.FetchProductsResultProducts) {
      return inAppProducts()
          .map<gentype.ProductCommon>((product) => product)
          .toList(growable: false);
    }
    if (this is gentype.FetchProductsResultSubscriptions) {
      return subscriptionProducts()
          .map<gentype.ProductCommon>((product) => product)
          .toList(growable: false);
    }
    return const <gentype.ProductCommon>[];
  }
}
