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

  @override
  void initState() {
    super.initState();
    // Load subscriptions after a delay to ensure provider is ready
    Future<void>.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _loadSubscriptions();
        _loadPurchases();
      }
    });
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      CupertinoIcons.checkmark_circle_fill,
                      color: Color(0xFF4CAF50),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Active',
                      style: const TextStyle(
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
                onPressed: (iapProvider?.loading ?? false) || isSubscribed
                    ? null
                    : () async {
                        // Simplified subscription request
                        await FlutterInappPurchase.instance.requestPurchaseAuto(
                          sku: productId,
                          type: PurchaseType.subs,
                          andDangerouslyFinishTransactionAutomaticallyIOS:
                              false,
                          // Optional parameters will be automatically applied based on platform:
                          // iOS: appAccountToken, quantity, withOffer
                          // Android: obfuscatedAccountIdAndroid, obfuscatedProfileIdAndroid,
                          //          purchaseToken, replacementModeAndroid, subscriptionOffers
                        );
                      },
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
}
