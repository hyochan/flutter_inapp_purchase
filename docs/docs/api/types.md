---
title: Types
sidebar_position: 2
---

# Types

Comprehensive type definitions for flutter_inapp_purchase v6.8.0. All types are fully documented with TypeScript-style definitions for complete type safety.

## Core Types

### RequestPurchase

Platform-specific purchase request configuration.

```dart
class RequestPurchase {
  final RequestPurchaseIOS? ios;
  final RequestPurchaseAndroid? android;

  RequestPurchase({
    this.ios,
    this.android,
  });
}
```

### RequestPurchaseIOS

iOS-specific purchase parameters.

```dart
class RequestPurchaseIOS {
  final String sku;                                                   // Product SKU
  final bool? andDangerouslyFinishTransactionAutomaticallyIOS;       // Auto-finish transaction
  final String? appAccountToken;                                      // App account token
  final int? quantity;                                               // Purchase quantity
  final PaymentDiscount? withOffer;                                  // Promotional offer

  RequestPurchaseIOS({
    required this.sku,
    this.andDangerouslyFinishTransactionAutomaticallyIOS,
    this.appAccountToken,
    this.quantity,
    this.withOffer,
  });
}
```

### RequestPurchaseAndroid

Android-specific purchase parameters.

```dart
class RequestPurchaseAndroid {
  final List<String> skus;                      // Product SKUs
  final String? obfuscatedAccountIdAndroid;     // Account ID
  final String? obfuscatedProfileIdAndroid;     // Profile ID
  final bool? isOfferPersonalized;              // Personalized offer
  final String? purchaseToken;                  // Existing purchase token
  final int? offerTokenIndex;                   // Offer token index
  final int? prorationMode;                     // Proration mode

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
```

## Product Types

### IapItem

Represents a product available for purchase.

```dart
class IapItem {
  final String? productId;                              // Product identifier
  final String? price;                                  // Price as string
  final String? currency;                               // Currency code
  final String? localizedPrice;                         // Localized price string
  final String? title;                                  // Product title
  final String? description;                            // Product description
  final String? introductoryPrice;                      // Intro price

  // iOS-specific fields
  final String? subscriptionPeriodNumberIOS;           // Subscription period number
  final String? subscriptionPeriodUnitIOS;             // Subscription period unit
  final String? introductoryPriceNumberIOS;            // Intro price number
  final String? introductoryPricePaymentModeIOS;       // Intro payment mode
  final String? introductoryPriceNumberOfPeriodsIOS;   // Intro periods count
  final String? introductoryPriceSubscriptionPeriodIOS; // Intro period
  final List<DiscountIOS>? discountsIOS;               // Available discounts

  // Android-specific fields
  final String? signatureAndroid;                       // Purchase signature
  final List<SubscriptionOfferAndroid>? subscriptionOffersAndroid; // Subscription offers
  final String? subscriptionPeriodAndroid;             // Subscription period

  final String? iconUrl;                                // Product icon URL
  final String? originalJson;                           // Original platform JSON
  final String originalPrice;                           // Original price
}
```

### DiscountIOS

iOS promotional discount information.

```dart
class DiscountIOS {
  final String? identifier;            // Discount identifier
  final String? type;                   // Discount type
  final String? numberOfPeriods;       // Number of periods
  final double? price;                  // Discount price
  final String? localizedPrice;        // Localized price
  final String? paymentMode;           // Payment mode
  final String? subscriptionPeriod;    // Subscription period

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
```

### SubscriptionOfferAndroid

Android subscription offer details.

```dart
class SubscriptionOfferAndroid {
  final String sku;                              // Product SKU
  final String offerToken;                       // Offer token
  final String? offerId;                         // Offer ID
  final String? basePlanId;                      // Base plan ID
  final List<PricingPhaseAndroid>? pricingPhases; // Pricing phases

  SubscriptionOfferAndroid({
    required this.sku,
    required this.offerToken,
    this.offerId,
    this.basePlanId,
    this.pricingPhases,
  });
}
```

## Purchase Types

### Purchase

Represents a completed purchase (unified across iOS and Android).

```dart
class Purchase {
  // Common fields
  final String productId;                         // Product identifier (SKU)
  final String? transactionId;                    // Transaction ID (legacy id)
  final int? transactionDate;                     // Timestamp (ms)
  final String? transactionReceipt;               // Receipt payload
  final String? purchaseToken;                    // JWS (iOS) or purchase token (Android)

  // iOS-specific fields
  final String? originalTransactionIdentifierIOS; // Original transaction ID
  final String? originalTransactionDateIOS;       // Original transaction date (string)
  final TransactionState? transactionStateIOS;    // Transaction state
  final String? jwsRepresentationIOS;             // [DEPRECATED] Use purchaseToken

  // Android-specific fields
  final String? dataAndroid;                      // Raw purchase data
  final String? signatureAndroid;                 // Signature
  final bool? autoRenewingAndroid;                // Auto-renewing status
  final bool? isAcknowledgedAndroid;              // Acknowledgment status
  final int? purchaseStateAndroid;                // Purchase state
  final String? purchaseTokenAndroid;             // [DEPRECATED] Use purchaseToken
}
```

### PurchaseError

Detailed error information for failed purchases.

```dart
class PurchaseError implements Exception {
  final String name;                // Error name
  final String message;             // Error message
  final int? responseCode;          // Platform response code
  final String? debugMessage;       // Debug information
  final ErrorCode? code;            // Standardized error code
  final String? productId;          // Related product ID
  final IAPPlatform? platform;      // Platform where error occurred

  PurchaseError({
    String? name,
    required this.message,
    this.responseCode,
    this.debugMessage,
    this.code,
    this.productId,
    this.platform,
  });
}
```

### PurchaseResult

Legacy purchase result structure (deprecated in favor of PurchaseError).

```dart
class PurchaseResult {
  final int? responseCode;              // Response code
  final String? debugMessage;           // Debug message
  final String? code;                   // Error code
  final String? message;                // Error message
  final String? purchaseTokenAndroid;   // Android purchase token

  PurchaseResult({
    this.responseCode,
    this.debugMessage,
    this.code,
    this.message,
    this.purchaseTokenAndroid,
  });
}
```

## Enums

### PurchaseType

Product purchase types.

```dart
enum PurchaseType {
  inapp,    // One-time purchases
  subs      // Subscriptions
}
```

### ErrorCode

Standardized error codes across platforms.

```dart
enum ErrorCode {
  Unknown,                           // Unknown error
  UserCancelled,                     // User cancelled
  UserError,                         // User error
  ItemUnavailable,                   // Item unavailable
  ProductNotAvailable,               // Product unavailable on this store
  ProductAlreadyOwned,               // Product already purchased on Google Play
  ReceiptFinished,                   // Receipt completed successfully
  AlreadyOwned,                      // Product already owned (legacy mapping)
  NetworkError,                      // Network error
  ServiceError,                      // Store service error
  RemoteError,                       // Remote server error
  ReceiptFailed,                     // Receipt validation failed
  Pending,                           // Purchase pending
  NotEnded,                          // Transaction not ended
  DeveloperError,                    // Developer integration error
  ReceiptFinishedFailed,             // Receipt finish failed
  NotPrepared,                       // Billing not prepared
  BillingResponseJsonParseError,     // JSON parse error
  DeferredPayment,                   // Deferred payment (awaiting approval)
  Interrupted,                       // Flow interrupted
  IapNotAvailable,                   // IAP not available on device
  PurchaseError,                     // Generic purchase error
  SyncError,                         // Synchronization error
  TransactionValidationFailed,       // Transaction validation failed
  ActivityUnavailable,               // Required activity unavailable (Android)
  AlreadyPrepared,                   // Billing client already prepared
  ConnectionClosed,                  // Connection closed unexpectedly
  BillingUnavailable,                // Billing unavailable on device
  PurchaseNotAllowed,                // Purchase not allowed for user
  QuotaExceeded,                     // Subscription quota exceeded
  FeatureNotSupported,               // Feature not supported
  NotInitialized,                    // Module not initialized
  AlreadyInitialized,                // Module already initialized
  ClientInvalid,                     // iOS client invalid
  PaymentInvalid,                    // Payment information invalid
  PaymentNotAllowed,                 // Payment not allowed for user
  StorekitOriginalTransactionIdNotFound, // Original transaction ID missing
  NotSupported,                      // Operation not supported
  TransactionFailed,                 // Transaction failed
  TransactionInvalid,                // Transaction invalid
  ProductNotFound,                   // Product not found
  PurchaseFailed,                    // Purchase failed
  TransactionNotFound,               // Transaction not found
  RestoreFailed,                     // Restore operation failed
  RedeemFailed,                      // Code redemption failed
  NoWindowScene,                     // No window scene available (iOS)
  ShowSubscriptionsFailed,           // Unable to open subscriptions UI
  ProductLoadFailed,                 // Failed to load products
}
```

### IAPPlatform

Platform enumeration.

```dart
enum IAPPlatform {
  ios,      // iOS platform
  android   // Android platform
}
```

### TransactionState

iOS transaction states.

```dart
enum TransactionState {
  purchasing,   // Transaction in progress
  purchased,    // Transaction completed
  failed,       // Transaction failed
  restored,     // Transaction restored
  deferred      // Transaction deferred
}
```

### PurchaseState

Android purchase states.

```dart
enum PurchaseState {
  pending,      // Purchase pending
  purchased,    // Purchase completed
  unspecified   // Unspecified state
}
```

## Platform-Specific Types

### PaymentDiscount (iOS)

iOS promotional offer configuration.

```dart
class PaymentDiscount {
  final String identifier;      // Offer identifier
  final String keyIdentifier;   // Key identifier
  final String nonce;           // Nonce value
  final String signature;       // Signature
  final int timestamp;          // Timestamp

  PaymentDiscount({
    required this.identifier,
    required this.keyIdentifier,
    required this.nonce,
    required this.signature,
    required this.timestamp,
  });
}
```

### PricingPhaseAndroid

Android subscription pricing phase.

```dart
class PricingPhaseAndroid {
  String? price;              // Price
  String? formattedPrice;     // Formatted price
  String? billingPeriod;      // Billing period
  String? currencyCode;       // Currency code
  int? recurrenceMode;        // Recurrence mode
  int? billingCycleCount;     // Billing cycle count
}
```

## Utility Types

### ConnectionResult

Connection establishment result.

```dart
class ConnectionResult {
  final bool connected;       // Connection status
  final String? message;      // Connection message

  ConnectionResult({
    required this.connected,
    this.message,
  });
}
```

### IAPConfig

IAP configuration options.

```dart
class IAPConfig {
  final bool autoFinishTransactions;     // Auto-finish transactions
  final bool enablePendingPurchases;     // Enable pending purchases
  final Duration? connectionTimeout;     // Connection timeout
  final bool validateReceipts;           // Validate receipts

  const IAPConfig({
    this.autoFinishTransactions = true,
    this.enablePendingPurchases = true,
    this.connectionTimeout,
    this.validateReceipts = false,
  });
}
```

## Type Guards

Utility functions for type checking.

```dart
// Check if props use platform-specific format
bool isPlatformRequestProps(dynamic props);

// Check if props use unified format
bool isUnifiedRequestProps(dynamic props);

// Get current platform
IAPPlatform getCurrentPlatform();
```

## Platform Differences

### Key Type Differences

| Feature           | iOS                                      | Android                                          |
| ----------------- | ---------------------------------------- | ------------------------------------------------ |
| Product IDs       | Single `sku` string                      | Array of `skus`                                  |
| Purchase Token    | **Unified `purchaseToken`** (JWS format) | **Unified `purchaseToken`** (Google Play format) |
| Transaction State | `TransactionState` enum                  | `PurchaseState` enum                             |
| Error Handling    | Integer codes                            | String codes                                     |
| Discounts         | `DiscountIOS` objects                    | `SubscriptionOfferAndroid`                       |
| Transaction IDs   | Large numbers (e.g., `2000000985615347`) | String format (e.g., `GPA.1234-5678-9012`)       |

### Platform-Specific Fields

**iOS Only:**

- `originalTransactionIdentifierIOS`
- `transactionStateIOS`
- `discountsIOS`
- `subscriptionPeriodUnitIOS`
- `jwsRepresentationIOS` ⚠️ **DEPRECATED** - Use `purchaseToken` instead

**Android Only:**

- `dataAndroid`
- `signatureAndroid`
- `isAcknowledgedAndroid`
- `purchaseStateAndroid`
- `purchaseTokenAndroid` ⚠️ **DEPRECATED** - Use `purchaseToken` instead

**Cross-Platform:**

- `purchaseToken` - Unified field containing iOS JWS or Android purchase token

## Migration Notes

⚠️ **Breaking Changes from v5.x:**

1. **Request Objects**: Now use `RequestPurchase` instead of string parameters
2. **Error Types**: `PurchaseError` replaces legacy error handling
3. **Type Safety**: All optional fields are properly nullable
4. **Platform Separation**: Clear distinction between iOS and Android types

✨ **New in v6.8.0:**

1. **Simplified fetchProducts result** – `fetchProducts` now directly returns
   a list of products based on the query type, no more union types or helper
   extensions needed.

2. **Typed ProductRequest input** – Catalog queries take a
   `ProductRequest(skus: [...], type: ProductQueryType.InApp|Subs)`. This keeps
   Dart in sync with the OpenIAP GraphQL schema and prevents invalid "all"
   queries.

3. **PurchaseOptions parity** – `PurchaseOptions` unifies
   `getAvailablePurchases()` flags across platforms, adding the
   `alsoPublishToEventListenerIOS` toggle for StoreKit event mirroring.

## See Also

- [Core Methods](./core-methods.md) - Using these types in method calls
- [Error Codes](./error-codes.md) - Detailed error handling
- [Migration Guide](../migration/from-v5.md) - Upgrading from v5.x
