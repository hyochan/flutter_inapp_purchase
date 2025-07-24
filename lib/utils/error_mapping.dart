/// Error mapping utilities for flutter_inapp_purchase
/// Provides helper functions for handling platform-specific errors

import '../types.dart';

/// Checks if an error is a user cancellation
/// @param error Error object or error code
/// @returns True if the error represents user cancellation
bool isUserCancelledError(dynamic error) {
  if (error is ErrorCode) {
    return error == ErrorCode.E_USER_CANCELLED;
  }

  if (error is String) {
    return error == ErrorCode.E_USER_CANCELLED.toString() ||
        error == 'E_USER_CANCELLED';
  }

  if (error is PurchaseError) {
    return error.code == ErrorCode.E_USER_CANCELLED;
  }

  if (error is Map<String, dynamic> && error['code'] != null) {
    return error['code'] == ErrorCode.E_USER_CANCELLED ||
        error['code'] == ErrorCode.E_USER_CANCELLED.toString() ||
        error['code'] == 'E_USER_CANCELLED';
  }

  return false;
}

/// Checks if an error is related to network connectivity
/// @param error Error object or error code
/// @returns True if the error is network-related
bool isNetworkError(dynamic error) {
  const networkErrors = [
    ErrorCode.E_NETWORK_ERROR,
    ErrorCode.E_REMOTE_ERROR,
    ErrorCode.E_SERVICE_ERROR,
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
    ErrorCode.E_NETWORK_ERROR,
    ErrorCode.E_REMOTE_ERROR,
    ErrorCode.E_SERVICE_ERROR,
    ErrorCode.E_INTERRUPTED,
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
      case ErrorCode.E_USER_CANCELLED:
        return 'Purchase was cancelled by user';
      case ErrorCode.E_NETWORK_ERROR:
        return 'Network connection error. Please check your internet connection and try again.';
      case ErrorCode.E_ITEM_UNAVAILABLE:
        return 'This item is not available for purchase';
      case ErrorCode.E_ALREADY_OWNED:
        return 'You already own this item';
      case ErrorCode.E_PRODUCT_ALREADY_OWNED:
        return 'You already own this product';
      case ErrorCode.E_DEFERRED_PAYMENT:
        return 'Payment is pending approval';
      case ErrorCode.E_NOT_PREPARED:
        return 'In-app purchase is not ready. Please try again later.';
      case ErrorCode.E_SERVICE_ERROR:
        return 'Store service error. Please try again later.';
      case ErrorCode.E_TRANSACTION_VALIDATION_FAILED:
        return 'Transaction could not be verified';
      case ErrorCode.E_RECEIPT_FAILED:
        return 'Receipt processing failed';
      case ErrorCode.E_DEVELOPER_ERROR:
        return 'Configuration error. Please contact support.';
      case ErrorCode.E_BILLING_UNAVAILABLE:
        return 'Billing is not available on this device';
      case ErrorCode.E_PURCHASE_NOT_ALLOWED:
        return 'Purchases are not allowed on this device';
      case ErrorCode.E_FEATURE_NOT_SUPPORTED:
        return 'This feature is not supported on your device';
      case ErrorCode.E_NOT_INITIALIZED:
        return 'In-app purchase service is not initialized';
      case ErrorCode.E_ALREADY_INITIALIZED:
        return 'In-app purchase service is already initialized';
      case ErrorCode.E_PENDING:
        return 'Transaction is pending. Please wait.';
      case ErrorCode.E_REMOTE_ERROR:
        return 'Server error. Please try again later.';
      case ErrorCode.E_PURCHASE_ERROR:
        return 'Purchase failed. Please try again.';
      case ErrorCode.E_PRODUCT_NOT_FOUND:
        return 'Product not found in the store';
      case ErrorCode.E_TRANSACTION_NOT_FOUND:
        return 'Transaction not found';
      case ErrorCode.E_RESTORE_FAILED:
        return 'Failed to restore purchases';
      case ErrorCode.E_NO_WINDOW_SCENE:
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
  bool get isUserCancelled => this == ErrorCode.E_USER_CANCELLED;

  /// Check if this error code is network-related
  bool get isNetworkRelated => [
        ErrorCode.E_NETWORK_ERROR,
        ErrorCode.E_REMOTE_ERROR,
        ErrorCode.E_SERVICE_ERROR,
      ].contains(this);

  /// Check if this error code is recoverable
  bool get isRecoverable => [
        ErrorCode.E_NETWORK_ERROR,
        ErrorCode.E_REMOTE_ERROR,
        ErrorCode.E_SERVICE_ERROR,
        ErrorCode.E_INTERRUPTED,
      ].contains(this);

  /// Get a user-friendly message for this error code
  String get userFriendlyMessage => getUserFriendlyErrorMessage(this);
}
