---
sidebar_position: 2
title: Purchase States
---

# Purchase States

Types and enums representing the state of purchases and transactions.

## Purchase Class

Main class representing a completed or pending purchase.

```dart
class Purchase {
  final String productId;
  final String? transactionId;
  final String? transactionReceipt;
  final String? purchaseToken;
  final DateTime? transactionDate;
  final IAPPlatform platform;
  final bool? isAcknowledgedAndroid;
  final String? purchaseStateAndroid;
  final String? originalTransactionIdentifierIOS;
  final Map<String, dynamic>? originalJson;

  // StoreKit 2 specific fields
  final String? transactionState;
  final bool? isUpgraded;
  final DateTime? expirationDate;
  final DateTime? revocationDate;
  final int? revocationReason;
}
```

### Common Properties

- `productId` - The product identifier that was purchased
- `transactionId` - Unique transaction identifier
- `transactionReceipt` - Receipt data (iOS primarily)
- `purchaseToken` - Purchase token (Android primarily)
- `transactionDate` - When the transaction occurred
- `platform` - Platform where purchase was made

### Android-Specific Properties

- `isAcknowledgedAndroid` - Whether purchase has been acknowledged
- `purchaseStateAndroid` - Current state of the purchase

### iOS-Specific Properties

- `originalTransactionIdentifierIOS` - Original transaction ID for renewals
- `transactionState` - Current transaction state
- `isUpgraded` - Whether subscription was upgraded
- `expirationDate` - When subscription expires
- `revocationDate` - When purchase was revoked
- `revocationReason` - Reason for revocation

## PurchaseState (Android)

Enum representing the state of an Android purchase.

```dart
enum PurchaseState {
  pending,      // Purchase is pending (awaiting payment)
  purchased,    // Purchase completed successfully
  unspecified   // Unknown/unspecified state
}
```

### Usage

```dart
void handleAndroidPurchase(Purchase item) {
  switch (item.purchaseStateAndroid) {
    case PurchaseState.purchased:
      // Purchase completed - safe to deliver content
      deliverContent(item.productId);
      break;
    case PurchaseState.pending:
      // Payment pending - wait for completion
      showPendingMessage();
      break;
    case PurchaseState.unspecified:
      // Unknown state - handle cautiously
      logUnknownState(item);
      break;
  }
}
```

## TransactionState (iOS)

Enum representing the state of an iOS transaction.

```dart
enum TransactionState {
  purchasing,  // Transaction is being processed
  purchased,   // Transaction completed successfully
  failed,      // Transaction failed
  restored,    // Transaction was restored
  deferred     // Transaction pending external approval (e.g., Ask to Buy)
}
```

### Usage

```dart
void handleIOSTransaction(Purchase item) {
  switch (item.transactionStateIOS) {
    case TransactionState.purchased:
    case TransactionState.restored:
      // Safe to deliver content and finish transaction
      deliverContent(item.productId);
      FlutterInappPurchase.instance.finishTransaction(item);
      break;
    case TransactionState.failed:
      // Transaction failed - don't deliver content
      showErrorMessage();
      // Still need to finish failed transactions
      FlutterInappPurchase.instance.finishTransaction(item);
      break;
    case TransactionState.purchasing:
      // Still processing - wait
      showLoadingIndicator();
      break;
    case TransactionState.deferred:
      // Waiting for parental approval
      showDeferredMessage();
      break;
  }
}
```

## Complete State Handling

```dart
class PurchaseStateHandler {
  void processPurchase(Purchase purchase) {
    if (Platform.isAndroid) {
      _handleAndroidPurchase(purchase);
    } else if (Platform.isIOS) {
      _handleIOSPurchase(purchase);
    }
  }

  void _handleAndroidPurchase(Purchase purchase) {
    switch (purchase.purchaseStateAndroid) {
      case PurchaseState.purchased:
        if (purchase.isAcknowledgedAndroid == false) {
          // Need to acknowledge within 3 days
          _acknowledgePurchase(purchase);
        }
        _deliverContent(purchase);
        break;

      case PurchaseState.pending:
        // Store pending purchase for later processing
        _storePendingPurchase(purchase);
        _showPendingUI();
        break;

      case PurchaseState.unspecified:
        // Log for investigation
        _logUnknownPurchaseState(purchase);
        break;
    }
  }

  void _handleIOSPurchase(Purchase purchase) {
    switch (purchase.transactionStateIOS) {
      case TransactionState.purchased:
        _deliverContent(purchase);
        _finishTransaction(purchase);
        break;

      case TransactionState.restored:
        _restoreContent(purchase);
        _finishTransaction(purchase);
        break;

      case TransactionState.failed:
        _handleFailure(purchase);
        _finishTransaction(purchase); // Still need to finish
        break;

      case TransactionState.deferred:
        _handleDeferred(purchase);
        // Don't finish - wait for final state
        break;

      case TransactionState.purchasing:
        _showPurchasingUI();
        // Don't finish - wait for completion
        break;
    }
  }
}
```

## State Transitions

### Android Purchase Flow

```
User initiates purchase
         ↓
 Payment method selected
         ↓
    PurchaseState.pending (if async payment)
         ↓
    Payment processed
         ↓
    PurchaseState.purchased
         ↓
    App acknowledges purchase
         ↓
    Purchase complete
```

### iOS Transaction Flow

```
User initiates purchase
         ↓
    TransactionState.purchasing
         ↓
    Payment processed
         ↓
    TransactionState.purchased
         ↓
    App delivers content
         ↓
    App finishes transaction
         ↓
    Transaction removed from queue
```

## Error States and Recovery

```dart
class StateRecoveryHandler {
  Future<void> recoverPendingStates() async {
    // Get all available purchases
    final purchases = await FlutterInappPurchase.instance.getAvailablePurchases();

    for (var purchase in purchases) {
      await _recoverPurchaseState(purchase);
    }
  }

  Future<void> _recoverPurchaseState(Purchase purchase) async {
    if (Platform.isAndroid) {
      // Check if acknowledgment is needed
      if (purchase.purchaseStateAndroid == PurchaseState.purchased &&
          purchase.isAcknowledgedAndroid == false) {

        // Check if content was already delivered
        if (await _wasContentDelivered(purchase.transactionId)) {
          // Just acknowledge without re-delivering
          await _acknowledgePurchaseOnly(purchase);
        } else {
          // Deliver content and acknowledge
          await _deliverContentAndAcknowledge(purchase);
        }
      }
    } else if (Platform.isIOS) {
      // Check for unfinished transactions
      final pending = await FlutterInappPurchase.instance.getPendingTransactionsIOS();

      for (var transaction in pending ?? []) {
        if (transaction.transactionStateIOS == TransactionState.purchased ||
            transaction.transactionStateIOS == TransactionState.restored) {

          // Verify content delivery
          if (!await _wasContentDelivered(transaction.transactionId)) {
            await _deliverContent(transaction);
          }

          // Finish the transaction
          await FlutterInappPurchase.instance.finishTransactionIOS(transaction);
        }
      }
    }
  }
}
```

## Best Practices

### State Checking

```dart
bool isPurchaseComplete(Purchase purchase) {
  if (Platform.isAndroid) {
    return purchase.purchaseStateAndroid == PurchaseState.purchased &&
           purchase.isAcknowledgedAndroid == true;
  } else if (Platform.isIOS) {
    // On iOS, if we receive the purchase, it's valid
    // State checking is for transaction management
    return true;
  }
  return false;
}

bool needsAcknowledgment(Purchase purchase) {
  return Platform.isAndroid &&
         purchase.purchaseStateAndroid == PurchaseState.purchased &&
         purchase.isAcknowledgedAndroid == false;
}

bool canFinishTransaction(Purchase item) {
  if (Platform.isIOS) {
    return item.transactionStateIOS == TransactionState.purchased ||
           item.transactionStateIOS == TransactionState.restored ||
           item.transactionStateIOS == TransactionState.failed;
  }
  return true; // Android transactions can always be "finished"
}
```

### State Persistence

```dart
class PurchaseStateManager {
  final SharedPreferences prefs;

  Future<void> savePurchaseState(Purchase purchase) async {
    final stateData = {
      'productId': purchase.productId,
      'transactionId': purchase.transactionId,
      'state': Platform.isAndroid
          ? purchase.purchaseStateAndroid
          : purchase.transactionState,
      'acknowledged': purchase.isAcknowledgedAndroid,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    await prefs.setString(
      'purchase_state_${purchase.transactionId}',
      json.encode(stateData),
    );
  }

  Future<Map<String, dynamic>?> getPurchaseState(String transactionId) async {
    final stateJson = prefs.getString('purchase_state_$transactionId');
    return stateJson != null ? json.decode(stateJson) : null;
  }
}
```

## Related Types

- [Error Codes](./error-codes.md) - Error states and codes
- [Product Types](./product-type.md) - Product-related types
