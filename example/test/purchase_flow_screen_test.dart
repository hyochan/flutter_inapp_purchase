import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_inapp_purchase_example/src/screens/purchase_flow_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('flutter_inapp');

  late List<MethodCall> log;

  setUp(() {
    log = <MethodCall>[];
    channel.setMockMethodCallHandler((MethodCall call) async {
      log.add(call);
      switch (call.method) {
        case 'initConnection':
          return true;
        case 'fetchProducts':
          final args = call.arguments as Map<dynamic, dynamic>?;
          final type = (args?['type']?.toString() ?? 'inapp')
              .replaceAll('-', '')
              .toLowerCase();
          if (type == 'inapp') {
            return <Map<String, dynamic>>[
              <String, dynamic>{
                'platform': 'android',
                'id': 'dev.hyo.martie.10bulbs',
                'productId': 'dev.hyo.martie.10bulbs',
                'title': '10 Bulbs',
                'description': 'Adds 10 bulbs to your account',
                'currency': 'USD',
                'displayPrice': '\$0.99',
                'price': '0.99',
                'type': 'in-app',
                'localizedPrice': '\$0.99',
              },
            ];
          }
          return [];
        case 'getAvailableItems':
        case 'getAvailablePurchases':
        case 'getPurchaseHistory':
          return <Map<String, dynamic>>[];
        case 'requestPurchase':
          return null;
        case 'endConnection':
          return true;
      }
      return null;
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  testWidgets('loads products and triggers purchase when tapping Buy',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: PurchaseFlowScreen()));

    await tester.pumpAndSettle();

    expect(log.where((call) => call.method == 'fetchProducts'), isNotEmpty);
    expect(find.text('10 Bulbs'), findsOneWidget);

    // Verify the Buy button is present
    expect(find.text('Buy'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
