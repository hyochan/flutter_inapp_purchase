import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_inapp_purchase/types.dart';

void main() {
  group('DiscountOffer', () {
    test('serializes to JSON with all fields', () {
      const offer = DiscountOffer(
        id: 'discount_001',
        displayPrice: '\$4.99',
        price: 4.99,
        currency: 'USD',
        type: DiscountOfferType.OneTime,
        offerTokenAndroid: 'token_abc',
        offerTagsAndroid: ['discount', 'promo'],
        fullPriceMicrosAndroid: '9990000',
        percentageDiscountAndroid: 50,
        discountAmountMicrosAndroid: '4990000',
        formattedDiscountAmountAndroid: '\$5.00',
      );

      final json = offer.toJson();

      expect(json['id'], 'discount_001');
      expect(json['displayPrice'], '\$4.99');
      expect(json['price'], 4.99);
      expect(json['currency'], 'USD');
      expect(json['type'], 'one-time');
      expect(json['offerTokenAndroid'], 'token_abc');
      expect(json['offerTagsAndroid'], ['discount', 'promo']);
      expect(json['fullPriceMicrosAndroid'], '9990000');
      expect(json['percentageDiscountAndroid'], 50);
    });

    test('deserializes from JSON', () {
      final json = {
        'id': 'discount_002',
        'displayPrice': '\$2.99',
        'price': 2.99,
        'currency': 'USD',
        'type': 'promotional',
        'offerTokenAndroid': 'token_xyz',
      };

      final offer = DiscountOffer.fromJson(json);

      expect(offer.id, 'discount_002');
      expect(offer.displayPrice, '\$2.99');
      expect(offer.price, 2.99);
      expect(offer.type, DiscountOfferType.Promotional);
    });

    test('round-trips through JSON', () {
      const original = DiscountOffer(
        displayPrice: '\$1.99',
        price: 1.99,
        currency: 'EUR',
        type: DiscountOfferType.Introductory,
      );

      final restored = DiscountOffer.fromJson(original.toJson());

      expect(restored.displayPrice, original.displayPrice);
      expect(restored.price, original.price);
      expect(restored.currency, original.currency);
      expect(restored.type, original.type);
    });
  });

  group('SubscriptionOffer', () {
    test('serializes to JSON with cross-platform fields', () {
      const offer = SubscriptionOffer(
        id: 'intro_offer',
        displayPrice: '\$0.99/month',
        price: 0.99,
        currency: 'USD',
        type: DiscountOfferType.Introductory,
        paymentMode: PaymentMode.FreeTrial,
        period: SubscriptionPeriod(
          unit: SubscriptionPeriodUnit.Month,
          value: 1,
        ),
        periodCount: 3,
      );

      final json = offer.toJson();

      expect(json['id'], 'intro_offer');
      expect(json['displayPrice'], '\$0.99/month');
      expect(json['price'], 0.99);
      expect(json['currency'], 'USD');
      expect(json['type'], 'introductory');
      expect(json['paymentMode'], 'free-trial');
      expect(json['period']['unit'], 'month');
      expect(json['period']['value'], 1);
      expect(json['periodCount'], 3);
    });

    test('serializes Android-specific fields', () {
      const phases = PricingPhasesAndroid(
        pricingPhaseList: [
          PricingPhaseAndroid(
            billingCycleCount: 1,
            billingPeriod: 'P1M',
            formattedPrice: 'Free',
            priceAmountMicros: '0',
            priceCurrencyCode: 'USD',
            recurrenceMode: 2,
          ),
        ],
      );

      const offer = SubscriptionOffer(
        id: 'promo_android',
        displayPrice: 'Free',
        price: 0,
        type: DiscountOfferType.Promotional,
        basePlanIdAndroid: 'monthly_plan',
        offerTokenAndroid: 'offer_token_123',
        offerTagsAndroid: ['promo', 'trial'],
        pricingPhasesAndroid: phases,
      );

      final json = offer.toJson();

      expect(json['basePlanIdAndroid'], 'monthly_plan');
      expect(json['offerTokenAndroid'], 'offer_token_123');
      expect(json['offerTagsAndroid'], ['promo', 'trial']);
      expect(json['pricingPhasesAndroid']['pricingPhaseList'], isNotEmpty);
    });

    test('serializes iOS-specific fields', () {
      const offer = SubscriptionOffer(
        id: 'ios_promo',
        displayPrice: '\$4.99',
        price: 4.99,
        type: DiscountOfferType.Promotional,
        keyIdentifierIOS: 'key_123',
        nonceIOS: 'nonce_abc',
        signatureIOS: 'signature_xyz',
        timestampIOS: 1700000000.0,
        localizedPriceIOS: '\$4.99',
        numberOfPeriodsIOS: 6,
      );

      final json = offer.toJson();

      expect(json['keyIdentifierIOS'], 'key_123');
      expect(json['nonceIOS'], 'nonce_abc');
      expect(json['signatureIOS'], 'signature_xyz');
      expect(json['timestampIOS'], 1700000000.0);
      expect(json['localizedPriceIOS'], '\$4.99');
      expect(json['numberOfPeriodsIOS'], 6);
    });

    test('deserializes from JSON with all field variants', () {
      final json = {
        'id': 'offer_full',
        'displayPrice': '\$9.99/year',
        'price': 9.99,
        'currency': 'USD',
        'type': 'introductory',
        'paymentMode': 'pay-as-you-go',
        'period': {'unit': 'year', 'value': 1},
        'periodCount': 1,
        'basePlanIdAndroid': 'yearly_base',
        'offerTokenAndroid': 'token_yearly',
      };

      final offer = SubscriptionOffer.fromJson(json);

      expect(offer.id, 'offer_full');
      expect(offer.price, 9.99);
      expect(offer.type, DiscountOfferType.Introductory);
      expect(offer.paymentMode, PaymentMode.PayAsYouGo);
      expect(offer.period?.unit, SubscriptionPeriodUnit.Year);
      expect(offer.period?.value, 1);
      expect(offer.basePlanIdAndroid, 'yearly_base');
    });

    test('round-trips through JSON', () {
      const original = SubscriptionOffer(
        id: 'roundtrip_offer',
        displayPrice: '\$2.99/week',
        price: 2.99,
        currency: 'GBP',
        type: DiscountOfferType.Promotional,
        paymentMode: PaymentMode.PayUpFront,
        period: SubscriptionPeriod(unit: SubscriptionPeriodUnit.Week, value: 1),
      );

      final restored = SubscriptionOffer.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.displayPrice, original.displayPrice);
      expect(restored.price, original.price);
      expect(restored.currency, original.currency);
      expect(restored.type, original.type);
      expect(restored.paymentMode, original.paymentMode);
      expect(restored.period?.unit, original.period?.unit);
    });
  });

  group('DiscountOfferType', () {
    test('serializes to kebab-case JSON', () {
      expect(DiscountOfferType.Introductory.toJson(), 'introductory');
      expect(DiscountOfferType.Promotional.toJson(), 'promotional');
      expect(DiscountOfferType.OneTime.toJson(), 'one-time');
    });

    test('deserializes from kebab-case', () {
      expect(
        DiscountOfferType.fromJson('introductory'),
        DiscountOfferType.Introductory,
      );
      expect(
        DiscountOfferType.fromJson('promotional'),
        DiscountOfferType.Promotional,
      );
      expect(DiscountOfferType.fromJson('one-time'), DiscountOfferType.OneTime);
    });
  });

  group('PaymentMode', () {
    test('serializes to kebab-case JSON', () {
      expect(PaymentMode.FreeTrial.toJson(), 'free-trial');
      expect(PaymentMode.PayAsYouGo.toJson(), 'pay-as-you-go');
      expect(PaymentMode.PayUpFront.toJson(), 'pay-up-front');
      expect(PaymentMode.Unknown.toJson(), 'unknown');
    });

    test('deserializes from kebab-case', () {
      expect(PaymentMode.fromJson('free-trial'), PaymentMode.FreeTrial);
      expect(PaymentMode.fromJson('pay-as-you-go'), PaymentMode.PayAsYouGo);
      expect(PaymentMode.fromJson('pay-up-front'), PaymentMode.PayUpFront);
      expect(PaymentMode.fromJson('unknown'), PaymentMode.Unknown);
    });
  });

  group('SubscriptionPeriod', () {
    test('serializes day period', () {
      const period = SubscriptionPeriod(
        unit: SubscriptionPeriodUnit.Day,
        value: 7,
      );

      final json = period.toJson();

      expect(json['unit'], 'day');
      expect(json['value'], 7);
    });

    test('serializes week period', () {
      const period = SubscriptionPeriod(
        unit: SubscriptionPeriodUnit.Week,
        value: 1,
      );

      final json = period.toJson();

      expect(json['unit'], 'week');
      expect(json['value'], 1);
    });

    test('serializes month period', () {
      const period = SubscriptionPeriod(
        unit: SubscriptionPeriodUnit.Month,
        value: 3,
      );

      final json = period.toJson();

      expect(json['unit'], 'month');
      expect(json['value'], 3);
    });

    test('serializes year period', () {
      const period = SubscriptionPeriod(
        unit: SubscriptionPeriodUnit.Year,
        value: 1,
      );

      final json = period.toJson();

      expect(json['unit'], 'year');
      expect(json['value'], 1);
    });

    test('deserializes from JSON', () {
      final json = {'unit': 'month', 'value': 6};

      final period = SubscriptionPeriod.fromJson(json);

      expect(period.unit, SubscriptionPeriodUnit.Month);
      expect(period.value, 6);
    });

    test('round-trips through JSON', () {
      const original = SubscriptionPeriod(
        unit: SubscriptionPeriodUnit.Week,
        value: 2,
      );

      final restored = SubscriptionPeriod.fromJson(original.toJson());

      expect(restored.unit, original.unit);
      expect(restored.value, original.value);
    });
  });

  group('SubscriptionPeriodUnit', () {
    test('serializes to lowercase JSON', () {
      expect(SubscriptionPeriodUnit.Day.toJson(), 'day');
      expect(SubscriptionPeriodUnit.Week.toJson(), 'week');
      expect(SubscriptionPeriodUnit.Month.toJson(), 'month');
      expect(SubscriptionPeriodUnit.Year.toJson(), 'year');
      expect(SubscriptionPeriodUnit.Unknown.toJson(), 'unknown');
    });

    test('deserializes from lowercase', () {
      expect(
        SubscriptionPeriodUnit.fromJson('day'),
        SubscriptionPeriodUnit.Day,
      );
      expect(
        SubscriptionPeriodUnit.fromJson('week'),
        SubscriptionPeriodUnit.Week,
      );
      expect(
        SubscriptionPeriodUnit.fromJson('month'),
        SubscriptionPeriodUnit.Month,
      );
      expect(
        SubscriptionPeriodUnit.fromJson('year'),
        SubscriptionPeriodUnit.Year,
      );
      expect(
        SubscriptionPeriodUnit.fromJson('unknown'),
        SubscriptionPeriodUnit.Unknown,
      );
    });
  });

  group('Product with standardized offers', () {
    test('ProductAndroid includes discountOffers and subscriptionOffers', () {
      const discountOffer = DiscountOffer(
        id: 'discount_1',
        displayPrice: '\$3.99',
        price: 3.99,
        currency: 'USD',
        type: DiscountOfferType.OneTime,
      );

      const product = ProductAndroid(
        currency: 'USD',
        description: 'Test product with discounts',
        displayPrice: '\$9.99',
        id: 'product_with_discounts',
        nameAndroid: 'Test Product',
        platform: IapPlatform.Android,
        price: 9.99,
        title: 'Test Product',
        type: ProductType.InApp,
        discountOffers: [discountOffer],
      );

      final json = product.toJson();

      expect(json['discountOffers'], isNotNull);
      expect(json['discountOffers'], isA<List<dynamic>>());
      expect((json['discountOffers'] as List<dynamic>).length, 1);
      expect((json['discountOffers'] as List).first['type'], 'one-time');
    });

    test('ProductSubscriptionAndroid includes subscriptionOffers', () {
      const subscriptionOffer = SubscriptionOffer(
        id: 'intro_offer',
        displayPrice: '\$0.99/month',
        price: 0.99,
        type: DiscountOfferType.Introductory,
        paymentMode: PaymentMode.FreeTrial,
      );

      const phases = PricingPhasesAndroid(
        pricingPhaseList: [
          PricingPhaseAndroid(
            billingCycleCount: 1,
            billingPeriod: 'P1M',
            formattedPrice: '\$4.99',
            priceAmountMicros: '4990000',
            priceCurrencyCode: 'USD',
            recurrenceMode: 1,
          ),
        ],
      );

      const legacyOffer = ProductSubscriptionAndroidOfferDetails(
        basePlanId: 'monthly',
        offerToken: 'token_123',
        offerTags: ['intro'],
        pricingPhases: phases,
      );

      const subscription = ProductSubscriptionAndroid(
        currency: 'USD',
        description: 'Monthly subscription',
        displayPrice: '\$4.99/month',
        id: 'monthly_sub',
        nameAndroid: 'Monthly Sub',
        platform: IapPlatform.Android,
        price: 4.99,
        subscriptionOfferDetailsAndroid: [legacyOffer],
        subscriptionOffers: [subscriptionOffer],
        title: 'Monthly Subscription',
        type: ProductType.Subs,
      );

      final json = subscription.toJson();

      // Has both legacy and new fields
      expect(json['subscriptionOfferDetailsAndroid'], isNotNull);
      expect(json['subscriptionOffers'], isNotNull);

      // New standardized offer
      expect(
        (json['subscriptionOffers'] as List).first['paymentMode'],
        'free-trial',
      );
    });
  });
}
