---
sidebar_position: 2
title: Subscriptions
---

# Subscriptions Guide

Complete guide to implementing subscription-based purchases in your Flutter app.

## Overview

Subscriptions are recurring purchases that provide access to content or services for a specific period. This guide covers subscription implementation, management, and best practices.

## Basic Setup

### 1. Initialize IAP Connection

```dart
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

class SubscriptionService {
  // Using singleton instance for subscription management
  final _iap = FlutterInappPurchase.instance;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _iap.initConnection();
      _isInitialized = true;
      _setupListeners();
    } catch (e) {
      print('Failed to initialize IAP: $e');
    }
  }

  void _setupListeners() {
    _iap.purchaseUpdated.listen(_handlePurchase);
    _iap.purchaseError.listen(_handleError);
  }
}
```

### 2. Fetch Subscription Products

```dart
class SubscriptionManager {
  // Use singleton instance for subscription manager
  final _iap = FlutterInappPurchase.instance;

  final _subscriptionIds = [
    'com.example.monthly_premium',
    'com.example.yearly_premium',
    'com.example.basic_monthly',
  ];

  List<ProductCommon> _subscriptions = [];

  Future<void> loadSubscriptions() async {
    try {
      final result = await _iap.fetchProducts(
        ProductRequest(
          skus: _subscriptionIds,
          type: ProductQueryType.Subs,
        ),
      );

      _subscriptions = result.value;

      // Sort by price or preference
      _subscriptions.sort((a, b) {
        final priceA = a.price ?? 0.0;
        final priceB = b.price ?? 0.0;
        return priceA.compareTo(priceB);
      });

    } catch (e) {
      print('Error loading subscriptions: $e');
    }
  }
}
```

## Subscription Purchase Flow

### Basic Purchase

```dart
Future<void> purchaseSubscription(String subscriptionId) async {
  // Using singleton instance
  final iap = FlutterInappPurchase.instance;

  try {
    final requestProps = RequestPurchaseProps.subs(
      request: RequestSubscriptionPropsByPlatforms(
        ios: RequestSubscriptionIosProps(
          sku: subscriptionId,
        ),
        android: RequestSubscriptionAndroidProps(
          skus: [subscriptionId],
          obfuscatedAccountIdAndroid: await _getUserId(),
        ),
      ),
    );

    await iap.requestPurchase(requestProps);

    // Result will be delivered via purchaseUpdated stream

  } catch (e) {
    print('Subscription purchase failed: $e');
    _handlePurchaseError(e);
  }
}
```

### Advanced Purchase with Options

```dart
Future<void> purchaseSubscriptionAdvanced({
  required String subscriptionId,
  String? upgradeFromId,
  int? prorationMode,
}) async {
  // Use singleton instance
  final iap = FlutterInappPurchase.instance;

  try {
    if (Platform.isAndroid && upgradeFromId != null) {
      // Android subscription upgrade/downgrade
      final currentToken = await _getCurrentSubscriptionToken(upgradeFromId);

      final requestProps = RequestPurchaseProps.subs(
        request: RequestSubscriptionPropsByPlatforms(
          ios: RequestSubscriptionIosProps(
            sku: subscriptionId,
          ),
          android: RequestSubscriptionAndroidProps(
            skus: [subscriptionId],
            purchaseTokenAndroid: currentToken,
            replacementModeAndroid: prorationMode ?? 5, // IMMEDIATE_AND_CHARGE_PRORATED_PRICE
            obfuscatedAccountIdAndroid: await _getUserId(),
          ),
        ),
      );

      await iap.requestPurchase(requestProps);
    } else {
      // New subscription or iOS
      final requestProps = RequestPurchaseProps.subs(
        request: RequestSubscriptionPropsByPlatforms(
          ios: RequestSubscriptionIosProps(
            sku: subscriptionId,
          ),
          android: RequestSubscriptionAndroidProps(
            skus: [subscriptionId],
            obfuscatedAccountIdAndroid: await _getUserId(),
          ),
        ),
      );

      await iap.requestPurchase(requestProps);
    }
  } catch (e) {
    _handleSubscriptionError(e);
  }
}
```

## Subscription Management

### Check Active Subscriptions

```dart
class SubscriptionChecker {
  Future<SubscriptionStatus> checkSubscriptionStatus() async {
    try {
      final purchases = await FlutterInappPurchase.instance.getAvailablePurchases();

      final activeSubscriptions = purchases.where((purchase) =>
          _isSubscription(purchase.productId) &&
          _isActive(purchase)
      ).toList();

      if (activeSubscriptions.isEmpty) {
        return SubscriptionStatus(isActive: false);
      }

      // Get highest tier subscription
      final activeSub = _getHighestTierSubscription(activeSubscriptions);

      return SubscriptionStatus(
        isActive: true,
        productId: activeSub.productId,
        expirationDate: _calculateExpirationDate(activeSub),
        isInGracePeriod: _isInGracePeriod(activeSub),
      );

    } catch (e) {
      print('Error checking subscription status: $e');
      return SubscriptionStatus(isActive: false);
    }
  }

  bool _isSubscription(String? productId) {
    return productId?.contains('subscription') ?? false;
  }

  bool _isActive(Purchase purchase) {
    // Check platform-specific active status
    if (Platform.isAndroid) {
      return purchase.purchaseStateAndroid == 'purchased';
    }
    return true; // iOS purchases in the list are active
  }
}
```

### Handle Subscription Changes

```dart
class SubscriptionChangeHandler {
  Future<void> upgradeSubscription({
    required String fromProductId,
    required String toProductId,
  }) async {
    try {
      if (Platform.isAndroid) {
        // Get current subscription token
        final currentToken = await _getCurrentSubscriptionToken(fromProductId);

        if (currentToken != null) {
          final requestProps = RequestPurchaseProps.subs(
            request: RequestSubscriptionPropsByPlatforms(
              ios: RequestSubscriptionIosProps(
                sku: toProductId,
              ),
              android: RequestSubscriptionAndroidProps(
                skus: [toProductId],
                purchaseTokenAndroid: currentToken,
                replacementModeAndroid: 2, // IMMEDIATE_AND_CHARGE_PRORATED_PRICE
              ),
            ),
          );

          await FlutterInappPurchase.instance.requestPurchase(requestProps);
        } else {
          throw Exception('Current subscription not found');
        }
      } else {
        // iOS handles this automatically through subscription groups
        final requestProps = RequestPurchaseProps.subs(
          request: RequestSubscriptionPropsByPlatforms(
            ios: RequestSubscriptionIosProps(
              sku: toProductId,
            ),
            android: RequestSubscriptionAndroidProps(
              skus: [toProductId],
            ),
          ),
        );

        await FlutterInappPurchase.instance.requestPurchase(requestProps);
      }
    } catch (e) {
      print('Subscription upgrade failed: $e');
    }
  }

  Future<void> cancelSubscription(String productId) async {
    if (Platform.isIOS) {
      // Redirect to App Store subscription management
      await FlutterInappPurchase.instance.showManageSubscriptionsIOS();
    } else if (Platform.isAndroid) {
      // Redirect to Google Play subscription management
      await FlutterInappPurchase.instance.deepLinkToSubscriptionsAndroid(
        sku: productId,
        packageName: 'com.example.app',
      );
    }
  }
}
```

## Subscription UI Components

### Subscription Card Widget

```dart
class SubscriptionCard extends StatelessWidget {
  final IapItem subscription;
  final bool isCurrentPlan;
  final VoidCallback onTap;

  const SubscriptionCard({
    Key? key,
    required this.subscription,
    required this.isCurrentPlan,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isCurrentPlan ? 8 : 2,
      child: InkWell(
        onTap: isCurrentPlan ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    subscription.title ?? 'Subscription',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  if (isCurrentPlan)
                    Chip(
                      label: Text('Current'),
                      backgroundColor: Colors.green,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(subscription.description ?? ''),
              const SizedBox(height: 16),
              _buildPriceInfo(context),
              const SizedBox(height: 16),
              if (!isCurrentPlan)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onTap,
                    child: Text('Subscribe for ${subscription.localizedPrice}'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Price: ${subscription.localizedPrice}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text(
          'Billing: ${_getBillingPeriod()}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        if (_hasFreeTrial())
          Text(
            'Free trial: ${_getTrialPeriod()}',
            style: TextStyle(color: Colors.green),
          ),
      ],
    );
  }

  String _getBillingPeriod() {
    if (Platform.isIOS) {
      final unit = subscription.subscriptionPeriodUnitIOS?.toLowerCase() ?? '';
      final number = subscription.subscriptionPeriodNumberIOS ?? '1';
      return '$number $unit${number != '1' ? 's' : ''}';
    } else {
      final period = subscription.subscriptionPeriodAndroid ?? '';
      return _formatAndroidPeriod(period);
    }
  }

  String _formatAndroidPeriod(String period) {
    switch (period) {
      case 'P1M': return 'monthly';
      case 'P1Y': return 'yearly';
      case 'P1W': return 'weekly';
      default: return period;
    }
  }

  bool _hasFreeTrial() {
    return subscription.introductoryPrice == '0' ||
           subscription.introductoryPrice == '0.00';
  }

  String _getTrialPeriod() {
    // Extract trial period from introductory price details
    return '7 days'; // Simplified
  }
}
```

### Subscription Status Widget

```dart
class SubscriptionStatusWidget extends StatefulWidget {
  @override
  _SubscriptionStatusWidgetState createState() => _SubscriptionStatusWidgetState();
}

class _SubscriptionStatusWidgetState extends State<SubscriptionStatusWidget> {
  SubscriptionStatus? _status;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    setState(() => _loading = true);

    try {
      final status = await SubscriptionChecker().checkSubscriptionStatus();
      setState(() {
        _status = status;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      print('Error checking subscription status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return CircularProgressIndicator();
    }

    if (_status?.isActive != true) {
      return _buildInactiveStatus();
    }

    return _buildActiveStatus();
  }

  Widget _buildActiveStatus() {
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Active Subscription',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Plan: ${_status!.productId}'),
            if (_status!.expirationDate != null)
              Text('Expires: ${_formatDate(_status!.expirationDate!)}'),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _manageSubscription,
                  child: Text('Manage'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _checkStatus,
                  child: Text('Refresh'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInactiveStatus() {
    return Card(
      color: Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No Active Subscription',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Subscribe to unlock premium features'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _showSubscriptionOptions,
              child: Text('View Plans'),
            ),
          ],
        ),
      ),
    );
  }

  void _manageSubscription() async {
    if (Platform.isIOS) {
      await FlutterInappPurchase.instance.showManageSubscriptionsIOS();
    } else {
      // Show Android management options
      _showAndroidManagementOptions();
    }
  }

  void _showSubscriptionOptions() {
    // Navigate to subscription selection screen
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
```

## Platform-Specific Considerations

### iOS Subscriptions

```dart
class IOSSubscriptionHandler {
  // Handle subscription groups
  Future<void> handleSubscriptionGroup(String newSubscriptionId) async {
    // iOS automatically manages subscription groups
    // Users can only have one active subscription per group
    final requestProps = RequestPurchaseProps.subs(
      request: RequestSubscriptionPropsByPlatforms(
        ios: RequestSubscriptionIosProps(
          sku: newSubscriptionId,
        ),
        android: RequestSubscriptionAndroidProps(
          skus: [newSubscriptionId],
        ),
      ),
    );

    await FlutterInappPurchase.instance.requestPurchase(requestProps);
  }

  // Handle promotional offers
  Future<void> purchaseWithPromoOffer({
    required String subscriptionId,
    required String offerId,
    required String keyId,
    required String nonce,
    required String signature,
    required int timestamp,
  }) async {
    final requestProps = RequestPurchaseProps.subs(
      request: RequestSubscriptionPropsByPlatforms(
        ios: RequestSubscriptionIosProps(
          sku: subscriptionId,
          withOffer: SubscriptionOfferIOS(
            identifier: offerId,
            keyIdentifier: keyId,
            nonce: nonce,
            signature: signature,
            timestamp: timestamp,
          ),
        ),
        android: RequestSubscriptionAndroidProps(
          skus: [subscriptionId],
        ),
      ),
    );

    await FlutterInappPurchase.instance.requestPurchase(requestProps);
  }
}
```

### Android Subscriptions

```dart
class AndroidSubscriptionHandler {
  // Handle base plans and offers
  Future<void> purchaseWithOffer({
    required String subscriptionId,
    required String offerToken,
  }) async {
    final requestProps = RequestPurchaseProps.subs(
      request: RequestSubscriptionPropsByPlatforms(
        ios: RequestSubscriptionIosProps(
          sku: subscriptionId,
        ),
        android: RequestSubscriptionAndroidProps(
          skus: [subscriptionId],
          subscriptionOffers: [
            SubscriptionOfferAndroid(
              offerToken: offerToken,
              sku: subscriptionId,
            ),
          ],
        ),
      ),
    );

    await FlutterInappPurchase.instance.requestPurchase(requestProps);
  }

  // Handle subscription upgrades/downgrades
  Future<void> changeSubscription({
    required String oldSubscriptionId,
    required String newSubscriptionId,
    required int prorationMode,
  }) async {
    final oldToken = await _getCurrentSubscriptionToken(oldSubscriptionId);

    if (oldToken != null) {
      final requestProps = RequestPurchaseProps.subs(
        request: RequestSubscriptionPropsByPlatforms(
          ios: RequestSubscriptionIosProps(
            sku: newSubscriptionId,
          ),
          android: RequestSubscriptionAndroidProps(
            skus: [newSubscriptionId],
            purchaseTokenAndroid: oldToken,
            replacementModeAndroid: prorationMode,
          ),
        ),
      );

      await FlutterInappPurchase.instance.requestPurchase(requestProps);
    }
  }
}
```

## Subscription Validation

### Server-Side Validation

```dart
class SubscriptionValidator {
  Future<bool> validateSubscription(Purchase purchase) async {
    try {
      // Always validate subscriptions server-side
      final response = await _validateWithServer(purchase);

      if (response.isValid) {
        // Check expiration
        if (response.expirationDate?.isAfter(DateTime.now()) == true) {
          return true;
        }
      }

      return false;
    } catch (e) {
      print('Subscription validation error: $e');
      return false;
    }
  }

  Future<ValidationResponse> _validateWithServer(Purchase purchase) async {
    // Implement server validation
    // Return validation result including expiration date
    throw UnimplementedError();
  }
}
```

## Best Practices

1. **Always Validate Server-Side**: Subscriptions should be validated on your server
2. **Handle Gracefully**: Provide grace periods for failed renewals
3. **Clear Pricing**: Display all pricing information clearly
4. **Easy Management**: Provide easy access to subscription management
5. **Test Thoroughly**: Test all subscription scenarios including upgrades
6. **Monitor Metrics**: Track subscription metrics and churn

## Testing Subscriptions

### Sandbox Testing (iOS)

1. Create sandbox test accounts in App Store Connect
2. Sign out of your Apple ID in Settings
3. When purchasing, sign in with sandbox account
4. Use special subscription durations for testing

### Test Purchases (Android)

1. Create test accounts in Google Play Console
2. Upload APK to internal testing track
3. Add test accounts as testers
4. Use test product IDs for development

```dart
class SubscriptionTesting {
  static const testSubscriptions = [
    'android.test.purchased',
    'android.test.canceled',
    'android.test.item_unavailable',
  ];

  static bool get isTestMode {
    return kDebugMode || _isTestFlavor;
  }

  static Future<void> simulateSubscriptionRenewal() async {
    // Simulate renewal for testing
    if (isTestMode) {
      await Future.delayed(Duration(seconds: 5));
      // Trigger renewal logic
    }
  }
}
```

## Related Documentation

- [Purchases Guide](./purchases.md) - General purchase handling
- [Error Handling](./error-handling.md) - Handling subscription errors
- [API Reference](../api/methods/request-subscription.md) - Subscription API methods
