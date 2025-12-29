---
title: API Reference
sidebar_position: 1
---

import IapKitBanner from "@site/src/uis/IapKitBanner";

# API Reference

<IapKitBanner />

Complete reference for flutter_inapp_purchase v6.8.0 - A unified API for implementing in-app purchases across iOS and Android platforms.

## Available APIs

### Core Methods

Essential methods for initializing connections, loading products, and processing purchases.

- **Connection Management**: `initConnection()`
- **Product Loading**: `fetchProducts()`
- **Purchase Processing**: `requestPurchase()`, `requestPurchaseWithBuilder()`
- **Purchase History**: `getAvailablePurchases([PurchaseOptions?])`
- **Transaction Management**: `finishTransaction()`, `consumePurchase()`

### Platform-Specific Methods

Access iOS and Android specific features and capabilities.

- **iOS Features**: Offer code redemption, subscription management, StoreKit 2 support
- **Android Features**: Billing client state, pending purchases, deep links

### Event Listeners (Open IAP Spec)

Real-time streams for monitoring purchase events and connection states.

- **purchaseUpdatedListener**: Stream for successful purchase updates
- **purchaseErrorListener**: Stream for purchase errors
- **Connection Events**: Store connection status updates

### Types & Enums

Comprehensive type definitions for type-safe development.

- **Request Objects**: Platform-specific purchase and product requests
- **Response Models**: Products, purchases, and transaction data
- **Error Handling**: Detailed error codes and messages

## Quick Start

### Instance Management

flutter_inapp_purchase provides flexible instance management:

```dart
// Option 1: Create your own instance (recommended for most cases)
final iap = FlutterInappPurchase();

// Option 2: Use singleton for global state management
final iap = FlutterInappPurchase.instance;
```

### Basic Implementation

```dart
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

class PurchaseManager {
  final FlutterInappPurchase iap = FlutterInappPurchase();
  StreamSubscription<Purchase>? _purchaseSubscription;
  StreamSubscription<PurchaseError>? _errorSubscription;

  Future<void> initializePurchases() async {
    // Initialize connection
    await iap.initConnection();

    // Set up listeners (Open IAP spec)
    _purchaseSubscription = iap.purchaseUpdatedListener.listen(
      (purchase) {
        handlePurchaseSuccess(purchase);
      },
    );

    _errorSubscription = iap.purchaseErrorListener.listen(
      (error) {
        handlePurchaseError(error);
      },
    );
  }

  Future<void> makePurchase(String productId) async {
    await iap.requestPurchase(
      RequestPurchaseProps.inApp((
        apple: RequestPurchaseIosProps(sku: productId, quantity: 1),
        google: RequestPurchaseAndroidProps(skus: [productId]),
        useAlternativeBilling: null,
      )),
    );
  }
}
```

## Dart Type Safety

flutter_inapp_purchase provides full type safety with comprehensive type definitions for all methods, parameters, and return values.

## Platform Compatibility

- **iOS**: 12.0+ with StoreKit 2 (iOS 15.0+) and StoreKit 1 fallback
- **Android**: API level 21+ with Google Play Billing Client v8

## Need Help?

- Check our [Troubleshooting Guide](../guides/troubleshooting.md)
- Review [Migration Guide](../migration/from-v5.md) for v5 to v6 updates
- Browse [example implementations](https://github.com/hyochan/flutter_inapp_purchase/tree/main/example)
- Join the [Flutter Community](https://flutter.dev/community) for support
