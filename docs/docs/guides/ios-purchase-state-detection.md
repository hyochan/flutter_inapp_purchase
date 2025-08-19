# iOS Purchase State Detection

## Overview

iOS purchase state detection can be complex due to the differences in how iOS App Store handles purchase confirmations compared to Android Google Play Store. This guide explains the common issues and solutions for proper iOS purchase state detection in flutter_inapp_purchase.

## Common iOS Purchase Issues

### 1. Processing State Stuck Issue

**Problem**: iOS purchases succeed (valid tokens and transaction IDs are generated) but the UI remains stuck in "Processing..." state.

**Root Cause**: The `transactionStateIOS` field often returns `null` even for successful purchases, while `purchaseToken` and `transactionId` contain valid data.

**Solution**: Use multiple conditions to detect successful purchases:

```dart
bool isPurchased = false;

if (Platform.isIOS) {
  bool condition1 = purchase.transactionStateIOS == TransactionState.purchased;
  bool condition2 = purchase.purchaseToken != null && purchase.purchaseToken!.isNotEmpty;
  bool condition3 = purchase.transactionId != null && purchase.transactionId!.isNotEmpty;

  // For iOS, receiving a purchase update usually means success
  // especially if we have either a valid token OR transaction ID
  isPurchased = condition1 || condition2 || condition3;
}
```

### 2. Timeout Errors

**Problem**: iOS purchases fail with timeout errors ("요청한 시간이 초과되었습니다").

**Root Cause**: Apple App Store server issues or network connectivity problems.

**Solutions**:
- Wait a few minutes and retry
- Check network connection (try switching between WiFi and cellular)
- Test on real device instead of simulator
- Restart the app or device
- Check Apple system status

## Implementation Best Practices

### 1. Comprehensive Purchase State Detection

```dart
Future<void> _handlePurchaseUpdate(Purchase purchase) async {
  print('🎯 Purchase update received: ${purchase.productId}');
  print('  Platform: ${purchase.platform}');
  print('  Transaction state iOS: ${purchase.transactionStateIOS}');
  print('  Purchase token: ${purchase.purchaseToken}');
  print('  Transaction ID: ${purchase.transactionId}');

  bool isPurchased = false;

  if (Platform.isIOS) {
    // Enhanced iOS detection logic
    bool hasValidState = purchase.transactionStateIOS == TransactionState.purchased;
    bool hasValidToken = purchase.purchaseToken != null && purchase.purchaseToken!.isNotEmpty;
    bool hasValidTransactionId = purchase.transactionId != null && purchase.transactionId!.isNotEmpty;

    isPurchased = hasValidState || hasValidToken || hasValidTransactionId;
    
    print('  iOS condition checks:');
    print('    transactionStateIOS == purchased: $hasValidState');
    print('    has valid purchaseToken: $hasValidToken');
    print('    has valid transactionId: $hasValidTransactionId');
    print('  Final isPurchased: $isPurchased');
  }

  if (isPurchased) {
    // Handle successful purchase
    setState(() {
      _isProcessing = false;
      _purchaseResult = '✅ Purchase successful: ${purchase.productId}';
    });

    // Finish the transaction
    await _iap.finishTransaction(purchase);
  }
}
```

### 2. Timeout Error Handling

```dart
void _handlePurchaseError(PurchaseError error) {
  if (error.message.contains('요청한 시간이 초과되었습니다') || 
      error.message.contains('timeout') ||
      error.message.contains('timed out')) {
    // Handle timeout specifically
    setState(() {
      _purchaseResult = '''
⏱️ Request Timeout
Code: ${error.code}
Message: ${error.message}

🔄 Suggested Actions:
1. Check your internet connection
2. Wait a few minutes and try again
3. Restart the app
4. Try on a different network (WiFi/Cellular)
5. Restart your device
6. Check Apple server status

This is usually a temporary server issue.
      ''';
    });
  }
}
```

### 3. Duplicate Transaction Prevention

```dart
class _PurchaseScreenState extends State<PurchaseScreen> {
  final Set<String> _processedTransactionIds = {};

  Future<void> _handlePurchaseUpdate(Purchase purchase) async {
    // Check for duplicate processing
    final transactionId = purchase.transactionId ?? purchase.purchaseToken ?? '';
    if (transactionId.isNotEmpty && _processedTransactionIds.contains(transactionId)) {
      print('⚠️ Transaction already processed: $transactionId');
      return;
    }

    // Process purchase...
    
    // Mark as processed
    if (transactionId.isNotEmpty) {
      _processedTransactionIds.add(transactionId);
    }
  }
}
```

## Debugging iOS Purchase Issues

### 1. Enable Detailed Logging

Add comprehensive logging to understand what's happening:

```dart
print('🎯 Purchase updated: ${purchase.productId}');
print('  Platform: ${purchase.platform}');
print('  Purchase state: ${purchase.purchaseState}');
print('  Transaction state iOS: ${purchase.transactionStateIOS}');
print('  Transaction ID: ${purchase.transactionId}');
print('  Purchase token: ${purchase.purchaseToken}');
print('  Purchase token length: ${purchase.purchaseToken?.length ?? 0}');
```

### 2. Test on Real Device

iOS Simulator can have different behavior than real devices. Always test critical purchase flows on physical iOS devices.

### 3. Check StoreKit Configuration

Ensure your StoreKit configuration file (if using StoreKit testing) has the correct product IDs and is properly configured.

## Troubleshooting Checklist

### For Processing State Issues:
- [ ] Verify purchase update listener is properly set up
- [ ] Check if `purchaseToken` or `transactionId` are present even when `transactionStateIOS` is null
- [ ] Ensure UI state is updated in the purchase listener
- [ ] Verify transaction is being finished with `finishTransaction()`

### For Timeout Issues:
- [ ] Test on different network connections
- [ ] Try on real device vs simulator
- [ ] Check Apple system status
- [ ] Verify product IDs are correct
- [ ] Ensure App Store Connect configuration is complete

### For Double Purchase Issues:
- [ ] Implement transaction ID tracking
- [ ] Check for duplicate listeners
- [ ] Verify `finishTransaction()` is called properly
- [ ] Add proper error handling

## Related Issues

- [iOS purchases stuck in Processing state](https://github.com/hyochan/flutter_inapp_purchase/issues/XXX)
- [Apple timeout errors](https://github.com/hyochan/flutter_inapp_purchase/issues/XXX)
- [Transaction state detection improvements](https://github.com/hyochan/flutter_inapp_purchase/issues/XXX)

## See Also

- [Purchase Flow Implementation](../examples/basic-store.md)
- [Error Handling Guide](./error-handling.md)
- [Troubleshooting Guide](./troubleshooting.md)