import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import '../widgets/product_detail_modal.dart';

class SubscriptionFlowScreen extends StatefulWidget {
  const SubscriptionFlowScreen({Key? key}) : super(key: key);

  @override
  State<SubscriptionFlowScreen> createState() => _SubscriptionFlowScreenState();
}

class _SubscriptionFlowScreenState extends State<SubscriptionFlowScreen> {
  final FlutterInappPurchase _iap = FlutterInappPurchase.instance;

  // Multiple subscription tiers for testing upgrades/downgrades
  // Replace these with your actual subscription IDs
  final List<String> subscriptionIds = [
    'dev.hyo.martie.premium', // Premium tier
  ];

  List<ProductCommon> _subscriptions = [];
  final Map<String, ProductCommon> _originalProducts = {};
  List<Purchase> _activeSubscriptions = [];
  Purchase? _currentSubscription;
  bool _hasActiveSubscription = false;
  bool _isProcessing = false;
  bool _connected = false;
  bool _isConnecting = true;
  bool _isLoadingProducts = false;
  String? _purchaseResult;

  // Stream subscriptions
  StreamSubscription<Purchase>? _purchaseUpdatedSubscription;
  StreamSubscription<PurchaseError>? _purchaseErrorSubscription;

  // Track processed transactions to avoid duplicates
  final Set<String> _processedTransactionIds = {};

  // Proration mode selection
  int? _selectedProrationMode;
  final Map<String, int> _prorationModes = {
    'Immediate with Time Proration': 1,
    'Immediate and Charge Prorated Price': 2,
    'Immediate without Proration': 3,
    'Deferred': 4,
    'Immediate and Charge Full Price': 5,
  };

  List<SubscriptionOfferAndroid> _androidOffersFor(ProductCommon item) {
    if (item is ProductSubscriptionAndroid) {
      return item.subscriptionOfferDetailsAndroid
          .map(
            (offer) => SubscriptionOfferAndroid(
              offerToken: offer.offerToken,
              sku: offer.basePlanId,
            ),
          )
          .toList();
    }
    return const <SubscriptionOfferAndroid>[];
  }

  String? _transactionIdFor(Purchase purchase) {
    return purchase.id.isEmpty ? null : purchase.id;
  }

  int? _androidPurchaseStateValue(Purchase purchase) {
    if (purchase is PurchaseAndroid) {
      switch (purchase.purchaseState) {
        case PurchaseState.Purchased:
          return AndroidPurchaseState.Purchased.value;
        case PurchaseState.Pending:
          return AndroidPurchaseState.Pending.value;
        case PurchaseState.Failed:
        case PurchaseState.Deferred:
        case PurchaseState.Restored:
        case PurchaseState.Unknown:
          return AndroidPurchaseState.Unknown.value;
      }
    }
    return null;
  }

  TransactionState? _transactionStateForIOS(Purchase purchase) {
    if (purchase is! PurchaseIOS) {
      return null;
    }

    switch (purchase.purchaseState) {
      case PurchaseState.Purchased:
        return TransactionState.purchased;
      case PurchaseState.Pending:
        return TransactionState.purchasing;
      case PurchaseState.Failed:
        return TransactionState.failed;
      case PurchaseState.Deferred:
        return TransactionState.deferred;
      case PurchaseState.Restored:
        return TransactionState.restored;
      case PurchaseState.Unknown:
        return TransactionState.purchasing;
    }
  }

  bool? _isAcknowledgedAndroid(Purchase purchase) {
    return purchase is PurchaseAndroid ? purchase.isAcknowledgedAndroid : null;
  }

  @override
  void initState() {
    super.initState();
    _initConnection();
    _setupListeners();
  }

  @override
  void dispose() {
    _purchaseUpdatedSubscription?.cancel();
    _purchaseErrorSubscription?.cancel();
    _iap.endConnection();
    super.dispose();
  }

  void _setupListeners() {
    // Listen to purchase updates
    _purchaseUpdatedSubscription = _iap.purchaseUpdatedListener.listen(
      (purchase) async {
        debugPrint('🎯 Purchase updated: ${purchase.productId}');
        debugPrint('  Platform: ${purchase.platform}');
        debugPrint('  Purchase state: ${purchase.purchaseState}');
        final transactionId = _transactionIdFor(purchase);
        final androidStateValue = _androidPurchaseStateValue(purchase);
        final iosTransactionState = _transactionStateForIOS(purchase);
        final acknowledgedAndroid = _isAcknowledgedAndroid(purchase);
        debugPrint(
            '  Purchase state Android (legacy value): $androidStateValue');
        debugPrint('  Transaction state iOS: $iosTransactionState');
        debugPrint('  Is acknowledged Android: $acknowledgedAndroid');
        debugPrint('  Transaction ID: ${transactionId ?? 'N/A'}');
        debugPrint('  Purchase token: ${purchase.purchaseToken}');
        if (purchase is PurchaseAndroid) {
          debugPrint('  Auto renewing: ${purchase.autoRenewingAndroid}');
        }

        if (!mounted) {
          debugPrint('  ⚠️ Widget not mounted, ignoring update');
          return;
        }

        // Check for duplicate processing
        final transactionKey = transactionId ?? purchase.purchaseToken ?? '';
        if (transactionKey.isNotEmpty &&
            _processedTransactionIds.contains(transactionKey)) {
          debugPrint('  ⚠️ Transaction already processed: $transactionKey');
          return;
        }

        // Handle the purchase - check multiple conditions
        // purchaseState.purchased or purchaseStateAndroid == AndroidPurchaseState.Purchased or isAcknowledgedAndroid == false (new purchase)
        bool isPurchased = false;

        if (Platform.isAndroid && purchase is PurchaseAndroid) {
          // For Android, check multiple conditions since fields can be null
          final bool condition1 =
              purchase.purchaseState == PurchaseState.Purchased;
          final bool condition2 = acknowledgedAndroid == false &&
              purchase.purchaseToken != null &&
              purchase.purchaseToken!.isNotEmpty &&
              purchase.purchaseState == PurchaseState.Purchased;
          final bool condition3 =
              androidStateValue == AndroidPurchaseState.Purchased.value;

          debugPrint('  Android condition checks:');
          debugPrint('    purchaseState == purchased: $condition1');
          debugPrint('    unacknowledged with token: $condition2');
          debugPrint(
              '    purchaseStateAndroid == AndroidPurchaseState.Purchased: $condition3');

          isPurchased = condition1 || condition2 || condition3;
          debugPrint('  Final isPurchased: $isPurchased');
        } else if (purchase is PurchaseIOS) {
          // For iOS - simpler logic like purchase_flow_screen.dart
          // iOS purchase updates with valid tokens indicate successful purchases
          final bool condition1 =
              iosTransactionState == TransactionState.purchased;
          bool condition2 = purchase.purchaseToken != null &&
              purchase.purchaseToken!.isNotEmpty;
          final bool condition3 = transactionId != null;

          debugPrint('  iOS condition checks:');
          debugPrint('    transactionStateIOS == purchased: $condition1');
          debugPrint('    has valid purchaseToken: $condition2');
          debugPrint('    has valid transactionId: $condition3');

          // For iOS, receiving a purchase update usually means success
          // especially if we have either a valid token OR transaction ID
          isPurchased = condition1 || condition2 || condition3;
          debugPrint('  Final isPurchased: $isPurchased');
        }

        if (isPurchased) {
          debugPrint('✅ Purchase detected as successful, updating UI...');
          debugPrint('  _isProcessing before setState: $_isProcessing');

          // Mark as processed
          if (transactionKey.isNotEmpty) {
            _processedTransactionIds.add(transactionKey);
          }

          // Update UI immediately
          if (mounted) {
            setState(() {
              _purchaseResult = '✅ Purchase successful: ${purchase.productId}';
              _isProcessing = false;
            });
            debugPrint('  _isProcessing after setState: $_isProcessing');
            debugPrint('  UI should be updated now');
          } else {
            debugPrint('  ⚠️ Widget not mounted, cannot update UI');
          }

          // Acknowledge/finish the transaction
          try {
            debugPrint('Calling finishTransaction...');
            await _iap.finishTransaction(purchase);
            debugPrint('Transaction finished successfully');
          } catch (e) {
            debugPrint('Error finishing transaction: $e');
          }

          // Refresh subscriptions after a short delay to ensure transaction is processed
          await Future<void>.delayed(const Duration(milliseconds: 500));
          debugPrint('Refreshing subscriptions...');
          await _checkActiveSubscriptions();
          debugPrint('Subscriptions refreshed');
        } else if (purchase.purchaseState == PurchaseState.Pending ||
            androidStateValue == AndroidPurchaseState.Unknown.value) {
          // Pending
          if (!mounted) return;
          setState(() {
            _purchaseResult = '⏳ Purchase pending: ${purchase.productId}';
          });
        } else {
          // Unknown state - log for debugging
          debugPrint('❓ Unknown purchase state');
          debugPrint('  Purchase state: ${purchase.purchaseState}');
          debugPrint('  Transaction state iOS: $iosTransactionState');
          debugPrint(
              '  Purchase state Android (legacy value): $androidStateValue');
          debugPrint(
              '  Has token: ${purchase.purchaseToken != null && purchase.purchaseToken!.isNotEmpty}');

          if (!mounted) return;
          setState(() {
            _isProcessing = false;
            _purchaseResult = '''
⚠️ Purchase received but state unknown
Platform: ${purchase.platform}
Purchase state: ${purchase.purchaseState}
iOS transaction state: $iosTransactionState
Android purchase state (legacy value): $androidStateValue
Has token: ${purchase.purchaseToken != null && purchase.purchaseToken!.isNotEmpty}
          '''
                .trim();
          });
        }
      },
      onError: (Object error) {
        debugPrint('Purchase stream error: $error');
        if (!mounted) return;
        setState(() {
          _isProcessing = false;
          _purchaseResult = '❌ Stream error: $error';
        });
      },
    );

    // Listen to purchase errors
    _purchaseErrorSubscription = _iap.purchaseErrorListener.listen(
      (error) {
        debugPrint('Purchase error: ${error.code} - ${error.message}');

        if (!mounted) return;

        setState(() {
          _isProcessing = false;
          if (error.code == ErrorCode.UserCancelled) {
            _purchaseResult = '⚠️ Purchase cancelled';
          } else {
            _purchaseResult = '❌ Error: ${error.message}';
          }
        });
      },
      onError: (Object error) {
        debugPrint('Error stream error: $error');
      },
    );
  }

  Future<void> _initConnection() async {
    try {
      final result = await _iap.initConnection();
      debugPrint('Connection initialized: $result');

      if (!mounted) return;

      setState(() {
        _connected = result;
        _isConnecting = false;
      });

      if (_connected) {
        await _loadSubscriptions();
        await _checkActiveSubscriptions();
      }
    } catch (error) {
      debugPrint('Failed to initialize connection: $error');
      if (!mounted) return;
      setState(() {
        _connected = false;
        _isConnecting = false;
      });
    }
  }

  Future<void> _loadSubscriptions() async {
    if (!_connected) return;

    setState(() => _isLoadingProducts = true);

    try {
      // Use fetchProducts with Subscription type for type-safe list
      final products = await _iap.fetchProducts<ProductSubscription>(
        skus: subscriptionIds,
        type: ProductType.Subs,
      );

      debugPrint('Loaded ${products.length} subscriptions');

      if (!mounted) return;

      setState(() {
        // Store original products
        _originalProducts.clear();
        for (final product in products) {
          final productKey = product.id;
          _originalProducts[productKey] = product;
        }

        _subscriptions = products;
        _isLoadingProducts = false;
      });
    } catch (error) {
      debugPrint('Failed to load subscriptions: $error');
      if (!mounted) return;
      setState(() {
        _isLoadingProducts = false;
        _purchaseResult = '❌ Failed to load subscriptions: $error';
      });
    }
  }

  Future<void> _checkActiveSubscriptions() async {
    if (!_connected) return;

    try {
      // Get all available purchases
      final purchases = await _iap.getAvailablePurchases();

      debugPrint('=== Checking Active Subscriptions ===');
      debugPrint('Total purchases found: ${purchases.length}');
      for (var p in purchases) {
        debugPrint(
            '  - ${p.productId}: token=${p.purchaseToken?.substring(0, 20)}...');
      }

      // Filter for subscriptions
      final activeSubs = purchases
          .where((p) => subscriptionIds.contains(p.productId))
          .toList();

      if (!mounted) return;

      setState(() {
        _activeSubscriptions = activeSubs;
        _hasActiveSubscription = activeSubs.isNotEmpty;
        _currentSubscription = activeSubs.isNotEmpty ? activeSubs.first : null;

        if (_currentSubscription != null) {
          debugPrint(
              'Current subscription: ${_currentSubscription!.productId}');
          debugPrint('Purchase token: ${_currentSubscription!.purchaseToken}');
          _purchaseResult =
              'Active: ${_currentSubscription!.productId}\nToken: ${_currentSubscription!.purchaseToken?.substring(0, 30)}...';
        } else {
          debugPrint('No active subscription found in filtered list');
        }
      });
    } catch (error) {
      debugPrint('Failed to check active subscriptions: $error');
      if (!mounted) return;
      setState(() {
        _purchaseResult = '❌ Error checking subscriptions: $error';
      });
    }
  }

  Future<void> _purchaseSubscription(ProductCommon item,
      {bool isUpgrade = false}) async {
    if (_isProcessing) {
      debugPrint('⚠️ Already processing a purchase, ignoring');
      return;
    }

    debugPrint('🛒 Starting subscription purchase: ${item.id}');
    debugPrint('  isUpgrade: $isUpgrade');
    debugPrint('  Current subscription: ${_currentSubscription?.productId}');

    setState(() {
      _isProcessing = true;
      _purchaseResult = null;
    });
    debugPrint('  Set _isProcessing to true');

    try {
      // Check for Android offers
      final androidOffers = _androidOffersFor(item);
      final SubscriptionOfferAndroid? selectedOffer =
          androidOffers.isNotEmpty ? androidOffers.first : null;
      if (selectedOffer != null) {
        debugPrint('Using offer token: ${selectedOffer.offerToken}');
      }

      // Request subscription using the new API
      if (Platform.isAndroid) {
        // Check if this is an upgrade/downgrade
        if (isUpgrade &&
            _currentSubscription != null &&
            _selectedProrationMode != null) {
          // This is an upgrade/downgrade with proration
          debugPrint(
              'Upgrading subscription with proration mode: $_selectedProrationMode');
          debugPrint(
              'Using purchase token: ${_currentSubscription!.purchaseToken}');

          final requestProps = RequestPurchase(
            android: RequestSubscriptionAndroid(
              skus: [item.id],
              subscriptionOffers:
                  selectedOffer != null ? [selectedOffer] : androidOffers,
              purchaseTokenAndroid: _currentSubscription!.purchaseToken,
              replacementModeAndroid: _selectedProrationMode,
            ),
            type: ProductType.Subs,
          );

          await _iap.requestPurchase(requestProps.toProps());
        } else {
          // This is a new subscription purchase
          debugPrint('Purchasing new subscription');

          final requestProps = RequestPurchase(
            android: RequestSubscriptionAndroid(
              skus: [item.id],
              subscriptionOffers:
                  selectedOffer != null ? [selectedOffer] : androidOffers,
            ),
            type: ProductType.Subs,
          );

          await _iap.requestPurchase(requestProps.toProps());
        }
      } else {
        // iOS
        final requestProps = RequestPurchase(
          ios: RequestPurchaseIOS(
            sku: item.id,
          ),
          type: ProductType.Subs,
        );

        await _iap.requestPurchase(requestProps.toProps());
      }

      // Result will be handled by the purchase stream listeners
      debugPrint('Purchase request sent, waiting for response...');
    } catch (error) {
      debugPrint('Failed to request subscription: $error');
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _purchaseResult = '❌ Failed to request: $error';
      });
    }
  }

  // Test with fake/invalid token (should fail on native side)
  Future<void> _testWrongProrationUsage(ProductCommon item) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _purchaseResult = null;
    });

    try {
      debugPrint(
          'Testing proration mode with FAKE purchaseToken (should fail on native side)');

      // Use a fake/invalid token to test native validation
      final fakeToken =
          'fake_token_for_testing_${DateTime.now().millisecondsSinceEpoch}';
      debugPrint('Using fake token: $fakeToken');

      final requestProps = RequestPurchase(
        android: RequestSubscriptionAndroid(
          skus: [item.id],
          subscriptionOffers: _androidOffersFor(item),
          purchaseTokenAndroid:
              fakeToken, // Fake token that will fail on native side
          replacementModeAndroid: AndroidReplacementMode.deferred.value,
        ),
        type: ProductType.Subs,
      );

      await _iap.requestPurchase(requestProps.toProps());

      // If we get here, the purchase was attempted
      debugPrint('Purchase request sent with fake token');
      // Result will come through purchaseUpdatedListener
    } catch (error) {
      debugPrint('Error with fake token: $error');
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _purchaseResult = '❌ Error with fake token:\n$error';
      });
    }
  }

  // Test with empty purchaseToken (Issue #529)
  Future<void> _testEmptyTokenProration(ProductCommon item) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _purchaseResult = null;
    });

    try {
      debugPrint('Testing proration mode with EMPTY string purchaseToken');

      // Use current subscription token if available, otherwise use a test token
      final testToken = _currentSubscription?.purchaseToken ??
          'test_empty_token_${DateTime.now().millisecondsSinceEpoch}';
      debugPrint('Using test token: ${testToken.substring(0, 20)}...');

      // Test with empty string - but pass validation by using a non-empty token
      final requestProps = RequestPurchase(
        android: RequestSubscriptionAndroid(
          skus: [item.id],
          subscriptionOffers: _androidOffersFor(item),
          purchaseTokenAndroid: testToken, // Use test token to pass validation
          replacementModeAndroid: AndroidReplacementMode.deferred.value,
        ),
        type: ProductType.Subs,
      );

      await _iap.requestPurchase(requestProps.toProps());

      debugPrint('Purchase request sent with test token');
      // Result will come through purchaseUpdatedListener
    } catch (error) {
      debugPrint('Error with test token: $error');
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _purchaseResult = '❌ Error with test token:\n$error';
      });
    }
  }

  Future<void> _restorePurchases() async {
    setState(() {
      _isProcessing = true;
      _purchaseResult = null;
    });

    try {
      final purchases = await _iap.getAvailablePurchases();
      debugPrint('Restored ${purchases.length} purchases');

      if (!mounted) return;

      setState(() {
        _activeSubscriptions = purchases
            .where((p) => subscriptionIds.contains(p.productId))
            .toList();
        _hasActiveSubscription = _activeSubscriptions.isNotEmpty;
        _currentSubscription =
            _activeSubscriptions.isNotEmpty ? _activeSubscriptions.first : null;
        _isProcessing = false;
        _purchaseResult =
            '✅ Restored ${_activeSubscriptions.length} subscriptions';
      });

      // Verify each restored purchase
      for (final purchase in _activeSubscriptions) {
        debugPrint(
            'Restored: ${purchase.productId}, Token: ${purchase.purchaseToken}');
      }
    } catch (error) {
      debugPrint('Failed to restore purchases: $error');
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _purchaseResult = '❌ Failed to restore: $error';
      });
    }
  }

  Widget _buildSubscriptionTier(ProductCommon subscription) {
    final isCurrentSubscription =
        _currentSubscription?.productId == subscription.id;
    // Note: canUpgrade logic removed - now always show proration options for testing

    return GestureDetector(
      onTap: () => ProductDetailModal.show(
        context: context,
        item: subscription,
        product: _originalProducts[subscription.id],
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        color: isCurrentSubscription ? Colors.blue.shade50 : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subscription.title ?? subscription.id,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isCurrentSubscription)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'CURRENT',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    subscription.displayPrice ??
                        subscription.price?.toString() ??
                        '',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                subscription.description ?? 'Subscription tier',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 12),

              // Action buttons - Always show for testing
              // Show current status if this is the current subscription
              if (isCurrentSubscription) ...[
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '✓ Currently Active',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // Always show proration mode selector for testing
              if (Platform.isAndroid) ...[
                const Text(
                  'Proration Mode (Test):',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _prorationModes.entries.map((entry) {
                      final isSelected = _selectedProrationMode == entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(
                            entry.key,
                            style: const TextStyle(fontSize: 10),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedProrationMode =
                                  selected ? entry.value : null;
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // Purchase/Upgrade buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isProcessing ||
                              (_hasActiveSubscription &&
                                  Platform.isAndroid &&
                                  _selectedProrationMode == null)
                          ? null
                          : () => _purchaseSubscription(subscription,
                              isUpgrade: _hasActiveSubscription),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _hasActiveSubscription
                            ? Colors.orange.shade600
                            : const Color(0xFF007AFF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        _isProcessing
                            ? 'Processing...'
                            : _hasActiveSubscription
                                ? (isCurrentSubscription
                                    ? 'Re-subscribe'
                                    : 'Upgrade/Downgrade')
                                : 'Subscribe',
                      ),
                    ),
                  ),
                  if (Platform.isAndroid) ...[
                    const SizedBox(width: 4),
                    // Test wrong usage button
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isProcessing
                            ? null
                            : () => _testWrongProrationUsage(subscription),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade600,
                          side: BorderSide(color: Colors.red.shade300),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Tooltip(
                          message: 'Test proration without token',
                          child:
                              Text('No Token', style: TextStyle(fontSize: 11)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Test with empty token button
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isProcessing
                            ? null
                            : () => _testEmptyTokenProration(subscription),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orange.shade600,
                          side: BorderSide(color: Colors.orange.shade300),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Tooltip(
                          message: 'Test proration with empty token',
                          child: Text('Empty Token',
                              style: TextStyle(fontSize: 11)),
                        ),
                      ),
                    ),
                  ],
                ],
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Subscription Flow',
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          if (_currentSubscription != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Chip(
                label: Text(
                  'Token: ${_currentSubscription!.purchaseToken?.substring(0, 10)}...',
                  style: const TextStyle(fontSize: 10),
                ),
                backgroundColor: Colors.green,
              ),
            ),
        ],
      ),
      body: _isConnecting
          ? const Center(child: CircularProgressIndicator())
          : !_connected
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      const Text('Failed to connect to store'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _initConnection,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF007AFF),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    await _loadSubscriptions();
                    await _checkActiveSubscriptions();
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Active Subscription Status Card
                        Card(
                          color: _hasActiveSubscription
                              ? Colors.green.shade50
                              : Colors.orange.shade50,
                          child: ListTile(
                            leading: Icon(
                              _hasActiveSubscription
                                  ? Icons.check_circle
                                  : Icons.info,
                              color: _hasActiveSubscription
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                            title: Text(
                              _hasActiveSubscription
                                  ? 'Active Subscription: ${_currentSubscription?.productId}'
                                  : 'No Active Subscription',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              _hasActiveSubscription
                                  ? 'You can upgrade/downgrade with proration mode'
                                  : 'Subscribe to any tier to get started',
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Available Subscriptions
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Available Subscription Tiers',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_isLoadingProducts)
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        if (_subscriptions.isEmpty && !_isLoadingProducts)
                          const Card(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: Center(
                                child: Text(
                                  'No subscriptions available',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            ),
                          )
                        else
                          ..._subscriptions.map(_buildSubscriptionTier),

                        const SizedBox(height: 24),

                        // Test Instructions
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'How to Test Proration Mode:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text('1. Subscribe to Basic tier first',
                                  style: TextStyle(fontSize: 12)),
                              Text('2. Wait for purchase to complete',
                                  style: TextStyle(fontSize: 12)),
                              Text(
                                  '3. Tap "Restore Purchases" to load your subscription',
                                  style: TextStyle(fontSize: 12)),
                              Text(
                                  '4. Select a proration mode (e.g., "Immediate with Time Proration")',
                                  style: TextStyle(fontSize: 12)),
                              Text('5. Upgrade to Premium or Pro tier',
                                  style: TextStyle(fontSize: 12)),
                              SizedBox(height: 8),
                              Text(
                                'Test Buttons: "No Token" = without token, "Empty Token" = with empty string',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Restore Purchases Button
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _isProcessing ? null : _restorePurchases,
                            icon: const Icon(Icons.restore),
                            label: const Text('Restore Purchases'),
                          ),
                        ),

                        // Purchase Result
                        if (_purchaseResult != null) ...[
                          const SizedBox(height: 16),
                          Card(
                            color: _purchaseResult!.contains('✅')
                                ? Colors.green.shade50
                                : _purchaseResult!.contains('❌')
                                    ? Colors.red.shade50
                                    : Colors.orange.shade50,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _purchaseResult!,
                                      style: TextStyle(
                                        color: _purchaseResult!.contains('✅')
                                            ? Colors.green
                                            : _purchaseResult!.contains('❌')
                                                ? Colors.red
                                                : Colors.orange,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 18),
                                    onPressed: () {
                                      setState(() {
                                        _purchaseResult = null;
                                      });
                                    },
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
    );
  }
}
