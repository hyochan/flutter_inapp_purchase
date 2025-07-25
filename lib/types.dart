import 'dart:io';
import 'enums.dart';
export 'enums.dart';

/// Platform-specific error code mappings
class ErrorCodeMapping {
  static const Map<ErrorCode, int> ios = {
    ErrorCode.eUnknown: 0,
    ErrorCode.eServiceError: 1,
    ErrorCode.eUserCancelled: 2,
    ErrorCode.eUserError: 3,
    ErrorCode.eItemUnavailable: 4,
    ErrorCode.eRemoteError: 5,
    ErrorCode.eNetworkError: 6,
    ErrorCode.eReceiptFailed: 7,
    ErrorCode.eReceiptFinishedFailed: 8,
    ErrorCode.eDeveloperError: 9,
    ErrorCode.ePurchaseError: 10,
    ErrorCode.eSyncError: 11,
    ErrorCode.eDeferredPayment: 12,
    ErrorCode.eTransactionValidationFailed: 13,
    ErrorCode.eNotPrepared: 14,
    ErrorCode.eNotEnded: 15,
    ErrorCode.eAlreadyOwned: 16,
    ErrorCode.eBillingResponseJsonParseError: 17,
    ErrorCode.eInterrupted: 18,
    ErrorCode.eIapNotAvailable: 19,
    ErrorCode.eActivityUnavailable: 20,
    ErrorCode.eAlreadyPrepared: 21,
    ErrorCode.ePending: 22,
    ErrorCode.eConnectionClosed: 23,
  };

  static const Map<ErrorCode, String> android = {
    ErrorCode.eUnknown: 'E_UNKNOWN',
    ErrorCode.eUserCancelled: 'E_USER_CANCELLED',
    ErrorCode.eUserError: 'E_USER_ERROR',
    ErrorCode.eItemUnavailable: 'E_ITEM_UNAVAILABLE',
    ErrorCode.eRemoteError: 'E_REMOTE_ERROR',
    ErrorCode.eNetworkError: 'E_NETWORK_ERROR',
    ErrorCode.eServiceError: 'E_SERVICE_ERROR',
    ErrorCode.eReceiptFailed: 'E_RECEIPT_FAILED',
    ErrorCode.eReceiptFinishedFailed: 'E_RECEIPT_FINISHED_FAILED',
    ErrorCode.eNotPrepared: 'E_NOT_PREPARED',
    ErrorCode.eNotEnded: 'E_NOT_ENDED',
    ErrorCode.eAlreadyOwned: 'E_ALREADY_OWNED',
    ErrorCode.eDeveloperError: 'E_DEVELOPER_ERROR',
    ErrorCode.eBillingResponseJsonParseError:
        'E_BILLING_RESPONSE_JSON_PARSE_ERROR',
    ErrorCode.eDeferredPayment: 'E_DEFERRED_PAYMENT',
    ErrorCode.eInterrupted: 'E_INTERRUPTED',
    ErrorCode.eIapNotAvailable: 'E_IAP_NOT_AVAILABLE',
    ErrorCode.ePurchaseError: 'E_PURCHASE_ERROR',
    ErrorCode.eSyncError: 'E_SYNC_ERROR',
    ErrorCode.eTransactionValidationFailed: 'E_TRANSACTION_VALIDATION_FAILED',
    ErrorCode.eActivityUnavailable: 'E_ACTIVITY_UNAVAILABLE',
    ErrorCode.eAlreadyPrepared: 'E_ALREADY_PREPARED',
    ErrorCode.ePending: 'E_PENDING',
    ErrorCode.eConnectionClosed: 'E_CONNECTION_CLOSED',
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

  /// Create [DiscountIOS] from a Map that was previously JSON formatted
  DiscountIOS.fromJSON(Map<String, dynamic> json)
      : identifier = json['identifier'] as String?,
        type = json['type'] as String?,
        numberOfPeriods = json['numberOfPeriods'] as String?,
        price = json['price'] as double?,
        localizedPrice = json['localizedPrice'] as String?,
        paymentMode = json['paymentMode'] as String?,
        subscriptionPeriod = json['subscriptionPeriod'] as String?;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['identifier'] = this.identifier;
    data['type'] = this.type;
    data['numberOfPeriods'] = this.numberOfPeriods;
    data['price'] = this.price;
    data['localizedPrice'] = this.localizedPrice;
    data['paymentMode'] = this.paymentMode;
    data['subscriptionPeriod'] = this.subscriptionPeriod;
    return data;
  }

  /// Return the contents of this class as a string
  @override
  String toString() {
    return 'identifier: $identifier, '
        'type: $type, '
        'numberOfPeriods: $numberOfPeriods, '
        'price: $price, '
        'localizedPrice: $localizedPrice, '
        'paymentMode: $paymentMode, '
        'subscriptionPeriod: $subscriptionPeriod, ';
  }
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
        : ErrorCode.eUnknown;

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

  PurchaseResult.fromJSON(Map<String, dynamic> json)
      : responseCode = json['responseCode'] as int?,
        debugMessage = json['debugMessage'] as String?,
        code = json['code'] as String?,
        message = json['message'] as String?,
        purchaseTokenAndroid = json['purchaseTokenAndroid'] as String?;

  Map<String, dynamic> toJson() => {
        "responseCode": responseCode ?? 0,
        "debugMessage": debugMessage ?? '',
        "code": code ?? '',
        "message": message ?? '',
        "purchaseTokenAndroid": purchaseTokenAndroid ?? '',
      };

  @override
  String toString() {
    return 'responseCode: $responseCode, '
        'debugMessage: $debugMessage, '
        'code: $code, '
        'message: $message';
  }
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
    return ErrorCode.eUnknown;
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
  final String? offerId;
  final String? basePlanId;
  final List<PricingPhaseAndroid>? pricingPhases;

  SubscriptionOfferAndroid({
    required this.sku,
    required this.offerToken,
    this.offerId,
    this.basePlanId,
    this.pricingPhases,
  });

  SubscriptionOfferAndroid.fromJSON(Map<String, dynamic> json)
      : sku = json["sku"] as String? ?? '',
        offerToken = json["offerToken"] as String? ?? '',
        offerId = json["offerId"] as String?,
        basePlanId = json["basePlanId"] as String?,
        pricingPhases = _extractAndroidPricingPhase(json["pricingPhases"]);

  static List<PricingPhaseAndroid>? _extractAndroidPricingPhase(dynamic json) {
    List<dynamic>? list = json as List<dynamic>?;
    List<PricingPhaseAndroid>? phases;

    if (list != null) {
      phases = list
          .map<PricingPhaseAndroid>(
            (dynamic phase) =>
                PricingPhaseAndroid.fromJSON(phase as Map<String, dynamic>),
          )
          .toList();
    }

    return phases;
  }
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

/// An item available for purchase from either the `Google Play Store` or `iOS AppStore`
class IAPItem {
  final String? productId;
  final String? price;
  final String? currency;
  final String? localizedPrice;
  final String? title;
  final String? description;
  final String? introductoryPrice;

  /// ios only
  final String? subscriptionPeriodNumberIOS;
  final String? subscriptionPeriodUnitIOS;
  final String? introductoryPriceNumberIOS;
  final String? introductoryPricePaymentModeIOS;
  final String? introductoryPriceNumberOfPeriodsIOS;
  final String? introductoryPriceSubscriptionPeriodIOS;
  final List<DiscountIOS>? discountsIOS;

  /// android only
  final String? signatureAndroid;
  final List<SubscriptionOfferAndroid>? subscriptionOffersAndroid;
  final String? subscriptionPeriodAndroid;

  final String? iconUrl;
  final String? originalJson;
  final String originalPrice;

  /// Create [IAPItem] from a Map that was previously JSON formatted
  IAPItem.fromJSON(Map<String, dynamic> json)
      : productId = json['productId'] as String?,
        price = json['price'] as String?,
        currency = json['currency'] as String?,
        localizedPrice = json['localizedPrice'] as String?,
        title = json['title'] as String?,
        description = json['description'] as String?,
        introductoryPrice = json['introductoryPrice'] as String?,
        introductoryPricePaymentModeIOS =
            json['introductoryPricePaymentModeIOS'] as String?,
        introductoryPriceNumberOfPeriodsIOS =
            json['introductoryPriceNumberOfPeriodsIOS'] != null
                ? json['introductoryPriceNumberOfPeriodsIOS'].toString()
                : null,
        introductoryPriceSubscriptionPeriodIOS =
            json['introductoryPriceSubscriptionPeriodIOS'] as String?,
        introductoryPriceNumberIOS = json['introductoryPriceNumberIOS'] != null
            ? json['introductoryPriceNumberIOS'].toString()
            : null,
        subscriptionPeriodNumberIOS =
            json['subscriptionPeriodNumberIOS'] != null
                ? json['subscriptionPeriodNumberIOS'].toString()
                : null,
        subscriptionPeriodUnitIOS =
            json['subscriptionPeriodUnitIOS'] as String?,
        subscriptionPeriodAndroid =
            json['subscriptionPeriodAndroid'] as String?,
        signatureAndroid = json['signatureAndroid'] as String?,
        iconUrl = json['iconUrl'] as String?,
        originalJson = json['originalJson'] as String?,
        originalPrice = json['originalPrice'] != null
            ? json['originalPrice'].toString()
            : '',
        discountsIOS = _extractDiscountIOS(json['discounts']),
        subscriptionOffersAndroid =
            _extractSubscriptionOffersAndroid(json['subscriptionOffers']);

  /// wow, i find if i want to save a IAPItem, there is not "toJson" to cast it into String...
  /// i'm sorry to see that... so,
  ///
  /// you can cast a IAPItem to json(Map<String, dynamic>) via invoke this method.
  /// for example:
  /// String str =  convert.jsonEncode(item)
  ///
  /// and then get IAPItem from "str" above
  /// IAPItem item = IAPItem.fromJSON(convert.jsonDecode(str));
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['productId'] = this.productId;
    data['price'] = this.price;
    data['currency'] = this.currency;
    data['localizedPrice'] = this.localizedPrice;
    data['title'] = this.title;
    data['description'] = this.description;
    data['introductoryPrice'] = this.introductoryPrice;

    data['subscriptionPeriodNumberIOS'] = this.subscriptionPeriodNumberIOS;
    data['subscriptionPeriodUnitIOS'] = this.subscriptionPeriodUnitIOS;
    data['introductoryPricePaymentModeIOS'] =
        this.introductoryPricePaymentModeIOS;
    data['introductoryPriceNumberOfPeriodsIOS'] =
        this.introductoryPriceNumberOfPeriodsIOS;
    data['introductoryPriceSubscriptionPeriodIOS'] =
        this.introductoryPriceSubscriptionPeriodIOS;
    data['subscriptionPeriodAndroid'] = this.subscriptionPeriodAndroid;
    data['signatureAndroid'] = this.signatureAndroid;

    data['iconUrl'] = this.iconUrl;
    data['originalJson'] = this.originalJson;
    data['originalPrice'] = this.originalPrice;
    data['discounts'] = this.discountsIOS;
    return data;
  }

  /// Return the contents of this class as a string
  @override
  String toString() {
    return 'productId: $productId, '
        'price: $price, '
        'currency: $currency, '
        'localizedPrice: $localizedPrice, '
        'title: $title, '
        'description: $description, '
        'introductoryPrice: $introductoryPrice, '
        'subscriptionPeriodNumberIOS: $subscriptionPeriodNumberIOS, '
        'subscriptionPeriodUnitIOS: $subscriptionPeriodUnitIOS, '
        'introductoryPricePaymentModeIOS: $introductoryPricePaymentModeIOS, '
        'introductoryPriceNumberOfPeriodsIOS: $introductoryPriceNumberOfPeriodsIOS, '
        'introductoryPriceSubscriptionPeriodIOS: $introductoryPriceSubscriptionPeriodIOS, '
        'subscriptionPeriodAndroid: $subscriptionPeriodAndroid, '
        'iconUrl: $iconUrl, '
        'originalJson: $originalJson, '
        'originalPrice: $originalPrice, '
        'discounts: $discountsIOS, ';
  }

  static List<DiscountIOS>? _extractDiscountIOS(dynamic json) {
    List<dynamic>? list = json as List<dynamic>?;
    List<DiscountIOS>? discounts;

    if (list != null) {
      discounts = list
          .map<DiscountIOS>(
            (dynamic discount) =>
                DiscountIOS.fromJSON(discount as Map<String, dynamic>),
          )
          .toList();
    }

    return discounts;
  }

  static List<SubscriptionOfferAndroid>? _extractSubscriptionOffersAndroid(
      dynamic json) {
    List<dynamic>? list = json as List<dynamic>?;
    List<SubscriptionOfferAndroid>? offers;

    if (list != null) {
      offers = list
          .map<SubscriptionOfferAndroid>(
            (dynamic offer) => SubscriptionOfferAndroid.fromJSON(
                offer as Map<String, dynamic>),
          )
          .toList();
    }

    return offers;
  }
}

/// An item which was purchased from either the `Google Play Store` or `iOS AppStore`
class PurchasedItem {
  final String? productId;
  final String? transactionId;
  final DateTime? transactionDate;
  final String? transactionReceipt;
  final String? purchaseToken;

  // Android only
  final String? dataAndroid;
  final String? signatureAndroid;
  final bool? autoRenewingAndroid;
  final bool? isAcknowledgedAndroid;
  final PurchaseState? purchaseStateAndroid;

  // iOS only
  final DateTime? originalTransactionDateIOS;
  final String? originalTransactionIdentifierIOS;
  final TransactionState? transactionStateIOS;

  /// Create [PurchasedItem] from a Map that was previously JSON formatted
  PurchasedItem.fromJSON(Map<String, dynamic> json)
      : productId = json['productId'] as String?,
        transactionId = json['transactionId'] as String?,
        transactionDate = _extractDate(json['transactionDate']),
        transactionReceipt = json['transactionReceipt'] as String?,
        purchaseToken = json['purchaseToken'] as String?,
        dataAndroid = json['dataAndroid'] as String?,
        signatureAndroid = json['signatureAndroid'] as String?,
        isAcknowledgedAndroid = json['isAcknowledgedAndroid'] as bool?,
        autoRenewingAndroid = json['autoRenewingAndroid'] as bool?,
        purchaseStateAndroid =
            _decodePurchaseStateAndroid(json['purchaseStateAndroid'] as int?),
        originalTransactionDateIOS =
            _extractDate(json['originalTransactionDateIOS']),
        originalTransactionIdentifierIOS =
            json['originalTransactionIdentifierIOS'] as String?,
        transactionStateIOS =
            _decodeTransactionStateIOS(json['transactionStateIOS'] as int?);

  /// This returns transaction dates in ISO 8601 format.
  @override
  String toString() {
    return 'productId: $productId, '
        'transactionId: $transactionId, '
        'transactionDate: ${transactionDate?.toIso8601String()}, '
        'transactionReceipt: $transactionReceipt, '
        'purchaseToken: $purchaseToken, '

        /// android specific
        'dataAndroid: $dataAndroid, '
        'signatureAndroid: $signatureAndroid, '
        'isAcknowledgedAndroid: $isAcknowledgedAndroid, '
        'autoRenewingAndroid: $autoRenewingAndroid, '
        'purchaseStateAndroid: $purchaseStateAndroid, '

        /// ios specific
        'originalTransactionDateIOS: ${originalTransactionDateIOS?.toIso8601String()}, '
        'originalTransactionIdentifierIOS: $originalTransactionIdentifierIOS, '
        'transactionStateIOS: $transactionStateIOS';
  }

  /// Coerce miliseconds since epoch in double, int, or String into DateTime format
  static DateTime? _extractDate(dynamic timestamp) {
    if (timestamp == null) return null;

    int _toInt() => double.parse(timestamp.toString()).toInt();
    return DateTime.fromMillisecondsSinceEpoch(_toInt());
  }

  static TransactionState? _decodeTransactionStateIOS(int? rawValue) {
    switch (rawValue) {
      case 0:
        return TransactionState.purchasing;
      case 1:
        return TransactionState.purchased;
      case 2:
        return TransactionState.failed;
      case 3:
        return TransactionState.restored;
      case 4:
        return TransactionState.deferred;
      default:
        return null;
    }
  }

  static PurchaseState? _decodePurchaseStateAndroid(int? rawValue) {
    switch (rawValue) {
      case 0:
        return PurchaseState.unspecified;
      case 1:
        return PurchaseState.purchased;
      case 2:
        return PurchaseState.pending;
      default:
        return null;
    }
  }
}

/// Pricing phase for Android subscriptions
class PricingPhaseAndroid {
  String? price;
  String? formattedPrice;
  String? billingPeriod;
  String? currencyCode;
  int? recurrenceMode;
  int? billingCycleCount;

  PricingPhaseAndroid.fromJSON(Map<String, dynamic> json)
      : price = json["price"] as String?,
        formattedPrice = json["formattedPrice"] as String?,
        billingPeriod = json["billingPeriod"] as String?,
        currencyCode = json["currencyCode"] as String?,
        recurrenceMode = json["recurrenceMode"] as int?,
        billingCycleCount = json["billingCycleCount"] as int?;
}

/// Connection result
class ConnectionResult {
  final bool connected;
  final String? message;

  ConnectionResult({
    required this.connected,
    this.message,
  });

  ConnectionResult.fromJSON(Map<String, dynamic> json)
      : connected = json['connected'] as bool? ?? false,
        message = json['message'] as String?;

  Map<String, dynamic> toJson() => {
        "connected": connected,
        "message": message,
      };

  @override
  String toString() {
    return 'connected: $connected, message: $message';
  }
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
