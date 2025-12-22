---
sidebar_position: 2
---

import IapKitBanner from "@site/src/uis/IapKitBanner";

# Subscription Flow

<IapKitBanner />

> **Source Code**: [subscription_flow_screen.dart](https://github.com/hyochan/flutter_inapp_purchase/blob/main/example/lib/src/screens/subscription_flow_screen.dart)

This example demonstrates how to implement subscription purchases with support for upgrades, downgrades, and subscription management.

## Key Features

- Fetch subscription products
- Handle subscription purchases
- Check active subscriptions
- Manage subscription upgrades/downgrades (Android)
- Listen to subscription events

## Implementation Overview

### 1. Set Up Listeners

```dart
StreamSubscription<Purchase>? _purchaseUpdatedSubscription;
StreamSubscription<PurchaseError>? _purchaseErrorSubscription;

void _setupListeners() {
  _purchaseUpdatedSubscription = iap.purchaseUpdatedListener.listen(
    (purchase) {
      _handlePurchase(purchase);
    },
  );

  _purchaseErrorSubscription = iap.purchaseErrorListener.listen(
    (error) {
      _handleError(error);
    },
  );
}
```

### 2. Fetch Subscription Products

```dart
final subscriptions = await iap.fetchProducts<ProductSubscription>(
  skus: ['monthly_sub', 'yearly_sub'],
  type: ProductQueryType.Subs,
);

if (subscriptions.isNotEmpty) {
  for (final product in subscriptions) {
    if (product is ProductSubscriptionIOS) {
      debugPrint('iOS Subscription: ${product.displayName}');
    } else if (product is ProductSubscriptionAndroid) {
      debugPrint('Android Subscription: ${product.title}');
    }
  }
}
```

### 3. Check Active Subscriptions

```dart
// Lightweight check - returns only subscription IDs and expiry dates
final summaries = await iap.getActiveSubscriptions(['monthly_sub']);
if (summaries.isNotEmpty) {
  debugPrint('Active subscription: ${summaries.first.productId}');
  debugPrint('Expires: ${summaries.first.expirationDateIOS}');
}

// Detailed check - returns full purchase objects
final purchases = await iap.getAvailablePurchases(
  PurchaseOptions(onlyIncludeActiveItemsIOS: true),
);
```

### 4. Purchase Subscription

```dart
await iap.requestPurchase(
  RequestPurchaseProps.subs((
    ios: RequestPurchaseIosProps(
      sku: 'monthly_sub',
      quantity: 1,
    ),
    android: RequestPurchaseAndroidProps(
      skus: ['monthly_sub'],
    ),
    useAlternativeBilling: null,
  )),
);
```

### 5. Upgrade/Downgrade Subscription (Android)

```dart
await iap.requestPurchase(
  RequestPurchaseProps.subs((
    ios: RequestPurchaseIosProps(
      sku: 'yearly_sub',
      quantity: 1,
    ),
    android: RequestPurchaseAndroidProps(
      skus: ['yearly_sub'],
      replacementModeAndroid: AndroidReplacementMode.withTimeProration,
    ),
    useAlternativeBilling: null,
  )),
);
```

## Android Replacement Modes

```dart
enum AndroidReplacementMode {
  withTimeProration,      // 1: Credit unused time towards new subscription
  chargeProratedPrice,    // 2: Charge prorated price immediately
  withoutProration,       // 3: No credit for unused time
  deferred,               // 4: New subscription starts at next renewal
  chargeFullPrice,        // 5: Charge full price immediately
}
```

## Best Practices

1. **Use lightweight checks** - Use `getActiveSubscriptions()` for quick status checks
2. **Verify server-side** - Always validate subscription status on your backend
3. **Handle upgrades properly** - Choose appropriate replacement mode for Android
4. **Check subscription status** - Regularly verify subscription validity
5. **Handle expiration** - Monitor subscription expiry dates and renewal status
