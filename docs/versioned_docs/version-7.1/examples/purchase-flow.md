---
sidebar_position: 1
---

import IapKitBanner from "@site/src/uis/IapKitBanner";

# Purchase Flow

<IapKitBanner />

> **Source Code**: [purchase_flow_screen.dart](https://github.com/hyochan/flutter_inapp_purchase/blob/main/example/lib/src/screens/purchase_flow_screen.dart)

This example demonstrates how to implement a complete in-app purchase flow for consumable and non-consumable products.

## Key Features

- Initialize connection to the store
- Fetch available products
- Handle purchase requests
- Listen to purchase events
- Finish transactions properly

## Implementation Overview

### 1. Set Up Listeners

```dart
StreamSubscription<Purchase>? _purchaseUpdatedSubscription;
StreamSubscription<PurchaseError>? _purchaseErrorSubscription;

@override
void initState() {
  super.initState();
  _setupListeners();
  _initConnection();
}

void _setupListeners() {
  _purchaseUpdatedSubscription = iap.purchaseUpdatedListener.listen(
    (purchase) {
      debugPrint('Purchase: ${purchase.productId}');
      _handlePurchase(purchase);
    },
  );

  _purchaseErrorSubscription = iap.purchaseErrorListener.listen(
    (error) {
      debugPrint('Error: ${error.code} - ${error.message}');
      _handleError(error);
    },
  );
}

@override
void dispose() {
  _purchaseUpdatedSubscription?.cancel();
  _purchaseErrorSubscription?.cancel();
  super.dispose();
}
```

### 2. Initialize Connection

```dart
Future<void> _initConnection() async {
  await iap.initConnection();
  debugPrint('IAP connection initialized');

  // Load products after connection
  await _loadProducts();
}
```

### 3. Fetch Products

```dart
final products = await iap.fetchProducts<Product>(
  skus: ['product_id_1', 'product_id_2'],
  type: ProductQueryType.InApp,
);
debugPrint('Loaded ${products.length} products');
```

### 4. Request Purchase

```dart
await iap.requestPurchase(
  RequestPurchaseProps.inApp((
    ios: RequestPurchaseIosProps(
      sku: 'product_id',
      quantity: 1,
    ),
    android: RequestPurchaseAndroidProps(
      skus: ['product_id'],
    ),
    useAlternativeBilling: null,
  )),
);
```

### 5. Handle Purchase Updates

```dart
Future<void> _handlePurchase(Purchase purchase) async {
  // 1. Verify purchase on server (recommended)
  final isValid = await verifyPurchaseOnServer(purchase);
  if (!isValid) return;

  // 2. Deliver content to user
  await deliverContent(purchase.productId);

  // 3. Finish transaction
  await iap.finishTransaction(
    purchase: purchase,
    isConsumable: true, // Set based on product type
  );
}
```

### 6. Handle Purchase Errors

```dart
void _handleError(PurchaseError error) {
  // Don't show error for user cancellation
  if (error.code == ErrorCode.UserCancelled) {
    return;
  }

  // Show error message to user
  showErrorMessage('Purchase failed: ${error.message}');
}
```

## Purchase Validation

```dart
Future<void> _handlePurchase(Purchase purchase) async {
  // IMPORTANT: Server-side receipt validation should be performed here
  // Send the receipt to your backend server for validation
  final isValid = await validateReceiptOnServer(purchase.purchaseToken);

  if (!isValid) {
    showMessage('Receipt validation failed');
    return;
  }

  // After successful server validation, finish the transaction
  await iap.finishTransaction(
    purchase: purchase,
    isConsumable: true, // For consumable products
  );
}
```

## Best Practices

1. **Always set up listeners before initConnection** - Prevents missing purchase events
2. **Verify purchases server-side** - Validate receipts with your backend before granting access
3. **Finish transactions properly** - Call `finishTransaction()` after successful validation
4. **Handle user cancellation gracefully** - Check for `ErrorCode.UserCancelled`
5. **Clean up subscriptions** - Cancel stream subscriptions in `dispose()`
