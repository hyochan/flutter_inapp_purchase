import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import '../iap_provider.dart';

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({Key? key}) : super(key: key);

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  // Subscription IDs matching expo-iap example
  final List<String> subscriptionIds = [
    'dev.hyo.martie.premium',
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

    // Load subscriptions after a delay to ensure provider is ready
    Future<void>.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _loadSubscriptions();
        _loadPurchases();
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
              'Subscription purchase update received: ${purchasedItem.productId}, token: ${purchasedItem.purchaseToken}');
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
    debugPrint('Subscription purchase successful: ${purchasedItem.productId}');

    setState(() {
      _isProcessing = false;
      _purchaseResult = '✅ Subscription successful\n'
          'Product: ${purchasedItem.productId}\n'
          'Transaction ID: ${purchasedItem.transactionId ?? 'N/A'}\n'
          'Date: ${purchasedItem.transactionDate != null ? purchasedItem.transactionDate!.toLocal() : 'N/A'}\n'
          'Receipt: ${purchasedItem.transactionReceipt?.substring(0, 50)}...';
    });

    // Deliver the subscription to the user
    await _deliverSubscription(purchasedItem.productId);

    // Finish the transaction - Subscriptions are NOT consumed, only acknowledged
    try {
      if (!mounted) return;

      if (Platform.isAndroid) {
        // For Android subscriptions, acknowledge (NOT consume)
        if (purchasedItem.purchaseToken != null) {
          debugPrint(
              'Attempting to acknowledge Android subscription with token: ${purchasedItem.purchaseToken}');

          try {
            // For subscriptions, use acknowledgePurchaseAndroid for now (deprecated but working)
            await FlutterInappPurchase.instance.acknowledgePurchaseAndroid(
              purchaseToken: purchasedItem.purchaseToken!,
            );
            debugPrint('Android subscription acknowledged successfully');
          } catch (e) {
            debugPrint('Acknowledge failed: $e');
            if (mounted) {
              setState(() {
                _purchaseResult =
                    '❌ Failed to complete subscription. Please contact support.';
              });
            }
          }
        } else {
          debugPrint('ERROR: No purchase token available for Android');
        }
      } else if (Platform.isIOS) {
        // For iOS, finish the transaction (subscriptions are NOT consumable)
        await FlutterInappPurchase.instance.finishTransactionIOS(
          purchasedItem,
          isConsumable: false, // Subscriptions are NOT consumable
        );
        debugPrint('iOS subscription transaction finished');
      }
    } catch (e) {
      debugPrint('Error finishing subscription transaction: $e');
      if (mounted) {
        setState(() {
          _purchaseResult = '❌ Subscription error: $e';
        });
      }
    }

    // Show success dialog
    if (mounted) {
      showDialog<void>(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: const Text('Subscription Successful'),
          content:
              const Text('Your subscription has been activated successfully!'),
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

    // Refresh subscription status
    _loadSubscriptions();
    _loadPurchases();
  }

  void _handlePurchaseError(PurchaseResult error) {
    debugPrint('Subscription purchase failed: ${error.message}');

    setState(() {
      _isProcessing = false;
      _purchaseResult = '❌ Subscription failed: ${error.message}';
    });

    // Show error dialog
    if (mounted) {
      showDialog<void>(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: const Text('Subscription Failed'),
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

  Future<void> _deliverSubscription(String? productId) async {
    // Implement your subscription delivery logic here
    debugPrint('Delivering subscription: $productId');

    // In a real app, you would:
    // 1. Verify the subscription with your backend
    // 2. Update user's subscription status
    // 3. Enable premium features
  }

  Future<void> _handleSubscription(String productId) async {
    try {
      setState(() {
        _isProcessing = true;
        _purchaseResult = 'Processing subscription...';
      });

      // Use new v6.0.0+ API for subscription purchase
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
        type: PurchaseType.subs,
      );
    } catch (error) {
      setState(() {
        _isProcessing = false;
      });
      final errorMessage = error.toString();
      setState(() {
        _purchaseResult = '❌ Subscription failed: $errorMessage';
      });

      if (mounted) {
        showDialog<void>(
          context: context,
          builder: (_) => CupertinoAlertDialog(
            title: const Text('Subscription Failed'),
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

  Future<void> _loadSubscriptions() async {
    if (!mounted) return;

    final iapProvider = IapProvider.of(context);
    if (iapProvider == null || !iapProvider.connected) {
      // Wait a bit for connection to establish
      await Future<void>.delayed(const Duration(seconds: 1));
      if (!mounted) return;
    }

    if (iapProvider != null && iapProvider.connected) {
      await iapProvider.getSubscriptions(subscriptionIds);
    }
  }

  Future<void> _loadPurchases() async {
    if (!mounted) return;

    final iapProvider = IapProvider.of(context);
    if (iapProvider != null && iapProvider.connected) {
      await iapProvider.getAvailableItems();
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
          'Subscriptions',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: iapProvider?.loading ?? false
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadSubscriptions,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Connection Status
                  _buildConnectionStatus(iapProvider),
                  const SizedBox(height: 20),

                  // Error Message
                  if (iapProvider?.error != null)
                    _buildErrorMessage(iapProvider!.error!),

                  // Subscriptions List
                  if (iapProvider?.subscriptions.isEmpty ?? true)
                    _buildEmptyState()
                  else
                    ...iapProvider!.subscriptions.map((subscription) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child:
                              _buildSubscriptionCard(subscription, iapProvider),
                        )),

                  // Purchase Result
                  if (_purchaseResult != null) ...[
                    const SizedBox(height: 20),
                    _buildResultSection(),
                  ],
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
            CupertinoIcons.calendar,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Subscriptions Available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Subscriptions will appear here once loaded from the store',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard(
      IAPItem subscription, IapProvider? iapProvider) {
    final String productId = subscription.productId ?? '';
    final String title = subscription.title ?? productId;
    final String description = subscription.description ?? '';
    final String price =
        subscription.localizedPrice ?? subscription.price ?? '';

    // Check if this subscription is active
    // Check both purchases and available items
    final isSubscribed = (iapProvider?.availableItems
                .any((item) => item.productId == productId) ??
            false) ||
        (iapProvider?.purchases.any((purchase) =>
                purchase.productId == productId &&
                purchase.transactionReceipt != null) ??
            false);

    // Determine subscription type from product ID
    final isMonthly = productId.contains('monthly');
    final isYearly = productId.contains('yearly');

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
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(
                        CupertinoIcons.calendar,
                        color: Color(0xFF2196F3),
                        size: 32,
                      ),
                      if (isMonthly)
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
                            child: const Text(
                              'M',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      if (isYearly)
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
                            child: const Text(
                              'Y',
                              style: TextStyle(
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
            // Show subscription status
            if (isSubscribed)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.checkmark_circle_fill,
                      color: Color(0xFF4CAF50),
                      size: 16,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Active',
                      style: TextStyle(
                        color: Color(0xFF4CAF50),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: CupertinoButton(
                color: isSubscribed
                    ? const Color(0xFF6C757D)
                    : const Color(0xFF2196F3),
                borderRadius: BorderRadius.circular(12),
                padding: const EdgeInsets.symmetric(vertical: 16),
                onPressed: (_isProcessing ||
                        (iapProvider?.loading ?? false) ||
                        isSubscribed)
                    ? null
                    : () => _handleSubscription(productId),
                child: Text(
                  isSubscribed
                      ? 'Subscribed'
                      : (price.isNotEmpty ? 'Subscribe - $price' : 'Subscribe'),
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
}
