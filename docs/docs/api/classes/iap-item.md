---
sidebar_position: 2
title: IapItem
---

# IapItem Class

Represents an item available for purchase from either the Google Play Store or iOS App Store.

## Overview

The `IapItem` class contains all the information about a product that can be purchased, including pricing, descriptions, and platform-specific details. This class is used when querying available products from the store.

## Properties

### Common Properties

```dart
final String? productId
```

The unique identifier for the product.

```dart
final String? price
```

The price of the product as a string value.

```dart
final String? currency
```

The currency code for the price (e.g., "USD", "EUR").

```dart
final String? localizedPrice
```

The formatted price string with currency symbol, localized for the user's region.

```dart
final String? title
```

The localized title/name of the product.

```dart
final String? description
```

The localized description of the product.

```dart
final String? originalPrice
```

The original price before any discounts.

```dart
final String? originalJson
```

The raw JSON response from the platform store.

### iOS-Specific Properties

```dart
final String? subscriptionPeriodNumberIOS
```

The number of subscription periods for iOS subscriptions.

```dart
final String? subscriptionPeriodUnitIOS
```

The unit of the subscription period (e.g., "MONTH", "YEAR") for iOS.

```dart
final String? introductoryPrice
```

The introductory price for the subscription.

```dart
final String? introductoryPriceNumberIOS
```

The number of introductory price periods.

```dart
final String? introductoryPricePaymentModeIOS
```

The payment mode for the introductory price.

```dart
final String? introductoryPriceNumberOfPeriodsIOS
```

The number of periods the introductory price is valid.

```dart
final String? introductoryPriceSubscriptionPeriodIOS
```

The subscription period for the introductory price.

```dart
final List<DiscountIOS>? discountsIOS
```

Available discounts for the product on iOS.

### Android-Specific Properties

```dart
final String? signatureAndroid
```

The signature for the product on Android.

```dart
final String? subscriptionPeriodAndroid
```

The subscription period for Android subscriptions (e.g., "P1M" for 1 month).

```dart
final List<SubscriptionOfferAndroid>? subscriptionOffersAndroid
```

Available subscription offers for the product on Android.

```dart
final String? iconUrl
```

URL to the product's icon image.

## Methods

### fromJSON()

```dart
IapItem.fromJSON(Map<String, dynamic> json)
```

Creates an `IapItem` instance from a JSON map.

### toJson()

```dart
Map<String, dynamic> toJson()
```

Converts the `IapItem` instance to a JSON map.

**Example:**

```dart
String jsonString = convert.jsonEncode(item.toJson());
```

### toString()

```dart
String toString()
```

Returns a string representation of the item with all properties.

## Usage Example

```dart
// Fetching products
final products = await FlutterInappPurchase.instance.fetchProducts(
  ProductRequest(
    skus: ['com.example.premium', 'com.example.pro'],
    type: ProductQueryType.InApp,
  ),
);

// Accessing product information
for (final product in products) {
  print('Product ID: ${product.id}');
  print('Title: ${product.title}');
  print('Price: ${product.displayPrice}');
  print('Description: ${product.description}');

  // Check iOS-specific information
  if (Platform.isIOS && product.discountsIOS != null) {
    for (var discount in product.discountsIOS!) {
      print('Discount: ${discount.localizedPrice}');
    }
  }

  // Check Android-specific information
  if (Platform.isAndroid && product.subscriptionOffersAndroid != null) {
    for (var offer in product.subscriptionOffersAndroid!) {
      print('Offer ID: ${offer.offerId}');
    }
  }
}
```

## Related Classes

### DiscountIOS

Represents a discount available for an iOS product.

```dart
class DiscountIOS {
  String? identifier;
  String? type;
  String? numberOfPeriods;
  double? price;
  String? localizedPrice;
  String? paymentMode;
  String? subscriptionPeriod;
}
```

### SubscriptionOfferAndroid

Represents a subscription offer for an Android product.

```dart
class SubscriptionOfferAndroid {
  String? offerId;
  String? basePlanId;
  String? offerToken;
  List<PricingPhaseAndroid>? pricingPhases;
}
```

### PricingPhaseAndroid

Represents a pricing phase for an Android subscription offer.

```dart
class PricingPhaseAndroid {
  String? price;
  String? formattedPrice;
  String? billingPeriod;
  String? currencyCode;
  int? recurrenceMode;
  int? billingCycleCount;
}
```

## Platform Differences

- **iOS**: Uses subscription period units like "MONTH", "YEAR" and supports promotional offers
- **Android**: Uses ISO 8601 duration format (e.g., "P1M" for 1 month) and supports multiple pricing phases

## Notes

- All string properties are nullable to handle cases where the platform doesn't provide certain information
- The `originalJson` property contains the raw response from the platform, useful for accessing additional data not exposed through the class properties
- Prices are returned as strings to avoid floating-point precision issues
