---
title: Android Setup
sidebar_label: Android Setup
sidebar_position: 3
---

# Android Setup

For complete Android setup instructions including Google Play Console configuration, app setup, and testing guidelines, please visit:

👉 **[Android Setup Guide - openiap.dev](https://openiap.dev/docs/android-setup)**

The guide covers:

- Google Play Console configuration
- App bundle setup and signing
- Testing with internal testing tracks
- Common troubleshooting steps

## Code Implementation

### Basic Setup

```dart
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

final List<String> androidProductIds = [
  'premium_upgrade',
  'coins_100',
  'monthly_subscription',
];

class AndroidStoreExample extends StatefulWidget {
  @override
  _AndroidStoreExampleState createState() => _AndroidStoreExampleState();
}

class _AndroidStoreExampleState extends State<AndroidStoreExample> {
  late StreamSubscription _purchaseUpdatedSubscription;
  late StreamSubscription _purchaseErrorSubscription;
  List<IapItem> _products = [];
  List<IapItem> _subscriptions = [];
  bool _isAvailable = false;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    // Initialize connection
    final result = await FlutterInappPurchase.instance.initConnection();
    print('Connection result: $result');

    if (!mounted) return;

    setState(() {
      _isAvailable = result;
    });

    // Listen for purchase updates
    _purchaseUpdatedSubscription =
        FlutterInappPurchase.purchaseUpdated.listen((purchase) {
      print('Purchase updated: ${purchase?.productId}');
      _handlePurchaseUpdate(purchase);
    });

    _purchaseErrorSubscription =
        FlutterInappPurchase.purchaseError.listen((error) {
      print('Purchase error: ${error?.message}');
      _handlePurchaseError(error);
    });

    // Get products if connected
    if (_isAvailable) {
      await _loadProducts();
      await _loadSubscriptions();
    }
  }

  Future<void> _loadProducts() async {
    try {
      final result = await FlutterInappPurchase.instance.fetchProducts(
        ProductRequest(
          skus:
              androidProductIds.where((id) => !id.contains('subscription')).toList(),
          type: ProductQueryType.InApp,
        ),
      );
      final products = result.inAppProducts();
      setState(() {
        _products = products;
      });
    } catch (error) {
      print('Failed to get products: $error');
    }
  }

  Future<void> _loadSubscriptions() async {
    try {
      final result = await FlutterInappPurchase.instance.fetchProducts(
        ProductRequest(
          skus: androidProductIds.where((id) => id.contains('subscription')).toList(),
          type: ProductQueryType.Subs,
        ),
      );
      final subscriptions = result.subscriptionProducts();
      setState(() {
        _subscriptions = subscriptions;
      });
    } catch (error) {
      print('Failed to get subscriptions: $error');
    }
  }

  void _handlePurchaseUpdate(PurchaseResult? purchase) {
    if (purchase != null) {
      switch (purchase.purchaseStateAndroid) {
        case PurchaseState.purchased:
          _verifyAndFinishPurchase(purchase);
          break;
        case PurchaseState.pending:
          print('Purchase pending: ${purchase.productId}');
          _showPendingMessage();
          break;
        case PurchaseState.unspecified:
          print('Purchase unspecified: ${purchase.productId}');
          break;
      }
    }
  }

  void _showPendingMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Purchase is pending. You will receive access once payment is confirmed.'),
        duration: Duration(seconds: 5),
      ),
    );
  }

  void _handlePurchaseError(PurchaseResult? error) {
    if (error != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Purchase Error'),
          content: Text(error.message ?? 'Unknown error occurred'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _verifyAndFinishPurchase(PurchaseResult purchase) async {
    // Verify purchase on your server
    final isValid = await _verifyPurchaseOnServer(purchase);

    if (isValid) {
      // Grant access to content
      await _grantPurchaseContent(purchase);

      // Finish the transaction
      await FlutterInappPurchase.instance.finishTransactionAndroid(
        purchase,
        isConsumable: purchase.productId?.contains('consumable') ?? false,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Purchase successful!')),
      );
    } else {
      print('Purchase verification failed');
    }
  }

  Future<bool> _verifyPurchaseOnServer(PurchaseResult purchase) async {
    // Implement server-side purchase token validation
    // This is a placeholder - implement your actual validation logic
    return true;
  }

  Future<void> _grantPurchaseContent(PurchaseResult purchase) async {
    // Grant the purchased content to the user
    print('Granting content for: ${purchase.productId}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Android Store'),
      ),
      body: Column(
        children: [
          Text('Store Available: $_isAvailable'),
          Expanded(
            child: ListView(
              children: [
                if (_products.isNotEmpty) ...[
                  Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('Products', style: Theme.of(context).textTheme.headlineSmall),
                  ),
                  ..._products.map((product) => AndroidProductTile(
                    product: product,
                    onPurchase: () => _purchaseProduct(product, PurchaseType.inapp),
                  )),
                ],
                if (_subscriptions.isNotEmpty) ...[
                  Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('Subscriptions', style: Theme.of(context).textTheme.headlineSmall),
                  ),
                  ..._subscriptions.map((subscription) => AndroidProductTile(
                    product: subscription,
                    onPurchase: () => _purchaseProduct(subscription, PurchaseType.subs),
                  )),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _purchaseProduct(IapItem product, PurchaseType type) async {
    try {
      await FlutterInappPurchase.instance.requestPurchase(
        RequestPurchase(
          android: RequestPurchaseAndroidProps(skus: [product.productId!]),
        ),
        type,
      );
    } catch (error) {
      print('Purchase request failed: $error');
    }
  }

  @override
  void dispose() {
    _purchaseUpdatedSubscription.cancel();
    _purchaseErrorSubscription.cancel();
    FlutterInappPurchase.instance.finishTransaction();
    super.dispose();
  }
}

class AndroidProductTile extends StatelessWidget {
  final IapItem product;
  final VoidCallback onPurchase;

  const AndroidProductTile({
    Key? key,
    required this.product,
    required this.onPurchase,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8.0),
      child: ListTile(
        title: Text(product.title ?? 'Unknown Product'),
        subtitle: Text(product.description ?? 'No description'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              product.localizedPrice ?? 'N/A',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            ElevatedButton(
              onPressed: onPurchase,
              child: Text('Buy'),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Error Handling

```dart
void handleAndroidError(PurchaseResult? error) {
  if (error?.code != null) {
    switch (error!.code) {
      case 'E_USER_CANCELLED':
        // User cancelled - no action needed
        break;
      case 'E_SERVICE_DISCONNECTED':
        showErrorDialog('Google Play services are unavailable');
        break;
      case 'E_BILLING_UNAVAILABLE':
        showErrorDialog('Billing is not available on this device');
        break;
      case 'E_ITEM_UNAVAILABLE':
        showErrorDialog('This product is not available for purchase');
        break;
      case 'E_DEVELOPER_ERROR':
        showErrorDialog('Configuration error. Please contact support.');
        break;
      case 'E_ITEM_ALREADY_OWNED':
        showErrorDialog('You already own this item');
        break;
      case 'E_ITEM_NOT_OWNED':
        showErrorDialog('You do not own this item');
        break;
      default:
        showErrorDialog('Purchase failed: ${error.message}');
    }
  }
}

void showErrorDialog(String message) {
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
```

### Purchase Validation

```dart
// Validate purchase on your server
Future<bool> validatePurchaseOnServer(PurchaseResult purchase) async {
  try {
    final response = await http.post(
      Uri.parse('https://your-server.com/validate-purchase'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'purchaseToken': purchase.purchaseToken,
        'productId': purchase.productId,
        'packageName': 'your.app.package.name',
      }),
    );

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      return result['valid'] == true;
    }

    return false;
  } catch (error) {
    print('Validation failed: $error');
    return false;
  }
}
```

## Common Issues

### Product IDs Not Found

**Problem**: Products return empty or show as unavailable
**Solutions**:

- Verify product IDs match exactly between code and Play Console
- Ensure products are **Active** in Play Console
- Check that app is uploaded to at least Internal testing track
- Verify the app package name matches

### Testing Issues

**Problem**: "Item not found" or "Authentication required" errors
**Solutions**:

- Use Gmail accounts added as test users
- Install app from testing track, not directly via ADB
- Ensure test user has a valid payment method
- Clear Google Play Store cache and data

### Purchase Flow Issues

**Problem**: Purchase dialog doesn't appear or fails immediately
**Solutions**:

- Verify Google Play services are updated
- Check device has valid Google account
- Ensure app is properly signed
- Test on different devices

### Subscription Issues

**Problem**: Subscription offers not showing or failing
**Solutions**:

- Verify base plans are properly configured
- Check offer eligibility rules
- Ensure proper offer token handling
- Test with different user accounts

## Next Steps

- [Learn about getting started guide](./quickstart)
- [Explore iOS setup](./ios-setup)
- [Understand error codes](../api/error-codes)
