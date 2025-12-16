/// Error types for flutter_inapp_purchase (OpenIAP compliant)
library errors;

import 'package:flutter/foundation.dart';

import 'types.dart' as openiap_types;

// Type aliases for convenience
typedef ErrorCode = openiap_types.ErrorCode;
typedef IapPlatform = openiap_types.IapPlatform;

/// Get current platform
IapPlatform getCurrentPlatform() {
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    return IapPlatform.IOS;
  } else if (defaultTargetPlatform == TargetPlatform.android) {
    return IapPlatform.Android;
  }
  throw UnsupportedError('Platform not supported');
}

/// Platform-specific error code mappings
class ErrorCodeMapping {
  static const Map<ErrorCode, int> ios = {
    // OpenIAP standard error codes
    ErrorCode.Unknown: 0,
    ErrorCode.UserCancelled: 2,
    ErrorCode.NetworkError: 1,
    ErrorCode.ItemUnavailable: 3,
    ErrorCode.ServiceError: 4,
    ErrorCode.ReceiptFailed: 5,
    ErrorCode.AlreadyOwned: 6,
    ErrorCode.RemoteError: 10,
    ErrorCode.ReceiptFinished: 11,
    ErrorCode.Pending: 12,
    ErrorCode.NotEnded: 13,
    ErrorCode.DeveloperError: 14,
    // Legacy codes for compatibility
    ErrorCode.ReceiptFinishedFailed: 15,
    ErrorCode.PurchaseError: 16,
    ErrorCode.SyncError: 17,
    ErrorCode.DeferredPayment: 18,
    ErrorCode.TransactionValidationFailed: 19,
    ErrorCode.NotPrepared: 20,
    ErrorCode.BillingResponseJsonParseError: 21,
    ErrorCode.Interrupted: 22,
    ErrorCode.IapNotAvailable: 23,
    ErrorCode.ActivityUnavailable: 24,
    ErrorCode.AlreadyPrepared: 25,
    ErrorCode.ConnectionClosed: 26,
    // Purchase verification codes
    ErrorCode.PurchaseVerificationFailed: 27,
    ErrorCode.PurchaseVerificationFinished: 28,
    ErrorCode.PurchaseVerificationFinishFailed: 29,
  };

  static const Map<ErrorCode, String> android = {
    ErrorCode.Unknown: 'E_UNKNOWN',
    ErrorCode.UserCancelled: 'E_USER_CANCELLED',
    ErrorCode.UserError: 'E_USER_ERROR',
    ErrorCode.ItemUnavailable: 'E_ITEM_UNAVAILABLE',
    ErrorCode.AlreadyOwned: 'E_ALREADY_OWNED',
    ErrorCode.NetworkError: 'E_NETWORK_ERROR',
    ErrorCode.ServiceError: 'E_SERVICE_ERROR',
    ErrorCode.RemoteError: 'E_REMOTE_ERROR',
    ErrorCode.ReceiptFailed: 'E_RECEIPT_FAILED',
    ErrorCode.ReceiptFinished: 'E_RECEIPT_FINISHED',
    ErrorCode.Pending: 'E_PENDING',
    ErrorCode.NotEnded: 'E_NOT_ENDED',
    ErrorCode.DeveloperError: 'E_DEVELOPER_ERROR',
    ErrorCode.ReceiptFinishedFailed: 'E_RECEIPT_FINISHED_FAILED',
    ErrorCode.NotPrepared: 'E_NOT_PREPARED',
    ErrorCode.BillingResponseJsonParseError:
        'E_BILLING_RESPONSE_JSON_PARSE_ERROR',
    ErrorCode.DeferredPayment: 'E_DEFERRED_PAYMENT',
    ErrorCode.Interrupted: 'E_INTERRUPTED',
    ErrorCode.IapNotAvailable: 'E_IAP_NOT_AVAILABLE',
    ErrorCode.PurchaseError: 'E_PURCHASE_ERROR',
    ErrorCode.SyncError: 'E_SYNC_ERROR',
    ErrorCode.TransactionValidationFailed: 'E_TRANSACTION_VALIDATION_FAILED',
    ErrorCode.ActivityUnavailable: 'E_ACTIVITY_UNAVAILABLE',
    ErrorCode.AlreadyPrepared: 'E_ALREADY_PREPARED',
    ErrorCode.ConnectionClosed: 'E_CONNECTION_CLOSED',
    ErrorCode.BillingUnavailable: 'E_BILLING_UNAVAILABLE',
    ErrorCode.SkuNotFound: 'E_SKU_NOT_FOUND',
    ErrorCode.SkuOfferMismatch: 'E_SKU_OFFER_MISMATCH',
    ErrorCode.ItemNotOwned: 'E_ITEM_NOT_OWNED',
    ErrorCode.FeatureNotSupported: 'E_FEATURE_NOT_SUPPORTED',
    ErrorCode.EmptySkuList: 'E_EMPTY_SKU_LIST',
    // Purchase verification codes
    ErrorCode.PurchaseVerificationFailed: 'E_PURCHASE_VERIFICATION_FAILED',
    ErrorCode.PurchaseVerificationFinished: 'E_PURCHASE_VERIFICATION_FINISHED',
    ErrorCode.PurchaseVerificationFinishFailed:
        'E_PURCHASE_VERIFICATION_FINISH_FAILED',
  };
}

/// Convert string to kebab-case
String _toKebabCase(String str) {
  if (str.contains('_')) {
    return str.split('_').map((word) => word.toLowerCase()).join('-');
  } else {
    return str
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => '-${match.group(1)}')
        .toLowerCase()
        .replaceFirst(RegExp(r'^-'), '');
  }
}

ErrorCode _normalizeToErrorCode(dynamic error) {
  if (error is PurchaseError && error.code != null) return error.code!;
  if (error is ErrorCode) return error;
  final dynamic code =
      error is String ? error : (error is Map ? error['code'] : null);
  final dynamic platformRaw = error is Map ? error['platform'] : null;
  final IapPlatform platform =
      platformRaw == 'ios' ? IapPlatform.IOS : IapPlatform.Android;
  if (code is String) {
    // First try platform-specific codes (E_* for Android, numeric for iOS)
    final platformResult = ErrorCodeUtils.fromPlatformCode(code, platform);
    if (platformResult != ErrorCode.Unknown) {
      return platformResult;
    }
    // If platform code is unknown, try to parse as OpenIAP kebab-case error code
    try {
      return ErrorCode.fromJson(code);
    } catch (_) {
      // If that also fails, fall back to message-based inference
    }
  }
  if (code is ErrorCode) return code;
  if (code is int) {
    return ErrorCodeUtils.fromPlatformCode(code, platform);
  }

  return ErrorCode.Unknown;
}

/// Returns a user-friendly message for the given error or error code
String getUserFriendlyErrorMessage(dynamic error) {
  final ErrorCode code = _normalizeToErrorCode(error);
  switch (code) {
    case ErrorCode.UserCancelled:
      return 'Purchase was cancelled by user';
    case ErrorCode.NetworkError:
      return 'Network connection error. Please check your internet connection and try again.';
    case ErrorCode.ItemUnavailable:
    case ErrorCode.SkuNotFound:
      return 'This item is not available for purchase';
    case ErrorCode.AlreadyOwned:
      return 'You already own this item';
    case ErrorCode.DeferredPayment:
      return 'Payment is pending approval';
    case ErrorCode.NotPrepared:
      return 'In-app purchase is not ready. Please try again later.';
    case ErrorCode.ServiceError:
      return 'Store service error. Please try again later.';
    case ErrorCode.TransactionValidationFailed:
      return 'Transaction could not be verified';
    case ErrorCode.ReceiptFailed:
      return 'Receipt processing failed';
    case ErrorCode.PurchaseVerificationFailed:
      return 'Purchase verification failed';
    case ErrorCode.PurchaseVerificationFinished:
      return 'Purchase verification completed';
    case ErrorCode.PurchaseVerificationFinishFailed:
      return 'Failed to finish purchase verification';
    default:
      // Try to surface message from PurchaseError if available
      if (error is PurchaseError && error.message.isNotEmpty) {
        return error.message;
      }
      if (error is Map && error['message'] is String) {
        return error['message'] as String;
      }
      return 'An unexpected error occurred';
  }
}

/// Purchase error class (OpenIAP compliant)
class PurchaseError implements Exception {
  final String name;
  final String message;
  final int? responseCode;
  final String? debugMessage;
  final ErrorCode? code;
  final String? productId;
  final IapPlatform? platform;

  PurchaseError({
    required this.message,
    String? name,
    this.responseCode,
    this.debugMessage,
    this.code,
    this.productId,
    this.platform,
  }) : name = name ?? '[flutter_inapp_purchase]: PurchaseError';

  /// Creates a PurchaseError from platform-specific error data
  factory PurchaseError.fromPlatformError(
    Map<String, dynamic> errorData,
    IapPlatform platform,
  ) {
    ErrorCode errorCode = errorData['code'] != null
        ? ErrorCodeUtils.fromPlatformCode(errorData['code'], platform)
        : ErrorCode.Unknown;

    // Always try to infer from message if we have one, as it might provide more specific information
    if (errorData['message'] != null) {
      final inferredCode = _normalizeToErrorCode(errorData);
      if (inferredCode != ErrorCode.Unknown) {
        errorCode = inferredCode;
      }
    }

    return PurchaseError(
      message: errorData['message']?.toString() ?? 'Unknown error occurred',
      responseCode: errorData['responseCode'] as int?,
      debugMessage: errorData['debugMessage']?.toString(),
      code: errorCode,
      productId: errorData['productId']?.toString(),
      platform: platform,
    );
  }

  /// Gets the platform-specific error code for this error
  dynamic getPlatformCode() {
    if (code == null || platform == null) return null;
    return ErrorCodeUtils.toPlatformCode(code!, platform!);
  }

  @override
  String toString() => '$name: $message';
}

/// Purchase result (legacy - kept for backward compatibility)
class PurchaseResult {
  final int? responseCode;
  final String? debugMessage;
  final String? code;
  final String? message;
  final String? purchaseTokenAndroid;

  PurchaseResult({
    this.responseCode,
    this.debugMessage,
    this.code,
    this.message,
    this.purchaseTokenAndroid,
  });

  PurchaseResult.fromJSON(Map<String, dynamic> json)
      : responseCode = json['responseCode'] as int?,
        debugMessage = json['debugMessage'] as String?,
        code = json['code'] as String?,
        message = json['message'] as String?,
        purchaseTokenAndroid = json['purchaseTokenAndroid'] as String?;

  Map<String, dynamic> toJson() => {
        'responseCode': responseCode ?? 0,
        'debugMessage': debugMessage ?? '',
        'code': code ?? '',
        'message': message ?? '',
        'purchaseTokenAndroid': purchaseTokenAndroid ?? '',
      };

  @override
  String toString() {
    return 'responseCode: $responseCode, '
        'debugMessage: $debugMessage, '
        'code: $code, '
        'message: $message';
  }
}

/// Utility functions for error code mapping and validation
class ErrorCodeUtils {
  /// Maps a platform-specific error code back to the standardized ErrorCode enum
  static ErrorCode fromPlatformCode(
    dynamic platformCode,
    IapPlatform platform,
  ) {
    // Handle string codes (Android E_* codes or OpenIAP kebab-case)
    if (platformCode is String) {
      // First try direct mapping from ErrorCodeMapping
      const mapping = ErrorCodeMapping.android;
      for (final entry in mapping.entries) {
        if (entry.value == platformCode) {
          return entry.key;
        }
      }

      // If starts with E_, try to normalize and find match
      if (platformCode.startsWith('E_')) {
        final withoutE = platformCode.substring(2);
        final kebabCased = _toKebabCase(withoutE);
        final withE = 'E_${kebabCased.toUpperCase().replaceAll('-', '_')}';

        // Try to find in mapping again with normalized form
        for (final entry in mapping.entries) {
          if (entry.value == withE) {
            return entry.key;
          }
        }
      }

      // Try to parse as OpenIAP kebab-case
      try {
        return ErrorCode.fromJson(platformCode);
      } catch (_) {
        // Fall back to unknown
      }

      return ErrorCode.Unknown;
    }

    // Handle legacy/numeric iOS codes
    if (platformCode is int) {
      const mapping = ErrorCodeMapping.ios;
      for (final entry in mapping.entries) {
        if (entry.value == platformCode) {
          return entry.key;
        }
      }
    }

    return ErrorCode.Unknown;
  }

  /// Maps an ErrorCode enum to platform-specific code
  static dynamic toPlatformCode(ErrorCode errorCode, IapPlatform platform) {
    if (platform == IapPlatform.IOS) {
      return ErrorCodeMapping.ios[errorCode] ?? 0;
    } else {
      return ErrorCodeMapping.android[errorCode] ?? 'E_UNKNOWN';
    }
  }

  /// Checks if an error code is valid for the specified platform
  static bool isValidForPlatform(ErrorCode errorCode, IapPlatform platform) {
    if (platform == IapPlatform.IOS) {
      return ErrorCodeMapping.ios.containsKey(errorCode);
    } else {
      return ErrorCodeMapping.android.containsKey(errorCode);
    }
  }
}

/// Connection result (legacy - kept for backward compatibility)
class ConnectionResult {
  final String? msg;

  ConnectionResult({this.msg});

  ConnectionResult.fromJSON(Map<String, dynamic> json)
      : msg = json['msg'] as String?;

  Map<String, dynamic> toJson() => {'msg': msg ?? ''};

  @override
  String toString() {
    return 'msg: $msg';
  }
}
