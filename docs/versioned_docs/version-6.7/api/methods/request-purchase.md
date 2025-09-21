---
sidebar_position: 4
title: requestPurchase
---

# requestPurchase()

Initiates a purchase flow for the specified product.

## Overview

The `requestPurchase()` method starts the platform's native purchase flow for a product. It handles both one-time purchases and subscriptions with platform-specific options.

## Signature

```dart
Future<void> requestPurchase({
  required RequestPurchase request,
  required PurchaseType type,
})
```

## Parameters

- `request` - Platform-specific purchase request parameters
- `type` - Type of purchase (`PurchaseType.inapp` or `PurchaseType.subs`)

## Request Structure

### RequestPurchase
```dart
class RequestPurchase {
  final RequestPurchaseIOS? ios;
  final RequestPurchaseAndroid? android;
}
```

### RequestPurchaseIOS
```dart
class RequestPurchaseIOS {
  final String sku;                    // Product ID
  final int? quantity;                 // Quantity (for consumables)
  final String? appAccountToken;       // User identifier
  final Map<String, dynamic>? withOffer; // Promotional offer
}
```

### RequestPurchaseAndroid
```dart
class RequestPurchaseAndroid {
  final List<String> skus;             // Product IDs
  final String? obfuscatedAccountIdAndroid;  // User identifier
  final String? obfuscatedProfileIdAndroid;  // Profile identifier
  final String? purchaseToken;         // For upgrades/downgrades
  final int? offerTokenIndex;          // Specific offer index
  final int? prorationMode;            // Subscription proration
}
```

## Usage Examples

### Basic Purchase

```dart
// Simple product purchase
await FlutterInappPurchase.instance.requestPurchase(
  request: RequestPurchase(
    ios: RequestPurchaseIOS(sku: 'com.example.premium'),
    android: RequestPurchaseAndroid(skus: ['com.example.premium']),
  ),
  type: PurchaseType.inapp,
);
```

### Purchase with User Identifier

```dart
// Purchase with user account token for restoration
await FlutterInappPurchase.instance.requestPurchase(
  request: RequestPurchase(
    ios: RequestPurchaseIOS(
      sku: 'com.example.premium',
      appAccountToken: userId, // Your user ID
    ),
    android: RequestPurchaseAndroid(
      skus: ['com.example.premium'],
      obfuscatedAccountIdAndroid: userId,
    ),
  ),
  type: PurchaseType.inapp,
);
```

### Subscription with Promotional Offer (iOS)

```dart
// iOS subscription with promotional offer
await FlutterInappPurchase.instance.requestPurchase(
  request: RequestPurchase(
    ios: RequestPurchaseIOS(
      sku: 'com.example.monthly',
      withOffer: {
        'identifier': 'promo_50_off',
        'keyIdentifier': 'ABCDEF123456',
        'nonce': generateNonce(),
        'signature': generateSignature(), // Server-generated
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    ),
  ),
  type: PurchaseType.subs,
);
```

### Subscription Upgrade/Downgrade (Android)

```dart
// Android subscription change with proration
await FlutterInappPurchase.instance.requestPurchase(
  request: RequestPurchase(
    android: RequestPurchaseAndroid(
      skus: ['com.example.yearly'],
      purchaseToken: currentSubscriptionToken,
      prorationMode: AndroidProrationMode.IMMEDIATE_AND_CHARGE_PRORATED_PRICE,
    ),
  ),
  type: PurchaseType.subs,
);
```

## Complete Implementation

```dart
class PurchaseService {
  final _iap = FlutterInappPurchase.instance;
  
  Future<void> purchaseProduct(String productId, {bool isSubscription = false}) async {
    try {
      // Create platform-specific request
      final request = RequestPurchase(
        ios: RequestPurchaseIOS(
          sku: productId,
          appAccountToken: await _getUserId(),
        ),
        android: RequestPurchaseAndroid(
          skus: [productId],
          obfuscatedAccountIdAndroid: await _getUserId(),
        ),
      );
      
      // Initiate purchase
      await _iap.requestPurchase(
        request: request,
        type: isSubscription ? PurchaseType.subs : PurchaseType.inapp,
      );
      
      // Purchase result will be received via purchaseUpdated stream
      
    } on PurchaseError catch (e) {
      _handlePurchaseError(e);
    } catch (e) {
      print('Unexpected error: $e');
    }
  }
  
  void _handlePurchaseError(PurchaseError error) {
    switch (error.code) {
      case ErrorCode.E_USER_CANCELLED:
        print('User cancelled the purchase');
        break;
      case ErrorCode.E_PRODUCT_ALREADY_OWNED:
        print('Product already owned');
        break;
      case ErrorCode.E_BILLING_UNAVAILABLE:
        print('Billing service unavailable');
        break;
      default:
        print('Purchase error: ${error.message}');
    }
  }
  
  Future<String?> _getUserId() async {
    // Return your user identifier
    return 'user123';
  }
}
```

## Handling Purchase Results

Purchase results are delivered through streams:

```dart
// Listen to successful purchases
FlutterInappPurchase.purchaseUpdated.listen((Purchase? purchase) {
  if (purchase != null) {
    print('Purchase successful: ${purchase.productId}');
    
    // Verify the purchase
    _verifyPurchase(purchase);
    
    // Deliver the content
    _deliverContent(purchase.productId);
    
    // Finish the transaction
    _finishTransaction(purchase);
  }
});

// Listen to purchase errors
FlutterInappPurchase.purchaseError.listen((PurchaseResult? error) {
  if (error != null) {
    print('Purchase failed: ${error.message}');
  }
});
```

## Android Proration Modes

```dart
class AndroidProrationMode {
  static const int IMMEDIATE_AND_CHARGE_FULL_PRICE = 5;
  static const int DEFERRED = 4;
  static const int IMMEDIATE_AND_CHARGE_PRORATED_PRICE = 2;
  static const int IMMEDIATE_WITHOUT_PRORATION = 3;
  static const int IMMEDIATE_WITH_TIME_PRORATION = 1;
  static const int UNKNOWN_SUBSCRIPTION_UPGRADE_DOWNGRADE_POLICY = 0;
}
```

## Best Practices

1. **User Identification**: Always include a user identifier for purchase restoration
2. **Error Handling**: Implement comprehensive error handling for all failure cases
3. **Loading State**: Show loading indicator during purchase flow
4. **Double Purchase Prevention**: Disable purchase button after click

## Error Handling

```dart
Future<void> safePurchase(String productId) async {
  // Prevent double purchases
  if (_isPurchasing) return;
  _isPurchasing = true;
  
  try {
    await _iap.requestPurchase(
      request: RequestPurchase(
        ios: RequestPurchaseIOS(sku: productId),
        android: RequestPurchaseAndroid(skus: [productId]),
      ),
      type: PurchaseType.inapp,
    );
  } catch (e) {
    // Handle errors
    if (e is PurchaseError) {
      switch (e.code) {
        case ErrorCode.E_NOT_INITIALIZED:
          // Reinitialize connection
          await _iap.initConnection();
          break;
        case ErrorCode.E_ITEM_UNAVAILABLE:
          // Product not available
          showError('Product not available');
          break;
        default:
          showError(e.message);
      }
    }
  } finally {
    _isPurchasing = false;
  }
}
```

## Using the Builder DSL

`requestPurchaseWithBuilder` exposes a fluent builder for composing
platform-specific purchase parameters without manual object construction.

```dart
await FlutterInappPurchase.instance.requestPurchaseWithBuilder(
  build: (RequestPurchaseBuilder r) => r
    ..type = ProductType.Subs
    ..withIOS((RequestPurchaseIosBuilder i) => i..sku = 'your.sku1')
    ..withAndroid(
      (RequestPurchaseAndroidBuilder a) => a..skus = ['your.sku1'],
    ),
);
```

Use the builder when you:

- Need to configure different options per platform.
- Prefer a DSL-style API with chained modifiers.
- Want safeguards against unsupported `ProductType.All` usage—the builder only
  allows in-app or subscription types.

## Related Methods

- [`fetchProducts()`](./get-products.md) - Fetch products before purchasing
- [`finishTransaction()`](./finish-transaction.md) - Complete the purchase
- [`requestPurchase()`](./request-subscription.md) - Legacy subscription method

## Platform Notes

### iOS
- Requires valid product IDs from App Store Connect
- Promotional offers need server-side signature
- Quantity only works for consumable products

### Android
- Supports multiple SKUs but typically uses one
- Proration modes only apply to subscriptions
- Requires acknowledgment within 3 days
