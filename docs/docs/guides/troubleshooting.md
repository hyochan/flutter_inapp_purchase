---
sidebar_position: 9
title: Troubleshooting
---

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
  }
}
```

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

**Solutions:**

```dart
class ProductLoadingTroubleshooter {
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
  }
}
```

### Purchase Errors

#### Problem: "Purchase failed with unknown error"

**Solutions:**

```dart
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
  }
}
```

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
      }
    });
    
    FlutterInappPurchase.purchaseError.listen((error) {
      if (_debugEnabled && error != null) {
        _logPurchaseError(error);
      }
    });
  }
  
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
    }
  }
}
```

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
  }
}
```

## Next Steps

- Review the [FAQ](./faq.md) for common questions
- Implement proper [Error Handling](./error-handling.md)
- Set up [Receipt Validation](./receipt-validation.md)
- Test with real devices and accounts