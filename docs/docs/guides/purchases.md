---
sidebar_position: 1
title: Purchases
---

import IapKitBanner from "@site/src/uis/IapKitBanner";

# Purchases

<IapKitBanner />

Complete guide to implementing in-app purchases with flutter_inapp_purchase v7.0.

## Purchase Flow

1. **Initialize Connection** - Connect to the store
2. **Setup Listeners** - Handle purchase updates and errors
3. **Load Products** - Fetch available products
4. **Request Purchase** - Initiate purchase
5. **Deliver Content** - Provide purchased content
6. **Finish Transaction** - Complete the transaction

## Initialize Connection

```dart
final iap = FlutterInappPurchase.instance;
await iap.initConnection();
```

## Setup Purchase Listeners

```dart
StreamSubscription<Purchase>? _purchaseUpdatedSubscription;
StreamSubscription<PurchaseError>? _purchaseErrorSubscription;

void setupListeners() {
  _purchaseUpdatedSubscription = iap.purchaseUpdatedListener.listen(
    (purchase) {
      debugPrint('Purchase received: ${purchase.productId}');
      _handlePurchase(purchase);
    },
  );

  _purchaseErrorSubscription = iap.purchaseErrorListener.listen(
    (error) {
      debugPrint('Purchase error: ${error.message}');
      _handleError(error);
    },
  );
}

@override
void dispose() {
  _purchaseUpdatedSubscription?.cancel();
  _purchaseErrorSubscription?.cancel();
  super.dispose();
}
```

## Load Products

```dart
final products = await iap.fetchProducts(
  skus: ['product_id_1', 'product_id_2'],
  type: ProductQueryType.inApp,
);

for (final product in products) {
  print('${product.title}: ${product.displayPrice}');
}
```

## Request Purchase

```dart
await iap.requestPurchase(
  sku: 'product_id',
  obfuscatedAccountIdAndroid: userId,
  obfuscatedProfileIdAndroid: profileId,
);
```

## Handle Purchase

```dart
Future<void> _handlePurchase(Purchase purchase) async {
  // 1. Validate purchase on your server (required for production)
  final isValid = await verifyPurchaseOnServer(purchase);
  if (!isValid) return;

  // 2. Deliver content to user
  await deliverContent(purchase.productId);

  // 3. Finish transaction
  await iap.finishTransaction(
    purchase: purchase,
    isConsumable: true, // or false for non-consumables/subscriptions
  );
}
```

## Product Types

### Consumable Products

Products that can be purchased multiple times (coins, gems):

```dart
await iap.finishTransaction(
  purchase: purchase,
  isConsumable: true, // Consumes on Android, finishes on iOS
);
```

### Non-Consumable Products

One-time purchases (premium features, ad removal):

```dart
await iap.finishTransaction(
  purchase: purchase,
  isConsumable: false, // Acknowledges on Android, finishes on iOS
);
```

### Subscriptions

Recurring purchases - see [Subscription Offers](./subscription-offers)

## Restore Purchases

```dart
// Restore previous purchases
await iap.restorePurchases();

// Get available purchases
final purchases = await iap.getAvailablePurchases();

for (final purchase in purchases) {
  await deliverContent(purchase.productId);
}
```

## Best Practices

1. **Always set up listeners first** before making purchase requests
2. **Validate purchases server-side** for security
3. **Use correct `isConsumable` flag** - it handles consume/acknowledge automatically
4. **Handle errors gracefully** - see [Error Handling](./error-handling)
5. **Test thoroughly** in sandbox environments

## Complete Example

See working implementations in [Examples](../examples/purchase-flow).

## Next Steps

- [Purchase Lifecycle](./lifecycle) - Understand the full lifecycle
- [Subscription Offers](./subscription-offers) - Handle subscriptions
- [Error Handling](./error-handling) - Handle purchase errors
