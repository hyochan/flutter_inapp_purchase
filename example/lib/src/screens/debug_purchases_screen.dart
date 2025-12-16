import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:flutter_inapp_purchase/extensions/purchase_helpers.dart';
import 'package:flutter_inapp_purchase/types.dart' as gentype;

import '../widgets/purchase_detail_view.dart';

class DebugPurchasesScreen extends StatefulWidget {
  const DebugPurchasesScreen({Key? key}) : super(key: key);

  @override
  State<DebugPurchasesScreen> createState() => _DebugPurchasesScreenState();
}

class _DebugPurchasesScreenState extends State<DebugPurchasesScreen> {
  late FlutterInappPurchase _iap;
  List<gentype.Purchase> _purchases = [];
  bool _isLoading = false;
  String _debugInfo = '';

  @override
  void initState() {
    super.initState();
    _iap = FlutterInappPurchase();
    _loadPurchases();
  }

  Future<void> _loadPurchases() async {
    setState(() {
      _isLoading = true;
      _debugInfo = 'Loading purchases...';
    });

    try {
      // Restore purchases first
      await _iap.restorePurchases();
      await Future<void>.delayed(const Duration(seconds: 1));

      // Get all available purchases
      final purchases = await _iap.getAvailablePurchases();

      setState(() {
        _purchases = purchases;
        _debugInfo = 'Found ${purchases.length} purchases';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _debugInfo = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  bool _isSubscription(String? productId) {
    if (productId == null) return false;
    // Check if product ID contains subscription keywords
    return productId.contains('premium') ||
        productId.contains('subscription') ||
        productId.contains('monthly') ||
        productId.contains('yearly') ||
        productId.contains('pro');
  }

  bool _isConsumable(String? productId) {
    if (productId == null) return false;
    // Check if product ID contains consumable keywords
    return productId.contains('bulbs') ||
        productId.contains('coins') ||
        productId.contains('gems') ||
        productId.contains('lives') ||
        productId.contains('consumable');
  }

  Future<void> _consumePurchase(gentype.Purchase purchase) async {
    if (purchase.purchaseToken == null) {
      _showAlert('Error', 'No purchase token available');
      return;
    }

    setState(() {
      _debugInfo = 'Consuming ${purchase.productId}...';
    });

    try {
      final result = await _iap.consumePurchaseAndroid(
        purchase.purchaseToken!,
      );

      setState(() {
        _debugInfo = 'Consume result: $result';
      });

      if (result) {
        _showAlert('Success', 'Purchase consumed successfully');
      } else {
        _showAlert('Warning', 'Consume request completed but reported false');
      }

      // Reload purchases
      await _loadPurchases();
    } catch (e) {
      setState(() {
        _debugInfo = 'Consume error: $e';
      });
      _showAlert('Error', e.toString());
    }
  }

  Future<void> _cancelSubscription(gentype.Purchase purchase) async {
    setState(() {
      _debugInfo =
          'Opening subscription management for ${purchase.productId}...';
    });

    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        // For Android, directly show manual cancellation instructions
        // as the plugin's Android subscription management has issues
        setState(() {
          _debugInfo = 'Showing manual cancellation instructions for Android';
        });
        _showAlert(
            'Cancel Subscription - Android',
            'To cancel your subscription "${purchase.productId}":\n\n'
                '📱 Method 1 - Google Play Store App:\n'
                '1. Open Google Play Store app\n'
                '2. Tap Menu (☰) → Subscriptions\n'
                '3. Find your subscription\n'
                '4. Tap "Cancel subscription"\n\n'
                '💻 Method 2 - Web Browser:\n'
                '1. Go to play.google.com/store/account/subscriptions\n'
                '2. Sign in with your Google account\n'
                '3. Find and cancel the subscription\n\n'
                '⚙️ Method 3 - Phone Settings:\n'
                '1. Settings → Google → Manage Google Account\n'
                '2. Payments & subscriptions → Manage subscriptions');
      } else if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        // For iOS, try App Store subscription management
        try {
          await _iap.showManageSubscriptionsIOS();
          setState(() {
            _debugInfo =
                'App Store subscription management opened successfully';
          });
          _showAlert('Subscription Management',
              'Opened App Store subscription management. You can cancel your subscription there.');
        } catch (e) {
          // If that fails, show instructions for manual cancellation
          setState(() {
            _debugInfo =
                'Plugin method failed, showing manual instructions: $e';
          });
          _showAlert(
              'Subscription Management',
              'To cancel your subscription:\n\n'
                  '1. Open Settings app\n'
                  '2. Tap your name → Subscriptions\n'
                  '3. Find "${purchase.productId}"\n'
                  '4. Tap "Cancel Subscription"\n\n'
                  'Or visit: apps.apple.com and manage subscriptions');
        }
      }
    } catch (e) {
      setState(() {
        _debugInfo = 'Failed to open subscription management: $e';
      });
      _showAlert('Error',
          'Failed to open subscription management. Please cancel manually through your device settings.');
    }
  }

  void _showAlert(String title, String message) {
    showDialog<void>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
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
          'Debug Purchases',
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPurchases,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Debug Info
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Debug Info:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _debugInfo,
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                ),

                // Purchases List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _purchases.length,
                    itemBuilder: (context, index) {
                      final purchase = _purchases[index];
                      final isSubscription =
                          _isSubscription(purchase.productId);
                      final isConsumable = _isConsumable(purchase.productId);
                      final statusLabel = isSubscription
                          ? 'Subscription'
                          : isConsumable
                              ? 'Consumable'
                              : 'Non-consumable';
                      final statusColor = isSubscription
                          ? Colors.blue.shade600
                          : isConsumable
                              ? Colors.green.shade600
                              : Colors.grey.shade600;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              PurchaseDataView(
                                purchase: purchase,
                                statusLabel: statusLabel,
                                statusColor: statusColor,
                                sectionSpacing: 12,
                                fieldSpacing: 6,
                              ),
                              const SizedBox(height: 16),
                              if (purchase.purchaseToken != null) ...[
                                if (isConsumable &&
                                    defaultTargetPlatform ==
                                        TargetPlatform.android)
                                  SizedBox(
                                    width: double.infinity,
                                    child: CupertinoButton(
                                      color: Colors.red,
                                      onPressed: () =>
                                          _consumePurchase(purchase),
                                      child:
                                          const Text('Consume This Purchase'),
                                    ),
                                  )
                                else if (isSubscription)
                                  SizedBox(
                                    width: double.infinity,
                                    child: CupertinoButton(
                                      color: Colors.orange,
                                      onPressed: () =>
                                          _cancelSubscription(purchase),
                                      child: const Text('Cancel Subscription'),
                                    ),
                                  )
                                else if (!isConsumable)
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'Non-consumable purchase (cannot be consumed)',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                        fontStyle: FontStyle.italic,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
