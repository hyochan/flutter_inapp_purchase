import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:flutter_inapp_purchase/extensions/purchase_helpers.dart';
import 'package:flutter_inapp_purchase/helpers.dart';
import '../widgets/product_detail_modal.dart';
import '../constants.dart';

class AllProductsScreen extends StatefulWidget {
  const AllProductsScreen({Key? key}) : super(key: key);

  @override
  State<AllProductsScreen> createState() => _AllProductsScreenState();
}

class _AllProductsScreenState extends State<AllProductsScreen> {
  final FlutterInappPurchase _iap = FlutterInappPurchase.instance;

  // All products fetched from the store
  List<ProductCommon> _allProducts = [];
  final Map<String, ProductCommon> _originalProducts = {};
  bool _isProcessing = false;
  bool _connected = false;
  bool _loading = false;
  String? _purchaseResult;
  Purchase? _currentPurchase;
  StreamSubscription<Purchase>? _purchaseUpdatedSubscription;
  StreamSubscription<PurchaseError>? _purchaseErrorSubscription;
  final Set<String> _processedTransactionIds = {};
  final Set<String> _processedErrorMessages = {};
  String? _storefront;

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

  PurchaseError? _convertPlatformExceptionToPurchaseError(dynamic error) {
    if (error is! PlatformException) return null;

    // Web platform doesn't have IAP support, so this shouldn't be called
    // Use Android as default for error reporting purposes
    final IapPlatform platform;
    if (kIsWeb) {
      // Web doesn't support IAP - return null or use Android as fallback
      return null;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      platform = IapPlatform.IOS;
    } else {
      platform = IapPlatform.Android;
    }

    return PurchaseError.fromPlatformError({
      'code': error.code,
      'message': error.message ?? 'Unknown error',
      'details': error.details,
    }, platform);
  }

  Future<void> _initConnection() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
    });

    try {
      await _iap.initConnection();
      if (!mounted) return;
      setState(() {
        _connected = true;
      });

      _setupPurchaseListeners();
      await _loadAllProducts();
      await _loadStorefront();
    } catch (e) {
      debugPrint('Failed to initialize IAP connection: $e');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _setupPurchaseListeners() {
    debugPrint('Setting up purchase listeners...');

    _purchaseUpdatedSubscription = _iap.purchaseUpdatedListener.listen(
      (purchase) {
        final transactionId = purchase.purchaseToken ?? purchase.id;
        if (_processedTransactionIds.contains(transactionId)) {
          return;
        }
        _processedTransactionIds.add(transactionId);

        if (!mounted) return;
        setState(() {
          _currentPurchase = purchase;
          _purchaseResult = 'Purchase successful!';
          _isProcessing = false;
        });

        if (purchase.purchaseState == PurchaseState.Purchased) {
          _finalizePurchase(purchase);
        }
      },
      onError: (error) {
        debugPrint('Purchase update error: $error');
        final purchaseError = _convertPlatformExceptionToPurchaseError(error);
        if (purchaseError != null) {
          _handlePurchaseError(purchaseError);
        } else {
          if (!mounted) return;
          setState(() {
            _purchaseResult = 'Error: ${error.toString()}';
            _isProcessing = false;
          });
        }
      },
    );

    _purchaseErrorSubscription = _iap.purchaseErrorListener.listen(
      (error) {
        debugPrint('Purchase error received: ${error.message}');
        _handlePurchaseError(error);
      },
    );
  }

  void _handlePurchaseError(PurchaseError error) {
    final errorKey = '${error.code}-${error.message}';
    if (_processedErrorMessages.contains(errorKey)) {
      return;
    }
    _processedErrorMessages.add(errorKey);

    if (!mounted) return;
    setState(() {
      _purchaseResult = 'Error (${error.code}): ${error.message}';
      _isProcessing = false;
    });

    if (error.code == 'E_USER_CANCELLED') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Purchase cancelled'),
          backgroundColor: Colors.orange,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Purchase failed: ${error.message}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadStorefront() async {
    try {
      final storefront = await _iap.getStorefront();
      if (!mounted) return;
      setState(() {
        _storefront = storefront.isEmpty ? 'Unknown' : storefront;
      });
      debugPrint('Storefront: $_storefront');
    } catch (e) {
      debugPrint('Failed to get storefront: $e');
      if (!mounted) return;
      setState(() {
        _storefront = 'Error';
      });
    }
  }

  Future<void> _loadAllProducts() async {
    try {
      // Fetch all products using ProductQueryType.All
      // The library now handles both Product and ProductSubscription types internally
      // Use explicit type parameter for proper type inference
      final products = await _iap.fetchProducts<ProductCommon>(
        skus: IapConstants.allProductIds,
        type: ProductQueryType.All,
      );

      debugPrint('Loaded ${products.length} products');
      for (final product in products) {
        debugPrint(
            '  - ${product.id}: ${product.title} (${IapConstants.getProductTypeLabel(product.id)})');
      }

      if (!mounted) return;
      setState(() {
        _allProducts = products;

        // Store all original products
        for (final product in products) {
          _originalProducts[product.id] = product;
        }
      });
    } catch (e) {
      debugPrint('Failed to load products: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load products: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _requestPurchase(ProductCommon product) async {
    if (!mounted) return;
    setState(() {
      _isProcessing = true;
      _purchaseResult = null;
      _currentPurchase = null;
      _processedTransactionIds.clear();
      _processedErrorMessages.clear();
    });

    try {
      final RequestPurchaseProps params;
      if (IapConstants.isSubscription(product.id)) {
        // Subscription
        // For Android, convert subscription offer details to SubscriptionOfferAndroid
        List<SubscriptionOfferAndroid>? androidOffers;
        if (!kIsWeb &&
            defaultTargetPlatform == TargetPlatform.android &&
            product is ProductAndroid) {
          final details = product.subscriptionOfferDetailsAndroid;
          if (details != null && details.isNotEmpty) {
            androidOffers = [
              for (final offer in details)
                SubscriptionOfferAndroid(
                  offerToken: offer.offerToken,
                  // sku must be the productId (SKU), not the basePlanId.
                  sku: product.id,
                ),
            ];
          }
        }

        params = RequestPurchaseProps.subs((
          apple: !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS
              ? RequestSubscriptionIosProps(sku: product.id, quantity: 1)
              : null,
          google: !kIsWeb && defaultTargetPlatform == TargetPlatform.android
              ? RequestSubscriptionAndroidProps(
                  skus: [product.id],
                )
              : null,
          useAlternativeBilling: null,
        ));
      } else {
        // In-app purchase
        params = RequestPurchaseProps.inApp((
          apple: !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS
              ? RequestPurchaseIosProps(sku: product.id, quantity: 1)
              : null,
          google: !kIsWeb && defaultTargetPlatform == TargetPlatform.android
              ? RequestPurchaseAndroidProps(skus: [product.id])
              : null,
          useAlternativeBilling: null,
        ));
      }
      await _iap.requestPurchase(params);
    } catch (e) {
      debugPrint('Purchase request error: $e');
      final purchaseError = _convertPlatformExceptionToPurchaseError(e);
      if (purchaseError != null) {
        _handlePurchaseError(purchaseError);
      } else {
        if (mounted) {
          setState(() {
            _purchaseResult = 'Failed to request purchase: $e';
            _isProcessing = false;
          });
        }
      }
    }
  }

  Future<void> _finalizePurchase(Purchase purchase) async {
    try {
      final prod = _originalProducts[purchase.productId];
      final isConsumable = prod != null && IapConstants.isConsumable(prod.id);
      await _iap.finishTransaction(
        purchase: purchase,
        isConsumable: isConsumable,
      );
      debugPrint('Purchase finalized successfully');
    } catch (e) {
      debugPrint('Failed to finalize purchase: $e');
    }
  }

  void _showProductDetails(ProductCommon product) {
    ProductDetailModal.show(
      context: context,
      item: _originalProducts[product.id] ?? product,
      product: _originalProducts[product.id] ?? product,
    );
  }

  // Group products by type for display
  Map<String, List<ProductCommon>> _groupProductsByType() {
    final grouped = <String, List<ProductCommon>>{};

    for (final product in _allProducts) {
      final type = IapConstants.getProductTypeLabel(product.id);
      grouped[type] = (grouped[type] ?? [])..add(product);
    }

    return grouped;
  }

  Widget _buildProductSection({
    required String title,
    required List<ProductCommon> products,
  }) {
    if (products.isEmpty) {
      return Container();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...products.map((product) => _buildProductCard(product)),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildProductCard(ProductCommon product) {
    final productType = IapConstants.getProductTypeLabel(product.id);
    final isSubscription = IapConstants.isSubscription(product.id);

    // Set color based on product type
    Color accentColor;
    IconData icon;
    if (IapConstants.isSubscription(product.id)) {
      accentColor = Colors.purple;
      icon = CupertinoIcons.repeat;
    } else if (IapConstants.isConsumable(product.id)) {
      accentColor = Colors.blue;
      icon = CupertinoIcons.bag_fill;
    } else if (IapConstants.isNonConsumable(product.id)) {
      accentColor = Colors.green;
      icon = CupertinoIcons.checkmark_seal_fill;
    } else {
      accentColor = Colors.grey;
      icon = CupertinoIcons.question_circle;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showProductDetails(product),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: accentColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            product.price?.toString() ?? 'N/A',
                            style: TextStyle(
                              color: accentColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            productType,
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (!kIsWeb &&
                            defaultTargetPlatform == TargetPlatform.android &&
                            product is ProductAndroid) ...[
                          const SizedBox(width: 8),
                          if (product.oneTimePurchaseOfferDetailsAndroid !=
                              null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Play',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                CupertinoIcons.chevron_right,
                color: Colors.grey[400],
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: Column(
          children: [
            const Text('All Products'),
            if (_storefront != null)
              Text(
                'Store: $_storefront',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.refresh),
            onPressed: _connected && !_loading
                ? () async {
                    await _loadAllProducts();
                    await _loadStorefront();
                  }
                : null,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : !_connected
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.wifi_slash,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Store not connected',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _initConnection,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadAllProducts,
                  child: ListView(
                    children: [
                      if (_purchaseResult != null)
                        Container(
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.green.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _purchaseResult!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.close),
                                onPressed: () {
                                  setState(() {
                                    _purchaseResult = null;
                                    _currentPurchase = null;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      if (_isProcessing)
                        Container(
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.blue.withOpacity(0.3),
                            ),
                          ),
                          child: const Row(
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Processing purchase...',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      // Display all products grouped by type
                      if (_allProducts.isNotEmpty) ...[
                        // Group and display products by type
                        ..._groupProductsByType().entries.map((entry) {
                          String sectionTitle;
                          switch (entry.key) {
                            case 'Consumable':
                              sectionTitle = 'Consumable Products';
                              break;
                            case 'Non-Consumable':
                              sectionTitle = 'Non-Consumable Products';
                              break;
                            case 'Subscription':
                              sectionTitle = 'Subscriptions';
                              break;
                            default:
                              sectionTitle = entry.key;
                          }
                          return _buildProductSection(
                            title: sectionTitle,
                            products: entry.value,
                          );
                        }),
                      ],
                      if (_allProducts.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              children: [
                                Icon(
                                  CupertinoIcons.bag,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No products available',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Make sure products are configured in your store',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}
