// Enums for flutter_inapp_purchase package
library;

/// Store types
enum Store { none, playStore, amazon, appStore }

/// Platform detection enum
enum IapPlatform { ios, android }

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

/// Replacement mode (Android)
enum ReplacementMode {
  withTimeProration,
  chargeProratedPrice,
  withoutProration,
  deferred,
  chargeFullPrice,
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

/// Android purchase states from Google Play Billing
enum AndroidPurchaseState {
  unspecified(0), // UNSPECIFIED_STATE
  purchased(1), // PURCHASED
  pending(2); // PENDING

  final int value;
  const AndroidPurchaseState(this.value);

  static AndroidPurchaseState fromValue(int value) {
    return AndroidPurchaseState.values.firstWhere(
      (state) => state.value == value,
      orElse: () => AndroidPurchaseState.unspecified,
    );
  }
}

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

/// Android Replacement Mode (formerly Proration Mode)
///
/// IMPORTANT: Replacement modes are ONLY for upgrading/downgrading EXISTING subscriptions.
/// For NEW subscriptions, do NOT use any replacement mode.
///
/// To use replacement mode:
/// 1. User must have an active subscription
/// 2. You must provide the purchaseToken from the existing subscription
/// 3. Get the token using getAvailablePurchases()
///
/// Example:
/// ```dart
/// // First, check for existing subscription
/// final purchases = await FlutterInappPurchase.instance.getAvailablePurchases();
/// if (purchases.isEmpty) {
///   // User has no subscription - purchase new one WITHOUT replacement mode
///   await FlutterInappPurchase.instance.requestSubscription('premium_monthly');
/// } else {
///   // User has subscription - can upgrade/downgrade WITH replacement mode
///   final existingSub = purchases.first;
///   await FlutterInappPurchase.instance.requestSubscription(
///     'premium_yearly',
///     replacementModeAndroid: AndroidReplacementMode.withTimeProration.value,
///     purchaseTokenAndroid: existingSub.purchaseToken,
///   );
/// }
/// ```
enum AndroidReplacementMode {
  unknownReplacementMode(0),
  withTimeProration(1),
  chargeProratedPrice(2),
  withoutProration(3),
  deferred(4),
  chargeFullPrice(5);

  final int value;
  const AndroidReplacementMode(this.value);
}
