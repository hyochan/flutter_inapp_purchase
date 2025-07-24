import 'dart:io';
import 'enums.dart';
export 'enums.dart';

/// Platform-specific error code mappings
class ErrorCodeMapping {
  static const Map<ErrorCode, int> ios = {
    ErrorCode.E_UNKNOWN: 0,
    ErrorCode.E_SERVICE_ERROR: 1,
    ErrorCode.E_USER_CANCELLED: 2,
    ErrorCode.E_USER_ERROR: 3,
    ErrorCode.E_ITEM_UNAVAILABLE: 4,
    ErrorCode.E_REMOTE_ERROR: 5,
    ErrorCode.E_NETWORK_ERROR: 6,
    ErrorCode.E_RECEIPT_FAILED: 7,
    ErrorCode.E_RECEIPT_FINISHED_FAILED: 8,
    ErrorCode.E_DEVELOPER_ERROR: 9,
    ErrorCode.E_PURCHASE_ERROR: 10,
    ErrorCode.E_SYNC_ERROR: 11,
    ErrorCode.E_DEFERRED_PAYMENT: 12,
    ErrorCode.E_TRANSACTION_VALIDATION_FAILED: 13,
    ErrorCode.E_NOT_PREPARED: 14,
    ErrorCode.E_NOT_ENDED: 15,
    ErrorCode.E_ALREADY_OWNED: 16,
    ErrorCode.E_BILLING_RESPONSE_JSON_PARSE_ERROR: 17,
    ErrorCode.E_INTERRUPTED: 18,
    ErrorCode.E_IAP_NOT_AVAILABLE: 19,
    ErrorCode.E_ACTIVITY_UNAVAILABLE: 20,
    ErrorCode.E_ALREADY_PREPARED: 21,
    ErrorCode.E_PENDING: 22,
    ErrorCode.E_CONNECTION_CLOSED: 23,
  };

  static const Map<ErrorCode, String> android = {
    ErrorCode.E_UNKNOWN: 'E_UNKNOWN',
    ErrorCode.E_USER_CANCELLED: 'E_USER_CANCELLED',
    ErrorCode.E_USER_ERROR: 'E_USER_ERROR',
    ErrorCode.E_ITEM_UNAVAILABLE: 'E_ITEM_UNAVAILABLE',
    ErrorCode.E_REMOTE_ERROR: 'E_REMOTE_ERROR',
    ErrorCode.E_NETWORK_ERROR: 'E_NETWORK_ERROR',
    ErrorCode.E_SERVICE_ERROR: 'E_SERVICE_ERROR',
    ErrorCode.E_RECEIPT_FAILED: 'E_RECEIPT_FAILED',
    ErrorCode.E_RECEIPT_FINISHED_FAILED: 'E_RECEIPT_FINISHED_FAILED',
    ErrorCode.E_NOT_PREPARED: 'E_NOT_PREPARED',
    ErrorCode.E_NOT_ENDED: 'E_NOT_ENDED',
    ErrorCode.E_ALREADY_OWNED: 'E_ALREADY_OWNED',
    ErrorCode.E_DEVELOPER_ERROR: 'E_DEVELOPER_ERROR',
    ErrorCode.E_BILLING_RESPONSE_JSON_PARSE_ERROR:
        'E_BILLING_RESPONSE_JSON_PARSE_ERROR',
    ErrorCode.E_DEFERRED_PAYMENT: 'E_DEFERRED_PAYMENT',
    ErrorCode.E_INTERRUPTED: 'E_INTERRUPTED',
    ErrorCode.E_IAP_NOT_AVAILABLE: 'E_IAP_NOT_AVAILABLE',
    ErrorCode.E_PURCHASE_ERROR: 'E_PURCHASE_ERROR',
    ErrorCode.E_SYNC_ERROR: 'E_SYNC_ERROR',
    ErrorCode.E_TRANSACTION_VALIDATION_FAILED:
        'E_TRANSACTION_VALIDATION_FAILED',
    ErrorCode.E_ACTIVITY_UNAVAILABLE: 'E_ACTIVITY_UNAVAILABLE',
    ErrorCode.E_ALREADY_PREPARED: 'E_ALREADY_PREPARED',
    ErrorCode.E_PENDING: 'E_PENDING',
    ErrorCode.E_CONNECTION_CLOSED: 'E_CONNECTION_CLOSED',
  };
}

/// Change event payload
class ChangeEventPayload {
  final String value;

  ChangeEventPayload({required this.value});
}

/// Base product class
class ProductBase {
  final String id;
  final String title;
  final String description;
  final PurchaseType type;
  final String? displayName;
  final String displayPrice;
  final String currency;
  final double? price;

  ProductBase({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.displayName,
    required this.displayPrice,
    required this.currency,
    this.price,
  });
}

/// Base purchase class
class PurchaseBase {
  final String id;
  final String? transactionId;
  final int transactionDate;
  final String transactionReceipt;

  PurchaseBase({
    required this.id,
    this.transactionId,
    required this.transactionDate,
    required this.transactionReceipt,
  });
}

/// Base product interface (for backward compatibility)
abstract class BaseProduct {
  final String productId;
  final String price;
  final String? currency;
  final String? localizedPrice;
  final String? title;
  final String? description;
  final IAPPlatform platform;

  BaseProduct({
    required this.productId,
    required this.price,
    this.currency,
    this.localizedPrice,
    this.title,
    this.description,
    required this.platform,
  });
}

/// Product class for non-subscription items
class Product extends BaseProduct {
  final String type;
  final bool? isFamilyShareable;
  // Android-specific fields
  final String? iconUrl;
  final String? originalJson;
  final String? originalPrice;
  // iOS-specific fields
  final List<DiscountIOS>? discountsIOS;

  Product({
    required String productId,
    required String price,
    String? currency,
    String? localizedPrice,
    String? title,
    String? description,
    required IAPPlatform platform,
    String? type,
    this.isFamilyShareable,
    this.iconUrl,
    this.originalJson,
    this.originalPrice,
    this.discountsIOS,
  })  : type = type ?? 'inapp',
        super(
          productId: productId,
          price: price,
          currency: currency,
          localizedPrice: localizedPrice,
          title: title,
          description: description,
          platform: platform,
        );
}

/// iOS-specific discount information
class DiscountIOS {
  final String? identifier;
  final String? type;
  final String? numberOfPeriods;
  final double? price;
  final String? localizedPrice;
  final String? paymentMode;
  final String? subscriptionPeriod;

  DiscountIOS({
    this.identifier,
    this.type,
    this.numberOfPeriods,
    this.price,
    this.localizedPrice,
    this.paymentMode,
    this.subscriptionPeriod,
  });
}

/// Subscription class for subscription items
class Subscription extends BaseProduct {
  final String type;
  final List<SubscriptionOffer>? subscriptionOfferDetails;
  final String? subscriptionPeriodAndroid;
  final String? subscriptionPeriodUnitIOS;
  final int? subscriptionPeriodNumberIOS;
  final bool? isFamilyShareable;
  final String? subscriptionGroupId;
  final String? introductoryPrice;
  final int? introductoryPriceNumberOfPeriodsIOS;
  final String? introductoryPriceSubscriptionPeriod;

  Subscription({
    required String productId,
    required String price,
    String? currency,
    String? localizedPrice,
    String? title,
    String? description,
    required IAPPlatform platform,
    this.subscriptionOfferDetails,
    this.subscriptionPeriodAndroid,
    this.subscriptionPeriodUnitIOS,
    this.subscriptionPeriodNumberIOS,
    String? type,
    this.isFamilyShareable,
    this.subscriptionGroupId,
    this.introductoryPrice,
    this.introductoryPriceNumberOfPeriodsIOS,
    this.introductoryPriceSubscriptionPeriod,
  })  : type = type ?? 'subs',
        super(
          productId: productId,
          price: price,
          currency: currency,
          localizedPrice: localizedPrice,
          title: title,
          description: description,
          platform: platform,
        );
}

/// Subscription offer details
class SubscriptionOffer {
  final String? offerId;
  final String? basePlanId;
  final String? offerToken;
  final List<PricingPhase>? pricingPhases;

  SubscriptionOffer({
    this.offerId,
    this.basePlanId,
    this.offerToken,
    this.pricingPhases,
  });
}

/// Pricing phase for subscriptions
class PricingPhase {
  final String? price;
  final String? formattedPrice;
  final String? currencyCode;
  final int? billingCycleCount;
  final String? billingPeriod;

  PricingPhase({
    this.price,
    this.formattedPrice,
    this.currencyCode,
    this.billingCycleCount,
    this.billingPeriod,
  });
}

/// Purchase class
class Purchase {
  final String productId;
  final String? transactionId;
  final String? transactionReceipt;
  final String? purchaseToken;
  final DateTime? transactionDate;
  final IAPPlatform platform;
  final bool? isAcknowledgedAndroid;
  final String? purchaseStateAndroid;
  final String? originalTransactionIdentifierIOS;
  final Map<String, dynamic>? originalJson;
  // StoreKit 2 specific fields
  final String? transactionState;
  final bool? isUpgraded;
  final DateTime? expirationDate;
  final DateTime? revocationDate;
  final int? revocationReason;

  Purchase({
    required this.productId,
    this.transactionId,
    this.transactionReceipt,
    this.purchaseToken,
    this.transactionDate,
    required this.platform,
    this.isAcknowledgedAndroid,
    this.purchaseStateAndroid,
    this.originalTransactionIdentifierIOS,
    this.originalJson,
    this.transactionState,
    this.isUpgraded,
    this.expirationDate,
    this.revocationDate,
    this.revocationReason,
  });
}

/// Purchase error class
class PurchaseError implements Exception {
  final String name;
  final String message;
  final int? responseCode;
  final String? debugMessage;
  final ErrorCode? code;
  final String? productId;
  final IAPPlatform? platform;

  PurchaseError({
    String? name,
    required this.message,
    this.responseCode,
    this.debugMessage,
    this.code,
    this.productId,
    this.platform,
  }) : name = name ?? '[flutter_inapp_purchase]: PurchaseError';

  /// Creates a PurchaseError from platform-specific error data
  factory PurchaseError.fromPlatformError(
    Map<String, dynamic> errorData,
    IAPPlatform platform,
  ) {
    final errorCode = errorData['code'] != null
        ? ErrorCodeUtils.fromPlatformCode(errorData['code'], platform)
        : ErrorCode.E_UNKNOWN;

    return PurchaseError(
      message: errorData['message']?.toString() ?? 'Unknown error occurred',
      responseCode: errorData['responseCode'] as int?,
      debugMessage: errorData['debugMessage']?.toString(),
      code: errorCode,
      productId: errorData['productId']?.toString(),
      platform: platform,
    );
  }

  /// Gets the platform-specific error code for this error
  dynamic getPlatformCode() {
    if (code == null || platform == null) return null;
    return ErrorCodeUtils.toPlatformCode(code!, platform!);
  }

  @override
  String toString() => '$name: $message';
}

/// Purchase result (legacy)
class PurchaseResult {
  final int? responseCode;
  final String? debugMessage;
  final String? code;
  final String? message;
  final String? purchaseTokenAndroid;

  PurchaseResult({
    this.responseCode,
    this.debugMessage,
    this.code,
    this.message,
    this.purchaseTokenAndroid,
  });
}

/// Utility functions for error code mapping and validation
class ErrorCodeUtils {
  /// Maps a platform-specific error code back to the standardized ErrorCode enum
  static ErrorCode fromPlatformCode(
    dynamic platformCode,
    IAPPlatform platform,
  ) {
    if (platform == IAPPlatform.ios) {
      final mapping = ErrorCodeMapping.ios;
      for (final entry in mapping.entries) {
        if (entry.value == platformCode) {
          return entry.key;
        }
      }
    } else {
      final mapping = ErrorCodeMapping.android;
      for (final entry in mapping.entries) {
        if (entry.value == platformCode) {
          return entry.key;
        }
      }
    }
    return ErrorCode.E_UNKNOWN;
  }

  /// Maps an ErrorCode enum to platform-specific code
  static dynamic toPlatformCode(
    ErrorCode errorCode,
    IAPPlatform platform,
  ) {
    if (platform == IAPPlatform.ios) {
      return ErrorCodeMapping.ios[errorCode] ?? 0;
    } else {
      return ErrorCodeMapping.android[errorCode] ?? 'E_UNKNOWN';
    }
  }

  /// Checks if an error code is valid for the specified platform
  static bool isValidForPlatform(
    ErrorCode errorCode,
    IAPPlatform platform,
  ) {
    if (platform == IAPPlatform.ios) {
      return ErrorCodeMapping.ios.containsKey(errorCode);
    } else {
      return ErrorCodeMapping.android.containsKey(errorCode);
    }
  }
}

/// Request purchase parameters
class RequestPurchase {
  final RequestPurchaseIOS? ios;
  final RequestPurchaseAndroid? android;

  RequestPurchase({
    this.ios,
    this.android,
  });
}

/// iOS specific purchase request
class RequestPurchaseIOS {
  final String sku;
  final bool? andDangerouslyFinishTransactionAutomaticallyIOS;
  final String? appAccountToken;
  final int? quantity;
  final PaymentDiscount? withOffer;

  RequestPurchaseIOS({
    required this.sku,
    this.andDangerouslyFinishTransactionAutomaticallyIOS,
    this.appAccountToken,
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
  final int timestamp;

  PaymentDiscount({
    required this.identifier,
    required this.keyIdentifier,
    required this.nonce,
    required this.signature,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'identifier': identifier,
        'keyIdentifier': keyIdentifier,
        'nonce': nonce,
        'signature': signature,
        'timestamp': timestamp,
      };
}

/// Android specific purchase request
class RequestPurchaseAndroid {
  final List<String> skus;
  final String? obfuscatedAccountIdAndroid;
  final String? obfuscatedProfileIdAndroid;
  final bool? isOfferPersonalized;
  final String? purchaseToken;
  final int? offerTokenIndex;
  final int? prorationMode;

  RequestPurchaseAndroid({
    required this.skus,
    this.obfuscatedAccountIdAndroid,
    this.obfuscatedProfileIdAndroid,
    this.isOfferPersonalized,
    this.purchaseToken,
    this.offerTokenIndex,
    this.prorationMode,
  });
}

/// Android specific subscription request
class RequestSubscriptionAndroid extends RequestPurchaseAndroid {
  final int? replacementModeAndroid;
  final List<SubscriptionOfferAndroid>? subscriptionOffers;

  RequestSubscriptionAndroid({
    required List<String> skus,
    String? obfuscatedAccountIdAndroid,
    String? obfuscatedProfileIdAndroid,
    bool? isOfferPersonalized,
    String? purchaseToken,
    int? offerTokenIndex,
    int? prorationMode,
    this.replacementModeAndroid,
    this.subscriptionOffers,
  }) : super(
          skus: skus,
          obfuscatedAccountIdAndroid: obfuscatedAccountIdAndroid,
          obfuscatedProfileIdAndroid: obfuscatedProfileIdAndroid,
          isOfferPersonalized: isOfferPersonalized,
          purchaseToken: purchaseToken,
          offerTokenIndex: offerTokenIndex,
          prorationMode: prorationMode,
        );
}

/// Subscription offer for Android
class SubscriptionOfferAndroid {
  final String sku;
  final String offerToken;

  SubscriptionOfferAndroid({
    required this.sku,
    required this.offerToken,
  });
}

/// Request subscription parameters
class RequestSubscription {
  final RequestPurchaseIOS? ios;
  final RequestSubscriptionAndroid? android;

  RequestSubscription({
    this.ios,
    this.android,
  });
}

/// Unified request purchase props
class UnifiedRequestPurchaseProps {
  // Universal properties
  final String? sku;
  final List<String>? skus;

  // iOS-specific properties
  final bool? andDangerouslyFinishTransactionAutomaticallyIOS;
  final String? appAccountToken;
  final int? quantity;
  final PaymentDiscount? withOffer;

  // Android-specific properties
  final String? obfuscatedAccountIdAndroid;
  final String? obfuscatedProfileIdAndroid;
  final bool? isOfferPersonalized;

  UnifiedRequestPurchaseProps({
    this.sku,
    this.skus,
    this.andDangerouslyFinishTransactionAutomaticallyIOS,
    this.appAccountToken,
    this.quantity,
    this.withOffer,
    this.obfuscatedAccountIdAndroid,
    this.obfuscatedProfileIdAndroid,
    this.isOfferPersonalized,
  });
}

/// Unified subscription request props
class UnifiedRequestSubscriptionProps extends UnifiedRequestPurchaseProps {
  // Android subscription-specific properties
  final String? purchaseTokenAndroid;
  final int? replacementModeAndroid;
  final List<SubscriptionOfferAndroid>? subscriptionOffers;

  UnifiedRequestSubscriptionProps({
    String? sku,
    List<String>? skus,
    bool? andDangerouslyFinishTransactionAutomaticallyIOS,
    String? appAccountToken,
    int? quantity,
    PaymentDiscount? withOffer,
    String? obfuscatedAccountIdAndroid,
    String? obfuscatedProfileIdAndroid,
    bool? isOfferPersonalized,
    this.purchaseTokenAndroid,
    this.replacementModeAndroid,
    this.subscriptionOffers,
  }) : super(
          sku: sku,
          skus: skus,
          andDangerouslyFinishTransactionAutomaticallyIOS:
              andDangerouslyFinishTransactionAutomaticallyIOS,
          appAccountToken: appAccountToken,
          quantity: quantity,
          withOffer: withOffer,
          obfuscatedAccountIdAndroid: obfuscatedAccountIdAndroid,
          obfuscatedProfileIdAndroid: obfuscatedProfileIdAndroid,
          isOfferPersonalized: isOfferPersonalized,
        );
}

/// Request products parameters
class RequestProductsParams {
  final List<String> skus;
  final PurchaseType type;

  RequestProductsParams({
    required this.skus,
    required this.type,
  });
}

/// Connection result
class ConnectionResult {
  final bool connected;
  final String? message;

  ConnectionResult({
    required this.connected,
    this.message,
  });
}

/// iOS App Store info
class AppStoreInfo {
  final String? storefrontCountryCode;
  final String? identifier;

  AppStoreInfo({
    this.storefrontCountryCode,
    this.identifier,
  });
}

/// App Transaction data (iOS 16.0+)
class AppTransaction {
  final String bundleID;
  final String appVersion;
  final String originalAppVersion;
  final DateTime originalPurchaseDate;
  final String deviceVerification;
  final String deviceVerificationNonce;
  final String environment;
  final DateTime signedDate;
  final int appID;
  final int appVersionID;
  final DateTime? preorderDate;

  // iOS 18.4+ specific properties
  final String? appTransactionID;
  final String? originalPlatform;

  AppTransaction({
    required this.bundleID,
    required this.appVersion,
    required this.originalAppVersion,
    required this.originalPurchaseDate,
    required this.deviceVerification,
    required this.deviceVerificationNonce,
    required this.environment,
    required this.signedDate,
    required this.appID,
    required this.appVersionID,
    this.preorderDate,
    this.appTransactionID,
    this.originalPlatform,
  });

  factory AppTransaction.fromJson(Map<String, dynamic> json) {
    return AppTransaction(
      bundleID: json['bundleID'] as String,
      appVersion: json['appVersion'] as String,
      originalAppVersion: json['originalAppVersion'] as String,
      originalPurchaseDate: DateTime.fromMillisecondsSinceEpoch(
        (json['originalPurchaseDate'] as num).toInt(),
      ),
      deviceVerification: json['deviceVerification'] as String,
      deviceVerificationNonce: json['deviceVerificationNonce'] as String,
      environment: json['environment'] as String,
      signedDate: DateTime.fromMillisecondsSinceEpoch(
        (json['signedDate'] as num).toInt(),
      ),
      appID: json['appID'] as int,
      appVersionID: json['appVersionID'] as int,
      preorderDate: json['preorderDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (json['preorderDate'] as num).toInt(),
            )
          : null,
      appTransactionID: json['appTransactionID'] as String?,
      originalPlatform: json['originalPlatform'] as String?,
    );
  }
}

/// Get current platform
IAPPlatform getCurrentPlatform() {
  return Platform.isIOS ? IAPPlatform.ios : IAPPlatform.android;
}

// Type guards
bool isPlatformRequestProps(dynamic props) {
  return props is RequestPurchase || props is RequestSubscription;
}

bool isUnifiedRequestProps(dynamic props) {
  return props is UnifiedRequestPurchaseProps ||
      props is UnifiedRequestSubscriptionProps;
}

// Platform-specific product purchase types
class ProductPurchaseIos extends PurchaseBase {
  final IAPPlatform platform = IAPPlatform.ios;
  final String? originalTransactionIdentifierIOS;
  final DateTime? originalTransactionDateIOS;
  final String? transactionStateIOS;
  final bool? isUpgraded;
  final DateTime? expirationDate;
  final DateTime? revocationDate;
  final int? revocationReason;

  ProductPurchaseIos({
    required String id,
    String? transactionId,
    required int transactionDate,
    required String transactionReceipt,
    this.originalTransactionIdentifierIOS,
    this.originalTransactionDateIOS,
    this.transactionStateIOS,
    this.isUpgraded,
    this.expirationDate,
    this.revocationDate,
    this.revocationReason,
  }) : super(
          id: id,
          transactionId: transactionId,
          transactionDate: transactionDate,
          transactionReceipt: transactionReceipt,
        );
}

class ProductPurchaseAndroid extends PurchaseBase {
  final IAPPlatform platform = IAPPlatform.android;
  final String? purchaseToken;
  final String? dataAndroid;
  final String? signatureAndroid;
  final bool? autoRenewingAndroid;
  final bool? isAcknowledgedAndroid;
  final String? purchaseStateAndroid;

  ProductPurchaseAndroid({
    required String id,
    String? transactionId,
    required int transactionDate,
    required String transactionReceipt,
    this.purchaseToken,
    this.dataAndroid,
    this.signatureAndroid,
    this.autoRenewingAndroid,
    this.isAcknowledgedAndroid,
    this.purchaseStateAndroid,
  }) : super(
          id: id,
          transactionId: transactionId,
          transactionDate: transactionDate,
          transactionReceipt: transactionReceipt,
        );
}

// Union types
typedef ProductPurchase
    = dynamic; // ProductPurchaseAndroid | ProductPurchaseIos
typedef SubscriptionPurchase
    = dynamic; // ProductPurchaseAndroid | ProductPurchaseIos
typedef PurchaseUnion = dynamic; // ProductPurchase | SubscriptionPurchase

/// Store constants
class StoreConstants {
  static const String appStore = 'App Store';
  static const String playStore = 'Play Store';
  static const String sandbox = 'Sandbox';
  static const String production = 'Production';
}

/// Purchase update listener data
class PurchaseUpdate {
  final Purchase? purchase;
  final PurchaseError? error;
  final String? message;

  PurchaseUpdate({
    this.purchase,
    this.error,
    this.message,
  });
}

/// Receipt validation result
class ReceiptValidationResult {
  final bool isValid;
  final int? status;
  final Map<String, dynamic>? receipt;
  final String? message;

  ReceiptValidationResult({
    required this.isValid,
    this.status,
    this.receipt,
    this.message,
  });
}

/// Purchase token info
class PurchaseTokenInfo {
  final String token;
  final bool isValid;
  final DateTime? expiryTime;
  final String? productId;

  PurchaseTokenInfo({
    required this.token,
    required this.isValid,
    this.expiryTime,
    this.productId,
  });
}

/// Store info
class StoreInfo {
  final String storeName;
  final String? countryCode;
  final String? currencyCode;
  final bool isAvailable;

  StoreInfo({
    required this.storeName,
    this.countryCode,
    this.currencyCode,
    required this.isAvailable,
  });
}

/// IAP configuration
class IAPConfig {
  final bool autoFinishTransactions;
  final bool enablePendingPurchases;
  final Duration? connectionTimeout;
  final bool validateReceipts;

  const IAPConfig({
    this.autoFinishTransactions = true,
    this.enablePendingPurchases = true,
    this.connectionTimeout,
    this.validateReceipts = false,
  });
}

/// Platform check utilities
class PlatformCheck {
  static bool get isIOS => Platform.isIOS;
  static bool get isAndroid => Platform.isAndroid;
  static bool get isMacOS => Platform.isMacOS;
  static bool get isSupported => isIOS || isAndroid;
}

/// Deep link options
class DeepLinkOptions {
  final String? sku;
  final bool? showPriceChangeIfNeeded;

  DeepLinkOptions({
    this.sku,
    this.showPriceChangeIfNeeded,
  });
}

/// Promoted product
class PromotedProduct {
  final String productId;
  final int order;
  final bool visible;

  PromotedProduct({
    required this.productId,
    required this.order,
    required this.visible,
  });
}

/// Transaction info
class TransactionInfo {
  final String id;
  final String productId;
  final DateTime date;
  final TransactionState state;
  final String? receipt;

  TransactionInfo({
    required this.id,
    required this.productId,
    required this.date,
    required this.state,
    this.receipt,
  });
}

/// Billing info
class BillingInfo {
  final String? billingPeriod;
  final double? price;
  final String? currency;
  final String? countryCode;

  BillingInfo({
    this.billingPeriod,
    this.price,
    this.currency,
    this.countryCode,
  });
}

/// SKU details params (Android)
class SkuDetailsParams {
  final List<String> skuList;
  final String skuType;

  SkuDetailsParams({
    required this.skuList,
    required this.skuType,
  });
}

/// Purchase history record
class PurchaseHistoryRecord {
  final Purchase purchase;
  final DateTime date;
  final String? developerPayload;

  PurchaseHistoryRecord({
    required this.purchase,
    required this.date,
    this.developerPayload,
  });
}

/// Acknowledgement params
class AcknowledgementParams {
  final String purchaseToken;
  final String? developerPayload;

  AcknowledgementParams({
    required this.purchaseToken,
    this.developerPayload,
  });
}

/// Consumption params
class ConsumptionParams {
  final String purchaseToken;
  final String? developerPayload;

  ConsumptionParams({
    required this.purchaseToken,
    this.developerPayload,
  });
}
