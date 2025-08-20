import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_inapp_purchase/types.dart';

void main() {
  group('OpenIAP Type Alignment Tests', () {
    group('Product Type Alignment', () {
      test('Product should have OpenIAP compliant id getter', () {
        final product = Product(
          productId: 'test_product',
          priceString: '9.99',
          platformEnum: IapPlatform.android,
        );

        // OpenIAP spec: Product should have id field that maps to productId
        expect(product.id, 'test_product');
        expect(product.productId, 'test_product');
      });

      test('Product should have required OpenIAP fields', () {
        final product = Product(
          productId: 'test_product',
          title: 'Test Product',
          description: 'Test Description',
          type: 'inapp',
          displayPrice: '\$9.99',
          currency: 'USD',
          price: 9.99,
          platformEnum: IapPlatform.android,
        );

        expect(product.id, isA<String>());
        expect(product.title, isA<String?>());
        expect(product.description, isA<String?>());
        expect(product.type, isA<String>());
        expect(product.displayPrice, isA<String>());
        expect(product.currency, isA<String?>());
        expect(product.price, isA<double?>());
      });

      test('Android Product should have platform-specific fields', () {
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

        expect(product.nameAndroid, isA<String?>());
        expect(product.oneTimePurchaseOfferDetailsAndroid,
            isA<Map<String, dynamic>?>());
        expect(product.platformEnum, IapPlatform.android);
      });

      test('iOS Product should have platform-specific fields', () {
        final product = Product(
          productId: 'ios_product',
          priceString: '9.99',
          platformEnum: IapPlatform.ios,
          environmentIOS: 'Sandbox',
          subscriptionGroupIdIOS: 'group_123',
          promotionalOfferIdsIOS: ['offer1', 'offer2'],
        );

        expect(product.environmentIOS, isA<String?>());
        expect(product.subscriptionGroupIdIOS, isA<String?>());
        expect(product.promotionalOfferIdsIOS, isA<List<String>?>());
        expect(product.platformEnum, IapPlatform.ios);
      });
    });

    group('Subscription Type Alignment', () {
      test('Subscription should have OpenIAP compliant id and ids getters', () {
        final subscription = Subscription(
          productId: 'test_sub',
          price: '9.99',
          platform: IapPlatform.android,
        );

        // OpenIAP spec: Subscription should have id field that maps to productId
        expect(subscription.id, 'test_sub');
        expect(subscription.ids, ['test_sub']);
      });

      test('Android Subscription should have offer details structure', () {
        final subscription = Subscription(
          productId: 'android_sub',
          price: '9.99',
          platform: IapPlatform.android,
          subscriptionOfferDetailsAndroid: [
            OfferDetail(
              basePlanId: 'monthly',
              offerId: 'intro_offer',
              pricingPhases: [
                PricingPhase(
                  priceAmount: 0.99,
                  price: '0.99',
                  currency: 'USD',
                  billingPeriod: 'P1M',
                  billingCycleCount: 3,
                  recurrenceMode: RecurrenceMode.finiteRecurring,
                ),
              ],
            ),
          ],
        );

        expect(subscription.subscriptionOfferDetailsAndroid,
            isA<List<OfferDetail>?>());
        final offer = subscription.subscriptionOfferDetailsAndroid!.first;
        expect(offer.basePlanId, 'monthly');
        expect(offer.offerId, 'intro_offer');
        expect(offer.pricingPhases, isA<List<PricingPhase>>());
      });
    });

    group('Purchase Type Alignment', () {
      test('Purchase should have OpenIAP compliant id and ids getters', () {
        final purchase = Purchase(
          productId: 'test_product',
          platform: IapPlatform.android,
          transactionId: 'txn_123',
        );

        // OpenIAP spec: Purchase should have id field for transaction identifier
        expect(purchase.id, 'txn_123');
        expect(purchase.ids, ['test_product']);
      });

      test('Android Purchase should have platform-specific fields', () {
        final purchase = Purchase(
          productId: 'android_product',
          platform: IapPlatform.android,
          transactionId: 'GPA.123456789',
          purchaseToken: 'android_token',
          dataAndroid: '{"test": "data"}',
          signatureAndroid: 'signature_123',
          purchaseStateAndroid: 1,
          isAcknowledgedAndroid: true,
          packageNameAndroid: 'com.example.app',
          obfuscatedAccountIdAndroid: 'account_123',
        );

        expect(purchase.dataAndroid, isA<String?>());
        expect(purchase.signatureAndroid, isA<String?>());
        expect(purchase.purchaseStateAndroid, isA<int?>());
        expect(purchase.isAcknowledgedAndroid, isA<bool?>());
        expect(purchase.packageNameAndroid, isA<String?>());
        expect(purchase.obfuscatedAccountIdAndroid, isA<String?>());
      });

      test('iOS Purchase should have platform-specific fields', () {
        final purchase = Purchase(
          productId: 'ios_product',
          platform: IapPlatform.ios,
          transactionId: '2000000123456789',
          quantityIOS: 1,
          originalTransactionDateIOS: '2023-08-20T10:00:00Z',
          originalTransactionIdentifierIOS: '2000000000000001',
          environmentIOS: 'Production',
          currencyCodeIOS: 'USD',
          priceIOS: 9.99,
          appBundleIdIOS: 'com.example.ios.app',
          productTypeIOS: 'Auto-Renewable Subscription',
          transactionReasonIOS: 'PURCHASE',
        );

        expect(purchase.quantityIOS, isA<int?>());
        expect(purchase.originalTransactionDateIOS, isA<String?>());
        expect(purchase.originalTransactionIdentifierIOS, isA<String?>());
        expect(purchase.environmentIOS, isA<String?>());
        expect(purchase.currencyCodeIOS, isA<String?>());
        expect(purchase.priceIOS, isA<double?>());
        expect(purchase.appBundleIdIOS, isA<String?>());
        expect(purchase.productTypeIOS, isA<String?>());
        expect(purchase.transactionReasonIOS, isA<String?>());
      });
    });

    group('Pricing and Offer Type Alignment', () {
      test('PricingPhase should match OpenIAP structure', () {
        final phase = PricingPhase(
          priceAmount: 9.99,
          price: '9.99',
          currency: 'USD',
          billingPeriod: 'P1M',
          billingCycleCount: 1,
          recurrenceMode: RecurrenceMode.infiniteRecurring,
        );

        expect(phase.priceAmount, isA<double>());
        expect(phase.price, isA<String>());
        expect(phase.currency, isA<String>());
        expect(phase.billingPeriod, isA<String?>());
        expect(phase.billingCycleCount, isA<int?>());
        expect(phase.recurrenceMode, isA<RecurrenceMode?>());
      });

      test('OfferDetail should have nested pricingPhases structure', () {
        final offer = OfferDetail(
          basePlanId: 'monthly_base',
          offerId: 'intro_offer',
          pricingPhases: [
            PricingPhase(
              priceAmount: 0.99,
              price: '0.99',
              currency: 'USD',
              billingPeriod: 'P1W',
            ),
          ],
        );

        final json = offer.toJson();

        // Should match TypeScript structure with nested pricingPhases
        expect(json['basePlanId'], 'monthly_base');
        expect(json['offerId'], 'intro_offer');
        expect(json['pricingPhases'], isA<Map<String, dynamic>>());
        expect(json['pricingPhases']['pricingPhaseList'], isA<List<dynamic>>());

        final phases =
            json['pricingPhases']['pricingPhaseList'] as List<dynamic>;
        expect(phases.length, 1);

        final phase = phases.first as Map<String, dynamic>;
        expect(phase['priceAmountMicros'], isA<String>());
        expect(phase['formattedPrice'], '0.99');
        expect(phase['priceCurrencyCode'], 'USD');
        expect(phase['billingPeriod'], 'P1W');
      });
    });

    group('Error Code Type Alignment', () {
      test('ErrorCode enum should match OpenIAP specification', () {
        // Test that our ErrorCode enum has the expected OpenIAP values
        expect(ErrorCode.eUnknown, isA<ErrorCode>());
        expect(ErrorCode.eUserCancelled, isA<ErrorCode>());
        expect(ErrorCode.eUserError, isA<ErrorCode>());
        expect(ErrorCode.eItemUnavailable, isA<ErrorCode>());
        expect(ErrorCode.eProductNotAvailable, isA<ErrorCode>());
        expect(ErrorCode.eProductAlreadyOwned, isA<ErrorCode>());
        expect(ErrorCode.eNetworkError, isA<ErrorCode>());
        expect(ErrorCode.eAlreadyOwned, isA<ErrorCode>());
      });

      test('PurchaseError should have OpenIAP compliant structure', () {
        final error = PurchaseError(
          code: ErrorCode.eUserCancelled,
          message: 'User cancelled the purchase',
          platform: IapPlatform.android,
          responseCode: 6,
        );

        expect(error.code, isA<ErrorCode>());
        expect(error.message, isA<String>());
        expect(error.platform, isA<IapPlatform>());
        expect(error.responseCode, isA<int?>());
      });
    });

    group('Platform Enum Alignment', () {
      test('IapPlatform should have correct string representations', () {
        expect(IapPlatform.android.toString(), contains('android'));
        expect(IapPlatform.ios.toString(), contains('ios'));
      });

      test('Product types should be OpenIAP compliant', () {
        expect(ProductType.inapp, 'inapp');
        expect(ProductType.subs, 'subs');
      });

      test('RecurrenceMode should match OpenIAP enum', () {
        expect(RecurrenceMode.infiniteRecurring, isA<RecurrenceMode>());
        expect(RecurrenceMode.finiteRecurring, isA<RecurrenceMode>());
        expect(RecurrenceMode.nonRecurring, isA<RecurrenceMode>());
      });
    });
  });
}
