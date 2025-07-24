---
sidebar_position: 5
title: requestSubscription
---

# requestSubscription()

Initiates a subscription purchase flow.

## Overview

The `requestSubscription()` method starts the platform's native subscription purchase flow. This is a legacy method that's being replaced by `requestPurchase()` with `PurchaseType.subs`.

## Signature

```dart
Future requestSubscription(
  String productId, {
  int? prorationModeAndroid,
  String? obfuscatedAccountIdAndroid,
  String? obfuscatedProfileIdAndroid,
  String? purchaseTokenAndroid,
  int? offerTokenIndex,
})
```

## Parameters

- `productId` - The subscription product identifier
- `prorationModeAndroid` - (Android only) How to handle proration for upgrades/downgrades
- `obfuscatedAccountIdAndroid` - (Android only) Obfuscated user account identifier
- `obfuscatedProfileIdAndroid` - (Android only) Obfuscated profile identifier
- `purchaseTokenAndroid` - (Android only) Token of existing subscription for upgrades
- `offerTokenIndex` - (Android only) Index of specific offer to purchase

## Usage Examples

### Basic Subscription

```dart
// Simple subscription purchase
await FlutterInappPurchase.instance.requestSubscription('com.example.monthly');
```

### Subscription with User Account

```dart
// Subscription with user identifier for restoration
await FlutterInappPurchase.instance.requestSubscription(
  'com.example.monthly',
  obfuscatedAccountIdAndroid: 'user123_hashed',
);
```

### Subscription Upgrade (Android)

```dart
// Upgrade from monthly to yearly with proration
await FlutterInappPurchase.instance.requestSubscription(
  'com.example.yearly',
  prorationModeAndroid: AndroidProrationMode.IMMEDIATE_AND_CHARGE_PRORATED_PRICE,
  purchaseTokenAndroid: currentMonthlyToken,
  obfuscatedAccountIdAndroid: 'user123_hashed',
);
```

### Complete Implementation

```dart
class SubscriptionManager {
  final _iap = FlutterInappPurchase.instance;
  String? _currentSubscriptionToken;
  
  Future<void> subscribe(String subscriptionId) async {
    try {
      await _iap.requestSubscription(
        subscriptionId,
        obfuscatedAccountIdAndroid: await _getUserId(),
      );
      
      // Result will be delivered via purchaseUpdated stream
      
    } catch (e) {
      print('Subscription failed: $e');
      _handleSubscriptionError(e);
    }
  }
  
  Future<void> upgradeSubscription({
    required String newSubscriptionId,
    required int prorationMode,
  }) async {
    if (_currentSubscriptionToken == null) {
      print('No active subscription to upgrade');
      return;
    }
    
    try {
      await _iap.requestSubscription(
        newSubscriptionId,
        prorationModeAndroid: prorationMode,
        purchaseTokenAndroid: _currentSubscriptionToken,
        obfuscatedAccountIdAndroid: await _getUserId(),
      );
    } catch (e) {
      print('Upgrade failed: $e');
    }
  }
  
  Future<String?> _getUserId() async {
    // Generate obfuscated user ID
    // Should be consistent across sessions
    return 'user_${DateTime.now().millisecondsSinceEpoch}';
  }
  
  void _handleSubscriptionError(dynamic error) {
    // Handle subscription-specific errors
    if (error.toString().contains('already owned')) {
      print('User already has an active subscription');
    }
  }
}
```

## Proration Modes (Android)

When upgrading or downgrading subscriptions on Android, you can specify how to handle the proration:

```dart
// Immediate upgrade with prorated charge
await _iap.requestSubscription(
  'com.example.yearly',
  prorationModeAndroid: AndroidProrationMode.IMMEDIATE_AND_CHARGE_PRORATED_PRICE,
  purchaseTokenAndroid: monthlyToken,
);

// Immediate upgrade with full price
await _iap.requestSubscription(
  'com.example.yearly',
  prorationModeAndroid: AndroidProrationMode.IMMEDIATE_AND_CHARGE_FULL_PRICE,
  purchaseTokenAndroid: monthlyToken,
);

// Deferred upgrade (at next renewal)
await _iap.requestSubscription(
  'com.example.yearly',
  prorationModeAndroid: AndroidProrationMode.DEFERRED,
  purchaseTokenAndroid: monthlyToken,
);
```

## Handling Subscription Results

```dart
void setupSubscriptionListeners() {
  // Listen for successful subscriptions
  FlutterInappPurchase.purchaseUpdated.listen((PurchasedItem? item) {
    if (item != null && _isSubscription(item.productId)) {
      print('Subscription successful: ${item.productId}');
      
      // Store the token for future upgrades
      if (Platform.isAndroid) {
        _currentSubscriptionToken = item.purchaseToken;
      }
      
      // Verify and activate subscription
      _activateSubscription(item);
      
      // Finish the transaction
      _iap.finishTransactionIOS(item);
    }
  });
  
  // Listen for errors
  FlutterInappPurchase.purchaseError.listen((PurchaseResult? error) {
    if (error != null) {
      print('Subscription error: ${error.message}');
    }
  });
}

bool _isSubscription(String? productId) {
  const subscriptionIds = [
    'com.example.monthly',
    'com.example.yearly',
    'com.example.premium',
  ];
  return subscriptionIds.contains(productId);
}
```

## Best Practices

1. **Store Purchase Tokens**: On Android, store purchase tokens for upgrade/downgrade scenarios
2. **Handle Already Owned**: Check for existing subscriptions before purchasing
3. **User Account Linking**: Always include user identifiers for cross-device restoration
4. **Proration Understanding**: Educate users about proration when upgrading

## Migration Guide

This method is being deprecated in favor of the more flexible `requestPurchase()` method:

### Old Way
```dart
await _iap.requestSubscription(
  'com.example.monthly',
  obfuscatedAccountIdAndroid: 'user123',
);
```

### New Way
```dart
await _iap.requestPurchase(
  request: RequestPurchase(
    ios: RequestPurchaseIOS(
      sku: 'com.example.monthly',
      appAccountToken: 'user123',
    ),
    android: RequestPurchaseAndroid(
      skus: ['com.example.monthly'],
      obfuscatedAccountIdAndroid: 'user123',
    ),
  ),
  type: PurchaseType.subs,
);
```

## Platform Differences

### iOS
- No proration modes (handled automatically by App Store)
- User account token passed differently
- Subscription groups managed by App Store

### Android
- Supports various proration modes
- Requires purchase token for upgrades
- Multiple offers per subscription possible

## Related Methods

- [`getSubscriptions()`](./get-subscriptions.md) - Fetch subscription products
- [`requestPurchase()`](./request-purchase.md) - Modern purchase method
- [`getAvailablePurchases()`](./get-available-purchases.md) - Check active subscriptions

## Common Issues

1. **Missing Purchase Token**: Ensure you store the purchase token from the initial subscription
2. **Invalid Proration Mode**: Use valid AndroidProrationMode constants
3. **Subscription Groups**: On iOS, users can only have one active subscription per group