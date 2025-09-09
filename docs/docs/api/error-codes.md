---
title: Error Codes
sidebar_position: 5
---

# Error Codes

Comprehensive error handling reference for flutter_inapp_purchase v6.0.0. This guide covers all error codes, their meanings, and how to handle them effectively.

## ErrorCode Enum

The standardized error codes used across both platforms.

```dart
enum ErrorCode {
  eUnknown,                           // Unknown error
  eUserCancelled,                     // User cancelled
  eUserError,                         // User error
  eItemUnavailable,                   // Item unavailable
  eRemoteError,                       // Remote server error
  eNetworkError,                      // Network error
  eServiceError,                      // Service error
  eReceiptFailed,                     // Receipt validation failed
  eReceiptFinishedFailed,             // Receipt finish failed
  eNotPrepared,                       // Not prepared
  eNotEnded,                          // Not ended
  eAlreadyOwned,                      // Already owned
  eDeveloperError,                    // Developer error
  eBillingResponseJsonParseError,     // JSON parse error
  eDeferredPayment,                   // Deferred payment
  eInterrupted,                       // Interrupted
  eIapNotAvailable,                   // IAP not available
  ePurchaseError,                     // Purchase error
  eSyncError,                         // Sync error
  eTransactionValidationFailed,       // Transaction validation failed
  eActivityUnavailable,               // Activity unavailable
  eAlreadyPrepared,                   // Already prepared
  ePending,                           // Pending
  eConnectionClosed,                  // Connection closed
  // Additional error codes
  eBillingUnavailable,                // Billing unavailable
  eProductAlreadyOwned,               // Product already owned
  ePurchaseNotAllowed,                // Purchase not allowed
  eQuotaExceeded,                     // Quota exceeded
  eFeatureNotSupported,               // Feature not supported
  eNotInitialized,                    // Not initialized
  eAlreadyInitialized,                // Already initialized
  eClientInvalid,                     // Client invalid
  ePaymentInvalid,                    // Payment invalid
  ePaymentNotAllowed,                 // Payment not allowed
  eStorekitOriginalTransactionIdNotFound, // StoreKit transaction not found
  eNotSupported,                      // Not supported
  eTransactionFailed,                 // Transaction failed
  eTransactionInvalid,                // Transaction invalid
  eProductNotFound,                   // Product not found
  ePurchaseFailed,                    // Purchase failed
  eTransactionNotFound,               // Transaction not found
  eRestoreFailed,                     // Restore failed
  eRedeemFailed,                      // Redeem failed
  eNoWindowScene,                     // No window scene
  eShowSubscriptionsFailed,           // Show subscriptions failed
  eProductLoadFailed,                 // Product load failed
}
```

## PurchaseError Class

The main error class used throughout the library.

```dart
class PurchaseError implements Exception {
  final String name;                // Error name
  final String message;             // Human-readable error message
  final int? responseCode;          // Platform-specific response code
  final String? debugMessage;       // Additional debug information
  final ErrorCode? code;            // Standardized error code
  final String? productId;          // Related product ID (if applicable)
  final IAPPlatform? platform;      // Platform where error occurred

  PurchaseError({
    String? name,
    required this.message,
    this.responseCode,
    this.debugMessage,
    this.code,
    this.productId,
    this.platform,
  });
}
```

**Example Usage**:

```dart
try {
  await FlutterInappPurchase.instance.requestPurchase(
    request: request,
    type: PurchaseType.inapp,
  );
} on PurchaseError catch (e) {
  print('Error Code: ${e.code}');
  print('Message: ${e.message}');
  print('Platform: ${e.platform}');
  print('Product: ${e.productId}');
  print('Debug: ${e.debugMessage}');
}
```

## Common Error Codes

### User-Related Errors

#### eUserCancelled

**Meaning**: User cancelled the purchase  
**When it occurs**: User closes purchase dialog or cancels payment  
**User action**: No action needed - this is normal behavior  
**Developer action**: Don't show error messages for cancellation

```dart
if (error.code == ErrorCode.eUserCancelled) {
  // User cancelled - this is normal, don't show error
  print('User cancelled the purchase');
  return;
}
```

#### eUserError

**Meaning**: User made an error during purchase  
**When it occurs**: Invalid payment method, insufficient funds  
**User action**: Check payment method and try again  
**Developer action**: Show helpful message about payment methods

```dart
if (error.code == ErrorCode.eUserError) {
  showMessage('Please check your payment method and try again.');
}
```

#### eAlreadyOwned

**Meaning**: User already owns this product  
**When it occurs**: Attempting to purchase owned non-consumable  
**User action**: Product is already available  
**Developer action**: Unlock product or suggest restore purchases

```dart
if (error.code == ErrorCode.eAlreadyOwned) {
  showMessage('You already own this item.');
  // Optionally trigger restore purchases
  await restorePurchases();
}
```

### Network & Service Errors

#### eNetworkError

**Meaning**: Network connectivity issues  
**When it occurs**: No internet, poor connection, server timeout  
**User action**: Check internet connection  
**Developer action**: Show retry option

```dart
if (error.code == ErrorCode.eNetworkError) {
  showRetryDialog(
    'Network error. Please check your connection and try again.',
    onRetry: () => retryPurchase(),
  );
}
```

#### eServiceError

**Meaning**: Store service unavailable  
**When it occurs**: App Store/Play Store service issues  
**User action**: Try again later  
**Developer action**: Show temporary error message

```dart
if (error.code == ErrorCode.eServiceError) {
  showMessage('Store service temporarily unavailable. Please try again later.');
}
```

#### eRemoteError

**Meaning**: Remote server error  
**When it occurs**: Store backend issues  
**User action**: Try again later  
**Developer action**: Log for monitoring, show generic error

```dart
if (error.code == ErrorCode.eRemoteError) {
  logError('Remote server error', error);
  showMessage('Service temporarily unavailable. Please try again.');
}
```

### Product & Availability Errors

#### eItemUnavailable

**Meaning**: Product not available for purchase  
**When it occurs**: Product deleted, not in current storefront  
**User action**: Contact support if expected  
**Developer action**: Check product configuration

```dart
if (error.code == ErrorCode.eItemUnavailable) {
  showMessage('This item is currently unavailable.');
  // Log for investigation
  logError('Product unavailable: ${error.productId}', error);
}
```

#### eProductNotFound

**Meaning**: Product ID not found in store  
**When it occurs**: Invalid product ID, not published  
**User action**: Contact support  
**Developer action**: Verify product ID and store configuration

```dart
if (error.code == ErrorCode.eProductNotFound) {
  logError('Product not found: ${error.productId}', error);
  showMessage('Product not found. Please contact support.');
}
```

### Configuration & Developer Errors

#### eDeveloperError

**Meaning**: Developer configuration error  
**When it occurs**: Invalid parameters, wrong usage  
**User action**: Contact support  
**Developer action**: Fix implementation

```dart
if (error.code == ErrorCode.eDeveloperError) {
  logError('Developer error: ${error.message}', error);
  showMessage('Configuration error. Please contact support.');
}
```

#### eNotInitialized

**Meaning**: IAP not initialized  
**When it occurs**: Calling methods before `initConnection()`  
**User action**: None  
**Developer action**: Call `initConnection()` first

```dart
if (error.code == ErrorCode.eNotInitialized) {
  await FlutterInappPurchase.instance.initConnection();
  // Retry the operation
}
```

#### eAlreadyInitialized

**Meaning**: IAP already initialized  
**When it occurs**: Calling `initConnection()` multiple times  
**User action**: None  
**Developer action**: Check initialization state

```dart
if (error.code == ErrorCode.eAlreadyInitialized) {
  // Already initialized - continue with operation
  print('IAP already initialized');
}
```

## Platform-Specific Mappings

### iOS Error Code Mapping

```dart
static const Map<ErrorCode, int> ios = {
  ErrorCode.eUnknown: 0,
  ErrorCode.eServiceError: 1,
  ErrorCode.eUserCancelled: 2,
  ErrorCode.eUserError: 3,
  ErrorCode.eItemUnavailable: 4,
  ErrorCode.eRemoteError: 5,
  ErrorCode.eNetworkError: 6,
  ErrorCode.eReceiptFailed: 7,
  ErrorCode.eReceiptFinishedFailed: 8,
  ErrorCode.eDeveloperError: 9,
  ErrorCode.ePurchaseError: 10,
  ErrorCode.eSyncError: 11,
  ErrorCode.eDeferredPayment: 12,
  ErrorCode.eTransactionValidationFailed: 13,
  ErrorCode.eNotPrepared: 14,
  ErrorCode.eNotEnded: 15,
  ErrorCode.eAlreadyOwned: 16,
  // ... additional mappings
};
```

### Android Error Code Mapping

```dart
static const Map<ErrorCode, String> android = {
  ErrorCode.eUnknown: 'E_UNKNOWN',
  ErrorCode.eUserCancelled: 'E_USER_CANCELLED',
  ErrorCode.eUserError: 'E_USER_ERROR',
  ErrorCode.eItemUnavailable: 'E_ITEM_UNAVAILABLE',
  ErrorCode.eRemoteError: 'E_REMOTE_ERROR',
  ErrorCode.eNetworkError: 'E_NETWORK_ERROR',
  ErrorCode.eServiceError: 'E_SERVICE_ERROR',
  ErrorCode.eReceiptFailed: 'E_RECEIPT_FAILED',
  ErrorCode.eAlreadyOwned: 'E_ALREADY_OWNED',
  // ... additional mappings
};
```

## Error Handling Patterns

### Basic Error Handler

```dart
class ErrorHandler {
  static void handlePurchaseError(PurchaseError error) {
    switch (error.code) {
      case ErrorCode.eUserCancelled:
        // Don't show error for user cancellation
        break;

      case ErrorCode.eNetworkError:
        showRetryDialog('Network error. Please check your connection.');
        break;

      case ErrorCode.eAlreadyOwned:
        showMessage('You already own this item.');
        restorePurchases();
        break;

      case ErrorCode.eItemUnavailable:
        showMessage('This item is currently unavailable.');
        break;

      case ErrorCode.eServiceError:
        showMessage('Service temporarily unavailable. Please try again later.');
        break;

      default:
        showMessage('Purchase failed: ${error.message}');
        logError('Unhandled purchase error', error);
    }
  }

  static void showRetryDialog(String message) {
    // Implementation depends on your UI framework
  }

  static void showMessage(String message) {
    // Implementation depends on your UI framework
  }

  static void logError(String message, PurchaseError error) {
    // Log to your analytics/monitoring service
    print('$message: ${error.code} - ${error.message}');
  }

  static Future<void> restorePurchases() async {
    try {
      await FlutterInappPurchase.instance.restorePurchases();
    } catch (e) {
      print('Restore failed: $e');
    }
  }
}
```

### Comprehensive Error Handler

```dart
class ComprehensiveErrorHandler {
  static void handleError(dynamic error, {String? context}) {
    if (error is PurchaseError) {
      _handlePurchaseError(error, context: context);
    } else if (error is PlatformException) {
      _handlePlatformException(error, context: context);
    } else {
      _handleGenericError(error, context: context);
    }
  }

  static void _handlePurchaseError(PurchaseError error, {String? context}) {
    // Log error for analytics
    _logError(error, context: context);

    switch (error.code) {
      case ErrorCode.eUserCancelled:
        // Silent handling - user intentionally cancelled
        return;

      case ErrorCode.eNetworkError:
        _showNetworkError();
        break;

      case ErrorCode.eAlreadyOwned:
        _handleAlreadyOwned(error.productId);
        break;

      case ErrorCode.eItemUnavailable:
        _handleItemUnavailable(error.productId);
        break;

      case ErrorCode.eServiceError:
      case ErrorCode.eRemoteError:
        _showServiceError();
        break;

      case ErrorCode.eDeveloperError:
      case ErrorCode.eNotInitialized:
        _handleConfigurationError(error);
        break;

      case ErrorCode.eReceiptFailed:
      case ErrorCode.eTransactionValidationFailed:
        _handleValidationError(error);
        break;

      case ErrorCode.eDeferredPayment:
        _handleDeferredPayment();
        break;

      case ErrorCode.ePending:
        _handlePendingPurchase();
        break;

      default:
        _showGenericError(error.message);
    }
  }

  static void _showNetworkError() {
    showDialog(
      title: 'Connection Error',
      message: 'Please check your internet connection and try again.',
      actions: [
        DialogAction('Retry', onPressed: () => _retryLastOperation()),
        DialogAction('Cancel'),
      ],
    );
  }

  static void _handleAlreadyOwned(String? productId) {
    showDialog(
      title: 'Already Purchased',
      message: 'You already own this item. Would you like to restore your purchases?',
      actions: [
        DialogAction('Restore', onPressed: () => _restorePurchases()),
        DialogAction('OK'),
      ],
    );
  }

  static void _handleItemUnavailable(String? productId) {
    _logError('Product unavailable: $productId');
    showMessage('This item is currently unavailable. Please try again later.');
  }

  static void _showServiceError() {
    showMessage('Service temporarily unavailable. Please try again later.');
  }

  static void _handleConfigurationError(PurchaseError error) {
    _logError('Configuration error: ${error.message}');
    showMessage('Configuration error. Please contact support.');
  }

  static void _handleValidationError(PurchaseError error) {
    _logError('Validation error: ${error.message}');
    showMessage('Purchase validation failed. Please contact support.');
  }

  static void _handleDeferredPayment() {
    showMessage(
      'Your purchase is pending approval. You will be notified when it\'s approved.',
    );
  }

  static void _handlePendingPurchase() {
    showMessage('Your purchase is being processed. Please wait...');
  }

  static void _showGenericError(String message) {
    showMessage('Purchase failed: $message');
  }

  static void _logError(dynamic error, {String? context}) {
    final contextStr = context != null ? '[$context] ' : '';
    print('${contextStr}Error: $error');

    // Send to analytics/monitoring service
    // Analytics.logError(error, context: context);
  }
}
```

### Retry Logic

```dart
class RetryLogic {
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  static Future<T> withRetry<T>(
    Future<T> Function() operation, {
    bool Function(dynamic error)? shouldRetry,
    int maxAttempts = maxRetries,
  }) async {
    int attempts = 0;

    while (attempts < maxAttempts) {
      try {
        return await operation();
      } catch (error) {
        attempts++;

        if (attempts >= maxAttempts) {
          rethrow;
        }

        // Check if we should retry this error
        if (shouldRetry != null && !shouldRetry(error)) {
          rethrow;
        }

        // Only retry on specific errors
        if (error is PurchaseError) {
          switch (error.code) {
            case ErrorCode.eNetworkError:
            case ErrorCode.eServiceError:
            case ErrorCode.eRemoteError:
              // Retry these errors
              await Future.delayed(retryDelay * attempts);
              continue;
            default:
              // Don't retry other errors
              rethrow;
          }
        }

        rethrow;
      }
    }

    throw Exception('Max retry attempts exceeded');
  }
}

// Usage example
Future<void> makePurchaseWithRetry(String productId) async {
  try {
    await RetryLogic.withRetry(() async {
      final request = RequestPurchase(
        ios: RequestPurchaseIOS(sku: productId, quantity: 1),
        android: RequestPurchaseAndroid(skus: [productId]),
      );

      await FlutterInappPurchase.instance.requestPurchase(
        request: request,
        type: PurchaseType.inapp,
      );
    });
  } catch (e) {
    ComprehensiveErrorHandler.handleError(e, context: 'purchase');
  }
}
```

## Error Prevention

### Best Practices

1. **Always Initialize**: Call `initConnection()` before other operations
2. **Handle All Errors**: Implement comprehensive error handling
3. **User-Friendly Messages**: Show helpful messages, not technical details
4. **Log for Monitoring**: Track errors for analysis and improvement
5. **Graceful Degradation**: Continue app functionality when IAP fails

### Validation Checklist

```dart
class ValidationHelper {
  static Future<bool> validateBeforePurchase(String productId) async {
    try {
      // Check if IAP is initialized
      if (!FlutterInappPurchase.instance._isInitialized) {
        await FlutterInappPurchase.instance.initConnection();
      }

      // Check if product exists
      final products = await FlutterInappPurchase.instance.getProducts([productId]);
      if (products.isEmpty) {
        throw PurchaseError(
          code: ErrorCode.eProductNotFound,
          message: 'Product not found: $productId',
        );
      }

      // Check if already owned (for non-consumables)
      final availablePurchases = await FlutterInappPurchase.instance.getAvailablePurchases();
      if (availablePurchases.any((p) => p.productId == productId)) {
        throw PurchaseError(
          code: ErrorCode.eAlreadyOwned,
          message: 'Product already owned: $productId',
        );
      }

      return true;
    } catch (e) {
      ComprehensiveErrorHandler.handleError(e, context: 'validation');
      return false;
    }
  }
}
```

## Debugging Error Codes

### Debug Logging

```dart
class ErrorDebugger {
  static void logDetailedError(PurchaseError error) {
    print('=== Purchase Error Debug Info ===');
    print('Code: ${error.code}');
    print('Message: ${error.message}');
    print('Response Code: ${error.responseCode}');
    print('Debug Message: ${error.debugMessage}');
    print('Product ID: ${error.productId}');
    print('Platform: ${error.platform}');
    print('Platform Code: ${error.getPlatformCode()}');
    print('================================');
  }
}
```

### Testing Error Scenarios

```dart
class ErrorTesting {
  static Future<void> testErrorScenarios() async {
    // Test network error
    await _testNetworkError();

    // Test invalid product
    await _testInvalidProduct();

    // Test user cancellation
    await _testUserCancellation();
  }

  static Future<void> _testNetworkError() async {
    // Simulate network error conditions
  }

  static Future<void> _testInvalidProduct() async {
    try {
      await FlutterInappPurchase.instance.getProducts(['invalid_product_id']);
    } catch (e) {
      print('Expected error for invalid product: $e');
    }
  }

  static Future<void> _testUserCancellation() async {
    // Test cancellation flow
  }
}
```

## Migration Notes

⚠️ **Breaking Changes from v5.x:**

1. **Error Types**: `PurchaseError` replaces simple error strings
2. **Error Codes**: New `ErrorCode` enum for standardized handling
3. **Platform Codes**: Access via `getPlatformCode()` method
4. **Null Safety**: All error fields are properly nullable

## See Also

- [Core Methods](./core-methods.md) - Methods that can throw these errors
- [Listeners](./listeners.md) - Error event streams
- [Troubleshooting Guide](../guides/troubleshooting.md) - Solving common issues
- [Types](./types.md) - Error data structures
