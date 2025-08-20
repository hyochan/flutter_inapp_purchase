import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_inapp_purchase/types.dart';

void main() {
  group('OpenIAP Extensions Tests', () {
    group('Product Extension', () {
      test('toOpenIapFormat should work for Android Product', () {
        final product = Product(
          productId: 'android_product',
          priceString: '9.99',
          platformEnum: IapPlatform.android,
          nameAndroid: 'Android Product Name',
          oneTimePurchaseOfferDetailsAndroid: {
            'priceAmountMicros': 9990000,
            'priceCurrencyCode': 'USD',
            'formattedPrice': '\$9.99',
          },
        );

        final result = product.toOpenIapFormat();

        expect(result['platform'], 'android');
        expect(result['nameAndroid'], 'Android Product Name');
        expect(result['oneTimePurchaseOfferDetailsAndroid'], isNotNull);

        // Should not contain iOS-specific fields
        expect(result.containsKey('environmentIOS'), false);
        expect(result.containsKey('subscriptionGroupIdIOS'), false);
      });

      test('toOpenIapFormat should work for iOS Product', () {
        final product = Product(
          productId: 'ios_product',
          priceString: '9.99',
          platformEnum: IapPlatform.ios,
          environmentIOS: 'Sandbox',
          subscriptionGroupIdIOS: 'group_123',
          discountsIOS: [],
        );

        final result = product.toOpenIapFormat();

        expect(result['platform'], 'ios');
        expect(result['environmentIOS'], 'Sandbox');
        expect(result['subscriptionGroupIdIOS'], 'group_123');
        expect(result['discountsIOS'], isA<List<dynamic>>());

        // Should not contain Android-specific fields
        expect(result.containsKey('nameAndroid'), false);
        expect(result.containsKey('oneTimePurchaseOfferDetailsAndroid'), false);
      });

      test('toExpoIapFormat should be alias for toOpenIapFormat', () {
        final product = Product(
          productId: 'test_product',
          priceString: '5.99',
          platformEnum: IapPlatform.ios,
        );

        final openIapResult = product.toOpenIapFormat();
        final expoResult = product.toExpoIapFormat();

        expect(expoResult, equals(openIapResult));
      });
    });

    group('Subscription Extension', () {
      test('toOpenIapFormat should work for Android Subscription', () {
        final subscription = Subscription(
          productId: 'android_sub',
          price: '9.99',
          platform: IapPlatform.android,
          nameAndroid: 'Android Subscription',
          subscriptionOfferDetailsAndroid: [
            OfferDetail(
              basePlanId: 'monthly',
              pricingPhases: [
                PricingPhase(
                  priceAmount: 9.99,
                  price: '9.99',
                  currency: 'USD',
                  billingPeriod: 'P1M',
                ),
              ],
            ),
          ],
        );

        final result = subscription.toOpenIapFormat();

        expect(result['platform'], 'android');
        expect(result['type'], 'subs');
        expect(result['nameAndroid'], 'Android Subscription');
        expect(result['subscriptionOfferDetailsAndroid'], isA<List<dynamic>>());

        // Should not contain iOS-specific fields
        expect(result.containsKey('environmentIOS'), false);
      });

      test('toOpenIapFormat should work for iOS Subscription', () {
        final subscription = Subscription(
          productId: 'ios_sub',
          price: '9.99',
          platform: IapPlatform.ios,
          environmentIOS: 'Production',
          subscriptionGroupIdIOS: 'ios_group_456',
          discountsIOS: [],
        );

        final result = subscription.toOpenIapFormat();

        expect(result['platform'], 'ios');
        expect(result['type'], 'subs');
        expect(result['environmentIOS'], 'Production');
        expect(result['subscriptionGroupIdIOS'], 'ios_group_456');
        expect(result['discountsIOS'], isA<List<dynamic>>());

        // Should not contain Android-specific fields
        expect(result.containsKey('nameAndroid'), false);
      });
    });

    group('Purchase Extension', () {
      test('toOpenIapFormat should work for Android Purchase', () {
        final purchase = Purchase(
          productId: 'android_product',
          platform: IapPlatform.android,
          transactionId: 'GPA.123456789',
          purchaseToken: 'android_token',
          dataAndroid: '{"test": "android_data"}',
          signatureAndroid: 'android_signature',
          purchaseStateAndroid: 1,
          isAcknowledgedAndroid: true,
        );

        final result = purchase.toOpenIapFormat();

        expect(result['platform'], 'android');
        expect(result['id'], purchase.id);
        expect(result['ids'], purchase.ids);
        expect(result['dataAndroid'], '{"test": "android_data"}');
        expect(result['signatureAndroid'], 'android_signature');
        expect(result['purchaseStateAndroid'], 1);
        expect(result['isAcknowledgedAndroid'], true);

        // Should not contain iOS-specific fields
        expect(result.containsKey('quantityIOS'), false);
        expect(result.containsKey('environmentIOS'), false);
      });

      test('toOpenIapFormat should work for iOS Purchase', () {
        final purchase = Purchase(
          productId: 'ios_product',
          platform: IapPlatform.ios,
          transactionId: '2000000123456789',
          quantityIOS: 2,
          originalTransactionDateIOS: '2023-08-20T10:00:00Z',
          environmentIOS: 'Production',
          currencyCodeIOS: 'USD',
          priceIOS: 9.99,
          appBundleIdIOS: 'com.example.ios.app',
        );

        final result = purchase.toOpenIapFormat();

        expect(result['platform'], 'ios');
        expect(result['id'], purchase.id);
        expect(result['ids'], purchase.ids);
        expect(result['quantityIOS'], 2);
        expect(result['originalTransactionDateIOS'], '2023-08-20T10:00:00Z');
        expect(result['environmentIOS'], 'Production');
        expect(result['currencyCodeIOS'], 'USD');
        expect(result['priceIOS'], 9.99);
        expect(result['appBundleIdIOS'], 'com.example.ios.app');

        // Should not contain Android-specific fields
        expect(result.containsKey('dataAndroid'), false);
        expect(result.containsKey('signatureAndroid'), false);
      });

      test('Purchase should handle empty transactionId correctly', () {
        final purchase = Purchase(
          productId: 'test_product',
          platform: IapPlatform.android,
          transactionId: null,
        );

        final result = purchase.toOpenIapFormat();

        expect(result['id'], purchase.id); // Should be empty string from getter
        expect(result['ids'], purchase.ids); // Should be [productId]
      });

      test('toExpoIapFormat should be alias for toOpenIapFormat', () {
        final purchase = Purchase(
          productId: 'test_product',
          platform: IapPlatform.android,
          transactionId: 'test_123',
        );

        final openIapResult = purchase.toOpenIapFormat();
        final expoResult = purchase.toExpoIapFormat();

        expect(expoResult, equals(openIapResult));
      });
    });

    group('Platform Field Filtering', () {
      test('should remove all Android fields from iOS products', () {
        final product = Product(
          productId: 'mixed_product',
          priceString: '9.99',
          platformEnum: IapPlatform.ios,
          // iOS fields
          environmentIOS: 'Sandbox',
          // These would normally not be set together, but testing filtering
          nameAndroid: 'Should be removed',
        );

        final result = product.toOpenIapFormat();

        expect(result['platform'], 'ios');
        expect(result['environmentIOS'], 'Sandbox');
        expect(result.containsKey('nameAndroid'), false);
      });

      test('should remove all iOS fields from Android products', () {
        final product = Product(
          productId: 'mixed_product',
          priceString: '9.99',
          platformEnum: IapPlatform.android,
          // Android fields
          nameAndroid: 'Android Name',
          // These would normally not be set together, but testing filtering
          environmentIOS: 'Should be removed',
        );

        final result = product.toOpenIapFormat();

        expect(result['platform'], 'android');
        expect(result['nameAndroid'], 'Android Name');
        expect(result.containsKey('environmentIOS'), false);
      });
    });
  });
}
