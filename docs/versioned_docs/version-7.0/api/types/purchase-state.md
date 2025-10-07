---
sidebar_position: 2
title: Purchase States
---

# Purchase States

Types and enums representing the state of purchases and transactions.

## PurchaseState

Enum representing the state of a purchase.

```dart
enum PurchaseState {
  Pending,      // Purchase is pending (awaiting payment)
  Purchased,    // Purchase completed successfully
  Failed,       // Purchase failed
  Restored,     // Purchase was restored
  Deferred,     // Purchase deferred (e.g., Ask to Buy on iOS)
  Unknown,      // Unknown/unspecified state
}
```

### Usage

```dart
void _handlePurchase(Purchase purchase) {
  // PurchaseState is available in both PurchaseIOS and PurchaseAndroid
  final state = purchase is PurchaseIOS
    ? purchase.transactionState
    : (purchase as PurchaseAndroid).purchaseState;

  switch (state) {
    case PurchaseState.Purchased:
      // Purchase completed - safe to deliver content
      _deliverContent(purchase.productId);
      break;

    case PurchaseState.Pending:
      // Payment pending - wait for completion
      _showPendingMessage();
      break;

    case PurchaseState.Failed:
      // Purchase failed
      _showErrorMessage();
      break;

    case PurchaseState.Restored:
      // Purchase was restored
      _deliverContent(purchase.productId);
      break;

    case PurchaseState.Deferred:
      // Waiting for parental approval (iOS Ask to Buy)
      _showDeferredMessage();
      break;

    case PurchaseState.Unknown:
      // Unknown state - handle cautiously
      debugPrint('Unknown purchase state');
      break;
  }
}
```

## Purchase Classes

flutter_inapp_purchase uses union types for purchases. When you receive purchases, you get platform-specific purchase types.

### PurchaseIOS

```dart
class PurchaseIOS extends Purchase {
  final String id;
  final String originalId;
  final String productId;
  final DateTime purchaseDate;
  final PurchaseState transactionState;
  final String? receiptData;
  // ... additional iOS-specific properties
}
```

### PurchaseAndroid

```dart
class PurchaseAndroid extends Purchase {
  final String? orderId;
  final String productId;
  final PurchaseState purchaseState;
  final int purchaseTime;
  final String purchaseToken;
  final bool acknowledged;
  // ... additional Android-specific properties
}
```

## Handling Purchase States

### Basic Purchase Handling

```dart
void _handlePurchase(Purchase purchase) async {
  if (purchase is PurchaseIOS) {
    switch (purchase.transactionState) {
      case PurchaseState.Purchased:
      case PurchaseState.Restored:
        await _deliverContent(purchase.productId);
        await iap.finishTransaction(
          purchase: purchase,
          isConsumable: false,
        );
        break;

      case PurchaseState.Deferred:
        _showMessage('Waiting for approval...');
        break;

      case PurchaseState.Failed:
        _showMessage('Purchase failed');
        break;

      default:
        break;
    }
  } else if (purchase is PurchaseAndroid) {
    switch (purchase.purchaseState) {
      case PurchaseState.Purchased:
        if (!purchase.acknowledged) {
          await _deliverContent(purchase.productId);
          await iap.finishTransaction(
            purchase: purchase,
            isConsumable: false,
          );
        }
        break;

      case PurchaseState.Pending:
        _showMessage('Purchase pending...');
        break;

      default:
        break;
    }
  }
}
```

## Best Practices

1. **Handle all states** - Don't assume purchases will always be in `Purchased` state
2. **Check acknowledgment** - On Android, check if purchase needs acknowledgment
3. **Finish transactions** - Always finish transactions after delivering content
4. **Handle pending** - Support pending purchases for async payment methods
5. **Persist state** - Save purchase state locally for recovery

## Related

- [Error Codes](./error-codes) - Error states and codes
- [Product Types](./product-type) - Product-related types
- [Purchase Lifecycle](../../guides/lifecycle) - Complete purchase flow
