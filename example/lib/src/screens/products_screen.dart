import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:flutter_inapp_purchase/types.dart' as iap_types;
import '../iap_provider.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({Key? key}) : super(key: key);

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  // Product IDs matching Martie app
  final List<String> productIds = [
    'dev.hyo.martie.10bulbs',
    'dev.hyo.martie.30bulbs',
  ];

  String? _purchaseResult;
  bool _isProcessing = false;
  StreamSubscription<PurchasedItem?>? _purchaseUpdatedSubscription;
  StreamSubscription<PurchaseResult?>? _purchaseErrorSubscription;

  @override
  void initState() {
    super.initState();

    // Set up purchase listeners
    _setupPurchaseListeners();

    // Load products after a delay to ensure provider is ready
    Future<void>.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _loadProducts();
      }
    });
  }

  @override
  void dispose() {
    _purchaseUpdatedSubscription?.cancel();
    _purchaseErrorSubscription?.cancel();
    super.dispose();
  }

  void _setupPurchaseListeners() {
    // Listen to purchase updates
    _purchaseUpdatedSubscription = FlutterInappPurchase.purchaseUpdated.listen(
      (purchasedItem) {
        if (purchasedItem != null) {
          debugPrint(
              'Purchase update received: ${purchasedItem.productId}, token: ${purchasedItem.purchaseToken}');
          _handlePurchaseUpdate(purchasedItem);
        }
      },
    );

    // Listen to purchase errors
    _purchaseErrorSubscription = FlutterInappPurchase.purchaseError.listen(
      (purchaseError) {
        if (purchaseError != null) {
          _handlePurchaseError(purchaseError);
        }
      },
    );
  }

  Future<void> _handlePurchaseUpdate(PurchasedItem purchasedItem) async {
    debugPrint('Purchase successful: ${purchasedItem.productId}');

    setState(() {
      _isProcessing = false;
      _purchaseResult = '✅ Purchase successful\n'
          'Product: ${purchasedItem.productId}\n'
          'Transaction ID: ${purchasedItem.transactionId ?? 'N/A'}\n'
          'Date: ${purchasedItem.transactionDate != null ? purchasedItem.transactionDate!.toLocal() : 'N/A'}\n'
          'Receipt: ${purchasedItem.transactionReceipt?.substring(0, 50)}...';
    });

    // Deliver the product to the user
    await _deliverProduct(purchasedItem.productId);

    // Finish the transaction
    try {
      if (!mounted) return;

      if (Platform.isAndroid) {
        // For Android, directly consume the purchase for consumable products
        if (purchasedItem.purchaseToken != null) {
          debugPrint(
              'Attempting to consume Android purchase with token: ${purchasedItem.purchaseToken}');

          // Try multiple times to ensure consumption
          bool consumed = false;
          for (int i = 0; i < 3 && !consumed; i++) {
            try {
              await FlutterInappPurchase.instance.consumePurchaseAndroid(
                purchaseToken: purchasedItem.purchaseToken!,
              );
              consumed = true;
              debugPrint(
                  'Android purchase consumed successfully on attempt ${i + 1}');
            } catch (e) {
              debugPrint('Consume attempt ${i + 1} failed: $e');
              if (i < 2) {
                await Future<void>.delayed(const Duration(milliseconds: 500));
              }
            }
          }

          if (!consumed) {
            debugPrint('ERROR: Failed to consume purchase after 3 attempts');
            // Show error to user
            if (mounted) {
              setState(() {
                _purchaseResult =
                    '❌ Failed to complete purchase. Please try "Force Clear All Purchases" in Settings.';
              });
            }
          }
        } else {
          debugPrint('ERROR: No purchase token available for Android');
        }
      } else if (Platform.isIOS) {
        // For iOS, finish the transaction
        await FlutterInappPurchase.instance.finishTransactionIOS(
          purchasedItem,
          isConsumable: true, // Set to true for consumable products
        );
        debugPrint('iOS transaction finished');
      }
    } catch (e) {
      debugPrint('Error finishing transaction: $e');
      if (mounted) {
        setState(() {
          _purchaseResult = '❌ Transaction error: $e';
        });
      }
    }

    // Show success dialog
    if (mounted) {
      showDialog<void>(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: const Text('Success'),
          content: const Text('Purchase completed successfully!'),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _handlePurchaseError(PurchaseResult error) {
    debugPrint('Purchase failed: ${error.message}');

    setState(() {
      _isProcessing = false;
      _purchaseResult = '❌ Purchase failed: ${error.message}';
    });

    // Check if error is "You already own this item" (Error code 7)
    if (error.responseCode == 7 ||
        error.message?.contains('already own') == true) {
      debugPrint(
          'User already owns this item. Attempting to consume existing purchase...');
      _consumeExistingPurchase();
    } else {
      // Show error dialog for other errors
      if (mounted) {
        showDialog<void>(
          context: context,
          builder: (_) => CupertinoAlertDialog(
            title: const Text('Purchase Failed'),
            content: Text(error.message ?? 'Unknown error occurred'),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _consumeExistingPurchase() async {
    setState(() {
      _purchaseResult = 'Attempting to consume existing purchases...';
    });

    try {
      // First, restore purchases to get all owned items
      await FlutterInappPurchase.instance.restorePurchases();

      // Wait a bit for restoration
      await Future<void>.delayed(const Duration(milliseconds: 500));

      // Get all available purchases
      final purchases =
          await FlutterInappPurchase.instance.getAvailablePurchases();

      debugPrint('Found ${purchases.length} existing purchases');

      // Find and consume purchases for our product IDs
      for (final purchase in purchases) {
        if (productIds.contains(purchase.productId)) {
          if (purchase.purchaseToken != null) {
            debugPrint('Consuming existing purchase: ${purchase.productId}');
            try {
              await FlutterInappPurchase.instance.consumePurchaseAndroid(
                purchaseToken: purchase.purchaseToken!,
              );
              debugPrint('Successfully consumed: ${purchase.productId}');

              if (mounted) {
                setState(() {
                  _purchaseResult =
                      '✅ Consumed existing purchase. Try purchasing again.';
                });
              }

              // Show success dialog
              if (mounted) {
                showDialog<void>(
                  context: context,
                  builder: (_) => CupertinoAlertDialog(
                    title: const Text('Purchase Cleared'),
                    content: const Text(
                        'The previous purchase has been consumed. You can now purchase this item again.'),
                    actions: [
                      CupertinoDialogAction(
                        isDefaultAction: true,
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              }

              break; // Exit after consuming the first matching product
            } catch (e) {
              debugPrint('Failed to consume: $e');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error during consume process: $e');
      setState(() {
        _purchaseResult = '❌ Failed to clear existing purchase: $e';
      });
    }
  }

  Future<void> _deliverProduct(String? productId) async {
    // Implement your product delivery logic here
    // For example, add bulbs to user's account
    debugPrint('Delivering product: $productId');

    // In a real app, you would:
    // 1. Verify the purchase with your backend
    // 2. Update user's account with the purchased items
    // 3. Store the purchase status locally if needed
  }

  Future<void> _loadProducts() async {
    if (!mounted) return;

    final iapProvider = IapProvider.of(context);
    if (iapProvider != null && iapProvider.connected) {
      try {
        // Use requestProducts instead of getProducts (new API)
        await FlutterInappPurchase.instance.requestProducts(
          iap_types.RequestProductsParams(
              skus: productIds, type: PurchaseType.inapp),
        );
        // Update provider state if needed
        await iapProvider.getProducts(productIds);
      } catch (e) {
        debugPrint('Error loading products: $e');
      }
    }
  }

  Future<void> _handlePurchase(String productId) async {
    try {
      setState(() {
        _isProcessing = true;
        _purchaseResult = 'Processing purchase...';
      });

      // Use requestPurchase (new API)
      await FlutterInappPurchase.instance.requestPurchase(
        request: RequestPurchase(
          ios: RequestPurchaseIOS(
            sku: productId,
            quantity: 1,
          ),
          android: RequestPurchaseAndroid(
            skus: [productId],
          ),
        ),
        type: PurchaseType.inapp,
      );
    } catch (error) {
      setState(() {
        _isProcessing = false;
      });
      final errorMessage = error.toString();
      setState(() {
        _purchaseResult = '❌ Purchase failed: $errorMessage';
      });

      if (mounted) {
        showDialog<void>(
          context: context,
          builder: (_) => CupertinoAlertDialog(
            title: const Text('Purchase Failed'),
            content: Text(errorMessage),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
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
    final iapProvider = IapProvider.of(context);

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
          'Products',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: iapProvider?.loading ?? false
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProducts,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Connection Status
                  _buildConnectionStatus(iapProvider),
                  const SizedBox(height: 20),

                  // Error Message
                  if (iapProvider?.error != null)
                    _buildErrorMessage(iapProvider!.error!),

                  // Products List
                  if (iapProvider?.products.isEmpty ?? true)
                    _buildEmptyState()
                  else
                    ...iapProvider!.products.map((product) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildProductCard(product, iapProvider),
                        )),

                  // Purchase Result
                  if (_purchaseResult != null) ...[
                    const SizedBox(height: 20),
                    _buildResultSection(),
                  ],

                  // Info Section
                  const SizedBox(height: 20),
                  _buildInfoSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildConnectionStatus(IapProvider? iapProvider) {
    final isConnected = iapProvider?.connected ?? false;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isConnected ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            isConnected
                ? CupertinoIcons.checkmark_circle_fill
                : CupertinoIcons.xmark_circle_fill,
            color:
                isConnected ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            isConnected ? 'Store Connected' : 'Store Disconnected',
            style: TextStyle(
              color: isConnected
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFFF44336),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage(String error) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFCDD2)),
      ),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.exclamationmark_circle_fill,
            color: Color(0xFFF44336),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(
                color: Color(0xFFF44336),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            CupertinoIcons.cart,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Products Available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Products will appear here once loaded from the store',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 16),
          CupertinoButton(
            color: const Color(0xFF007AFF),
            borderRadius: BorderRadius.circular(8),
            onPressed: _loadProducts,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(IAPItem product, IapProvider? iapProvider) {
    final String productId = product.productId ?? '';
    final String title = product.title ?? productId;
    final String description = product.description ?? '';
    final String price = product.localizedPrice ?? product.price ?? '';

    // Extract bulb count from product ID
    final bulbCount = productId.split('.').last.replaceAll('bulbs', '');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(
                        CupertinoIcons.lightbulb_fill,
                        color: Color(0xFFFFC107),
                        size: 32,
                      ),
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            bulbCount,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: CupertinoButton(
                color: const Color(0xFF007AFF),
                borderRadius: BorderRadius.circular(12),
                padding: const EdgeInsets.symmetric(vertical: 16),
                onPressed: (_isProcessing || !(iapProvider?.connected ?? false))
                    ? null
                    : () => _handlePurchase(productId),
                child: Text(
                  _isProcessing
                      ? 'Processing...'
                      : (price.isNotEmpty ? price : 'Purchase'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _purchaseResult!.startsWith('✅')
              ? const Color(0xFF4CAF50)
              : const Color(0xFF007AFF),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Result',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _purchaseResult!,
            style: const TextStyle(
              fontSize: 14,
              fontFamily: 'Courier',
              height: 1.5,
              color: Color(0xFF333333),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F8FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🎯 Key Features Demonstrated',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0066CC),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '• Purchase success/error handling\n'
            '• Transaction finishing\n'
            '• Using requestProducts API (new)\n'
            '• Using requestPurchase API (new)\n'
            '• Real-time purchase status updates\n'
            '• Platform-agnostic implementation',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
