---
sidebar_position: 3
title: Error Codes
---

# Error Codes

Comprehensive error handling types and codes for flutter_inapp_purchase.

## ErrorCode Enum

Enumeration of all possible error codes that can occur during IAP operations.

```dart
enum ErrorCode {
  // User-related errors
  E_USER_CANCELLED,
  E_PAYMENT_NOT_ALLOWED,
  E_USER_ERROR,
  
  // Product/Item errors
  E_ITEM_UNAVAILABLE,
  E_PRODUCT_ALREADY_OWNED,
  E_PRODUCT_NOT_FOUND,
  E_PURCHASE_NOT_ALLOWED,
  
  // Service/Network errors
  E_SERVICE_ERROR,
  E_NETWORK_ERROR,
  E_BILLING_UNAVAILABLE,
  E_REMOTE_ERROR,
  
  // Developer errors
  E_DEVELOPER_ERROR,
  E_NOT_INITIALIZED,
  E_ALREADY_INITIALIZED,
  E_CLIENT_INVALID,
  
  // Transaction errors
  E_PAYMENT_INVALID,
  E_TRANSACTION_FAILED,
  E_TRANSACTION_INVALID,
  E_TRANSACTION_NOT_FOUND,
  E_PURCHASE_FAILED,
  
  // Platform-specific errors
  E_FEATURE_NOT_SUPPORTED,
  E_NOT_SUPPORTED,
  E_QUOTA_EXCEEDED,
  E_DEFERRED_PAYMENT,
  
  // Receipt/Validation errors
  E_RECEIPT_FAILED,
  E_RECEIPT_FINISHED_FAILED,
  
  // Subscription errors
  E_RESTORE_FAILED,
  E_SHOW_SUBSCRIPTIONS_FAILED,
  
  // iOS-specific errors
  E_STOREKIT_ORIGINAL_TRANSACTION_ID_NOT_FOUND,
  E_NO_WINDOW_SCENE,
  E_REDEEM_FAILED,
  
  // General errors
  E_UNKNOWN,
  E_PENDING,
}
```

## PurchaseError Class

Main error class containing error details and platform information.

```dart
class PurchaseError {
  final ErrorCode code;
  final String message;
  final String? debugMessage;
  final IAPPlatform platform;
  
  PurchaseError({
    required this.code,
    required this.message,
    this.debugMessage,
    required this.platform,
  });
}
```

### Properties

- `code` - The specific error code
- `message` - Human-readable error message
- `debugMessage` - Additional debug information (optional)
- `platform` - Platform where the error occurred

## Error Categories

### User-Related Errors

```dart
void handleUserErrors(PurchaseError error) {
  switch (error.code) {
    case ErrorCode.E_USER_CANCELLED:
      // User cancelled the purchase dialog
      showMessage('Purchase cancelled');
      break;
      
    case ErrorCode.E_PAYMENT_NOT_ALLOWED:
      // Parental controls or restrictions
      showMessage('Purchases are not allowed on this device');
      break;
      
    case ErrorCode.E_USER_ERROR:
      // General user-related error
      showMessage('Please try again');
      break;
  }
}
```

### Product/Item Errors

```dart
void handleProductErrors(PurchaseError error) {
  switch (error.code) {
    case ErrorCode.E_ITEM_UNAVAILABLE:
      // Product not found in store
      showMessage('This item is not available');
      break;
      
    case ErrorCode.E_PRODUCT_ALREADY_OWNED:
      // User already owns this product
      showMessage('You already own this item');
      _restoreProduct();
      break;
      
    case ErrorCode.E_PRODUCT_NOT_FOUND:
      // Product ID not configured
      showMessage('Product not found');
      _reportToAnalytics('product_not_found', error.debugMessage);
      break;
  }
}
```

### Service Errors

```dart
Future<void> handleServiceErrors(PurchaseError error) async {
  switch (error.code) {
    case ErrorCode.E_SERVICE_ERROR:
      // Store service unavailable
      showMessage('Store service is unavailable. Please try again later.');
      await _retryAfterDelay();
      break;
      
    case ErrorCode.E_NETWORK_ERROR:
      // Network connectivity issues
      showMessage('Please check your internet connection');
      break;
      
    case ErrorCode.E_BILLING_UNAVAILABLE:
      // Billing service not available
      showMessage('Billing is not available on this device');
      break;
  }
}
```

### Developer Errors

```dart
void handleDeveloperErrors(PurchaseError error) {
  switch (error.code) {
    case ErrorCode.E_NOT_INITIALIZED:
      // IAP not initialized
      print('IAP not initialized - initializing now');
      _initializeIAP();
      break;
      
    case ErrorCode.E_ALREADY_INITIALIZED:
      // Already initialized (not really an error)
      print('IAP already initialized');
      break;
      
    case ErrorCode.E_DEVELOPER_ERROR:
      // Configuration issue
      print('Developer error: ${error.message}');
      _reportToAnalytics('developer_error', error.debugMessage);
      break;
      
    case ErrorCode.E_CLIENT_INVALID:
      // Invalid client configuration
      print('Invalid client configuration');
      break;
  }
}
```

## Complete Error Handler

```dart
class ErrorHandler {
  static void handlePurchaseError(PurchaseError error) {
    print('Purchase error: ${error.code} - ${error.message}');
    if (error.debugMessage != null) {
      print('Debug: ${error.debugMessage}');
    }
    
    switch (error.code) {
      // User cancelled - normal flow
      case ErrorCode.E_USER_CANCELLED:
        _showSnackbar('Purchase cancelled');
        break;
        
      // Already owned - restore the product
      case ErrorCode.E_PRODUCT_ALREADY_OWNED:
        _showSnackbar('You already own this item');
        _attemptRestore();
        break;
        
      // Service unavailable - suggest retry
      case ErrorCode.E_SERVICE_ERROR:
      case ErrorCode.E_BILLING_UNAVAILABLE:
        _showRetryDialog('Store service unavailable');
        break;
        
      // Network issues - check connectivity
      case ErrorCode.E_NETWORK_ERROR:
        _showNetworkError();
        break;
        
      // Product not available
      case ErrorCode.E_ITEM_UNAVAILABLE:
        _showSnackbar('This item is not available');
        _refreshProductList();
        break;
        
      // Payment not allowed - device restriction
      case ErrorCode.E_PAYMENT_NOT_ALLOWED:
        _showSnackbar('Purchases are disabled on this device');
        break;
        
      // Not initialized - try to initialize
      case ErrorCode.E_NOT_INITIALIZED:
        _reinitializeIAP();
        break;
        
      // Generic handling for other errors
      default:
        _showGenericError(error.message);
    }
    
    // Always log errors for analytics
    _logError(error);
  }
  
  static void _showSnackbar(String message) {
    // Show user-friendly message
  }
  
  static void _showRetryDialog(String message) {
    // Show dialog with retry option
  }
  
  static void _showNetworkError() {
    // Show network connectivity message
  }
  
  static void _showGenericError(String message) {
    // Show generic error message
  }
  
  static void _attemptRestore() {
    // Try to restore the purchase
  }
  
  static void _refreshProductList() {
    // Refresh available products
  }
  
  static void _reinitializeIAP() {
    // Reinitialize IAP connection
  }
  
  static void _logError(PurchaseError error) {
    // Log to analytics service
  }
}
```

## Platform-Specific Error Mapping

### Android Response Codes

```dart
class AndroidErrorMapper {
  static ErrorCode mapBillingResponseCode(int responseCode) {
    switch (responseCode) {
      case 0: // BILLING_RESPONSE_RESULT_OK
        return ErrorCode.E_UNKNOWN; // Shouldn't happen in error context
      case 1: // BILLING_RESPONSE_RESULT_USER_CANCELED
        return ErrorCode.E_USER_CANCELLED;
      case 2: // BILLING_RESPONSE_RESULT_SERVICE_UNAVAILABLE
        return ErrorCode.E_SERVICE_ERROR;
      case 3: // BILLING_RESPONSE_RESULT_BILLING_UNAVAILABLE
        return ErrorCode.E_BILLING_UNAVAILABLE;
      case 4: // BILLING_RESPONSE_RESULT_ITEM_UNAVAILABLE
        return ErrorCode.E_ITEM_UNAVAILABLE;
      case 5: // BILLING_RESPONSE_RESULT_DEVELOPER_ERROR
        return ErrorCode.E_DEVELOPER_ERROR;
      case 6: // BILLING_RESPONSE_RESULT_ERROR
        return ErrorCode.E_SERVICE_ERROR;
      case 7: // BILLING_RESPONSE_RESULT_ITEM_ALREADY_OWNED
        return ErrorCode.E_PRODUCT_ALREADY_OWNED;
      case 8: // BILLING_RESPONSE_RESULT_ITEM_NOT_OWNED
        return ErrorCode.E_PURCHASE_NOT_ALLOWED;
      default:
        return ErrorCode.E_UNKNOWN;
    }
  }
}
```

### iOS Error Mapping

```dart
class IOSErrorMapper {
  static ErrorCode mapStoreKitError(int errorCode) {
    switch (errorCode) {
      case 0: // SKErrorUnknown
        return ErrorCode.E_UNKNOWN;
      case 1: // SKErrorClientInvalid
        return ErrorCode.E_CLIENT_INVALID;
      case 2: // SKErrorPaymentCancelled
        return ErrorCode.E_USER_CANCELLED;
      case 3: // SKErrorPaymentInvalid
        return ErrorCode.E_PAYMENT_INVALID;
      case 4: // SKErrorPaymentNotAllowed
        return ErrorCode.E_PAYMENT_NOT_ALLOWED;
      case 5: // SKErrorStoreProductNotAvailable
        return ErrorCode.E_ITEM_UNAVAILABLE;
      case 6: // SKErrorCloudServicePermissionDenied
        return ErrorCode.E_FEATURE_NOT_SUPPORTED;
      case 7: // SKErrorCloudServiceNetworkConnectionFailed
        return ErrorCode.E_NETWORK_ERROR;
      case 8: // SKErrorCloudServiceRevoked
        return ErrorCode.E_SERVICE_ERROR;
      default:
        return ErrorCode.E_UNKNOWN;
    }
  }
}
```

## Error Recovery Strategies

```dart
class ErrorRecoveryManager {
  final int maxRetries = 3;
  final Map<String, int> _retryCount = {};
  
  Future<bool> shouldRetry(PurchaseError error, String operationId) async {
    final retries = _retryCount[operationId] ?? 0;
    
    if (retries >= maxRetries) {
      return false;
    }
    
    switch (error.code) {
      // Network/service errors - retry with backoff
      case ErrorCode.E_NETWORK_ERROR:
      case ErrorCode.E_SERVICE_ERROR:
        await _backoffDelay(retries);
        _retryCount[operationId] = retries + 1;
        return true;
        
      // Not initialized - try once to reinitialize
      case ErrorCode.E_NOT_INITIALIZED:
        if (retries == 0) {
          await _reinitialize();
          _retryCount[operationId] = retries + 1;
          return true;
        }
        return false;
        
      // User errors - don't retry
      case ErrorCode.E_USER_CANCELLED:
      case ErrorCode.E_PAYMENT_NOT_ALLOWED:
        return false;
        
      // Product errors - don't retry
      case ErrorCode.E_ITEM_UNAVAILABLE:  
      case ErrorCode.E_PRODUCT_ALREADY_OWNED:
        return false;
        
      default:
        return false;
    }
  }
  
  Future<void> _backoffDelay(int retryCount) async {
    final delay = Duration(seconds: math.pow(2, retryCount).toInt());
    await Future.delayed(delay);
  }
  
  Future<void> _reinitialize() async {
    try {
      await FlutterInappPurchase.instance.endConnection();
      await FlutterInappPurchase.instance.initConnection();
    } catch (e) {
      print('Reinitialization failed: $e');
    }
  }
  
  void clearRetryCount(String operationId) {
    _retryCount.remove(operationId);
  }
}
```

## Best Practices

1. **Always Handle Errors**: Never ignore IAP errors
2. **User-Friendly Messages**: Show appropriate messages to users
3. **Log for Analytics**: Track error patterns for improvement  
4. **Retry Strategies**: Implement smart retry logic
5. **Fallback Options**: Provide alternative flows when possible
6. **Test Error Cases**: Test with various error scenarios

## Testing Error Scenarios

```dart
class ErrorTesting {
  // Simulate network error
  static void simulateNetworkError() {
    throw PurchaseError(
      code: ErrorCode.E_NETWORK_ERROR,
      message: 'Network connection failed',
      platform: IAPPlatform.ios,
    );
  }
  
  // Simulate user cancellation
  static void simulateUserCancellation() {
    throw PurchaseError(
      code: ErrorCode.E_USER_CANCELLED,
      message: 'User cancelled the purchase',
      platform: IAPPlatform.android,
    );
  }
  
  // Test error handling
  static void testErrorHandling() {
    final errors = [
      ErrorCode.E_USER_CANCELLED,
      ErrorCode.E_ITEM_UNAVAILABLE,
      ErrorCode.E_SERVICE_ERROR,
      ErrorCode.E_NOT_INITIALIZED,
    ];
    
    for (var errorCode in errors) {
      final error = PurchaseError(
        code: errorCode,
        message: 'Test error: $errorCode',
        platform: IAPPlatform.ios,
      );
      
      ErrorHandler.handlePurchaseError(error);
    }
  }
}
```