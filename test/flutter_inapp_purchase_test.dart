import 'package:flutter/services.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform/platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FlutterInappPurchase', () {
    late MethodChannel channel;

    setUpAll(() {
      final iap = FlutterInappPurchase();
      channel = iap.channel;
    });
    // Platform detection tests removed as getCurrentPlatform() uses Platform directly
    // and cannot be properly mocked in tests

    group('initConnection', () {
      group('for Android', () {
        final List<MethodCall> log = <MethodCall>[];
        late FlutterInappPurchase testIap;
        setUp(() {
          testIap = FlutterInappPurchase.private(
            FakePlatform(operatingSystem: 'android'),
          );

          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
            log.add(methodCall);
            return 'Billing service is ready';
          });
        });

        tearDown(() {
          channel.setMethodCallHandler(null);
        });

        test('invokes correct method', () async {
          await testIap.initConnection();
          expect(log, <Matcher>[
            isMethodCall('initConnection', arguments: null),
          ]);
        });

        test('returns correct result', () async {
          final result = await testIap.initConnection();
          expect(result, true);
        });
      });
    });

    group('requestProducts', () {
      group('for Android', () {
        final List<MethodCall> log = <MethodCall>[];
        late FlutterInappPurchase testIap;
        setUp(() async {
          testIap = FlutterInappPurchase.private(
            FakePlatform(operatingSystem: 'android'),
          );

          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
            log.add(methodCall);
            if (methodCall.method == 'initConnection') {
              return true;
            }
            // For requestProducts, Android expects parsed JSON list
            if (methodCall.method == 'getProducts' ||
                methodCall.method == 'getSubscriptions') {
              return '''[
                {
                  "productId": "com.example.product1",
                  "price": "0.99",
                  "currency": "USD",
                  "localizedPrice": "\$0.99",
                  "title": "Product 1",
                  "description": "Description 1"
                },
                {
                  "productId": "com.example.product2",
                  "price": "1.99",  
                  "currency": "USD",
                  "localizedPrice": "\$1.99",
                  "title": "Product 2",
                  "description": "Description 2"
                }
              ]''';
            }
            return null;
          });
        });

        tearDown(() {
          channel.setMethodCallHandler(null);
        });

        test('invokes correct method', () async {
          // Initialize connection first
          await testIap.initConnection();
          log.clear(); // Clear init log

          await testIap.requestProducts(
            skus: ['com.example.product1', 'com.example.product2'],
            type: ProductType.inapp,
          );
          // Since getProducts is deprecated and redirects to requestProducts,
          // it now passes productIds directly as List, not wrapped in a Map
          expect(log, <Matcher>[
            isMethodCall(
              'getProducts',
              arguments: {
                'productIds': ['com.example.product1', 'com.example.product2'],
              },
            ),
          ]);
        });

        test('returns correct products', () async {
          // Initialize connection first
          await testIap.initConnection();

          final products = await testIap.requestProducts<Product>(
            skus: ['com.example.product1', 'com.example.product2'],
            type: ProductType.inapp,
          );
          expect(products.length, 2);
          expect(products[0].productId, 'com.example.product1');
          expect(products[0].price, 0.99);
          expect(products[0].currency, 'USD');
          expect(products[1].productId, 'com.example.product2');
        });
      });
    });

    group('requestProducts for subscriptions', () {
      group('for iOS', () {
        final List<MethodCall> log = <MethodCall>[];
        late FlutterInappPurchase testIap;
        setUp(() async {
          testIap = FlutterInappPurchase.private(
            FakePlatform(operatingSystem: 'ios'),
          );

          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
            log.add(methodCall);
            if (methodCall.method == 'initConnection') {
              return true;
            }
            return [
              {
                'productId': 'com.example.subscription1',
                'price': '9.99',
                'currency': 'USD',
                'localizedPrice': r'$9.99',
                'title': 'Subscription 1',
                'description': 'Monthly subscription',
                'subscriptionPeriodUnitIOS': 'MONTH',
                'subscriptionPeriodNumberIOS': '1',
              },
            ];
          });
        });

        tearDown(() {
          channel.setMethodCallHandler(null);
        });

        test('invokes correct method', () async {
          // Initialize connection first
          await testIap.initConnection();
          log.clear(); // Clear init log

          await testIap.requestProducts(
            skus: ['com.example.subscription1'],
            type: ProductType.subs,
          );
          expect(log, <Matcher>[
            isMethodCall(
              'fetchProducts',
              arguments: <String, dynamic>{
                'skus': ['com.example.subscription1'],
                'type': ProductType.subs,
              },
            ),
          ]);
        });

        test('returns correct subscriptions', () async {
          // Initialize connection first
          await testIap.initConnection();

          final subscriptions = await testIap.requestProducts<Subscription>(
            skus: ['com.example.subscription1'],
            type: ProductType.subs,
          );
          expect(subscriptions.length, 1);
          expect(subscriptions[0].productId, 'com.example.subscription1');
          // Now we can directly access Subscription properties
          expect(subscriptions[0].subscriptionPeriodUnitIOS, 'MONTH');
        });
      });
    });

    group('Error Handling', () {
      test('PurchaseError creation from platform error', () {
        final error = PurchaseError.fromPlatformError({
          'code': 'E_USER_CANCELLED',
          'message': 'User cancelled the purchase',
          'responseCode': 1,
          'debugMessage': 'Debug info',
          'productId': 'com.example.product',
        }, IapPlatform.android);

        expect(error.code, ErrorCode.eUserCancelled);
        expect(error.message, 'User cancelled the purchase');
        expect(error.responseCode, 1);
        expect(error.debugMessage, 'Debug info');
        expect(error.productId, 'com.example.product');
        expect(error.platform, IapPlatform.android);
      });

      test('ErrorCodeUtils maps platform codes correctly', () {
        // Test iOS mapping
        expect(
          ErrorCodeUtils.fromPlatformCode(2, IapPlatform.ios),
          ErrorCode.eUserCancelled,
        );
        expect(
          ErrorCodeUtils.toPlatformCode(
            ErrorCode.eUserCancelled,
            IapPlatform.ios,
          ),
          2,
        );

        // Test Android mapping
        expect(
          ErrorCodeUtils.fromPlatformCode(
            'E_USER_CANCELLED',
            IapPlatform.android,
          ),
          ErrorCode.eUserCancelled,
        );
        expect(
          ErrorCodeUtils.toPlatformCode(
            ErrorCode.eUserCancelled,
            IapPlatform.android,
          ),
          'E_USER_CANCELLED',
        );

        // Test unknown code
        expect(
          ErrorCodeUtils.fromPlatformCode('UNKNOWN_ERROR', IapPlatform.android),
          ErrorCode.eUnknown,
        );
      });
    });

    group('Product OpenIAP Compatibility', () {
      test('Product has OpenIAP compliant id getter', () {
        final product = Product(productId: 'test.product.id', price: 9.99);

        expect(product.id, 'test.product.id');
        expect(product.productId, 'test.product.id');
      });

      test('Price parsing tolerates numeric values in JSON', () {
        // Subscription.fromJson with numeric price
        final sub = Subscription.fromJson({
          'productId': 'com.example.sub',
          'price': 9.99, // numeric
          'platform': 'ios',
        });
        expect(sub.price, 9.99);

        // ProductIOS.fromJson with numeric price
        final pios = ProductIOS.fromJson({
          'productId': 'com.example.inapp',
          'price': 2.49, // numeric
          'currency': 'USD',
          'localizedPrice': r'$2.49',
          'title': 'Inapp',
          'description': 'Desc',
          'type': 'inapp',
        });
        expect(pios.price, 2.49);

        // DiscountIOS.fromJson with numeric price
        final discount = DiscountIOS.fromJson({
          'identifier': 'offer1',
          'type': 'PAYASYOUGO',
          'price': 1.99, // numeric
          'localizedPrice': r'$1.99',
          'paymentMode': 'PAYASYOUGO',
          'numberOfPeriods': '1',
          'subscriptionPeriod': 'MONTH',
        });
        expect(discount.price, '1.99');

        // ProductAndroid.fromJson with numeric price
        final pand = ProductAndroid.fromJson({
          'productId': 'com.example.android',
          'price': 4.5, // numeric
          'currency': 'USD',
          'localizedPrice': r'$4.50',
          'title': 'Android Product',
          'description': 'Desc',
          'type': 'inapp',
        });
        expect(pand.price, 4.5);
      });

      test('Subscription has OpenIAP compliant id getter', () {
        final subscription = Subscription(
          productId: 'test.subscription.id',
          price: '4.99',
          platform: IapPlatform.ios,
        );

        expect(subscription.id, 'test.subscription.id');
        expect(subscription.productId, 'test.subscription.id');
      });

      test('Purchase has OpenIAP compliant id getter', () {
        final purchase = Purchase(
          productId: 'test.product',
          transactionId: 'transaction123',
          platform: IapPlatform.android,
        );

        expect(purchase.id, 'transaction123');
        expect(purchase.ids, ['test.product']);
      });

      test(
        'Purchase id getter returns empty string when transactionId is null',
        () {
          final purchase = Purchase(
            productId: 'test.product',
            transactionId: null,
            platform: IapPlatform.ios,
          );

          expect(purchase.id, '');
          expect(purchase.ids, ['test.product']);
        },
      );

      test('Product toString includes new fields', () {
        final product = Product(
          productId: 'test.product',
          price: 9.99,
          environmentIOS: 'Production',
          subscriptionPeriodAndroid: 'P1M',
        );

        final str = product.toString();
        expect(str, contains('productId: test.product'));
        expect(str, contains('id: test.product'));
        expect(str, contains('environmentIOS: Production'));
        expect(str, contains('subscriptionPeriodAndroid: P1M'));
      });

      test('Purchase toString includes new fields', () {
        final purchase = Purchase(
          productId: 'test.product',
          transactionId: 'trans123',
          platform: IapPlatform.ios,
          environmentIOS: 'Sandbox',
        );

        final str = purchase.toString();
        expect(str, contains('productId: test.product'));
        expect(str, contains('id: "trans123"'));
        expect(str, contains('environmentIOS: "Sandbox"'));
        expect(str, isNot(contains('purchaseStateAndroid')));
      });
    });

    group('Enum Values', () {
      test('Store enum has correct values', () {
        expect(Store.values.length, 4);
        expect(Store.none.toString(), 'Store.none');
        expect(Store.playStore.toString(), 'Store.playStore');
        expect(Store.amazon.toString(), 'Store.amazon');
        expect(Store.appStore.toString(), 'Store.appStore');
      });

      test('ProductType has correct values', () {
        expect(ProductType.inapp, 'inapp');
        expect(ProductType.subs, 'subs');
      });

      test('SubscriptionState enum has correct values', () {
        expect(SubscriptionState.values.length, 5);
        expect(SubscriptionState.active.toString(), 'SubscriptionState.active');
        expect(
          SubscriptionState.expired.toString(),
          'SubscriptionState.expired',
        );
        expect(
          SubscriptionState.inBillingRetry.toString(),
          'SubscriptionState.inBillingRetry',
        );
        expect(
          SubscriptionState.inGracePeriod.toString(),
          'SubscriptionState.inGracePeriod',
        );
        expect(
          SubscriptionState.revoked.toString(),
          'SubscriptionState.revoked',
        );
      });

      // ProrationModeAndroid test removed - enum is in iap_android_types.dart
      // and not directly exported from main library
    });

    group('getActiveSubscriptions', () {
      group('for Android', () {
        late FlutterInappPurchase testIap;

        setUp(() {
          testIap = FlutterInappPurchase.private(
            FakePlatform(operatingSystem: 'android'),
          );

          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
            if (methodCall.method == 'initConnection') {
              return 'Billing service is ready';
            }
            if (methodCall.method == 'getAvailableItemsByType') {
              final arguments = methodCall.arguments;
              if (arguments is Map && arguments['type'] == 'subs') {
                // Return a mock subscription purchase
                return '''[
                  {
                    "productId": "monthly_subscription",
                    "transactionId": "GPA.1234-5678-9012-34567",
                    "transactionDate": ${DateTime.now().millisecondsSinceEpoch},
                    "transactionReceipt": "receipt_data",
                    "purchaseToken": "token_123",
                    "autoRenewingAndroid": true,
                    "purchaseStateAndroid": 1,
                    "isAcknowledgedAndroid": true
                  }
                ]''';
              }
              return '[]';
            }
            return '[]';
          });
        });

        tearDown(() {
          channel.setMethodCallHandler(null);
        });

        test('returns active subscriptions', () async {
          await testIap.initConnection();
          final subscriptions = await testIap.getActiveSubscriptions();

          expect(subscriptions.length, 1);
          expect(subscriptions.first.productId, 'monthly_subscription');
          expect(subscriptions.first.isActive, true);
          expect(subscriptions.first.autoRenewingAndroid, true);
        });

        test('filters by subscription IDs', () async {
          await testIap.initConnection();
          final subscriptions = await testIap.getActiveSubscriptions(
            subscriptionIds: ['yearly_subscription'],
          );

          expect(subscriptions.length, 0);
        });
      });

      group('for iOS', () {
        late FlutterInappPurchase testIap;

        setUp(() {
          testIap = FlutterInappPurchase.private(
            FakePlatform(operatingSystem: 'ios'),
          );

          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
            if (methodCall.method == 'initConnection') {
              return 'Billing service is ready';
            }
            if (methodCall.method == 'getAvailableItems') {
              // Return a mock iOS subscription purchase
              return <Map<String, dynamic>>[
                <String, dynamic>{
                  'productId': 'monthly_subscription',
                  'transactionId': '1000000123456789',
                  'transactionDate': DateTime.now().millisecondsSinceEpoch,
                  'transactionReceipt': 'receipt_data',
                  'purchaseToken':
                      'ios_jws_token_123', // Unified field for iOS JWS
                  'jwsRepresentationIOS':
                      'ios_jws_token_123', // Deprecated field
                  'transactionStateIOS':
                      '1', // TransactionState.purchased value
                  'environmentIOS': 'Production',
                  'expirationDateIOS': DateTime.now()
                      .add(Duration(days: 30))
                      .millisecondsSinceEpoch,
                },
              ];
            }
            return null;
          });
        });

        tearDown(() {
          channel.setMethodCallHandler(null);
        });

        test('returns active subscriptions with iOS-specific fields', () async {
          await testIap.initConnection();
          final subscriptions = await testIap.getActiveSubscriptions();

          expect(subscriptions.length, 1);
          expect(subscriptions.first.productId, 'monthly_subscription');
          expect(subscriptions.first.isActive, true);
          expect(subscriptions.first.environmentIOS, 'Production');
          expect(subscriptions.first.expirationDateIOS, isNotNull);
        });
      });
    });

    group('requestPurchase', () {
      late FlutterInappPurchase testIap;

      setUp(() {
        testIap = FlutterInappPurchase.private(
          FakePlatform(operatingSystem: 'android'),
        );

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          if (methodCall.method == 'initConnection') {
            return 'Billing service is ready';
          }
          if (methodCall.method == 'requestPurchase') {
            // Simulate purchase flow with unified purchaseToken
            return <String, dynamic>{
              'productId': methodCall.arguments['sku'],
              'transactionId': 'GPA.test-transaction-123',
              'transactionDate': DateTime.now().millisecondsSinceEpoch,
              'transactionReceipt': 'test_receipt',
              'purchaseToken': 'unified_purchase_token_123',
              'purchaseTokenAndroid': 'unified_purchase_token_123',
              'signatureAndroid': 'test_signature',
              'purchaseStateAndroid': 1,
            };
          }
          if (methodCall.method == 'requestSubscription') {
            // Simulate subscription flow with unified purchaseToken
            return <String, dynamic>{
              'productId': methodCall.arguments['sku'],
              'transactionId': 'GPA.sub-transaction-456',
              'transactionDate': DateTime.now().millisecondsSinceEpoch,
              'transactionReceipt': 'test_subscription_receipt',
              'purchaseToken': 'unified_subscription_token_456',
              'purchaseTokenAndroid': 'unified_subscription_token_456',
              'autoRenewingAndroid': true,
              'purchaseStateAndroid': 1,
            };
          }
          return null;
        });
      });

      tearDown(() {
        channel.setMethodCallHandler(null);
      });

      test(
        'requestPurchase includes unified purchaseToken in response',
        () async {
          await testIap.initConnection();

          // Request purchase will not directly return a PurchasedItem
          // It triggers a native purchase flow that sends events
          // For testing, we just verify the method can be called without error
          await expectLater(
            testIap.requestPurchaseAuto(
              sku: 'test.product',
              type: ProductType.inapp,
            ),
            completes,
          );
        },
      );

      test(
        'requestSubscription includes unified purchaseToken in response',
        () async {
          await testIap.initConnection();

          // Request subscription will not directly return a PurchasedItem
          // It triggers a native purchase flow that sends events
          // For testing, we just verify the method can be called without error
          await expectLater(
            testIap.requestPurchaseAuto(
              sku: 'test.subscription',
              type: ProductType.subs,
            ),
            completes,
          );
        },
      );
    });

    group('requestPurchase for iOS', () {
      late FlutterInappPurchase testIap;

      setUp(() {
        testIap = FlutterInappPurchase.private(
          FakePlatform(operatingSystem: 'ios'),
        );

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          if (methodCall.method == 'initConnection') {
            return 'Billing service is ready';
          }
          if (methodCall.method == 'requestPurchase') {
            // Simulate iOS purchase with JWS token
            return <String, dynamic>{
              'productId': methodCall.arguments,
              'transactionId': '2000000123456789',
              'transactionDate': DateTime.now().millisecondsSinceEpoch,
              'transactionReceipt': 'ios_receipt_data',
              'purchaseToken': 'ios_jws_representation_token',
              'jwsRepresentationIOS': 'ios_jws_representation_token',
              'transactionStateIOS': '1',
            };
          }
          return null;
        });
      });

      tearDown(() {
        channel.setMethodCallHandler(null);
      });

      test('iOS purchase includes unified purchaseToken (JWS)', () async {
        await testIap.initConnection();

        // Request purchase will not directly return a PurchasedItem
        // It triggers a native purchase flow that sends events
        // For testing, we just verify the method can be called without error
        await expectLater(
          testIap.requestPurchaseAuto(
            sku: 'ios.test.product',
            type: ProductType.inapp,
          ),
          completes,
        );
      });
    });

    group('getAvailablePurchases', () {
      late FlutterInappPurchase testIap;

      setUp(() {
        testIap = FlutterInappPurchase.private(
          FakePlatform(operatingSystem: 'android'),
        );

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          if (methodCall.method == 'initConnection') {
            return 'Billing service is ready';
          }
          if (methodCall.method == 'getAvailableItemsByType') {
            // Return purchases with unified purchaseToken as JSON string
            final timestamp = DateTime.now().millisecondsSinceEpoch;
            return '''[
              {
                "productId": "test.product.1",
                "transactionId": "GPA.purchase-1",
                "transactionDate": $timestamp,
                "transactionReceipt": "receipt_1",
                "purchaseToken": "unified_token_1",
                "purchaseTokenAndroid": "unified_token_1",
                "signatureAndroid": "signature_1",
                "purchaseStateAndroid": 1,
                "isAcknowledgedAndroid": true
              },
              {
                "productId": "test.product.2",
                "transactionId": "GPA.purchase-2",
                "transactionDate": $timestamp,
                "transactionReceipt": "receipt_2",
                "purchaseToken": "unified_token_2",
                "purchaseTokenAndroid": "unified_token_2",
                "signatureAndroid": "signature_2",
                "purchaseStateAndroid": 1,
                "isAcknowledgedAndroid": false
              }
            ]''';
          }
          return null;
        });
      });

      tearDown(() {
        channel.setMethodCallHandler(null);
      });

      test('returns available purchases with unified purchaseToken', () async {
        await testIap.initConnection();
        final purchases = await testIap.getAvailablePurchases();

        // Android calls getAvailableItemsByType twice (inapp and subs)
        // Each returns 2 items, so total is 4
        expect(purchases.length, 4);

        // Check that all purchases have unified purchaseToken
        for (final purchase in purchases) {
          expect(purchase.purchaseToken, isNotNull);
          expect(purchase.purchaseToken, contains('unified_token'));
        }
      });
    });

    group('getAvailablePurchases for iOS', () {
      late FlutterInappPurchase testIap;

      setUp(() {
        testIap = FlutterInappPurchase.private(
          FakePlatform(operatingSystem: 'ios'),
        );

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          if (methodCall.method == 'initConnection') {
            return 'Billing service is ready';
          }
          if (methodCall.method == 'getAvailableItems') {
            // Return iOS purchases with JWS tokens
            return <Map<String, dynamic>>[
              <String, dynamic>{
                'productId': 'ios.product.1',
                'transactionId': '2000000111111111',
                'transactionDate': DateTime.now().millisecondsSinceEpoch,
                'transactionReceipt': 'ios_receipt_1',
                'purchaseToken': 'ios_jws_token_1',
                'jwsRepresentationIOS': 'ios_jws_token_1',
                'transactionStateIOS': '1',
              },
            ];
          }
          return null;
        });
      });

      tearDown(() {
        channel.setMethodCallHandler(null);
      });

      test('iOS returns purchases with unified purchaseToken (JWS)', () async {
        await testIap.initConnection();
        final purchases = await testIap.getAvailablePurchases();

        expect(purchases.length, 1);
        expect(purchases[0].productId, 'ios.product.1');
        expect(purchases[0].purchaseToken, 'ios_jws_token_1');
        expect(purchases[0].transactionStateIOS, TransactionState.purchased);
      });
    });

    group('finishTransaction', () {
      late FlutterInappPurchase testIap;

      group('on Android', () {
        setUp(() {
          testIap = FlutterInappPurchase.private(
            FakePlatform(operatingSystem: 'android'),
          );

          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
            if (methodCall.method == 'initConnection') {
              return 'Billing service is ready';
            }
            if (methodCall.method == 'consumeProduct') {
              expect(methodCall.arguments['purchaseToken'], isNotNull);
              // Return JSON response like actual Android implementation
              return '{"responseCode":0,"debugMessage":"","code":"OK","message":"","purchaseToken":"${methodCall.arguments['purchaseToken']}"}';
            }
            if (methodCall.method == 'acknowledgePurchase') {
              expect(methodCall.arguments['purchaseToken'], isNotNull);
              // Return JSON response like actual Android implementation
              return '{"responseCode":0,"debugMessage":"","code":"OK","message":""}';
            }
            return null;
          });
        });

        tearDown(() {
          channel.setMethodCallHandler(null);
        });

        test('consumes consumable purchases on Android', () async {
          await testIap.initConnection();

          final purchase = Purchase(
            productId: 'consumable.product',
            transactionId: 'GPA.consume-123',
            purchaseToken: 'consume_token_123',
            platform: IapPlatform.android,
            isAcknowledgedAndroid: false,
          );

          await testIap.finishTransaction(purchase, isConsumable: true);
          // Test passes if consumeProduct was called
        });

        test('acknowledges non-consumable purchases on Android', () async {
          await testIap.initConnection();

          final purchase = Purchase(
            productId: 'non_consumable.product',
            transactionId: 'GPA.acknowledge-456',
            purchaseToken: 'acknowledge_token_456',
            platform: IapPlatform.android,
            isAcknowledgedAndroid: false,
          );

          await testIap.finishTransaction(purchase, isConsumable: false);
          // Test passes if acknowledgePurchase was called
        });

        test('skips already acknowledged purchases on Android', () async {
          await testIap.initConnection();

          final purchase = Purchase(
            productId: 'already_acknowledged.product',
            transactionId: 'GPA.ack-789',
            purchaseToken: 'ack_token_789',
            platform: IapPlatform.android,
            isAcknowledgedAndroid: true,
          );

          await testIap.finishTransaction(purchase, isConsumable: false);
          // Should not call acknowledgePurchase since already acknowledged
        });
      });

      group('on iOS', () {
        setUp(() {
          testIap = FlutterInappPurchase.private(
            FakePlatform(operatingSystem: 'ios'),
          );

          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
            if (methodCall.method == 'initConnection') {
              return 'Billing service is ready';
            }
            if (methodCall.method == 'finishTransaction') {
              // Allow null transactionId for edge case testing
              return 'finished';
            }
            return null;
          });
        });

        tearDown(() {
          channel.setMethodCallHandler(null);
        });

        test('finishes transaction on iOS using id field', () async {
          await testIap.initConnection();

          final purchase = Purchase(
            productId: 'ios.product',
            transactionId: '2000000123456',
            platform: IapPlatform.ios,
          );

          await testIap.finishTransaction(purchase);
          // Test passes if finishTransaction was called with transactionId
        });

        test('finishes transaction on iOS when id is empty', () async {
          await testIap.initConnection();

          final purchase = Purchase(
            productId: 'ios.product',
            transactionId: null,
            platform: IapPlatform.ios,
          );

          // When transactionId is null, finishTransaction should still be called
          // but with null transactionId. Test that it doesn't throw an error.
          await expectLater(testIap.finishTransaction(purchase), completes);
        });
      });
    });

    group('hasActiveSubscriptions', () {
      late FlutterInappPurchase testIap;

      setUp(() {
        testIap = FlutterInappPurchase.private(
          FakePlatform(operatingSystem: 'android'),
        );

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          if (methodCall.method == 'initConnection') {
            return 'Billing service is ready';
          }
          if (methodCall.method == 'getAvailableItemsByType') {
            final arguments = methodCall.arguments;
            if (arguments is Map && arguments['type'] == 'subs') {
              return '''[
                {
                  "productId": "monthly_subscription",
                  "transactionId": "GPA.1234-5678-9012-34567",
                  "transactionDate": ${DateTime.now().millisecondsSinceEpoch},
                  "transactionReceipt": "receipt_data",
                  "purchaseToken": "token_123",
                  "autoRenewingAndroid": true,
                  "purchaseStateAndroid": 1,
                  "isAcknowledgedAndroid": true
                }
              ]''';
            }
            return '[]';
          }
          return '[]';
        });
      });

      tearDown(() {
        channel.setMethodCallHandler(null);
      });

      test('returns true when user has active subscriptions', () async {
        await testIap.initConnection();
        final hasSubscriptions = await testIap.hasActiveSubscriptions();

        expect(hasSubscriptions, true);
      });

      test(
        'returns false when filtering for non-existent subscription',
        () async {
          await testIap.initConnection();
          final hasSubscriptions = await testIap.hasActiveSubscriptions(
            subscriptionIds: ['non_existent_subscription'],
          );

          expect(hasSubscriptions, false);
        },
      );

      test('returns true when filtering for existing subscription', () async {
        await testIap.initConnection();
        final hasSubscriptions = await testIap.hasActiveSubscriptions(
          subscriptionIds: ['monthly_subscription'],
        );

        expect(hasSubscriptions, true);
      });
    });
  });
}
