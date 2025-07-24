---
sidebar_position: 10
title: FAQ
---

# Frequently Asked Questions

Common questions and answers about flutter_inapp_purchase v6.0.0, covering implementation, platform differences, best practices, and migration.

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
- **iOS** (10.0+) - Uses StoreKit 2 (iOS 15.0+) with fallback to StoreKit 1
- **Android** (minSdkVersion 19) - Uses Google Play Billing Client v8

Amazon App Store support is available through a separate implementation.

### What's new in v6.0.0?

Major changes in v6.0.0:

```dart
// Old API (v5.x)
await FlutterInappPurchase.instance.requestPurchase('product_id');

// New API (v6.0.0)
await FlutterInappPurchase.instance.requestPurchase(
  request: RequestPurchase(
    ios: RequestPurchaseIOS(
      sku: 'product_id',
      appAccountToken: 'user_id',
    ),
    android: RequestPurchaseAndroid(
      skus: ['product_id'],
      obfuscatedAccountIdAndroid: 'user_id',
    ),
  ),
  type: PurchaseType.inapp,
);
```

Key improvements:
- Platform-specific request objects
- Better type safety
- Enhanced error handling
- Improved subscription support
- StoreKit 2 support for iOS

## Implementation Questions

### How do I get started?

Basic implementation steps:

```dart
// 1. Import the package
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

// 2. Initialize connection
await FlutterInappPurchase.instance.initConnection();

// 3. Set up listeners
FlutterInappPurchase.purchaseUpdated.listen((purchase) {
  // Handle successful purchase
});

FlutterInappPurchase.purchaseError.listen((error) {
  // Handle purchase error
});

// 4. Load products
final products = await FlutterInappPurchase.instance.getProducts([
  'product_id_1',
  'product_id_2',
]);

// 5. Request purchase
await FlutterInappPurchase.instance.requestPurchase(
  request: RequestPurchase(
    ios: RequestPurchaseIOS(sku: 'product_id'),
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
        ios: RequestPurchaseIOS(sku: productId),
        android: RequestPurchaseAndroid(skus: [productId]),
      ),
      type: PurchaseType.inapp,
    );
    
    // Always finish consumable transactions
    // Content delivery happens in purchaseUpdated listener
  }
  
  // Non-consumable products
  Future<void> purchaseNonConsumable(String productId) async {
    // Check if already owned
    if (await isProductOwned(productId)) {
      print('Product already owned');
      return;
    }
    
    await FlutterInappPurchase.instance.requestPurchase(
      request: RequestPurchase(
        ios: RequestPurchaseIOS(sku: productId),
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
    
    if (Platform.isIOS) {
      // iOS: Get restored items
      final items = await FlutterInappPurchase.instance.getAvailableItemsIOS();
      
      if (items != null && items.isNotEmpty) {
        print('Restored ${items.length} purchases');
        
        for (final item in items) {
          // Process restored purchase
          await processRestoredPurchase(item);
        }
      }
    } else {
      // Android: Restored purchases come through purchaseUpdated stream
      print('Restore initiated, listening for updates...');
    }
  } catch (e) {
    print('Restore failed: $e');
  }
}
```

### How do I validate receipts?

Receipt validation should always be done server-side:

```dart
class ReceiptValidator {
  // iOS Receipt Validation
  Future<bool> validateIOSReceipt(PurchasedItem purchase) async {
    if (purchase.transactionReceipt == null) return false;
    
    final response = await http.post(
      Uri.parse('https://api.yourserver.com/validate-ios'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'receipt': purchase.transactionReceipt,
        'productId': purchase.productId,
        'sandbox': kDebugMode,
      }),
    );
    
    return response.statusCode == 200;
  }
  
  // Android Receipt Validation
  Future<bool> validateAndroidReceipt(PurchasedItem purchase) async {
    if (purchase.purchaseToken == null) return false;
    
    final response = await http.post(
      Uri.parse('https://api.yourserver.com/validate-android'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'purchaseToken': purchase.purchaseToken,
        'productId': purchase.productId,
        'packageName': await getPackageName(),
      }),
    );
    
    return response.statusCode == 200;
  }
}
```

## Platform Differences

### What are the key differences between iOS and Android?

| Feature | iOS | Android |
|---------|-----|---------|
| Product IDs | Single SKU | Array of SKUs |
| Receipt Format | Base64 encoded receipt | Purchase token |
| Pending Purchases | Not supported | Supported (state = 2) |
| Offer Codes | `presentCodeRedemptionSheet()` | External Play Store link |
| Subscription Upgrades | Automatic handling | Manual implementation |
| Transaction Finishing | Required for all | Acknowledgment required |
| Sandbox Testing | Sandbox accounts | Test accounts & reserved IDs |

### How do I handle platform-specific features?

```dart
class PlatformSpecificHandler {
  // iOS-specific features
  Future<void> handleIOSFeatures() async {
    if (!Platform.isIOS) return;
    
    // Present offer code redemption
    await FlutterInappPurchase.instance.presentCodeRedemptionSheet();
    
    // Get unfinished transactions
    final pending = await FlutterInappPurchase.instance.getAvailableItemsIOS();
    
    // Get receipt data
    final receipt = await FlutterInappPurchase.instance.getReceiptDataIOS();
  }
  
  // Android-specific features
  Future<void> handleAndroidFeatures() async {
    if (!Platform.isAndroid) return;
    
    // Handle pending purchases
    FlutterInappPurchase.purchaseUpdated.listen((purchase) {
      if (purchase?.purchaseStateAndroid == 2) {
        // Purchase is pending
        print('Purchase pending: ${purchase?.productId}');
      }
    });
    
    // Get purchase history
    final history = await FlutterInappPurchase.instance.getPurchaseHistory();
  }
}
```

### Do I need different product IDs for each platform?

Yes, typically you'll have different product IDs:

```dart
class ProductIds {
  static String getProductId(String baseId) {
    if (Platform.isIOS) {
      return 'com.yourcompany.ios.$baseId';
    } else {
      return 'com.yourcompany.android.$baseId';
    }
  }
  
  // Or use a mapping
  static const productMap = {
    'premium': {
      'ios': 'com.company.premium.ios',
      'android': 'com.company.premium.android',
    },
    'coins_100': {
      'ios': 'com.company.coins100.ios',
      'android': 'coins_100_android',
    },
  };
  
  static String getMappedId(String key) {
    final platform = Platform.isIOS ? 'ios' : 'android';
    return productMap[key]?[platform] ?? key;
  }
}
```

## Best Practices

### Should I verify purchases client-side or server-side?

**Always verify purchases server-side** for security:

```dart
// ❌ Don't do this - Client-side only
void badPractice(PurchasedItem purchase) {
  // Directly deliver content without verification
  deliverContent(purchase.productId);
}

// ✅ Do this - Server-side verification
Future<void> goodPractice(PurchasedItem purchase) async {
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
    
    switch (error.code) {
      case ErrorCode.eUserCancelled:
        // Don't show error for user cancellation
        print('User cancelled purchase');
        break;
        
      case ErrorCode.eNetworkError:
        showRetryDialog('Network error. Please check your connection.');
        break;
        
      case ErrorCode.eAlreadyOwned:
        showMessage('You already own this item.');
        suggestRestorePurchases();
        break;
        
      default:
        showGenericError();
        logError(error);
    }
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
  }
}
```

### Should I cache product information?

Yes, cache products for better UX:

```dart
class ProductCache {
  static final Map<String, IAPItem> _cache = {};
  static DateTime? _lastFetch;
  static const cacheDuration = Duration(hours: 1);
  
  static Future<List<IAPItem>> getProducts(List<String> ids) async {
    // Check cache validity
    if (_lastFetch != null && 
        DateTime.now().difference(_lastFetch!) < cacheDuration &&
        ids.every((id) => _cache.containsKey(id))) {
      return ids.map((id) => _cache[id]!).toList();
    }
    
    // Fetch fresh data
    try {
      final products = await FlutterInappPurchase.instance.getProducts(ids);
      
      // Update cache
      for (final product in products) {
        _cache[product.productId!] = product;
      }
      _lastFetch = DateTime.now();
      
      return products;
    } catch (e) {
      // Return cached data on error
      return ids
          .where((id) => _cache.containsKey(id))
          .map((id) => _cache[id]!)
          .toList();
    }
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

// New (v6.0.0)
await _iap.requestPurchase(
  request: RequestPurchase(
    ios: RequestPurchaseIOS(sku: 'product_id'),
    android: RequestPurchaseAndroid(skus: ['product_id']),
  ),
  type: PurchaseType.inapp,
);

// 2. Update subscription requests
// Old (v5.x)
await _iap.requestSubscription('subscription_id');

// New (v6.0.0)
await _iap.requestPurchase(
  request: RequestPurchase(
    ios: RequestPurchaseIOS(sku: 'subscription_id'),
    android: RequestPurchaseAndroid(skus: ['subscription_id']),
  ),
  type: PurchaseType.subs,
);

// 3. Update method names
// finishTransaction -> finishTransactionIOS
// endConnection -> endConnection (no change)
// initConnection -> initConnection (no change)
```

### What breaking changes should I be aware of?

Major breaking changes in v6.0.0:

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
   - iOS 10.0+ (was 9.0+)
   - Android minSdk 19 (no change)

### Can I use both old and new APIs?

The old string-based API is still supported for backward compatibility:

```dart
// Legacy API - still works
await _iap.requestPurchase('product_id');

// New API - recommended
await _iap.requestPurchase(
  request: RequestPurchase(
    ios: RequestPurchaseIOS(sku: 'product_id'),
    android: RequestPurchaseAndroid(skus: ['product_id']),
  ),
  type: PurchaseType.inapp,
);
```

However, it's recommended to migrate to the new API for better functionality.

## Troubleshooting Questions

### Why are my products not loading?

Common causes and solutions:

```dart
class ProductLoadingIssues {
  static Future<void> diagnose() async {
    // 1. Check connection
    try {
      await FlutterInappPurchase.instance.initConnection();
      print('✓ Connection established');
    } catch (e) {
      print('✗ Connection failed: $e');
      return;
    }
    
    // 2. Verify product IDs
    final testIds = ['your_product_id'];
    print('Testing product IDs: $testIds');
    
    // 3. Check platform-specific issues
    if (Platform.isIOS) {
      print('iOS Checklist:');
      print('- Products "Ready to Submit" in App Store Connect');
      print('- Banking/tax forms completed');
      print('- Bundle ID matches');
      print('- Using sandbox account');
    } else {
      print('Android Checklist:');
      print('- Products active in Play Console');
      print('- App published (at least internal testing)');
      print('- Signed APK/AAB uploaded');
      print('- Tester account added');
    }
    
    // 4. Try loading products
    try {
      final products = await FlutterInappPurchase.instance.getProducts(testIds);
      print('✓ Loaded ${products.length} products');
    } catch (e) {
      print('✗ Product loading failed: $e');
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
  if (Platform.isIOS) {
    // Get all unfinished transactions
    final pending = await FlutterInappPurchase.instance.getAvailableItemsIOS();
    
    if (pending != null) {
      for (final transaction in pending) {
        try {
          // Try to finish the transaction
          await FlutterInappPurchase.instance.finishTransactionIOS(
            transaction,
            isConsumable: true,
          );
          print('Cleared transaction: ${transaction.transactionId}');
        } catch (e) {
          print('Failed to clear: $e');
        }
      }
    }
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
    await ProductCache.getProducts(allProductIds);
  }
  
  // 2. Prepare purchase flow
  static Future<void> preparePurchaseFlow() async {
    // Initialize connection early
    await FlutterInappPurchase.instance.initConnection();
    
    // Set up listeners before user interaction
    setupPurchaseListeners();
    
    // Preload user information
    await getUserIdentifier();
  }
  
  // 3. Optimize UI updates
  static void optimizeUI() {
    // Debounce purchase button
    // Show loading states immediately
    // Cache product displays
  }
}
```

### Should I keep the connection open?

Best practices for connection management:

```dart
class ConnectionManagement {
  // Initialize on app start
  static Future<void> initializeOnAppStart() async {
    await FlutterInappPurchase.instance.initConnection();
  }
  
  // Keep connection alive during purchase flows
  static void maintainConnection() {
    // Don't close connection between purchases
    // Only close when app is terminating
  }
  
  // Clean up on app termination
  static Future<void> cleanup() async {
    await FlutterInappPurchase.instance.endConnection();
  }
}
```

## Additional Resources

### Where can I find more examples?

- [GitHub Repository Examples](https://github.com/hyochan/flutter_inapp_purchase/tree/main/example)
- [Complete Implementation Guide](./complete-implementation.md)
- [API Documentation](../api/flutter-inapp-purchase.md)

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