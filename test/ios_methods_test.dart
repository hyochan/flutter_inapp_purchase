import 'package:flutter/services.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform/platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('iOS specific channel methods', () {
    late FlutterInappPurchase iap;
    late MethodChannel channel;
    final calls = <MethodCall>[];

    setUp(() {
      iap = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'ios'),
      );
      channel = iap.channel;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        channel,
        (MethodCall methodCall) async {
          calls.add(methodCall);
          switch (methodCall.method) {
            case 'initConnection':
              return true;
            case 'presentCodeRedemptionSheetIOS':
              return null;
            case 'showManageSubscriptionsIOS':
              return null;
            case 'getStorefrontIOS':
              return <String, dynamic>{'countryCode': 'US'};
            case 'validateReceiptIOS':
              return <String, dynamic>{
                'isValid': true,
                'jwsRepresentation': 'jws-token',
                'receiptData': 'receipt-data',
                'latestTransaction': <String, dynamic>{
                  '__typename': 'PurchaseIOS',
                  'id': 'txn-ios',
                  'productId': 'com.example.prod1',
                  'platform': 'IOS',
                  'store': 'apple',
                  'purchaseState': 'PURCHASED',
                  'quantity': 1,
                  'transactionDate': 1700000000000,
                  'transactionId': 'txn-ios',
                  'isAutoRenewing': false,
                },
              };
            case 'isEligibleForIntroOfferIOS':
              return true;
            case 'getSubscriptionStatus':
              return <Map<String, dynamic>>[
                <String, dynamic>{'state': 'active'},
              ];
            case 'getAvailableItems':
              return <Map<String, dynamic>>[
                <String, dynamic>{
                  'platform': 'ios',
                  'store': 'apple',
                  'productId': 'com.example.prod1',
                  'transactionId': 'txn-available',
                  'purchaseState': 'PURCHASED',
                  'transactionReceipt': 'receipt-data',
                  'transactionDate': 1700000000000,
                },
              ];
            case 'getAppTransaction':
              return <String, dynamic>{
                'appId': 1,
                'appTransactionId': 'txn-app',
                'appVersion': '1.0',
                'appVersionId': 1,
                'bundleId': 'com.example',
                'deviceVerification': 'verify',
                'deviceVerificationNonce': 'nonce',
                'environment': 'Sandbox',
                'originalAppVersion': '1.0',
                'originalPlatform': 'ios',
                'originalPurchaseDate': 1700000000000,
                'preorderDate': 1700000000000,
                'signedDate': 1700000000000,
              };
            case 'getPurchaseHistoriesIOS':
              return <Map<String, dynamic>>[
                <String, dynamic>{
                  'platform': 'ios',
                  'store': 'apple',
                  'productId': 'com.example.prod1',
                  'transactionId': 'txn-history',
                  'purchaseState': 'PURCHASED',
                  'transactionReceipt': 'history-receipt',
                  'transactionDate': 1700000000000,
                },
              ];
            case 'clearTransactionIOS':
              return null;
            case 'requestPurchaseOnPromotedProductIOS':
              return true;
            case 'getPromotedProductIOS':
              return <String, dynamic>{
                'currency': 'USD',
                'description': 'Desc',
                'displayNameIOS': 'Prod 1',
                'displayPrice': '\$0.99',
                'id': 'com.example.prod1',
                'isFamilyShareableIOS': false,
                'jsonRepresentationIOS': '{}',
                'platform': 'IOS',
                'price': 0.99,
                'subscriptionInfoIOS': null,
                'title': 'Prod 1',
                'type': 'IN_APP',
                'typeIOS': 'CONSUMABLE',
              };
            case 'getPendingTransactionsIOS':
              // Return a list of purchases (as native would)
              return <Map<String, dynamic>>[
                <String, dynamic>{
                  'id': '1000001',
                  'productId': 'com.example.prod1',
                  'transactionDate': DateTime.now().millisecondsSinceEpoch,
                  'transactionReceipt': 'xyz',
                  'purchaseToken': 'jwt-token',
                  'platform': 'ios',
                  'store': 'apple',
                },
              ];
            default:
              return null;
          }
        },
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
      calls.clear();
    });

    test('presentCodeRedemptionSheetIOS calls correct channel method',
        () async {
      await iap.presentCodeRedemptionSheetIOS();
      expect(calls.last.method, 'presentCodeRedemptionSheetIOS');
    });

    test('showManageSubscriptionsIOS calls correct channel method', () async {
      await iap.showManageSubscriptionsIOS();
      expect(calls.last.method, 'showManageSubscriptionsIOS');
    });

    test('getStorefrontIOS returns storefront country code', () async {
      final code = await iap.getStorefrontIOS();
      expect(code, 'US');
      expect(calls.last.method, 'getStorefrontIOS');
    });

    test('getPromotedProduct returns structured map', () async {
      final product = await iap.getPromotedProductIOS();
      expect(product, isA<ProductIOS>());
      expect(product!.id, 'com.example.prod1');
      expect(calls.last.method, 'getPromotedProductIOS');
    });

    test('getPendingTransactionsIOS returns purchases list', () async {
      final list = await iap.getPendingTransactionsIOS();
      expect(list, isA<List<PurchaseIOS>>());
      expect(list.length, 1);
      expect(list.first.productId, 'com.example.prod1');
      expect(calls.last.method, 'getPendingTransactionsIOS');
    });

    test('validateReceiptIOS returns structured result', () async {
      await iap.initConnection();

      final result = await iap.validateReceiptIOS(
        apple: const VerifyPurchaseAppleOptions(sku: 'com.example.prod1'),
      );

      expect(result.isValid, isTrue);
      expect(result.latestTransaction, isA<Purchase>());
      expect(calls.last.method, 'validateReceiptIOS');
    });

    test('validateReceiptIOS throws when connection not initialized', () async {
      await expectLater(
        iap.validateReceiptIOS(
          apple: const VerifyPurchaseAppleOptions(sku: 'com.example.prod1'),
        ),
        throwsA(
          isA<PurchaseError>().having(
            (error) => error.code,
            'code',
            ErrorCode.NotPrepared,
          ),
        ),
      );
    });

    test('validateReceiptIOS rejects empty SKU', () async {
      await iap.initConnection();

      await expectLater(
        iap.validateReceiptIOS(
          apple: const VerifyPurchaseAppleOptions(sku: '   '),
        ),
        throwsA(
          isA<PurchaseError>().having(
            (error) => error.code,
            'code',
            ErrorCode.DeveloperError,
          ),
        ),
      );
    });

    test('validateReceiptIOS wraps platform exceptions', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'initConnection') {
          return true;
        }
        if (methodCall.method == 'validateReceiptIOS') {
          throw PlatformException(code: '500', message: 'native error');
        }
        return null;
      });

      await iap.initConnection();

      await expectLater(
        iap.validateReceiptIOS(
          apple: const VerifyPurchaseAppleOptions(sku: 'com.example.prod1'),
        ),
        throwsA(
          isA<PurchaseError>().having(
            (error) => error.code,
            'code',
            ErrorCode.ServiceError,
          ),
        ),
      );
    });

    test('validateReceipt throws IapNotAvailable on Android', () async {
      final androidIap = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'android'),
      );

      await expectLater(
        androidIap.validateReceipt(
          apple: const VerifyPurchaseAppleOptions(sku: 'com.example.prod1'),
        ),
        throwsA(
          isA<PurchaseError>().having(
            (error) => error.code,
            'code',
            ErrorCode.IapNotAvailable,
          ),
        ),
      );
    });

    test('isEligibleForIntroOfferIOS returns platform result', () async {
      expect(await iap.isEligibleForIntroOfferIOS('group'), isTrue);
      expect(calls.last.method, 'isEligibleForIntroOfferIOS');
    });

    test('isEligibleForIntroOfferIOS returns false on non-iOS', () async {
      final androidIap = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'android'),
      );

      expect(await androidIap.isEligibleForIntroOfferIOS('group'), isFalse);
    });

    test('subscriptionStatusIOS parses list payload', () async {
      final statuses = await iap.subscriptionStatusIOS('sku');
      expect(statuses, hasLength(1));
      expect(statuses.first.state, 'active');
      expect(calls.last.method, 'getSubscriptionStatus');
    });

    test('subscriptionStatusIOS accepts string payload', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'getSubscriptionStatus') {
          return '[{"state":"expired"}]';
        }
        return null;
      });

      final statuses = await iap.subscriptionStatusIOS('sku');
      expect(statuses.single.state, 'expired');
    });

    test('getAppTransactionIOS returns typed transaction', () async {
      final transaction = await iap.getAppTransactionIOS();
      expect(transaction, isNotNull);
      expect(transaction!.bundleId, 'com.example');
      expect(calls.last.method, 'getAppTransaction');
    });

    test('getStorefrontIOS throws when country code missing', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'getStorefrontIOS') {
          return <String, dynamic>{};
        }
        return null;
      });

      await expectLater(
        iap.getStorefrontIOS(),
        throwsA(
          isA<PurchaseError>().having(
            (error) => error.code,
            'code',
            ErrorCode.ServiceError,
          ),
        ),
      );
    });

    test('presentCodeRedemptionSheetIOS throws on non-iOS', () async {
      final androidIap = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'android'),
      );

      await expectLater(
        androidIap.presentCodeRedemptionSheetIOS(),
        throwsA(isA<PlatformException>()),
      );
    });

    test('showManageSubscriptionsIOS throws on non-iOS', () async {
      final androidIap = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'android'),
      );

      await expectLater(
        androidIap.showManageSubscriptionsIOS(),
        throwsA(isA<PlatformException>()),
      );
    });

    test('getAppTransactionIOS returns null when native layer returns null',
        () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'getAppTransaction') {
          return null;
        }
        return null;
      });

      final transaction = await iap.getAppTransactionIOS();
      expect(transaction, isNull);
    });

    test('clearTransactionIOS returns true when native call succeeds',
        () async {
      expect(await iap.clearTransactionIOS(), isTrue);
      expect(calls.last.method, 'clearTransactionIOS');
    });

    test('clearTransactionIOS returns false on non-iOS', () async {
      final androidIap = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'android'),
      );

      expect(await androidIap.clearTransactionIOS(), isFalse);
    });

    test('clearTransactionIOS returns false when native throws', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'clearTransactionIOS') {
          throw PlatformException(code: '500', message: 'error');
        }
        return null;
      });

      expect(await iap.clearTransactionIOS(), isFalse);
    });

    test('requestPurchaseOnPromotedProductIOS returns true on iOS', () async {
      // ignore: deprecated_member_use_from_same_package
      expect(await iap.requestPurchaseOnPromotedProductIOS(), isTrue);
      expect(calls.last.method, 'requestPurchaseOnPromotedProductIOS');
    });

    test('requestPurchaseOnPromotedProductIOS returns false on non-iOS',
        () async {
      final androidIap = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'android'),
      );

      // ignore: deprecated_member_use_from_same_package
      expect(await androidIap.requestPurchaseOnPromotedProductIOS(), isFalse);
    });

    test('getPromotedProductIOS returns null when native sends string payload',
        () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'getPromotedProductIOS') {
          return '{}';
        }
        return null;
      });

      expect(await iap.getPromotedProductIOS(), isNull);
    });

    test('requestPurchaseOnPromotedProductIOS returns false when native throws',
        () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'requestPurchaseOnPromotedProductIOS') {
          throw PlatformException(code: '500', message: 'failure');
        }
        return null;
      });

      // ignore: deprecated_member_use_from_same_package
      expect(await iap.requestPurchaseOnPromotedProductIOS(), isFalse);
    });

    test('subscriptionStatusIOS returns empty list on error', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'getSubscriptionStatus') {
          throw PlatformException(code: '500', message: 'failure');
        }
        return null;
      });

      final statuses = await iap.subscriptionStatusIOS('sku');
      expect(statuses, isEmpty);
    });

    test('getPromotedProductIOS returns null when native throws', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'getPromotedProductIOS') {
          throw PlatformException(code: '500', message: 'error');
        }
        return null;
      });

      expect(await iap.getPromotedProductIOS(), isNull);
    });

    test('validateReceipt delegates to platform-specific implementation',
        () async {
      await iap.initConnection();

      final result = await iap.validateReceipt(
        apple: const VerifyPurchaseAppleOptions(sku: 'com.example.prod1'),
      );

      expect(result, isA<VerifyPurchaseResultIOS>());
    });
  });
}
