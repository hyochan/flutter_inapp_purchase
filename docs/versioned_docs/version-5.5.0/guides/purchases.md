---
sidebar_position: 3
title: Purchases
---

# Purchases Guide

Complete guide to implementing one-time purchases (consumable and non-consumable) in your Flutter app.

## Overview

One-time purchases include consumable items (like coins or power-ups) and non-consumable items (like premium features or ad removal). This guide covers the complete purchase flow from product loading to transaction completion.

## Purchase Types

### Consumable Products
- Can be purchased multiple times
- Must be "consumed" after use (Android)
- Examples: coins, gems, lives, power-ups

### Non-Consumable Products
- Purchased once and owned permanently
- Examples: premium features, ad removal, unlock levels

## Basic Setup

### 1. Initialize and Setup Listeners

```dart
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

class PurchaseService {
  final _iap = FlutterInappPurchase.instance;
  bool _isInitialized = false;
  
  // Track purchase states
  final Set<String> _ownedProducts = {};
  StreamSubscription? _purchaseSubscription;
  StreamSubscription? _errorSubscription;
  
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await _iap.initConnection();
      _isInitialized = true;
      _setupPurchaseListeners();
      await _loadOwnedProducts();
    } catch (e) {
      print('Failed to initialize IAP: $e');
    }
  }
  
  void _setupPurchaseListeners() {
    _purchaseSubscription = FlutterInappPurchase.purchaseUpdated
        .listen(_handlePurchaseUpdate);
    
    _errorSubscription = FlutterInappPurchase.purchaseError
        .listen(_handlePurchaseError);
  }
  
  Future<void> dispose() async {
    await _purchaseSubscription?.cancel();
    await _errorSubscription?.cancel();
    
    if (_isInitialized) {
      await _iap.endConnection();
    }
  }
}
```

### 2. Load Products

```dart
class ProductLoader {
  final _iap = FlutterInappPurchase.instance;
  
  // Define your product IDs
  static const consumableIds = [
    'com.example.coins_100',
    'com.example.coins_500',
    'com.example.power_pack',
  ];
  
  static const nonConsumableIds = [
    'com.example.remove_ads',
    'com.example.premium_features',
    'com.example.unlock_all',
  ];
  
  List<IAPItem> _consumables = [];
  List<IAPItem> _nonConsumables = [];
  
  Future<void> loadProducts() async {
    try {
      // Load all products
      final allIds = [...consumableIds, ...nonConsumableIds];
      final products = await _iap.requestProducts(skus: allIds, type: 'inapp');
      
      // Separate by type
      _consumables = products.where((p) => 
          consumableIds.contains(p.productId)).toList();
      _nonConsumables = products.where((p) => 
          nonConsumableIds.contains(p.productId)).toList();
      
      print('Loaded ${_consumables.length} consumables, '
            '${_nonConsumables.length} non-consumables');
            
    } catch (e) {
      print('Error loading products: $e');
    }
  }
  
  IAPItem? getProduct(String productId) {
    return [..._consumables, ..._nonConsumables]
        .firstWhere((p) => p.productId == productId, orElse: () => null);
  }
}
```

## Purchase Flow Implementation

### Basic Purchase Method

```dart
class PurchaseManager {
  final _iap = FlutterInappPurchase.instance;
  bool _isPurchasing = false;
  
  Future<void> purchaseProduct(String productId) async {
    // Prevent double purchases
    if (_isPurchasing) {
      print('Purchase already in progress');
      return;
    }
    
    _isPurchasing = true;
    
    try {
      // Check if user already owns non-consumable
      if (_isNonConsumable(productId) && _ownsProduct(productId)) {
        _showMessage('You already own this item');
        return;
      }
      
      // Initiate purchase
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
      print('Purchase failed: $e');
      _handlePurchaseError(e);
    } finally {
      _isPurchasing = false;
    }
  }
  
  bool _isNonConsumable(String productId) {
    return ProductLoader.nonConsumableIds.contains(productId);
  }
  
  bool _ownsProduct(String productId) {
    return _ownedProducts.contains(productId);
  }
}
```

### Handle Purchase Updates

```dart
void _handlePurchaseUpdate(PurchasedItem? item) async {
  if (item == null) return;
  
  print('Purchase update: ${item.productId}');
  
  try {
    // Verify the purchase
    if (!await _verifyPurchase(item)) {
      print('Purchase verification failed');
      return;
    }
    
    // Deliver the content
    await _deliverContent(item);
    
    // Finish the transaction
    await _finishTransaction(item);
    
    // Update UI
    _notifyPurchaseComplete(item.productId!);
    
  } catch (e) {
    print('Error processing purchase: $e');
    // Don't finish transaction if processing failed
  }
}

Future<bool> _verifyPurchase(PurchasedItem item) async {
  // Always verify purchases, preferably server-side
  try {
    if (Platform.isIOS && item.transactionReceipt != null) {
      return await _verifyIOSReceipt(item.transactionReceipt!);
    } else if (Platform.isAndroid && item.purchaseToken != null) {
      return await _verifyAndroidReceipt(item);
    }
    return false;
  } catch (e) {
    print('Verification error: $e');
    return false;
  }
}

Future<void> _deliverContent(PurchasedItem item) async {
  final productId = item.productId!;
  
  if (_isConsumable(productId)) {
    await _deliverConsumable(productId);
  } else {
    await _deliverNonConsumable(productId);
  }
}

Future<void> _deliverConsumable(String productId) async {
  switch (productId) {
    case 'com.example.coins_100':
      await _addCoins(100);
      break;
    case 'com.example.coins_500':
      await _addCoins(500);
      break;
    case 'com.example.power_pack':
      await _addPowerUps();
      break;
  }
}

Future<void> _deliverNonConsumable(String productId) async {
  // Add to owned products
  _ownedProducts.add(productId);
  await _saveOwnedProducts();
  
  switch (productId) {
    case 'com.example.remove_ads':
      await _removeAds();
      break;
    case 'com.example.premium_features':
      await _unlockPremiumFeatures();
      break;
    case 'com.example.unlock_all':
      await _unlockAllContent();
      break;
  }
}

Future<void> _finishTransaction(PurchasedItem item) async {
  await _iap.finishTransactionIOS(
    item,
    isConsumable: _isConsumable(item.productId),
  );
  
  print('Transaction finished: ${item.productId}');
}
```

### Handle Purchase Errors

```dart
void _handlePurchaseError(PurchaseResult? error) {
  if (error == null) return;
  
  print('Purchase error: ${error.message}');
  
  String userMessage;
  bool shouldRetry = false;
  
  switch (error.responseCode) {
    case 1: // User cancelled
      userMessage = 'Purchase cancelled';
      break;
    case 2: // Service unavailable
      userMessage = 'Store service unavailable. Please try again.';
      shouldRetry = true;
      break;
    case 3: // Billing unavailable
      userMessage = 'Billing is not available on this device';
      break;
    case 4: // Item unavailable
      userMessage = 'This item is not available';
      break;
    case 7: // Item already owned
      userMessage = 'You already own this item';
      _handleAlreadyOwned(error);
      break;
    default:
      userMessage = 'Purchase failed. Please try again.';
      shouldRetry = true;
  }
  
  _showErrorDialog(userMessage, shouldRetry);
}

void _handleAlreadyOwned(PurchaseResult error) {
  // For already owned items, try to restore
  _restorePurchases();
}
```

## Product Display UI

### Product Grid Widget

```dart
class ProductGrid extends StatelessWidget {
  final List<IAPItem> products;
  final Function(String) onPurchase;
  final Set<String> ownedProducts;
  
  const ProductGrid({
    Key? key,
    required this.products,
    required this.onPurchase,
    required this.ownedProducts,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        final isOwned = ownedProducts.contains(product.productId);
        
        return ProductCard(
          product: product,
          isOwned: isOwned,
          onPurchase: () => onPurchase(product.productId!),
        );
      },
    );
  }
}
```

### Product Card Widget

```dart
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
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product icon
            Container(
              height: 60,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getProductIcon(),
                size: 32,
                color: Colors.grey.shade600,
              ),
            ),
            
            SizedBox(height: 12),
            
            // Product title
            Text(
              product.title ?? 'Product',
              style: Theme.of(context).textTheme.titleMedium,
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
    );
  }
  
  Widget _buildPurchaseButton(BuildContext context) {
    if (isOwned) {
      return ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check, size: 16),
            SizedBox(width: 4),
            Text('Owned'),
          ],
        ),
      );
    }
    
    return ElevatedButton(
      onPressed: onPurchase,
      child: Text(product.localizedPrice ?? 'Buy'),
    );
  }
  
  IconData _getProductIcon() {
    final productId = product.productId ?? '';
    
    if (productId.contains('coins')) return Icons.monetization_on;
    if (productId.contains('remove_ads')) return Icons.block;
    if (productId.contains('premium')) return Icons.star;
    if (productId.contains('power')) return Icons.flash_on;
    
    return Icons.shopping_cart;
  }
}
```

## Purchase Restoration

### Restore Purchases Method

```dart
class PurchaseRestorer {
  final _iap = FlutterInappPurchase.instance;
  
  Future<void> restorePurchases() async {
    try {
      // Show loading
      _showRestoreDialog();
      
      // Get available purchases
      final purchases = await _iap.getAvailablePurchases();
      
      int restoredCount = 0;
      
      for (var purchase in purchases) {
        // Only restore non-consumables
        if (_isNonConsumable(purchase.productId)) {
          if (!_ownedProducts.contains(purchase.productId)) {
            // Verify and restore
            if (await _verifyPurchase(purchase)) {
              await _deliverNonConsumable(purchase.productId);
              restoredCount++;
            }
          }
        }
      }
      
      _hideRestoreDialog();
      
      if (restoredCount > 0) {
        _showMessage('Restored $restoredCount purchases');
      } else {
        _showMessage('No purchases to restore');
      }
      
    } catch (e) {
      _hideRestoreDialog();
      _showMessage('Failed to restore purchases');
      print('Restore error: $e');
    }
  }
}
```

## Advanced Features

### Purchase Queue Management

```dart
class PurchaseQueue {
  final Queue<String> _pendingPurchases = Queue();
  bool _processing = false;
  
  void addToPurchaseQueue(String productId) {
    _pendingPurchases.add(productId);
    _processPurchaseQueue();
  }
  
  Future<void> _processPurchaseQueue() async {
    if (_processing || _pendingPurchases.isEmpty) return;
    
    _processing = true;
    
    try {
      while (_pendingPurchases.isNotEmpty) {
        final productId = _pendingPurchases.removeFirst();
        await _purchaseProduct(productId);
        
        // Wait between purchases
        await Future.delayed(Duration(seconds: 1));
      }
    } finally {
      _processing = false;
    }
  }
}
```

### Purchase Analytics

```dart
class PurchaseAnalytics {
  static void trackPurchaseAttempt(String productId) {
    // Track purchase attempt
    analytics.logEvent('purchase_attempt', parameters: {
      'product_id': productId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }
  
  static void trackPurchaseSuccess(String productId, String price) {
    // Track successful purchase
    analytics.logEvent('purchase_success', parameters: {
      'product_id': productId,
      'price': price,
      'currency': 'USD', // Get from product
    });
  }
  
  static void trackPurchaseFailure(String productId, String error) {
    // Track purchase failure
    analytics.logEvent('purchase_failure', parameters: {
      'product_id': productId,
      'error': error,
    });
  }
}
```

### Purchase Validation with Backend

```dart
class PurchaseValidator {
  static Future<bool> validateWithServer(PurchasedItem purchase) async {
    try {
      final response = await http.post(
        Uri.parse('${Config.serverUrl}/validate-purchase'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await AuthService.getToken()}',
        },
        body: json.encode({
          'platform': Platform.isIOS ? 'ios' : 'android',
          'productId': purchase.productId,
          'transactionId': purchase.transactionId,
          'receipt': Platform.isIOS 
              ? purchase.transactionReceipt 
              : purchase.dataAndroid,
          'signature': Platform.isAndroid 
              ? purchase.signatureAndroid 
              : null,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['valid'] == true;
      }
      
      return false;
    } catch (e) {
      print('Server validation error: $e');
      return false;
    }
  }
}
```

## Testing Purchases

### Test Environment Setup

```dart
class PurchaseTesting {
  static const testProductIds = [
    'android.test.purchased',
    'android.test.canceled',
    'android.test.refunded',
    'android.test.item_unavailable',
  ];
  
  static bool get isTestMode {
    return kDebugMode || _isTestEnvironment;
  }
  
  static Future<void> setupTestEnvironment() async {
    if (isTestMode) {
      // Use test product IDs
      await _loadTestProducts();
      
      // Mock purchase responses
      _setupMockResponses();
    }
  }
  
  static void simulateSuccessfulPurchase(String productId) {
    if (isTestMode) {
      final mockPurchase = PurchasedItem.fromJSON({
        'productId': productId,
        'transactionId': 'test_${DateTime.now().millisecondsSinceEpoch}',
        'transactionDate': DateTime.now().millisecondsSinceEpoch,
        'transactionReceipt': 'test_receipt_data',
      });
      
      // Trigger purchase updated stream
      FlutterInappPurchase._purchaseController?.add(mockPurchase);
    }
  }
}
```

## Best Practices

1. **Always Verify**: Verify all purchases, preferably server-side
2. **Handle Errors Gracefully**: Provide clear error messages to users
3. **Prevent Double Purchases**: Disable purchase buttons during processing
4. **Store Owned Items**: Persist non-consumable ownership locally
5. **Provide Restore**: Always offer a restore purchases option
6. **Test Thoroughly**: Test all purchase scenarios including failures
7. **Monitor Performance**: Track purchase success rates and errors

## Common Issues and Solutions

### Issue: Purchase Not Recognized
```dart
// Solution: Check and restore purchases on app start
Future<void> checkPendingPurchases() async {
  final purchases = await _iap.getAvailablePurchases();
  
  for (var purchase in purchases) {
    if (_shouldProcessPurchase(purchase)) {
      await _processPurchase(purchase);
    }
  }
}
```

### Issue: Duplicate Purchases
```dart
// Solution: Track transaction IDs
final Set<String> _processedTransactions = {};

bool _isTransactionProcessed(String? transactionId) {
  return transactionId != null && 
         _processedTransactions.contains(transactionId);
}

void _markTransactionProcessed(String transactionId) {
  _processedTransactions.add(transactionId);
}
```

## Related Documentation

- [Subscriptions Guide](./subscriptions.md) - Subscription purchases
- [Receipt Validation](./receipt-validation.md) - Validating purchases
- [Error Handling](./error-handling.md) - Handling purchase errors
- [API Reference](../api/methods/request-purchase.md) - Purchase API methods