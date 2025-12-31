---
sidebar_position: 4
title: Subscription Validation
---

import IapKitBanner from "@site/src/uis/IapKitBanner";
import IapKitLink from "@site/src/uis/IapKitLink";

# Subscription Validation

<IapKitBanner />

flutter_inapp_purchase exposes modern StoreKit 2 (iOS) and Google Play Billing (Android) pipelines. This guide walks through the data available on the Dart side, how it maps to the underlying native APIs, and practical strategies to answer common lifecycle questions such as "is the user currently inside their free trial?"

iOS and Android share the same high-level API surface, but individual capabilities differ. Notes in each section call out platform-specific behaviour—for example, `subscriptionStatusIOS` only exists on Apple platforms, whereas Android relies on Purchase objects and the Play Developer API.

## Summary of Key APIs

| Capability | API | iOS | Android |
|-----------|-----|-----|---------|
| Fetch latest entitlement records the store still considers active | `getAvailablePurchases` | Wraps StoreKit 2 Transaction.currentEntitlements; optional flags control listener mirror & active-only filtering | Queries Play Billing twice (inapp + subs) and merges validated purchases, exposing purchaseToken for server use |
| Filter entitlements down to subscriptions only | `getActiveSubscriptions` | Adds expirationDateIOS, daysUntilExpirationIOS, environmentIOS convenience fields | Re-shapes merged purchase list and surfaces autoRenewingAndroid, purchaseToken, and willExpireSoon placeholders |
| Inspect fine-grained subscription phase | `subscriptionStatusIOS` | StoreKit 2 status API (inTrialPeriod, inGracePeriod, etc.) | Not available; pair getAvailablePurchases with Play Developer API for phase data |
| Retrieve receipts for validation | `getReceiptDataIOS`, `validateReceiptIOS` | Provides App Store receipt / JWS for backend validation | validateReceipt forwards to OpenIAP's Google Play validator and expects purchaseToken / packageName |

## Working with getAvailablePurchases

`getAvailablePurchases` returns every purchase that the native store still considers active for the signed-in user.

**iOS** — The library bridges directly to StoreKit 2's Transaction.currentEntitlements, so each item is a fully validated `PurchaseIOS`. Optional flags (`onlyIncludeActiveItemsIOS`, `alsoPublishToEventListenerIOS`) are forwarded to StoreKit and mimic the native behaviour.

**Android** — Google Play Billing keeps one list for in-app products and another for subscriptions. The wrapper automatically queries both (`type: 'inapp'` and `type: 'subs'`), merges the results, and validates them before returning control to Dart.

```dart
class SubscriptionGate extends StatefulWidget {
  final List<String> subscriptionIds;

  const SubscriptionGate({required this.subscriptionIds, Key? key}) : super(key: key);

  @override
  State<SubscriptionGate> createState() => _SubscriptionGateState();
}

class _SubscriptionGateState extends State<SubscriptionGate> {
  final _iap = FlutterInappPurchase.instance;
  Map<String, ActiveSubscription> _activeSubscriptionInfo = {};
  bool _hasActiveSubscription = false;

  @override
  void initState() {
    super.initState();
    _checkActiveSubscriptions();
  }

  Future<void> _checkActiveSubscriptions() async {
    try {
      // Get active subscription summaries
      final summaries = await _iap.getActiveSubscriptions(widget.subscriptionIds);

      // Get corresponding Purchase objects for additional details
      final purchases = await _iap.getAvailablePurchases(
        onlyIncludeActiveItemsIOS: true,
      );

      // Create map of summaries by product ID
      final summaryByProduct = <String, ActiveSubscription>{};
      for (final summary in summaries) {
        summaryByProduct[summary.productId] = summary;
      }

      // Match purchases with summaries
      final activeSubs = <Purchase>[];
      final addedProducts = <String>{};

      for (final purchase in purchases) {
        if (summaryByProduct.containsKey(purchase.productId) &&
            addedProducts.add(purchase.productId)) {
          activeSubs.add(purchase);
        }
      }

      if (!mounted) return;

      setState(() {
        _activeSubscriptionInfo = summaryByProduct;
        _hasActiveSubscription = activeSubs.isNotEmpty;
      });
    } catch (e) {
      debugPrint('Error checking subscriptions: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Render locked/unlocked UI based on subscription status
    return _hasActiveSubscription ? UnlockedContent() : LockedContent();
  }
}
```

### Data Included

For each purchase you can inspect fields such as:

- `transactionDate`: Transaction timestamp
- `transactionId`: Unique transaction identifier
- `productId`: Product SKU
- `purchaseToken`: Token for server-side validation
- Platform-specific fields (see Purchase types)

### Limitations

StoreKit does not bake "current phase" indicators into these records. To answer questions like "is the user still in a free trial?" you need either the StoreKit status API or server-side receipt validation.

## Using getActiveSubscriptions

`getActiveSubscriptions` is a helper that filters down to subscription products and adds convenience fields. It returns an array of `ActiveSubscription` objects:

```dart
final activeSubscriptions = await iap.getActiveSubscriptions([
  'yearly_subscription',
  'monthly_subscription',
]);

if (activeSubscriptions.isEmpty) {
  // User has no valid subscription
  print('No active subscriptions');
} else {
  for (final sub in activeSubscriptions) {
    print('Product: ${sub.productId}');
    print('Transaction ID: ${sub.transactionId}');
    print('Expiration (iOS): ${sub.expirationDateIOS}');
    print('Auto-renewing (Android): ${sub.autoRenewingAndroid}');
    print('Environment (iOS): ${sub.environmentIOS}');
  }
}
```

### Fields Available

- `isActive`: Always true as long as the subscription remains in the current entitlement set
- `expirationDateIOS` & `daysUntilExpirationIOS`: Surfaced directly from StoreKit
- `transactionId` / `purchaseToken`: Handy for reconciling with receipts or Play Billing
- `willExpireSoon`: Flag set when the subscription is within its grace window
- `autoRenewingAndroid`: Reflects the Google Play auto-renew status
- `environmentIOS`: Sandbox or Production

**Platform note**: On iOS the helper re-shapes StoreKit 2 entitlement objects. On Android it operates on the merged inapp + subs purchase list, so the output contains both one-time products and subscriptions unless you filter by specific product IDs.

## Deriving Subscription Phase

If you want a coarse subscription phase that works on both platforms, compute it from the data:

```dart
enum SubscriptionPhase { subscribed, expiringSoon, expired }

const msInDay = 1000 * 60 * 60 * 24;
const graceWindowDays = 3;

Future<SubscriptionPhase> getCurrentPhase(String sku) async {
  final subscriptions = await iap.getActiveSubscriptions([sku]);
  final entry = subscriptions.where((sub) => sub.productId == sku).firstOrNull;

  if (entry == null) {
    return SubscriptionPhase.expired;
  }

  final now = DateTime.now().millisecondsSinceEpoch;
  final expiresAt = entry.expirationDateIOS;

  if (entry.daysUntilExpirationIOS != null && entry.daysUntilExpirationIOS! <= 0) {
    return SubscriptionPhase.expired;
  }

  if (expiresAt != null && expiresAt <= now) {
    return SubscriptionPhase.expired;
  }

  final graceWindowMs = graceWindowDays * msInDay;
  if ((expiresAt != null && expiresAt - now <= graceWindowMs) ||
      (entry.daysUntilExpirationIOS != null &&
          entry.daysUntilExpirationIOS! * msInDay <= graceWindowMs) ||
      entry.autoRenewingAndroid == false) {
    return SubscriptionPhase.expiringSoon;
  }

  return SubscriptionPhase.subscribed;
}
```

## StoreKit 2 Status API (iOS)

When you need to know the exact lifecycle phase on iOS, call `subscriptionStatusIOS`. This maps to StoreKit 2's `Product.SubscriptionInfo.Status` API and returns an array of status entries for the subscription group.

```dart
final statuses = await iap.subscriptionStatusIOS('yearly_subscription');
final latestState = statuses.isNotEmpty ? statuses.first.state : 'unknown';

switch (latestState) {
  case 'subscribed':
    print('Subscription is active');
    break;
  case 'inTrialPeriod':
    print('User is in free trial');
    break;
  case 'inGracePeriod':
    print('Auto-renewal failed, in grace period');
    break;
  case 'expired':
    print('Subscription expired');
    break;
}
```

### Phase Reference

| State Value | Meaning |
|------------|---------|
| `subscribed` | Subscription is active and billing is up to date |
| `expired` | Subscription is no longer active |
| `inGracePeriod` | Auto-renewal failed but StoreKit granted a grace period |
| `inBillingRetryPeriod` | Auto-renewal failed and StoreKit is retrying payment |
| `revoked` | Apple revoked the subscription (e.g., refunds) |
| `inIntroOfferPeriod` | User is in a paid introductory offer |
| `inTrialPeriod` | User is currently in the free-trial window |
| `paused` | Subscription manually paused by the user |

## Server-Side Validation

### iOS - App Store Server API

Validate receipts on your backend:

```dart
// Get receipt data
final receiptData = await iap.getReceiptDataIOS();

// Send to your backend for validation
final response = await http.post(
  Uri.parse('https://your-backend.com/validate-ios'),
  body: {'receipt_data': receiptData},
);
```

Backend validation (App Store verifyReceipt endpoint):

```javascript
const response = await fetch(
  'https://buy.itunes.apple.com/verifyReceipt',
  {
    method: 'POST',
    body: JSON.stringify({
      'receipt-data': receiptData,
      'password': SHARED_SECRET,
    }),
  }
);

const data = await response.json();
// Check data.status === 0 for valid receipt
// Inspect data.latest_receipt_info for is_trial_period, etc.
```

### Android - Google Play Developer API

Validate purchase tokens on your backend using Google Play Developer API to get detailed subscription phase data.

## Client-Side Validation (iOS)

For quick client-side validation on iOS:

```dart
final result = await iap.validateReceiptIOS(
  sku: 'yearly_subscription',
);

if (result.isValid) {
  print('Receipt is valid');
  print('JWS Representation: ${result.jwsRepresentation}');
} else {
  print('Receipt validation failed');
}
```

## Best Practices

1. **Use `subscriptionStatusIOS` for fast, on-device checks** when UI needs to react immediately (iOS only)
2. **Periodically upload receipts to your backend** for authoritative validation and entitlement provisioning
3. **Recalculate client caches** (`getAvailablePurchases`) after server reconciliation
4. **Combine both approaches**: Use client APIs for immediate feedback, server validation for security
5. **Handle both platforms**: Use `getActiveSubscriptions` for cross-platform checks, enhance with `subscriptionStatusIOS` on iOS

## Complete Flow Example

A typical subscription screen might:

1. Call `initConnection` and `fetchProducts` when mounted
2. Set up purchase listeners to observe updates
3. Fetch `getAvailablePurchases` on launch to restore entitlements
4. Query `subscriptionStatusIOS` (iOS) to display trial/grace period status
5. Sync receipts to your server to unlock cross-device access

```dart
class SubscriptionManager {
  final _iap = FlutterInappPurchase.instance;

  Future<void> initialize() async {
    await _iap.initConnection();

    // Restore purchases
    final purchases = await _iap.getAvailablePurchases();

    // Check subscription status (iOS)
    if (Platform.isIOS) {
      final statuses = await _iap.subscriptionStatusIOS('yearly_sub');
      final inTrial = statuses.any((s) => s.state == 'inTrialPeriod');
      print('In trial: $inTrial');
    }

    // Validate on server
    if (Platform.isIOS) {
      final receiptData = await _iap.getReceiptDataIOS();
      await validateOnServer(receiptData);
    }
  }
}
```

## Subscription Renewal Detection

iOS and Android handle subscription renewals differently, which affects how your app detects renewed subscriptions when the user opens the app.

### Platform Differences

| Platform | Behavior | Renewal Detection |
|----------|----------|-------------------|
| **iOS (StoreKit 2)** | Renewed subscriptions are automatically detected when the app launches | `purchaseUpdatedListener` fires for renewals; `getAvailablePurchases()` returns current entitlements |
| **Android (Google Play Billing)** | `purchaseUpdatedListener` does NOT fire for renewals that occurred while the app was closed | Must call `getAvailablePurchases()` and verify with server to detect renewals |

### Why This Matters

On Android, if a subscription renews while your app is closed (or the device is off), the `purchaseUpdatedListener` will not emit an event for that renewal when the app reopens. This means relying solely on the listener can result in users losing access to premium features until they make a new purchase.

### Recommended Solution: IAPKit Verification

Use <IapKitLink>IAPKit</IapKitLink> to get authoritative subscription status on app launch:

```dart
Future<void> checkSubscriptionStatusOnLaunch() async {
  final iap = FlutterInappPurchase.instance;

  // Get available purchases from the device
  final purchases = await iap.getAvailablePurchases();

  for (final purchase in purchases) {
    // Verify each purchase with IAPKit for authoritative status
    final result = await iap.verifyPurchaseWithProvider(
      VerifyPurchaseWithProviderProps(
        provider: VerifyPurchaseProvider.iapkit,
        iapkit: RequestVerifyPurchaseWithIapkitProps(
          apiKey: 'your-iapkit-api-key',
          apple: RequestVerifyPurchaseWithIapkitAppleProps(
            jws: purchase.purchaseToken,
          ),
          google: RequestVerifyPurchaseWithIapkitGoogleProps(
            purchaseToken: purchase.purchaseToken,
          ),
        ),
      ),
    );

    if (result.iapkit case final iapkit?) {
      switch (iapkit.state) {
        case IapkitPurchaseState.Entitled:
          // User has active subscription - grant access
          await grantPremiumAccess(purchase.productId);
        case IapkitPurchaseState.Expired:
          // Subscription expired - revoke access
          await revokePremiumAccess(purchase.productId);
        case IapkitPurchaseState.Canceled:
          // User canceled but may still have time remaining
          // Check expirationDate if available
        default:
          debugPrint('Purchase state: ${iapkit.state}');
      }
    }
  }
}
```

### IAPKit Purchase States

| State | Description | Action |
|-------|-------------|--------|
| `entitled` | User has active entitlement | Grant premium access |
| `expired` | Subscription has expired | Revoke premium access |
| `canceled` | User canceled, may have time remaining | Check expiration, show renewal prompt |
| `pending` | Purchase pending (e.g., parental approval) | Show pending state UI |
| `pending-acknowledgment` | Purchase needs acknowledgment (Android) | Call `finishTransaction()` |
| `inauthentic` | Purchase failed validation | Do not grant access, investigate |

### Custom Hook Example

Create a reusable hook to manage subscription status:

```dart
class SubscriptionStatusManager {
  final _iap = FlutterInappPurchase.instance;
  final String _apiKey;

  bool _isSubscribed = false;
  IapkitPurchaseState? _subscriptionState;

  SubscriptionStatusManager({required String apiKey}) : _apiKey = apiKey;

  bool get isSubscribed => _isSubscribed;
  IapkitPurchaseState? get subscriptionState => _subscriptionState;

  Future<void> refreshSubscriptionStatus(List<String> subscriptionIds) async {
    try {
      final purchases = await _iap.getAvailablePurchases();

      // Filter to subscription products only
      final subscriptionPurchases = purchases.where(
        (p) => subscriptionIds.contains(p.productId),
      );

      if (subscriptionPurchases.isEmpty) {
        _isSubscribed = false;
        _subscriptionState = null;
        return;
      }

      // Verify the most recent subscription purchase
      final purchase = subscriptionPurchases.first;
      final result = await _iap.verifyPurchaseWithProvider(
        VerifyPurchaseWithProviderProps(
          provider: VerifyPurchaseProvider.iapkit,
          iapkit: RequestVerifyPurchaseWithIapkitProps(
            apiKey: _apiKey,
            apple: RequestVerifyPurchaseWithIapkitAppleProps(
              jws: purchase.purchaseToken,
            ),
            google: RequestVerifyPurchaseWithIapkitGoogleProps(
              purchaseToken: purchase.purchaseToken,
            ),
          ),
        ),
      );

      if (result.iapkit case final iapkit?) {
        _subscriptionState = iapkit.state;
        _isSubscribed = iapkit.isValid;
      }
    } catch (e) {
      debugPrint('Failed to refresh subscription status: $e');
    }
  }
}
```

### When to Check Subscription Status

1. **App Launch** - Always check on `initState` or app resume
2. **After Purchase** - Verify immediately after `purchaseUpdatedListener` fires
3. **Periodically** - For long-running sessions, check every few hours
4. **On Demand** - When user accesses premium features

```dart
class PremiumScreen extends StatefulWidget {
  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> with WidgetsBindingObserver {
  final _subscriptionManager = SubscriptionStatusManager(
    apiKey: 'your-iapkit-api-key',
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkSubscription();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Check subscription when app comes to foreground
      _checkSubscription();
    }
  }

  Future<void> _checkSubscription() async {
    await _subscriptionManager.refreshSubscriptionStatus([
      'monthly_subscription',
      'yearly_subscription',
    ]);
    setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _subscriptionManager.isSubscribed
        ? PremiumContent()
        : SubscriptionPaywall();
  }
}
```

## Next Steps

- [Subscription Offers](./subscription-offers) - Handle subscription purchases
- [Error Handling](./error-handling) - Handle validation errors
- [Troubleshooting](./troubleshooting) - Debug validation issues
