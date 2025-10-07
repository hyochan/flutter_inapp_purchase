---
sidebar_position: 3
title: Subscription Offers
---

# Subscription Offers

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
      android: RequestSubscriptionAndroidProps(
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
    ios: RequestSubscriptionIosProps(
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
    android: RequestSubscriptionAndroidProps(
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
  ios: RequestSubscriptionIosProps(
    sku: 'monthly_sub',
    withOffer: PurchaseOfferIOS(
      id: 'promo_offer_id',
      keyId: 'key_identifier',
      nonce: nonceValue,
      signature: signatureValue,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    ),
  ),
  android: null,
  useAlternativeBilling: null,
));

await iap.requestPurchase(requestProps);
```

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
