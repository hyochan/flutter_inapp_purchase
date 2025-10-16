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
    final result = extractPurchases(
      <Map<String, dynamic>>[
        <String, dynamic>{
          'platform': 'android',
          'purchaseStateAndroid': 1,
        },
      ],
      platformIsAndroid: true,
      platformIsIOS: false,
      acknowledgedAndroidPurchaseTokens: <String, bool>{},
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
          case 'getActiveSubscriptions':
            return <Map<String, dynamic>>[
              <String, dynamic>{
                'productId': 'sub.android',
                'transactionId': 'txn_android',
                'purchaseToken': 'token-123',
                'isActive': true,
                'autoRenewingAndroid': true,
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
          case 'getActiveSubscriptions':
            // Native method filters out deferred purchases
            return <Map<String, dynamic>>[];
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
          case 'getActiveSubscriptions':
            return <Map<String, dynamic>>[
              <String, dynamic>{
                'productId': 'sub.ios',
                'transactionId': 'txn_ios',
                'purchaseToken': 'receipt-data',
                'isActive': true,
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
