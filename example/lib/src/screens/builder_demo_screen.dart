import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import '../constants.dart';

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
    super.dispose();
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
      await _iap.initConnection();

      // Setup purchase listeners
      _setupPurchaseListeners();

      setState(() => _status = 'Connected');
    } catch (e) {
      setState(() => _status = 'Connection failed: $e');
    }
  }

  void _setupPurchaseListeners() {
    _purchaseUpdatedSubscription = _iap.purchaseUpdatedListener.listen(
      (purchase) {
        debugPrint('Purchase successful: ${purchase.productId}');
        setState(() {
          _status = 'Purchase successful: ${purchase.productId}';
          _isProcessing = false;
        });

        // Finish transaction
        final bool isConsumable = !purchase.isAutoRenewing;
        _iap
            .finishTransaction(purchase: purchase, isConsumable: isConsumable)
            .then((_) {
          debugPrint('Transaction finished (consumable: $isConsumable)');
        }).catchError((error) {
          debugPrint('Failed to finish transaction: $error');
        });
      },
      onError: (error) {
        debugPrint('Purchase stream error: $error');
        setState(() {
          _status = 'Stream error: $error';
          _isProcessing = false;
        });
      },
    );

    _purchaseErrorSubscription = _iap.purchaseErrorListener.listen(
      (error) {
        debugPrint('Purchase error: ${error.message}');
        setState(() {
          _status = 'Error: ${error.message}';
          _isProcessing = false;
        });
      },
      onError: (error) {
        debugPrint('Error stream error: $error');
        setState(() {
          _status = 'Error stream error: $error';
          _isProcessing = false;
        });
      },
    );
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
          ..withIOS((RequestPurchaseIosBuilder i) =>
              i..sku = IapConstants.inAppProductIds[0])
          ..withAndroid((RequestPurchaseAndroidBuilder a) =>
              a..skus = [IapConstants.inAppProductIds[0]]),
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
          ..withIOS((RequestPurchaseIosBuilder i) =>
              i..sku = IapConstants.subscriptionProductIds[0])
          ..withAndroid((RequestPurchaseAndroidBuilder a) =>
              a..skus = [IapConstants.subscriptionProductIds[0]]),
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
      for (final purchase in purchases) {
        if (purchase.productId == IapConstants.subscriptionProductIds[0]) {
          existing = purchase;
          break;
        }
      }

      // Android requires an existing purchase token to replace (proration)
      final token = existing?.purchaseToken;
      final hasToken = token != null && token.isNotEmpty;
      // Demo: use a default proration mode for upgrade
      final int prorationMode = AndroidReplacementMode.withTimeProration.value;

      if (!kIsWeb &&
          defaultTargetPlatform == TargetPlatform.android &&
          hasToken) {
        // Upgrade/downgrade with replacement mode
        final subBuilder = RequestSubscriptionBuilder()
          ..withAndroid((RequestSubscriptionAndroidBuilder a) => a
            ..skus = [IapConstants.subscriptionProductIds[0]]
            ..replacementModeAndroid = prorationMode
            ..purchaseTokenAndroid = token);

        await _iap.requestPurchase(subBuilder.build());
        setState(() => _status = 'Subscription upgrade initiated');
      } else {
        // Fallback to a new subscription purchase (no replacement)
        final newSub = RequestSubscriptionBuilder()
          ..withAndroid((RequestSubscriptionAndroidBuilder a) =>
              a..skus = [IapConstants.subscriptionProductIds[0]]);
        await _iap.requestPurchase(newSub.build());
        setState(() => _status =
            'No token/proration; purchased yearly as new subscription');
      }
    } catch (e) {
      setState(() => _status = 'Error: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _alternativeBillingPurchase() async {
    setState(() {
      _isProcessing = true;
      _status = 'Processing with Alternative Billing...';
    });

    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        // iOS: Use external purchase link
        final result = await _iap.presentExternalPurchaseLinkIOS(
          'https://openiap.dev',
        );

        if (result.error != null) {
          setState(() => _status = 'Error: ${result.error}');
        } else if (result.success) {
          setState(
              () => _status = 'External purchase link opened successfully');
        } else {
          setState(() => _status = 'User cancelled external purchase');
        }
      } else if (!kIsWeb) {
        // Android: Check availability first
        final availability =
            await _iap.checkAlternativeBillingAvailabilityAndroid();
        if (!availability) {
          setState(() => _status = 'Alternative billing unavailable');
          return;
        }

        // Use builder with Alternative Billing
        // Note: When useAlternativeBilling is true, Google Play will automatically
        // show the user-choice dialog (if in user-choice mode)
        await _iap.requestPurchaseWithBuilder(
          build: (RequestPurchaseBuilder r) => r
            ..type = ProductType.InApp
            ..useAlternativeBilling = true
            ..withAndroid((RequestPurchaseAndroidBuilder a) =>
                a..skus = [IapConstants.inAppProductIds[0]]),
        );
        setState(() => _status = 'Alternative billing purchase initiated');
      } else {
        setState(() => _status = 'Alternative billing not supported on web');
      }
    } catch (e) {
      setState(() => _status = 'Error: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _alternativeBillingSubscription() async {
    setState(() {
      _isProcessing = true;
      _status = 'Processing subscription with Alternative Billing...';
    });

    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        // iOS: Use external purchase link
        final result = await _iap.presentExternalPurchaseLinkIOS(
          'https://openiap.dev',
        );

        if (result.error != null) {
          setState(() => _status = 'Error: ${result.error}');
        } else if (result.success) {
          setState(
              () => _status = 'External purchase link opened successfully');
        } else {
          setState(() => _status = 'User cancelled external purchase');
        }
      } else if (!kIsWeb) {
        // Android: Check availability first
        final availability =
            await _iap.checkAlternativeBillingAvailabilityAndroid();
        if (!availability) {
          setState(() => _status = 'Alternative billing unavailable');
          return;
        }

        // Use builder with Alternative Billing
        // Note: When useAlternativeBilling is true, Google Play will automatically
        // show the user-choice dialog (if in user-choice mode)
        await _iap.requestPurchaseWithBuilder(
          build: (RequestPurchaseBuilder r) => r
            ..type = ProductType.Subs
            ..useAlternativeBilling = true
            ..withAndroid((RequestPurchaseAndroidBuilder a) =>
                a..skus = [IapConstants.subscriptionProductIds[0]]),
        );
        setState(() => _status = 'Alternative billing subscription initiated');
      } else {
        setState(() => _status = 'Alternative billing not supported on web');
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
              onPressed: _isProcessing ||
                      kIsWeb ||
                      defaultTargetPlatform != TargetPlatform.android
                  ? null
                  : _subscriptionUpgrade,
              icon: const Icon(Icons.upgrade),
              label: const Text('Upgrade Subscription (Android)'),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Alternative Billing (Builder Pattern)',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _alternativeBillingPurchase,
              icon: const Icon(Icons.payment),
              label: const Text('Purchase with Alternative Billing'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _alternativeBillingSubscription,
              icon: const Icon(Icons.card_membership),
              label: const Text('Subscription with Alternative Billing'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
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
                      """// Regular purchase:
await iap.requestPurchaseWithBuilder(
  build: (RequestPurchaseBuilder r) => r
    ..type = ProductType.InApp
    ..withIOS((RequestPurchaseIosBuilder i) => i
      ..sku = 'dev.hyo.martie.10bulbs'
      ..quantity = 1)
    ..withAndroid((RequestPurchaseAndroidBuilder a) => a
      ..skus = ['dev.hyo.martie.10bulbs']),
);

// Subscription (new purchase):
await iap.requestPurchaseWithBuilder(
  build: (RequestPurchaseBuilder r) => r
    ..type = ProductType.Subs
    ..withIOS((RequestPurchaseIosBuilder i) => i..sku = 'dev.hyo.martie.premium')
    ..withAndroid((RequestPurchaseAndroidBuilder a) => a..skus = ['dev.hyo.martie.premium']),
);

// Alternative Billing:
await iap.requestPurchaseWithBuilder(
  build: (RequestPurchaseBuilder r) => r
    ..type = ProductType.InApp
    ..useAlternativeBilling = true
    ..withIOS((RequestPurchaseIosBuilder i) => i..sku = 'dev.hyo.martie.10bulbs')
    ..withAndroid((RequestPurchaseAndroidBuilder a) => a..skus = ['dev.hyo.martie.10bulbs']),
);

// Subscription upgrade/downgrade (Android):
final b = RequestSubscriptionBuilder()
  ..withAndroid((RequestSubscriptionAndroidBuilder a) => a
    ..skus = ['dev.hyo.martie.premium']
    ..replacementModeAndroid = AndroidReplacementMode.withTimeProration.value
    ..purchaseTokenAndroid = '<existing_token>');
await iap.requestPurchase(b.build());""",
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
