---
title: Listeners
sidebar_position: 4
---

import IapKitBanner from "@site/src/uis/IapKitBanner";

# Event Listeners

<IapKitBanner />

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

## userChoiceBillingAndroid

Android-only listener for User Choice Billing events. This fires when a user selects alternative billing instead of Google Play billing in the User Choice Billing dialog (only in `user-choice` mode).

```dart
Stream<UserChoiceBillingResult> get userChoiceBillingAndroid
```

**Example:**

```dart
import 'dart:io';
import 'dart:async';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

class UserChoiceBillingExample extends StatefulWidget {
  @override
  _UserChoiceBillingExampleState createState() => _UserChoiceBillingExampleState();
}

class _UserChoiceBillingExampleState extends State<UserChoiceBillingExample> {
  StreamSubscription<UserChoiceBillingResult>? _userChoiceSubscription;

  @override
  void initState() {
    super.initState();
    _setupUserChoiceBillingListener();
  }

  Future<void> _setupUserChoiceBillingListener() async {
    if (!Platform.isAndroid) return;

    // Initialize with user-choice mode
    await FlutterInappPurchase.instance.initConnection(
      alternativeBillingModeAndroid: AlternativeBillingModeAndroid.UserChoice,
    );

    _userChoiceSubscription = FlutterInappPurchase.instance
        .userChoiceBillingAndroid.listen((details) {
      debugPrint('User selected alternative billing');
      debugPrint('Token: ${details.externalTransactionToken}');
      debugPrint('Products: ${details.products}');

      _handleUserChoiceBilling(details);
    });
  }

  Future<void> _handleUserChoiceBilling(UserChoiceBillingResult details) async {
    try {
      // Step 1: Process payment in your payment system
      final paymentResult = await processPaymentInYourSystem(details.products);

      if (!paymentResult.success) {
        debugPrint('Payment failed');
        return;
      }

      // Step 2: Report token to Google Play backend within 24 hours
      await reportTokenToGooglePlay(
        token: details.externalTransactionToken,
        products: details.products,
        paymentResult: paymentResult,
      );

      debugPrint('Alternative billing completed successfully');
    } catch (error) {
      debugPrint('Error handling user choice billing: $error');
    }
  }

  @override
  void dispose() {
    _userChoiceSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ... your widget implementation
  }
}
```

**UserChoiceBillingResult Properties:**

```dart
class UserChoiceBillingResult {
  final String externalTransactionToken;  // Token to report to Google within 24 hours
  final List<String> products;            // Product IDs selected by user
}
```

**Platform:** Android only (requires `user-choice` mode)

**Important:**

- Only fires when using `alternativeBillingModeAndroid: AlternativeBillingModeAndroid.UserChoice`
- Token must be reported to Google Play backend within 24 hours
- If user selects Google Play billing instead, `purchaseUpdatedListener` will fire as normal
- Must clean up subscription in `dispose()` to prevent memory leaks

**Flow:**

1. User initiates purchase with `requestPurchase(useAlternativeBilling: true)`
2. Google shows User Choice Billing dialog
3. If user selects alternative billing → `userChoiceBillingAndroid` fires
4. If user selects Google Play → `purchaseUpdatedListener` fires

**See also:**

- [Alternative Billing Guide](../guides/alternative-billing) - Complete implementation guide
- [checkAlternativeBillingAvailabilityAndroid()](./core-methods#checkalternativebillingavailabilityandroid)
- [showAlternativeBillingDialogAndroid()](./core-methods#showalternativebillingdialogandroid)
- [createAlternativeBillingTokenAndroid()](./core-methods#createalternativebillingtokenandroid)

## See Also

- [Core Methods](./core-methods) - Methods that trigger these events
- [Types](./types) - Event data structures
- [Error Codes](./types/error-codes) - Error handling reference
- [Purchase Lifecycle](../guides/lifecycle) - Complete purchase flow
- [Alternative Billing Guide](../guides/alternative-billing) - Alternative billing implementation
