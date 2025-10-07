---
sidebar_position: 2
title: fetchProducts
---

# fetchProducts()

`fetchProducts()` is the unified way to load in-app products or subscriptions from the store, consolidating the legacy helpers into a single API.

## Signature

```dart
Future<List<dynamic>> fetchProducts({
  required List<String> skus,
  ProductQueryType type = ProductQueryType.InApp,
})
```

## Parameters

| Parameter | Type                | Required | Description                                                                          |
| --------- | ------------------- | -------- | ------------------------------------------------------------------------------------ |
| `skus`    | `List<String>`      | ✅       | Store identifiers to query (Google Play product IDs / App Store product identifiers) |
| `type`    | `ProductQueryType` | ❌       | `ProductQueryType.InApp` (default), `ProductQueryType.Subs`, or `ProductQueryType.All` |

## Return Value

Returns a dynamically-typed list. **Always use explicit type annotation** for proper type inference:

- **InApp**: Use `List<Product>` annotation
- **Subs**: Use `List<ProductSubscription>` annotation
- **All**: Use `List<ProductCommon>` annotation

## Usage Examples

### Fetch in-app products

```dart
// Use explicit type annotation
final List<Product> products = await FlutterInappPurchase.instance.fetchProducts(
  skus: ['coins_100', 'remove_ads'],
  type: ProductQueryType.InApp,
);

for (final product in products) {
  print('${product.title}: ${product.displayPrice}');
}
```

### Fetch subscriptions

```dart
// Use explicit type annotation
final List<ProductSubscription> subscriptions =
    await FlutterInappPurchase.instance.fetchProducts(
  skus: ['premium_monthly', 'premium_yearly'],
  type: ProductQueryType.Subs,
);

for (final sub in subscriptions) {
  print('${sub.title}: ${sub.displayPrice}');
  print('Period: ${sub.subscriptionPeriodUnitIOS ?? sub.subscriptionInfoAndroid?.billingPeriod}');
}
```

### Fetch both types

```dart
Future<void> loadCatalog() async {
  // Use explicit type annotation
  final List<Product> inAppProducts =
      await FlutterInappPurchase.instance.fetchProducts(
    skus: ['coins_100', 'remove_ads'],
    type: ProductQueryType.InApp,
  );

  final List<ProductSubscription> subscriptions =
      await FlutterInappPurchase.instance.fetchProducts(
    skus: ['premium_monthly'],
    type: ProductQueryType.Subs,
  );

  // Combine into a single list if needed
  final List<ProductCommon> allProducts = [
    ...inAppProducts,
    ...subscriptions,
  ];

  for (final item in allProducts) {
    debugPrint('Loaded ${item.id} (${item.displayPrice})');
  }
}
```

### Fetch all products at once

```dart
// Query all products together
final List<ProductCommon> allProducts =
    await FlutterInappPurchase.instance.fetchProducts(
  skus: ['coins_100', 'remove_ads', 'premium_monthly'],
  type: ProductQueryType.All,
);

for (final item in allProducts) {
  debugPrint('Loaded ${item.id} (${item.displayPrice})');
}
```

## Error Handling

```dart
try {
  final List<Product> products =
      await FlutterInappPurchase.instance.fetchProducts(
    skus: productIds,
    type: ProductQueryType.InApp,
  );

  if (products.isEmpty) {
    debugPrint('No products returned for: $productIds');
  }
} on PurchaseError catch (error) {
  switch (error.code) {
    case ErrorCode.NotPrepared:
      debugPrint('Call initConnection() before fetching products');
      break;
    case ErrorCode.NetworkError:
      debugPrint('Network error – prompt the user to retry');
      break;
    default:
      debugPrint('Unexpected store error: ${error.message}');
  }
}
```

## Platform Notes

### iOS

- Products must be visible in App Store Connect (Ready for Sale or Approved)
- The bundle identifier must match the app querying the products
- StoreKit 2 caching means results may be served from a local cache on subsequent calls

### Android

- Products must be active in Google Play Console (Internal Testing track or above)
- Billing client v8 requires the app to be signed with a certificate added to Play Console
- Only SKUs that belong to the current package can be queried

## Migration Notes

### From v6.x to v7.0

The API now requires explicit type annotation for proper type inference:

```dart
// Before (v6.x)
final result = await iap.fetchProducts(
  ProductRequest(
    skus: ['product_id'],
    type: ProductQueryType.InApp,
  ),
);
final products = result.value; // or result.products

// After (v7.0) - Use explicit type annotation
final List<Product> products = await iap.fetchProducts(
  skus: ['product_id'],
  type: ProductQueryType.InApp,
);

// For subscriptions
final List<ProductSubscription> subscriptions = await iap.fetchProducts(
  skus: ['sub_id'],
  type: ProductQueryType.Subs,
);
```

### Key Changes

- **No more `.value` or `.products` getters** - The method returns the list directly
- **Explicit type annotation required** - Use `List<Product>`, `List<ProductSubscription>`, or `List<ProductCommon>`
- **Simplified API** - Direct iteration without unwrapping union types

## Related APIs

- [`requestPurchase()`](./request-purchase) – Start the purchase flow
- [`getAvailablePurchases()`](./get-available-purchases) – Restore owned items
- [`fetchProducts()` helper extensions](../../guides/products#fetchproducts-helper-extensions)

## See Also

- [Products Guide](../../guides/products) – Designing product catalogs
- [Subscriptions Guide](../../guides/subscriptions) – Subscription-specific flows
- [Troubleshooting](../../troubleshooting) – Diagnostics for common failures
