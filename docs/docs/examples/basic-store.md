---
title: Basic Store Implementation
sidebar_label: Basic Store
sidebar_position: 1
---

# Basic Store Implementation

A simple store implementation demonstrating core flutter_inapp_purchase concepts and basic purchase flow. Perfect for getting started with in-app purchases.

## Key Features Demonstrated

- ✅ **Connection Management** - Initialize and manage store connection
- ✅ **Product Loading** - Fetch products from both App Store and Google Play
- ✅ **Purchase Flow** - Complete purchase process with user feedback
- ✅ **Transaction Finishing** - Properly complete transactions
- ✅ **Error Handling** - Handle common purchase errors gracefully
- ✅ **Platform Differences** - Handle iOS and Android specific requirements

## Platform Differences

⚠️ **Important**: This example handles key differences between iOS and Android:

- **iOS**: Uses single SKU per request, requires StoreKit configuration
- **Android**: Uses SKU arrays, requires Google Play Console setup
- **Receipt Handling**: Different receipt formats and validation approaches
- **Transaction States**: Platform-specific state management

## Complete Implementation

```dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

void main() {
  runApp(BasicStoreApp());
}

class BasicStoreApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Basic Store Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: BasicStoreScreen(),
    );
  }
}

class BasicStoreScreen extends StatefulWidget {
  @override
  _BasicStoreScreenState createState() => _BasicStoreScreenState();
}

class _BasicStoreScreenState extends State<BasicStoreScreen> {
  // IAP instance
  final FlutterInappPurchase _iap = FlutterInappPurchase.instance;

  // State management
  bool _isConnected = false;
  bool _isLoading = false;
  List<ProductCommon> _products = [];
  String? _errorMessage;
  Purchase? _latestPurchase;

  // Stream subscriptions
  StreamSubscription<Purchase>? _purchaseSubscription;
  StreamSubscription<PurchaseError>? _errorSubscription;

  // Product IDs - Replace with your actual product IDs
  final List<String> _productIds = [
    'coins_100',
    'coins_500',
    'remove_ads',
    'premium_upgrade',
  ];

  @override
  void initState() {
    super.initState();
    _initializeStore();
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    _errorSubscription?.cancel();
    _iap.endConnection();
    super.dispose();
  }

  /// Initialize the store connection and set up listeners
  Future<void> _initializeStore() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Initialize connection
      final connected = await _iap.initConnection();

      // Set up purchase success listener
      _purchaseSubscription = _iap.purchaseUpdated.listen(
        (purchase) {
          _handlePurchaseSuccess(purchase);
        },
        onError: (error) {
          _showError('Purchase stream error: $error');
        },
      );

      // Set up purchase error listener
      _errorSubscription = _iap.purchaseError.listen(
        (error) {
          _handlePurchaseError(error);
        },
      );

      setState(() {
        _isConnected = connected;
      });

      // Load products
      await _loadProducts();

    } catch (e) {
      _showError('Failed to initialize store: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Load products from the store
  Future<void> _loadProducts() async {
    if (!_isConnected) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _iap.fetchProducts(
        ProductRequest(
          skus: _productIds,
          type: ProductQueryType.InApp,
        ),
      );

      setState(() {
        _products = result.value;
      });

      print('✅ Loaded ${result.value.length} products');
      for (final product in result.value) {
        print('Product: ${product.id} - ${product.displayPrice}');
      }

    } catch (e) {
      _showError('Failed to load products: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Handle successful purchase
  Future<void> _handlePurchaseSuccess(Purchase? purchase) async {
    if (purchase == null) return;

    print('✅ Purchase successful: ${purchase.productId}');

    setState(() {
      _latestPurchase = purchase;
      _errorMessage = null;
    });

    // Show success message
    _showSuccessSnackBar('Purchase successful: ${purchase.productId}');

    try {
      // 1. Here you would typically verify the purchase with your server
      final isValid = await _verifyPurchase(purchase);

      if (isValid) {
        // 2. Deliver the product to the user
        await _deliverProduct(purchase.productId);

        // 3. Finish the transaction
        await _finishTransaction(purchase);

        print('✅ Purchase completed and delivered');
      } else {
        _showError('Purchase verification failed');
      }

    } catch (e) {
      _showError('Error processing purchase: $e');
    }
  }

  /// Handle purchase errors
  void _handlePurchaseError(PurchaseError? error) {
    if (error == null) return;

    print('❌ Purchase failed: ${error.message}');

    setState(() {
      _latestPurchase = null;
    });

    // Handle specific error codes
    final code = error.code;
    if (code == 'E_USER_CANCELLED') {
      // Don't show error for user cancellation
      print('User cancelled purchase');
    } else if (code == 'E_NETWORK_ERROR') {
      _showError('Network error. Please check your connection and try again.');
    } else if (code == 'E_ALREADY_OWNED') {
      _showError('You already own this item. Try restoring your purchases.');
    } else {
      _showError(error.message ?? 'Purchase failed. Please try again.');
    }
  }

  /// Verify purchase with server (mock implementation)
  Future<bool> _verifyPurchase(Purchase purchase) async {
    // In a real app, send the receipt to your server for verification
    // For this example, we'll just simulate a successful verification
    await Future.delayed(Duration(milliseconds: 500));

    print('🔍 Verifying purchase: ${purchase.productId}');
    print('Receipt: ${purchase.transactionReceipt?.substring(0, 50)}...');

    return true; // Assume verification successful
  }

  /// Deliver the purchased product to the user
  Future<void> _deliverProduct(String? productId) async {
    if (productId == null) return;

    print('🎁 Delivering product: $productId');

    // Implement your product delivery logic here
    switch (productId) {
      case 'coins_100':
        // Add 100 coins to user's account
        print('Added 100 coins to user account');
        break;

      case 'coins_500':
        // Add 500 coins to user's account
        print('Added 500 coins to user account');
        break;

      case 'remove_ads':
        // Remove ads for user
        print('Removed ads for user');
        break;

      case 'premium_upgrade':
        // Upgrade user to premium
        print('Upgraded user to premium');
        break;

      default:
        print('Unknown product: $productId');
    }
  }

  /// Finish the transaction
  Future<void> _finishTransaction(Purchase purchase) async {
    try {
      if (Platform.isAndroid) {
        // For Android, consume the purchase if it's a consumable product
        if (purchase.purchaseToken != null) {
          if (_isConsumableProduct(purchase.productId)) {
            await _iap.consumePurchaseAndroid(
              purchaseToken: purchase.purchaseToken!,
            );
            print('✅ Android purchase consumed');
          } else {
            await _iap.acknowledgePurchaseAndroid(
              purchaseToken: purchase.purchaseToken!,
            );
            print('✅ Android purchase acknowledged');
          }
        }
      } else if (Platform.isIOS) {
        // For iOS, finish the transaction
        await _iap.finishTransaction(
          purchase: purchase,
          isConsumable: _isConsumableProduct(purchase.productId),
        );
        print('✅ iOS transaction finished');
      }

      setState(() {
        _latestPurchase = null;
      });

    } catch (e) {
      _showError('Failed to finish transaction: $e');
    }
  }

  /// Check if a product is consumable
  bool _isConsumableProduct(String? productId) {
    // Define which products are consumable
    const consumableProducts = ['coins_100', 'coins_500'];
    return consumableProducts.contains(productId);
  }

  /// Make a purchase
  Future<void> _makePurchase(String productId) async {
    if (!_isConnected) {
      _showError('Not connected to store');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

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

      await _iap.requestPurchase(requestProps);

      print('🛒 Purchase requested for: $productId');

    } catch (e) {
      _showError('Failed to request purchase: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Restore purchases
  Future<void> _restorePurchases() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get available purchases
      final availablePurchases = await _iap.getAvailablePurchases();

      if (availablePurchases.isNotEmpty) {
        _showSuccessSnackBar('Restored ${availablePurchases.length} purchases');

        // Process restored purchases
        for (final purchase in availablePurchases) {
          await _deliverProduct(purchase.productId);
        }
      } else {
        _showSuccessSnackBar('No purchases to restore');
      }

    } catch (e) {
      _showError('Failed to restore purchases: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Show error message
  void _showError(String message) {
    setState(() {
      _errorMessage = message;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 4),
      ),
    );
  }

  /// Show success message
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Basic Store'),
        backgroundColor: _isConnected ? Colors.green : Colors.red,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadProducts,
          ),
          IconButton(
            icon: Icon(Icons.restore),
            onPressed: _restorePurchases,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        // Connection status
        _buildConnectionStatus(),

        // Error message
        if (_errorMessage != null) _buildErrorBanner(),

        // Latest purchase info
        if (_latestPurchase != null) _buildPurchaseInfo(),

        // Products list
        Expanded(child: _buildProductsList()),
      ],
    );
  }

  Widget _buildConnectionStatus() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: _isConnected ? Colors.green[100] : Colors.red[100],
      child: Row(
        children: [
          Icon(
            _isConnected ? Icons.cloud_done : Icons.cloud_off,
            color: _isConnected ? Colors.green[800] : Colors.red[800],
          ),
          SizedBox(width: 8),
          Text(
            _isConnected ? 'Connected to Store' : 'Not Connected',
            style: TextStyle(
              color: _isConnected ? Colors.green[800] : Colors.red[800],
              fontWeight: FontWeight.w600,
            ),
          ),
          Spacer(),
          if (_isLoading) SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      color: Colors.red[50],
      child: Row(
        children: [
          Icon(Icons.error, color: Colors.red[800]),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red[800]),
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _errorMessage = null),
            icon: Icon(Icons.close, color: Colors.red[800]),
          ),
        ],
      ),
    );
  }

  Widget _buildPurchaseInfo() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      color: Colors.blue[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shopping_cart, color: Colors.blue[800]),
              SizedBox(width: 8),
              Text(
                'Purchase Successful!',
                style: TextStyle(
                  color: Colors.blue[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            'Product: ${_latestPurchase!.productId}',
            style: TextStyle(color: Colors.blue[700]),
          ),
          Text(
            'Transaction: ${_latestPurchase!.transactionId ?? 'N/A'}',
            style: TextStyle(color: Colors.blue[700]),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsList() {
    if (_isLoading && _products.isEmpty) {
      return Center(child: CircularProgressIndicator());
    }

    if (_products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.store, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'No products available',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadProducts,
              child: Text('Reload Products'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        return _buildProductCard(product);
      },
    );
  }

  Widget _buildProductCard(ProductCommon product) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getProductIcon(product.id),
                    color: Colors.blue[800],
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        product.description,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  product.displayPrice,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
                ElevatedButton(
                  onPressed: _isLoading
                    ? null
                    : () => _makePurchase(product.id),
                  child: Text('Buy Now'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getProductIcon(String? productId) {
    switch (productId) {
      case 'coins_100':
      case 'coins_500':
        return Icons.monetization_on;
      case 'remove_ads':
        return Icons.block;
      case 'premium_upgrade':
        return Icons.star;
      default:
        return Icons.shopping_bag;
    }
  }
}
```

## Key Features Explained

### 1. Connection Management

```dart
await _iap.initConnection();
```

- Initializes connection to App Store or Google Play
- Must be called before any other IAP operations
- Connection state is monitored via `connectionUpdated` stream

### 2. Product Loading

```dart
final result = await _iap.fetchProducts(
  ProductRequest(
    skus: _productIds,
    type: ProductQueryType.InApp,
  ),
);
final products = result.value;
```

- Fetches product information from the store
- Returns localized pricing and descriptions
- Product IDs must be configured in store console

### 3. Purchase Flow

```dart
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

await _iap.requestPurchase(requestProps);
```

- Platform-specific request objects handle iOS/Android differences
- Purchase result comes through `purchaseUpdated` stream
- Errors are delivered via `purchaseError` stream

### 4. Transaction Finishing

```dart
// iOS
await _iap.finishTransaction(purchase: purchase, isConsumable: true);

// Android - Consumable
await _iap.consumePurchaseAndroid(purchaseToken: token);

// Android - Non-consumable
await _iap.acknowledgePurchaseAndroid(purchaseToken: token);
```

- Essential for completing the purchase flow
- iOS: `finishTransaction` for all purchases
- Android: `consumePurchaseAndroid` for consumables, `acknowledgePurchaseAndroid` for non-consumables

### 5. Error Handling

The example demonstrates handling common error scenarios:

- User cancellation (don't show error)
- Network errors (suggest retry)
- Already owned items (suggest restore)
- Generic errors (show user-friendly message)

## Usage Instructions

1. **Replace Product IDs**: Update `_productIds` with your actual product IDs
2. **Configure Stores**:
   - iOS: Add products to App Store Connect
   - Android: Add products to Google Play Console
3. **Implement Server Verification**: Replace `_verifyPurchase` with real server validation
4. **Customize Product Delivery**: Update `_deliverProduct` with your business logic
5. **Style the UI**: Customize the UI to match your app's design

## Customization Options

### Product Types

```dart
// For different product types
enum ProductType { consumable, nonConsumable, subscription }

bool _isConsumableProduct(String productId) {
  // Your logic to determine consumable products
  return ['coins_100', 'coins_500'].contains(productId);
}
```

### Custom Error Handling

```dart
void _handlePurchaseError(PurchaseError? error) {
  if (error == null) return;

  final code = error.code;
  if (code == 'E_USER_CANCELLED') {
    // User cancelled
  } else if (code == 'E_NETWORK_ERROR') {
    // Network error
  } else if (code == 'E_ALREADY_OWNED') {
    // Already owned
  }
  // Add your custom error handling
}
```

### Loading States

```dart
// Add loading indicators for better UX
bool _isLoading = false;
String? _loadingMessage;

void _setLoading(bool loading, [String? message]) {
  setState(() {
    _isLoading = loading;
    _loadingMessage = message;
  });
}
```

## Next Steps

- **Learn Subscriptions**: Check out the [Subscription Store Example](./subscription-store.md)
- **Advanced Features**: See the [Complete Implementation](./complete-implementation.md)
- **Error Handling**: Read the [Error Codes Reference](../api/error-codes.md)
- **Platform Setup**: Review [iOS Setup](../getting-started/ios-setup.md) and [Android Setup](../getting-started/android-setup.md)
