---
sidebar_position: 9
title: Troubleshooting
---

# Troubleshooting

Common issues and solutions when working with flutter_inapp_purchase v6.7.0.

## Transaction ID Issues

### Simple Sequential IDs (1, 2, 3) in Testing

**Problem**: Transaction IDs appear as simple numbers like 1, 2, 3 instead of proper secure IDs.

**Cause**: You're using StoreKit Configuration file for local testing.

**Solution**: Switch to Sandbox testing for realistic transaction IDs:

1. **Remove StoreKit Configuration** from Xcode scheme:

   ```xml
   <!-- Remove this from Runner.xcscheme -->
   <StoreKitConfigurationFileReference
      identifier = "../Runner/StoreKit.storekit">
   </StoreKitConfigurationFileReference>
   ```

2. **Use Sandbox Environment**:
   - Create sandbox test account in App Store Connect
   - Sign in with test account on device
   - Transaction IDs will be realistic: `2000000985615347`

### Transaction ID Formats by Environment

| Environment            | Transaction ID Format | Example            |
| ---------------------- | --------------------- | ------------------ |
| StoreKit Configuration | Sequential numbers    | `1`, `2`, `3`      |
| Sandbox                | Large secure numbers  | `2000000985615347` |
| Production             | Large secure numbers  | `2000000891234567` |

### Duplicate finishTransaction Calls

**Problem**: "finished transaction successfully" appears twice.

**Cause**: Both purchase method and transaction listener send duplicate events.

**Solution**: This is fixed in v6.x with duplicate event prevention.

```dart
// v6.x automatically prevents duplicate events
final purchase = await FlutterInappPurchase.instance.requestPurchase(
  RequestPurchase(ios: RequestPurchaseIOS(sku: 'product_id'))
);
// Only one completion event will fire
```

## Purchase Token Issues

### iOS purchaseToken is null

**Problem**: `purchaseToken` is null on iOS in older versions.

**Solution**: Upgrade to v6.x which includes JWS representation:

```dart
// v6.x - purchaseToken now available on iOS
purchase.purchaseToken; // Contains JWS for server validation

// DEPRECATED - use purchaseToken instead
purchase.jwsRepresentationIOS; // [DEPRECATED] Use purchaseToken instead
```

### Server Validation with Unified Token

**New in v6.x**: Use the same `purchaseToken` field for both platforms:

```dart
// Cross-platform server validation
void validatePurchase(Purchase purchase) {
  final token = purchase.purchaseToken; // Works on both iOS & Android

  if (purchase.platform == IapPlatform.ios) {
    // token contains JWS (JWT format)
    validateWithApple(token);
  } else {
    // token contains Google Play purchase token
    validateWithGoogle(token);
  }
}
```

## Prerequisites Checklist

Before troubleshooting, ensure you have completed the basic setup:

### Flutter Setup

- [ ] Flutter SDK 3.0.0 or higher
- [ ] Dart SDK 2.17.0 or higher
- [ ] flutter_inapp_purchase v6.x added to `pubspec.yaml`
- [ ] Run `flutter pub get` after adding dependency

### Project Configuration

- [ ] Minimum SDK versions set correctly:
  - Android: `minSdkVersion 21` or higher
  - iOS: `ios.deploymentTarget = '12.0'` or higher
- [ ] Platform-specific permissions configured
- [ ] Bundle ID matches store configuration

```yaml
# pubspec.yaml
dependencies:
  flutter_inapp_purchase: ^6.0.0

# android/app/build.gradle
android {
    compileSdkVersion 34
    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 34
    }
}

# ios/Runner.xcodeproj/project.pbxproj
IPHONEOS_DEPLOYMENT_TARGET = 12.0;
```

## App Store Setup (iOS)

### Required Configurations

1. **App Store Connect Setup**

   - [ ] App registered in App Store Connect
   - [ ] Bundle ID matches your app
   - [ ] In-App Purchases configured and approved
   - [ ] Test users added to sandbox

2. **Xcode Configuration**

   - [ ] In-App Purchase capability enabled
   - [ ] Code signing configured
   - [ ] Bundle ID matches App Store Connect

3. **Product Configuration**
   - [ ] Product IDs match exactly (case-sensitive)
   - [ ] Products are in "Ready to Submit" status
   - [ ] At least one screenshot uploaded per product

```dart
// Verify your product IDs match exactly
final productIds = [
  'com.yourapp.premium',     // Must match App Store Connect
  'com.yourapp.coins_100',   // Case-sensitive
];

// Test with actual product IDs from App Store Connect
final result = await FlutterInappPurchase.instance.fetchProducts(
  ProductRequest(
    skus: productIds,
    type: ProductQueryType.InApp,
  ),
);
final products = result.inAppProducts();
debugPrint('Found ${products.length} products');
```

## Google Play Setup (Android)

### Required Configurations

1. **Google Play Console Setup**

   - [ ] App uploaded to Play Console (at least Internal Testing)
   - [ ] In-app products created and activated
   - [ ] License testing accounts configured
   - [ ] App bundle signed and uploaded

2. **Android Configuration**

   - [ ] `BILLING` permission in AndroidManifest.xml
   - [ ] Play Billing Library dependency (handled by plugin)
   - [ ] ProGuard rules configured if using code obfuscation

3. **Testing Setup**
   - [ ] License testing accounts added in Play Console
   - [ ] Test using signed APK/AAB (not debug build)
   - [ ] Products are "Active" in Play Console

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<uses-permission android:name="com.android.vending.BILLING" />
```

```dart
// Test connection on Android
Future<void> testAndroidConnection() async {
  try {
    final result = await FlutterInappPurchase.instance.initConnection();
    debugPrint('Android connection result: $result');

    // Test product loading
    final result = await FlutterInappPurchase.instance.fetchProducts(
      ProductRequest(
        skus: ['your_product_id_from_play_console'],
        type: ProductQueryType.InApp,
      ),
    );
    final products = result.inAppProducts();
    debugPrint('Loaded ${products.length} products');
  } catch (e) {
    debugPrint('Android connection failed: $e');
  }
}
```

## Common Issues

### fetchProducts() returns an empty array

**Symptoms:**

- `fetchProducts()` returns empty list
- Products configured in store but not loading

**Solutions:**

```dart
class ProductLoadingTroubleshooter {
  static Future<void> diagnoseProductLoading() async {
    final productIds = ['your.product.id'];

    // 1. Check connection first
    final connected = await _ensureConnection();
    if (!connected) {
      debugPrint('❌ Store not connected');
      return;
    }

    // 2. Try loading products with error handling
    try {
      await FlutterInappPurchase.instance.fetchProducts(
        skus: productIds,
        type: PurchaseType.inapp,
      );

      final result = await FlutterInappPurchase.instance.fetchProducts(
        ProductRequest(
          skus: productIds,
          type: ProductQueryType.InApp,
        ),
      );
      final products = result.inAppProducts();

      if (products.isEmpty) {
        debugPrint('❌ No products loaded');
        await _diagnoseEmptyProducts(productIds);
      } else {
        debugPrint('✅ Loaded ${products.length} products');
        for (final product in products) {
          debugPrint('Product: ${product.productId} - ${product.title}');
        }
      }
    } catch (e) {
      debugPrint('❌ Product loading error: $e');
    }
  }

  static Future<void> _diagnoseEmptyProducts(List<String> productIds) async {
    debugPrint('Diagnosing empty product list...');

    // Check product ID format
    for (final id in productIds) {
      debugPrint('Checking product ID: $id');

      if (Platform.isIOS) {
        // iOS product IDs should not contain bundle ID
        if (id.contains('.')) {
          debugPrint('⚠️ iOS product ID contains dots - verify format');
        }
      } else if (Platform.isAndroid) {
        // Android product IDs are typically reverse domain notation
        if (!id.contains('.')) {
          debugPrint('⚠️ Android product ID missing dots - verify format');
        }
      }
    }

    // Suggest solutions
    debugPrint('\n🔧 Troubleshooting steps:');
    debugPrint('1. Verify product IDs match store configuration exactly');
    debugPrint('2. Check if products are approved/active in store');
    debugPrint('3. Ensure app version matches store configuration');
    debugPrint('4. Try with test product IDs first');
  }
}
```

### Purchase flow issues

**Common purchase problems and solutions:**

```dart
class PurchaseFlowTroubleshooter {
  static void setupComprehensivePurchaseFlow() {
    // 1. Set up listeners BEFORE making purchases
    FlutterInappPurchase.purchaseUpdated.listen((purchase) {
      if (purchase != null) {
        debugPrint('✅ Purchase successful: ${purchase.productId}');
        _handlePurchaseSuccess(purchase);
      }
    });

    FlutterInappPurchase.purchaseError.listen((error) {
      if (error != null) {
        debugPrint('❌ Purchase error: ${error.message}');
        _handlePurchaseError(error);
      }
    });
  }

  static Future<void> makePurchaseWithDiagnostics(String productId) async {
    debugPrint('🛒 Initiating purchase for: $productId');

    try {
      // Pre-purchase checks
      final connected = await _verifyConnection();
      if (!connected) {
        throw Exception('Store not connected');
      }

      final productExists = await _verifyProduct(productId);
      if (!productExists) {
        throw Exception('Product not found: $productId');
      }

      // Make purchase
      await FlutterInappPurchase.instance.requestPurchase(
        request: RequestPurchase(
          ios: RequestPurchaseIOS(sku: productId, quantity: 1),
          android: RequestPurchaseAndroid(skus: [productId]),
        ),
        type: PurchaseType.inapp,
      );

      debugPrint('📱 Purchase dialog should appear now');

    } catch (e) {
      debugPrint('❌ Purchase initiation failed: $e');
      _suggestPurchaseSolutions(e);
    }
  }

  static void _handlePurchaseError(PurchaseResult error) {
    switch (error.responseCode) {
      case 1:
        debugPrint('User cancelled purchase');
        break;
      case 7:
        debugPrint('User already owns this item - consuming...');
        _handleAlreadyOwned(error);
        break;
      default:
        debugPrint('Purchase error ${error.responseCode}: ${error.message}');
    }
  }
}
```

### Connection issues

**Connection problems and diagnostics:**

```dart
class ConnectionDiagnostics {
  static Future<void> runConnectionDiagnostics() async {
    debugPrint('🔍 Running connection diagnostics...');

    // Test 1: Basic connection
    try {
      await FlutterInappPurchase.instance.initConnection();
      debugPrint('✅ Basic connection successful');
    } catch (e) {
      debugPrint('❌ Basic connection failed: $e');
      return;
    }

    // Test 2: Platform-specific checks
    if (Platform.isIOS) {
      await _checkIOSConnection();
    } else if (Platform.isAndroid) {
      debugPrint('🤖 Android connection established via initConnection()');
      debugPrint('💡 Use connectionUpdated stream for ongoing state changes.');
    }

    // Test 3: Product loading test
    await _testProductLoading();
  }

  static Future<void> _checkIOSConnection() async {
    debugPrint('🍎 Checking iOS connection...');

    try {
      // Check if payments are allowed
      final canMakePayments = await FlutterInappPurchase.instance.initialize();
      if (!canMakePayments) {
        debugPrint('❌ Device cannot make payments');
        debugPrint('💡 Check: Screen Time restrictions, parental controls');
        return;
      }

      debugPrint('✅ iOS payments are allowed');
    } catch (e) {
      debugPrint('❌ iOS connection check failed: $e');
    }
  }

}
```

### iOS Purchase State Detection Issues

**Problem**: iOS purchases succeed but UI remains stuck in "Processing..." state.

**Symptoms:**

- Purchase logs show valid `purchaseToken` and `transactionId`
- `transactionStateIOS` returns `null`
- UI doesn't update to success state
- Transaction completes but user doesn't see confirmation

**Root Cause**: iOS App Store sometimes returns `null` for `transactionStateIOS` even when purchases are successful.

**Solution**: Use enhanced purchase state detection logic:

```dart
Future<void> _handlePurchaseUpdate(Purchase purchase) async {
  bool isPurchased = false;

  if (Platform.isIOS) {
    // Enhanced iOS detection - check multiple conditions
    bool condition1 = purchase.transactionStateIOS == TransactionState.purchased;
    bool condition2 = purchase.purchaseToken != null && purchase.purchaseToken!.isNotEmpty;
    bool condition3 = purchase.transactionId != null && purchase.transactionId!.isNotEmpty;

    // For iOS, any valid token or transaction ID usually indicates success
    isPurchased = condition1 || condition2 || condition3;

    print('iOS purchase state detection:');
    print('  transactionStateIOS == purchased: $condition1');
    print('  has valid purchaseToken: $condition2');
    print('  has valid transactionId: $condition3');
    print('  Final result: $isPurchased');
  }

  if (isPurchased) {
    // Update UI immediately
    setState(() {
      _isProcessing = false;
      _purchaseResult = '✅ Purchase successful';
    });

    // Finish the transaction
    await FlutterInappPurchase.instance.finishTransaction(purchase);
  }
}
```

**Timeout Error Handling**:

```dart
void _handlePurchaseError(PurchaseError error) {
  if (error.message.contains('요청한 시간이 초과되었습니다') ||
      error.message.contains('timeout')) {
    // Apple server timeout - provide user guidance
    setState(() {
      _purchaseResult = '''
⏱️ Request Timeout - Apple Server Issue

Suggested actions:
1. Check internet connection
2. Wait 2-3 minutes and try again
3. Restart the app
4. Try on different network (WiFi/Cellular)
5. Restart device if problem persists

This is usually temporary.
      ''';
    });
  }
}
```

**See also**: [iOS Purchase State Detection Guide](./ios-purchase-state-detection.md)

### Platform-specific issues

**iOS Specific:**

```dart
class IOSTroubleshooting {
  static Future<void> diagnoseIOSIssues() async {
    debugPrint('🍎 Diagnosing iOS-specific issues...');

    // Check sandbox vs production
    if (kDebugMode) {
      debugPrint('Running in DEBUG mode - using iOS Sandbox');
      debugPrint('💡 Ensure you have sandbox test account signed in');
    } else {
      debugPrint('Running in RELEASE mode - using Production');
    }

    // Check StoreKit availability
    try {
      final promoted = await FlutterInappPurchase.instance.getPromotedProduct();
      debugPrint('StoreKit promotional products available: ${promoted != null}');
    } catch (e) {
      debugPrint('StoreKit check failed: $e');
    }

    // Common iOS issues
    debugPrint('\n🔧 Common iOS solutions:');
    debugPrint('1. Sign out and back into sandbox account in Settings');
    debugPrint('2. Verify products are "Ready to Submit" in App Store Connect');
    debugPrint('3. Check Bundle ID matches exactly');
    debugPrint('4. Ensure In-App Purchase capability is enabled');
  }
}
```

**Android Specific:**

```dart
class AndroidTroubleshooting {
  static Future<void> diagnoseAndroidIssues() async {
    debugPrint('🤖 Diagnosing Android-specific issues...');

    // Check Play Store availability
    try {
      final store = await FlutterInappPurchase.instance.getStorefront();
      debugPrint('Current store: $store');

      if (store != 'play') {
        debugPrint('❌ Not using Google Play Store');
        debugPrint('💡 App must be installed from Play Store for purchases');
      }
    } catch (e) {
      debugPrint('Store check failed: $e');
    }

    // Check if running on signed build
    debugPrint('Build mode: ${kDebugMode ? "DEBUG" : "RELEASE"}');
    if (kDebugMode) {
      debugPrint('⚠️ Debug builds may not work with real products');
      debugPrint('💡 Use signed build for testing real products');
    }

    // Common Android issues
    debugPrint('\n🔧 Common Android solutions:');
    debugPrint('1. Use signed APK/AAB, not debug build');
    debugPrint('2. Add license testing account in Play Console');
    debugPrint('3. Ensure products are "Active" in Play Console');
    debugPrint('4. Upload app to at least Internal Testing track');
  }
}
```

## Debugging Tips

### 1. Enable verbose logging

```dart
class DebugLogging {
  static void enableVerboseLogging() {
    if (kDebugMode) {
      // Log all purchase events
      FlutterInappPurchase.purchaseUpdated.listen((purchase) {
        debugPrint('📱 PURCHASE UPDATE: ${purchase?.toJson()}');
      });

      FlutterInappPurchase.purchaseError.listen((error) {
        debugPrint('❌ PURCHASE ERROR: ${error?.toJson()}');
      });

      FlutterInappPurchase.connectionUpdated.listen((result) {
        debugPrint('🔗 CONNECTION UPDATE: $result');
      });
    }
  }
}
```

### 2. Log purchase events

```dart
class PurchaseEventLogger {
  static void logPurchaseFlow(String step, [Map<String, dynamic>? data]) {
    final timestamp = DateTime.now().toIso8601String();
    debugPrint('[$timestamp] PURCHASE: $step');

    if (data != null) {
      data.forEach((key, value) {
        debugPrint('  $key: $value');
      });
    }
  }

  // Usage
  static void example() {
    logPurchaseFlow('INITIATED', {'productId': 'premium'});
    logPurchaseFlow('DIALOG_SHOWN');
    logPurchaseFlow('COMPLETED', {'transactionId': 'txn_123'});
  }
}
```

### 3. Monitor connection state

```dart
class ConnectionMonitor {
  static void startMonitoring() {
    Timer.periodic(Duration(seconds: 10), (timer) async {
      try {
        final connected = await _checkConnection();
        debugPrint('🔗 Connection status: ${connected ? "CONNECTED" : "DISCONNECTED"}');

        if (!connected) {
          debugPrint('⚠️ Connection lost - attempting reconnect...');
          await FlutterInappPurchase.instance.initConnection();
        }
      } catch (e) {
        debugPrint('❌ Connection check failed: $e');
      }
    });
  }
}
```

## Testing Strategies

### 1. Staged testing approach

```dart
class StagedTesting {
  static Future<void> runStagedTests() async {
    debugPrint('🧪 Starting staged testing...');

    // Stage 1: Connection test
    debugPrint('\n📊 Stage 1: Connection Test');
    final connected = await _testConnection();
    if (!connected) return;

    // Stage 2: Product loading test
    debugPrint('\n📊 Stage 2: Product Loading Test');
    final productsLoaded = await _testProductLoading();
    if (!productsLoaded) return;

    // Stage 3: Purchase flow test
    debugPrint('\n📊 Stage 3: Purchase Flow Test');
    await _testPurchaseFlow();

    debugPrint('\n✅ All tests completed');
  }
}
```

### 2. Test different scenarios

```dart
class ScenarioTesting {
  static Future<void> testAllScenarios() async {
    final scenarios = [
      'first_time_user',
      'returning_user',
      'user_with_existing_purchases',
      'network_interruption',
      'app_backgrounded_during_purchase',
    ];

    for (final scenario in scenarios) {
      debugPrint('🎭 Testing scenario: $scenario');
      await _testScenario(scenario);
    }
  }
}
```

### 3. Device testing matrix

```dart
class DeviceTestMatrix {
  static const testMatrix = {
    'iOS': [
      {'version': '15.0', 'device': 'iPhone 12'},
      {'version': '16.0', 'device': 'iPhone 14'},
      {'version': '17.0', 'device': 'iPhone 15'},
    ],
    'Android': [
      {'version': '11', 'device': 'Pixel 5'},
      {'version': '12', 'device': 'Samsung S22'},
      {'version': '13', 'device': 'Pixel 7'},
    ],
  };

  static void logTestResults(String platform, String version, bool passed) {
    debugPrint('📱 Test Result: $platform $version - ${passed ? "PASSED" : "FAILED"}');
  }
}
```

## Error Code Reference

```dart
class ErrorCodeReference {
  static String getErrorDescription(int code) {
    switch (code) {
      case 0:
        return 'OK - Success';
      case 1:
        return 'User Canceled - User pressed back or canceled a dialog';
      case 2:
        return 'Service Unavailable - Network connection is down';
      case 3:
        return 'Billing Unavailable - Billing API version is not supported';
      case 4:
        return 'Item Unavailable - Requested product is not available';
      case 5:
        return 'Developer Error - Invalid arguments provided to the API';
      case 6:
        return 'Error - Fatal error during the API action';
      case 7:
        return 'Item Already Owned - User already owns the item';
      case 8:
        return 'Item Not Owned - User does not own the item';
      default:
        return 'Unknown Error Code: $code';
    }
  }

  static void logError(PurchaseResult error) {
    debugPrint('❌ Error ${error.responseCode}: ${getErrorDescription(error.responseCode ?? -1)}');
    debugPrint('   Message: ${error.message}');
    debugPrint('   Debug Message: ${error.debugMessage}');
  }
}
```

## Getting Help

### Bug report template

When reporting issues, please include:

````
**Environment:**
- flutter_inapp_purchase version: 6.0.0
- Flutter version: [run `flutter --version`]
- Platform: iOS/Android
- Device/OS version:

**Store Setup:**
- [ ] Products configured in App Store Connect/Play Console
- [ ] App uploaded to store (Internal Testing for Android)
- [ ] Test accounts configured

**Issue Description:**
[Describe what you expected vs what actually happened]

**Code Sample:**
```dart
// Minimal reproducible code
````

**Logs:**

```
// Error logs and debug output
// Enable verbose logging first
```

**Troubleshooting Attempted:**

- [ ] Verified product IDs match store configuration
- [ ] Tested with signed build (Android)
- [ ] Checked connection status
- [ ] Reviewed platform-specific setup

**Additional Context:**
[Any other relevant information]

```

### Debug checklist

Before reporting bugs, verify:

- [ ] Product IDs match store configuration exactly
- [ ] App is properly configured in respective store
- [ ] Using signed build for testing (Android)
- [ ] Connection established before making requests
- [ ] Purchase listeners set up before purchase attempts
- [ ] Error handling implemented
- [ ] Tested on physical device
- [ ] Verbose logging enabled

For additional help:
- Check [GitHub Issues](https://github.com/hyochan/flutter_inapp_purchase/issues)
- Review [API Documentation](../api/flutter-inapp-purchase.md)
- Test with [Example App](https://github.com/hyochan/flutter_inapp_purchase/tree/main/example)
```
