---
sidebar_position: 6
title: Testing
---

# Testing Guide

Comprehensive guide to testing in-app purchases during development and before release.

## Overview

Testing IAP functionality requires special setup and considerations due to the integration with platform stores. This guide covers testing strategies, sandbox environments, test accounts, and common testing scenarios.

## Testing Environments

### Development Testing
- Local testing with mock data
- Unit tests for purchase logic
- Widget tests for UI components
- Integration tests for full flows

### Sandbox Testing
- iOS Sandbox environment
- Android Internal Testing
- Test with real store APIs
- Validate purchase flows

### Production Testing
- Limited production testing
- A/B testing for purchase flows
- Real user validation
- Performance monitoring

## iOS Sandbox Testing

### Setting Up iOS Sandbox

1. **Create Sandbox Test Accounts**
   - Go to App Store Connect
   - Navigate to Users and Access > Sandbox Testers
   - Create test accounts with different characteristics

2. **Configure Test Products**
   - Ensure products are in "Ready to Submit" state
   - Test both consumable and non-consumable products
   - Set up subscription groups and offers

3. **Device Setup**
   - Sign out of Apple ID in Settings
   - Install app through Xcode or TestFlight
   - When purchasing, sign in with sandbox account

### iOS Sandbox Test Implementation

```dart
class IOSSandboxTesting {
  static bool get isSandboxEnvironment {
    // Check if running in sandbox
    return kDebugMode || _isTestFlight;
  }
  
  static Future<void> setupSandboxTesting() async {
    if (isSandboxEnvironment) {
      // Use sandbox product IDs
      await _loadSandboxProductIds();
      
      // Enable verbose logging
      _enableSandboxLogging();
      
      // Clear any existing purchases for fresh testing
      await _clearSandboxPurchases();
    }
  }
  
  static Future<void> _clearSandboxPurchases() async {
    try {
      // Get all available purchases
      final purchases = await FlutterInappPurchase.instance.getAvailablePurchases();
      
      // Finish all transactions to clean slate
      for (var purchase in purchases) {
        await FlutterInappPurchase.instance.finishTransaction(purchase);
      }
      
      print('Cleared ${purchases.length} sandbox purchases');
    } catch (e) {
      print('Error clearing sandbox purchases: $e');
    }
  }
  
  static void testSubscriptionRenewal() {
    // In sandbox, subscriptions renew quickly for testing:
    // 1 week subscription = 3 minutes
    // 1 month subscription = 5 minutes
    // 1 year subscription = 1 hour
    
    Timer.periodic(Duration(minutes: 1), (timer) {
      _checkSubscriptionRenewal();
    });
  }
  
  static void _checkSubscriptionRenewal() async {
    final purchases = await FlutterInappPurchase.instance.getAvailablePurchases();
    final subscriptions = purchases.where((p) => _isSubscription(p.productId));
    
    for (var subscription in subscriptions) {
      print('Subscription status: ${subscription.productId}');
      // In sandbox, you can see rapid renewal cycles
    }
  }
}
```

### iOS Sandbox Test Scenarios

```dart
class IOSTestScenarios {
  static Future<void> testPurchaseFlow() async {
    print('Testing iOS purchase flow...');
    
    try {
      // Test consumable purchase
      await _testConsumablePurchase();
      
      // Test non-consumable purchase
      await _testNonConsumablePurchase();
      
      // Test subscription purchase
      await _testSubscriptionPurchase();
      
      // Test purchase restoration
      await _testPurchaseRestoration();
      
      // Test error scenarios
      await _testErrorScenarios();
      
      print('✓ All iOS tests completed');
      
    } catch (e) {
      print('✗ iOS test failed: $e');
    }
  }
  
  static Future<void> _testConsumablePurchase() async {
    const productId = 'com.example.coins_100';
    
    // Purchase consumable item
    await FlutterInappPurchase.instance.requestPurchase(
      request: RequestPurchase(
        ios: RequestPurchaseIOS(sku: productId),
      ),
      type: PurchaseType.inapp,
    );
    
    // Verify purchase completed
    await _waitForPurchaseCompletion(productId);
    
    // Verify item can be purchased again (consumable)
    await FlutterInappPurchase.instance.requestPurchase(
      request: RequestPurchase(
        ios: RequestPurchaseIOS(sku: productId),
      ),
      type: PurchaseType.inapp,
    );
    
    print('✓ Consumable purchase test passed');
  }
  
  static Future<void> _testNonConsumablePurchase() async {
    const productId = 'com.example.remove_ads';
    
    // Purchase non-consumable item
    await FlutterInappPurchase.instance.requestPurchase(
      request: RequestPurchase(
        ios: RequestPurchaseIOS(sku: productId),
      ),
      type: PurchaseType.inapp,
    );
    
    // Verify purchase completed
    await _waitForPurchaseCompletion(productId);
    
    // Verify item cannot be purchased again
    try {
      await FlutterInappPurchase.instance.requestPurchase(
        request: RequestPurchase(
          ios: RequestPurchaseIOS(sku: productId),
        ),
        type: PurchaseType.inapp,
      );
      
      // Should not reach here
      throw Exception('Non-consumable was purchased twice');
      
    } catch (e) {
      if (e.toString().contains('already owned')) {
        print('✓ Non-consumable purchase protection works');
      } else {
        rethrow;
      }
    }
  }
}
```

## Android Testing

### Android Internal Testing Setup

1. **Upload to Play Console**
   - Upload APK/AAB to Internal Testing track
   - Add test accounts as internal testers
   - Configure in-app products

2. **Test Account Configuration**
   - Add Gmail accounts as testers
   - Ensure testers accept testing invitation
   - Test accounts can make purchases without charges

3. **Product Configuration**
   - Set up products in Play Console
   - Configure subscription base plans and offers
   - Set up license testing responses

### Android Testing Implementation

```dart
class AndroidTesting {
  static const testProductIds = [
    'android.test.purchased',
    'android.test.canceled',
    'android.test.refunded',
    'android.test.item_unavailable',
  ];
  
  static bool get isTestEnvironment {
    return kDebugMode || _isInternalTesting;
  }
  
  static Future<void> setupAndroidTesting() async {
    if (isTestEnvironment) {
      // Configure for testing
      await _setupTestProducts();
      await _enableTestingFeatures();
    }
  }
  
  static Future<void> testAndroidPurchaseFlow() async {
    print('Testing Android purchase flow...');
    
    try {
      // Test different license testing responses
      await _testLicenseResponses();
      
      // Test real product purchases
      await _testRealProducts();
      
      // Test subscription flows
      await _testSubscriptionFlow();
      
      // Test Google Play Billing features
      await _testBillingFeatures();
      
      print('✓ All Android tests completed');
      
    } catch (e) {
      print('✗ Android test failed: $e');
    }
  }
  
  static Future<void> _testLicenseResponses() async {
    for (String testId in testProductIds) {
      try {
        await FlutterInappPurchase.instance.requestPurchase(
          request: RequestPurchase(
            android: RequestPurchaseAndroid(skus: [testId]),
          ),
          type: PurchaseType.inapp,
        );
        
        await _handleTestResponse(testId);
        
      } catch (e) {
        print('Test response for $testId: $e');
      }
    }
  }
  
  static Future<void> _handleTestResponse(String testId) async {
    switch (testId) {
      case 'android.test.purchased':
        print('✓ Purchase test successful');
        break;
      case 'android.test.canceled':
        print('✓ Cancel test successful');
        break;
      case 'android.test.refunded':
        print('✓ Refund test successful');
        break;
      case 'android.test.item_unavailable':
        print('✓ Unavailable test successful');
        break;
    }
  }
  
  static Future<void> _testSubscriptionFlow() async {
    const subscriptionId = 'com.example.test_subscription';
    
    // Test subscription purchase
    await FlutterInappPurchase.instance.requestSubscription(subscriptionId);
    
    // Test subscription upgrade
    await _testSubscriptionUpgrade(subscriptionId);
    
    // Test subscription cancellation
    await _testSubscriptionCancellation(subscriptionId);
  }
  
  static Future<void> _testSubscriptionUpgrade(String fromSubscription) async {
    const toSubscription = 'com.example.premium_subscription';
    
    // Get current subscription purchase token
    final purchases = await FlutterInappPurchase.instance.getAvailablePurchases();
    final currentSub = purchases.firstWhere(
      (p) => p.productId == fromSubscription,
      orElse: () => null,
    );
    
    if (currentSub?.purchaseToken != null) {
      await FlutterInappPurchase.instance.requestSubscription(
        toSubscription,
        purchaseTokenAndroid: currentSub!.purchaseToken,
        prorationModeAndroid: AndroidProrationMode.IMMEDIATE_AND_CHARGE_PRORATED_PRICE,
      );
      
      print('✓ Subscription upgrade test successful');
    }
  }
}
```

## Test Data Management

### Mock Purchase Data

```dart
class MockPurchaseData {
  static List<IAPItem> getMockProducts() {
    return [
      _createMockProduct(
        id: 'test_consumable',
        title: 'Test Coins',
        description: '100 test coins',
        price: '0.99',
        type: 'inapp',
      ),
      _createMockProduct(
        id: 'test_nonconsumable',
        title: 'Test Premium',
        description: 'Remove ads',
        price: '2.99',
        type: 'inapp',
      ),
      _createMockSubscription(
        id: 'test_subscription',
        title: 'Test Subscription',
        description: 'Monthly subscription',
        price: '4.99',
        period: 'P1M',
      ),
    ];
  }
  
  static IAPItem _createMockProduct({
    required String id,
    required String title,
    required String description,
    required String price,
    required String type,
  }) {
    return IAPItem.fromJSON({
      'productId': id,
      'title': title,
      'description': description,
      'price': price,
      'localizedPrice': '\$$price',
      'currency': 'USD',
      'type': type,
    });
  }
  
  static IAPItem _createMockSubscription({
    required String id,
    required String title,
    required String description,
    required String price,
    required String period,
  }) {
    return IAPItem.fromJSON({
      'productId': id,
      'title': title,
      'description': description,
      'price': price,
      'localizedPrice': '\$$price/month',
      'currency': 'USD',
      'subscriptionPeriodAndroid': period,
      'subscriptionPeriodUnitIOS': 'MONTH',
      'subscriptionPeriodNumberIOS': '1',
    });
  }
  
  static PurchasedItem createMockPurchase({
    required String productId,
    String? transactionId,
    bool isSubscription = false,
  }) {
    return PurchasedItem.fromJSON({
      'productId': productId,
      'transactionId': transactionId ?? 'mock_${DateTime.now().millisecondsSinceEpoch}',
      'transactionDate': DateTime.now().millisecondsSinceEpoch,
      'transactionReceipt': 'mock_receipt_data',
      'purchaseToken': 'mock_purchase_token',
      if (Platform.isAndroid) ...{
        'isAcknowledgedAndroid': false,
        'purchaseStateAndroid': 1, // Purchased
      },
      if (Platform.isIOS) ...{
        'transactionStateIOS': 1, // Purchased
      },
    });
  }
}
```

### Test Database

```dart
class TestDatabase {
  static final Map<String, dynamic> _testData = {};
  
  static void setTestPurchases(List<PurchasedItem> purchases) {
    _testData['purchases'] = purchases.map((p) => p.toJson()).toList();
  }
  
  static List<PurchasedItem> getTestPurchases() {
    final purchaseData = _testData['purchases'] as List<dynamic>? ?? [];
    return purchaseData
        .map((data) => PurchasedItem.fromJSON(data))
        .toList();
  }
  
  static void setTestProducts(List<IAPItem> products) {
    _testData['products'] = products.map((p) => p.toJson()).toList();
  }
  
  static List<IAPItem> getTestProducts() {
    final productData = _testData['products'] as List<dynamic>? ?? [];
    return productData
        .map((data) => IAPItem.fromJSON(data))
        .toList();
  }
  
  static void clearTestData() {
    _testData.clear();
  }
  
  static void simulateNetworkDelay() async {
    await Future.delayed(Duration(milliseconds: 500 + Random().nextInt(1000)));
  }
}
```

## Unit Testing

### Purchase Logic Tests

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

class MockFlutterInappPurchase extends Mock implements FlutterInappPurchase {}

void main() {
  group('Purchase Logic Tests', () {
    late MockFlutterInappPurchase mockIAP;
    late PurchaseService purchaseService;
    
    setUp(() {
      mockIAP = MockFlutterInappPurchase();
      purchaseService = PurchaseService(iap: mockIAP);
    });
    
    test('should initialize connection successfully', () async {
      // Arrange
      when(mockIAP.initConnection()).thenAnswer((_) async {});
      
      // Act
      await purchaseService.initialize();
      
      // Assert
      verify(mockIAP.initConnection()).called(1);
      expect(purchaseService.isInitialized, true);
    });
    
    test('should handle purchase success', () async {
      // Arrange
      final mockPurchase = MockPurchaseData.createMockPurchase(
        productId: 'test_product',
      );
      
      when(mockIAP.requestPurchase(any, type: anyNamed('type')))
          .thenAnswer((_) async {});
      
      // Act
      await purchaseService.purchaseProduct('test_product');
      
      // Simulate purchase update
      await purchaseService.handlePurchaseUpdate(mockPurchase);
      
      // Assert
      expect(purchaseService.ownedProducts.contains('test_product'), true);
    });
    
    test('should handle purchase errors', () async {
      // Arrange
      when(mockIAP.requestPurchase(any, type: anyNamed('type')))
          .thenThrow(PurchaseError(
            code: ErrorCode.E_USER_CANCELLED,
            message: 'User cancelled',
            platform: IAPPlatform.ios,
          ));
      
      // Act & Assert
      expect(
        () => purchaseService.purchaseProduct('test_product'),
        throwsA(isA<PurchaseError>()),
      );
    });
    
    test('should validate consumable vs non-consumable', () {
      // Test product type detection
      expect(purchaseService.isConsumable('coins_100'), true);
      expect(purchaseService.isConsumable('remove_ads'), false);
    });
    
    test('should handle subscription upgrade', () async {
      // Arrange
      final existingSubscription = MockPurchaseData.createMockPurchase(
        productId: 'monthly_sub',
        isSubscription: true,
      );
      
      purchaseService.setActivePurchases([existingSubscription]);
      
      // Act
      await purchaseService.upgradeSubscription(
        from: 'monthly_sub',
        to: 'yearly_sub',
      );
      
      // Assert
      verify(mockIAP.requestSubscription(
        'yearly_sub',
        purchaseTokenAndroid: anyNamed('purchaseTokenAndroid'),
        prorationModeAndroid: anyNamed('prorationModeAndroid'),
      )).called(1);
    });
  });
}
```

### Widget Testing

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Purchase UI Widget Tests', () {
    testWidgets('should display products correctly', (tester) async {
      // Arrange
      final mockProducts = MockPurchaseData.getMockProducts();
      
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: ProductListWidget(products: mockProducts),
        ),
      );
      
      // Assert
      expect(find.text('Test Coins'), findsOneWidget);
      expect(find.text('Test Premium'), findsOneWidget);
      expect(find.text('\$0.99'), findsOneWidget);
    });
    
    testWidgets('should handle purchase button tap', (tester) async {
      // Arrange
      final mockProducts = MockPurchaseData.getMockProducts();
      var purchasedProductId = '';
      
      await tester.pumpWidget(
        MaterialApp(
          home: ProductListWidget(
            products: mockProducts,
            onPurchase: (productId) {
              purchasedProductId = productId;
            },
          ),
        ),
      );
      
      // Act
      await tester.tap(find.text('\$0.99'));
      await tester.pump();
      
      // Assert
      expect(purchasedProductId, 'test_consumable');
    });
    
    testWidgets('should show loading during purchase', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: PurchaseButton(
            product: MockPurchaseData.getMockProducts().first,
            isLoading: true,
          ),
        ),
      );
      
      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
    
    testWidgets('should disable button for owned products', (tester) async {
      // Arrange
      final product = MockPurchaseData.getMockProducts().first;
      
      await tester.pumpWidget(
        MaterialApp(
          home: PurchaseButton(
            product: product,
            isOwned: true,
          ),
        ),
      );
      
      // Assert
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, null);
    });
  });
}
```

## Integration Testing

### Full Purchase Flow Tests

```dart
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('Purchase Flow Integration Tests', () {
    testWidgets('complete purchase flow', (tester) async {
      // Launch app
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();
      
      // Navigate to store
      await tester.tap(find.text('Store'));
      await tester.pumpAndSettle();
      
      // Wait for products to load
      await tester.pump(Duration(seconds: 2));
      
      // Find and tap purchase button
      final purchaseButton = find.text('Buy').first;
      await tester.tap(purchaseButton);
      
      // Handle platform purchase dialog (iOS/Android)
      await _handlePurchaseDialog(tester);
      
      // Wait for purchase completion
      await tester.pump(Duration(seconds: 5));
      
      // Verify purchase success UI
      expect(find.text('Purchase successful'), findsOneWidget);
      
      // Verify product is now owned
      expect(find.text('Owned'), findsOneWidget);
    });
    
    testWidgets('restore purchases flow', (tester) async {
      // Launch app
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();
      
      // Navigate to settings
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      
      // Tap restore purchases
      await tester.tap(find.text('Restore Purchases'));
      await tester.pumpAndSettle();
      
      // Wait for restore completion
      await tester.pump(Duration(seconds: 3));
      
      // Verify restore result
      expect(
        find.textContaining('Restored'),
        findsOneWidget,
      );
    });
  });
}

Future<void> _handlePurchaseDialog(WidgetTester tester) async {
  // This would need platform-specific handling
  // iOS: Handle StoreKit dialog
  // Android: Handle Google Play dialog
  
  if (Platform.isIOS) {
    // iOS purchase confirmation might appear
    await tester.pump(Duration(seconds: 1));
    
    // Look for iOS purchase dialog and confirm
    // This is tricky as it's a native dialog
  } else if (Platform.isAndroid) {
    // Android purchase flow
    await tester.pump(Duration(seconds: 1));
    
    // Handle Google Play purchase dialog
  }
}
```

## Performance Testing

### Purchase Performance Metrics

```dart
class PurchasePerformanceTest {
  static Future<void> measurePurchaseFlow() async {
    final stopwatch = Stopwatch();
    
    // Measure initialization time
    stopwatch.start();
    await FlutterInappPurchase.instance.initConnection();
    final initTime = stopwatch.elapsedMilliseconds;
    stopwatch.reset();
    
    // Measure product loading time
    stopwatch.start();
    await FlutterInappPurchase.instance.requestProducts(skus: ['test_product'], type: 'inapp');
    final loadTime = stopwatch.elapsedMilliseconds;
    stopwatch.reset();
    
    // Measure purchase time
    stopwatch.start();
    try {
      await FlutterInappPurchase.instance.requestPurchase(
        request: RequestPurchase(
          ios: RequestPurchaseIOS(sku: 'test_product'),
          android: RequestPurchaseAndroid(skus: ['test_product']),
        ),
        type: PurchaseType.inapp,
      );
    } catch (e) {
      // Expected for test
    }
    final purchaseTime = stopwatch.elapsedMilliseconds;
    
    // Report metrics
    print('Performance Metrics:');
    print('  Initialization: ${initTime}ms');
    print('  Product Loading: ${loadTime}ms');
    print('  Purchase Request: ${purchaseTime}ms');
    
    // Send to analytics
    AnalyticsService.logEvent('iap_performance', {
      'init_time_ms': initTime,
      'load_time_ms': loadTime,
      'purchase_time_ms': purchaseTime,
    });
  }
  
  static Future<void> stressTestPurchaseFlow() async {
    const iterations = 10;
    final times = <int>[];
    
    for (int i = 0; i < iterations; i++) {
      final stopwatch = Stopwatch()..start();
      
      try {
        await FlutterInappPurchase.instance.requestProducts(skus: ['test_product'], type: 'inapp');
      } catch (e) {
        // Continue testing
      }
      
      times.add(stopwatch.elapsedMilliseconds);
    }
    
    final avgTime = times.reduce((a, b) => a + b) / times.length;
    final maxTime = times.reduce((a, b) => a > b ? a : b);
    final minTime = times.reduce((a, b) => a < b ? a : b);
    
    print('Stress Test Results ($iterations iterations):');
    print('  Average: ${avgTime.toStringAsFixed(1)}ms');
    print('  Min: ${minTime}ms');
    print('  Max: ${maxTime}ms');
  }
}
```

## Test Automation

### Automated Test Suite

```dart
class AutomatedTestSuite {
  static Future<void> runFullTestSuite() async {
    print('Starting automated IAP test suite...');
    
    final results = <String, bool>{};
    
    // Run all test categories
    results['Unit Tests'] = await _runUnitTests();
    results['Widget Tests'] = await _runWidgetTests();
    results['Integration Tests'] = await _runIntegrationTests();
    results['Performance Tests'] = await _runPerformanceTests();
    results['Error Handling Tests'] = await _runErrorTests();
    
    // Generate report
    _generateTestReport(results);
  }
  
  static Future<bool> _runUnitTests() async {
    try {
      // Run all unit tests
      await PurchaseLogicTest.runAllTests();
      await ValidationTest.runAllTests();
      await ErrorHandlingTest.runAllTests();
      
      return true;
    } catch (e) {
      print('Unit tests failed: $e');
      return false;
    }
  }
  
  static Future<bool> _runWidgetTests() async {
    try {
      // Run widget tests
      await ProductWidgetTest.runAllTests();
      await PurchaseButtonTest.runAllTests();
      
      return true;
    } catch (e) {
      print('Widget tests failed: $e');
      return false;
    }
  }
  
  static void _generateTestReport(Map<String, bool> results) {
    print('\n=== IAP Test Report ===');
    
    results.forEach((testType, passed) {
      final status = passed ? '✓ PASS' : '✗ FAIL';
      print('$testType: $status');
    });
    
    final passCount = results.values.where((v) => v).length;
    final totalCount = results.length;
    
    print('\nOverall: $passCount/$totalCount tests passed');
    
    if (passCount == totalCount) {
      print('🎉 All tests passed!');
    } else {
      print('❌ Some tests failed - check logs for details');
    }
  }
}
```

## Best Practices

1. **Test Early and Often**: Start testing IAP integration early in development
2. **Use Sandbox Environments**: Always test with official sandbox environments
3. **Test All Scenarios**: Include success, failure, and edge case scenarios
4. **Mock External Dependencies**: Use mocks for unit testing
5. **Test Platform Differences**: Ensure both iOS and Android work correctly
6. **Performance Testing**: Monitor IAP operation performance
7. **Automated Testing**: Set up CI/CD pipeline with automated tests
8. **User Testing**: Conduct user testing with real test accounts
9. **Error Scenario Testing**: Test all error conditions
10. **Documentation**: Document test procedures and results

## Common Testing Pitfalls

1. **Forgetting Sandbox Setup**: Not properly configuring sandbox accounts
2. **Testing in Production**: Never test purchases in production environment
3. **Ignoring Platform Differences**: Not testing platform-specific features
4. **Missing Error Cases**: Not testing failure scenarios
5. **Cache Issues**: Not clearing test data between test runs
6. **Timing Issues**: Not accounting for async nature of purchases
7. **Network Dependencies**: Not testing offline scenarios
8. **Configuration Errors**: Product IDs not matching store configuration

## Related Documentation

- [Purchases Guide](./purchases.md) - Purchase implementation
- [Subscriptions Guide](./subscriptions.md) - Subscription testing
- [Error Handling](./error-handling.md) - Testing error scenarios
- [Receipt Validation](./receipt-validation.md) - Testing validation flows