---
sidebar_position: 2
title: Subscription Store
---

# Subscription Store Example

A complete subscription store implementation with monthly and yearly plans.

## Features

- Multiple subscription tiers
- Subscription status display
- Automatic renewal handling
- Restore purchases
- Grace period support

## Complete Implementation

```dart
import 'package:flutter/material.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'dart:async';
import 'dart:io';

class SubscriptionStore extends StatefulWidget {
  @override
  _SubscriptionStoreState createState() => _SubscriptionStoreState();
}

class _SubscriptionStoreState extends State<SubscriptionStore> {
  StreamSubscription? _purchaseUpdatedSubscription;
  StreamSubscription? _purchaseErrorSubscription;

  List<IapItem> _subscriptions = [];
  List<Purchase> _purchases = [];
  bool _isLoading = true;

  // Your subscription IDs
  final List<String> _subscriptionIds = [
    'premium_monthly',
    'premium_yearly',
    'pro_monthly',
    'pro_yearly',
  ];

  @override
  void initState() {
    super.initState();
    _initializeStore();
  }

  @override
  void dispose() {
    _purchaseUpdatedSubscription?.cancel();
    _purchaseErrorSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeStore() async {
    try {
      // Initialize connection
      await FlutterInappPurchase.instance.initialize();

      // Set up listeners
      _purchaseUpdatedSubscription =
          FlutterInappPurchase.purchaseUpdated.listen(_handlePurchaseUpdate);

      _purchaseErrorSubscription =
          FlutterInappPurchase.purchaseError.listen(_handlePurchaseError);

      // Load subscriptions and purchases
      await _loadSubscriptions();
      await _loadPurchases();

    } catch (e) {
      _showError('Failed to initialize store: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSubscriptions() async {
    try {
      final subscriptions = await FlutterInappPurchase.instance
          .fetchProducts(skus: _subscriptionIds, type: 'subs');

      setState(() {
        _subscriptions = subscriptions;
      });
    } catch (e) {
      _showError('Failed to load subscriptions: $e');
    }
  }

  Future<void> _loadPurchases() async {
    try {
      final purchases = await FlutterInappPurchase.instance
          .getAvailablePurchases();

      setState(() {
        _purchases = purchases ?? [];
      });
    } catch (e) {
      _showError('Failed to load purchases: $e');
    }
  }

  void _handlePurchaseUpdate(Purchase? item) async {
    if (item == null) return;

    print('Purchase update: ${item.productId}');

    try {
      // Verify purchase on your server
      final isValid = await _verifyPurchase(item);

      if (isValid) {
        // Deliver subscription access
        await _deliverSubscription(item);

        // Complete transaction
        await _completeTransaction(item);

        // Refresh purchases
        await _loadPurchases();

        _showSuccess('Subscription activated!');
      } else {
        _showError('Purchase verification failed');
      }
    } catch (e) {
      _showError('Failed to process purchase: $e');
    }
  }

  void _handlePurchaseError(Purchase? item) {
    // Handle purchase errors
    _showError('Purchase failed');
  }

  Future<void> _requestPurchase(String productId) async {
    try {
      await FlutterInappPurchase.instance.requestPurchase(productId);
    } catch (e) {
      _showError('Failed to request subscription: $e');
    }
  }

  Future<void> _restorePurchases() async {
    try {
      setState(() => _isLoading = true);
      await _loadPurchases();
      _showSuccess('Purchases restored');
    } catch (e) {
      _showError('Failed to restore purchases: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<bool> _verifyPurchase(Purchase item) async {
    // TODO: Implement server-side verification
    // This should verify the receipt with your backend
    return true;
  }

  Future<void> _deliverSubscription(Purchase item) async {
    // TODO: Grant subscription access to user
    print('Delivering subscription: ${item.productId}');
  }

  Future<void> _completeTransaction(Purchase item) async {
    if (Platform.isIOS) {
      await FlutterInappPurchase.instance.finishTransaction(item);
    } else if (Platform.isAndroid) {
      // Subscriptions are auto-acknowledged on Android
      // But you might want to acknowledge manually for better control
      if (item.isAcknowledgedAndroid == false) {
        await FlutterInappPurchase.instance.acknowledgePurchase(
          purchaseToken: item.purchaseToken!,
        );
      }
    }
  }

  bool _isSubscriptionActive(String productId) {
    return _purchases.any((purchase) {
      if (purchase.productId != productId) return false;

      // Check if subscription is still valid
      // You might want to check expiration date here
      return true;
    });
  }

  String _getSubscriptionTier(String productId) {
    if (productId.contains('premium')) return 'Premium';
    if (productId.contains('pro')) return 'Pro';
    return 'Basic';
  }

  String _getSubscriptionPeriod(String productId) {
    if (productId.contains('monthly')) return 'Monthly';
    if (productId.contains('yearly')) return 'Yearly';
    return '';
  }

  Color _getTierColor(String tier) {
    switch (tier.toLowerCase()) {
      case 'premium': return Colors.orange;
      case 'pro': return Colors.purple;
      default: return Colors.blue;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Premium Subscriptions'),
        actions: [
          IconButton(
            icon: Icon(Icons.restore),
            onPressed: _restorePurchases,
            tooltip: 'Restore Purchases',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _buildSubscriptionPlans(),
    );
  }

  Widget _buildSubscriptionPlans() {
    // Group subscriptions by tier
    final Map<String, List<IapItem>> groupedSubs = {};

    for (final sub in _subscriptions) {
      final tier = _getSubscriptionTier(sub.productId!);
      groupedSubs.putIfAbsent(tier, () => []).add(sub);
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current Status
          _buildCurrentStatus(),

          SizedBox(height: 24),

          // Subscription Plans
          Text(
            'Choose Your Plan',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          SizedBox(height: 16),

          ...groupedSubs.entries.map((entry) {
            return _buildTierSection(entry.key, entry.value);
          }),
        ],
      ),
    );
  }

  Widget _buildCurrentStatus() {
    final activeSubscriptions = _purchases.where((p) =>
        _subscriptionIds.contains(p.productId)).toList();

    if (activeSubscriptions.isEmpty) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.grey),
              SizedBox(width: 12),
              Text('No active subscriptions'),
            ],
          ),
        ),
      );
    }

    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Active Subscriptions',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            ...activeSubscriptions.map((sub) => Padding(
              padding: EdgeInsets.only(left: 32, top: 4),
              child: Text(
                '${_getSubscriptionTier(sub.productId!)} ${_getSubscriptionPeriod(sub.productId!)}',
                style: TextStyle(color: Colors.green.shade700),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildTierSection(String tier, List<IapItem> subscriptions) {
    final color = _getTierColor(tier);

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            child: Text(
              tier,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          ...subscriptions.map((sub) => _buildSubscriptionTile(sub, color)),
        ],
      ),
    );
  }

  Widget _buildSubscriptionTile(IapItem subscription, Color color) {
    final isActive = _isSubscriptionActive(subscription.productId!);
    final period = _getSubscriptionPeriod(subscription.productId!);

    return ListTile(
      title: Text(subscription.title ?? period),
      subtitle: Text(subscription.description ?? ''),
      trailing: isActive
          ? Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'ACTIVE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : ElevatedButton(
              onPressed: () => _requestPurchase(subscription.productId!),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
              ),
              child: Text(subscription.localizedPrice ?? 'Subscribe'),
            ),
    );
  }
}
```

## Key Features Explained

### 1. Subscription Grouping

The store groups subscriptions by tier (Premium, Pro) for better organization:

```dart
final Map<String, List<IapItem>> groupedSubs = {};

for (final sub in _subscriptions) {
  final tier = _getSubscriptionTier(sub.productId!);
  groupedSubs.putIfAbsent(tier, () => []).add(sub);
}
```

### 2. Status Display

Shows current subscription status prominently:

```dart
Widget _buildCurrentStatus() {
  final activeSubscriptions = _purchases.where((p) =>
      _subscriptionIds.contains(p.productId)).toList();

  if (activeSubscriptions.isEmpty) {
    return _buildNoSubscriptionCard();
  }

  return _buildActiveSubscriptionCard(activeSubscriptions);
}
```

### 3. Visual Hierarchy

Different colors and styling for different subscription tiers:

```dart
Color _getTierColor(String tier) {
  switch (tier.toLowerCase()) {
    case 'premium': return Colors.orange;
    case 'pro': return Colors.purple;
    default: return Colors.blue;
  }
}
```

## Best Practices Implemented

1. **Error Handling**: Comprehensive error handling with user-friendly messages
2. **Loading States**: Shows loading indicators during async operations
3. **Purchase Verification**: Placeholder for server-side verification
4. **Transaction Completion**: Proper handling of iOS and Android differences
5. **Restore Functionality**: Easy way for users to restore purchases
6. **Status Display**: Clear indication of active subscriptions

## Testing Considerations

- Test with different subscription tiers
- Test restoration on device reinstall
- Test subscription expiration handling
- Test grace period scenarios
- Test with different payment methods

This example provides a solid foundation for a subscription-based app with multiple tiers and billing periods.
