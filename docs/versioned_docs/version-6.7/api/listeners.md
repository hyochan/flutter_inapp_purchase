---
title: Listeners
sidebar_position: 4
---

# Event Listeners

Real-time event streams for monitoring purchase transactions, connection states, and other IAP events in flutter_inapp_purchase v6.7.0.

## Core Event Streams

### purchaseUpdated

Stream for successful purchase completions.

```dart
static Stream<Purchase?> get purchaseUpdated
```

**Type**: `Stream<Purchase?>`  
**Emits**: Purchase completion events  
**Null Safety**: Can emit null values - always check for null

**Example**:
```dart
StreamSubscription<Purchase?>? _purchaseSubscription;

void setupPurchaseListener() {
  _purchaseSubscription = FlutterInappPurchase.purchaseUpdated.listen(
    (purchase) {
      if (purchase != null) {
        handlePurchaseSuccess(purchase);
      }
    },
    onError: (error) {
      print('Purchase stream error: $error');
    },
  );
}

Future<void> handlePurchaseSuccess(Purchase purchase) async {
  print('Purchase completed: ${purchase.productId}');
  
  try {
    // 1. Verify the purchase (recommended)
    final isValid = await verifyPurchaseOnServer(purchase);
    if (!isValid) {
      print('Purchase verification failed');
      return;
    }
    
    // 2. Deliver the product to user
    await deliverProduct(purchase.productId);
    
    // 3. Finish the transaction
    await FlutterInappPurchase.instance.finishTransaction(
      purchase,
      isConsumable: true, // Set appropriately for your product
    );
    
    print('Purchase processed successfully');
  } catch (e) {
    print('Error processing purchase: $e');
  }
}

void dispose() {
  _purchaseSubscription?.cancel();
}
```

**Platform Data**:
- **iOS**: Contains `transactionReceipt`, `originalTransactionIdentifierIOS`
- **Android**: Contains `purchaseToken`, `dataAndroid`, `signatureAndroid`

---

### purchaseError

Stream for purchase failures and errors.

```dart
static Stream<PurchaseResult?> get purchaseError
```

**Type**: `Stream<PurchaseResult?>`  
**Emits**: Purchase error events  
**Null Safety**: Can emit null values - always check for null

**Example**:
```dart
StreamSubscription<PurchaseResult?>? _errorSubscription;

void setupErrorListener() {
  _errorSubscription = FlutterInappPurchase.purchaseError.listen(
    (error) {
      if (error != null) {
        handlePurchaseError(error);
      }
    },
  );
}

void handlePurchaseError(PurchaseResult error) {
  print('Purchase failed: ${error.message}');
  print('Error code: ${error.responseCode}');
  print('Debug info: ${error.debugMessage}');
  
  switch (error.responseCode) {
    case 1: // User cancelled
      // Don't show error for user cancellation
      print('User cancelled the purchase');
      break;
      
    case 2: // Network error
      showUserMessage('Network error. Please check your connection and try again.');
      break;
      
    case 7: // Already owned
      showUserMessage('You already own this item.');
      // Optionally trigger restore purchases
      restorePreviousPurchases();
      break;
      
    default:
      showUserMessage('Purchase failed: ${error.message ?? 'Unknown error'}');
  }
}
```

**Common Error Codes**:
- `1` - User cancelled
- `2` - Network error
- `3` - Service unavailable
- `4` - Item unavailable
- `7` - Already owned
- `8` - Invalid purchase

---

### connectionUpdated

Stream for store connection state changes.

```dart
static Stream<ConnectionResult> get connectionUpdated
```

**Type**: `Stream<ConnectionResult>`  
**Emits**: Connection state changes  
**Never Null**: Always emits valid `ConnectionResult` objects

**Example**:
```dart
StreamSubscription<ConnectionResult>? _connectionSubscription;

void setupConnectionListener() {
  _connectionSubscription = FlutterInappPurchase.connectionUpdated.listen(
    (connectionResult) {
      handleConnectionChange(connectionResult);
    },
  );
}

void handleConnectionChange(ConnectionResult result) {
  if (result.connected) {
    print('Store connected: ${result.message ?? 'Successfully connected'}');
    
    // Connection established - safe to load products
    loadProducts();
  } else {
    print('Store disconnected: ${result.message ?? 'Connection lost'}');
    
    // Handle disconnection - disable purchase UI
    disablePurchaseButtons();
    
    // Optionally attempt reconnection
    scheduleReconnection();
  }
}

Future<void> scheduleReconnection() async {
  await Future.delayed(Duration(seconds: 5));
  try {
    await FlutterInappPurchase.instance.initConnection();
  } catch (e) {
    print('Reconnection failed: $e');
  }
}
```

---

### purchasePromoted

Stream for promoted purchase events (iOS App Store promotions).

```dart
static Stream<String?> get purchasePromoted
```

**Type**: `Stream<String?>`  
**Emits**: Product ID of promoted purchases  
**Platform**: iOS only

**Example**:
```dart
StreamSubscription<String?>? _promotedSubscription;

void setupPromotedListener() {
  _promotedSubscription = FlutterInappPurchase.purchasePromoted.listen(
    (productId) {
      if (productId != null) {
        handlePromotedPurchase(productId);
      }
    },
  );
}

Future<void> handlePromotedPurchase(String productId) async {
  print('Promoted purchase initiated for: $productId');
  
  try {
    // Load product information
    final result = await FlutterInappPurchase.instance.fetchProducts(
      ProductRequest(
        skus: [productId],
        type: ProductQueryType.InApp,
      ),
    );
    final products = result.inAppProducts();
    if (products.isEmpty) {
      print('Promoted product not found: $productId');
      return;
    }
    
    final product = products.first;
    
    // Show promotional purchase UI
    final shouldPurchase = await showPromotedPurchaseDialog(product);
    
    if (shouldPurchase) {
      // Proceed with purchase
      final request = RequestPurchase(
        ios: RequestPurchaseIOS(sku: productId, quantity: 1),
        android: RequestPurchaseAndroid(skus: [productId]),
      );
      
      await FlutterInappPurchase.instance.requestPurchase(
        request: request,
        type: PurchaseType.inapp,
      );
    }
  } catch (e) {
    print('Error handling promoted purchase: $e');
  }
}
```

**Requirements**: iOS 11.0+, promoted purchases configured in App Store Connect

---

## Complete Listener Setup

### Full Implementation Example

```dart
class IAPListenerManager {
  StreamSubscription<Purchase?>? _purchaseSubscription;
  StreamSubscription<PurchaseResult?>? _errorSubscription;
  StreamSubscription<ConnectionResult>? _connectionSubscription;
  StreamSubscription<String?>? _promotedSubscription;
  
  bool _isListening = false;
  
  void startListening() {
    if (_isListening) return;
    
    // Purchase success listener
    _purchaseSubscription = FlutterInappPurchase.purchaseUpdated.listen(
      (purchase) {
        if (purchase != null) {
          _handlePurchaseSuccess(purchase);
        }
      },
      onError: (error) {
        print('Purchase stream error: $error');
      },
    );
    
    // Purchase error listener
    _errorSubscription = FlutterInappPurchase.purchaseError.listen(
      (error) {
        if (error != null) {
          _handlePurchaseError(error);
        }
      },
      onError: (error) {
        print('Error stream error: $error');
      },
    );
    
    // Connection state listener
    _connectionSubscription = FlutterInappPurchase.connectionUpdated.listen(
      (connectionResult) {
        _handleConnectionChange(connectionResult);
      },
      onError: (error) {
        print('Connection stream error: $error');
      },
    );
    
    // iOS promoted purchases
    if (Platform.isIOS) {
      _promotedSubscription = FlutterInappPurchase.purchasePromoted.listen(
        (productId) {
          if (productId != null) {
            _handlePromotedPurchase(productId);
          }
        },
      );
    }
    
    // Android in-app messages
    _isListening = true;
    print('IAP listeners started');
  }
  
  void stopListening() {
    _purchaseSubscription?.cancel();
    _errorSubscription?.cancel();
    _connectionSubscription?.cancel();
    _promotedSubscription?.cancel();
    
    _purchaseSubscription = null;
    _errorSubscription = null;
    _connectionSubscription = null;
    _promotedSubscription = null;
    
    _isListening = false;
    print('IAP listeners stopped');
  }
  
  Future<void> _handlePurchaseSuccess(Purchase purchase) async {
    // Implementation from examples above
  }
  
  void _handlePurchaseError(PurchaseResult error) {
    // Implementation from examples above
  }
  
  void _handleConnectionChange(ConnectionResult result) {
    // Implementation from examples above
  }
  
  Future<void> _handlePromotedPurchase(String productId) async {
    // Implementation from examples above
  }
  
}
```

## Error Handling Best Practices

### 1. Null Safety
Always check for null values in stream emissions:

```dart
FlutterInappPurchase.purchaseUpdated.listen((purchase) {
  if (purchase != null) {
    // Safe to use purchase
    processPurchase(purchase);
  } else {
    print('Received null purchase event');
  }
});
```

### 2. Stream Error Handling
Handle stream errors to prevent app crashes:

```dart
FlutterInappPurchase.purchaseUpdated.listen(
  (purchase) {
    // Handle success
  },
  onError: (error) {
    print('Purchase stream error: $error');
    // Optionally restart the stream or show user message
  },
  onDone: () {
    print('Purchase stream closed');
    // Handle stream closure
  },
);
```

### 3. Subscription Lifecycle
Properly manage subscription lifecycle:

```dart
class SubscriptionManager {
  StreamSubscription? _subscription;
  
  void start() {
    _subscription ??= FlutterInappPurchase.purchaseUpdated.listen(
      handlePurchase,
      onError: handleError,
    );
  }
  
  void stop() {
    _subscription?.cancel();
    _subscription = null;
  }
  
  void restart() {
    stop();
    start();
  }
}
```

## Platform Differences

### iOS-Specific Considerations

1. **Transaction State**: Use `transactionStateIOS` for detailed state
2. **Receipt Data**: Access via `transactionReceipt` 
3. **Original Transaction**: Available via `originalTransactionIdentifierIOS`
4. **Promoted Purchases**: Only available on iOS 11.0+

### Android-Specific Considerations

1. **Purchase State**: Use `purchaseStateAndroid` for state information
2. **Purchase Token**: Essential for consumption and acknowledgment
3. **Pending Purchases**: Handle state `2` for pending purchases
4. **In-App Messages**: Android-specific messaging system

## Performance Optimization

### 1. Lazy Listener Setup
Only set up listeners when needed:

```dart
StreamSubscription? _purchaseSubscription;

void startPurchaseFlow() {
  // Set up listener only when starting purchase
  _purchaseSubscription ??= FlutterInappPurchase.purchaseUpdated.listen(
    handlePurchase,
  );
  
  // Proceed with purchase
  requestPurchase();
}

void completePurchaseFlow() {
  // Clean up listener after purchase flow
  _purchaseSubscription?.cancel();
  _purchaseSubscription = null;
}
```

### 2. Debounced Error Handling
Avoid overwhelming users with repeated errors:

```dart
Timer? _errorDebounceTimer;

void handlePurchaseError(PurchaseResult error) {
  _errorDebounceTimer?.cancel();
  _errorDebounceTimer = Timer(Duration(seconds: 2), () {
    showErrorToUser(error.message);
  });
}
```

## Troubleshooting

### Common Issues

1. **Missing Purchases**: Ensure listeners are set up before `initConnection()`
2. **Memory Leaks**: Always cancel subscriptions in `dispose()`
3. **Null Emissions**: Always check for null in stream handlers
4. **Platform Crashes**: Handle stream errors with `onError`

### Debug Logging

```dart
void setupDebugLogging() {
  FlutterInappPurchase.purchaseUpdated.listen(
    (purchase) {
      print('🛒 Purchase: ${purchase?.productId ?? 'null'}');
    },
    onError: (error) {
      print('❌ Purchase Error: $error');
    },
  );
  
  FlutterInappPurchase.purchaseError.listen(
    (error) {
      print('🚫 Error: ${error?.message ?? 'null'}');
    },
  );
  
  FlutterInappPurchase.connectionUpdated.listen(
    (result) {
      print('🔗 Connection: ${result.connected ? 'Connected' : 'Disconnected'}');
    },
  );
}
```

## See Also

- [Core Methods](./core-methods.md) - Methods that trigger these events
- [Types](./types.md) - Event data structures
- [Error Codes](./error-codes.md) - Error handling reference
- [Purchase Guide](../guides/purchases.md) - Complete purchase flow implementation
