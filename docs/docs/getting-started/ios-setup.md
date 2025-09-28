---
title: iOS Setup
sidebar_label: iOS Setup
sidebar_position: 2
---

# iOS Setup

For complete iOS setup instructions including App Store Connect configuration, Xcode setup, and testing guidelines, please visit:

👉 **[iOS Setup Guide - openiap.dev](https://openiap.dev/docs/ios-setup)**

The guide covers:

- App Store Connect configuration
- Xcode project setup
- Sandbox testing
- Common troubleshooting steps

## Code Implementation

### Basic Setup

```dart
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

final List<String> iosProductIds = [
  'com.yourapp.premium_upgrade',
  'com.yourapp.remove_ads',
  'com.yourapp.monthly_subscription',
];

class IOSStoreExample extends StatefulWidget {
  @override
  _IOSStoreExampleState createState() => _IOSStoreExampleState();
}

class _IOSStoreExampleState extends State<IOSStoreExample> {
  late StreamSubscription _purchaseUpdatedSubscription;
  late StreamSubscription _purchaseErrorSubscription;
  List<IapItem> _products = [];
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
    }
  }

  Future<void> _loadProducts() async {
    try {
      final products = await FlutterInappPurchase.instance.fetchProducts(
        ProductRequest(
          skus: iosProductIds,
          type: ProductQueryType.InApp,
        ),
      );
      setState(() {
        _products = products;
      });
    } catch (error) {
      print('Failed to get products: $error');
    }
  }

  void _handlePurchaseUpdate(PurchaseResult? purchase) {
    if (purchase != null) {
      switch (purchase.purchaseStateIOS) {
        case PurchaseState.purchased:
          _verifyAndFinishPurchase(purchase);
          break;
        case PurchaseState.restored:
          print('Purchase restored: ${purchase.productId}');
          break;
        case PurchaseState.purchasing:
          print('Purchase in progress: ${purchase.productId}');
          break;
        case PurchaseState.deferred:
          print('Purchase deferred: ${purchase.productId}');
          break;
        case PurchaseState.failed:
          print('Purchase failed: ${purchase.productId}');
          break;
      }
    }
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
      await FlutterInappPurchase.instance.finishTransactionIOS(
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
    // Implement server-side receipt validation
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
        title: Text('iOS Store'),
      ),
      body: Column(
        children: [
          Text('Store Available: $_isAvailable'),
          Expanded(
            child: ListView.builder(
              itemCount: _products.length,
              itemBuilder: (context, index) {
                final product = _products[index];
                return IOSProductTile(
                  product: product,
                  onPurchase: () => _purchaseProduct(product),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _purchaseProduct(IapItem product) async {
    try {
      await FlutterInappPurchase.instance.requestPurchase(
        RequestPurchase(
          ios: RequestPurchaseIosProps(sku: product.productId!),
        ),
        PurchaseType.inapp,
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

class IOSProductTile extends StatelessWidget {
  final IapItem product;
  final VoidCallback onPurchase;

  const IOSProductTile({
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

### iOS-Specific Features

#### StoreKit 2 Support

```dart
// Check StoreKit 2 availability
Future<void> checkStoreKit2Support() async {
  if (Platform.isIOS) {
    final version = await FlutterInappPurchase.instance.getIOSVersion();
    final isStoreKit2Available = version >= 15.0;
    print('StoreKit 2 available: $isStoreKit2Available');
  }
}
```

#### Subscription Management

```dart
// Show subscription management page
Future<void> showSubscriptionManagement() async {
  if (Platform.isIOS) {
    await FlutterInappPurchase.instance.showManageSubscriptions();
  }
}

// Present code redemption sheet
Future<void> redeemCode() async {
  if (Platform.isIOS) {
    await FlutterInappPurchase.instance.presentCodeRedemptionSheet();
  }
}
```

#### Restore Purchases

```dart
Future<void> restorePurchases() async {
  try {
    final restoredPurchases = await FlutterInappPurchase.instance.restoreTransactions();
    print('Restored ${restoredPurchases.length} purchases');

    for (var purchase in restoredPurchases) {
      await _verifyAndFinishPurchase(purchase);
    }
  } catch (error) {
    print('Restore failed: $error');
  }
}
```

### Error Handling

```dart
void handleIOSError(PurchaseResult? error) {
  if (error?.code != null) {
    switch (error!.code) {
      case 'E_USER_CANCELLED':
        // User cancelled - no action needed
        break;
      case 'E_PAYMENT_INVALID':
        showErrorDialog('Payment information is invalid');
        break;
      case 'E_PAYMENT_NOT_ALLOWED':
        showErrorDialog('Payments are not allowed on this device');
        break;
      case 'E_PRODUCT_NOT_AVAILABLE':
        showErrorDialog('This product is not available');
        break;
      case 'E_RECEIPT_FAILED':
        showErrorDialog('Receipt validation failed');
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

## Common Issues

### Products Not Loading

**Problem**: `fetchProducts()` returns empty list or throws error
**Solutions**:

- Verify product IDs match exactly between code and App Store Connect
- Ensure products are **Active** in App Store Connect
- Check that all Apple Developer agreements are signed
- Wait 24 hours after creating products in App Store Connect

### Testing Issues

**Problem**: "Cannot connect to iTunes Store" error
**Solutions**:

- Test on real device, not simulator
- Use proper sandbox tester account
- Sign out of production Apple ID first
- Ensure In-App Purchase capability is enabled in Xcode

### Receipt Validation

**Problem**: Receipt validation failing
**Solutions**:

- Always validate receipts on your server, not client-side
- Use Apple's receipt validation API
- Handle both sandbox and production receipt endpoints
- Implement proper retry logic for network failures

## Next Steps

- [Learn about getting started guide](./quickstart)
- [Explore Android setup](./android-setup)
- [Understand error codes](../api/error-codes)
