---
title: Listeners
sidebar_position: 4
---

# Event Listeners

Real-time event streams for monitoring purchase transactions and errors in flutter_inapp_purchase v7.0.

All listeners are available through the singleton instance:

```dart
final iap = FlutterInappPurchase.instance;
```

## Core Event Streams

### purchaseUpdatedListener

Stream for successful purchase completions.

```dart
Stream<Purchase> get purchaseUpdatedListener
```

**Type**: `Stream<Purchase>` (non-nullable)
**Emits**: Purchase completion events

**Example**:
```dart
StreamSubscription<Purchase>? _purchaseSubscription;

void setupPurchaseListener() {
  _purchaseSubscription = iap.purchaseUpdatedListener.listen(
    (purchase) {
      handlePurchaseSuccess(purchase);
    },
    onError: (error) {
      debugPrint('Purchase stream error: $error');
    },
  );
}

Future<void> handlePurchaseSuccess(Purchase purchase) async {
  debugPrint('Purchase completed: ${purchase.productId}');

  try {
    // 1. Verify the purchase (recommended)
    final isValid = await verifyPurchaseOnServer(purchase);
    if (!isValid) {
      debugPrint('Purchase verification failed');
      return;
    }

    // 2. Deliver the product to user
    await deliverProduct(purchase.productId);

    // 3. Finish the transaction
    await iap.finishTransaction(
      purchase: purchase,
      isConsumable: true, // Set appropriately for your product
    );

    debugPrint('Purchase processed successfully');
  } catch (e) {
    debugPrint('Error processing purchase: $e');
  }
}

@override
void dispose() {
  _purchaseSubscription?.cancel();
  super.dispose();
}
```

**Purchase Types**:
- `PurchaseIOS` - iOS purchases with iOS-specific fields
- `PurchaseAndroid` - Android purchases with Android-specific fields

---

### purchaseErrorListener

Stream for purchase failures and errors.

```dart
Stream<PurchaseError> get purchaseErrorListener
```

**Type**: `Stream<PurchaseError>` (non-nullable)
**Emits**: Purchase error events

**Example**:
```dart
StreamSubscription<PurchaseError>? _errorSubscription;

void setupErrorListener() {
  _errorSubscription = iap.purchaseErrorListener.listen(
    (error) {
      handlePurchaseError(error);
    },
  );
}

void handlePurchaseError(PurchaseError error) {
  debugPrint('Purchase failed: ${error.message}');
  debugPrint('Error code: ${error.code}');

  switch (error.code) {
    case ErrorCode.UserCancelled:
      // Don't show error for user cancellation
      debugPrint('User cancelled the purchase');
      break;

    case ErrorCode.NetworkError:
      showUserMessage('Network error. Please check your connection and try again.');
      break;

    case ErrorCode.AlreadyOwned:
      showUserMessage('You already own this item.');
      // Optionally trigger restore purchases
      restorePreviousPurchases();
      break;

    default:
      showUserMessage('Purchase failed: ${error.message}');
  }
}
```

**Common Error Codes**:
- `ErrorCode.UserCancelled` - User cancelled
- `ErrorCode.NetworkError` - Network error
- `ErrorCode.ServiceError` - Service unavailable
- `ErrorCode.ItemUnavailable` - Item unavailable
- `ErrorCode.AlreadyOwned` - Already owned

See [Error Codes](./types/error-codes) for complete list.

---

## Complete Listener Setup

### Full Implementation Example

```dart
class IAPListenerManager {
  final _iap = FlutterInappPurchase.instance;

  StreamSubscription<Purchase>? _purchaseSubscription;
  StreamSubscription<PurchaseError>? _errorSubscription;

  bool _isListening = false;

  void startListening() {
    if (_isListening) return;

    // Purchase success listener
    _purchaseSubscription = _iap.purchaseUpdatedListener.listen(
      (purchase) {
        _handlePurchaseSuccess(purchase);
      },
      onError: (error) {
        debugPrint('Purchase stream error: $error');
      },
    );

    // Purchase error listener
    _errorSubscription = _iap.purchaseErrorListener.listen(
      (error) {
        _handlePurchaseError(error);
      },
      onError: (error) {
        debugPrint('Error stream error: $error');
      },
    );

    _isListening = true;
    debugPrint('IAP listeners started');
  }

  void stopListening() {
    _purchaseSubscription?.cancel();
    _errorSubscription?.cancel();

    _purchaseSubscription = null;
    _errorSubscription = null;

    _isListening = false;
    debugPrint('IAP listeners stopped');
  }

  Future<void> _handlePurchaseSuccess(Purchase purchase) async {
    // Verify purchase on server
    final isValid = await verifyPurchaseOnServer(purchase);
    if (!isValid) return;

    // Deliver content
    await deliverContent(purchase.productId);

    // Finish transaction
    await _iap.finishTransaction(
      purchase: purchase,
      isConsumable: false,
    );
  }

  void _handlePurchaseError(PurchaseError error) {
    if (error.code == ErrorCode.UserCancelled) return;

    showErrorMessage(error.message);
  }
}
```

## Best Practices

### 1. Set Up Listeners Before initConnection

```dart
@override
void initState() {
  super.initState();

  // Set up listeners FIRST
  _purchaseSubscription = iap.purchaseUpdatedListener.listen(
    (purchase) => _handlePurchase(purchase),
  );

  _errorSubscription = iap.purchaseErrorListener.listen(
    (error) => _handleError(error),
  );

  // THEN initialize connection
  iap.initConnection();
}
```

### 2. Always Cancel in Dispose

```dart
@override
void dispose() {
  _purchaseSubscription?.cancel();
  _errorSubscription?.cancel();
  super.dispose();
}
```

### 3. Handle Stream Errors

```dart
_purchaseSubscription = iap.purchaseUpdatedListener.listen(
  (purchase) {
    // Handle success
  },
  onError: (error) {
    debugPrint('Stream error: $error');
  },
);
```

### 4. Don't Block the Listener

```dart
// ❌ Wrong: Blocking listener with async work
iap.purchaseUpdatedListener.listen((purchase) async {
  await longRunningTask(purchase); // This blocks other purchases
});

// ✅ Correct: Fire and forget
iap.purchaseUpdatedListener.listen((purchase) {
  _processPurchaseAsync(purchase); // Don't await
});

Future<void> _processPurchaseAsync(Purchase purchase) async {
  // Handle async work here
}
```

## Platform-Specific Purchase Handling

### iOS Purchase

```dart
void _handlePurchase(Purchase purchase) {
  if (purchase is PurchaseIOS) {
    debugPrint('iOS Purchase: ${purchase.id}');
    debugPrint('Transaction state: ${purchase.transactionState}');
    debugPrint('Receipt: ${purchase.receiptData}');
  }
}
```

### Android Purchase

```dart
void _handlePurchase(Purchase purchase) {
  if (purchase is PurchaseAndroid) {
    debugPrint('Android Purchase: ${purchase.productId}');
    debugPrint('Purchase state: ${purchase.purchaseState}');
    debugPrint('Purchase token: ${purchase.purchaseToken}');
    debugPrint('Acknowledged: ${purchase.acknowledged}');
  }
}
```

## Troubleshooting

### Missing Purchases

**Symptom**: Purchases not appearing in listener

**Solution**: Ensure listeners are set up before `initConnection()`

```dart
// ✅ Correct order
_setupListeners();
await iap.initConnection();
```

### Memory Leaks

**Symptom**: App performance degrades over time

**Solution**: Always cancel subscriptions

```dart
@override
void dispose() {
  _purchaseSubscription?.cancel();
  _errorSubscription?.cancel();
  super.dispose();
}
```

## See Also

- [Core Methods](./core-methods) - Methods that trigger these events
- [Types](./types) - Event data structures
- [Error Codes](./types/error-codes) - Error handling reference
- [Purchase Lifecycle](../guides/lifecycle) - Complete purchase flow
