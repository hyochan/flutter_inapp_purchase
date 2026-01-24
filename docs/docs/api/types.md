---
title: Types
sidebar_position: 2
---

import IapKitBanner from "@site/src/uis/IapKitBanner";

# Types

<IapKitBanner />

Comprehensive type definitions for flutter_inapp_purchase v8.2. All types follow the OpenIAP specification and are auto-generated from the schema.

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
  final String? appAccountToken;                                      // App account token (must be UUID format)
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

flutter_inapp_purchase uses union types for products. Products are platform-specific and auto-generated from the OpenIAP schema.

### Product (Union Type)

The base `Product` type is implemented by platform-specific classes:

- `ProductIOS` - iOS in-app products
- `ProductAndroid` - Android in-app products
- `ProductSubscriptionIOS` - iOS subscriptions
- `ProductSubscriptionAndroid` - Android subscriptions

### ProductIOS

```dart
class ProductIOS extends Product {
  final String id;
  final String displayName;
  final String description;
  final double price;
  final String displayPrice;
  final ProductTypeIOS type;
  final SubscriptionInfoIOS? subscription;
  final bool isFamilyShareable;
  // ... additional iOS-specific properties
}
```

### ProductAndroid

```dart
class ProductAndroid extends Product {
  final String productId;
  final ProductType productType;
  final String title;
  final String name;
  final String description;
  final ProductAndroidOneTimePurchaseOfferDetail? oneTimePurchaseOfferDetails;
  // ... additional Android-specific properties
}
```

### ProductSubscriptionIOS

```dart
class ProductSubscriptionIOS extends ProductSubscription {
  final String id;
  final String displayName;
  final String description;
  final double price;
  final String displayPrice;
  final SubscriptionInfoIOS subscription;
  final List<SubscriptionOfferIOS>? subscriptionOffers;
  // ... additional iOS subscription properties
}
```

### ProductSubscriptionAndroid

```dart
class ProductSubscriptionAndroid extends ProductSubscription {
  final String productId;
  final String title;
  final String name;
  final String description;
  final List<ProductSubscriptionAndroidOfferDetails>? subscriptionOfferDetailsAndroid;
  // ... additional Android subscription properties
}
```

See [Product Types](./types/product-type) for detailed documentation.

## Purchase Types

flutter_inapp_purchase uses union types for purchases. Purchases are platform-specific.

### Purchase (Union Type)

The base `Purchase` type is implemented by platform-specific classes:

- `PurchaseIOS` - iOS purchases
- `PurchaseAndroid` - Android purchases

### PurchaseIOS

```dart
class PurchaseIOS extends Purchase {
  final String id;
  final String originalId;
  final String productId;
  final DateTime purchaseDate;
  final PurchaseState transactionState;
  final String? receiptData;
  final int? quantity;
  // ... additional iOS-specific properties
}
```

### PurchaseAndroid

```dart
class PurchaseAndroid extends Purchase {
  final String? orderId;
  final String productId;
  final PurchaseState purchaseState;
  final int purchaseTime;
  final String purchaseToken;
  final bool acknowledged;
  final bool autoRenewing;
  // ... additional Android-specific properties
}
```

See [Purchase States](./types/purchase-state) for detailed documentation.

### PurchaseError

Error information for failed purchases.

```dart
class PurchaseError {
  final ErrorCode code;
  final String message;
  final String? debugMessage;
  final String? productId;
}
```

See [Error Codes](./types/error-codes) for detailed documentation.

## Enums

### ProductQueryType

Product query types for fetching products.

```dart
enum ProductQueryType {
  InApp,  // One-time purchases
  Subs    // Subscriptions
}
```

### ProductType

Product types.

```dart
enum ProductType {
  InApp,
  Subs,
}
```

### PurchaseState

Purchase states (unified across platforms).

```dart
enum PurchaseState {
  Pending,      // Purchase pending
  Purchased,    // Purchase completed
  Unknown,      // Unknown state
}
```

:::info Breaking Change in v8.2.0
`Failed`, `Restored`, and `Deferred` states have been removed:
- **Failed**: Both platforms return errors instead of Purchase objects on failure
- **Restored**: Restored purchases now return as `Purchased` state
- **Deferred**: iOS StoreKit 2 has no transaction state; Android uses `Pending`
:::

### ErrorCode

Error codes for purchase errors. See [Error Codes](./types/error-codes) for complete list.

```dart
enum ErrorCode {
  Unknown,
  UserCancelled,
  ItemUnavailable,
  NetworkError,
  ServiceError,
  AlreadyOwned,
  // ... see Error Codes documentation for full list
}
```

### IapPlatform

Platform enumeration.

```dart
enum IapPlatform {
  IOS,      // iOS platform
  Android   // Android platform
}
```

## Standardized Offer Types

:::tip New in v8.3+
These cross-platform types replace the deprecated platform-specific offer types (`SubscriptionOfferIOS`, `ProductSubscriptionAndroidOfferDetails`). Use these for cross-platform compatibility.
:::

### SubscriptionOffer

Cross-platform subscription offer type (introductory offers, promotional offers).

```dart
class SubscriptionOffer {
  final String id;                                    // Unique offer identifier
  final String displayPrice;                          // Formatted price string
  final double price;                                 // Numeric price value
  final String? currency;                             // ISO 4217 currency code
  final DiscountOfferType type;                       // Introductory or Promotional
  final PaymentMode? paymentMode;                     // How user pays during offer
  final SubscriptionPeriod? period;                   // Billing period
  final int? periodCount;                             // Number of billing periods

  // Android-specific fields
  final String? basePlanIdAndroid;                    // Android base plan ID
  final String? offerTokenAndroid;                    // Token for purchase
  final List<String>? offerTagsAndroid;              // Offer tags
  final PricingPhasesAndroid? pricingPhasesAndroid;  // Pricing phases

  // iOS-specific fields
  final String? keyIdentifierIOS;                     // Signature validation key
  final String? nonceIOS;                             // Cryptographic nonce
  final String? signatureIOS;                         // Server-generated signature
  final double? timestampIOS;                         // Signature timestamp
  final String? localizedPriceIOS;                    // Localized price string
  final int? numberOfPeriodsIOS;                      // Number of periods
}
```

### DiscountOffer

Cross-platform one-time product discount (Android Google Play Billing 7.0+).

```dart
class DiscountOffer {
  final String? id;                                   // Unique offer identifier
  final String displayPrice;                          // Formatted price string
  final double price;                                 // Numeric price value
  final String currency;                              // ISO 4217 currency code
  final DiscountOfferType type;                       // Discount type

  // Android-specific fields
  final String? offerTokenAndroid;                    // Token for purchase
  final List<String>? offerTagsAndroid;              // Offer tags
  final String? fullPriceMicrosAndroid;              // Original price in micro-units
  final int? percentageDiscountAndroid;              // Percentage discount
  final String? discountAmountMicrosAndroid;         // Fixed discount amount
  final String? formattedDiscountAmountAndroid;      // Formatted discount string
  final ValidTimeWindowAndroid? validTimeWindowAndroid; // Valid time window
  final LimitedQuantityInfoAndroid? limitedQuantityInfoAndroid; // Quantity limits
  final PreorderDetailsAndroid? preorderDetailsAndroid; // Pre-order info
  final RentalDetailsAndroid? rentalDetailsAndroid;  // Rental details
}
```

### DiscountOfferType

Type of discount/subscription offer.

```dart
enum DiscountOfferType {
  Introductory,  // New subscriber discount
  Promotional,   // Existing subscriber discount
  OneTime,       // One-time product discount (Android only)
}
```

### PaymentMode

How the user pays during an offer period.

```dart
enum PaymentMode {
  FreeTrial,     // No charge during offer (price = 0)
  PayAsYouGo,    // Reduced price per period (recurring)
  PayUpFront,    // Discounted amount upfront (non-recurring)
  Unknown,       // Unknown or unspecified
}
```

### SubscriptionPeriod

Billing period for subscription offers.

```dart
class SubscriptionPeriod {
  final SubscriptionPeriodUnit unit;  // Period unit (day, week, month, year)
  final int value;                     // Number of units (e.g., 1 for monthly)
}

enum SubscriptionPeriodUnit {
  Day,
  Week,
  Month,
  Year,
  Unknown,
}
```

### Using Standardized Offers

Products now include both legacy and standardized offer fields:

```dart
// Access standardized offers (recommended)
final product = await fetchProducts(['subscription_id']);
if (product is ProductSubscriptionAndroid) {
  final offers = product.subscriptionOffers;
  for (final offer in offers ?? []) {
    print('Offer: ${offer.id}');
    print('Price: ${offer.displayPrice}');
    print('Type: ${offer.type}');
    print('Payment Mode: ${offer.paymentMode}');
  }
}

// Legacy access (deprecated but still available)
final legacyOffers = product.subscriptionOfferDetailsAndroid;
```

## Additional Types

### ActiveSubscription

Lightweight subscription status information.

```dart
class ActiveSubscription {
  final String productId;
  final bool isActive;
  final DateTime? expirationDate;
}
```

Returned by `getActiveSubscriptions()` for lightweight subscription checks.

### PurchaseOptions

Options for `getAvailablePurchases()`.

```dart
class PurchaseOptions {
  final bool? onlyIncludeActiveItemsIOS;
  final bool? alsoPublishToEventListenerIOS;
}
```

### ProductRequest

Request configuration for fetching products.

```dart
class ProductRequest {
  final List<String> skus;
  final ProductQueryType? type;
}
```

## Request Purchase Types

### RequestPurchaseProps

Base class for purchase requests. Use factory constructors:

```dart
// In-app purchase
RequestPurchaseProps.inApp(
  request: RequestPurchasePropsByPlatforms(...),
)

// Subscription purchase
RequestPurchaseProps.subs(
  request: RequestPurchasePropsByPlatforms(...),
)
```

### RequestPurchasePropsByPlatforms

Platform-specific purchase request props.

```dart
class RequestPurchasePropsByPlatforms {
  final RequestPurchaseIosProps? ios;
  final RequestPurchaseAndroidProps? android;
}
```

## Type Generation

All types in `lib/types.dart` are auto-generated from the OpenIAP schema. **Do not edit manually**.

To regenerate types:

```bash
./scripts/generate-type.sh
```

## See Also

- [Product Types](./types/product-type) - Detailed product type documentation
- [Purchase States](./types/purchase-state) - Purchase state documentation
- [Error Codes](./types/error-codes) - Error code documentation
- [Migration Guide](../migration/from-v6) - Upgrading from v6.x
