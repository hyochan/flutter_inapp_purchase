import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

class StoreKit2Demo extends StatefulWidget {
  const StoreKit2Demo({Key? key}) : super(key: key);

  @override
  _StoreKit2DemoState createState() => _StoreKit2DemoState();
}

class _StoreKit2DemoState extends State<StoreKit2Demo> {
  final FlutterInappPurchase _iap = FlutterInappPurchase();
  StreamSubscription<Purchase?>? _purchaseUpdatedSubscription;
  StreamSubscription<PurchaseError>? _purchaseErrorSubscription;

  bool _connected = false;
  bool _loading = false;
  String? _error;
  List<ProductCommon> _products = [];
  List<Purchase> _purchases = [];

  // Test product IDs
  final List<String> _productIds = [
    'dev.hyo.martie.10bulbs',
    'dev.hyo.martie.30bulbs',
  ];

  @override
  void initState() {
    super.initState();
    _initializeStore();
  }

  @override
  void dispose() {
    _purchaseUpdatedSubscription?.cancel();
    _purchaseErrorSubscription?.cancel();
    _iap.finalize();
    super.dispose();
  }

  Future<void> _initializeStore() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Initialize connection
      await _iap.initConnection();

      // Set up purchase listeners
      _purchaseUpdatedSubscription =
          _iap.purchaseUpdatedListener.listen((purchase) {
        _handlePurchaseUpdate(purchase);
      });

      _purchaseErrorSubscription = _iap.purchaseErrorListener.listen((error) {
        setState(() {
          _error = error.message;
          _loading = false;
        });
      });

      // Get products
      await _getProducts();

      // Get available purchases
      await _getAvailablePurchases();

      setState(() {
        _connected = true;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
        _connected = false;
      });
    }
  }

  Future<void> _getProducts() async {
    try {
      final products = await _iap.requestProducts<Product>(
        skus: _productIds,
        type: ProductType.inapp,
      );
      setState(() {
        _products = products;
      });
    } catch (e) {
      print('Error getting products: $e');
    }
  }

  Future<void> _getAvailablePurchases() async {
    try {
      final purchases = await _iap.getAvailablePurchases();
      setState(() {
        _purchases = purchases;
      });
    } catch (e) {
      print('Error getting purchases: $e');
    }
  }

  Future<void> _handlePurchaseUpdate(Purchase purchase) async {
    setState(() {
      _loading = true;
    });

    try {
      // Verify the purchase with your backend here
      // For demo, we'll just finish the transaction

      await _iap.finishTransaction(purchase, isConsumable: true);

      // Refresh purchases list
      await _getAvailablePurchases();

      setState(() {
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Purchase completed: ${purchase.productId}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _buyProduct(String productId) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _iap.requestPurchase(
        request: RequestPurchase(
          ios: RequestPurchaseIOS(sku: productId),
        ),
        type: ProductType.inapp,
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _restorePurchases() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _iap.restorePurchases();
      await _getAvailablePurchases();

      setState(() {
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Purchases restored successfully'),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _presentCodeRedemption() async {
    if (!Platform.isIOS) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Code redemption is only available on iOS'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      await _iap.presentCodeRedemptionSheetIOS();
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  Future<void> _showManageSubscriptions() async {
    if (!Platform.isIOS) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Manage subscriptions is only available on iOS'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      await _iap.showManageSubscriptionsIOS();
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  Widget _buildProductCard(ProductCommon product) {
    final isSubscription = product.productId?.contains('subscription') ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isSubscription ? Icons.repeat : Icons.shopping_bag,
                  color: isSubscription ? Colors.blue : Colors.green,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    product.title ?? product.productId ?? 'Unknown Product',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  product.localizedPrice ?? product.price?.toString() ?? '0',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              product.description ?? 'No description available',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (isSubscription &&
                product is Subscription &&
                product.subscriptionPeriodUnitIOS != null) ...[
              const SizedBox(height: 8),
              Text(
                'Subscription period: ${product.subscriptionPeriodNumberIOS} ${product.subscriptionPeriodUnitIOS}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    _loading ? null : () => _buyProduct(product.productId!),
                child: Text(isSubscription ? 'Subscribe' : 'Buy'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseItem(Purchase purchase) {
    return Card(
      color: Colors.green.shade50,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.check_circle, color: Colors.green),
        title: Text(purchase.productId),
        subtitle: Text(
          'Transaction: ${purchase.transactionId ?? 'N/A'}\n'
          'Date: ${purchase.transactionDate != null ? DateTime.fromMillisecondsSinceEpoch(purchase.transactionDate!).toLocal().toString() : 'N/A'}',
        ),
        isThreeLine: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('StoreKit 2 Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _initializeStore,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Connection Status
                  Card(
                    color: _connected
                        ? Colors.green.shade100
                        : Colors.red.shade100,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            _connected ? Icons.check_circle : Icons.error,
                            color: _connected ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _connected
                                ? 'Store Connected'
                                : 'Store Disconnected',
                            style: TextStyle(
                              color: _connected ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Error Message
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Card(
                      color: Colors.red.shade100,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(Icons.error, color: Colors.red),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _error!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // StoreKit 2 Actions
                  const SizedBox(height: 20),
                  Text(
                    'StoreKit 2 Features',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _loading ? null : _restorePurchases,
                        icon: const Icon(Icons.restore),
                        label: const Text('Restore Purchases'),
                      ),
                      if (Platform.isIOS) ...[
                        ElevatedButton.icon(
                          onPressed: _loading ? null : _presentCodeRedemption,
                          icon: const Icon(Icons.card_giftcard),
                          label: const Text('Redeem Code'),
                        ),
                        ElevatedButton.icon(
                          onPressed: _loading ? null : _showManageSubscriptions,
                          icon: const Icon(Icons.subscriptions),
                          label: const Text('Manage Subscriptions'),
                        ),
                      ],
                    ],
                  ),

                  // Products Section
                  const SizedBox(height: 24),
                  Text(
                    'Available Products',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  if (_products.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No products available'),
                      ),
                    )
                  else
                    ..._products.map(_buildProductCard),

                  // Purchases Section
                  const SizedBox(height: 24),
                  Text(
                    'Your Purchases',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  if (_purchases.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No purchases found'),
                      ),
                    )
                  else
                    ..._purchases.map(_buildPurchaseItem),
                ],
              ),
            ),
    );
  }
}
