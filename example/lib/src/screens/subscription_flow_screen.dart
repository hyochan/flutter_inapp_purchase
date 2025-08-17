import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

class SubscriptionFlowScreen extends StatefulWidget {
  const SubscriptionFlowScreen({Key? key}) : super(key: key);

  @override
  State<SubscriptionFlowScreen> createState() => _SubscriptionFlowScreenState();
}

class _SubscriptionFlowScreenState extends State<SubscriptionFlowScreen> {
  final FlutterInappPurchase _iap = FlutterInappPurchase.instance;

  // Subscription IDs
  final List<String> subscriptionIds = [
    'dev.hyo.martie.premium',
  ];

  List<IAPItem> _subscriptions = [];
  List<Purchase> _activeSubscriptions = [];
  List<ActiveSubscription> _activeSubscriptionDetails = [];
  bool _hasActiveSubscription = false;
  bool _isProcessing = false;
  bool _connected = false;
  bool _isConnecting = true;
  bool _isLoadingProducts = false;
  String? _purchaseResult;
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
      _isConnecting = true;
    });

    try {
      // Step 1: Initialize connection
      final connectionResult = await _iap.initConnection();
      setState(() {
        _connected = connectionResult == true;
      });

      if (!_connected) {
        debugPrint('Failed to connect to store');
        return;
      }

      // Step 2: Connection successful, setup listeners and load products
      _setupPurchaseListeners();

      setState(() {
        _isConnecting = false;
        _isLoadingProducts = true;
      });

      // Load active purchases and subscription products in parallel
      await Future.wait([
        _loadActiveSubscriptions(),
        _loadSubscriptions(),
      ]);
    } catch (e) {
      debugPrint('Failed to initialize IAP connection: $e');
      setState(() {
        _purchaseResult = 'Initialization error: $e';
        _connected = false;
      });
    } finally {
      setState(() {
        _isConnecting = false;
        _isLoadingProducts = false;
      });
    }
  }

  void _setupPurchaseListeners() {
    debugPrint('Setting up subscription purchase listeners...');

    // Listen to purchase updates
    _purchaseUpdatedSubscription = _iap.purchaseUpdatedListener.listen(
      (purchase) {
        debugPrint('🎉 Subscription update received!');
        debugPrint('ProductId: ${purchase.productId}');
        debugPrint('TransactionId: ${purchase.transactionId}');
        _handlePurchaseUpdate(purchase);
      },
      onError: (Object error) {
        debugPrint('❌ Subscription stream error: $error');
      },
    );

    // Listen to purchase errors
    _purchaseErrorSubscription = _iap.purchaseErrorListener.listen(
      (purchaseError) {
        debugPrint('❌ Subscription error received!');
        debugPrint('Error code: ${purchaseError.code}');
        debugPrint('Error message: ${purchaseError.message}');
        _handlePurchaseError(purchaseError);
      },
    );

    debugPrint('Subscription listeners setup complete');
  }

  Future<void> _handlePurchaseUpdate(Purchase purchase) async {
    debugPrint('Subscription successful: ${purchase.productId}');

    // Debug purchase object structure
    debugPrint('🔍 Purchase object debug:');
    debugPrint('  productId: ${purchase.productId}');
    debugPrint('  transactionId: ${purchase.transactionId}');
    debugPrint('  purchaseToken: ${purchase.purchaseToken}');
    debugPrint(
        '  transactionReceipt: ${purchase.transactionReceipt?.substring(0, 50)}...');
    debugPrint('  transactionDate: ${purchase.transactionDate}');
    debugPrint('  isAcknowledgedAndroid: ${purchase.isAcknowledgedAndroid}');

    setState(() {
      _isProcessing = false;

      // Format subscription result like KMP-IAP
      _purchaseResult = '''
✅ Subscription successful (${Platform.operatingSystem})
Product: ${purchase.productId}
Transaction ID: ${purchase.transactionId ?? "N/A"}
Date: ${purchase.transactionDate ?? "N/A"}
Receipt: ${purchase.transactionReceipt?.substring(0, purchase.transactionReceipt!.length > 50 ? 50 : purchase.transactionReceipt!.length)}...
      '''
          .trim();
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
    // For subscriptions, set isConsumable to false

    // Skip transaction finishing for invalid transaction IDs
    // Real products should still try, but handle errors gracefully
    bool shouldSkipFinish = purchase.transactionId == null ||
        purchase.transactionId!.isEmpty ||
        // Skip obvious test transaction IDs
        purchase.transactionId == '3' ||
        // Skip very short transaction IDs that are clearly invalid
        purchase.transactionId!.length < 3;

    if (shouldSkipFinish) {
      debugPrint('🔧 Skipping transaction finish in development environment');
      debugPrint('Transaction ID: ${purchase.transactionId}');

      // Still reload active subscriptions and update UI
      await _loadActiveSubscriptions();

      setState(() {
        _purchaseResult =
            '$_purchaseResult\n\n✅ Purchase successful (development mode - transaction finish skipped)';

        // Update active subscriptions list
        if (subscriptionIds.contains(purchase.productId)) {
          if (!_activeSubscriptions
              .any((p) => p.productId == purchase.productId)) {
            _activeSubscriptions.add(purchase);
          }
        }
      });
      return;
    }

    try {
      debugPrint(
          'Attempting to finish transaction with ID: ${purchase.transactionId}');
      debugPrint('Purchase token: ${purchase.purchaseToken}');

      await _iap.finishTransaction(purchase, isConsumable: false);
      debugPrint('Subscription transaction finished successfully');

      // Reload active subscriptions with new API
      await _loadActiveSubscriptions();

      setState(() {
        _purchaseResult =
            '$_purchaseResult\n\n✅ Transaction finished successfully';

        // Update active subscriptions list
        if (subscriptionIds.contains(purchase.productId)) {
          if (!_activeSubscriptions
              .any((p) => p.productId == purchase.productId)) {
            _activeSubscriptions.add(purchase);
          }
        }
      });
    } catch (e) {
      debugPrint('Error finishing subscription transaction: $e');

      // For development/testing, transaction finish errors are often not critical
      // The purchase is still valid, just the cleanup failed
      if (e.toString().contains('Transaction not found') ||
          e.toString().contains('E_TRANSACTION_NOT_FOUND')) {
        debugPrint(
            '⚠️ Transaction finish failed (common in development), but purchase is valid');

        // Still reload active subscriptions and update UI
        await _loadActiveSubscriptions();

        setState(() {
          _purchaseResult =
              '$_purchaseResult\n\n⚠️ Purchase successful but transaction cleanup failed (common in development)';

          // Update active subscriptions list
          if (subscriptionIds.contains(purchase.productId)) {
            if (!_activeSubscriptions
                .any((p) => p.productId == purchase.productId)) {
              _activeSubscriptions.add(purchase);
            }
          }
        });
      } else {
        setState(() {
          _purchaseResult =
              '$_purchaseResult\n\n❌ Failed to finish transaction: $e';
        });
      }
    }
  }

  void _handlePurchaseError(PurchaseError error) {
    setState(() {
      _isProcessing = false;

      // Format error result like KMP-IAP
      if (error.code == ErrorCode.eUserCancelled) {
        _purchaseResult = '⚠️ Subscription cancelled by user';
      } else {
        _purchaseResult = '''
❌ Error: ${error.message}
Code: ${error.code}
Platform: ${error.platform}
        '''
            .trim();
      }
    });
  }

  Future<void> _loadActiveSubscriptions() async {
    try {
      // Load purchases for restore/finish transaction purposes
      final purchases = await _iap.getAvailablePurchases();

      // Use new APIs to get detailed subscription information
      final activeSubscriptions = await _iap.getActiveSubscriptions(
        subscriptionIds: subscriptionIds,
      );
      final hasActive = await _iap.hasActiveSubscriptions(
        subscriptionIds: subscriptionIds,
      );

      setState(() {
        _activeSubscriptions = purchases
            .where((p) => subscriptionIds.contains(p.productId))
            .toList();
        _activeSubscriptionDetails = activeSubscriptions;
        _hasActiveSubscription = hasActive;
      });

      debugPrint('Loaded ${_activeSubscriptions.length} active subscriptions');
      debugPrint('Has active subscription: $_hasActiveSubscription');

      // Log detailed subscription info
      for (final sub in _activeSubscriptionDetails) {
        debugPrint('Active subscription: ${sub.productId}');
        if (Platform.isIOS && sub.expirationDateIOS != null) {
          debugPrint('  Expires: ${sub.expirationDateIOS}');
          debugPrint('  Days until expiration: ${sub.daysUntilExpirationIOS}');
          debugPrint('  Environment: ${sub.environmentIOS}');
        }
        if (Platform.isAndroid && sub.autoRenewingAndroid != null) {
          debugPrint('  Auto-renewing: ${sub.autoRenewingAndroid}');
        }
        if (sub.willExpireSoon == true) {
          debugPrint('  ⚠️ Will expire soon!');
        }
      }
    } catch (e) {
      debugPrint('Failed to load active subscriptions: $e');
    }
  }

  Future<void> _loadSubscriptions() async {
    if (!_connected) return;

    try {
      debugPrint(
          'Loading subscriptions for IDs: ${subscriptionIds.join(", ")}');
      final subscriptions = await _iap.getSubscriptions(subscriptionIds);
      setState(() {
        _subscriptions = subscriptions;
      });

      if (_subscriptions.isEmpty) {
        setState(() {
          _purchaseResult =
              'No subscriptions found for IDs: ${subscriptionIds.join(", ")}';
        });
      } else {
        debugPrint('Loaded ${_subscriptions.length} subscription products');
      }
    } catch (e) {
      debugPrint('Error loading subscriptions: $e');
      setState(() {
        _purchaseResult = 'Failed to load subscriptions: $e';
      });
    }
  }

  Future<void> _refreshSubscriptions() async {
    setState(() {
      _isLoadingProducts = true;
    });

    try {
      await Future.wait([
        _loadActiveSubscriptions(),
        _loadSubscriptions(),
      ]);
    } catch (e) {
      debugPrint('Failed to refresh subscriptions: $e');
    } finally {
      setState(() {
        _isLoadingProducts = false;
      });
    }
  }

  Future<void> _restorePurchases() async {
    setState(() {
      _isProcessing = true;
      _purchaseResult = null;
    });

    try {
      debugPrint('🔄 Restoring purchases...');

      // Get all available purchases (restored)
      final restoredPurchases = await _iap.getAvailablePurchases();

      // Load active subscriptions with new API
      await _loadActiveSubscriptions();

      if (_activeSubscriptionDetails.isNotEmpty) {
        setState(() {
          _purchaseResult = '''
✅ Purchases restored successfully!
Found ${_activeSubscriptionDetails.length} active subscription(s):
${_activeSubscriptionDetails.map((sub) => '• ${sub.productId}').join('\n')}
          '''
              .trim();
        });
      } else if (restoredPurchases.isNotEmpty) {
        setState(() {
          _purchaseResult = '''
✅ Restored ${restoredPurchases.length} purchase(s)
${restoredPurchases.map((p) => '• ${p.productId}').join('\n')}
          '''
              .trim();
        });
      } else {
        setState(() {
          _purchaseResult = 'No purchases to restore';
        });
      }

      debugPrint('✅ Restore completed');
    } catch (e) {
      debugPrint('❌ Restore failed: $e');
      setState(() {
        _purchaseResult = '❌ Failed to restore purchases: $e';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _handleSubscribe(String productId) async {
    debugPrint('🛒 Starting subscription for: $productId');
    setState(() {
      _isProcessing = true;
      _purchaseResult = null;
    });

    try {
      debugPrint('Requesting subscription purchase...');
      await _iap.requestPurchase(
        request: RequestPurchase(
          ios: RequestPurchaseIOS(
            sku: productId,
          ),
          android: RequestSubscriptionAndroid(
            skus: [productId],
            subscriptionOffers: [],
          ),
        ),
        type: PurchaseType.subs,
      );
      debugPrint('✅ Subscription request sent successfully');
      // Note: The actual subscription result will come through the purchaseUpdatedListener
    } catch (error) {
      setState(() {
        _isProcessing = false;
        _purchaseResult = 'Subscription failed: $error';
      });
      debugPrint('❌ Subscription request error: $error');
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
          'Subscription Flow',
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          IconButton(
            icon: _isLoadingProducts
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh, color: Colors.black),
            onPressed: _isLoadingProducts ? null : _refreshSubscriptions,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Status Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _connected ? Colors.green[50] : Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                if (_isConnecting)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(
                    _connected ? Icons.check_circle : Icons.error,
                    color: _connected ? Colors.green : Colors.red,
                  ),
                const SizedBox(width: 8),
                Text(
                  _isConnecting
                      ? 'Connecting...'
                      : (_connected ? '✓ Connected to Store' : 'Not connected'),
                  style: TextStyle(
                    color: _connected ? Colors.green : Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Active Subscription Status
          if (_hasActiveSubscription &&
              _activeSubscriptionDetails.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle,
                          color: Colors.green[700], size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'Active Subscription',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._activeSubscriptionDetails.map((sub) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Product: ${sub.productId}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          if (Platform.isIOS &&
                              sub.expirationDateIOS != null) ...[
                            Text(
                                'Expires: ${sub.expirationDateIOS!.toLocal()}'),
                            if (sub.daysUntilExpirationIOS != null)
                              Text(
                                  'Days until expiration: ${sub.daysUntilExpirationIOS}'),
                            if (sub.environmentIOS != null)
                              Text('Environment: ${sub.environmentIOS}'),
                          ],
                          if (Platform.isAndroid &&
                              sub.autoRenewingAndroid != null)
                            Text(
                                'Auto-renewing: ${sub.autoRenewingAndroid! ? "Yes" : "No"}'),
                          if (sub.willExpireSoon == true)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange[100],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '⚠️ Will expire soon',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange[800],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          const SizedBox(height: 8),
                        ],
                      )),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Subscriptions Section Title
          const Text(
            'Available Subscriptions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),

          // Subscriptions
          if (_isLoadingProducts)
            Card(
              child: Container(
                padding: const EdgeInsets.all(24),
                alignment: Alignment.center,
                child: const CircularProgressIndicator(),
              ),
            )
          else if (_subscriptions.isEmpty)
            Card(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _connected
                      ? 'No subscriptions available'
                      : 'Connect to load subscriptions',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            )
          else
            ..._subscriptions.map((subscription) {
              final isSubscribed = _activeSubscriptions
                  .any((p) => p.productId == subscription.productId);
              final activeDetail = _activeSubscriptionDetails.firstWhere(
                (sub) => sub.productId == subscription.productId,
                orElse: () => ActiveSubscription(
                  productId: '',
                  isActive: false,
                ),
              );

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  subscription.title ??
                                      subscription.productId ??
                                      '',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  subscription.description ?? '',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                if (Platform.isAndroid &&
                                    subscription.subscriptionPeriodAndroid !=
                                        null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Period: ${subscription.subscriptionPeriodAndroid}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 4),
                                Text(
                                  'ID: ${subscription.productId}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontFamily: 'monospace',
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                subscription.localizedPrice ?? '',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF007AFF),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Show subscribed status badge if active
                      if (isSubscribed)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                '✓ Subscribed',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (activeDetail.isActive &&
                                  activeDetail.productId ==
                                      subscription.productId) ...[
                                const SizedBox(height: 8),
                                if (Platform.isIOS &&
                                    activeDetail.expirationDateIOS != null)
                                  Text(
                                    'Expires: ${activeDetail.expirationDateIOS!.toLocal().toString().split('.')[0]}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                if (Platform.isAndroid &&
                                    activeDetail.autoRenewingAndroid != null)
                                  Text(
                                    activeDetail.autoRenewingAndroid!
                                        ? 'Auto-renewing'
                                        : 'Not auto-renewing',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                              ],
                            ],
                          ),
                        )
                      else
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isProcessing || !_connected
                                ? null
                                : () =>
                                    _handleSubscribe(subscription.productId!),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF007AFF),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              _isProcessing ? 'Processing...' : 'Subscribe',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),

          // Restore Purchases Button
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: _isProcessing || !_connected ? null : _restorePurchases,
            icon: const Icon(Icons.restore),
            label: Text(_isProcessing ? 'Processing...' : 'Restore Purchases'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),

          // Purchase Result Card (like KMP-IAP)
          if (_purchaseResult != null) ...[
            const SizedBox(height: 20),
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
                          'Subscription Result',
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
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
