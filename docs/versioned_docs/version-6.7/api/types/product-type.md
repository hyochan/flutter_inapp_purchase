---
sidebar_position: 1
title: Product Types
---

# Product Types

Types and enums related to products and purchases in flutter_inapp_purchase.

## PurchaseType

Enum representing the type of product being purchased.

```dart
enum PurchaseType {
  inapp,  // One-time purchases (consumable and non-consumable)
  subs    // Subscription products
}
```

### Usage

```dart
// For regular products
await FlutterInappPurchase.instance.requestPurchase(
  request: RequestPurchase(...),
  type: PurchaseType.inapp,
);

// For subscriptions
await FlutterInappPurchase.instance.requestPurchase(
  request: RequestPurchase(...),
  type: PurchaseType.subs,
);
```

## PurchaseOptions

Configuration used by `getAvailablePurchases()` to control receipt filtering on iOS.

```dart
class PurchaseOptions {
  final bool? onlyIncludeActiveItemsIOS;
  final bool? alsoPublishToEventListenerIOS;

  const PurchaseOptions({
    this.onlyIncludeActiveItemsIOS,
    this.alsoPublishToEventListenerIOS,
  });
}
```

### Properties

- `onlyIncludeActiveItemsIOS` — When `true` (default), excludes expired subscriptions. Set to `false` to include expired receipts for compliance or historical checks.
- `alsoPublishToEventListenerIOS` — When `true`, replays restored purchases through the `purchaseUpdated` event stream in addition to the method return value.

### Example

```dart
final purchases = await FlutterInappPurchase.instance.getAvailablePurchases(
  PurchaseOptions(
    onlyIncludeActiveItemsIOS: false,
    alsoPublishToEventListenerIOS: true,
  ),
);
```

## BaseProduct

Abstract base class for all product types.

```dart
abstract class BaseProduct {
  final String productId;
  final String price;
  final String? currency;
  final String? localizedPrice;
  final String? title;
  final String? description;
  final IAPPlatform platform;
}
```

### Properties

- `productId` - Unique identifier for the product
- `price` - Raw price value as string
- `currency` - ISO 4217 currency code (e.g., "USD", "EUR")
- `localizedPrice` - Formatted price string with currency symbol
- `title` - Localized product title
- `description` - Localized product description
- `platform` - Platform where product is available

## Product

Class representing a non-subscription product.

```dart
class Product extends BaseProduct {
  final String type;
  final bool? isFamilyShareable;

  Product({
    required String productId,
    required String price,
    String? currency,
    String? localizedPrice,
    String? title,
    String? description,
    required IAPPlatform platform,
    String? type,
    this.isFamilyShareable,
  });
}
```

### Additional Properties

- `type` - Product type (defaults to "inapp")
- `isFamilyShareable` - Whether product can be shared with family (iOS)

### Example

```dart
Product premiumFeature = Product(
  productId: 'com.example.premium',
  price: '9.99',
  currency: 'USD',
  localizedPrice: '$9.99',
  title: 'Premium Features',
  description: 'Unlock all premium features',
  platform: IAPPlatform.ios,
  isFamilyShareable: true,
);
```

## Subscription

Class representing a subscription product.

```dart
class Subscription extends BaseProduct {
  final String type;
  final List<SubscriptionOffer>? subscriptionOfferDetails;
  final String? subscriptionPeriodAndroid;
  final String? subscriptionPeriodUnitIOS;
  final int? subscriptionPeriodNumberIOS;
  final bool? isFamilyShareable;
  final String? subscriptionGroupId;
  final String? introductoryPrice;
  final int? introductoryPriceNumberOfPeriodsIOS;
  final String? introductoryPriceSubscriptionPeriod;
}
```

### Additional Properties

- `type` - Product type (defaults to "subs")
- `subscriptionOfferDetails` - Available offers (Android)
- `subscriptionPeriodAndroid` - ISO 8601 duration format (e.g., "P1M")
- `subscriptionPeriodUnitIOS` - Period unit ("DAY", "WEEK", "MONTH", "YEAR")
- `subscriptionPeriodNumberIOS` - Number of period units
- `isFamilyShareable` - Whether subscription can be shared
- `subscriptionGroupId` - Subscription group identifier (iOS)
- `introductoryPrice` - Introductory price if available
- `introductoryPriceNumberOfPeriodsIOS` - Duration of intro price
- `introductoryPriceSubscriptionPeriod` - Period of intro price

### Example

```dart
Subscription monthlyPlan = Subscription(
  productId: 'com.example.monthly',
  price: '4.99',
  currency: 'USD',
  localizedPrice: '$4.99',
  title: 'Monthly Subscription',
  description: 'Access all features for a month',
  platform: IAPPlatform.ios,
  subscriptionPeriodUnitIOS: 'MONTH',
  subscriptionPeriodNumberIOS: 1,
  introductoryPrice: '0.99',
  introductoryPriceNumberOfPeriodsIOS: 1,
);
```

## SubscriptionOffer

Represents offer details for Android subscriptions.

```dart
class SubscriptionOffer {
  final String? offerId;
  final String? basePlanId;
  final String? offerToken;
  final List<PricingPhase>? pricingPhases;
}
```

### Properties

- `offerId` - Unique offer identifier
- `basePlanId` - Base plan identifier
- `offerToken` - Token to use when purchasing this offer
- `pricingPhases` - List of pricing phases for the offer

## PricingPhase

Represents a pricing phase in a subscription offer.

```dart
class PricingPhase {
  final String? price;
  final String? formattedPrice;
  final String? currencyCode;
  final int? billingCycleCount;
  final String? billingPeriod;
}
```

### Properties

- `price` - Raw price value
- `formattedPrice` - Formatted price string
- `currencyCode` - ISO 4217 currency code
- `billingCycleCount` - Number of billing cycles
- `billingPeriod` - ISO 8601 duration

## Platform-Specific Considerations

### iOS

- Uses `subscriptionPeriodUnitIOS` and `subscriptionPeriodNumberIOS`
- Supports subscription groups and family sharing
- Introductory prices are automatically applied

### Android

- Uses ISO 8601 duration format for periods
- Supports multiple offers per subscription
- Each offer can have multiple pricing phases

## Type Conversion

Converting between legacy `IapItem` and new types:

```dart
// Convert IapItem to Product/Subscription
BaseProduct convertToProduct(IapItem item, PurchaseType type) {
  if (type == PurchaseType.subs) {
    return Subscription(
      productId: item.productId ?? '',
      price: item.price ?? '0',
      currency: item.currency,
      localizedPrice: item.localizedPrice,
      title: item.title,
      description: item.description,
      platform: Platform.isIOS ? IAPPlatform.ios : IAPPlatform.android,
      subscriptionPeriodAndroid: item.subscriptionPeriodAndroid,
      subscriptionPeriodUnitIOS: item.subscriptionPeriodUnitIOS,
      subscriptionPeriodNumberIOS: item.subscriptionPeriodNumberIOS != null
          ? int.tryParse(item.subscriptionPeriodNumberIOS!)
          : null,
    );
  } else {
    return Product(
      productId: item.productId ?? '',
      price: item.price ?? '0',
      currency: item.currency,
      localizedPrice: item.localizedPrice,
      title: item.title,
      description: item.description,
      platform: Platform.isIOS ? IAPPlatform.ios : IAPPlatform.android,
    );
  }
}
```
