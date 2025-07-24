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
<<<<<<< HEAD
- **iOS** (12.0+) - Uses StoreKit 2 (iOS 15.0+) with fallback to StoreKit 1
- **Android** (minSdkVersion 21) - Uses Google Play Billing Client v8
=======
- **iOS** (10.0+) - Uses StoreKit 2 (iOS 15.0+) with fallback to StoreKit 1
- **Android** (minSdkVersion 19) - Uses Google Play Billing Client v8

Amazon App Store support is available through a separate implementation.
>>>>>>> 5e86ee0 (docs: Update community links and fix configuration)

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
<<<<<<< HEAD
      quantity: 1,
    ),
    android: RequestPurchaseAndroid(
      skus: ['product_id'],
=======
      appAccountToken: 'user_id',
    ),
    android: RequestPurchaseAndroid(
      skus: ['product_id'],
      obfuscatedAccountIdAndroid: 'user_id',
>>>>>>> 5e86ee0 (docs: Update community links and fix configuration)
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
<<<<<<< HEAD
import 'package:flutter_inapp_purchase/types.dart' as iap_types;
=======
>>>>>>> 5e86ee0 (docs: Update community links and fix configuration)

// 2. Initialize connection
await FlutterInappPurchase.instance.initConnection();

<<<<<<< HEAD
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
=======
// 3. Set up listeners
FlutterInappPurchase.purchaseUpdated.listen((purchase) {
  // Handle successful purchase
});

FlutterInappPurchase.purchaseError.listen((error) {
  // Handle purchase error
>>>>>>> 5e86ee0 (docs: Update community links and fix configuration)
});

// 4. Load products
final products = await FlutterInappPurchase.instance.getProducts([
  'product_id_1',
  'product_id_2',
]);

// 5. Request purchase
await FlutterInappPurchase.instance.requestPurchase(
  request: RequestPurchase(
<<<<<<< HEAD
    ios: RequestPurchaseIOS(sku: 'product_id', quantity: 1),
=======
    ios: RequestPurchaseIOS(sku: 'product_id'),
>>>>>>> 5e86ee0 (docs: Update community links and fix configuration)
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
<<<<<<< HEAD
        ios: RequestPurchaseIOS(sku: productId, quantity: 1),
=======
        ios: RequestPurchaseIOS(sku: productId),
>>>>>>> 5e86ee0 (docs: Update community links and fix configuration)
        android: RequestPurchaseAndroid(skus: [productId]),
      ),
      type: PurchaseType.inapp,
    );
    
<<<<<<< HEAD
    // Handle success in purchaseUpdated listener
=======
    // Always finish consumable transactions
    // Content delivery happens in purchaseUpdated listener
>>>>>>> 5e86ee0 (docs: Update community links and fix configuration)
  }
  
  // Non-consumable products
  Future<void> purchaseNonConsumable(String productId) async {
<<<<<<< HEAD
    // Check if already owned first
    final availablePurchases = await FlutterInappPurchase.instance.getAvailablePurchases();
    final alreadyOwned = availablePurchases.any((purchase) => purchase.productId == productId);
    
    if (alreadyOwned) {
      debugPrint('Product already owned');
=======
    // Check if already owned
    if (await isProductOwned(productId)) {
      print('Product already owned');
>>>>>>> 5e86ee0 (docs: Update community links and fix configuration)
      return;
    }
    
    await FlutterInappPurchase.instance.requestPurchase(
      request: RequestPurchase(
<<<<<<< HEAD
        ios: RequestPurchaseIOS(sku: productId, quantity: 1),
=======
        ios: RequestPurchaseIOS(sku: productId),
>>>>>>> 5e86ee0 (docs: Update community links and fix configuration)
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
    
<<<<<<< HEAD
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
=======
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
>>>>>>> 5e86ee0 (docs: Update community links and fix configuration)
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
<<<<<<< HEAD
        'transactionId': purchase.transactionId,
=======
>>>>>>> 5e86ee0 (docs: Update community links and fix configuration)
        'sandbox': kDebugMode,
      }),
    );
    
    return response.statusCode == 200;
  }
  
<<<<<<< HEAD
  // Android Receipt Validation  
=======
  // Android Receipt Validation
>>>>>>> 5e86ee0 (docs: Update community links and fix configuration)
  Future<bool> validateAndroidReceipt(PurchasedItem purchase) async {
    if (purchase.purchaseToken == null) return false;
    
    final response = await http.post(
      Uri.parse('https://api.yourserver.com/validate-android'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'purchaseToken': purchase.purchaseToken,
        'productId': purchase.productId,
<<<<<<< HEAD
        'dataAndroid': purchase.dataAndroid,
=======
        'packageName': await getPackageName(),
>>>>>>> 5e86ee0 (docs: Update community links and fix configuration)
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
<<<<<<< HEAD
| Offer Codes | `presentCodeRedemptionSheetIOS()` | External Play Store link |
=======
| Offer Codes | `presentCodeRedemptionSheet()` | External Play Store link |
>>>>>>> 5e86ee0 (docs: Update community links and fix configuration)
| Subscription Upgrades | Automatic handling | Manual implementation |
| Transaction Finishing | Required for all | Acknowledgment required |
| Sandbox Testing | Sandbox accounts | Test accounts & reserved IDs |

### How do I handle platform-specific features?

```dart
class PlatformSpecificHandler {
  // iOS-specific features
  Future<void> handleIOSFeatures() async {
    if (!Platform.isIOS) return;
    
<<<<<<< HEAD
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
=======
    // Present offer code redemption
    await FlutterInappPurchase.instance.presentCodeRedemptionSheet();
    
    // Get unfinished transactions
    final pending = await FlutterInappPurchase.instance.getAvailableItemsIOS();
    
    // Get receipt data
    final receipt = await FlutterInappPurchase.instance.getReceiptDataIOS();
>>>>>>> 5e86ee0 (docs: Update community links and fix configuration)
  }
  
  // Android-specific features
  Future<void> handleAndroidFeatures() async {
    if (!Platform.isAndroid) return;
    
    // Handle pending purchases
    FlutterInappPurchase.purchaseUpdated.listen((purchase) {
<<<<<<< HEAD
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
    
    // Get connection state
    try {
      final state = await FlutterInappPurchase.instance.getConnectionStateAndroid();
      debugPrint('Android connection state: $state');
    } catch (e) {
      debugPrint('Failed to get connection state: $e');
    }
=======
      if (purchase?.purchaseStateAndroid == 2) {
        // Purchase is pending
        print('Purchase pending: ${purchase?.productId}');
      }
    });
    
    // Get purchase history
    final history = await FlutterInappPurchase.instance.getPurchaseHistory();
>>>>>>> 5e86ee0 (docs: Update community links and fix configuration)
  }
}
```

### Do I need different product IDs for each platform?

Yes, typically you'll have different product IDs:

```dart
class ProductIds {
  static String getProductId(String baseId) {
    if (Platform.isIOS) {
<<<<<<< HEAD
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
=======
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
>>>>>>> 5e86ee0 (docs: Update community links and fix configuration)
      'android': 'coins_100_android',
    },
  };
  
  static String getMappedId(String key) {
    final platform = Platform.isIOS ? 'ios' : 'android';
    return productMap[key]?[platform] ?? key;
  }
<<<<<<< HEAD
  
  // Example from the actual project
  static const actualProductIds = [
    'dev.hyo.martie.10bulbs',
    'dev.hyo.martie.30bulbs',
  ];
=======
>>>>>>> 5e86ee0 (docs: Update community links and fix configuration)
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
    
<<<<<<< HEAD
    switch (error.responseCode) {
      case 1: // User cancelled
        // Don't show error for user cancellation
        debugPrint('User cancelled purchase');
        break;
        
      case 2: // Network error
        showRetryDialog('Network error. Please check your connection.');
        break;
        
      case 7: // Already owned
=======
    switch (error.code) {
      case ErrorCode.eUserCancelled:
        // Don't show error for user cancellation
        print('User cancelled purchase');
        break;
        
      case ErrorCode.eNetworkError:
        showRetryDialog('Network error. Please check your connection.');
        break;
        
      case ErrorCode.eAlreadyOwned:
>>>>>>> 5e86ee0 (docs: Update community links and fix configuration)
        showMessage('You already own this item.');
        suggestRestorePurchases();
        break;
        
      default:
        showGenericError();
        logError(error);
    }
  }
<<<<<<< HEAD
  
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
=======
>>>>>>> 5e86ee0 (docs: Update community links and fix configuration)
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
<<<<<<< HEAD
    // 2. Add test products  
    // 3. Run app with StoreKit configuration
    
    debugPrint('iOS Testing Setup:');
    debugPrint('- Create sandbox test account in App Store Connect');
    debugPrint('- Products must be "Ready to Submit"');
    debugPrint('- Banking and tax forms must be completed');
=======
    // 2. Add test products
    // 3. Run app with StoreKit configuration
>>>>>>> 5e86ee0 (docs: Update community links and fix configuration)
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
<<<<<<< HEAD
    
    debugPrint('Android Testing Setup:');
    debugPrint('- Upload signed APK to Play Console');
    debugPrint('- Add license testing accounts');
    debugPrint('- Products must be "Active"');
    debugPrint('- Test with: $testProducts');
=======
>>>>>>> 5e86ee0 (docs: Update community links and fix configuration)
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
<<<<<<< HEAD
        if (product.productId != null) {
          _cache[product.productId!] = product;
        }
=======
        _cache[product.productId!] = product;
>>>>>>> 5e86ee0 (docs: Update community links and fix configuration)
      }
      _lastFetch = DateTime.now();
      
      return products;
    } catch (e) {
<<<<<<< HEAD
      debugPrint('Error fetching products: $e');
=======
>>>>>>> 5e86ee0 (docs: Update community links and fix configuration)
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
<<<<<<< HEAD
    ios: RequestPurchaseIOS(sku: 'product_id', quantity: 1),
=======
    ios: RequestPurchaseIOS(sku: 'product_id'),
>>>>>>> 5e86ee0 (docs: Update community links and fix configuration)
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
<<<<<<< HEAD
await _iap.finishTransactionIOS(purchase, isConsumable: true);

// 4. Add null checks to stream listeners
FlutterInappPurchase.purchaseUpdated.listen((purchase) {
  if (purchase != null) {
    // Handle purchase
  }
});
=======
// endConnection -> endConnection (no change)
// initConnection -> initConnection (no change)
>>>>>>> 5e86ee0 (docs: Update community links and fix configuration)
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
<<<<<<< HEAD
   - iOS 12.0+ (was 10.0+)
   - Android minSdk 21 (was 19)
=======
   - iOS 10.0+ (was 9.0+)
   - Android minSdk 19 (no change)
>>>>>>> 5e86ee0 (docs: Update community links and fix configuration)

### Can I use both old and new APIs?

The old string-based API is still supported for backward compatibility:

```dart
// Legacy API - still works
await _iap.requestPurchase('product_id');

// New API - recommended
await _iap.requestPurchase(
  request: RequestPurchase(
<<<<<<< HEAD
    ios: RequestPurchaseIOS(sku: 'product_id', quantity: 1),
=======
    ios: RequestPurchaseIOS(sku: 'product_id'),
>>>>>>> 5e86ee0 (docs: Update community links and fix configuration)
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
<<<<<<< HEAD
class ProductLoadingDiagnostics {
=======
class ProductLoadingIssues {
>>>>>>> 5e86ee0 (docs: Update community links and fix configuration)
  static Future<void> diagnose() async {
    // 1. Check connection
    try {
      await FlutterInappPurchase.instance.initConnection();
<<<<<<< HEAD
      debugPrint('✓ Connection established');
    } catch (e) {
      debugPrint('✗ Connection failed: $e');
=======
      print('✓ Connection established');
    } catch (e) {
      print('✗ Connection failed: $e');
>>>>>>> 5e86ee0 (docs: Update community links and fix configuration)
      return;
    }
    
    // 2. Verify product IDs
    final testIds = ['your_product_id'];
<<<<<<< HEAD
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
=======
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
>>>>>>> 5e86ee0 (docs: Update community links and fix configuration)
    }
    
    // 4. Try loading products
    try {
      final products = await FlutterInappPurchase.instance.getProducts(testIds);
<<<<<<< HEAD
      debugPrint('✓ Loaded ${products.length} products');
      
      for (final product in products) {
        debugPrint('Product: ${product.productId} - ${product.title}');
        debugPrint('Price: ${product.localizedPrice}');
      }
    } catch (e) {
      debugPrint('✗ Product loading failed: $e');
=======
      print('✓ Loaded ${products.length} products');
    } catch (e) {
      print('✗ Product loading failed: $e');
>>>>>>> 5e86ee0 (docs: Update community links and fix configuration)
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
<<<<<<< HEAD
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
=======
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
>>>>>>> 5e86ee0 (docs: Update community links and fix configuration)
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
<<<<<<< HEAD
    final productIds = ['product1', 'product2', 'product3'];
    await ProductCache.getProducts(productIds);
=======
    await ProductCache.getProducts(allProductIds);
>>>>>>> 5e86ee0 (docs: Update community links and fix configuration)
  }
  
  // 2. Prepare purchase flow
  static Future<void> preparePurchaseFlow() async {
    // Initialize connection early
    await FlutterInappPurchase.instance.initConnection();
    
    // Set up listeners before user interaction
    setupPurchaseListeners();
<<<<<<< HEAD
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
  
  static void _processPurchaseImmediately(PurchasedItem purchase) {
    // Implementation for immediate purchase processing
  }
  
  static void _handleErrorImmediately(PurchaseResult error) {
    // Implementation for immediate error handling
=======
    
    // Preload user information
    await getUserIdentifier();
  }
  
  // 3. Optimize UI updates
  static void optimizeUI() {
    // Debounce purchase button
    // Show loading states immediately
    // Cache product displays
>>>>>>> 5e86ee0 (docs: Update community links and fix configuration)
  }
}
```

### Should I keep the connection open?

Best practices for connection management:

```dart
class ConnectionManagement {
  // Initialize on app start
  static Future<void> initializeOnAppStart() async {
<<<<<<< HEAD
    try {
      await FlutterInappPurchase.instance.initConnection();
      debugPrint('IAP connection initialized');
    } catch (e) {
      debugPrint('Failed to initialize IAP connection: $e');
    }
=======
    await FlutterInappPurchase.instance.initConnection();
>>>>>>> 5e86ee0 (docs: Update community links and fix configuration)
  }
  
  // Keep connection alive during purchase flows
  static void maintainConnection() {
    // Don't close connection between purchases
    // Only close when app is terminating
  }
  
  // Clean up on app termination
  static Future<void> cleanup() async {
<<<<<<< HEAD
    try {
      await FlutterInappPurchase.instance.finalize();
      debugPrint('IAP connection closed');
    } catch (e) {
      debugPrint('Failed to close IAP connection: $e');
    }
=======
    await FlutterInappPurchase.instance.endConnection();
>>>>>>> 5e86ee0 (docs: Update community links and fix configuration)
  }
}
```

## Additional Resources

### Where can I find more examples?

- [GitHub Repository Examples](https://github.com/hyochan/flutter_inapp_purchase/tree/main/example)
<<<<<<< HEAD
- [API Documentation](../api/flutter-inapp-purchase.md)
- [Troubleshooting Guide](./troubleshooting.md)
=======
- [Complete Implementation Guide](./complete-implementation.md)
- [API Documentation](../api/flutter-inapp-purchase.md)
>>>>>>> 5e86ee0 (docs: Update community links and fix configuration)

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