import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:flutter/cupertino.dart';

/// Example screen demonstrating the useIAP hook
class HooksExampleScreen extends HookWidget {
  const HooksExampleScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use the IAP hook with options
    final iap = useIAP(
      UseIAPOptions(
        onPurchaseSuccess: (purchase) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Purchase successful: ${purchase.productId}'),
              backgroundColor: Colors.green,
            ),
          );
        },
        onPurchaseError: (error) {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Purchase failed: ${error.message}'),
              backgroundColor: Colors.red,
            ),
          );
        },
      ),
    );

    // Fetch products on first build
    useEffect(() {
      if (iap.connected) {
        // Fetch products
        iap.getProducts(['dev.hyo.martie.10bulbs', 'dev.hyo.martie.100bulbs']);
        // Fetch subscriptions
        iap.getSubscriptions(['dev.hyo.martie.premium']);
      }
      return null;
    }, [iap.connected]);

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
          'Flutter Hooks IAP Example',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Connection Status
          _buildConnectionStatus(iap.connected),
          const SizedBox(height: 20),

          // Current Purchase Info
          if (iap.currentPurchase != null)
            _buildCurrentPurchase(iap.currentPurchase!),

          // Current Error Info
          if (iap.currentPurchaseError != null)
            _buildCurrentError(iap.currentPurchaseError!),

          // Products Section
          _buildSectionTitle('Products'),
          ...iap.products.map((product) => _buildProductCard(
            product: product,
            onBuy: () => _purchaseProduct(iap, product),
          )),

          const SizedBox(height: 20),

          // Subscriptions Section
          _buildSectionTitle('Subscriptions'),
          ...iap.subscriptions.map((subscription) => _buildSubscriptionCard(
            subscription: subscription,
            isSubscribed: iap.availablePurchases.any(
              (p) => p.productId == subscription.productId,
            ),
            onBuy: () => _purchaseSubscription(iap, subscription),
          )),

          const SizedBox(height: 20),

          // Actions
          _buildActionButton(
            title: 'Restore Purchases',
            icon: CupertinoIcons.refresh,
            onPressed: () async {
              try {
                await iap.restorePurchases();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Purchases restored')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Restore failed: $e')),
                );
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
            color: connected ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            connected ? 'Store Connected' : 'Store Disconnected',
            style: TextStyle(
              color: connected ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentPurchase(Purchase purchase) {
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

  Widget _buildCurrentError(PurchaseError error) {
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
            'Purchase Error',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFFF44336),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error.message,
            style: const TextStyle(color: Color(0xFFF44336)),
          ),
          if (error.debugMessage != null)
            Text(
              error.debugMessage!,
              style: TextStyle(
                color: Colors.red[700],
                fontSize: 12,
              ),
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
    required Product product,
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
                    product.title ?? product.productId,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.localizedPrice ?? product.price,
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
    required Subscription subscription,
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
                        subscription.title ?? subscription.productId,
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
                    subscription.localizedPrice ?? subscription.price,
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

  Future<void> _purchaseProduct(UseIAPReturn iap, Product product) async {
    try {
      await iap.requestPurchase(
        request: RequestPurchase(
          ios: RequestPurchaseIOS(sku: product.productId),
          android: RequestPurchaseAndroid(skus: [product.productId]),
        ),
        type: PurchaseType.inapp,
      );
    } catch (e) {
      debugPrint('Purchase failed: $e');
    }
  }

  Future<void> _purchaseSubscription(UseIAPReturn iap, Subscription subscription) async {
    try {
      await iap.requestPurchase(
        request: RequestPurchase(
          ios: RequestPurchaseIOS(sku: subscription.productId),
          android: RequestPurchaseAndroid(skus: [subscription.productId]),
        ),
        type: PurchaseType.subs,
      );
    } catch (e) {
      debugPrint('Subscription purchase failed: $e');
    }
  }
}