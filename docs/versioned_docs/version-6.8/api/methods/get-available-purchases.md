---
sidebar_position: 7
title: getAvailablePurchases
---

# getAvailablePurchases()

Retrieves non-consumed purchases with optional filters for platform-specific behavior.

## Overview

The `getAvailablePurchases()` method returns a list of purchases that haven't been consumed or finished. Use it to restore purchases, check subscription status, and handle incomplete transactions. On iOS you can pass `PurchaseOptions` to include expired subscriptions or publish restored receipts to the purchase event stream.

## Signatures

### expo-iap Compatible
```dart
Future<List<Purchase>> getAvailablePurchases([PurchaseOptions? options])
```

### Legacy Method
```dart
Future<List<Purchase>?> getAvailableItemsIOS()
```

## Parameters

| Parameter | Type               | Required | Default | Description |
| --------- | ------------------ | -------- | ------- | ----------- |
| `options` | `PurchaseOptions?` | No       | `null`  | Controls whether expired iOS receipts are included and if restored purchases should be re-emitted via `purchaseUpdated` |

## Returns

A list of active purchases including:
- Non-consumable items
- Active subscriptions
- Unfinished transactions
- Purchases awaiting acknowledgment (Android)

## Platform Behavior

### iOS
- Returns all transactions in the payment queue
- Includes restored purchases
- Shows both finished and unfinished transactions

### Android
- Returns purchases from Google Play
- Includes both in-app products and subscriptions
- Only shows purchases that haven't been consumed

## Usage Examples

### Basic Usage

```dart
// Active purchases only (default)
final purchases = await FlutterInappPurchase.instance.getAvailablePurchases();

// Include expired iOS subscriptions and publish them to purchaseUpdated
final allPurchases = await FlutterInappPurchase.instance.getAvailablePurchases(
  PurchaseOptions(
    onlyIncludeActiveItemsIOS: false,
    alsoPublishToEventListenerIOS: true,
  ),
);

for (var purchase in purchases) {
  print('Active purchase: ${purchase.productId}');
  print('Transaction ID: ${purchase.transactionId}');
}
```

### Restore Purchases

```dart
class PurchaseRestorer {
  final _iap = FlutterInappPurchase.instance;
  
  Future<void> restorePurchases() async {
    try {
      // Show loading indicator
      showLoading(true);
      
      // Get all available purchases
      final purchases = await _iap.getAvailablePurchases();
      
      if (purchases.isEmpty) {
        showMessage('No purchases to restore');
        return;
      }
      
      // Process each purchase
      for (var purchase in purchases) {
        await _processPurchase(purchase);
      }
      
      showMessage('Restored ${purchases.length} purchases');
      
    } catch (e) {
      showError('Failed to restore purchases: $e');
    } finally {
      showLoading(false);
    }
  }
  
  Future<void> _processPurchase(Purchase purchase) async {
    // Verify the purchase
    if (await _verifyPurchase(purchase)) {
      // Unlock content
      await _unlockContent(purchase.productId);
      
      // Finish transaction if needed
      if (_shouldFinishTransaction(purchase)) {
        await _iap.finishTransaction(purchase);
      }
    }
  }
}
```

### Check Subscription Status

```dart
class SubscriptionChecker {
  final _subscriptionIds = [
    'com.example.monthly',
    'com.example.yearly',
    'com.example.premium',
  ];
  
  Future<SubscriptionStatus> checkSubscriptionStatus() async {
    try {
      final purchases = await FlutterInappPurchase.instance.getAvailablePurchases();
      
      // Find active subscriptions
      final activeSubscriptions = purchases.where((p) => 
        _subscriptionIds.contains(p.productId)
      ).toList();
      
      if (activeSubscriptions.isEmpty) {
        return SubscriptionStatus(
          isActive: false,
          activeProduct: null,
        );
      }
      
      // Get the most recent subscription
      activeSubscriptions.sort((a, b) => 
        (b.transactionDate ?? DateTime(1970))
            .compareTo(a.transactionDate ?? DateTime(1970))
      );
      
      final latestSubscription = activeSubscriptions.first;
      
      return SubscriptionStatus(
        isActive: true,
        activeProduct: latestSubscription.productId,
        expirationDate: _calculateExpirationDate(latestSubscription),
      );
      
    } catch (e) {
      print('Error checking subscription: $e');
      return SubscriptionStatus(isActive: false, activeProduct: null);
    }
  }
  
  DateTime? _calculateExpirationDate(Purchase purchase) {
    // Implementation depends on your subscription periods
    // This is a simplified example
    if (purchase.productId == 'com.example.monthly') {
      return purchase.transactionDate?.add(Duration(days: 30));
    } else if (purchase.productId == 'com.example.yearly') {
      return purchase.transactionDate?.add(Duration(days: 365));
    }
    return null;
  }
}
```

### Handle Pending Transactions

```dart
class PendingTransactionHandler {
  final _iap = FlutterInappPurchase.instance;
  
  Future<void> processPendingTransactions() async {
    final purchases = await _iap.getAvailablePurchases();
    
    for (var purchase in purchases) {
      if (_isPending(purchase)) {
        print('Found pending transaction: ${purchase.productId}');
        
        // Try to complete the transaction
        await _completePendingTransaction(purchase);
      }
    }
  }
  
  bool _isPending(Purchase purchase) {
    // Check platform-specific pending states
    if (Platform.isAndroid) {
      return purchase.purchaseStateAndroid == 'pending';
    } else if (Platform.isIOS) {
      // iOS transactions in queue are pending
      return true;
    }
    return false;
  }
  
  Future<void> _completePendingTransaction(Purchase purchase) async {
    try {
      // Verify with backend
      final isValid = await _verifyWithBackend(purchase);
      
      if (isValid) {
        // Deliver content
        await _deliverContent(purchase.productId);
        
        // Finish transaction
        await _iap.finishTransaction(purchase);
      }
    } catch (e) {
      print('Error completing pending transaction: $e');
      // Transaction remains pending for retry
    }
  }
}
```

### Filter Purchase Types

```dart
class PurchaseFilter {
  List<Purchase> filterConsumables(List<Purchase> purchases) {
    const consumableIds = ['coins_100', 'coins_500', 'gems_pack'];
    return purchases.where((p) => consumableIds.contains(p.productId)).toList();
  }
  
  List<Purchase> filterNonConsumables(List<Purchase> purchases) {
    const nonConsumableIds = ['remove_ads', 'unlock_pro', 'theme_pack'];
    return purchases.where((p) => nonConsumableIds.contains(p.productId)).toList();
  }
  
  List<Purchase> filterSubscriptions(List<Purchase> purchases) {
    const subscriptionIds = ['monthly_sub', 'yearly_sub'];
    return purchases.where((p) => subscriptionIds.contains(p.productId)).toList();
  }
  
  List<Purchase> filterUnacknowledged(List<Purchase> purchases) {
    if (Platform.isAndroid) {
      return purchases.where((p) => p.isAcknowledgedAndroid == false).toList();
    }
    return [];
  }
}
```

## Complete Implementation

```dart
class PurchaseManager {
  final _iap = FlutterInappPurchase.instance;
  final _ownedProducts = <String>{};
  
  Future<void> syncPurchases() async {
    try {
      // Get all available purchases
      final purchases = await _iap.getAvailablePurchases();
      
      // Clear current state
      _ownedProducts.clear();
      
      // Process each purchase
      for (var purchase in purchases) {
        // Add to owned products
        _ownedProducts.add(purchase.productId);
        
        // Handle based on platform
        if (Platform.isAndroid && !purchase.isAcknowledgedAndroid!) {
          // Acknowledge Android purchase
          await _acknowledgeAndroidPurchase(purchase);
        }
        
        // Unlock content if not already unlocked
        if (!await _isContentUnlocked(purchase.productId)) {
          await _unlockContent(purchase.productId);
        }
      }
      
      print('Synced ${_ownedProducts.length} purchases');
      
    } catch (e) {
      print('Error syncing purchases: $e');
    }
  }
  
  bool isProductOwned(String productId) {
    return _ownedProducts.contains(productId);
  }
  
  Future<void> _acknowledgeAndroidPurchase(Purchase purchase) async {
    if (purchase.purchaseToken != null) {
      await _iap.acknowledgePurchaseAndroid(
        purchaseToken: purchase.purchaseToken!,
      );
    }
  }
}
```

## Best Practices

1. **Cache Results**: Don't call this method too frequently
2. **Verify Purchases**: Always verify purchases with your backend
3. **Handle Duplicates**: Check for duplicate transactions
4. **Process All**: Process all available purchases on app launch
5. **Error Recovery**: Implement retry logic for failed processing

## Common Use Cases

1. **Restore Purchases**: After app reinstall or device change
2. **Subscription Check**: Verify active subscription status
3. **Pending Transactions**: Complete interrupted purchases
4. **Content Sync**: Ensure all purchased content is unlocked
5. **Receipt Validation**: Get receipts for server validation

## Related Methods

- `getPurchaseHistory()` - Gets historical purchases (Android only)
- [`finishTransaction()`](./finish-transaction.md) - Completes transactions
- `restorePurchases()` - iOS-specific restore method

## Platform Notes

### iOS
- Includes all non-finished transactions
- May include very old transactions if not finished
- Restored purchases appear here

### Android
- Only includes purchases from current Google account
- Consumed items don't appear
- Requires BILLING permission
