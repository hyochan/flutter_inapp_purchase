import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:flutter_inapp_purchase/extensions/purchase_helpers.dart';

import '../widgets/product_detail_modal.dart';
import '../widgets/purchase_detail_view.dart';
import '../constants.dart';

class SubscriptionFlowScreen extends StatefulWidget {
  const SubscriptionFlowScreen({Key? key}) : super(key: key);

  @override
  State<SubscriptionFlowScreen> createState() => _SubscriptionFlowScreenState();
}

class _SubscriptionFlowScreenState extends State<SubscriptionFlowScreen> {
  final FlutterInappPurchase _iap = FlutterInappPurchase.instance;

  // Use subscription IDs from constants
  final List<String> subscriptionIds = IapConstants.subscriptionProductIds;

  List<ProductCommon> _subscriptions = [];
  final Map<String, ProductCommon> _originalProducts = {};
  final Map<String, ActiveSubscription> _activeSubscriptionInfo = {};
  ActiveSubscription? _currentActiveSubscription;
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

  // Proration mode selection (default to Immediate with Time Proration)
  int? _selectedProrationMode = 1;
  final Map<String, int> _prorationModes = {
    'Immediate with Time Proration': 1,
    'Immediate and Charge Prorated Price': 2,
    'Immediate without Proration': 3,
    'Deferred': 4,
    'Immediate and Charge Full Price': 5,
  };

  List<SubscriptionOfferAndroid> _androidOffersFor(ProductCommon item) {
    if (item is ProductAndroid) {
      final details = item.subscriptionOfferDetailsAndroid;
      if (details != null && details.isNotEmpty) {
        return [
          for (final offer in details)
            SubscriptionOfferAndroid(
              offerToken: offer.offerToken,
              // sku must be the productId (SKU), not the basePlanId.
              sku: item.id,
            ),
        ];
      }
    }
    return const <SubscriptionOfferAndroid>[];
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
        final transactionId = purchase.transactionIdFor;
        final androidStateValue = purchase.androidPurchaseStateValue;
        final iosTransactionState = purchase.iosTransactionState;
        final acknowledgedAndroid = purchase.androidIsAcknowledged;
        debugPrint(
            '  Purchase state Android (legacy value): $androidStateValue');
        debugPrint('  Transaction state iOS: $iosTransactionState');
        debugPrint('  Is acknowledged Android: $acknowledgedAndroid');
        debugPrint('  Transaction ID: ${transactionId ?? 'N/A'}');
        final token = purchase.purchaseToken;
        final maskedToken = token == null
            ? 'null'
            : '${token.substring(0, token.length > 10 ? 10 : token.length)}...';
        debugPrint('  Purchase token: $maskedToken');
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

        if (!kIsWeb &&
            defaultTargetPlatform == TargetPlatform.android &&
            purchase is PurchaseAndroid) {
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
            await _iap.finishTransaction(
              purchase: purchase,
            );
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
      // End any existing connection first to reset configuration
      // This ensures we start fresh without alternative billing settings
      try {
        await _iap.endConnection();
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (e) {
        debugPrint('Note: endConnection failed (might not be connected): $e');
      }

      // Initialize with default settings (no alternative billing)
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
      debugPrint('🔄 Loading subscriptions with SKUs: $subscriptionIds');

      // Use explicit type annotation for proper type inference
      final subscriptions = await _iap.fetchProducts<ProductSubscription>(
        skus: subscriptionIds,
        type: ProductQueryType.Subs,
      );

      debugPrint('✅ Loaded ${subscriptions.length} subscriptions');
      for (final sub in subscriptions) {
        debugPrint('  - ${sub.id}: ${sub.title} (${sub.runtimeType})');
      }

      if (!mounted) return;

      setState(() {
        // Store original products
        _originalProducts.clear();
        for (final product in subscriptions) {
          final productKey = product.id;
          _originalProducts[productKey] = product;
        }

        _subscriptions = List.of(subscriptions, growable: false);
        _isLoadingProducts = false;
      });
    } catch (error, stackTrace) {
      debugPrint('💥 Failed to load subscriptions: $error');
      debugPrint('📍 Stack trace: $stackTrace');
      if (!mounted) return;
      setState(() {
        _subscriptions = [];
        _isLoadingProducts = false;
        _purchaseResult = '❌ Failed to load subscriptions: $error';
      });
    }
  }

  Future<void> _checkActiveSubscriptions() async {
    if (!_connected) return;

    try {
      debugPrint('=== Checking Active Subscriptions ===');

      // NOTE: Two approaches for getting active subscriptions:
      //
      // Approach 1 (Recommended): Use getActiveSubscriptions() - works on Google Play
      // final summaries = await _iap.getActiveSubscriptions(subscriptionIds);
      //
      // Approach 2 (Horizon compatible): Use getAvailablePurchases() and filter
      // This approach is used in this example to demonstrate Horizon OS compatibility.
      // Horizon OS doesn't support subscription-specific queries, so we get all
      // purchases and filter for subscriptions manually.
      //
      // For production apps:
      // - Use Approach 1 for Google Play Store
      // - Use Approach 2 for Meta Horizon Store (or when supporting both)
      final allPurchases = await _iap.getAvailablePurchases();
      final subscriptionPurchases = allPurchases
          .where((p) => subscriptionIds.contains(p.productId))
          .toList();

      // Convert to ActiveSubscription format
      final summaries = <ActiveSubscription>[];
      for (final purchase in subscriptionPurchases) {
        // Map platform-specific fields
        final bool? autoRenewing =
            purchase is PurchaseAndroid ? purchase.autoRenewingAndroid : null;
        final String? basePlanId =
            purchase is PurchaseAndroid ? purchase.currentPlanId : null;
        final String? environmentIOS =
            purchase is PurchaseIOS ? purchase.environmentIOS : null;
        final double? expirationDateIOS =
            purchase is PurchaseIOS ? purchase.expirationDateIOS : null;
        final RenewalInfoIOS? renewalInfoIOS =
            purchase is PurchaseIOS ? purchase.renewalInfoIOS : null;

        // Calculate daysUntilExpirationIOS and willExpireSoon for iOS
        double? daysUntilExpirationIOS;
        bool? willExpireSoon;
        if (expirationDateIOS != null) {
          final expirationDate = DateTime.fromMillisecondsSinceEpoch(
            expirationDateIOS.toInt(),
          );
          final now = DateTime.now();
          final daysUntilExpiration = expirationDate.difference(now).inDays;
          daysUntilExpirationIOS = daysUntilExpiration.toDouble();
          // Consider subscription expiring soon if < 7 days remaining
          willExpireSoon = daysUntilExpiration > 0 && daysUntilExpiration < 7;
        }

        // Create ActiveSubscription from Purchase
        summaries.add(ActiveSubscription(
          productId: purchase.productId,
          transactionId:
              purchase.transactionIdFor ?? purchase.purchaseToken ?? '',
          purchaseToken: purchase.purchaseToken,
          transactionDate: purchase.transactionDate is String
              ? double.tryParse(purchase.transactionDate as String) ?? 0.0
              : (purchase.transactionDate as num?)?.toDouble() ?? 0.0,
          isActive: purchase.purchaseState == PurchaseState.Purchased,
          autoRenewingAndroid: autoRenewing,
          basePlanIdAndroid: basePlanId,
          currentPlanId: purchase.currentPlanId,
          daysUntilExpirationIOS: daysUntilExpirationIOS,
          environmentIOS: environmentIOS,
          expirationDateIOS: expirationDateIOS,
          renewalInfoIOS: renewalInfoIOS,
          purchaseTokenAndroid:
              purchase is PurchaseAndroid ? purchase.purchaseToken : null,
          willExpireSoon: willExpireSoon,
        ));
      }

      debugPrint('Active subscription summaries: ${summaries.length}');
      for (final summary in summaries) {
        debugPrint(
          '  • ${summary.productId} (tx: ${summary.transactionId}, autoRenew: ${summary.autoRenewingAndroid})',
        );

        // Log renewalInfoIOS details
        if (summary.renewalInfoIOS != null) {
          final renewal = summary.renewalInfoIOS!;
          debugPrint('    renewalInfo: {');
          debugPrint('      willAutoRenew: ${renewal.willAutoRenew}');
          debugPrint(
              '      pendingUpgradeProductId: ${renewal.pendingUpgradeProductId}');
          debugPrint(
              '      autoRenewPreference: ${renewal.autoRenewPreference}');
          debugPrint(
              '      renewalDate: ${renewal.renewalDate != null ? DateTime.fromMillisecondsSinceEpoch(renewal.renewalDate!.toInt()) : null}');
          debugPrint('      expirationReason: ${renewal.expirationReason}');
          debugPrint('      isInBillingRetry: ${renewal.isInBillingRetry}');
          debugPrint(
              '      gracePeriodExpirationDate: ${renewal.gracePeriodExpirationDate}');
          debugPrint(
              '      priceIncreaseStatus: ${renewal.priceIncreaseStatus}');
          debugPrint('    }');
        }
      }

      // Create map of summaries by product ID
      final Map<String, ActiveSubscription> summaryByProduct = {};
      for (final summary in summaries) {
        summaryByProduct[summary.productId] = summary;
      }

      // Sort by transaction date (most recent first)
      final sortedSummaries = List<ActiveSubscription>.from(summaries)
        ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));

      if (!mounted) return;

      setState(() {
        _activeSubscriptionInfo
          ..clear()
          ..addAll(summaryByProduct);
        _hasActiveSubscription = summaries.isNotEmpty;
        _currentActiveSubscription =
            sortedSummaries.isNotEmpty ? sortedSummaries.first : null;

        if (_currentActiveSubscription != null) {
          debugPrint(
            'Current subscription: ${_currentActiveSubscription!.productId}',
          );

          final summary = _currentActiveSubscription!;
          final buffer = StringBuffer(
            'Active: ${summary.productId}',
          );
          if (summary.expirationDateIOS != null) {
            buffer.write(
              '\nExpires: ${_formatReadableDate(summary.expirationDateIOS!)}',
            );
          }
          if (summary.autoRenewingAndroid != null) {
            buffer.write(
              '\nAuto renew: ${summary.autoRenewingAndroid == true}',
            );
          }
          if (summary.renewalInfoIOS?.willAutoRenew != null) {
            buffer.write(
              '\nWill auto renew (iOS): ${summary.renewalInfoIOS!.willAutoRenew}',
            );
          }
          _purchaseResult = buffer.toString();
        } else {
          debugPrint('No active subscription found');
          _purchaseResult = 'No active subscriptions found';
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
    debugPrint(
        '  Current subscription: ${_currentActiveSubscription?.productId}');

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
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        // Check if this is an upgrade/downgrade
        if (isUpgrade &&
            _currentActiveSubscription != null &&
            _selectedProrationMode != null) {
          // This is an upgrade/downgrade with proration
          debugPrint(
              'Upgrading subscription with proration mode: $_selectedProrationMode');
          debugPrint(
              'Using purchase token: ${_currentActiveSubscription!.purchaseToken}');

          final requestProps = RequestPurchaseProps.subs((
            apple: null,
            google: RequestSubscriptionAndroidProps(
              skus: [item.id],
            ),
            useAlternativeBilling: null,
          ));

          await _iap.requestPurchase(requestProps);
        } else {
          // This is a new subscription purchase
          debugPrint('Purchasing new subscription');

          final requestProps = RequestPurchaseProps.subs((
            apple: null,
            google: RequestSubscriptionAndroidProps(
              skus: [item.id],
            ),
            useAlternativeBilling: null,
          ));

          await _iap.requestPurchase(requestProps);
        }
      } else {
        // iOS
        final requestProps = RequestPurchaseProps.subs((
          apple: RequestSubscriptionIosProps(
            sku: item.id,
          ),
          google: null,
          useAlternativeBilling: null,
        ));

        await _iap.requestPurchase(requestProps);
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

      final requestProps = RequestPurchaseProps.subs((
        apple: null,
        google: RequestSubscriptionAndroidProps(
          skus: [item.id],
        ),
        useAlternativeBilling: null,
      ));

      await _iap.requestPurchase(requestProps);

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
      final testToken = _currentActiveSubscription?.purchaseToken ??
          'test_empty_token_${DateTime.now().millisecondsSinceEpoch}';
      debugPrint(
          'Using test token: ${testToken.substring(0, testToken.length > 20 ? 20 : testToken.length)}...');

      // Test with empty string - but pass validation by using a non-empty token
      final requestProps = RequestPurchaseProps.subs((
        apple: null,
        google: RequestSubscriptionAndroidProps(
          skus: [item.id],
        ),
        useAlternativeBilling: null,
      ));

      await _iap.requestPurchase(requestProps);

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
      await _iap.restorePurchases();
      await _checkActiveSubscriptions();

      if (!mounted) return;

      setState(() {
        _isProcessing = false;
        _purchaseResult =
            '✅ Restored ${_activeSubscriptionInfo.length} subscription(s)';
      });

      for (final subscription in _activeSubscriptionInfo.values) {
        final t = subscription.purchaseToken;
        final masked = t == null
            ? 'null'
            : '${t.substring(0, t.length > 10 ? 10 : t.length)}...';
        debugPrint('Restored: ${subscription.productId}, Token: $masked');
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

  Widget _buildActiveSubscriptionCard(ActiveSubscription subscription) {
    final isCurrent =
        _currentActiveSubscription?.productId == subscription.productId;
    final chips = <Widget>[
      _infoChip('Status: ${subscription.isActive ? 'Active' : 'Inactive'}'),
      if (subscription.basePlanIdAndroid != null)
        _infoChip('Plan: ${subscription.basePlanIdAndroid}'),
    ];

    final bool? autoRenew = subscription.autoRenewingAndroid ??
        subscription.renewalInfoIOS?.willAutoRenew;
    if (autoRenew != null) {
      chips.add(_infoChip('Auto renew: $autoRenew'));
    }

    final expiration = subscription.expirationDateIOS;
    if (expiration != null) {
      chips.add(
        _infoChip('Expires: ${_formatReadableDate(expiration)}'),
      );
    }
    if (subscription.willExpireSoon == true) {
      chips.add(_infoChip('Expiring soon'));
    }
    final environment = subscription.environmentIOS;
    if (environment != null && environment.isNotEmpty) {
      chips.add(_infoChip('Env: $environment'));
    }

    final renewal = subscription.renewalInfoIOS;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    subscription.productId.isEmpty
                        ? 'Unknown product'
                        : subscription.productId,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isCurrent
                            ? Colors.green.shade600
                            : Colors.blueGrey.shade600)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isCurrent
                          ? Colors.green.shade600
                          : Colors.blueGrey.shade600,
                    ),
                  ),
                  child: Text(
                    isCurrent ? 'Current' : 'Active',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isCurrent
                          ? Colors.green.shade700
                          : Colors.blueGrey.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: chips,
            ),

            // renewalInfoIOS showcase
            if (renewal != null) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'Renewal Info (iOS)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildRenewalInfoRow(
                'Auto-Renew',
                renewal.willAutoRenew ? '✅ Enabled' : '⚠️ Disabled',
                renewal.willAutoRenew ? Colors.green : Colors.orange,
              ),
              if (renewal.pendingUpgradeProductId != null)
                _buildRenewalInfoRow(
                  'Pending Upgrade',
                  renewal.pendingUpgradeProductId!,
                  Colors.blue,
                ),
              if (renewal.renewalDate != null)
                _buildRenewalInfoRow(
                  'Next Renewal',
                  _formatReadableDate(renewal.renewalDate!),
                  Colors.blue,
                ),
              if (renewal.expirationReason != null)
                _buildRenewalInfoRow(
                  'Expiration Reason',
                  renewal.expirationReason!,
                  Colors.red,
                ),
              if (renewal.isInBillingRetry == true)
                _buildRenewalInfoRow(
                  'Billing Status',
                  '⚠️ In Billing Retry',
                  Colors.orange,
                ),
              if (renewal.gracePeriodExpirationDate != null)
                _buildRenewalInfoRow(
                  'Grace Period Ends',
                  _formatReadableDate(renewal.gracePeriodExpirationDate!),
                  Colors.orange,
                ),
              if (renewal.priceIncreaseStatus != null)
                _buildRenewalInfoRow(
                  'Price Increase',
                  renewal.priceIncreaseStatus!,
                  Colors.purple,
                ),
              if (renewal.autoRenewPreference != null &&
                  renewal.autoRenewPreference != subscription.productId)
                _buildRenewalInfoRow(
                  'Auto-Renew Preference',
                  renewal.autoRenewPreference!,
                  Colors.purple,
                ),
            ],

            const SizedBox(height: 12),
            Text(
              'Transaction ID: ${subscription.transactionId}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontFamily: 'monospace',
              ),
            ),
            if (subscription.purchaseToken != null) ...[
              const SizedBox(height: 4),
              Text(
                'Token: ${subscription.purchaseToken!.substring(0, subscription.purchaseToken!.length > 20 ? 20 : subscription.purchaseToken!.length)}...',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRenewalInfoRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }

  String _formatReadableDate(double timestamp) {
    if (timestamp == 0) {
      return 'Unknown';
    }
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp.round());
    return date.toLocal().toString().split('.').first;
  }

  Widget _buildSubscriptionTier(ProductCommon subscription) {
    final isCurrentSubscription =
        _currentActiveSubscription?.productId == subscription.id;
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
              if (!kIsWeb &&
                  defaultTargetPlatform == TargetPlatform.android) ...[
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
                      onPressed: _isProcessing || isCurrentSubscription
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
                            : isCurrentSubscription
                                ? 'Active'
                                : _hasActiveSubscription
                                    ? 'Upgrade/Downgrade'
                                    : 'Subscribe',
                      ),
                    ),
                  ),
                  if (!kIsWeb &&
                      defaultTargetPlatform == TargetPlatform.android) ...[
                    const SizedBox(width: 4),
                    // Test wrong usage button
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isProcessing || isCurrentSubscription
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
          if (_currentActiveSubscription != null &&
              _currentActiveSubscription!.purchaseToken != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Chip(
                label: Text(
                  'Token: ${_currentActiveSubscription!.purchaseToken!.substring(0, _currentActiveSubscription!.purchaseToken!.length > 10 ? 10 : _currentActiveSubscription!.purchaseToken!.length)}...',
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
                                  ? 'Active Subscription: ${_currentActiveSubscription?.productId}'
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

                        // Upgrade Detection Section
                        if (_activeSubscriptionInfo.values.any((sub) =>
                            sub.renewalInfoIOS?.pendingUpgradeProductId !=
                            null)) ...[
                          Card(
                            color: Colors.blue.shade50,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.upgrade,
                                          color: Colors.blue.shade700),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Pending Upgrade Detected',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  ..._activeSubscriptionInfo.values
                                      .where((sub) =>
                                          sub.renewalInfoIOS
                                              ?.pendingUpgradeProductId !=
                                          null)
                                      .map((sub) {
                                    final renewal = sub.renewalInfoIOS!;
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: RichText(
                                        text: TextSpan(
                                          style: TextStyle(
                                              color: Colors.grey.shade800,
                                              fontSize: 14),
                                          children: [
                                            TextSpan(
                                              text: '${sub.productId}',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w600),
                                            ),
                                            const TextSpan(text: ' → '),
                                            TextSpan(
                                              text: renewal
                                                  .pendingUpgradeProductId!,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: Colors.blue.shade700,
                                              ),
                                            ),
                                            if (renewal.renewalDate != null)
                                              TextSpan(
                                                text:
                                                    '\nUpgrade takes effect: ${_formatReadableDate(renewal.renewalDate!)}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Cancellation Detection Section
                        if (_activeSubscriptionInfo.values.any((sub) =>
                            sub.renewalInfoIOS?.willAutoRenew == false &&
                            sub.renewalInfoIOS?.pendingUpgradeProductId ==
                                null)) ...[
                          Card(
                            color: Colors.orange.shade50,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.warning,
                                          color: Colors.orange.shade700),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Subscription Cancelled',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  ..._activeSubscriptionInfo.values
                                      .where((sub) =>
                                          sub.renewalInfoIOS?.willAutoRenew ==
                                              false &&
                                          sub.renewalInfoIOS
                                                  ?.pendingUpgradeProductId ==
                                              null)
                                      .map((sub) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: RichText(
                                        text: TextSpan(
                                          style: TextStyle(
                                              color: Colors.grey.shade800,
                                              fontSize: 14),
                                          children: [
                                            TextSpan(
                                              text: '${sub.productId}',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w600),
                                            ),
                                            const TextSpan(
                                                text:
                                                    ' is active but will not renew'),
                                            if (sub.expirationDateIOS != null)
                                              TextSpan(
                                                text:
                                                    '\nExpires: ${_formatReadableDate(sub.expirationDateIOS!)}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        if (_activeSubscriptionInfo.isNotEmpty) ...[
                          const Text(
                            'Active Subscriptions',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ..._activeSubscriptionInfo.values
                              .map(_buildActiveSubscriptionCard),
                          const SizedBox(height: 24),
                        ],

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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _purchaseResult!,
                                          style: TextStyle(
                                            color: _purchaseResult!
                                                    .contains('✅')
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
                                  if (_currentActiveSubscription != null) ...[
                                    const SizedBox(height: 12),
                                    Text(
                                      'View subscription details above in the Active Subscriptions section',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
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
