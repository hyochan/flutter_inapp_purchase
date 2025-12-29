---
sidebar_position: 7
title: Troubleshooting
---

import IapKitBanner from "@site/src/uis/IapKitBanner";

# Troubleshooting

<IapKitBanner />

This guide covers common issues you might encounter when implementing in-app purchases with flutter_inapp_purchase and how to resolve them.

## Prerequisites Checklist

Before diving into troubleshooting, ensure you have completed these essential steps:

### App Store Setup (iOS)

- [ ] Completed all agreements, tax, and banking information in App Store Connect
- [ ] Created sandbox testing accounts in "Users and Roles"
- [ ] Signed into iOS device with sandbox account in "Settings > App Store"
- [ ] Set up In-App Purchase products with status "Ready to Submit"

### Google Play Setup (Android)

- [ ] Completed all required information in Google Play Console
- [ ] Added test accounts to your app's testing track
- [ ] Using signed APK/AAB (not debug builds)
- [ ] Uploaded at least one version to internal testing

## Common Issues

### fetchProducts() returns empty list

This is one of the most common issues. Here are the potential causes and solutions:

#### 1. Connection not established

```dart
class ProductLoader {
  final _iap = FlutterInappPurchase.instance;
  bool _connected = false;

  Future<void> initialize() async {
    _connected = await _iap.initConnection();

    if (_connected) {
      // ✅ Only call fetchProducts when connected
      await loadProducts();
    } else {
      debugPrint('Not connected to store yet');
    }
  }

  Future<void> loadProducts() async {
    final products = await _iap.fetchProducts(
      skus: productIds,
      type: ProductQueryType.inApp,
    );
    debugPrint('Loaded ${products.length} products');
  }
}
```

#### 2. Product IDs don't match

Ensure your product IDs exactly match those configured in the stores:

```dart
// ❌ Wrong: Using different IDs
const productIds = ['my_product_1', 'my_product_2'];

// ✅ Correct: Using exact IDs from store
const productIds = ['com.yourapp.product1', 'com.yourapp.premium'];
```

#### 3. Products not approved (iOS)

Products need time to propagate through Apple's systems:

- Wait up to 24 hours after creating products
- Ensure products are in "Ready to Submit" status
- Test with sandbox accounts

#### 4. App not uploaded to Play Console (Android)

For Android, your app must be uploaded to Play Console:

```bash
# Create signed build
flutter build appbundle --release

# Upload to Play Console internal testing track
```

### Purchase flow issues

#### 1. Purchases not completing

Always handle purchase updates and finish transactions:

```dart
class PurchaseHandler {
  final _iap = FlutterInappPurchase.instance;
  StreamSubscription<Purchase>? _purchaseSubscription;

  void setupListener() {
    _purchaseSubscription = _iap.purchaseUpdatedListener.listen(
      (purchase) async {
        try {
          // Validate receipt
          final isValid = await validateOnServer(purchase);

          if (isValid) {
            // Grant purchase to user
            await grantPurchase(purchase);

            // ✅ Always finish the transaction
            await _iap.finishTransaction(
              purchase: purchase,
              isConsumable: false, // default is false
            );
          }
        } catch (error) {
          debugPrint('Purchase handling failed: $error');
        }
      },
    );
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
  }
}
```

**Important - Transaction Acknowledgment Requirements:**

- **iOS**: Unfinished transactions remain in the queue indefinitely until `finishTransaction` is called
- **Android**: Purchases must be acknowledged within 3 days (72 hours) or they will be automatically refunded
- For **consumable products**: Use `finishTransaction(purchase: purchase, isConsumable: true)`
- For **non-consumables/subscriptions**: Use `finishTransaction(purchase: purchase, isConsumable: false)`

#### 2. Purchase events triggering automatically on app restart (iOS)

This happens when transactions are not properly finished. iOS stores unfinished transactions and replays them on app startup.

**Problem:** Your purchase listener fires automatically every time the app starts with a previous purchase.

**Cause:** You didn't call `finishTransaction` after processing the purchase, so iOS keeps the transaction in an "unfinished" state.

**Solution:** Always call `finishTransaction` after successfully processing a purchase:

```dart
void setupListener() {
  _iap.purchaseUpdatedListener.listen((purchase) async {
    debugPrint('Purchase successful: ${purchase.productId}');

    try {
      // 1. Validate the receipt (Server-side validation required)
      final isValid = await validateReceiptOnServer(purchase);
      if (!isValid) {
        debugPrint('Invalid receipt');
        return;
      }

      // 2. Process the purchase
      await processPurchase(purchase);

      // 3. IMPORTANT: Finish the transaction to prevent replay
      await _iap.finishTransaction(
        purchase: purchase,
        isConsumable: false, // For subscriptions/non-consumables
      );
    } catch (error) {
      debugPrint('Purchase processing failed: $error');
    }
  });
}
```

**Prevention:** Handle pending transactions on app startup:

```dart
Future<void> checkPendingPurchases() async {
  // Get all unfinished transactions
  final purchases = await _iap.getAvailablePurchases();

  for (final purchase in purchases) {
    // If already processed, just finish the transaction
    if (await isAlreadyProcessed(purchase)) {
      await _iap.finishTransaction(purchase: purchase);
    } else {
      // Process the purchase first, then finish
      await processPurchase(purchase);
      await _iap.finishTransaction(purchase: purchase);
    }
  }
}
```

#### 3. Testing on simulators/emulators

In-app purchases only work on real devices:

```dart
import 'dart:io';

Future<bool> checkDeviceSupport() async {
  // iOS simulator check
  if (Platform.isIOS) {
    // Simulators cannot make purchases
    // Use physical device with sandbox account
    return true; // Assume real device in production
  }

  // Android emulator check
  if (Platform.isAndroid) {
    // Google Play must be installed
    return true; // Assume real device in production
  }

  return false;
}
```

### Connection issues

#### 1. Network connectivity

Handle network errors gracefully:

```dart
class ConnectionHandler {
  final _iap = FlutterInappPurchase.instance;
  StreamSubscription<PurchaseError>? _errorSubscription;

  void setupErrorListener() {
    _errorSubscription = _iap.purchaseErrorListener.listen((error) {
      if (error.code == ErrorCode.NetworkError) {
        showRetryDialog();
      }
    });
  }

  void showRetryDialog() {
    // Show user-friendly message
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Connection Error'),
        content: Text('Please check your internet connection'),
        actions: [
          TextButton(
            onPressed: () => retryConnection(),
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }
}
```

#### 2. Store service unavailable

Sometimes store services are temporarily unavailable:

```dart
void handleStoreUnavailable() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Store Unavailable'),
      content: Text('The store is temporarily unavailable. Please try again later.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('OK'),
        ),
      ],
    ),
  );
}
```

## Platform-Specific Issues

### iOS Issues

**Invalid product ID error:**

- Ensure you're signed in with sandbox account
- Check product IDs match exactly
- Verify app bundle ID matches

**StoreKit configuration:**

- Add StoreKit capability in Xcode
- Ensure proper iOS deployment target (15.0+)

### Android Issues

**Billing client setup:**

```gradle
// android/app/build.gradle
dependencies {
  implementation 'com.android.billingclient:billing:6.0.1'
}
```

**Missing permissions:**

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<uses-permission android:name="com.android.vending.BILLING" />
```

## Debugging Tips

### 1. Enable verbose logging

```dart
void setupDebugging() {
  if (kDebugMode) {
    // Use debugPrint throughout your implementation
    debugPrint('IAP Debug mode enabled');
  }
}
```

### 2. Log purchase events

```dart
void setupPurchaseListener() {
  _iap.purchaseUpdatedListener.listen((purchase) {
    debugPrint('Purchase received: ${purchase.toJson()}');
  });

  _iap.purchaseErrorListener.listen((error) {
    debugPrint('Purchase error: ${error.code?.name} - ${error.message}');
  });
}
```

### 3. Monitor connection state

```dart
Future<void> initializeAndLog() async {
  try {
    final connected = await _iap.initConnection();
    debugPrint('Connection state: $connected');
  } catch (error) {
    debugPrint('Connection failed: $error');
  }
}
```

## Testing Strategies

### 1. Staged testing approach

1. **Unit tests**: Test your purchase logic without actual store calls
2. **Sandbox testing**: Use store sandbox/test accounts
3. **Internal testing**: Test with real store in closed testing
4. **Production testing**: Final verification in live environment

### 2. Test different scenarios

```dart
final testScenarios = [
  'successful_purchase',
  'user_cancelled',
  'network_error',
  'insufficient_funds',
  'product_unavailable',
  'pending_purchase',
];
```

### 3. Device testing matrix

Test on various devices and OS versions:

- **iOS**: Different iPhone/iPad models, iOS versions
- **Android**: Different manufacturers, Android versions, Play Services versions

## Error Code Reference

Common error codes and their meanings:

| Code | Description | Action |
|------|-------------|--------|
| `ErrorCode.UserCancelled` | User cancelled purchase | No action needed |
| `ErrorCode.NetworkError` | Network connectivity issue | Show retry option |
| `ErrorCode.ItemUnavailable` | Product not available | Check product setup |
| `ErrorCode.AlreadyOwned` | User already owns product | Check ownership status |
| `ErrorCode.Unknown` | Unknown error | Log for investigation |

See [Error Codes](../api/error-codes) for complete reference.

## Getting Help

If you're still experiencing issues:

1. **Check logs**: Review device logs and crash reports
2. **Search issues**: Check the [GitHub issues](https://github.com/dooboolab-community/flutter_inapp_purchase/issues)
3. **Minimal reproduction**: Create a minimal example that reproduces the issue
4. **Report bug**: File a detailed issue with reproduction steps

### Bug Report Template

```markdown
**Environment:**
- flutter_inapp_purchase version: x.x.x
- Platform: iOS/Android
- OS version: x.x.x
- Device: Device model
- Flutter version: x.x.x

**Description:**
Clear description of the issue

**Steps to reproduce:**
1. Step 1
2. Step 2
3. Step 3

**Expected behavior:**
What should happen

**Actual behavior:**
What actually happens

**Logs:**
Relevant logs and error messages
```

## Next Steps

- [Error Handling](./error-handling) - Handle errors gracefully
- [FAQ](./faq) - Frequently asked questions
- [Support](./support) - Get additional help
