---
sidebar_position: 3
title: Complete Implementation
---

# Complete Production-Ready Implementation

A comprehensive, production-ready implementation with all best practices for a robust in-app purchase system.

## Architecture Overview

This implementation includes:

- State management with provider
- Server-side receipt validation
- Offline support with local caching
- Comprehensive error handling
- Analytics tracking
- Security best practices

## Complete Store Implementation

### 1. IAP Service

```dart
// services/iap_service.dart
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class IAPService {
  static final IAPService _instance = IAPService._internal();
  factory IAPService() => _instance;
  IAPService._internal();

  StreamSubscription? _purchaseUpdatedSubscription;
  StreamSubscription? _purchaseErrorSubscription;

  final StreamController<PurchaseUpdate> _purchaseController =
      StreamController.broadcast();

  Stream<PurchaseUpdate> get purchaseStream => _purchaseController.stream;

  Future<bool> initialize() async {
    try {
      final result = await FlutterInappPurchase.instance.initConnection();

      _purchaseUpdatedSubscription = FlutterInappPurchase.instance
          .purchaseUpdated.listen(_handlePurchaseUpdate);

      _purchaseErrorSubscription = FlutterInappPurchase.instance
          .purchaseError.listen(_handlePurchaseError);

      return result;
    } catch (e) {
      print('IAP initialization failed: $e');
      return false;
    }
  }

  void _handlePurchaseUpdate(Purchase? item) async {
    if (item == null) return;

    try {
      // Validate receipt server-side
      final validationResult = await _validatePurchase(item);

      if (validationResult.isValid) {
        // Deliver content
        await _deliverPurchase(item, validationResult);

        // Complete transaction
        await _completeTransaction(item);

        _purchaseController.add(PurchaseUpdate(
          item: item,
          status: PurchaseStatus.success,
          validationResult: validationResult,
        ));
      } else {
        _purchaseController.add(PurchaseUpdate(
          item: item,
          status: PurchaseStatus.validationFailed,
          error: 'Receipt validation failed',
        ));
      }
    } catch (e) {
      _purchaseController.add(PurchaseUpdate(
        item: item,
        status: PurchaseStatus.error,
        error: e.toString(),
      ));
    }
  }

  void _handlePurchaseError(Purchase? item) {
    _purchaseController.add(PurchaseUpdate(
      item: item,
      status: PurchaseStatus.error,
      error: 'Purchase failed',
    ));
  }

  Future<List<ProductCommon>> fetchInAppProducts(List<String> productIds) async {
    try {
      final result = await FlutterInappPurchase.instance.fetchProducts(
        ProductRequest(
          skus: productIds,
          type: ProductQueryType.InApp,
        ),
      );
      return result.value;
    } catch (e) {
      print('Failed to get products: $e');
      return [];
    }
  }

  Future<List<ProductCommon>> fetchSubscriptionProducts(List<String> subscriptionIds) async {
    try {
      final result = await FlutterInappPurchase.instance.fetchProducts(
        ProductRequest(
          skus: subscriptionIds,
          type: ProductQueryType.Subs,
        ),
      );
      return result.value;
    } catch (e) {
      print('Failed to get subscriptions: $e');
      return [];
    }
  }

  Future<void> requestPurchase(String productId) async {
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
  }

  Future<List<Purchase>> getAvailablePurchases() async {
    try {
      final purchases = await FlutterInappPurchase.instance
          .getAvailablePurchases();
      return purchases ?? [];
    } catch (e) {
      print('Failed to get available purchases: $e');
      return [];
    }
  }

  Future<ValidationResult> _validatePurchase(Purchase item) async {
    try {
      String? receipt;

      if (Platform.isIOS) {
        receipt = await FlutterInappPurchase.instance.getReceiptData();
      } else {
        receipt = item.purchaseToken;
      }

      final response = await http.post(
        Uri.parse('${Config.baseUrl}/validate-purchase'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await AuthService().getToken()}',
        },
        body: jsonEncode({
          'platform': Platform.isIOS ? 'ios' : 'android',
          'productId': item.productId,
          'transactionId': item.transactionId,
          'receipt': receipt,
          'userId': await UserService().getCurrentUserId(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ValidationResult.fromJson(data);
      } else {
        return ValidationResult.invalid('Server validation failed');
      }
    } catch (e) {
      return ValidationResult.invalid(e.toString());
    }
  }

  Future<void> _deliverPurchase(
    Purchase item,
    ValidationResult validationResult
  ) async {
    // Update local storage
    await LocalStorage().savePurchase(item);

    // Track analytics
    AnalyticsService().trackPurchase(item);

    // Grant content/features
    await ContentService().grantAccess(
      item.productId!,
      validationResult.purchaseData
    );
  }

  Future<void> _completeTransaction(Purchase item) async {
    if (Platform.isIOS) {
      await FlutterInappPurchase.instance.finishTransaction(
        purchase: item,
        isConsumable: ProductConfig.isConsumable(item.productId!),
      );
    } else if (Platform.isAndroid) {
      final isConsumable = ProductConfig.isConsumable(item.productId!);

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
  }

  void dispose() {
    _purchaseUpdatedSubscription?.cancel();
    _purchaseErrorSubscription?.cancel();
    _purchaseController.close();
  }
}

// Data models
class PurchaseUpdate {
  final Purchase? item;
  final PurchaseStatus status;
  final String? error;
  final ValidationResult? validationResult;

  PurchaseUpdate({
    this.item,
    required this.status,
    this.error,
    this.validationResult,
  });
}

enum PurchaseStatus {
  success,
  error,
  validationFailed,
  cancelled,
}

class ValidationResult {
  final bool isValid;
  final String? error;
  final Map<String, dynamic>? purchaseData;

  ValidationResult.valid(this.purchaseData)
    : isValid = true, error = null;

  ValidationResult.invalid(this.error)
    : isValid = false, purchaseData = null;

  factory ValidationResult.fromJson(Map<String, dynamic> json) {
    return ValidationResult.valid(json['purchaseData']);
  }
}
```

### 2. Store Provider

```dart
// providers/store_provider.dart
import 'package:flutter/foundation.dart';
import '../services/iap_service.dart';

class StoreProvider extends ChangeNotifier {
  final IAPService _iapService = IAPService();

  List<ProductCommon> _products = [];
  List<ProductCommon> _subscriptions = [];
  List<Purchase> _purchases = [];

  bool _isInitialized = false;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<ProductCommon> get products => _products;
  List<ProductCommon> get subscriptions => _subscriptions;
  List<Purchase> get purchases => _purchases;
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> initialize() async {
    _setLoading(true);

    try {
      _isInitialized = await _iapService.initialize();

      if (_isInitialized) {
        // Listen to purchase updates
        _iapService.purchaseStream.listen(_handlePurchaseUpdate);

        // Load initial data
        await loadProducts();
        await loadPurchases();
      }

      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadProducts() async {
    try {
      final productIds = ProductConfig.getAllProductIds();
      final subscriptionIds = ProductConfig.getAllSubscriptionIds();

      final results = await Future.wait([
        _iapService.fetchInAppProducts(productIds),
        _iapService.fetchSubscriptionProducts(subscriptionIds),
      ]);

      _products = results[0];
      _subscriptions = results[1];

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadPurchases() async {
    try {
      _purchases = await _iapService.getAvailablePurchases();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> purchaseProduct(String productId) async {
    try {
      _error = null;
      await _iapService.requestPurchase(productId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> purchaseSubscription(String productId) async {
    try {
      _error = null;
      await _iapService.requestPurchase(productId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  bool isPurchased(String productId) {
    return _purchases.any((p) => p.productId == productId);
  }

  bool isSubscriptionActive(String productId) {
    final purchase = _purchases.firstWhere(
      (p) => p.productId == productId,
      orElse: () => Purchase(
        productId: '',
        platform: IapPlatform.ios,
      ),
    );

    // Check if subscription is still valid
    // You'd implement expiration checking here
    return purchase.productId != null;
  }

  void _handlePurchaseUpdate(PurchaseUpdate update) {
    switch (update.status) {
      case PurchaseStatus.success:
        loadPurchases(); // Refresh purchases
        break;
      case PurchaseStatus.error:
      case PurchaseStatus.validationFailed:
        _error = update.error;
        notifyListeners();
        break;
      case PurchaseStatus.cancelled:
        // Handle cancellation
        break;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  @override
  void dispose() {
    _iapService.dispose();
    super.dispose();
  }
}
```

### 3. Store UI

```dart
// screens/store_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/store_provider.dart';

class StoreScreen extends StatefulWidget {
  @override
  _StoreScreenState createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen>
    with SingleTickerProviderStateMixin {

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Initialize store if not already done
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final store = Provider.of<StoreProvider>(context, listen: false);
      if (!store.isInitialized) {
        store.initialize();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Store'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Products'),
            Tab(text: 'Subscriptions'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.restore),
            onPressed: _restorePurchases,
          ),
        ],
      ),
      body: Consumer<StoreProvider>(
        builder: (context, store, child) {
          if (!store.isInitialized) {
            return _buildInitializingView();
          }

          if (store.isLoading) {
            return _buildLoadingView();
          }

          if (store.error != null) {
            return _buildErrorView(store.error!, store);
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildProductsTab(store),
              _buildSubscriptionsTab(store),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInitializingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Initializing store...'),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(child: CircularProgressIndicator());
  }

  Widget _buildErrorView(String error, StoreProvider store) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red),
          SizedBox(height: 16),
          Text(
            'Store Error',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => store.initialize(),
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsTab(StoreProvider store) {
    if (store.products.isEmpty) {
      return Center(child: Text('No products available'));
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: store.products.length,
      itemBuilder: (context, index) {
        final product = store.products[index];
        final isPurchased = store.isPurchased(product.productId!);

        return Card(
          child: ListTile(
            title: Text(product.title ?? product.productId!),
            subtitle: Text(product.description ?? ''),
            trailing: isPurchased
                ? Chip(
                    label: Text('OWNED'),
                    backgroundColor: Colors.green,
                    labelStyle: TextStyle(color: Colors.white),
                  )
                : ElevatedButton(
                    onPressed: () => store.purchaseProduct(product.productId!),
                    child: Text(product.localizedPrice ?? 'Buy'),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildSubscriptionsTab(StoreProvider store) {
    if (store.subscriptions.isEmpty) {
      return Center(child: Text('No subscriptions available'));
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: store.subscriptions.length,
      itemBuilder: (context, index) {
        final subscription = store.subscriptions[index];
        final isActive = store.isSubscriptionActive(subscription.productId!);

        return Card(
          child: ListTile(
            title: Text(subscription.title ?? subscription.productId!),
            subtitle: Text(subscription.description ?? ''),
            trailing: isActive
                ? Chip(
                    label: Text('ACTIVE'),
                    backgroundColor: Colors.blue,
                    labelStyle: TextStyle(color: Colors.white),
                  )
                : ElevatedButton(
                    onPressed: () => store.purchaseSubscription(
                      subscription.productId!
                    ),
                    child: Text(subscription.localizedPrice ?? 'Subscribe'),
                  ),
          ),
        );
      },
    );
  }

  void _restorePurchases() async {
    final store = Provider.of<StoreProvider>(context, listen: false);
    await store.loadPurchases();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Purchases restored')),
    );
  }
}
```

### 4. Configuration & Security

```dart
// config/product_config.dart
class ProductConfig {
  static const Map<String, ProductInfo> _products = {
    'coins_100': ProductInfo(type: ProductType.consumable, value: 100),
    'coins_500': ProductInfo(type: ProductType.consumable, value: 500),
    'remove_ads': ProductInfo(type: ProductType.nonConsumable),
    'premium_monthly': ProductInfo(type: ProductType.subscription),
    'premium_yearly': ProductInfo(type: ProductType.subscription),
  };

  static List<String> getAllProductIds() {
    return _products.entries
        .where((e) => e.value.type != ProductType.subscription)
        .map((e) => e.key)
        .toList();
  }

  static List<String> getAllSubscriptionIds() {
    return _products.entries
        .where((e) => e.value.type == ProductType.subscription)
        .map((e) => e.key)
        .toList();
  }

  static bool isConsumable(String productId) {
    return _products[productId]?.type == ProductType.consumable;
  }

  static ProductInfo? getProductInfo(String productId) {
    return _products[productId];
  }
}

class ProductInfo {
  final ProductType type;
  final int? value;

  const ProductInfo({
    required this.type,
    this.value,
  });
}

enum ProductType { consumable, nonConsumable, subscription }
```

## Security Best Practices

1. **Server-Side Validation**: All receipts validated on secure backend
2. **User Authentication**: Purchases tied to authenticated user accounts
3. **Secure Storage**: Purchase data encrypted locally
4. **Network Security**: HTTPS only, certificate pinning
5. **Obfuscation**: Sensitive code obfuscated in production builds

## Production Considerations

- Implement proper logging and crash reporting
- Add comprehensive analytics tracking
- Handle network failures gracefully
- Implement offline mode with sync
- Add proper loading states throughout
- Test thoroughly with different devices and conditions

This implementation provides a robust foundation for production apps with complex IAP requirements.
