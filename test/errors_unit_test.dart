import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inapp_purchase/errors.dart' as errors;
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:flutter_inapp_purchase/types.dart' as types;
import 'package:flutter_test/flutter_test.dart';
import 'package:platform/platform.dart';

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
      final error = errors.PurchaseError.fromPlatformError(<String, dynamic>{
        'message': 'Something went wrong',
        'code': 'E_SERVICE_ERROR',
        'responseCode': 3,
        'debugMessage': 'debug',
        'productId': 'sku',
      }, types.IapPlatform.Android);

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
        final error = errors.PurchaseError.fromPlatformError(<String, dynamic>{
          'message': 'User cancelled the operation',
          'code': 'E_UNKNOWN', // Platform code is unknown
          'responseCode': 0,
        }, types.IapPlatform.Android);

        expect(error.message, 'User cancelled the operation');
        expect(error.code, types.ErrorCode.Unknown);
      },
    );

    test(
      'message-based inference removed - returns Unknown for "Invalid arguments provided to the API"',
      () {
        final error = errors.PurchaseError.fromPlatformError(<String, dynamic>{
          'message': 'Invalid arguments provided to the API',
          'code': 'E_UNKNOWN', // Platform code is unknown
          'responseCode': 0,
        }, types.IapPlatform.Android);

        expect(error.message, 'Invalid arguments provided to the API');
        expect(error.code, types.ErrorCode.Unknown);
      },
    );
  });

  group('PlatformException error code mapping', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    const channel = MethodChannel('flutter_inapp');

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
      debugDefaultTargetPlatformOverride = null;
    });

    test(
      'requestPurchase maps user-cancelled PlatformException to '
      'ErrorCode.UserCancelled',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          channel,
          (MethodCall call) async {
            if (call.method == 'requestPurchase') {
              throw PlatformException(
                code: 'user-cancelled',
                message: 'User cancelled the purchase flow',
              );
            }
            return null;
          },
        );

        final iap = FlutterInappPurchase.private(
          FakePlatform(operatingSystem: 'ios'),
        );
        await iap.initConnection();

        try {
          await iap.requestPurchase(
            const types.RequestPurchaseProps.inApp((
              apple: types.RequestPurchaseIosProps(sku: 'test_sku'),
              google: null,
              useAlternativeBilling: null,
            )),
          );
          fail('Expected PurchaseError');
        } on errors.PurchaseError catch (e) {
          expect(e.code, types.ErrorCode.UserCancelled);
          expect(e.message, contains('user-cancelled'));
        }
      },
    );

    test(
      'requestPurchase maps service-error PlatformException to '
      'ErrorCode.ServiceError',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          channel,
          (MethodCall call) async {
            if (call.method == 'requestPurchase') {
              throw PlatformException(
                code: 'service-error',
                message: 'Store service unavailable',
              );
            }
            return null;
          },
        );

        final iap = FlutterInappPurchase.private(
          FakePlatform(operatingSystem: 'ios'),
        );
        await iap.initConnection();

        try {
          await iap.requestPurchase(
            const types.RequestPurchaseProps.inApp((
              apple: types.RequestPurchaseIosProps(sku: 'test_sku'),
              google: null,
              useAlternativeBilling: null,
            )),
          );
          fail('Expected PurchaseError');
        } on errors.PurchaseError catch (e) {
          expect(e.code, types.ErrorCode.ServiceError);
        }
      },
    );

    test(
      'initConnection maps PlatformException error code properly',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          channel,
          (MethodCall call) async {
            if (call.method == 'initConnection') {
              throw PlatformException(
                code: 'E_SERVICE_ERROR',
                message: 'Billing service unavailable',
              );
            }
            return null;
          },
        );

        final iap = FlutterInappPurchase.private(
          FakePlatform(operatingSystem: 'android'),
        );

        try {
          await iap.initConnection();
          fail('Expected PurchaseError');
        } on errors.PurchaseError catch (e) {
          expect(e.code, types.ErrorCode.ServiceError);
          expect(e.message, contains('E_SERVICE_ERROR'));
        }
      },
    );

    test(
      'getAvailablePurchases maps PlatformException error code',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          channel,
          (MethodCall call) async {
            if (call.method == 'getAvailableItems') {
              throw PlatformException(
                code: 'E_NETWORK_ERROR',
                message: 'Network unavailable',
              );
            }
            return null;
          },
        );

        final iap = FlutterInappPurchase.private(
          FakePlatform(operatingSystem: 'android'),
        );
        await iap.initConnection();

        try {
          await iap.getAvailablePurchases();
          fail('Expected PurchaseError');
        } on errors.PurchaseError catch (e) {
          expect(e.code, types.ErrorCode.NetworkError);
        }
      },
    );

    test(
      'fetchProducts maps PlatformException error code',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          channel,
          (MethodCall call) async {
            if (call.method == 'fetchProducts') {
              throw PlatformException(
                code: 'item-unavailable',
                message: 'Products not found',
              );
            }
            return null;
          },
        );

        final iap = FlutterInappPurchase.private(
          FakePlatform(operatingSystem: 'ios'),
        );
        await iap.initConnection();

        try {
          await iap.fetchProducts<types.Product>(
            skus: ['test_sku'],
          );
          fail('Expected PurchaseError');
        } on errors.PurchaseError catch (e) {
          expect(e.code, types.ErrorCode.ItemUnavailable);
        }
      },
    );

    test(
      'endConnection maps PlatformException error code',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          channel,
          (MethodCall call) async {
            if (call.method == 'endConnection') {
              throw PlatformException(
                code: 'service-error',
                message: 'End failed',
              );
            }
            return null;
          },
        );

        final iap = FlutterInappPurchase.private(
          FakePlatform(operatingSystem: 'ios'),
        );
        await iap.initConnection();

        try {
          await iap.endConnection();
          fail('Expected PurchaseError');
        } on errors.PurchaseError catch (e) {
          expect(e.code, types.ErrorCode.ServiceError);
          expect(e.message, contains('service-error'));
        }
      },
    );

    test(
      'getStorefront maps PlatformException error code on Android',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          channel,
          (MethodCall call) async {
            if (call.method == 'getStorefront') {
              throw PlatformException(
                code: 'E_SERVICE_ERROR',
                message: 'Storefront unavailable',
              );
            }
            return null;
          },
        );

        final iap = FlutterInappPurchase.private(
          FakePlatform(operatingSystem: 'android'),
        );

        try {
          await iap.getStorefront();
          fail('Expected PurchaseError');
        } on errors.PurchaseError catch (e) {
          expect(e.code, types.ErrorCode.ServiceError);
        }
      },
    );

    test(
      'getStorefrontIOS maps PlatformException error code',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          channel,
          (MethodCall call) async {
            if (call.method == 'getStorefrontIOS') {
              throw PlatformException(
                code: 'network-error',
                message: 'Network issue',
              );
            }
            return null;
          },
        );

        final iap = FlutterInappPurchase.private(
          FakePlatform(operatingSystem: 'ios'),
        );

        try {
          await iap.getStorefrontIOS();
          fail('Expected PurchaseError');
        } on errors.PurchaseError catch (e) {
          expect(e.code, types.ErrorCode.NetworkError);
        }
      },
    );

    test(
      'presentCodeRedemptionSheetIOS maps PlatformException',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          channel,
          (MethodCall call) async {
            if (call.method == 'presentCodeRedemptionSheetIOS') {
              throw PlatformException(
                code: 'service-error',
                message: 'Sheet failed',
              );
            }
            return null;
          },
        );

        final iap = FlutterInappPurchase.private(
          FakePlatform(operatingSystem: 'ios'),
        );

        try {
          await iap.presentCodeRedemptionSheetIOS();
          fail('Expected PurchaseError');
        } on errors.PurchaseError catch (e) {
          expect(e.code, types.ErrorCode.ServiceError);
        }
      },
    );

    test(
      'showManageSubscriptionsIOS maps PlatformException',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          channel,
          (MethodCall call) async {
            if (call.method == 'showManageSubscriptionsIOS') {
              throw PlatformException(
                code: 'service-error',
                message: 'Manage subs failed',
              );
            }
            return null;
          },
        );

        final iap = FlutterInappPurchase.private(
          FakePlatform(operatingSystem: 'ios'),
        );

        try {
          await iap.showManageSubscriptionsIOS();
          fail('Expected PurchaseError');
        } on errors.PurchaseError catch (e) {
          expect(e.code, types.ErrorCode.ServiceError);
        }
      },
    );

    test(
      'getActiveSubscriptions maps PlatformException error code',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          channel,
          (MethodCall call) async {
            if (call.method == 'getActiveSubscriptions') {
              throw PlatformException(
                code: 'network-error',
                message: 'Network issue',
              );
            }
            return null;
          },
        );

        final iap = FlutterInappPurchase.private(
          FakePlatform(operatingSystem: 'ios'),
        );
        await iap.initConnection();

        try {
          await iap.getActiveSubscriptions();
          fail('Expected PurchaseError');
        } on errors.PurchaseError catch (e) {
          expect(e.code, types.ErrorCode.NetworkError);
        }
      },
    );

    test(
      'isEligibleForExternalPurchaseCustomLinkIOS maps '
      'PlatformException',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          channel,
          (MethodCall call) async {
            if (call.method == 'isEligibleForExternalPurchaseCustomLinkIOS') {
              throw PlatformException(
                code: 'service-error',
                message: 'Eligibility check failed',
              );
            }
            return null;
          },
        );

        final iap = FlutterInappPurchase.private(
          FakePlatform(operatingSystem: 'ios'),
        );

        try {
          await iap.isEligibleForExternalPurchaseCustomLinkIOS();
          fail('Expected PurchaseError');
        } on errors.PurchaseError catch (e) {
          expect(e.code, types.ErrorCode.ServiceError);
        }
      },
    );

    test(
      'PurchaseError includes platform field from mapping',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          channel,
          (MethodCall call) async {
            if (call.method == 'requestPurchase') {
              throw PlatformException(
                code: 'user-cancelled',
                message: 'Cancelled',
              );
            }
            return null;
          },
        );

        final iap = FlutterInappPurchase.private(
          FakePlatform(operatingSystem: 'ios'),
        );
        await iap.initConnection();

        try {
          await iap.requestPurchase(
            const types.RequestPurchaseProps.inApp((
              apple: types.RequestPurchaseIosProps(
                sku: 'test_sku',
              ),
              google: null,
              useAlternativeBilling: null,
            )),
          );
          fail('Expected PurchaseError');
        } on errors.PurchaseError catch (e) {
          expect(e.code, types.ErrorCode.UserCancelled);
          expect(e.platform, types.IapPlatform.IOS);
        }
      },
    );
  });
}
