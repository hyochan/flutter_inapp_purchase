---
title: Basic Setup Guide
sidebar_label: Basic Setup
sidebar_position: 1
---

# 📖 Basic Setup Guide

Learn the fundamentals of setting up in-app purchases with flutter_inapp_purchase.

## 🎯 Overview

This guide covers the essential steps for implementing basic in-app purchases in your Flutter app. By the end, you'll have a working purchase flow that handles both iOS and Android platforms.

## 🏗️ Project Structure

First, let's organize our code properly:

```
lib/
├── main.dart
├── services/
│   ├── iap_service.dart      # Purchase logic
│   └── purchase_handler.dart # Purchase event handling
├── models/
│   └── product_model.dart    # Product data models
└── screens/
    └── store_screen.dart     # Purchase UI
```

## 🔧 Creating the IAP Service

Create a dedicated service class to handle all purchase operations:

```dart title="lib/services/iap_service.dart"
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

class IAPService {
  static final IAPService _instance = IAPService._internal();
  factory IAPService() => _instance;
  IAPService._internal();

  // Stream subscriptions
  StreamSubscription<Purchase?>? _purchaseSubscription;
  StreamSubscription<PurchaseResult?>? _errorSubscription;

  // Connection state
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // Product IDs - Configure these for your app
  static const List<String> _productIds = [
    'remove_ads',
    'premium_upgrade',
    'extra_lives',
  ];

  static const List<String> _subscriptionIds = [
    'monthly_premium',
    'yearly_premium',
  ];

  /// Initialize the IAP service
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Initialize connection
      await FlutterInappPurchase.instance.initConnection();

      // Set up purchase listeners
      _setupPurchaseListeners();

      _isInitialized = true;
      print('✅ IAP Service initialized successfully');
      return true;
    } catch (e) {
      print('❌ Failed to initialize IAP Service: $e');
      return false;
    }
  }

  /// Set up purchase event listeners
  void _setupPurchaseListeners() {
    // Listen for successful purchases
    _purchaseSubscription = FlutterInappPurchase.purchaseUpdated.listen(
      (purchase) async {
        if (purchase != null) {
          await _handlePurchaseUpdate(purchase);
        }
      },
      onError: (error) {
        print('Purchase stream error: $error');
      },
    );

    // Listen for purchase errors
    _errorSubscription = FlutterInappPurchase.purchaseError.listen(
      (error) {
        if (error != null) {
          _handlePurchaseError(error);
        }
      },
    );
  }

  /// Handle successful purchase updates
  Future<void> _handlePurchaseUpdate(Purchase purchase) async {
    print('🎉 Purchase received: ${purchase.productId}');

    try {
      // 1. Verify the purchase (implement your server verification here)
      final isValid = await _verifyPurchase(purchase);

      if (!isValid) {
        print('❌ Purchase verification failed');
        return;
      }

      // 2. Grant the purchased content
      await _grantPurchasedContent(purchase);

      // 3. Complete the transaction
      await FlutterInappPurchase.instance.finishTransaction(
        purchase,
        isConsumable: _isConsumableProduct(purchase.productId ?? ''),
      );

      print('✅ Purchase completed successfully: ${purchase.productId}');
    } catch (e) {
      print('❌ Error handling purchase: $e');
    }
  }

  /// Handle purchase errors
  void _handlePurchaseError(PurchaseResult error) {
    print('💥 Purchase error: ${error.message}');

    // Handle specific error codes
    switch (error.code) {
      case ErrorCode.UserCancelled:
        print('ℹ️ User cancelled the purchase');
        break;
      case ErrorCode.NetworkError:
        print('🌐 Network error occurred');
        // Show retry option to user
        break;
      case ErrorCode.ItemUnavailable:
        print('🚫 Product is not available');
        break;
      case ErrorCode.AlreadyOwned:
        print('✅ User already owns this product');
        // Restore the purchase
        break;
      default:
        print('❓ Unknown error: ${error.message}');
    }
  }

  /// Verify purchase with your server
  Future<bool> _verifyPurchase(Purchase purchase) async {
    // TODO: Implement server-side verification
    // This is crucial for security!

    // For now, return true (implement proper verification)
    await Future.delayed(Duration(milliseconds: 500)); // Simulate API call
    return true;
  }

  /// Grant purchased content to the user
  Future<void> _grantPurchasedContent(Purchase purchase) async {
    final productId = purchase.productId ?? '';

    // Grant content based on product ID
    switch (productId) {
      case 'remove_ads':
        await _removeAds();
        break;
      case 'premium_upgrade':
        await _unlockPremiumFeatures();
        break;
      case 'extra_lives':
        await _addExtraLives();
        break;
      case 'monthly_premium':
      case 'yearly_premium':
        await _activateSubscription(productId);
        break;
      default:
        print('⚠️ Unknown product: $productId');
    }
  }

  /// Check if a product is consumable
  bool _isConsumableProduct(String productId) {
    const consumableProducts = ['extra_lives'];
    return consumableProducts.contains(productId);
  }

  /// Get available products
  Future<List<ProductCommon>> fetchInAppProducts() async {
    if (!_isInitialized) {
      throw Exception('IAP Service not initialized');
    }

    try {
      final result = await FlutterInappPurchase.instance.fetchProducts(
        ProductRequest(
          skus: _productIds,
          type: ProductQueryType.InApp,
        ),
      );
      final products = result.inAppProducts();
      print('📦 Found ${products.length} products');
      return products;
    } catch (e) {
      print('❌ Error fetching products: $e');
      throw e;
    }
  }

  /// Get available subscriptions
  Future<List<ProductCommon>> fetchSubscriptions() async {
    if (!_isInitialized) {
      throw Exception('IAP Service not initialized');
    }

    try {
      final result = await FlutterInappPurchase.instance.fetchProducts(
        ProductRequest(
          skus: _subscriptionIds,
          type: ProductQueryType.Subs,
        ),
      );
      final subscriptions = result.subscriptionProducts();
      print('📑 Found ${subscriptions.length} subscriptions');
      return subscriptions;
    } catch (e) {
      print('❌ Error fetching subscriptions: $e');
      throw e;
    }
  }

  /// Purchase a product
  Future<void> purchaseProduct(String productId) async {
    if (!_isInitialized) {
      throw Exception('IAP Service not initialized');
    }

    try {
      print('🛒 Requesting purchase for: $productId');

      await FlutterInappPurchase.instance.requestPurchaseSimple(
        productId: productId,
        type: _subscriptionIds.contains(productId)
            ? PurchaseType.subs
            : PurchaseType.inapp,
      );
    } catch (e) {
      print('❌ Error requesting purchase: $e');
      throw e;
    }
  }

  /// Restore purchases
  Future<void> restorePurchases() async {
    if (!_isInitialized) {
      throw Exception('IAP Service not initialized');
    }

    try {
      print('🔄 Restoring purchases...');

      final purchases = await FlutterInappPurchase.instance.getAvailablePurchases();

      if (purchases == null || purchases.isEmpty) {
        print('ℹ️ No purchases to restore');
        return;
      }

      print('🎉 Found ${purchases.length} purchases to restore');

      for (final purchase in purchases) {
        await _grantPurchasedContent(purchase);
      }
    } catch (e) {
      print('❌ Error restoring purchases: $e');
      throw e;
    }
  }

  /// Clean up resources
  Future<void> dispose() async {
    await _purchaseSubscription?.cancel();
    await _errorSubscription?.cancel();

    if (_isInitialized) {
      await FlutterInappPurchase.instance.endConnection();
      _isInitialized = false;
    }

    print('🧹 IAP Service disposed');
  }

  // Content granting methods (implement based on your app's needs)
  Future<void> _removeAds() async {
    // Remove ads from your app
    print('🚫 Ads removed');
  }

  Future<void> _unlockPremiumFeatures() async {
    // Unlock premium features
    print('⭐ Premium features unlocked');
  }

  Future<void> _addExtraLives() async {
    // Add extra lives or credits
    print('❤️ Extra lives added');
  }

  Future<void> _activateSubscription(String subscriptionId) async {
    // Activate subscription benefits
    print('📅 Subscription activated: $subscriptionId');
  }
}
```

## 🖥️ Creating the Store Screen

Now create a simple store interface:

```dart title="lib/screens/store_screen.dart"
import 'package:flutter/material.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import '../services/iap_service.dart';

class StoreScreen extends StatefulWidget {
  @override
  _StoreScreenState createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  final IAPService _iapService = IAPService();

  List<IapItem> _products = [];
  List<IapItem> _subscriptions = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeStore();
  }

  Future<void> _initializeStore() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Initialize IAP service
      final initialized = await _iapService.initialize();
      if (!initialized) {
        throw Exception('Failed to initialize IAP service');
      }

      // Load products and subscriptions
      final products = await _iapService.fetchInAppProducts();
      final subscriptions = await _iapService.fetchSubscriptions();

      setState(() {
        _products = products;
        _subscriptions = subscriptions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _purchaseProduct(String productId) async {
    try {
      await _iapService.purchaseProduct(productId);
    } catch (e) {
      _showErrorDialog('Purchase failed: $e');
    }
  }

  Future<void> _restorePurchases() async {
    try {
      await _iapService.restorePurchases();
      _showSuccessDialog('Purchases restored successfully!');
    } catch (e) {
      _showErrorDialog('Restore failed: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Success'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('🛒 Store'),
        actions: [
          IconButton(
            icon: Icon(Icons.restore),
            onPressed: _restorePurchases,
            tooltip: 'Restore Purchases',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading store...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text('Error: $_error'),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initializeStore,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _initializeStore,
      child: ListView(
        padding: EdgeInsets.all(16),
        children: [
          if (_products.isNotEmpty) ...[
            _buildSectionHeader('💎 Premium Products'),
            ..._products.map(_buildProductCard),
            SizedBox(height: 24),
          ],
          if (_subscriptions.isNotEmpty) ...[
            _buildSectionHeader('📅 Subscriptions'),
            ..._subscriptions.map(_buildProductCard),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildProductCard(IapItem product) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.title ?? 'Unknown Product',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        product.description ?? 'No description available',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      product.localizedPrice ?? product.price ?? 'N/A',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => _purchaseProduct(product.productId ?? ''),
                      child: Text('Buy Now'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _iapService.dispose();
    super.dispose();
  }
}
```

## 🔌 Integrating with Your App

Update your main app to include the store:

```dart title="lib/main.dart"
import 'package:flutter/material.dart';
import 'screens/store_screen.dart';
import 'services/iap_service.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IAP Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My App')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome to My App!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            SizedBox(height: 32),
            ElevatedButton.icon(
              icon: Icon(Icons.shopping_cart),
              label: Text('Open Store'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => StoreScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
```

## ✅ Testing Your Setup

1. **Test Connection**: Run the app and open the store screen
2. **Load Products**: Verify products load correctly
3. **Test Purchase**: Try purchasing a test product
4. **Test Restore**: Use the restore button to restore purchases
5. **Error Handling**: Test with airplane mode to verify error handling

## 🚨 Important Security Notes

:::warning Server-Side Verification
The example above shows a placeholder `_verifyPurchase()` method. In production, you **must** implement proper server-side verification:

1. Send the purchase receipt to your server
2. Verify with Apple/Google servers
3. Only grant content after successful verification
   :::

## 🎯 Next Steps

Now that you have basic purchases working:

- [🔍 **Error Handling Guide**](/guides/error-handling) - Comprehensive error handling
- [🧪 **Testing Guide**](/guides/testing) - Testing strategies and best practices
- [📱 **Platform Differences**](/guides/platform-differences) - iOS vs Android specifics
- [💡 **Advanced Features**](/guides/advanced-features) - Subscriptions, promotional offers, etc.

---

🎉 **Congratulations!** You now have a working in-app purchase system. Remember to test thoroughly on both platforms before releasing to production.
