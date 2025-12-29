# Alternative Billing Example

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

  Future<void> handlePurchase(BuildContext context) async {
    if (!Platform.isIOS) return;

    try {
      final result = await FlutterInappPurchase.instance
          .presentExternalPurchaseLinkIOS('https://your-site.com/checkout');

      if (result.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${result.error}')),
        );
      } else if (result.success) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Redirected'),
            content: Text(
              'Complete purchase on the external website. '
              'You will be redirected back to the app.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
        );
      } else {
        print('User cancelled');
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
      onPressed: () => handlePurchase(context),
      child: Text('Buy (External URL)'),
    );
  }
}
```

### Important Notes

- **iOS 16.0+ Required**: External URLs only work on iOS 16.0 and later
- **No Callback**: Purchase listeners will NOT fire when using external URLs
- **Deep Linking**: Implement deep linking to return users to your app
- **Manual Validation**: Validate purchases on your backend server

## Android - Alternative Billing Only

Manual 3-step flow for alternative billing only:

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

class AndroidAlternativeBillingOnly extends StatelessWidget {
  final Product product;

  const AndroidAlternativeBillingOnly({required this.product});

  Future<void> handlePurchase(BuildContext context) async {
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

      print('Token created: $token');

      // Step 4: Report token to Google Play backend within 24 hours
      // await reportToGoogleBackend(token);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Success'),
          content: Text('Alternative billing completed (DEMO)'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => handlePurchase(context),
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
  final Product product;

  const AndroidUserChoiceBilling({required this.product});

  @override
  _AndroidUserChoiceBillingState createState() =>
      _AndroidUserChoiceBillingState();
}

class _AndroidUserChoiceBillingState extends State<AndroidUserChoiceBilling> {
  final _iap = FlutterInappPurchase.instance;
  StreamSubscription<Purchase>? _purchaseSubscription;
  StreamSubscription<UserChoiceBillingResult>? _userChoiceSubscription;

  @override
  void initState() {
    super.initState();
    _initConnection();
  }

  Future<void> _initConnection() async {
    // Initialize with user choice mode
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

  Future<void> handlePurchase() async {
    if (!Platform.isAndroid) return;

    try {
      // Google will show selection dialog automatically
      await _iap.requestPurchase(
        RequestPurchaseProps.inApp((
          google: RequestPurchaseAndroidProps(skus: [widget.product.id]),
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
    return ElevatedButton(
      onPressed: handlePurchase,
      child: Text('Buy (User Choice)'),
    );
  }
}
```

### Selection Dialog

- Google shows automatic selection dialog
- User chooses: Google Play (30% fee) or Alternative (lower fee)
- Different callbacks based on user choice

## Using Builder Pattern

Simplified alternative billing with builder pattern:

```dart
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

// Alternative Billing with builder pattern
Future<void> purchaseWithAlternativeBilling(String productId) async {
  await FlutterInappPurchase.instance.requestPurchaseWithBuilder(
    build: (RequestPurchaseBuilder r) => r
      ..type = ProductType.InApp
      ..useAlternativeBilling = true  // Enable alternative billing
      ..withAndroid((RequestPurchaseAndroidBuilder a) =>
        a..skus = [productId]),
  );
}

// Regular purchase (no alternative billing)
Future<void> regularPurchase(String productId) async {
  await FlutterInappPurchase.instance.requestPurchaseWithBuilder(
    build: (RequestPurchaseBuilder r) => r
      ..type = ProductType.InApp
      // useAlternativeBilling defaults to false
      ..withAndroid((RequestPurchaseAndroidBuilder a) =>
        a..skus = [productId]),
  );
}
```

## Configuration

### Connection Initialization

```dart
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

// Initialize with alternative billing mode
await FlutterInappPurchase.instance.initConnection(
  alternativeBillingModeAndroid: AlternativeBillingModeAndroid.AlternativeOnly,
  // or AlternativeBillingModeAndroid.UserChoice
);
```

### Available Modes

```dart
enum AlternativeBillingModeAndroid {
  None,              // Default - no alternative billing
  AlternativeOnly,   // Only your payment system
  UserChoice,        // User chooses between Google Play or your system
}
```

## Testing

### iOS

- Test on iOS 16.0+ devices
- Verify external URL opens in Safari
- Test deep link return flow
- Ensure StoreKit configuration is correct

### Android

- Configure alternative billing in Google Play Console
- Test both modes separately
- Verify token generation and reporting
- Test user choice dialog behavior

## Best Practices

1. **Backend Validation** - Always validate purchases on your server
2. **Clear UI** - Inform users they're leaving the app
3. **Error Handling** - Handle all error cases gracefully
4. **Token Reporting** - Report tokens within 24 hours (Android)
5. **Deep Linking** - Essential for iOS return flow
6. **Mode Selection** - Choose appropriate mode for your use case

## Common Errors

### iOS

- **"Feature not supported"** - Ensure iOS 16.0+ and entitlement approval
- **"External URL not opening"** - Check URL format and configuration
- **"User stuck on external site"** - Implement deep linking

### Android

- **"Alternative billing not available"** - Verify Google Play approval
- **"Token creation failed"** - Check billing mode configuration
- **"User choice dialog not showing"** - Verify mode and configuration

## See Also

- [Alternative Billing Guide](../guides/alternative-billing.md)
- [Error Handling](../guides/error-handling.md)
- [Purchase Flow Example](purchase-flow.md)
- [OpenIAP Alternative Billing Specification](https://www.openiap.dev/docs/apis#alternative-billing)
