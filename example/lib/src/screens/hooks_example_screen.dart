import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:flutter/cupertino.dart';
import '../iap_provider.dart';

/// Example screen demonstrating the IapProvider usage
/// This replaces the previous hooks-based approach with the IapProvider pattern
class HooksExampleScreen extends StatefulWidget {
  const HooksExampleScreen({Key? key}) : super(key: key);

  @override
  State<HooksExampleScreen> createState() => _HooksExampleScreenState();
}

class _HooksExampleScreenState extends State<HooksExampleScreen> {
  StreamSubscription<PurchasedItem?>? _purchaseUpdateSubscription;
  StreamSubscription<PurchaseResult?>? _purchaseErrorSubscription;

  @override
  void initState() {
    super.initState();
    // Listen to purchase updates
    _purchaseUpdateSubscription =
        FlutterInappPurchase.purchaseUpdated.listen((purchase) {
      if (purchase != null && mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase successful: ${purchase.productId}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });

    // Listen to purchase errors
    _purchaseErrorSubscription =
        FlutterInappPurchase.purchaseError.listen((error) {
      if (error != null && mounted) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase failed: ${error.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    // Fetch products on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final iapProvider = IapProvider.of(context);
      if (iapProvider != null && iapProvider.connected) {
        // Fetch products
        iapProvider
            .getProducts(['dev.hyo.martie.10bulbs', 'dev.hyo.martie.100bulbs']);
        // Fetch subscriptions
        iapProvider.getSubscriptions(['dev.hyo.martie.premium']);
      }
    });
  }

  @override
  void dispose() {
    _purchaseUpdateSubscription?.cancel();
    _purchaseErrorSubscription?.cancel();
    super.dispose();
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
          'IapProvider Example',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Connection Status
          _buildConnectionStatus(iapProvider?.connected ?? false),
          const SizedBox(height: 20),

          // Current Purchase Info
          if (iapProvider?.purchases.isNotEmpty ?? false)
            _buildCurrentPurchase(iapProvider!.purchases.last),

          // Current Error Info
          if (iapProvider?.error != null)
            _buildCurrentError(iapProvider!.error!),

          // Products Section
          _buildSectionTitle('Products'),
          ...(iapProvider?.products ?? []).map((product) => _buildProductCard(
                product: product,
                onBuy: () => _purchaseProduct(iapProvider, product),
              )),

          const SizedBox(height: 20),

          // Subscriptions Section
          _buildSectionTitle('Subscriptions'),
          ...(iapProvider?.subscriptions ?? [])
              .map((subscription) => _buildSubscriptionCard(
                    subscription: subscription,
                    isSubscribed: iapProvider?.availableItems.any(
                          (p) => p.productId == subscription.productId,
                        ) ??
                        false,
                    onBuy: () =>
                        _purchaseSubscription(iapProvider, subscription),
                  )),

          const SizedBox(height: 20),

          // Actions
          _buildActionButton(
            title: 'Restore Purchases',
            icon: CupertinoIcons.refresh,
            onPressed: () async {
              try {
                await iapProvider?.restorePurchases();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Purchases restored')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Restore failed: $e')),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionStatus(bool connected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: connected ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            connected
                ? CupertinoIcons.checkmark_circle_fill
                : CupertinoIcons.xmark_circle_fill,
            color:
                connected ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            connected ? 'Store Connected' : 'Store Disconnected',
            style: TextStyle(
              color:
                  connected ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentPurchase(PurchasedItem purchase) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current Purchase',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text('Product: ${purchase.productId}'),
          if (purchase.transactionId != null)
            Text('Transaction: ${purchase.transactionId}'),
        ],
      ),
    );
  }

  Widget _buildCurrentError(String error) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Error',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFFF44336),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: const TextStyle(color: Color(0xFFF44336)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1A1A1A),
        ),
      ),
    );
  }

  Widget _buildProductCard({
    required IAPItem product,
    required VoidCallback onBuy,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                CupertinoIcons.cube_box_fill,
                color: Color(0xFFFF9800),
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title ?? product.productId ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.localizedPrice ?? product.price ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: onBuy,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Buy',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionCard({
    required IAPItem subscription,
    required bool isSubscribed,
    required VoidCallback onBuy,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isSubscribed
            ? Border.all(color: const Color(0xFF4CAF50), width: 2)
            : null,
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
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSubscribed
                    ? const Color(0xFFE8F5E9)
                    : const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isSubscribed
                    ? CupertinoIcons.checkmark_seal_fill
                    : CupertinoIcons.star_fill,
                color: isSubscribed
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFF2196F3),
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        subscription.title ?? subscription.productId ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (isSubscribed) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Active',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subscription.localizedPrice ?? subscription.price ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: isSubscribed ? null : onBuy,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                isSubscribed ? 'Subscribed' : 'Subscribe',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String title,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF2196F3),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _purchaseProduct(IapProvider? iap, IAPItem product) async {
    if (iap == null) return;

    try {
      await iap.requestPurchase(product.productId ?? '');
    } catch (e) {
      debugPrint('Purchase failed: $e');
    }
  }

  Future<void> _purchaseSubscription(
      IapProvider? iap, IAPItem subscription) async {
    if (iap == null) return;

    try {
      await iap.requestSubscription(subscription.productId ?? '');
    } catch (e) {
      debugPrint('Subscription purchase failed: $e');
    }
  }
}
