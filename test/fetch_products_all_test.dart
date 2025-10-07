import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:flutter_inapp_purchase/types.dart' as types;
import 'package:platform/platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('flutter_inapp');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      switch (call.method) {
        case 'initConnection':
          return true;
        case 'fetchProducts':
          final args = call.arguments as Map<dynamic, dynamic>?;
          final type = args?['type']?.toString();

          final subscription = <String, dynamic>{
            'platform': 'ios',
            'id': 'premium_monthly',
            'type': 'subs',
            'title': 'Premium Monthly',
            'description': 'Monthly subscription',
            'currency': 'USD',
            'displayNameIOS': 'Premium Monthly',
            'displayPrice': '\$24.99',
            'isFamilyShareableIOS': false,
            'jsonRepresentationIOS': '{}',
            'typeIOS': 'AUTO_RENEWABLE_SUBSCRIPTION',
            'price': 24.99,
          };

          final inApp = <String, dynamic>{
            'platform': 'ios',
            'id': 'coin_pack',
            'type': 'in-app',
            'title': 'Coin Pack',
            'description': 'One time coins',
            'currency': 'USD',
            'displayNameIOS': 'Coin Pack',
            'displayPrice': '\$2.99',
            'isFamilyShareableIOS': false,
            'jsonRepresentationIOS': '{}',
            'typeIOS': 'NON_CONSUMABLE',
            'price': 2.99,
          };

          if (type == 'subs') {
            return <Map<String, dynamic>>[subscription];
          }
          if (type == 'inapp') {
            return <Map<String, dynamic>>[inApp];
          }
          return <Map<String, dynamic>>[subscription, inApp];
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('fetchProducts returns in-app products when querying in-app type',
      () async {
    final platform = FakePlatform(operatingSystem: 'ios');
    final iap = FlutterInappPurchase.private(platform);

    await iap.initConnection();

    final products = (await iap.fetchProducts(
      skus: const ['premium_monthly', 'coin_pack'],
      type: types.ProductQueryType.InApp,
    ))
        .cast<types.Product>();

    expect(products, hasLength(1));
    expect(products.first.id, 'coin_pack');
  });

  test('fetchProducts returns subscriptions when querying subs type', () async {
    final platform = FakePlatform(operatingSystem: 'ios');
    final iap = FlutterInappPurchase.private(platform);

    await iap.initConnection();

    final subscriptions = (await iap.fetchProducts(
      skus: const ['premium_monthly', 'coin_pack'],
      type: types.ProductQueryType.Subs,
    ))
        .cast<types.ProductSubscription>();

    expect(subscriptions, hasLength(1));
    expect(subscriptions.first.id, 'premium_monthly');
  });
}
