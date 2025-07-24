---
sidebar_position: 9
title: Troubleshooting
---

<<<<<<< HEAD
# Troubleshooting

Common issues and solutions when working with flutter_inapp_purchase v6.0.0.

## Prerequisites Checklist

Before troubleshooting, ensure you have completed the basic setup:

### Flutter Setup
- [ ] Flutter SDK 3.0.0 or higher
- [ ] Dart SDK 2.17.0 or higher
- [ ] flutter_inapp_purchase v6.0.0 added to `pubspec.yaml`
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
final products = await FlutterInappPurchase.instance.getProducts(productIds);
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
    final products = await FlutterInappPurchase.instance.getProducts([
      'your_product_id_from_play_console'
    ]);
    debugPrint('Loaded ${products.length} products');
  } catch (e) {
    debugPrint('Android connection failed: $e');
=======
# Troubleshooting Guide

Comprehensive troubleshooting guide for common issues with flutter_inapp_purchase v6.0.0, including solutions, debugging techniques, and platform-specific problems.

## Common Issues

### Connection Issues

#### Problem: "Failed to initialize connection"

**Symptoms:**
- `initConnection()` throws an exception
- Store connection cannot be established
- Error: "Billing service unavailable"

**Solutions:**

```dart
class ConnectionTroubleshooter {
  static Future<void> diagnoseConnectionIssue() async {
    final _iap = FlutterInappPurchase.instance;
    
    try {
      // 1. Check network connectivity
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        print('No network connection');
        return;
      }
      
      // 2. Check platform-specific requirements
      if (Platform.isAndroid) {
        await _checkAndroidRequirements();
      } else if (Platform.isIOS) {
        await _checkIOSRequirements();
      }
      
      // 3. Attempt connection with retry
      await _connectWithRetry();
      
    } catch (e) {
      print('Connection diagnosis failed: $e');
      _suggestSolutions(e);
    }
  }
  
  static Future<void> _checkAndroidRequirements() async {
    // Check Google Play Services
    try {
      // Verify Play Store is installed and updated
      final playStoreInstalled = await _isPlayStoreInstalled();
      if (!playStoreInstalled) {
        throw Exception('Google Play Store not installed or disabled');
      }
      
      print('Android requirements check passed');
    } catch (e) {
      print('Android requirements check failed: $e');
      throw e;
    }
  }
  
  static Future<void> _checkIOSRequirements() async {
    // Check iOS configuration
    try {
      // Verify sandbox account for testing
      if (kDebugMode) {
        print('Ensure you are signed in with a sandbox account in Settings > App Store');
      }
      
      // Check StoreKit configuration
      print('iOS requirements check passed');
    } catch (e) {
      print('iOS requirements check failed: $e');
      throw e;
    }
  }
  
  static Future<void> _connectWithRetry() async {
    final _iap = FlutterInappPurchase.instance;
    int attempts = 0;
    const maxAttempts = 3;
    
    while (attempts < maxAttempts) {
      try {
        await _iap.initConnection();
        print('Connection established on attempt ${attempts + 1}');
        return;
      } catch (e) {
        attempts++;
        if (attempts < maxAttempts) {
          print('Connection attempt $attempts failed, retrying...');
          await Future.delayed(Duration(seconds: attempts * 2));
        } else {
          throw e;
        }
      }
    }
>>>>>>> 5e86ee0 (docs: Update community links and fix configuration)
  }
}
```

<<<<<<< HEAD
## Common Issues

### requestProducts() returns an empty array

**Symptoms:**
- `getProducts()` or `requestProducts()` returns empty list
- Products configured in store but not loading
=======
#### Problem: "Connection lost during purchase"

**Solutions:**

```dart
class ConnectionRecovery {
  static Future<void> recoverFromConnectionLoss() async {
    final _iap = FlutterInappPurchase.instance;
    
    try {
      // 1. Check current connection state
      bool isConnected = false;
      try {
        await _iap.getProducts(['test_product']);
        isConnected = true;
      } catch (_) {
        isConnected = false;
      }
      
      if (!isConnected) {
        // 2. Re-establish connection
        await _iap.endConnection();
        await Future.delayed(Duration(seconds: 1));
        await _iap.initConnection();
      }
      
      // 3. Check for incomplete transactions
      if (Platform.isIOS) {
        final pending = await _iap.getAvailableItemsIOS();
        if (pending != null && pending.isNotEmpty) {
          print('Found ${pending.length} incomplete transactions');
          // Process pending transactions
        }
      }
      
    } catch (e) {
      print('Connection recovery failed: $e');
    }
  }
}
```

### Product Loading Problems

#### Problem: "No products returned"

**Symptoms:**
- `getProducts()` returns empty list
- Products exist in store but not loading
- Product IDs not recognized
>>>>>>> 5e86ee0 (docs: Update community links and fix configuration)

**Solutions:**

```dart
class ProductLoadingTroubleshooter {
<<<<<<< HEAD
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
      await FlutterInappPurchase.instance.requestProducts(
        RequestProductsParams(skus: productIds, type: PurchaseType.inapp),
      );
      
      final products = await FlutterInappPurchase.instance.getProducts(productIds);
      
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
=======
  static Future<void> diagnoseProductLoading(List<String> productIds) async {
    final _iap = FlutterInappPurchase.instance;
    
    print('Diagnosing product loading for: $productIds');
    
    // 1. Verify product ID format
    for (final id in productIds) {
      if (!_isValidProductId(id)) {
        print('Invalid product ID format: $id');
      }
    }
    
    // 2. Check platform-specific issues
    if (Platform.isAndroid) {
      await _checkAndroidProductIssues(productIds);
    } else if (Platform.isIOS) {
      await _checkIOSProductIssues(productIds);
    }
    
    // 3. Try loading products with detailed error handling
    try {
      final products = await _iap.getProducts(productIds);
      
      if (products.isEmpty) {
        print('No products returned. Possible causes:');
        print('- Products not published in store');
        print('- Incorrect product IDs');
        print('- Store agreement not accepted');
        print('- App not properly configured');
      } else {
        print('Successfully loaded ${products.length} products:');
        for (final product in products) {
          print('- ${product.productId}: ${product.localizedPrice}');
        }
      }
    } catch (e) {
      print('Product loading error: $e');
      _analyzeProductLoadingError(e);
    }
  }
  
  static bool _isValidProductId(String productId) {
    // Check for common issues
    if (productId.isEmpty) return false;
    if (productId.contains(' ')) return false;
    if (productId != productId.toLowerCase()) {
      print('Warning: Product ID contains uppercase: $productId');
    }
    return true;
  }
  
  static Future<void> _checkAndroidProductIssues(List<String> productIds) async {
    print('\nAndroid Product Checklist:');
    print('1. Products are ACTIVE in Google Play Console');
    print('2. App is published (at least in internal testing)');
    print('3. APK/AAB with billing permission is uploaded');
    print('4. Prices are set for all countries');
    print('5. Testing with signed APK');
    print('6. Account is added as tester');
    
    // Check if using reserved test IDs
    final testIds = ['android.test.purchased', 'android.test.canceled'];
    for (final id in productIds) {
      if (testIds.contains(id)) {
        print('Note: Using Android test product ID: $id');
      }
    }
  }
  
  static Future<void> _checkIOSProductIssues(List<String> productIds) async {
    print('\nIOS Product Checklist:');
    print('1. Products are Ready to Submit in App Store Connect');
    print('2. Banking and tax forms are completed');
    print('3. Products are added to app in App Store Connect');
    print('4. Using sandbox account for testing');
    print('5. Bundle ID matches App Store Connect');
    print('6. StoreKit configuration file is set up (for local testing)');
>>>>>>> 5e86ee0 (docs: Update community links and fix configuration)
  }
}
```

<<<<<<< HEAD
### useIAP hook not working

**Problem:** Provider or state management not working properly
=======
### Purchase Errors

#### Problem: "Purchase failed with unknown error"
>>>>>>> 5e86ee0 (docs: Update community links and fix configuration)

**Solutions:**

```dart
<<<<<<< HEAD
// Ensure proper provider setup
class IAPProviderSetup {
  static Widget setupProvider(Widget child) {
    return IapProviderWidget(
      child: child,
    );
  }
}

// In your main.dart
void main() {
  runApp(
    IAPProviderSetup.setupProvider(
      MyApp(),
    ),
  );
}

// Access provider in widgets
class ProductScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final iapProvider = IapProvider.of(context);
    
    if (iapProvider == null) {
      return Text('❌ IAP Provider not found - check widget tree');
    }
    
    if (!iapProvider.connected) {
      return Text('⏳ Connecting to store...');
    }
    
    return Text('✅ Store connected');
=======
class PurchaseErrorDiagnostics {
  static void analyzePurchaseError(dynamic error) {
    print('\n=== Purchase Error Analysis ===');
    
    if (error is PurchaseResult) {
      _analyzePurchaseResult(error);
    } else if (error is Exception) {
      _analyzeException(error);
    } else {
      print('Unknown error type: ${error.runtimeType}');
      print('Error details: $error');
    }
    
    print('\n=== Suggested Actions ===');
    _suggestActions(error);
  }
  
  static void _analyzePurchaseResult(PurchaseResult result) {
    print('Error Code: ${result.code}');
    print('Error Message: ${result.message}');
    
    switch (result.code) {
      case ErrorCode.eUserCancelled:
        print('Diagnosis: User cancelled the purchase');
        print('This is normal behavior - no action needed');
        break;
        
      case ErrorCode.eNetworkError:
        print('Diagnosis: Network connection issue');
        print('Check internet connectivity');
        break;
        
      case ErrorCode.eItemUnavailable:
        print('Diagnosis: Product not available in store');
        print('Verify product configuration');
        break;
        
      case ErrorCode.eAlreadyOwned:
        print('Diagnosis: User already owns this product');
        print('Implement restore purchases functionality');
        break;
        
      case ErrorCode.eDeveloperError:
        print('Diagnosis: Configuration or implementation error');
        print('Check product IDs and store setup');
        break;
        
      case ErrorCode.eServiceDisconnected:
        print('Diagnosis: Store service disconnected');
        print('Re-initialize connection');
        break;
        
      default:
        print('Diagnosis: Unhandled error code');
    }
  }
  
  static void _suggestActions(dynamic error) {
    // Platform-specific suggestions
    if (Platform.isAndroid) {
      print('Android-specific checks:');
      print('- Clear Google Play Store cache');
      print('- Update Google Play Services');
      print('- Check Google account has payment method');
      print('- Verify app signing configuration');
    } else if (Platform.isIOS) {
      print('iOS-specific checks:');
      print('- Sign out and back into sandbox account');
      print('- Reset App Store settings');
      print('- Check for iOS/StoreKit updates');
      print('- Verify certificates and provisioning profiles');
    }
>>>>>>> 5e86ee0 (docs: Update community links and fix configuration)
  }
}
```

<<<<<<< HEAD
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
=======
#### Problem: "Purchase completes but content not delivered"

**Solutions:**

```dart
class PurchaseDeliveryDebugger {
  static Future<void> debugPurchaseDelivery(PurchasedItem purchase) async {
    print('\n=== Purchase Delivery Debug ===');
    print('Product ID: ${purchase.productId}');
    print('Transaction ID: ${purchase.transactionId}');
    print('Transaction Date: ${DateTime.fromMillisecondsSinceEpoch(purchase.transactionDate ?? 0)}');
    
    // 1. Check purchase validity
    final isValid = await _validatePurchase(purchase);
    print('Purchase validation: ${isValid ? "PASSED" : "FAILED"}');
    
    // 2. Check transaction state
    if (Platform.isAndroid) {
      print('Android purchase state: ${purchase.purchaseStateAndroid}');
      print('Is acknowledged: ${purchase.isAcknowledgedAndroid}');
    }
    
    // 3. Check if transaction was finished
    final wasFinished = await _checkIfTransactionFinished(purchase);
    print('Transaction finished: ${wasFinished ? "YES" : "NO"}');
    
    // 4. Verify content delivery
    final contentDelivered = await _verifyContentDelivery(purchase.productId!);
    print('Content delivered: ${contentDelivered ? "YES" : "NO"}');
    
    if (!contentDelivered) {
      print('\nTroubleshooting steps:');
      print('1. Check purchase verification logic');
      print('2. Verify content delivery implementation');
      print('3. Check for exceptions in delivery code');
      print('4. Ensure transaction is properly finished');
    }
  }
  
  static Future<bool> _validatePurchase(PurchasedItem purchase) async {
    try {
      // Check receipt presence
      if (Platform.isIOS && purchase.transactionReceipt == null) {
        print('Warning: No receipt found for iOS purchase');
        return false;
      }
      
      if (Platform.isAndroid && purchase.purchaseToken == null) {
        print('Warning: No purchase token for Android');
        return false;
      }
      
      return true;
    } catch (e) {
      print('Validation error: $e');
      return false;
    }
  }
}
```

### Platform-Specific Issues

#### iOS Specific Problems

```dart
class IOSTroubleshooter {
  static Future<void> diagnoseIOSIssues() async {
    print('\n=== iOS Diagnostics ===');
    
    // 1. Check StoreKit availability
    await _checkStoreKitAvailability();
    
    // 2. Check sandbox environment
    _checkSandboxConfiguration();
    
    // 3. Check receipt validation
    await _checkReceiptValidation();
    
    // 4. Check entitlements
    _checkEntitlements();
  }
  
  static Future<void> _checkStoreKitAvailability() async {
    try {
      final _iap = FlutterInappPurchase.instance;
      
      // Try to fetch a test product
      await _iap.getProducts(['com.test.product']);
      print('StoreKit: Available');
      
    } catch (e) {
      print('StoreKit: Not available or misconfigured');
      print('Error: $e');
      
      print('\nPossible causes:');
      print('- Running on simulator without StoreKit configuration');
      print('- App Store agreements not accepted');
      print('- Invalid bundle identifier');
    }
  }
  
  static void _checkSandboxConfiguration() {
    if (kDebugMode) {
      print('\nSandbox Configuration:');
      print('1. Go to Settings > App Store');
      print('2. Scroll to bottom for Sandbox Account');
      print('3. Sign in with test account');
      print('4. DO NOT use production Apple ID');
      
      print('\nCommon sandbox issues:');
      print('- Sandbox account not verified');
      print('- Using production account in sandbox');
      print('- Expired sandbox account');
    }
  }
  
  static Future<void> _checkReceiptValidation() async {
    print('\nReceipt Validation Check:');
    
    try {
      final _iap = FlutterInappPurchase.instance;
      final receiptBody = await _iap.getReceiptDataIOS();
      
      if (receiptBody != null && receiptBody.isNotEmpty) {
        print('Receipt data: Available (${receiptBody.length} bytes)');
        
        // Check if it's base64 encoded
        try {
          base64.decode(receiptBody);
          print('Receipt format: Valid base64');
        } catch (_) {
          print('Receipt format: Invalid base64');
        }
      } else {
        print('Receipt data: Not available');
        print('This is normal if no purchases have been made');
      }
    } catch (e) {
      print('Receipt check error: $e');
    }
  }
  
  static void _checkEntitlements() {
    print('\nEntitlements Check:');
    print('Ensure Info.plist contains:');
    print('- com.apple.developer.in-app-payments');
    print('- Correct merchant IDs if using Apple Pay');
    
    print('\nCapabilities in Xcode:');
    print('- In-App Purchase: Enabled');
    print('- Sign in with Apple: If using subscriptions');
  }
}
```

#### Android Specific Problems

```dart
class AndroidTroubleshooter {
  static Future<void> diagnoseAndroidIssues() async {
    print('\n=== Android Diagnostics ===');
    
    // 1. Check Google Play Services
    await _checkPlayServices();
    
    // 2. Check billing client
    await _checkBillingClient();
    
    // 3. Check app configuration
    _checkAppConfiguration();
    
    // 4. Check testing setup
    _checkTestingSetup();
  }
  
  static Future<void> _checkPlayServices() async {
    print('\nGoogle Play Services Check:');
    
    try {
      // Check if Play Store is available
      final playStorePackage = 'com.android.vending';
      
      if (await canLaunchUrlString('market://details?id=$playStorePackage')) {
        print('Play Store: Installed');
      } else {
        print('Play Store: Not available');
      }
      
    } catch (e) {
      print('Play Services check error: $e');
    }
    
    print('\nCommon Play Services issues:');
    print('- Outdated Play Store version');
    print('- Play Services disabled');
    print('- Device not certified by Google');
  }
  
  static Future<void> _checkBillingClient() async {
    print('\nBilling Client Check:');
    
    try {
      final _iap = FlutterInappPurchase.instance;
      await _iap.initConnection();
      
      print('Billing Client: Connected');
      
      // Check billing client version
      print('Using Google Play Billing v8');
      
    } catch (e) {
      print('Billing Client: Connection failed');
      print('Error: $e');
      
      print('\nPossible causes:');
      print('- BILLING permission missing in AndroidManifest.xml');
      print('- Google Play Store not installed');
      print('- Account not configured for payments');
    }
  }
  
  static void _checkAppConfiguration() {
    print('\nApp Configuration Check:');
    print('Ensure AndroidManifest.xml contains:');
    print('<uses-permission android:name="com.android.vending.BILLING" />');
    
    print('\nBuild configuration:');
    print('- Using signed APK/AAB for testing');
    print('- Package name matches Play Console');
    print('- Version code uploaded to Play Console');
    
    print('\nPlay Console configuration:');
    print('- App published (at least internal testing)');
    print('- Products active and published');
    print('- Tester accounts added');
  }
  
  static void _checkTestingSetup() {
    print('\nTesting Setup Check:');
    print('1. Upload signed APK/AAB to Play Console');
    print('2. Create internal testing release');
    print('3. Add tester accounts');
    print('4. Accept testing invitation email');
    print('5. Download app from Play Store testing link');
    
    print('\nLicense testing:');
    print('- Add test accounts in Play Console');
    print('- Settings > Developer account > License testing');
  }
}
```

## Debug Techniques

### Enable Debug Logging

```dart
class IAPDebugger {
  static bool _debugEnabled = false;
  
  static void enableDebugMode() {
    _debugEnabled = true;
    
    // Set up debug interceptor
    FlutterInappPurchase.purchaseUpdated.listen((purchase) {
      if (_debugEnabled && purchase != null) {
        _logPurchaseUpdate(purchase);
>>>>>>> 5e86ee0 (docs: Update community links and fix configuration)
      }
    });
    
    FlutterInappPurchase.purchaseError.listen((error) {
<<<<<<< HEAD
      if (error != null) {
        debugPrint('❌ Purchase error: ${error.message}');
        _handlePurchaseError(error);
=======
      if (_debugEnabled && error != null) {
        _logPurchaseError(error);
>>>>>>> 5e86ee0 (docs: Update community links and fix configuration)
      }
    });
  }
  
<<<<<<< HEAD
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
=======
  static void _logPurchaseUpdate(PurchasedItem purchase) {
    final log = StringBuffer();
    log.writeln('\n========== PURCHASE UPDATE ==========');
    log.writeln('Time: ${DateTime.now()}');
    log.writeln('Product ID: ${purchase.productId}');
    log.writeln('Transaction ID: ${purchase.transactionId}');
    log.writeln('State: ${_getPurchaseState(purchase)}');
    
    if (Platform.isAndroid) {
      log.writeln('Purchase Token: ${purchase.purchaseToken?.substring(0, 20)}...');
      log.writeln('Acknowledged: ${purchase.isAcknowledgedAndroid}');
      log.writeln('Auto Renewing: ${purchase.autoRenewingAndroid}');
    } else {
      log.writeln('Receipt: ${purchase.transactionReceipt != null ? "Present" : "Missing"}');
      log.writeln('Original Transaction ID: ${purchase.originalTransactionIdentifierIOS}');
    }
    
    log.writeln('=====================================\n');
    print(log.toString());
  }
  
  static void _logPurchaseError(PurchaseResult error) {
    final log = StringBuffer();
    log.writeln('\n========== PURCHASE ERROR ==========');
    log.writeln('Time: ${DateTime.now()}');
    log.writeln('Code: ${error.code}');
    log.writeln('Message: ${error.message}');
    log.writeln('Response Code: ${error.responseCode}');
    log.writeln('Debug Message: ${error.debugMessage}');
    log.writeln('====================================\n');
    print(log.toString());
  }
  
  static String _getPurchaseState(PurchasedItem purchase) {
    if (Platform.isAndroid) {
      switch (purchase.purchaseStateAndroid) {
        case 0: return 'UNSPECIFIED';
        case 1: return 'PURCHASED';
        case 2: return 'PENDING';
        default: return 'UNKNOWN';
      }
    }
    return 'PURCHASED';
  }
}
```

### Network Request Debugging

```dart
class NetworkDebugger {
  static void interceptNetworkRequests() {
    // Set up HTTP client with logging
    HttpOverrides.global = DebugHttpOverrides();
  }
}

class DebugHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    
    // Log all requests
    client.findProxy = (uri) {
      print('[HTTP] Request: ${uri.toString()}');
      return HttpClient.findProxyFromEnvironment(uri);
    };
    
    return client;
  }
}
```

### State Inspection Tool

```dart
class IAPStateInspector {
  static Future<void> inspectCurrentState() async {
    final _iap = FlutterInappPurchase.instance;
    
    print('\n=== IAP State Inspection ===');
    print('Time: ${DateTime.now()}');
    print('Platform: ${Platform.operatingSystem}');
    
    // Connection state
    bool isConnected = false;
    try {
      await _iap.getProducts(['test']);
      isConnected = true;
    } catch (_) {
      isConnected = false;
    }
    print('Connection: ${isConnected ? "Connected" : "Disconnected"}');
    
    // Pending purchases
    if (Platform.isIOS) {
      try {
        final pending = await _iap.getAvailableItemsIOS();
        print('Pending Purchases: ${pending?.length ?? 0}');
        
        pending?.forEach((purchase) {
          print('  - ${purchase.productId}: ${purchase.transactionId}');
        });
      } catch (e) {
        print('Pending Purchases: Error - $e');
      }
    }
    
    // Product availability
    try {
      final testIds = Platform.isAndroid 
          ? ['android.test.purchased']
          : ['com.example.test'];
      
      final products = await _iap.getProducts(testIds);
      print('Test Products Available: ${products.length}');
    } catch (e) {
      print('Test Products: Error - $e');
    }
    
    print('===========================\n');
  }
}
```

## Recovery Procedures

### Stuck Transaction Recovery

```dart
class TransactionRecovery {
  static Future<void> recoverStuckTransactions() async {
    final _iap = FlutterInappPurchase.instance;
    
    print('Starting transaction recovery...');
    
    if (Platform.isIOS) {
      await _recoverIOSTransactions();
    } else {
      await _recoverAndroidTransactions();
    }
  }
  
  static Future<void> _recoverIOSTransactions() async {
    try {
      // 1. Get all pending transactions
      final pending = await FlutterInappPurchase.instance.getAvailableItemsIOS();
      
      if (pending == null || pending.isEmpty) {
        print('No stuck transactions found');
        return;
      }
      
      print('Found ${pending.length} stuck transactions');
      
      // 2. Process each transaction
      for (final transaction in pending) {
        print('Processing: ${transaction.productId}');
        
        try {
          // Attempt to finish the transaction
          await FlutterInappPurchase.instance.finishTransactionIOS(
            transaction,
            isConsumable: true, // Try as consumable first
          );
          
          print('Finished transaction: ${transaction.transactionId}');
        } catch (e) {
          print('Failed to finish: $e');
          
          // Try alternative approach
          await _forceFinishTransaction(transaction);
        }
      }
    } catch (e) {
      print('iOS recovery failed: $e');
    }
  }
  
  static Future<void> _recoverAndroidTransactions() async {
    try {
      // For Android, check purchase history
      final history = await FlutterInappPurchase.instance.getPurchaseHistory();
      
      if (history == null || history.isEmpty) {
        print('No purchase history found');
        return;
      }
      
      // Check for unacknowledged purchases
      for (final purchase in history) {
        if (purchase.isAcknowledgedAndroid == false) {
          print('Found unacknowledged purchase: ${purchase.productId}');
          
          // Acknowledge the purchase
          await _acknowledgePurchase(purchase);
        }
      }
    } catch (e) {
      print('Android recovery failed: $e');
>>>>>>> 5e86ee0 (docs: Update community links and fix configuration)
    }
  }
}
```

<<<<<<< HEAD
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
      await _checkAndroidConnection();
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
  
  static Future<void> _checkAndroidConnection() async {
    debugPrint('🤖 Checking Android connection...');
    
    try {
      final connectionState = await FlutterInappPurchase.instance.getConnectionStateAndroid();
      debugPrint('Android connection state: $connectionState');
      
      if (connectionState != 'connected') {
        debugPrint('❌ Android billing service not connected');
        debugPrint('💡 Check: Google Play Services, Play Store app updates');
        return;
      }
      
      debugPrint('✅ Android billing service connected');
    } catch (e) {
      debugPrint('❌ Android connection check failed: $e');
    }
  }
}
```

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
      final store = await FlutterInappPurchase.instance.getStore();
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
=======
### Store Configuration Validator

```dart
class StoreConfigValidator {
  static Future<Map<String, bool>> validateConfiguration() async {
    final results = <String, bool>{};
    
    // Connection test
    results['connection'] = await _testConnection();
    
    // Product configuration test
    results['products'] = await _testProductConfiguration();
    
    // Purchase capability test
    results['purchasing'] = await _testPurchaseCapability();
    
    // Platform-specific tests
    if (Platform.isIOS) {
      results['ios_sandbox'] = await _testIOSSandbox();
      results['ios_receipt'] = await _testIOSReceipt();
    } else {
      results['android_billing'] = await _testAndroidBilling();
      results['android_signature'] = await _testAndroidSignature();
    }
    
    // Print results
    print('\n=== Configuration Validation Results ===');
    results.forEach((test, passed) {
      print('${test.padRight(20)}: ${passed ? "✓ PASSED" : "✗ FAILED"}');
    });
    
    return results;
  }
  
  static Future<bool> _testConnection() async {
    try {
      await FlutterInappPurchase.instance.initConnection();
      return true;
    } catch (_) {
      return false;
    }
  }
  
  static Future<bool> _testProductConfiguration() async {
    try {
      final testIds = Platform.isAndroid
          ? ['android.test.purchased']
          : ['com.example.consumable'];
      
      final products = await FlutterInappPurchase.instance.getProducts(testIds);
      return products.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
```

## Best Practices

### Error Prevention Checklist

1. **Before Release**
   - Test all purchase flows
   - Verify receipt validation
   - Test restore purchases
   - Check error handling
   - Test network interruptions

2. **Configuration**
   - Double-check product IDs
   - Verify store configuration
   - Test with production-like data
   - Check platform requirements

3. **Monitoring**
   - Log all purchase events
   - Track error rates
   - Monitor transaction completion
   - Set up alerts for failures

### Common Mistakes to Avoid

```dart
class CommonMistakes {
  // ❌ Don't do this
  static void badExample1() async {
    // Not checking connection before use
    final products = await FlutterInappPurchase.instance.getProducts(['id']);
  }
  
  // ✅ Do this instead
  static void goodExample1() async {
    try {
      await FlutterInappPurchase.instance.initConnection();
      final products = await FlutterInappPurchase.instance.getProducts(['id']);
    } catch (e) {
      // Handle connection error
    }
  }
  
  // ❌ Don't do this
  static void badExample2(PurchasedItem purchase) {
    // Not finishing transactions
    // This causes stuck transactions!
  }
  
  // ✅ Do this instead
  static void goodExample2(PurchasedItem purchase) async {
    // Always finish transactions
    await FlutterInappPurchase.instance.finishTransactionIOS(
      purchase,
      isConsumable: true,
    );
>>>>>>> 5e86ee0 (docs: Update community links and fix configuration)
  }
}
```

<<<<<<< HEAD
## Getting Help

### Bug report template

When reporting issues, please include:

```
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
```

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
=======
## Next Steps

- Review the [FAQ](./faq.md) for common questions
- Implement proper [Error Handling](./error-handling.md)
- Set up [Receipt Validation](./receipt-validation.md)
- Test with real devices and accounts
>>>>>>> 5e86ee0 (docs: Update community links and fix configuration)
