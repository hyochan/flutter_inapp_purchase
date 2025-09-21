---
title: Error Codes
sidebar_position: 5
---

# Error Codes

Comprehensive error handling reference for flutter_inapp_purchase v6.7.0. This guide covers all error codes, their meanings, and how to handle them effectively.

## ErrorCode Enum

The standardized error codes used across both platforms.

```dart
enum ErrorCode {
  Unknown,                           // Unknown error
  UserCancelled,                     // User cancelled
  UserError,                         // User error
  ItemUnavailable,                   // Item unavailable
  RemoteError,                       // Remote server error
  NetworkError,                      // Network error
  ServiceError,                      // Service error
  ReceiptFailed,                     // Receipt validation failed
  ReceiptFinishedFailed,             // Receipt finish failed
  NotPrepared,                       // Not prepared
  NotEnded,                          // Not ended
  AlreadyOwned,                      // Already owned
  DeveloperError,                    // Developer error
  BillingResponseJsonParseError,     // JSON parse error
  DeferredPayment,                   // Deferred payment
  Interrupted,                       // Interrupted
  IapNotAvailable,                   // IAP not available
  PurchaseError,                     // Purchase error
  SyncError,                         // Sync error
  TransactionValidationFailed,       // Transaction validation failed
  ActivityUnavailable,               // Activity unavailable
  AlreadyPrepared,                   // Already prepared
  Pending,                           // Pending
  ConnectionClosed,                  // Connection closed
  // Additional error codes
  BillingUnavailable,                // Billing unavailable
  ProductAlreadyOwned,               // Product already owned
  PurchaseNotAllowed,                // Purchase not allowed
  QuotaExceeded,                     // Quota exceeded
  FeatureNotSupported,               // Feature not supported
  NotInitialized,                    // Not initialized
  AlreadyInitialized,                // Already initialized
  ClientInvalid,                     // Client invalid
  PaymentInvalid,                    // Payment invalid
  PaymentNotAllowed,                 // Payment not allowed
  StorekitOriginalTransactionIdNotFound, // StoreKit transaction not found
  NotSupported,                      // Not supported
  TransactionFailed,                 // Transaction failed
  TransactionInvalid,                // Transaction invalid
  ProductNotFound,                   // Product not found
  PurchaseFailed,                    // Purchase failed
  TransactionNotFound,               // Transaction not found
  RestoreFailed,                     // Restore failed
  RedeemFailed,                      // Redeem failed
  NoWindowScene,                     // No window scene
  ShowSubscriptionsFailed,           // Show subscriptions failed
  ProductLoadFailed,                 // Product load failed
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

#### UserCancelled

**Meaning**: User cancelled the purchase  
**When it occurs**: User closes purchase dialog or cancels payment  
**User action**: No action needed - this is normal behavior  
**Developer action**: Don't show error messages for cancellation

```dart
if (error.code == ErrorCode.UserCancelled) {
  // User cancelled - this is normal, don't show error
  print('User cancelled the purchase');
  return;
}
```

#### UserError

**Meaning**: User made an error during purchase  
**When it occurs**: Invalid payment method, insufficient funds  
**User action**: Check payment method and try again  
**Developer action**: Show helpful message about payment methods

```dart
if (error.code == ErrorCode.UserError) {
  showMessage('Please check your payment method and try again.');
}
```

#### AlreadyOwned

**Meaning**: User already owns this product  
**When it occurs**: Attempting to purchase owned non-consumable  
**User action**: Product is already available  
**Developer action**: Unlock product or suggest restore purchases

```dart
if (error.code == ErrorCode.AlreadyOwned) {
  showMessage('You already own this item.');
  // Optionally trigger restore purchases
  await restorePurchases();
}
```

### Network & Service Errors

#### NetworkError

**Meaning**: Network connectivity issues  
**When it occurs**: No internet, poor connection, server timeout  
**User action**: Check internet connection  
**Developer action**: Show retry option

```dart
if (error.code == ErrorCode.NetworkError) {
  showRetryDialog(
    'Network error. Please check your connection and try again.',
    onRetry: () => retryPurchase(),
  );
}
```

#### ServiceError

**Meaning**: Store service unavailable  
**When it occurs**: App Store/Play Store service issues  
**User action**: Try again later  
**Developer action**: Show temporary error message

```dart
if (error.code == ErrorCode.ServiceError) {
  showMessage('Store service temporarily unavailable. Please try again later.');
}
```

#### RemoteError

**Meaning**: Remote server error  
**When it occurs**: Store backend issues  
**User action**: Try again later  
**Developer action**: Log for monitoring, show generic error

```dart
if (error.code == ErrorCode.RemoteError) {
  logError('Remote server error', error);
  showMessage('Service temporarily unavailable. Please try again.');
}
```

### Product & Availability Errors

#### ItemUnavailable

**Meaning**: Product not available for purchase  
**When it occurs**: Product deleted, not in current storefront  
**User action**: Contact support if expected  
**Developer action**: Check product configuration

```dart
if (error.code == ErrorCode.ItemUnavailable) {
  showMessage('This item is currently unavailable.');
  // Log for investigation
  logError('Product unavailable: ${error.productId}', error);
}
```

#### ProductNotFound

**Meaning**: Product ID not found in store  
**When it occurs**: Invalid product ID, not published  
**User action**: Contact support  
**Developer action**: Verify product ID and store configuration

```dart
if (error.code == ErrorCode.ProductNotFound) {
  logError('Product not found: ${error.productId}', error);
  showMessage('Product not found. Please contact support.');
}
```

### Configuration & Developer Errors

#### DeveloperError

**Meaning**: Developer configuration error  
**When it occurs**: Invalid parameters, wrong usage  
**User action**: Contact support  
**Developer action**: Fix implementation

```dart
if (error.code == ErrorCode.DeveloperError) {
  logError('Developer error: ${error.message}', error);
  showMessage('Configuration error. Please contact support.');
}
```

#### NotInitialized

**Meaning**: IAP not initialized  
**When it occurs**: Calling methods before `initConnection()`  
**User action**: None  
**Developer action**: Call `initConnection()` first

```dart
if (error.code == ErrorCode.NotInitialized) {
  await FlutterInappPurchase.instance.initConnection();
  // Retry the operation
}
```

#### AlreadyInitialized

**Meaning**: IAP already initialized  
**When it occurs**: Calling `initConnection()` multiple times  
**User action**: None  
**Developer action**: Check initialization state

```dart
if (error.code == ErrorCode.AlreadyInitialized) {
  // Already initialized - continue with operation
  print('IAP already initialized');
}
```

## Platform-Specific Mappings

### iOS Error Code Mapping

```dart
static const Map<ErrorCode, int> ios = {
  ErrorCode.Unknown: 0,
  ErrorCode.ServiceError: 1,
  ErrorCode.UserCancelled: 2,
  ErrorCode.UserError: 3,
  ErrorCode.ItemUnavailable: 4,
  ErrorCode.RemoteError: 5,
  ErrorCode.NetworkError: 6,
  ErrorCode.ReceiptFailed: 7,
  ErrorCode.ReceiptFinishedFailed: 8,
  ErrorCode.DeveloperError: 9,
  ErrorCode.PurchaseError: 10,
  ErrorCode.SyncError: 11,
  ErrorCode.DeferredPayment: 12,
  ErrorCode.TransactionValidationFailed: 13,
  ErrorCode.NotPrepared: 14,
  ErrorCode.NotEnded: 15,
  ErrorCode.AlreadyOwned: 16,
  // ... additional mappings
};
```

### Android Error Code Mapping

```dart
static const Map<ErrorCode, String> android = {
  ErrorCode.Unknown: 'E_UNKNOWN',
  ErrorCode.UserCancelled: 'E_USER_CANCELLED',
  ErrorCode.UserError: 'E_USER_ERROR',
  ErrorCode.ItemUnavailable: 'E_ITEM_UNAVAILABLE',
  ErrorCode.RemoteError: 'E_REMOTE_ERROR',
  ErrorCode.NetworkError: 'E_NETWORK_ERROR',
  ErrorCode.ServiceError: 'E_SERVICE_ERROR',
  ErrorCode.ReceiptFailed: 'E_RECEIPT_FAILED',
  ErrorCode.AlreadyOwned: 'E_ALREADY_OWNED',
  // ... additional mappings
};
```

## Error Handling Patterns

### Basic Error Handler

```dart
class ErrorHandler {
  static void handlePurchaseError(PurchaseError error) {
    switch (error.code) {
      case ErrorCode.UserCancelled:
        // Don't show error for user cancellation
        break;

      case ErrorCode.NetworkError:
        showRetryDialog('Network error. Please check your connection.');
        break;

      case ErrorCode.AlreadyOwned:
        showMessage('You already own this item.');
        restorePurchases();
        break;

      case ErrorCode.ItemUnavailable:
        showMessage('This item is currently unavailable.');
        break;

      case ErrorCode.ServiceError:
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
      case ErrorCode.UserCancelled:
        // Silent handling - user intentionally cancelled
        return;

      case ErrorCode.NetworkError:
        _showNetworkError();
        break;

      case ErrorCode.AlreadyOwned:
        _handleAlreadyOwned(error.productId);
        break;

      case ErrorCode.ItemUnavailable:
        _handleItemUnavailable(error.productId);
        break;

      case ErrorCode.ServiceError:
      case ErrorCode.RemoteError:
        _showServiceError();
        break;

      case ErrorCode.DeveloperError:
      case ErrorCode.NotInitialized:
        _handleConfigurationError(error);
        break;

      case ErrorCode.ReceiptFailed:
      case ErrorCode.TransactionValidationFailed:
        _handleValidationError(error);
        break;

      case ErrorCode.DeferredPayment:
        _handleDeferredPayment();
        break;

      case ErrorCode.Pending:
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
            case ErrorCode.NetworkError:
            case ErrorCode.ServiceError:
            case ErrorCode.RemoteError:
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
      final result = await FlutterInappPurchase.instance.fetchProducts(
        ProductRequest(
          skus: [productId],
          type: ProductQueryType.InApp,
        ),
      );
      final products = result.inAppProducts();
      if (products.isEmpty) {
        throw PurchaseError(
          code: ErrorCode.ProductNotFound,
          message: 'Product not found: $productId',
        );
      }

      // Check if already owned (for non-consumables)
      final availablePurchases = await FlutterInappPurchase.instance.getAvailablePurchases();
      if (availablePurchases.any((p) => p.productId == productId)) {
        throw PurchaseError(
          code: ErrorCode.AlreadyOwned,
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
      await FlutterInappPurchase.instance.fetchProducts(
        ProductRequest(
          skus: ['invalid_product_id'],
          type: ProductQueryType.InApp,
        ),
      );
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
