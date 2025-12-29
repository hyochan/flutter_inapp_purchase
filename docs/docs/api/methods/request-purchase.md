---
sidebar_position: 4
title: requestPurchase
---

import IapKitBanner from "@site/src/uis/IapKitBanner";

# requestPurchase()

<IapKitBanner />

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

### RequestPurchaseProps (v8.2.0+ Recommended)

Use the factory constructors for type-safe purchase requests:

```dart
// For in-app products
RequestPurchaseProps.inApp((
  apple: RequestPurchaseIosProps(sku: 'product_id'),
  google: RequestPurchaseAndroidProps(skus: ['product_id']),
))

// For subscriptions
RequestPurchaseProps.subs((
  apple: RequestPurchaseIosProps(sku: 'subscription_id'),
  google: RequestPurchaseAndroidProps(skus: ['subscription_id']),
))
```

### RequestPurchase (Legacy)
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
  final String? advancedCommerceData; // Attribution data (iOS 15+)
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

### Basic Purchase (Recommended v8.2.0+)

```dart
// Simple product purchase using RequestPurchaseProps
await FlutterInappPurchase.instance.requestPurchase(
  RequestPurchaseProps.inApp((
    apple: RequestPurchaseIosProps(sku: 'com.example.premium'),
    google: RequestPurchaseAndroidProps(skus: ['com.example.premium']),
  )),
);
```

### Purchase with User Identifier

```dart
// Purchase with user account token for restoration
await FlutterInappPurchase.instance.requestPurchase(
  RequestPurchaseProps.inApp((
    apple: RequestPurchaseIosProps(
      sku: 'com.example.premium',
      appAccountToken: userId, // Your user ID
    ),
    google: RequestPurchaseAndroidProps(
      skus: ['com.example.premium'],
      obfuscatedAccountIdAndroid: userId,
    ),
  )),
);
```

### Subscription with Promotional Offer (iOS)

```dart
// iOS subscription with promotional offer
await FlutterInappPurchase.instance.requestPurchase(
  RequestPurchaseProps.subs((
    apple: RequestPurchaseIosProps(
      sku: 'com.example.monthly',
      withOffer: PaymentDiscount(
        identifier: 'promo_50_off',
        keyIdentifier: 'ABCDEF123456',
        nonce: generateNonce(),
        signature: generateSignature(), // Server-generated
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ),
    ),
    google: RequestPurchaseAndroidProps(skus: ['com.example.monthly']),
  )),
);
```

### Subscription Upgrade/Downgrade (Android)

```dart
// Android subscription change with proration
await FlutterInappPurchase.instance.requestPurchase(
  RequestPurchaseProps.subs((
    apple: RequestPurchaseIosProps(sku: 'com.example.yearly'),
    google: RequestPurchaseAndroidProps(
      skus: ['com.example.yearly'],
      purchaseToken: currentSubscriptionToken,
      prorationMode: AndroidProrationMode.IMMEDIATE_AND_CHARGE_PRORATED_PRICE,
    ),
  )),
);
```

### Purchase with Attribution Data (iOS 15+)

```dart
// iOS purchase with advanced commerce data for attribution tracking
await FlutterInappPurchase.instance.requestPurchaseWithBuilder(
  build: (builder) {
    builder.ios.sku = 'com.example.premium';
    builder.ios.advancedCommerceData = 'campaign_summer_2025';
    builder.type = ProductQueryType.InApp;
  },
);
```

The `advancedCommerceData` field uses StoreKit 2's `Product.PurchaseOption.custom` API to pass campaign tokens, affiliate IDs, or other attribution data during purchases.

## Complete Implementation

```dart
class PurchaseService {
  final _iap = FlutterInappPurchase.instance;

  Future<void> purchaseProduct(String productId, {bool isSubscription = false}) async {
    try {
      final userId = await _getUserId();

      // Initiate purchase using RequestPurchaseProps (v8.2.0+)
      if (isSubscription) {
        await _iap.requestPurchase(
          RequestPurchaseProps.subs((
            apple: RequestPurchaseIosProps(
              sku: productId,
              appAccountToken: userId,
            ),
            google: RequestPurchaseAndroidProps(
              skus: [productId],
              obfuscatedAccountIdAndroid: userId,
            ),
          )),
        );
      } else {
        await _iap.requestPurchase(
          RequestPurchaseProps.inApp((
            apple: RequestPurchaseIosProps(
              sku: productId,
              appAccountToken: userId,
            ),
            google: RequestPurchaseAndroidProps(
              skus: [productId],
              obfuscatedAccountIdAndroid: userId,
            ),
          )),
        );
      }

      // Purchase result will be received via purchaseUpdatedListener stream

    } on PurchaseError catch (e) {
      _handlePurchaseError(e);
    } catch (e) {
      print('Unexpected error: $e');
    }
  }

  void _handlePurchaseError(PurchaseError error) {
    switch (error.code) {
      case ErrorCode.UserCancelled:
        print('User cancelled the purchase');
        break;
      case ErrorCode.AlreadyOwned:
        print('Product already owned');
        break;
      case ErrorCode.ServiceError:
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
FlutterInappPurchase.instance.purchaseUpdatedListener.listen((purchase) {
  print('Purchase successful: ${purchase.productId}');

  // Handle purchase state (v8.2.0+: unified across platforms)
  switch (purchase.purchaseState) {
    case PurchaseState.Purchased:
      // Verify the purchase
      _verifyPurchase(purchase);
      // Deliver the content
      _deliverContent(purchase.productId);
      // Finish the transaction
      _finishTransaction(purchase);
      break;
    case PurchaseState.Pending:
      print('Purchase pending');
      break;
    case PurchaseState.Unknown:
      print('Unknown purchase state');
      break;
  }
});

// Listen to purchase errors
FlutterInappPurchase.instance.purchaseErrorListener.listen((error) {
  print('Purchase failed: ${error.message}');
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
      RequestPurchaseProps.inApp((
        apple: RequestPurchaseIosProps(sku: productId),
        google: RequestPurchaseAndroidProps(skus: [productId]),
      )),
    );
  } catch (e) {
    // Handle errors
    if (e is PurchaseError) {
      switch (e.code) {
        case ErrorCode.NotInitialized:
          // Reinitialize connection
          await _iap.initConnection();
          break;
        case ErrorCode.ItemUnavailable:
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
- `advancedCommerceData` requires iOS 15+ and StoreKit 2

### Android
- Supports multiple SKUs but typically uses one
- Proration modes only apply to subscriptions
- Requires acknowledgment within 3 days
- Use `google` field for request parameters (v8.2.0+)
