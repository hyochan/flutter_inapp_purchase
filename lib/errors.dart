/// Error types for flutter_inapp_purchase (OpenIAP compliant)

import 'dart:io';
import 'enums.dart';

/// Get current platform
IAPPlatform getCurrentPlatform() {
  if (Platform.isIOS) {
    return IAPPlatform.ios;
  } else if (Platform.isAndroid) {
    return IAPPlatform.android;
  }
  throw UnsupportedError('Platform not supported');
}

/// Platform-specific error code mappings
class ErrorCodeMapping {
  static const Map<ErrorCode, int> ios = {
    // OpenIAP standard error codes
    ErrorCode.eUnknown: 0,
    ErrorCode.eUserCancelled: 2, // SKErrorPaymentCancelled
    ErrorCode.eNetworkError: 1, // SKErrorClientInvalid
    ErrorCode.eItemUnavailable: 3,
    ErrorCode.eServiceError: 4,
    ErrorCode.eReceiptFailed: 5,
    ErrorCode.eAlreadyOwned: 6,
    ErrorCode.eProductNotAvailable: 7,
    ErrorCode.eProductAlreadyOwned: 8,
    ErrorCode.eUserError: 9,
    ErrorCode.eRemoteError: 10,
    ErrorCode.eReceiptFinished: 11,
    ErrorCode.ePending: 12,
    ErrorCode.eNotEnded: 13,
    ErrorCode.eDeveloperError: 14,
    // Legacy codes for compatibility
    ErrorCode.eReceiptFinishedFailed: 15,
    ErrorCode.ePurchaseError: 16,
    ErrorCode.eSyncError: 17,
    ErrorCode.eDeferredPayment: 18,
    ErrorCode.eTransactionValidationFailed: 19,
    ErrorCode.eNotPrepared: 20,
    ErrorCode.eBillingResponseJsonParseError: 21,
    ErrorCode.eInterrupted: 22,
    ErrorCode.eIapNotAvailable: 23,
    ErrorCode.eActivityUnavailable: 24,
    ErrorCode.eAlreadyPrepared: 25,
    ErrorCode.eConnectionClosed: 26,
  };

  static const Map<ErrorCode, String> android = {
    // OpenIAP standard error codes
    ErrorCode.eUnknown: 'E_UNKNOWN',
    ErrorCode.eUserCancelled: 'E_USER_CANCELLED',
    ErrorCode.eUserError: 'E_USER_ERROR',
    ErrorCode.eItemUnavailable: 'E_ITEM_UNAVAILABLE',
    ErrorCode.eProductNotAvailable: 'E_PRODUCT_NOT_AVAILABLE',
    ErrorCode.eProductAlreadyOwned: 'E_PRODUCT_ALREADY_OWNED',
    ErrorCode.eAlreadyOwned: 'E_ALREADY_OWNED',
    ErrorCode.eNetworkError: 'E_NETWORK_ERROR',
    ErrorCode.eServiceError: 'E_SERVICE_ERROR',
    ErrorCode.eRemoteError: 'E_REMOTE_ERROR',
    ErrorCode.eReceiptFailed: 'E_RECEIPT_FAILED',
    ErrorCode.eReceiptFinished: 'E_RECEIPT_FINISHED',
    ErrorCode.ePending: 'E_PENDING',
    ErrorCode.eNotEnded: 'E_NOT_ENDED',
    ErrorCode.eDeveloperError: 'E_DEVELOPER_ERROR',
    // Legacy codes for compatibility
    ErrorCode.eReceiptFinishedFailed: 'E_RECEIPT_FINISHED_FAILED',
    ErrorCode.eNotPrepared: 'E_NOT_PREPARED',
    ErrorCode.eBillingResponseJsonParseError:
        'E_BILLING_RESPONSE_JSON_PARSE_ERROR',
    ErrorCode.eDeferredPayment: 'E_DEFERRED_PAYMENT',
    ErrorCode.eInterrupted: 'E_INTERRUPTED',
    ErrorCode.eIapNotAvailable: 'E_IAP_NOT_AVAILABLE',
    ErrorCode.ePurchaseError: 'E_PURCHASE_ERROR',
    ErrorCode.eSyncError: 'E_SYNC_ERROR',
    ErrorCode.eTransactionValidationFailed: 'E_TRANSACTION_VALIDATION_FAILED',
    ErrorCode.eActivityUnavailable: 'E_ACTIVITY_UNAVAILABLE',
    ErrorCode.eAlreadyPrepared: 'E_ALREADY_PREPARED',
    ErrorCode.eConnectionClosed: 'E_CONNECTION_CLOSED',
  };
}

/// Purchase error class (OpenIAP compliant)
class PurchaseError implements Exception {
  final String name;
  final String message;
  final int? responseCode;
  final String? debugMessage;
  final ErrorCode? code;
  final String? productId;
  final IAPPlatform? platform;

  PurchaseError({
    String? name,
    required this.message,
    this.responseCode,
    this.debugMessage,
    this.code,
    this.productId,
    this.platform,
  }) : name = name ?? '[flutter_inapp_purchase]: PurchaseError';

  /// Creates a PurchaseError from platform-specific error data
  factory PurchaseError.fromPlatformError(
    Map<String, dynamic> errorData,
    IAPPlatform platform,
  ) {
    final errorCode = errorData['code'] != null
        ? ErrorCodeUtils.fromPlatformCode(errorData['code'], platform)
        : ErrorCode.eUnknown;

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
    IAPPlatform platform,
  ) {
    if (platform == IAPPlatform.ios) {
      final mapping = ErrorCodeMapping.ios;
      for (final entry in mapping.entries) {
        if (entry.value == platformCode) {
          return entry.key;
        }
      }
    } else {
      final mapping = ErrorCodeMapping.android;
      for (final entry in mapping.entries) {
        if (entry.value == platformCode) {
          return entry.key;
        }
      }
    }
    return ErrorCode.eUnknown;
  }

  /// Maps an ErrorCode enum to platform-specific code
  static dynamic toPlatformCode(ErrorCode errorCode, IAPPlatform platform) {
    if (platform == IAPPlatform.ios) {
      return ErrorCodeMapping.ios[errorCode] ?? 0;
    } else {
      return ErrorCodeMapping.android[errorCode] ?? 'E_UNKNOWN';
    }
  }

  /// Checks if an error code is valid for the specified platform
  static bool isValidForPlatform(ErrorCode errorCode, IAPPlatform platform) {
    if (platform == IAPPlatform.ios) {
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
