import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

/// Demo screen showing the new DSL-like builder pattern for purchases
class BuilderDemoScreen extends StatefulWidget {
  const BuilderDemoScreen({Key? key}) : super(key: key);

  @override
  State<BuilderDemoScreen> createState() => _BuilderDemoScreenState();
}

class _BuilderDemoScreenState extends State<BuilderDemoScreen> {
  final _iap = FlutterInappPurchase.instance;
  String _status = 'Ready';
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initConnection();
  }

  Future<void> _initConnection() async {
    try {
      await _iap.initConnection();
      setState(() => _status = 'Connected');
    } catch (e) {
      setState(() => _status = 'Connection failed: $e');
    }
  }

  /// Example 1: Simple product purchase
  Future<void> _simplePurchase() async {
    setState(() {
      _isProcessing = true;
      _status = 'Processing simple purchase...';
    });

    try {
      await _iap.requestPurchase(
        request: RequestPurchase(
          ios: RequestPurchaseIOS(sku: 'com.example.coins100'),
          android: RequestPurchaseAndroid(skus: ['com.example.coins100']),
        ),
        type: ProductType.inapp,
      );
      setState(() => _status = 'Purchase initiated');
    } catch (e) {
      setState(() => _status = 'Error: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  /// Example 2: Purchase with quantity (iOS)
  Future<void> _purchaseWithQuantity() async {
    setState(() {
      _isProcessing = true;
      _status = 'Processing purchase with quantity...';
    });

    try {
      await _iap.requestPurchase(
        request: RequestPurchase(
          ios: RequestPurchaseIOS(sku: 'com.example.coins100', quantity: 5),
          android: RequestPurchaseAndroid(skus: ['com.example.coins100']),
        ),
        type: ProductType.inapp,
      );
      setState(() => _status = 'Purchase with quantity initiated');
    } catch (e) {
      setState(() => _status = 'Error: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  /// Example 3: Subscription purchase
  Future<void> _subscriptionPurchase() async {
    setState(() {
      _isProcessing = true;
      _status = 'Processing subscription...';
    });

    try {
      await _iap.requestPurchase(
        request: RequestPurchase(
          ios: RequestPurchaseIOS(sku: 'com.example.premium_monthly'),
          android: RequestSubscriptionAndroid(
            skus: ['com.example.premium_monthly'],
          ),
        ),
        type: ProductType.subs,
      );
      setState(() => _status = 'Subscription initiated');
    } catch (e) {
      setState(() => _status = 'Error: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  /// Example 4: Subscription upgrade with proration (Android)
  Future<void> _subscriptionUpgrade() async {
    setState(() {
      _isProcessing = true;
      _status = 'Processing subscription upgrade...';
    });

    try {
      // First get existing subscription
      final purchases = await _iap.getAvailablePurchases();
      final existingSubscription = purchases.firstWhere(
        (p) => p.productId == 'com.example.premium_monthly',
        orElse: () => throw Exception('No existing subscription found'),
      );

      await _iap.requestPurchase(
        request: RequestPurchase(
          ios: RequestPurchaseIOS(sku: 'com.example.premium_yearly'),
          android: RequestSubscriptionAndroid(
            skus: ['com.example.premium_yearly'],
            replacementModeAndroid: AndroidReplacementMode.withTimeProration.value,
            purchaseTokenAndroid: existingSubscription.purchaseToken,
          ),
        ),
        type: ProductType.subs,
      );
      setState(() => _status = 'Subscription upgrade initiated');
    } catch (e) {
      setState(() => _status = 'Error: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  /// Example 5: Purchase with account information
  Future<void> _purchaseWithAccount() async {
    setState(() {
      _isProcessing = true;
      _status = 'Processing purchase with account...';
    });

    try {
      await _iap.requestPurchase(
        request: RequestPurchase(
          ios: RequestPurchaseIOS(
            sku: 'com.example.powerup',
            applicationUsername: 'user123',
            appAccountToken: 'token-abc-123',
          ),
          android: RequestPurchaseAndroid(
            skus: ['com.example.powerup'],
            obfuscatedAccountIdAndroid: 'user123_obfuscated',
            obfuscatedProfileIdAndroid: 'profile456_obfuscated',
          ),
        ),
        type: ProductType.inapp,
      );
      setState(() => _status = 'Purchase with account initiated');
    } catch (e) {
      setState(() => _status = 'Error: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  /// Example 6: Subscription with offer (Android)
  Future<void> _subscriptionWithOffer() async {
    setState(() {
      _isProcessing = true;
      _status = 'Processing subscription with offer...';
    });

    try {
      // Create subscription offer
      final offer = SubscriptionOfferAndroid(
        sku: 'com.example.premium_monthly',
        offerToken: 'offer_token_xyz',
      );

      await _iap.requestPurchase(
        request: RequestPurchase(
          ios: RequestPurchaseIOS(sku: 'com.example.premium_monthly'),
          android: RequestSubscriptionAndroid(
            skus: ['com.example.premium_monthly'],
            subscriptionOffers: [offer],
            isOfferPersonalized: true,
          ),
        ),
        type: ProductType.subs,
      );
      setState(() => _status = 'Subscription with offer initiated');
    } catch (e) {
      setState(() => _status = 'Error: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Builder Pattern Demo'),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Card(
              color:
                  _isProcessing ? Colors.orange.shade50 : Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      _isProcessing
                          ? Icons.hourglass_empty
                          : Icons.info_outline,
                      size: 32,
                      color: _isProcessing ? Colors.orange : Colors.blue,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Status',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _status,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _isProcessing
                            ? Colors.orange.shade800
                            : Colors.blue.shade800,
                        fontSize: 12,
                      ),
                    ),
                    if (_isProcessing) ...[
                      const SizedBox(height: 8),
                      const LinearProgressIndicator(),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DSL-like Builder Pattern',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This demo shows the new builder pattern for creating purchase requests. '
                      'The builder pattern provides a more intuitive and type-safe way to construct '
                      'platform-specific purchase parameters.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Example buttons
            Text(
              'Purchase Examples',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),

            _buildExampleButton(
              title: '1. Simple Purchase',
              subtitle: 'Basic in-app purchase',
              onPressed: _isProcessing ? null : _simplePurchase,
              icon: Icons.shopping_cart,
            ),

            _buildExampleButton(
              title: '2. Purchase with Quantity',
              subtitle: 'iOS quantity purchase (5 items)',
              onPressed: _isProcessing || !Platform.isIOS
                  ? null
                  : _purchaseWithQuantity,
              icon: Icons.add_shopping_cart,
            ),

            _buildExampleButton(
              title: '3. Subscription',
              subtitle: 'Monthly subscription',
              onPressed: _isProcessing ? null : _subscriptionPurchase,
              icon: Icons.subscriptions,
            ),

            _buildExampleButton(
              title: '4. Subscription Upgrade',
              subtitle: 'Upgrade with proration (Android)',
              onPressed: _isProcessing || !Platform.isAndroid
                  ? null
                  : _subscriptionUpgrade,
              icon: Icons.upgrade,
            ),

            _buildExampleButton(
              title: '5. Purchase with Account',
              subtitle: 'Include user account information',
              onPressed: _isProcessing ? null : _purchaseWithAccount,
              icon: Icons.account_circle,
            ),

            _buildExampleButton(
              title: '6. Subscription with Offer',
              subtitle: 'Android subscription offer',
              onPressed: _isProcessing || !Platform.isAndroid
                  ? null
                  : _subscriptionWithOffer,
              icon: Icons.local_offer,
            ),

            const SizedBox(height: 24),

            // Code Example Card
            Card(
              color: Colors.grey.shade100,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Code Example',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade900,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '''await iap.requestPurchase(
  request: RequestPurchase(
    ios: RequestPurchaseIOS(sku: 'product_id', quantity: 1),
    android: RequestPurchaseAndroid(skus: ['product_id']),
  ),
  type: ProductType.inapp,
);''',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: Colors.greenAccent,
                        ),
                      ),
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

  Widget _buildExampleButton({
    required String title,
    required String subtitle,
    required VoidCallback? onPressed,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(16),
          backgroundColor:
              onPressed != null ? Colors.deepPurple : Colors.grey.shade300,
          foregroundColor:
              onPressed != null ? Colors.white : Colors.grey.shade600,
          alignment: Alignment.centerLeft,
        ),
        child: Row(
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: onPressed != null
                          ? Colors.white.withOpacity(0.8)
                          : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: onPressed != null
                  ? Colors.white.withOpacity(0.6)
                  : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _iap.endConnection();
    super.dispose();
  }
}
