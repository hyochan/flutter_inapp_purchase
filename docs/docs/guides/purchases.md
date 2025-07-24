---
sidebar_position: 3
title: Purchases
---

Complete guide to implementing in-app purchases with flutter_inapp_purchase v6.0.0, covering everything from basic setup to advanced purchase handling.

## Purchase Flow Overview

The in-app purchase flow follows a standardized pattern across iOS and Android:

1. **Initialize Connection** - Establish connection with the store
2. **Setup Listeners** - Listen for purchase updates and errors
3. **Load Products** - Fetch product information from the store
4. **Request Purchase** - Initiate purchase flow
5. **Handle Updates** - Process purchase results via streams
6. **Verify Purchase** - Validate the purchase (server-side recommended)
7. **Deliver Content** - Provide purchased content to user
8. **Finish Transaction** - Complete the transaction with the store

## Key Concepts

### Purchase Types
- **Consumable**: Can be purchased multiple times (coins, gems, lives)
- **Non-Consumable**: Purchased once, owned forever (premium features, ad removal)
- **Subscriptions**: Recurring purchases (covered in [Subscriptions Guide](./subscriptions.md))

### Platform Differences
- **iOS**: Uses StoreKit 2 (iOS 15.0+) with fallback to StoreKit 1
- **Android**: Uses Google Play Billing Client v8
- Both platforms use the same API surface in flutter_inapp_purchase

## Basic Purchase Flow

### 1. Setup Listeners

Before initializing the connection, set up listeners to handle purchase updates and errors:

```dart
import 'dart:async';
import 'dart:io';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

class PurchaseService {
  final _iap = FlutterInappPurchase.instance;
  
  StreamSubscription<PurchasedItem?>? _purchaseUpdatedSubscription;
  StreamSubscription<PurchaseResult?>? _purchaseErrorSubscription;
  
  void setupListeners() {
    // Listen for successful purchases
    _purchaseUpdatedSubscription = FlutterInappPurchase.purchaseUpdated
        .listen((PurchasedItem? purchase) {
      if (purchase != null) {
        print('Purchase successful: ${purchase.productId}');
        _handlePurchaseUpdate(purchase);
      }
    });
    
    // Listen for purchase errors
    _purchaseErrorSubscription = FlutterInappPurchase.purchaseError
        .listen((PurchaseResult? error) {
      if (error != null) {
        print('Purchase error: ${error.message}');
        _handlePurchaseError(error);
      }
    });
  }
  
  void _handlePurchaseUpdate(PurchasedItem purchase) {
    // Process successful purchase
    // This is where you verify and deliver content
  }
  
  void _handlePurchaseError(PurchaseResult error) {
    // Handle purchase errors
    // Show user-friendly error messages
  }
  
  void dispose() {
    _purchaseUpdatedSubscription?.cancel();
    _purchaseErrorSubscription?.cancel();
  }
}
```

### 2. Initialize Connection

```dart
class PurchaseManager {
  final _iap = FlutterInappPurchase.instance;
  bool _connected = false;
  
  Future<void> initialize() async {
    try {
      // Initialize connection to the store
      await _iap.initConnection();
      _connected = true;
      print('Store connection initialized');
      
      // Setup listeners after connection
      _setupListeners();
      
      // Check for pending purchases
      await _checkPendingPurchases();
      
    } catch (e) {
      print('Failed to initialize store connection: $e');
      _connected = false;
    }
  }
  
  Future<void> _checkPendingPurchases() async {
    // iOS only - check for unfinished transactions
    if (Platform.isIOS) {
      final pending = await _iap.getAvailableItemsIOS();
      if (pending != null && pending.isNotEmpty) {
        print('Found ${pending.length} pending purchases');
        // Process pending purchases
      }
    }
  }
  
  Future<void> disconnect() async {
    if (_connected) {
      await _iap.endConnection();
      _connected = false;
    }
  }
}
```

### 3. Request Purchase

With the new v6.0.0 API, purchase requests use platform-specific request objects:

```dart
Future<void> requestPurchase(String productId) async {
  try {
    await _iap.requestPurchase(
      request: RequestPurchase(
        ios: RequestPurchaseIOS(
          sku: productId,
          // Optional: Add user account identifier for receipt validation
          appAccountToken: 'user_id_123',
        ),
        android: RequestPurchaseAndroid(
          skus: [productId],
          // Optional: Add obfuscated account ID
          obfuscatedAccountIdAndroid: 'user_id_123',
        ),
      ),
      type: PurchaseType.inapp,
    );
    // Purchase result will be delivered via purchaseUpdated stream
  } catch (e) {
    print('Purchase request failed: $e');
  }
}
```

## New Platform-Specific API (v6.0.0+)

Version 6.0.0 introduces platform-specific request objects for better type safety and platform-specific features:

### iOS Request Purchase

```dart
// iOS-specific purchase request
await _iap.requestPurchase(
  request: RequestPurchase(
    ios: RequestPurchaseIOS(
      sku: 'product_id',
      // New in v6: App Account Token for receipt validation
      appAccountToken: 'user_unique_identifier',
      // Quantity (for consumables)
      quantity: 1,
      // Enable promotional offers
      requestPromotionalOffer: true,
    ),
  ),
  type: PurchaseType.inapp,
);
```

### Android Request Purchase

```dart
// Android-specific purchase request
await _iap.requestPurchase(
  request: RequestPurchase(
    android: RequestPurchaseAndroid(
      skus: ['product_id'],
      // Obfuscated account ID for purchase tracking
      obfuscatedAccountIdAndroid: 'hashed_user_id',
      // Profile ID for multi-user support
      obfuscatedProfileIdAndroid: 'profile_id',
      // Purchase token for replacing subscriptions
      purchaseToken: 'existing_purchase_token',
    ),
  ),
  type: PurchaseType.inapp,
);
```

## Legacy API (Still Supported)

For backward compatibility, the simple string-based API is still available:

```dart
// Legacy API - still works but less flexible
await _iap.requestPurchase('product_id');
```

## Subscription APIs

For subscription purchases, use `PurchaseType.subs`:

```dart
await _iap.requestPurchase(
  request: RequestPurchase(
    ios: RequestPurchaseIOS(
      sku: 'subscription_id',
      appAccountToken: 'user_id',
    ),
  ),
  type: PurchaseType.subs, // Important: Use subs type
);
```

For detailed subscription handling, see the [Subscriptions Guide](./subscriptions.md).

## Purchase Flow Best Practices

### Complete Purchase Implementation

```dart
class CompletePurchaseService {
  final _iap = FlutterInappPurchase.instance;
  final Set<String> _processingPurchases = {};
  final Set<String> _ownedNonConsumables = {};
  
  // Product definitions
  static const consumableProducts = [
    'com.example.coins_100',
    'com.example.coins_500',
    'com.example.power_boost',
  ];
  
  static const nonConsumableProducts = [
    'com.example.remove_ads',
    'com.example.premium_unlock',
    'com.example.vip_features',
  ];
  
  Future<void> purchaseProduct(String productId) async {
    // 1. Prevent duplicate purchases
    if (_processingPurchases.contains(productId)) {
      print('Purchase already in progress for $productId');
      return;
    }
    
    // 2. Check ownership for non-consumables
    if (isNonConsumable(productId) && _ownedNonConsumables.contains(productId)) {
      _showMessage('You already own this item');
      return;
    }
    
    // 3. Mark as processing
    _processingPurchases.add(productId);
    
    try {
      // 4. Get user identifier for tracking
      final userId = await _getUserIdentifier();
      
      // 5. Request purchase with platform-specific parameters
      await _iap.requestPurchase(
        request: RequestPurchase(
          ios: RequestPurchaseIOS(
            sku: productId,
            appAccountToken: userId,
            quantity: 1,
          ),
          android: RequestPurchaseAndroid(
            skus: [productId],
            obfuscatedAccountIdAndroid: _hashUserId(userId),
          ),
        ),
        type: PurchaseType.inapp,
      );
      
      // 6. Purchase result will be delivered via stream
      print('Purchase request sent for $productId');
      
    } catch (e) {
      print('Purchase request failed: $e');
      _handlePurchaseRequestError(e);
    } finally {
      // 7. Remove from processing
      _processingPurchases.remove(productId);
    }
  }
  
  bool isConsumable(String? productId) =>
      consumableProducts.contains(productId);
  
  bool isNonConsumable(String? productId) =>
      nonConsumableProducts.contains(productId);
  
  String _hashUserId(String userId) {
    // Simple hash for demo - use proper hashing in production
    return userId.hashCode.toString();
  }
}
```

## Pending Purchases

### Handling Pending Transactions

Pending purchases occur when:
- Payment is delayed (e.g., waiting for parental approval)
- Network issues during purchase
- App crashes during transaction

```dart
class PendingPurchaseHandler {
  final _iap = FlutterInappPurchase.instance;
  
  Future<void> checkPendingPurchases() async {
    if (Platform.isIOS) {
      // iOS: Get unfinished transactions
      final pending = await _iap.getAvailableItemsIOS();
      
      if (pending != null && pending.isNotEmpty) {
        print('Found ${pending.length} pending purchases');
        
        for (final purchase in pending) {
          // Process each pending purchase
          await _processPendingPurchase(purchase);
        }
      }
    } else if (Platform.isAndroid) {
      // Android: Pending purchases come through purchaseUpdated stream
      // with purchaseState = 2 (pending)
    }
  }
  
  Future<void> _processPendingPurchase(PurchasedItem purchase) async {
    print('Processing pending purchase: ${purchase.productId}');
    
    // Check purchase state
    if (purchase.purchaseStateAndroid == 2) {
      // Android: Pending state
      print('Purchase is pending payment');
      _showPendingMessage();
    } else {
      // Complete the purchase flow
      await _handlePurchaseUpdate(purchase);
    }
  }
}
```

## Getting Product Information

### Loading and Displaying Products

```dart
class ProductService {
  final _iap = FlutterInappPurchase.instance;
  List<IAPItem> _products = [];
  List<IAPItem> _subscriptions = [];
  
  Future<List<IAPItem>> loadProducts(List<String> productIds) async {
    try {
      // Load in-app products
      _products = await _iap.getProducts(productIds);
      
      print('Loaded ${_products.length} products');
      
      // Sort by price (optional)
      _products.sort((a, b) => 
        (a.priceNumber ?? 0).compareTo(b.priceNumber ?? 0));
      
      return _products;
    } catch (e) {
      print('Failed to load products: $e');
      return [];
    }
  }
  
  Future<List<IAPItem>> loadSubscriptions(List<String> subscriptionIds) async {
    try {
      // Load subscription products
      _subscriptions = await _iap.getSubscriptions(subscriptionIds);
      
      print('Loaded ${_subscriptions.length} subscriptions');
      return _subscriptions;
    } catch (e) {
      print('Failed to load subscriptions: $e');
      return [];
    }
  }
  
  // Get product by ID
  IAPItem? getProduct(String productId) {
    return [..._products, ..._subscriptions]
        .firstWhere((p) => p.productId == productId, 
                   orElse: () => throw Exception('Product not found'));
  }
}
```

### Product Information Available

```dart
// IAPItem properties available after loading:
class ProductInfo {
  void displayProduct(IAPItem product) {
    print('Product ID: ${product.productId}');
    print('Title: ${product.title}');
    print('Description: ${product.description}');
    print('Price: ${product.localizedPrice}'); // e.g., "$0.99"
    print('Price Number: ${product.priceNumber}'); // e.g., 0.99
    print('Currency: ${product.currency}'); // e.g., "USD"
    print('Currency Symbol: ${product.currencySymbol}'); // e.g., "$"
    
    // iOS specific
    if (Platform.isIOS) {
      print('Is downloadable: ${product.isDownloadable}');
      print('Download content version: ${product.downloadContentVersion}');
    }
    
    // Android specific
    if (Platform.isAndroid) {
      print('Original JSON: ${product.originalJson}');
      print('Signature: ${product.signatureAndroid}');
    }
  }
}
```

## Product Types

### Consumable Products

Consumable products can be purchased multiple times and are "consumed" after use:

```dart
class ConsumableHandler {
  // Common consumable products
  static const consumables = {
    'coins_100': {'type': 'currency', 'amount': 100},
    'coins_500': {'type': 'currency', 'amount': 500},
    'coins_1000': {'type': 'currency', 'amount': 1000},
    'energy_refill': {'type': 'energy', 'amount': 'full'},
    'hint_pack_5': {'type': 'hints', 'amount': 5},
    'power_boost': {'type': 'boost', 'duration': 3600}, // 1 hour
  };
  
  Future<void> deliverConsumable(String productId) async {
    final product = consumables[productId];
    if (product == null) return;
    
    switch (product['type']) {
      case 'currency':
        await _addCurrency(product['amount'] as int);
        break;
      case 'energy':
        await _refillEnergy();
        break;
      case 'hints':
        await _addHints(product['amount'] as int);
        break;
      case 'boost':
        await _activateBoost(product['duration'] as int);
        break;
    }
  }
  
  Future<void> _addCurrency(int amount) async {
    final currentCoins = await _getCoins();
    await _saveCoins(currentCoins + amount);
    print('Added $amount coins');
  }
}
```

### Non-Consumable Products

Non-consumable products are purchased once and owned forever:

```dart
class NonConsumableHandler {
  // Common non-consumable products
  static const nonConsumables = {
    'remove_ads': 'ads_removed',
    'premium_unlock': 'premium_features',
    'all_levels': 'all_levels_unlocked',
    'pro_tools': 'pro_tools_enabled',
    'theme_pack': 'additional_themes',
  };
  
  final Set<String> _ownedProducts = {};
  
  Future<void> deliverNonConsumable(String productId) async {
    // Add to owned products
    _ownedProducts.add(productId);
    await _saveOwnedProducts();
    
    // Enable features
    final feature = nonConsumables[productId];
    if (feature != null) {
      await _enableFeature(feature);
    }
  }
  
  Future<void> _enableFeature(String feature) async {
    switch (feature) {
      case 'ads_removed':
        await _disableAds();
        break;
      case 'premium_features':
        await _unlockPremiumFeatures();
        break;
      case 'all_levels_unlocked':
        await _unlockAllLevels();
        break;
      // Add more features as needed
    }
  }
  
  bool ownsProduct(String productId) {
    return _ownedProducts.contains(productId);
  }
}
```

### Subscriptions

Subscriptions are recurring purchases with expiration dates:

```dart
class SubscriptionHandler {
  // Common subscription tiers
  static const subscriptions = {
    'monthly_basic': {'duration': 'P1M', 'tier': 'basic'},
    'monthly_premium': {'duration': 'P1M', 'tier': 'premium'},
    'yearly_basic': {'duration': 'P1Y', 'tier': 'basic'},
    'yearly_premium': {'duration': 'P1Y', 'tier': 'premium'},
  };
  
  Future<bool> isSubscriptionActive(String productId) async {
    if (Platform.isIOS) {
      // Check receipt for active subscription
      final purchases = await _iap.getAvailableItemsIOS();
      return purchases?.any((p) => p.productId == productId) ?? false;
    } else {
      // Android: Check purchase state and expiry
      // Implementation depends on your backend
      return false;
    }
}
```

## Advanced Purchase Handling

### Complete Purchase Update Handler

```dart
class PurchaseUpdateHandler {
  final _iap = FlutterInappPurchase.instance;
  final _verificationService = PurchaseVerificationService();
  final _contentDelivery = ContentDeliveryService();
  
  Future<void> handlePurchaseUpdate(PurchasedItem purchase) async {
    print('Processing purchase: ${purchase.productId}');
    
    try {
      // 1. Check if already processed (prevent duplicates)
      if (await _isAlreadyProcessed(purchase)) {
        print('Purchase already processed');
        await _finishTransaction(purchase);
        return;
      }
      
      // 2. Verify the purchase
      final isValid = await _verifyPurchase(purchase);
      if (!isValid) {
        print('Invalid purchase detected');
        // Don't finish transaction for invalid purchases
        return;
      }
      
      // 3. Deliver content
      await _deliverContent(purchase);
      
      // 4. Record the transaction
      await _recordTransaction(purchase);
      
      // 5. Finish the transaction
      await _finishTransaction(purchase);
      
      // 6. Update UI
      _notifyPurchaseSuccess(purchase);
      
    } catch (e) {
      print('Error processing purchase: $e');
      // Don't finish transaction on error
      // User can retry or restore purchases
    }
  }
  
  Future<bool> _verifyPurchase(PurchasedItem purchase) async {
    if (Platform.isIOS) {
      return await _verifyIOSPurchase(purchase);
    } else {
      return await _verifyAndroidPurchase(purchase);
    }
  }
  
  Future<bool> _verifyIOSPurchase(PurchasedItem purchase) async {
    if (purchase.transactionReceipt == null) return false;
    
    // Send receipt to your server for validation
    return await _verificationService.verifyIOSReceipt(
      receipt: purchase.transactionReceipt!,
      productId: purchase.productId!,
      transactionId: purchase.transactionId!,
    );
  }
  
  Future<bool> _verifyAndroidPurchase(PurchasedItem purchase) async {
    if (purchase.purchaseToken == null) return false;
    
    // Verify with Google Play
    return await _verificationService.verifyAndroidPurchase(
      purchaseToken: purchase.purchaseToken!,
      productId: purchase.productId!,
      packageName: purchase.dataAndroid?['packageName'],
    );
  }
  
  Future<void> _finishTransaction(PurchasedItem purchase) async {
    final isConsumable = ConsumableHandler.consumables
        .containsKey(purchase.productId);
    
    await _iap.finishTransactionIOS(
      purchase,
      isConsumable: isConsumable,
    );
  }
}
```

### Purchase Verification Service

```dart
class PurchaseVerificationService {
  final String _serverUrl = 'https://api.example.com';
  
  Future<bool> verifyIOSReceipt({
    required String receipt,
    required String productId,
    required String transactionId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_serverUrl/verify-ios'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getAuthToken()}',
        },
        body: json.encode({
          'receipt': receipt,
          'productId': productId,
          'transactionId': transactionId,
          'sandbox': kDebugMode, // Use sandbox in debug mode
        }),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['valid'] == true;
      }
      return false;
    } catch (e) {
      print('Receipt verification failed: $e');
      return false;
    }
  }
  
  Future<bool> verifyAndroidPurchase({
    required String purchaseToken,
    required String productId,
    String? packageName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_serverUrl/verify-android'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getAuthToken()}',
        },
        body: json.encode({
          'purchaseToken': purchaseToken,
          'productId': productId,
          'packageName': packageName ?? await _getPackageName(),
        }),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['valid'] == true;
      }
      return false;
    } catch (e) {
      print('Purchase verification failed: $e');
      return false;
    }
  }
}
```

## Error Handling

### Comprehensive Error Handler

```dart
class PurchaseErrorHandler {
  void handlePurchaseError(PurchaseResult? error) {
    if (error == null) return;
    
    print('Purchase error: ${error.code} - ${error.message}');
    
    // Map error codes to user-friendly messages
    String userMessage;
    bool isRecoverable = false;
    
    switch (error.code) {
      case ErrorCode.eUserCancelled:
        userMessage = 'Purchase cancelled';
        isRecoverable = false;
        break;
        
      case ErrorCode.eNetworkError:
        userMessage = 'Network error. Please check your connection and try again.';
        isRecoverable = true;
        break;
        
      case ErrorCode.eItemUnavailable:
        userMessage = 'This item is currently unavailable.';
        isRecoverable = false;
        break;
        
      case ErrorCode.eAlreadyOwned:
        userMessage = 'You already own this item. Try restoring purchases.';
        isRecoverable = false;
        _suggestRestore();
        break;
        
      case ErrorCode.eServiceDisconnected:
        userMessage = 'Store service disconnected. Please restart the app.';
        isRecoverable = true;
        break;
        
      case ErrorCode.eDeveloperError:
        userMessage = 'Configuration error. Please contact support.';
        isRecoverable = false;
        _logDeveloperError(error);
        break;
        
      case ErrorCode.eServiceUnavailable:
        userMessage = 'Store service is temporarily unavailable.';
        isRecoverable = true;
        break;
        
      case ErrorCode.eBillingUnavailable:
        userMessage = 'Billing is not available on this device.';
        isRecoverable = false;
        break;
        
      case ErrorCode.eServiceTimeout:
        userMessage = 'Request timed out. Please try again.';
        isRecoverable = true;
        break;
        
      case ErrorCode.eFeatureNotSupported:
        userMessage = 'This feature is not supported on your device.';
        isRecoverable = false;
        break;
        
      default:
        userMessage = 'Purchase failed. Please try again later.';
        isRecoverable = true;
    }
    
    _showErrorDialog(
      title: 'Purchase Error',
      message: userMessage,
      isRecoverable: isRecoverable,
      onRetry: isRecoverable ? () => _retryLastPurchase() : null,
    );
  }
  
  void _showErrorDialog({
    required String title,
    required String message,
    required bool isRecoverable,
    VoidCallback? onRetry,
  }) {
    // Show error dialog to user
    showDialog(
      context: _context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
          if (isRecoverable && onRetry != null)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                onRetry();
              },
              child: Text('Retry'),
            ),
        ],
      ),
    );
  }
}
```

## Testing Purchases

### Test Configuration

```dart
class PurchaseTestConfig {
  static bool get isTestMode => kDebugMode;
  
  // Test product IDs for different scenarios
  static const testProducts = {
    // Android test products
    'android.test.purchased': 'Always succeeds',
    'android.test.canceled': 'Always cancelled by user',
    'android.test.refunded': 'Always refunded',
    'android.test.item_unavailable': 'Always unavailable',
    
    // iOS sandbox products (configure in App Store Connect)
    'com.example.test_consumable': 'Test consumable',
    'com.example.test_nonconsumable': 'Test non-consumable',
    'com.example.test_subscription': 'Test subscription',
  };
  
  static List<String> getTestProductIds() {
    if (Platform.isAndroid && isTestMode) {
      return testProducts.keys.where((id) => id.startsWith('android.test')).toList();
    }
    return [];
  }
}
```

### Testing Different Scenarios

```dart
class PurchaseTestScenarios {
  final _iap = FlutterInappPurchase.instance;
  
  // Test successful purchase
  Future<void> testSuccessfulPurchase() async {
    if (Platform.isAndroid) {
      await _iap.requestPurchase(
        request: RequestPurchase(
          android: RequestPurchaseAndroid(
            skus: ['android.test.purchased'],
          ),
        ),
        type: PurchaseType.inapp,
      );
    }
  }
  
  // Test cancelled purchase
  Future<void> testCancelledPurchase() async {
    if (Platform.isAndroid) {
      await _iap.requestPurchase(
        request: RequestPurchase(
          android: RequestPurchaseAndroid(
            skus: ['android.test.canceled'],
          ),
        ),
        type: PurchaseType.inapp,
      );
    }
  }
  
  // Test restore purchases
  Future<void> testRestorePurchases() async {
    try {
      await _iap.restorePurchases();
      
      if (Platform.isIOS) {
        final restored = await _iap.getAvailableItemsIOS();
        print('Restored ${restored?.length ?? 0} purchases');
      }
    } catch (e) {
      print('Restore test failed: $e');
    }
  }
}
```

## Next Steps

### 1. Implement Receipt Validation

Always validate purchases server-side for security:
- See [Receipt Validation Guide](./receipt-validation.md)
- Set up server endpoints for iOS and Android
- Implement retry logic for failed validations

### 2. Handle Subscriptions

For subscription products:
- See [Subscriptions Guide](./subscriptions.md)
- Implement subscription status checking
- Handle upgrades/downgrades
- Manage trial periods

### 3. Analytics and Monitoring

Track purchase metrics:
```dart
class PurchaseAnalytics {
  static void trackPurchaseEvent(String event, Map<String, dynamic> params) {
    // Log to your analytics service
    analytics.logEvent(event, parameters: {
      ...params,
      'platform': Platform.operatingSystem,
      'app_version': packageInfo.version,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  static void trackPurchaseSuccess(PurchasedItem purchase) {
    trackPurchaseEvent('purchase_success', {
      'product_id': purchase.productId,
      'transaction_id': purchase.transactionId,
      'price': purchase.priceAmountMicros ?? 0 / 1000000,
      'currency': purchase.priceCurrencyCode,
    });
  }
  
  static void trackPurchaseFailure(String productId, String error) {
    trackPurchaseEvent('purchase_failure', {
      'product_id': productId,
      'error': error,
    });
  }
}
```

### 4. Production Checklist

Before going live:
- [ ] Server-side receipt validation implemented
- [ ] Error handling covers all scenarios
- [ ] Restore purchases functionality tested
- [ ] Analytics tracking in place
- [ ] Test accounts removed from production
- [ ] Products configured in both stores
- [ ] Privacy policy includes purchase data handling
- [ ] Refund policy clearly stated

### 5. Common Pitfalls to Avoid

1. **Not finishing transactions**: Always call `finishTransaction`
2. **No receipt validation**: Vulnerable to fraud
3. **Poor error handling**: Users get stuck
4. **Not handling pending purchases**: Lost revenue
5. **Hardcoded product IDs**: Use configuration
6. **No restore functionality**: Users lose purchases
7. **Testing in production**: Use sandbox/test accounts

## Additional Resources

### Example Implementation

For a complete working example, check the [example app](https://github.com/hyochan/flutter_inapp_purchase/tree/main/example) in the repository.

### API Reference

- [FlutterInappPurchase API](../api/flutter-inapp-purchase.md)
- [RequestPurchase API](../api/request-purchase.md)
- [IAPItem Model](../api/iap-item.md)
- [PurchasedItem Model](../api/purchased-item.md)

### Platform Documentation

- [Apple StoreKit Documentation](https://developer.apple.com/documentation/storekit)
- [Google Play Billing Documentation](https://developer.android.com/google/play/billing)

### Community Support

- [GitHub Issues](https://github.com/hyochan/flutter_inapp_purchase/issues)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/flutter-inapp-purchase)
- [Flutter Community](https://flutter.dev/community)
