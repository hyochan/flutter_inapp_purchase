---
title: Error Handling
sidebar_position: 5
---

import IapKitBanner from "@site/src/uis/IapKitBanner";

# Error Handling

<IapKitBanner />

Comprehensive error handling guide for flutter_inapp_purchase v7.0. Learn how to handle purchase errors effectively.

## PurchaseError Class

Errors are delivered through the `purchaseErrorListener` stream.

```dart
class PurchaseError {
  final ErrorCode code;
  final String message;
  final String? debugMessage;
  final String? productId;
}
```

**Listening for Errors**:

```dart
iap.purchaseErrorListener.listen((error) {
  debugPrint('Error: ${error.code} - ${error.message}');
  _handleError(error);
});
```

## Error Codes

For a complete list of error codes, see [Error Codes Reference](./types/error-codes).

## Error Handling Pattern

### Basic Handler

```dart
void _handleError(PurchaseError error) {
  switch (error.code) {
    case ErrorCode.UserCancelled:
      // Don't show error for user cancellation
      debugPrint('User cancelled purchase');
      break;

    case ErrorCode.NetworkError:
      _showMessage('Network error. Please check your connection.');
      break;

    case ErrorCode.AlreadyOwned:
      _showMessage('You already own this item.');
      _restorePurchases();
      break;

    case ErrorCode.ItemUnavailable:
      _showMessage('This item is currently unavailable.');
      break;

    case ErrorCode.ServiceError:
      _showMessage('Service temporarily unavailable. Please try again later.');
      break;

    default:
      _showMessage('Purchase failed: ${error.message}');
  }
}
```

## Best Practices

1. **Don't show errors for user cancellation** - Check for `ErrorCode.UserCancelled`
2. **Retry network errors** - Implement exponential backoff
3. **Log errors for monitoring** - Track error patterns
4. **Show user-friendly messages** - Avoid technical jargon
5. **Handle platform-specific errors** - Check error codes appropriately

## See Also

- [Error Codes Reference](./types/error-codes) - Complete error code list
- [Listeners](./listeners) - Error event streams
- [Troubleshooting](../guides/troubleshooting) - Solving common issues
