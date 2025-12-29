---
sidebar_position: 0
---

import IapKitBanner from "@site/src/uis/IapKitBanner";

# Migration from v8.1

<IapKitBanner />

This guide helps you migrate from flutter_inapp_purchase v8.1.x to v8.2.0.

## Breaking Changes

### PurchaseState Enum Simplified

The `PurchaseState` enum has been simplified by removing unused states. This is a breaking change if you're explicitly handling these states.

**Before (v8.1.x):**
```dart
enum PurchaseState {
  Pending,
  Purchased,
  Failed,      // REMOVED
  Restored,    // REMOVED
  Deferred,    // REMOVED
  Unknown,
}

// Example: handling purchase states
switch (purchase.purchaseState) {
  case PurchaseState.Purchased:
    // Grant entitlement
    break;
  case PurchaseState.Failed:
    // Handle failure - NO LONGER VALID
    break;
  case PurchaseState.Restored:
    // Handle restore - NO LONGER VALID
    break;
  case PurchaseState.Deferred:
    // Handle pending approval - NO LONGER VALID
    break;
  case PurchaseState.Pending:
  case PurchaseState.Unknown:
    // Handle pending/unknown
    break;
}
```

**After (v8.2.0):**
```dart
enum PurchaseState {
  Pending,
  Purchased,
  Unknown,
}

// Example: handling purchase states
switch (purchase.purchaseState) {
  case PurchaseState.Purchased:
    // Grant entitlement (includes restored purchases)
    break;
  case PurchaseState.Pending:
    // Purchase is pending (includes deferred on Android)
    break;
  case PurchaseState.Unknown:
    // Unknown state - handle appropriately
    break;
}
```

**Why were these states removed?**

| Removed State | Reason |
|---------------|--------|
| `Failed` | Both platforms return errors instead of Purchase objects on failure. Use `purchaseErrorListener` instead. |
| `Restored` | Restored purchases now return as `Purchased` state. |
| `Deferred` | iOS StoreKit 2 has no transaction state; Android uses `Pending`. |

**Migration steps:**

1. Remove any `case PurchaseState.Failed:`, `case PurchaseState.Restored:`, and `case PurchaseState.Deferred:` from switch statements
2. For failure handling, use `purchaseErrorListener`:
   ```dart
   iap.purchaseErrorListener.listen((error) {
     print('Purchase failed: ${error.message}');
   });
   ```
3. Restored purchases will come through as `PurchaseState.Purchased`
4. Deferred purchases will come through as `PurchaseState.Pending` on Android

## Deprecations

### AlternativeBillingModeAndroid Deprecated

`AlternativeBillingModeAndroid` is deprecated in favor of the unified `BillingProgramAndroid` enum.

**Before (deprecated):**
```dart
await iap.initConnection(
  alternativeBillingModeAndroid: AlternativeBillingModeAndroid.UserChoice,
);

// or
await iap.initConnection(
  alternativeBillingModeAndroid: AlternativeBillingModeAndroid.AlternativeOnly,
);
```

**After (recommended):**
```dart
await iap.initConnection(
  enableBillingProgramAndroid: BillingProgramAndroid.UserChoiceBilling,
);

// or
await iap.initConnection(
  enableBillingProgramAndroid: BillingProgramAndroid.ExternalOffer,
);
```

**Migration mapping:**

| Deprecated | Recommended |
|------------|-------------|
| `AlternativeBillingModeAndroid.UserChoice` | `BillingProgramAndroid.UserChoiceBilling` |
| `AlternativeBillingModeAndroid.AlternativeOnly` | `BillingProgramAndroid.ExternalOffer` |

### useAlternativeBilling Deprecated

`RequestPurchaseProps.useAlternativeBilling` is deprecated. It only logged debug info and had no effect on purchase flow.

**Before (deprecated):**
```dart
await iap.requestPurchase(
  RequestPurchaseProps.inApp((
    apple: RequestPurchaseIosProps(sku: 'product_id'),
    useAlternativeBilling: true,  // DEPRECATED - no effect
  )),
);
```

**After (recommended):**
```dart
// For iOS external purchases, use presentExternalPurchaseLinkIOS
final result = await iap.presentExternalPurchaseLinkIOS(
  'https://your-site.com/checkout',
);
```

## New Features

### BillingProgramAndroid.UserChoiceBilling

A new enum value has been added to `BillingProgramAndroid` for User Choice Billing:

```dart
enum BillingProgramAndroid {
  Unspecified,
  UserChoiceBilling,     // NEW in v8.2.0
  ExternalContentLink,
  ExternalOffer,
  ExternalPayments,
}
```

This allows you to check User Choice Billing availability:

```dart
final availability = await iap.isBillingProgramAvailableAndroid(
  BillingProgramAndroid.UserChoiceBilling,
);

if (availability.isAvailable) {
  // User Choice Billing is available
}
```

## Dependencies Update

Update your `pubspec.yaml`:

```yaml
dependencies:
  flutter_inapp_purchase: ^8.2.0
```

The plugin automatically uses:
- `openiap-apple`: 1.3.9
- `openiap-google`: 1.3.21
- `openiap-gql`: 1.3.11

## References

- [Google Play Billing - Purchase.PurchaseState](https://developer.android.com/reference/com/android/billingclient/api/Purchase.PurchaseState)
- [Apple StoreKit 2 - Product.PurchaseResult](https://developer.apple.com/documentation/storekit/product/purchaseresult)
- [Apple StoreKit 1 - SKPaymentTransactionState (Deprecated)](https://developer.apple.com/documentation/storekit/skpaymenttransactionstate)
