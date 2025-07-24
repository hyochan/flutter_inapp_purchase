/// Enums for flutter_inapp_purchase package

/// Store types
enum Store { none, playStore, amazon, appStore }

/// Platform detection enum
enum IAPPlatform { ios, android }

/// Purchase type enum
enum PurchaseType { inapp, subs }

/// Error codes matching flutter IAP
enum ErrorCode {
  E_UNKNOWN,
  E_USER_CANCELLED,
  E_USER_ERROR,
  E_ITEM_UNAVAILABLE,
  E_REMOTE_ERROR,
  E_NETWORK_ERROR,
  E_SERVICE_ERROR,
  E_RECEIPT_FAILED,
  E_RECEIPT_FINISHED_FAILED,
  E_NOT_PREPARED,
  E_NOT_ENDED,
  E_ALREADY_OWNED,
  E_DEVELOPER_ERROR,
  E_BILLING_RESPONSE_JSON_PARSE_ERROR,
  E_DEFERRED_PAYMENT,
  E_INTERRUPTED,
  E_IAP_NOT_AVAILABLE,
  E_PURCHASE_ERROR,
  E_SYNC_ERROR,
  E_TRANSACTION_VALIDATION_FAILED,
  E_ACTIVITY_UNAVAILABLE,
  E_ALREADY_PREPARED,
  E_PENDING,
  E_CONNECTION_CLOSED,
  // Additional error codes
  E_BILLING_UNAVAILABLE,
  E_PRODUCT_ALREADY_OWNED,
  E_PURCHASE_NOT_ALLOWED,
  E_QUOTA_EXCEEDED,
  E_FEATURE_NOT_SUPPORTED,
  E_NOT_INITIALIZED,
  E_ALREADY_INITIALIZED,
  E_CLIENT_INVALID,
  E_PAYMENT_INVALID,
  E_PAYMENT_NOT_ALLOWED,
  E_STOREKIT_ORIGINAL_TRANSACTION_ID_NOT_FOUND,
  E_NOT_SUPPORTED,
  E_TRANSACTION_FAILED,
  E_TRANSACTION_INVALID,
  E_PRODUCT_NOT_FOUND,
  E_PURCHASE_FAILED,
  E_TRANSACTION_NOT_FOUND,
  E_RESTORE_FAILED,
  E_REDEEM_FAILED,
  E_NO_WINDOW_SCENE,
  E_SHOW_SUBSCRIPTIONS_FAILED,
  E_PRODUCT_LOAD_FAILED,
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