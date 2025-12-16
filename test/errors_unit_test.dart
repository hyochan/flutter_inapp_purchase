import 'package:flutter/foundation.dart';
import 'package:flutter_inapp_purchase/errors.dart' as errors;
import 'package:flutter_inapp_purchase/types.dart' as types;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('getCurrentPlatform', () {
    tearDown(() {
      // Reset platform override after each test
      debugDefaultTargetPlatformOverride = null;
    });

    test('returns IOS when running on iOS', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      expect(errors.getCurrentPlatform(), types.IapPlatform.IOS);
    });

    test('returns Android when running on Android', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(errors.getCurrentPlatform(), types.IapPlatform.Android);
    });

    test('throws UnsupportedError for unsupported platforms', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      expect(() => errors.getCurrentPlatform(), throwsUnsupportedError);

      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      expect(() => errors.getCurrentPlatform(), throwsUnsupportedError);

      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      expect(() => errors.getCurrentPlatform(), throwsUnsupportedError);

      debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
      expect(() => errors.getCurrentPlatform(), throwsUnsupportedError);
    });
  });

  group('ErrorCodeUtils', () {
    test('fromPlatformCode maps Android string codes', () {
      final code = errors.ErrorCodeUtils.fromPlatformCode(
        'E_ALREADY_OWNED',
        types.IapPlatform.Android,
      );
      expect(code, types.ErrorCode.AlreadyOwned);
    });

    test('fromPlatformCode maps iOS numeric codes', () {
      final iosCode = errors.ErrorCodeUtils.fromPlatformCode(
        4,
        types.IapPlatform.IOS,
      );
      expect(iosCode, types.ErrorCode.ServiceError);
    });

    test('toPlatformCode provides platform specific mapping', () {
      final iosValue = errors.ErrorCodeUtils.toPlatformCode(
        types.ErrorCode.NetworkError,
        types.IapPlatform.IOS,
      );
      expect(iosValue, isA<int>());

      final androidValue = errors.ErrorCodeUtils.toPlatformCode(
        types.ErrorCode.NetworkError,
        types.IapPlatform.Android,
      );
      expect(androidValue, 'E_NETWORK_ERROR');
    });

    test('isValidForPlatform validates error codes', () {
      expect(
        errors.ErrorCodeUtils.isValidForPlatform(
          types.ErrorCode.DeveloperError,
          types.IapPlatform.Android,
        ),
        isTrue,
      );
      expect(
        errors.ErrorCodeUtils.isValidForPlatform(
          types.ErrorCode.DeveloperError,
          types.IapPlatform.IOS,
        ),
        isTrue,
      );
    });
  });

  group('PurchaseError', () {
    test('fromPlatformError normalizes payload', () {
      final error = errors.PurchaseError.fromPlatformError(
        <String, dynamic>{
          'message': 'Something went wrong',
          'code': 'E_SERVICE_ERROR',
          'responseCode': 3,
          'debugMessage': 'debug',
          'productId': 'sku',
        },
        types.IapPlatform.Android,
      );

      expect(error.message, 'Something went wrong');
      expect(error.code, types.ErrorCode.ServiceError);
      expect(error.productId, 'sku');
      expect(error.platform, types.IapPlatform.Android);
    });

    test('getPlatformCode returns mapped value when possible', () {
      final error = errors.PurchaseError(
        message: 'Oops',
        code: types.ErrorCode.NotPrepared,
        platform: types.IapPlatform.Android,
      );

      expect(error.getPlatformCode(), 'E_NOT_PREPARED');
    });
  });

  group('Error messages', () {
    test('getUserFriendlyErrorMessage surfaces known codes', () {
      final message = errors.getUserFriendlyErrorMessage(
        errors.PurchaseError(
          message: 'ignored',
          code: types.ErrorCode.UserCancelled,
        ),
      );
      expect(message, contains('cancelled'));
    });

    test('getUserFriendlyErrorMessage falls back to provided message', () {
      final message = errors.getUserFriendlyErrorMessage(
        errors.PurchaseError(
          message: 'Custom message',
          code: types.ErrorCode.Unknown,
        ),
      );
      expect(message, 'Custom message');
    });

    test('getUserFriendlyErrorMessage handles Map payload', () {
      final message = errors.getUserFriendlyErrorMessage(<String, dynamic>{
        'code': 'developer-error',
        'message': 'Validation failed',
      });
      expect(message, 'Validation failed');
    });
  });

  group('Legacy models', () {
    test('PurchaseResult serialization is reversible', () {
      final result = errors.PurchaseResult(
        responseCode: 1,
        debugMessage: 'debug',
        code: 'E_UNKNOWN',
        message: 'message',
        purchaseTokenAndroid: 'token',
      );

      final json = result.toJson();
      final roundTrip = errors.PurchaseResult.fromJSON(json);
      expect(roundTrip.responseCode, 1);
      expect(roundTrip.purchaseTokenAndroid, 'token');
    });

    test('ConnectionResult serialization', () {
      final result = errors.ConnectionResult(msg: 'connected');
      final json = result.toJson();
      final parsed = errors.ConnectionResult.fromJSON(json);
      expect(parsed.msg, 'connected');
      expect(parsed.toString(), contains('connected'));
    });

    test(
        'message-based inference removed - returns Unknown for "User cancelled the operation"',
        () {
      final error = errors.PurchaseError.fromPlatformError(
        <String, dynamic>{
          'message': 'User cancelled the operation',
          'code': 'E_UNKNOWN', // Platform code is unknown
          'responseCode': 0,
        },
        types.IapPlatform.Android,
      );

      expect(error.message, 'User cancelled the operation');
      expect(error.code, types.ErrorCode.Unknown);
    });

    test(
        'message-based inference removed - returns Unknown for "Invalid arguments provided to the API"',
        () {
      final error = errors.PurchaseError.fromPlatformError(
        <String, dynamic>{
          'message': 'Invalid arguments provided to the API',
          'code': 'E_UNKNOWN', // Platform code is unknown
          'responseCode': 0,
        },
        types.IapPlatform.Android,
      );

      expect(error.message, 'Invalid arguments provided to the API');
      expect(error.code, types.ErrorCode.Unknown);
    });
  });
}
