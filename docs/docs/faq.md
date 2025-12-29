---
sidebar_position: 9
title: FAQ
---

import IapKitBanner from "@site/src/uis/IapKitBanner";

# Frequently Asked Questions

<IapKitBanner />

Common questions and answers about flutter_inapp_purchase.

## General Questions

### Q: What platforms does flutter_inapp_purchase support?

**A:** The plugin supports:

- **iOS**: 11.0+ with StoreKit
- **Android**: API 21+ (Android 5.0) with Google Play Billing Library v5+
- **macOS**: 10.15+ with StoreKit (limited support)

Windows, Linux, and Web are not supported as they don't have native in-app purchase systems.

### Q: Can I use this plugin with Expo?

**A:** No, this is a Flutter plugin specifically. For Expo/React Native, use [expo-iap](https://github.com/hyochan/expo-iap) instead. However, you can [migrate from expo-iap](./migration/from-expo-iap) if switching to Flutter.

### Q: Is this plugin free to use?

**A:** Yes, flutter_inapp_purchase is open source and free to use under the MIT license. However, both Apple and Google charge fees for in-app purchases (typically 15-30%).

## Setup & Configuration

### Q: Do I need to configure anything in Xcode or Android Studio?

**A:** Yes, minimal setup is required:

**iOS:**

- Enable In-App Purchase capability in Xcode
- Configure products in App Store Connect

**Android:**

- Add `<uses-permission android:name="com.android.vending.BILLING" />` to AndroidManifest.xml
- Configure products in Google Play Console

See our [setup guides](./getting-started/setup-ios) for detailed instructions.

### Q: Can I test purchases without publishing my app?

**A:** Yes:

**iOS:** Use sandbox testing with sandbox Apple IDs
**Android:** Upload to Internal Testing track in Play Console

Both platforms require proper store setup but don't require public app release.

### Q: How long does it take for products to appear after configuration?

**A:** Product availability varies:

- **iOS:** Usually within a few hours, up to 24 hours
- **Android:** Can take 24-48 hours after app upload

Products must be properly configured and approved in the respective stores.

## Products & Subscriptions

### Q: What's the difference between consumable and non-consumable products?

**A:**

- **Consumable**: Can be purchased multiple times (coins, gems, power-ups)
- **Non-consumable**: Purchased once, owned forever (remove ads, premium features)
- **Subscriptions**: Recurring purchases with auto-renewal

### Q: How do I handle different product types?

**A:** Use different completion methods:

```dart
if (Platform.isIOS) {
  // iOS: Always finish transaction
  await FlutterInappPurchase.instance.finishTransaction(
    purchase: item,
    isConsumable: isConsumable,
  );
} else {
  // Android: Consume or acknowledge
  if (isConsumable) {
    await FlutterInappPurchase.instance.consumePurchaseAndroid(
      purchaseToken: item.purchaseToken!,
    );
  } else {
    await FlutterInappPurchase.instance.acknowledgePurchaseAndroid(
      purchaseToken: item.purchaseToken!,
    );
  }
}
```

### Q: Can I offer subscription trials?

**A:** Yes, but setup varies by platform:

- **iOS:** Configure introductory offers in App Store Connect
- **Android:** Configure free trials in Play Console

The plugin will return trial information in the product data.

### Q: How do I handle subscription renewals?

**A:** Subscriptions auto-renew by default. To check status:

```dart
final purchases = await FlutterInappPurchase.instance.getAvailablePurchases();
final activeSubscriptions = purchases.where((p) =>
  subscriptionIds.contains(p.productId) && isActive(p));
```

Implement server-side receipt validation for accurate expiration checking.

## Purchases & Transactions

### Q: Why isn't my purchase completing?

**A:** Common causes:

1. **Not finishing transactions:** Always call `finishTransaction` (iOS) or `consumePurchase`/`acknowledgePurchase` (Android)
2. **No purchase listeners:** Set up stream listeners before requesting purchases
3. **Network issues:** Ensure device has internet connectivity
4. **Account issues:** Verify store account is properly set up

### Q: How do I restore purchases?

**A:** Use `getAvailablePurchases()`:

```dart
Future<void> restorePurchases() async {
  try {
    final purchases = await FlutterInappPurchase.instance.getAvailablePurchases();

    for (final purchase in purchases) {
      // Re-deliver non-consumable products
      if (isNonConsumable(purchase.productId)) {
        await deliverProduct(purchase);
      }
    }
  } catch (e) {
    print('Restore failed: $e');
  }
}
```

### Q: Can users purchase the same product multiple times?

**A:** Depends on product type:

- **Consumable:** Yes, after consuming previous purchase
- **Non-consumable:** No, will get "already owned" error
- **Subscription:** Can upgrade/downgrade, but not duplicate

### Q: How do I handle pending purchases?

**A:** Purchases can be pending for various payment methods (v8.2.0+ uses unified `purchaseState`):

```dart
void _handlePurchaseUpdate(Purchase? item) {
  if (item == null) return;

  // Check unified purchase state (v8.2.0+)
  switch (item.purchaseState) {
    case PurchaseState.Purchased:
      // Purchase completed
      _deliverProduct(item);
      break;
    case PurchaseState.Pending:
      // Purchase pending - show pending UI
      _showPendingMessage();
      break;
    case PurchaseState.Unknown:
      // Handle unknown state
      break;
  }
}
```

## Security & Validation

### Q: Do I need to validate receipts?

**A:** Yes, for production apps you should always validate receipts server-side to prevent fraud. The plugin provides receipt data, but validation must be implemented separately.

### Q: How do I validate iOS receipts?

**A:** Send receipt to Apple's verification servers:

```dart
// Get receipt data
String? receiptData = await FlutterInappPurchase.instance.getReceiptData();

// Send to your server for validation with Apple
await validateReceiptOnServer(receiptData);
```

### Q: How do I validate Android purchases?

**A:** Use the purchase token with Google Play Developer API:

```dart
// Get purchase token
String? token = item.purchaseToken;

// Validate on your server using Google Play Developer API
await validateTokenOnServer(token, item.productId);
```

### Q: Can I trust client-side purchase data?

**A:** No, never trust client-side data for security-critical operations. Always validate receipts server-side before granting paid content.

## Error Handling

### Q: What does "Billing is unavailable" mean?

**A:** This indicates the billing system isn't ready. Common causes:

- Google Play Store not installed/updated (Android)
- App not uploaded to store (Android)
- Network connectivity issues
- Store service temporarily unavailable

### Q: Why do I get "Product not found" errors?

**A:** Product ID mismatches are common:

- Verify exact product ID spelling
- Check product is active in store console
- Wait for product propagation (up to 24 hours)
- Ensure app bundle ID matches store configuration

### Q: How do I handle purchase cancellations?

**A:** Listen for specific error codes:

```dart
FlutterInappPurchase.instance.purchaseError.listen((error) {
  if (error?.code == ErrorCode.UserCancelled) {
    // User cancelled - no error message needed
  } else {
    // Show error message
    showErrorDialog(error?.message);
  }
});
```

## Development & Testing

### Q: Can I test purchases on simulators/emulators?

**A:**

- **iOS Simulator:** Limited support, use StoreKit testing
- **Android Emulator:** Not recommended, use real devices
- **Best practice:** Always test on real devices with test accounts

### Q: How do I test subscriptions?

**A:** Both platforms offer accelerated testing:

- **iOS:** Subscriptions renew every few minutes in sandbox
- **Android:** Test subscriptions renew quickly in test environment

### Q: Do test purchases cost real money?

**A:** No:

- **iOS:** Sandbox purchases are free
- **Android:** License tester purchases are free and auto-refund

### Q: How do I clear test purchase history?

**A:**

- **iOS:** Settings > iTunes & App Store > Sandbox Account > Reset
- **Android:** Google Play Store > Account > Purchase history (cancel test purchases)

## Performance & Best Practices

### Q: When should I initialize the IAP connection?

**A:** Initialize as early as possible, typically in your app's main entry point or store screen initialization. Don't initialize on every screen.

### Q: How do I handle app lifecycle events?

**A:** Clean up properly:

```dart
@override
void dispose() {
  _purchaseSubscription?.cancel();
  _errorSubscription?.cancel();
  FlutterInappPurchase.instance.endConnection();
  super.dispose();
}
```

## Troubleshooting

### Q: My app was rejected for IAP issues. What should I check?

**A:** Common rejection reasons:

1. **Missing restore functionality:** Always provide restore purchases option
2. **Incorrect product types:** Ensure consumable/non-consumable types match usage
3. **Price display:** Show localized prices from store data
4. **Terms compliance:** Follow platform guidelines for IAP UI

### Q: Why are my products not loading in production but work in testing?

**A:** Check:

1. **App review status:** App must be approved and live
2. **Product review status:** Products must be approved
3. **Regional availability:** Products might not be available in all regions
4. **Time delay:** Products can take 24+ hours to propagate globally

### Q: How do I debug IAP issues?

**A:** Enable debug logging:

```dart
FlutterInappPurchase.instance.setDebugMode(true);
```

Check console output for detailed error information.

## Support & Community

### Q: Where can I get help?

**A:** Multiple support channels:

- [GitHub Issues](https://github.com/hyochan/flutter_inapp_purchase/issues) for bugs
- [GitHub Discussions](https://github.com/hyochan/flutter_inapp_purchase/discussions) for questions
- [Stack Overflow](https://stackoverflow.com/questions/tagged/flutter-inapp-purchase) with `flutter-inapp-purchase` tag
- [Discord Community](https://discord.gg/hyo) for real-time chat

### Q: How do I report bugs?

**A:** Create detailed GitHub issues with:

- Platform and version information
- Steps to reproduce
- Expected vs actual behavior
- Relevant code snippets
- Console logs with debug mode enabled

### Q: Can I contribute to the project?

**A:** Yes! Contributions are welcome:

- Report bugs and issues
- Submit pull requests for fixes
- Improve documentation
- Help answer community questions

See the [Contributing Guide](https://github.com/hyochan/flutter_inapp_purchase/blob/main/CONTRIBUTING.md) for details.

---

**Still have questions?** Check our [Troubleshooting Guide](./troubleshooting) or [open a discussion](https://github.com/hyochan/flutter_inapp_purchase/discussions) on GitHub.
