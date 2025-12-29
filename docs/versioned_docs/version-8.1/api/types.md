---
title: Types
sidebar_position: 2
---

import IapKitBanner from "@site/src/uis/IapKitBanner";

# Types

<IapKitBanner />

Comprehensive type definitions for flutter_inapp_purchase v8.1. All types follow the OpenIAP specification and are auto-generated from the schema.

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
  final List<ProductSubscriptionAndroidOfferDetails>? subscriptionOfferDetails;
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
  Failed,       // Purchase failed
  Restored,     // Purchase restored
  Deferred,     // Purchase deferred (awaiting approval)
  Unknown,      // Unknown state
}
```

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
