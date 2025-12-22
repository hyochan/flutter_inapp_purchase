---
sidebar_position: 3
title: Purchases
---

import IapKitBanner from "@site/src/uis/IapKitBanner";

# Purchases

<IapKitBanner />

Complete guide to implementing in-app purchases with flutter_inapp_purchase v6.8.0, covering everything from basic setup to advanced purchase handling.

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
  // Using singleton instance for in-app purchases
  final _iap = FlutterInappPurchase.instance;

  StreamSubscription<Purchase?>? _purchaseUpdatedSubscription;
  StreamSubscription<PurchaseResult?>? _purchaseErrorSubscription;

  void setupPurchaseListeners() {
    // Listen to successful purchases
    _purchaseUpdatedSubscription = _iap.purchaseUpdated.listen(
      (purchase) {
        if (purchase != null) {
          debugPrint('Purchase update received: ${purchase.productId}');
          _handlePurchaseUpdate(purchase);
        }
      },
    );

    // Listen to purchase errors
    _purchaseErrorSubscription = _iap.purchaseError.listen(
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

### 2. Request a Purchase

Use the new `requestPurchase` API for initiating purchases:

```dart
Future<void> _handlePurchase(String productId) async {
  // Using singleton instance for in-app purchases
  final iap = FlutterInappPurchase.instance;

  try {
    setState(() {
      _isProcessing = true;
      _purchaseResult = 'Processing purchase...';
    });

    // Use the new requestPurchase API
    final requestProps = RequestPurchaseProps.inApp(
      request: RequestPurchasePropsByPlatforms(
        ios: RequestPurchaseIosProps(
          sku: productId,
          quantity: 1,
        ),
        android: RequestPurchaseAndroidProps(
          skus: [productId],
        ),
      ),
    );

    await iap.requestPurchase(requestProps);
  } catch (error) {
    setState(() {
      _isProcessing = false;
      _purchaseResult = '❌ Purchase failed: $error';
    });
  }
}
```

## New Platform-Specific API (v6.7.0+)

### New Product Loading API

```dart
Future<void> _loadProducts() async {
  try {
    final products = await FlutterInappPurchase.instance.fetchProducts(
      ProductRequest(
        skus: productIds,
        type: ProductQueryType.InApp,
      ),
    );

    // Get products from provider or state management
    debugPrint('Loaded ${products.length} products');
  } catch (e) {
    debugPrint('Error loading products: $e');
  }
}
```

## New Subscription API (v6.7.0+)

### Subscription Purchase

```dart
Future<void> requestPurchase(String productId) async {
  final requestProps = RequestPurchaseProps.subs(
    request: RequestSubscriptionPropsByPlatforms(
      ios: RequestSubscriptionIosProps(
        sku: productId,
      ),
      android: RequestSubscriptionAndroidProps(
        skus: [productId],
      ),
    ),
  );

  await FlutterInappPurchase.instance.requestPurchase(requestProps);
}
```

### Legacy Subscription API

```dart
// Legacy method - still supported
await FlutterInappPurchase.instance.requestPurchase(productId);
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
Future<void> _handlePurchaseUpdate(Purchase purchasedItem) async {
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
      await FlutterInappPurchase.instance.finishTransaction(
        purchase: purchasedItem,
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
  static Future<List<ProductCommon>> loadProductInformation(List<String> productIds) async {
    try {
      // Request products from store
      final result = await FlutterInappPurchase.instance.fetchProducts(
        ProductRequest(
          skus: productIds,
          type: ProductQueryType.InApp,
        ),
      );

      // Get product details

      for (final product in products) {
        debugPrint('Product: ${product.productId}');
        debugPrint('Title: ${product.title}');
        debugPrint('Description: ${product.description}');
        debugPrint('Price: ${product.displayPrice}');
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
      // Initialize connection for both platforms
      final initialized = await FlutterInappPurchase.instance.initConnection();
      return initialized;
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
  }
}
```

## Product Types

### Consumable Products

Products that can be purchased multiple times:

```dart
Future<void> handleConsumableProduct(Purchase purchase) async {
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
    await FlutterInappPurchase.instance.finishTransaction(
      purchase: purchase,
      isConsumable: true,
    );
  }
}
```

### Non-Consumable Products

Products purchased once and owned permanently:

```dart
Future<void> handleNonConsumableProduct(Purchase purchase) async {
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
    await FlutterInappPurchase.instance.finishTransaction(
      purchase: purchase,
      isConsumable: false,
    );
  }
}
```

### Subscriptions

Recurring purchases with auto-renewal:

```dart
Future<void> handleSubscriptionProduct(Purchase purchase) async {
  // Activate subscription for user
  await activateSubscription(purchase.productId);

  // For Android - acknowledge the subscription
  if (Platform.isAndroid && purchase.purchaseToken != null) {
    await FlutterInappPurchase.instance.acknowledgePurchaseAndroid(
      purchaseToken: purchase.purchaseToken!,
    );
  }

  // For iOS - finish transaction
  if (Platform.isIOS) {
    await FlutterInappPurchase.instance.finishTransaction(
      purchase: purchase,
      isConsumable: false,
    );
  }
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
      await FlutterInappPurchase.instance.showManageSubscriptionsIOS();
    } else if (Platform.isAndroid) {
      await FlutterInappPurchase.instance.deepLinkToSubscriptions();
    }
  } catch (e) {
    debugPrint('Failed to open subscription management: $e');
  }
}
```

### Receipt Validation

Validate purchases server-side for security:

```dart
Future<bool> validatePurchaseReceipt(Purchase purchase) async {
  try {
    if (Platform.isIOS) {
      // Validate iOS receipt using StoreKit 2
      final result = await FlutterInappPurchase.instance.validateReceiptIOS(
        ValidateReceiptIosPropsInput(
          sku: purchase.productId,
        ),
      );

      return result.isValid;

    } else if (Platform.isAndroid) {
      // For Android, validate purchase token on your backend server
      // Send purchase.purchaseToken to your server for validation
      // via Google Play Developer API

      return await validateOnBackendServer(purchase);
    }

    return false;
  } catch (e) {
    debugPrint('Receipt validation failed: $e');
    return false;
  }
}
```

## Error Handling

### Common Purchase Errors

```dart
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

  StreamSubscription<Purchase?>? _purchaseUpdatedSubscription;
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

    _purchaseErrorSubscription = FlutterInappPurchase.purchaseError.listen(
      (purchaseError) {
        if (purchaseError != null) {
          _handlePurchaseError(purchaseError);
        }
      },
    );
  }

  Future<void> _handlePurchaseSuccess(Purchase purchase) async {
    // 1. Deliver product
    await _deliverProduct(purchase.productId);

    // 2. Finish transaction
    if (Platform.isAndroid && purchase.purchaseToken != null) {
      await _iap.consumePurchaseAndroid(
        purchaseToken: purchase.purchaseToken!,
      );
    } else if (Platform.isIOS) {
      await _iap.finishTransaction(purchase: purchase, isConsumable: true);
    }
  }

  void _handlePurchaseError(PurchaseResult error) {
    if (error.responseCode == 7) {
      // Handle "already owned" error
      _consumeExistingPurchases();
    }
  }

  Future<void> purchaseProduct(String productId) async {
    final requestProps = RequestPurchaseProps.inApp(
      request: RequestPurchasePropsByPlatforms(
        ios: RequestPurchaseIosProps(
          sku: productId,
          quantity: 1,
        ),
        android: RequestPurchaseAndroidProps(
          skus: [productId],
        ),
      ),
    );

    await _iap.requestPurchase(requestProps);
  }

  void dispose() {
    _purchaseUpdatedSubscription?.cancel();
    _purchaseErrorSubscription?.cancel();
  }
}
```

This guide covers the complete purchase flow using the actual flutter_inapp_purchase v6.8.0 API, with examples based on the working code from your project.
