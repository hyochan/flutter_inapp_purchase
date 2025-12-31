---
sidebar_position: 3
title: Subscription Offers
---

import IapKitBanner from "@site/src/uis/IapKitBanner";
import IapKitLink from "@site/src/uis/IapKitLink";

# Subscription Offers

<IapKitBanner />

Handle subscription purchases, upgrades, downgrades, and promotional offers.

## Fetch Subscription Products

```dart
final subscriptions = await iap.fetchProducts(
  skus: ['monthly_sub', 'yearly_sub'],
  type: ProductQueryType.subs,
);
```

## Basic Subscription Purchase

### Android with Offers

```dart
// Get available offers for Android
List<AndroidSubscriptionOfferInput> getAndroidOffers(ProductCommon product) {
  if (product is ProductAndroid) {
    final details = product.subscriptionOfferDetailsAndroid;
    if (details != null && details.isNotEmpty) {
      return [
        for (final offer in details)
          AndroidSubscriptionOfferInput(
            offerToken: offer.offerToken,
            sku: product.id, // Use productId, not basePlanId
          ),
      ];
    }
  }
  return [];
}

// Purchase subscription with offers
Future<void> purchaseSubscription(ProductCommon product) async {
  if (Platform.isAndroid) {
    final offers = getAndroidOffers(product);
    final requestProps = RequestPurchaseProps.subs((
      ios: null,
      google: RequestSubscriptionAndroidProps(
        skus: [product.id],
        subscriptionOffers: offers.isNotEmpty ? offers : null,
      ),
      useAlternativeBilling: null,
    ));

    await iap.requestPurchase(requestProps);
  }
}
```

### iOS Subscription

```dart
Future<void> purchaseSubscriptionIOS(ProductCommon product) async {
  final requestProps = RequestPurchaseProps.subs((
    apple: RequestSubscriptionIosProps(
      sku: product.id,
    ),
    android: null,
    useAlternativeBilling: null,
  ));

  await iap.requestPurchase(requestProps);
}
```

## Upgrade/Downgrade Subscriptions (Android)

```dart
Future<void> upgradeSubscription(
  ProductCommon newProduct,
  Purchase currentSubscription,
  int replacementMode,
) async {
  final requestProps = RequestPurchaseProps.subs((
    ios: null,
    google: RequestSubscriptionAndroidProps(
      skus: [newProduct.id],
      oldSkus: [currentSubscription.productId],
      purchaseTokenAndroid: currentSubscription.purchaseToken,
      replacementModeAndroid: replacementMode,
    ),
    useAlternativeBilling: null,
  ));

  await iap.requestPurchase(requestProps);
}
```

## Replacement Modes (Android)

```dart
// Use AndroidReplacementMode enum
AndroidReplacementMode.withTimeProration.value         // 1: Credit unused time
AndroidReplacementMode.chargeProratedPrice.value       // 2: Charge difference now
AndroidReplacementMode.withoutProration.value          // 3: No credit
AndroidReplacementMode.deferred.value                  // 4: Apply at next renewal
AndroidReplacementMode.chargeFullPrice.value           // 5: Charge full price now
```

## Android basePlanId Limitation

> **Related Issues**: [react-native-iap#3096](https://github.com/hyochan/react-native-iap/issues/3096)

The Google Play Billing Library does not directly expose the `basePlanId` in purchase objects. To retrieve `basePlanId` and other subscription details, use server-side verification with <IapKitLink>IAPKit</IapKitLink>.

### Using IAPKit for basePlanId

When you verify a purchase with `verifyPurchaseWithProvider`, you can access the full subscription details including `basePlanId`:

```dart
final result = await iap.verifyPurchaseWithProvider(
  purchase: purchase,
  providerUrl: 'https://www.iapkit.com/api/v1/verify',
);

// The result contains offerDetails with basePlanId
// Response includes: offerDetails.basePlanId
```

See [SubscriptionOfferAndroid](https://www.openiap.dev/docs/types#subscriptionofferandroid) for available offer properties. Each offer contains: `basePlanId`, `offerId`, `offerTags`, `offerToken`, and `pricingPhases`.

## Check Active Subscriptions

### Quick Check (Lightweight)

Use `getActiveSubscriptions` for lightweight subscription status:

```dart
// Get active subscription summaries (lightweight)
final summaries = await iap.getActiveSubscriptions([
  'monthly_sub',
  'yearly_sub',
]);

for (final summary in summaries) {
  print('Product: ${summary.productId}');
  print('Transaction ID: ${summary.transactionId}');
  print('Auto-renewing: ${summary.autoRenewingAndroid}');
  print('Expiration: ${summary.expirationDateIOS}');
}

final hasActiveSubscription = summaries.isNotEmpty;
```

### Detailed Purchase Information

Use `getAvailablePurchases` for full purchase details and transaction info:

```dart
// Get detailed purchase objects with full transaction info
final purchases = await iap.getAvailablePurchases(
  onlyIncludeActiveItemsIOS: true,
);

for (final purchase in purchases) {
  print('Product: ${purchase.productId}');
  print('Purchase token: ${purchase.purchaseToken}');
  print('Transaction date: ${purchase.transactionDate}');
  print('Transaction ID: ${purchase.transactionId}');
}
```

### Get Purchase History (iOS)

Include expired subscriptions on iOS:

```dart
// Get all purchases including expired subscriptions (iOS only)
final allPurchases = await iap.getAvailablePurchases(
  onlyIncludeActiveItemsIOS: false,
  alsoPublishToEventListenerIOS: false,
);
```

## Handle Subscription Purchase

```dart
StreamSubscription<Purchase>? _purchaseSubscription;

void setupListener() {
  _purchaseSubscription = iap.purchaseUpdatedListener.listen(
    (purchase) async {
      // Check purchase state
      bool isPurchased = false;

      if (Platform.isAndroid && purchase is PurchaseAndroid) {
        isPurchased = purchase.purchaseState == PurchaseState.purchased ||
            purchase.androidPurchaseStateValue ==
                AndroidPurchaseState.purchased.value;
      } else if (purchase is PurchaseIOS) {
        isPurchased = purchase.iosTransactionState ==
            TransactionState.purchased;
      }

      if (isPurchased) {
        // Validate on server
        final isValid = await verifyPurchaseOnServer(purchase);
        if (!isValid) return;

        // Activate subscription
        await activateSubscription(purchase.productId);

        // Finish transaction
        await iap.finishTransaction(
          purchase: purchase,
          isConsumable: false, // Subscriptions are non-consumable
        );
      }
    },
  );
}
```

## iOS Promotional Offers

### Check Eligibility

```dart
final isEligible = await iap.isEligibleForIntroOfferIOS(
  groupID: 'subscription_group_id',
);

if (isEligible) {
  // Show promotional price
  print('Eligible for intro offer');
}
```

### Apply Promotional Offer

```dart
final requestProps = RequestPurchaseProps.subs((
  apple: RequestSubscriptionIosProps(
    sku: 'monthly_sub',
    withOffer: DiscountOfferInputIOS(
      identifier: 'promo_offer_id',
      keyIdentifier: 'key_identifier',
      nonce: nonceValue,
      signature: signatureValue,
      timestamp: timestampValue,
    ),
  ),
  android: null,
  useAlternativeBilling: null,
));

await iap.requestPurchase(requestProps);
```

### Handle Promotional Offer Upgrades

> **Related Issue**: [#578](https://github.com/hyochan/flutter_inapp_purchase/issues/578)

When upgrading subscriptions using promotional offers (e.g., monthly → yearly), Apple StoreKit first emits a **renewal transaction** for the old subscription before creating the new one. This means `purchaseUpdatedListener` may initially return the old product ID.

**Important**: Always check `renewalInfo.autoRenewPreference` to get the actual subscribed product.

#### Example: Upgrade Monthly to Yearly with Promo Offer

```dart
StreamSubscription<Purchase>? _purchaseUpdatedSubscription;

@override
void initState() {
  super.initState();
  _setupPurchaseListener();
}

void _setupPurchaseListener() {
  _purchaseUpdatedSubscription = iap.purchaseUpdatedListener.listen(
    (purchase) async {
      if (purchase.asIOS() case final ios?) {
        await _handleIOSPurchase(ios);
      }
    },
    onError: (error) {
      print('Purchase error: $error');
    },
  );
}

Future<void> _handleIOSPurchase(PurchaseIOS purchase) async {
  final renewalInfo = purchase.renewalInfoIOS;

  // ✅ IMPORTANT: Get the effective product ID
  final effectiveProductId = _getEffectiveProductId(purchase);

  print('''
  Purchase Update:
  - Transaction productId: ${purchase.productId}
  - Effective productId: $effectiveProductId
  - Auto-renew preference: ${renewalInfo?.autoRenewPreference}
  - Pending upgrade: ${renewalInfo?.pendingUpgradeProductId}
  ''');

  // Use effectiveProductId for your business logic
  await activateSubscription(effectiveProductId);

  // Finish the transaction
  await iap.finishTransaction(purchase, isConsumable: false);
}

String _getEffectiveProductId(PurchaseIOS purchase) {
  final renewalInfo = purchase.renewalInfoIOS;

  // Priority 1: Check for pending upgrade
  if (renewalInfo?.pendingUpgradeProductId != null) {
    return renewalInfo!.pendingUpgradeProductId!;
  }

  // Priority 2: Use autoRenewPreference (the product that will renew)
  if (renewalInfo?.autoRenewPreference != null) {
    return renewalInfo!.autoRenewPreference!;
  }

  // Priority 3: Fall back to transaction productId
  return purchase.productId;
}

Future<void> purchasePromotionalOffer({
  required String productId,
  required String offerId,
  required String keyId,
  required String nonce,
  required String signature,
  required double timestamp,
}) async {
  try {
    await iap.requestPurchase(
      RequestPurchaseProps.subs((
        android: null,
        apple: RequestSubscriptionIosProps(
          sku: productId,
          appAccountToken: '',
          withOffer: DiscountOfferInputIOS(
            identifier: offerId,
            keyIdentifier: keyId,
            nonce: nonce,
            signature: signature,
            timestamp: timestamp,
          ),
        ),
        useAlternativeBilling: null,
      )),
    );

    // Note: purchaseUpdatedListener will handle the purchase
    // and use _getEffectiveProductId() to get the correct product

  } catch (error) {
    print('Purchase failed: $error');
    rethrow;
  }
}

@override
void dispose() {
  _purchaseUpdatedSubscription?.cancel();
  super.dispose();
}
```

#### Alternative: Reload Subscriptions After Purchase

You can also reload subscriptions to get the complete updated state:

```dart
Future<void> purchasePromotionalOfferWithReload({
  required String productId,
  required String offerId,
  required String keyId,
  required String nonce,
  required String signature,
  required double timestamp,
}) async {
  try {
    await iap.requestPurchase(
      RequestPurchaseProps.subs((
        android: null,
        apple: RequestSubscriptionIosProps(
          sku: productId,
          appAccountToken: '',
          withOffer: DiscountOfferInputIOS(
            identifier: offerId,
            keyIdentifier: keyId,
            nonce: nonce,
            signature: signature,
            timestamp: timestamp,
          ),
        ),
        useAlternativeBilling: null,
      )),
    );

    // Wait for StoreKit to process
    await Future.delayed(Duration(seconds: 2));

    // Reload to get updated subscription state
    final activeSubscriptions = await iap.getActiveSubscriptions(null);

    if (activeSubscriptions.isNotEmpty) {
      final subscription = activeSubscriptions.first;
      print('Active subscription: ${subscription.productId}');
      await activateSubscription(subscription.productId);
    }

  } catch (error) {
    print('Purchase failed: $error');
    rethrow;
  }
}
```

#### Why This Happens

During a promotional offer upgrade:
1. User purchases yearly subscription (ProductIdv2) with promotional offer
2. StoreKit processes it as a "renewal with plan change"
3. First emits the **existing monthly subscription's renewal** transaction (ProductIdv1)
4. `renewalInfo.autoRenewPreference` immediately reflects the new product (ProductIdv2)
5. The actual new subscription transaction is created later (can take several minutes in sandbox)

This is Apple's normal behavior and is also acknowledged in the `openiap` example app:

```swift
// From openiap's SubscriptionFlowScreen.swift
// Reload subscription state after upgrade/downgrade
// (onPurchaseSuccess may fire with old subscription for upgrades)
await loadPurchases()
```

#### RenewalInfo Fields

| Field | Description | Usage |
|-------|-------------|-------|
| `autoRenewPreference` | The product ID that will renew next | **Use this** as the effective product ID |
| `pendingUpgradeProductId` | Set only when upgrade is pending and different from current | Indicates an upgrade in progress |
| `willAutoRenew` | Whether subscription will auto-renew | Check if subscription is active |
| `renewalDate` | When the next renewal will occur | Display to user |

#### Sandbox Testing Notes

In sandbox environment:
- Monthly subscriptions renew every 5 minutes
- Yearly subscriptions renew every 1 hour
- Transaction events may arrive with slight delays
- Always wait for current subscription to expire before testing promotional offers

## Manage Subscriptions

Open native subscription management UI:

```dart
Future<void> manageSubscriptions() async {
  if (Platform.isIOS) {
    await iap.showManageSubscriptionsIOS();
  } else if (Platform.isAndroid) {
    await iap.deepLinkToSubscriptions(
      skuAndroid: 'monthly_sub',
    );
  }
}
```

## Restore Purchases

```dart
Future<void> restorePurchases() async {
  // Get all available purchases
  final purchases = await iap.getAvailablePurchases();

  // Remove duplicates by productId, keeping most recent
  final uniquePurchases = <String, Purchase>{};
  for (final purchase in purchases) {
    final existing = uniquePurchases[purchase.productId];
    if (existing == null ||
        purchase.transactionDate.compareTo(existing.transactionDate) > 0) {
      uniquePurchases[purchase.productId] = purchase;
    }
  }

  print('Restored ${uniquePurchases.length} unique purchase(s)');
}
```

## Best Practices

1. **Server-side validation** - Always validate subscriptions on your backend
2. **Handle states properly** - Check both `purchaseState` and platform-specific states
3. **Avoid duplicate processing** - Track processed transaction IDs
4. **Test proration** - Test upgrade/downgrade flows thoroughly
5. **Monitor renewals** - Check subscription status regularly

## Complete Example

See [Subscription Flow Example](../examples/subscription-flow) for full implementation with:

- Subscription purchase flow
- Upgrade/downgrade handling
- Proration mode selection
- Active subscription checking

## Next Steps

- [Subscription Validation](./subscription-validation) - Validate subscriptions
- [Error Handling](./error-handling) - Handle subscription errors
- [Offer Code Redemption](./offer-code-redemption) - iOS offer codes
