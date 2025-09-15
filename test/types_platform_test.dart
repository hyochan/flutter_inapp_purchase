import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_inapp_purchase/types.dart';

void main() {
  group('Platform-specific Types Coverage', () {
    group('Product toJson platform checks', () {
      test('should include Android fields only on Android platform', () {
        final product = Product(
          id: 'android_product',
          priceString: '9.99',
          currency: 'USD',
          platformEnum: IapPlatform.android,
          nameAndroid: 'Android Product Name',
          oneTimePurchaseOfferDetailsAndroid: {
            'priceAmountMicros': 9990000,
            'priceCurrencyCode': 'USD',
            'formattedPrice': '\$9.99',
          },
        );

        final json = product.toJson();

        // Should include Android fields
        expect(json['platform'], 'android');
        expect(json['nameAndroid'], 'Android Product Name');
        expect(json['oneTimePurchaseOfferDetailsAndroid'], isNotNull);

        // Should NOT include iOS fields
        expect(json.containsKey('environmentIOS'), false);
        expect(json.containsKey('subscriptionGroupIdIOS'), false);
      });

      test('should include iOS fields only on iOS platform', () {
        final product = Product(
          id: 'ios_product',
          priceString: '9.99',
          currency: 'USD',
          platformEnum: IapPlatform.ios,
          environmentIOS: 'Sandbox',
          subscriptionGroupIdIOS: 'group_123',
          promotionalOfferIdsIOS: ['promo1', 'promo2'],
        );

        final json = product.toJson();

        // Should include iOS fields
        expect(json['platform'], 'ios');
        expect(json['environmentIOS'], 'Sandbox');
        expect(json['subscriptionGroupIdIOS'], 'group_123');
        expect(json['promotionalOfferIdsIOS'], ['promo1', 'promo2']);

        // Should NOT include Android fields
        expect(json.containsKey('nameAndroid'), false);
        expect(json.containsKey('oneTimePurchaseOfferDetailsAndroid'), false);
      });
    });

    group('Subscription platform checks', () {
      test('should handle subscription offer details on Android platform', () {
        final subscription = ProductSubscription(
          id: 'android_sub',
          price: '9.99',
          currency: 'USD',
          platform: IapPlatform.android,
          subscriptionOfferDetailsAndroid: [
            OfferDetail(
              offerId: 'offer_123',
              basePlanId: 'base_plan_monthly',
              pricingPhases: [],
            ),
          ],
        );

        final json = subscription.toJson();
        expect(json['platform'], 'android');
        expect(json['subscriptionOfferDetailsAndroid'], isNotNull);
      });

      test('should handle iOS subscription fields', () {
        final subscription = ProductSubscription(
          id: 'ios_sub',
          price: '9.99',
          currency: 'USD',
          platform: IapPlatform.ios,
          environmentIOS: 'Production',
          subscriptionGroupIdIOS: 'ios_group_456',
        );

        final json = subscription.toJson();
        expect(json['platform'], 'ios');
        expect(json['environmentIOS'], 'Production');
        expect(json['subscriptionGroupIdIOS'], 'ios_group_456');
      });
    });

    group('OfferDetail and PricingPhase', () {
      test('should create OfferDetail with required fields', () {
        final offer = OfferDetail(
          offerId: 'test_offer',
          basePlanId: 'monthly_base',
          pricingPhases: [
            PricingPhase(
              priceAmount: 9.99,
              price: '9.99',
              currency: 'USD',
              billingPeriod: 'P1M',
            ),
          ],
        );

        expect(offer.offerId, 'test_offer');
        expect(offer.basePlanId, 'monthly_base');
        expect(offer.pricingPhases.length, 1);
        expect(offer.pricingPhases.first.priceAmount, 9.99);
      });

      test('should convert OfferDetail to JSON', () {
        final offer = OfferDetail(
          offerId: 'json_offer',
          basePlanId: 'base_monthly',
          pricingPhases: [
            PricingPhase(
              priceAmount: 5.99,
              price: '5.99',
              currency: 'EUR',
              billingPeriod: 'P1M',
              billingCycleCount: 1,
            ),
          ],
        );

        final json = offer.toJson();
        expect(json['offerId'], 'json_offer');
        expect(json['basePlanId'], 'base_monthly');
        expect(json['pricingPhases'], isA<Map<String, dynamic>>());
        expect(json['pricingPhases']['pricingPhaseList'], isA<List<dynamic>>());
        expect((json['pricingPhases']['pricingPhaseList'] as List).length, 1);
      });

      test('should create PricingPhase with all fields', () {
        final phase = PricingPhase(
          priceAmount: 7.99,
          price: '7.99',
          currency: 'GBP',
          billingPeriod: 'P3M',
          billingCycleCount: 4,
          recurrenceMode: RecurrenceMode.finiteRecurring,
        );

        expect(phase.priceAmount, 7.99);
        expect(phase.price, '7.99');
        expect(phase.currency, 'GBP');
        expect(phase.billingPeriod, 'P3M');
        expect(phase.billingCycleCount, 4);
        expect(phase.recurrenceMode, RecurrenceMode.finiteRecurring);
      });

      test('should parse OfferDetail from JSON with nested structure', () {
        final json = {
          'offerId': 'parsed_offer',
          'basePlanId': 'parsed_base',
          'pricingPhases': [
            {
              'priceAmount': 12.99,
              'price': '12.99',
              'currency': 'CAD',
              'billingPeriod': 'P1Y',
              'billingCycleCount': 1,
            },
          ],
        };

        final offer = OfferDetail.fromJson(json);
        expect(offer.offerId, 'parsed_offer');
        expect(offer.basePlanId, 'parsed_base');
        expect(offer.pricingPhases.length, 1);
        expect(offer.pricingPhases.first.priceAmount, 12.99);
        expect(offer.pricingPhases.first.currency, 'CAD');
      });
    });

    group('Purchase platform checks', () {
      test('Purchase toString should show Android fields only on Android', () {
        final purchase = Purchase(
          productId: 'android_purchase',
          platform: IapPlatform.android,
          transactionId: 'GPA.123456789',
          purchaseToken: 'android_token',
          dataAndroid: '{"test": "android_data"}',
          signatureAndroid: 'android_signature',
          purchaseStateAndroid: 1,
          isAcknowledgedAndroid: true,
          autoRenewingAndroid: false,
          packageNameAndroid: 'com.example.app',
          orderIdAndroid: 'GPA.ORDER.123',
          obfuscatedAccountIdAndroid: 'account_123',
          obfuscatedProfileIdAndroid: 'profile_456',
        );

        final result = purchase.toString();

        // Should include Android-specific fields
        expect(result, contains('android'));
        expect(result, contains('dataAndroid'));
        expect(result, contains('signatureAndroid'));
        expect(result, contains('purchaseStateAndroid'));
        expect(result, contains('isAcknowledgedAndroid'));
        expect(result, contains('autoRenewingAndroid'));
        expect(result, contains('packageNameAndroid'));
        expect(result, contains('orderIdAndroid'));
        expect(result, contains('obfuscatedAccountIdAndroid'));
        expect(result, contains('obfuscatedProfileIdAndroid'));

        // Should NOT include iOS-specific fields in output
        expect(result, isNot(contains('environmentIOS')));
        expect(result, isNot(contains('transactionStateIOS')));
      });

      test('Purchase toString should show iOS fields only on iOS', () {
        final purchase = Purchase(
          productId: 'ios_purchase',
          platform: IapPlatform.ios,
          transactionId: '2000000123456789',
          purchaseToken: 'ios_jws_token',
          originalTransactionDateIOS: '2023-08-20T10:00:00Z',
          originalTransactionIdentifierIOS: '2000000000000001',
          isUpgradeIOS: false,
          transactionStateIOS: TransactionState.purchased,
          environmentIOS: 'Production',
          expirationDateIOS: DateTime.now().add(const Duration(days: 30)),
          subscriptionGroupIdIOS: 'ios_group_789',
          isUpgradedIOS: false,
          offerCodeRefNameIOS: 'SUMMER2023',
          offerIdentifierIOS: 'summer_discount',
          storeFrontIOS: 'USA',
          storeFrontCountryCodeIOS: 'US',
          currencyCodeIOS: 'USD',
          priceIOS: 9.99,
          quantityIOS: 1,
          appBundleIdIOS: 'com.example.ios.app',
          productTypeIOS: 'Auto-Renewable Subscription',
          ownershipTypeIOS: 'PURCHASED',
          transactionReasonIOS: 'PURCHASE',
          reasonIOS: 'PURCHASE',
          webOrderLineItemIdIOS: 'WEB.ORDER.123',
        );

        final result = purchase.toString();

        // Should include iOS-specific fields
        expect(result, contains('ios'));
        expect(result, contains('originalTransactionDateIOS'));
        expect(result, contains('originalTransactionIdentifierIOS'));
        expect(result, contains('transactionStateIOS'));
        expect(result, contains('environmentIOS'));
        expect(result, contains('subscriptionGroupIdIOS'));
        expect(result, contains('quantityIOS'));
        expect(result, contains('appBundleIdIOS'));
        expect(result, contains('productTypeIOS'));
        expect(result, contains('ownershipTypeIOS'));
        expect(result, contains('transactionReasonIOS'));
        expect(result, contains('webOrderLineItemIdIOS'));
        expect(result, contains('storefrontCountryCodeIOS'));

        // Should NOT include Android-specific fields in output
        expect(result, isNot(contains('dataAndroid')));
        expect(result, isNot(contains('signatureAndroid')));
      });

      test('Purchase id and ids getters should work correctly', () {
        final purchase = Purchase(
          productId: 'test_product',
          platform: IapPlatform.android,
          transactionId: 'test_transaction_123',
        );

        // OpenIAP compliant getters
        expect(purchase.id, 'test_transaction_123');
        expect(purchase.ids, ['test_product']);
      });

      test('Purchase with empty transactionId should return empty id', () {
        final purchase = Purchase(
          productId: 'test_product',
          platform: IapPlatform.android,
          transactionId: null,
        );

        expect(purchase.id, '');
        expect(purchase.ids, ['test_product']);
      });
    });

    group('DiscountIOS tests', () {
      test('should create DiscountIOS with all fields', () {
        final discount = DiscountIOS(
          identifier: 'intro_offer',
          type: 'introductory',
          numberOfPeriods: '3',
          price: '1.99',
          localizedPrice: '\$1.99',
          paymentMode: 'payUpFront',
          subscriptionPeriod: 'P1M',
        );

        expect(discount.identifier, 'intro_offer');
        expect(discount.type, 'introductory');
        expect(discount.numberOfPeriods, '3');
        expect(discount.price, '1.99');
        expect(discount.localizedPrice, '\$1.99');
        expect(discount.paymentMode, 'payUpFront');
        expect(discount.subscriptionPeriod, 'P1M');
      });

      test('should convert DiscountIOS to JSON', () {
        final discount = DiscountIOS(
          identifier: 'promo_offer',
          type: 'promotional',
          numberOfPeriods: '1',
          price: '0.99',
          localizedPrice: '\$0.99',
          paymentMode: 'payAsYouGo',
          subscriptionPeriod: 'P1W',
        );

        final json = discount.toJson();
        expect(json['identifier'], 'promo_offer');
        expect(json['type'], 'promotional');
        expect(json['numberOfPeriods'], '1');
        expect(json['price'], '0.99');
        expect(json['localizedPrice'], '\$0.99');
        expect(json['paymentMode'], 'payAsYouGo');
        expect(json['subscriptionPeriod'], 'P1W');
      });

      test('should parse DiscountIOS from JSON', () {
        final json = {
          'identifier': 'parsed_discount',
          'type': 'parsed_type',
          'numberOfPeriods': '2',
          'price': '2.99',
          'localizedPrice': '\$2.99',
          'paymentMode': 'payUpFront',
          'subscriptionPeriod': 'P2W',
        };

        final discount = DiscountIOS.fromJson(json);
        expect(discount.identifier, 'parsed_discount');
        expect(discount.type, 'parsed_type');
        expect(discount.numberOfPeriods, '2');
        expect(discount.price, '2.99');
        expect(discount.localizedPrice, '\$2.99');
        expect(discount.paymentMode, 'payUpFront');
        expect(discount.subscriptionPeriod, 'P2W');
      });
    });
  });
}
