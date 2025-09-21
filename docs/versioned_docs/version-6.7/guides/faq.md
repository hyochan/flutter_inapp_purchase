---
sidebar_position: 10
title: FAQ
---

# Frequently Asked Questions

Common questions and answers about flutter_inapp_purchase v6.7.0, covering implementation, platform differences, best practices, and migration.

## General Questions

### What is flutter_inapp_purchase?

flutter_inapp_purchase is a Flutter plugin that provides a unified API for implementing in-app purchases across iOS and Android platforms. It supports:

- Consumable products (coins, gems, lives)
- Non-consumable products (premium features, ad removal)
- Auto-renewable subscriptions
- Receipt validation
- Purchase restoration

### Which platforms are supported?

Currently supported platforms:

- **iOS** (12.0+) - Uses StoreKit 2 (iOS 15.0+) with fallback to StoreKit 1
- **Android** (minSdkVersion 21) - Uses Google Play Billing Client v8

### What's new in v6.7.0?

Major changes in v6.7.0:

```dart
// Old API (v5.x)
await FlutterInappPurchase.instance.requestPurchase('product_id');

// New API (v6.7.0)
await FlutterInappPurchase.instance.requestPurchase(
  request: RequestPurchase(
    ios: RequestPurchaseIOS(
      sku: 'product_id',
      quantity: 1,
    ),
    android: RequestPurchaseAndroid(
      skus: ['product_id'],
    ),
  ),
  type: PurchaseType.inapp,
);
```

Key improvements:

- Direct parameters for `fetchProducts()` (no `RequestProductsParams`)
- Platform-specific request objects for `requestPurchase()`
- `PurchaseOptions` for controlling `getAvailablePurchases()` behavior
- Enhanced type safety and error handling
- StoreKit 2 support for iOS

## Implementation Questions

### How do I get started?

Basic implementation steps:

```dart
// 1. Import the package
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:flutter_inapp_purchase/types.dart' as gentype;

// 2. Initialize connection
await FlutterInappPurchase.instance.initConnection();

// 3. Set up listeners with null checks
FlutterInappPurchase.purchaseUpdated.listen((purchase) {
  if (purchase != null) {
    // Handle successful purchase
    _handlePurchaseSuccess(purchase);
  }
});

FlutterInappPurchase.purchaseError.listen((error) {
  if (error != null) {
    // Handle purchase error
    _handlePurchaseError(error);
  }
});

// 4. Load products
final products = await FlutterInappPurchase.instance.fetchProducts(
  skus: ['product_id_1', 'product_id_2'],
  type: PurchaseType.inapp,
);

// 5. Request purchase
await FlutterInappPurchase.instance.requestPurchase(
  request: RequestPurchase(
    ios: RequestPurchaseIOS(sku: 'product_id', quantity: 1),
    android: RequestPurchaseAndroid(skus: ['product_id']),
  ),
  type: PurchaseType.inapp,
);
```

### How do I handle different product types?

```dart
class ProductTypeHandler {
  // Consumable products
  Future<void> purchaseConsumable(String productId) async {
    await FlutterInappPurchase.instance.requestPurchase(
      request: RequestPurchase(
        ios: RequestPurchaseIOS(sku: productId, quantity: 1),
        android: RequestPurchaseAndroid(skus: [productId]),
      ),
      type: PurchaseType.inapp,
    );

    // Handle success in purchaseUpdated listener
  }

  // Non-consumable products
  Future<void> purchaseNonConsumable(String productId) async {
    // Check if already owned first
    final availablePurchases = await FlutterInappPurchase.instance.getAvailablePurchases(
      const PurchaseOptions(onlyIncludeActiveItemsIOS: true),
    );
    final alreadyOwned = availablePurchases.any((purchase) => purchase.productId == productId);

    if (alreadyOwned) {
      debugPrint('Product already owned');
      return;
    }

    await FlutterInappPurchase.instance.requestPurchase(
      request: RequestPurchase(
        ios: RequestPurchaseIOS(sku: productId, quantity: 1),
        android: RequestPurchaseAndroid(skus: [productId]),
      ),
      type: PurchaseType.inapp,
    );
  }

  // Subscriptions
  Future<void> purchaseSubscription(String productId) async {
    await FlutterInappPurchase.instance.requestPurchase(
      request: RequestPurchase(
        ios: RequestPurchaseIOS(sku: productId),
        android: RequestPurchaseAndroid(skus: [productId]),
      ),
      type: PurchaseType.subs, // Note: Use subs type
    );
  }
}
```

### How do I restore purchases?

```dart
Future<void> restorePurchases() async {
  try {
    // Restore purchases
    await FlutterInappPurchase.instance.restorePurchases();

    // Get available purchases
    final purchases = await FlutterInappPurchase.instance.getAvailablePurchases();

    if (purchases.isNotEmpty) {
      debugPrint('Restored ${purchases.length} purchases');

      for (final purchase in purchases) {
        // Process restored purchase
        await _processRestoredPurchase(purchase);
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

Receipt validation should always be done server-side:

```dart
class ReceiptValidator {
  // iOS Receipt Validation
  Future<bool> validateIOSReceipt(Purchase purchase) async {
    if (purchase.transactionReceipt == null) return false;

    final response = await http.post(
      Uri.parse('https://api.yourserver.com/validate-ios'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'receipt': purchase.transactionReceipt,
        'productId': purchase.productId,
        'transactionId': purchase.transactionId,
        'sandbox': kDebugMode,
      }),
    );

    return response.statusCode == 200;
  }

  // Android Receipt Validation
  Future<bool> validateAndroidReceipt(Purchase purchase) async {
    if (purchase.purchaseToken == null) return false;

    final response = await http.post(
      Uri.parse('https://api.yourserver.com/validate-android'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'purchaseToken': purchase.purchaseToken,
        'productId': purchase.productId,
        'dataAndroid': purchase.dataAndroid,
      }),
    );

    return response.statusCode == 200;
  }
}
```

## Platform Differences

### What are the key differences between iOS and Android?

| Feature               | iOS                               | Android                      |
| --------------------- | --------------------------------- | ---------------------------- |
| Product IDs           | Single SKU                        | Array of SKUs                |
| Receipt Format        | Base64 encoded receipt            | Purchase token               |
| Pending Purchases     | Not supported                     | Supported (state = 2)        |
| Offer Codes           | `presentCodeRedemptionSheetIOS()` | External Play Store link     |
| Subscription Upgrades | Automatic handling                | Manual implementation        |
| Transaction Finishing | Required for all                  | Acknowledgment required      |
| Sandbox Testing       | Sandbox accounts                  | Test accounts & reserved IDs |

### How do I handle platform-specific features?

```dart
class PlatformSpecificHandler {
  // iOS-specific features
  Future<void> handleIOSFeatures() async {
    if (!Platform.isIOS) return;

    // Present offer code redemption (iOS 14+)
    try {
      await FlutterInappPurchase.instance.presentCodeRedemptionSheetIOS();
      debugPrint('Offer code redemption sheet presented');
    } catch (e) {
      debugPrint('Failed to present offer code sheet: $e');
    }

    // Check introductory offer eligibility
    try {
      final eligible = await FlutterInappPurchase.instance.isEligibleForIntroOfferIOS('product_id');
      debugPrint('Eligible for intro offer: $eligible');
    } catch (e) {
      debugPrint('Failed to check intro offer eligibility: $e');
    }

    // Show subscription management
    try {
      await FlutterInappPurchase.instance.showManageSubscriptionsIOS();
      debugPrint('Subscription management shown');
    } catch (e) {
      debugPrint('Failed to show subscription management: $e');
    }
  }

  // Android-specific features
  Future<void> handleAndroidFeatures() async {
    if (!Platform.isAndroid) return;

    // Handle pending purchases
    FlutterInappPurchase.purchaseUpdated.listen((purchase) {
      if (purchase != null && purchase.purchaseStateAndroid == 2) {
        // Purchase is pending
        debugPrint('Purchase pending: ${purchase.productId}');
      }
    });

    // Deep link to subscription management
    try {
      await FlutterInappPurchase.instance.deepLinkToSubscriptionsAndroid();
      debugPrint('Opened Android subscription management');
    } catch (e) {
      debugPrint('Failed to open subscription management: $e');
    }

  }
}
```

### Do I need different product IDs for each platform?

Yes, typically you'll have different product IDs:

```dart
class ProductIds {
  static String getProductId(String baseId) {
    if (Platform.isIOS) {
      return 'ios_$baseId';
    } else {
      return 'android_$baseId';
    }
  }

  // Or use a mapping approach
  static const productMap = {
    'premium': {
      'ios': 'premium_ios',
      'android': 'premium_android',
    },
    'coins_100': {
      'ios': 'coins_100_ios',
      'android': 'coins_100_android',
    },
  };

  static String getMappedId(String key) {
    final platform = Platform.isIOS ? 'ios' : 'android';
    return productMap[key]?[platform] ?? key;
  }

  // Example from the actual project
  static const actualProductIds = [
    'dev.hyo.martie.10bulbs',
    'dev.hyo.martie.30bulbs',
  ];
}
```

## Best Practices

### Should I verify purchases client-side or server-side?

**Always verify purchases server-side** for security:

```dart
// ❌ Don't do this - Client-side only
void badPractice(Purchase purchase) {
  // Directly deliver content without verification
  deliverContent(purchase.productId);
}

// ✅ Do this - Server-side verification
Future<void> goodPractice(Purchase purchase) async {
  // 1. Send to server for verification
  final isValid = await verifyOnServer(purchase);

  // 2. Only deliver content if verified
  if (isValid) {
    await deliverContent(purchase.productId);
    await finishTransaction(purchase);
  }
}
```

### How should I handle errors?

Implement comprehensive error handling:

```dart
class ErrorHandler {
  static void handlePurchaseError(PurchaseResult? error) {
    if (error == null) return;

    switch (error.responseCode) {
      case 1: // User cancelled
        // Don't show error for user cancellation
        debugPrint('User cancelled purchase');
        break;

      case 2: // Network error
        showRetryDialog('Network error. Please check your connection.');
        break;

      case 7: // Already owned
        showMessage('You already own this item.');
        suggestRestorePurchases();
        break;

      default:
        showGenericError();
        logError(error);
    }
  }

  static void showRetryDialog(String message) {
    // Show retry dialog implementation
  }

  static void showMessage(String message) {
    // Show message implementation
  }

  static void suggestRestorePurchases() {
    // Suggest restore purchases implementation
  }

  static void showGenericError() {
    // Show generic error implementation
  }

  static void logError(PurchaseResult error) {
    debugPrint('Purchase error: ${error.message}');
    debugPrint('Error code: ${error.responseCode}');
    debugPrint('Debug message: ${error.debugMessage}');
  }
}
```

### How do I test purchases?

Testing approach for each platform:

```dart
class PurchaseTesting {
  // iOS Testing
  static void setupIOSTesting() {
    // 1. Create sandbox tester in App Store Connect
    // 2. Sign out of production account on device
    // 3. Don't sign into sandbox account in Settings
    // 4. Use sandbox account when prompted during purchase

    // For local testing with StoreKit configuration:
    // 1. Create .storekit file in Xcode
    // 2. Add test products
    // 3. Run app with StoreKit configuration

    debugPrint('iOS Testing Setup:');
    debugPrint('- Create sandbox test account in App Store Connect');
    debugPrint('- Products must be "Ready to Submit"');
    debugPrint('- Banking and tax forms must be completed');
  }

  // Android Testing
  static void setupAndroidTesting() {
    // Option 1: Use test product IDs
    final testProducts = [
      'android.test.purchased',     // Always succeeds
      'android.test.canceled',      // Always cancelled
      'android.test.refunded',      // Always refunded
      'android.test.item_unavailable', // Always unavailable
    ];

    // Option 2: Use license testers
    // 1. Add testers in Play Console
    // 2. Upload signed APK to internal testing
    // 3. Download from testing track

    debugPrint('Android Testing Setup:');
    debugPrint('- Upload signed APK to Play Console');
    debugPrint('- Add license testing accounts');
    debugPrint('- Products must be "Active"');
    debugPrint('- Test with: $testProducts');
  }
}
```

## Migration Questions

### How do I migrate from v5 to v6?

Key migration steps:

```dart
// 1. Update purchase requests
// Old (v5.x)
await _iap.requestPurchase('product_id');

// New (v6.7.0)
await _iap.requestPurchase(
  request: RequestPurchase(
    ios: RequestPurchaseIOS(sku: 'product_id', quantity: 1),
    android: RequestPurchaseAndroid(skus: ['product_id']),
  ),
  type: PurchaseType.inapp,
);

// 2. Update subscription requests
// Old (v5.x)
await _iap.requestPurchase('subscription_id');

// New (v6.7.0)
await _iap.requestPurchase(
  request: RequestPurchase(
    ios: RequestPurchaseIOS(sku: 'subscription_id'),
    android: RequestPurchaseAndroid(skus: ['subscription_id']),
  ),
  type: PurchaseType.subs,
);

// 3. Update method names
// finishTransaction -> finishTransactionIOS
await _iap.finishTransactionIOS(purchase, isConsumable: true);

// 4. Add null checks to stream listeners
FlutterInappPurchase.purchaseUpdated.listen((purchase) {
  if (purchase != null) {
    // Handle purchase
  }
});
```

### What breaking changes should I be aware of?

Major breaking changes in v6.7.0:

1. **Request API Changed**

   - Now uses platform-specific request objects
   - Type parameter is required

2. **Method Renames**

   - `finishTransaction` → `finishTransactionIOS`
   - Some return types changed

3. **Error Handling**

   - New error codes added
   - Error structure updated

4. **Minimum Requirements**
   - iOS 12.0+ (was 10.0+)
   - Android minSdk 21 (was 19)

### Can I use both old and new APIs?

The old string-based API is still supported for backward compatibility:

```dart
// Legacy API - still works
await _iap.requestPurchase('product_id');

// New API - recommended
await _iap.requestPurchase(
  request: RequestPurchase(
    ios: RequestPurchaseIOS(sku: 'product_id', quantity: 1),
    android: RequestPurchaseAndroid(skus: ['product_id']),
  ),
  type: PurchaseType.inapp,
);
```

However, it's recommended to migrate to the new API for better functionality.

## Troubleshooting Questions

### I sometimes see both a success and an error for one subscription purchase

This can briefly happen on iOS due to StoreKit 2 event ordering and native background work. If you already received a success and processed it, you can safely ignore a transient error that arrives shortly afterwards.

Tip (dedup in app logic):

```dart
class IapDeduper {
  int _lastSuccessAtMs = 0;

  void attachListeners() {
    // Success handler
    FlutterInappPurchase.purchaseUpdated.listen((purchase) async {
      if (purchase == null) return;
      _lastSuccessAtMs = DateTime.now().millisecondsSinceEpoch;

      // Subscriptions are non-consumable; finish/acknowledge the transaction
      await FlutterInappPurchase.instance
          .finishTransaction(purchase, isConsumable: false);
    });

    // Error handler with spurious-error filter
    FlutterInappPurchase.purchaseError.listen((error) {
      if (error == null) return;

      // Ignore user-cancelled
      if (error.code == 'E_USER_CANCELLED') return;

      // If an error follows immediately after a success, ignore it
      if (error.code == 'E_SERVICE_ERROR') {
        final now = DateTime.now().millisecondsSinceEpoch;
        final dt = now - _lastSuccessAtMs;
        if (dt >= 0 && dt < 1500) return; // Ignore spurious error
      }

      // Surface remaining errors to the user/logs
      debugPrint('Purchase failed: ${error.message}');
    });
  }
}
```

Because of this timing model, all request* APIs (for example, `requestPurchase`) are event‑driven, not promise‑based:

- `requestPurchase()` does not resolve with a final outcome. It triggers the native flow; handle results via `purchaseUpdated`/`purchaseError`.
- Avoid relying on `await requestPurchase(...)` for the final status; multiple events and inter‑session completions are possible.
- This design ensures robustness when the store delivers updates after app restarts or in edge timing conditions.

### Why are my products not loading?

Common causes and solutions:

```dart
class ProductLoadingDiagnostics {
  static Future<void> diagnose() async {
    // 1. Check connection
    try {
      await FlutterInappPurchase.instance.initConnection();
      debugPrint('✓ Connection established');
    } catch (e) {
      debugPrint('✗ Connection failed: $e');
      return;
    }

    // 2. Verify product IDs
    final testIds = ['your_product_id'];
    debugPrint('Testing product IDs: $testIds');

    // 3. Check platform-specific issues
    if (Platform.isIOS) {
      debugPrint('iOS Checklist:');
      debugPrint('- Products "Ready to Submit" in App Store Connect');
      debugPrint('- Banking/tax forms completed');
      debugPrint('- Bundle ID matches');
      debugPrint('- Using sandbox account');
    } else {
      debugPrint('Android Checklist:');
      debugPrint('- Products active in Play Console');
      debugPrint('- App published (at least internal testing)');
      debugPrint('- Signed APK/AAB uploaded');
      debugPrint('- Tester account added');
    }

    // 4. Try loading products
    try {
      final result = await FlutterInappPurchase.instance.fetchProducts(
        ProductRequest(
          skus: testIds,
          type: Platform.isIOS
              ? ProductQueryType.InApp
              : ProductQueryType.InApp,
        ),
      );
      final products = result.inAppProducts();
      debugPrint('✓ Loaded ${products.length} products');

      for (final product in products) {
        debugPrint('Product: ${product.id} - ${product.title}');
        debugPrint('Price: ${product.displayPrice}');
      }
    } catch (e) {
      debugPrint('✗ Product loading failed: $e');
    }
  }
}
```

### Why do purchases fail silently?

Ensure you're listening to both streams:

```dart
// ❌ Common mistake - only listening to one stream
FlutterInappPurchase.purchaseUpdated.listen((purchase) {
  // Only handles success
});

// ✅ Correct approach - listen to both streams
FlutterInappPurchase.purchaseUpdated.listen((purchase) {
  // Handle successful purchases
  if (purchase != null) {
    processPurchase(purchase);
  }
});

FlutterInappPurchase.purchaseError.listen((error) {
  // Handle purchase errors
  if (error != null) {
    handleError(error);
  }
});
```

### How do I handle stuck transactions?

```dart
Future<void> clearStuckTransactions() async {
  try {
    // Get all available purchases
    final purchases = await FlutterInappPurchase.instance.getAvailablePurchases();

    if (purchases.isNotEmpty) {
      for (final purchase in purchases) {
        try {
          // Finish the transaction based on platform
          if (Platform.isAndroid && purchase.purchaseToken != null) {
            await FlutterInappPurchase.instance.consumePurchaseAndroid(
              purchaseToken: purchase.purchaseToken!,
            );
          } else if (Platform.isIOS) {
            await FlutterInappPurchase.instance.finishTransactionIOS(
              purchase,
              isConsumable: true,
            );
          }
          debugPrint('Cleared transaction: ${purchase.transactionId}');
        } catch (e) {
          debugPrint('Failed to clear transaction: $e');
        }
      }
    }
  } catch (e) {
    debugPrint('Failed to get stuck transactions: $e');
  }
}
```

## Performance Questions

### How can I optimize purchase flow performance?

```dart
class PerformanceOptimization {
  // 1. Preload products
  static Future<void> preloadProducts() async {
    // Load products early in app lifecycle
    final productIds = ['product1', 'product2', 'product3'];
    await FlutterInappPurchase.instance.fetchProducts(
      ProductRequest(
        skus: productIds,
        type: ProductQueryType.InApp,
      ),
    );
  }

  // 2. Prepare purchase flow
  static Future<void> preparePurchaseFlow() async {
    // Initialize connection early
    await FlutterInappPurchase.instance.initConnection();

    // Set up listeners before user interaction
    setupPurchaseListeners();
  }

  static void setupPurchaseListeners() {
    FlutterInappPurchase.purchaseUpdated.listen((purchase) {
      if (purchase != null) {
        // Process purchase immediately
        _processPurchaseImmediately(purchase);
      }
    });

    FlutterInappPurchase.purchaseError.listen((error) {
      if (error != null) {
        // Handle error immediately
        _handleErrorImmediately(error);
      }
    });
  }

  static void _processPurchaseImmediately(Purchase purchase) {
    // Implementation for immediate purchase processing
  }

  static void _handleErrorImmediately(PurchaseResult error) {
    // Implementation for immediate error handling
  }
}
```

### Should I keep the connection open?

Best practices for connection management:

```dart
class ConnectionManagement {
  // Initialize on app start
  static Future<void> initializeOnAppStart() async {
    try {
      await FlutterInappPurchase.instance.initConnection();
      debugPrint('IAP connection initialized');
    } catch (e) {
      debugPrint('Failed to initialize IAP connection: $e');
    }
  }

  // Keep connection alive during purchase flows
  static void maintainConnection() {
    // Don't close connection between purchases
    // Only close when app is terminating
  }

  // Clean up on app termination
  static Future<void> cleanup() async {
    try {
      await FlutterInappPurchase.instance.endConnection();
      debugPrint('IAP connection closed');
    } catch (e) {
      debugPrint('Failed to close IAP connection: $e');
    }
  }
}
```

## Additional Resources

### Where can I find more examples?

- [GitHub Repository Examples](https://github.com/hyochan/flutter_inapp_purchase/tree/main/example)
- [API Documentation](../api/flutter-inapp-purchase.md)
- [Troubleshooting Guide](./troubleshooting.md)

### How do I get help?

1. Check the [Troubleshooting Guide](./troubleshooting.md)
2. Search [GitHub Issues](https://github.com/hyochan/flutter_inapp_purchase/issues)
3. Post on [Stack Overflow](https://stackoverflow.com/questions/tagged/flutter-inapp-purchase) with tag `flutter-inapp-purchase`
4. Join [Flutter Community](https://flutter.dev/community)

### How can I contribute?

Contributions are welcome! See the [Contributing Guidelines](https://github.com/hyochan/flutter_inapp_purchase/blob/main/CONTRIBUTING.md) for:

- Bug reports
- Feature requests
- Pull requests
- Documentation improvements
