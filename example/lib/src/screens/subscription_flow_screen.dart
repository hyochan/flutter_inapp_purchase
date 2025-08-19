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
    'dev.hyo.martie.basic', // Basic tier
    'dev.hyo.martie.premium', // Premium tier
    'dev.hyo.martie.pro', // Pro tier
  ];

  List<IAPItem> _subscriptions = [];
  final Map<String, BaseProduct> _originalProducts = {};
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
        print('🎯 Purchase updated: ${purchase.productId}');
        print('  Platform: ${purchase.platform}');
        print('  Purchase state: ${purchase.purchaseState}');
        print('  Purchase state Android: ${purchase.purchaseStateAndroid}');
        print('  Transaction state iOS: ${purchase.transactionStateIOS}');
        print('  Is acknowledged: ${purchase.isAcknowledgedAndroid}');
        print('  Transaction ID: ${purchase.transactionId}');
        print('  Purchase token: ${purchase.purchaseToken}');
        print('  Auto renewing: ${purchase.autoRenewingAndroid}');

        if (!mounted) {
          print('  ⚠️ Widget not mounted, ignoring update');
          return;
        }

        // Check for duplicate processing
        final transactionId =
            purchase.transactionId ?? purchase.purchaseToken ?? '';
        if (transactionId.isNotEmpty &&
            _processedTransactionIds.contains(transactionId)) {
          print('  ⚠️ Transaction already processed: $transactionId');
          return;
        }

        // Handle the purchase - check multiple conditions
        // purchaseState.purchased or purchaseStateAndroid == 1 or isAcknowledgedAndroid == false (new purchase)
        bool isPurchased = false;

        if (Platform.isAndroid) {
          // For Android, check multiple conditions since fields can be null
          bool condition1 = purchase.purchaseState == PurchaseState.purchased;
          bool condition2 = (purchase.isAcknowledgedAndroid == false &&
              purchase.purchaseToken != null &&
              purchase.purchaseToken!.isNotEmpty);
          bool condition3 = purchase.purchaseStateAndroid == 1;

          print('  Android condition checks:');
          print('    purchaseState == purchased: $condition1');
          print('    unacknowledged with token: $condition2');
          print('    purchaseStateAndroid == 1: $condition3');

          isPurchased = condition1 || condition2 || condition3;
          print('  Final isPurchased: $isPurchased');
        } else {
          // For iOS - simpler logic like purchase_flow_screen.dart
          // iOS purchase updates with valid tokens indicate successful purchases
          bool condition1 =
              purchase.transactionStateIOS == TransactionState.purchased;
          bool condition2 = purchase.purchaseToken != null &&
              purchase.purchaseToken!.isNotEmpty;
          bool condition3 = purchase.transactionId != null &&
              purchase.transactionId!.isNotEmpty;

          print('  iOS condition checks:');
          print('    transactionStateIOS == purchased: $condition1');
          print('    has valid purchaseToken: $condition2');
          print('    has valid transactionId: $condition3');

          // For iOS, receiving a purchase update usually means success
          // especially if we have either a valid token OR transaction ID
          isPurchased = condition1 || condition2 || condition3;
          print('  Final isPurchased: $isPurchased');
        }

        if (isPurchased) {
          print('✅ Purchase detected as successful, updating UI...');
          print('  _isProcessing before setState: $_isProcessing');

          // Mark as processed
          if (transactionId.isNotEmpty) {
            _processedTransactionIds.add(transactionId);
          }

          // Update UI immediately
          if (mounted) {
            setState(() {
              _purchaseResult = '✅ Purchase successful: ${purchase.productId}';
              _isProcessing = false;
            });
            print('  _isProcessing after setState: $_isProcessing');
            print('  UI should be updated now');
          } else {
            print('  ⚠️ Widget not mounted, cannot update UI');
          }

          // Acknowledge/finish the transaction
          try {
            print('Calling finishTransaction...');
            await _iap.finishTransaction(purchase);
            print('Transaction finished successfully');
          } catch (e) {
            print('Error finishing transaction: $e');
          }

          // Refresh subscriptions after a short delay to ensure transaction is processed
          await Future<void>.delayed(const Duration(milliseconds: 500));
          print('Refreshing subscriptions...');
          await _checkActiveSubscriptions();
          print('Subscriptions refreshed');
        } else if (purchase.purchaseState == PurchaseState.pending ||
            purchase.purchaseStateAndroid == 0) {
          // Pending
          setState(() {
            _purchaseResult = '⏳ Purchase pending: ${purchase.productId}';
          });
        } else {
          // Unknown state - log for debugging
          print('❓ Unknown purchase state');
          print('  Purchase state: ${purchase.purchaseState}');
          print('  Transaction state iOS: ${purchase.transactionStateIOS}');
          print('  Purchase state Android: ${purchase.purchaseStateAndroid}');
          print(
              '  Has token: ${purchase.purchaseToken != null && purchase.purchaseToken!.isNotEmpty}');

          setState(() {
            _isProcessing = false;
            _purchaseResult = '''
⚠️ Purchase received but state unknown
Platform: ${purchase.platform}
Purchase state: ${purchase.purchaseState}
iOS transaction state: ${purchase.transactionStateIOS}
Android purchase state: ${purchase.purchaseStateAndroid}
Has token: ${purchase.purchaseToken != null && purchase.purchaseToken!.isNotEmpty}
            '''
                .trim();
          });
        }
      },
      onError: (Object error) {
        print('Purchase stream error: $error');
        setState(() {
          _isProcessing = false;
          _purchaseResult = '❌ Stream error: $error';
        });
      },
    );

    // Listen to purchase errors
    _purchaseErrorSubscription = _iap.purchaseErrorListener.listen(
      (error) {
        print('Purchase error: ${error.code} - ${error.message}');

        if (!mounted) return;

        setState(() {
          _isProcessing = false;
          if (error.code == ErrorCode.eUserCancelled) {
            _purchaseResult = '⚠️ Purchase cancelled';
          } else {
            _purchaseResult = '❌ Error: ${error.message}';
          }
        });
      },
      onError: (Object error) {
        print('Error stream error: $error');
      },
    );
  }

  Future<void> _initConnection() async {
    try {
      final result = await _iap.initConnection();
      print('Connection initialized: $result');

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
      print('Failed to initialize connection: $error');
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
      // Use the new requestProducts method
      final params = RequestProductsParams(
        productIds: subscriptionIds,
        type: PurchaseType.subs,
      );

      final products = await _iap.requestProducts(params);

      print('Loaded ${products.length} subscriptions');

      if (!mounted) return;

      setState(() {
        _subscriptions = products.map((baseProduct) {
          // Store the original BaseProduct for detailed view
          _originalProducts[baseProduct.productId] = baseProduct;

          // Convert BaseProduct to IAPItem for compatibility
          final itemMap = <String, dynamic>{
            'productId': baseProduct.productId,
            'price': baseProduct.price,
            'currency': baseProduct.currency,
            'localizedPrice': baseProduct.localizedPrice,
            'title': baseProduct.title,
            'description': baseProduct.description,
          };

          // Add subscription-specific fields if available
          if (baseProduct is Subscription) {
            itemMap['subscriptionPeriodUnitIOS'] =
                baseProduct.subscriptionPeriodUnitIOS;
            itemMap['subscriptionPeriodNumberIOS'] =
                baseProduct.subscriptionPeriodNumberIOS;
            itemMap['introductoryPricePaymentModeIOS'] =
                baseProduct.introductoryPricePaymentModeIOS;
            itemMap['subscriptionGroupIdIOS'] =
                baseProduct.subscriptionGroupIdIOS;
            if (baseProduct.discountsIOS != null) {
              itemMap['discountsIOS'] = baseProduct.discountsIOS!
                  .map((d) => {
                        'identifier': d.identifier,
                        'type': d.type,
                        'price': d.price,
                        'localizedPrice': d.localizedPrice,
                        'numberOfPeriods': d.numberOfPeriods,
                        'subscriptionPeriod': d.subscriptionPeriod,
                        'paymentMode': d.paymentMode,
                      })
                  .toList();
            }
          }

          return IAPItem.fromJSON(itemMap);
        }).toList();
        _isLoadingProducts = false;
      });
    } catch (error) {
      print('Failed to load subscriptions: $error');
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

      print('=== Checking Active Subscriptions ===');
      print('Total purchases found: ${purchases.length}');
      for (var p in purchases) {
        print(
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
          print('Current subscription: ${_currentSubscription!.productId}');
          print('Purchase token: ${_currentSubscription!.purchaseToken}');
          _purchaseResult =
              'Active: ${_currentSubscription!.productId}\nToken: ${_currentSubscription!.purchaseToken?.substring(0, 30)}...';
        } else {
          print('No active subscription found in filtered list');
        }
      });
    } catch (error) {
      print('Failed to check active subscriptions: $error');
      setState(() {
        _purchaseResult = '❌ Error checking subscriptions: $error';
      });
    }
  }

  Future<void> _purchaseSubscription(IAPItem item,
      {bool isUpgrade = false}) async {
    if (_isProcessing) {
      print('⚠️ Already processing a purchase, ignoring');
      return;
    }

    print('🛒 Starting subscription purchase: ${item.productId}');
    print('  isUpgrade: $isUpgrade');
    print('  Current subscription: ${_currentSubscription?.productId}');

    setState(() {
      _isProcessing = true;
      _purchaseResult = null;
    });
    print('  Set _isProcessing to true');

    try {
      // Check for Android offers
      SubscriptionOfferAndroid? selectedOffer;
      if (Platform.isAndroid && item.subscriptionOffersAndroid != null) {
        final offers = item.subscriptionOffersAndroid!;
        if (offers.isNotEmpty) {
          selectedOffer = offers.first;
          print('Using offer token: ${selectedOffer.offerToken}');
        }
      }

      // Request subscription using the new API
      if (Platform.isAndroid) {
        // Check if this is an upgrade/downgrade
        if (isUpgrade &&
            _currentSubscription != null &&
            _selectedProrationMode != null) {
          // This is an upgrade/downgrade with proration
          print(
              'Upgrading subscription with proration mode: $_selectedProrationMode');
          print('Using purchase token: ${_currentSubscription!.purchaseToken}');

          final request = RequestPurchase(
            android: RequestSubscriptionAndroid(
              skus: [item.productId!],
              subscriptionOffers: selectedOffer != null ? [selectedOffer] : [],
              purchaseTokenAndroid: _currentSubscription!.purchaseToken,
              replacementModeAndroid: _selectedProrationMode,
            ),
          );

          await _iap.requestPurchase(
            request: request,
            type: PurchaseType.subs,
          );
        } else {
          // This is a new subscription purchase
          print('Purchasing new subscription');

          final request = RequestPurchase(
            android: RequestSubscriptionAndroid(
              skus: [item.productId!],
              subscriptionOffers: selectedOffer != null ? [selectedOffer] : [],
            ),
          );

          await _iap.requestPurchase(
            request: request,
            type: PurchaseType.subs,
          );
        }
      } else {
        // iOS
        final request = RequestPurchase(
          ios: RequestPurchaseIOS(
            sku: item.productId!,
          ),
        );

        await _iap.requestPurchase(
          request: request,
          type: PurchaseType.subs,
        );
      }

      // Result will be handled by the purchase stream listeners
      print('Purchase request sent, waiting for response...');
    } catch (error) {
      print('Failed to request subscription: $error');
      setState(() {
        _isProcessing = false;
        _purchaseResult = '❌ Failed to request: $error';
      });
    }
  }

  // Test with fake/invalid token (should fail on native side)
  Future<void> _testWrongProrationUsage(IAPItem item) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _purchaseResult = null;
    });

    try {
      print(
          'Testing proration mode with FAKE purchaseToken (should fail on native side)');

      // Use a fake/invalid token to test native validation
      final fakeToken =
          'fake_token_for_testing_${DateTime.now().millisecondsSinceEpoch}';
      print('Using fake token: $fakeToken');

      final request = RequestPurchase(
        android: RequestSubscriptionAndroid(
          skus: [item.productId!],
          subscriptionOffers: item.subscriptionOffersAndroid ?? [],
          purchaseTokenAndroid:
              fakeToken, // Fake token that will fail on native side
          replacementModeAndroid: AndroidProrationMode.deferred.value,
        ),
      );

      await _iap.requestPurchase(
        request: request,
        type: PurchaseType.subs,
      );

      // If we get here, the purchase was attempted
      print('Purchase request sent with fake token');
      // Result will come through purchaseUpdatedListener
    } catch (error) {
      print('Error with fake token: $error');
      setState(() {
        _isProcessing = false;
        _purchaseResult = '❌ Error with fake token:\n$error';
      });
    }
  }

  // Test with empty purchaseToken (Issue #529)
  Future<void> _testEmptyTokenProration(IAPItem item) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _purchaseResult = null;
    });

    try {
      print('Testing proration mode with EMPTY string purchaseToken');

      // Use current subscription token if available, otherwise use a test token
      final testToken = _currentSubscription?.purchaseToken ??
          'test_empty_token_${DateTime.now().millisecondsSinceEpoch}';
      print('Using test token: ${testToken.substring(0, 20)}...');

      // Test with empty string - but pass validation by using a non-empty token
      final request = RequestPurchase(
        android: RequestSubscriptionAndroid(
          skus: [item.productId!],
          subscriptionOffers: item.subscriptionOffersAndroid ?? [],
          purchaseTokenAndroid: testToken, // Use test token to pass validation
          replacementModeAndroid: AndroidProrationMode.deferred.value,
        ),
      );

      await _iap.requestPurchase(
        request: request,
        type: PurchaseType.subs,
      );

      print('Purchase request sent with test token');
      // Result will come through purchaseUpdatedListener
    } catch (error) {
      print('Error with test token: $error');
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
      print('Restored ${purchases.length} purchases');

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
        print(
            'Restored: ${purchase.productId}, Token: ${purchase.purchaseToken}');
      }
    } catch (error) {
      print('Failed to restore purchases: $error');
      setState(() {
        _isProcessing = false;
        _purchaseResult = '❌ Failed to restore: $error';
      });
    }
  }

  Widget _buildSubscriptionTier(IAPItem subscription) {
    final isCurrentSubscription =
        _currentSubscription?.productId == subscription.productId;
    // Note: canUpgrade logic removed - now always show proration options for testing

    return GestureDetector(
      onTap: () => ProductDetailModal.show(
        context: context,
        item: subscription,
        product: _originalProducts[subscription.productId ?? ''],
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
                          subscription.title ??
                              subscription.productId ??
                              'Subscription',
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
                    subscription.localizedPrice ?? subscription.price ?? '',
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
