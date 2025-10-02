---
sidebar_position: 3
---

# Available Purchases

> **Source Code**: [available_purchases_screen.dart](https://github.com/hyochan/flutter_inapp_purchase/blob/main/example/lib/src/screens/available_purchases_screen.dart)

This example demonstrates how to retrieve and display user's available purchases and purchase history.

## Key Features

- Retrieve active purchases
- Include expired subscriptions (iOS)
- Display purchase details
- Restore purchases
- Handle purchase validation

## Implementation Overview

### 1. Get Active Purchases

```dart
final purchases = await iap.getAvailablePurchases(
  onlyIncludeActiveItemsIOS: true,
);
```

### 2. Get All Purchases (Including Expired)

```dart
final allPurchases = await iap.getAvailablePurchases(
  onlyIncludeActiveItemsIOS: false,
  alsoPublishToEventListenerIOS: false,
);
```

### 3. Display Purchase Information

```dart
for (final purchase in purchases) {
  debugPrint('Product ID: ${purchase.productId}');
  debugPrint('Transaction ID: ${purchase.transactionIdFor}');
  debugPrint('Purchase Date: ${purchase.transactionDate}');
  debugPrint('Purchase Token: ${purchase.purchaseToken}');
}
```


### 4. Restore Purchases

```dart
Future<void> restorePurchases() async {
  final restored = await iap.getAvailablePurchases();

  // Verify purchases on server
  for (final purchase in restored) {
    await verifyPurchaseOnServer(purchase.purchaseToken);
  }

  // Grant access to purchased content
  await updateUserAccess(restored);
}
```

## Platform Differences

### iOS
- Use `onlyIncludeActiveItemsIOS: true` to filter expired subscriptions
- Use `onlyIncludeActiveItemsIOS: false` to include purchase history
- `alsoPublishToEventListenerIOS` publishes purchases to the event stream

### Android
- Returns all verified purchases from Google Play
- Includes purchase tokens for server-side verification
- No separate purchase history API

## Best Practices

1. **Verify purchases on your backend** - Don't trust client-side purchase data alone
2. **Handle restore gracefully** - Show clear feedback during restore process
3. **Check purchase state** - Validate purchase state before granting access
4. **Support offline mode** - Cache validated purchases locally
5. **Handle edge cases** - Account for refunds, cancellations, and billing retries
