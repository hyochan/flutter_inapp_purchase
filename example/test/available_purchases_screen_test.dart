import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_inapp_purchase_example/src/screens/available_purchases_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('flutter_inapp');

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall call) async {
      switch (call.method) {
        case 'initConnection':
          return true;
        case 'getAvailablePurchases':
          return <Map<String, dynamic>>[
            <String, dynamic>{
              'platform': 'android',
              'id': 'txn_123',
              'productId': 'dev.hyo.martie.premium',
              'purchaseToken': 'token_abc',
              'purchaseTokenAndroid': 'token_abc',
              'purchaseStateAndroid': 1,
              'isAutoRenewing': true,
              'autoRenewingAndroid': true,
              'transactionDate': 1700000000000.0,
              'transactionId': 'txn_123',
            },
          ];
        case 'getPurchaseHistory':
        case 'getPendingPurchases':
        case 'getAvailableItems':
          return <Map<String, dynamic>>[];
        case 'endConnection':
          return true;
      }
      return null;
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  testWidgets('shows available purchase cards', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AvailablePurchasesScreen()),
    );

    // Wait for the initial load to complete
    await tester.pumpAndSettle();

    // Verify the screen loads and shows the connected status
    expect(find.text('Connected to Store'), findsOneWidget);
    // Verify restore button is present
    expect(find.text('Restore Purchases'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
