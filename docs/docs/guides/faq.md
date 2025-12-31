---
sidebar_position: 9
title: FAQ
---

import IapKitBanner from "@site/src/uis/IapKitBanner";
import IapKitLink from "@site/src/uis/IapKitLink";

# Frequently Asked Questions

<IapKitBanner />

Common questions and answers about flutter_inapp_purchase v7.0, covering implementation, platform differences, best practices, and troubleshooting.

## General Questions

### What is flutter_inapp_purchase?

flutter_inapp_purchase is a Flutter plugin that provides a unified API for implementing in-app purchases across iOS and Android platforms. It follows the [OpenIAP specification](https://openiap.dev) and supports:

- Consumable products (coins, gems, lives)
- Non-consumable products (premium features, ad removal)
- Auto-renewable subscriptions
- Subscription offers and promotional codes
- Receipt validation
- Purchase restoration

### Which platforms are supported?

Currently supported platforms:

- **iOS** (12.0+) - Uses StoreKit 2 (iOS 15.0+) with fallback to StoreKit 1
- **Android** (minSdkVersion 21) - Uses Google Play Billing Library v6+

### What's new in v7.0?

Major changes in v7.0:

```dart
// Named parameters API
final products = await iap.fetchProducts(
  skus: ['product_id'],
  type: ProductQueryType.InApp,
);

// Simplified finishTransaction
await iap.finishTransaction(
  purchase: purchase,
  isConsumable: true,
);
```

Key improvements:

- **Named parameters** - All methods now use named parameters for clearer API
- **Simplified finishTransaction** - Pass Purchase object directly
- **Better OpenIAP alignment** - Closer adherence to OpenIAP specification
- **Removed deprecated iOS methods** - Use standard methods instead

See [Migration Guide](../migration/from-v6) for details.

## Implementation Questions

### How do I get started?

Basic implementation steps:

```dart
// 1. Import the package
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

// 2. Initialize connection
final iap = FlutterInappPurchase.instance;
await iap.initConnection();

// 3. Set up listeners
StreamSubscription? _purchaseUpdatedSubscription;
StreamSubscription? _purchaseErrorSubscription;

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

// 4. Load products
final products = await iap.fetchProducts(
  skus: ['product_id_1', 'product_id_2'],
  type: ProductQueryType.InApp,
);

// 5. Request purchase
await iap.requestPurchase(
  RequestPurchaseProps.inApp((
    apple: RequestPurchaseIosProps(sku: 'product_id'),
    google: RequestPurchaseAndroidProps(skus: ['product_id']),
  )),
);
```

### How do I handle different product types?

```dart
final iap = FlutterInappPurchase.instance;

// Consumable products (coins, gems)
await iap.requestPurchase(
  RequestPurchaseProps.inApp((
    apple: RequestPurchaseIosProps(sku: 'consumable_product'),
    google: RequestPurchaseAndroidProps(skus: ['consumable_product']),
  )),
);

// In purchase handler:
await iap.finishTransaction(
  purchase: purchase,
  isConsumable: true, // Consumes on Android, finishes on iOS
);

// Non-consumable products (premium features)
// Check if already owned first
final purchases = await iap.getAvailablePurchases();
final alreadyOwned = purchases.any((p) => p.productId == 'non_consumable');

if (!alreadyOwned) {
  await iap.requestPurchase(
    RequestPurchaseProps.inApp((
      apple: RequestPurchaseIosProps(sku: 'non_consumable'),
      google: RequestPurchaseAndroidProps(skus: ['non_consumable']),
    )),
  );

  // In purchase handler:
  await iap.finishTransaction(
    purchase: purchase,
    isConsumable: false, // Acknowledges on Android, finishes on iOS
  );
}

// Subscriptions
await iap.requestPurchase(
  RequestPurchaseProps.subs((
    apple: RequestSubscriptionIosProps(sku: 'subscription_id'),
    google: RequestSubscriptionAndroidProps(skus: ['subscription_id']),
  )),
);
```

### How do I restore purchases?

```dart
Future<void> restorePurchases() async {
  try {
    final purchases = await iap.getAvailablePurchases();

    if (purchases.isNotEmpty) {
      debugPrint('Restored ${purchases.length} purchases');

      for (final purchase in purchases) {
        // Deliver content for each restored purchase
        await deliverContent(purchase.productId);
      }
    } else {
      debugPrint('No purchases to restore');
    }
  } catch (e) {
    debugPrint('Restore failed: $e');
  }
}
```

### How do I validate receipts?

**Always validate purchases server-side** for security:

```dart
Future<void> _handlePurchase(Purchase purchase) async {
  // 1. Verify on your server
  final isValid = await verifyPurchaseOnServer(purchase);

  if (!isValid) {
    debugPrint('Invalid purchase');
    return;
  }

  // 2. Deliver content
  await deliverContent(purchase.productId);

  // 3. Finish transaction
  await iap.finishTransaction(
    purchase: purchase,
    isConsumable: true, // or false for non-consumables
  );
}

Future<bool> verifyPurchaseOnServer(Purchase purchase) async {
  try {
    final response = await http.post(
      Uri.parse('https://your-server.com/verify-purchase'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'platform': Platform.isIOS ? 'ios' : 'android',
        'productId': purchase.productId,
        'transactionReceipt': purchase.transactionReceipt, // iOS
        'purchaseToken': purchase.purchaseToken, // Android
      }),
    );

    return response.statusCode == 200;
  } catch (e) {
    debugPrint('Verification failed: $e');
    return false;
  }
}
```

## Platform Differences

### What are the key differences between iOS and Android?

| Feature               | iOS                               | Android                           |
| --------------------- | --------------------------------- | --------------------------------- |
| Receipt Format        | Base64 encoded receipt            | Purchase token                    |
| Pending Purchases     | Not supported                     | Supported (purchaseState == PurchaseState.Pending) |
| Offer Codes           | `presentCodeRedemptionSheetIOS()` | Not supported                     |
| Subscription Upgrades | Automatic handling                | Use `replacementModeAndroid`      |
| Transaction Finishing | `finishTransaction()` finishes    | Consumes or acknowledges based on `isConsumable` |
| Sandbox Testing       | Sandbox accounts                  | Test accounts & license testers   |

### How do I handle platform-specific features?

```dart
// iOS-specific: Offer code redemption
if (Platform.isIOS) {
  await iap.presentCodeRedemptionSheetIOS();
}

// iOS-specific: Check introductory offer eligibility
if (Platform.isIOS) {
  final eligible = await iap.isEligibleForIntroOfferIOS('subscription_id');
  debugPrint('Eligible for intro offer: $eligible');
}

// Handle pending purchases (unified across platforms in v8.2.0+)
iap.purchaseUpdatedListener.listen((purchase) {
  if (purchase.purchaseState == PurchaseState.Pending) {
    debugPrint('Purchase pending: ${purchase.productId}');
    // Show pending UI
  } else if (purchase.purchaseState == PurchaseState.Purchased) {
    _handlePurchase(purchase);
  }
});

// Android-specific: Subscription upgrade/downgrade
if (Platform.isAndroid) {
  await iap.requestPurchase(
    RequestPurchaseProps.subs(
      request: RequestPurchasePropsByPlatforms(
        google: RequestPurchaseAndroidProps(
          skus: ['new_subscription'],
          oldSkuAndroid: 'old_subscription',
          purchaseTokenAndroid: oldPurchaseToken,
          replacementModeAndroid: AndroidReplacementMode.withTimeProration.value,
        ),
      ),
    ),
  );
}
```

### Do I need different product IDs for each platform?

Yes, typically you'll have different product IDs configured in App Store Connect and Google Play Console:

```dart
class ProductConfig {
  // Platform-specific product IDs
  static const productIds = {
    'premium': Platform.isIOS ? 'com.app.premium.ios' : 'com.app.premium.android',
    'coins_100': Platform.isIOS ? 'com.app.coins100.ios' : 'com.app.coins100.android',
  };

  // Or use a mapping approach
  static String getProductId(String key) {
    const iosIds = {
      'premium': 'com.app.premium.ios',
      'coins_100': 'com.app.coins100.ios',
    };

    const androidIds = {
      'premium': 'com.app.premium.android',
      'coins_100': 'com.app.coins100.android',
    };

    return Platform.isIOS ? iosIds[key]! : androidIds[key]!;
  }
}
```

## Subscription Renewals

### Are subscription renewals automatically detected when the app launches?

The behavior differs by platform:

| Platform | Auto-Detection | Recommendation |
|----------|----------------|----------------|
| **iOS** | Yes | `purchaseUpdatedListener` fires for renewals that occurred while the app was closed |
| **Android** | No | `purchaseUpdatedListener` does NOT fire for renewals that occurred while the app was closed |

**Recommended approach**: Always call `getAvailablePurchases()` on app launch and verify with <IapKitLink>IAPKit</IapKitLink>'s `verifyPurchaseWithProvider()` to get authoritative subscription status:

```dart
@override
void initState() {
  super.initState();
  _checkSubscriptionOnLaunch();
}

Future<void> _checkSubscriptionOnLaunch() async {
  final purchases = await iap.getAvailablePurchases();

  for (final purchase in purchases) {
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

    if (result.iapkit case final iapkit? when iapkit.isValid) {
      // User has active subscription
      grantPremiumAccess();
    }
  }
}
```

See [Subscription Renewal Detection](./subscription-validation#subscription-renewal-detection) for detailed guidance.

### Why doesn't my subscription status update on Android?

On Android, `purchaseUpdatedListener` only fires for purchases made while the app is running. If a subscription renews while your app is closed:

1. The listener will NOT fire when the app reopens
2. You must explicitly call `getAvailablePurchases()` to get current purchases
3. Use server-side verification (like <IapKitLink>IAPKit</IapKitLink>) to confirm subscription validity

This is a Google Play Billing Library limitation, not a flutter_inapp_purchase issue.

## Troubleshooting

### Why are my products not loading?

Common causes:

1. **iOS**: Products not "Ready to Submit" in App Store Connect
2. **iOS**: Banking/tax information incomplete
3. **Android**: App not published (even to internal testing)
4. **Android**: Signed APK/AAB not uploaded
5. **Both**: Product IDs don't match exactly

```dart
// Debug product loading
try {
  final products = await iap.fetchProducts(
    skus: ['your_product_id'],
    type: ProductQueryType.InApp,
  );

  if (products.isEmpty) {
    debugPrint('No products loaded - check product IDs and store setup');
  } else {
    debugPrint('Loaded ${products.length} products');
  }
} catch (e) {
  debugPrint('Product loading error: $e');
}
```

### Why do purchases fail silently?

Always listen to both purchase streams:

```dart
// ✅ Correct: Listen to both streams
_purchaseUpdatedSubscription = iap.purchaseUpdatedListener.listen((purchase) {
  debugPrint('Purchase success: ${purchase.productId}');
  _handlePurchase(purchase);
});

_purchaseErrorSubscription = iap.purchaseErrorListener.listen((error) {
  debugPrint('Purchase error: ${error.code} - ${error.message}');
  _handleError(error);
});

// Don't forget to cancel subscriptions
@override
void dispose() {
  _purchaseUpdatedSubscription?.cancel();
  _purchaseErrorSubscription?.cancel();
  super.dispose();
}
```

### I see both success and error for one subscription purchase

This can happen on iOS due to StoreKit 2 event timing. If you already processed a success, you can safely ignore a subsequent transient error:

```dart
class PurchaseDeduper {
  int _lastSuccessMs = 0;

  void setupListeners() {
    iap.purchaseUpdatedListener.listen((purchase) async {
      _lastSuccessMs = DateTime.now().millisecondsSinceEpoch;
      await iap.finishTransaction(purchase: purchase, isConsumable: false);
    });

    iap.purchaseErrorListener.listen((error) {
      // Ignore user cancellation
      if (error.code == ErrorCode.userCancelled) return;

      // Ignore spurious errors that follow success within 1.5s
      final now = DateTime.now().millisecondsSinceEpoch;
      final timeSinceSuccess = now - _lastSuccessMs;
      if (timeSinceSuccess >= 0 && timeSinceSuccess < 1500) {
        debugPrint('Ignoring spurious error after success');
        return;
      }

      // Handle real errors
      _handleError(error);
    });
  }
}
```

**Important**: `requestPurchase()` is event-driven, not promise-based. Don't rely on `await requestPurchase()` for the final status—handle results via listeners.

### How do I handle common error codes?

```dart
void _handleError(PurchaseError error) {
  switch (error.code) {
    case ErrorCode.userCancelled:
      // Don't show error - user intentionally cancelled
      debugPrint('User cancelled purchase');
      break;

    case ErrorCode.networkError:
      _showMessage('Network error. Please check your connection and try again.');
      break;

    case ErrorCode.itemAlreadyOwned:
      _showMessage('You already own this item.');
      // Suggest restore purchases
      break;

    case ErrorCode.itemUnavailable:
      _showMessage('This item is currently unavailable.');
      break;

    default:
      _showMessage('Purchase failed: ${error.message}');
      debugPrint('Error code: ${error.code}');
  }
}
```

### How do I handle stuck transactions?

```dart
Future<void> clearStuckTransactions() async {
  final purchases = await iap.getAvailablePurchases();

  for (final purchase in purchases) {
    // Verify and deliver content
    final isValid = await verifyPurchaseOnServer(purchase);

    if (isValid) {
      await deliverContent(purchase.productId);
    }

    // Finish transaction
    await iap.finishTransaction(
      purchase: purchase,
      isConsumable: false, // Adjust based on product type
    );
  }
}
```

## Best Practices

### What are the key best practices?

1. **Always set up listeners first** before making purchase requests
2. **Validate purchases server-side** for security
3. **Use correct `isConsumable` flag** - it handles consume/acknowledge automatically
4. **Handle errors gracefully** with proper error codes
5. **Test thoroughly** in sandbox/test environments
6. **Initialize connection early** in app lifecycle
7. **Cancel subscriptions** in dispose to prevent memory leaks

```dart
class BestPracticeExample extends StatefulWidget {
  @override
  State<BestPracticeExample> createState() => _BestPracticeExampleState();
}

class _BestPracticeExampleState extends State<BestPracticeExample> {
  final _iap = FlutterInappPurchase.instance;
  StreamSubscription? _purchaseUpdatedSubscription;
  StreamSubscription? _purchaseErrorSubscription;

  @override
  void initState() {
    super.initState();
    _initializeIAP();
  }

  Future<void> _initializeIAP() async {
    // 1. Initialize connection early
    await _iap.initConnection();

    // 2. Set up listeners before any purchase requests
    _purchaseUpdatedSubscription = _iap.purchaseUpdatedListener.listen(
      (purchase) async {
        // 3. Always verify server-side
        final isValid = await verifyPurchaseOnServer(purchase);
        if (!isValid) return;

        await deliverContent(purchase.productId);

        // 4. Use correct isConsumable flag
        await _iap.finishTransaction(
          purchase: purchase,
          isConsumable: true,
        );
      },
    );

    _purchaseErrorSubscription = _iap.purchaseErrorListener.listen(
      (error) {
        // 5. Handle errors gracefully
        _handleError(error);
      },
    );
  }

  @override
  void dispose() {
    // 7. Cancel subscriptions
    _purchaseUpdatedSubscription?.cancel();
    _purchaseErrorSubscription?.cancel();
    super.dispose();
  }
}
```

## Additional Resources

### Where can I find more help?

- **Documentation**: [flutter_inapp_purchase docs](https://flutter-inapp-purchase.dooboolab.com)
- **Examples**: [GitHub Repository](https://github.com/dooboolab-community/flutter_inapp_purchase/tree/main/example)
- **Issues**: [GitHub Issues](https://github.com/dooboolab-community/flutter_inapp_purchase/issues)
- **OpenIAP Spec**: [openiap.dev](https://openiap.dev)

### Related Guides

- [Purchase Lifecycle](./lifecycle) - Understand the full purchase flow
- [Subscription Validation](./subscription-validation) - Validate subscriptions properly
- [Error Handling](./error-handling) - Handle errors comprehensively
- [Troubleshooting](./troubleshooting) - Common issues and solutions
