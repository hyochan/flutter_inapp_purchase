---
sidebar_position: 5
title: Error Handling
---

# Error Handling Guide

Comprehensive guide to handling errors in flutter_inapp_purchase for robust and user-friendly applications.

## Overview

Proper error handling is crucial for a smooth user experience in in-app purchase implementations. This guide covers error types, handling strategies, recovery mechanisms, and best practices.

## Error Types and Categories

### User Errors

Errors caused by user actions or decisions:

- User cancelled purchase
- Payment method issues
- Parental controls/restrictions

### System Errors

Errors related to system or service availability:

- Network connectivity issues
- Store service unavailable
- Billing service unavailable

### Developer Errors

Errors due to configuration or implementation issues:

- Product not found
- Invalid product IDs
- Missing permissions

### Transaction Errors

Errors during the purchase process:

- Payment processing failures
- Transaction timeouts
- Duplicate purchases

## Error Handling Architecture

### Central Error Handler

```dart
class IAPErrorHandler {
  static void handleError(dynamic error, {
    String? context,
    Map<String, dynamic>? metadata,
  }) {
    // Log the error
    _logError(error, context, metadata);

    // Determine error type
    final errorInfo = _categorizeError(error);

    // Handle based on type
    switch (errorInfo.category) {
      case ErrorCategory.user:
        _handleUserError(errorInfo);
        break;
      case ErrorCategory.system:
        _handleSystemError(errorInfo);
        break;
      case ErrorCategory.developer:
        _handleDeveloperError(errorInfo);
        break;
      case ErrorCategory.transaction:
        _handleTransactionError(errorInfo);
        break;
      default:
        _handleUnknownError(errorInfo);
    }
  }

  static ErrorInfo _categorizeError(dynamic error) {
    if (error is PurchaseError) {
      return _categorizePurchaseError(error);
    } else if (error is PlatformException) {
      return _categorizePlatformException(error);
    } else {
      return ErrorInfo(
        category: ErrorCategory.unknown,
        code: 'UNKNOWN',
        message: error.toString(),
        isRetryable: false,
      );
    }
  }

  static ErrorInfo _categorizePurchaseError(PurchaseError error) {
    switch (error.code) {
      case ErrorCode.E_USER_CANCELLED:
        return ErrorInfo(
          category: ErrorCategory.user,
          code: error.code.toString(),
          message: 'Purchase was cancelled',
          isRetryable: true,
          userMessage: 'Purchase cancelled',
        );

      case ErrorCode.E_NETWORK_ERROR:
        return ErrorInfo(
          category: ErrorCategory.system,
          code: error.code.toString(),
          message: error.message,
          isRetryable: true,
          userMessage: 'Please check your internet connection',
        );

      case ErrorCode.E_DEVELOPER_ERROR:
        return ErrorInfo(
          category: ErrorCategory.developer,
          code: error.code.toString(),
          message: error.message,
          isRetryable: false,
          userMessage: 'Service temporarily unavailable',
        );

      default:
        return ErrorInfo(
          category: ErrorCategory.unknown,
          code: error.code.toString(),
          message: error.message,
          isRetryable: false,
          userMessage: 'An error occurred. Please try again.',
        );
    }
  }
}
```

### Error Information Structure

```dart
enum ErrorCategory {
  user,
  system,
  developer,
  transaction,
  unknown,
}

class ErrorInfo {
  final ErrorCategory category;
  final String code;
  final String message;
  final bool isRetryable;
  final String? userMessage;
  final Duration? retryDelay;
  final Map<String, dynamic>? metadata;

  ErrorInfo({
    required this.category,
    required this.code,
    required this.message,
    required this.isRetryable,
    this.userMessage,
    this.retryDelay,
    this.metadata,
  });
}
```

## User Error Handling

### User-Friendly Error Messages

```dart
class UserErrorHandler {
  static void handleUserError(ErrorInfo error) {
    switch (error.code) {
      case 'E_USER_CANCELLED':
        // Don't show error for user cancellation
        break;

      case 'E_PAYMENT_NOT_ALLOWED':
        _showErrorDialog(
          title: 'Purchases Not Allowed',
          message: 'In-app purchases are disabled on this device. '
                   'Please check your device settings or parental controls.',
          actions: [_createSettingsAction()],
        );
        break;

      case 'E_PRODUCT_ALREADY_OWNED':
        _showErrorDialog(
          title: 'Already Purchased',
          message: 'You already own this item. Would you like to restore your purchases?',
          actions: [_createRestoreAction(), _createCancelAction()],
        );
        break;

      default:
        _showGenericErrorDialog(error.userMessage);
    }
  }

  static void _showErrorDialog({
    required String title,
    required String message,
    List<Widget>? actions,
  }) {
    // Implementation depends on your UI framework
    showDialog(
      context: NavigationService.context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: actions ?? [_createOkAction()],
      ),
    );
  }

  static Widget _createRestoreAction() {
    return TextButton(
      onPressed: () async {
        Navigator.of(NavigationService.context).pop();
        await PurchaseRestoreService.restorePurchases();
      },
      child: Text('Restore'),
    );
  }

  static Widget _createSettingsAction() {
    return TextButton(
      onPressed: () {
        Navigator.of(NavigationService.context).pop();
        // Open device settings if possible
        _openDeviceSettings();
      },
      child: Text('Settings'),
    );
  }
}
```

## System Error Handling

### Network and Service Errors

```dart
class SystemErrorHandler {
  static const int maxRetries = 3;
  static const Duration baseDelay = Duration(seconds: 2);

  static Future<void> handleSystemError(
    ErrorInfo error, {
    required Function() retryOperation,
  }) async {
    switch (error.code) {
      case 'E_NETWORK_ERROR':
        await _handleNetworkError(retryOperation);
        break;

      case 'E_SERVICE_ERROR':
      case 'E_BILLING_UNAVAILABLE':
        await _handleServiceError(error, retryOperation);
        break;

      default:
        _showSystemErrorDialog(error);
    }
  }

  static Future<void> _handleNetworkError(Function() retryOperation) async {
    final hasConnection = await ConnectivityService.hasConnection();

    if (!hasConnection) {
      _showNetworkErrorDialog();
    } else {
      // Network available but request failed - retry with backoff
      await _retryWithBackoff(retryOperation);
    }
  }

  static Future<void> _handleServiceError(
    ErrorInfo error,
    Function() retryOperation,
  ) async {
    // Show loading indicator
    LoadingService.show('Retrying...');

    try {
      // Wait before retry
      await Future.delayed(Duration(seconds: 5));

      // Retry the operation
      await retryOperation();

    } catch (e) {
      // Retry failed - show error to user
      _showServiceUnavailableDialog();
    } finally {
      LoadingService.hide();
    }
  }

  static Future<void> _retryWithBackoff(Function() operation) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        await operation();
        return; // Success
      } catch (e) {
        if (attempt == maxRetries) {
          // Final attempt failed
          _showRetryFailedDialog();
          break;
        }

        // Wait with exponential backoff
        final delay = baseDelay * (1 << (attempt - 1));
        await Future.delayed(delay);
      }
    }
  }

  static void _showNetworkErrorDialog() {
    UserErrorHandler._showErrorDialog(
      title: 'No Internet Connection',
      message: 'Please check your internet connection and try again.',
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(NavigationService.context),
          child: Text('OK'),
        ),
      ],
    );
  }
}
```

## Developer Error Handling

### Configuration and Setup Errors

```dart
class DeveloperErrorHandler {
  static void handleDeveloperError(ErrorInfo error) {
    // Log detailed error for developers
    _logDeveloperError(error);

    switch (error.code) {
      case 'E_NOT_INITIALIZED':
        _handleNotInitialized();
        break;

      case 'E_ITEM_UNAVAILABLE':
        _handleItemUnavailable(error);
        break;

      case 'E_DEVELOPER_ERROR':
        _handleConfigurationError(error);
        break;

      default:
        _handleGenericDeveloperError(error);
    }
  }

  static Future<void> _handleNotInitialized() async {
    print('IAP not initialized - attempting to initialize');

    try {
      await FlutterInappPurchase.instance.initConnection();
      print('IAP initialization successful');
    } catch (e) {
      print('IAP initialization failed: $e');
      _showGenericErrorToUser();
    }
  }

  static void _handleItemUnavailable(ErrorInfo error) {
    print('Product not available: ${error.message}');

    // Check if products are configured correctly
    _validateProductConfiguration();

    // Show user-friendly message
    UserErrorHandler._showErrorDialog(
      title: 'Product Unavailable',
      message: 'This item is currently not available. Please try again later.',
    );
  }

  static void _handleConfigurationError(ErrorInfo error) {
    print('Configuration error: ${error.message}');

    // Don't expose technical details to users
    _showGenericErrorToUser();

    // Report to crash analytics
    CrashReporting.recordError(
      'IAP Configuration Error',
      error.message,
      error.metadata,
    );
  }

  static void _validateProductConfiguration() {
    // Validate that products are configured in stores
    const expectedProducts = [
      'com.example.premium',
      'com.example.remove_ads',
    ];

    print('Expected products: $expectedProducts');
    print('Verify these are configured in App Store Connect and Play Console');
  }

  static void _showGenericErrorToUser() {
    UserErrorHandler._showErrorDialog(
      title: 'Service Unavailable',
      message: 'The service is temporarily unavailable. Please try again later.',
    );
  }
}
```

## Transaction Error Recovery

### Purchase Flow Recovery

```dart
class TransactionErrorRecovery {
  static Future<void> handleTransactionError(
    ErrorInfo error,
    String productId,
  ) async {
    switch (error.code) {
      case 'E_PURCHASE_FAILED':
        await _handlePurchaseFailure(productId);
        break;

      case 'E_TRANSACTION_TIMEOUT':
        await _handleTransactionTimeout(productId);
        break;

      case 'E_DUPLICATE_PURCHASE':
        await _handleDuplicatePurchase(productId);
        break;

      default:
        await _handleGenericTransactionError(error, productId);
    }
  }

  static Future<void> _handlePurchaseFailure(String productId) async {
    // Check if there are pending transactions
    final pendingPurchases = await FlutterInappPurchase.instance
        .getAvailablePurchases();

    final pendingForProduct = pendingPurchases
        .where((p) => p.productId == productId)
        .toList();

    if (pendingForProduct.isNotEmpty) {
      // There's a pending purchase - try to complete it
      await _completePendingPurchase(pendingForProduct.first);
    } else {
      // No pending purchase - safe to retry
      _showRetryPurchaseDialog(productId);
    }
  }

  static Future<void> _handleTransactionTimeout(String productId) async {
    // Show message that transaction is still processing
    UserErrorHandler._showErrorDialog(
      title: 'Transaction Processing',
      message: 'Your purchase is still being processed. '
               'Please wait a moment and check your purchases.',
      actions: [
        TextButton(
          onPressed: () async {
            Navigator.pop(NavigationService.context);
            await _checkPurchaseStatus(productId);
          },
          child: Text('Check Status'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(NavigationService.context),
          child: Text('OK'),
        ),
      ],
    );
  }

  static Future<void> _completePendingPurchase(Purchase purchase) async {
    try {
      // Verify the purchase
      final isValid = await PurchaseValidator.validate(purchase);

      if (isValid) {
        // Deliver content
        await ContentDelivery.deliver(purchase.productId);

        // Finish transaction
        await FlutterInappPurchase.instance.finishTransaction(purchase);

        // Notify user
        _showPurchaseCompletedMessage();
      } else {
        _showPurchaseValidationFailedMessage();
      }
    } catch (e) {
      print('Error completing pending purchase: $e');
      _showGenericErrorToUser();
    }
  }

  static Future<void> _checkPurchaseStatus(String productId) async {
    LoadingService.show('Checking purchase status...');

    try {
      final purchases = await FlutterInappPurchase.instance
          .getAvailablePurchases();

      final purchase = purchases
          .firstWhere((p) => p.productId == productId, orElse: () => null);

      if (purchase != null) {
        await _completePendingPurchase(purchase);
      } else {
        _showNoPurchaseFoundMessage();
      }
    } catch (e) {
      _showCheckStatusErrorMessage();
    } finally {
      LoadingService.hide();
    }
  }
}
```

## Error Recovery Strategies

### Automatic Recovery

```dart
class AutomaticErrorRecovery {
  static final Map<String, int> _retryCount = {};
  static const int maxAutoRetries = 2;

  static Future<bool> attemptRecovery(
    ErrorInfo error,
    String operationId,
    Function() operation,
  ) async {
    if (!error.isRetryable) {
      return false;
    }

    final retries = _retryCount[operationId] ?? 0;
    if (retries >= maxAutoRetries) {
      return false;
    }

    _retryCount[operationId] = retries + 1;

    try {
      // Wait before retry
      if (error.retryDelay != null) {
        await Future.delayed(error.retryDelay!);
      }

      // Attempt recovery based on error type
      await _performRecovery(error);

      // Retry original operation
      await operation();

      // Success - clear retry count
      _retryCount.remove(operationId);
      return true;

    } catch (e) {
      print('Auto recovery failed: $e');
      return false;
    }
  }

  static Future<void> _performRecovery(ErrorInfo error) async {
    switch (error.category) {
      case ErrorCategory.system:
        await _recoverFromSystemError(error);
        break;
      case ErrorCategory.developer:
        await _recoverFromDeveloperError(error);
        break;
      default:
        // No automatic recovery for other types
        break;
    }
  }

  static Future<void> _recoverFromSystemError(ErrorInfo error) async {
    switch (error.code) {
      case 'E_NOT_INITIALIZED':
        await FlutterInappPurchase.instance.initConnection();
        break;
      case 'E_NETWORK_ERROR':
        await _waitForNetworkRecovery();
        break;
    }
  }

  static Future<void> _waitForNetworkRecovery() async {
    // Wait for network to become available
    const maxWait = Duration(seconds: 30);
    const checkInterval = Duration(seconds: 2);

    final stopTime = DateTime.now().add(maxWait);

    while (DateTime.now().isBefore(stopTime)) {
      if (await ConnectivityService.hasConnection()) {
        return; // Network recovered
      }
      await Future.delayed(checkInterval);
    }

    throw Exception('Network recovery timeout');
  }
}
```

### Manual Recovery Options

```dart
class ManualRecoveryOptions {
  static void showRecoveryDialog(ErrorInfo error, String operationId) {
    final recoveryOptions = _getRecoveryOptions(error);

    showDialog(
      context: NavigationService.context,
      builder: (context) => AlertDialog(
        title: Text('Something went wrong'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(error.userMessage ?? 'An error occurred'),
            SizedBox(height: 16),
            Text(
              'What would you like to do?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: recoveryOptions.map((option) =>
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              option.action();
            },
            child: Text(option.label),
          )
        ).toList(),
      ),
    );
  }

  static List<RecoveryOption> _getRecoveryOptions(ErrorInfo error) {
    final options = <RecoveryOption>[];

    // Always offer retry for retryable errors
    if (error.isRetryable) {
      options.add(RecoveryOption(
        label: 'Try Again',
        action: () => _retryLastOperation(),
      ));
    }

    // Error-specific options
    switch (error.category) {
      case ErrorCategory.user:
        if (error.code == 'E_PRODUCT_ALREADY_OWNED') {
          options.add(RecoveryOption(
            label: 'Restore Purchases',
            action: () => PurchaseRestoreService.restorePurchases(),
          ));
        }
        break;

      case ErrorCategory.system:
        options.add(RecoveryOption(
          label: 'Check Connection',
          action: () => ConnectivityService.showConnectionStatus(),
        ));
        break;
    }

    // Always offer contact support
    options.add(RecoveryOption(
      label: 'Contact Support',
      action: () => SupportService.openSupportChat(),
    ));

    return options;
  }
}

class RecoveryOption {
  final String label;
  final VoidCallback action;

  RecoveryOption({required this.label, required this.action});
}
```

## Error Logging and Analytics

### Comprehensive Error Logging

```dart
class ErrorLogging {
  static void logError(
    dynamic error, {
    String? context,
    Map<String, dynamic>? metadata,
    StackTrace? stackTrace,
  }) {
    final errorData = {
      'error': error.toString(),
      'context': context,
      'timestamp': DateTime.now().toIso8601String(),
      'platform': Platform.isIOS ? 'ios' : 'android',
      'app_version': _getAppVersion(),
      'user_id': _getUserId(),
      'device_info': _getDeviceInfo(),
      'metadata': metadata,
    };

    // Log to console in debug mode
    if (kDebugMode) {
      print('IAP Error: ${json.encode(errorData)}');
      if (stackTrace != null) {
        print('Stack trace: $stackTrace');
      }
    }

    // Send to analytics in production
    if (kReleaseMode) {
      AnalyticsService.logError('iap_error', errorData);
    }

    // Send to crash reporting
    CrashReporting.recordError(
      error,
      stackTrace,
      context: errorData,
    );
  }

  static void logErrorPattern(String pattern, Map<String, dynamic> data) {
    AnalyticsService.logEvent('iap_error_pattern', {
      'pattern': pattern,
      'count': data['count'],
      'first_occurrence': data['first_occurrence'],
      'last_occurrence': data['last_occurrence'],
    });
  }
}
```

### Error Metrics and Monitoring

```dart
class ErrorMetrics {
  static final Map<String, int> _errorCounts = {};
  static final Map<String, DateTime> _firstOccurrence = {};
  static Timer? _reportingTimer;

  static void recordError(String errorCode) {
    _errorCounts[errorCode] = (_errorCounts[errorCode] ?? 0) + 1;
    _firstOccurrence[errorCode] ??= DateTime.now();

    _scheduleReporting();
  }

  static void _scheduleReporting() {
    _reportingTimer?.cancel();
    _reportingTimer = Timer(Duration(minutes: 5), _reportMetrics);
  }

  static void _reportMetrics() {
    for (final entry in _errorCounts.entries) {
      final errorCode = entry.key;
      final count = entry.value;

      ErrorLogging.logErrorPattern(errorCode, {
        'count': count,
        'first_occurrence': _firstOccurrence[errorCode]?.toIso8601String(),
        'last_occurrence': DateTime.now().toIso8601String(),
      });
    }

    // Reset counters
    _errorCounts.clear();
    _firstOccurrence.clear();
  }

  static Map<String, int> getErrorSummary() {
    return Map.from(_errorCounts);
  }
}
```

## Testing Error Scenarios

### Error Simulation

```dart
class ErrorSimulator {
  static bool enableSimulation = false;
  static double simulationRate = 0.1; // 10% error rate

  static void maybeThrowTestError(String operation) {
    if (!enableSimulation) return;
    if (Random().nextDouble() > simulationRate) return;

    final errorTypes = [
      PurchaseError(
        code: ErrorCode.E_NETWORK_ERROR,
        message: 'Simulated network error',
        platform: IAPPlatform.ios,
      ),
      PurchaseError(
        code: ErrorCode.E_SERVICE_ERROR,
        message: 'Simulated service error',
        platform: IAPPlatform.android,
      ),
    ];

    final randomError = errorTypes[Random().nextInt(errorTypes.length)];
    throw randomError;
  }

  static Future<void> simulateSpecificError(ErrorCode errorCode) async {
    throw PurchaseError(
      code: errorCode,
      message: 'Simulated error: $errorCode',
      platform: Platform.isIOS ? IAPPlatform.ios : IAPPlatform.android,
    );
  }
}
```

### Error Testing Framework

```dart
class ErrorTestSuite {
  static Future<void> runAllTests() async {
    await testUserCancellationError();
    await testNetworkError();
    await testServiceUnavailableError();
    await testProductNotFoundError();
    await testDuplicatePurchaseError();

    print('All error handling tests completed');
  }

  static Future<void> testUserCancellationError() async {
    try {
      await ErrorSimulator.simulateSpecificError(ErrorCode.E_USER_CANCELLED);
      assert(false, 'Expected error was not thrown');
    } catch (e) {
      IAPErrorHandler.handleError(e, context: 'test_user_cancellation');
      print('✓ User cancellation error handled correctly');
    }
  }

  static Future<void> testNetworkError() async {
    try {
      await ErrorSimulator.simulateSpecificError(ErrorCode.E_NETWORK_ERROR);
      assert(false, 'Expected error was not thrown');
    } catch (e) {
      IAPErrorHandler.handleError(e, context: 'test_network_error');
      print('✓ Network error handled correctly');
    }
  }

  // Add more test methods...
}
```

## Best Practices

1. **Categorize Errors**: Group errors by type for appropriate handling
2. **User-Friendly Messages**: Show helpful messages, not technical details
3. **Automatic Recovery**: Implement smart retry logic for recoverable errors
4. **Log Everything**: Comprehensive logging for debugging and analytics
5. **Test Error Scenarios**: Test all error paths in your application
6. **Graceful Degradation**: App should remain functional despite IAP errors
7. **Monitor Patterns**: Track error patterns to identify systemic issues
8. **Provide Alternatives**: Offer workarounds when possible

## Error Prevention

1. **Validate Early**: Check prerequisites before attempting operations
2. **Handle State**: Manage IAP state carefully to prevent errors
3. **Queue Operations**: Prevent concurrent IAP operations
4. **Cache Results**: Reduce API calls that might fail
5. **Update Dependencies**: Keep IAP libraries up to date

## Related Documentation

- [Purchases Guide](./purchases.md) - Purchase implementation
- [Subscriptions Guide](./subscriptions.md) - Subscription handling
- [API Types](../api/types/error-codes.md) - Error code reference
