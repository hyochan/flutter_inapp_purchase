// Product IDs for testing in the example app
class IAPConstants {
  // Consumable Product IDs
  static const List<String> consumableProductIds = [
    'dev.hyo.martie.10bulbs',
    'dev.hyo.martie.30bulbs',
  ];

  // Non-Consumable Product IDs
  static const List<String> nonConsumableProductIds = [
    'dev.hyo.martie.certified',
  ];

  // In-App Purchase Product IDs (Consumable + Non-Consumable)
  static List<String> get inAppProductIds => [
        ...consumableProductIds,
        ...nonConsumableProductIds,
      ];

  // Subscription Product IDs
  static const List<String> subscriptionProductIds = [
    'dev.hyo.martie.premium', // This is the actual subscription ID in the store
  ];

  // All product IDs combined
  static List<String> get allProductIds => [
        ...inAppProductIds,
        ...subscriptionProductIds,
      ];

  // Check if a product ID is a subscription
  static bool isSubscription(String productId) {
    return subscriptionProductIds.contains(productId);
  }

  // Check if a product ID is an in-app purchase
  static bool isInAppPurchase(String productId) {
    return inAppProductIds.contains(productId);
  }

  // Check if a product ID is consumable
  static bool isConsumable(String productId) {
    return consumableProductIds.contains(productId);
  }

  // Check if a product ID is non-consumable
  static bool isNonConsumable(String productId) {
    return nonConsumableProductIds.contains(productId);
  }

  // Get product type label
  static String getProductTypeLabel(String productId) {
    if (isSubscription(productId)) return 'Subscription';
    if (isConsumable(productId)) return 'Consumable';
    if (isNonConsumable(productId)) return 'Non-Consumable';
    return 'Unknown';
  }
}
