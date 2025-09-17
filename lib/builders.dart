import 'package:flutter_inapp_purchase/types.dart';

/// Builder for iOS-specific purchase props
class RequestPurchaseIOSBuilder {
  String sku = '';
  bool? andDangerouslyFinishTransactionAutomatically;
  String? appAccountToken;
  int? quantity;
  DiscountOfferInputIOS? withOffer;

  RequestPurchaseIOSBuilder();

  RequestPurchaseIosProps build() {
    return RequestPurchaseIosProps(
      sku: sku,
      andDangerouslyFinishTransactionAutomatically:
          andDangerouslyFinishTransactionAutomatically,
      appAccountToken: appAccountToken,
      quantity: quantity,
      withOffer: withOffer,
    );
  }
}

/// Builder for iOS-specific subscription props
class RequestSubscriptionIOSBuilder {
  String sku = '';
  bool? andDangerouslyFinishTransactionAutomatically;
  String? appAccountToken;
  int? quantity;
  DiscountOfferInputIOS? withOffer;

  RequestSubscriptionIOSBuilder();

  RequestSubscriptionIosProps build() {
    return RequestSubscriptionIosProps(
      sku: sku,
      andDangerouslyFinishTransactionAutomatically:
          andDangerouslyFinishTransactionAutomatically,
      appAccountToken: appAccountToken,
      quantity: quantity,
      withOffer: withOffer,
    );
  }
}

/// Builder for Android purchase props
class RequestPurchaseAndroidBuilder {
  List<String> skus = const [];
  String? obfuscatedAccountIdAndroid;
  String? obfuscatedProfileIdAndroid;
  bool? isOfferPersonalized;

  RequestPurchaseAndroidBuilder();

  RequestPurchaseAndroidProps build() {
    return RequestPurchaseAndroidProps(
      skus: skus,
      obfuscatedAccountIdAndroid: obfuscatedAccountIdAndroid,
      obfuscatedProfileIdAndroid: obfuscatedProfileIdAndroid,
      isOfferPersonalized: isOfferPersonalized,
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
    );
  }
}

/// Unified purchase parameter builder
class RequestPurchaseBuilder {
  final RequestPurchaseIOSBuilder ios = RequestPurchaseIOSBuilder();
  final RequestPurchaseAndroidBuilder android = RequestPurchaseAndroidBuilder();
  ProductQueryType _type = ProductQueryType.InApp;

  ProductQueryType get type => _type;

  set type(Object value) {
    if (value is ProductQueryType) {
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
      final payload = RequestPurchasePropsByPlatforms(
        ios: iosProps,
        android: androidProps,
      );
      return RequestPurchaseProps.inApp(request: payload);
    }

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
            obfuscatedAccountIdAndroid: androidProps.obfuscatedAccountIdAndroid,
            obfuscatedProfileIdAndroid: androidProps.obfuscatedProfileIdAndroid,
            purchaseTokenAndroid: null,
            replacementModeAndroid: null,
            subscriptionOffers: null,
          );

    final subscriptionPayload = RequestSubscriptionPropsByPlatforms(
      ios: iosSub,
      android: androidSub,
    );
    return RequestPurchaseProps.subs(request: subscriptionPayload);
  }
}

typedef IosPurchaseBuilder = void Function(RequestPurchaseIOSBuilder builder);
typedef AndroidPurchaseBuilder = void Function(
    RequestPurchaseAndroidBuilder builder);
typedef IosSubscriptionBuilder = void Function(
    RequestSubscriptionIOSBuilder builder);
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

class RequestSubscriptionBuilder {
  RequestSubscriptionBuilder();

  final RequestSubscriptionIOSBuilder ios = RequestSubscriptionIOSBuilder();
  final RequestSubscriptionAndroidBuilder android =
      RequestSubscriptionAndroidBuilder();

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

    return RequestPurchaseProps.subs(
      request: RequestSubscriptionPropsByPlatforms(
        ios: iosProps,
        android: androidProps,
      ),
    );
  }
}
