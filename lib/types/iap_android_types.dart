/// Android-specific types for in-app purchases

/// Android product information
class ProductAndroid {
  final String productId;
  final String price;
  final String currency;
  final String localizedPrice;
  final String title;
  final String description;
  final String subscriptionPeriodAndroid;
  final String freeTrialPeriodAndroid;
  final String introductoryPriceAndroid;
  final String introductoryPricePeriodAndroid;
  final String introductoryPriceCyclesAndroid;
  final String iconUrl;
  final String originalJson;
  final List<SubscriptionOfferDetail> subscriptionOffersAndroid;

  ProductAndroid({
    required this.productId,
    required this.price,
    required this.currency,
    required this.localizedPrice,
    required this.title,
    required this.description,
    required this.subscriptionPeriodAndroid,
    required this.freeTrialPeriodAndroid,
    required this.introductoryPriceAndroid,
    required this.introductoryPricePeriodAndroid,
    required this.introductoryPriceCyclesAndroid,
    required this.iconUrl,
    required this.originalJson,
    required this.subscriptionOffersAndroid,
  });

  factory ProductAndroid.fromJson(Map<String, dynamic> json) {
    return ProductAndroid(
      productId: (json['productId'] as String?) ?? '',
      price: json['price']?.toString() ?? '',
      currency: (json['currency'] as String?) ?? '',
      localizedPrice: (json['localizedPrice'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      subscriptionPeriodAndroid: (json['subscriptionPeriodAndroid'] as String?) ?? '',
      freeTrialPeriodAndroid: (json['freeTrialPeriodAndroid'] as String?) ?? '',
      introductoryPriceAndroid: (json['introductoryPriceAndroid'] as String?) ?? '',
      introductoryPricePeriodAndroid: (json['introductoryPricePeriodAndroid'] as String?) ?? '',
      introductoryPriceCyclesAndroid: (json['introductoryPriceCyclesAndroid'] as String?) ?? '',
      iconUrl: (json['iconUrl'] as String?) ?? '',
      originalJson: (json['originalJson'] as String?) ?? '',
      subscriptionOffersAndroid: (json['subscriptionOffersAndroid'] as List<dynamic>?)
          ?.map((e) => SubscriptionOfferDetail.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'price': price,
      'currency': currency,
      'localizedPrice': localizedPrice,
      'title': title,
      'description': description,
      'subscriptionPeriodAndroid': subscriptionPeriodAndroid,
      'freeTrialPeriodAndroid': freeTrialPeriodAndroid,
      'introductoryPriceAndroid': introductoryPriceAndroid,
      'introductoryPricePeriodAndroid': introductoryPricePeriodAndroid,
      'introductoryPriceCyclesAndroid': introductoryPriceCyclesAndroid,
      'iconUrl': iconUrl,
      'originalJson': originalJson,
      'subscriptionOffersAndroid': subscriptionOffersAndroid.map((e) => e.toJson()).toList(),
    };
  }
}

/// Android subscription offer details
class SubscriptionOfferDetail {
  final String offerToken;
  final List<PricingPhase> pricingPhases;

  SubscriptionOfferDetail({
    required this.offerToken,
    required this.pricingPhases,
  });

  factory SubscriptionOfferDetail.fromJson(Map<String, dynamic> json) {
    return SubscriptionOfferDetail(
      offerToken: (json['offerToken'] as String?) ?? '',
      pricingPhases: (json['pricingPhases'] as List<dynamic>?)
          ?.map((e) => PricingPhase.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'offerToken': offerToken,
      'pricingPhases': pricingPhases.map((e) => e.toJson()).toList(),
    };
  }
}

/// Android pricing phase for subscriptions
class PricingPhase {
  final double price;
  final String currency;
  final String billingPeriod;
  final String formattedPrice;
  final int billingCycleCount;
  final String recurrenceMode;

  PricingPhase({
    required this.price,
    required this.currency,
    required this.billingPeriod,
    required this.formattedPrice,
    required this.billingCycleCount,
    required this.recurrenceMode,
  });

  factory PricingPhase.fromJson(Map<String, dynamic> json) {
    return PricingPhase(
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      currency: (json['currency'] as String?) ?? '',
      billingPeriod: (json['billingPeriod'] as String?) ?? '',
      formattedPrice: (json['formattedPrice'] as String?) ?? '',
      billingCycleCount: (json['billingCycleCount'] as int?) ?? 0,
      recurrenceMode: (json['recurrenceMode'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'price': price,
      'currency': currency,
      'billingPeriod': billingPeriod,
      'formattedPrice': formattedPrice,
      'billingCycleCount': billingCycleCount,
      'recurrenceMode': recurrenceMode,
    };
  }
}

/// Android purchase request properties
class RequestPurchaseAndroidProps {
  final String skus;
  final bool? isOfferPersonalized;
  final String? obfuscatedAccountId;
  final String? obfuscatedProfileId;
  final String? purchaseToken;

  RequestPurchaseAndroidProps({
    required this.skus,
    this.isOfferPersonalized,
    this.obfuscatedAccountId,
    this.obfuscatedProfileId,
    this.purchaseToken,
  });

  Map<String, dynamic> toJson() {
    return {
      'skus': skus,
      if (isOfferPersonalized != null) 'isOfferPersonalized': isOfferPersonalized,
      if (obfuscatedAccountId != null) 'obfuscatedAccountId': obfuscatedAccountId,
      if (obfuscatedProfileId != null) 'obfuscatedProfileId': obfuscatedProfileId,
      if (purchaseToken != null) 'purchaseToken': purchaseToken,
    };
  }
}

/// Android subscription purchase request properties
class RequestPurchaseSubscriptionAndroid {
  final String purchaseToken;
  final ProrationModeAndroid prorationMode;

  RequestPurchaseSubscriptionAndroid({
    required this.purchaseToken,
    required this.prorationMode,
  });

  Map<String, dynamic> toJson() {
    return {
      'purchaseToken': purchaseToken,
      'prorationMode': prorationMode.index,
    };
  }
}

/// Android proration modes
enum ProrationModeAndroid {
  /// Replacement takes effect immediately, and the user is charged the full price 
  /// of the new plan and is given a full billing cycle of subscription, 
  /// plus remaining prorated time from the old plan.
  immediateAndChargeFullPrice,

  /// Replacement takes effect immediately, and the billing cycle remains the same. 
  /// The price for the remaining period will be charged. 
  /// This is the default behavior.
  immediateWithTimeProration,

  /// Replacement takes effect immediately, and the new plan will take effect 
  /// immediately and be charged when the old plan expires.
  immediateWithoutProration,

  /// Replacement takes effect immediately, and the user is charged the prorated 
  /// price for the rest of the billing period.
  immediateAndChargeProratedPrice,

  /// Replacement takes effect when the old plan expires.
  deferred,
}

/// Android purchase information
class PurchaseAndroid {
  final String? productId;
  final String? transactionId;
  final String? transactionReceipt;
  final String? purchaseToken;
  final int? transactionDate;
  final String? dataAndroid;
  final String? signatureAndroid;
  final String? orderId;
  final int? purchaseStateAndroid;
  final bool? isAcknowledgedAndroid;
  final String? packageNameAndroid;
  final String? developerPayloadAndroid;
  final String? accountIdentifiersAndroid;
  final String? obfuscatedAccountIdAndroid;
  final String? obfuscatedProfileIdAndroid;

  PurchaseAndroid({
    this.productId,
    this.transactionId,
    this.transactionReceipt,
    this.purchaseToken,
    this.transactionDate,
    this.dataAndroid,
    this.signatureAndroid,
    this.orderId,
    this.purchaseStateAndroid,
    this.isAcknowledgedAndroid,
    this.packageNameAndroid,
    this.developerPayloadAndroid,
    this.accountIdentifiersAndroid,
    this.obfuscatedAccountIdAndroid,
    this.obfuscatedProfileIdAndroid,
  });

  factory PurchaseAndroid.fromJson(Map<String, dynamic> json) {
    return PurchaseAndroid(
      productId: json['productId'] as String?,
      transactionId: json['transactionId'] as String?,
      transactionReceipt: json['transactionReceipt'] as String?,
      purchaseToken: json['purchaseToken'] as String?,
      transactionDate: json['transactionDate'] as int?,
      dataAndroid: json['dataAndroid'] as String?,
      signatureAndroid: json['signatureAndroid'] as String?,
      orderId: json['orderId'] as String?,
      purchaseStateAndroid: json['purchaseStateAndroid'] as int?,
      isAcknowledgedAndroid: json['isAcknowledgedAndroid'] as bool?,
      packageNameAndroid: json['packageNameAndroid'] as String?,
      developerPayloadAndroid: json['developerPayloadAndroid'] as String?,
      accountIdentifiersAndroid: json['accountIdentifiersAndroid'] as String?,
      obfuscatedAccountIdAndroid: json['obfuscatedAccountIdAndroid'] as String?,
      obfuscatedProfileIdAndroid: json['obfuscatedProfileIdAndroid'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (productId != null) 'productId': productId,
      if (transactionId != null) 'transactionId': transactionId,
      if (transactionReceipt != null) 'transactionReceipt': transactionReceipt,
      if (purchaseToken != null) 'purchaseToken': purchaseToken,
      if (transactionDate != null) 'transactionDate': transactionDate,
      if (dataAndroid != null) 'dataAndroid': dataAndroid,
      if (signatureAndroid != null) 'signatureAndroid': signatureAndroid,
      if (orderId != null) 'orderId': orderId,
      if (purchaseStateAndroid != null) 'purchaseStateAndroid': purchaseStateAndroid,
      if (isAcknowledgedAndroid != null) 'isAcknowledgedAndroid': isAcknowledgedAndroid,
      if (packageNameAndroid != null) 'packageNameAndroid': packageNameAndroid,
      if (developerPayloadAndroid != null) 'developerPayloadAndroid': developerPayloadAndroid,
      if (accountIdentifiersAndroid != null) 'accountIdentifiersAndroid': accountIdentifiersAndroid,
      if (obfuscatedAccountIdAndroid != null) 'obfuscatedAccountIdAndroid': obfuscatedAccountIdAndroid,
      if (obfuscatedProfileIdAndroid != null) 'obfuscatedProfileIdAndroid': obfuscatedProfileIdAndroid,
    };
  }
}

/// Android billing response codes
class BillingResponseCodeAndroid {
  static const int ok = 0;
  static const int userCanceled = 1;
  static const int serviceUnavailable = 2;
  static const int billingUnavailable = 3;
  static const int itemUnavailable = 4;
  static const int developerError = 5;
  static const int error = 6;
  static const int itemAlreadyOwned = 7;
  static const int itemNotOwned = 8;
  static const int serviceDisconnected = -1;
  static const int featureNotSupported = -2;
  static const int networkError = 12;
}

/// Android purchase states
enum PurchaseStateAndroid {
  pending,
  purchased,
  unspecified,
}

/// Android account identifiers
class AccountIdentifiers {
  final String? obfuscatedAccountId;
  final String? obfuscatedProfileId;

  AccountIdentifiers({
    this.obfuscatedAccountId,
    this.obfuscatedProfileId,
  });

  factory AccountIdentifiers.fromJson(Map<String, dynamic> json) {
    return AccountIdentifiers(
      obfuscatedAccountId: json['obfuscatedAccountId'] as String?,
      obfuscatedProfileId: json['obfuscatedProfileId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (obfuscatedAccountId != null) 'obfuscatedAccountId': obfuscatedAccountId,
      if (obfuscatedProfileId != null) 'obfuscatedProfileId': obfuscatedProfileId,
    };
  }
}