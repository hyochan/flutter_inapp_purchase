import 'package:flutter_inapp_purchase/types.dart';

/// Builder for iOS-specific purchase props
class RequestPurchaseIosBuilder {
  String sku = '';
  bool? andDangerouslyFinishTransactionAutomatically;
  String? appAccountToken;
  int? quantity;
  DiscountOfferInputIOS? withOffer;
  String? advancedCommerceData;

  RequestPurchaseIosBuilder();

  RequestPurchaseIosProps build() {
    return RequestPurchaseIosProps(
      sku: sku,
      andDangerouslyFinishTransactionAutomatically:
          andDangerouslyFinishTransactionAutomatically,
      appAccountToken: appAccountToken,
      quantity: quantity,
      withOffer: withOffer,
      advancedCommerceData: advancedCommerceData,
    );
  }
}

/// Builder for iOS-specific subscription props
class RequestSubscriptionIosBuilder {
  String sku = '';
  bool? andDangerouslyFinishTransactionAutomatically;
  String? appAccountToken;
  int? quantity;
  DiscountOfferInputIOS? withOffer;
  String? advancedCommerceData;

  RequestSubscriptionIosBuilder();

  RequestSubscriptionIosProps build() {
    return RequestSubscriptionIosProps(
      sku: sku,
      andDangerouslyFinishTransactionAutomatically:
          andDangerouslyFinishTransactionAutomatically,
      appAccountToken: appAccountToken,
      quantity: quantity,
      withOffer: withOffer,
      advancedCommerceData: advancedCommerceData,
    );
  }
}

/// Builder for Android purchase props
class RequestPurchaseAndroidBuilder {
  List<String> skus = const [];
  String? obfuscatedAccountIdAndroid;
  String? obfuscatedProfileIdAndroid;
  bool? isOfferPersonalized;
  DeveloperBillingOptionParamsAndroid? developerBillingOption;

  RequestPurchaseAndroidBuilder();

  RequestPurchaseAndroidProps build() {
    return RequestPurchaseAndroidProps(
      skus: skus,
      obfuscatedAccountIdAndroid: obfuscatedAccountIdAndroid,
      obfuscatedProfileIdAndroid: obfuscatedProfileIdAndroid,
      isOfferPersonalized: isOfferPersonalized,
      developerBillingOption: developerBillingOption,
    );
  }
}

/// Builder for Android subscription props
class RequestSubscriptionAndroidBuilder {
  List<String> skus = const [];
  List<AndroidSubscriptionOfferInput> subscriptionOffers = const [];
  String? obfuscatedAccountIdAndroid;
  String? obfuscatedProfileIdAndroid;
  String? purchaseTokenAndroid;
  int? replacementModeAndroid;
  bool? isOfferPersonalized;
  DeveloperBillingOptionParamsAndroid? developerBillingOption;

  RequestSubscriptionAndroidBuilder();

  RequestSubscriptionAndroidProps build() {
    return RequestSubscriptionAndroidProps(
      skus: skus,
      subscriptionOffers:
          subscriptionOffers.isEmpty ? null : subscriptionOffers,
      obfuscatedAccountIdAndroid: obfuscatedAccountIdAndroid,
      obfuscatedProfileIdAndroid: obfuscatedProfileIdAndroid,
      purchaseTokenAndroid: purchaseTokenAndroid,
      replacementModeAndroid: replacementModeAndroid,
      isOfferPersonalized: isOfferPersonalized,
      developerBillingOption: developerBillingOption,
    );
  }
}

/// Unified purchase parameter builder
class RequestPurchaseBuilder {
  final RequestPurchaseIosBuilder ios = RequestPurchaseIosBuilder();
  final RequestPurchaseAndroidBuilder android = RequestPurchaseAndroidBuilder();
  ProductQueryType _type = ProductQueryType.InApp;
  bool? useAlternativeBilling = false;

  ProductQueryType get type => _type;

  set type(Object value) {
    if (value is ProductQueryType) {
      if (value == ProductQueryType.All) {
        throw ArgumentError(
          'ProductQueryType.All is not supported in RequestPurchaseBuilder. '
          'Use RequestSubscriptionBuilder or specify ProductType.InApp/ProductType.Subs explicitly.',
        );
      }
      _type = value;
      return;
    }
    if (value is ProductType) {
      _type = value == ProductType.InApp
          ? ProductQueryType.InApp
          : ProductQueryType.Subs;
      return;
    }
    if (value is String) {
      final normalized = value.toLowerCase();
      if (normalized.contains('sub')) {
        _type = ProductQueryType.Subs;
      } else {
        _type = ProductQueryType.InApp;
      }
      return;
    }
    throw ArgumentError('Unsupported type assignment: $value');
  }

  RequestPurchaseBuilder();

  RequestPurchaseProps build() {
    final iosProps = ios.sku.isNotEmpty ? ios.build() : null;
    final androidProps = android.skus.isNotEmpty ? android.build() : null;

    if (_type == ProductQueryType.InApp) {
      return RequestPurchaseProps.inApp((
        apple: iosProps,
        google: androidProps,
        useAlternativeBilling: useAlternativeBilling,
      ));
    }

    if (_type == ProductQueryType.Subs) {
      final iosSub = iosProps == null
          ? null
          : RequestSubscriptionIosProps(
              sku: iosProps.sku,
              andDangerouslyFinishTransactionAutomatically:
                  iosProps.andDangerouslyFinishTransactionAutomatically,
              appAccountToken: iosProps.appAccountToken,
              quantity: iosProps.quantity,
              withOffer: iosProps.withOffer,
            );

      final androidSub = androidProps == null
          ? null
          : RequestSubscriptionAndroidProps(
              skus: androidProps.skus,
              isOfferPersonalized: androidProps.isOfferPersonalized,
              obfuscatedAccountIdAndroid:
                  androidProps.obfuscatedAccountIdAndroid,
              obfuscatedProfileIdAndroid:
                  androidProps.obfuscatedProfileIdAndroid,
              purchaseTokenAndroid: null,
              replacementModeAndroid: null,
              subscriptionOffers: null,
              developerBillingOption: androidProps.developerBillingOption,
            );

      return RequestPurchaseProps.subs((
        apple: iosSub,
        google: androidSub,
        useAlternativeBilling: useAlternativeBilling,
      ));
    }

    throw ArgumentError(
      'ProductQueryType.All is not supported in RequestPurchaseBuilder. '
      'Use RequestSubscriptionBuilder or specify ProductType.InApp/ProductType.Subs explicitly.',
    );
  }
}

typedef IosPurchaseBuilder = void Function(RequestPurchaseIosBuilder builder);
typedef AndroidPurchaseBuilder = void Function(
    RequestPurchaseAndroidBuilder builder);
typedef IosSubscriptionBuilder = void Function(
    RequestSubscriptionIosBuilder builder);
typedef AndroidSubscriptionBuilder = void Function(
    RequestSubscriptionAndroidBuilder builder);
typedef RequestBuilder = void Function(RequestPurchaseBuilder builder);

extension RequestPurchaseBuilderExtension on RequestPurchaseBuilder {
  RequestPurchaseBuilder withIOS(IosPurchaseBuilder configure) {
    configure(ios);
    return this;
  }

  RequestPurchaseBuilder withAndroid(AndroidPurchaseBuilder configure) {
    configure(android);
    return this;
  }
}

mixin RequestPurchaseBuilderApi {
  MutationRequestPurchaseHandler get requestPurchase;

  /// DSL-like request purchase method with builder pattern.
  Future<void> requestPurchaseWithBuilder({
    required RequestBuilder build,
  }) async {
    final builder = RequestPurchaseBuilder();
    build(builder);
    final props = builder.build();

    await requestPurchase(props);
  }
}

class RequestSubscriptionBuilder {
  RequestSubscriptionBuilder();

  final RequestSubscriptionIosBuilder ios = RequestSubscriptionIosBuilder();
  final RequestSubscriptionAndroidBuilder android =
      RequestSubscriptionAndroidBuilder();
  bool? useAlternativeBilling = false;

  RequestSubscriptionBuilder withIOS(IosSubscriptionBuilder configure) {
    configure(ios);
    return this;
  }

  RequestSubscriptionBuilder withAndroid(AndroidSubscriptionBuilder configure) {
    configure(android);
    return this;
  }

  RequestPurchaseProps build() {
    final iosProps = ios.sku.isNotEmpty ? ios.build() : null;
    final androidProps = android.skus.isNotEmpty ? android.build() : null;

    return RequestPurchaseProps.subs((
      apple: iosProps,
      google: androidProps,
      useAlternativeBilling: useAlternativeBilling,
    ));
  }
}
