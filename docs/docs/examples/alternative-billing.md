---
title: Alternative Billing Example
sidebar_label: Alternative Billing
sidebar_position: 5
---

import AdFitTopFixed from "@site/src/uis/AdFitTopFixed";

# Alternative Billing

<AdFitTopFixed />

Use alternative billing to redirect users to external payment systems or offer payment choices alongside platform billing.

View the full example source:

- GitHub: [alternative_billing_screen.dart](https://github.com/hyochan/flutter_inapp_purchase/blob/main/example/lib/src/screens/alternative_billing_screen.dart)

## iOS - External Purchase URL

Redirect users to an external website for payment (iOS 16.0+):

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

class IOSAlternativeBilling extends StatelessWidget {
  final Product product;

  const IOSAlternativeBilling({required this.product});

  Future<void> _handlePurchase(BuildContext context) async {
    if (!Platform.isIOS) return;

    try {
      await FlutterInappPurchase.instance.requestPurchase(
        RequestPurchaseProps.inApp(
          request: RequestPurchasePropsByPlatforms(
            ios: RequestPurchaseIosProps(
              sku: product.id,
              quantity: 1,
            ),
          ),
          useAlternativeBilling: true,
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Complete purchase on the external website. '
            'You will be redirected back to the app.',
          ),
        ),
      );
    } catch (e) {
      if (e is PurchaseError && e.code != ErrorCode.UserCancelled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.message}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _handlePurchase(context),
      child: Text('Buy (External URL)'),
    );
  }
}
```

### iOS Custom URL (iOS 18.2+)

For dynamic URLs or runtime configuration:

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

class IOSCustomUrlPurchase extends StatelessWidget {
  final String externalUrl;

  const IOSCustomUrlPurchase({
    required this.externalUrl,
  });

  Future<void> _handlePurchase(BuildContext context) async {
    if (!Platform.isIOS) return;

    try {
      final result = await FlutterInappPurchase.instance
          .presentExternalPurchaseLinkIOS(externalUrl);

      if (result.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${result.error}')),
        );
      } else if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'User redirected to external website. '
              'Complete purchase there.',
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _handlePurchase(context),
      child: Text('Buy (Custom URL)'),
    );
  }
}
```

### Important Notes

- **iOS 16.0+ Required**: External URLs only work on iOS 16.0 and later
- **iOS 18.2+ for Custom URLs**: `presentExternalPurchaseLinkIOS` requires iOS 18.2+
- **Configuration Required**: External URLs must be configured in Info.plist (see [Alternative Billing Guide](/docs/guides/alternative-billing))
- **No Callback**: Purchase streams will NOT emit when using external URLs
- **Deep Linking**: Implement deep linking to return users to your app

## Android - Alternative Billing Only

Manual 3-step flow for alternative billing only:

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

class AndroidAlternativeBillingOnly extends StatelessWidget {
  final Product product;

  const AndroidAlternativeBillingOnly({required this.product});

  Future<void> _handlePurchase(BuildContext context) async {
    if (!Platform.isAndroid) return;

    try {
      // Step 1: Check availability
      final isAvailable = await FlutterInappPurchase.instance
          .checkAlternativeBillingAvailabilityAndroid();

      if (!isAvailable) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Alternative billing not available')),
        );
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
      print('Processing payment...');

      // Step 3: Create reporting token (after successful payment)
      final token = await FlutterInappPurchase.instance
          .createAlternativeBillingTokenAndroid();

      if (token != null) {
        print('Token created: $token');

        // Step 4: Report token to Google Play backend within 24 hours
        // await reportToGoogleBackend(token);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Alternative billing completed (DEMO)'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _handlePurchase(context),
      child: Text('Buy (Alternative Only)'),
    );
  }
}
```

### Flow Steps

1. **Check availability** - Verify alternative billing is enabled
2. **Show info dialog** - Display Google's information dialog
3. **Process payment** - Handle payment with your system
4. **Create token** - Generate reporting token
5. **Report to Google** - Send token to Google within 24 hours

## Android - User Choice Billing

Let users choose between Google Play and alternative billing:

```dart
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

class AndroidUserChoiceBilling extends StatefulWidget {
  @override
  _AndroidUserChoiceBillingState createState() =>
      _AndroidUserChoiceBillingState();
}

class _AndroidUserChoiceBillingState extends State<AndroidUserChoiceBilling> {
  StreamSubscription? _purchaseSubscription;
  StreamSubscription? _userChoiceSubscription;

  @override
  void initState() {
    super.initState();
    _initConnection();
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    _userChoiceSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initConnection() async {
    await FlutterInappPurchase.instance.initialize();

    if (Platform.isAndroid) {
      await FlutterInappPurchase.instance.initConnection(
        alternativeBillingModeAndroid:
            AlternativeBillingModeAndroid.UserChoice,
      );
    }

    // Listen for Google Play purchases
    _purchaseSubscription =
        FlutterInappPurchase.purchaseUpdated.listen((purchase) {
      if (purchase != null) {
        print('Google Play purchase: ${purchase.productId}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Purchase via Google Play successful')),
        );
      }
    });

    // Listen for alternative billing choices
    _userChoiceSubscription =
        FlutterInappPurchase.userChoiceBillingAndroid.listen((details) {
      print('User selected alternative billing');
      print('Products: ${details.products}');
      print('Token: ${details.externalTransactionToken}');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'User selected alternative billing. '
            'Process payment with your system.',
          ),
        ),
      );
    });
  }

  Future<void> _handlePurchase(Product product) async {
    if (!Platform.isAndroid) return;

    try {
      // Google will show selection dialog automatically
      await FlutterInappPurchase.instance.requestPurchase(
        RequestPurchaseProps.inApp(
          request: RequestPurchasePropsByPlatforms(
            android: RequestPurchaseAndroidProps(skus: [product.id]),
          ),
          useAlternativeBilling: true,
        ),
      );

      // If user selects Google Play: purchaseUpdated stream
      // If user selects alternative: userChoiceBillingAndroid stream
    } catch (e) {
      print('Purchase error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _handlePurchase(/* your product */),
      child: Text('Buy (User Choice)'),
    );
  }
}
```

### Selection Dialog

- Google shows automatic selection dialog
- User chooses: Google Play (30% fee) or Alternative (lower fee)
- Different callbacks based on user choice


## Configuration

### Initialize with Alternative Billing Mode

```dart
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'dart:io';

Future<void> initializeWithAlternativeBilling() async {
  await FlutterInappPurchase.instance.initialize();

  if (Platform.isAndroid) {
    await FlutterInappPurchase.instance.initConnection(
      alternativeBillingModeAndroid:
          AlternativeBillingModeAndroid.AlternativeOnly, // or UserChoice
    );
  } else {
    await FlutterInappPurchase.instance.initConnection();
  }
}
```

## Testing

### iOS

- Test on iOS 16.0+ devices
- Verify external URL opens in Safari
- Test deep link return flow
- Ensure Info.plist is configured

### Android

- Configure alternative billing in Google Play Console
- Test both modes separately
- Verify token generation
- Test user choice dialog

## Best Practices

1. **Backend Validation** - Always validate on server
2. **Clear UI** - Show users they're leaving the app
3. **Error Handling** - Handle all error cases
4. **Token Reporting** - Report within 24 hours (Android)
5. **Deep Linking** - Essential for iOS return flow

## See Also

- [Alternative Billing Guide](/docs/guides/alternative-billing)
- [Error Handling](/docs/guides/error-handling)
- [Purchase Flow](/docs/examples/purchase-flow)
