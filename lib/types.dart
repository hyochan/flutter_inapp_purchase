// ============================================================================
// AUTO-GENERATED TYPES — DO NOT EDIT DIRECTLY
// Run `npm run generate` after updating any *.graphql schema file.
// ============================================================================

// ignore_for_file: unused_element, unused_field

import 'dart:async';

// MARK: - Enums

enum ErrorCode {
  Unknown('UNKNOWN'),
  UserCancelled('USER_CANCELLED'),
  UserError('USER_ERROR'),
  ItemUnavailable('ITEM_UNAVAILABLE'),
  RemoteError('REMOTE_ERROR'),
  NetworkError('NETWORK_ERROR'),
  ServiceError('SERVICE_ERROR'),
  ReceiptFailed('RECEIPT_FAILED'),
  ReceiptFinished('RECEIPT_FINISHED'),
  ReceiptFinishedFailed('RECEIPT_FINISHED_FAILED'),
  NotPrepared('NOT_PREPARED'),
  NotEnded('NOT_ENDED'),
  AlreadyOwned('ALREADY_OWNED'),
  DeveloperError('DEVELOPER_ERROR'),
  BillingResponseJsonParseError('BILLING_RESPONSE_JSON_PARSE_ERROR'),
  DeferredPayment('DEFERRED_PAYMENT'),
  Interrupted('INTERRUPTED'),
  IapNotAvailable('IAP_NOT_AVAILABLE'),
  PurchaseError('PURCHASE_ERROR'),
  SyncError('SYNC_ERROR'),
  TransactionValidationFailed('TRANSACTION_VALIDATION_FAILED'),
  ActivityUnavailable('ACTIVITY_UNAVAILABLE'),
  AlreadyPrepared('ALREADY_PREPARED'),
  Pending('PENDING'),
  ConnectionClosed('CONNECTION_CLOSED'),
  InitConnection('INIT_CONNECTION'),
  ServiceDisconnected('SERVICE_DISCONNECTED'),
  QueryProduct('QUERY_PRODUCT'),
  SkuNotFound('SKU_NOT_FOUND'),
  SkuOfferMismatch('SKU_OFFER_MISMATCH'),
  ItemNotOwned('ITEM_NOT_OWNED'),
  BillingUnavailable('BILLING_UNAVAILABLE'),
  FeatureNotSupported('FEATURE_NOT_SUPPORTED'),
  EmptySkuList('EMPTY_SKU_LIST');

  const ErrorCode(this.value);
  final String value;

  factory ErrorCode.fromJson(String value) {
    switch (value) {
      case 'UNKNOWN':
        return ErrorCode.Unknown;
      case 'Unknown':
        return ErrorCode.Unknown;
      case 'USER_CANCELLED':
        return ErrorCode.UserCancelled;
      case 'UserCancelled':
        return ErrorCode.UserCancelled;
      case 'USER_ERROR':
        return ErrorCode.UserError;
      case 'UserError':
        return ErrorCode.UserError;
      case 'ITEM_UNAVAILABLE':
        return ErrorCode.ItemUnavailable;
      case 'ItemUnavailable':
        return ErrorCode.ItemUnavailable;
      case 'REMOTE_ERROR':
        return ErrorCode.RemoteError;
      case 'RemoteError':
        return ErrorCode.RemoteError;
      case 'NETWORK_ERROR':
        return ErrorCode.NetworkError;
      case 'NetworkError':
        return ErrorCode.NetworkError;
      case 'SERVICE_ERROR':
        return ErrorCode.ServiceError;
      case 'ServiceError':
        return ErrorCode.ServiceError;
      case 'RECEIPT_FAILED':
        return ErrorCode.ReceiptFailed;
      case 'ReceiptFailed':
        return ErrorCode.ReceiptFailed;
      case 'RECEIPT_FINISHED':
        return ErrorCode.ReceiptFinished;
      case 'ReceiptFinished':
        return ErrorCode.ReceiptFinished;
      case 'RECEIPT_FINISHED_FAILED':
        return ErrorCode.ReceiptFinishedFailed;
      case 'ReceiptFinishedFailed':
        return ErrorCode.ReceiptFinishedFailed;
      case 'NOT_PREPARED':
        return ErrorCode.NotPrepared;
      case 'NotPrepared':
        return ErrorCode.NotPrepared;
      case 'NOT_ENDED':
        return ErrorCode.NotEnded;
      case 'NotEnded':
        return ErrorCode.NotEnded;
      case 'ALREADY_OWNED':
        return ErrorCode.AlreadyOwned;
      case 'AlreadyOwned':
        return ErrorCode.AlreadyOwned;
      case 'DEVELOPER_ERROR':
        return ErrorCode.DeveloperError;
      case 'DeveloperError':
        return ErrorCode.DeveloperError;
      case 'BILLING_RESPONSE_JSON_PARSE_ERROR':
        return ErrorCode.BillingResponseJsonParseError;
      case 'BillingResponseJsonParseError':
        return ErrorCode.BillingResponseJsonParseError;
      case 'DEFERRED_PAYMENT':
        return ErrorCode.DeferredPayment;
      case 'DeferredPayment':
        return ErrorCode.DeferredPayment;
      case 'INTERRUPTED':
        return ErrorCode.Interrupted;
      case 'Interrupted':
        return ErrorCode.Interrupted;
      case 'IAP_NOT_AVAILABLE':
        return ErrorCode.IapNotAvailable;
      case 'IapNotAvailable':
        return ErrorCode.IapNotAvailable;
      case 'PURCHASE_ERROR':
        return ErrorCode.PurchaseError;
      case 'PurchaseError':
        return ErrorCode.PurchaseError;
      case 'SYNC_ERROR':
        return ErrorCode.SyncError;
      case 'SyncError':
        return ErrorCode.SyncError;
      case 'TRANSACTION_VALIDATION_FAILED':
        return ErrorCode.TransactionValidationFailed;
      case 'TransactionValidationFailed':
        return ErrorCode.TransactionValidationFailed;
      case 'ACTIVITY_UNAVAILABLE':
        return ErrorCode.ActivityUnavailable;
      case 'ActivityUnavailable':
        return ErrorCode.ActivityUnavailable;
      case 'ALREADY_PREPARED':
        return ErrorCode.AlreadyPrepared;
      case 'AlreadyPrepared':
        return ErrorCode.AlreadyPrepared;
      case 'PENDING':
        return ErrorCode.Pending;
      case 'Pending':
        return ErrorCode.Pending;
      case 'CONNECTION_CLOSED':
        return ErrorCode.ConnectionClosed;
      case 'ConnectionClosed':
        return ErrorCode.ConnectionClosed;
      case 'INIT_CONNECTION':
        return ErrorCode.InitConnection;
      case 'InitConnection':
        return ErrorCode.InitConnection;
      case 'SERVICE_DISCONNECTED':
        return ErrorCode.ServiceDisconnected;
      case 'ServiceDisconnected':
        return ErrorCode.ServiceDisconnected;
      case 'QUERY_PRODUCT':
        return ErrorCode.QueryProduct;
      case 'QueryProduct':
        return ErrorCode.QueryProduct;
      case 'SKU_NOT_FOUND':
        return ErrorCode.SkuNotFound;
      case 'SkuNotFound':
        return ErrorCode.SkuNotFound;
      case 'SKU_OFFER_MISMATCH':
        return ErrorCode.SkuOfferMismatch;
      case 'SkuOfferMismatch':
        return ErrorCode.SkuOfferMismatch;
      case 'ITEM_NOT_OWNED':
        return ErrorCode.ItemNotOwned;
      case 'ItemNotOwned':
        return ErrorCode.ItemNotOwned;
      case 'BILLING_UNAVAILABLE':
        return ErrorCode.BillingUnavailable;
      case 'BillingUnavailable':
        return ErrorCode.BillingUnavailable;
      case 'FEATURE_NOT_SUPPORTED':
        return ErrorCode.FeatureNotSupported;
      case 'FeatureNotSupported':
        return ErrorCode.FeatureNotSupported;
      case 'EMPTY_SKU_LIST':
        return ErrorCode.EmptySkuList;
      case 'EmptySkuList':
        return ErrorCode.EmptySkuList;
    }
    throw ArgumentError('Unknown ErrorCode value: $value');
  }

  String toJson() => value;
}

enum IapEvent {
  PurchaseUpdated('PURCHASE_UPDATED'),
  PurchaseError('PURCHASE_ERROR'),
  PromotedProductIOS('PROMOTED_PRODUCT_IOS');

  const IapEvent(this.value);
  final String value;

  factory IapEvent.fromJson(String value) {
    switch (value) {
      case 'PURCHASE_UPDATED':
        return IapEvent.PurchaseUpdated;
      case 'PurchaseUpdated':
        return IapEvent.PurchaseUpdated;
      case 'PURCHASE_ERROR':
        return IapEvent.PurchaseError;
      case 'PurchaseError':
        return IapEvent.PurchaseError;
      case 'PROMOTED_PRODUCT_IOS':
        return IapEvent.PromotedProductIOS;
      case 'PromotedProductIOS':
        return IapEvent.PromotedProductIOS;
    }
    throw ArgumentError('Unknown IapEvent value: $value');
  }

  String toJson() => value;
}

enum IapPlatform {
  IOS('IOS'),
  Android('ANDROID');

  const IapPlatform(this.value);
  final String value;

  factory IapPlatform.fromJson(String value) {
    switch (value) {
      case 'IOS':
        return IapPlatform.IOS;
      case 'ANDROID':
        return IapPlatform.Android;
      case 'Android':
        return IapPlatform.Android;
    }
    throw ArgumentError('Unknown IapPlatform value: $value');
  }

  String toJson() => value;
}

enum PaymentModeIOS {
  Empty('EMPTY'),
  FreeTrial('FREE_TRIAL'),
  PayAsYouGo('PAY_AS_YOU_GO'),
  PayUpFront('PAY_UP_FRONT');

  const PaymentModeIOS(this.value);
  final String value;

  factory PaymentModeIOS.fromJson(String value) {
    switch (value) {
      case 'EMPTY':
        return PaymentModeIOS.Empty;
      case 'Empty':
        return PaymentModeIOS.Empty;
      case 'FREE_TRIAL':
        return PaymentModeIOS.FreeTrial;
      case 'FreeTrial':
        return PaymentModeIOS.FreeTrial;
      case 'PAY_AS_YOU_GO':
        return PaymentModeIOS.PayAsYouGo;
      case 'PayAsYouGo':
        return PaymentModeIOS.PayAsYouGo;
      case 'PAY_UP_FRONT':
        return PaymentModeIOS.PayUpFront;
      case 'PayUpFront':
        return PaymentModeIOS.PayUpFront;
    }
    throw ArgumentError('Unknown PaymentModeIOS value: $value');
  }

  String toJson() => value;
}

enum ProductQueryType {
  InApp('IN_APP'),
  Subs('SUBS'),
  All('ALL');

  const ProductQueryType(this.value);
  final String value;

  factory ProductQueryType.fromJson(String value) {
    switch (value) {
      case 'IN_APP':
        return ProductQueryType.InApp;
      case 'InApp':
        return ProductQueryType.InApp;
      case 'SUBS':
        return ProductQueryType.Subs;
      case 'Subs':
        return ProductQueryType.Subs;
      case 'ALL':
        return ProductQueryType.All;
      case 'All':
        return ProductQueryType.All;
    }
    throw ArgumentError('Unknown ProductQueryType value: $value');
  }

  String toJson() => value;
}

enum ProductType {
  InApp('IN_APP'),
  Subs('SUBS');

  const ProductType(this.value);
  final String value;

  factory ProductType.fromJson(String value) {
    switch (value) {
      case 'IN_APP':
        return ProductType.InApp;
      case 'InApp':
        return ProductType.InApp;
      case 'SUBS':
        return ProductType.Subs;
      case 'Subs':
        return ProductType.Subs;
    }
    throw ArgumentError('Unknown ProductType value: $value');
  }

  String toJson() => value;
}

enum ProductTypeIOS {
  Consumable('CONSUMABLE'),
  NonConsumable('NON_CONSUMABLE'),
  AutoRenewableSubscription('AUTO_RENEWABLE_SUBSCRIPTION'),
  NonRenewingSubscription('NON_RENEWING_SUBSCRIPTION');

  const ProductTypeIOS(this.value);
  final String value;

  factory ProductTypeIOS.fromJson(String value) {
    switch (value) {
      case 'CONSUMABLE':
        return ProductTypeIOS.Consumable;
      case 'Consumable':
        return ProductTypeIOS.Consumable;
      case 'NON_CONSUMABLE':
        return ProductTypeIOS.NonConsumable;
      case 'NonConsumable':
        return ProductTypeIOS.NonConsumable;
      case 'AUTO_RENEWABLE_SUBSCRIPTION':
        return ProductTypeIOS.AutoRenewableSubscription;
      case 'AutoRenewableSubscription':
        return ProductTypeIOS.AutoRenewableSubscription;
      case 'NON_RENEWING_SUBSCRIPTION':
        return ProductTypeIOS.NonRenewingSubscription;
      case 'NonRenewingSubscription':
        return ProductTypeIOS.NonRenewingSubscription;
    }
    throw ArgumentError('Unknown ProductTypeIOS value: $value');
  }

  String toJson() => value;
}

enum PurchaseState {
  Pending('PENDING'),
  Purchased('PURCHASED'),
  Failed('FAILED'),
  Restored('RESTORED'),
  Deferred('DEFERRED'),
  Unknown('UNKNOWN');

  const PurchaseState(this.value);
  final String value;

  factory PurchaseState.fromJson(String value) {
    switch (value) {
      case 'PENDING':
        return PurchaseState.Pending;
      case 'Pending':
        return PurchaseState.Pending;
      case 'PURCHASED':
        return PurchaseState.Purchased;
      case 'Purchased':
        return PurchaseState.Purchased;
      case 'FAILED':
        return PurchaseState.Failed;
      case 'Failed':
        return PurchaseState.Failed;
      case 'RESTORED':
        return PurchaseState.Restored;
      case 'Restored':
        return PurchaseState.Restored;
      case 'DEFERRED':
        return PurchaseState.Deferred;
      case 'Deferred':
        return PurchaseState.Deferred;
      case 'UNKNOWN':
        return PurchaseState.Unknown;
      case 'Unknown':
        return PurchaseState.Unknown;
    }
    throw ArgumentError('Unknown PurchaseState value: $value');
  }

  String toJson() => value;
}

enum SubscriptionOfferTypeIOS {
  Introductory('INTRODUCTORY'),
  Promotional('PROMOTIONAL');

  const SubscriptionOfferTypeIOS(this.value);
  final String value;

  factory SubscriptionOfferTypeIOS.fromJson(String value) {
    switch (value) {
      case 'INTRODUCTORY':
        return SubscriptionOfferTypeIOS.Introductory;
      case 'Introductory':
        return SubscriptionOfferTypeIOS.Introductory;
      case 'PROMOTIONAL':
        return SubscriptionOfferTypeIOS.Promotional;
      case 'Promotional':
        return SubscriptionOfferTypeIOS.Promotional;
    }
    throw ArgumentError('Unknown SubscriptionOfferTypeIOS value: $value');
  }

  String toJson() => value;
}

enum SubscriptionPeriodIOS {
  Day('DAY'),
  Week('WEEK'),
  Month('MONTH'),
  Year('YEAR'),
  Empty('EMPTY');

  const SubscriptionPeriodIOS(this.value);
  final String value;

  factory SubscriptionPeriodIOS.fromJson(String value) {
    switch (value) {
      case 'DAY':
        return SubscriptionPeriodIOS.Day;
      case 'Day':
        return SubscriptionPeriodIOS.Day;
      case 'WEEK':
        return SubscriptionPeriodIOS.Week;
      case 'Week':
        return SubscriptionPeriodIOS.Week;
      case 'MONTH':
        return SubscriptionPeriodIOS.Month;
      case 'Month':
        return SubscriptionPeriodIOS.Month;
      case 'YEAR':
        return SubscriptionPeriodIOS.Year;
      case 'Year':
        return SubscriptionPeriodIOS.Year;
      case 'EMPTY':
        return SubscriptionPeriodIOS.Empty;
      case 'Empty':
        return SubscriptionPeriodIOS.Empty;
    }
    throw ArgumentError('Unknown SubscriptionPeriodIOS value: $value');
  }

  String toJson() => value;
}

// MARK: - Interfaces

abstract class ProductCommon {
  String get currency;
  String? get debugDescription;
  String get description;
  String? get displayName;
  String get displayPrice;
  String get id;
  IapPlatform get platform;
  double? get price;
  String get title;
  ProductType get type;
}

abstract class PurchaseCommon {
  String get id;
  List<String>? get ids;
  bool get isAutoRenewing;
  IapPlatform get platform;
  String get productId;
  PurchaseState get purchaseState;
  /// Unified purchase token (iOS JWS, Android purchaseToken)
  String? get purchaseToken;
  int get quantity;
  double get transactionDate;
}

// MARK: - Objects

class ActiveSubscription {
  const ActiveSubscription({
    this.autoRenewingAndroid,
    this.daysUntilExpirationIOS,
    this.environmentIOS,
    this.expirationDateIOS,
    required this.isActive,
    required this.productId,
    this.purchaseToken,
    required this.transactionDate,
    required this.transactionId,
    this.willExpireSoon,
  });

  final bool? autoRenewingAndroid;
  final double? daysUntilExpirationIOS;
  final String? environmentIOS;
  final double? expirationDateIOS;
  final bool isActive;
  final String productId;
  final String? purchaseToken;
  final double transactionDate;
  final String transactionId;
  final bool? willExpireSoon;

  factory ActiveSubscription.fromJson(Map<String, dynamic> json) {
    return ActiveSubscription(
      autoRenewingAndroid: json['autoRenewingAndroid'] as bool?,
      daysUntilExpirationIOS: (json['daysUntilExpirationIOS'] as num?)?.toDouble(),
      environmentIOS: json['environmentIOS'] as String?,
      expirationDateIOS: (json['expirationDateIOS'] as num?)?.toDouble(),
      isActive: json['isActive'] as bool,
      productId: json['productId'] as String,
      purchaseToken: json['purchaseToken'] as String?,
      transactionDate: (json['transactionDate'] as num).toDouble(),
      transactionId: json['transactionId'] as String,
      willExpireSoon: json['willExpireSoon'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '__typename': 'ActiveSubscription',
      'autoRenewingAndroid': autoRenewingAndroid,
      'daysUntilExpirationIOS': daysUntilExpirationIOS,
      'environmentIOS': environmentIOS,
      'expirationDateIOS': expirationDateIOS,
      'isActive': isActive,
      'productId': productId,
      'purchaseToken': purchaseToken,
      'transactionDate': transactionDate,
      'transactionId': transactionId,
      'willExpireSoon': willExpireSoon,
    };
  }
}

class AppTransaction {
  const AppTransaction({
    required this.appId,
    this.appTransactionId,
    required this.appVersion,
    required this.appVersionId,
    required this.bundleId,
    required this.deviceVerification,
    required this.deviceVerificationNonce,
    required this.environment,
    required this.originalAppVersion,
    this.originalPlatform,
    required this.originalPurchaseDate,
    this.preorderDate,
    required this.signedDate,
  });

  final double appId;
  final String? appTransactionId;
  final String appVersion;
  final double appVersionId;
  final String bundleId;
  final String deviceVerification;
  final String deviceVerificationNonce;
  final String environment;
  final String originalAppVersion;
  final String? originalPlatform;
  final double originalPurchaseDate;
  final double? preorderDate;
  final double signedDate;

  factory AppTransaction.fromJson(Map<String, dynamic> json) {
    return AppTransaction(
      appId: (json['appId'] as num).toDouble(),
      appTransactionId: json['appTransactionId'] as String?,
      appVersion: json['appVersion'] as String,
      appVersionId: (json['appVersionId'] as num).toDouble(),
      bundleId: json['bundleId'] as String,
      deviceVerification: json['deviceVerification'] as String,
      deviceVerificationNonce: json['deviceVerificationNonce'] as String,
      environment: json['environment'] as String,
      originalAppVersion: json['originalAppVersion'] as String,
      originalPlatform: json['originalPlatform'] as String?,
      originalPurchaseDate: (json['originalPurchaseDate'] as num).toDouble(),
      preorderDate: (json['preorderDate'] as num?)?.toDouble(),
      signedDate: (json['signedDate'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '__typename': 'AppTransaction',
      'appId': appId,
      'appTransactionId': appTransactionId,
      'appVersion': appVersion,
      'appVersionId': appVersionId,
      'bundleId': bundleId,
      'deviceVerification': deviceVerification,
      'deviceVerificationNonce': deviceVerificationNonce,
      'environment': environment,
      'originalAppVersion': originalAppVersion,
      'originalPlatform': originalPlatform,
      'originalPurchaseDate': originalPurchaseDate,
      'preorderDate': preorderDate,
      'signedDate': signedDate,
    };
  }
}

class DiscountIOS {
  const DiscountIOS({
    required this.identifier,
    this.localizedPrice,
    required this.numberOfPeriods,
    required this.paymentMode,
    required this.price,
    required this.priceAmount,
    required this.subscriptionPeriod,
    required this.type,
  });

  final String identifier;
  final String? localizedPrice;
  final int numberOfPeriods;
  final PaymentModeIOS paymentMode;
  final String price;
  final double priceAmount;
  final String subscriptionPeriod;
  final String type;

  factory DiscountIOS.fromJson(Map<String, dynamic> json) {
    return DiscountIOS(
      identifier: json['identifier'] as String,
      localizedPrice: json['localizedPrice'] as String?,
      numberOfPeriods: json['numberOfPeriods'] as int,
      paymentMode: PaymentModeIOS.fromJson(json['paymentMode'] as String),
      price: json['price'] as String,
      priceAmount: (json['priceAmount'] as num).toDouble(),
      subscriptionPeriod: json['subscriptionPeriod'] as String,
      type: json['type'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '__typename': 'DiscountIOS',
      'identifier': identifier,
      'localizedPrice': localizedPrice,
      'numberOfPeriods': numberOfPeriods,
      'paymentMode': paymentMode.toJson(),
      'price': price,
      'priceAmount': priceAmount,
      'subscriptionPeriod': subscriptionPeriod,
      'type': type,
    };
  }
}

class DiscountOfferIOS {
  const DiscountOfferIOS({
    /// Discount identifier
    required this.identifier,
    /// Key identifier for validation
    required this.keyIdentifier,
    /// Cryptographic nonce
    required this.nonce,
    /// Signature for validation
    required this.signature,
    /// Timestamp of discount offer
    required this.timestamp,
  });

  /// Discount identifier
  final String identifier;
  /// Key identifier for validation
  final String keyIdentifier;
  /// Cryptographic nonce
  final String nonce;
  /// Signature for validation
  final String signature;
  /// Timestamp of discount offer
  final double timestamp;

  factory DiscountOfferIOS.fromJson(Map<String, dynamic> json) {
    return DiscountOfferIOS(
      identifier: json['identifier'] as String,
      keyIdentifier: json['keyIdentifier'] as String,
      nonce: json['nonce'] as String,
      signature: json['signature'] as String,
      timestamp: (json['timestamp'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '__typename': 'DiscountOfferIOS',
      'identifier': identifier,
      'keyIdentifier': keyIdentifier,
      'nonce': nonce,
      'signature': signature,
      'timestamp': timestamp,
    };
  }
}

class EntitlementIOS {
  const EntitlementIOS({
    required this.jsonRepresentation,
    required this.sku,
    required this.transactionId,
  });

  final String jsonRepresentation;
  final String sku;
  final String transactionId;

  factory EntitlementIOS.fromJson(Map<String, dynamic> json) {
    return EntitlementIOS(
      jsonRepresentation: json['jsonRepresentation'] as String,
      sku: json['sku'] as String,
      transactionId: json['transactionId'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '__typename': 'EntitlementIOS',
      'jsonRepresentation': jsonRepresentation,
      'sku': sku,
      'transactionId': transactionId,
    };
  }
}

class FetchProductsResult {
  const FetchProductsResult({
    this.products,
    this.subscriptions,
  });

  final List<Product>? products;
  final List<ProductSubscription>? subscriptions;

  factory FetchProductsResult.fromJson(Map<String, dynamic> json) {
    return FetchProductsResult(
      products: (json['products'] as List<dynamic>?) == null ? null : (json['products'] as List<dynamic>?)!.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList(),
      subscriptions: (json['subscriptions'] as List<dynamic>?) == null ? null : (json['subscriptions'] as List<dynamic>?)!.map((e) => ProductSubscription.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '__typename': 'FetchProductsResult',
      'products': products == null ? null : products!.map((e) => e.toJson()).toList(),
      'subscriptions': subscriptions == null ? null : subscriptions!.map((e) => e.toJson()).toList(),
    };
  }
}

class PricingPhaseAndroid {
  const PricingPhaseAndroid({
    required this.billingCycleCount,
    required this.billingPeriod,
    required this.formattedPrice,
    required this.priceAmountMicros,
    required this.priceCurrencyCode,
    required this.recurrenceMode,
  });

  final int billingCycleCount;
  final String billingPeriod;
  final String formattedPrice;
  final String priceAmountMicros;
  final String priceCurrencyCode;
  final int recurrenceMode;

  factory PricingPhaseAndroid.fromJson(Map<String, dynamic> json) {
    return PricingPhaseAndroid(
      billingCycleCount: json['billingCycleCount'] as int,
      billingPeriod: json['billingPeriod'] as String,
      formattedPrice: json['formattedPrice'] as String,
      priceAmountMicros: json['priceAmountMicros'] as String,
      priceCurrencyCode: json['priceCurrencyCode'] as String,
      recurrenceMode: json['recurrenceMode'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '__typename': 'PricingPhaseAndroid',
      'billingCycleCount': billingCycleCount,
      'billingPeriod': billingPeriod,
      'formattedPrice': formattedPrice,
      'priceAmountMicros': priceAmountMicros,
      'priceCurrencyCode': priceCurrencyCode,
      'recurrenceMode': recurrenceMode,
    };
  }
}

class PricingPhasesAndroid {
  const PricingPhasesAndroid({
    required this.pricingPhaseList,
  });

  final List<PricingPhaseAndroid> pricingPhaseList;

  factory PricingPhasesAndroid.fromJson(Map<String, dynamic> json) {
    return PricingPhasesAndroid(
      pricingPhaseList: (json['pricingPhaseList'] as List<dynamic>).map((e) => PricingPhaseAndroid.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '__typename': 'PricingPhasesAndroid',
      'pricingPhaseList': pricingPhaseList.map((e) => e.toJson()).toList(),
    };
  }
}

class ProductAndroid extends Product implements ProductCommon {
  const ProductAndroid({
    required this.currency,
    this.debugDescription,
    required this.description,
    this.displayName,
    required this.displayPrice,
    required this.id,
    required this.nameAndroid,
    this.oneTimePurchaseOfferDetailsAndroid,
    required this.platform,
    this.price,
    this.subscriptionOfferDetailsAndroid,
    required this.title,
    required this.type,
  });

  final String currency;
  final String? debugDescription;
  final String description;
  final String? displayName;
  final String displayPrice;
  final String id;
  final String nameAndroid;
  final ProductAndroidOneTimePurchaseOfferDetail? oneTimePurchaseOfferDetailsAndroid;
  final IapPlatform platform;
  final double? price;
  final List<ProductSubscriptionAndroidOfferDetails>? subscriptionOfferDetailsAndroid;
  final String title;
  final ProductType type;

  factory ProductAndroid.fromJson(Map<String, dynamic> json) {
    return ProductAndroid(
      currency: json['currency'] as String,
      debugDescription: json['debugDescription'] as String?,
      description: json['description'] as String,
      displayName: json['displayName'] as String?,
      displayPrice: json['displayPrice'] as String,
      id: json['id'] as String,
      nameAndroid: json['nameAndroid'] as String,
      oneTimePurchaseOfferDetailsAndroid: json['oneTimePurchaseOfferDetailsAndroid'] != null ? ProductAndroidOneTimePurchaseOfferDetail.fromJson(json['oneTimePurchaseOfferDetailsAndroid'] as Map<String, dynamic>) : null,
      platform: IapPlatform.fromJson(json['platform'] as String),
      price: (json['price'] as num?)?.toDouble(),
      subscriptionOfferDetailsAndroid: (json['subscriptionOfferDetailsAndroid'] as List<dynamic>?) == null ? null : (json['subscriptionOfferDetailsAndroid'] as List<dynamic>?)!.map((e) => ProductSubscriptionAndroidOfferDetails.fromJson(e as Map<String, dynamic>)).toList(),
      title: json['title'] as String,
      type: ProductType.fromJson(json['type'] as String),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      '__typename': 'ProductAndroid',
      'currency': currency,
      'debugDescription': debugDescription,
      'description': description,
      'displayName': displayName,
      'displayPrice': displayPrice,
      'id': id,
      'nameAndroid': nameAndroid,
      'oneTimePurchaseOfferDetailsAndroid': oneTimePurchaseOfferDetailsAndroid?.toJson(),
      'platform': platform.toJson(),
      'price': price,
      'subscriptionOfferDetailsAndroid': subscriptionOfferDetailsAndroid == null ? null : subscriptionOfferDetailsAndroid!.map((e) => e.toJson()).toList(),
      'title': title,
      'type': type.toJson(),
    };
  }
}

class ProductAndroidOneTimePurchaseOfferDetail {
  const ProductAndroidOneTimePurchaseOfferDetail({
    required this.formattedPrice,
    required this.priceAmountMicros,
    required this.priceCurrencyCode,
  });

  final String formattedPrice;
  final String priceAmountMicros;
  final String priceCurrencyCode;

  factory ProductAndroidOneTimePurchaseOfferDetail.fromJson(Map<String, dynamic> json) {
    return ProductAndroidOneTimePurchaseOfferDetail(
      formattedPrice: json['formattedPrice'] as String,
      priceAmountMicros: json['priceAmountMicros'] as String,
      priceCurrencyCode: json['priceCurrencyCode'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '__typename': 'ProductAndroidOneTimePurchaseOfferDetail',
      'formattedPrice': formattedPrice,
      'priceAmountMicros': priceAmountMicros,
      'priceCurrencyCode': priceCurrencyCode,
    };
  }
}

class ProductIOS extends Product implements ProductCommon {
  const ProductIOS({
    required this.currency,
    this.debugDescription,
    required this.description,
    this.displayName,
    required this.displayNameIOS,
    required this.displayPrice,
    required this.id,
    required this.isFamilyShareableIOS,
    required this.jsonRepresentationIOS,
    required this.platform,
    this.price,
    this.subscriptionInfoIOS,
    required this.title,
    required this.type,
    required this.typeIOS,
  });

  final String currency;
  final String? debugDescription;
  final String description;
  final String? displayName;
  final String displayNameIOS;
  final String displayPrice;
  final String id;
  final bool isFamilyShareableIOS;
  final String jsonRepresentationIOS;
  final IapPlatform platform;
  final double? price;
  final SubscriptionInfoIOS? subscriptionInfoIOS;
  final String title;
  final ProductType type;
  final ProductTypeIOS typeIOS;

  factory ProductIOS.fromJson(Map<String, dynamic> json) {
    return ProductIOS(
      currency: json['currency'] as String,
      debugDescription: json['debugDescription'] as String?,
      description: json['description'] as String,
      displayName: json['displayName'] as String?,
      displayNameIOS: json['displayNameIOS'] as String,
      displayPrice: json['displayPrice'] as String,
      id: json['id'] as String,
      isFamilyShareableIOS: json['isFamilyShareableIOS'] as bool,
      jsonRepresentationIOS: json['jsonRepresentationIOS'] as String,
      platform: IapPlatform.fromJson(json['platform'] as String),
      price: (json['price'] as num?)?.toDouble(),
      subscriptionInfoIOS: json['subscriptionInfoIOS'] != null ? SubscriptionInfoIOS.fromJson(json['subscriptionInfoIOS'] as Map<String, dynamic>) : null,
      title: json['title'] as String,
      type: ProductType.fromJson(json['type'] as String),
      typeIOS: ProductTypeIOS.fromJson(json['typeIOS'] as String),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      '__typename': 'ProductIOS',
      'currency': currency,
      'debugDescription': debugDescription,
      'description': description,
      'displayName': displayName,
      'displayNameIOS': displayNameIOS,
      'displayPrice': displayPrice,
      'id': id,
      'isFamilyShareableIOS': isFamilyShareableIOS,
      'jsonRepresentationIOS': jsonRepresentationIOS,
      'platform': platform.toJson(),
      'price': price,
      'subscriptionInfoIOS': subscriptionInfoIOS?.toJson(),
      'title': title,
      'type': type.toJson(),
      'typeIOS': typeIOS.toJson(),
    };
  }
}

class ProductSubscriptionAndroid extends ProductSubscription implements ProductCommon {
  const ProductSubscriptionAndroid({
    required this.currency,
    this.debugDescription,
    required this.description,
    this.displayName,
    required this.displayPrice,
    required this.id,
    required this.nameAndroid,
    this.oneTimePurchaseOfferDetailsAndroid,
    required this.platform,
    this.price,
    required this.subscriptionOfferDetailsAndroid,
    required this.title,
    required this.type,
  });

  final String currency;
  final String? debugDescription;
  final String description;
  final String? displayName;
  final String displayPrice;
  final String id;
  final String nameAndroid;
  final ProductAndroidOneTimePurchaseOfferDetail? oneTimePurchaseOfferDetailsAndroid;
  final IapPlatform platform;
  final double? price;
  final List<ProductSubscriptionAndroidOfferDetails> subscriptionOfferDetailsAndroid;
  final String title;
  final ProductType type;

  factory ProductSubscriptionAndroid.fromJson(Map<String, dynamic> json) {
    return ProductSubscriptionAndroid(
      currency: json['currency'] as String,
      debugDescription: json['debugDescription'] as String?,
      description: json['description'] as String,
      displayName: json['displayName'] as String?,
      displayPrice: json['displayPrice'] as String,
      id: json['id'] as String,
      nameAndroid: json['nameAndroid'] as String,
      oneTimePurchaseOfferDetailsAndroid: json['oneTimePurchaseOfferDetailsAndroid'] != null ? ProductAndroidOneTimePurchaseOfferDetail.fromJson(json['oneTimePurchaseOfferDetailsAndroid'] as Map<String, dynamic>) : null,
      platform: IapPlatform.fromJson(json['platform'] as String),
      price: (json['price'] as num?)?.toDouble(),
      subscriptionOfferDetailsAndroid: (json['subscriptionOfferDetailsAndroid'] as List<dynamic>).map((e) => ProductSubscriptionAndroidOfferDetails.fromJson(e as Map<String, dynamic>)).toList(),
      title: json['title'] as String,
      type: ProductType.fromJson(json['type'] as String),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      '__typename': 'ProductSubscriptionAndroid',
      'currency': currency,
      'debugDescription': debugDescription,
      'description': description,
      'displayName': displayName,
      'displayPrice': displayPrice,
      'id': id,
      'nameAndroid': nameAndroid,
      'oneTimePurchaseOfferDetailsAndroid': oneTimePurchaseOfferDetailsAndroid?.toJson(),
      'platform': platform.toJson(),
      'price': price,
      'subscriptionOfferDetailsAndroid': subscriptionOfferDetailsAndroid.map((e) => e.toJson()).toList(),
      'title': title,
      'type': type.toJson(),
    };
  }
}

class ProductSubscriptionAndroidOfferDetails {
  const ProductSubscriptionAndroidOfferDetails({
    required this.basePlanId,
    this.offerId,
    required this.offerTags,
    required this.offerToken,
    required this.pricingPhases,
  });

  final String basePlanId;
  final String? offerId;
  final List<String> offerTags;
  final String offerToken;
  final PricingPhasesAndroid pricingPhases;

  factory ProductSubscriptionAndroidOfferDetails.fromJson(Map<String, dynamic> json) {
    return ProductSubscriptionAndroidOfferDetails(
      basePlanId: json['basePlanId'] as String,
      offerId: json['offerId'] as String?,
      offerTags: (json['offerTags'] as List<dynamic>).map((e) => e as String).toList(),
      offerToken: json['offerToken'] as String,
      pricingPhases: PricingPhasesAndroid.fromJson(json['pricingPhases'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '__typename': 'ProductSubscriptionAndroidOfferDetails',
      'basePlanId': basePlanId,
      'offerId': offerId,
      'offerTags': offerTags.map((e) => e).toList(),
      'offerToken': offerToken,
      'pricingPhases': pricingPhases.toJson(),
    };
  }
}

class ProductSubscriptionIOS extends ProductSubscription implements ProductCommon {
  const ProductSubscriptionIOS({
    required this.currency,
    this.debugDescription,
    required this.description,
    this.discountsIOS,
    this.displayName,
    required this.displayNameIOS,
    required this.displayPrice,
    required this.id,
    this.introductoryPriceAsAmountIOS,
    this.introductoryPriceIOS,
    this.introductoryPriceNumberOfPeriodsIOS,
    this.introductoryPricePaymentModeIOS,
    this.introductoryPriceSubscriptionPeriodIOS,
    required this.isFamilyShareableIOS,
    required this.jsonRepresentationIOS,
    required this.platform,
    this.price,
    this.subscriptionInfoIOS,
    this.subscriptionPeriodNumberIOS,
    this.subscriptionPeriodUnitIOS,
    required this.title,
    required this.type,
    required this.typeIOS,
  });

  final String currency;
  final String? debugDescription;
  final String description;
  final List<DiscountIOS>? discountsIOS;
  final String? displayName;
  final String displayNameIOS;
  final String displayPrice;
  final String id;
  final String? introductoryPriceAsAmountIOS;
  final String? introductoryPriceIOS;
  final String? introductoryPriceNumberOfPeriodsIOS;
  final PaymentModeIOS? introductoryPricePaymentModeIOS;
  final SubscriptionPeriodIOS? introductoryPriceSubscriptionPeriodIOS;
  final bool isFamilyShareableIOS;
  final String jsonRepresentationIOS;
  final IapPlatform platform;
  final double? price;
  final SubscriptionInfoIOS? subscriptionInfoIOS;
  final String? subscriptionPeriodNumberIOS;
  final SubscriptionPeriodIOS? subscriptionPeriodUnitIOS;
  final String title;
  final ProductType type;
  final ProductTypeIOS typeIOS;

  factory ProductSubscriptionIOS.fromJson(Map<String, dynamic> json) {
    return ProductSubscriptionIOS(
      currency: json['currency'] as String,
      debugDescription: json['debugDescription'] as String?,
      description: json['description'] as String,
      discountsIOS: (json['discountsIOS'] as List<dynamic>?) == null ? null : (json['discountsIOS'] as List<dynamic>?)!.map((e) => DiscountIOS.fromJson(e as Map<String, dynamic>)).toList(),
      displayName: json['displayName'] as String?,
      displayNameIOS: json['displayNameIOS'] as String,
      displayPrice: json['displayPrice'] as String,
      id: json['id'] as String,
      introductoryPriceAsAmountIOS: json['introductoryPriceAsAmountIOS'] as String?,
      introductoryPriceIOS: json['introductoryPriceIOS'] as String?,
      introductoryPriceNumberOfPeriodsIOS: json['introductoryPriceNumberOfPeriodsIOS'] as String?,
      introductoryPricePaymentModeIOS: json['introductoryPricePaymentModeIOS'] != null ? PaymentModeIOS.fromJson(json['introductoryPricePaymentModeIOS'] as String) : null,
      introductoryPriceSubscriptionPeriodIOS: json['introductoryPriceSubscriptionPeriodIOS'] != null ? SubscriptionPeriodIOS.fromJson(json['introductoryPriceSubscriptionPeriodIOS'] as String) : null,
      isFamilyShareableIOS: json['isFamilyShareableIOS'] as bool,
      jsonRepresentationIOS: json['jsonRepresentationIOS'] as String,
      platform: IapPlatform.fromJson(json['platform'] as String),
      price: (json['price'] as num?)?.toDouble(),
      subscriptionInfoIOS: json['subscriptionInfoIOS'] != null ? SubscriptionInfoIOS.fromJson(json['subscriptionInfoIOS'] as Map<String, dynamic>) : null,
      subscriptionPeriodNumberIOS: json['subscriptionPeriodNumberIOS'] as String?,
      subscriptionPeriodUnitIOS: json['subscriptionPeriodUnitIOS'] != null ? SubscriptionPeriodIOS.fromJson(json['subscriptionPeriodUnitIOS'] as String) : null,
      title: json['title'] as String,
      type: ProductType.fromJson(json['type'] as String),
      typeIOS: ProductTypeIOS.fromJson(json['typeIOS'] as String),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      '__typename': 'ProductSubscriptionIOS',
      'currency': currency,
      'debugDescription': debugDescription,
      'description': description,
      'discountsIOS': discountsIOS == null ? null : discountsIOS!.map((e) => e.toJson()).toList(),
      'displayName': displayName,
      'displayNameIOS': displayNameIOS,
      'displayPrice': displayPrice,
      'id': id,
      'introductoryPriceAsAmountIOS': introductoryPriceAsAmountIOS,
      'introductoryPriceIOS': introductoryPriceIOS,
      'introductoryPriceNumberOfPeriodsIOS': introductoryPriceNumberOfPeriodsIOS,
      'introductoryPricePaymentModeIOS': introductoryPricePaymentModeIOS?.toJson(),
      'introductoryPriceSubscriptionPeriodIOS': introductoryPriceSubscriptionPeriodIOS?.toJson(),
      'isFamilyShareableIOS': isFamilyShareableIOS,
      'jsonRepresentationIOS': jsonRepresentationIOS,
      'platform': platform.toJson(),
      'price': price,
      'subscriptionInfoIOS': subscriptionInfoIOS?.toJson(),
      'subscriptionPeriodNumberIOS': subscriptionPeriodNumberIOS,
      'subscriptionPeriodUnitIOS': subscriptionPeriodUnitIOS?.toJson(),
      'title': title,
      'type': type.toJson(),
      'typeIOS': typeIOS.toJson(),
    };
  }
}

class PurchaseAndroid extends Purchase implements PurchaseCommon {
  const PurchaseAndroid({
    this.autoRenewingAndroid,
    this.dataAndroid,
    this.developerPayloadAndroid,
    required this.id,
    this.ids,
    this.isAcknowledgedAndroid,
    required this.isAutoRenewing,
    this.obfuscatedAccountIdAndroid,
    this.obfuscatedProfileIdAndroid,
    this.packageNameAndroid,
    required this.platform,
    required this.productId,
    required this.purchaseState,
    this.purchaseToken,
    required this.quantity,
    this.signatureAndroid,
    required this.transactionDate,
  });

  final bool? autoRenewingAndroid;
  final String? dataAndroid;
  final String? developerPayloadAndroid;
  final String id;
  final List<String>? ids;
  final bool? isAcknowledgedAndroid;
  final bool isAutoRenewing;
  final String? obfuscatedAccountIdAndroid;
  final String? obfuscatedProfileIdAndroid;
  final String? packageNameAndroid;
  final IapPlatform platform;
  final String productId;
  final PurchaseState purchaseState;
  final String? purchaseToken;
  final int quantity;
  final String? signatureAndroid;
  final double transactionDate;

  factory PurchaseAndroid.fromJson(Map<String, dynamic> json) {
    return PurchaseAndroid(
      autoRenewingAndroid: json['autoRenewingAndroid'] as bool?,
      dataAndroid: json['dataAndroid'] as String?,
      developerPayloadAndroid: json['developerPayloadAndroid'] as String?,
      id: json['id'] as String,
      ids: (json['ids'] as List<dynamic>?) == null ? null : (json['ids'] as List<dynamic>?)!.map((e) => e as String).toList(),
      isAcknowledgedAndroid: json['isAcknowledgedAndroid'] as bool?,
      isAutoRenewing: json['isAutoRenewing'] as bool,
      obfuscatedAccountIdAndroid: json['obfuscatedAccountIdAndroid'] as String?,
      obfuscatedProfileIdAndroid: json['obfuscatedProfileIdAndroid'] as String?,
      packageNameAndroid: json['packageNameAndroid'] as String?,
      platform: IapPlatform.fromJson(json['platform'] as String),
      productId: json['productId'] as String,
      purchaseState: PurchaseState.fromJson(json['purchaseState'] as String),
      purchaseToken: json['purchaseToken'] as String?,
      quantity: json['quantity'] as int,
      signatureAndroid: json['signatureAndroid'] as String?,
      transactionDate: (json['transactionDate'] as num).toDouble(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      '__typename': 'PurchaseAndroid',
      'autoRenewingAndroid': autoRenewingAndroid,
      'dataAndroid': dataAndroid,
      'developerPayloadAndroid': developerPayloadAndroid,
      'id': id,
      'ids': ids == null ? null : ids!.map((e) => e).toList(),
      'isAcknowledgedAndroid': isAcknowledgedAndroid,
      'isAutoRenewing': isAutoRenewing,
      'obfuscatedAccountIdAndroid': obfuscatedAccountIdAndroid,
      'obfuscatedProfileIdAndroid': obfuscatedProfileIdAndroid,
      'packageNameAndroid': packageNameAndroid,
      'platform': platform.toJson(),
      'productId': productId,
      'purchaseState': purchaseState.toJson(),
      'purchaseToken': purchaseToken,
      'quantity': quantity,
      'signatureAndroid': signatureAndroid,
      'transactionDate': transactionDate,
    };
  }
}

class PurchaseError {
  const PurchaseError({
    required this.code,
    required this.message,
    this.productId,
  });

  final ErrorCode code;
  final String message;
  final String? productId;

  factory PurchaseError.fromJson(Map<String, dynamic> json) {
    return PurchaseError(
      code: ErrorCode.fromJson(json['code'] as String),
      message: json['message'] as String,
      productId: json['productId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '__typename': 'PurchaseError',
      'code': code.toJson(),
      'message': message,
      'productId': productId,
    };
  }
}

class PurchaseIOS extends Purchase implements PurchaseCommon {
  const PurchaseIOS({
    this.appAccountToken,
    this.appBundleIdIOS,
    this.countryCodeIOS,
    this.currencyCodeIOS,
    this.currencySymbolIOS,
    this.environmentIOS,
    this.expirationDateIOS,
    required this.id,
    this.ids,
    required this.isAutoRenewing,
    this.isUpgradedIOS,
    this.offerIOS,
    this.originalTransactionDateIOS,
    this.originalTransactionIdentifierIOS,
    this.ownershipTypeIOS,
    required this.platform,
    required this.productId,
    required this.purchaseState,
    this.purchaseToken,
    required this.quantity,
    this.quantityIOS,
    this.reasonIOS,
    this.reasonStringRepresentationIOS,
    this.revocationDateIOS,
    this.revocationReasonIOS,
    this.storefrontCountryCodeIOS,
    this.subscriptionGroupIdIOS,
    required this.transactionDate,
    this.transactionReasonIOS,
    this.webOrderLineItemIdIOS,
  });

  final String? appAccountToken;
  final String? appBundleIdIOS;
  final String? countryCodeIOS;
  final String? currencyCodeIOS;
  final String? currencySymbolIOS;
  final String? environmentIOS;
  final double? expirationDateIOS;
  final String id;
  final List<String>? ids;
  final bool isAutoRenewing;
  final bool? isUpgradedIOS;
  final PurchaseOfferIOS? offerIOS;
  final double? originalTransactionDateIOS;
  final String? originalTransactionIdentifierIOS;
  final String? ownershipTypeIOS;
  final IapPlatform platform;
  final String productId;
  final PurchaseState purchaseState;
  final String? purchaseToken;
  final int quantity;
  final int? quantityIOS;
  final String? reasonIOS;
  final String? reasonStringRepresentationIOS;
  final double? revocationDateIOS;
  final String? revocationReasonIOS;
  final String? storefrontCountryCodeIOS;
  final String? subscriptionGroupIdIOS;
  final double transactionDate;
  final String? transactionReasonIOS;
  final String? webOrderLineItemIdIOS;

  factory PurchaseIOS.fromJson(Map<String, dynamic> json) {
    return PurchaseIOS(
      appAccountToken: json['appAccountToken'] as String?,
      appBundleIdIOS: json['appBundleIdIOS'] as String?,
      countryCodeIOS: json['countryCodeIOS'] as String?,
      currencyCodeIOS: json['currencyCodeIOS'] as String?,
      currencySymbolIOS: json['currencySymbolIOS'] as String?,
      environmentIOS: json['environmentIOS'] as String?,
      expirationDateIOS: (json['expirationDateIOS'] as num?)?.toDouble(),
      id: json['id'] as String,
      ids: (json['ids'] as List<dynamic>?) == null ? null : (json['ids'] as List<dynamic>?)!.map((e) => e as String).toList(),
      isAutoRenewing: json['isAutoRenewing'] as bool,
      isUpgradedIOS: json['isUpgradedIOS'] as bool?,
      offerIOS: json['offerIOS'] != null ? PurchaseOfferIOS.fromJson(json['offerIOS'] as Map<String, dynamic>) : null,
      originalTransactionDateIOS: (json['originalTransactionDateIOS'] as num?)?.toDouble(),
      originalTransactionIdentifierIOS: json['originalTransactionIdentifierIOS'] as String?,
      ownershipTypeIOS: json['ownershipTypeIOS'] as String?,
      platform: IapPlatform.fromJson(json['platform'] as String),
      productId: json['productId'] as String,
      purchaseState: PurchaseState.fromJson(json['purchaseState'] as String),
      purchaseToken: json['purchaseToken'] as String?,
      quantity: json['quantity'] as int,
      quantityIOS: json['quantityIOS'] as int?,
      reasonIOS: json['reasonIOS'] as String?,
      reasonStringRepresentationIOS: json['reasonStringRepresentationIOS'] as String?,
      revocationDateIOS: (json['revocationDateIOS'] as num?)?.toDouble(),
      revocationReasonIOS: json['revocationReasonIOS'] as String?,
      storefrontCountryCodeIOS: json['storefrontCountryCodeIOS'] as String?,
      subscriptionGroupIdIOS: json['subscriptionGroupIdIOS'] as String?,
      transactionDate: (json['transactionDate'] as num).toDouble(),
      transactionReasonIOS: json['transactionReasonIOS'] as String?,
      webOrderLineItemIdIOS: json['webOrderLineItemIdIOS'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      '__typename': 'PurchaseIOS',
      'appAccountToken': appAccountToken,
      'appBundleIdIOS': appBundleIdIOS,
      'countryCodeIOS': countryCodeIOS,
      'currencyCodeIOS': currencyCodeIOS,
      'currencySymbolIOS': currencySymbolIOS,
      'environmentIOS': environmentIOS,
      'expirationDateIOS': expirationDateIOS,
      'id': id,
      'ids': ids == null ? null : ids!.map((e) => e).toList(),
      'isAutoRenewing': isAutoRenewing,
      'isUpgradedIOS': isUpgradedIOS,
      'offerIOS': offerIOS?.toJson(),
      'originalTransactionDateIOS': originalTransactionDateIOS,
      'originalTransactionIdentifierIOS': originalTransactionIdentifierIOS,
      'ownershipTypeIOS': ownershipTypeIOS,
      'platform': platform.toJson(),
      'productId': productId,
      'purchaseState': purchaseState.toJson(),
      'purchaseToken': purchaseToken,
      'quantity': quantity,
      'quantityIOS': quantityIOS,
      'reasonIOS': reasonIOS,
      'reasonStringRepresentationIOS': reasonStringRepresentationIOS,
      'revocationDateIOS': revocationDateIOS,
      'revocationReasonIOS': revocationReasonIOS,
      'storefrontCountryCodeIOS': storefrontCountryCodeIOS,
      'subscriptionGroupIdIOS': subscriptionGroupIdIOS,
      'transactionDate': transactionDate,
      'transactionReasonIOS': transactionReasonIOS,
      'webOrderLineItemIdIOS': webOrderLineItemIdIOS,
    };
  }
}

class PurchaseOfferIOS {
  const PurchaseOfferIOS({
    required this.id,
    required this.paymentMode,
    required this.type,
  });

  final String id;
  final String paymentMode;
  final String type;

  factory PurchaseOfferIOS.fromJson(Map<String, dynamic> json) {
    return PurchaseOfferIOS(
      id: json['id'] as String,
      paymentMode: json['paymentMode'] as String,
      type: json['type'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '__typename': 'PurchaseOfferIOS',
      'id': id,
      'paymentMode': paymentMode,
      'type': type,
    };
  }
}

class ReceiptValidationResultAndroid extends ReceiptValidationResult {
  const ReceiptValidationResultAndroid({
    required this.autoRenewing,
    required this.betaProduct,
    this.cancelDate,
    this.cancelReason,
    this.deferredDate,
    this.deferredSku,
    required this.freeTrialEndDate,
    required this.gracePeriodEndDate,
    required this.parentProductId,
    required this.productId,
    required this.productType,
    required this.purchaseDate,
    required this.quantity,
    required this.receiptId,
    required this.renewalDate,
    required this.term,
    required this.termSku,
    required this.testTransaction,
  });

  final bool autoRenewing;
  final bool betaProduct;
  final double? cancelDate;
  final String? cancelReason;
  final double? deferredDate;
  final String? deferredSku;
  final double freeTrialEndDate;
  final double gracePeriodEndDate;
  final String parentProductId;
  final String productId;
  final String productType;
  final double purchaseDate;
  final int quantity;
  final String receiptId;
  final double renewalDate;
  final String term;
  final String termSku;
  final bool testTransaction;

  factory ReceiptValidationResultAndroid.fromJson(Map<String, dynamic> json) {
    return ReceiptValidationResultAndroid(
      autoRenewing: json['autoRenewing'] as bool,
      betaProduct: json['betaProduct'] as bool,
      cancelDate: (json['cancelDate'] as num?)?.toDouble(),
      cancelReason: json['cancelReason'] as String?,
      deferredDate: (json['deferredDate'] as num?)?.toDouble(),
      deferredSku: json['deferredSku'] as String?,
      freeTrialEndDate: (json['freeTrialEndDate'] as num).toDouble(),
      gracePeriodEndDate: (json['gracePeriodEndDate'] as num).toDouble(),
      parentProductId: json['parentProductId'] as String,
      productId: json['productId'] as String,
      productType: json['productType'] as String,
      purchaseDate: (json['purchaseDate'] as num).toDouble(),
      quantity: json['quantity'] as int,
      receiptId: json['receiptId'] as String,
      renewalDate: (json['renewalDate'] as num).toDouble(),
      term: json['term'] as String,
      termSku: json['termSku'] as String,
      testTransaction: json['testTransaction'] as bool,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      '__typename': 'ReceiptValidationResultAndroid',
      'autoRenewing': autoRenewing,
      'betaProduct': betaProduct,
      'cancelDate': cancelDate,
      'cancelReason': cancelReason,
      'deferredDate': deferredDate,
      'deferredSku': deferredSku,
      'freeTrialEndDate': freeTrialEndDate,
      'gracePeriodEndDate': gracePeriodEndDate,
      'parentProductId': parentProductId,
      'productId': productId,
      'productType': productType,
      'purchaseDate': purchaseDate,
      'quantity': quantity,
      'receiptId': receiptId,
      'renewalDate': renewalDate,
      'term': term,
      'termSku': termSku,
      'testTransaction': testTransaction,
    };
  }
}

class ReceiptValidationResultIOS extends ReceiptValidationResult {
  const ReceiptValidationResultIOS({
    /// Whether the receipt is valid
    required this.isValid,
    /// JWS representation
    required this.jwsRepresentation,
    /// Latest transaction if available
    this.latestTransaction,
    /// Receipt data string
    required this.receiptData,
  });

  /// Whether the receipt is valid
  final bool isValid;
  /// JWS representation
  final String jwsRepresentation;
  /// Latest transaction if available
  final Purchase? latestTransaction;
  /// Receipt data string
  final String receiptData;

  factory ReceiptValidationResultIOS.fromJson(Map<String, dynamic> json) {
    return ReceiptValidationResultIOS(
      isValid: json['isValid'] as bool,
      jwsRepresentation: json['jwsRepresentation'] as String,
      latestTransaction: json['latestTransaction'] != null ? Purchase.fromJson(json['latestTransaction'] as Map<String, dynamic>) : null,
      receiptData: json['receiptData'] as String,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      '__typename': 'ReceiptValidationResultIOS',
      'isValid': isValid,
      'jwsRepresentation': jwsRepresentation,
      'latestTransaction': latestTransaction?.toJson(),
      'receiptData': receiptData,
    };
  }
}

class RefundResultIOS {
  const RefundResultIOS({
    this.message,
    required this.status,
  });

  final String? message;
  final String status;

  factory RefundResultIOS.fromJson(Map<String, dynamic> json) {
    return RefundResultIOS(
      message: json['message'] as String?,
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '__typename': 'RefundResultIOS',
      'message': message,
      'status': status,
    };
  }
}

class RenewalInfoIOS {
  const RenewalInfoIOS({
    this.autoRenewPreference,
    this.jsonRepresentation,
    required this.willAutoRenew,
  });

  final String? autoRenewPreference;
  final String? jsonRepresentation;
  final bool willAutoRenew;

  factory RenewalInfoIOS.fromJson(Map<String, dynamic> json) {
    return RenewalInfoIOS(
      autoRenewPreference: json['autoRenewPreference'] as String?,
      jsonRepresentation: json['jsonRepresentation'] as String?,
      willAutoRenew: json['willAutoRenew'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '__typename': 'RenewalInfoIOS',
      'autoRenewPreference': autoRenewPreference,
      'jsonRepresentation': jsonRepresentation,
      'willAutoRenew': willAutoRenew,
    };
  }
}

class RequestPurchaseResult {
  const RequestPurchaseResult({
    this.purchase,
    this.purchases,
  });

  final Purchase? purchase;
  final List<Purchase>? purchases;

  factory RequestPurchaseResult.fromJson(Map<String, dynamic> json) {
    return RequestPurchaseResult(
      purchase: json['purchase'] != null ? Purchase.fromJson(json['purchase'] as Map<String, dynamic>) : null,
      purchases: (json['purchases'] as List<dynamic>?) == null ? null : (json['purchases'] as List<dynamic>?)!.map((e) => Purchase.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '__typename': 'RequestPurchaseResult',
      'purchase': purchase?.toJson(),
      'purchases': purchases == null ? null : purchases!.map((e) => e.toJson()).toList(),
    };
  }
}

class SubscriptionInfoIOS {
  const SubscriptionInfoIOS({
    this.introductoryOffer,
    this.promotionalOffers,
    required this.subscriptionGroupId,
    required this.subscriptionPeriod,
  });

  final SubscriptionOfferIOS? introductoryOffer;
  final List<SubscriptionOfferIOS>? promotionalOffers;
  final String subscriptionGroupId;
  final SubscriptionPeriodValueIOS subscriptionPeriod;

  factory SubscriptionInfoIOS.fromJson(Map<String, dynamic> json) {
    return SubscriptionInfoIOS(
      introductoryOffer: json['introductoryOffer'] != null ? SubscriptionOfferIOS.fromJson(json['introductoryOffer'] as Map<String, dynamic>) : null,
      promotionalOffers: (json['promotionalOffers'] as List<dynamic>?) == null ? null : (json['promotionalOffers'] as List<dynamic>?)!.map((e) => SubscriptionOfferIOS.fromJson(e as Map<String, dynamic>)).toList(),
      subscriptionGroupId: json['subscriptionGroupId'] as String,
      subscriptionPeriod: SubscriptionPeriodValueIOS.fromJson(json['subscriptionPeriod'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '__typename': 'SubscriptionInfoIOS',
      'introductoryOffer': introductoryOffer?.toJson(),
      'promotionalOffers': promotionalOffers == null ? null : promotionalOffers!.map((e) => e.toJson()).toList(),
      'subscriptionGroupId': subscriptionGroupId,
      'subscriptionPeriod': subscriptionPeriod.toJson(),
    };
  }
}

class SubscriptionOfferIOS {
  const SubscriptionOfferIOS({
    required this.displayPrice,
    required this.id,
    required this.paymentMode,
    required this.period,
    required this.periodCount,
    required this.price,
    required this.type,
  });

  final String displayPrice;
  final String id;
  final PaymentModeIOS paymentMode;
  final SubscriptionPeriodValueIOS period;
  final int periodCount;
  final double price;
  final SubscriptionOfferTypeIOS type;

  factory SubscriptionOfferIOS.fromJson(Map<String, dynamic> json) {
    return SubscriptionOfferIOS(
      displayPrice: json['displayPrice'] as String,
      id: json['id'] as String,
      paymentMode: PaymentModeIOS.fromJson(json['paymentMode'] as String),
      period: SubscriptionPeriodValueIOS.fromJson(json['period'] as Map<String, dynamic>),
      periodCount: json['periodCount'] as int,
      price: (json['price'] as num).toDouble(),
      type: SubscriptionOfferTypeIOS.fromJson(json['type'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '__typename': 'SubscriptionOfferIOS',
      'displayPrice': displayPrice,
      'id': id,
      'paymentMode': paymentMode.toJson(),
      'period': period.toJson(),
      'periodCount': periodCount,
      'price': price,
      'type': type.toJson(),
    };
  }
}

class SubscriptionPeriodValueIOS {
  const SubscriptionPeriodValueIOS({
    required this.unit,
    required this.value,
  });

  final SubscriptionPeriodIOS unit;
  final int value;

  factory SubscriptionPeriodValueIOS.fromJson(Map<String, dynamic> json) {
    return SubscriptionPeriodValueIOS(
      unit: SubscriptionPeriodIOS.fromJson(json['unit'] as String),
      value: json['value'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '__typename': 'SubscriptionPeriodValueIOS',
      'unit': unit.toJson(),
      'value': value,
    };
  }
}

class SubscriptionStatusIOS {
  const SubscriptionStatusIOS({
    this.renewalInfo,
    required this.state,
  });

  final RenewalInfoIOS? renewalInfo;
  final String state;

  factory SubscriptionStatusIOS.fromJson(Map<String, dynamic> json) {
    return SubscriptionStatusIOS(
      renewalInfo: json['renewalInfo'] != null ? RenewalInfoIOS.fromJson(json['renewalInfo'] as Map<String, dynamic>) : null,
      state: json['state'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '__typename': 'SubscriptionStatusIOS',
      'renewalInfo': renewalInfo?.toJson(),
      'state': state,
    };
  }
}

class VoidResult {
  const VoidResult({
    required this.success,
  });

  final bool success;

  factory VoidResult.fromJson(Map<String, dynamic> json) {
    return VoidResult(
      success: json['success'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '__typename': 'VoidResult',
      'success': success,
    };
  }
}

// MARK: - Input Objects

class AndroidSubscriptionOfferInput {
  const AndroidSubscriptionOfferInput({
    /// Offer token
    required this.offerToken,
    /// Product SKU
    required this.sku,
  });

  /// Offer token
  final String offerToken;
  /// Product SKU
  final String sku;

  factory AndroidSubscriptionOfferInput.fromJson(Map<String, dynamic> json) {
    return AndroidSubscriptionOfferInput(
      offerToken: json['offerToken'] as String,
      sku: json['sku'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'offerToken': offerToken,
      'sku': sku,
    };
  }
}

class DeepLinkOptions {
  const DeepLinkOptions({
    /// Android package name to target (required on Android)
    this.packageNameAndroid,
    /// Android SKU to open (required on Android)
    this.skuAndroid,
  });

  /// Android package name to target (required on Android)
  final String? packageNameAndroid;
  /// Android SKU to open (required on Android)
  final String? skuAndroid;

  factory DeepLinkOptions.fromJson(Map<String, dynamic> json) {
    return DeepLinkOptions(
      packageNameAndroid: json['packageNameAndroid'] as String?,
      skuAndroid: json['skuAndroid'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'packageNameAndroid': packageNameAndroid,
      'skuAndroid': skuAndroid,
    };
  }
}

class DiscountOfferInputIOS {
  const DiscountOfferInputIOS({
    /// Discount identifier
    required this.identifier,
    /// Key identifier for validation
    required this.keyIdentifier,
    /// Cryptographic nonce
    required this.nonce,
    /// Signature for validation
    required this.signature,
    /// Timestamp of discount offer
    required this.timestamp,
  });

  /// Discount identifier
  final String identifier;
  /// Key identifier for validation
  final String keyIdentifier;
  /// Cryptographic nonce
  final String nonce;
  /// Signature for validation
  final String signature;
  /// Timestamp of discount offer
  final double timestamp;

  factory DiscountOfferInputIOS.fromJson(Map<String, dynamic> json) {
    return DiscountOfferInputIOS(
      identifier: json['identifier'] as String,
      keyIdentifier: json['keyIdentifier'] as String,
      nonce: json['nonce'] as String,
      signature: json['signature'] as String,
      timestamp: (json['timestamp'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'identifier': identifier,
      'keyIdentifier': keyIdentifier,
      'nonce': nonce,
      'signature': signature,
      'timestamp': timestamp,
    };
  }
}

class ProductRequest {
  const ProductRequest({
    required this.skus,
    this.type,
  });

  final List<String> skus;
  final ProductQueryType? type;

  factory ProductRequest.fromJson(Map<String, dynamic> json) {
    return ProductRequest(
      skus: (json['skus'] as List<dynamic>).map((e) => e as String).toList(),
      type: json['type'] != null ? ProductQueryType.fromJson(json['type'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'skus': skus.map((e) => e).toList(),
      'type': type?.toJson(),
    };
  }
}

class PurchaseInput {
  const PurchaseInput({
    required this.id,
    this.ids,
    required this.isAutoRenewing,
    required this.platform,
    required this.productId,
    required this.purchaseState,
    this.purchaseToken,
    required this.quantity,
    required this.transactionDate,
  });

  final String id;
  final List<String>? ids;
  final bool isAutoRenewing;
  final IapPlatform platform;
  final String productId;
  final PurchaseState purchaseState;
  final String? purchaseToken;
  final int quantity;
  final double transactionDate;

  factory PurchaseInput.fromJson(Map<String, dynamic> json) {
    return PurchaseInput(
      id: json['id'] as String,
      ids: (json['ids'] as List<dynamic>?) == null ? null : (json['ids'] as List<dynamic>?)!.map((e) => e as String).toList(),
      isAutoRenewing: json['isAutoRenewing'] as bool,
      platform: IapPlatform.fromJson(json['platform'] as String),
      productId: json['productId'] as String,
      purchaseState: PurchaseState.fromJson(json['purchaseState'] as String),
      purchaseToken: json['purchaseToken'] as String?,
      quantity: json['quantity'] as int,
      transactionDate: (json['transactionDate'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ids': ids == null ? null : ids!.map((e) => e).toList(),
      'isAutoRenewing': isAutoRenewing,
      'platform': platform.toJson(),
      'productId': productId,
      'purchaseState': purchaseState.toJson(),
      'purchaseToken': purchaseToken,
      'quantity': quantity,
      'transactionDate': transactionDate,
    };
  }
}

class PurchaseOptions {
  const PurchaseOptions({
    /// Also emit results through the iOS event listeners
    this.alsoPublishToEventListenerIOS,
    /// Limit to currently active items on iOS
    this.onlyIncludeActiveItemsIOS,
  });

  /// Also emit results through the iOS event listeners
  final bool? alsoPublishToEventListenerIOS;
  /// Limit to currently active items on iOS
  final bool? onlyIncludeActiveItemsIOS;

  factory PurchaseOptions.fromJson(Map<String, dynamic> json) {
    return PurchaseOptions(
      alsoPublishToEventListenerIOS: json['alsoPublishToEventListenerIOS'] as bool?,
      onlyIncludeActiveItemsIOS: json['onlyIncludeActiveItemsIOS'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'alsoPublishToEventListenerIOS': alsoPublishToEventListenerIOS,
      'onlyIncludeActiveItemsIOS': onlyIncludeActiveItemsIOS,
    };
  }
}

class ReceiptValidationAndroidOptions {
  const ReceiptValidationAndroidOptions({
    required this.accessToken,
    this.isSub,
    required this.packageName,
    required this.productToken,
  });

  final String accessToken;
  final bool? isSub;
  final String packageName;
  final String productToken;

  factory ReceiptValidationAndroidOptions.fromJson(Map<String, dynamic> json) {
    return ReceiptValidationAndroidOptions(
      accessToken: json['accessToken'] as String,
      isSub: json['isSub'] as bool?,
      packageName: json['packageName'] as String,
      productToken: json['productToken'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'isSub': isSub,
      'packageName': packageName,
      'productToken': productToken,
    };
  }
}

class ReceiptValidationProps {
  const ReceiptValidationProps({
    /// Android-specific validation options
    this.androidOptions,
    /// Product SKU to validate
    required this.sku,
  });

  /// Android-specific validation options
  final ReceiptValidationAndroidOptions? androidOptions;
  /// Product SKU to validate
  final String sku;

  factory ReceiptValidationProps.fromJson(Map<String, dynamic> json) {
    return ReceiptValidationProps(
      androidOptions: json['androidOptions'] != null ? ReceiptValidationAndroidOptions.fromJson(json['androidOptions'] as Map<String, dynamic>) : null,
      sku: json['sku'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'androidOptions': androidOptions?.toJson(),
      'sku': sku,
    };
  }
}

class RequestPurchaseAndroidProps {
  const RequestPurchaseAndroidProps({
    /// Personalized offer flag
    this.isOfferPersonalized,
    /// Obfuscated account ID
    this.obfuscatedAccountIdAndroid,
    /// Obfuscated profile ID
    this.obfuscatedProfileIdAndroid,
    /// List of product SKUs
    required this.skus,
  });

  /// Personalized offer flag
  final bool? isOfferPersonalized;
  /// Obfuscated account ID
  final String? obfuscatedAccountIdAndroid;
  /// Obfuscated profile ID
  final String? obfuscatedProfileIdAndroid;
  /// List of product SKUs
  final List<String> skus;

  factory RequestPurchaseAndroidProps.fromJson(Map<String, dynamic> json) {
    return RequestPurchaseAndroidProps(
      isOfferPersonalized: json['isOfferPersonalized'] as bool?,
      obfuscatedAccountIdAndroid: json['obfuscatedAccountIdAndroid'] as String?,
      obfuscatedProfileIdAndroid: json['obfuscatedProfileIdAndroid'] as String?,
      skus: (json['skus'] as List<dynamic>).map((e) => e as String).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isOfferPersonalized': isOfferPersonalized,
      'obfuscatedAccountIdAndroid': obfuscatedAccountIdAndroid,
      'obfuscatedProfileIdAndroid': obfuscatedProfileIdAndroid,
      'skus': skus.map((e) => e).toList(),
    };
  }
}

class RequestPurchaseIosProps {
  const RequestPurchaseIosProps({
    /// Auto-finish transaction (dangerous)
    this.andDangerouslyFinishTransactionAutomatically,
    /// App account token for user tracking
    this.appAccountToken,
    /// Purchase quantity
    this.quantity,
    /// Product SKU
    required this.sku,
    /// Discount offer to apply
    this.withOffer,
  });

  /// Auto-finish transaction (dangerous)
  final bool? andDangerouslyFinishTransactionAutomatically;
  /// App account token for user tracking
  final String? appAccountToken;
  /// Purchase quantity
  final int? quantity;
  /// Product SKU
  final String sku;
  /// Discount offer to apply
  final DiscountOfferInputIOS? withOffer;

  factory RequestPurchaseIosProps.fromJson(Map<String, dynamic> json) {
    return RequestPurchaseIosProps(
      andDangerouslyFinishTransactionAutomatically: json['andDangerouslyFinishTransactionAutomatically'] as bool?,
      appAccountToken: json['appAccountToken'] as String?,
      quantity: json['quantity'] as int?,
      sku: json['sku'] as String,
      withOffer: json['withOffer'] != null ? DiscountOfferInputIOS.fromJson(json['withOffer'] as Map<String, dynamic>) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'andDangerouslyFinishTransactionAutomatically': andDangerouslyFinishTransactionAutomatically,
      'appAccountToken': appAccountToken,
      'quantity': quantity,
      'sku': sku,
      'withOffer': withOffer?.toJson(),
    };
  }
}

class RequestPurchaseProps {
  RequestPurchaseProps({
    required this.request,
    ProductQueryType? type,
  }) : type = type ?? (request is RequestPurchasePropsRequestPurchase
          ? ProductQueryType.InApp
          : ProductQueryType.Subs) {
    if (request is RequestPurchasePropsRequestPurchase && this.type != ProductQueryType.InApp) {
      throw ArgumentError('type must be IN_APP when requestPurchase is provided');
    }
    if (request is RequestPurchasePropsRequestSubscription && this.type != ProductQueryType.Subs) {
      throw ArgumentError('type must be SUBS when requestSubscription is provided');
    }
  }

  final RequestPurchasePropsRequest request;
  final ProductQueryType type;

  factory RequestPurchaseProps.fromJson(Map<String, dynamic> json) {
    final typeValue = json['type'] as String?;
    final parsedType = typeValue != null ? ProductQueryType.fromJson(typeValue) : null;
    final purchaseJson = json['requestPurchase'] as Map<String, dynamic>?;
    if (purchaseJson != null) {
      final request = RequestPurchasePropsRequestPurchase(RequestPurchasePropsByPlatforms.fromJson(purchaseJson));
      final finalType = parsedType ?? ProductQueryType.InApp;
      if (finalType != ProductQueryType.InApp) {
        throw ArgumentError('type must be IN_APP when requestPurchase is provided');
      }
      return RequestPurchaseProps(request: request, type: finalType);
    }
    final subscriptionJson = json['requestSubscription'] as Map<String, dynamic>?;
    if (subscriptionJson != null) {
      final request = RequestPurchasePropsRequestSubscription(RequestSubscriptionPropsByPlatforms.fromJson(subscriptionJson));
      final finalType = parsedType ?? ProductQueryType.Subs;
      if (finalType != ProductQueryType.Subs) {
        throw ArgumentError('type must be SUBS when requestSubscription is provided');
      }
      return RequestPurchaseProps(request: request, type: finalType);
    }
    throw ArgumentError('RequestPurchaseProps requires requestPurchase or requestSubscription');
  }

  Map<String, dynamic> toJson() {
    if (request is RequestPurchasePropsRequestPurchase) {
      return {
        'requestPurchase': (request as RequestPurchasePropsRequestPurchase).value.toJson(),
        'type': type.toJson(),
      };
    }
    if (request is RequestPurchasePropsRequestSubscription) {
      return {
        'requestSubscription': (request as RequestPurchasePropsRequestSubscription).value.toJson(),
        'type': type.toJson(),
      };
    }
    throw StateError('Unsupported RequestPurchaseProps request variant');
  }

  static RequestPurchaseProps inApp({required RequestPurchasePropsByPlatforms request}) {
    return RequestPurchaseProps(request: RequestPurchasePropsRequestPurchase(request), type: ProductQueryType.InApp);
  }

  static RequestPurchaseProps subs({required RequestSubscriptionPropsByPlatforms request}) {
    return RequestPurchaseProps(request: RequestPurchasePropsRequestSubscription(request), type: ProductQueryType.Subs);
  }
}

sealed class RequestPurchasePropsRequest {
  const RequestPurchasePropsRequest();
}

class RequestPurchasePropsRequestPurchase extends RequestPurchasePropsRequest {
  const RequestPurchasePropsRequestPurchase(this.value);
  final RequestPurchasePropsByPlatforms value;
}

class RequestPurchasePropsRequestSubscription extends RequestPurchasePropsRequest {
  const RequestPurchasePropsRequestSubscription(this.value);
  final RequestSubscriptionPropsByPlatforms value;
}

class RequestPurchasePropsByPlatforms {
  const RequestPurchasePropsByPlatforms({
    /// Android-specific purchase parameters
    this.android,
    /// iOS-specific purchase parameters
    this.ios,
  });

  /// Android-specific purchase parameters
  final RequestPurchaseAndroidProps? android;
  /// iOS-specific purchase parameters
  final RequestPurchaseIosProps? ios;

  factory RequestPurchasePropsByPlatforms.fromJson(Map<String, dynamic> json) {
    return RequestPurchasePropsByPlatforms(
      android: json['android'] != null ? RequestPurchaseAndroidProps.fromJson(json['android'] as Map<String, dynamic>) : null,
      ios: json['ios'] != null ? RequestPurchaseIosProps.fromJson(json['ios'] as Map<String, dynamic>) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'android': android?.toJson(),
      'ios': ios?.toJson(),
    };
  }
}

class RequestSubscriptionAndroidProps {
  const RequestSubscriptionAndroidProps({
    /// Personalized offer flag
    this.isOfferPersonalized,
    /// Obfuscated account ID
    this.obfuscatedAccountIdAndroid,
    /// Obfuscated profile ID
    this.obfuscatedProfileIdAndroid,
    /// Purchase token for upgrades/downgrades
    this.purchaseTokenAndroid,
    /// Replacement mode for subscription changes
    this.replacementModeAndroid,
    /// List of subscription SKUs
    required this.skus,
    /// Subscription offers
    this.subscriptionOffers,
  });

  /// Personalized offer flag
  final bool? isOfferPersonalized;
  /// Obfuscated account ID
  final String? obfuscatedAccountIdAndroid;
  /// Obfuscated profile ID
  final String? obfuscatedProfileIdAndroid;
  /// Purchase token for upgrades/downgrades
  final String? purchaseTokenAndroid;
  /// Replacement mode for subscription changes
  final int? replacementModeAndroid;
  /// List of subscription SKUs
  final List<String> skus;
  /// Subscription offers
  final List<AndroidSubscriptionOfferInput>? subscriptionOffers;

  factory RequestSubscriptionAndroidProps.fromJson(Map<String, dynamic> json) {
    return RequestSubscriptionAndroidProps(
      isOfferPersonalized: json['isOfferPersonalized'] as bool?,
      obfuscatedAccountIdAndroid: json['obfuscatedAccountIdAndroid'] as String?,
      obfuscatedProfileIdAndroid: json['obfuscatedProfileIdAndroid'] as String?,
      purchaseTokenAndroid: json['purchaseTokenAndroid'] as String?,
      replacementModeAndroid: json['replacementModeAndroid'] as int?,
      skus: (json['skus'] as List<dynamic>).map((e) => e as String).toList(),
      subscriptionOffers: (json['subscriptionOffers'] as List<dynamic>?) == null ? null : (json['subscriptionOffers'] as List<dynamic>?)!.map((e) => AndroidSubscriptionOfferInput.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isOfferPersonalized': isOfferPersonalized,
      'obfuscatedAccountIdAndroid': obfuscatedAccountIdAndroid,
      'obfuscatedProfileIdAndroid': obfuscatedProfileIdAndroid,
      'purchaseTokenAndroid': purchaseTokenAndroid,
      'replacementModeAndroid': replacementModeAndroid,
      'skus': skus.map((e) => e).toList(),
      'subscriptionOffers': subscriptionOffers == null ? null : subscriptionOffers!.map((e) => e.toJson()).toList(),
    };
  }
}

class RequestSubscriptionIosProps {
  const RequestSubscriptionIosProps({
    this.andDangerouslyFinishTransactionAutomatically,
    this.appAccountToken,
    this.quantity,
    required this.sku,
    this.withOffer,
  });

  final bool? andDangerouslyFinishTransactionAutomatically;
  final String? appAccountToken;
  final int? quantity;
  final String sku;
  final DiscountOfferInputIOS? withOffer;

  factory RequestSubscriptionIosProps.fromJson(Map<String, dynamic> json) {
    return RequestSubscriptionIosProps(
      andDangerouslyFinishTransactionAutomatically: json['andDangerouslyFinishTransactionAutomatically'] as bool?,
      appAccountToken: json['appAccountToken'] as String?,
      quantity: json['quantity'] as int?,
      sku: json['sku'] as String,
      withOffer: json['withOffer'] != null ? DiscountOfferInputIOS.fromJson(json['withOffer'] as Map<String, dynamic>) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'andDangerouslyFinishTransactionAutomatically': andDangerouslyFinishTransactionAutomatically,
      'appAccountToken': appAccountToken,
      'quantity': quantity,
      'sku': sku,
      'withOffer': withOffer?.toJson(),
    };
  }
}

class RequestSubscriptionPropsByPlatforms {
  const RequestSubscriptionPropsByPlatforms({
    /// Android-specific subscription parameters
    this.android,
    /// iOS-specific subscription parameters
    this.ios,
  });

  /// Android-specific subscription parameters
  final RequestSubscriptionAndroidProps? android;
  /// iOS-specific subscription parameters
  final RequestSubscriptionIosProps? ios;

  factory RequestSubscriptionPropsByPlatforms.fromJson(Map<String, dynamic> json) {
    return RequestSubscriptionPropsByPlatforms(
      android: json['android'] != null ? RequestSubscriptionAndroidProps.fromJson(json['android'] as Map<String, dynamic>) : null,
      ios: json['ios'] != null ? RequestSubscriptionIosProps.fromJson(json['ios'] as Map<String, dynamic>) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'android': android?.toJson(),
      'ios': ios?.toJson(),
    };
  }
}

// MARK: - Unions

sealed class Product implements ProductCommon {
  const Product();

  factory Product.fromJson(Map<String, dynamic> json) {
    final typeName = json['__typename'] as String?;
    switch (typeName) {
      case 'ProductAndroid':
        return ProductAndroid.fromJson(json);
      case 'ProductIOS':
        return ProductIOS.fromJson(json);
    }
    throw ArgumentError('Unknown __typename for Product: $typeName');
  }

  @override
  String get currency;
  @override
  String? get debugDescription;
  @override
  String get description;
  @override
  String? get displayName;
  @override
  String get displayPrice;
  @override
  String get id;
  @override
  IapPlatform get platform;
  @override
  double? get price;
  @override
  String get title;
  @override
  ProductType get type;

  Map<String, dynamic> toJson();
}

sealed class ProductSubscription implements ProductCommon {
  const ProductSubscription();

  factory ProductSubscription.fromJson(Map<String, dynamic> json) {
    final typeName = json['__typename'] as String?;
    switch (typeName) {
      case 'ProductSubscriptionAndroid':
        return ProductSubscriptionAndroid.fromJson(json);
      case 'ProductSubscriptionIOS':
        return ProductSubscriptionIOS.fromJson(json);
    }
    throw ArgumentError('Unknown __typename for ProductSubscription: $typeName');
  }

  @override
  String get currency;
  @override
  String? get debugDescription;
  @override
  String get description;
  @override
  String? get displayName;
  @override
  String get displayPrice;
  @override
  String get id;
  @override
  IapPlatform get platform;
  @override
  double? get price;
  @override
  String get title;
  @override
  ProductType get type;

  Map<String, dynamic> toJson();
}

sealed class Purchase implements PurchaseCommon {
  const Purchase();

  factory Purchase.fromJson(Map<String, dynamic> json) {
    final typeName = json['__typename'] as String?;
    switch (typeName) {
      case 'PurchaseAndroid':
        return PurchaseAndroid.fromJson(json);
      case 'PurchaseIOS':
        return PurchaseIOS.fromJson(json);
    }
    throw ArgumentError('Unknown __typename for Purchase: $typeName');
  }

  @override
  String get id;
  @override
  List<String>? get ids;
  @override
  bool get isAutoRenewing;
  @override
  IapPlatform get platform;
  @override
  String get productId;
  @override
  PurchaseState get purchaseState;
  /// Unified purchase token (iOS JWS, Android purchaseToken)
  @override
  String? get purchaseToken;
  @override
  int get quantity;
  @override
  double get transactionDate;

  Map<String, dynamic> toJson();
}

sealed class ReceiptValidationResult {
  const ReceiptValidationResult();

  factory ReceiptValidationResult.fromJson(Map<String, dynamic> json) {
    final typeName = json['__typename'] as String?;
    switch (typeName) {
      case 'ReceiptValidationResultAndroid':
        return ReceiptValidationResultAndroid.fromJson(json);
      case 'ReceiptValidationResultIOS':
        return ReceiptValidationResultIOS.fromJson(json);
    }
    throw ArgumentError('Unknown __typename for ReceiptValidationResult: $typeName');
  }

  Map<String, dynamic> toJson();
}

// MARK: - Root Operations

/// GraphQL root mutation operations.
abstract class MutationResolver {
  /// Acknowledge a non-consumable purchase or subscription
  Future<VoidResult> acknowledgePurchaseAndroid({
    required String purchaseToken,
  });
  /// Initiate a refund request for a product (iOS 15+)
  Future<RefundResultIOS> beginRefundRequestIOS({
    required String sku,
  });
  /// Clear pending transactions from the StoreKit payment queue
  Future<VoidResult> clearTransactionIOS();
  /// Consume a purchase token so it can be repurchased
  Future<VoidResult> consumePurchaseAndroid({
    required String purchaseToken,
  });
  /// Open the native subscription management surface
  Future<VoidResult> deepLinkToSubscriptions({
    DeepLinkOptions? options,
  });
  /// Close the platform billing connection
  Future<bool> endConnection();
  /// Finish a transaction after validating receipts
  Future<VoidResult> finishTransaction({
    required PurchaseInput purchase,
    bool? isConsumable,
  });
  /// Establish the platform billing connection
  Future<bool> initConnection();
  /// Present the App Store code redemption sheet
  Future<VoidResult> presentCodeRedemptionSheetIOS();
  /// Initiate a purchase flow; rely on events for final state
  Future<RequestPurchaseResult?> requestPurchase({
    required RequestPurchaseProps params,
  });
  /// Purchase the promoted product surfaced by the App Store
  Future<PurchaseIOS> requestPurchaseOnPromotedProductIOS();
  /// Restore completed purchases across platforms
  Future<VoidResult> restorePurchases();
  /// Open subscription management UI and return changed purchases (iOS 15+)
  Future<List<PurchaseIOS>> showManageSubscriptionsIOS();
  /// Force a StoreKit sync for transactions (iOS 15+)
  Future<VoidResult> syncIOS();
  /// Validate purchase receipts with the configured providers
  Future<ReceiptValidationResult> validateReceipt({
    required ReceiptValidationProps options,
  });
}

/// GraphQL root query operations.
abstract class QueryResolver {
  /// Get current StoreKit 2 entitlements (iOS 15+)
  Future<List<EntitlementIOS>> currentEntitlementIOS({
    List<String>? skus,
  });
  /// Retrieve products or subscriptions from the store
  Future<FetchProductsResult> fetchProducts({
    required ProductRequest params,
  });
  /// Get active subscriptions (filters by subscriptionIds when provided)
  Future<List<ActiveSubscription>> getActiveSubscriptions({
    List<String>? subscriptionIds,
  });
  /// Fetch the current app transaction (iOS 16+)
  Future<AppTransaction?> getAppTransactionIOS();
  /// Get all available purchases for the current user
  Future<List<Purchase>> getAvailablePurchases({
    PurchaseOptions? options,
  });
  /// Retrieve all pending transactions in the StoreKit queue
  Future<List<PurchaseIOS>> getPendingTransactionsIOS();
  /// Get the currently promoted product (iOS 11+)
  Future<ProductIOS?> getPromotedProductIOS();
  /// Get base64-encoded receipt data for validation
  Future<String> getReceiptDataIOS();
  /// Get the current App Store storefront country code
  Future<String> getStorefrontIOS();
  /// Get the transaction JWS (StoreKit 2)
  Future<String> getTransactionJwsIOS({
    required String transactionId,
  });
  /// Check whether the user has active subscriptions
  Future<bool> hasActiveSubscriptions({
    List<String>? subscriptionIds,
  });
  /// Check introductory offer eligibility for specific products
  Future<bool> isEligibleForIntroOfferIOS({
    required List<String> productIds,
  });
  /// Verify a StoreKit 2 transaction signature
  Future<bool> isTransactionVerifiedIOS({
    required String transactionId,
  });
  /// Get the latest transaction for a product using StoreKit 2
  Future<PurchaseIOS?> latestTransactionIOS({
    required String sku,
  });
  /// Get StoreKit 2 subscription status details (iOS 15+)
  Future<List<SubscriptionStatusIOS>> subscriptionStatusIOS({
    List<String>? skus,
  });
}

/// GraphQL root subscription operations.
abstract class SubscriptionResolver {
  /// Fires when the App Store surfaces a promoted product (iOS only)
  Future<String> promotedProductIOS();
  /// Fires when a purchase fails or is cancelled
  Future<PurchaseError> purchaseError();
  /// Fires when a purchase completes successfully or a pending purchase resolves
  Future<Purchase> purchaseUpdated();
}
