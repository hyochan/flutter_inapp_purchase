---
sidebar_position: 4
---

# Quick Start

Get up and running with Flutter In-App Purchase in minutes.

## Complete Example

Here's a complete example implementing a simple store with products and subscriptions:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'dart:async';

class SimpleStore extends StatefulWidget {
  @override
  _SimpleStoreState createState() => _SimpleStoreState();
}

class _SimpleStoreState extends State<SimpleStore> {
  StreamSubscription? _purchaseUpdatedSubscription;
  StreamSubscription? _purchaseErrorSubscription;
  
  List<IAPItem> _products = [];
  List<IAPItem> _subscriptions = [];
  List<PurchasedItem> _purchases = [];
  
  // Your product IDs from App Store Connect / Google Play Console
  final List<String> _productIds = [
    'com.example.coins_100',
    'com.example.coins_500',
  ];
  
  final List<String> _subscriptionIds = [
    'com.example.premium_monthly',
    'com.example.premium_yearly',
  ];

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  @override
  void dispose() {
    _purchaseUpdatedSubscription?.cancel();
    _purchaseErrorSubscription?.cancel();
    super.dispose();
  }

  // Initialize the plugin
  Future<void> initPlatformState() async {
    // Initialize connection
    var result = await FlutterInappPurchase.instance.initialize();
    print('IAP initialized: $result');
    
    // Set up purchase listeners
    _purchaseUpdatedSubscription = 
        FlutterInappPurchase.purchaseUpdated.listen((productItem) {
      print('Purchase updated: ${productItem?.productId}');
      _handlePurchaseUpdate(productItem!);
    });
    
    _purchaseErrorSubscription = 
        FlutterInappPurchase.purchaseError.listen((purchaseError) {
      print('Purchase error: $purchaseError');
      _showError('Purchase failed: ${purchaseError.message}');
    });
    
    // Load products and purchases
    await _getProducts();
    await _getPurchases();
  }

  // Get available products
  Future<void> _getProducts() async {
    try {
      // Get consumable products
      List<IAPItem> products = 
          await FlutterInappPurchase.instance.requestProducts(
            skus: _productIds,
            type: 'inapp',
          );
      
      // Get subscriptions
      List<IAPItem> subscriptions = 
          await FlutterInappPurchase.instance.requestProducts(
            skus: _subscriptionIds,
            type: 'subs',
          );
      
      setState(() {
        _products = products;
        _subscriptions = subscriptions;
      });
    } catch (e) {
      _showError('Failed to load products: $e');
    }
  }

  // Get previous purchases
  Future<void> _getPurchases() async {
    try {
      List<PurchasedItem>? purchases = 
          await FlutterInappPurchase.instance.getAvailablePurchases();
      
      setState(() {
        _purchases = purchases ?? [];
      });
    } catch (e) {
      _showError('Failed to load purchases: $e');
    }
  }

  // Handle purchase updates
  void _handlePurchaseUpdate(PurchasedItem productItem) async {
    // Verify purchase on your server here
    bool isValid = await _verifyPurchase(productItem);
    
    if (isValid) {
      // Deliver the product to user
      await _deliverProduct(productItem);
      
      // Finish the transaction
      if (Platform.isIOS) {
        await FlutterInappPurchase.instance.finishTransaction(productItem);
      } else if (productItem.isConsumableAndroid ?? false) {
        await FlutterInappPurchase.instance.consumePurchase(
          purchaseToken: productItem.purchaseTokenAndroid!,
        );
      } else {
        await FlutterInappPurchase.instance.acknowledgePurchase(
          purchaseToken: productItem.purchaseTokenAndroid!,
        );
      }
      
      // Update UI
      await _getPurchases();
      _showSuccess('Purchase successful!');
    }
  }

  // Request a purchase
  Future<void> _requestPurchase(String productId) async {
    try {
      await FlutterInappPurchase.instance.requestPurchase(productId);
    } catch (e) {
      _showError('Purchase failed: $e');
    }
  }

  // Request a subscription
  Future<void> _requestSubscription(String productId) async {
    try {
      await FlutterInappPurchase.instance.requestSubscription(productId);
    } catch (e) {
      _showError('Subscription failed: $e');
    }
  }

  // Restore purchases
  Future<void> _restorePurchases() async {
    try {
      await FlutterInappPurchase.instance.getAvailablePurchases();
      _showSuccess('Purchases restored!');
    } catch (e) {
      _showError('Restore failed: $e');
    }
  }

  // Verify purchase (implement your server logic)
  Future<bool> _verifyPurchase(PurchasedItem item) async {
    // TODO: Verify receipt with your server
    // For now, just return true
    return true;
  }

  // Deliver product (implement your logic)
  Future<void> _deliverProduct(PurchasedItem item) async {
    // TODO: Deliver the product to user
    print('Delivering product: ${item.productId}');
  }

  // UI Helper methods
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('In-App Purchase Example'),
        actions: [
          IconButton(
            icon: Icon(Icons.restore),
            onPressed: _restorePurchases,
            tooltip: 'Restore Purchases',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Products Section
            Text('Products', style: Theme.of(context).textTheme.headline6),
            SizedBox(height: 8),
            ..._products.map((product) => Card(
              child: ListTile(
                title: Text(product.title ?? product.productId ?? ''),
                subtitle: Text(product.description ?? ''),
                trailing: TextButton(
                  child: Text(product.localizedPrice ?? ''),
                  onPressed: () => _requestPurchase(product.productId!),
                ),
              ),
            )),
            
            SizedBox(height: 24),
            
            // Subscriptions Section
            Text('Subscriptions', style: Theme.of(context).textTheme.headline6),
            SizedBox(height: 8),
            ..._subscriptions.map((subscription) => Card(
              child: ListTile(
                title: Text(subscription.title ?? subscription.productId ?? ''),
                subtitle: Text(subscription.description ?? ''),
                trailing: TextButton(
                  child: Text(subscription.localizedPrice ?? ''),
                  onPressed: () => _requestSubscription(subscription.productId!),
                ),
                leading: _isPurchased(subscription.productId!) 
                    ? Icon(Icons.check_circle, color: Colors.green)
                    : null,
              ),
            )),
            
            SizedBox(height: 24),
            
            // Active Purchases Section
            Text('Active Purchases', style: Theme.of(context).textTheme.headline6),
            SizedBox(height: 8),
            if (_purchases.isEmpty)
              Text('No active purchases'),
            ..._purchases.map((purchase) => Card(
              child: ListTile(
                title: Text(purchase.productId ?? 'Unknown'),
                subtitle: Text('Purchased: ${DateTime.fromMillisecondsSinceEpoch(
                  purchase.transactionDate ?? 0
                )}'),
              ),
            )),
          ],
        ),
      ),
    );
  }
  
  bool _isPurchased(String productId) {
    return _purchases.any((purchase) => purchase.productId == productId);
  }
}
```

## Key Concepts

### 1. Initialization

Always initialize the plugin before using any other methods:

```dart
await FlutterInappPurchase.instance.initialize();
```

### 2. Loading Products

Fetch products using their IDs:

```dart
// Regular products
List<IAPItem> products = await FlutterInappPurchase.instance
    .requestProducts(skus: ['product_id_1', 'product_id_2'], type: 'inapp');

// Subscriptions
List<IAPItem> subscriptions = await FlutterInappPurchase.instance
    .requestProducts(skus: ['subscription_id_1', 'subscription_id_2'], type: 'subs');
```

### 3. Purchase Flow

Listen to purchase updates and handle them appropriately:

```dart
// Listen to successful purchases
FlutterInappPurchase.purchaseUpdated.listen((productItem) {
  // 1. Verify purchase
  // 2. Deliver content
  // 3. Finish transaction
});

// Listen to purchase errors
FlutterInappPurchase.purchaseError.listen((error) {
  // Handle error
});
```

### 4. Platform Differences

Handle platform-specific requirements:

```dart
if (Platform.isIOS) {
  // iOS: Always finish transactions
  await FlutterInappPurchase.instance.finishTransaction(item);
} else {
  // Android: Acknowledge or consume
  if (isConsumable) {
    await FlutterInappPurchase.instance.consumePurchase(
      purchaseToken: item.purchaseTokenAndroid!,
    );
  } else {
    await FlutterInappPurchase.instance.acknowledgePurchase(
      purchaseToken: item.purchaseTokenAndroid!,
    );
  }
}
```

## Best Practices

1. **Always verify purchases** server-side before delivering content
2. **Handle all error cases** to provide good user experience
3. **Test thoroughly** with sandbox/test accounts
4. **Restore purchases** when users reinstall or switch devices
5. **Clean up listeners** in dispose() to prevent memory leaks

## Next Steps

- [Products Guide](../guides/products) - Working with consumable products
- [Subscriptions Guide](../guides/subscriptions) - Implementing subscriptions
- [Receipt Validation](../guides/receipt-validation) - Secure purchase verification
- [Error Handling](../guides/error-handling) - Handling edge cases