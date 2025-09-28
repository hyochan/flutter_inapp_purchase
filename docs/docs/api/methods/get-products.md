---
sidebar_position: 2
title: fetchProducts
---

# fetchProducts()

`fetchProducts()` is the unified way to load in-app products or subscriptions from the store, consolidating the legacy helpers into a single API.

## Signature

```dart
Future<List<Product>> fetchProducts(ProductRequest params)
```

## Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `params.skus` | `List<String>` | ✅ | Store identifiers to query (Google Play product IDs / App Store product identifiers) |
| `params.type` | `ProductQueryType?` | ❌ | `ProductQueryType.InApp` (default) or `ProductQueryType.Subs` |

## Return Value

The method resolves to a `List<Product>` containing the requested products:

- For `ProductQueryType.InApp`: returns a list of in-app products
- For `ProductQueryType.Subs`: returns a list of subscription products

## Usage Examples

### Fetch in-app products

```dart
final products = await FlutterInappPurchase.instance.fetchProducts(
  ProductRequest(
    skus: ['coins_100', 'remove_ads'],
    type: ProductQueryType.InApp,
  ),
);
for (final product in products) {
  print('${product.title}: ${product.displayPrice}');
}
```

### Fetch subscriptions

```dart
final subscriptions = await FlutterInappPurchase.instance.fetchProducts(
  ProductRequest(
    skus: ['premium_monthly', 'premium_yearly'],
    type: ProductQueryType.Subs,
  ),
);
for (final sub in subscriptions) {
  print('${sub.title}: ${sub.displayPrice}');
  print('Period: ${sub.subscriptionPeriodUnitIOS ?? sub.subscriptionInfoAndroid?.billingPeriod}');
}
```

### Fetch both types

```dart
Future<void> loadCatalog() async {
  final inApps = await FlutterInappPurchase.instance.fetchProducts(
    ProductRequest(skus: ['coins_100', 'remove_ads'], type: ProductQueryType.InApp),
  );
  final subs = await FlutterInappPurchase.instance.fetchProducts(
    ProductRequest(skus: ['premium_monthly'], type: ProductQueryType.Subs),
  );

  final allProducts = [
    ...inApps,
    ...subs,
  ];

  for (final item in allProducts) {
    debugPrint('Loaded ${item.id} (${item.displayPrice})');
  }
}
```

## Error Handling

```dart
try {
  final products = await FlutterInappPurchase.instance.fetchProducts(
    ProductRequest(skus: productIds, type: ProductQueryType.InApp),
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

- Replace `requestProducts()` calls with `fetchProducts(ProductRequest(...))`
- Convert the returned `FetchProductsResult` using `inAppProducts()`, `subscriptionProducts()`, or `allProducts()` depending on the query type
- Replace any legacy product-loading helpers in your codebase with `fetchProducts()`

## Related APIs

- [`requestPurchase()`](./request-purchase) – Start the purchase flow
- [`getAvailablePurchases()`](./get-available-purchases) – Restore owned items
- [`fetchProducts()` helper extensions](../../guides/products#fetchproducts-helper-extensions)

## See Also

- [Products Guide](../../guides/products) – Designing product catalogs
- [Subscriptions Guide](../../guides/subscriptions) – Subscription-specific flows
- [Troubleshooting](../../troubleshooting) – Diagnostics for common failures
