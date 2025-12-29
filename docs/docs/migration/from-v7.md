---
sidebar_position: 1
---

import IapKitBanner from "@site/src/uis/IapKitBanner";

# Migration from v7

<IapKitBanner />

This guide helps you migrate from flutter_inapp_purchase v7.x to v8.0.

## Breaking Changes

### `oneTimePurchaseOfferDetailsAndroid` is now an array

The most significant breaking change is that `oneTimePurchaseOfferDetailsAndroid` changed from a single object to an array. This was necessary to support multiple discount offers per product (Google Play Billing 7.0+).

**Before (v7.x):**
```dart
final price = product.oneTimePurchaseOfferDetailsAndroid?.formattedPrice;
```

**After (v8.x):**
```dart
final offers = product.oneTimePurchaseOfferDetailsAndroid;
final price = offers?.isNotEmpty == true ? offers![0].formattedPrice : null;

// Or iterate through all offers
for (final offer in offers ?? []) {
  print('Offer: ${offer.offerId ?? "default"}');
  print('Price: ${offer.formattedPrice}');

  // Check for discount info
  if (offer.discountDisplayInfo != null) {
    print('Discount: ${offer.discountDisplayInfo!.percentageDiscount}% off');
  }
}
```

### `verifyPurchase` API changed

The verification APIs now use platform-specific options objects instead of the deprecated `sku` and `androidOptions` parameters.

**Before (v7.x):**
```dart
// iOS
final result = await iap.verifyPurchase(sku: 'product_id');

// Android
final result = await iap.verifyPurchase(
  sku: 'product_id',
  androidOptions: VerifyPurchaseAndroidOptions(
    accessToken: 'token',
    packageName: 'com.your.app',
    productToken: 'purchase_token',
  ),
);
```

**After (v8.x):**
```dart
// iOS - use apple options
final result = await iap.verifyPurchase(
  apple: VerifyPurchaseAppleOptions(sku: 'product_id'),
);

// Android - use google options
final result = await iap.verifyPurchase(
  google: VerifyPurchaseGoogleOptions(
    sku: 'product_id',
    accessToken: 'your-oauth-token',  // From your backend
    packageName: 'com.your.app',
    purchaseToken: purchase.purchaseToken,
  ),
);

// Meta Horizon (Quest) - use horizon options
final result = await iap.verifyPurchase(
  horizon: VerifyPurchaseHorizonOptions(
    sku: 'product_id',
    accessToken: 'your-meta-token',
    userId: 'user_id',
  ),
);
```

Note: The same change applies to `validateReceipt` and `validateReceiptIOS`.

## Deprecated APIs

### Alternative Billing APIs

The Alternative Billing APIs are deprecated in favor of the new Billing Programs API:

| Deprecated | Replacement |
|------------|-------------|
| `checkAlternativeBillingAvailabilityAndroid()` | `isBillingProgramAvailableAndroid(BillingProgramAndroid.ExternalOffer)` |
| `showAlternativeBillingDialogAndroid()` | `launchExternalLinkAndroid()` |
| `createAlternativeBillingTokenAndroid()` | `createBillingProgramReportingDetailsAndroid(BillingProgramAndroid.ExternalOffer)` |

**Before (v7.x):**
```dart
final available = await iap.checkAlternativeBillingAvailabilityAndroid();
if (available) {
  await iap.showAlternativeBillingDialogAndroid();
  final token = await iap.createAlternativeBillingTokenAndroid();
}
```

**After (v8.x):**
```dart
final result = await iap.isBillingProgramAvailableAndroid(
  BillingProgramAndroid.ExternalOffer,
);

if (result.isAvailable) {
  await iap.launchExternalLinkAndroid(
    LaunchExternalLinkParamsAndroid(
      billingProgram: BillingProgramAndroid.ExternalOffer,
      launchMode: ExternalLinkLaunchModeAndroid.LaunchInExternalBrowserOrApp,
      linkType: ExternalLinkTypeAndroid.LinkToDigitalContentOffer,
      linkUri: 'https://your-payment-site.com/purchase',
    ),
  );

  final details = await iap.createBillingProgramReportingDetailsAndroid(
    BillingProgramAndroid.ExternalOffer,
  );
  // Use details.externalTransactionToken
}
```

## New Features

### Billing Programs API

The new Billing Programs API provides three methods:

- `isBillingProgramAvailableAndroid(program)` - Check if a billing program is available
- `launchExternalLinkAndroid(params)` - Launch external link for billing programs
- `createBillingProgramReportingDetailsAndroid(program)` - Get external transaction token

See [Billing Programs Guide](/docs/guides/alternative-billing) for detailed usage.

### One-Time Product Discount Fields

New fields are available in `ProductAndroidOneTimePurchaseOfferDetail`:

- `offerId` - Unique offer identifier
- `fullPriceMicros` - Full (non-discounted) price
- `discountDisplayInfo` - Contains `percentageDiscount` and `discountAmount`
- `limitedQuantityInfo` - Maximum and remaining quantity
- `validTimeWindow` - Offer start and end times
- `offerTags` - List of tags for the offer
- `offerToken` - Token for purchase requests
- `preorderDetailsAndroid` - Pre-order release dates (Android 8.0+)
- `rentalDetailsAndroid` - Rental period info (Android 8.0+)

### Purchase Suspension Status

Check if a subscription is suspended due to payment issues:

```dart
final purchases = await iap.getAvailablePurchases();

for (final purchase in purchases) {
  if (purchase is PurchaseAndroid && purchase.isSuspendedAndroid == true) {
    // Do NOT grant entitlements for suspended subscriptions
    // Direct user to fix payment method
  }
}
```

### Advanced Commerce Data (v8.1.0+)

New support for StoreKit 2's attribution data API on iOS 15+:

```dart
await iap.requestPurchaseWithBuilder(
  build: (builder) {
    builder.ios.sku = 'com.example.premium';
    builder.ios.advancedCommerceData = 'campaign_summer_2025';
    builder.type = ProductQueryType.InApp;
  },
);
```

Use cases:
- Campaign attribution tracking
- Affiliate marketing integration
- Promotional code tracking

### Promoted Products (v8.1.0+)

`requestPurchaseOnPromotedProductIOS()` is now deprecated. Use the `purchasePromoted` stream instead:

**Before (deprecated):**
```dart
await iap.requestPurchaseOnPromotedProductIOS();
```

**After (recommended):**
```dart
iap.purchasePromoted.listen((productId) async {
  if (productId != null) {
    await iap.requestPurchaseWithBuilder(
      build: (builder) {
        builder.ios.sku = productId;
        builder.type = ProductQueryType.InApp;
      },
    );
  }
});
```

### `google` Field Support (v8.1.0+)

Android request parameters now support the `google` field (recommended) alongside the deprecated `android` field:

```dart
// types.dart - RequestPurchasePropsByPlatforms
RequestPurchasePropsByPlatforms(
  google: RequestPurchaseAndroidProps(skus: ['sku']),  // Recommended
  // android: ...  // Deprecated
);
```

## Dependencies Update

Update your `pubspec.yaml`:

```yaml
dependencies:
  flutter_inapp_purchase: ^8.1.0
```

The plugin automatically uses:
- `openiap-apple`: 1.3.7
- `openiap-google`: 1.3.16
- `openiap-gql`: 1.3.8
