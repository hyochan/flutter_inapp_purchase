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
          return <Map<String, dynamic>>[
            <String, dynamic>{
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
            },
            <String, dynamic>{
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
            },
          ];
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('fetchProducts detects per-item type when querying all products',
      () async {
    final platform = FakePlatform(operatingSystem: 'ios');
    final iap = FlutterInappPurchase.private(platform);

    await iap.initConnection();

    final result = await iap.fetchProducts<types.ProductCommon>(
      skus: const ['premium_monthly', 'coin_pack'],
      type: types.ProductQueryType.All,
    );

    final subs = result.whereType<types.ProductSubscriptionIOS>().toList();
    final inApps = result.whereType<types.ProductIOS>().toList();

    expect(subs, hasLength(1));
    expect(subs.first.id, 'premium_monthly');
    expect(inApps, hasLength(1));
    expect(inApps.first.id, 'coin_pack');
  });
}
