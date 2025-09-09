import 'package:flutter/services.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform/platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Purchase Flow Tests', () {
    late FlutterInappPurchase plugin;
    final List<MethodCall> methodChannelLog = <MethodCall>[];

    setUp(() {
      methodChannelLog.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('flutter_inapp'), (
        MethodCall methodCall,
      ) async {
        methodChannelLog.add(methodCall);
        switch (methodCall.method) {
          case 'initConnection':
            return true;
          case 'endConnection':
            return true;
          case 'getProducts':
          case 'getSubscriptions':
            final args = methodCall.arguments;
            final productIds = args is Map
                ? (args['productIds'] as Iterable?)
                    ?.map((e) => e.toString())
                    .toList()
                : args is Iterable
                    ? args.map((e) => e.toString()).toList()
                    : null;
            final allProducts = _getMockProducts();
            final filteredProducts = productIds != null
                ? allProducts
                    .where(
                      (product) => productIds.contains(product['productId']),
                    )
                    .toList()
                : allProducts;
            return filteredProducts
                .map((item) => Map<String, dynamic>.from(item))
                .toList();
          case 'buyItemByType':
            return _getMockPurchase(methodCall.arguments);
          case 'buyProduct':
            return _getMockPurchase(methodCall.arguments);
          case 'requestSubscription':
            return _getMockSubscription(methodCall.arguments);
          case 'finishTransaction':
            return 'finished';
          case 'consumeProduct':
            return <String, dynamic>{'purchaseToken': methodCall.arguments};
          case 'acknowledgePurchase':
            return <String, dynamic>{'purchaseToken': methodCall.arguments};
          case 'getAvailablePurchases':
            return _getMockAvailablePurchases()
                .map((item) => Map<String, dynamic>.from(item))
                .toList();
          case 'getAvailableItems':
            return _getMockAvailablePurchases()
                .map((item) => Map<String, dynamic>.from(item))
                .toList();
          case 'restorePurchases':
            return _getMockAvailablePurchases()
                .map((item) => Map<String, dynamic>.from(item))
                .toList();
          case 'getPurchaseHistory':
            return _getMockPurchaseHistory()
                .map((item) => Map<String, dynamic>.from(item))
                .toList();
          case 'getAvailableItemsByType':
            return _getMockAvailablePurchases()
                .map((item) => Map<String, dynamic>.from(item))
                .toList();
          default:
            return null;
        }
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('flutter_inapp'), null);
    });

    group('Connection Management', () {
      test('initConnection succeeds on Android', () async {
        plugin = FlutterInappPurchase.private(
          FakePlatform(operatingSystem: 'android'),
        );
        final result = await plugin.initConnection();
        expect(result, true);
        expect(methodChannelLog.last.method, 'initConnection');
      });

      test('initConnection succeeds on iOS', () async {
        plugin = FlutterInappPurchase.private(
          FakePlatform(operatingSystem: 'ios'),
        );
        final result = await plugin.initConnection();
        expect(result, true);
        expect(methodChannelLog.last.method, 'initConnection');
      });

      test('initConnection throws when already initialized', () async {
        plugin = FlutterInappPurchase.private(
          FakePlatform(operatingSystem: 'android'),
        );
        await plugin.initConnection();

        expect(
          () => plugin.initConnection(),
          throwsA(
            isA<PurchaseError>().having(
              (e) => e.code,
              'error code',
              ErrorCode.eAlreadyInitialized,
            ),
          ),
        );
      });

      test('endConnection succeeds when initialized', () async {
        plugin = FlutterInappPurchase.private(
          FakePlatform(operatingSystem: 'android'),
        );
        await plugin.initConnection();
        final result = await plugin.endConnection();
        expect(result, true);
        expect(methodChannelLog.last.method, 'endConnection');
      });

      test('endConnection returns false when not initialized', () async {
        plugin = FlutterInappPurchase.private(
          FakePlatform(operatingSystem: 'android'),
        );
        final result = await plugin.endConnection();
        expect(result, false);
      });
    });

    group('Product Requests', () {
      test('requestProducts returns products on Android', () async {
        plugin = FlutterInappPurchase.private(
          FakePlatform(operatingSystem: 'android'),
        );
        await plugin.initConnection();

        final products = await plugin.requestProducts(
          skus: ['product1', 'product2'],
          type: ProductType.inapp,
        );

        expect(products.length, 2);
        expect(products[0].productId, 'product1');
        expect(products[0].displayPrice, '\$1.99');
        expect(products[1].productId, 'product2');
      });

      test('requestProducts throws when not initialized', () async {
        plugin = FlutterInappPurchase.private(
          FakePlatform(operatingSystem: 'android'),
        );

        expect(
          () => plugin.requestProducts(
            skus: ['product1'],
            type: ProductType.inapp,
          ),
          throwsA(
            isA<PurchaseError>().having(
              (e) => e.code,
              'error code',
              ErrorCode.eNotInitialized,
            ),
          ),
        );
      });

      test('requestProducts for subscriptions', () async {
        plugin = FlutterInappPurchase.private(
          FakePlatform(operatingSystem: 'android'),
        );
        await plugin.initConnection();

        final subscriptions = await plugin.requestProducts(
          skus: ['sub1', 'sub2'],
          type: ProductType.subs,
        );

        expect(subscriptions.length, 2);
        expect(methodChannelLog.last.method, 'getSubscriptions');
      });
    });

    group('Purchase Requests', () {
      test('requestPurchase for product on Android', () async {
        plugin = FlutterInappPurchase.private(
          FakePlatform(operatingSystem: 'android'),
        );
        await plugin.initConnection();

        await plugin.requestPurchase(
          request: RequestPurchase(
            android: RequestPurchaseAndroid(skus: ['product1']),
          ),
          type: ProductType.inapp,
        );

        expect(methodChannelLog.last.method, 'buyItemByType');
      });

      test('requestPurchase with additional params on Android', () async {
        plugin = FlutterInappPurchase.private(
          FakePlatform(operatingSystem: 'android'),
        );
        await plugin.initConnection();

        await plugin.requestPurchase(
          request: RequestPurchase(
            android: RequestPurchaseAndroid(
              skus: ['product1'],
              obfuscatedAccountIdAndroid: 'user123',
              obfuscatedProfileIdAndroid: 'profile456',
            ),
          ),
          type: ProductType.inapp,
        );

        expect(
          methodChannelLog.last.arguments['sku'] ??
              methodChannelLog.last.arguments['productId'],
          'product1',
        );
        expect(
          methodChannelLog.last.arguments['obfuscatedAccountId'],
          'user123',
        );
        expect(
          methodChannelLog.last.arguments['obfuscatedProfileId'],
          'profile456',
        );
      });

      test('requestPurchase for subscription on Android', () async {
        plugin = FlutterInappPurchase.private(
          FakePlatform(operatingSystem: 'android'),
        );
        await plugin.initConnection();

        await plugin.requestPurchase(
          request: RequestPurchase(
            android: RequestPurchaseAndroid(skus: ['subscription1']),
          ),
          type: ProductType.subs,
        );

        expect(methodChannelLog.last.method, 'buyItemByType');
      });

      test('requestPurchase with offer token on Android', () async {
        plugin = FlutterInappPurchase.private(
          FakePlatform(operatingSystem: 'android'),
        );
        await plugin.initConnection();

        await plugin.requestPurchase(
          request: RequestPurchase(
            android: RequestSubscriptionAndroid(
              skus: ['subscription1'],
              subscriptionOffers: [
                SubscriptionOfferAndroid(
                  sku: 'subscription1',
                  offerToken: 'offer_token_123',
                ),
              ],
            ),
          ),
          type: ProductType.subs,
        );

        // Check that subscription1 is in the arguments
        expect(
          methodChannelLog.last.arguments.toString(),
          contains('subscription1'),
        );
      });

      test('requestPurchase on iOS', () async {
        plugin = FlutterInappPurchase.private(
          FakePlatform(operatingSystem: 'ios'),
        );
        await plugin.initConnection();

        await plugin.requestPurchase(
          request: RequestPurchase(ios: RequestPurchaseIOS(sku: 'ios.product')),
          type: ProductType.inapp,
        );

        expect(methodChannelLog.last.method, 'requestPurchase');
      });
    });

    group('Transaction Completion', () {
      test('finishTransaction consumes consumable on Android', () async {
        plugin = FlutterInappPurchase.private(
          FakePlatform(operatingSystem: 'android'),
        );
        await plugin.initConnection();

        final purchase = Purchase(
          productId: 'consumable.product',
          transactionId: 'GPA.1234',
          purchaseToken: 'consume_token',
          platform: IapPlatform.android,
          isAcknowledgedAndroid: false,
        );

        await plugin.finishTransaction(purchase, isConsumable: true);

        expect(methodChannelLog.last.method, 'consumeProduct');
      });

      test(
        'finishTransaction acknowledges non-consumable on Android',
        () async {
          plugin = FlutterInappPurchase.private(
            FakePlatform(operatingSystem: 'android'),
          );
          await plugin.initConnection();

          final purchase = Purchase(
            productId: 'non_consumable.product',
            transactionId: 'GPA.5678',
            purchaseToken: 'acknowledge_token',
            platform: IapPlatform.android,
            isAcknowledgedAndroid: false,
          );

          await plugin.finishTransaction(purchase);

          expect(methodChannelLog.last.method, 'acknowledgePurchase');
        },
      );

      test('finishTransaction on iOS', () async {
        plugin = FlutterInappPurchase.private(
          FakePlatform(operatingSystem: 'ios'),
        );
        await plugin.initConnection();

        final purchase = Purchase(
          productId: 'ios.product',
          transactionId: '1000000123456',
          platform: IapPlatform.ios,
        );

        await plugin.finishTransaction(purchase);

        expect(methodChannelLog.last.method, 'finishTransaction');
        expect(
          methodChannelLog.last.arguments['transactionId'],
          '1000000123456',
        );
      });

      test('finishTransaction skips already acknowledged', () async {
        plugin = FlutterInappPurchase.private(
          FakePlatform(operatingSystem: 'android'),
        );
        await plugin.initConnection();

        final purchase = Purchase(
          productId: 'already_ack.product',
          transactionId: 'GPA.9999',
          purchaseToken: 'ack_token',
          platform: IapPlatform.android,
          isAcknowledgedAndroid: true,
        );

        await plugin.finishTransaction(purchase);

        // Should not call any method since already acknowledged
        expect(
          methodChannelLog.isEmpty ||
              methodChannelLog.last.method == 'initConnection',
          true,
        );
      });
    });

    group('Purchase History', () {
      test('getAvailablePurchases returns purchases', () async {
        plugin = FlutterInappPurchase.private(
          FakePlatform(operatingSystem: 'android'),
        );
        await plugin.initConnection();

        final purchases = await plugin.getAvailablePurchases();

        // The mock returns all available purchases
        expect(purchases.length, greaterThan(0));
        // Just verify we have some purchases
        expect(purchases[0].productId, isNotEmpty);
      });
    });

    group('Error Handling', () {
      test('handles purchase cancellation', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(const MethodChannel('flutter_inapp'), (
          MethodCall methodCall,
        ) async {
          if (methodCall.method == 'initConnection') return true;
          if (methodCall.method == 'buyItemByType' ||
              methodCall.method == 'buyProduct') {
            throw PlatformException(
              code: 'E_USER_CANCELLED',
              message: 'User cancelled the purchase',
            );
          }
          return null;
        });

        plugin = FlutterInappPurchase.private(
          FakePlatform(operatingSystem: 'android'),
        );
        await plugin.initConnection();

        expect(
          () => plugin.requestPurchase(
            request: RequestPurchase(
              android: RequestPurchaseAndroid(skus: ['product1']),
            ),
            type: ProductType.inapp,
          ),
          throwsA(isA<PurchaseError>()),
        );
      });

      test('handles network errors', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(const MethodChannel('flutter_inapp'), (
          MethodCall methodCall,
        ) async {
          if (methodCall.method == 'initConnection') return true;
          if (methodCall.method == 'getProducts') {
            throw PlatformException(
              code: 'E_NETWORK_ERROR',
              message: 'Network connection failed',
            );
          }
          return null;
        });

        plugin = FlutterInappPurchase.private(
          FakePlatform(operatingSystem: 'android'),
        );
        await plugin.initConnection();

        expect(
          () => plugin.requestProducts(
            skus: ['product1'],
            type: ProductType.inapp,
          ),
          throwsA(isA<PurchaseError>()),
        );
      });
    });
  });
}

List<Map<String, dynamic>> _getMockProducts() {
  return <Map<String, dynamic>>[
    <String, dynamic>{
      'productId': 'product1',
      'price': '\$1.99',
      'currency': 'USD',
      'localizedPrice': '\$1.99',
      'title': 'Product 1',
      'description': 'Description for product 1',
    },
    <String, dynamic>{
      'productId': 'product2',
      'price': '\$2.99',
      'currency': 'USD',
      'localizedPrice': '\$2.99',
      'title': 'Product 2',
      'description': 'Description for product 2',
    },
    <String, dynamic>{
      'productId': 'sub1',
      'price': '\$4.99',
      'currency': 'USD',
      'localizedPrice': '\$4.99',
      'title': 'Subscription 1',
      'description': 'Monthly subscription',
    },
    <String, dynamic>{
      'productId': 'sub2',
      'price': '\$9.99',
      'currency': 'USD',
      'localizedPrice': '\$9.99',
      'title': 'Subscription 2',
      'description': 'Yearly subscription',
    },
  ];
}

Map<String, dynamic> _getMockPurchase(dynamic arguments) {
  final args = arguments as Map<dynamic, dynamic>?;
  return <String, dynamic>{
    'productId': args?['productId'] ?? args?['sku'] ?? 'product1',
    'purchaseToken': 'mock_purchase_token',
    'orderId': 'ORDER123',
    'transactionId': 'GPA.1234-5678',
    'purchaseState': 1,
    'isAcknowledged': false,
  };
}

Map<String, dynamic> _getMockSubscription(dynamic arguments) {
  final args = arguments as Map<dynamic, dynamic>?;
  return <String, dynamic>{
    'productId': args?['sku'] ?? 'subscription1',
    'purchaseToken': 'mock_subscription_token',
    'orderId': 'SUB_ORDER123',
    'transactionId': 'GPA.SUB-1234',
    'purchaseState': 1,
    'isAcknowledged': false,
    'autoRenewing': true,
  };
}

List<Map<String, dynamic>> _getMockAvailablePurchases() {
  return <Map<String, dynamic>>[
    <String, dynamic>{
      'productId': 'past_product1',
      'purchaseToken': 'past_token1',
      'transactionId': 'GPA.PAST-001',
    },
    <String, dynamic>{
      'productId': 'past_product2',
      'purchaseToken': 'past_token2',
      'transactionId': 'GPA.PAST-002',
    },
  ];
}

List<Map<String, dynamic>> _getMockPurchaseHistory() {
  return <Map<String, dynamic>>[
    <String, dynamic>{
      'productId': 'history_product1',
      'purchaseToken': 'history_token1',
      'transactionId': 'GPA.HIST-001',
      'transactionDate': '2024-01-01T10:00:00Z',
    },
    <String, dynamic>{
      'productId': 'history_product2',
      'purchaseToken': 'history_token2',
      'transactionId': 'GPA.HIST-002',
      'transactionDate': '2024-01-02T10:00:00Z',
    },
    <String, dynamic>{
      'productId': 'history_product3',
      'purchaseToken': 'history_token3',
      'transactionId': 'GPA.HIST-003',
      'transactionDate': '2024-01-03T10:00:00Z',
    },
  ];
}
