---
sidebar_position: 1
title: Basic Store
---

# Basic Store Implementation

A complete example of implementing a basic in-app purchase store with consumable and non-consumable products.

## Overview

This example demonstrates:
- Product loading and display
- Purchase handling for consumables and non-consumables
- Error handling and user feedback
- Purchase restoration
- Simple state management

## Complete Implementation

### Store Service

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'dart:async';

class StoreService extends ChangeNotifier {
  static final StoreService _instance = StoreService._internal();
  factory StoreService() => _instance;
  StoreService._internal();

  final FlutterInappPurchase _iap = FlutterInappPurchase.instance;
  
  // Product configurations
  static const List<String> _consumableIds = [
    'com.example.coins_100',
    'com.example.coins_500',
    'com.example.coins_1000',
    'com.example.energy_pack',
  ];
  
  static const List<String> _nonConsumableIds = [
    'com.example.remove_ads',
    'com.example.premium_features',
    'com.example.unlock_themes',
  ];
  
  // State
  bool _isInitialized = false;
  bool _isLoading = false;
  List<IAPItem> _products = [];
  Set<String> _ownedProducts = {};
  String? _error;
  
  // Stream subscriptions
  StreamSubscription<PurchasedItem?>? _purchaseSubscription;
  StreamSubscription<PurchaseResult?>? _errorSubscription;
  
  // Getters
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  List<IAPItem> get products => List.unmodifiable(_products);
  Set<String> get ownedProducts => Set.unmodifiable(_ownedProducts);
  String? get error => _error;
  
  List<IAPItem> get consumables => _products
      .where((p) => _consumableIds.contains(p.productId))
      .toList();
      
  List<IAPItem> get nonConsumables => _products
      .where((p) => _nonConsumableIds.contains(p.productId))
      .toList();

  /// Initialize the store service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _setLoading(true);
      _clearError();
      
      // Initialize IAP connection
      await _iap.initConnection();
      
      // Set up purchase listeners
      _setupPurchaseListeners();
      
      // Load products
      await _loadProducts();
      
      // Load owned products
      await _loadOwnedProducts();
      
      _isInitialized = true;
      print('Store service initialized successfully');
      
    } catch (e) {
      _setError('Failed to initialize store: $e');
      print('Store initialization error: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// Load products from store
  Future<void> _loadProducts() async {
    try {
      final allProductIds = [..._consumableIds, ..._nonConsumableIds];
      _products = await _iap.requestProducts(skus: allProductIds, type: 'inapp');
      
      print('Loaded ${_products.length} products');
      notifyListeners();
      
    } catch (e) {
      throw Exception('Failed to load products: $e');
    }
  }
  
  /// Load previously owned products
  Future<void> _loadOwnedProducts() async {
    try {
      final purchases = await _iap.getAvailablePurchases();
      
      _ownedProducts.clear();
      for (var purchase in purchases) {
        if (_nonConsumableIds.contains(purchase.productId)) {
          _ownedProducts.add(purchase.productId!);
        }
      }
      
      print('Loaded ${_ownedProducts.length} owned products');
      notifyListeners();
      
    } catch (e) {
      print('Error loading owned products: $e');
    }
  }
  
  /// Set up purchase event listeners
  void _setupPurchaseListeners() {
    _purchaseSubscription = FlutterInappPurchase.purchaseUpdated
        .listen(_handlePurchaseUpdate);
    
    _errorSubscription = FlutterInappPurchase.purchaseError
        .listen(_handlePurchaseError);
  }
  
  /// Handle successful purchase updates
  Future<void> _handlePurchaseUpdate(PurchasedItem? item) async {
    if (item == null) return;
    
    print('Purchase update: ${item.productId}');
    
    try {
      // Verify the purchase (simplified for example)
      if (await _verifyPurchase(item)) {
        // Deliver content
        await _deliverContent(item);
        
        // Finish transaction
        await _finishTransaction(item);
        
        // Update owned products for non-consumables
        if (_nonConsumableIds.contains(item.productId)) {
          _ownedProducts.add(item.productId!);
          notifyListeners();
        }
        
        print('Purchase completed: ${item.productId}');
        
      } else {
        print('Purchase verification failed: ${item.productId}');
      }
      
    } catch (e) {
      print('Error processing purchase: $e');
      _setError('Failed to process purchase: $e');
    }
  }
  
  /// Handle purchase errors
  void _handlePurchaseError(PurchaseResult? error) {
    if (error == null) return;
    
    print('Purchase error: ${error.message}');
    
    String userMessage;
    switch (error.responseCode) {
      case 1: // User cancelled
        return; // Don't show error for user cancellation
      case 7: // Already owned
        userMessage = 'You already own this item';
        break;
      default:
        userMessage = error.message ?? 'Purchase failed';
    }
    
    _setError(userMessage);
  }
  
  /// Purchase a product
  Future<void> purchaseProduct(String productId) async {
    if (!_isInitialized) {
      throw Exception('Store not initialized');
    }
    
    // Check if non-consumable is already owned
    if (_nonConsumableIds.contains(productId) && 
        _ownedProducts.contains(productId)) {
      _setError('You already own this item');
      return;
    }
    
    try {
      _setLoading(true);
      _clearError();
      
      await _iap.requestPurchase(
        request: RequestPurchase(
          ios: RequestPurchaseIOS(
            sku: productId,
            appAccountToken: await _getUserId(),
          ),
          android: RequestPurchaseAndroid(
            skus: [productId],
            obfuscatedAccountIdAndroid: await _getUserId(),
          ),
        ),
        type: PurchaseType.inapp,
      );
      
      // Purchase result will come through purchaseUpdated stream
      
    } catch (e) {
      _setError('Purchase failed: $e');
      print('Purchase error: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// Restore purchases
  Future<void> restorePurchases() async {
    if (!_isInitialized) {
      throw Exception('Store not initialized');
    }
    
    try {
      _setLoading(true);
      _clearError();
      
      final purchases = await _iap.getAvailablePurchases();
      int restoredCount = 0;
      
      for (var purchase in purchases) {
        if (_nonConsumableIds.contains(purchase.productId)) {
          if (!_ownedProducts.contains(purchase.productId)) {
            // Verify and restore
            if (await _verifyPurchase(purchase)) {
              _ownedProducts.add(purchase.productId!);
              restoredCount++;
            }
          }
        }
      }
      
      if (restoredCount > 0) {
        print('Restored $restoredCount purchases');
        notifyListeners();
      } else {
        _setError('No purchases to restore');
      }
      
    } catch (e) {
      _setError('Failed to restore purchases: $e');
      print('Restore error: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// Simple purchase verification (implement proper verification in production)
  Future<bool> _verifyPurchase(dynamic purchase) async {
    // In production, verify with your backend server
    // This is a simplified example
    await Future.delayed(Duration(milliseconds: 500)); // Simulate network call
    return true;
  }
  
  /// Deliver purchased content
  Future<void> _deliverContent(PurchasedItem purchase) async {
    final productId = purchase.productId!;
    
    if (_consumableIds.contains(productId)) {
      await _deliverConsumable(productId);
    } else if (_nonConsumableIds.contains(productId)) {
      await _deliverNonConsumable(productId);
    }
  }
  
  /// Deliver consumable content
  Future<void> _deliverConsumable(String productId) async {
    // Implement your consumable delivery logic
    switch (productId) {
      case 'com.example.coins_100':
        // Add 100 coins to user account
        print('Added 100 coins');
        break;
      case 'com.example.coins_500':
        // Add 500 coins to user account
        print('Added 500 coins');
        break;
      case 'com.example.coins_1000':
        // Add 1000 coins to user account
        print('Added 1000 coins');
        break;
      case 'com.example.energy_pack':
        // Add energy pack to user account
        print('Added energy pack');
        break;
    }
  }
  
  /// Deliver non-consumable content
  Future<void> _deliverNonConsumable(String productId) async {
    // Implement your non-consumable delivery logic
    switch (productId) {
      case 'com.example.remove_ads':
        // Remove ads from the app
        print('Ads removed');
        break;
      case 'com.example.premium_features':
        // Unlock premium features
        print('Premium features unlocked');
        break;
      case 'com.example.unlock_themes':
        // Unlock all themes
        print('All themes unlocked');
        break;
    }
  }
  
  /// Finish transaction
  Future<void> _finishTransaction(PurchasedItem purchase) async {
    await _iap.finishTransactionIOS(
      purchase,
      isConsumable: _consumableIds.contains(purchase.productId),
    );
  }
  
  /// Get user ID for purchase tracking
  Future<String> _getUserId() async {
    // Return your user identifier
    return 'user_${DateTime.now().millisecondsSinceEpoch}';
  }
  
  /// Check if product is owned
  bool isProductOwned(String productId) {
    return _ownedProducts.contains(productId);
  }
  
  /// Get product by ID
  IAPItem? getProduct(String productId) {
    return _products
        .where((p) => p.productId == productId)
        .firstOrNull;
  }
  
  /// Utility methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }
  
  void _clearError() {
    _error = null;
    notifyListeners();
  }
  
  /// Dispose resources
  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    _errorSubscription?.cancel();
    
    if (_isInitialized) {
      _iap.endConnection();
    }
    
    super.dispose();
  }
}
```

### Store Screen UI

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class StoreScreen extends StatefulWidget {
  @override
  _StoreScreenState createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeStore();
    });
  }
  
  Future<void> _initializeStore() async {
    try {
      await context.read<StoreService>().initialize();
    } catch (e) {
      _showErrorSnackBar('Failed to initialize store: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Store'),
        actions: [
          IconButton(
            icon: Icon(Icons.restore),
            onPressed: _restorePurchases,
            tooltip: 'Restore Purchases',
          ),
        ],
      ),
      body: Consumer<StoreService>(
        builder: (context, store, child) {
          if (!store.isInitialized) {
            return _buildLoadingView();
          }
          
          if (store.products.isEmpty) {
            return _buildEmptyView();
          }
          
          return _buildStoreContent(store);
        },
      ),
    );
  }
  
  Widget _buildLoadingView() {
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
  
  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.store, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No products available',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          SizedBox(height: 8),
          Text('Please try again later'),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _initializeStore,
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStoreContent(StoreService store) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Error display
          if (store.error != null)
            _buildErrorCard(store.error!),
          
          // Loading indicator
          if (store.isLoading)
            _buildLoadingCard(),
          
          // Consumables section
          if (store.consumables.isNotEmpty) ...[
            _buildSectionHeader('Consumables'),
            SizedBox(height: 8),
            _buildProductGrid(store.consumables, store),
            SizedBox(height: 24),
          ],
          
          // Non-consumables section
          if (store.nonConsumables.isNotEmpty) ...[
            _buildSectionHeader('Premium Features'),
            SizedBox(height: 8),
            _buildProductGrid(store.nonConsumables, store),
          ],
        ],
      ),
    );
  }
  
  Widget _buildErrorCard(String error) {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                error,
                style: TextStyle(color: Colors.red.shade700),
              ),
            ),
            IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                context.read<StoreService>()._clearError();
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLoadingCard() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Processing...'),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }
  
  Widget _buildProductGrid(List<IAPItem> products, StoreService store) {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return ProductCard(
          product: product,
          isOwned: store.isProductOwned(product.productId!),
          onPurchase: () => _purchaseProduct(product.productId!),
        );
      },
    );
  }
  
  Future<void> _purchaseProduct(String productId) async {
    try {
      await context.read<StoreService>().purchaseProduct(productId);
    } catch (e) {
      _showErrorSnackBar('Purchase failed: $e');
    }
  }
  
  Future<void> _restorePurchases() async {
    try {
      await context.read<StoreService>().restorePurchases();
      _showSuccessSnackBar('Purchases restored successfully');
    } catch (e) {
      _showErrorSnackBar('Restore failed: $e');
    }
  }
  
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
  
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
}
```

### Product Card Widget

```dart
import 'package:flutter/material.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

class ProductCard extends StatelessWidget {
  final IAPItem product;
  final bool isOwned;
  final VoidCallback onPurchase;
  
  const ProductCard({
    Key? key,
    required this.product,
    required this.isOwned,
    required this.onPurchase,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: isOwned ? null : onPurchase,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product icon
              Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getProductIcon(),
                  size: 32,
                  color: isOwned ? Colors.green : Colors.grey.shade600,
                ),
              ),
              
              SizedBox(height: 12),
              
              // Product title
              Text(
                product.title ?? 'Product',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              SizedBox(height: 4),
              
              // Product description
              Expanded(
                child: Text(
                  product.description ?? '',
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              SizedBox(height: 12),
              
              // Purchase button
              SizedBox(
                width: double.infinity,
                child: _buildPurchaseButton(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildPurchaseButton(BuildContext context) {
    if (isOwned) {
      return ElevatedButton.icon(
        onPressed: null,
        icon: Icon(Icons.check, size: 16),
        label: Text('Owned'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
      );
    }
    
    return ElevatedButton(
      onPressed: onPurchase,
      child: Text(product.localizedPrice ?? 'Buy'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }
  
  IconData _getProductIcon() {
    final productId = product.productId ?? '';
    
    if (productId.contains('coins')) {
      return Icons.monetization_on;
    } else if (productId.contains('energy')) {
      return Icons.battery_charging_full;
    } else if (productId.contains('remove_ads')) {
      return Icons.block;
    } else if (productId.contains('premium')) {
      return Icons.star;
    } else if (productId.contains('themes')) {
      return Icons.palette;
    }
    
    return Icons.shopping_cart;
  }
}
```

### Main App Setup

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => StoreService(),
      child: MaterialApp(
        title: 'Basic Store Example',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: HomeScreen(),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Basic Store Example'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.store,
              size: 100,
              color: Colors.blue,
            ),
            SizedBox(height: 32),
            Text(
              'Welcome to the Store!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            SizedBox(height: 16),
            Text(
              'Purchase coins, remove ads, and unlock premium features.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => StoreScreen(),
                  ),
                );
              },
              icon: Icon(Icons.shopping_cart),
              label: Text('Open Store'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

## Key Features

### 1. State Management
- Uses Provider for reactive state management
- Separates business logic from UI
- Handles loading states and errors

### 2. Product Categories
- Clearly separates consumables and non-consumables
- Different handling for each product type
- Tracks ownership for non-consumables

### 3. Error Handling
- Comprehensive error handling for all scenarios
- User-friendly error messages
- Retry mechanisms

### 4. Purchase Restoration
- Easy restore purchases functionality
- Verifies and restores owned products
- User feedback for restore operations

### 5. UI/UX
- Clean, intuitive interface
- Loading indicators
- Error displays
- Product ownership indication

## Usage

1. **Configure Product IDs**: Update the product ID constants in `StoreService`
2. **Implement Content Delivery**: Add your logic in `_deliverConsumable` and `_deliverNonConsumable`
3. **Add Verification**: Implement proper receipt verification in `_verifyPurchase`
4. **Customize UI**: Modify the UI components to match your app's design
5. **Test**: Test with sandbox accounts on both iOS and Android

## Dependencies

Add these to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_inapp_purchase: ^6.0.0
  provider: ^6.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
```

## Next Steps

- Add server-side receipt validation
- Implement user account integration
- Add analytics tracking
- Enhance error handling
- Add purchase history
- Implement offline support

This basic store implementation provides a solid foundation that you can extend based on your specific needs.