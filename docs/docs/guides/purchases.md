---
sidebar_position: 3
title: Purchases
---

<<<<<<< HEAD
=======
# Purchases

>>>>>>> 40157f9 (docs: Update guides and examples content)
Complete guide to implementing in-app purchases with flutter_inapp_purchase v6.0.0, covering everything from basic setup to advanced purchase handling.

## Purchase Flow Overview

The in-app purchase flow follows this standardized pattern:

1. **Initialize Connection** - Establish connection with the store
2. **Setup Purchase Listeners** - Listen for purchase updates and errors  
3. **Load Products** - Fetch product information from the store
4. **Request Purchase** - Initiate purchase flow
5. **Handle Updates** - Process purchase results via streams
6. **Deliver Content** - Provide purchased content to user
7. **Finish Transaction** - Complete the transaction with the store

## Key Concepts

### Purchase Types
- **Consumable**: Can be purchased multiple times (coins, gems, lives)
- **Non-Consumable**: Purchased once, owned forever (premium features, ad removal)  
- **Subscriptions**: Recurring purchases with auto-renewal

### Platform Differences
- **iOS**: Uses StoreKit 2 (iOS 15.0+) with fallback to StoreKit 1
- **Android**: Uses Google Play Billing Client v8
- Both platforms use the same API surface in flutter_inapp_purchase

## Basic Purchase Flow

### 1. Setup Purchase Listeners

Before making any purchases, set up listeners to handle purchase updates and errors:

```dart
import 'dart:async';
import 'dart:io';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

class PurchaseHandler {
  final _iap = FlutterInappPurchase.instance;
  
  StreamSubscription<PurchasedItem?>? _purchaseUpdatedSubscription;
  StreamSubscription<PurchaseResult?>? _purchaseErrorSubscription;
  
  void setupPurchaseListeners() {
    // Listen to successful purchases
    _purchaseUpdatedSubscription = FlutterInappPurchase.purchaseUpdated.listen(
      (purchasedItem) {
        if (purchasedItem != null) {
          debugPrint('Purchase update received: ${purchasedItem.productId}');
          _handlePurchaseUpdate(purchasedItem);
        }
      },
    );

    // Listen to purchase errors
    _purchaseErrorSubscription = FlutterInappPurchase.purchaseError.listen(
      (purchaseError) {
        if (purchaseError != null) {
          debugPrint('Purchase failed: ${purchaseError.message}');
          _handlePurchaseError(purchaseError);
        }
      },
    );
  }
  
  void dispose() {
    _purchaseUpdatedSubscription?.cancel();
    _purchaseErrorSubscription?.cancel();
  }
}
```

### 2. Using with Hooks (Recommended)

For a more structured approach, use this purchase handler pattern:

```dart
class ProductsScreen extends StatefulWidget {
  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final List<String> productIds = [
    'dev.hyo.martie.10bulbs',
    'dev.hyo.martie.30bulbs',
  ];

  String? _purchaseResult;
  bool _isProcessing = false;
  StreamSubscription<PurchasedItem?>? _purchaseUpdatedSubscription;
  StreamSubscription<PurchaseResult?>? _purchaseErrorSubscription;

  @override
  void initState() {
    super.initState();
    _setupPurchaseListeners();
    
    // Load products after initialization
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _loadProducts();
      }
    });
  }

  @override
  void dispose() {
    _purchaseUpdatedSubscription?.cancel();
    _purchaseErrorSubscription?.cancel();
    super.dispose();
  }
  
  // Purchase listener setup...
}
```

### 3. Request a Purchase

Use the new `requestPurchase` API for initiating purchases:

```dart
Future<void> _handlePurchase(String productId) async {
  try {
    setState(() {
      _isProcessing = true;
      _purchaseResult = 'Processing purchase...';
    });

    // Use the new requestPurchase API
    await FlutterInappPurchase.instance.requestPurchase(
      request: RequestPurchase(
        ios: RequestPurchaseIOS(
          sku: productId,
          quantity: 1,
        ),
        android: RequestPurchaseAndroid(
          skus: [productId],
        ),
      ),
      type: PurchaseType.inapp, // or PurchaseType.subs for subscriptions
    );
  } catch (error) {
    setState(() {
      _isProcessing = false;
      _purchaseResult = '❌ Purchase failed: $error';
    });
  }
}
```

## New Platform-Specific API (v2.7.0+)

### New Product Loading API

```dart
Future<void> _loadProducts() async {
  try {
    // Use requestProducts (new API)
    await FlutterInappPurchase.instance.requestProducts(
      RequestProductsParams(
        skus: productIds, 
        type: PurchaseType.inapp
      ),
    );
    
    // Get products from provider or state management
    final products = await FlutterInappPurchase.instance.getProducts(productIds);
    debugPrint('Loaded ${products.length} products');
  } catch (e) {
    debugPrint('Error loading products: $e');
  }
}
```

### Legacy API (Still Supported)

```dart
// Legacy method - still works but deprecated
final products = await FlutterInappPurchase.instance.getProducts(productIds);
final subscriptions = await FlutterInappPurchase.instance.getSubscriptions(subscriptionIds);
```

## New Subscription API (v2.7.0+)

### Subscription Purchase

```dart
Future<void> requestSubscription(String productId) async {
  await FlutterInappPurchase.instance.requestPurchase(
    request: RequestPurchase(
      ios: RequestPurchaseIOS(sku: productId),
      android: RequestPurchaseAndroid(skus: [productId]),
    ),
    type: PurchaseType.subs,
  );
}
```

### Legacy Subscription API

```dart
// Legacy method - still supported
await FlutterInappPurchase.instance.requestSubscription(productId);
```

## Important Notes

### Purchase Flow Best Practices

1. **Always set up listeners first** before making any purchase requests
2. **Handle both success and error cases** appropriately
3. **Show loading states** during purchase processing
4. **Validate purchases server-side** for security
5. **Consume consumable products** after delivery

### Pending Purchases

Handle cases where purchases might be pending:

```dart
Future<void> _handlePurchaseUpdate(PurchasedItem purchasedItem) async {
  debugPrint('Purchase successful: ${purchasedItem.productId}');

  // Deliver the product to the user
  await _deliverProduct(purchasedItem.productId);

  // Finish the transaction
  try {
    if (Platform.isAndroid) {
      // For Android consumable products - consume the purchase
      if (purchasedItem.purchaseToken != null) {
        await FlutterInappPurchase.instance.consumePurchaseAndroid(
          purchaseToken: purchasedItem.purchaseToken!,
        );
        debugPrint('Android purchase consumed successfully');
      }
    } else if (Platform.isIOS) {
      // For iOS - finish the transaction
      await FlutterInappPurchase.instance.finishTransactionIOS(
        purchasedItem,
        isConsumable: true, // Set appropriately for your product type
      );
      debugPrint('iOS transaction finished');
    }
  } catch (e) {
    debugPrint('Error finishing transaction: $e');
  }
}
```

## Getting Product Information

### Retrieving Product Prices

```dart
class ProductInfo {
  static Future<List<IAPItem>> loadProductInformation(List<String> productIds) async {
    try {
      // Request products from store
      await FlutterInappPurchase.instance.requestProducts(
        RequestProductsParams(skus: productIds, type: PurchaseType.inapp),
      );
      
      // Get product details
      final products = await FlutterInappPurchase.instance.getProducts(productIds);
      
      for (final product in products) {
        debugPrint('Product: ${product.productId}');
        debugPrint('Title: ${product.title}');
        debugPrint('Description: ${product.description}');
        debugPrint('Price: ${product.localizedPrice}');
        debugPrint('Currency: ${product.currency}');
      }
      
      return products;
    } catch (e) {
      debugPrint('Error loading product information: $e');
      return [];
    }
  }
}
```

### Platform Support

```dart
class PlatformSupport {
  static Future<bool> checkPurchaseSupport() async {
    try {
      if (Platform.isIOS) {
        // Check if device can make payments
        final canMakePayments = await FlutterInappPurchase.instance.initialize();
        return canMakePayments;
      } else if (Platform.isAndroid) {
        // Check Play Store connection
        final connected = await FlutterInappPurchase.instance.initConnection();
        return connected == 'connected';
      }
      return false;
    } catch (e) {
      debugPrint('Error checking purchase support: $e');
      return false;
    }
  }
}
```

### Checking Platform Compatibility

```dart
void checkPlatformFeatures() {
  if (Platform.isIOS) {
    // iOS-specific features
    debugPrint('iOS platform detected');
    // Can use iOS-specific methods like:
    // - presentCodeRedemptionSheet()
    // - showManageSubscriptions()
    // - isEligibleForIntroOfferIOS()
  } else if (Platform.isAndroid) {
    // Android-specific features  
    debugPrint('Android platform detected');
    // Can use Android-specific methods like:
    // - consumePurchaseAndroid()
    // - deepLinkToSubscriptionsAndroid()
    // - getConnectionStateAndroid()
  }
}
```

## Product Types

### Consumable Products

Products that can be purchased multiple times:

```dart
Future<void> handleConsumableProduct(PurchasedItem purchase) async {
  // Deliver the consumable content (coins, lives, etc.)
  await deliverConsumableProduct(purchase.productId);
  
  // For Android - consume the purchase so it can be bought again
  if (Platform.isAndroid && purchase.purchaseToken != null) {
    await FlutterInappPurchase.instance.consumePurchaseAndroid(
      purchaseToken: purchase.purchaseToken!,
    );
  }
  
  // For iOS - finish transaction
  if (Platform.isIOS) {
    await FlutterInappPurchase.instance.finishTransactionIOS(
      purchase,
      isConsumable: true,
    );
  }
}
```

### Non-Consumable Products

Products purchased once and owned permanently:

```dart
Future<void> handleNonConsumableProduct(PurchasedItem purchase) async {
  // Deliver the permanent content (premium features, ad removal)
  await deliverPermanentProduct(purchase.productId);
  
  // For Android - acknowledge the purchase (don't consume)
  if (Platform.isAndroid && purchase.purchaseToken != null) {
    await FlutterInappPurchase.instance.acknowledgePurchaseAndroid(
      purchaseToken: purchase.purchaseToken!,
    );
  }
  
  // For iOS - finish transaction  
  if (Platform.isIOS) {
    await FlutterInappPurchase.instance.finishTransactionIOS(
      purchase,
      isConsumable: false,
    );
  }
}
```

### Subscriptions

Recurring purchases with auto-renewal:

```dart
Future<void> handleSubscriptionProduct(PurchasedItem purchase) async {
  // Activate subscription for user
  await activateSubscription(purchase.productId);
  
<<<<<<< HEAD
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
=======
  // For Android - acknowledge the subscription
  if (Platform.isAndroid && purchase.purchaseToken != null) {
    await FlutterInappPurchase.instance.acknowledgePurchaseAndroid(
      purchaseToken: purchase.purchaseToken!,
    );
  }
  
  // For iOS - finish transaction
  if (Platform.isIOS) {
    await FlutterInappPurchase.instance.finishTransactionIOS(
      purchase,
      isConsumable: false,
    );
  }
>>>>>>> 40157f9 (docs: Update guides and examples content)
}
```

## Advanced Purchase Handling

### Purchase Restoration

Restore previously purchased items:

```dart
Future<void> restorePurchases() async {
  try {
    // Restore completed transactions
    await FlutterInappPurchase.instance.restorePurchases();
    
    // Get available purchases
    final purchases = await FlutterInappPurchase.instance.getAvailablePurchases();
    
    debugPrint('Restored ${purchases.length} purchases');
    
    // Process each restored purchase
    for (final purchase in purchases) {
      await _deliverProduct(purchase.productId);
    }
    
  } catch (e) {
    debugPrint('Error restoring purchases: $e');
  }
}
```

### Handling Pending Purchases

Handle purchases that are pending approval:

```dart
void _handlePurchaseError(PurchaseResult error) {
  debugPrint('Purchase failed: ${error.message}');

  // Check if error is "You already own this item" (Error code 7)
  if (error.responseCode == 7 || error.message?.contains('already own') == true) {
    debugPrint('User already owns this item. Attempting to consume existing purchase...');
    _consumeExistingPurchase();
  } else {
    // Handle other errors
    _showErrorDialog(error.message ?? 'Unknown error occurred');
  }
}

Future<void> _consumeExistingPurchase() async {
  try {
    // Restore purchases to get all owned items
    await FlutterInappPurchase.instance.restorePurchases();
    
    // Get available purchases
    final purchases = await FlutterInappPurchase.instance.getAvailablePurchases();
    
    // Find and consume purchases for our product IDs
    for (final purchase in purchases) {
      if (productIds.contains(purchase.productId)) {
        if (purchase.purchaseToken != null) {
          await FlutterInappPurchase.instance.consumePurchaseAndroid(
            purchaseToken: purchase.purchaseToken!,
          );
          debugPrint('Successfully consumed: ${purchase.productId}');
        }
      }
    }
  } catch (e) {
    debugPrint('Error during consume process: $e');
  }
}
```

### Subscription Management

Open native subscription management:

```dart
Future<void> openSubscriptionManagement() async {
  try {
    if (Platform.isIOS) {
      await FlutterInappPurchase.instance.showManageSubscriptions();
    } else if (Platform.isAndroid) {
      await FlutterInappPurchase.instance.deepLinkToSubscriptionsAndroid();
    }
  } catch (e) {
    debugPrint('Failed to open subscription management: $e');
  }
}
```

### Receipt Validation

Validate purchases server-side for security:

```dart
Future<bool> validatePurchaseReceipt(PurchasedItem purchase) async {
  try {
    if (Platform.isIOS) {
      // Validate iOS receipt
      final result = await FlutterInappPurchase.instance.validateReceiptIos(
        receiptBody: {
          'receipt-data': purchase.transactionReceipt,
          'password': 'your-shared-secret', // From App Store Connect
        },
        isTest: true, // Set to false for production
      );
      
      return result != null && result['status'] == 0;
      
    } else if (Platform.isAndroid) {
      // Validate Android purchase
      final result = await FlutterInappPurchase.instance.validateReceiptAndroid(
        packageName: 'your.package.name',
        productId: purchase.productId!,
        productToken: purchase.purchaseToken!,
        accessToken: 'your-access-token', // From Google Play Console
        isSubscription: false,
      );
      
<<<<<<< HEAD
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['valid'] == true;
      }
      return false;
    } catch (e) {
      print('Purchase verification failed: $e');
      return false;
    }
=======
      return result != null;
    }
    
    return false;
  } catch (e) {
    debugPrint('Receipt validation failed: $e');
    return false;
>>>>>>> 40157f9 (docs: Update guides and examples content)
  }
}
```

## Error Handling

### Common Purchase Errors

```dart
<<<<<<< HEAD
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
=======
void handlePurchaseError(PurchaseResult error) {
  switch (error.responseCode) {
    case 1: // User cancelled
      debugPrint('User cancelled the purchase');
      break;
    case 2: // Network error
      debugPrint('Network error occurred');
      break;
    case 3: // Billing unavailable
      debugPrint('Billing service unavailable');
      break;
    case 4: // Item unavailable
      debugPrint('Requested item is unavailable');
      break;
    case 5: // Developer error
      debugPrint('Invalid arguments provided to the API');
      break;
    case 6: // Error
      debugPrint('Fatal error during the API action');
      break;
    case 7: // Item already owned
      debugPrint('User already owns this item');
      _handleAlreadyOwned();
      break;
    case 8: // Item not owned
      debugPrint('User does not own this item');
      break;
    default:
      debugPrint('Unknown error: ${error.message}');
>>>>>>> 40157f9 (docs: Update guides and examples content)
  }
}
```

## Testing Purchases

### iOS Testing

Set up iOS testing environment:

```dart
// For iOS testing in sandbox environment
void setupIOSTesting() {
  debugPrint('Testing on iOS Sandbox');
  
  // Use test Apple ID for sandbox testing
  // Products must be configured in App Store Connect
  // Test with different sandbox user accounts
}
```

### Android Testing

Set up Android testing environment:

```dart
// For Android testing with test purchases
void setupAndroidTesting() {
  debugPrint('Testing on Android');
  
  // Use test product IDs like:
  // - android.test.purchased
  // - android.test.canceled  
  // - android.test.refunded
  // - android.test.item_unavailable
  
  final testProductIds = [
    'android.test.purchased', // Always succeeds
    'android.test.canceled',  // Always cancelled
  ];
}
```

## Complete Example

Here's a complete working example based on the project's `products_screen.dart`:

```dart
class PurchaseService {
  final _iap = FlutterInappPurchase.instance;
  
  StreamSubscription<PurchasedItem?>? _purchaseUpdatedSubscription;
  StreamSubscription<PurchaseResult?>? _purchaseErrorSubscription;
  
  void init() {
    _setupPurchaseListeners();
  }
  
  void _setupPurchaseListeners() {
    _purchaseUpdatedSubscription = FlutterInappPurchase.purchaseUpdated.listen(
      (purchasedItem) {
        if (purchasedItem != null) {
          _handlePurchaseSuccess(purchasedItem);
        }
      },
    );

<<<<<<< HEAD
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
=======
    _purchaseErrorSubscription = FlutterInappPurchase.purchaseError.listen(
      (purchaseError) {
        if (purchaseError != null) {
          _handlePurchaseError(purchaseError);
        }
      },
    );
  }
  
  Future<void> _handlePurchaseSuccess(PurchasedItem purchase) async {
    // 1. Deliver product
    await _deliverProduct(purchase.productId);
    
    // 2. Finish transaction
    if (Platform.isAndroid && purchase.purchaseToken != null) {
      await _iap.consumePurchaseAndroid(
        purchaseToken: purchase.purchaseToken!,
      );
    } else if (Platform.isIOS) {
      await _iap.finishTransactionIOS(purchase, isConsumable: true);
    }
  }
  
  void _handlePurchaseError(PurchaseResult error) {
    if (error.responseCode == 7) {
      // Handle "already owned" error
      _consumeExistingPurchases();
    }
  }
  
  Future<void> purchaseProduct(String productId) async {
    await _iap.requestPurchase(
      request: RequestPurchase(
        ios: RequestPurchaseIOS(sku: productId, quantity: 1),
        android: RequestPurchaseAndroid(skus: [productId]),
      ),
      type: PurchaseType.inapp,
    );
  }
  
  void dispose() {
    _purchaseUpdatedSubscription?.cancel();
    _purchaseErrorSubscription?.cancel();
>>>>>>> 40157f9 (docs: Update guides and examples content)
  }
}
```

<<<<<<< HEAD
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
=======
This guide covers the complete purchase flow using the actual flutter_inapp_purchase v6.0.0 API, with examples based on the working code from your project.
>>>>>>> 40157f9 (docs: Update guides and examples content)
