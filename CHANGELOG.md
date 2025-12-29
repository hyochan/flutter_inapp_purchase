# CHANGELOG

## 8.2.0

### Breaking Changes

- **Parameter naming**: `RequestPurchaseProps.inApp()` and `RequestPurchaseProps.subs()` now use `apple`/`google` fields instead of `ios`/`android`
  - This aligns with the OpenIAP GQL schema
  - The type generation script now dynamically reads field names from the schema

  ```dart
  // Before (8.1.x)
  RequestPurchaseProps.inApp((
    ios: RequestPurchaseIosProps(sku: 'product_id'),
    android: RequestPurchaseAndroidProps(skus: ['product_id']),
  ))

  // After (8.2.0)
  RequestPurchaseProps.inApp((
    apple: RequestPurchaseIosProps(sku: 'product_id'),
    google: RequestPurchaseAndroidProps(skus: ['product_id']),
    useAlternativeBilling: null,
  ))
  ```

### Deprecated

- **`AlternativeBillingModeAndroid`**: Use `BillingProgramAndroid` instead
  - `AlternativeBillingModeAndroid.alternativeOnly` -> `BillingProgramAndroid.ExternalOffer`
  - `AlternativeBillingModeAndroid.userChoice` -> `BillingProgramAndroid.UserChoiceBilling`

- **`alternativeBillingModeAndroid` parameter**: Use `enableBillingProgramAndroid` in `initConnection()` instead

### Dependencies

- Updated OpenIAP versions:
  - `openiap-gql`: 1.3.10 -> 1.3.11

## 8.1.2

### New Features

- **External Payments Program (Android 8.3.0+, Japan Only)**: Support for Google Play Billing Library 8.3.0's External Payments program
  - Presents a side-by-side choice between Google Play Billing and the developer's external payment option directly in the purchase flow
  - New `BillingProgramAndroid.ExternalPayments` billing program type
  - New `DeveloperBillingOptionParamsAndroid` to configure external payment option in purchase flow
  - New `DeveloperBillingLaunchModeAndroid` enum for how to launch the external payment link
  - New `DeveloperProvidedBillingDetailsAndroid` type containing `externalTransactionToken` when user selects developer billing
  - New `developerProvidedBillingAndroid` stream for listening to developer billing selection events
  - New `developerBillingOption` field in `RequestPurchaseAndroidProps` and `RequestSubscriptionAndroidProps`

  ```dart
  // Listen for developer billing selection
  iap.developerProvidedBillingAndroid.listen((details) {
    // User selected developer billing
    // Report transaction to Google within 24 hours using details.externalTransactionToken
    print('External transaction token: ${details.externalTransactionToken}');
  });

  // Request purchase with external payments option
  await iap.requestPurchaseWithBuilder(
    build: (builder) {
      builder.google.skus = ['product_id'];
      builder.google.developerBillingOption = DeveloperBillingOptionParamsAndroid(
        billingProgram: BillingProgramAndroid.ExternalPayments,
        launchMode: DeveloperBillingLaunchModeAndroid.LaunchInExternalBrowserOrApp,
        linkUri: 'https://example.com/checkout',
      );
      builder.type = ProductQueryType.InApp;
    },
  );
  ```

- **New Event**: `IapEvent.DeveloperProvidedBillingAndroid` - Fired when user selects developer billing in External Payments flow

- **enableBillingProgramAndroid in InitConnectionConfig**: Enable a specific billing program during connection initialization
  ```dart
  // Enable External Payments during connection
  await iap.initConnection(
    enableBillingProgramAndroid: BillingProgramAndroid.ExternalPayments,
  );
  ```
  This provides a cleaner alternative to calling `enableBillingProgram()` separately before `initConnection()`.

### Dependencies

- Updated OpenIAP versions:
  - `openiap-gql`: 1.3.8 -> 1.3.10
  - `openiap-google`: 1.3.16 -> 1.3.19
  - `openiap-apple`: 1.3.7 -> 1.3.8

## 8.1.1

### Dependencies

- Updated OpenIAP versions:
  - `openiap-google`: 1.3.15 -> 1.3.16

## 8.1.0

### New Features

- **Advanced Commerce Data (iOS 15+)**: Support for StoreKit 2's `Product.PurchaseOption.custom` API
  - New `advancedCommerceData` field in `RequestPurchaseIosProps` and `RequestSubscriptionIosProps`
  - Pass campaign tokens, affiliate IDs, or other attribution data during purchases

  ```dart
  await iap.requestPurchaseWithBuilder(
    build: (builder) {
      builder.ios.sku = 'com.example.premium';
      builder.ios.advancedCommerceData = 'campaign_summer_2025';
      builder.type = ProductQueryType.InApp;
    },
  );
  ```

- **`google` field support (Android)**: New `google` field in request parameters with `android` fallback
  - Aligns with OpenIAP specification for consistent cross-platform naming
  - `android` field is now deprecated; use `google` instead

### Deprecated

- **`requestPurchaseOnPromotedProductIOS()`**: Use `purchasePromoted` stream + `requestPurchase()` instead
  - In StoreKit 2, promoted products can be purchased via the standard purchase flow

  ```dart
  // Recommended approach
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

### Dependencies

- Updated OpenIAP versions:
  - `openiap-apple`: 1.3.5 -> 1.3.7
  - `openiap-google`: 1.3.14 -> 1.3.16
  - `openiap-gql`: 1.3.5 -> 1.3.8

## 8.0.0

### Breaking Changes

- **`oneTimePurchaseOfferDetailsAndroid` is now an array**: Changed from `ProductAndroidOneTimePurchaseOfferDetail?` to `List<ProductAndroidOneTimePurchaseOfferDetail>?` to support multiple discount offers per product (Google Play Billing 7.0+)

  ```dart
  // Before (v7.x)
  final price = product.oneTimePurchaseOfferDetailsAndroid?.formattedPrice;

  // After (v8.x)
  final offers = product.oneTimePurchaseOfferDetailsAndroid;
  final price = offers?.isNotEmpty == true ? offers![0].formattedPrice : null;
  ```

- **`verifyPurchase` and `validateReceipt` API changed**: Now uses platform-specific options instead of deprecated `sku` and `androidOptions` parameters

  ```dart
  // Before (v7.x)
  final result = await iap.verifyPurchase(sku: 'product_id');
  final result = await iap.verifyPurchase(
    sku: 'product_id',
    androidOptions: VerifyPurchaseAndroidOptions(...),
  );

  // After (v8.x) - iOS
  final result = await iap.verifyPurchase(
    apple: VerifyPurchaseAppleOptions(sku: 'product_id'),
  );

  // After (v8.x) - Android
  final result = await iap.verifyPurchase(
    google: VerifyPurchaseGoogleOptions(
      sku: 'product_id',
      accessToken: 'your-oauth-token',  // From your backend
      packageName: 'com.your.app',
      purchaseToken: purchase.purchaseToken,
    ),
  );
  ```

### New Features

- **Billing Programs API (Android 8.2.0+)**: Support for external billing programs
  - `isBillingProgramAvailableAndroid()` - Check if a billing program is available
  - `createBillingProgramReportingDetailsAndroid()` - Get external transaction token for reporting
  - `launchExternalLinkAndroid()` - Launch external link for billing programs

  ```dart
  // Check availability
  final result = await iap.isBillingProgramAvailableAndroid(
    BillingProgramAndroid.ExternalOffer,
  );

  if (result.isAvailable) {
    // Launch external link
    await iap.launchExternalLinkAndroid(
      LaunchExternalLinkParamsAndroid(
        billingProgram: BillingProgramAndroid.ExternalOffer,
        launchMode: ExternalLinkLaunchModeAndroid.LaunchInExternalBrowserOrApp,
        linkType: ExternalLinkTypeAndroid.LinkToDigitalContentOffer,
        linkUri: 'https://your-payment-site.com/purchase',
      ),
    );

    // Get reporting token
    final details = await iap.createBillingProgramReportingDetailsAndroid(
      BillingProgramAndroid.ExternalOffer,
    );
    // Send details.externalTransactionToken to your server
  }
  ```

- **One-Time Product Discounts (Android 7.0+)**: New fields in `ProductAndroidOneTimePurchaseOfferDetail`
  - `offerId` - Unique offer identifier
  - `fullPriceMicros` - Full (non-discounted) price
  - `discountDisplayInfo` - Discount percentage and amount
  - `limitedQuantityInfo` - Maximum and remaining quantity
  - `validTimeWindow` - Offer validity period
  - `offerTags` - List of offer tags
  - `offerToken` - Token for purchase requests
  - `preorderDetailsAndroid` - Pre-order release dates (Android 8.0+)
  - `rentalDetailsAndroid` - Rental period information (Android 8.0+)

- **Purchase Suspension Status (Android 8.1.0+)**: New `isSuspendedAndroid` field in `PurchaseAndroid`
  - Check if a subscription is suspended due to payment issues
  - Do NOT grant entitlements for suspended subscriptions

  ```dart
  for (final purchase in purchases) {
    if (purchase is PurchaseAndroid && purchase.isSuspendedAndroid == true) {
      // Subscription suspended - do not grant access
      // Direct user to fix payment method
    }
  }
  ```

### Deprecated

- `checkAlternativeBillingAvailabilityAndroid()` - Use `isBillingProgramAvailableAndroid(BillingProgramAndroid.ExternalOffer)` instead
- `showAlternativeBillingDialogAndroid()` - Use `launchExternalLinkAndroid()` instead
- `createAlternativeBillingTokenAndroid()` - Use `createBillingProgramReportingDetailsAndroid(BillingProgramAndroid.ExternalOffer)` instead

### Fixes

- **Web Build Error**: Fixed `dart:io` import causing web build failures
  - Replaced `dart:io Platform` with `defaultTargetPlatform` from Flutter foundation
  - Added `kIsWeb` guards to prevent native API calls on web
  - Note: IAP functionality is still iOS/Android only; this fix only enables web compilation

### Dependencies

- Updated OpenIAP versions:
  - `openiap-apple`: 1.3.0 → 1.3.5
  - `openiap-google`: 1.3.12 → 1.3.14
  - `openiap-gql`: 1.3.2 → 1.3.5

### Migration Guide

See [Migration from v7](https://hyochan.github.io/flutter_inapp_purchase/migration/from-v7) for detailed upgrade instructions.

## 7.2.0

- feat: Add `IapStore` enum for unified store identification (`apple`, `google`, `horizon`, `unknown`)
- feat: Add `store` field to Purchase types (deprecates `platform`)
- feat: Support `apple`/`google` keys in request parameters (alongside legacy `ios`/`android`)
- chore(deps): Update OpenIAP versions (apple: 1.3.0, google: 1.3.10, gql: 1.3.0)

## 7.1.21

- feat: Add `verifyPurchaseWithProvider` for IAPKit integration
  - Supports server-side purchase verification via IAPKit
  - New `VerificationMethod` option: `ignore`, `local`, `iapkit`
  - New verification status error codes
- fix: Deep conversion of purchase maps to avoid `_Map<Object?, Object?>` cast errors on iOS 26
  - Fixes trial subscription purchase parsing failures
  - Uses existing `normalizeDynamicMap` for recursive map conversion
- chore(deps): Update openiap versions (apple: 1.2.42, google: 1.3.8, gql: 1.2.7)

## 7.1.20

- chore(deps): Update openiap-versions

  ```json
  {
    "apple": "1.2.38"
  }
  ```

## 7.1.19

- chore(deps): Update openiap-versions

  ```json
  {
    "google": "1.3.7",
    "apple": "1.2.38"
  }
  ```

## 7.1.18

- chore(deps): Update openiap-versions

  ```json
  {
    "google": "1.3.6",
    "apple": "1.2.36"
  }
  ```

## 7.1.17

- **feat**: Add macOS platform support
  - Minimum deployment target: macOS 14.0
  - Shares StoreKit 2 implementation with iOS

## 7.1.16

- chore(deps): openiap-apple@1.2.34

## 7.1.15

- Update openiap-versions.

  ```json
  {
    "gql": "1.2.5",
    "google": "1.3.5",
    "apple": "1.2.32"
  }
  ```

  - [openiap-gql v1.2.5](https://github.com/hyodotdev/openiap/releases/tag/1.2.5)

## 7.1.14

- **fix(android)**: Prevent incomplete product data on repeated `fetchProducts` calls
  - Fixed issue where `displayPrice` and other fields were missing on subsequent calls
  - ProductManager now validates cached data integrity before returning
  - Automatically re-queries products with incomplete cached data
  - [openiap/pull/29](https://github.com/hyodotdev/openiap/pull/29)

:::warning Migration Required for v7.1.14+
Due to product flavor support added in v7.1.13, apps using Google Play must add platform dimension configuration to avoid build errors. Add to `android/app/build.gradle`:

```groovy
android {
    defaultConfig {
        missingDimensionStrategy 'platform', 'play'
    }
}
```

See [Android Setup Guide](https://hyochan.github.io/flutter_inapp_purchase/docs/getting-started/android-setup#required-configuration-v7114) for details.
:::

## 7.1.13

- **feat**: Add Horizon OS support for Meta Quest devices
  - Added product flavor support for Meta Horizon billing (play/horizon flavors)
  - Integrated `openiap-google-horizon` dependency for Meta Quest Platform SDK
  - Added Horizon App ID configuration via gradle.properties and AndroidManifest.xml
  - Example app now supports both Google Play and Meta Horizon builds
  - Added comprehensive documentation for Horizon OS setup
  - [Blog post: Horizon OS Support](https://hyochan.github.io/flutter_inapp_purchase/blog/horizon-os-support)
  - [Setup guide: Horizon OS](https://hyochan.github.io/flutter_inapp_purchase/docs/getting-started/setup-horizon)
- **BREAKING**: Android apps must configure platform dimension
  - Due to product flavor support, apps must add `missingDimensionStrategy 'platform', 'play'` to their build.gradle
  - See [Android Setup Guide](https://hyochan.github.io/flutter_inapp_purchase/docs/getting-started/android-setup#required-configuration-v7114) for configuration details
- **BREAKING**: `introductoryPricePaymentModeIOS` is now required (non-nullable) in `ProductSubscriptionIOS`
  - Changed from `PaymentModeIOS?` to `PaymentModeIOS` (required field)
  - Default value is `PaymentModeIOS.Empty` when not provided
  - Update: Modified `_parsePaymentMode` helper to return `PaymentModeIOS.Empty` instead of `null`
  - **Migration**: Add `introductoryPricePaymentModeIOS: PaymentModeIOS.Empty` when creating `ProductSubscriptionIOS` instances manually

## 7.1.12

- Update openiap-versions.

  ```json
  {
    "apple": "1.2.25",
    "google": "1.3.1",
    "gql": "1.2.2"
  }
  ```

  - [openiap-apple v1.2.25](https://github.com/hyodotdev/openiap/releases/tag/apple-v1.2.25)
  - [openiap-google v1.3.1](https://github.com/hyodotdev/openiap/releases/tag/google-v1.3.1)

## 7.1.11

- fix: improve subscription state handling
  - [openiap/pull/15](https://github.com/hyodotdev/openiap/pull/15)

## 7.1.10

- fix: handle string timestamp in DiscountOfferInputIOS
  - [openiap-apple/pull/26](https://github.com/hyodotdev/openiap-apple/pull/26)

## 7.1.9

- **feat**: Add native `getActiveSubscriptions` support with `renewalInfoIOS`
  - Implemented native method calls for both iOS (openiap-apple@1.2.21) and Android (openiap-google@1.2.13)
  - Added `renewalInfoIOS` field to `ActiveSubscription` for subscription renewal status, pending upgrades/downgrades, and cancellation detection
  - Simplified Dart implementation from 50+ lines to ~10 lines by using native methods
  - Added comprehensive tests for `renewalInfoIOS` parsing (upgrade detection, cancellation, billing retry, grace period)
- **fix**: Improved `_parseActiveSubscriptions` error handling
  - Added support for Map result type (single subscription)
  - Safe JSON decoding with try-catch for unexpected types
- **refactor**: Android native code - extracted `withBillingReady` helper to reduce duplication
- **chore(deps)**: openiap-apple@1.2.21, openiap-google@1.2.13, openiap-gql@1.2.1

## 7.1.8

- chore(deps): openiap-apple@1.2.18
  - [openiap-apple pr#23](https://github.com/hyodotdev/openiap-apple/pull/23)

## 7.1.7

- **fix(ios): corrected transactionReason detection for re-purchased subscriptions by upgrading openiap-apple to `1.2.18`** - Fixed an issue where previously cancelled subscriptions that were purchased again were incorrectly marked as `RENEWAL` instead of `PURCHASE`. Now uses Apple's `transactionReason` from JSON representation for accurate transaction type detection.

## 7.1.6

- Accidental release with no changes.

## 7.1.5

- Resolve issue like [react-native-iap issue #3054](https://github.com/hyochan/react-native-iap/issues/3054) by upgrading openiap-apple to `1.2.17`.

## 7.1.4

- Fixed missing upgrade of `openiap-apple` module to `1.2.14` in the previous release.

## 7.1.3

- Updated `openiap-apple` to `1.2.14`, improving promotional offer error messages.

## 7.1.2

- Upgrade openiap-apple module to `1.2.13`.

## 7.1.1

- Upgrade openiap-apple module to `1.2.12`.

## 7.1.0

- **Breaking**: `fetchProducts()` now returns `Future<List<dynamic>>` instead of specific typed lists
  - Requires explicit type annotation for proper type inference
  - Example: `final List<Product> products = await iap.fetchProducts(skus: ['id'], type: ProductQueryType.InApp);`
  - For subscriptions: `final List<ProductSubscription> subscriptions = await iap.fetchProducts(skus: ['id'], type: ProductQueryType.Subs);`
  - Simplifies API by removing the need for `.value` or `.products` getters
  - Fixes #576 - Type inference issues with `FetchProductsResult`

## 7.0.1

- Add missing `isEligibleForIntroOfferIOS` method (Fixes #574)

## 7.0.0

- **Feature**: Full Alternative Billing support for iOS and Android
  - iOS: External purchase links via `presentExternalPurchaseLinkIOS()`
  - Android: Alternative-Only and User-Choice billing modes
  - New event listener: `userChoiceBillingAndroid` for Android User Choice Billing
  - New APIs: `checkAlternativeBillingAvailabilityAndroid()`, `showAlternativeBillingDialogAndroid()`, `createAlternativeBillingTokenAndroid()`
- **Breaking**: Major API redesign with named parameters and record types
  - `fetchProducts()` now uses named parameters instead of `ProductRequest` object
  - `getAvailablePurchases()` now uses named parameters instead of `PurchaseOptions` object
  - `finishTransaction()` simplified to accept `Purchase` object directly
  - `validateReceiptIOS()`, `deepLinkToSubscriptions()` now use named parameters
  - `RequestPurchaseProps.inApp()` / `.subs()` factory methods removed (use constructor with `type` parameter)
- **Breaking**: Removed deprecated iOS-specific methods
  - `getAvailableItemsIOS()` - Use `getAvailablePurchases()` instead
  - `getAppTransactionTypedIOS()` - Use `getAppTransactionIOS()` instead
  - `getPurchaseHistoriesIOS()` - Use `getAvailablePurchases()` with options instead
- **Improvement**: Moved `_buildIosPurchasePayload` to public utils for better code organization
- 👉 [Full release notes](https://hyochan.github.io/flutter_inapp_purchase/blog/7.0.0-release)
- 👉 [Migration guide](https://hyochan.github.io/flutter_inapp_purchase/docs/migration/from-v6)

## 6.8.8

- Update OpenIAP google module to `1.2.10`

## 6.8.7

- Update readme

## 6.8.6

- feat: fetchProducts with ProductQueryType.All #568

## 6.8.5

- fix(android): openiap module version path

## 6.8.4

- fix(ios): Resolve #567

## 6.8.3

- fix(ios): send error only once - prevent duplicate purchase error events on iOS
- chore(deps): openiap-google@1.2.7
- chore: refine error codes - improve error code mapping and remove message-based inference

**Full Changelog**: <https://github.com/hyochan/flutter_inapp_purchase/compare/6.8.2...6.8.3>

## 6.8.2

- fix: resolve type casting error with PurchaseOptions by @hyochan in <https://github.com/hyochan/flutter_inapp_purchase/pull/565>
- chore(android): refine openiap-versions.json search by @hyochan in <https://github.com/hyochan/flutter_inapp_purchase/pull/566>

**Full Changelog**: <https://github.com/hyochan/flutter_inapp_purchase/compare/6.8.1...6.8.2>

## 6.8.1

- chore(deps): openiap-apple@1.2.3 [#562](https://github.com/hyochan/flutter_inapp_purchase/pull/562)

## 6.8.0

- migrate Flutter In-App Purchase fully into the OpenIAP ecosystem, aligning with `openiap-apple@1.2.2`, `openiap-google@1.2.6`, and `openiap-gql@1.0.8`.
- update product and purchase APIs: use `fetchProducts(ProductRequest(...))` with typed helpers and extend `getAvailablePurchases()` via `PurchaseOptions`; legacy `getProducts`, `getSubscriptions`, and `getPurchaseHistories` are removed.
- clarify identifiers by keeping native transaction IDs untouched and documenting `purchaseToken` as the canonical receipt for server validation.
- 👉 [full release notes](https://hyochan.github.io/flutter_inapp_purchase/blog/6.8.0-release)

## 6.7.2

- refactor: align [openiap-gql@1.0.6](https://github.com/hyodotdev/openiap-gql/releases/tag/1.0.6)
- migration: integrate `openiap-google@1.1.12`
- feat: purchase helper extensions; product prices now use displayPrice and transaction IDs shown only when available.
- refactor: api migrated to a generated, typed handler surface; purchase requests now use a single props object and result types simplified.
- docs: added conventions guide, multiple blog/FAQ updates, and CHANGELOG entry for 6.7.1.

## 6.7.1

- Follow-up fixes & refinements for 6.7.0

## 6.7.0

- fix(android): honor subscription offerToken
- refactor: align [openiap-gql@1.0.2](https://github.com/hyodotdev/openiap-gql/releases/tag/1.0.2)
- migration: integrate `openiap-google@1.1.11`
- migration: integrate `openiap-apple@1.1.12`

## 6.6.1

### Fixed

- iOS: Ensure `product.id` is always populated in `fetchProducts()` (fixes cases where id was empty on iOS). The parser now resolves id from the first non-empty of: `productId` → `id` → `sku` → `productIdentifier` (#550). In debug builds, logs which key was used.
  `withOpacity` in example UI.
- refactor: remove overridden field in `PurchaseIOS` (use `super.expirationDateIOS`).
- refactor: locally suppress legacy `jwsRepresentation` mapping and deprecated `requestPurchase` calls kept for backward compatibility.

### Changed

- Products API: `id` is the primary identifier for `Product`/`ProductSubscription`. `productId` is kept for backward compatibility only (see Deprecated).
- `fetchProducts()`: Adds support for `type: 'all'`.
  - iOS: passes `'all'` through the native `fetchProducts` call
  - Android: fetches `inapp` and `subs`, then merges results
- `productId` on `ProductCommon`: Use `id` instead (will be removed in 6.6.0).
- `Subscription` type name: Use `ProductSubscription` instead (will be removed in 6.6.0). The alias keeps existing code working.
- Parser now emits `ProductSubscription` (alias of `Subscription`) for subscriptions internally.
- Docs/Examples: Completed migration from `PurchasedItem` → `Purchase` in current docs/examples.

## 6.6.0

### Changed

- Android: Migrated native billing to openiap-google and simplified plugin with coroutines and connection gating.
- Android: Hardened null-safety and error logging; removed BuildConfig dependency in Amazon plugin.
- Dart: More robust product parsing (platform heuristics, per-item guards) and safer generics in fetchProducts.
- Example: Fixed sporadic setState after dispose by guarding mounted across async paths.

### Added

- iOS mixin: Convenience helpers (subscription group, App Store country, available items, typed app transaction, purchase histories).

### Tooling

- Pre-commit: Align dart format flags with CI and avoid staging untracked files.

### Deprecated

- Methods (removal in 6.6.0):
  - `fetchProducts()` → use `fetchProducts()`
  - `purchaseAsync()` → use `requestPurchase()`
  - `requestPurchaseAuto()` → use `requestPurchase()`
  - `finalize()` → use `endConnection()`
  - `deepLinkToSubscriptionsAndroid()` → use platform UI links as documented
  - `getPurchaseHistories()` → use `getAvailablePurchases(PurchaseOptions(onlyIncludeActiveItemsIOS: false))`

## 6.5.2

### Fixed

- iOS: Fix product/discount price parsing to tolerate numeric values (prevents `type 'double' is not a subtype of type 'String?'`), fixes #547.

### Changed

- iOS: pin OpenIAP Apple native module to `openiap 1.1.9` (exact version) to avoid unexpected CocoaPods minor updates.

### Notes

- Recommend upgrading to 6.5.2. Prior 6.5.0–6.5.1 allowed older constraints; this release enforces exact 1.1.9 for stability. No breaking changes.

## 6.5.1

### Changed

- iOS: bump OpenIAP Apple native module to `openiap ~> 1.1.8` (no breaking changes)
- iOS: unified error helper to `OpenIapError.defaultMessage` (OpenIAP 1.1.8 consolidation)

### Notes

- Example iOS Podfile pins tag `1.1.8`; run `cd example/ios && pod install` to refresh lockfile.

## 6.5.0

### Changed

- iOS: rename native channel method `buyProduct` to `requestPurchase` and update Dart to call `requestPurchase` (tests adjusted).
- iOS: standardize error codes/messages using OpenIAP (`OpenIapError.defaultMessage`) instead of ad‑hoc reason strings.
- Dart: make product parsing tolerant of numeric fields (e.g., price, subscriptionPeriodNumberIOS) to avoid type cast crashes.
- Restore flow: on iOS run `syncIOS()` (soft‑fail) then `getAvailablePurchases()`; on Android call `getAvailablePurchases()`.

### Added

- iOS mixin: `clearTransactionIOS`, `getPromotedProductIOS`, `requestPurchaseOnPromotedProductIOS` helpers.

### Removed

- iOS: remove no‑op `clearTransactionCache` channel case.
- Deprecated/legacy convenience methods: internal `getAppTransactionTyped`, `getProductsAsync`, `finishTransactionAsync`, non‑suffixed `presentCodeRedemptionSheet`/`showManageSubscriptions`.

### iOS Native

- Use OpenIAP error codes for `initConnection`, `fetchProducts`, `finishTransaction`, receipt validation and system UI calls.
- Purchase error event now emits `E_PURCHASE_ERROR` with standard message.

### CocoaPods

- Podspec requires `openiap ~> 1.1.7`. Example Podfile uses CDN and pins git tag when needed.

## 6.4.6

### Fixed

- **iOS**: Retrieve expired subscriptions in StoreKit 2 sandbox ([#543](https://github.com/hyochan/flutter_inapp_purchase/issues/543))
  - Added `PurchaseOptions` parameter to `getAvailablePurchases()` for OpenIAP compliance
  - Use `onlyIncludeActiveItemsIOS: false` to include expired subscriptions

### Deprecated

- `getPurchaseHistories()` → Use `getAvailablePurchases()` with options (removed in 6.6.0)

## 6.4.5

### Changed

- **BREAKING**: Updated `getAvailablePurchases()` to support `PurchaseOptions` parameter (OpenIAP compliant)
  - Now accepts optional `PurchaseOptions` parameter for platform-specific configuration
  - iOS: Added `onlyIncludeActiveItemsIOS` option (default: true) to control whether expired subscriptions are included

### Added

- Added `PurchaseOptions` class with iOS-specific options:
  - `alsoPublishToEventListenerIOS`: Whether to also publish purchase events to the event listener when fetching available purchases
  - `onlyIncludeActiveItemsIOS`: Whether to only include active items (set to false to get expired subscriptions)
- **iOS**: Added `getPurchaseHistoriesIOS()` platform-specific method that retrieves all transactions including expired subscriptions

### Deprecated

- `getPurchaseHistories()` - Use `getAvailablePurchases(PurchaseOptions(onlyIncludeActiveItemsIOS: false))` instead (will be removed in 6.6.0)

### Bug Fixes

- **iOS**: Fixed missing transactionStateIOS field in getAvailableItems method ([#538](https://github.com/hyochan/flutter_inapp_purchase/issues/538))
- **iOS**: Fixed expired subscriptions not being returned in purchase history ([#543](https://github.com/hyochan/flutter_inapp_purchase/issues/543))
  - Added new iOS native method using `Transaction.all` instead of `Transaction.currentEntitlements`
  - This ensures all historical purchases including expired subscriptions are returned correctly

## 6.4.4

### Bug Fixes

- **Android**: Fixed FormatException when calling finishTransaction ([#539](https://github.com/hyochan/flutter_inapp_purchase/issues/539))

## 6.4.3

### Bug Fixes

- **iOS**: Replace ISO8601DateFormatter with millisecond timestamps for date fields ([#535](https://github.com/hyochan/flutter_inapp_purchase/issues/535))
  - Changed `expirationDateIOS` and `revocationDateIOS` to use millisecond timestamps
  - Added explicit Int64 casting for better type safety
  - Aligned with expo-iap implementation for consistency
  - Improved Dart type safety for date parsing with safe num to int conversion

## 6.4.2

### Bug Fixes

- **Android**: Fixed `subscriptionOfferDetailsAndroid` field returning null (Fixes [#534](https://github.com/hyochan/flutter_inapp_purchase/issues/534))
  - Added proper parsing for `subscriptionOfferDetailsAndroid` in subscription products
  - Removed parsing of deprecated `subscriptionOfferDetails` field
  - Fixed Map type casting issues that could cause runtime errors with `Map<dynamic, dynamic>` inputs

### Improvements

- **Type Safety**: Improved type safety for JSON parsing across the codebase
  - Added safe JSON map conversion helper to prevent type casting errors
  - Fixed all unsafe `as Map<String, dynamic>` casts in `types.dart`
  - Ensures robust handling of platform channel data

## 6.4.1

### Improvements

- **ActiveSubscription Type**: Implemented a dedicated `ActiveSubscription` type for subscription APIs to provide better type safety and clearer subscription status information ([#532](https://github.com/hyochan/flutter_inapp_purchase/issues/532))
  - `getActiveSubscriptions()` now returns `List<ActiveSubscription>` instead of `List<SubscriptionPurchase>`
  - New type includes subscription-specific fields like `willExpireSoon` and `daysUntilExpirationIOS`
  - Automatically calculates expiration status for iOS subscriptions
  - Provides cleaner API with subscription-focused properties

## 6.4.0

### Breaking Changes

- **Simplified fetchProducts API**: The `fetchProducts` method now accepts direct parameters instead of a wrapper object (Fixes [#527](https://github.com/hyochan/flutter_inapp_purchase/issues/527))

  ```dart
  // Before (6.3.x)
  final products = await iap.fetchProducts(
    RequestProductsParams(
      skus: ['product_id'],
      type: PurchaseType.inapp,
    ),
  );

  // After (6.4.0)
  final products = await iap.fetchProducts(
    skus: ['product_id'],
    type: PurchaseType.inapp,  // Optional, defaults to PurchaseType.inapp
  );
  ```

  - Removed `RequestProductsParams` class
  - This change simplifies the API and improves developer experience based on user feedback

### New Features

- **DSL-like Builder Pattern for Purchase Requests**: Added a builder pattern API for more intuitive and type-safe purchase request construction

  ```dart
  // New builder pattern approach
  await iap.requestPurchaseWithBuilder(
    build: (r) => r
      ..type = PurchaseType.inapp
      ..withIOS((i) => i
        ..sku = 'product_id'
        ..quantity = 1)
      ..withAndroid((a) => a
        ..skus = ['product_id']),
  );
  ```

  - Provides better type safety with platform-specific configurations
  - Supports cascade notation for cleaner code
  - Separate builders for iOS and Android parameters
  - Available for both purchases and subscriptions

### Improvements

- **Replaced magic numbers with enums**: Android purchase states now use `AndroidPurchaseState` enum instead of hardcoded values (0, 1, 2)
  - Better code readability and maintainability
  - Type-safe state checking

### Deprecated Items Removed

The following deprecated items from v6.3.x have been removed in v6.4.0:

- `subscriptionOfferDetails` field (use `subscriptionOfferDetailsAndroid` instead)
- `prorationMode` field (use `replacementModeAndroid` instead)
- `AndroidProrationMode` typedef (use `AndroidReplacementMode` instead)

### Note to Users

We understand there have been several breaking changes recently. We sincerely apologize for any inconvenience. These changes are part of our effort to quickly address the long maintenance gap and bring the library up to modern standards. With version 6.4.0, we believe the major restructuring is now complete, and the API should remain stable going forward.

## 6.3.3

### Bug Fixes

- **Android Type Mapping**: Fixed Android-specific field mappings to match TypeScript/OpenIAP specifications
  - Fixed Product parsing for `nameAndroid` and `oneTimePurchaseOfferDetailsAndroid` fields
  - Fixed Purchase `dataAndroid` field mapping from native Android data
  - Added proper platform checks for Android/iOS specific fields in toJson output
  - Fixed subscription offer details structure to handle nested pricingPhases
  - Fixed PricingPhase parsing for Android field names (formattedPrice, priceCurrencyCode, priceAmountMicros)

### Code Quality

- **Platform-Specific Field Segregation**: Enhanced platform checks across all type classes
  - Added `_platform.isAndroid` and `_platform.isIOS` conditions for platform-specific fields
  - Android-specific fields now only appear on Android platform
  - iOS-specific fields now only appear on iOS platform
  - Added comprehensive TODO comments for v6.4.0 deprecation cleanup

### Documentation

- **Release Notes**: Added proper version planning comments for deprecated field removal in v6.4.0

## 6.3.2

### Bug Fixes

- **iOS Purchase State Detection**: Enhanced purchase state detection for iOS
  - Fixed UI getting stuck in "Processing..." state when `transactionStateIOS` is null
  - Now properly detects successful purchases using multiple conditions (state, token, transaction ID)
  - Added duplicate transaction tracking to prevent double processing
- **Timeout Error Handling**: Improved error handling for store server timeouts
  - Added specific handling for Korean timeout message "요청한 시간이 초과되었습니다"
  - Provides user-friendly troubleshooting steps for network issues
- **Security**: Enhanced security for sensitive data logging
  - Purchase tokens are now masked in debug logs (showing only last 4 characters)
  - All sensitive logging is properly gated behind `kDebugMode` flag

### Documentation

- Added comprehensive iOS purchase state detection guide
- Enhanced troubleshooting documentation with iOS-specific solutions

## 6.3.1

### Bug Fixes

- **Android Subscription Loading**: Fixed type casting error when loading subscriptions
  - Fixed `_Map<String, dynamic>` type casting issue that prevented subscriptions from loading
  - Improved handling of pricing phases data structure from Android
  - Fixed parsing of subscription offer details from nested JSON structure
- **Test Product Cleanup**: Removed deprecated `android.test.purchased` test product ID
  - This test ID is no longer valid in Google Play Billing Library 6+
- **Type Safety**: Improved type handling for Map conversions from native platforms
  - Better handling of different Map implementations from iOS and Android

## 6.3.0

### Bug Fixes

- **CRITICAL FIX: Android Purchase State Mapping**: Fixed incorrect mapping of Android purchase states (#524)
  - Previously mapped: 0=PURCHASED, 1=PENDING (incorrect)
  - Now correctly maps: 0=UNSPECIFIED_STATE, 1=PURCHASED, 2=PENDING
  - This fix aligns with official Google Play Billing documentation
  - Prevents misinterpreting UNSPECIFIED_STATE as a completed purchase
  - UNSPECIFIED_STATE (0) and unknown states now properly map to `PurchaseState.unspecified`

### Features

- **Enhanced OpenIAP Compliance**: Extended OpenIAP specification support with comprehensive field mapping

  - Added full iOS-specific field support: `displayName`, `displayPrice`, `isFamilyShareable`, `jsonRepresentation`, `discountsIOS`, `subscription` info, and promotional offer fields
  - Added comprehensive Android-specific field support: `originalPrice`, `originalPriceAmount`, `freeTrialPeriod`, `subscriptionOffersAndroid`, and billing cycle information
  - Enhanced Purchase object with StoreKit 2 fields: `verificationResultIOS`, `environmentIOS`, `expirationDateIOS`, `revocationDateIOS`, and transaction metadata

- **Improved Test Organization**: Restructured test suite by business flows
  - **Purchase Flow Tests**: General purchase operations and error handling
  - **Subscription Flow Tests**: Subscription-specific operations and lifecycle management
  - **Available Purchases Tests**: Purchase history, restoration, and transaction management
  - Enhanced test coverage from 26% to 28.2%

### Improvements

- **Type Safety**: Enhanced type casting and JSON parsing reliability

  - Fixed `Map<Object?, Object?>` to `Map<String, dynamic>` conversion issues
  - Improved null safety handling for platform-specific fields
  - Better error handling for malformed data

- **Subscription Management**: Enhanced active subscription detection

  - Improved iOS subscription detection logic for better reliability
  - Added fallback logic for subscription identification across platforms

- **Code Quality**: Comprehensive test suite improvements
  - All 95 tests now pass consistently
  - Flexible test assertions that adapt to mock data variations
  - Better separation of platform-specific test scenarios

### Bug Fixes

- **Critical Fix**: Fixed iOS subscription loading issue where `fetchProducts` with `PurchaseType.subs` returned empty arrays
  - iOS now correctly uses `getItems` method instead of unsupported `getSubscriptions`
  - Resolves GitHub issues where users couldn't load subscription products on iOS
- Fixed type casting errors in purchase data conversion
- Fixed subscription detection on iOS platform
- Fixed Android purchase state mapping in active subscription queries
- Resolved null reference exceptions for platform-specific fields
- Fixed test expectations to match actual implementation behavior

### Technical Improvements

- Enhanced mock data consistency across test files
- Improved JSON serialization/deserialization robustness
- Better error messages and debugging information
- Standardized field naming conventions following OpenIAP specification

### Breaking Changes

None - This version maintains full backward compatibility while extending functionality.

## 6.2.0

### Features

- **OpenIAP Compliance**: Added `id` field to `Purchase` class for standardized transaction identification
- **Unified Purchase Token**: Added `purchaseToken` field for cross-platform server validation
  - iOS: Contains JWS representation for App Store validation
  - Android: Contains purchase token for Google Play validation
  - Deprecated platform-specific token fields in favor of unified approach

### Improvements

- **Transaction Management**: `finishTransaction` now accepts `Purchase` objects directly
- **iOS StoreKit 2**: Complete implementation with improved transaction handling
- **Date Handling**: Fixed date parsing issues across platforms
- **Error Handling**: Enhanced error reporting and duplicate event prevention

### Bug Fixes

- Fixed missing `transactionId` and `id` fields in Android purchase responses
- Fixed iOS transaction finishing with proper ID lookup
- Fixed date conversion issues in `Purchase.fromJson()`

### Breaking Changes

None - This version maintains backward compatibility.

## 6.1.0

### Breaking Changes

- **API Cleanup**: Removed all deprecated methods that were marked for removal in 6.0.0
  - Removed `initialize()` - use `initConnection()` instead
  - Removed `checkSubscribed()` - implement custom logic with `getAvailablePurchases()`
  - Removed `showInAppMessageAndroid()` - no longer supported
  - Removed `manageSubscription()` - use `deepLinkToSubscriptionsAndroid()` instead
  - Removed `openPlayStoreSubscriptions()` - use `deepLinkToSubscriptionsAndroid()` instead
  - Removed `clearTransactionIOS()` - no longer needed
  - Removed `showPromoCodesIOS()` - use `presentCodeRedemptionSheetIOS()` instead
  - Removed `getPromotedProductIOS()` and `requestPromotedProductIOS()` - use standard purchase flow
  - Removed `requestProductWithOfferIOS()` and `requestPurchaseWithQuantityIOS()` - use `requestPurchase()` with RequestPurchase object
  - Removed `consumePurchaseAndroidLegacy()` and `validateReceiptAndroidLegacy()` - use modern equivalents
  - Removed `deepLinkToSubscriptionsAndroidLegacy()` - use `deepLinkToSubscriptionsAndroid()`
  - Removed `acknowledgePurchaseAndroid()` - use `finishTransaction()` instead

### Improvements

- **Code Quality**: Removed internal legacy methods and cleaned up codebase
  - Removed `_requestPurchaseOld()` internal method
  - Consolidated duplicate functionality
  - Improved type safety and consistency

### Migration Guide

If you're upgrading from 6.0.x and were using any deprecated methods:

- Replace `initialize()` with `initConnection()`
- Replace `acknowledgePurchaseAndroid()` with `finishTransaction()`
- Use `requestPurchase()` with proper RequestPurchase objects instead of platform-specific methods
- Use `presentCodeRedemptionSheetIOS()` for promo codes on iOS

## 6.0.2

### Bug Fixes

- **Android**: Fixed missing `signatureAndroid` field in purchase conversion
  - Added `signatureAndroid` and other Android-specific fields to the Purchase object
  - Ensures Android purchase signature is properly passed through for receipt validation

## 6.0.1

### Bug Fixes

- **iOS**: Fixed type casting issue where `subscriptionPeriodNumberIOS` was sent as integer instead of string from native iOS code, causing runtime errors
- **Internal**: Renamed unused stream controllers for better code clarity
  - `_purchaseUpdatedController` → `_purchaseUpdatedListener`
  - `_purchaseErrorListenerController` → `_purchaseErrorListener`

## 6.0.0

### Major Release - Open IAP Specification Compliance

This major release redesigns the API to fully comply with the [Open IAP](https://www.openiap.dev) specification, providing a standardized interface for in-app purchases across platforms.

### What is Open IAP?

[Open IAP](https://www.openiap.dev) is an open standard for implementing in-app purchases consistently across different platforms and frameworks. By following this specification, flutter_inapp_purchase now offers:

- Consistent API design patterns
- Standardized error codes and handling
- Unified purchase flow across iOS and Android
- Better interoperability with other IAP libraries

### Breaking Changes

- **Architecture**: Complete redesign following Open IAP specification
  - Removed `useIap` hook and `IapProvider` - use `FlutterInappPurchase.instance` directly
  - Removed `flutter_hooks` dependency
  - Simplified API with direct instance access pattern
- **iOS**: Now requires iOS 11.0+ with StoreKit 2 support (iOS 15.0+)
- **Android**: Updated to Billing Client v8.0.0
- **API Changes**:
  - Enum naming convention: `E_UNKNOWN` → `Unknown` (PascalCase)
  - Channel access: `FlutterInappPurchase.channel` → `FlutterInappPurchase.instance.channel`
  - Unified error handling with standardized error codes

### New Features

- **Open IAP Compliance**: Full implementation of the Open IAP specification
- **Improved Error Handling**: Standardized error codes across platforms
- **Event-based Architecture**: New listeners for purchase updates and errors
- **StoreKit 2 Support**: Automatic transaction verification on iOS 15.0+
- **Better Type Safety**: Enhanced TypeScript-like type definitions

### Migration Guide

```dart
// Before (5.x)
final iap = useIap();
await iap.initialize();

// After (6.0)
final iap = FlutterInappPurchase.instance;
await iap.initConnection();
```

For complete migration details, see the [documentation](https://hyochan.github.io/flutter_inapp_purchase).

## 5.6.2

- fix: removed references to deprecated v1 Android embedding by @moodstubos in <https://github.com/hyochan/flutter_inapp_purchase/pull/497>

## 5.6.1

- Erroneous duplicate item by @deakjahn in <https://github.com/hyochan/flutter_inapp_purchase/pull/441>
- Fixed consumable products reading on Android by @33-Elephants in <https://github.com/hyochan/flutter_inapp_purchase/pull/439>
- fix: Support AGP8 namespace by @dev-yakuza in <https://github.com/hyochan/flutter_inapp_purchase/pull/467>

## 5.6.0

- refactor: android init connection

  ```text
  Used Kotlin apply for cleaner initialization of billingClient.
  Introduced context ?: return for null-safety with context.
  Merged repetitive code into the updateConnectionStatus method to avoid duplication.
  Improved the handling of the alreadyFinished flag to ensure it is only set once and at the appropriate time.
  Streamlined the error and success handling for clarity.
  ```

- Migrate android billingClient to 6.0.1
  - <https://developer.android.com/google/play/billing/release-notes#6-0-1>

## 5.5.0

- Erroneous duplicate item (#441) - Remove extra `introductoryPricePaymentModeIOS`
- Fixed consumable products reading on Android (#439)
- chore(deps): migrate internal packages to recent

  ```sh
  http: ^1.1.0
  meta: ^1.10.0
  platform: ^3.1.3
  ```

- chore: migrate example project to recent flutter version, 3.16.0-0.3.pre

## 5.4.2

## What's Changed

- Update actions/stale action to v8 by @renovate in <https://github.com/hyochan/flutter_inapp_purchase/pull/414>
- Fix - wrong casting by @BrunoFSimon in <https://github.com/hyochan/flutter_inapp_purchase/pull/427>
- Fixed consumable product purchase on Android by @33-Elephants in <https://github.com/hyochan/flutter_inapp_purchase/pull/420>

## New Contributors

- @BrunoFSimon made their first contribution in <https://github.com/hyochan/flutter_inapp_purchase/pull/427>
- @33-Elephants made their first contribution in <https://github.com/hyochan/flutter_inapp_purchase/pull/420>

**Full Changelog**: <https://github.com/hyochan/flutter_inapp_purchase/compare/5.4.1...5.4.2>

## 5.4.1

- Fixed concurrency issue on iOS. by @OctavianLfrd in <https://github.com/hyochan/flutter_inapp_purchase/pull/413>

## 5.4.0

- Fixed wrong casting in checkSubscribed method by @kleeb in <https://github.com/hyochan/flutter_inapp_purchase/pull/368>
- Upgrade to billing 5.1 (reverse compatible) by @SamBergeron in <https://github.com/hyochan/flutter_inapp_purchase/pull/392>

## 5.3.0

## What's Changed

- Refactor java to kotlin, add showInAppMessageAndroid by @offline-first in <https://github.com/hyochan/flutter_inapp_purchase/pull/365>

## New Contributors

- @offline-first made their first contribution in <https://github.com/hyochan/flutter_inapp_purchase/pull/365>

**Full Changelog**: <https://github.com/hyochan/flutter_inapp_purchase/compare/5.2.0...5.3.0>

## 5.2.0

Bugfix #356

## 5.1.1

Run on UiThread and few others (#328)

- Related #272

- The main difference is a new MethodResultWrapper class that wraps both the result and the channel. onMethodCall() now immediately saves this wrapped result-channel to a field and only uses that later to set both the result and to send back info on the channel. I did this in both Google and Amazon but I can't test the Amazon one.

- Included the plugin registration differences.

- Midified suggested in one of the issues that initConnection, endConnection and consumeAllItems shouldn't be accessors. This is very much so, property accessors are not supposed to do work and have side effects, just return a value. Now three new functions are suggested and marked the old ones deprecated.

Fourth, EnumUtil.getValueString() is not really necessary, we have describeEnum() in the Flutter engine just for this purpose.

## 5.1.0

Upgrade android billing client to `4.0.0` (#326)

Remove `orderId` in `Purchase`

- This is duplicate of `transactionId`.

Support for Amazon devices with Google Play sideloaded (#313)

## 5.0.4

- Add iOS promo codes (#325)
- Use http client in validateReceiptIos (#322)
- Amazon `getPrice` directly withoiut formatting (#316)

## 5.0.3

- Fix plugin exception for `requestProductWithQuantityIOS` [#306](https://github.com/hyochan/flutter_inapp_purchase/pull/306)

## 5.0.2

- Replaced obfuscatedAccountIdAndroid with obfuscatedAccountId in request purchase method [#299](https://github.com/hyochan/flutter_inapp_purchase/pull/299)

## 5.0.1

- Add AndroidProrationMode values [#273](https://github.com/hyochan/flutter_inapp_purchase/pull/273)

## 5.0.0

- Support null safety [#275](https://github.com/hyochan/flutter_inapp_purchase/pull/275)

## 4.0.2

- The dart side requires "introductoryPriceCyclesAndroid" to be a int [#268](https://github.com/hyochan/flutter_inapp_purchase/pull/268)

## 4.0.1

- `platform` dep version `>=2.0.0 <4.0.0`

## 4.0.0

- Support flutter v2 [#265](https://github.com/hyochan/flutter_inapp_purchase/pull/265)

## 3.0.1

- Migrate to flutter embedding v2 [#240](https://github.com/hyochan/flutter_inapp_purchase/pull/240)
- Expose android purchase state as enum [#243](https://github.com/hyochan/flutter_inapp_purchase/pull/243)

## 3.0.0

- Upgrade android billing client to `2.1.0` from `3.0.0`.
- Removed `deveoperId` and `accountId` when requesting `purchase` or `subscription` in `android`.
- Added `obfuscatedAccountIdAndroid` and `obfuscatedProfileIdAndroid` when requesting `purchase` or `subscription` in `android`.
- Removed `developerPayload` in `android`.
- Added `purchaseTokenAndroid` as an optional parameter to `requestPurchase` and `requestPurchase`.

## 2.3.1

Republishing since sourcode seems not merged correctly.

## 2.3.0

- Bugfix IapItem deserialization [#212](https://github.com/hyochan/flutter_inapp_purchase/pull/212)
- Add introductoryPriceNumberIOS [#214](https://github.com/hyochan/flutter_inapp_purchase/pull/214)
- Fix iOS promotional offers [#220](https://github.com/hyochan/flutter_inapp_purchase/pull/220)

## 2.2.0

- Implement `endConnection` method to declaratively finish observer in iOS.
- Remove `addTransactionObserver` in IAPPromotionObserver.m for dup observer problems.
- Automatically startPromotionObserver in `initConnection` for iOS.

## 2.1.5

- Fix ios failed purchase handling problem in 11.4+ [#176](https://github.com/hyochan/flutter_inapp_purchase/pull/176)

## 2.1.4

- Fix dart side expression warning [#169](https://github.com/hyochan/flutter_inapp_purchase/pull/169).

## 2.1.3

- Fix wrong introductory price number of periods [#164](https://github.com/hyochan/flutter_inapp_purchase/pull/164).

## 2.1.2

- Trigger purchaseUpdated callback when iap purchased [#165](https://github.com/hyochan/flutter_inapp_purchase/pull/165).

## 2.1.1

- Renamed `finishTransactionIOS` argument `purchaseToken` to `transactionId`.

## 2.1.0

- `finishTransaction` parameter changes to `purchasedItem` from `purchaseToken`.
- Update android billing client to `2.1.0` from `2.0.3`.

## 2.0.5

- [bugfix] Fix double call of result reply on connection init [#126](https://github.com/hyochan/flutter_inapp_purchase/pull/126)

## 2.0.4

- [bugfix] Fix plugin throws exceptions with flutter v1.10.7 beta [#117](https://github.com/hyochan/flutter_inapp_purchase/pull/117)

## 2.0.3

- [bugfix] Decode response code for connection updates stream [#114](https://github.com/hyochan/flutter_inapp_purchase/pull/114)
- [bugfix] Fix typo in `consumePurchase` [#115](https://github.com/hyochan/flutter_inapp_purchase/pull/115)

## 2.0.2

- use ConnectionResult as type for connection stream, fix controller creation [#112](https://github.com/hyochan/flutter_inapp_purchase/pull/112)

## 2.0.0+16

- Resolve [#106](https://github.com/hyochan/flutter_inapp_purchase/issues/106) by not sending `result.error` to the listener. Created use `_conectionSubscription`.

## 2.0.0+15

- Fixed minor typo when generating string with `toString`. Resolve [#110](https://github.com/hyochan/flutter_inapp_purchase/issues/110).

## 2.0.0+14

- Pass android exception to flutter side.

## 2.0.0+13

- Android receipt validation api upgrade to `v3`.

## 2.0.0+12

- Resolve [#102](https://github.com/hyochan/flutter_inapp_purchase/issues/102). Fluter seems to only sends strings between platforms.

## 2.0.0+9

- Resolve [#101](https://github.com/hyochan/flutter_inapp_purchase/issues/101).

## 2.0.0+8

- Resolve [#100](https://github.com/hyochan/flutter_inapp_purchase/issues/100).

## 2.0.0+7

- Resolve [#99](https://github.com/hyochan/flutter_inapp_purchase/issues/99).

## 2.0.0+6

- Send `purchase-error` with purchases returns null.

## 2.0.0+5

- Renamed invoked parameters non-platform specific.

## 2.0.0+4

- Add `deveoperId` and `accountId` when requesting `purchase` or `subscription` in `android`. Find out more in `requestPurchase` and `requestPurchase`.

## 2.0.0+3

- Correctly mock invoke method and return results [#94](https://github.com/hyochan/flutter_inapp_purchase/pull/96)

## 2.0.0+2

- Seperate long `example` code to `example` readme.

## 2.0.0+1

- Properly set return type `PurchaseResult` of when finishing transaction.

## 2.0.0 :tada:

- Removed deprecated note in the `readme`.
- Make the previous tests work in `travis`.
- Documentation on `readme` for breaking features.
- Abstracts `finishTransaction`.
  - `acknowledgePurchaseAndroid`, `consumePurchaseAndroid`, `finishTransactionIOS`.

[Android]

- Completely remove prepare.
- Upgrade billingclient to 2.0.3 which is currently recent in Sep 15 2019.
- Remove [IInAppBillingService] binding since billingClient has its own functionalities.
- Add [DoobooUtils] and add `getBillingResponseData` that visualizes erorr codes better.
- `buyProduct` no more return asyn result. It rather relies on the `purchaseUpdatedListener`.
- Add feature method `acknowledgePurchaseAndroid`
  - Implement `acknowledgePurchaseAndroid`.
  - Renamed `consumePurchase` to `consumePurchaseAndroid` in dart side.
  - Update test codes.
- Renamed methods
  - `buyProduct` to `requestPurchase`.
  - `buySubscription` to `requestPurchase`.

[iOS]

- Implment features in new releases.
  - enforce to `finishTransaction` after purchases.
  - Work with `purchaseUpdated` and `purchaseError` listener as in android.
  - Feature set from `react-native-iap v3`.
  - Should call finish transaction in every purchase request.
  - Add `IAPPromotionObserver` cocoa touch file
  - Convert dic to json string before invoking purchase-updated
  - Add `getPromotedProductIOS` and `requestPromotedProductIOS` methods
  - Implement clearTransaction for ios
  - Include `purchasePromoted` stream that listens to `iap-promoted-product`.

## 1.0.0

- Add `DEPRECATION` note. Please use [in_app_purchase](https://pub.dev/packages/in_app_purchase).

## 0.9.+

- Breaking change. Migrate from the deprecated original Android Support Library to AndroidX. This shouldn't result in any functional changes, but it requires any Android apps using this plugin to also migrate to Android X if they're using the original support library. [Android's Migrating to Android X Guide](https://developer.android.com/jetpack/androidx/migrate).

- Improved getPurchaseHistory's speed 44% faster [#68](https://github.com/hyochan/flutter_inapp_purchase/pull/68).

## 0.8.+

- Fixed receipt validation param for `android`.
- Updated `http` package.
- Implemented new method `getAppStoreInitiatedProducts`.
  - Handling of iOS method `paymentQueue:shouldAddStorePayment:forProduct:`
  - Has no effect on Android.
- Fixed issue with method `buyProductWithoutFinishTransaction` for iOS, was not getting the productId.
- Fixed issue with `toString` method of class `IapItem`, was printing incorrect values.
- Fixes for #44. Unsafe getting `originalJson` when restoring item and `Android`.
- Use dictionaryWithObjectsAndKeys in NSDictionary to fetch product values. This will prevent from NSInvalidArgumentException in ios which rarely occurs.
- Fixed wrong npe in `android` when `getAvailablePurchases`.

- Only parse `orderId` when exists in `Android` to prevent crashing.
- Add additional success purchase listener in `iOS`. Related [#54](https://github.com/hyochan/flutter_inapp_purchase/issues/54)

## 0.7.1

- Implemented receiptValidation for both android and ios.
  - In Android, you need own backend to get your `accessToken`.

## 0.7.0

- Addition of Amazon In-App Purchases.

## 0.6.9

- Prevent nil element exception when getting products.

## 0.6.8

- Prevent nil exception in ios when fetching products.

## 0.6.7

- Fix broken images on pub.

## 0.6.6

- Added missing introductory fields in ios.

## 0.6.5

- convert dynamic objects to PurchasedItems.
- Fix return type for getAvailablePurchases().
- Fix ios null value if optional operator.

## 0.6.3

- Update readme.

## 0.6.2

- Fixed failing when there is no introductory price in ios.

## 0.6.1

- Fixed `checkSubscribed` that can interrupt billing lifecycle.

## 0.6.0

- Major code refactoring by lukepighetti. Unify PlatformException, cleanup new, DateTime instead of string.

## 0.5.9

- Fix getSubscription json encoding problem in `ios`.

## 0.5.8

- Avoid crashing on android caused by IllegalStateException.

## 0.5.7

- Avoid possible memory leak in android by deleting static declaration of activity and context.

## 0.5.6

- Few types fixed.

## 0.5.4

- Fixed error parsing IapItem.

## 0.5.3

- Fixed error parsing purchaseHistory.

## 0.5.2

- Fix crashing on error.

## 0.5.1

- Give better error message on ios.

## 0.5.0

- Code migration.
- Support subscription period.
- There was parameter renaming in `0.5.0` to identify different parameters sent from the device. Please check the readme.

## 0.4.3

- Fixed subscription return types.

## 0.4.0

- Well formatted code.

## 0.3.3

- Code formatted
- Updated missing data types

## 0.3.1

- Upgraded readme for ease of usage.
- Enabled strong mode.

## 0.3.0

- Moved dynamic return type away and instead give `PurchasedItem`.

## 0.2.3

- Quickly fixed purchase bug out there in [issue](https://github.com/hyochan/flutter_inapp_purchase/issues/2). Need much more improvement currently.

## 0.2.2

- Migrated packages from FlutterInApp to FlutterInAppPurchase because pub won't get it.

## 0.1.0

- Initial release of beta
- Moved code from [react-native-iap](https://github.com/hyochan/react-native-iap)
