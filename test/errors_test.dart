import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_inapp_purchase/types.dart';

void main() {
  group('Errors', () {
    group('PurchaseError', () {
      test('should create with all fields', () {
        final error = PurchaseError(
          name: 'CustomError',
          message: 'User cancelled',
          code: ErrorCode.UserCancelled,
          platform: IapPlatform.android,
          responseCode: 6,
          debugMessage: 'Debug info',
          productId: 'product_123',
        );

        expect(error.name, 'CustomError');
        expect(error.code, ErrorCode.UserCancelled);
        expect(error.message, 'User cancelled');
        expect(error.platform, IapPlatform.android);
        expect(error.responseCode, 6);
        expect(error.debugMessage, 'Debug info');
        expect(error.productId, 'product_123');
      });

      test('should create with minimal fields', () {
        final error = PurchaseError(
          message: 'Network failed',
          code: ErrorCode.NetworkError,
          platform: IapPlatform.ios,
        );

        expect(error.name, '[flutter_inapp_purchase]: PurchaseError');
        expect(error.code, ErrorCode.NetworkError);
        expect(error.message, 'Network failed');
        expect(error.platform, IapPlatform.ios);
        expect(error.responseCode, isNull);
        expect(error.debugMessage, isNull);
        expect(error.productId, isNull);
      });

      test('toString should return formatted string', () {
        final error = PurchaseError(
          message: 'Item not found',
          code: ErrorCode.ItemUnavailable,
          platform: IapPlatform.android,
          responseCode: 4,
        );

        final result = error.toString();
        expect(result, contains('Item not found'));
        expect(result, isA<String>());
      });

      test('should create from platform error', () {
        final errorData = {
          'code': 'E_USER_CANCELLED',
          'message': 'User cancelled the purchase',
          'responseCode': 6,
        };

        final error = PurchaseError.fromPlatformError(
          errorData,
          IapPlatform.android,
        );

        expect(error.code, ErrorCode.UserCancelled);
        expect(error.message, 'User cancelled the purchase');
        expect(error.platform, IapPlatform.android);
      });
    });

    group('PurchaseResult', () {
      test('should create with all parameters', () {
        final result = PurchaseResult(
          responseCode: 0,
          debugMessage: 'Success',
          code: 'OK',
          message: 'Purchase completed',
          purchaseTokenAndroid: 'token_123',
        );

        expect(result.responseCode, 0);
        expect(result.debugMessage, 'Success');
        expect(result.code, 'OK');
        expect(result.message, 'Purchase completed');
        expect(result.purchaseTokenAndroid, 'token_123');
      });

      test('should create from JSON', () {
        final json = {
          'responseCode': 5,
          'debugMessage': 'Error occurred',
          'code': 'ERR_001',
          'message': 'Purchase failed',
          'purchaseTokenAndroid': 'failed_token',
        };

        final result = PurchaseResult.fromJSON(json);
        expect(result.responseCode, 5);
        expect(result.debugMessage, 'Error occurred');
        expect(result.code, 'ERR_001');
        expect(result.message, 'Purchase failed');
        expect(result.purchaseTokenAndroid, 'failed_token');
      });

      test('should convert to JSON', () {
        final result = PurchaseResult(
          responseCode: 1,
          debugMessage: 'Billing unavailable',
          code: 'BILLING_UNAVAILABLE',
          message: 'Billing is not available',
          purchaseTokenAndroid: null,
        );

        final json = result.toJson();
        expect(json['responseCode'], 1);
        expect(json['debugMessage'], 'Billing unavailable');
        expect(json['code'], 'BILLING_UNAVAILABLE');
        expect(json['message'], 'Billing is not available');
        expect(json['purchaseTokenAndroid'], '');
      });

      test('toString should return formatted string', () {
        final result = PurchaseResult(
          responseCode: 7,
          debugMessage: 'Item already owned',
          code: 'ITEM_ALREADY_OWNED',
          message: 'User already owns this item',
        );

        final stringResult = result.toString();
        expect(stringResult, contains('responseCode: 7'));
        expect(stringResult, contains('debugMessage: Item already owned'));
        expect(stringResult, contains('code: ITEM_ALREADY_OWNED'));
        expect(stringResult, contains('message: User already owns this item'));
      });
    });

    group('ConnectionResult', () {
      test('should create with message', () {
        final result = ConnectionResult(msg: 'Connected successfully');
        expect(result.msg, 'Connected successfully');
      });

      test('should create from JSON', () {
        final json = {'msg': 'Connection established'};
        final result = ConnectionResult.fromJSON(json);
        expect(result.msg, 'Connection established');
      });

      test('should convert to JSON', () {
        final result = ConnectionResult(msg: 'Ready to purchase');
        final json = result.toJson();
        expect(json['msg'], 'Ready to purchase');
      });

      test('should handle null message in toJson', () {
        final result = ConnectionResult();
        final json = result.toJson();
        expect(json['msg'], '');
      });

      test('toString should return formatted string', () {
        final result = ConnectionResult(msg: 'Service connected');
        expect(result.toString(), 'msg: Service connected');
      });
    });

    group('ErrorCode enum', () {
      test('should contain all expected error codes', () {
        expect(ErrorCode.Unknown, isA<ErrorCode>());
        expect(ErrorCode.UserCancelled, isA<ErrorCode>());
        expect(ErrorCode.UserError, isA<ErrorCode>());
        expect(ErrorCode.ItemUnavailable, isA<ErrorCode>());
        expect(ErrorCode.ProductNotAvailable, isA<ErrorCode>());
        expect(ErrorCode.ProductAlreadyOwned, isA<ErrorCode>());
        expect(ErrorCode.ReceiptFinished, isA<ErrorCode>());
        expect(ErrorCode.AlreadyOwned, isA<ErrorCode>());
        expect(ErrorCode.NetworkError, isA<ErrorCode>());
      });
    });
  });
}
