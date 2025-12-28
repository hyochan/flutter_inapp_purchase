---
title: Alternative Billing
sidebar_label: Alternative Billing
---

import IapKitBanner from "@site/src/uis/IapKitBanner";

# Alternative Billing

<IapKitBanner />

This guide explains how to implement alternative billing functionality in your app using flutter_inapp_purchase, allowing you to use external payment systems alongside or instead of the App Store/Google Play billing.

## Official Documentation

### Apple (iOS)

- [StoreKit External Purchase Documentation](https://developer.apple.com/documentation/storekit/external-purchase) - Official StoreKit external purchase API reference
- [External Purchase Link Entitlement](https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.developer.storekit.external-purchase-link) - Entitlement configuration
- [ExternalPurchaseCustomLink API](https://developer.apple.com/documentation/storekit/externalpurchasecustomlink) - Custom link API documentation
- [OpenIAP External Purchase](https://www.openiap.dev/docs/external-purchase) - OpenIAP external purchase specification

### Google Play (Android)

- [Alternative Billing APIs](https://developer.android.com/google/play/billing/alternative) - Official Android alternative billing API guide
- [User Choice Billing Overview](https://support.google.com/googleplay/android-developer/answer/13821247) - Understanding user choice billing
- [User Choice Billing Pilot](https://support.google.com/googleplay/android-developer/answer/12570971) - Enrollment and setup
- [Payments Policy](https://support.google.com/googleplay/android-developer/answer/10281818) - Google Play's payment policy
- [UX Guidelines (User Choice)](https://developer.android.com/google/play/billing/alternative/interim-ux/user-choice) - User choice billing UX guidelines
- [UX Guidelines (Alternative Billing)](https://developer.android.com/google/play/billing/alternative/interim-ux/billing-choice) - Alternative billing UX guidelines
- [EEA Alternative Billing](https://support.google.com/googleplay/android-developer/answer/12348241) - European Economic Area specific guidance

### Platform Updates (2024)

#### iOS

- US apps can use StoreKit External Purchase Link Entitlement
- System disclosure sheet shown each time external link is accessed
- Commission: 27% (reduced from 30%) for first year, 12% for subsequent years
- EU apps have additional flexibility for external purchases

#### Android

- As of March 13, 2024: Alternative billing APIs must be used (manual reporting deprecated)
- Service fee reduced by 4% when using alternative billing (e.g., 15% → 11%)
- Available in South Korea, India, and EEA
- Gaming and non-gaming apps eligible (varies by region)

## Overview

Alternative billing enables developers to offer payment options outside of the platform's standard billing systems:

- **iOS**: Redirect users to external websites for payment (iOS 16.0+)
- **Android**: Use Google Play's alternative billing options (requires approval)

:::warning Platform Approval Required
Both platforms require special approval to use alternative billing:

- **iOS**: Must be approved for external purchase entitlement
- **Android**: Must be approved for alternative billing in Google Play Console
:::

## iOS Alternative Billing (External Purchase URLs)

On iOS, alternative billing works by redirecting users to an external website where they complete the purchase.

### iOS Native Configuration

To enable iOS alternative billing, you need to configure your Xcode project:

#### 1. Add Entitlements

Open your `ios/Runner/Runner.entitlements` file and add:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Required: Enable external purchase -->
    <key>com.apple.developer.storekit.external-purchase</key>
    <true/>

    <!-- Optional: Enable external purchase link (iOS 18.2+) -->
    <key>com.apple.developer.storekit.external-purchase-link</key>
    <true/>

    <!-- Optional: Enable streaming entitlement (music apps only) -->
    <key>com.apple.developer.storekit.external-purchase-link-streaming</key>
    <true/>
</dict>
</plist>
```

#### 2. Configure Info.plist

Open your `ios/Runner/Info.plist` and add:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Countries where external purchases are supported (ISO 3166-1 alpha-2) -->
    <key>SKExternalPurchase</key>
    <array>
        <string>kr</string>
        <string>nl</string>
        <string>de</string>
        <string>fr</string>
    </array>

    <!-- Optional: External purchase URLs per country (iOS 15.4+) -->
    <key>SKExternalPurchaseLink</key>
    <dict>
        <key>kr</key>
        <string>https://your-site.com/kr/checkout</string>
        <key>nl</key>
        <string>https://your-site.com/nl/checkout</string>
    </dict>

    <!-- Optional: Multiple URLs per country (iOS 17.5+, up to 5) -->
    <key>SKExternalPurchaseMultiLink</key>
    <dict>
        <key>fr</key>
        <array>
            <string>https://your-site.com/fr</string>
            <string>https://your-site.com/global-sale</string>
        </array>
    </dict>

    <!-- Optional: Custom link regions (iOS 18.1+) -->
    <key>SKExternalPurchaseCustomLinkRegions</key>
    <array>
        <string>de</string>
        <string>fr</string>
        <string>nl</string>
    </array>

    <!-- Optional: Streaming regions (music apps, iOS 18.2+) -->
    <key>SKExternalPurchaseLinkStreamingRegions</key>
    <array>
        <string>at</string>
        <string>de</string>
        <string>fr</string>
        <string>nl</string>
        <string>is</string>
        <string>no</string>
    </array>
</dict>
</plist>
```

:::warning iOS Requirements

- **Approval Required**: You must obtain approval from Apple to use external purchase features
- **URL Format**: URLs must use HTTPS, have no query parameters, and be 1,000 characters or fewer
- **Link Limits**:
  - Music streaming apps: up to 5 links per country (EU + Iceland, Norway)
  - Other apps: 1 link per country
- **Supported Regions**: Different features support different regions (EU, US, etc.)

See [External Purchase Link Entitlement](https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.developer.storekit.external-purchase-link) for details.
:::

### iOS Basic Usage (Info.plist URLs)

When URLs are configured in Info.plist, use `requestPurchase`:

```dart
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

Future<void> purchaseWithExternalUrl() async {
  try {
    await FlutterInappPurchase.instance.requestPurchase(
      RequestPurchaseProps.inApp((
        ios: RequestPurchaseIosProps(
          sku: 'com.example.product',
          quantity: 1,
        ),
        useAlternativeBilling: true,
      )),
    );

    // User will be redirected to the external URL configured in Info.plist
    // No purchase callback will fire
    print('User redirected to external payment site');
  } catch (e) {
    print('Alternative billing error: $e');
  }
}
```

### iOS Custom URL (iOS 18.2+)

For dynamic URLs or runtime configuration, use `presentExternalPurchaseLinkIOS`:

```dart
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'dart:io';

Future<void> purchaseWithCustomUrl(String productId) async {
  if (!Platform.isIOS) return;

  try {
    final result = await FlutterInappPurchase.instance
        .presentExternalPurchaseLinkIOS('https://your-site.com/checkout');

    if (result.error != null) {
      print('Error: ${result.error}');
    } else if (result.success) {
      print('User redirected to external website');
      // Implement deep linking to return users to app
    }
  } catch (e) {
    print('External purchase link error: $e');
  }
}
```

### iOS Notice Sheet (iOS 18.2+)

Check availability and present external purchase notice:

```dart
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

Future<void> showExternalPurchaseNotice() async {
  try {
    // Check if external purchase notice can be presented
    final canPresent = await FlutterInappPurchase.instance
        .canPresentExternalPurchaseNoticeIOS();

    if (!canPresent) {
      print('External purchase notice not available');
      return;
    }

    // Present the notice sheet
    final result = await FlutterInappPurchase.instance
        .presentExternalPurchaseNoticeSheetIOS();

    if (result.success) {
      print('User acknowledged external purchase notice');
      // Proceed with external purchase flow
    }
  } catch (e) {
    print('Notice sheet error: $e');
  }
}
```

### Important iOS Notes

- **iOS 16.0+ Required**: External purchase links only work on iOS 16.0 and later
- **iOS 18.2+ for Dynamic URLs**: `presentExternalPurchaseLinkIOS` requires iOS 18.2+
- **No Purchase Callback**: Purchase streams will NOT emit events when using external URLs
- **Deep Link Required**: Implement deep linking to return users to your app after purchase
- **Manual Validation**: You must validate purchases on your backend server

## Android Alternative Billing

Android supports two alternative billing modes:

1. **Alternative Billing Only**: Users can ONLY use your payment system
2. **User Choice Billing**: Users choose between Google Play or your payment system

### Android Native Configuration

No special configuration is needed in your Android project files. Alternative billing is configured at runtime when initializing the connection.

However, you must:

1. **Enroll in Google Play Console**: Apply for alternative billing in your Google Play Console
2. **Get Approval**: Wait for Google's approval
3. **Configure in Console**: Set up alternative billing settings in Play Console

See [User Choice Billing Pilot](https://support.google.com/googleplay/android-developer/answer/12570971) for enrollment details.

### Mode 1: Alternative Billing Only

This mode requires a manual 3-step flow:

```dart
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'dart:io';

Future<void> handleAlternativeBillingOnly(String productId) async {
  if (!Platform.isAndroid) return;

  try {
    // Step 1: Check availability
    final isAvailable = await FlutterInappPurchase.instance
        .checkAlternativeBillingAvailabilityAndroid();

    if (!isAvailable) {
      print('Alternative billing not available');
      return;
    }

    // Step 2: Show information dialog
    final userAccepted = await FlutterInappPurchase.instance
        .showAlternativeBillingDialogAndroid();

    if (!userAccepted) {
      print('User declined');
      return;
    }

    // Step 2.5: Process payment with your payment system
    // ... your payment processing logic here ...

    // Step 3: Create reporting token (after successful payment)
    final token = await FlutterInappPurchase.instance
        .createAlternativeBillingTokenAndroid();

    if (token != null) {
      // Step 4: Report token to Google Play backend within 24 hours
      await reportToGoogleBackend(token);
      print('Alternative billing completed');
    }
  } catch (e) {
    print('Alternative billing error: $e');
  }
}
```

### Mode 2: User Choice Billing

With user choice, Google automatically shows a selection dialog:

```dart
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'dart:io';

Future<void> initializeWithUserChoice() async {
  if (!Platform.isAndroid) return;

  // Initialize with user choice mode
  await FlutterInappPurchase.instance.initialize();
  await FlutterInappPurchase.instance.initConnection(
    alternativeBillingModeAndroid: AlternativeBillingModeAndroid.UserChoice,
  );

  // Set up listeners
  FlutterInappPurchase.instance.purchaseUpdatedListener.listen((purchase) {
    // This fires if user selects Google Play
    print('Google Play purchase: ${purchase.productId}');
  });

  FlutterInappPurchase.instance.userChoiceBillingAndroid.listen((details) {
    // This fires if user selects alternative billing
    print('Alternative billing selected: ${details.products}');
    print('Token: ${details.externalTransactionToken}');
    // Process payment with your system and report token
  });
}

Future<void> handleUserChoicePurchase(String productId) async {
  if (!Platform.isAndroid) return;

  try {
    // Google will show selection dialog automatically
    await FlutterInappPurchase.instance.requestPurchase(
      RequestPurchaseProps.inApp((
        android: RequestPurchaseAndroidProps(skus: [productId]),
        useAlternativeBilling: true,
      )),
    );

    // If user selects Google Play: purchaseUpdated stream
    // If user selects alternative: userChoiceBillingAndroid stream
  } catch (e) {
    print('Purchase error: $e');
  }
}
```

### Mode 3: External Payments (Japan Only)

:::info New in v8.1.2+
External Payments is available starting from Google Play Billing Library 8.3.0 and is currently only supported in Japan.
:::

External Payments presents a side-by-side choice between Google Play Billing and the developer's external payment option directly in the purchase dialog.

**Key differences from User Choice Billing:**

| Feature | User Choice Billing | External Payments |
|---------|---------------------|-------------------|
| Billing Library | 7.0+ | 8.3.0+ |
| Availability | Eligible regions | Japan only |
| UI | Separate dialog | Side-by-side in purchase dialog |

```dart
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'dart:io';

Future<void> initializeWithExternalPayments() async {
  if (!Platform.isAndroid) return;

  // Option 1: Enable during initConnection
  await FlutterInappPurchase.instance.initialize();
  await FlutterInappPurchase.instance.initConnection(
    enableBillingProgramAndroid: BillingProgramAndroid.ExternalPayments,
  );

  // Listen for developer billing selection
  FlutterInappPurchase.instance.developerProvidedBillingAndroid.listen((details) {
    // User selected developer billing
    // IMPORTANT: Report token to Google within 24 hours
    print('External transaction token: ${details.externalTransactionToken}');
    reportToGoogleBackend(details.externalTransactionToken);
  });
}

Future<void> handleExternalPaymentsPurchase(String productId) async {
  if (!Platform.isAndroid) return;

  try {
    // Check if External Payments is available
    final availability = await FlutterInappPurchase.instance
        .isBillingProgramAvailableAndroid(BillingProgramAndroid.ExternalPayments);

    if (!availability.isAvailable) {
      print('External Payments not available');
      // Fall back to standard purchase
      return;
    }

    // Request purchase with external payment option
    await FlutterInappPurchase.instance.requestPurchaseWithBuilder(
      build: (builder) {
        builder.android.skus = [productId];
        builder.android.developerBillingOption = DeveloperBillingOptionParamsAndroid(
          billingProgram: BillingProgramAndroid.ExternalPayments,
          launchMode: DeveloperBillingLaunchModeAndroid.LaunchInExternalBrowserOrApp,
          linkUri: 'https://yoursite.com/checkout?product=$productId',
        );
        builder.type = ProductQueryType.InApp;
      },
    );

    // If user selects Google Play: purchaseUpdated stream
    // If user selects developer billing: developerProvidedBillingAndroid stream
  } catch (e) {
    print('Purchase error: $e');
  }
}
```

**Launch Mode Options:**

- `LaunchInExternalBrowserOrApp`: Google Play launches the URL in external browser
- `CallerWillLaunchLink`: Your app handles launching the URL

### Configuring Alternative Billing Mode

Set the billing mode when initializing the connection:

```dart
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

Future<void> initWithAlternativeBilling() async {
  await FlutterInappPurchase.instance.initialize();

  // Option 1: Alternative Billing Only
  await FlutterInappPurchase.instance.initConnection(
    alternativeBillingModeAndroid:
        AlternativeBillingModeAndroid.AlternativeOnly,
  );

  // Option 2: User Choice Billing
  await FlutterInappPurchase.instance.initConnection(
    alternativeBillingModeAndroid: AlternativeBillingModeAndroid.UserChoice,
  );

  // Option 3: External Payments (Japan Only, 8.3.0+)
  await FlutterInappPurchase.instance.initConnection(
    enableBillingProgramAndroid: BillingProgramAndroid.ExternalPayments,
  );

  // Option 4: None (default Google Play only)
  await FlutterInappPurchase.instance.initConnection(
    alternativeBillingModeAndroid: AlternativeBillingModeAndroid.None,
  );
}
```

## Best Practices

### General

1. **Backend Validation**: Always validate purchases on your backend server
2. **Clear Communication**: Inform users they're leaving the app for external payment
3. **Deep Linking**: Implement deep links to return users to your app (iOS)
4. **Error Handling**: Handle all error cases gracefully

### iOS Specific

1. **iOS Version Check**: Verify iOS 16.0+ before enabling alternative billing
2. **URL Validation**: Ensure external URLs are valid and secure (HTTPS)
3. **No Purchase Events**: Don't rely on purchase streams when using external URLs
4. **Deep Link Implementation**: Crucial for returning users to your app

### Android Specific

1. **24-Hour Reporting**: Report tokens to Google within 24 hours
2. **Mode Selection**: Choose the appropriate mode for your use case
3. **User Experience**: User Choice mode provides better UX but shares revenue with Google
4. **Backend Integration**: Implement proper token reporting to Google Play

## Testing

### iOS Testing

1. Test on real devices running iOS 16.0+
2. Verify external URL opens correctly in Safari
3. Test deep link return flow
4. Ensure StoreKit is configured for alternative billing

### Android Testing

1. Configure alternative billing in Google Play Console
2. Test both billing modes separately
3. Verify token generation and reporting
4. Test user choice dialog behavior

## Troubleshooting

### iOS Issues

#### "Feature not supported"

- Ensure iOS 16.0 or later
- Verify external purchase entitlement is approved
- Check Info.plist configuration

#### "External URL not opening"

- Check URL format (must be valid HTTPS)
- Verify `useAlternativeBilling` flag is set
- Ensure SKExternalPurchase countries are configured

#### "User stuck on external site"

- Implement deep linking to return to app
- Test deep link handling

### Android Issues

#### "Alternative billing not available"

- Verify Google Play approval
- Check device and Play Store version
- Ensure billing mode is configured correctly

#### "Token creation failed"

- Verify product ID is correct
- Check billing mode configuration
- Ensure user completed info dialog

#### "User choice dialog not showing"

- Verify `alternativeBillingModeAndroid: UserChoice`
- Ensure `useAlternativeBilling: true` in request
- Check Google Play configuration

## Platform Requirements

- **iOS**: iOS 16.0+ for external purchase URLs, iOS 18.2+ for dynamic URLs
- **Android**: Google Play Billing Library 5.0+ with alternative billing enabled
- **Approval**: Both platforms require approval for alternative billing features

## See Also

- [OpenIAP Alternative Billing Specification](https://www.openiap.dev/docs/apis#alternative-billing)
- [Alternative Billing Example](/docs/examples/alternative-billing)
- [Error Handling](/docs/guides/error-handling)
