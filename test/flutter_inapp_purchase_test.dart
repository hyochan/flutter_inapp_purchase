import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:flutter_inapp_purchase/enums.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform/platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final MethodChannel channel = FlutterInappPurchase.channel;

  group('FlutterInappPurchase', () {
    group('Platform Detection', () {
      test('getCurrentPlatform returns correct platform for iOS', () {
        FlutterInappPurchase(FlutterInappPurchase.private(
            FakePlatform(operatingSystem: "ios")));
        expect(getCurrentPlatform(), IAPPlatform.ios);
      });

      test('getCurrentPlatform returns correct platform for Android', () {
        FlutterInappPurchase(FlutterInappPurchase.private(
            FakePlatform(operatingSystem: "android")));
        expect(getCurrentPlatform(), IAPPlatform.android);
      });
    });

    group('showInAppMessageAndroid', () {
      group('for Android', () {
        final List<MethodCall> log = <MethodCall>[];
        setUp(() {
          FlutterInappPurchase(FlutterInappPurchase.private(
              FakePlatform(operatingSystem: "android")));

          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
            log.add(methodCall);
            return "ready";
          });
        });
        test('invokes correct method', () async {
          await FlutterInappPurchase.instance.showInAppMessageAndroid();
          expect(log, <Matcher>[
            isMethodCall('showInAppMessages', arguments: null),
          ]);
        });

        tearDown(() {
          FlutterInappPurchase.channel.setMethodCallHandler(null);
        });

        test('returns correct result', () async {
          final result =
              await FlutterInappPurchase.instance.showInAppMessageAndroid();
          expect(result, "ready");
        });
      });
    });

    group('consumeAll', () {
      group('for Android', () {
        final List<MethodCall> log = <MethodCall>[];
        setUp(() {
          FlutterInappPurchase(FlutterInappPurchase.private(
              FakePlatform(operatingSystem: "android")));

          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
            log.add(methodCall);
            return "All items have been consumed";
          });
        });

        tearDown(() {
          FlutterInappPurchase.channel.setMethodCallHandler(null);
        });

        test('invokes correct method', () async {
          await FlutterInappPurchase.instance.consumeAll();
          expect(log, <Matcher>[
            isMethodCall('consumeAllItems', arguments: null),
          ]);
        });

        test('returns correct result', () async {
          expect(await FlutterInappPurchase.instance.consumeAll(),
              "All items have been consumed");
        });
      });

      group('for iOS', () {
        setUp(() {
          FlutterInappPurchase(FlutterInappPurchase.private(
              FakePlatform(operatingSystem: "ios")));
        });

        tearDown(() {
          FlutterInappPurchase.channel.setMethodCallHandler(null);
        });

        test('returns correct result', () async {
          expect(await FlutterInappPurchase.instance.consumeAll(),
              "no-ops in ios");
        });
      });
    });

    group('initConnection', () {
      group('for Android', () {
        final List<MethodCall> log = <MethodCall>[];
        setUp(() {
          FlutterInappPurchase(FlutterInappPurchase.private(
              FakePlatform(operatingSystem: "android")));

          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
            log.add(methodCall);
            return "Billing service is ready";
          });
        });

        tearDown(() {
          FlutterInappPurchase.channel.setMethodCallHandler(null);
        });

        test('invokes correct method', () async {
          await FlutterInappPurchase.instance.initialize();
          expect(log, <Matcher>[
            isMethodCall('initConnection', arguments: null),
          ]);
        });

        test('returns correct result', () async {
          expect(await FlutterInappPurchase.instance.initialize(),
              "Billing service is ready");
        });
      });
    });

    group('getProducts', () {
      group('for Android', () {
        final List<MethodCall> log = <MethodCall>[];
        setUp(() {
          FlutterInappPurchase(FlutterInappPurchase.private(
              FakePlatform(operatingSystem: "android")));

          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
            log.add(methodCall);
            return json.encode([
              {
                'productId': 'com.example.product1',
                'price': '0.99',
                'currency': 'USD',
                'localizedPrice': r'$0.99',
                'title': 'Product 1',
                'description': 'Description 1',
              },
              {
                'productId': 'com.example.product2',
                'price': '1.99',
                'currency': 'USD',
                'localizedPrice': r'$1.99',
                'title': 'Product 2',
                'description': 'Description 2',
              },
            ]);
          });
        });

        tearDown(() {
          FlutterInappPurchase.channel.setMethodCallHandler(null);
        });

        test('invokes correct method', () async {
          await FlutterInappPurchase.instance.getProducts(['com.example.product1', 'com.example.product2']);
          expect(log, <Matcher>[
            isMethodCall('getItemsByType', arguments: <String, dynamic>{
              'type': 'inapp',
              'skus': ['com.example.product1', 'com.example.product2'],
            }),
          ]);
        });

        test('returns correct products', () async {
          final products = await FlutterInappPurchase.instance.getProducts(['com.example.product1', 'com.example.product2']);
          expect(products?.length, 2);
          expect(products?[0].productId, 'com.example.product1');
          expect(products?[0].price, '0.99');
          expect(products?[0].currency, 'USD');
          expect(products?[1].productId, 'com.example.product2');
        });
      });
    });

    group('getSubscriptions', () {
      group('for iOS', () {
        final List<MethodCall> log = <MethodCall>[];
        setUp(() {
          FlutterInappPurchase(FlutterInappPurchase.private(
              FakePlatform(operatingSystem: "ios")));

          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
            log.add(methodCall);
            return json.encode([
              {
                'productId': 'com.example.subscription1',
                'price': '9.99',
                'currency': 'USD',
                'localizedPrice': r'$9.99',
                'title': 'Subscription 1',
                'description': 'Monthly subscription',
                'subscriptionPeriodUnitIOS': 'MONTH',
                'subscriptionPeriodNumberIOS': '1',
              },
            ]);
          });
        });

        tearDown(() {
          FlutterInappPurchase.channel.setMethodCallHandler(null);
        });

        test('invokes correct method', () async {
          await FlutterInappPurchase.instance.getSubscriptions(['com.example.subscription1']);
          expect(log, <Matcher>[
            isMethodCall('getItemsByType', arguments: <String, dynamic>{
              'type': 'subs',
              'skus': ['com.example.subscription1'],
            }),
          ]);
        });

        test('returns correct subscriptions', () async {
          final subscriptions = await FlutterInappPurchase.instance.getSubscriptions(['com.example.subscription1']);
          expect(subscriptions?.length, 1);
          expect(subscriptions?[0].productId, 'com.example.subscription1');
          expect(subscriptions?[0].subscriptionPeriodUnitIOS, 'MONTH');
        });
      });
    });

    group('Error Handling', () {
      test('PurchaseError creation from platform error', () {
        final error = PurchaseError.fromPlatformError(
          {
            'code': 'E_USER_CANCELLED',
            'message': 'User cancelled the purchase',
            'responseCode': 1,
            'debugMessage': 'Debug info',
            'productId': 'com.example.product',
          },
          IAPPlatform.android,
        );

        expect(error.code, ErrorCode.E_USER_CANCELLED);
        expect(error.message, 'User cancelled the purchase');
        expect(error.responseCode, 1);
        expect(error.debugMessage, 'Debug info');
        expect(error.productId, 'com.example.product');
        expect(error.platform, IAPPlatform.android);
      });

      test('ErrorCodeUtils maps platform codes correctly', () {
        // Test iOS mapping
        expect(ErrorCodeUtils.fromPlatformCode(2, IAPPlatform.ios), ErrorCode.E_USER_CANCELLED);
        expect(ErrorCodeUtils.toPlatformCode(ErrorCode.E_USER_CANCELLED, IAPPlatform.ios), 2);

        // Test Android mapping
        expect(ErrorCodeUtils.fromPlatformCode('E_USER_CANCELLED', IAPPlatform.android), ErrorCode.E_USER_CANCELLED);
        expect(ErrorCodeUtils.toPlatformCode(ErrorCode.E_USER_CANCELLED, IAPPlatform.android), 'E_USER_CANCELLED');

        // Test unknown code
        expect(ErrorCodeUtils.fromPlatformCode('UNKNOWN_ERROR', IAPPlatform.android), ErrorCode.E_UNKNOWN);
      });
    });

    group('Type Conversions', () {
      test('IAPItem conversion preserves all fields', () {
        final jsonData = {
          'productId': 'test.product',
          'price': '1.99',
          'currency': 'USD',
          'localizedPrice': r'$1.99',
          'title': 'Test Product',
          'description': 'Test Description',
          'type': 'inapp',
          'iconUrl': 'https://example.com/icon.png',
          'originalJson': '{}',
          'originalPrice': '1.99',
          'discounts': <dynamic>[],
        };

        final item = IAPItem.fromJSON(jsonData);
        expect(item.productId, 'test.product');
        expect(item.price, '1.99');
        expect(item.currency, 'USD');
        expect(item.localizedPrice, r'$1.99');
        expect(item.title, 'Test Product');
        expect(item.description, 'Test Description');
        // type field was removed in refactoring
        expect(item.iconUrl, 'https://example.com/icon.png');
      });

      test('PurchasedItem conversion handles all fields', () {
        final jsonData = {
          'productId': 'test.product',
          'transactionId': 'trans123',
          'transactionDate': 1234567890,
          'transactionReceipt': 'receipt_data',
          'purchaseToken': 'token123',
          'orderId': 'order123',
          'dataAndroid': 'android_data',
          'signatureAndroid': 'signature',
          'isAcknowledgedAndroid': true,
          'purchaseStateAndroid': 1,
          'originalTransactionDateIOS': 1234567890,
          'originalTransactionIdentifierIOS': 'orig_trans123',
        };

        final item = PurchasedItem.fromJSON(jsonData);
        expect(item.productId, 'test.product');
        expect(item.transactionId, 'trans123');
        expect(item.transactionDate, 1234567890);
        expect(item.transactionReceipt, 'receipt_data');
        expect(item.purchaseToken, 'token123');
        // orderId field was removed in refactoring
        expect(item.isAcknowledgedAndroid, true);
      });
    });

    group('Enum Values', () {
      test('Store enum has correct values', () {
        expect(Store.values.length, 4);
        expect(Store.none.toString(), 'Store.none');
        expect(Store.playStore.toString(), 'Store.playStore');
        expect(Store.amazon.toString(), 'Store.amazon');
        expect(Store.appStore.toString(), 'Store.appStore');
      });

      test('PurchaseType enum has correct values', () {
        expect(PurchaseType.values.length, 2);
        expect(PurchaseType.inapp.toString(), 'PurchaseType.inapp');
        expect(PurchaseType.subs.toString(), 'PurchaseType.subs');
      });

      test('SubscriptionState enum has correct values', () {
        expect(SubscriptionState.values.length, 5);
        expect(SubscriptionState.active.toString(), 'SubscriptionState.active');
        expect(SubscriptionState.expired.toString(), 'SubscriptionState.expired');
        expect(SubscriptionState.inBillingRetry.toString(), 'SubscriptionState.inBillingRetry');
        expect(SubscriptionState.inGracePeriod.toString(), 'SubscriptionState.inGracePeriod');
        expect(SubscriptionState.revoked.toString(), 'SubscriptionState.revoked');
      });

      test('ProrationMode enum has correct values', () {
        expect(ProrationMode.values.length, 5);
        expect(ProrationMode.immediateWithTimeProration.toString(), 'ProrationMode.immediateWithTimeProration');
        expect(ProrationMode.immediateAndChargeProratedPrice.toString(), 'ProrationMode.immediateAndChargeProratedPrice');
        expect(ProrationMode.immediateWithoutProration.toString(), 'ProrationMode.immediateWithoutProration');
        expect(ProrationMode.deferred.toString(), 'ProrationMode.deferred');
        expect(ProrationMode.immediateAndChargeFullPrice.toString(), 'ProrationMode.immediateAndChargeFullPrice');
      });
    });
  });
}