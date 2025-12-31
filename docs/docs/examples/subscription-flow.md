---
sidebar_position: 2
---

import IapKitBanner from "@site/src/uis/IapKitBanner";
import IapKitLink from "@site/src/uis/IapKitLink";

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
final result = await iap.fetchProducts(
  ProductRequest(
    skus: ['monthly_sub', 'yearly_sub'],
    type: ProductQueryType.Subs,
  ),
);

if (result is FetchProductsResultSubscriptions) {
  final subscriptions = result.value ?? [];
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
    apple: RequestPurchaseIosProps(
      sku: 'monthly_sub',
      quantity: 1,
    ),
    google: RequestPurchaseAndroidProps(
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
    apple: RequestPurchaseIosProps(
      sku: 'yearly_sub',
      quantity: 1,
    ),
    google: RequestPurchaseAndroidProps(
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

## IAPKit Server Verification

Use <IapKitLink>IAPKit</IapKitLink> for enterprise-grade purchase verification without maintaining your own validation infrastructure.

### Complete Verification Flow

```dart
Future<void> _handlePurchaseWithVerification(Purchase purchase) async {
  // 1. Verify purchase with IAPKit
  final result = await iap.verifyPurchaseWithProvider(
    VerifyPurchaseWithProviderProps(
      provider: VerifyPurchaseProvider.iapkit,
      iapkit: RequestVerifyPurchaseWithIapkitProps(
        apiKey: 'your-iapkit-api-key',
        apple: RequestVerifyPurchaseWithIapkitAppleProps(
          jws: purchase.purchaseToken,
        ),
        google: RequestVerifyPurchaseWithIapkitGoogleProps(
          purchaseToken: purchase.purchaseToken,
        ),
      ),
    ),
  );

  // 2. Handle verification result
  if (result.iapkit case final iapkit?) {
    switch (iapkit.state) {
      case IapkitPurchaseState.Entitled:
        // Purchase is valid - grant access
        await grantPremiumAccess(purchase.productId);
        await iap.finishTransaction(purchase: purchase, isConsumable: false);
      case IapkitPurchaseState.Expired:
        // Subscription expired
        await revokePremiumAccess(purchase.productId);
      case IapkitPurchaseState.Inauthentic:
        // Fraudulent purchase detected
        debugPrint('Inauthentic purchase detected');
      default:
        debugPrint('Purchase state: ${iapkit.state}');
    }
  }
}
```

### IAPKit Purchase States

| State | Description | Recommended Action |
|-------|-------------|-------------------|
| `entitled` | User has active subscription | Grant premium access |
| `expired` | Subscription has expired | Revoke access, show renewal prompt |
| `canceled` | User canceled, may have time remaining | Check expiration date |
| `pending` | Purchase pending (parental approval, etc.) | Show pending UI |
| `pending-acknowledgment` | Needs acknowledgment (Android) | Call `finishTransaction()` |
| `inauthentic` | Failed validation | Do not grant access |

### Checking Subscription Status on App Launch

```dart
class SubscriptionManager {
  final _iap = FlutterInappPurchase.instance;
  final String _apiKey;

  SubscriptionManager({required String apiKey}) : _apiKey = apiKey;

  Future<bool> checkSubscriptionOnLaunch(List<String> subscriptionIds) async {
    try {
      // Get all available purchases
      final purchases = await _iap.getAvailablePurchases();

      // Filter to subscriptions only
      final subscriptionPurchases = purchases.where(
        (p) => subscriptionIds.contains(p.productId),
      );

      for (final purchase in subscriptionPurchases) {
        final result = await _iap.verifyPurchaseWithProvider(
          VerifyPurchaseWithProviderProps(
            provider: VerifyPurchaseProvider.iapkit,
            iapkit: RequestVerifyPurchaseWithIapkitProps(
              apiKey: _apiKey,
              apple: RequestVerifyPurchaseWithIapkitAppleProps(
                jws: purchase.purchaseToken,
              ),
              google: RequestVerifyPurchaseWithIapkitGoogleProps(
                purchaseToken: purchase.purchaseToken,
              ),
            ),
          ),
        );

        if (result.iapkit case final iapkit? when iapkit.isValid) {
          return true; // Active subscription found
        }
      }

      return false; // No active subscription
    } catch (e) {
      debugPrint('Failed to check subscription: $e');
      return false;
    }
  }
}

// Usage
final manager = SubscriptionManager(apiKey: 'your-iapkit-api-key');
final isSubscribed = await manager.checkSubscriptionOnLaunch([
  'monthly_subscription',
  'yearly_subscription',
]);
```

## Best Practices

1. **Use lightweight checks** - Use `getActiveSubscriptions()` for quick status checks
2. **Verify server-side** - Always validate subscription status with <IapKitLink>IAPKit</IapKitLink>
3. **Handle upgrades properly** - Choose appropriate replacement mode for Android
4. **Check subscription status** - Verify on app launch and app resume
5. **Handle expiration** - Monitor subscription expiry dates and renewal status
6. **Check renewals on Android** - `purchaseUpdatedListener` doesn't fire for renewals while app is closed
