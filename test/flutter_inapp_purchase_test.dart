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

    group('getProducts', () {
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
            // For Android, return JSON string
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
          });
        });

        tearDown(() {
          channel.setMethodCallHandler(null);
        });

        test('invokes correct method', () async {
          await testIap.getProducts([
            'com.example.product1',
            'com.example.product2',
          ]);
          expect(log, <Matcher>[
            isMethodCall(
              'getProducts',
              arguments: <String, dynamic>{
                'productIds': ['com.example.product1', 'com.example.product2'],
              },
            ),
          ]);
        });

        test('returns correct products', () async {
          final products = await testIap.getProducts([
            'com.example.product1',
            'com.example.product2',
          ]);
          expect(products.length, 2);
          expect(products[0].productId, 'com.example.product1');
          expect(products[0].price, '0.99');
          expect(products[0].currency, 'USD');
          expect(products[1].productId, 'com.example.product2');
        });
      });
    });

    group('getSubscriptions', () {
      group('for iOS', () {
        final List<MethodCall> log = <MethodCall>[];
        late FlutterInappPurchase testIap;
        setUp(() {
          testIap = FlutterInappPurchase.private(
            FakePlatform(operatingSystem: 'ios'),
          );

          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
            log.add(methodCall);
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
          await testIap.getSubscriptions(['com.example.subscription1']);
          expect(log, <Matcher>[
            isMethodCall(
              'getItems',
              arguments: <String, dynamic>{
                'skus': ['com.example.subscription1'],
              },
            ),
          ]);
        });

        test('returns correct subscriptions', () async {
          final subscriptions = await testIap.getSubscriptions([
            'com.example.subscription1',
          ]);
          expect(subscriptions.length, 1);
          expect(subscriptions[0].productId, 'com.example.subscription1');
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

    group('Type Conversions', () {
      test('IAPItem conversion preserves all fields', () {
        final jsonData = {
          'productId': 'test.product',
          'price': '1.99',
          'currency': 'USD',
          'localizedPrice': r'$1.99',
          'title': 'Test Product',
          'description': 'Test Description',
          'type': 'inapp',
          'iconUrl': 'https://example.com/icon.png',
          'originalJson': '{}',
          'originalPrice': '1.99',
          'discounts': <dynamic>[],
        };

        final item = IAPItem.fromJSON(jsonData);
        expect(item.productId, 'test.product');
        expect(item.price, '1.99');
        expect(item.currency, 'USD');
        expect(item.localizedPrice, r'$1.99');
        expect(item.title, 'Test Product');
        expect(item.description, 'Test Description');
        // type field was removed in refactoring
        expect(item.iconUrl, 'https://example.com/icon.png');
      });

      test('PurchasedItem conversion handles all fields', () {
        final jsonData = {
          'productId': 'test.product',
          'transactionId': 'trans123',
          'transactionDate': 1234567890,
          'transactionReceipt': 'receipt_data',
          'purchaseToken': 'token123',
          'orderId': 'order123',
          'dataAndroid': 'android_data',
          'signatureAndroid': 'signature',
          'isAcknowledgedAndroid': true,
          'purchaseStateAndroid': 1,
          'originalTransactionDateIOS': 1234567890,
          'originalTransactionIdentifierIOS': 'orig_trans123',
        };

        final item = PurchasedItem.fromJSON(jsonData);
        expect(item.productId, 'test.product');
        expect(item.transactionId, 'trans123');
        expect(
          item.transactionDate,
          DateTime.fromMillisecondsSinceEpoch(1234567890),
        );
        expect(item.transactionReceipt, 'receipt_data');
        expect(item.purchaseToken, 'token123');
        // orderId field was removed in refactoring
        expect(item.isAcknowledgedAndroid, true);
      });

      test('PurchasedItem handles unified purchaseToken field', () {
        // Test with purchaseToken field present
        final jsonDataWithToken = {
          'productId': 'test.product',
          'transactionId': '2000000985615347',
          'transactionDate': 1234567890,
          'transactionReceipt': 'receipt_data',
          'purchaseToken': 'unified_token_123',
        };

        final item = PurchasedItem.fromJSON(jsonDataWithToken);
        expect(item.productId, 'test.product');
        expect(item.purchaseToken, 'unified_token_123');
        expect(item.transactionId, '2000000985615347');
        expect(item.id, '2000000985615347'); // OpenIAP compliance
      });

      test('PurchasedItem OpenIAP id field fallback', () {
        // Test id field fallback to transactionId for OpenIAP compliance
        final jsonData = {
          'productId': 'test.product',
          'transactionId': 'fallback_transaction_id',
          'transactionDate': 1234567890,
          'transactionReceipt': 'receipt_data',
        };

        final item = PurchasedItem.fromJSON(jsonData);
        expect(item.id, 'fallback_transaction_id');
        expect(item.transactionId, 'fallback_transaction_id');
      });

      test('PurchasedItem handles missing token fields gracefully', () {
        final jsonDataWithoutTokens = {
          'productId': 'product.without.tokens',
          'transactionId': 'trans_no_tokens',
          'transactionDate': 1234567890,
          'transactionReceipt': 'receipt_data',
        };

        final item = PurchasedItem.fromJSON(jsonDataWithoutTokens);
        expect(item.productId, 'product.without.tokens');
        expect(item.purchaseToken, isNull);
        expect(item.transactionId, 'trans_no_tokens');
        expect(item.id, 'trans_no_tokens');
      });

      test('PurchasedItem date parsing handles different formats', () {
        // Test millisecond timestamp
        final jsonWithMillis = {
          'productId': 'test.product.millis',
          'transactionDate': 1234567890123, // Large number (milliseconds)
        };
        
        final itemMillis = PurchasedItem.fromJSON(jsonWithMillis);
        expect(itemMillis.transactionDate, 
               DateTime.fromMillisecondsSinceEpoch(1234567890123));

        // Test smaller timestamp (seconds)
        final jsonWithSeconds = {
          'productId': 'test.product.seconds',
          'transactionDate': 1234567890, // Smaller number
        };
        
        final itemSeconds = PurchasedItem.fromJSON(jsonWithSeconds);
        expect(itemSeconds.transactionDate, isNotNull);

        // Test string date
        final jsonWithString = {
          'productId': 'test.product.string',
          'transactionDate': '2023-01-01T00:00:00Z',
        };
        
        final itemString = PurchasedItem.fromJSON(jsonWithString);
        expect(itemString.transactionDate, isNotNull);
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

      test('PurchaseType enum has correct values', () {
        expect(PurchaseType.values.length, 2);
        expect(PurchaseType.inapp.toString(), 'PurchaseType.inapp');
        expect(PurchaseType.subs.toString(), 'PurchaseType.subs');
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

      test('ProrationMode enum has correct values', () {
        expect(ProrationMode.values.length, 5);
        expect(
          ProrationMode.immediateWithTimeProration.toString(),
          'ProrationMode.immediateWithTimeProration',
        );
        expect(
          ProrationMode.immediateAndChargeProratedPrice.toString(),
          'ProrationMode.immediateAndChargeProratedPrice',
        );
        expect(
          ProrationMode.immediateWithoutProration.toString(),
          'ProrationMode.immediateWithoutProration',
        );
        expect(ProrationMode.deferred.toString(), 'ProrationMode.deferred');
        expect(
          ProrationMode.immediateAndChargeFullPrice.toString(),
          'ProrationMode.immediateAndChargeFullPrice',
        );
      });
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
                    "purchaseStateAndroid": 0,
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
              return [
                {
                  'productId': 'monthly_subscription',
                  'transactionId': '1000000123456789',
                  'transactionDate': DateTime.now().millisecondsSinceEpoch,
                  'transactionReceipt': 'receipt_data',
                  'transactionStateIOS':
                      '1', // TransactionState.purchased value
                }
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
          expect(subscriptions.first.daysUntilExpirationIOS, isNotNull);
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
                  "purchaseStateAndroid": 0,
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

      test('returns false when filtering for non-existent subscription',
          () async {
        await testIap.initConnection();
        final hasSubscriptions = await testIap.hasActiveSubscriptions(
          subscriptionIds: ['non_existent_subscription'],
        );

        expect(hasSubscriptions, false);
      });

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
