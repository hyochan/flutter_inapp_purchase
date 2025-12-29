# Alternative Billing

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

> **Warning: Platform Approval Required**
>
> Both platforms require special approval to use alternative billing:
> - **iOS**: Must be approved for external purchase entitlement
> - **Android**: Must be approved for alternative billing in Google Play Console

## iOS Alternative Billing (External Purchase URLs)

On iOS, alternative billing works by redirecting users to an external website where they complete the purchase.

### Basic Usage

```dart
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

Future<void> purchaseWithExternalUrl() async {
  try {
    final result = await FlutterInappPurchase.instance.presentExternalPurchaseLinkIOS(
      'https://your-site.com/checkout',
    );

    if (result.error != null) {
      print('Error: ${result.error}');
    } else if (result.success) {
      print('User redirected to external payment site');
      // User will complete purchase on external website
      // No purchase callback will fire
    } else {
      print('User cancelled');
    }
  } catch (e) {
    print('Alternative billing error: $e');
  }
}
```

### Important Notes

- **iOS 16.0+ Required**: External purchase links only work on iOS 16.0 and later
- **No Purchase Callback**: The purchase listeners will NOT fire when using external URLs
- **Deep Link Required**: Implement deep linking to return users to your app after purchase
- **Manual Validation**: You must validate purchases on your backend server

### Complete iOS Example

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

class AlternativeBillingScreen extends StatefulWidget {
  @override
  _AlternativeBillingScreenState createState() => _AlternativeBillingScreenState();
}

class _AlternativeBillingScreenState extends State<AlternativeBillingScreen> {
  final _iap = FlutterInappPurchase.instance;

  Future<void> _handleIOSAlternativeBilling() async {
    if (!Platform.isIOS) return;

    try {
      final result = await _iap.presentExternalPurchaseLinkIOS(
        'https://your-site.com/checkout',
      );

      if (result.error != null) {
        _showDialog('Error', result.error!);
      } else if (result.success) {
        _showDialog(
          'Redirected',
          'Complete your purchase on the external website. '
          'You will be redirected back to the app.',
        );
      } else {
        print('User cancelled');
      }
    } catch (e) {
      _showDialog('Error', e.toString());
    }
  }

  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Alternative Billing')),
      body: Center(
        child: ElevatedButton(
          onPressed: _handleIOSAlternativeBilling,
          child: Text('Purchase with Alternative Billing'),
        ),
      ),
    );
  }
}
```

## Android Alternative Billing

Android supports two alternative billing modes:

1. **Alternative Billing Only**: Users can ONLY use your payment system
2. **User Choice Billing**: Users choose between Google Play or your payment system

### Configuration

Initialize the connection with the desired billing mode:

```dart
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

// Initialize with Alternative Billing Only mode
await FlutterInappPurchase.instance.initConnection(
  alternativeBillingModeAndroid: AlternativeBillingModeAndroid.AlternativeOnly,
);

// Or with User Choice mode
await FlutterInappPurchase.instance.initConnection(
  alternativeBillingModeAndroid: AlternativeBillingModeAndroid.UserChoice,
);
```

### Mode 1: Alternative Billing Only

This mode requires a manual 3-step flow:

```dart
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

Future<void> handleAlternativeBillingOnly(Product product) async {
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

    // Step 4: Report token to Google Play backend within 24 hours
    await reportToGoogleBackend(token);

    print('Alternative billing completed');
  } catch (e) {
    print('Alternative billing error: $e');
  }
}
```

### Mode 2: User Choice Billing

With user choice, the purchase flow automatically handles the billing selection:

```dart
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

class UserChoiceBillingScreen extends StatefulWidget {
  @override
  _UserChoiceBillingScreenState createState() => _UserChoiceBillingScreenState();
}

class _UserChoiceBillingScreenState extends State<UserChoiceBillingScreen> {
  final _iap = FlutterInappPurchase.instance;
  StreamSubscription<Purchase>? _purchaseSubscription;
  StreamSubscription<UserChoiceBillingResult>? _userChoiceSubscription;

  @override
  void initState() {
    super.initState();
    _initConnection();
  }

  Future<void> _initConnection() async {
    // Initialize with User Choice mode
    await _iap.initConnection(
      alternativeBillingModeAndroid: AlternativeBillingModeAndroid.UserChoice,
    );

    // Listen for Google Play purchases
    _purchaseSubscription = _iap.purchaseUpdatedListener.listen((purchase) {
      print('Google Play purchase: ${purchase.productId}');
      // Handle Google Play purchase
    });

    // Listen for alternative billing selections
    _userChoiceSubscription = _iap.userChoiceBillingListener.listen((result) {
      print('User selected alternative billing');
      // Handle alternative billing flow
    });
  }

  Future<void> _handlePurchase(String productId) async {
    try {
      // Request purchase - Google will show selection dialog
      await _iap.requestPurchase(
        RequestPurchaseProps.inApp((
          google: RequestPurchaseAndroidProps(skus: [productId]),
          useAlternativeBilling: true,
        )),
      );

      // If user selects Google Play: purchaseUpdatedListener fires
      // If user selects alternative: userChoiceBillingListener fires
    } catch (e) {
      print('Purchase error: $e');
    }
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    _userChoiceSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('User Choice Billing')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _handlePurchase('product_id'),
          child: Text('Purchase with User Choice'),
        ),
      ),
    );
  }
}
```

### Using Builder Pattern

```dart
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

// Alternative Billing with builder pattern
await FlutterInappPurchase.instance.requestPurchaseWithBuilder(
  build: (RequestPurchaseBuilder r) => r
    ..type = ProductType.InApp
    ..useAlternativeBilling = true  // Enable alternative billing
    ..withAndroid((RequestPurchaseAndroidBuilder a) =>
      a..skus = ['product_id']),
);

// Regular purchase (no alternative billing)
await FlutterInappPurchase.instance.requestPurchaseWithBuilder(
  build: (RequestPurchaseBuilder r) => r
    ..type = ProductType.InApp
    // useAlternativeBilling defaults to false
    ..withAndroid((RequestPurchaseAndroidBuilder a) =>
      a..skus = ['product_id']),
);
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

  // Enable during initConnection
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


## Best Practices

### General

1. **Backend Validation**: Always validate purchases on your backend server
2. **Clear Communication**: Inform users they're leaving the app for external payment
3. **Deep Linking**: Implement deep links to return users to your app (iOS)
4. **Error Handling**: Handle all error cases gracefully

### iOS Specific

1. **iOS Version Check**: Verify iOS 16.0+ before enabling alternative billing
2. **URL Validation**: Ensure external URLs are valid and secure (HTTPS)
3. **No Purchase Events**: Don't rely on purchase listeners when using external URLs
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

#### "External URL not opening"

- Check URL format (must be valid HTTPS)
- Verify `presentExternalPurchaseLinkIOS` is called

#### "User stuck on external site"

- Implement deep linking to return to app
- Test deep link handling

### Android Issues

#### "Alternative billing not available"

- Verify Google Play approval
- Check device and Play Store version
- Ensure billing mode is configured

#### "Token creation failed"

- Verify product ID is correct
- Check billing mode configuration
- Ensure user completed info dialog

#### "User choice dialog not showing"

- Verify `alternativeBillingModeAndroid: UserChoice`
- Ensure `useAlternativeBilling: true` in request
- Check Google Play configuration

## Platform Requirements

- **iOS**: iOS 16.0+ for external purchase URLs
- **Android**: Google Play Billing Library 5.0+ with alternative billing enabled
- **Approval**: Both platforms require approval for alternative billing features

## See Also

- [OpenIAP Alternative Billing Specification](https://www.openiap.dev/docs/apis#alternative-billing)
- [Alternative Billing Example](https://github.com/hyochan/flutter_inapp_purchase/tree/main/example)
