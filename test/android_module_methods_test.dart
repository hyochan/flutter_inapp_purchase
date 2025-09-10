import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform/platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Android module methods', () {
    late FlutterInappPurchase iapAndroid;

    setUp(() async {
      iapAndroid = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'android'),
      );

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(iapAndroid.channel, (call) async {
        switch (call.method) {
          case 'manageSubscription':
            return null; // success
          case 'validateReceiptAndroid':
            return <String, dynamic>{
              'status': 'ok',
              'productId': call.arguments['productId'],
            };
          case 'consumePurchase':
            return true;
          case 'showInAppMessages':
            return true;
          case 'getInAppMessages':
            final list = [
              {
                'messageId': 'm1',
                'campaignName': 'camp',
                'messageType': 0,
              }
            ];
            return jsonEncode(list);
          case 'getConnectionState':
            return 2; // connected
        }
        return null;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(iapAndroid.channel, null);
    });

    test('deepLinkToSubscriptionsAndroid invokes on Android', () async {
      // Should not throw
      await iapAndroid.deepLinkToSubscriptionsAndroid(sku: 'sub');
    });

    test('validateReceiptAndroid returns map', () async {
      final res = await iapAndroid.validateReceiptAndroid(
        packageName: 'pkg',
        productId: 'prod',
        productToken: 'tok',
        accessToken: 'acc',
        isSub: true,
      );
      expect(res?['status'], 'ok');
      expect(res?['productId'], 'prod');
    });

    test('consumePurchaseAndroid returns true', () async {
      final ok = await iapAndroid.consumePurchaseAndroid(
        purchaseToken: 'token',
      );
      expect(ok, true);
    });

    test('getInAppMessagesAndroid parses response', () async {
      final msgs = await iapAndroid.getInAppMessagesAndroid();
      expect(msgs.length, 1);
      expect(msgs.first.messageId, 'm1');
    });

    test('showInAppMessagesAndroid returns true', () async {
      final ok = await iapAndroid.showInAppMessagesAndroid();
      expect(ok, true);
    });

    test('getConnectionStateAndroid mapping', () async {
      final state = await iapAndroid.getConnectionStateAndroid();
      expect(state, BillingClientState.connected);
    });

    test('android methods are no-op on iOS', () async {
      final iapIOS = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'ios'),
      );
      // Should not throw and return defaults
      await iapIOS.deepLinkToSubscriptionsAndroid();
      expect(
        await iapIOS.consumePurchaseAndroid(purchaseToken: 'x'),
        false,
      );
      expect(await iapIOS.getInAppMessagesAndroid(), isEmpty);
      expect(await iapIOS.showInAppMessagesAndroid(), false);
      expect(
        await iapIOS.getConnectionStateAndroid(),
        BillingClientState.disconnected,
      );
    });
  });
}

