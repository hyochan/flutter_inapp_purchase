---
sidebar_position: 2
title: Product
---

import IapKitBanner from "@site/src/uis/IapKitBanner";

# Product Class

<IapKitBanner />

Represents a product available for purchase from either the Google Play Store or iOS App Store.

## Overview

The `Product` class is a union type that contains all the information about an in-app product that can be purchased. Starting from v6.0, this class follows the OpenIAP specification and replaces the legacy `IapItem` class.

## Type Variants

The `Product` type is a union of platform-specific implementations:

- `ProductIOS` - iOS in-app products (non-subscription)
- `ProductAndroid` - Android in-app products (non-subscription)

For subscriptions, use the `ProductSubscription` union type:
- `ProductSubscriptionIOS` - iOS subscription products
- `ProductSubscriptionAndroid` - Android subscription products

## Common Properties

All product types share these properties:

```dart
final String id
```
The unique identifier for the product (SKU).

```dart
final String title
```
The localized title/name of the product.

```dart
final String description
```
The localized description of the product.

```dart
final String displayPrice
```
The formatted price string with currency symbol, localized for the user's region.

```dart
final String currency
```
The currency code for the price (e.g., "USD", "EUR").

```dart
final double? price
```
The price of the product as a numeric value (optional).

```dart
final ProductType type
```
The type of product (`ProductType.InApp` or `ProductType.Subs`).

```dart
final IapPlatform platform
```
The platform this product is from (`IapPlatform.IOS` or `IapPlatform.Android`).

## iOS-Specific Properties (ProductIOS)

```dart
final String displayNameIOS
```
The display name for the product on iOS.

```dart
final bool isFamilyShareableIOS
```
Whether the product is shareable with family members.

```dart
final String jsonRepresentationIOS
```
The JSON representation from StoreKit 2.

```dart
final ProductTypeIOS typeIOS
```
The StoreKit 2 product type (e.g., `ProductTypeIOS.Consumable`, `ProductTypeIOS.NonConsumable`).

```dart
final SubscriptionInfoIOS? subscriptionInfoIOS
```
Subscription information if this is a subscription product (optional).

## Android-Specific Properties (ProductAndroid)

```dart
final String nameAndroid
```
The product name on Android.

```dart
final ProductAndroidOneTimePurchaseOfferDetail? oneTimePurchaseOfferDetailsAndroid
```
One-time purchase offer details for in-app products.

```dart
final List<ProductSubscriptionAndroidOfferDetails>? subscriptionOfferDetailsAndroid
```
Subscription offer details for subscription products (optional).

## Usage Examples

### Fetching Products

```dart
final result = await FlutterInappPurchase.instance.fetchProducts(
  ProductRequest(
    skus: ['premium_feature', 'remove_ads'],
    type: ProductQueryType.InApp,
  ),
);

if (result is FetchProductsResultProducts) {
  for (final product in result.value ?? const []) {
    print('Product ID: ${product.id}');
    print('Title: ${product.title}');
    print('Price: ${product.displayPrice}');
    print('Description: ${product.description}');
  }
}
```

### Platform-Specific Information

```dart
void displayProductInfo(Product product) {
  // Common information
  print('Product: ${product.title}');
  print('Price: ${product.displayPrice}');

  // Check platform-specific details
  if (product is ProductIOS) {
    print('iOS Product');
    print('Family Shareable: ${product.isFamilyShareableIOS}');
    print('Product Type: ${product.typeIOS}');

    if (product.subscriptionInfoIOS != null) {
      print('Subscription Period: ${product.subscriptionInfoIOS!.subscriptionPeriod}');
    }
  } else if (product is ProductAndroid) {
    print('Android Product');
    print('Name: ${product.nameAndroid}');

    if (product.subscriptionOfferDetailsAndroid != null) {
      for (var offer in product.subscriptionOfferDetailsAndroid!) {
        print('Offer: ${offer.basePlanId}');
        print('Token: ${offer.offerToken}');
      }
    }
  }
}
```

### Displaying Product List

```dart
class ProductListWidget extends StatelessWidget {
  final List<Product> products;

  const ProductListWidget({required this.products});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return ListTile(
          title: Text(product.title),
          subtitle: Text(product.description),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                product.displayPrice,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                product.currency,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          onTap: () => _purchaseProduct(product),
        );
      },
    );
  }

  Future<void> _purchaseProduct(Product product) async {
    // Implement purchase logic
  }
}
```

## Subscription Products

For subscription products, use `ProductSubscription`:

```dart
final result = await FlutterInappPurchase.instance.fetchProducts(
  ProductRequest(
    skus: ['monthly_sub', 'yearly_sub'],
    type: ProductQueryType.Subs,
  ),
);

if (result is FetchProductsResultSubscriptions) {
  for (final subscription in result.value ?? const []) {
    if (subscription is ProductSubscriptionIOS) {
      print('iOS Subscription: ${subscription.title}');
      print('Period: ${subscription.subscriptionPeriodUnitIOS}');
      print('Period Number: ${subscription.subscriptionPeriodNumberIOS}');

      if (subscription.introductoryPriceIOS != null) {
        print('Intro Price: ${subscription.introductoryPriceIOS}');
        print('Intro Period: ${subscription.introductoryPriceSubscriptionPeriodIOS}');
      }
    } else if (subscription is ProductSubscriptionAndroid) {
      print('Android Subscription: ${subscription.title}');

      for (var offer in subscription.subscriptionOfferDetailsAndroid) {
        print('Base Plan: ${offer.basePlanId}');

        for (var phase in offer.pricingPhases.pricingPhaseList) {
          print('Phase Price: ${phase.formattedPrice}');
          print('Billing Period: ${phase.billingPeriod}');
          print('Billing Cycle Count: ${phase.billingCycleCount}');
        }
      }
    }
  }
}
```

### Android basePlanId Limitation

**Client-Side Limitation**: The `basePlanId` is available when fetching products, but not when retrieving purchases via `getAvailablePurchases()`. This is a limitation of Google Play Billing Library - the purchase token alone doesn't reveal which base plan was purchased.

See [GitHub Issue #3096](https://github.com/hyochan/react-native-iap/issues/3096) for more details. See the [basePlanId Limitation](../guides/subscription-offers#android-baseplanid-limitation) section for details and workarounds.

## Type Checking

Use type checking to determine the platform-specific variant:

```dart
void handleProduct(Product product) {
  if (product is ProductIOS) {
    // Handle iOS product
    handleIOSProduct(product);
  } else if (product is ProductAndroid) {
    // Handle Android product
    handleAndroidProduct(product);
  }
}
```

## Related Types

### ProductType

```dart
enum ProductType {
  InApp,  // One-time purchase
  Subs,   // Subscription
}
```

### ProductTypeIOS

```dart
enum ProductTypeIOS {
  Consumable,
  NonConsumable,
  NonRenewingSubscription,
  AutoRenewableSubscription,
}
```

### IapPlatform

```dart
enum IapPlatform {
  IOS,
  Android,
}
```

## Migration from IapItem (v5 → v6+)

The `IapItem` class was removed in v6.0. Use `Product` instead:

```dart
// Before (v5.x)
IapItem item = ...;
String productId = item.productId;
String price = item.localizedPrice;

// After (v6.0+)
Product product = ...;
String productId = product.id;
String price = product.displayPrice;
```

## Platform Differences

### iOS
- Uses StoreKit 2 API
- Provides `jsonRepresentationIOS` with raw StoreKit data
- Supports family sharing
- Product type includes consumable/non-consumable distinction

### Android
- Uses Google Play Billing Library v6+
- Supports multiple subscription offers per product
- Pricing phases for flexible billing
- One-time purchase offer details for in-app products

## Important Notes

1. **Type Safety**: Use the union type pattern for type-safe access to platform-specific properties
2. **Null Safety**: Optional properties may be null if the platform doesn't provide that information
3. **Price Format**: Use `displayPrice` for displaying to users (pre-formatted with currency)
4. **Subscription Info**: Check `subscriptionInfoIOS` or `subscriptionOfferDetailsAndroid` for subscription-specific data
5. **Product Query**: Use `ProductQueryType.InApp` for in-app products and `ProductQueryType.Subs` for subscriptions

## See Also

- [Purchase Class](./purchase-item.md) - Represents a completed purchase
- [fetchProducts() Method](../methods/get-products.md) - Fetch available products
