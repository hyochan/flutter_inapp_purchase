---
sidebar_position: 6
title: finishTransaction
---

# finishTransaction()

Completes a transaction and removes it from the queue.

## Overview

The `finishTransaction()` method marks a transaction as complete, removing it from the pending transactions queue. This is crucial for proper transaction management on both iOS and Android platforms.

## Signatures

### expo-iap Compatible

```dart
Future<String?> finishTransaction(Purchase purchase, {bool isConsumable = false})
```

### Legacy Method

```dart
Future<String?> finishTransactionIOS(Purchase purchasedItem, {bool isConsumable = false})
```

## Parameters

- `purchase` / `purchasedItem` - The purchase to finish
- `isConsumable` - Whether the product is consumable (affects Android behavior)

## Platform Behavior

### iOS

- Removes the transaction from StoreKit's payment queue
- Required for all purchases (consumable and non-consumable)
- Must be called after content delivery

### Android

- For consumables: Consumes the purchase, allowing repurchase
- For non-consumables: Acknowledges the purchase
- Must acknowledge within 3 days or purchase is refunded

## Usage Examples

### Basic Transaction Completion

```dart
// Listen for purchases and finish them
FlutterInappPurchase.purchaseUpdated.listen((Purchase? purchase) async {
  if (purchase != null) {
    // Verify and deliver content
    await _verifyAndDeliver(purchase);

    // Finish the transaction
    await FlutterInappPurchase.instance.finishTransactionIOS(
      purchase,
      isConsumable: _isConsumable(purchase.productId),
    );
  }
});
```

### expo-iap Compatible Usage

```dart
// Using the expo-iap compatible method
FlutterInappPurchase.instance.purchaseUpdatedListener.listen((Purchase purchase) async {
  // Process the purchase
  await _processPurchase(purchase);

  // Finish the transaction
  await FlutterInappPurchase.instance.finishTransaction(
    purchase,
    isConsumable: true,
  );
});
```

### Complete Purchase Flow

```dart
class PurchaseHandler {
  final _iap = FlutterInappPurchase.instance;
  final _consumableIds = ['coins_100', 'coins_500', 'powerup_pack'];

  void initialize() {
    FlutterInappPurchase.purchaseUpdated.listen(_handlePurchase);
  }

  Future<void> _handlePurchase(Purchase? purchase) async {
    if (purchase == null) return;

    try {
      // Step 1: Verify the purchase
      final isValid = await _verifyPurchase(purchase);
      if (!isValid) {
        print('Invalid purchase detected');
        return;
      }

      // Step 2: Deliver the content
      await _deliverContent(purchase.productId!);

      // Step 3: Finish the transaction
      final isConsumable = _consumableIds.contains(purchase.productId);
      await _iap.finishTransactionIOS(purchase, isConsumable: isConsumable);

      print('Transaction completed successfully');

    } catch (e) {
      print('Error processing purchase: $e');
      // Don't finish transaction if processing failed
      // This keeps it in the queue for retry
    }
  }

  Future<bool> _verifyPurchase(Purchase item) async {
    // Implement your verification logic
    // - Verify receipt with your backend
    // - Check transaction ID uniqueness
    // - Validate product ID
    return true;
  }

  Future<void> _deliverContent(String productId) async {
    // Deliver the purchased content
    switch (productId) {
      case 'coins_100':
        await _addCoins(100);
        break;
      case 'coins_500':
        await _addCoins(500);
        break;
      case 'premium':
        await _unlockPremium();
        break;
    }
  }
}
```

## Android-Specific Handling

```dart
Future<void> handleAndroidPurchase(Purchase item) async {
  if (!Platform.isAndroid) return;

  // Check acknowledgment status
  if (item.isAcknowledgedAndroid == false) {
    if (_isConsumable(item.productId)) {
      // Consume the purchase
      await _iap.consumePurchaseAndroid(item.purchaseToken!);
    } else {
      // Acknowledge non-consumable
      await _iap.acknowledgePurchaseAndroid(
        purchaseToken: item.purchaseToken!,
      );
    }
  }
}
```

## Pending Transactions

Handle pending transactions on app startup:

```dart
class TransactionManager {
  Future<void> processPendingTransactions() async {
    try {
      // Get pending transactions
      final pending = await FlutterInappPurchase.instance.getPendingTransactionsIOS();

      if (pending != null && pending.isNotEmpty) {
        print('Found ${pending.length} pending transactions');

        for (var transaction in pending) {
          // Process each pending transaction
          await _processPendingTransaction(transaction);
        }
      }
    } catch (e) {
      print('Error processing pending transactions: $e');
    }
  }

  Future<void> _processPendingTransaction(Purchase item) async {
    // Verify the transaction
    final isValid = await _verifyTransaction(item);

    if (isValid) {
      // Deliver content if not already delivered
      if (!await _isContentDelivered(item.transactionId)) {
        await _deliverContent(item.productId!);
      }

      // Finish the transaction
      await FlutterInappPurchase.instance.finishTransaction(item);
    }
  }
}
```

## Best Practices

1. **Always Verify First**: Verify purchases before finishing transactions
2. **Handle Failures**: Keep transactions pending if verification fails
3. **Idempotent Delivery**: Ensure content delivery is idempotent
4. **Process on Startup**: Check for pending transactions when app launches
5. **Track Delivery**: Maintain records of delivered content

## Error Handling

```dart
Future<void> safeFinishTransaction(Purchase item) async {
  const maxRetries = 3;
  var retryCount = 0;

  while (retryCount < maxRetries) {
    try {
      await _iap.finishTransactionIOS(
        item,
        isConsumable: _isConsumable(item.productId),
      );
      print('Transaction finished successfully');
      break;

    } catch (e) {
      retryCount++;
      print('Failed to finish transaction (attempt $retryCount): $e');

      if (retryCount >= maxRetries) {
        // Log error but don't throw
        // Transaction will remain pending
        _logError('Failed to finish transaction after $maxRetries attempts', item);
      } else {
        // Wait before retry
        await Future.delayed(Duration(seconds: retryCount));
      }
    }
  }
}
```

## Transaction States

Monitor transaction states for proper handling:

```dart
void handleTransactionState(Purchase item) {
  if (Platform.isIOS) {
    switch (item.transactionStateIOS) {
      case TransactionState.purchased:
      case TransactionState.restored:
        // Safe to finish
        _finishTransaction(item);
        break;
      case TransactionState.failed:
        // Don't finish failed transactions
        print('Transaction failed');
        break;
      case TransactionState.purchasing:
      case TransactionState.deferred:
        // Wait for final state
        print('Transaction pending');
        break;
    }
  } else if (Platform.isAndroid) {
    switch (item.purchaseStateAndroid) {
      case PurchaseState.purchased:
        // Safe to finish
        _finishTransaction(item);
        break;
      case PurchaseState.pending:
        // Don't finish pending transactions
        print('Purchase pending');
        break;
    }
  }
}
```

## Related Methods

- [`requestPurchase()`](./request-purchase.md) - Initiates a purchase
- [`getAvailablePurchases()`](./get-available-purchases.md) - Gets unfinished purchases
- `acknowledgePurchaseAndroid()` - Android-specific acknowledgment (see example above)
- `consumePurchaseAndroid()` - Android-specific consumption (see example above)

## Important Notes

1. **iOS Requirements**: All transactions must be finished, even failed ones
2. **Android 3-Day Rule**: Acknowledge purchases within 3 days or they're refunded
3. **Consumables**: Must be consumed on Android to allow repurchase
4. **Network Failures**: Transactions remain pending if finish fails
5. **App Termination**: Unfinished transactions persist across app sessions
