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
          case 'isEligibleForIntroOfferIOS':
            return true;
          case 'getSubscriptionStatus':
            return <Map<String, dynamic>>[
              <String, dynamic>{
                'state': 'active',
              },
            ];
          case 'presentCodeRedemptionSheetIOS':
            return null;
          case 'clearTransactionIOS':
            return null;
          case 'getPromotedProductIOS':
            return <String, dynamic>{
              'currency': 'USD',
              'description': 'Promoted product',
              'displayNameIOS': 'Promoted',
              'displayPrice': '\$0.99',
              'id': 'sku.promoted',
              'isFamilyShareableIOS': false,
              'jsonRepresentationIOS': '{}',
              'platform': 'IOS',
              'title': 'Promoted product',
              'type': 'IN_APP',
              'typeIOS': 'CONSUMABLE',
            };
          case 'getAvailableItems':
            // Return JSON string to exercise parsing path
            return jsonEncode([
              {
                'productId': 'p1',
                'transactionId': 't1',
                'platform': 'ios',
                'store': 'apple',
              }
            ]);
          case 'getAppTransaction':
            return <String, dynamic>{
              'appId': 123,
              'appTransactionId': 'tx-1',
              'appVersion': '1.0.0',
              'appVersionId': 1,
              'bundleId': 'com.example',
              'deviceVerification': 'sig',
              'deviceVerificationNonce': 'nonce',
              'environment': 'Sandbox',
              'originalAppVersion': '1.0.0',
              'originalPlatform': 'IOS',
              'originalPurchaseDate': 1700000000000,
              'signedDate': 1700000000000,
            };
          case 'getPurchaseHistoriesIOS':
            return jsonEncode([
              {
                'productId': 'p2',
                'transactionId': 't2',
                'platform': 'ios',
                'store': 'apple',
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
      final subscriptionStatuses = await iapIOS.subscriptionStatusIOS('sku');
      expect(subscriptionStatuses, hasLength(1));
      expect(subscriptionStatuses.first.state, 'active');
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
  });
}
