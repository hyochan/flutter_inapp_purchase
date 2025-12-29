---
sidebar_position: 6
title: Error Handling
---

import IapKitBanner from "@site/src/uis/IapKitBanner";

# Error Handling

<IapKitBanner />

This guide covers best practices for handling errors in your flutter_inapp_purchase implementation.

## Overview

flutter_inapp_purchase provides comprehensive error handling through standardized error codes and messages. All errors are returned as structured `PurchaseError` objects with consistent properties across iOS and Android platforms.

For a complete list of error codes, see [Error Codes](../api/error-codes).

## Error Structure

```dart
class PurchaseError {
  final String name;
  final String message;
  final int? responseCode;
  final String? debugMessage;
  final ErrorCode? code;
  final String? productId;
  final IapPlatform? platform;
}
```

## Common Error Scenarios

### Network Errors

Handle network connectivity issues gracefully:

```dart
final _iap = FlutterInappPurchase.instance;
StreamSubscription<PurchaseError>? _errorSubscription;

void setupErrorListener() {
  _errorSubscription = _iap.purchaseErrorListener.listen((error) {
    if (error.code == ErrorCode.NetworkError) {
      // Handle network issues
      showRetryDialog('Please check your internet connection');
    }
  });
}

@override
void dispose() {
  _errorSubscription?.cancel();
  super.dispose();
}
```

### User Cancellation

Gracefully handle when users cancel purchases:

```dart
void setupErrorListener() {
  _iap.purchaseErrorListener.listen((error) {
    if (error.code == ErrorCode.UserCancelled) {
      // User cancelled the purchase
      // Don't show error message, just continue
      debugPrint('User cancelled purchase');
      return;
    }
  });
}
```

### Payment Issues

Handle various payment-related errors:

```dart
void setupErrorListener() {
  _iap.purchaseErrorListener.listen((error) {
    switch (error.code) {
      case ErrorCode.DeveloperError:
        showMessage('Invalid payment method. Please check your payment settings.');
        break;
      case ErrorCode.ItemUnavailable:
        showMessage('This item is not available.');
        break;
      case ErrorCode.AlreadyOwned:
        showMessage('You already own this item.');
        break;
      case ErrorCode.Unknown:
      default:
        showMessage('Purchase failed. Please try again.');
    }
  });
}
```

## Error Recovery Strategies

### Retry Logic

Implement exponential backoff for transient errors:

```dart
Future<T> retryWithBackoff<T>(
  Future<T> Function() operation, {
  int maxRetries = 3,
}) async {
  for (int attempt = 0; attempt < maxRetries; attempt++) {
    try {
      return await operation();
    } catch (error) {
      if (attempt == maxRetries - 1) rethrow;

      // Only retry on network or service errors
      if (error is PurchaseError &&
          [ErrorCode.NetworkError, ErrorCode.ServiceError].contains(error.code)) {
        final delaySeconds = math.pow(2, attempt).toInt();
        await Future.delayed(Duration(seconds: delaySeconds));
      } else {
        rethrow;
      }
    }
  }
  throw Exception('Max retries exceeded');
}

// Usage
try {
  final products = await retryWithBackoff(() => iap.fetchProducts(
    skus: productIds,
    type: ProductQueryType.inApp,
  ));
} catch (error) {
  debugPrint('Failed after retries: $error');
}
```

### Graceful Degradation

Provide fallback experiences:

```dart
Future<void> handlePurchase(String productId) async {
  try {
    await _iap.requestPurchase(
      RequestPurchaseProps.inApp((
        apple: RequestPurchaseIosProps(sku: productId),
        google: RequestPurchaseAndroidProps(skus: [productId]),
        useAlternativeBilling: null,
      )),
    );
  } on PurchaseError catch (error) {
    if (error.code == ErrorCode.IapNotAvailable) {
      // Redirect to web subscription
      await redirectToWebPurchase(productId);
    } else {
      showErrorMessage(error.message);
    }
  } catch (error) {
    showErrorMessage('An unexpected error occurred');
  }
}
```

## Logging and Analytics

Track errors for debugging and analytics:

```dart
void trackError(PurchaseError error, String context) {
  debugPrint('IAP Error in $context: ${error.message}');

  // Send to analytics
  analytics.logEvent(
    name: 'iap_error',
    parameters: {
      'error_code': error.code?.name ?? 'unknown',
      'error_message': error.message,
      'context': context,
      'platform': Platform.isIOS ? 'ios' : 'android',
      'product_id': error.productId,
    },
  );
}

// Usage
_iap.purchaseErrorListener.listen((error) {
  trackError(error, 'purchase_flow');
  handlePurchaseError(error);
});
```

## Best Practices

### 1. Always Handle Errors

Never leave IAP operations without error handling:

```dart
// ❌ Bad - no error handling
iap.requestPurchase(
  RequestPurchaseProps.inApp((
    apple: RequestPurchaseIosProps(sku: productId),
    google: RequestPurchaseAndroidProps(skus: [productId]),
  )),
);

// ✅ Good - with error handling
try {
  await iap.requestPurchase(
    RequestPurchaseProps.inApp((
      apple: RequestPurchaseIosProps(sku: productId),
      google: RequestPurchaseAndroidProps(skus: [productId]),
    )),
  );
} catch (error) {
  handlePurchaseError(error);
}
```

### 2. Provide User-Friendly Messages

Convert technical errors to user-friendly messages:

```dart
String getUserFriendlyMessage(PurchaseError error) {
  switch (error.code) {
    case ErrorCode.UserCancelled:
      return ''; // Don't show message
    case ErrorCode.NetworkError:
      return 'Please check your internet connection and try again.';
    case ErrorCode.ItemUnavailable:
      return 'This item is currently unavailable.';
    case ErrorCode.AlreadyOwned:
      return 'You already own this item.';
    case ErrorCode.DeveloperError:
      return 'There was an issue with your payment method.';
    default:
      return 'Something went wrong. Please try again later.';
  }
}
```

### 3. Handle Platform Differences

Some errors may be platform-specific:

```dart
void handlePlatformSpecificError(PurchaseError error) {
  if (Platform.isIOS && error.code == ErrorCode.ItemUnavailable) {
    showMessage('This product is not available in your country.');
  } else if (Platform.isAndroid && error.code == ErrorCode.DeveloperError) {
    // Log for debugging but don't show to user
    debugPrint('Google Play configuration error: ${error.debugMessage}');
    showMessage('Please try again later.');
  }
}
```

### 4. Set Up Listeners Early

Initialize error listeners before making any IAP calls:

```dart
class PurchaseManager {
  final _iap = FlutterInappPurchase.instance;
  StreamSubscription<PurchaseError>? _errorSubscription;

  Future<void> initialize() async {
    // Set up error listener first
    _errorSubscription = _iap.purchaseErrorListener.listen(handleError);

    // Then initialize connection
    await _iap.initConnection();
  }

  void handleError(PurchaseError error) {
    final message = getUserFriendlyMessage(error);
    if (message.isNotEmpty) {
      showMessage(message);
    }
    trackError(error, 'purchase_manager');
  }

  void dispose() {
    _errorSubscription?.cancel();
  }
}
```

## Complete Example

```dart
class PurchaseHandler {
  final _iap = FlutterInappPurchase.instance;
  StreamSubscription<Purchase>? _purchaseSubscription;
  StreamSubscription<PurchaseError>? _errorSubscription;

  Future<void> initialize() async {
    // Set up listeners
    _purchaseSubscription = _iap.purchaseUpdatedListener.listen(_handlePurchase);
    _errorSubscription = _iap.purchaseErrorListener.listen(_handleError);

    // Initialize connection
    await _iap.initConnection();
  }

  void _handlePurchase(Purchase purchase) {
    debugPrint('Purchase success: ${purchase.productId}');
    // Process purchase
  }

  void _handleError(PurchaseError error) {
    debugPrint('Purchase error: ${error.code?.name} - ${error.message}');

    // Track error
    trackError(error, 'purchase_handler');

    // Show user-friendly message
    final message = getUserFriendlyMessage(error);
    if (message.isNotEmpty) {
      showMessage(message);
    }
  }

  String getUserFriendlyMessage(PurchaseError error) {
    switch (error.code) {
      case ErrorCode.UserCancelled:
        return '';
      case ErrorCode.NetworkError:
        return 'Please check your internet connection';
      case ErrorCode.ItemUnavailable:
        return 'This item is unavailable';
      case ErrorCode.AlreadyOwned:
        return 'You already own this item';
      default:
        return 'Purchase failed. Please try again.';
    }
  }

  void dispose() {
    _purchaseSubscription?.cancel();
    _errorSubscription?.cancel();
  }
}
```

## Next Steps

- [Error Codes](../api/error-codes) - Complete error code reference
- [Troubleshooting](./troubleshooting) - Common issues and solutions
- [Purchases](./purchases) - Purchase implementation guide
