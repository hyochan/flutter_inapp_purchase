---
sidebar_position: 1
---

# API Overview

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
  Future<List<IAPItem>> requestProducts({
    required List<String> skus,
    String type = 'inapp', // 'inapp' or 'subs'
  });
  
  // Purchase management
  Future<void> requestPurchase(String sku);
  Future<void> requestSubscription(String sku);
  Future<List<PurchasedItem>?> getAvailablePurchases();
  
  // Transaction management
  Future<String?> finishTransaction(PurchasedItem purchase);
  Future<String?> acknowledgePurchase({required String purchaseToken});
  Future<String?> consumePurchase({required String purchaseToken});
  
  // Streams
  static Stream<PurchasedItem?> get purchaseUpdated;
  static Stream<PurchasedItem?> get purchaseError;
}
```

### IAPItem

Represents a product or subscription:

```dart
class IAPItem {
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

### PurchasedItem

Represents a completed purchase:

```dart
class PurchasedItem {
  final String? productId;
  final String? transactionId;
  final DateTime? transactionDate;
  final String? transactionReceipt;
  final String? purchaseToken;
  
  // iOS specific
  final String? originalTransactionDateIOS;
  final String? originalTransactionIdentifierIOS;
  
  // Android specific
  final String? purchaseTokenAndroid;
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

#### requestProducts()
```dart
Future<List<IAPItem>> requestProducts({
  required List<String> skus,
  String type = 'inapp',
}) async
```
Fetches product or subscription information for the given SKUs.

**Parameters**:
- `skus`: List of product identifiers
- `type`: Product type - `'inapp'` for regular products or `'subs'` for subscriptions

**Returns**: List of available products or subscriptions

**Examples**:
```dart
// Get regular products (consumables and non-consumables)
List<IAPItem> products = await FlutterInappPurchase.instance
    .requestProducts(skus: ['coin_pack_100', 'remove_ads'], type: 'inapp');

// Get subscriptions
List<IAPItem> subscriptions = await FlutterInappPurchase.instance
    .requestProducts(skus: ['premium_monthly', 'premium_yearly'], type: 'subs');
```

### Purchase Management

#### requestPurchase()
```dart
Future<void> requestPurchase(String sku) async
```
Initiates a purchase for the specified product.

**Parameters**:
- `sku`: Product identifier to purchase

**Throws**: `PlatformException` if purchase fails

**Example**:
```dart
try {
  await FlutterInappPurchase.instance.requestPurchase('remove_ads');
  // Purchase result delivered via purchaseUpdated stream
} catch (e) {
  // Handle purchase error
}
```

#### getAvailablePurchases()
```dart
Future<List<PurchasedItem>?> getAvailablePurchases() async
```
Retrieves all available purchases (including pending and non-consumed).

**Returns**: List of purchases or null

### Transaction Management

#### finishTransaction()
```dart
Future<String?> finishTransaction(PurchasedItem purchase) async
```
**iOS only**: Completes a transaction. Must be called for all purchases.

**Parameters**:
- `purchase`: The purchase to finish

**Returns**: Result message or null

#### consumePurchase()
```dart
Future<String?> consumePurchase({required String purchaseToken}) async
```
**Android only**: Consumes a purchase, allowing it to be purchased again.

**Parameters**:
- `purchaseToken`: The purchase token from the purchase

**Returns**: Result message or null

#### acknowledgePurchase()
```dart
Future<String?> acknowledgePurchase({required String purchaseToken}) async
```
**Android only**: Acknowledges a non-consumable purchase.

**Parameters**:
- `purchaseToken`: The purchase token from the purchase

**Returns**: Result message or null

## Streams

### purchaseUpdated
```dart
static Stream<PurchasedItem?> get purchaseUpdated
```
Stream of successful purchase updates.

**Example**:
```dart
FlutterInappPurchase.purchaseUpdated.listen((item) {
  if (item != null) {
    // Handle successful purchase
    print('Purchased: ${item.productId}');
  }
});
```

### purchaseError
```dart
static Stream<PurchasedItem?> get purchaseError
```
Stream of purchase errors.

**Example**:
```dart
FlutterInappPurchase.purchaseError.listen((item) {
  // Handle purchase error
  print('Purchase failed: ${item?.productId}');
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
Future<List<IAPItem>> getProductsIOS(List<String> skus) async
```

### Android Specific

```dart
// Get purchase history
Future<List<PurchasedItem>?> getPurchaseHistoryAndroid() async

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
FlutterInappPurchase.purchaseUpdated.listen(handlePurchase);

// 3. Load products
var products = await FlutterInappPurchase.instance.requestProducts(
  skus: productIds, 
  type: 'inapp'
);

// 4. Request purchase
await FlutterInappPurchase.instance.requestPurchase(productId);

// 5. Handle in listener
void handlePurchase(PurchasedItem? item) {
  // Verify, deliver, and finish
}
```

### Subscription Flow

```dart
// 1. Load subscriptions
var subs = await FlutterInappPurchase.instance.requestProducts(
  skus: subIds, 
  type: 'subs'
);

// 2. Request subscription
await FlutterInappPurchase.instance.requestSubscription(subId);

// 3. Check active subscriptions
var purchases = await FlutterInappPurchase.instance.getAvailablePurchases();
var activeSubs = purchases?.where((p) => isSubscriptionActive(p));
```

## Next Steps

- [Method Reference](./methods/init-connection) - Detailed method documentation
- [Type Reference](./types/product-type) - Type definitions
- [Error Codes](./types/error-codes) - Complete error code reference