import 'package:flutter_inapp_purchase/types.dart';

/// iOS purchase request builder
class RequestPurchaseIOSBuilder {
  String sku = '';
  bool? andDangerouslyFinishTransactionAutomaticallyIOS;
  String? applicationUsername;
  String? appAccountToken;
  bool? simulatesAskToBuyInSandbox;
  String? discountIdentifier;
  String? discountTimestamp;
  String? discountNonce;
  String? discountSignature;
  int quantity = 1;
  PaymentDiscount? withOffer;

  RequestPurchaseIOSBuilder();

  RequestPurchaseIOS build() {
    return RequestPurchaseIOS(
      sku: sku,
      andDangerouslyFinishTransactionAutomaticallyIOS:
          andDangerouslyFinishTransactionAutomaticallyIOS,
      applicationUsername: applicationUsername,
      appAccountToken: appAccountToken,
      simulatesAskToBuyInSandbox: simulatesAskToBuyInSandbox,
      discountIdentifier: discountIdentifier,
      discountTimestamp: discountTimestamp,
      discountNonce: discountNonce,
      discountSignature: discountSignature,
      quantity: quantity,
      withOffer: withOffer,
    );
  }
}

/// Android purchase request builder
class RequestPurchaseAndroidBuilder {
  List<String> skus = const [];
  String? obfuscatedAccountIdAndroid;
  String? obfuscatedProfileIdAndroid;
  bool? isOfferPersonalized;

  RequestPurchaseAndroidBuilder();

  RequestPurchaseAndroid build() {
    return RequestPurchaseAndroid(
      skus: skus,
      obfuscatedAccountIdAndroid: obfuscatedAccountIdAndroid,
      obfuscatedProfileIdAndroid: obfuscatedProfileIdAndroid,
      isOfferPersonalized: isOfferPersonalized,
    );
  }
}

/// Android subscription request builder
class RequestSubscriptionAndroidBuilder {
  List<String> skus = const [];
  List<SubscriptionOfferAndroid> subscriptionOffers = const [];
  String? obfuscatedAccountIdAndroid;
  String? obfuscatedProfileIdAndroid;
  String? purchaseTokenAndroid;
  int? replacementModeAndroid;
  bool? isOfferPersonalized;

  RequestSubscriptionAndroidBuilder();

  RequestSubscriptionAndroid build() {
    return RequestSubscriptionAndroid(
      skus: skus,
      subscriptionOffers: subscriptionOffers,
      obfuscatedAccountIdAndroid: obfuscatedAccountIdAndroid,
      obfuscatedProfileIdAndroid: obfuscatedProfileIdAndroid,
      purchaseTokenAndroid: purchaseTokenAndroid,
      replacementModeAndroid: replacementModeAndroid,
      isOfferPersonalized: isOfferPersonalized,
    );
  }
}

/// Unified request purchase builder
class RequestPurchaseBuilder {
  final ios = RequestPurchaseIOSBuilder();
  final android = RequestPurchaseAndroidBuilder();
  String type = ProductType.inapp;

  RequestPurchaseBuilder();

  /// Build the final RequestPurchase object
  RequestPurchase build() {
    return RequestPurchase(
      ios: ios.sku.isNotEmpty ? ios.build() : null,
      android: android.skus.isNotEmpty ? android.build() : null,
    );
  }
}

/// Unified request subscription builder
class RequestSubscriptionBuilder {
  final ios = RequestPurchaseIOSBuilder();
  final android = RequestSubscriptionAndroidBuilder();
  String type = ProductType.subs;

  RequestSubscriptionBuilder();

  /// Build the final RequestPurchase object for subscriptions
  RequestPurchase build() {
    return RequestPurchase(
      ios: ios.sku.isNotEmpty ? ios.build() : null,
      android: android.skus.isNotEmpty ? android.build() : null,
    );
  }
}

// Type definitions for builder functions
typedef IosBuilder = void Function(RequestPurchaseIOSBuilder builder);
typedef AndroidBuilder = void Function(RequestPurchaseAndroidBuilder builder);
typedef AndroidSubscriptionBuilder = void Function(
    RequestSubscriptionAndroidBuilder builder);
typedef RequestBuilder = void Function(RequestPurchaseBuilder builder);
typedef SubscriptionBuilder = void Function(RequestSubscriptionBuilder builder);

/// Extensions to enable cascade notation
extension RequestPurchaseBuilderExtension on RequestPurchaseBuilder {
  /// Configure iOS-specific settings
  RequestPurchaseBuilder withIOS(IosBuilder configure) {
    configure(ios);
    return this;
  }

  /// Configure Android-specific settings
  RequestPurchaseBuilder withAndroid(AndroidBuilder configure) {
    configure(android);
    return this;
  }
}

extension RequestSubscriptionBuilderExtension on RequestSubscriptionBuilder {
  /// Configure iOS-specific settings
  RequestSubscriptionBuilder withIOS(IosBuilder configure) {
    configure(ios);
    return this;
  }

  /// Configure Android-specific subscription settings
  RequestSubscriptionBuilder withAndroid(AndroidSubscriptionBuilder configure) {
    configure(android);
    return this;
  }
}
