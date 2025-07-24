---
title: useIAP Hook
sidebar_position: 4
---

# useIAP Hook

flutter_inapp_purchase provides multiple approaches for state management: a React-style hook using Flutter Hooks, a custom InheritedWidget provider, and direct stream usage.

## useIAP Hook

### Basic Setup

The `useIAP` hook provides a React-style interface for managing in-app purchases with automatic state management.

**Requirements**: Add `flutter_hooks` to your `pubspec.yaml`

```yaml
dependencies:
  flutter_hooks: ^0.20.0
  flutter_inapp_purchase: ^6.0.0
```

### Basic Usage

```dart
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

class PurchaseScreen extends HookWidget {
  @override
  Widget build(BuildContext context) {
    // Initialize useIAP hook
    final iap = useIAP(UseIAPOptions(
      onPurchaseSuccess: (purchase) {
        print('✅ Purchase successful: ${purchase.productId}');
        // Handle purchase success
        _deliverProduct(purchase.productId);
      },
      onPurchaseError: (error) {
        print('❌ Purchase failed: ${error.message}');
        // Handle purchase error
        _showErrorDialog(error.message);
      },
      onSyncError: (error) {
        print('🔄 Sync error: $error');
      },
      shouldAutoSyncPurchases: true,
    ));

    // Load products when connected
    useEffect(() {
      if (iap.connected) {
        iap.getProducts(['product_1', 'product_2', 'premium_upgrade']);
      }
      return null;
    }, [iap.connected]);

    return Scaffold(
      appBar: AppBar(
        title: Text('Products'),
        backgroundColor: iap.connected ? Colors.green : Colors.red,
      ),
      body: _buildBody(iap),
    );
  }

  Widget _buildBody(UseIAPReturn iap) {
    return Column(
      children: [
        // Connection Status
        _buildConnectionStatus(iap.connected),
        
        // Products List
        Expanded(
          child: ListView.builder(
            itemCount: iap.products.length,
            itemBuilder: (context, index) {
              final product = iap.products[index];
              return ProductCard(
                product: product,
                onPurchase: () => _purchaseProduct(iap, product),
              );
            },
          ),
        ),
        
        // Current Purchase Status
        if (iap.currentPurchase != null)
          _buildPurchaseSuccess(iap),
        
        // Error Display
        if (iap.currentPurchaseError != null)
          _buildPurchaseError(iap),
      ],
    );
  }

  Future<void> _purchaseProduct(UseIAPReturn iap, Product product) async {
    final request = RequestPurchase(
      ios: RequestPurchaseIOS(sku: product.id, quantity: 1),
      android: RequestPurchaseAndroid(skus: [product.id]),
    );
    
    await iap.requestPurchase(
      request: request,
      type: PurchaseType.inapp,
    );
  }
}
```

### Advanced Features

```dart
class AdvancedPurchaseScreen extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final iap = useIAP();

    // Custom callbacks for specific actions
    final loadProducts = useCallback(() async {
      await iap.requestProducts(
        skus: ['coins_100', 'coins_500', 'remove_ads'],
        type: PurchaseType.inapp,
      );
    }, []);

    final loadSubscriptions = useCallback(() async {
      await iap.getSubscriptions(['premium_monthly', 'premium_yearly']);
    }, []);

    final handleRestore = useCallback(() async {
      try {
        await iap.restorePurchases();
        
        // Check restored purchases
        if (iap.availablePurchases.isNotEmpty) {
          _showRestoredPurchases(iap.availablePurchases);
        } else {
          _showMessage('No purchases to restore');
        }
      } catch (e) {
        _showMessage('Restore failed: $e');
      }
    }, []);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: Text('Advanced IAP'),
            actions: [
              IconButton(
                icon: Icon(Icons.refresh),
                onPressed: loadProducts,
              ),
              IconButton(
                icon: Icon(Icons.restore),
                onPressed: handleRestore,
              ),
            ],
          ),
          
          // Connection Status
          SliverToBoxAdapter(
            child: ConnectionBanner(connected: iap.connected),
          ),
          
          // Products Section
          if (iap.products.isNotEmpty)
            SliverToBoxAdapter(
              child: ProductSection(
                title: 'Products',
                items: iap.products,
                onPurchase: (product) async {
                  final request = RequestPurchase(
                    ios: RequestPurchaseIOS(sku: product.id),
                    android: RequestPurchaseAndroid(skus: [product.id]),
                  );
                  await iap.requestPurchase(
                    request: request, 
                    type: PurchaseType.inapp,
                  );
                },
              ),
            ),
          
          // Subscriptions Section
          if (iap.subscriptions.isNotEmpty)
            SliverToBoxAdapter(
              child: SubscriptionSection(
                title: 'Subscriptions',
                items: iap.subscriptions,
                onSubscribe: (subscription) async {
                  final request = RequestPurchase(
                    ios: RequestPurchaseIOS(sku: subscription.id),
                    android: RequestPurchaseAndroid(skus: [subscription.id]),
                  );
                  await iap.requestPurchase(
                    request: request,
                    type: PurchaseType.subs,
                  );
                },
              ),
            ),
          
          // Purchase History
          if (iap.purchaseHistories.isNotEmpty)
            SliverToBoxAdapter(
              child: PurchaseHistorySection(
                histories: iap.purchaseHistories,
                onFinish: (purchase) async {
                  await iap.finishTransaction(
                    purchase: purchase,
                    isConsumable: true,
                  );
                },
              ),
            ),
          
          // Action Buttons
          SliverToBoxAdapter(
            child: ActionButtonsSection(
              onLoadProducts: loadProducts,
              onLoadSubscriptions: loadSubscriptions,
              onRestore: handleRestore,
            ),
          ),
        ],
      ),
    );
  }
}
```

### UseIAPOptions Configuration

```dart
class UseIAPOptions {
  final void Function(Purchase purchase)? onPurchaseSuccess;
  final void Function(PurchaseError error)? onPurchaseError;
  final void Function(Object error)? onSyncError;
  final bool shouldAutoSyncPurchases;

  const UseIAPOptions({
    this.onPurchaseSuccess,
    this.onPurchaseError,
    this.onSyncError,
    this.shouldAutoSyncPurchases = true,
  });
}
```

**Configuration Options**:
- `onPurchaseSuccess` - Called when purchase completes successfully
- `onPurchaseError` - Called when purchase fails
- `onSyncError` - Called when synchronization fails
- `shouldAutoSyncPurchases` - Automatically sync purchases (default: true)

### UseIAPReturn Properties

```dart
class UseIAPReturn {
  // State
  final bool connected;                              // Connection status
  final List<Product> products;                      // Available products
  final List<Subscription> subscriptions;           // Available subscriptions
  final List<Purchase> purchaseHistories;           // Purchase history
  final List<Purchase> availablePurchases;          // Available purchases
  final Purchase? currentPurchase;                   // Current purchase
  final PurchaseError? currentPurchaseError;        // Current error
  
  // Actions
  final void Function() clearCurrentPurchase;
  final void Function() clearCurrentPurchaseError;
  final Future<void> Function(List<String> skus) getProducts;
  final Future<void> Function(List<String> skus) getSubscriptions;
  final Future<void> Function({
    required RequestPurchase request,
    PurchaseType type,
  }) requestPurchase;
  final Future<void> Function({
    required Purchase purchase,
    bool isConsumable,
  }) finishTransaction;
  final Future<void> Function() restorePurchases;
}
```

## Custom Provider (InheritedWidget)

### Provider Setup

```dart
// main.dart
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: IapProviderWidget(  // Wrap with provider
        child: HomeScreen(),
      ),
    );
  }
}
```

### Provider Usage

```dart
class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final iap = IapProvider.of(context);  // Access provider
    
    if (iap == null) {
      return Scaffold(
        body: Center(child: Text('IAP Provider not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Custom Provider IAP'),
        backgroundColor: iap.connected ? Colors.green : Colors.orange,
        actions: [
          // Connection indicator
          Icon(
            iap.connected ? Icons.cloud_done : Icons.cloud_off,
            color: Colors.white,
          ),
          SizedBox(width: 16),
        ],
      ),
      body: iap.loading
        ? Center(child: CircularProgressIndicator())
        : _buildContent(iap),
    );
  }

  Widget _buildContent(IapProvider iap) {
    return Column(
      children: [
        // Error Banner
        if (iap.error != null)
          Material(
            color: Colors.red[100],
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.error, color: Colors.red[800]),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Error: ${iap.error}',
                      style: TextStyle(color: Colors.red[800]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        
        // Action Buttons
        Padding(
          padding: EdgeInsets.all(16),
          child: Wrap(
            spacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: () => _loadProducts(iap),
                icon: Icon(Icons.shopping_cart),
                label: Text('Load Products'),
              ),
              ElevatedButton.icon(
                onPressed: () => _loadSubscriptions(iap),
                icon: Icon(Icons.subscriptions),
                label: Text('Load Subscriptions'),
              ),
              ElevatedButton.icon(
                onPressed: iap.restorePurchases,
                icon: Icon(Icons.restore),
                label: Text('Restore'),
              ),
              if (Platform.isIOS) ...[
                ElevatedButton.icon(
                  onPressed: iap.presentCodeRedemption,
                  icon: Icon(Icons.redeem),
                  label: Text('Redeem Code'),
                ),
                ElevatedButton.icon(
                  onPressed: iap.showManageSubscriptions,
                  icon: Icon(Icons.manage_accounts),
                  label: Text('Manage'),
                ),
              ],
            ],
          ),
        ),
        
        // Content Tabs
        Expanded(
          child: DefaultTabController(
            length: 3,
            child: Column(
              children: [
                TabBar(
                  labelColor: Theme.of(context).primaryColor,
                  tabs: [
                    Tab(icon: Icon(Icons.shopping_bag), text: 'Products'),
                    Tab(icon: Icon(Icons.subscriptions), text: 'Subscriptions'),
                    Tab(icon: Icon(Icons.history), text: 'Purchases'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildProductsTab(iap),
                      _buildSubscriptionsTab(iap),
                      _buildPurchasesTab(iap),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductsTab(IapProvider iap) {
    if (iap.products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No products loaded'),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _loadProducts(iap),
              child: Text('Load Products'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: iap.products.length,
      itemBuilder: (context, index) {
        final product = iap.products[index];
        return ProductCard(
          product: product,
          onPurchase: () => iap.requestPurchase(product.productId!),
        );
      },
    );
  }

  Widget _buildSubscriptionsTab(IapProvider iap) {
    if (iap.subscriptions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.subscriptions_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No subscriptions loaded'),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _loadSubscriptions(iap),
              child: Text('Load Subscriptions'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: iap.subscriptions.length,
      itemBuilder: (context, index) {
        final subscription = iap.subscriptions[index];
        return SubscriptionCard(
          subscription: subscription,
          onSubscribe: () => iap.requestSubscription(subscription.productId!),
        );
      },
    );
  }

  Widget _buildPurchasesTab(IapProvider iap) {
    if (iap.availableItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No available purchases'),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: iap.getAvailableItems,
              child: Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: iap.availableItems.length,
      itemBuilder: (context, index) {
        final purchase = iap.availableItems[index];
        return PurchaseCard(
          purchase: purchase,
          onFinish: () => iap.finishTransaction(purchase, isConsumable: true),
        );
      },
    );
  }

  Future<void> _loadProducts(IapProvider iap) async {
    final productIds = [
      'dev.hyo.martie.10bulbs',
      'dev.hyo.martie.30bulbs',
      'premium_upgrade',
      'remove_ads',
    ];
    
    try {
      await iap.getProducts(productIds);
    } catch (e) {
      _showError('Failed to load products: $e');
    }
  }

  Future<void> _loadSubscriptions(IapProvider iap) async {
    final subscriptionIds = [
      'premium_monthly',
      'premium_yearly',
      'premium_lifetime',
    ];
    
    try {
      await iap.getSubscriptions(subscriptionIds);
    } catch (e) {
      _showError('Failed to load subscriptions: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
```

### Custom Widget Components

```dart
// Product Card Widget
class ProductCard extends StatelessWidget {
  final IAPItem product;
  final VoidCallback onPurchase;

  const ProductCard({
    required this.product,
    required this.onPurchase,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.shopping_bag,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.title ?? product.productId ?? 'Unknown Product',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (product.description != null && product.description!.isNotEmpty)
                        Text(
                          product.description!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
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
                  product.localizedPrice ?? product.price ?? 'Unknown Price',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton(
                  onPressed: onPurchase,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: Text('Buy Now'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Subscription Card Widget
class SubscriptionCard extends StatelessWidget {
  final IAPItem subscription;
  final VoidCallback onSubscribe;

  const SubscriptionCard({
    required this.subscription,
    required this.onSubscribe,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.subscriptions, color: Colors.orange),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subscription.title ?? subscription.productId ?? 'Unknown Subscription',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (subscription.description != null)
                        Text(
                          subscription.description!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            
            // Subscription Details
            if (subscription.subscriptionPeriodAndroid != null ||
                subscription.subscriptionPeriodUnitIOS != null)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Period: ${subscription.subscriptionPeriodAndroid ?? subscription.subscriptionPeriodUnitIOS}',
                  style: TextStyle(
                    color: Colors.blue[800],
                    fontSize: 12,
                  ),
                ),
              ),
            
            if (subscription.introductoryPrice != null)
              Container(
                margin: EdgeInsets.only(top: 4),
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Intro: ${subscription.introductoryPrice}',
                  style: TextStyle(
                    color: Colors.green[800],
                    fontSize: 12,
                  ),
                ),
              ),
            
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  subscription.localizedPrice ?? subscription.price ?? 'Unknown Price',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton(
                  onPressed: onSubscribe,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: Text('Subscribe'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Purchase Card Widget
class PurchaseCard extends StatelessWidget {
  final PurchasedItem purchase;
  final VoidCallback onFinish;

  const PurchaseCard({
    required this.purchase,
    required this.onFinish,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.receipt, color: Colors.green),
        ),
        title: Text(purchase.productId ?? 'Unknown Purchase'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Transaction: ${purchase.transactionId ?? 'N/A'}'),
            Text(
              'Date: ${purchase.transactionDate?.toLocal().toString().split('.')[0] ?? 'Unknown'}',
            ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: onFinish,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
          ),
          child: Text('Finish'),
        ),
      ),
    );
  }
}
```

## Direct Stream Usage

For maximum control, you can use the streams directly:

```dart
class DirectStreamExample extends StatefulWidget {
  @override
  _DirectStreamExampleState createState() => _DirectStreamExampleState();
}

class _DirectStreamExampleState extends State<DirectStreamExample> {
  StreamSubscription<PurchasedItem?>? _purchaseSubscription;
  StreamSubscription<PurchaseResult?>? _errorSubscription;
  StreamSubscription<ConnectionResult>? _connectionSubscription;
  
  final FlutterInappPurchase _iap = FlutterInappPurchase.instance;
  bool _connected = false;
  List<IAPItem> _products = [];
  PurchasedItem? _currentPurchase;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeIAP();
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    _errorSubscription?.cancel();
    _connectionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeIAP() async {
    try {
      // Initialize connection
      await _iap.initConnection();
      
      // Set up listeners
      _setupListeners();
      
      // Load products
      await _loadProducts();
      
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize IAP: $e';
      });
    }
  }

  void _setupListeners() {
    // Purchase success listener
    _purchaseSubscription = FlutterInappPurchase.purchaseUpdated.listen(
      (purchase) {
        if (purchase != null) {
          setState(() {
            _currentPurchase = purchase;
            _errorMessage = null;
          });
          
          // Auto-finish transaction for demo
          _finishTransaction(purchase);
        }
      },
      onError: (error) {
        setState(() {
          _errorMessage = 'Purchase stream error: $error';
        });
      },
    );
    
    // Purchase error listener
    _errorSubscription = FlutterInappPurchase.purchaseError.listen(
      (error) {
        if (error != null) {
          setState(() {
            _errorMessage = error.message;
            _currentPurchase = null;
          });
        }
      },
    );
    
    // Connection state listener
    _connectionSubscription = FlutterInappPurchase.connectionUpdated.listen(
      (connectionResult) {
        setState(() {
          _connected = connectionResult.connected;
        });
        
        if (connectionResult.connected) {
          print('✅ Store connected');
        } else {
          print('❌ Store disconnected: ${connectionResult.message}');
        }
      },
    );
  }

  Future<void> _loadProducts() async {
    try {
      final products = await _iap.getProducts([
        'dev.hyo.martie.10bulbs',
        'dev.hyo.martie.30bulbs',
      ]);
      
      setState(() {
        _products = products;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load products: $e';
      });
    }
  }

  Future<void> _makePurchase(String productId) async {
    try {
      setState(() {
        _errorMessage = null;
      });
      
      final request = RequestPurchase(
        ios: RequestPurchaseIOS(sku: productId, quantity: 1),
        android: RequestPurchaseAndroid(skus: [productId]),
      );
      
      await _iap.requestPurchase(
        request: request,
        type: PurchaseType.inapp,
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Purchase failed: $e';
      });
    }
  }

  Future<void> _finishTransaction(PurchasedItem purchase) async {
    try {
      await _iap.finishTransactionIOS(purchase, isConsumable: true);
      
      setState(() {
        _currentPurchase = null;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Purchase completed: ${purchase.productId}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to finish transaction: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Direct Stream IAP'),
        backgroundColor: _connected ? Colors.green : Colors.red,
      ),
      body: Column(
        children: [
          // Status indicators
          _buildStatusSection(),
          
          // Products
          Expanded(
            child: _buildProductsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection() {
    return Container(
      width: double.infinity,
      child: Column(
        children: [
          // Connection status
          Container(
            padding: EdgeInsets.all(16),
            color: _connected ? Colors.green[100] : Colors.red[100],
            child: Row(
              children: [
                Icon(
                  _connected ? Icons.wifi : Icons.wifi_off,
                  color: _connected ? Colors.green[800] : Colors.red[800],
                ),
                SizedBox(width: 8),
                Text(
                  _connected ? 'Connected to Store' : 'Not Connected',
                  style: TextStyle(
                    color: _connected ? Colors.green[800] : Colors.red[800],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          // Error message
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              color: Colors.orange[100],
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange[800]),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.orange[800]),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _errorMessage = null),
                    icon: Icon(Icons.close, color: Colors.orange[800]),
                  ),
                ],
              ),
            ),
          
          // Current purchase
          if (_currentPurchase != null)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              color: Colors.blue[100],
              child: Column(
                children: [
                  Text(
                    '🎉 Purchase Successful: ${_currentPurchase!.productId}',
                    style: TextStyle(
                      color: Colors.blue[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _finishTransaction(_currentPurchase!),
                    child: Text('Finish Transaction'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProductsList() {
    if (_products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No products available'),
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
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        return Card(
          margin: EdgeInsets.all(8),
          child: ListTile(
            leading: Icon(Icons.shopping_bag),
            title: Text(product.title ?? product.productId ?? 'Unknown'),
            subtitle: Text(product.description ?? ''),
            trailing: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  product.localizedPrice ?? '',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                ElevatedButton(
                  onPressed: () => _makePurchase(product.productId!),
                  child: Text('Buy'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
```

## Choosing the Right Approach

### useIAP Hook
**Best for:**
- ✅ Flutter Hooks users
- ✅ Functional components
- ✅ Simple implementations
- ✅ Automatic state management

### Custom Provider
**Best for:**
- ✅ App-wide IAP state sharing
- ✅ InheritedWidget pattern preference
- ✅ Complex business logic
- ✅ Custom state management needs

### Direct Streams
**Best for:**
- ✅ Maximum control
- ✅ Custom state management integration
- ✅ Performance optimization
- ✅ Advanced error handling

## Migration Examples

### From Direct Streams to useIAP

```dart
// Before: Direct streams
class OldPurchaseScreen extends StatefulWidget {
  // ... lots of boilerplate
}

// After: useIAP hook
class NewPurchaseScreen extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final iap = useIAP(UseIAPOptions(
      onPurchaseSuccess: (purchase) => _handleSuccess(purchase),
      onPurchaseError: (error) => _handleError(error),
    ));
    
    return Scaffold(
      body: PurchaseView(iap: iap),
    );
  }
}
```

### From Provider to useIAP

```dart
// Before: Provider access
final iap = IapProvider.of(context);
await iap.requestPurchase(productId);

// After: Hook usage
final iap = useIAP();
await iap.requestPurchase(
  request: RequestPurchase(
    ios: RequestPurchaseIOS(sku: productId),
    android: RequestPurchaseAndroid(skus: [productId]),
  ),
  type: PurchaseType.inapp,
);
```

## Best Practices

1. **Choose One Approach**: Don't mix multiple state management approaches
2. **Handle Errors**: Always implement error handling
3. **Clean Up**: Cancel subscriptions in dispose methods
4. **Loading States**: Show loading indicators during operations
5. **User Feedback**: Provide clear feedback for purchase states
6. **Platform Differences**: Handle iOS/Android differences appropriately

## See Also

- [Core Methods](./core-methods.md) - Underlying IAP methods
- [Listeners](./listeners.md) - Stream event details
- [Types](./types.md) - Data structure definitions
- [Error Codes](./error-codes.md) - Error handling reference