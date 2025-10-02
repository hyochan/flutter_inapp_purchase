---
sidebar_position: 4
---

# Offer Code Redemption

> **Source Code**: [offer_code_screen.dart](https://github.com/hyochan/flutter_inapp_purchase/blob/main/example/lib/src/screens/offer_code_screen.dart)

This example demonstrates how to implement offer code redemption for promotional campaigns (iOS only).

## Key Features

- Present iOS redemption sheet
- Handle offer code validation
- Support promotional campaigns
- Manage redemption flow

## Implementation Overview

### 1. Check Platform Support

```dart
if (!Platform.isIOS) {
  debugPrint('Offer codes are only available on iOS');
  return;
}
```

### 2. Present Redemption Sheet

```dart
try {
  await iap.presentCodeRedemptionSheetIOS();
  debugPrint('Redemption sheet presented');
} catch (e) {
  debugPrint('Failed to present redemption sheet: $e');
}
```

## Use Cases

Offer codes are useful for:

- **Promotional campaigns** - Launch campaigns with special offers
- **Customer retention** - Retain at-risk customers with discounts
- **Win-back campaigns** - Re-engage churned users
- **Special partnerships** - Provide exclusive offers to partners

## Creating Offer Codes

1. Go to App Store Connect
2. Navigate to your app
3. Select "Subscriptions" or "In-App Purchases"
4. Choose "Offer Codes"
5. Create and configure your offer
6. Generate codes for distribution

## Platform Support

:::warning iOS Only
Offer code redemption is only supported on iOS. Android uses promo codes through the Google Play Console instead.
:::

## Best Practices

1. **Verify platform** - Always check for iOS before presenting redemption sheet
2. **Handle errors** - Gracefully handle cases where the sheet cannot be presented
3. **Track redemptions** - Monitor offer code usage through App Store Connect
4. **Clear communication** - Inform users about the redemption process
5. **Test thoroughly** - Use sandbox environment to test offer codes
