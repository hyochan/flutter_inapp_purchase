import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

class PurchaseFlowScreen extends StatefulWidget {
  const PurchaseFlowScreen({Key? key}) : super(key: key);

  @override
  State<PurchaseFlowScreen> createState() => _PurchaseFlowScreenState();
}

class _PurchaseFlowScreenState extends State<PurchaseFlowScreen> {
  final FlutterInappPurchase _iap = FlutterInappPurchase.instance;
  
  // Product IDs - consumable products
  final List<String> productIds = [
    'dev.hyo.martie.10bulbs',
    'dev.hyo.martie.30bulbs',
  ];

  List<IAPItem> _products = [];
  bool _isProcessing = false;
  bool _connected = false;
  bool _loading = false;
  String? _purchaseResult;
  Purchase? _currentPurchase;
  StreamSubscription<Purchase>? _purchaseUpdatedSubscription;
  StreamSubscription<PurchaseError>? _purchaseErrorSubscription;

  @override
  void initState() {
    super.initState();
    _initConnection();
  }

  @override
  void dispose() {
    _purchaseUpdatedSubscription?.cancel();
    _purchaseErrorSubscription?.cancel();
    _iap.endConnection();
    super.dispose();
  }

  Future<void> _initConnection() async {
    setState(() {
      _loading = true;
    });
    
    try {
      await _iap.initConnection();
      setState(() {
        _connected = true;
      });
      
      _setupPurchaseListeners();
      await _loadProducts();
    } catch (e) {
      debugPrint('Failed to initialize IAP connection: $e');
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  void _setupPurchaseListeners() {
    debugPrint('Setting up purchase listeners...');
    
    // Listen to purchase updates (using new purchaseUpdatedListener)
    _purchaseUpdatedSubscription = _iap.purchaseUpdatedListener.listen(
      (purchase) {
        debugPrint('🎉 Purchase update received!');
        debugPrint('ProductId: ${purchase.productId}');
        debugPrint('TransactionId: ${purchase.transactionId}');
        debugPrint('PurchaseToken: ${purchase.purchaseToken}');
        debugPrint('Full purchase data: $purchase');
        _handlePurchaseUpdate(purchase);
      },
      onError: (error) {
        debugPrint('❌ Purchase stream error: $error');
      },
      onDone: () {
        debugPrint('Purchase stream closed');
      },
    );

    // Listen to purchase errors (using new purchaseErrorListener)
    _purchaseErrorSubscription = _iap.purchaseErrorListener.listen(
      (purchaseError) {
        debugPrint('❌ Purchase error received!');
        debugPrint('Error code: ${purchaseError.code}');
        debugPrint('Error message: ${purchaseError.message}');
        _handlePurchaseError(purchaseError);
      },
      onError: (error) {
        debugPrint('❌ Error stream error: $error');
      },
    );
    
    debugPrint('Purchase listeners setup complete');
  }

  Future<void> _handlePurchaseUpdate(Purchase purchase) async {
    debugPrint('Purchase successful: ${purchase.productId}');
    debugPrint('Purchase token: ${purchase.purchaseToken}');
    debugPrint('Transaction ID: ${purchase.transactionId}');
    
    setState(() {
      _isProcessing = false;
      _currentPurchase = purchase;
      
      // Format purchase result like KMP-IAP
      _purchaseResult = '''
✅ Purchase successful (${Platform.operatingSystem})
Product: ${purchase.productId}
Transaction ID: ${purchase.transactionId ?? "N/A"}
Date: ${purchase.transactionDate ?? "N/A"}
Receipt: ${purchase.transactionReceipt?.substring(0, purchase.transactionReceipt!.length > 50 ? 50 : purchase.transactionReceipt!.length)}...
Purchase Token: ${purchase.purchaseToken?.substring(0, 30)}...
      '''.trim();
    });

    // IMPORTANT: Server-side receipt validation should be performed here
    // Send the receipt to your backend server for validation
    // Example:
    // final isValid = await validateReceiptOnServer(purchase.transactionReceipt);
    // if (!isValid) {
    //   setState(() {
    //     _purchaseResult = '❌ Receipt validation failed';
    //   });
    //   return;
    // }

    // After successful server validation, finish the transaction
    // For consumable products (like bulb packs), set isConsumable to true
    try {
      await _iap.finishTransaction(purchase, isConsumable: true);
      debugPrint('Transaction finished successfully');
      setState(() {
        _purchaseResult = '$_purchaseResult\n\n✅ Transaction finished successfully';
      });
    } catch (e) {
      debugPrint('Error finishing transaction: $e');
      setState(() {
        _purchaseResult = '$_purchaseResult\n\n❌ Failed to finish transaction: $e';
      });
    }
  }

  void _handlePurchaseError(PurchaseError error) {
    setState(() {
      _isProcessing = false;
      
      // Format error result like KMP-IAP
      if (error.code == ErrorCode.eUserCancelled) {
        _purchaseResult = '⚠️ Purchase cancelled by user';
      } else {
        _purchaseResult = '''
❌ Error: ${error.message}
Code: ${error.code}
Platform: ${error.platform}
        '''.trim();
      }
    });
  }

  Future<void> _loadProducts() async {
    if (!_connected) return;

    try {
      final products = await _iap.getProducts(productIds);
      setState(() {
        _products = products;
      });
    } catch (e) {
      debugPrint('Error loading products: $e');
    }
  }

  Future<void> _handlePurchase(String productId) async {
    debugPrint('🛒 Starting purchase for: $productId');
    setState(() {
      _isProcessing = true;
    });

    try {
      debugPrint('Requesting purchase...');
      await _iap.requestPurchase(
        request: RequestPurchase(
          ios: RequestPurchaseIOS(
            sku: productId,
          ),
          android: RequestPurchaseAndroid(
            skus: [productId],
          ),
        ),
        type: PurchaseType.inapp,
      );
      debugPrint('✅ Purchase request sent successfully');
      // Note: The actual purchase result will come through the purchaseUpdatedListener
    } catch (error) {
      setState(() {
        _isProcessing = false;
      });
      debugPrint('❌ Purchase request error: $error');
      
      // Show error to user
      if (mounted) {
        showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Purchase Failed'),
            content: Text('Error: $error'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Purchase Flow',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Connection Status
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _connected ? Colors.green[50] : Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _connected ? Icons.check_circle : Icons.error,
                        color: _connected ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _connected ? 'Connected to Store' : 'Not Connected',
                        style: TextStyle(
                          color: _connected ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Purchase Result Card (like KMP-IAP)
                if (_purchaseResult != null) ...[
                  Card(
                    color: _purchaseResult!.contains('✅')
                        ? Colors.green.shade50
                        : _purchaseResult!.contains('❌')
                            ? Colors.red.shade50
                            : _purchaseResult!.contains('⚠️')
                                ? Colors.orange.shade50
                                : Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Purchase Result',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 20),
                                onPressed: () {
                                  setState(() {
                                    _purchaseResult = null;
                                    _currentPurchase = null;
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: SelectableText(
                              _purchaseResult!,
                              style: const TextStyle(
                                fontSize: 12,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                          if (_currentPurchase != null) ...[
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () {
                                // Copy full receipt to clipboard
                                final fullInfo = '''
Purchase Information:
====================
Product ID: ${_currentPurchase!.productId}
Transaction ID: ${_currentPurchase!.transactionId}
Date: ${_currentPurchase!.transactionDate}
Platform: ${_currentPurchase!.platform}

Receipt:
${_currentPurchase!.transactionReceipt}

Purchase Token:
${_currentPurchase!.purchaseToken}
                                ''';
                                // You can add clipboard functionality here
                                debugPrint(fullInfo);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Purchase info logged to console'),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.info_outline, size: 18),
                              label: const Text('View Full Details'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Products
                if (_products.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('No products available'),
                    ),
                  )
                else
                  ..._products.map((product) => Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.title ?? product.productId ?? '',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            product.description ?? '',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                product.localizedPrice ?? '',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF007AFF),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: _isProcessing || !_connected
                                    ? null
                                    : () => _handlePurchase(product.productId!),
                                child: Text(_isProcessing ? 'Processing...' : 'Buy'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )),
              ],
            ),
    );
  }
}