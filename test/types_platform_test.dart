import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_inapp_purchase/types.dart';

void main() {
  group('Platform-specific product serialization', () {
    test('ProductAndroid toJson includes Android metadata', () {
      const product = ProductAndroid(
        currency: 'USD',
        description: 'Android pass',
        displayPrice: '\$9.99',
        id: 'android_pass',
        nameAndroid: 'Android Pass',
        platform: IapPlatform.Android,
        price: 9.99,
        title: 'Android Pass',
        type: ProductType.InApp,
      );

      final json = product.toJson();

      expect(json['platform'], IapPlatform.Android.toJson());
      expect(json['nameAndroid'], 'Android Pass');
      expect(json.containsKey('displayNameIOS'), isFalse);
    });

    test('ProductIOS toJson includes StoreKit metadata', () {
      const product = ProductIOS(
        currency: 'USD',
        description: 'Premium subscription',
        displayNameIOS: 'Premium',
        displayPrice: '\$7.99',
        id: 'premium_ios',
        isFamilyShareableIOS: true,
        jsonRepresentationIOS: '{}',
        platform: IapPlatform.IOS,
        price: 7.99,
        title: 'Premium',
        type: ProductType.Subs,
        typeIOS: ProductTypeIOS.AutoRenewableSubscription,
      );

      final json = product.toJson();

      expect(json['platform'], IapPlatform.IOS.toJson());
      expect(json['displayNameIOS'], 'Premium');
      expect(json.containsKey('nameAndroid'), isFalse);
    });
  });

  group('Subscription offer details', () {
    test('Android subscription contains pricing phases', () {
      const phases = PricingPhasesAndroid(
        pricingPhaseList: [
          PricingPhaseAndroid(
            billingCycleCount: 3,
            billingPeriod: 'P1M',
            formattedPrice: '\$0.99',
            priceAmountMicros: '990000',
            priceCurrencyCode: 'USD',
            recurrenceMode: 1,
          ),
        ],
      );

      const offer = ProductSubscriptionAndroidOfferDetails(
        basePlanId: 'base_plan',
        offerId: 'intro_offer',
        offerTags: ['intro'],
        offerToken: 'token_123',
        pricingPhases: phases,
      );

      const subscription = ProductSubscriptionAndroid(
        currency: 'USD',
        description: 'Android subscription',
        displayPrice: '\$4.99',
        id: 'android_sub',
        nameAndroid: 'Android Subscription',
        platform: IapPlatform.Android,
        price: 4.99,
        subscriptionOfferDetailsAndroid: [offer],
        title: 'Android Subscription',
        type: ProductType.Subs,
      );

      expect(subscription.subscriptionOfferDetailsAndroid.length, 1);
      expect(
        subscription.subscriptionOfferDetailsAndroid.first.pricingPhases
            .pricingPhaseList.first.formattedPrice,
        '\$0.99',
      );
    });

    test('iOS subscription encodes introductory pricing metadata', () {
      const subscription = ProductSubscriptionIOS(
        currency: 'USD',
        description: 'iOS subscription',
        displayNameIOS: 'iOS Premium',
        displayPrice: '\$5.99',
        id: 'ios_sub',
        isFamilyShareableIOS: false,
        introductoryPricePaymentModeIOS: PaymentModeIOS.Empty,
        jsonRepresentationIOS: '{}',
        platform: IapPlatform.IOS,
        title: 'iOS Premium',
        type: ProductType.Subs,
        typeIOS: ProductTypeIOS.AutoRenewableSubscription,
      );

      final json = subscription.toJson();
      expect(json['platform'], IapPlatform.IOS.toJson());
      expect(json['displayNameIOS'], 'iOS Premium');
      expect(json.containsKey('subscriptionOfferDetailsAndroid'), isFalse);
    });
  });
}
