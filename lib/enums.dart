// Enums for flutter_inapp_purchase package
// ignore_for_file: constant_identifier_names

/// Store types
enum Store { none, playStore, amazon, appStore }

/// Platform detection enum
enum IapPlatform { ios, android }

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
@Deprecated('Use AndroidReplacementMode')
enum ReplacementMode {
  withTimeProration,
  chargeProratedPrice,
  withoutProration,
  deferred,
  chargeFullPrice,
}

/// Replace mode (Android)
@Deprecated('Use AndroidReplacementMode')
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
  Unknown, // UNSPECIFIED_STATE
  Purchased, // PURCHASED
  Pending, // PENDING
}

AndroidPurchaseState androidPurchaseStateFromValue(int value) {
  switch (value) {
    case 1:
      return AndroidPurchaseState.Purchased;
    case 2:
      return AndroidPurchaseState.Pending;
    default:
      return AndroidPurchaseState.Unknown;
  }
}

extension AndroidPurchaseStateValue on AndroidPurchaseState {
  int get value {
    switch (this) {
      case AndroidPurchaseState.Unknown:
        return 0;
      case AndroidPurchaseState.Purchased:
        return 1;
      case AndroidPurchaseState.Pending:
        return 2;
    }
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
///   await FlutterInappPurchase.instance.requestPurchaseWithBuilder(
///     build: (builder) {
///       builder.type = ProductQueryType.Subs;
///       builder.android.skus = ['premium_monthly'];
///     },
///   );
/// } else {
///   // User has subscription - can upgrade/downgrade WITH replacement mode
///   final existingSub = purchases.first;
///   await FlutterInappPurchase.instance.requestPurchaseWithBuilder(
///     build: (builder) {
///       builder.type = ProductQueryType.Subs;
///       builder.android
///         ..skus = ['premium_yearly']
///         ..purchaseTokenAndroid = existingSub.purchaseToken
///         ..replacementModeAndroid =
///             AndroidReplacementMode.withTimeProration.value;
///     },
///   );
/// }
/// ```
enum AndroidReplacementMode {
  unknownReplacementMode,
  withTimeProration,
  chargeProratedPrice,
  withoutProration,
  deferred,
  chargeFullPrice,
}

extension AndroidReplacementModeValue on AndroidReplacementMode {
  int get value {
    switch (this) {
      case AndroidReplacementMode.unknownReplacementMode:
        return 0;
      case AndroidReplacementMode.withTimeProration:
        return 1;
      case AndroidReplacementMode.chargeProratedPrice:
        return 2;
      case AndroidReplacementMode.withoutProration:
        return 3;
      case AndroidReplacementMode.deferred:
        return 4;
      case AndroidReplacementMode.chargeFullPrice:
        return 5;
    }
  }
}
