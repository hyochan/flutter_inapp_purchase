/// iOS-specific types for in-app purchases

/// iOS product information
class ProductIos {
  final String productId;
  final String price;
  final String currency;
  final String localizedPrice;
  final String title;
  final String description;
  final PeriodUnit? periodUnit;
  final PeriodUnitIOS? periodUnitIOS;
  final String? discountId;
  final List<PaymentDiscount> discounts;
  final List<PaymentDiscount> introductoryOffers;
  final List<SubscriptionInfo> subscriptionOffers;

  ProductIos({
    required this.productId,
    required this.price,
    required this.currency,
    required this.localizedPrice,
    required this.title,
    required this.description,
    this.periodUnit,
    this.periodUnitIOS,
    this.discountId,
    required this.discounts,
    required this.introductoryOffers,
    required this.subscriptionOffers,
  });

  factory ProductIos.fromJson(Map<String, dynamic> json) {
    return ProductIos(
      productId: (json['productId'] as String?) ?? '',
      price: json['price']?.toString() ?? '',
      currency: (json['currency'] as String?) ?? '',
      localizedPrice: (json['localizedPrice'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      periodUnit: json['periodUnit'] != null
          ? PeriodUnit.values.firstWhere(
              (e) => e.toString().split('.').last == json['periodUnit'],
              orElse: () => PeriodUnit.unknown,
            )
          : null,
      periodUnitIOS: json['periodUnitIOS'] != null
          ? PeriodUnitIOS.values.firstWhere(
              (e) => e.toString().split('.').last == json['periodUnitIOS'],
              orElse: () => PeriodUnitIOS.NONE,
            )
          : null,
      discountId: json['discountId'] as String?,
      discounts: (json['discounts'] as List<dynamic>?)
              ?.map((e) => PaymentDiscount.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      introductoryOffers: (json['introductoryOffers'] as List<dynamic>?)
              ?.map((e) => PaymentDiscount.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      subscriptionOffers: (json['subscriptionOffers'] as List<dynamic>?)
              ?.map((e) => SubscriptionInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
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
      if (periodUnit != null)
        'periodUnit': periodUnit!.toString().split('.').last,
      if (periodUnitIOS != null)
        'periodUnitIOS': periodUnitIOS!.toString().split('.').last,
      if (discountId != null) 'discountId': discountId,
      'discounts': discounts.map((e) => e.toJson()).toList(),
      'introductoryOffers': introductoryOffers.map((e) => e.toJson()).toList(),
      'subscriptionOffers': subscriptionOffers.map((e) => e.toJson()).toList(),
    };
  }
}

/// Period units for subscriptions
enum PeriodUnit {
  day,
  week,
  month,
  year,
  unknown,
}

/// iOS-specific period units
enum PeriodUnitIOS {
  DAY,
  WEEK,
  MONTH,
  YEAR,
  NONE,
}

/// iOS subscription information
class SubscriptionInfo {
  final List<SubscriptionOffer> subscriptionOffers;
  final String? groupIdentifier;
  final String? subscriptionPeriod;

  SubscriptionInfo({
    required this.subscriptionOffers,
    this.groupIdentifier,
    this.subscriptionPeriod,
  });

  factory SubscriptionInfo.fromJson(Map<String, dynamic> json) {
    return SubscriptionInfo(
      subscriptionOffers: (json['subscriptionOffers'] as List<dynamic>?)
              ?.map(
                  (e) => SubscriptionOffer.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      groupIdentifier: json['groupIdentifier'] as String?,
      subscriptionPeriod: json['subscriptionPeriod'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subscriptionOffers': subscriptionOffers.map((e) => e.toJson()).toList(),
      if (groupIdentifier != null) 'groupIdentifier': groupIdentifier,
      if (subscriptionPeriod != null) 'subscriptionPeriod': subscriptionPeriod,
    };
  }
}

/// iOS subscription offer
class SubscriptionOffer {
  final String? sku;
  final PaymentDiscount? offer;

  SubscriptionOffer({
    this.sku,
    this.offer,
  });

  factory SubscriptionOffer.fromJson(Map<String, dynamic> json) {
    return SubscriptionOffer(
      sku: json['sku'] as String?,
      offer: json['offer'] != null
          ? PaymentDiscount.fromJson(json['offer'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (sku != null) 'sku': sku,
      if (offer != null) 'offer': offer!.toJson(),
    };
  }
}

/// iOS payment discount information
class PaymentDiscount {
  final String identifier;
  final String type;
  final String price;
  final String localizedPrice;
  final String paymentMode;
  final int numberOfPeriods;
  final String? subscriptionPeriod;

  PaymentDiscount({
    required this.identifier,
    required this.type,
    required this.price,
    required this.localizedPrice,
    required this.paymentMode,
    required this.numberOfPeriods,
    this.subscriptionPeriod,
  });

  factory PaymentDiscount.fromJson(Map<String, dynamic> json) {
    return PaymentDiscount(
      identifier: (json['identifier'] as String?) ?? '',
      type: (json['type'] as String?) ?? '',
      price: json['price']?.toString() ?? '',
      localizedPrice: (json['localizedPrice'] as String?) ?? '',
      paymentMode: (json['paymentMode'] as String?) ?? '',
      numberOfPeriods: (json['numberOfPeriods'] as int?) ?? 0,
      subscriptionPeriod: json['subscriptionPeriod'] as String?,
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
      if (subscriptionPeriod != null) 'subscriptionPeriod': subscriptionPeriod,
    };
  }
}

/// iOS purchase request properties
class RequestPurchaseIosProps {
  final String sku;
  final String? applicationUsername;
  final bool? simulatesAskToBuyInSandbox;
  final int? quantity;
  final PaymentDiscount? withOffer;

  RequestPurchaseIosProps({
    required this.sku,
    this.applicationUsername,
    this.simulatesAskToBuyInSandbox,
    this.quantity,
    this.withOffer,
  });

  Map<String, dynamic> toJson() {
    return {
      'sku': sku,
      if (applicationUsername != null)
        'applicationUsername': applicationUsername,
      if (simulatesAskToBuyInSandbox != null)
        'simulatesAskToBuyInSandbox': simulatesAskToBuyInSandbox,
      if (quantity != null) 'quantity': quantity,
      if (withOffer != null) 'withOffer': withOffer!.toJson(),
    };
  }
}

/// iOS purchase information
class PurchaseIos {
  final String? productId;
  final String? transactionId;
  final String? transactionReceipt;
  final String? applicationUsername;
  final int? transactionDate;
  final String? originalTransactionDateIOS;
  final String? originalTransactionIdentifierIOS;
  final bool? isUpgrade;
  final String? verificationData;

  PurchaseIos({
    this.productId,
    this.transactionId,
    this.transactionReceipt,
    this.applicationUsername,
    this.transactionDate,
    this.originalTransactionDateIOS,
    this.originalTransactionIdentifierIOS,
    this.isUpgrade,
    this.verificationData,
  });

  factory PurchaseIos.fromJson(Map<String, dynamic> json) {
    return PurchaseIos(
      productId: json['productId'] as String?,
      transactionId: json['transactionId'] as String?,
      transactionReceipt: json['transactionReceipt'] as String?,
      applicationUsername: json['applicationUsername'] as String?,
      transactionDate: json['transactionDate'] as int?,
      originalTransactionDateIOS: json['originalTransactionDateIOS'] as String?,
      originalTransactionIdentifierIOS:
          json['originalTransactionIdentifierIOS'] as String?,
      isUpgrade: json['isUpgrade'] as bool?,
      verificationData: json['verificationData'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (productId != null) 'productId': productId,
      if (transactionId != null) 'transactionId': transactionId,
      if (transactionReceipt != null) 'transactionReceipt': transactionReceipt,
      if (applicationUsername != null)
        'applicationUsername': applicationUsername,
      if (transactionDate != null) 'transactionDate': transactionDate,
      if (originalTransactionDateIOS != null)
        'originalTransactionDateIOS': originalTransactionDateIOS,
      if (originalTransactionIdentifierIOS != null)
        'originalTransactionIdentifierIOS': originalTransactionIdentifierIOS,
      if (isUpgrade != null) 'isUpgrade': isUpgrade,
      if (verificationData != null) 'verificationData': verificationData,
    };
  }
}

/// iOS App Transaction information (iOS 18.4+)
class AppTransactionIOS {
  final String? appAppleId;
  final String? bundleId;
  final String? originalAppVersion;
  final String? originalPurchaseDate;
  final String? appTransactionID;
  final String? originalPlatform;
  final String? deviceVerification;
  final String? deviceVerificationNonce;
  final String? preorderDate;

  AppTransactionIOS({
    this.appAppleId,
    this.bundleId,
    this.originalAppVersion,
    this.originalPurchaseDate,
    this.appTransactionID,
    this.originalPlatform,
    this.deviceVerification,
    this.deviceVerificationNonce,
    this.preorderDate,
  });

  factory AppTransactionIOS.fromJson(Map<String, dynamic> json) {
    return AppTransactionIOS(
      appAppleId: json['appAppleId'] as String?,
      bundleId: json['bundleId'] as String?,
      originalAppVersion: json['originalAppVersion'] as String?,
      originalPurchaseDate: json['originalPurchaseDate'] as String?,
      appTransactionID: json['appTransactionID'] as String?,
      originalPlatform: json['originalPlatform'] as String?,
      deviceVerification: json['deviceVerification'] as String?,
      deviceVerificationNonce: json['deviceVerificationNonce'] as String?,
      preorderDate: json['preorderDate'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (appAppleId != null) 'appAppleId': appAppleId,
      if (bundleId != null) 'bundleId': bundleId,
      if (originalAppVersion != null) 'originalAppVersion': originalAppVersion,
      if (originalPurchaseDate != null)
        'originalPurchaseDate': originalPurchaseDate,
      if (appTransactionID != null) 'appTransactionID': appTransactionID,
      if (originalPlatform != null) 'originalPlatform': originalPlatform,
      if (deviceVerification != null) 'deviceVerification': deviceVerification,
      if (deviceVerificationNonce != null)
        'deviceVerificationNonce': deviceVerificationNonce,
      if (preorderDate != null) 'preorderDate': preorderDate,
    };
  }
}

/// iOS transaction states
enum TransactionStateIOS {
  purchasing,
  purchased,
  failed,
  restored,
  deferred,
}

/// iOS promotional offer
class PromotionalOffer {
  final String offerIdentifier;
  final String keyIdentifier;
  final String nonce;
  final String signature;
  final int timestamp;

  PromotionalOffer({
    required this.offerIdentifier,
    required this.keyIdentifier,
    required this.nonce,
    required this.signature,
    required this.timestamp,
  });

  factory PromotionalOffer.fromJson(Map<String, dynamic> json) {
    return PromotionalOffer(
      offerIdentifier: (json['offerIdentifier'] as String?) ?? '',
      keyIdentifier: (json['keyIdentifier'] as String?) ?? '',
      nonce: (json['nonce'] as String?) ?? '',
      signature: (json['signature'] as String?) ?? '',
      timestamp: (json['timestamp'] as int?) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'offerIdentifier': offerIdentifier,
      'keyIdentifier': keyIdentifier,
      'nonce': nonce,
      'signature': signature,
      'timestamp': timestamp,
    };
  }
}

/// iOS receipt validation response
class ReceiptValidationResponseIOS {
  final int status;
  final Map<String, dynamic>? receipt;
  final Map<String, dynamic>? latestReceiptInfo;
  final List<Map<String, dynamic>>? latestReceipts;

  ReceiptValidationResponseIOS({
    required this.status,
    this.receipt,
    this.latestReceiptInfo,
    this.latestReceipts,
  });

  factory ReceiptValidationResponseIOS.fromJson(Map<String, dynamic> json) {
    return ReceiptValidationResponseIOS(
      status: (json['status'] as int?) ?? 0,
      receipt: json['receipt'] as Map<String, dynamic>?,
      latestReceiptInfo: json['latest_receipt_info'] as Map<String, dynamic>?,
      latestReceipts: json['latest_receipts'] != null
          ? List<Map<String, dynamic>>.from(
              json['latest_receipts'] as List<dynamic>)
          : null,
    );
  }
}

/// iOS subscription status
enum SubscriptionStateIOS {
  active,
  expired,
  inBillingRetry,
  inGracePeriod,
  revoked,
}
