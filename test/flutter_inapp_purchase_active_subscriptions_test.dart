import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:platform/platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('flutter_inapp');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('extractPurchases skips entries missing identifiers', () {
    final iap = FlutterInappPurchase.private(
      FakePlatform(operatingSystem: 'android'),
    );

    final result = iap.extractPurchases(
      <Map<String, dynamic>>[
        <String, dynamic>{
          'platform': 'android',
          'purchaseStateAndroid': 1,
        },
      ],
    );

    expect(result, isEmpty);
  });

  group('getActiveSubscriptions', () {
    test('returns active Android subscriptions only for purchased items',
        () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        switch (call.method) {
          case 'initConnection':
            return true;
          case 'getAvailableItems':
            return <Map<String, dynamic>>[
              <String, dynamic>{
                'platform': 'android',
                'productId': 'sub.android',
                'transactionId': 'txn_android',
                'purchaseToken': 'token-123',
                'purchaseStateAndroid': 1,
                'isAutoRenewing': true,
                'autoRenewingAndroid': true,
                'quantity': 1,
                'transactionDate': 1700000000000,
              },
            ];
        }
        return null;
      });

      final iap = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'android'),
      );

      await iap.initConnection();
      final subs = await iap.getActiveSubscriptions();

      expect(subs, hasLength(1));
      expect(subs.single.productId, 'sub.android');
      expect(subs.single.autoRenewingAndroid, isTrue);
    });

    test('ignores deferred iOS purchases', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        switch (call.method) {
          case 'initConnection':
            return true;
          case 'getAvailableItems':
            return <Map<String, dynamic>>[
              <String, dynamic>{
                'platform': 'ios',
                'productId': 'sub.ios',
                'transactionId': 'txn_ios',
                'purchaseToken': 'receipt-data',
                'purchaseState': 'DEFERRED',
                'transactionDate': 1700000000000,
              },
            ];
        }
        return null;
      });

      final iap = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'ios'),
      );

      await iap.initConnection();
      final subs = await iap.getActiveSubscriptions();

      expect(subs, isEmpty);
    });

    test('includes purchased iOS subscriptions', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        switch (call.method) {
          case 'initConnection':
            return true;
          case 'getAvailableItems':
            return <Map<String, dynamic>>[
              <String, dynamic>{
                'platform': 'ios',
                'productId': 'sub.ios',
                'transactionId': 'txn_ios',
                'purchaseToken': 'receipt-data',
                'purchaseState': 'PURCHASED',
                'transactionDate': 1700000000000,
              },
            ];
        }
        return null;
      });

      final iap = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'ios'),
      );

      await iap.initConnection();
      final subs = await iap.getActiveSubscriptions();

      expect(subs, hasLength(1));
      expect(subs.single.productId, 'sub.ios');
      expect(subs.single.environmentIOS, isNull);
    });
  });
}
