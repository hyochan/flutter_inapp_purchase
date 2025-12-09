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
          'store': 'google',
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

    test('parses renewalInfoIOS with all fields', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        switch (call.method) {
          case 'initConnection':
            return true;
          case 'getActiveSubscriptions':
            return <Map<String, dynamic>>[
              <String, dynamic>{
                'productId': 'sub.ios.premium',
                'transactionId': 'txn_ios_123',
                'purchaseToken': 'receipt-data',
                'isActive': true,
                'transactionDate': 1700000000000,
                'renewalInfoIOS': <String, dynamic>{
                  'willAutoRenew': true,
                  'autoRenewPreference': 'sub.ios.premium',
                  'expirationReason': null,
                  'isInBillingRetry': false,
                  'gracePeriodExpirationDate': null,
                  'priceIncreaseStatus': 'noIncreasePending',
                  'renewalDate': 1735689599000.0,
                  'pendingUpgradeProductId': null,
                },
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
      final sub = subs.single;
      expect(sub.productId, 'sub.ios.premium');
      expect(sub.renewalInfoIOS, isNotNull);
      expect(sub.renewalInfoIOS!.willAutoRenew, isTrue);
      expect(sub.renewalInfoIOS!.autoRenewPreference, 'sub.ios.premium');
      expect(sub.renewalInfoIOS!.expirationReason, isNull);
      expect(sub.renewalInfoIOS!.isInBillingRetry, isFalse);
      expect(sub.renewalInfoIOS!.priceIncreaseStatus, 'noIncreasePending');
      expect(sub.renewalInfoIOS!.renewalDate, 1735689599000.0);
      expect(sub.renewalInfoIOS!.pendingUpgradeProductId, isNull);
    });

    test('parses renewalInfoIOS with pending upgrade', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        switch (call.method) {
          case 'initConnection':
            return true;
          case 'getActiveSubscriptions':
            return <Map<String, dynamic>>[
              <String, dynamic>{
                'productId': 'sub.ios.basic',
                'transactionId': 'txn_ios_456',
                'purchaseToken': 'receipt-data',
                'isActive': true,
                'transactionDate': 1700000000000,
                'renewalInfoIOS': <String, dynamic>{
                  'willAutoRenew': true,
                  'autoRenewPreference': 'sub.ios.premium',
                  'pendingUpgradeProductId': 'sub.ios.premium',
                  'renewalDate': 1735689599000.0,
                },
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
      final sub = subs.single;
      expect(sub.productId, 'sub.ios.basic');
      expect(sub.renewalInfoIOS, isNotNull);
      expect(sub.renewalInfoIOS!.pendingUpgradeProductId, 'sub.ios.premium');
      expect(sub.renewalInfoIOS!.autoRenewPreference, 'sub.ios.premium');
    });

    test('parses renewalInfoIOS with cancellation (will not renew)', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        switch (call.method) {
          case 'initConnection':
            return true;
          case 'getActiveSubscriptions':
            return <Map<String, dynamic>>[
              <String, dynamic>{
                'productId': 'sub.ios.premium',
                'transactionId': 'txn_ios_789',
                'purchaseToken': 'receipt-data',
                'isActive': true,
                'transactionDate': 1700000000000,
                'renewalInfoIOS': <String, dynamic>{
                  'willAutoRenew': false,
                  'expirationReason': 'voluntaryCancellation',
                  'renewalDate': 1736899200000.0,
                },
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
      final sub = subs.single;
      expect(sub.renewalInfoIOS, isNotNull);
      expect(sub.renewalInfoIOS!.willAutoRenew, isFalse);
      expect(sub.renewalInfoIOS!.expirationReason, 'voluntaryCancellation');
    });

    test('parses renewalInfoIOS with billing retry and grace period', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        switch (call.method) {
          case 'initConnection':
            return true;
          case 'getActiveSubscriptions':
            return <Map<String, dynamic>>[
              <String, dynamic>{
                'productId': 'sub.ios.premium',
                'transactionId': 'txn_ios_retry',
                'purchaseToken': 'receipt-data',
                'isActive': true,
                'transactionDate': 1700000000000,
                'renewalInfoIOS': <String, dynamic>{
                  'willAutoRenew': true,
                  'isInBillingRetry': true,
                  'gracePeriodExpirationDate': 1737331200000.0,
                  'renewalDate': 1736899200000.0,
                },
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
      final sub = subs.single;
      expect(sub.renewalInfoIOS, isNotNull);
      expect(sub.renewalInfoIOS!.isInBillingRetry, isTrue);
      expect(sub.renewalInfoIOS!.gracePeriodExpirationDate, 1737331200000.0);
    });

    test('handles Map result type (single subscription)', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        switch (call.method) {
          case 'initConnection':
            return true;
          case 'getActiveSubscriptions':
            // Return single Map instead of List
            return <String, dynamic>{
              'productId': 'sub.ios.single',
              'transactionId': 'txn_single',
              'purchaseToken': 'receipt-data',
              'isActive': true,
              'transactionDate': 1700000000000,
            };
        }
        return null;
      });

      final iap = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'ios'),
      );

      await iap.initConnection();
      final subs = await iap.getActiveSubscriptions();

      expect(subs, hasLength(1));
      expect(subs.single.productId, 'sub.ios.single');
    });

    test('handles unexpected result type gracefully', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        switch (call.method) {
          case 'initConnection':
            return true;
          case 'getActiveSubscriptions':
            // Return unexpected type
            return 12345;
        }
        return null;
      });

      final iap = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'ios'),
      );

      await iap.initConnection();
      final subs = await iap.getActiveSubscriptions();

      // Should return empty list instead of crashing
      expect(subs, isEmpty);
    });
  });
}
