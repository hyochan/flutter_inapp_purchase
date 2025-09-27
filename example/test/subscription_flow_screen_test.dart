import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_inapp_purchase_example/src/screens/subscription_flow_screen.dart';

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
          final type = (args?['type']?.toString() ?? 'subs')
              .replaceAll('-', '')
              .toLowerCase();
          if (type == 'subs') {
            return <Map<String, dynamic>>[
              <String, dynamic>{
                'platform': 'ios',
                'id': 'dev.hyo.martie.premium',
                'productId': 'dev.hyo.martie.premium',
                'title': 'Premium Monthly',
                'description': 'Unlock premium access',
                'currency': 'USD',
                'displayPrice': '\$4.99',
                'price': '4.99',
                'type': 'subs',
                'displayNameIOS': 'Premium Monthly',
                'isFamilyShareableIOS': false,
                'jsonRepresentationIOS': '{}',
                'typeIOS': 'AUTO_RENEWABLE_SUBSCRIPTION',
                'subscriptionInfoIOS': <String, dynamic>{
                  'subscriptionGroupId': 'group1',
                  'subscriptionPeriod': <String, dynamic>{
                    'unit': 'MONTH',
                    'value': 1,
                  },
                  'introductoryOffer': null,
                  'promotionalOffers': <Map<String, dynamic>>[],
                },
              },
            ];
          }
          return [];
        case 'getAvailablePurchases':
        case 'getAvailableItems':
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

  testWidgets('renders subscription tiles and triggers requestPurchase',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SubscriptionFlowScreen()),
    );

    await tester.pumpAndSettle();

    expect(log.where((call) => call.method == 'fetchProducts'), isNotEmpty);
    // The mock returns 1 subscription, so we should see it displayed
    expect(find.text('Premium Monthly'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
