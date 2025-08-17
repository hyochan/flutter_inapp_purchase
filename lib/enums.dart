/// Enums for flutter_inapp_purchase package

/// Store types
enum Store { none, playStore, amazon, appStore }

/// Platform detection enum
enum IapPlatform { ios, android }

/// Purchase type enum
enum PurchaseType { inapp, subs }

/// Error codes (OpenIAP compliant)
enum ErrorCode {
  // Common error codes per OpenIAP spec
  eUnknown,
  eUserCancelled,
  eUserError,
  eItemUnavailable,
  eProductNotAvailable,
  eProductAlreadyOwned,
  eReceiptFinished,
  eAlreadyOwned,
  eNetworkError,
  eServiceError,
  eRemoteError,
  eReceiptFailed,
  ePending,
  eNotEnded,
  eDeveloperError,

  // Legacy codes kept for compatibility
  eReceiptFinishedFailed,
  eNotPrepared,
  eBillingResponseJsonParseError,
  eDeferredPayment,
  eInterrupted,
  eIapNotAvailable,
  ePurchaseError,
  eSyncError,
  eTransactionValidationFailed,
  eActivityUnavailable,
  eAlreadyPrepared,
  eConnectionClosed,
  eBillingUnavailable,
  ePurchaseNotAllowed,
  eQuotaExceeded,
  eFeatureNotSupported,
  eNotInitialized,
  eAlreadyInitialized,
  eClientInvalid,
  ePaymentInvalid,
  ePaymentNotAllowed,
  eStorekitOriginalTransactionIdNotFound,
  eNotSupported,
  eTransactionFailed,
  eTransactionInvalid,
  eProductNotFound,
  ePurchaseFailed,
  eTransactionNotFound,
  eRestoreFailed,
  eRedeemFailed,
  eNoWindowScene,
  eShowSubscriptionsFailed,
  eProductLoadFailed,
}

/// Subscription states
enum SubscriptionState {
  active,
  expired,
  inBillingRetry,
  inGracePeriod,
  revoked,
}

/// Transaction states
enum TransactionState { purchasing, purchased, failed, restored, deferred }

/// Platform availability types
enum ProductAvailability {
  canMakePayments,
  installed,
  notInstalled,
  notSupported,
}

/// In-app message types
enum InAppMessageType { purchase, billing, price, generic }

/// Refund types
enum RefundType { issue, priceChange, preference }

/// Offer types
enum OfferType { introductory, promotional, code, winBack }

/// Billing client state
enum BillingClientState { disconnected, connecting, connected, closed }

/// Proration mode (Android)
enum ProrationMode {
  immediateWithTimeProration,
  immediateAndChargeProratedPrice,
  immediateWithoutProration,
  deferred,
  immediateAndChargeFullPrice,
}

/// Replace mode (Android)
enum ReplaceMode {
  withTimeProration,
  chargeProratedPrice,
  withoutProration,
  deferred,
  chargeFullPrice,
}

/// A enumeration of in-app purchase types for Android
enum TypeInApp { inapp, subs }

/// Android billing response codes
enum ResponseCodeAndroid {
  billingResponseResultOk,
  billingResponseResultUserCanceled,
  billingResponseResultServiceUnavailable,
  billingResponseResultBillingUnavailable,
  billingResponseResultItemUnavailable,
  billingResponseResultDeveloperError,
  billingResponseResultError,
  billingResponseResultItemAlreadyOwned,
  billingResponseResultItemNotOwned,
  unknown,
}

/// See also https://developer.android.com/reference/com/android/billingclient/api/Purchase.PurchaseState
enum PurchaseState { pending, purchased, unspecified }

/// Android Proration Mode
enum AndroidProrationMode {
  unknownSubscriptionUpgradeDowngradePolicy(0),
  immediateWithTimeProration(1),
  immediateAndChargeProratedPrice(2),
  immediateWithoutProration(3),
  deferred(4),
  immediateAndChargeFullPrice(5);

  final int value;
  const AndroidProrationMode(this.value);
}
