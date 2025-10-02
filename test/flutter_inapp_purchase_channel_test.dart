import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:flutter_inapp_purchase/types.dart' as types;
import 'package:platform/platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('flutter_inapp');
  const codec = StandardMethodCodec();

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('requestPurchase', () {
    test('throws when connection not initialized', () async {
      final iap = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'ios'),
      );

      await expectLater(
        iap.requestPurchase(
          const types.RequestPurchaseProps.inApp((
            ios: types.RequestPurchaseIosProps(sku: 'demo.sku'),
            android: null,
            useAlternativeBilling: null,
          )),
        ),
        throwsA(
          isA<PurchaseError>().having(
            (error) => error.code,
            'code',
            types.ErrorCode.NotPrepared,
          ),
        ),
      );
    });

    test('sends expected payload for iOS purchases', () async {
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        calls.add(call);
        switch (call.method) {
          case 'initConnection':
            return true;
          case 'requestPurchase':
            return null;
        }
        return null;
      });

      final iap = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'ios'),
      );

      await iap.initConnection();

      const props = types.RequestPurchaseProps.inApp((
        ios: types.RequestPurchaseIosProps(
          sku: 'ios.sku',
          appAccountToken: 'app-token',
          quantity: 3,
          andDangerouslyFinishTransactionAutomatically: null,
          withOffer: types.DiscountOfferInputIOS(
            identifier: 'offer-id',
            keyIdentifier: 'key-id',
            nonce: 'nonce',
            signature: 'signature',
            timestamp: 123456.0,
          ),
        ),
        android: null,
        useAlternativeBilling: null,
      ));

      await iap.requestPurchase(props);

      final requestCall =
          calls.singleWhere((MethodCall c) => c.method == 'requestPurchase');
      final payload = Map<String, dynamic>.from(
          requestCall.arguments as Map<dynamic, dynamic>);

      expect(payload['sku'], 'ios.sku');
      expect(payload['type'], 'inapp');
      expect(payload['appAccountToken'], 'app-token');
      expect(payload['quantity'], 3);
      expect(
        payload['andDangerouslyFinishTransactionAutomatically'],
        isFalse,
      );
      final offer = Map<String, dynamic>.from(
          payload['withOffer'] as Map<dynamic, dynamic>);
      expect(offer['identifier'], 'offer-id');
      expect(offer['keyIdentifier'], 'key-id');
      expect(offer['nonce'], 'nonce');
      expect(offer['signature'], 'signature');
      expect(offer['timestamp'], 123456.0);
    });

    test('initConnection memoizes after first call', () async {
      int initCount = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        if (call.method == 'initConnection') {
          initCount += 1;
          return true;
        }
        return null;
      });

      final iap = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'ios'),
      );

      expect(await iap.initConnection(), isTrue);
      expect(await iap.initConnection(), isTrue);
      expect(initCount, 1);
    });

    test('endConnection forwards to native channel when initialized', () async {
      int endCount = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        switch (call.method) {
          case 'initConnection':
            return true;
          case 'endConnection':
            endCount += 1;
            return true;
        }
        return null;
      });

      final iap = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'ios'),
      );

      expect(await iap.initConnection(), isTrue);
      expect(await iap.endConnection(), isTrue);
      expect(endCount, 1);
    });

    test('endConnection returns false when not initialized', () async {
      bool endCalled = false;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        if (call.method == 'endConnection') {
          endCalled = true;
        }
        return null;
      });

      final iap = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'ios'),
      );

      expect(await iap.endConnection(), isFalse);
      expect(endCalled, isFalse);
    });

    test('initConnection wraps platform exception with PurchaseError',
        () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        if (call.method == 'initConnection') {
          throw PlatformException(code: 'platform', message: 'boom');
        }
        return null;
      });

      final iap = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'ios'),
      );

      await expectLater(
        iap.initConnection(),
        throwsA(
          isA<PurchaseError>().having(
            (error) => error.code,
            'code',
            types.ErrorCode.NotPrepared,
          ),
        ),
      );
    });

    test('endConnection throws PurchaseError when native layer fails',
        () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        if (call.method == 'initConnection') {
          return true;
        }
        if (call.method == 'endConnection') {
          throw PlatformException(code: 'platform', message: 'end failed');
        }
        return null;
      });

      final iap = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'ios'),
      );

      expect(await iap.initConnection(), isTrue);
      await expectLater(
        iap.endConnection(),
        throwsA(
          isA<PurchaseError>().having(
            (error) => error.code,
            'code',
            types.ErrorCode.ServiceError,
          ),
        ),
      );
    });

    // Note: Android subscription proration (purchaseTokenAndroid, replacementModeAndroid)
    // is not supported in RequestPurchaseAndroidProps. These fields only exist in
    // RequestSubscriptionAndroidProps which is used in specialized subscription APIs.
    test('sends subscription request without proration fields', () async {
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        calls.add(call);
        if (call.method == 'initConnection') {
          return true;
        }
        if (call.method == 'requestPurchase') {
          return null;
        }
        return null;
      });

      final iap = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'android'),
      );

      await iap.initConnection();

      const props = types.RequestPurchaseProps.subs((
        ios: null,
        android: types.RequestSubscriptionAndroidProps(
          skus: <String>['sub.premium'],
        ),
        useAlternativeBilling: null,
      ));

      await iap.requestPurchase(props);

      final requestCall =
          calls.singleWhere((MethodCall c) => c.method == 'requestPurchase');
      final payload = Map<String, dynamic>.from(
          requestCall.arguments as Map<dynamic, dynamic>);

      expect(payload['type'], 'subs');
      expect(payload['productId'], 'sub.premium');
      expect(payload['skus'], <String>['sub.premium']);
      // Proration fields should not be present
      expect(payload.containsKey('purchaseToken'), isFalse);
      expect(payload.containsKey('replacementMode'), isFalse);
    });

    test('sends expected payload for Android subscriptions', () async {
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        calls.add(call);
        switch (call.method) {
          case 'initConnection':
            return true;
          case 'requestPurchase':
            return null;
        }
        return null;
      });

      final iap = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'android'),
      );

      await iap.initConnection();

      const props = types.RequestPurchaseProps.subs((
        ios: null,
        android: types.RequestSubscriptionAndroidProps(
          skus: <String>['sub.premium'],
          isOfferPersonalized: true,
          obfuscatedAccountIdAndroid: 'acc-id',
          obfuscatedProfileIdAndroid: 'profile-id',
        ),
        useAlternativeBilling: null,
      ));

      await iap.requestPurchase(props);

      final requestCall =
          calls.singleWhere((MethodCall c) => c.method == 'requestPurchase');
      final payload = Map<String, dynamic>.from(
          requestCall.arguments as Map<dynamic, dynamic>);

      expect(payload['type'], 'subs');
      expect(payload['productId'], 'sub.premium');
      expect(payload['skus'], <String>['sub.premium']);
      expect(payload['isOfferPersonalized'], isTrue);
      expect(payload['obfuscatedAccountId'], 'acc-id');
      expect(payload['obfuscatedAccountIdAndroid'], 'acc-id');
      expect(payload['obfuscatedProfileId'], 'profile-id');
      expect(payload['obfuscatedProfileIdAndroid'], 'profile-id');
      // Note: purchaseToken, replacementMode, and subscriptionOffers
      // are not in RequestPurchaseAndroidProps
      // They only exist in RequestSubscriptionAndroidProps
      expect(payload.containsKey('purchaseToken'), isFalse);
      expect(payload.containsKey('replacementMode'), isFalse);
      expect(payload.containsKey('subscriptionOffers'), isFalse);
    });
  });

  group('requestPurchase validation', () {
    test('throws developer error when iOS props missing', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        if (call.method == 'initConnection') {
          return true;
        }
        if (call.method == 'requestPurchase') {
          fail('requestPurchase should not be invoked when payload is invalid');
        }
        return null;
      });

      final iap = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'ios'),
      );

      await iap.initConnection();

      await expectLater(
        () => iap.requestPurchase(
          const types.RequestPurchaseProps.inApp((
            ios: null,
            android: types.RequestPurchaseAndroidProps(
              skus: <String>['android-only'],
            ),
            useAlternativeBilling: null,
          )),
        ),
        throwsA(
          isA<PurchaseError>().having(
            (error) => error.code,
            'code',
            types.ErrorCode.DeveloperError,
          ),
        ),
      );
    });

    test('throws when platform is not supported', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        if (call.method == 'initConnection') {
          return true;
        }
        if (call.method == 'requestPurchase') {
          fail(
              'requestPurchase should not reach native layer on unsupported platforms');
        }
        return null;
      });

      final iap = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'linux'),
      );

      await iap.initConnection();

      await expectLater(
        () => iap.requestPurchase(
          const types.RequestPurchaseProps.inApp((
            ios: types.RequestPurchaseIosProps(sku: 'ignored'),
            android: null,
            useAlternativeBilling: null,
          )),
        ),
        throwsA(
          isA<PurchaseError>().having(
            (error) => error.code,
            'code',
            types.ErrorCode.IapNotAvailable,
          ),
        ),
      );
    });
  });

  group('requestPurchase Android in-app', () {
    test('sends payload including obfuscated identifiers', () async {
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        calls.add(call);
        switch (call.method) {
          case 'initConnection':
            return true;
          case 'requestPurchase':
            return null;
        }
        return null;
      });

      final iap = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'android'),
      );

      await iap.initConnection();

      await iap.requestPurchase(
        const types.RequestPurchaseProps.inApp((
          ios: null,
          android: types.RequestPurchaseAndroidProps(
            skus: <String>['coin.pack'],
            isOfferPersonalized: true,
            obfuscatedAccountIdAndroid: 'account-1',
            obfuscatedProfileIdAndroid: 'profile-1',
          ),
          useAlternativeBilling: null,
        )),
      );

      final requestCall =
          calls.singleWhere((MethodCall c) => c.method == 'requestPurchase');
      final payload = Map<String, dynamic>.from(
        requestCall.arguments as Map<dynamic, dynamic>,
      );

      expect(payload['type'], 'inapp');
      expect(payload['productId'], 'coin.pack');
      expect(payload['skus'], <String>['coin.pack']);
      expect(payload['isOfferPersonalized'], isTrue);
      expect(payload['obfuscatedAccountId'], 'account-1');
      expect(payload['obfuscatedAccountIdAndroid'], 'account-1');
      expect(payload['obfuscatedProfileId'], 'profile-1');
      expect(payload['obfuscatedProfileIdAndroid'], 'profile-1');
      expect(payload.containsKey('purchaseToken'), isFalse);
    });
  });

  group('getAvailablePurchases', () {
    test('forwards iOS options to native channel and filters invalid entries',
        () async {
      final capturedArguments = <dynamic>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        switch (call.method) {
          case 'initConnection':
            return true;
          case 'getAvailableItems':
            capturedArguments.add(call.arguments);
            return <Map<String, dynamic>>[
              <String, dynamic>{
                'platform': 'ios',
                'productId': 'iap.premium',
                'transactionId': 'txn-123',
                'purchaseToken': 'receipt-data',
                'purchaseState': 'PURCHASED',
                'transactionDate': 1700000000000,
              },
              <String, dynamic>{
                'platform': 'ios',
                'productId': '',
                'transactionId': null,
              },
            ];
        }
        return null;
      });

      final iap = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'ios'),
      );

      await iap.initConnection();

      final purchases = await iap.getAvailablePurchases(
        onlyIncludeActiveItemsIOS: false,
        alsoPublishToEventListenerIOS: true,
      );

      final args = Map<String, dynamic>.from(
        capturedArguments.single as Map<dynamic, dynamic>,
      );

      expect(args['onlyIncludeActiveItemsIOS'], isFalse);
      expect(args['alsoPublishToEventListenerIOS'], isTrue);
      expect(purchases, hasLength(1));
      expect(purchases.single.productId, 'iap.premium');
    });

    test('throws when connection is not initialized', () async {
      final iap = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'android'),
      );

      await expectLater(
        () => iap.getAvailablePurchases(),
        throwsA(
          isA<PurchaseError>().having(
            (error) => error.code,
            'code',
            types.ErrorCode.NotPrepared,
          ),
        ),
      );
    });

    test('filters Android purchases missing identifiers', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        switch (call.method) {
          case 'initConnection':
            return true;
          case 'getAvailableItems':
            return <Map<String, dynamic>>[
              <String, dynamic>{
                'platform': 'android',
                'productId': 'coins.100',
                'transactionId': 'txn-android',
                'purchaseToken': 'token-android',
                'purchaseStateAndroid': 1,
              },
              <String, dynamic>{
                'platform': 'android',
                'productId': '',
              },
            ];
        }
        return null;
      });

      final iap = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'android'),
      );

      await iap.initConnection();

      final purchases = await iap.getAvailablePurchases();
      expect(purchases, hasLength(1));
      expect(purchases.single.productId, 'coins.100');
    });

    test('wraps native errors as PurchaseError', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        if (call.method == 'initConnection') {
          return true;
        }
        if (call.method == 'getAvailableItems') {
          throw PlatformException(code: 'platform', message: 'failure');
        }
        return null;
      });

      final iap = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'android'),
      );

      await iap.initConnection();

      await expectLater(
        iap.getAvailablePurchases(),
        throwsA(
          isA<PurchaseError>().having(
            (error) => error.code,
            'code',
            types.ErrorCode.ServiceError,
          ),
        ),
      );
    });
  });

  group('method channel listeners', () {
    test('purchase-updated emits events on both streams', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        if (call.method == 'initConnection') {
          return true;
        }
        return null;
      });

      final iap = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'ios'),
      );

      final purchaseFuture = iap.purchaseUpdated.first;
      final listenerFuture = iap.purchaseUpdatedListener.first;

      await iap.initConnection();

      final purchasePayload = <String, dynamic>{
        'platform': 'ios',
        'productId': 'iap.premium',
        'transactionId': 'txn-456',
        'purchaseState': 'PURCHASED',
        'transactionReceipt': 'receipt-data',
        'transactionDate': 1700000000000,
      };

      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
        channel.name,
        codec.encodeMethodCall(
          MethodCall('purchase-updated', jsonEncode(purchasePayload)),
        ),
        (_) {},
      );

      final purchase = await purchaseFuture;
      final listenerPurchase = await listenerFuture;

      expect(purchase, isNotNull);
      expect(purchase!.productId, 'iap.premium');
      expect(listenerPurchase.productId, 'iap.premium');
    });

    test('purchase-error emits results to both error streams', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        if (call.method == 'initConnection') {
          return true;
        }
        return null;
      });

      final iap = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'ios'),
      );

      final purchaseErrorFuture = iap.purchaseError.first;
      final listenerErrorFuture = iap.purchaseErrorListener.first;

      await iap.initConnection();

      final errorPayload = <String, dynamic>{
        'responseCode': 5,
        'code': 'DEVELOPER_ERROR',
        'message': 'Validation failed',
      };

      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
        channel.name,
        codec.encodeMethodCall(
          MethodCall('purchase-error', jsonEncode(errorPayload)),
        ),
        (_) {},
      );

      final purchaseError = await purchaseErrorFuture;
      final listenerError = await listenerErrorFuture;

      expect(purchaseError, isNotNull);
      expect(purchaseError!.message, 'Validation failed');
      expect(listenerError.code, types.ErrorCode.DeveloperError);
      expect(listenerError.message, 'Validation failed');
    });

    test('connection-updated emits ConnectionResult', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        if (call.method == 'initConnection') {
          return true;
        }
        return null;
      });

      final iap = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'android'),
      );

      final connectionFuture = iap.connectionUpdated.first;

      await iap.initConnection();

      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
        channel.name,
        codec.encodeMethodCall(
          MethodCall(
              'connection-updated',
              jsonEncode(<String, dynamic>{
                'msg': 'connected',
              })),
        ),
        (_) {},
      );

      final result = await connectionFuture;
      expect(result.msg, 'connected');
    });

    test('iap-promoted-product emits the productId', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        if (call.method == 'initConnection') {
          return true;
        }
        return null;
      });

      final iap = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'ios'),
      );

      final promotedFuture = iap.purchasePromoted.first;

      await iap.initConnection();

      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
        channel.name,
        codec.encodeMethodCall(
          const MethodCall('iap-promoted-product', 'promo.product'),
        ),
        (_) {},
      );

      final productId = await promotedFuture;
      expect(productId, 'promo.product');
    });
  });

  group('sync and restore helpers', () {
    test('restorePurchases triggers sync and fetch on iOS', () async {
      int initCalls = 0;
      int endCalls = 0;
      int availableCalls = 0;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        switch (call.method) {
          case 'initConnection':
            initCalls += 1;
            return true;
          case 'endConnection':
            endCalls += 1;
            return true;
          case 'getAvailableItems':
            availableCalls += 1;
            return <Map<String, dynamic>>[];
        }
        return null;
      });

      final iap = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'ios'),
      );

      expect(await iap.initConnection(), isTrue);
      await iap.restorePurchases();

      expect(endCalls, greaterThanOrEqualTo(1));
      expect(initCalls, greaterThanOrEqualTo(2));
      expect(availableCalls, 1);
    });

    test('restorePurchases swallows sync errors and still fetches', () async {
      int availableCalls = 0;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        if (call.method == 'initConnection') {
          return true;
        }
        if (call.method == 'endConnection') {
          throw PlatformException(code: '500', message: 'boom');
        }
        if (call.method == 'getAvailableItems') {
          availableCalls += 1;
          return <Map<String, dynamic>>[];
        }
        return null;
      });

      final iap = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'ios'),
      );

      expect(await iap.initConnection(), isTrue);
      await iap.restorePurchases();

      expect(availableCalls, 1);
    });

    test('restorePurchases fetches purchases directly on Android', () async {
      int availableCalls = 0;
      int endCalls = 0;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        if (call.method == 'initConnection') {
          return true;
        }
        if (call.method == 'endConnection') {
          endCalls += 1;
          return true;
        }
        if (call.method == 'getAvailableItems') {
          availableCalls += 1;
          return <Map<String, dynamic>>[];
        }
        return null;
      });

      final iap = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'android'),
      );

      expect(await iap.initConnection(), isTrue);
      await iap.restorePurchases();

      expect(availableCalls, 1);
      expect(endCalls, 0);
    });

    test('syncIOS returns true when native calls succeed', () async {
      int endCalls = 0;
      int initCalls = 0;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        if (call.method == 'endConnection') {
          endCalls += 1;
          return true;
        }
        if (call.method == 'initConnection') {
          initCalls += 1;
          return true;
        }
        return null;
      });

      final iap = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'ios'),
      );

      expect(await iap.syncIOS(), isTrue);
      expect(endCalls, 1);
      expect(initCalls, 1);
    });

    test('syncIOS rethrows platform exceptions', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        if (call.method == 'endConnection') {
          throw PlatformException(code: '500', message: 'boom');
        }
        if (call.method == 'initConnection') {
          return true;
        }
        return null;
      });

      final iap = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'ios'),
      );

      await expectLater(
        iap.syncIOS(),
        throwsA(isA<PlatformException>()),
      );
    });

    test('syncIOS returns false on unsupported platforms', () async {
      final iap = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'android'),
      );

      expect(await iap.syncIOS(), isFalse);
    });
  });
}
