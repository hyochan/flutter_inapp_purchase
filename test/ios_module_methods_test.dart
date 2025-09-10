import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform/platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('iOS module methods', () {
    late FlutterInappPurchase iapIOS;

    setUp(() async {
      iapIOS = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'ios'),
      );

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(iapIOS.channel, (call) async {
        switch (call.method) {
          case 'endConnection':
          case 'initConnection':
            return true;
          case 'isEligibleForIntroOffer':
            return true;
          case 'getSubscriptionStatus':
            return <String, dynamic>{'status': 'active'};
          case 'getSubscriptionGroup':
            return 'group1';
          case 'getAppStoreCountry':
            return 'US';
          case 'presentCodeRedemptionSheetIOS':
            return null;
          case 'clearTransactionIOS':
            return null;
          case 'getPromotedProductIOS':
            return 'sku.promoted';
          case 'getAvailableItems':
            // Return JSON string to exercise parsing path
            return jsonEncode([
              {
                'productId': 'p1',
                'transactionId': 't1',
              }
            ]);
          case 'getAppTransaction':
            return <String, dynamic>{
              'appAppleId': '123',
              'bundleId': 'com.example',
            };
          case 'getPurchaseHistoriesIOS':
            return jsonEncode([
              {
                'productId': 'p2',
                'transactionId': 't2',
                'platform': 'ios',
              }
            ]);
        }
        return null;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(iapIOS.channel, null);
    });

    test('syncIOS calls end/init on iOS and false on Android', () async {
      expect(await iapIOS.syncIOS(), true);
      final iapAndroid = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'android'),
      );
      expect(await iapAndroid.syncIOS(), false);
    });

    test('eligibility and subscription helpers', () async {
      expect(await iapIOS.isEligibleForIntroOfferIOS('sku'), true);
      expect(
        await iapIOS.getSubscriptionStatusIOS('sku'),
        containsPair('status', 'active'),
      );
      expect(await iapIOS.getSubscriptionGroupIOS('sku'), 'group1');
      expect(await iapIOS.getAppStoreCountryIOS(), 'US');
    });

    test('presentCodeRedemptionSheetIOS only on iOS', () async {
      await iapIOS.presentCodeRedemptionSheetIOS();
      final iapAndroid = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'android'),
      );
      expect(
        () => iapAndroid.presentCodeRedemptionSheetIOS(),
        throwsA(isA<PlatformException>()),
      );
    });

    test('promoted product & available items parsing', () async {
      final promoted = await iapIOS.getPromotedProductIOS();
      expect(promoted, isNotNull);
      expect(promoted!['productIdentifier'], 'sku.promoted');

      final items = await iapIOS.getAvailableItemsIOS();
      expect(items, isNotNull);
      expect(items!.first.productId, 'p1');
    });

    test('app transaction (typed) and histories', () async {
      final txMap = await iapIOS.getAppTransactionIOS();
      expect(txMap, isNotNull);
      // Typed parsing expects full iOS 18.4+ schema; with partial map it returns null
      final typed = await iapIOS.getAppTransactionTypedIOS();
      expect(typed, isNull);

      final histories = await iapIOS.getPurchaseHistoriesIOS();
      expect(histories.length, 1);
      expect(histories.first.productId, 'p2');
    });
  });
}
