---
sidebar_position: 1
---

import IapKitBanner from "@site/src/uis/IapKitBanner";

# API Overview

<IapKitBanner />

Flutter In-App Purchase provides a comprehensive API for managing in-app purchases across iOS and Android platforms.

## Core Classes

### FlutterInappPurchase

The main class providing all IAP functionality:

```dart
class FlutterInappPurchase {
  static FlutterInappPurchase get instance => _instance;

  // Connection management
  Future<String?> initialize();
  Future<String?> endConnection();

  // Product management
  Future<List<IapItem>> fetchProducts({
    required List<String> skus,
    PurchaseType type = PurchaseType.inapp,
  });

  // Purchase management
  Future<void> requestPurchase({
    required RequestPurchase request,
    required PurchaseType type,
  });
  Future<List<Purchase>> getAvailablePurchases([PurchaseOptions? options]);

  // Transaction management
  Future<String?> finishTransaction(Purchase purchase, {bool isConsumable = false});
  // Android helpers
  Future<String?> acknowledgePurchaseAndroid({required String purchaseToken});
  Future<String?> consumePurchaseAndroid({required String purchaseToken});

  // Streams (expo-iap compatible)
  Stream<Purchase> get purchaseUpdatedListener;
  Stream<PurchaseError> get purchaseErrorListener;
}
```

### IapItem

Represents a product or subscription:

```dart
class IapItem {
  final String? productId;
  final String? price;
  final String? currency;
  final String? localizedPrice;
  final String? title;
  final String? description;

  // iOS specific fields
  final String? introductoryPrice;
  final String? introductoryPricePaymentModeIOS;
  final String? introductoryPriceNumberOfPeriodsIOS;
  final String? introductoryPriceSubscriptionPeriodIOS;
  final String? subscriptionPeriodNumberIOS;
  final String? subscriptionPeriodUnitIOS;

  // Android specific fields
  final String? signatureAndroid;
  final String? originalJsonAndroid;
  final String? developerPayloadAndroid;
  final String? isConsumableAndroid;
}
```

### Purchase

Represents a completed purchase:

```dart
class Purchase {
  final String productId;
  final String? transactionId;
  final int? transactionDate; // timestamp (ms)
  final String? transactionReceipt;
  final String? purchaseToken;

  // iOS specific
  final String? originalTransactionDateIOS; // string
  final String? originalTransactionIdentifierIOS;

  // Android specific
  final String? purchaseTokenAndroid;  // [DEPRECATED] Use purchaseToken instead
  final String? developerPayloadAndroid;
  final bool? isAcknowledgedAndroid;
  final int? purchaseStateAndroid;
  final String? packageNameAndroid;
}
```

## Key Methods

### Connection Management

#### initialize()

```dart
Future<String?> initialize() async
```

Establishes connection to the store. Must be called before any other methods.

**Returns**: Connection result message or error

**Example**:

```dart
String? result = await FlutterInappPurchase.instance.initialize();
if (result == 'Billing is unavailable') {
  // Handle unavailable billing
}
```

### Product Management

#### fetchProducts()

```dart
Future<List<IapItem>> fetchProducts({
  required List<String> skus,
  PurchaseType type = PurchaseType.inapp,
}) async
```

Fetches product or subscription information for the given SKUs.

**Parameters**:

- `skus`: List of product identifiers
- `type`: Product type - `PurchaseType.inapp` (regular) or `PurchaseType.subs` (subscriptions)

**Returns**: List of available products or subscriptions

**Examples**:

```dart
// Get regular products (consumables and non-consumables)
List<IapItem> products = await FlutterInappPurchase.instance
    .fetchProducts(skus: ['coin_pack_100', 'remove_ads'], type: PurchaseType.inapp);

// Get subscriptions
List<IapItem> subscriptions = await FlutterInappPurchase.instance
    .fetchProducts(skus: ['premium_monthly', 'premium_yearly'], type: PurchaseType.subs);
```

### Purchase Management

#### requestPurchase()

```dart
Future<void> requestPurchase({
  required RequestPurchase request,
  required PurchaseType type,
}) async
```

Initiates a purchase using platform-specific request payloads.

**Parameters**:

- `request`: Platform-specific purchase request
- `type`: Product type to purchase (`PurchaseType.inapp` or `PurchaseType.subs`)

**Example**:

```dart
final request = RequestPurchase(
  ios: RequestPurchaseIOS(sku: 'remove_ads', quantity: 1),
  android: RequestPurchaseAndroid(skus: ['remove_ads']),
);

try {
  await FlutterInappPurchase.instance.requestPurchase(
    request: request,
    type: PurchaseType.inapp,
  );
  // Purchase result delivered via purchaseUpdated stream
} catch (e) {
  // Handle purchase error
}
```

#### getAvailablePurchases()

```dart
Future<List<Purchase>> getAvailablePurchases([PurchaseOptions? options]) async
```

Retrieves available purchases. Pass `PurchaseOptions` to include expired iOS subscriptions or re-emit receipts through the purchase event stream.

**Returns**: List of available purchases

### Transaction Management

#### finishTransaction()

```dart
Future<String?> finishTransaction(Purchase purchase, {bool isConsumable = false}) async
```

Completes a transaction and removes it from the queue.

**Parameters**:

- `purchase`: The purchase to finish

**Returns**: Result message or null

#### consumePurchaseAndroid()

```dart
Future<String?> consumePurchaseAndroid({required String purchaseToken}) async
```

**Android only**: Consumes a purchase, allowing it to be purchased again.

**Parameters**:

- `purchaseToken`: The purchase token from the purchase

**Returns**: Result message or null

#### acknowledgePurchaseAndroid()

```dart
Future<String?> acknowledgePurchaseAndroid({required String purchaseToken}) async
```

**Android only**: Acknowledges a non-consumable purchase.

**Parameters**:

- `purchaseToken`: The purchase token from the purchase

**Returns**: Result message or null

## Streams

### purchaseUpdatedListener

```dart
Stream<Purchase> get purchaseUpdatedListener
```

Stream of successful purchase updates (expo-iap compatible).

**Example**:

```dart
FlutterInappPurchase.instance.purchaseUpdatedListener.listen((purchase) {
  // Handle successful purchase
  print('Purchased: ${purchase.productId}');
});
```

### purchaseErrorListener

```dart
Stream<PurchaseError> get purchaseErrorListener
```

Stream of purchase errors (expo-iap compatible).

**Example**:

```dart
FlutterInappPurchase.instance.purchaseErrorListener.listen((error) {
  // Handle purchase error
  print('Purchase failed: ${error.message}');
});
```

## Platform-Specific Features

### iOS Specific

```dart
// Get App Store receipt
Future<String?> getReceiptData() async

// Validate receipt locally
Future<Map<String, dynamic>?> validateReceiptIos({
  required String receiptBody,
  bool isTest = true,
}) async

// Get promoted product
Future<String?> getPromotedProduct() async

// Request product info
Future<FetchProductsResult> fetchProductsIOS(ProductRequest request)
```

### Android Specific

```dart
// Get purchase history
Future<List<Purchase>> getPurchaseHistoryAndroid() async

// Enable debug mode
void setDebugMode(bool enabled)

// Check if item is consumed
bool isConsumableAndroid(String productId)
```

## Error Handling

Common error codes:

```dart
class IAPError {
  static const String E_UNKNOWN = 'E_UNKNOWN';
  static const String E_USER_CANCELLED = 'E_USER_CANCELLED';
  static const String E_NETWORK = 'E_NETWORK';
  static const String E_ITEM_UNAVAILABLE = 'E_ITEM_UNAVAILABLE';
  static const String E_REMOTE_ERROR = 'E_REMOTE_ERROR';
  static const String E_NOT_PREPARED = 'E_NOT_PREPARED';
  static const String E_ALREADY_OWNED = 'E_ALREADY_OWNED';
}
```

## Usage Patterns

### Basic Purchase Flow

```dart
// 1. Initialize
await FlutterInappPurchase.instance.initialize();

// 2. Set up listeners
FlutterInappPurchase.instance.purchaseUpdatedListener.listen(handlePurchase);

// 3. Load products
var products = await FlutterInappPurchase.instance.fetchProducts(
  skus: productIds,
  type: PurchaseType.inapp
);

// 4. Request purchase
await FlutterInappPurchase.instance.requestPurchase(
  request: RequestPurchase(
    ios: RequestPurchaseIOS(sku: productId, quantity: 1),
    android: RequestPurchaseAndroid(skus: [productId]),
  ),
  type: PurchaseType.inapp,
);

// 5. Handle in listener
void handlePurchase(Purchase purchase) {
  // Verify, deliver, and finish
}
```

### Subscription Flow

```dart
// 1. Load subscriptions
var subs = await FlutterInappPurchase.instance.fetchProducts(
  skus: subIds,
  type: PurchaseType.subs
);

// 2. Request subscription
await FlutterInappPurchase.instance.requestPurchase(
  request: RequestPurchase(
    ios: RequestPurchaseIOS(sku: subId, quantity: 1),
    android: RequestPurchaseAndroid(skus: [subId]),
  ),
  type: PurchaseType.subs,
);

// 3. Check active subscriptions
var purchases = await FlutterInappPurchase.instance.getAvailablePurchases(
  const PurchaseOptions(onlyIncludeActiveItemsIOS: true),
);
var activeSubs = purchases.where((p) => isSubscriptionActive(p));
```

## Next Steps

- [Method Reference](./methods/init-connection) - Detailed method documentation
- [Type Reference](./types/product-type) - Type definitions
- [Error Codes](./types/error-codes) - Complete error code reference
