---
title: API Reference
sidebar_position: 1
---

# API Reference
Complete reference for flutter_inapp_purchase v6.0.0 - A unified API for implementing in-app purchases across iOS and Android platforms.

## Available APIs

### 🏪 Core Methods
Essential methods for initializing connections, loading products, and processing purchases.

- **Connection Management**: `initConnection()`, `finalize()`
- **Product Loading**: `getProducts()`, `getSubscriptions()`
- **Purchase Processing**: `requestPurchase()`, `requestSubscription()`
- **Transaction Management**: `finishTransaction()`, `consumePurchase()`

### 📱 Platform-Specific Methods
Access iOS and Android specific features and capabilities.

- **iOS Features**: Offer code redemption, subscription management, StoreKit 2 support
- **Android Features**: Billing client state, pending purchases, deep links

### 🎧 Event Listeners
Real-time streams for monitoring purchase events and connection states.

- **Purchase Events**: Success, errors, and state changes
- **Connection Events**: Store connection status updates

### 🔧 Types & Enums
Comprehensive type definitions for type-safe development.

- **Request Objects**: Platform-specific purchase and product requests
- **Response Models**: Products, purchases, and transaction data
- **Error Handling**: Detailed error codes and messages

## Quick Start

```dart
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

class PurchaseManager {
  StreamSubscription<PurchasedItem?>? _purchaseSubscription;
  StreamSubscription<PurchaseResult?>? _errorSubscription;

  Future<void> initializePurchases() async {
    // Initialize connection
    await FlutterInappPurchase.instance.initConnection();
    
    // Set up listeners
    _purchaseSubscription = FlutterInappPurchase.purchaseUpdated.listen(
      (purchase) {
        if (purchase != null) {
          handlePurchaseSuccess(purchase);
        }
      },
    );
    
    _errorSubscription = FlutterInappPurchase.purchaseError.listen(
      (error) {
        if (error != null) {
          handlePurchaseError(error);
        }
      },
    );
  }
  
  Future<void> makePurchase(String productId) async {
    await FlutterInappPurchase.instance.requestPurchase(
      request: RequestPurchase(
        ios: RequestPurchaseIOS(sku: productId, quantity: 1),
        android: RequestPurchaseAndroid(skus: [productId]),
      ),
      type: PurchaseType.inapp,
    );
  }
}
```

## TypeScript Support

flutter_inapp_purchase provides full type safety with comprehensive type definitions for all methods, parameters, and return values.

## Platform Compatibility

- **iOS**: 12.0+ with StoreKit 2 (iOS 15.0+) and StoreKit 1 fallback
- **Android**: API level 21+ with Google Play Billing Client v8

## Need Help?

- Check our [Troubleshooting Guide](../guides/troubleshooting.md)
- Review [Migration Guide](../migration/from-v5.md) for v5 to v6 updates
- Browse [example implementations](https://github.com/hyochan/flutter_inapp_purchase/tree/main/example)
- Join the [Flutter Community](https://flutter.dev/community) for support