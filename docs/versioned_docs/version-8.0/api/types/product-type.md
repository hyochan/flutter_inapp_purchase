---
sidebar_position: 1
title: Product Types
---

import IapKitBanner from "@site/src/uis/IapKitBanner";

# Product Types

<IapKitBanner />

Types and enums related to products and purchases in flutter_inapp_purchase.

## ProductQueryType

Enum representing the type of product to query.

```dart
enum ProductQueryType {
  InApp,  // One-time purchases (consumable and non-consumable)
  Subs    // Subscription products
}
```

### Usage

```dart
// Query in-app products
final products = await iap.fetchProducts(
  skus: ['product_id'],
  type: ProductQueryType.InApp,
);

// Query subscriptions
final subscriptions = await iap.fetchProducts(
  skus: ['subscription_id'],
  type: ProductQueryType.Subs,
);
```

## ProductType

Enum representing the product type.

```dart
enum ProductType {
  InApp,
  Subs,
}
```

## Product Classes

flutter_inapp_purchase uses union types for products. When you fetch products, you receive platform-specific product types.

### ProductIOS

iOS-specific product type.

```dart
class ProductIOS extends Product {
  final String id;
  final String displayName;
  final String description;
  final double price;
  final String displayPrice;
  final ProductTypeIOS type;
  final SubscriptionInfoIOS? subscription;
  // ... additional iOS-specific properties
}
```

### ProductAndroid

Android-specific product type.

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

iOS-specific subscription product.

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

Android-specific subscription product.

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

## FetchProducts Result

When fetching products, the result is a union type:

```dart
// For InApp products
class FetchProductsResultProducts extends FetchProductsResult {
  final List<Product> products; // List of ProductIOS or ProductAndroid
}

// For Subscriptions
class FetchProductsResultSubscriptions extends FetchProductsResult {
  final List<ProductSubscription> subscriptions; // List of subscription products
}
```

### Usage

```dart
final result = await iap.fetchProducts(
  skus: ['product_id'],
  type: ProductQueryType.InApp,
);

if (result is FetchProductsResultProducts) {
  for (final product in result.products) {
    if (product is ProductIOS) {
      debugPrint('iOS Product: ${product.displayName}');
    } else if (product is ProductAndroid) {
      debugPrint('Android Product: ${product.title}');
    }
  }
}
```

## PurchaseOptions

Configuration for `getAvailablePurchases()`.

```dart
class PurchaseOptions {
  final bool? onlyIncludeActiveItemsIOS;
  final bool? alsoPublishToEventListenerIOS;
}
```

### Example

```dart
final purchases = await iap.getAvailablePurchases(
  onlyIncludeActiveItemsIOS: true,  // Only active subscriptions
  alsoPublishToEventListenerIOS: false,
);
```

## ProductRequest

Request configuration for fetching products.

```dart
class ProductRequest {
  final List<String> skus;
  final ProductQueryType? type;
}
```

### Example

```dart
final products = await iap.fetchProducts(
  skus: ['product1', 'product2'],
  type: ProductQueryType.InApp,
);
```
