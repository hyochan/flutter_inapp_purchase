---
title: FlutterInappPurchase
sidebar_label: FlutterInappPurchase
sidebar_position: 1
---

import IapKitBanner from "@site/src/uis/IapKitBanner";

# 🔧 FlutterInappPurchase API

<IapKitBanner />

The main class for handling in-app purchases across iOS and Android platforms.

## 📦 Import

```dart
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
```

## 🏗️ Instance Access

```dart
// Access the singleton instance
final iap = FlutterInappPurchase.instance;
```

## 🔗 Connection Management

### initConnection()

Initialize the connection to the platform billing service.

```dart
Future<void> initConnection()
```

**Example:**

```dart
try {
  await FlutterInappPurchase.instance.initConnection();
  print('Connection initialized successfully');
} catch (e) {
  print('Failed to initialize connection: $e');
}
```

**Platform Notes:**

- **iOS**: Calls `canMakePayments` and registers transaction observers
- **Android**: Connects to Google Play Billing service

---

### endConnection()

End the connection to the platform billing service.

```dart
Future<void> endConnection()
```

**Example:**

```dart
@override
void dispose() {
  FlutterInappPurchase.instance.endConnection();
  super.dispose();
}
```

**Important:** Always call this in your app's dispose method to prevent memory leaks.

## 🛍️ Product Management

### fetchProducts()

Load products or subscriptions using the OpenIAP request schema.

```dart
Future<FetchProductsResult> fetchProducts(ProductRequest request)
```

**Example:**

```dart
final inAppResult = await FlutterInappPurchase.instance.fetchProducts(
  ProductRequest(
    skus: ['premium_upgrade', 'extra_lives'],
    type: ProductQueryType.InApp,
  ),
);
final products = inAppResult.inAppProducts();

final subsResult = await FlutterInappPurchase.instance.fetchProducts(
  ProductRequest(
    skus: ['monthly_premium'],
    type: ProductQueryType.Subs,
  ),
);
final subscriptions = subsResult.subscriptionProducts();
```

## 💳 Purchase Management

### requestPurchase()

Request a purchase using the new unified API.

```dart
Future<void> requestPurchase({
  required RequestPurchase request,
  required PurchaseType type,
})
```

**Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| `request` | `RequestPurchase` | Platform-specific purchase request |
| `type` | `PurchaseType` | Type of purchase (`inapp` or `subs`) |

**Example:**

```dart
await FlutterInappPurchase.instance.requestPurchase(
  request: RequestPurchase(
    apple: RequestPurchaseIosProps(sku: 'premium_upgrade'),
    google: RequestPurchaseAndroidProps(skus: ['premium_upgrade']),
  ),
  type: PurchaseType.inapp,
);
```

---

### requestPurchaseSimple()

Simplified purchase request for cross-platform products.

```dart
Future<void> requestPurchaseSimple({
  required String productId,
  required PurchaseType type,
  String? applicationUsername,
  String? obfuscatedAccountId,
  String? obfuscatedProfileId,
})
```

**Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `productId` | `String` | ✅ | Product ID to purchase |
| `type` | `PurchaseType` | ✅ | Purchase type |
| `applicationUsername` | `String?` | ❌ | iOS: Application username |
| `obfuscatedAccountId` | `String?` | ❌ | Android: Obfuscated account ID |
| `obfuscatedProfileId` | `String?` | ❌ | Android: Obfuscated profile ID |

**Example:**

```dart
await FlutterInappPurchase.instance.requestPurchaseSimple(
  productId: 'premium_upgrade',
  type: PurchaseType.inapp,
);
```

## 📋 Purchase History

### getAvailablePurchases()

Get all non-consumed purchases (restore purchases).

```dart
Future<List<Purchase>> getAvailablePurchases()
```

**Returns:** `Future<List<Purchase>>` - List of available purchases

**Example:**

```dart
final purchases = await FlutterInappPurchase.instance.getAvailablePurchases();
if (purchases != null) {
  for (var purchase in purchases) {
    print('Purchase: ${purchase.productId}');
  }
}
```

---

### getPurchaseHistory()

Get purchase history (including consumed purchases on Android).

```dart
Future<List<Purchase>> getPurchaseHistory()
```

**Returns:** `Future<List<Purchase>>` - List of purchase history

## ✅ Transaction Completion

### finishTransaction()

Complete a transaction (cross-platform).

```dart
Future<void> finishTransaction(Purchase purchase, {bool isConsumable = false})
```

**Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `purchase` | `Purchase` | ✅ | Purchase to finish |
| `isConsumable` | `bool` | ❌ | Whether the purchase is consumable (Android) |

**Example:**

```dart
// Listen for purchase updates
FlutterInappPurchase.purchaseUpdated.listen((purchase) async {
  if (purchase != null) {
    // Verify the purchase on your server first
    await verifyPurchaseOnServer(purchase);

    // Complete the transaction
    await FlutterInappPurchase.instance.finishTransaction(
      purchase,
      isConsumable: true, // for consumable products
    );
  }
});
```

## 📱 Platform-Specific Methods

### iOS Methods

#### syncIOS()

Sync pending iOS transactions.

```dart
Future<bool> syncIOS()
```

#### presentCodeRedemptionSheetIOS()

Present the code redemption sheet (iOS 14+).

```dart
Future<void> presentCodeRedemptionSheetIOS()
```

#### showManageSubscriptionsIOS()

Show the subscription management interface.

```dart
Future<void> showManageSubscriptionsIOS()
```

### Android Methods

#### deepLinkToSubscriptionsAndroid()

Deep link to subscription management.

```dart
Future<void> deepLinkToSubscriptionsAndroid({String? sku})
```

## 🎧 Event Streams

### purchaseUpdated

Stream of purchase updates.

```dart
Stream<Purchase?> get purchaseUpdated
```

**Example:**

```dart
late StreamSubscription _purchaseSubscription;

@override
void initState() {
  super.initState();
  _purchaseSubscription = FlutterInappPurchase.purchaseUpdated.listen(
    (purchase) async {
      if (purchase != null) {
        // Handle successful purchase
        await handlePurchase(purchase);
      }
    },
  );
}

@override
void dispose() {
  _purchaseSubscription.cancel();
  super.dispose();
}
```

---

### purchaseError

Stream of purchase errors.

```dart
Stream<PurchaseResult?> get purchaseError
```

**Example:**

```dart
FlutterInappPurchase.purchaseError.listen((error) {
  if (error != null) {
    print('Purchase error: ${error.message}');

    // Handle specific error codes
    if (error.code == ErrorCode.UserCancelled) {
      // User cancelled - no action needed
    } else if (error.code == ErrorCode.NetworkError) {
      // Show retry option
      showRetryDialog();
    }
  }
});
```

## 🔍 Error Handling

Common error codes you should handle:

| Error Code                   | Description               | Action                 |
| ---------------------------- | ------------------------- | ---------------------- |
| `ErrorCode.UserCancelled`   | User cancelled purchase   | No action needed       |
| `ErrorCode.NetworkError`    | Network error             | Offer retry            |
| `ErrorCode.ItemUnavailable` | Product not available     | Check product setup    |
| `ErrorCode.AlreadyOwned`    | User already owns product | Restore or acknowledge |
| `ErrorCode.DeveloperError`  | Configuration error       | Check setup            |

**Example Error Handling:**

```dart
FlutterInappPurchase.purchaseError.listen((error) {
  if (error == null) return;

  switch (error.code) {
    case ErrorCode.UserCancelled:
      // User cancelled - no UI needed
      break;
    case ErrorCode.NetworkError:
      showSnackBar('Network error. Please check your connection and try again.');
      break;
    case ErrorCode.ItemUnavailable:
      showSnackBar('This item is currently unavailable.');
      break;
    case ErrorCode.AlreadyOwned:
      showSnackBar('You already own this item.');
      break;
    default:
      showSnackBar('Purchase failed: ${error.message}');
  }
});
```

## 🎯 Best Practices

1. **Always initialize connection** before making purchases
2. **Handle all error cases** appropriately
3. **Verify purchases server-side** before granting content
4. **Complete transactions** after verification
5. **Clean up streams** in dispose methods
6. **Test thoroughly** on both platforms

---

## 📚 Related Documentation

- [🏁 **Getting Started**](/getting-started/installation) - Setup and configuration
- [📖 **Purchase Guide**](/guides/first-purchase) - Step-by-step purchase implementation
- [🔍 **Error Handling**](/guides/error-handling) - Comprehensive error handling
- [🧪 **Testing**](/guides/testing) - Testing strategies
