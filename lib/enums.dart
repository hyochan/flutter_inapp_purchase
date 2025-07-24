/// Enums for flutter_inapp_purchase package

/// Store types
enum Store { none, playStore, amazon, appStore }

/// Platform detection enum
enum IAPPlatform { ios, android }

/// Purchase type enum
enum PurchaseType { inapp, subs }

/// Error codes matching flutter IAP
enum ErrorCode {
  eUnknown,
  eUserCancelled,
  eUserError,
  eItemUnavailable,
  eRemoteError,
  eNetworkError,
  eServiceError,
  eReceiptFailed,
  eReceiptFinishedFailed,
  eNotPrepared,
  eNotEnded,
  eAlreadyOwned,
  eDeveloperError,
  eBillingResponseJsonParseError,
  eDeferredPayment,
  eInterrupted,
  eIapNotAvailable,
  ePurchaseError,
  eSyncError,
  eTransactionValidationFailed,
  eActivityUnavailable,
  eAlreadyPrepared,
  ePending,
  eConnectionClosed,
  // Additional error codes
  eBillingUnavailable,
  eProductAlreadyOwned,
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
enum TransactionState {
  purchasing,
  purchased,
  failed,
  restored,
  deferred,
}

/// Platform availability types
enum ProductAvailability {
  canMakePayments,
  installed,
  notInstalled,
  notSupported,
}

/// In-app message types
enum InAppMessageType {
  purchase,
  billing,
  price,
  generic,
}

/// Refund types
enum RefundType {
  issue,
  priceChange,
  preference,
}

/// Offer types
enum OfferType {
  introductory,
  promotional,
  code,
  winBack,
}

/// Billing client state
enum BillingClientState {
  disconnected,
  connecting,
  connected,
  closed,
}

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
  BILLING_RESPONSE_RESULT_OK,
  BILLING_RESPONSE_RESULT_USER_CANCELED,
  BILLING_RESPONSE_RESULT_SERVICE_UNAVAILABLE,
  BILLING_RESPONSE_RESULT_BILLING_UNAVAILABLE,
  BILLING_RESPONSE_RESULT_ITEM_UNAVAILABLE,
  BILLING_RESPONSE_RESULT_DEVELOPER_ERROR,
  BILLING_RESPONSE_RESULT_ERROR,
  BILLING_RESPONSE_RESULT_ITEM_ALREADY_OWNED,
  BILLING_RESPONSE_RESULT_ITEM_NOT_OWNED,
  UNKNOWN,
}

/// See also https://developer.android.com/reference/com/android/billingclient/api/Purchase.PurchaseState
enum PurchaseState {
  pending,
  purchased,
  unspecified,
}

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
