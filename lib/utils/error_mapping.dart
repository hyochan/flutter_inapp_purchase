/// Error mapping utilities for flutter_inapp_purchase
/// Provides helper functions for handling platform-specific errors
library;

import '../types.dart';

/// Checks if an error is a user cancellation
/// @param error Error object or error code
/// @returns True if the error represents user cancellation
bool isUserCancelledError(dynamic error) {
  if (error is ErrorCode) {
    return error == ErrorCode.eUserCancelled;
  }

  if (error is String) {
    return error == ErrorCode.eUserCancelled.toString() ||
        error == 'E_USER_CANCELLED';
  }

  if (error is PurchaseError) {
    return error.code == ErrorCode.eUserCancelled;
  }

  if (error is Map<String, dynamic> && error['code'] != null) {
    return error['code'] == ErrorCode.eUserCancelled ||
        error['code'] == ErrorCode.eUserCancelled.toString() ||
        error['code'] == 'E_USER_CANCELLED';
  }

  return false;
}

/// Checks if an error is related to network connectivity
/// @param error Error object or error code
/// @returns True if the error is network-related
bool isNetworkError(dynamic error) {
  const networkErrors = [
    ErrorCode.eNetworkError,
    ErrorCode.eRemoteError,
    ErrorCode.eServiceError,
  ];

  ErrorCode? errorCode;

  if (error is ErrorCode) {
    errorCode = error;
  } else if (error is String) {
    // Try to parse string to ErrorCode
    try {
      errorCode = ErrorCode.values.firstWhere(
        (e) => e.toString() == error || e.toString().split('.').last == error,
      );
    } catch (_) {
      return false;
    }
  } else if (error is PurchaseError) {
    errorCode = error.code;
  } else if (error is Map<String, dynamic> && error['code'] != null) {
    if (error['code'] is ErrorCode) {
      errorCode = error['code'] as ErrorCode?;
    } else if (error['code'] is String) {
      try {
        errorCode = ErrorCode.values.firstWhere(
          (e) =>
              e.toString() == error['code'] ||
              e.toString().split('.').last == error['code'],
        );
      } catch (_) {
        return false;
      }
    }
  }

  return errorCode != null && networkErrors.contains(errorCode);
}

/// Checks if an error is recoverable (user can retry)
/// @param error Error object or error code
/// @returns True if the error is potentially recoverable
bool isRecoverableError(dynamic error) {
  const recoverableErrors = [
    ErrorCode.eNetworkError,
    ErrorCode.eRemoteError,
    ErrorCode.eServiceError,
    ErrorCode.eInterrupted,
  ];

  ErrorCode? errorCode;

  if (error is ErrorCode) {
    errorCode = error;
  } else if (error is String) {
    // Try to parse string to ErrorCode
    try {
      errorCode = ErrorCode.values.firstWhere(
        (e) => e.toString() == error || e.toString().split('.').last == error,
      );
    } catch (_) {
      return false;
    }
  } else if (error is PurchaseError) {
    errorCode = error.code;
  } else if (error is Map<String, dynamic> && error['code'] != null) {
    if (error['code'] is ErrorCode) {
      errorCode = error['code'] as ErrorCode?;
    } else if (error['code'] is String) {
      try {
        errorCode = ErrorCode.values.firstWhere(
          (e) =>
              e.toString() == error['code'] ||
              e.toString().split('.').last == error['code'],
        );
      } catch (_) {
        return false;
      }
    }
  }

  return errorCode != null && recoverableErrors.contains(errorCode);
}

/// Gets a user-friendly error message for display
/// @param error Error object or error code
/// @returns User-friendly error message
String getUserFriendlyErrorMessage(dynamic error) {
  ErrorCode? errorCode;
  String? fallbackMessage;

  if (error is ErrorCode) {
    errorCode = error;
  } else if (error is String) {
    // Try to parse string to ErrorCode
    try {
      errorCode = ErrorCode.values.firstWhere(
        (e) => e.toString() == error || e.toString().split('.').last == error,
      );
    } catch (_) {
      // If it's not a valid error code, use the string as fallback
      fallbackMessage = error;
    }
  } else if (error is PurchaseError) {
    errorCode = error.code;
    fallbackMessage = error.message;
  } else if (error is Map<String, dynamic>) {
    if (error['code'] != null) {
      if (error['code'] is ErrorCode) {
        errorCode = error['code'] as ErrorCode?;
      } else if (error['code'] is String) {
        try {
          errorCode = ErrorCode.values.firstWhere(
            (e) =>
                e.toString() == error['code'] ||
                e.toString().split('.').last == error['code'],
          );
        } catch (_) {
          // Not a valid error code
        }
      }
    }
    fallbackMessage = error['message']?.toString();
  }

  // Return specific message based on error code
  if (errorCode != null) {
    switch (errorCode) {
      case ErrorCode.eUserCancelled:
        return 'Purchase was cancelled by user';
      case ErrorCode.eNetworkError:
        return 'Network connection error. Please check your internet connection and try again.';
      case ErrorCode.eItemUnavailable:
        return 'This item is not available for purchase';
      case ErrorCode.eAlreadyOwned:
        return 'You already own this item';
      case ErrorCode.eProductAlreadyOwned:
        return 'You already own this product';
      case ErrorCode.eDeferredPayment:
        return 'Payment is pending approval';
      case ErrorCode.eNotPrepared:
        return 'In-app purchase is not ready. Please try again later.';
      case ErrorCode.eServiceError:
        return 'Store service error. Please try again later.';
      case ErrorCode.eTransactionValidationFailed:
        return 'Transaction could not be verified';
      case ErrorCode.eReceiptFailed:
        return 'Receipt processing failed';
      case ErrorCode.eDeveloperError:
        return 'Configuration error. Please contact support.';
      case ErrorCode.eBillingUnavailable:
        return 'Billing is not available on this device';
      case ErrorCode.ePurchaseNotAllowed:
        return 'Purchases are not allowed on this device';
      case ErrorCode.eFeatureNotSupported:
        return 'This feature is not supported on your device';
      case ErrorCode.eNotInitialized:
        return 'In-app purchase service is not initialized';
      case ErrorCode.eAlreadyInitialized:
        return 'In-app purchase service is already initialized';
      case ErrorCode.ePending:
        return 'Transaction is pending. Please wait.';
      case ErrorCode.eRemoteError:
        return 'Server error. Please try again later.';
      case ErrorCode.ePurchaseError:
        return 'Purchase failed. Please try again.';
      case ErrorCode.eProductNotFound:
        return 'Product not found in the store';
      case ErrorCode.eTransactionNotFound:
        return 'Transaction not found';
      case ErrorCode.eRestoreFailed:
        return 'Failed to restore purchases';
      case ErrorCode.eNoWindowScene:
        return 'Unable to present purchase dialog';
      default:
        // Fall through to fallback message
        break;
    }
  }

  // Return fallback message or generic error
  return fallbackMessage ?? 'An unexpected error occurred';
}

/// Extension on PurchaseError for convenience methods
extension PurchaseErrorExtensions on PurchaseError {
  /// Check if this error is a user cancellation
  bool get isUserCancelled => isUserCancelledError(this);

  /// Check if this error is network-related
  bool get isNetworkRelated => isNetworkError(this);

  /// Check if this error is recoverable
  bool get isRecoverable => isRecoverableError(this);

  /// Get a user-friendly message for this error
  String get userFriendlyMessage => getUserFriendlyErrorMessage(this);
}

/// Extension on ErrorCode for convenience methods
extension ErrorCodeExtensions on ErrorCode {
  /// Check if this error code represents a user cancellation
  bool get isUserCancelled => this == ErrorCode.eUserCancelled;

  /// Check if this error code is network-related
  bool get isNetworkRelated => [
        ErrorCode.eNetworkError,
        ErrorCode.eRemoteError,
        ErrorCode.eServiceError,
      ].contains(this);

  /// Check if this error code is recoverable
  bool get isRecoverable => [
        ErrorCode.eNetworkError,
        ErrorCode.eRemoteError,
        ErrorCode.eServiceError,
        ErrorCode.eInterrupted,
      ].contains(this);

  /// Get a user-friendly message for this error code
  String get userFriendlyMessage => getUserFriendlyErrorMessage(this);
}
