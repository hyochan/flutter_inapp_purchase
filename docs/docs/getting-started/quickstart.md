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

  List<ProductCommon> _products = [];
  List<ProductCommon> _subscriptions = [];
  List<Purchase> _purchases = [];

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
    initIAP();
  }

  @override
  void dispose() {
    _purchaseUpdatedSubscription?.cancel();
    _purchaseErrorSubscription?.cancel();
    super.dispose();
  }

  // Initialize the plugin
  Future<void> initIAP() async {
    // Use singleton instance
    final iap = FlutterInappPurchase.instance;

    // Initialize connection
    await iap.initConnection();
    print('IAP connection initialized');

    // Set up purchase listeners
    _purchaseUpdatedSubscription =
        iap.purchaseUpdated.listen((productItem) {
      print('Purchase updated: ${productItem?.productId}');
      _handlePurchaseUpdate(productItem!);
    });

    _purchaseErrorSubscription =
        iap.purchaseError.listen((purchaseError) {
      print('Purchase error: $purchaseError');
      _showError('Purchase failed: ${purchaseError.message}');
    });

    // Load products and purchases
    await _loadProducts();
    await _getPurchases();
  }

  // Get available products
  Future<void> _loadProducts() async {
    try {
      // Get consumable products - use explicit type annotation
      final List<Product> products =
          await FlutterInappPurchase.instance.fetchProducts(
        skus: _productIds,
        type: ProductQueryType.InApp,
      );

      // Get subscriptions - use explicit type annotation
      final List<ProductSubscription> subscriptions =
          await FlutterInappPurchase.instance.fetchProducts(
        skus: _subscriptionIds,
        type: ProductQueryType.Subs,
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
      List<Purchase>? purchases =
          await FlutterInappPurchase.instance.getAvailablePurchases();

      setState(() {
        _purchases = purchases ?? [];
      });
    } catch (e) {
      _showError('Failed to load purchases: $e');
    }
  }

  // Handle purchase updates
  void _handlePurchaseUpdate(Purchase productItem) async {
    // Verify purchase on your server here
    bool isValid = await _verifyPurchase(productItem);

    if (isValid) {
      // Deliver the product to user
      await _deliverProduct(productItem);

      // Finish the transaction
      if (Platform.isIOS) {
        await FlutterInappPurchase.instance.finishTransaction(
          purchase: productItem,
          isConsumable: true, // Set based on your product type
        );
      } else if (productItem.isConsumableAndroid ?? false) {
        await FlutterInappPurchase.instance.consumePurchaseAndroid(
          purchaseToken: productItem.purchaseToken!,
        );
      } else {
        await FlutterInappPurchase.instance.acknowledgePurchaseAndroid(
          purchaseToken: productItem.purchaseToken!,
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
      final requestProps = RequestPurchaseProps.inApp(
        request: RequestPurchasePropsByPlatforms(
          ios: RequestPurchaseIosProps(
            sku: productId,
            quantity: 1,
          ),
          android: RequestPurchaseAndroidProps(
            skus: [productId],
          ),
        ),
      );

      await FlutterInappPurchase.instance.requestPurchase(requestProps);
    } catch (e) {
      _showError('Purchase failed: $e');
    }
  }

  // Request a subscription
  Future<void> _requestSubscription(String productId) async {
    try {
      final requestProps = RequestPurchaseProps.subs(
        request: RequestSubscriptionPropsByPlatforms(
          ios: RequestSubscriptionIosProps(
            sku: productId,
          ),
          android: RequestSubscriptionAndroidProps(
            skus: [productId],
          ),
        ),
      );

      await FlutterInappPurchase.instance.requestPurchase(requestProps);
    } catch (e) {
      _showError('Subscription failed: $e');
    }
  }

  // Restore purchases
  Future<void> _restorePurchases() async {
    try {
      await FlutterInappPurchase.instance.restorePurchases();
      await _getPurchases();
      _showSuccess('Purchases restored!');
    } catch (e) {
      _showError('Restore failed: $e');
    }
  }

  // Verify purchase (implement your server logic)
  Future<bool> _verifyPurchase(Purchase item) async {
    // TODO: Verify receipt with your server
    // For now, just return true
    return true;
  }

  // Deliver product (implement your logic)
  Future<void> _deliverProduct(Purchase item) async {
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
                  onPressed: () => _requestPurchase(subscription.productId!),
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

Always initialize the connection before using any other methods:

```dart
await FlutterInappPurchase.instance.initConnection();
```

### 2. Loading Products

Fetch products using their IDs with explicit type annotation:

```dart
// Regular products - use List<Product>
final List<Product> products = await FlutterInappPurchase.instance
    .fetchProducts(skus: ['product_id_1', 'product_id_2'], type: ProductQueryType.InApp);

// Subscriptions - use List<ProductSubscription>
final List<ProductSubscription> subscriptions = await FlutterInappPurchase.instance
    .fetchProducts(skus: ['subscription_id_1', 'subscription_id_2'], type: ProductQueryType.Subs);
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

// Request a purchase
await FlutterInappPurchase.instance.requestPurchase(
  request: RequestPurchase(
    ios: RequestPurchaseIOS(sku: 'product_id'),
    android: RequestPurchaseAndroid(skus: ['product_id']),
  ),
  type: PurchaseType.inapp, // or PurchaseType.subs for subscriptions
);
```

### 4. Platform Differences

Handle platform-specific requirements:

```dart
if (Platform.isIOS) {
  // iOS: Always finish transactions
  await FlutterInappPurchase.instance.finishTransaction(
    purchase: item,
    isConsumable: isConsumable,
  );
} else {
  // Android: Acknowledge or consume
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

## Best Practices

1. **Always verify purchases** server-side before delivering content
2. **Handle all error cases** to provide good user experience
3. **Test thoroughly** with sandbox/test accounts
4. **Restore purchases** when users reinstall or switch devices
5. **Clean up listeners** in dispose() to prevent memory leaks

## Next Steps

- [Products Guide](../guides/products) - Working with consumable products
- [Subscriptions Guide](../guides/subscriptions) - Implementing subscriptions
- [Error Handling](../guides/error-handling) - Handling edge cases
