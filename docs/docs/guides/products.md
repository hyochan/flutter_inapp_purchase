---
sidebar_position: 1
---

# Working with Products

This guide covers how to implement and manage one-time purchase products (consumables and non-consumables).

## Product Types

### Consumable Products

Products that can be purchased multiple times:

- Virtual currency (coins, gems)
- Power-ups or boosters
- Extra lives or hints

### Non-Consumable Products

Products purchased once and owned forever:

- Remove ads
- Unlock premium features
- Expansion packs

## Loading Products

### Basic Product Loading

```dart
// Define your product IDs
final List<String> productIds = [
  'com.example.coins_100',
  'com.example.coins_500',
  'com.example.remove_ads',
];

// Load products
Future<void> loadProducts() async {
  try {
    List<IapItem> products = await FlutterInappPurchase.instance
        .fetchProducts(skus: productIds, type: 'inapp');

    for (var product in products) {
      print('Product: ${product.productId}');
      print('Title: ${product.title}');
      print('Price: ${product.localizedPrice}');
    }
  } catch (e) {
    print('Failed to load products: $e');
  }
}
```

### Product Information

The `IapItem` class contains:

```dart
class IapItem {
  String? productId;          // Unique identifier
  String? price;              // Raw price value
  String? currency;           // Currency code
  String? localizedPrice;     // Formatted price string
  String? title;              // Product name
  String? description;        // Product description

  // iOS specific
  String? introductoryPrice;
  String? subscriptionPeriodNumberIOS;

  // Android specific
  String? signatureAndroid;
  String? originalJsonAndroid;
}
```

## Implementing Purchases

### Purchase Flow

```dart
class ProductStore {
  StreamSubscription? _purchaseUpdatedSubscription;

  void initializePurchaseListener() {
    _purchaseUpdatedSubscription = FlutterInappPurchase
        .purchaseUpdated.listen((productItem) {
      if (productItem != null) {
        handlePurchaseUpdate(productItem);
      }
    });
  }

  Future<void> purchaseProduct(String productId) async {
    try {
      await FlutterInappPurchase.instance.requestPurchase(productId);
      // Purchase result will be delivered via stream
    } catch (e) {
      handlePurchaseError(e);
    }
  }

  void handlePurchaseUpdate(Purchase item) async {
    // 1. Verify the purchase
    bool isValid = await verifyPurchase(item);

    if (isValid) {
      // 2. Deliver the product
      await deliverProduct(item);

      // 3. Complete the transaction
      await completePurchase(item);
    }
  }
}
```

### Completing Transactions

#### iOS

All purchases must be finished:

```dart
await FlutterInappPurchase.instance.finishTransaction(item);
```

#### Android

Consumable products must be consumed:

```dart
// For consumable products
await FlutterInappPurchase.instance.consumePurchase(
  purchaseToken: item.purchaseToken!,
);

// For non-consumable products
await FlutterInappPurchase.instance.acknowledgePurchase(
  purchaseToken: item.purchaseToken!,
);
```

## Purchase Verification

### Client-Side Validation

Basic validation before server verification:

```dart
bool validatePurchaseLocally(Purchase item) {
  // Check required fields
  if (item.productId == null || item.transactionId == null) {
    return false;
  }

  // Check purchase state (Android)
  if (Platform.isAndroid) {
    // 0 = Purchased, 1 = Pending
    if (item.purchaseStateAndroid != 0) {
      return false;
    }
  }

  // Check transaction date is reasonable
  int now = DateTime.now().millisecondsSinceEpoch;
  int purchaseTime = item.transactionDate ?? 0;
  if (purchaseTime > now || purchaseTime < now - 86400000) { // 24 hours
    return false;
  }

  return true;
}
```

### Server-Side Validation

Always verify purchases on your server:

```dart
Future<bool> verifyPurchase(Purchase item) async {
  // Get receipt data
  String? receipt;
  if (Platform.isIOS) {
    receipt = await FlutterInappPurchase.instance.getReceiptData();
  } else {
    receipt = item.purchaseToken;
  }

  // Send to your server
  final response = await http.post(
    Uri.parse('https://api.example.com/verify-purchase'),
    body: {
      'platform': Platform.isIOS ? 'ios' : 'android',
      'productId': item.productId,
      'receipt': receipt,
      'transactionId': item.transactionId,
    },
  );

  return response.statusCode == 200;
}
```

## Handling Different Product Types

### Consumable Products

```dart
class ConsumableManager {
  // Track consumable inventory
  Map<String, int> inventory = {};

  Future<void> handleConsumablePurchase(Purchase item) async {
    // Add to inventory
    String productId = item.productId!;
    int amount = getProductAmount(productId);
    inventory[productId] = (inventory[productId] ?? 0) + amount;

    // Save to persistent storage
    await saveInventory();

    // Consume the purchase (Android)
    if (Platform.isAndroid) {
      await FlutterInappPurchase.instance.consumePurchase(
        purchaseToken: item.purchaseToken!,
      );
    }

    // Finish transaction (iOS)
    if (Platform.isIOS) {
      await FlutterInappPurchase.instance.finishTransaction(item);
    }
  }

  int getProductAmount(String productId) {
    // Define your product amounts
    switch (productId) {
      case 'coins_100': return 100;
      case 'coins_500': return 500;
      default: return 0;
    }
  }
}
```

### Non-Consumable Products

```dart
class NonConsumableManager {
  Set<String> unlockedFeatures = {};

  Future<void> handleNonConsumablePurchase(Purchase item) async {
    // Unlock the feature
    unlockedFeatures.add(item.productId!);

    // Save to persistent storage
    await saveUnlockedFeatures();

    // Acknowledge purchase (Android)
    if (Platform.isAndroid && item.isAcknowledgedAndroid == false) {
      await FlutterInappPurchase.instance.acknowledgePurchase(
        purchaseToken: item.purchaseToken!,
      );
    }

    // Finish transaction (iOS)
    if (Platform.isIOS) {
      await FlutterInappPurchase.instance.finishTransaction(item);
    }
  }

  bool isFeatureUnlocked(String productId) {
    return unlockedFeatures.contains(productId);
  }
}
```

## Restoring Purchases

Always provide a way to restore non-consumable purchases:

```dart
Future<void> restorePurchases() async {
  try {
    List<Purchase>? purchases = await FlutterInappPurchase
        .instance.getAvailablePurchases();

    if (purchases != null) {
      for (var purchase in purchases) {
        // Re-deliver non-consumable products
        if (isNonConsumable(purchase.productId)) {
          await deliverProduct(purchase);
        }
      }
    }

    showMessage('Purchases restored successfully');
  } catch (e) {
    showError('Failed to restore purchases: $e');
  }
}
```

## Best Practices

### 1. Product Loading

- Cache product information to reduce API calls
- Handle network failures gracefully
- Show loading states while fetching products

### 2. Purchase Flow

- Disable purchase buttons during transaction
- Show clear purchase confirmation dialogs
- Handle pending purchases (especially on Android)

### 3. Error Handling

```dart
void handlePurchaseError(dynamic error) {
  if (error.code == 'E_USER_CANCELLED') {
    // User cancelled - no need to show error
    return;
  }

  String message = 'Purchase failed';
  switch (error.code) {
    case 'E_NETWORK':
      message = 'Network error. Please try again.';
      break;
    case 'E_ITEM_UNAVAILABLE':
      message = 'This item is not available.';
      break;
    case 'E_SERVICE_ERROR':
      message = 'Store service error. Please try later.';
      break;
    default:
      message = 'Purchase failed: ${error.message}';
  }

  showError(message);
}
```

### 4. Testing

- Test with different product types
- Test purchase restoration
- Test network failures
- Test with multiple test accounts

## Common Issues

### Products Not Loading

1. Verify product IDs match exactly
2. Check products are active in store console
3. Ensure app is properly configured
4. Wait for product propagation (can take 24 hours)

### Purchase Not Completing

1. Check internet connection
2. Verify transaction finishing logic
3. Handle pending purchases properly
4. Check for acknowledgment (Android)

## Next Steps

- [Subscriptions Guide](./subscriptions) - Implementing auto-renewable subscriptions
- [Error Handling](./error-handling) - Comprehensive error management
