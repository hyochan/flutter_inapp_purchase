---
sidebar_position: 3
title: PurchasedItem
---

# PurchasedItem Class

Represents an item that was purchased from either the Google Play Store or iOS App Store.

## Overview

The `PurchasedItem` class contains all the information about a completed or pending purchase transaction. This includes transaction identifiers, receipts, purchase states, and platform-specific details.

## Properties

### Common Properties

```dart
final String? productId
```

The product identifier of the purchased item.

```dart
final String? transactionId
```

The unique transaction identifier.

```dart
final DateTime? transactionDate
```

The date and time when the transaction occurred.

```dart
final String? transactionReceipt
```

The receipt data for the transaction (primarily used on iOS).

```dart
final String? purchaseToken
```

The purchase token (primarily used on Android).

### Android-Specific Properties

```dart
final String? dataAndroid
```

The original purchase data from Google Play.

```dart
final String? signatureAndroid
```

The signature for purchase verification on Android.

```dart
final bool? autoRenewingAndroid
```

Whether the subscription is set to auto-renew.

```dart
final bool? isAcknowledgedAndroid
```

Whether the purchase has been acknowledged (Android requires acknowledgment within 3 days).

```dart
final PurchaseState? purchaseStateAndroid
```

The current state of the purchase on Android.

### iOS-Specific Properties

```dart
final DateTime? originalTransactionDateIOS
```

The date of the original transaction (for restored purchases).

```dart
final String? originalTransactionIdentifierIOS
```

The identifier of the original transaction (for restored purchases).

```dart
final TransactionState? transactionStateIOS
```

The current state of the transaction on iOS.

## Methods

### fromJSON()

```dart
PurchasedItem.fromJSON(Map<String, dynamic> json)
```

Creates a `PurchasedItem` instance from a JSON map.

### toString()

```dart
String toString()
```

Returns a string representation with all properties. Transaction dates are formatted in ISO 8601 format.

## Enums

### PurchaseState (Android)

```dart
enum PurchaseState {
  pending,    // Purchase is pending
  purchased,  // Purchase is completed
  unspecified // Unknown state
}
```

### TransactionState (iOS)

```dart
enum TransactionState {
  purchasing, // Transaction is being processed
  purchased,  // Transaction is completed
  failed,     // Transaction failed
  restored,   // Transaction was restored
  deferred    // Transaction is pending external action
}
```

## Usage Example

```dart
// Listen to purchase updates
FlutterInappPurchase.purchaseUpdated.listen((PurchasedItem? item) {
  if (item != null) {
    print('Product purchased: ${item.productId}');
    print('Transaction ID: ${item.transactionId}');
    print('Transaction Date: ${item.transactionDate}');

    // Platform-specific handling
    if (Platform.isIOS) {
      // Check iOS transaction state
      if (item.transactionStateIOS == TransactionState.purchased) {
        // Finish the transaction
        await FlutterInappPurchase.instance.finishTransaction(item);
      }
    } else if (Platform.isAndroid) {
      // Check if acknowledgment is needed
      if (item.isAcknowledgedAndroid == false) {
        await FlutterInappPurchase.instance.acknowledgePurchaseAndroid(
          purchaseToken: item.purchaseToken!
        );
      }
    }
  }
});

// Get purchase history
List<PurchasedItem>? history = await FlutterInappPurchase.instance.getPurchaseHistory();
if (history != null) {
  for (var purchase in history) {
    print('Previous purchase: ${purchase.productId}');
    print('Purchase date: ${purchase.transactionDate?.toIso8601String()}');
  }
}
```

## Receipt Validation

For receipt validation, use the appropriate properties:

**iOS:**

```dart
if (Platform.isIOS && item.transactionReceipt != null) {
  final response = await FlutterInappPurchase.instance.validateReceiptIos(
    receiptBody: {
      'receipt-data': item.transactionReceipt!,
      'password': 'your-shared-secret',
    },
    isTest: true, // Use sandbox for testing
  );
}
```

**Android:**

```dart
if (Platform.isAndroid && item.purchaseToken != null) {
  final response = await FlutterInappPurchase.instance.validateReceiptAndroid(
    packageName: 'com.example.app',
    productId: item.productId!,
    productToken: item.purchaseToken!,
    accessToken: 'your-access-token',
    isSubscription: false,
  );
}
```

## Platform Differences

### iOS

- Uses `transactionReceipt` for validation
- Has `transactionStateIOS` to track transaction lifecycle
- Supports restored purchases with original transaction information
- Must call `finishTransaction()` to complete the purchase

### Android

- Uses `purchaseToken` for validation
- Requires acknowledgment within 3 days via `acknowledgePurchaseAndroid()`
- Has `purchaseStateAndroid` to track purchase state
- Consumable items must be consumed via `consumePurchaseAndroid()`

## Important Notes

1. **Transaction Completion**: Always finish/acknowledge transactions to remove them from the queue
2. **Receipt Storage**: Store receipts securely for validation and restoration
3. **Date Handling**: Transaction dates are automatically converted from milliseconds since epoch
4. **Null Safety**: Most properties are nullable as not all platforms provide all information
