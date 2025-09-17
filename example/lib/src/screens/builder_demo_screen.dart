import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

/// Demo screen showing DSL-like builder pattern for purchases/subscriptions
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

  Future<void> _simplePurchase() async {
    setState(() {
      _isProcessing = true;
      _status = 'Processing simple purchase...';
    });

    try {
      await _iap.requestPurchaseWithBuilder(
        build: (RequestPurchaseBuilder r) => r
          ..type = ProductType.InApp
          ..withIOS((RequestPurchaseIOSBuilder i) =>
              i..sku = 'dev.hyo.martie.10bulbs')
          ..withAndroid((RequestPurchaseAndroidBuilder a) =>
              a..skus = ['dev.hyo.martie.10bulbs']),
      );
      setState(() => _status = 'Purchase initiated');
    } catch (e) {
      setState(() => _status = 'Error: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _subscriptionPurchase() async {
    setState(() {
      _isProcessing = true;
      _status = 'Processing subscription...';
    });

    try {
      // Use requestPurchaseWithBuilder with type=subs
      await _iap.requestPurchaseWithBuilder(
        build: (RequestPurchaseBuilder r) => r
          ..type = ProductType.Subs
          ..withIOS((RequestPurchaseIOSBuilder i) =>
              i..sku = 'dev.hyo.martie.premium')
          ..withAndroid((RequestPurchaseAndroidBuilder a) =>
              a..skus = ['dev.hyo.martie.premium']),
      );
      setState(() => _status = 'Subscription initiated');
    } catch (e) {
      setState(() => _status = 'Error: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _subscriptionUpgrade() async {
    setState(() {
      _isProcessing = true;
      _status = 'Processing subscription upgrade...';
    });

    try {
      // Get existing subscription token if any
      final purchases = await _iap.getAvailablePurchases();
      Purchase? existing;
      if (purchases.isNotEmpty) {
        existing = purchases.firstWhere(
          (p) => p.productId == 'dev.hyo.martie.premium',
          orElse: () => purchases.first,
        );
      }

      // Android requires an existing purchase token to replace (proration)
      final token = existing?.purchaseToken;
      final hasToken = token != null && token.isNotEmpty;
      // Demo: use a default proration mode for upgrade
      final int prorationMode = AndroidReplacementMode.withTimeProration.value;

      if (Platform.isAndroid && hasToken) {
        // Upgrade/downgrade with replacement mode
        final subBuilder = RequestSubscriptionBuilder()
          ..withAndroid((RequestSubscriptionAndroidBuilder a) => a
            ..skus = ['dev.hyo.martie.premium']
            ..replacementModeAndroid = prorationMode
            ..purchaseTokenAndroid = token);

        await _iap.requestPurchase(
          props: subBuilder.build(),
          type: ProductType.Subs,
        );
        setState(() => _status = 'Subscription upgrade initiated');
      } else {
        // Fallback to a new subscription purchase (no replacement)
        final newSub = RequestSubscriptionBuilder()
          ..withAndroid((RequestSubscriptionAndroidBuilder a) =>
              a..skus = ['dev.hyo.martie.premium']);
        await _iap.requestPurchase(
          props: newSub.build(),
          type: ProductType.Subs,
        );
        setState(() => _status =
            'No token/proration; purchased yearly as new subscription');
      }
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
            Card(
              color:
                  _isProcessing ? Colors.orange.shade50 : Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text('Status',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(_status,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12)),
                    if (_isProcessing) ...[
                      const SizedBox(height: 8),
                      const LinearProgressIndicator(),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _simplePurchase,
              icon: const Icon(Icons.shopping_bag),
              label: const Text('Simple Purchase (In‑app)'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _subscriptionPurchase,
              icon: const Icon(Icons.subscriptions),
              label: const Text('Subscription (Monthly)'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _isProcessing || !Platform.isAndroid
                  ? null
                  : _subscriptionUpgrade,
              icon: const Icon(Icons.upgrade),
              label: const Text('Upgrade Subscription (Android)'),
            ),
            const SizedBox(height: 24),
            Card(
              color: Colors.grey.shade100,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Code Example'),
                    SizedBox(height: 8),
                    SelectableText(
                      """await iap.requestPurchaseWithBuilder(
  build: (RequestPurchaseBuilder r) => r
    ..type = ProductType.InApp
    ..withIOS((RequestPurchaseIOSBuilder i) => i
      ..sku = 'dev.hyo.martie.10bulbs'
      ..quantity = 1)
    ..withAndroid((RequestPurchaseAndroidBuilder a) => a
      ..skus = ['dev.hyo.martie.10bulbs']),
);

// For subscriptions (new purchase):
await iap.requestPurchaseWithBuilder(
  build: (RequestPurchaseBuilder r) => r
    ..type = ProductType.Subs
    ..withIOS((RequestPurchaseIOSBuilder i) => i..sku = 'dev.hyo.martie.premium')
    ..withAndroid((RequestPurchaseAndroidBuilder a) => a..skus = ['dev.hyo.martie.premium']),
);

// For subscription upgrade/downgrade (Android):
final b = RequestSubscriptionBuilder()
  ..withAndroid((RequestSubscriptionAndroidBuilder a) => a
    ..skus = ['dev.hyo.martie.premium']
    ..replacementModeAndroid = AndroidReplacementMode.withTimeProration.value
    ..purchaseTokenAndroid = '<existing_token>');
await iap.requestPurchase(request: b.build(), type: ProductType.Subs);""",
                      style: TextStyle(fontFamily: 'monospace', fontSize: 12),
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
