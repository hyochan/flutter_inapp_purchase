import 'package:flutter_inapp_purchase/builders.dart';
import 'package:flutter_inapp_purchase/types.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RequestPurchaseIosBuilder', () {
    test('builds RequestPurchaseIosProps with all fields', () {
      final builder = RequestPurchaseIosBuilder()
        ..sku = 'com.example.product'
        ..appAccountToken = 'user123'
        ..quantity = 2
        ..andDangerouslyFinishTransactionAutomatically = true
        ..advancedCommerceData = 'campaign_data';

      final props = builder.build();

      expect(props.sku, 'com.example.product');
      expect(props.appAccountToken, 'user123');
      expect(props.quantity, 2);
      expect(props.andDangerouslyFinishTransactionAutomatically, true);
      expect(props.advancedCommerceData, 'campaign_data');
    });

    test('builds with minimal fields', () {
      final builder = RequestPurchaseIosBuilder()..sku = 'product_id';

      final props = builder.build();

      expect(props.sku, 'product_id');
      expect(props.appAccountToken, isNull);
      expect(props.quantity, isNull);
    });
  });

  group('RequestSubscriptionIosBuilder', () {
    test('builds RequestSubscriptionIosProps with all fields', () {
      final builder = RequestSubscriptionIosBuilder()
        ..sku = 'com.example.subscription'
        ..appAccountToken = 'user456'
        ..quantity = 1
        ..advancedCommerceData = 'sub_campaign';

      final props = builder.build();

      expect(props.sku, 'com.example.subscription');
      expect(props.appAccountToken, 'user456');
      expect(props.quantity, 1);
      expect(props.advancedCommerceData, 'sub_campaign');
    });
  });

  group('RequestPurchaseAndroidBuilder', () {
    test('builds RequestPurchaseAndroidProps with all fields', () {
      final builder = RequestPurchaseAndroidBuilder()
        ..skus = ['sku1', 'sku2']
        ..obfuscatedAccountIdAndroid = 'account123'
        ..obfuscatedProfileIdAndroid = 'profile456'
        ..isOfferPersonalized = true;

      final props = builder.build();

      expect(props.skus, ['sku1', 'sku2']);
      expect(props.obfuscatedAccountIdAndroid, 'account123');
      expect(props.obfuscatedProfileIdAndroid, 'profile456');
      expect(props.isOfferPersonalized, true);
    });

    test('builds with developerBillingOption', () {
      final builder = RequestPurchaseAndroidBuilder()
        ..skus = ['product']
        ..developerBillingOption = const DeveloperBillingOptionParamsAndroid(
          billingProgram: BillingProgramAndroid.ExternalPayments,
          launchMode:
              DeveloperBillingLaunchModeAndroid.LaunchInExternalBrowserOrApp,
          linkUri: 'https://example.com',
        );

      final props = builder.build();

      expect(props.developerBillingOption, isNotNull);
      expect(props.developerBillingOption!.billingProgram,
          BillingProgramAndroid.ExternalPayments);
    });
  });

  group('RequestSubscriptionAndroidBuilder', () {
    test('builds RequestSubscriptionAndroidProps with all fields', () {
      final builder = RequestSubscriptionAndroidBuilder()
        ..skus = ['sub_sku']
        ..purchaseTokenAndroid = 'old_token'
        ..replacementModeAndroid = 1
        ..obfuscatedAccountIdAndroid = 'acc'
        ..obfuscatedProfileIdAndroid = 'prof';

      final props = builder.build();

      expect(props.skus, ['sub_sku']);
      expect(props.purchaseTokenAndroid, 'old_token');
      expect(props.replacementModeAndroid, 1);
    });

    test('builds with empty subscriptionOffers returns null', () {
      final builder = RequestSubscriptionAndroidBuilder()
        ..skus = ['sub']
        ..subscriptionOffers = [];

      final props = builder.build();

      expect(props.subscriptionOffers, isNull);
    });

    test('builds with subscriptionOffers', () {
      final builder = RequestSubscriptionAndroidBuilder()
        ..skus = ['sub']
        ..subscriptionOffers = const [
          AndroidSubscriptionOfferInput(
            sku: 'sub',
            offerToken: 'offer123',
          ),
        ];

      final props = builder.build();

      expect(props.subscriptionOffers, isNotNull);
      expect(props.subscriptionOffers!.length, 1);
    });
  });

  group('RequestPurchaseBuilder', () {
    test('builds InApp purchase with apple/google fields', () {
      final builder = RequestPurchaseBuilder()
        ..ios.sku = 'ios_product'
        ..android.skus = ['android_product']
        ..type = ProductQueryType.InApp;

      final props = builder.build();

      expect(props, isA<RequestPurchaseProps>());

      final json = props.toJson();
      expect(json['requestPurchase'], isNotNull);
      expect(json['requestPurchase']['ios'], isNotNull);
      expect(json['requestPurchase']['android'], isNotNull);
    });

    test('builds Subs purchase with apple/google fields', () {
      final builder = RequestPurchaseBuilder()
        ..ios.sku = 'ios_sub'
        ..android.skus = ['android_sub']
        ..type = ProductQueryType.Subs;

      final props = builder.build();

      expect(props, isA<RequestPurchaseProps>());

      final json = props.toJson();
      expect(json['requestSubscription'], isNotNull);
    });

    test('type setter accepts ProductType', () {
      final builder = RequestPurchaseBuilder()
        ..ios.sku = 'product'
        ..type = ProductType.Subs;

      expect(builder.type, ProductQueryType.Subs);
    });

    test('type setter accepts String', () {
      final builder = RequestPurchaseBuilder()..ios.sku = 'product';

      builder.type = 'subscription';
      expect(builder.type, ProductQueryType.Subs);

      builder.type = 'inapp';
      expect(builder.type, ProductQueryType.InApp);
    });

    test('type setter throws for ProductQueryType.All', () {
      final builder = RequestPurchaseBuilder();

      expect(
        () => builder.type = ProductQueryType.All,
        throwsArgumentError,
      );
    });

    test('type setter throws for unsupported types', () {
      final builder = RequestPurchaseBuilder();

      expect(
        () => builder.type = 123,
        throwsArgumentError,
      );
    });

    test('build throws for ProductQueryType.All', () {
      final builder = RequestPurchaseBuilder()..ios.sku = 'product';
      // Force internal type to All (should not happen normally)
      // This test ensures the build method handles edge cases

      // The only way to test this is through the setter which throws
      expect(() => builder.type = ProductQueryType.All, throwsArgumentError);
    });

    test('withIOS extension method works', () {
      final builder = RequestPurchaseBuilder()
          .withIOS((ios) => ios.sku = 'ios_product')
          .withAndroid((android) => android.skus = ['android_product']);

      expect(builder.ios.sku, 'ios_product');
      expect(builder.android.skus, ['android_product']);
    });

    test('builds with useAlternativeBilling', () {
      final builder = RequestPurchaseBuilder()
        ..ios.sku = 'product'
        ..useAlternativeBilling = true
        ..type = ProductQueryType.InApp;

      final props = builder.build();
      final json = props.toJson();

      expect(json['requestPurchase'], isNotNull);
    });

    test('builds with empty ios returns null apple field', () {
      final builder = RequestPurchaseBuilder()
        ..android.skus = ['product']
        ..type = ProductQueryType.InApp;

      final props = builder.build();
      final json = props.toJson();

      expect(json['requestPurchase']['ios'], isNull);
      expect(json['requestPurchase']['android'], isNotNull);
    });

    test('builds subscription with advancedCommerceData', () {
      final builder = RequestPurchaseBuilder()
        ..ios.sku = 'sub'
        ..ios.advancedCommerceData = 'campaign'
        ..type = ProductQueryType.Subs;

      final props = builder.build();
      // Subscription props don't include advancedCommerceData in the conversion
      expect(props, isA<RequestPurchaseProps>());
    });
  });

  group('RequestSubscriptionBuilder', () {
    test('builds subscription with apple/google fields', () {
      final builder = RequestSubscriptionBuilder()
        ..ios.sku = 'ios_sub'
        ..android.skus = ['android_sub'];

      final props = builder.build();

      expect(props, isA<RequestPurchaseProps>());

      final json = props.toJson();
      expect(json['requestSubscription'], isNotNull);
    });

    test('withIOS and withAndroid work correctly', () {
      final builder = RequestSubscriptionBuilder()
          .withIOS((ios) => ios.sku = 'sub_ios')
          .withAndroid((android) => android.skus = ['sub_android']);

      expect(builder.ios.sku, 'sub_ios');
      expect(builder.android.skus, ['sub_android']);
    });

    test('builds with useAlternativeBilling', () {
      final builder = RequestSubscriptionBuilder()
        ..ios.sku = 'sub'
        ..useAlternativeBilling = true;

      final props = builder.build();
      expect(props, isA<RequestPurchaseProps>());
    });

    test('builds with empty skus returns null fields', () {
      final builder = RequestSubscriptionBuilder();

      final props = builder.build();
      final json = props.toJson();

      expect(json['requestSubscription']['ios'], isNull);
      expect(json['requestSubscription']['android'], isNull);
    });
  });
}
