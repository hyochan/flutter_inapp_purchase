---
sidebar_position: 8
title: Troubleshooting
---

import IapKitBanner from "@site/src/uis/IapKitBanner";

# Troubleshooting

<IapKitBanner />

Common issues and solutions when implementing in-app purchases with flutter_inapp_purchase.

## Installation & Setup Issues

### Package Installation Problems

**Problem:** `flutter pub get` fails with dependency conflicts

**Solution:**

```bash
# Clear pub cache
flutter pub cache repair

# Clean project
flutter clean
flutter pub get

# For dependency conflicts, try:
flutter pub deps
flutter pub upgrade
```

### iOS Build Issues

**Problem:** Build fails with StoreKit-related errors

**Solution:**
1. Ensure iOS deployment target is 11.0+:

   ```xml
   <!-- ios/Podfile -->
   platform :ios, '11.0'
   ```

2. Clean and rebuild:

   ```bash
   cd ios
   rm -rf Pods Podfile.lock
   pod install
   cd ..
   flutter clean
   flutter build ios
   ```

### Android Build Issues

**Problem:** Build fails with billing library conflicts

**Solution:**
1. Check `android/app/build.gradle` minSdkVersion:

   ```gradle
   defaultConfig {
       minSdkVersion 21  // Required minimum
   }
   ```

2. Add billing permission to `AndroidManifest.xml`:

   ```xml
   <uses-permission android:name="com.android.vending.BILLING" />
   ```

## Connection & Initialization Issues

### "Billing is unavailable" Error

**Problem:** IAP initialization returns "Billing is unavailable"

**Possible Causes & Solutions:**

1. **Google Play Store not installed/updated:**
   - Ensure Google Play Store is installed and updated
   - Test on real device, not emulator

2. **App not uploaded to Play Console:**
   - Upload app to Internal Testing track minimum
   - Wait for processing (can take several hours)

3. **Package name mismatch:**
   ```gradle
   // Ensure android/app/build.gradle applicationId matches Play Console
   defaultConfig {
       applicationId "com.yourcompany.yourapp"
   }
   ```

4. **Developer account issues:**
   - Verify Google Play Developer account is active
   - Complete merchant agreement

### iOS Connection Issues

**Problem:** Connection fails on iOS

**Solutions:**

1. **Sandbox environment:**
   - Test on real device with sandbox account
   - Don't sign in to sandbox account in Settings
   - Only sign in when prompted during purchase

2. **App Store Connect setup:**
   - Verify products are "Ready to Submit"
   - Complete agreements in ASC
   - Wait up to 24 hours for product propagation

## Product Loading Issues

### Products Not Loading

**Problem:** `fetchProducts()` returns empty list

**Debugging Steps:**

1. **Verify product IDs:**
   ```dart
   // Enable debug logging
   FlutterInappPurchase.instance.setDebugMode(true);
   
   // Check exact product ID matching
   final result = await FlutterInappPurchase.instance.fetchProducts(
     ProductRequest(
       skus: ['exact.product.id.from.store'],
       type: ProductQueryType.InApp,
     ),
   );
   final products = result.inAppProducts();
   ```

2. **Check store console:**
   - iOS: Products "Ready to Submit" in App Store Connect
   - Android: Products "Active" in Play Console

3. **Wait for propagation:**
   - New products can take 24+ hours to be available
   - Try with existing, known-working products first

### iOS Products Not Loading

**Specific Solutions:**

1. **Bundle ID verification:**
   ```bash
   # Check bundle ID in Xcode matches App Store Connect
   open ios/Runner.xcworkspace
   ```

2. **Agreements verification:**
   - Check App Store Connect > Agreements, Tax, and Banking
   - Ensure Paid Applications Agreement is active

3. **Product status:**
   - Products must be "Ready to Submit" or "Approved"
   - Check in App Store Connect > Features > In-App Purchases

### Android Products Not Loading

**Specific Solutions:**

1. **App upload requirement:**
   ```bash
   # Build and upload APK/AAB to Play Console
   flutter build appbundle --release
   ```

2. **Package name verification:**
   - Verify `applicationId` in `build.gradle`
   - Must exactly match Play Console

3. **License testing:**
   - Add test accounts in Play Console > Setup > License testing
   - Use test accounts for testing

## Purchase Issues

### Purchase Flow Not Working

**Problem:** Purchase request doesn't trigger system dialog

**Debugging:**

1. **Check initialization:**
   ```dart
   // Ensure IAP is initialized before purchase
   bool initialized = await FlutterInappPurchase.instance.initialize() != null;
   if (!initialized) {
     print('IAP not initialized');
     return;
   }
   ```

2. **Verify product exists:**
   ```dart
   final products = await FlutterInappPurchase.instance.fetchProducts(skus: [productId], type: 'inapp');
   if (products.isEmpty) {
     print('Product not found: $productId');
     return;
   }
   ```

3. **Check purchase listeners:**
   ```dart
   // Ensure listeners are set up before purchase
   FlutterInappPurchase.purchaseUpdated.listen((purchase) {
     print('Purchase updated: ${purchase?.productId}');
   });
   
   FlutterInappPurchase.purchaseError.listen((result) {
     print('Purchase error: ${result?.message}');
   });
   ```

### Transaction Not Completing

**Problem:** Purchase succeeds but transaction doesn't complete

**Solution:**
```dart
void _handlePurchaseUpdate(Purchase? purchase) async {
  if (purchase == null) return;
  
  try {
    // IMPORTANT: Always complete transactions
    if (Platform.isIOS) {
      await FlutterInappPurchase.instance.finishTransaction(purchase);
    } else {
      // Android: Choose based on product type
      if (isConsumable(purchase.productId)) {
        await FlutterInappPurchase.instance.consumePurchase(
          purchaseToken: purchase.purchaseToken!,
        );
      } else {
        await FlutterInappPurchase.instance.acknowledgePurchase(
          purchaseToken: purchase.purchaseToken!,
        );
      }
    }
  } catch (e) {
    print('Failed to complete transaction: $e');
  }
}
```

### "Already Owned" Error

**Problem:** Getting "already owned" error on Android

**Solutions:**

1. **Consume previous purchases:**
   ```dart
   // For consumable products
   final purchases = await FlutterInappPurchase.instance.getAvailablePurchases();
   for (final purchase in purchases ?? []) {
     if (isConsumable(purchase.productId!)) {
       await FlutterInappPurchase.instance.consumePurchase(
         purchaseToken: purchase.purchaseToken!,
       );
     }
   }
   ```

2. **Clear test purchases:**
   - In Google Play Store app: Menu > Account > Purchase history
   - Cancel test purchases

## Testing Issues

### Sandbox Testing Problems (iOS)

**Problem:** Sandbox purchases not working

**Solutions:**

1. **Account management:**
   - Create fresh sandbox accounts in App Store Connect
   - Don't sign in to sandbox account in Settings > iTunes & App Store
   - Only sign in when prompted during purchase

2. **Purchase history:**
   - Clear purchase history: Settings > iTunes & App Store > Sandbox Account
   - Use different sandbox accounts for different test scenarios

3. **Network issues:**
   - Test on real device with cellular/different WiFi
   - Sandbox can be unstable, try multiple times

### Test Purchases Not Working (Android)

**Problem:** Test purchases failing on Android

**Solutions:**

1. **License testers:**
   ```
   Play Console > Setup > License testing > License Testers
   Add Gmail accounts for testing
   ```

2. **Test tracks:**
   - Upload app to Internal Testing minimum
   - Join testing program with test account
   - Install from Play Store (not sideload)

3. **Account verification:**
   - Use Gmail account added as license tester
   - Clear Play Store cache/data if needed

## Runtime Errors

### Stream Subscription Errors

**Problem:** Multiple listeners or subscription errors

**Solution:**
```dart
class _MyStoreState extends State<MyStore> {
  StreamSubscription? _purchaseSubscription;
  StreamSubscription? _errorSubscription;
  
  @override
  void initState() {
    super.initState();
    _setupListeners();
  }
  
  void _setupListeners() {
    // Cancel existing subscriptions first
    _purchaseSubscription?.cancel();
    _errorSubscription?.cancel();
    
    _purchaseSubscription = FlutterInappPurchase
        .purchaseUpdated.listen(_handlePurchase);
    
    _errorSubscription = FlutterInappPurchase
        .purchaseError.listen(_handleError);
  }
  
  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    _errorSubscription?.cancel();
    super.dispose();
  }
}
```

### Memory Leaks

**Problem:** App crashes or memory issues

**Solution:** Always clean up resources:
```dart
@override
void dispose() {
  // Cancel all subscriptions
  _purchaseUpdatedSubscription?.cancel();
  _purchaseErrorSubscription?.cancel();
  
  // End IAP connection if needed
  FlutterInappPurchase.instance.endConnection();
  
  super.dispose();
}
```

## Receipt Validation Issues

### iOS Receipt Validation

**Problem:** Receipt validation fails

**Solutions:**

1. **Receipt data retrieval:**
   ```dart
   String? receiptData = await FlutterInappPurchase.instance.getReceiptData();
   if (receiptData == null) {
     print('No receipt data available');
     return;
   }
   ```

2. **Server validation:**
   - Use production URL for live app: `https://buy.itunes.apple.com/verifyReceipt`
   - Use sandbox URL for testing: `https://sandbox.itunes.apple.com/verifyReceipt`

### Android Receipt Validation

**Problem:** Purchase token validation fails

**Solution:**
```dart
// Use Google Play Developer API for server-side validation
// Send purchase token to your server for verification
final purchaseToken = item.purchaseToken;
await validatePurchaseOnServer(purchaseToken, item.productId);
```


## Debug Tools

### Enable Debug Logging

```dart
// Add this for debugging
FlutterInappPurchase.instance.setDebugMode(true);
```

### Check Connection Status

```dart
Future<void> debugConnection() async {
  try {
    final result = await FlutterInappPurchase.instance.initialize();
    print('Connection result: $result');
    
    // Test with known product
    final products = await FlutterInappPurchase.instance
        .fetchProducts(skus: ['android.test.purchased'], type: 'inapp'); // Android test product
    print('Test products: ${products.length}');
  } catch (e) {
    print('Debug error: $e');
  }
}
```

## Getting Help

If you're still experiencing issues:

1. **Check logs:** Enable debug mode and check console logs
2. **Minimal reproduction:** Create minimal example that reproduces issue
3. **Platform testing:** Test on both iOS and Android
4. **Version check:** Ensure you're using latest plugin version
5. **GitHub Issues:** [Report bugs](https://github.com/hyochan/flutter_inapp_purchase/issues) with detailed information

### Issue Report Template

When reporting issues, include:

```
**Platform:** iOS/Android/Both
**Plugin Version:** flutter_inapp_purchase x.x.x
**Flutter Version:** flutter --version output
**Device:** Real device/Simulator/Emulator

**Issue Description:**
Clear description of the problem

**Steps to Reproduce:**
1. Step one
2. Step two
3. Step three

**Expected Behavior:**
What should happen

**Actual Behavior:**
What actually happens

**Logs:**
```
Relevant console output
```

**Sample Code:**
```dart
Minimal code that reproduces the issue
```
```

This comprehensive troubleshooting guide should help developers resolve most common issues with flutter_inapp_purchase.
