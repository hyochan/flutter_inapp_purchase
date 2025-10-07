---
sidebar_position: 5
title: Offer Code Redemption
---

# Offer Code Redemption

This guide explains how to implement offer code redemption functionality in your app using flutter_inapp_purchase.

## Overview

Offer codes (also known as promo codes or redemption codes) allow users to redeem special offers for in-app purchases and subscriptions. The implementation differs between iOS and Android platforms.

## iOS Implementation

On iOS, flutter_inapp_purchase provides a native method to present Apple's code redemption sheet directly within your app.

### Usage

```dart
import 'dart:io';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

// Present the code redemption sheet
Future<void> presentRedemptionSheet() async {
  if (!Platform.isIOS) {
    print('Offer code redemption is only available on iOS');
    return;
  }

  try {
    await FlutterInappPurchase.instance.presentCodeRedemptionSheetIOS();
    print('Code redemption sheet presented successfully');
    // The system will handle the redemption process
    // Listen for purchase updates via purchaseUpdatedListener
  } catch (error) {
    print('Failed to present code redemption sheet: $error');
  }
}
```

### Important Notes

- This method only works on real iOS devices (not simulators)
- The redemption sheet is handled by the iOS system
- After successful redemption, purchase updates will be delivered through your existing `purchaseUpdatedListener`

## Android Implementation

Google Play does not provide a direct API to redeem codes within the app. Instead, users must redeem codes through the Google Play Store app or website.

### Usage

```dart
import 'dart:io';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

// Open Google Play Store subscription management
Future<void> openPlayStoreRedemption() async {
  if (!Platform.isAndroid) {
    print('This feature is only available on Android');
    return;
  }

  try {
    await FlutterInappPurchase.instance.deepLinkToSubscriptions();
    // This will open the Play Store where users can manage subscriptions
  } catch (error) {
    print('Failed to open Play Store: $error');
  }
}
```

### Alternative Approach

You can also direct users to redeem codes via a custom URL:

```dart
import 'package:url_launcher/url_launcher.dart';

Future<void> redeemCode(String code) async {
  final url = Uri.parse('https://play.google.com/redeem?code=$code');
  if (await canLaunchUrl(url)) {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }
}
```

## Complete Example

Here's a complete example that handles both platforms:

```dart
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

class OfferCodeScreen extends StatefulWidget {
  const OfferCodeScreen({Key? key}) : super(key: key);

  @override
  State<OfferCodeScreen> createState() => _OfferCodeScreenState();
}

class _OfferCodeScreenState extends State<OfferCodeScreen> {
  final _iap = FlutterInappPurchase.instance;
  StreamSubscription<Purchase>? _purchaseSubscription;

  @override
  void initState() {
    super.initState();
    _setupPurchaseListener();
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    super.dispose();
  }

  void _setupPurchaseListener() {
    _purchaseSubscription = _iap.purchaseUpdatedListener.listen(
      (purchase) {
        print('Purchase updated after redemption: ${purchase.productId}');
        // Handle the new purchase/subscription
        _handlePurchase(purchase);
      },
    );
  }

  Future<void> _handlePurchase(Purchase purchase) async {
    // Validate and process the purchase
    await _iap.finishTransaction(
      purchase: purchase,
      isConsumable: false,
    );
  }

  Future<void> handleRedeemCode() async {
    try {
      if (Platform.isIOS) {
        // Present native iOS redemption sheet
        await _iap.presentCodeRedemptionSheetIOS();
        print('Redemption sheet presented');
      } else if (Platform.isAndroid) {
        // Open Play Store for Android
        await _iap.deepLinkToSubscriptions();
      }
    } catch (error) {
      print('Error redeeming code: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Redeem Offer Code'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: handleRedeemCode,
          child: Text(
            Platform.isIOS ? 'Redeem Offer Code' : 'Manage Subscriptions',
          ),
        ),
      ),
    );
  }
}
```

## Best Practices

1. **User Experience**: Clearly communicate to users where they can find and how to use offer codes
2. **Error Handling**: Always wrap redemption calls in try-catch blocks
3. **Platform Detection**: Use platform-specific methods appropriately
4. **Purchase Validation**: Always validate purchases on your server after redemption

## Testing

### iOS Testing

- Offer codes can only be tested on real devices
- Use TestFlight or App Store Connect to generate test codes
- Sandbox environment supports offer code testing

### Android Testing

- Test with promo codes generated in Google Play Console
- Ensure your app is properly configured for in-app purchases

## Troubleshooting

### iOS Issues

- **"Not available on simulator"**: Use a real device for testing
- **Sheet doesn't appear**: Ensure StoreKit is properly configured
- **User cancellation**: This is normal behavior and doesn't throw an error

### Android Issues

- **Play Store doesn't open**: Check if Play Store is installed and updated
- **Invalid code**: Verify the code format and validity in Play Console

## Next Steps

- [Subscription Offers](./subscription-offers) - Handle subscription purchases
- [Error Handling](./error-handling) - Handle redemption errors
- [Troubleshooting](./troubleshooting) - Debug issues
