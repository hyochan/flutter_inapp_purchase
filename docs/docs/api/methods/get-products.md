---
sidebar_position: 2
title: requestProducts
---

# requestProducts()

Fetches product or subscription information with unified API (v6.7.0+).

## Overview

The `requestProducts()` method fetches product information for the specified store SKUs from the App Store (iOS) or Google Play Store (Android). This replaces the deprecated `getProducts()` and `getSubscriptions()` methods with a unified API that uses a type parameter to distinguish between regular products and subscriptions.

## Signature

```dart
Future<List<ProductCommon>> requestProducts({
  required List<String> skus,
  PurchaseType type = PurchaseType.inapp,
})
```

## Parameters

| Parameter | Type           | Required | Default   | Description                                                                |
| --------- | -------------- | -------- | --------- | -------------------------------------------------------------------------- |
| `skus` | `List<String>` | Yes      | -         | List of store product identifiers to fetch                                |
| `type`    | `PurchaseType` | No       | `PurchaseType.inapp` | Product type: `PurchaseType.inapp` (regular) or `PurchaseType.subs` (subscriptions) |

## Returns

- **Type**: `Future<List<ProductCommon>>`
- **Description**: A list of product items with pricing and metadata

## Usage Examples

### Fetch Regular Products

```dart
try {
  List<ProductCommon> products = await FlutterInappPurchase.instance.requestProducts(
    skus: ['coins_100', 'coins_500', 'remove_ads'],
    type: PurchaseType.inapp,
  );

  for (var product in products) {
    print('Product: ${product.title}');
    print('Price: ${product.displayPrice}');
    print('Currency: ${product.currency}');
  }
} catch (e) {
  print('Failed to fetch products: $e');
}
```

### Fetch Subscriptions

```dart
try {
  List<ProductCommon> subscriptions = await FlutterInappPurchase.instance.requestProducts(
    skus: ['premium_monthly', 'premium_yearly'],
    type: PurchaseType.subs,
  );

  for (var subscription in subscriptions) {
    print('Subscription: ${subscription.title}');
    print('Price: ${subscription.displayPrice}');
    print('Description: ${subscription.description}');
  }
} catch (e) {
  print('Failed to fetch subscriptions: $e');
}
```

### Combined Example

```dart
class ProductService {
  Future<void> loadAllProducts() async {
    try {
      // Load regular products
      final products = await FlutterInappPurchase.instance.requestProducts(
        skus: ['coins_100', 'remove_ads'],
        type: PurchaseType.inapp,
      );

      // Load subscriptions
      final subscriptions = await FlutterInappPurchase.instance.requestProducts(
        skus: ['premium_monthly', 'premium_yearly'],
        type: PurchaseType.subs,
      );

      print('Loaded ${products.length} products');
      print('Loaded ${subscriptions.length} subscriptions');

    } catch (e) {
      print('Error loading products: $e');
    }
  }
}
```

## Product Types

### 'inapp' Type

- **Consumables**: Items that can be purchased multiple times (coins, gems)
- **Non-consumables**: Items purchased once and owned forever (remove ads, premium features)

### 'subs' Type

- **Auto-renewable subscriptions**: Recurring subscriptions with automatic renewal
- **Non-renewing subscriptions**: Fixed-duration subscriptions without auto-renewal

## Error Handling

```dart
try {
  final products = await FlutterInappPurchase.instance.requestProducts(
    skus: productIds,
    type: PurchaseType.inapp,
  );

  if (products.isEmpty) {
    print('No products found for the given SKUs');
  }

} catch (e) {
  if (e.toString().contains('E_NOT_PREPARED')) {
    print('Store not initialized');
  } else if (e.toString().contains('E_NETWORK')) {
    print('Network error - check internet connection');
  } else {
    print('Unknown error: $e');
  }
}
```

## Platform Differences

### iOS

- Products must be configured in App Store Connect
- Products must be in "Ready to Submit" or "Approved" status
- Bundle ID must match exactly

### Android

- Products must be active in Google Play Console
- App must be uploaded to at least Internal Testing
- Package name must match exactly

## Migration from Old API

### Before (Deprecated)

```dart
// Old separate methods
final products = await FlutterInappPurchase.instance.getProducts(productIds);
final subscriptions = await FlutterInappPurchase.instance.getSubscriptions(subscriptionIds);
```

### After (Recommended)

```dart
// New unified method
final products = await FlutterInappPurchase.instance.requestProducts(
  skus: productIds,
  type: PurchaseType.inapp,
);

final subscriptions = await FlutterInappPurchase.instance.requestProducts(
  skus: subscriptionIds,
  type: PurchaseType.subs,
);
```

## Best Practices

1. **Cache Results**: Store product information to reduce API calls
2. **Handle Empty Results**: Always check if the returned list is empty
3. **Error Recovery**: Implement retry logic for network failures
4. **Type Safety**: Use the correct type parameter for your products
5. **SKU Validation**: Ensure SKUs match exactly with store configuration

## Related Methods

- [`requestPurchase()`](./request-purchase) - Request a product purchase
- [`requestSubscription()`](./request-subscription) - Request a subscription purchase
- [`getAvailablePurchases()`](./get-available-purchases) - Get user's current purchases

## See Also

- [Products Guide](../../guides/products) - Detailed product implementation guide
- [Subscriptions Guide](../../guides/subscriptions) - Subscription-specific implementation
- [Troubleshooting](../../troubleshooting) - Common issues and solutions
