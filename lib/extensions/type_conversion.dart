import '../types.dart';

/// Extensions for converting Flutter types to TypeScript-compatible format
extension OfferDetailTypeScript on OfferDetail {
  /// Convert to TypeScript ProductSubscriptionAndroidOfferDetails format
  Map<String, dynamic> toTypeScriptJson() {
    return {
      'basePlanId': basePlanId,
      'offerId': offerId,
      'offerToken': offerToken,
      'pricingPhases': {
        'pricingPhaseList': pricingPhases
            .map((p) => p.toTypeScriptJson())
            .toList(),
      },
      'offerTags': offerTags ?? [],
    };
  }
}

extension PricingPhaseTypeScript on PricingPhase {
  /// Convert to TypeScript PricingPhaseAndroid format
  Map<String, dynamic> toTypeScriptJson() {
    return {
      'formattedPrice': price,
      'priceCurrencyCode': currency,
      'billingPeriod': billingPeriod,
      'billingCycleCount': billingCycleCount,
      'priceAmountMicros': (priceAmount * 1000000).toStringAsFixed(0),
      'recurrenceMode': recurrenceMode?.index,
    };
  }
}

extension ProductTypeScript on Product {
  /// Get subscription offer details in TypeScript-compatible format
  List<Map<String, dynamic>>? get subscriptionOfferDetailsTypeScript {
    return subscriptionOfferDetails
        ?.map((offer) => offer.toTypeScriptJson())
        .toList();
  }
}
