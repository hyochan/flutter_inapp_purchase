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
            case 'presentCodeRedemptionSheetIOS':
              return null;
            case 'showManageSubscriptionsIOS':
              return null;
            case 'getStorefrontIOS':
              return <String, dynamic>{'countryCode': 'US'};
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
  });
}
