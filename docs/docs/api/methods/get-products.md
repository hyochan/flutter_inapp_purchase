---
sidebar_position: 2
title: fetchProducts
---

# fetchProducts()

`fetchProducts()` is the unified way to load in-app products or subscriptions from the store, consolidating the legacy helpers into a single API.

## Signature

```dart
Future<FetchProductsResult> fetchProducts({
  required List<String> skus,
  ProductQueryType? type,
})
```

## Parameters

| Parameter | Type                | Required | Description                                                                          |
| --------- | ------------------- | -------- | ------------------------------------------------------------------------------------ |
| `skus`    | `List<String>`      | ✅       | Store identifiers to query (Google Play product IDs / App Store product identifiers) |
| `type`    | `ProductQueryType?` | ❌       | `ProductQueryType.InApp` (default) or `ProductQueryType.Subs`                        |

## Return Value

The method returns a `FetchProductsResult` union type:

**FetchProductsResultProducts:**

- Contains `.value` property with `List<Product>?` (nullable list)
- Returned for `ProductQueryType.InApp` queries

**FetchProductsResultSubscriptions:**

- Contains `.value` property with `List<ProductSubscription>?` (nullable list)
- Returned for `ProductQueryType.Subs` queries

**Important:** Always access the product list via the `.value` property:

```dart
final result = await fetchProducts(...);
final products = result.value ?? []; // Handle nullable list
```

## Usage Examples

### Fetch in-app products

```dart
final result = await FlutterInappPurchase.instance.fetchProducts(
  skus: ['coins_100', 'remove_ads'],
  type: ProductQueryType.InApp,
);

for (final product in result.value) {
  print('${product.title}: ${product.displayPrice}');
}
```

### Fetch subscriptions

```dart
final result = await FlutterInappPurchase.instance.fetchProducts(
  skus: ['premium_monthly', 'premium_yearly'],
  type: ProductQueryType.Subs,
);

for (final sub in result.value) {
  print('${sub.title}: ${sub.displayPrice}');
  print('Period: ${sub.subscriptionPeriodUnitIOS ?? sub.subscriptionInfoAndroid?.billingPeriod}');
}
```

### Fetch both types

```dart
Future<void> loadCatalog() async {
  final inAppsResult = await FlutterInappPurchase.instance.fetchProducts(
    skus: ['coins_100', 'remove_ads'],
    type: ProductQueryType.InApp,
  );
  final subsResult = await FlutterInappPurchase.instance.fetchProducts(
    skus: ['premium_monthly'],
    type: ProductQueryType.Subs,
  );

  final allProducts = [
    ...inAppsResult.value ?? [],
    ...subsResult.value ?? [],
  ];

  for (final item in allProducts) {
    debugPrint('Loaded ${item.id} (${item.displayPrice})');
  }
}
```

## Error Handling

```dart
try {
  final result = await FlutterInappPurchase.instance.fetchProducts(
    skus: productIds,
    type: ProductQueryType.InApp,
  );
  if (result.value.isEmpty) {
    debugPrint('No products returned for: $productIds');
  }
  if (result.invalidProductIds.isNotEmpty) {
    debugPrint('Invalid product IDs: ${result.invalidProductIds}');
  }
} on PurchaseError catch (error) {
  switch (error.code) {
    case 'E_NOT_PREPARED':
      debugPrint('Call initConnection() before fetching products');
      break;
    case 'E_NETWORK_ERROR':
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

```dart
// Before (v6.x)
final result = await iap.fetchProducts(
  ProductRequest(
    skus: ['product_id'],
    type: ProductQueryType.InApp,
  ),
);

// After (v7.0)
final result = await iap.fetchProducts(
  skus: ['product_id'],
  type: ProductQueryType.InApp,
);
```

### From legacy APIs

- Replace `requestProducts()` calls with `fetchProducts()`
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
