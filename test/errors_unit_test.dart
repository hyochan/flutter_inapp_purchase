import 'package:flutter_inapp_purchase/errors.dart';
import 'package:flutter_inapp_purchase/types.dart' as types;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ErrorCodeUtils', () {
    test('fromPlatformCode maps Android string codes', () {
      final code = ErrorCodeUtils.fromPlatformCode(
        'E_ALREADY_OWNED',
        types.IapPlatform.Android,
      );
      expect(code, types.ErrorCode.AlreadyOwned);
    });

    test('fromPlatformCode maps iOS numeric codes', () {
      final iosCode = ErrorCodeUtils.fromPlatformCode(
        4,
        types.IapPlatform.IOS,
      );
      expect(iosCode, types.ErrorCode.ServiceError);
    });

    test('toPlatformCode provides platform specific mapping', () {
      final iosValue = ErrorCodeUtils.toPlatformCode(
        types.ErrorCode.NetworkError,
        types.IapPlatform.IOS,
      );
      expect(iosValue, isA<int>());

      final androidValue = ErrorCodeUtils.toPlatformCode(
        types.ErrorCode.NetworkError,
        types.IapPlatform.Android,
      );
      expect(androidValue, 'E_NETWORK_ERROR');
    });

    test('isValidForPlatform validates error codes', () {
      expect(
        ErrorCodeUtils.isValidForPlatform(
          types.ErrorCode.DeveloperError,
          types.IapPlatform.Android,
        ),
        isTrue,
      );
      expect(
        ErrorCodeUtils.isValidForPlatform(
          types.ErrorCode.DeveloperError,
          types.IapPlatform.IOS,
        ),
        isTrue,
      );
    });
  });

  group('PurchaseError', () {
    test('fromPlatformError normalizes payload', () {
      final error = PurchaseError.fromPlatformError(
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
      final error = PurchaseError(
        message: 'Oops',
        code: types.ErrorCode.NotPrepared,
        platform: types.IapPlatform.Android,
      );

      expect(error.getPlatformCode(), 'E_NOT_PREPARED');
    });
  });

  group('Error messages', () {
    test('getUserFriendlyErrorMessage surfaces known codes', () {
      final message = getUserFriendlyErrorMessage(
        PurchaseError(
          message: 'ignored',
          code: types.ErrorCode.UserCancelled,
        ),
      );
      expect(message, contains('cancelled'));
    });

    test('getUserFriendlyErrorMessage falls back to provided message', () {
      final message = getUserFriendlyErrorMessage(
        PurchaseError(
          message: 'Custom message',
          code: types.ErrorCode.Unknown,
        ),
      );
      expect(message, 'Custom message');
    });

    test('getUserFriendlyErrorMessage handles Map payload', () {
      final message = getUserFriendlyErrorMessage(<String, dynamic>{
        'code': 'E_DEVELOPER_ERROR',
        'message': 'Validation failed',
      });
      expect(message, 'Validation failed');
    });
  });

  group('Legacy models', () {
    test('PurchaseResult serialization is reversible', () {
      final result = PurchaseResult(
        responseCode: 1,
        debugMessage: 'debug',
        code: 'E_UNKNOWN',
        message: 'message',
        purchaseTokenAndroid: 'token',
      );

      final json = result.toJson();
      final roundTrip = PurchaseResult.fromJSON(json);
      expect(roundTrip.responseCode, 1);
      expect(roundTrip.purchaseTokenAndroid, 'token');
    });

    test('ConnectionResult serialization', () {
      final result = ConnectionResult(msg: 'connected');
      final json = result.toJson();
      final parsed = ConnectionResult.fromJSON(json);
      expect(parsed.msg, 'connected');
      expect(parsed.toString(), contains('connected'));
    });
  });
}
