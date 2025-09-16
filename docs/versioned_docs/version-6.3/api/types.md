---
title: Types
sidebar_position: 2
---

# Types

Comprehensive type definitions for flutter_inapp_purchase v6.0.0. All types are fully documented with TypeScript-style definitions for complete type safety.

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

### RequestProductsParams

Parameters for loading product information.

```dart
class RequestProductsParams {
  final List<String> skus;         // Product SKUs to load
  final PurchaseType type;         // Product type (inapp/subs)

  RequestProductsParams({
    required this.skus,
    required this.type,
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

### PurchasedItem

Represents a completed purchase.

```dart
class PurchasedItem {
  final String? productId;                        // Product identifier
  final String? transactionId;                    // Transaction ID
  final DateTime? transactionDate;                // Transaction date
  final String? transactionReceipt;               // Transaction receipt
  final String? purchaseToken;                    // Unified purchase token (iOS JWS or Android token)

  // Android-specific fields
  final String? dataAndroid;                      // Purchase data
  final String? signatureAndroid;                 // Purchase signature
  final bool? autoRenewingAndroid;               // Auto-renewing status
  final bool? isAcknowledgedAndroid;             // Acknowledgment status
  final PurchaseState? purchaseStateAndroid;     // Purchase state
  final String? purchaseTokenAndroid;            // [DEPRECATED] Use purchaseToken instead

  // iOS-specific fields
  final DateTime? originalTransactionDateIOS;     // Original transaction date
  final String? originalTransactionIdentifierIOS; // Original transaction ID
  final TransactionState? transactionStateIOS;   // Transaction state
  final String? jwsRepresentationIOS;            // [DEPRECATED] Use purchaseToken instead
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
  RemoteError,                       // Remote server error
  NetworkError,                      // Network error
  ServiceError,                      // Service error
  ReceiptFailed,                     // Receipt validation failed
  ReceiptFinishedFailed,             // Receipt finish failed
  NotPrepared,                       // Not prepared
  NotEnded,                          // Not ended
  AlreadyOwned,                      // Already owned
  DeveloperError,                    // Developer error
  BillingResponseJsonParseError,     // JSON parse error
  DeferredPayment,                   // Deferred payment
  Interrupted,                       // Interrupted
  IapNotAvailable,                   // IAP not available
  PurchaseError,                     // Purchase error
  SyncError,                         // Sync error
  TransactionValidationFailed,       // Transaction validation failed
  ActivityUnavailable,               // Activity unavailable
  AlreadyPrepared,                   // Already prepared
  Pending,                           // Pending
  ConnectionClosed,                  // Connection closed
  // Additional error codes...
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

✨ **New in v6.0.0:**

1. **Unified Purchase Token**: `purchaseToken` field now works consistently across platforms:

   - **iOS**: Contains JWS representation for server-side validation
   - **Android**: Contains Google Play purchase token
   - **Migration**: Replace `jwsRepresentationIOS` and `purchaseTokenAndroid` with `purchaseToken`

2. **Improved Transaction IDs**:

   - **Development**: Uses sequential IDs (1, 2, 3) with StoreKit Configuration
   - **Sandbox/Production**: Uses proper secure IDs (e.g., `2000000985615347`)

3. **Enhanced Error Handling**:
   - Unified error events across platforms following expo-iap patterns
   - Better duplicate event prevention

## See Also

- [Core Methods](./core-methods.md) - Using these types in method calls
- [Error Codes](./error-codes.md) - Detailed error handling
- [Migration Guide](../migration/from-v5.md) - Upgrading from v5.x
