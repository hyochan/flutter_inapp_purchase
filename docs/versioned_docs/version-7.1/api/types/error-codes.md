---
sidebar_position: 3
title: Error Codes
---

import IapKitBanner from "@site/src/uis/IapKitBanner";

# Error Codes

<IapKitBanner />

Comprehensive error handling types and codes for flutter_inapp_purchase.

## ErrorCode Enum

Enumeration of all possible error codes that can occur during IAP operations.

```dart
enum ErrorCode {
  Unknown,
  UserCancelled,
  UserError,
  ItemUnavailable,
  RemoteError,
  NetworkError,
  ServiceError,
  ReceiptFailed,
  ReceiptFinished,
  ReceiptFinishedFailed,
  NotPrepared,
  NotEnded,
  AlreadyOwned,
  DeveloperError,
  BillingResponseJsonParseError,
  DeferredPayment,
  Interrupted,
  IapNotAvailable,
  PurchaseError,
  SyncError,
  TransactionValidationFailed,
  ActivityUnavailable,
  AlreadyPrepared,
  Pending,
  ConnectionClosed,
  InitConnection,
  ServiceDisconnected,
  QueryProduct,
  SkuNotFound,
  SkuOfferMismatch,
  ItemNotOwned,
  BillingUnavailable,
  FeatureNotSupported,
  EmptySkuList,
}
```

## Common Error Codes

### User-Related Errors

- **`UserCancelled`** - User cancelled the purchase dialog
- **`UserError`** - General user-related error
- **`DeferredPayment`** - Payment deferred (e.g., Ask to Buy on iOS)

### Product/Item Errors

- **`ItemUnavailable`** - Product not available in store
- **`AlreadyOwned`** - User already owns this product
- **`ItemNotOwned`** - User doesn't own the product (for consume/acknowledge)
- **`SkuNotFound`** - Product ID not found
- **`EmptySkuList`** - No product IDs provided
- **`SkuOfferMismatch`** - Offer doesn't match the product

### Service/Network Errors

- **`ServiceError`** - Store service unavailable
- **`NetworkError`** - Network connectivity issues
- **`BillingUnavailable`** - Billing service not available
- **`RemoteError`** - Remote server error
- **`ServiceDisconnected`** - Service connection lost

### Connection Errors

- **`NotPrepared`** - Connection not initialized
- **`AlreadyPrepared`** - Connection already initialized
- **`NotEnded`** - Connection not properly ended
- **`ConnectionClosed`** - Connection was closed
- **`InitConnection`** - Error during initialization

### Transaction Errors

- **`PurchaseError`** - General purchase error
- **`ReceiptFailed`** - Receipt validation failed
- **`ReceiptFinished`** - Receipt already finished
- **`ReceiptFinishedFailed`** - Failed to finish receipt
- **`TransactionValidationFailed`** - Transaction validation failed

### Developer Errors

- **`DeveloperError`** - Configuration or implementation issue
- **`BillingResponseJsonParseError`** - Failed to parse billing response
- **`QueryProduct`** - Error querying products
- **`ActivityUnavailable`** - Android Activity unavailable

### Platform-Specific Errors

- **`FeatureNotSupported`** - Feature not supported on platform
- **`IapNotAvailable`** - IAP not available on device

### Other Errors

- **`Unknown`** - Unknown or unspecified error
- **`Pending`** - Purchase is pending
- **`Interrupted`** - Purchase flow interrupted
- **`SyncError`** - Synchronization error

## Error Handling Examples

### Basic Error Handling

```dart
void _handleError(PurchaseError error) {
  switch (error.code) {
    case ErrorCode.UserCancelled:
      // Don't show error - user intentionally cancelled
      debugPrint('User cancelled purchase');
      break;

    case ErrorCode.NetworkError:
      _showMessage('Network error. Please check your connection.');
      break;

    case ErrorCode.AlreadyOwned:
      _showMessage('You already own this item.');
      // Suggest restore purchases
      break;

    case ErrorCode.ItemUnavailable:
      _showMessage('This item is currently unavailable.');
      break;

    case ErrorCode.ServiceError:
    case ErrorCode.BillingUnavailable:
      _showMessage('Store service unavailable. Please try again later.');
      break;

    default:
      _showMessage('Purchase failed: ${error.message}');
      debugPrint('Error code: ${error.code}');
  }
}
```

### Error Handling with Retry

```dart
Future<void> handleErrorWithRetry(PurchaseError error) async {
  switch (error.code) {
    case ErrorCode.NetworkError:
    case ErrorCode.ServiceError:
      // Retry with exponential backoff
      await _retryWithBackoff();
      break;

    case ErrorCode.NotPrepared:
      // Reinitialize connection
      await iap.initConnection();
      break;

    case ErrorCode.UserCancelled:
      // Don't retry
      break;

    default:
      _showError(error.message);
  }
}
```

## Best Practices

1. **Always Handle Errors** - Never ignore IAP errors, always listen to `purchaseErrorListener`
2. **User-Friendly Messages** - Show appropriate messages based on error code
3. **Log for Analytics** - Track error patterns to identify common issues
4. **Implement Retry Logic** - Retry for network/service errors with exponential backoff
5. **Don't Retry User Cancellations** - Respect when users cancel purchases
6. **Handle Platform Differences** - Some errors are platform-specific

## Related

- [Purchase Lifecycle](../../guides/lifecycle) - Full purchase flow
- [Error Handling Guide](../../guides/error-handling) - Comprehensive error handling
- [Troubleshooting](../../guides/troubleshooting) - Common error solutions
