---
sidebar_position: 1
title: FlutterInappPurchase
---

import IapKitBanner from "@site/src/uis/IapKitBanner";

# FlutterInappPurchase Class

<IapKitBanner />

The main class for handling in-app purchases in Flutter applications. This class provides a comprehensive API for managing purchases on both iOS and Android platforms.

## Overview

`FlutterInappPurchase` is a singleton class that manages the connection to platform-specific purchase services (App Store for iOS, Google Play for Android). It handles product queries, purchase flows, and transaction management.

## Properties

### Static Properties

```dart
static FlutterInappPurchase instance
```

The singleton instance of the FlutterInappPurchase class.

### Streams

```dart
Stream<Purchase?> purchaseUpdated
```

Stream that emits purchase updates when a transaction state changes.

```dart
Stream<PurchaseResult?> purchaseError
```

Stream that emits purchase errors when a transaction fails.

```dart
Stream<ConnectionResult> connectionUpdated
```

Stream that emits connection state updates.

```dart
Stream<String?> purchasePromoted
```

Stream that emits promoted product IDs (iOS only).

### Instance Streams (expo-iap compatible)

```dart
Stream<Purchase> purchaseUpdatedListener
```

Purchase updated event stream compatible with expo-iap.

```dart
Stream<PurchaseError> purchaseErrorListener
```

Purchase error event stream compatible with expo-iap.

## Methods

### Connection Management

#### initConnection()

```dart
Future<void> initConnection()
```

Initializes the connection to the platform's billing service. Must be called before any other purchase-related operations.

**Throws:**

- `PurchaseError` with `E_ALREADY_INITIALIZED` if already initialized
- `PurchaseError` with `E_NOT_INITIALIZED` if initialization fails

#### endConnection()

```dart
Future<void> endConnection()
```

Ends the connection to the platform's billing service. Should be called when the app no longer needs IAP functionality.

### Product Management

#### fetchProducts()

```dart
Future<List<ProductCommon>> fetchProducts({
  required List<String> skus,
  PurchaseType type = PurchaseType.inapp,
})
```

Fetches product information from the store.

**Parameters:**

- `skus`: List of product identifiers
- `type`: Product type (optional, defaults to `PurchaseType.inapp`)

**Returns:**

- List of products (either `Product` or `Subscription` instances)

**Example:**

```dart
final products = await FlutterInappPurchase.instance.fetchProducts(
  skus: ['com.example.premium', 'com.example.pro'],
  type: PurchaseType.inapp,
);
```

#### fetchProducts()

```dart
Future<List<IapItem>> fetchProducts({
  required List<String> skus,
  PurchaseType type = PurchaseType.inapp,
})
```

Unified method to retrieve products or subscriptions.

- `type: 'inapp'` - for regular products (consumables and non-consumables)
- `type: 'subs'` - for subscription products

### Purchase Management

#### requestPurchase()

```dart
Future<void> requestPurchase({
  required RequestPurchase request,
  required PurchaseType type,
})
```

Initiates a purchase flow for the specified product.

**Parameters:**

- `request`: Platform-specific purchase request parameters
- `type`: Type of purchase (inapp or subscription)

**Example:**

```dart
await FlutterInappPurchase.instance.requestPurchase(
  request: RequestPurchase(
    ios: RequestPurchaseIOS(
      sku: 'com.example.premium',
      appAccountToken: 'user123',
    ),
  ),
  type: PurchaseType.inapp,
);
```

#### finishTransaction()

```dart
Future<String?> finishTransaction(Purchase purchase, {bool isConsumable = false})
```

Completes a transaction and removes it from the queue.

**Parameters:**

- `purchase`: The purchase to finish
- `isConsumable`: Whether the product is consumable (Android only)

### Purchase History

#### getAvailablePurchases()

```dart
Future<List<Purchase>> getAvailablePurchases([PurchaseOptions? options])
```

Retrieves available (unfinished) purchases. Pass `PurchaseOptions` to include expired iOS subscriptions or publish restored purchases through the event stream.

```dart
// Active purchases only (default)
final activePurchases = await FlutterInappPurchase.instance.getAvailablePurchases();

// Include expired iOS subscriptions and re-emit through purchaseUpdated listener
final allPurchases = await FlutterInappPurchase.instance.getAvailablePurchases(
  PurchaseOptions(
    onlyIncludeActiveItemsIOS: false,
    alsoPublishToEventListenerIOS: true,
  ),
);
```

### Platform-Specific Methods

#### iOS Only

##### presentCodeRedemptionSheetIOS()

```dart
Future<void> presentCodeRedemptionSheetIOS()
```

Shows the App Store's code redemption sheet (iOS 16+).

##### showManageSubscriptionsIOS()

```dart
Future<void> showManageSubscriptionsIOS()
```

Opens the subscription management screen (iOS 15+).

##### getStorefrontIOS()

```dart
Future<AppStoreInfo?> getStorefrontIOS()
```

Retrieves the current App Store storefront information.

#### Android Only

##### deepLinkToSubscriptionsAndroid()

```dart
Future<void> deepLinkToSubscriptionsAndroid({
  required String sku,
  required String packageName,
})
```

Opens the Google Play subscription management screen for a specific product.

##### acknowledgePurchaseAndroid()

```dart
Future<void> acknowledgePurchaseAndroid({required String purchaseToken})
```

Acknowledges a purchase on Android (required within 3 days).

### Receipt Validation

#### validateReceiptIos()

```dart
Future<http.Response> validateReceiptIos({
  required Map<String, String> receiptBody,
  bool isTest = true,
})
```

Validates a receipt with Apple's verification service.

#### validateReceiptAndroid()

```dart
Future<http.Response> validateReceiptAndroid({
  required String packageName,
  required String productId,
  required String productToken,
  required String accessToken,
  bool isSubscription = false,
})
```

Validates a receipt with Google's verification API.

## Usage Example

```dart
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

class StoreService {
  final _iap = FlutterInappPurchase.instance;

  Future<void> initialize() async {
    // Initialize connection
    await _iap.initConnection();

    // Listen to purchase updates
    _iap.purchaseUpdatedListener.listen((purchase) {
      _handlePurchase(purchase);
    });

    // Listen to purchase errors
    _iap.purchaseErrorListener.listen((error) {
      _handleError(error);
    });
  }

  Future<void> buyProduct(String productId) async {
    await _iap.requestPurchase(
      request: RequestPurchase(
        ios: RequestPurchaseIOS(sku: productId),
        android: RequestPurchaseAndroid(skus: [productId]),
      ),
      type: PurchaseType.inapp,
    );
  }

  void _handlePurchase(Purchase purchase) {
    // Process the purchase
    print('Purchase completed: ${purchase.productId}');
  }

  void _handleError(PurchaseResult error) {
    // Handle the error
    print('Purchase failed: ${error.message}');
  }
}
```

## Migration Notes

This class maintains backward compatibility with the original API while also providing expo-iap compatible methods. When migrating from expo-iap, you can use the new methods that match the expo-iap interface:

- `initConnection()` instead of `initialize()`
- `fetchProducts()` with `ProductQueryType` to load products and subscriptions
- `purchaseUpdatedListener` instead of `purchaseUpdated`
- `purchaseErrorListener` instead of `purchaseError`
