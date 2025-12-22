---
sidebar_position: 5
title: requestSubscription
---

import IapKitBanner from "@site/src/uis/IapKitBanner";

# requestSubscription() *(Deprecated)*

<IapKitBanner />

> ⚠️ **Deprecated:** `requestSubscription()` remains for backwards compatibility with the v5 API. New code should call [`requestPurchase()`](./request-purchase.md) with either `PurchaseType.subs` (legacy API) or the unified [`RequestPurchaseProps`](../../api/classes/flutter-inapp-purchase.md#requestpurchase) flow.

## Overview

`requestSubscription()` starts the platform subscription purchase flow using the legacy method signature that predates the OpenIAP migration. The method still works but is implemented as a thin wrapper around `requestPurchase()`.

Use this API only while migrating older code. All new implementations should move to `requestPurchase()` so you can take advantage of the typed request builder and platform-specific props.

## Signature

```dart
Future<dynamic> requestSubscription(
  String productId, {
  int? prorationModeAndroid,
  String? obfuscatedAccountIdAndroid,
  String? obfuscatedProfileIdAndroid,
  String? purchaseTokenAndroid,
  int? offerTokenIndex,
})
```

## Parameters

- `productId` – Subscription identifier to purchase
- `prorationModeAndroid` *(Android only)* – BillingClient proration mode for upgrades/downgrades
- `obfuscatedAccountIdAndroid` *(Android only)* – Stable per-account identifier for Play Billing
- `obfuscatedProfileIdAndroid` *(Android only)* – Stable per-profile identifier for Play Billing
- `purchaseTokenAndroid` *(Android only, deprecated)* – Legacy upgrade token (use the new `purchaseToken` field via `requestPurchase()` instead)
- `offerTokenIndex` *(Android only)* – Index of the subscription offer to purchase

## Migration Guide

### Old code (legacy):

```dart
await FlutterInappPurchase.instance.requestSubscription('com.example.monthly');
```

### Recommended replacement:

```dart
await FlutterInappPurchase.instance.requestPurchase(
  request: RequestPurchase(
    ios: RequestPurchaseIOS(sku: 'com.example.monthly'),
    android: RequestPurchaseAndroid(skus: ['com.example.monthly']),
  ),
  type: PurchaseType.subs,
);
```

Or, when using the new OpenIAP helpers:

```dart
await FlutterInappPurchase.instance.requestPurchaseWithBuilder(
  build: (builder) {
    builder
      ..type = ProductQueryType.Subs
      ..ios.sku = 'com.example.monthly'
      ..android.skus = ['com.example.monthly'];
  },
);
```

## Notes

- The method simply forwards to [`requestPurchase()`](./request-purchase.md); no new features will be added here.
- `purchaseTokenAndroid` is maintained for binary compatibility but should be replaced with the new `purchaseToken` property when using `RequestPurchaseProps`.
- This method will be removed in a future major release (7.0). Plan your migration accordingly.
