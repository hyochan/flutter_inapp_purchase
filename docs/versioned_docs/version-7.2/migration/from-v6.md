---
sidebar_position: 1
---

import IapKitBanner from "@site/src/uis/IapKitBanner";

# Migrating from v6 to v7

<IapKitBanner />

Version 7.0.0 introduces breaking API changes to align with OpenIAP standards and improve developer experience with named parameters.

## Overview of Changes

### 1. Named Parameters API

All main methods now use named parameters instead of object-based parameters for a cleaner, more intuitive API.

### 2. Simplified finishTransaction

The `finishTransaction` method now accepts the `Purchase` object directly instead of individual fields.

### 3. Simplified RequestPurchaseProps

Removed sealed class structure in favor of a simpler direct structure.

### 4. New AlternativeBillingModeAndroid

Added support for alternative billing modes on Android.

## Migration Steps

### fetchProducts

**Before (v6.x)**:
```dart
final result = await FlutterInappPurchase.instance.fetchProducts(
  ProductRequest(
    skus: ['product_id'],
    type: ProductQueryType.InApp,
  ),
);
```

**After (v7.0)**:
```dart
final result = await FlutterInappPurchase.instance.fetchProducts(
  skus: ['product_id'],
  type: ProductQueryType.InApp,
);
```

### getAvailablePurchases

**Before (v6.x)**:
```dart
// Using PurchaseOptions object
final purchases = await FlutterInappPurchase.instance.getAvailablePurchases(
  PurchaseOptions(
    onlyIncludeActiveItemsIOS: true,
    alsoPublishToEventListenerIOS: false,
  ),
);
```

**After (v7.0)**:
```dart
// Using named parameters directly
final purchases = await FlutterInappPurchase.instance.getAvailablePurchases(
  onlyIncludeActiveItemsIOS: true,
  alsoPublishToEventListenerIOS: false,
);
```

### finishTransaction

**Before (v6.x)**:
```dart
await FlutterInappPurchase.instance.finishTransaction(
  id: purchase.id,
  isAutoRenewing: purchase.isAutoRenewing,
  platform: purchase.platform,
  productId: purchase.productId,
  purchaseState: purchase.purchaseState,
  purchaseToken: purchase.purchaseToken,
  quantity: purchase.quantity,
  transactionDate: purchase.transactionDate,
  isConsumable: true,
);
```

**After (v7.0)**:
```dart
await FlutterInappPurchase.instance.finishTransaction(
  purchase: purchase,
  isConsumable: true,
);
```

### validateReceipt (iOS)

**Before (v6.x)**:
```dart
final result = await FlutterInappPurchase.instance.validateReceiptIOS(
  ReceiptValidationProps(sku: 'product_id'),
);
```

**After (v7.0)**:
```dart
final result = await FlutterInappPurchase.instance.validateReceiptIOS(
  sku: 'product_id',
);
```

### initConnection

**Before (v6.x)**:
```dart
await FlutterInappPurchase.instance.initConnection();
```

**After (v7.0)**:
```dart
await FlutterInappPurchase.instance.initConnection(
  alternativeBillingModeAndroid: AlternativeBillingModeAndroid.None, // Optional
);
```

### deepLinkToSubscriptions

**Before (v6.x)**:
```dart
await FlutterInappPurchase.instance.deepLinkToSubscriptions(
  DeepLinkOptions(sku: 'subscription_id'),
);
```

**After (v7.0)**:
```dart
await FlutterInappPurchase.instance.deepLinkToSubscriptions(
  skuAndroid: 'subscription_id',
);
```

### Removed iOS-Specific Methods

The following iOS-specific methods have been removed in v7.0. Use the standard OpenIAP-compliant methods instead:

#### getAvailableItemsIOS()

**Before (v6.x)**:
```dart
final purchases = await FlutterInappPurchase.instance.getAvailableItemsIOS();
```

**After (v7.0)**:
```dart
// Use the standard getAvailablePurchases() method
final purchases = await FlutterInappPurchase.instance.getAvailablePurchases();
```

#### getAppTransactionTypedIOS()

**Before (v6.x)**:
```dart
final appTransaction = await FlutterInappPurchase.instance.getAppTransactionTypedIOS();
```

**After (v7.0)**:
```dart
// Use getAppTransactionIOS() directly
final appTransaction = await FlutterInappPurchase.instance.getAppTransactionIOS();
```

#### getPurchaseHistoriesIOS()

**Before (v6.x)**:
```dart
final histories = await FlutterInappPurchase.instance.getPurchaseHistoriesIOS();
```

**After (v7.0)**:
```dart
// Use getAvailablePurchases() with options to include expired items
final histories = await FlutterInappPurchase.instance.getAvailablePurchases(
  onlyIncludeActiveItemsIOS: false,
  alsoPublishToEventListenerIOS: true,
);
```

### RequestPurchaseProps

**Before (v6.x)**:
```dart
// Using factory methods
final props = RequestPurchaseProps.inApp(
  request: RequestPurchasePropsByPlatforms(
    ios: RequestPurchaseIosProps(sku: 'product_id'),
    android: RequestPurchaseAndroidProps(skus: ['product_id']),
  ),
);

final subsProps = RequestPurchaseProps.subs(
  request: RequestSubscriptionPropsByPlatforms(
    ios: RequestSubscriptionIosProps(sku: 'sub_id'),
    android: RequestSubscriptionAndroidProps(skus: ['sub_id']),
  ),
);
```

**After (v7.0)**:
```dart
// Direct constructor with type parameter
final props = RequestPurchaseProps(
  request: RequestPurchasePropsByPlatforms(
    ios: RequestPurchaseIosProps(sku: 'product_id'),
    android: RequestPurchaseAndroidProps(skus: ['product_id']),
  ),
  type: ProductQueryType.InApp,
);

final subsProps = RequestPurchaseProps(
  request: RequestPurchasePropsByPlatforms(
    ios: RequestPurchaseIosProps(sku: 'sub_id'),
    android: RequestPurchaseAndroidProps(skus: ['sub_id']),
  ),
  type: ProductQueryType.Subs,
);
```

## Benefits of v7.0

### Cleaner API
Named parameters make the API more intuitive and self-documenting:

```dart
// Clear and concise
await iap.fetchProducts(
  skus: ['product1', 'product2'],
  type: ProductQueryType.InApp,
);
```

### Reduced Boilerplate
Finishing transactions is now much simpler:

```dart
// Just pass the purchase object
await iap.finishTransaction(
  purchase: purchase,
  isConsumable: true,
);
```

### Type Safety
Direct constructor usage provides better type safety and IDE autocomplete support.

### Better OpenIAP Alignment
The new API structure aligns better with the OpenIAP specification.

## Breaking Changes Checklist

- [ ] Update all `fetchProducts` calls to use named parameters
- [ ] Update all `getAvailablePurchases` calls to use named parameters
- [ ] Update all `finishTransaction` calls to pass `Purchase` object
- [ ] Update all `validateReceiptIOS` calls to use named parameters
- [ ] Update all `deepLinkToSubscriptions` calls to use named parameters
- [ ] Replace `RequestPurchaseProps.inApp()` with direct constructor + `type` parameter
- [ ] Replace `RequestPurchaseProps.subs()` with direct constructor + `type` parameter
- [ ] Remove `RequestSubscriptionPropsByPlatforms` usage (use `RequestPurchasePropsByPlatforms` instead)
- [ ] Replace `getAvailableItemsIOS()` with `getAvailablePurchases()`
- [ ] Replace `getAppTransactionTypedIOS()` with `getAppTransactionIOS()`
- [ ] Replace `getPurchaseHistoriesIOS()` with `getAvailablePurchases()` with options
- [ ] Test all purchase flows thoroughly

## Need Help?

If you encounter issues during migration:

1. Check the [API Reference](/docs/api/overview) for detailed method signatures
2. Review the [Examples](/docs/examples/purchase-flow) for updated code patterns
3. Open an issue on [GitHub](https://github.com/dooboolab-community/flutter_inapp_purchase/issues)
