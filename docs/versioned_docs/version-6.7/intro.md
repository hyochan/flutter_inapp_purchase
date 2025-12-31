---
title: flutter_inapp_purchase
sidebar_label: Introduction
sidebar_position: 1
slug: /
---

# flutter_inapp_purchase

A comprehensive Flutter plugin for implementing in-app purchases that **conforms to the [Open IAP specification](https://openiap.dev)**.

<div style={{textAlign: 'center', margin: '2rem 0'}}>
  <img
    src={require("@site/static/img/logo.png").default}
    alt="flutter_inapp_purchase Logo"
    style={{maxWidth: '100%', height: 'auto'}}
  />
</div>

## What is flutter_inapp_purchase?

This is an **In App Purchase** plugin for Flutter. This project has been **forked** from [react-native-iap](https://github.com/hyochan/react-native-iap). We are trying to share same experience of **in-app-purchase** in **flutter** as in **react-native**.

We will keep working on it as time goes by just like we did in **react-native-iap**.

## Key Features

- **Cross-platform**: Works seamlessly on both iOS and Android
- **StoreKit 2 Support**: Full StoreKit 2 support for iOS 15.0+ with automatic fallback
- **Billing Client v8**: Latest Android Billing Client features
- **Type-safe**: Complete TypeScript-like support with Dart strong typing
- **Comprehensive Error Handling**: Detailed error codes and user-friendly messages
- **Subscription Management**: Advanced subscription handling and validation
- **Receipt Validation**: Built-in receipt validation for both platforms

## What this plugin does

- **Product Management**: Fetch and manage consumable and non-consumable products
- **Purchase Flow**: Handle complete purchase workflows with proper error handling
- **Subscription Support**: Full subscription lifecycle management
- **Receipt Validation**: Validate purchases on both platforms
- **Store Communication**: Direct communication with App Store and Google Play
- **Error Recovery**: Comprehensive error handling and recovery mechanisms

## Platform Support

| Feature                  | iOS | Android |
| ------------------------ | --- | ------- |
| Products & Subscriptions | ✅  | ✅      |
| Purchase Flow            | ✅  | ✅      |
| Receipt Validation       | ✅  | ✅      |
| Subscription Management  | ✅  | ✅      |
| Promotional Offers       | ✅  | N/A     |
| StoreKit 2               | ✅  | N/A     |
| Billing Client v8        | N/A | ✅      |

## Version Information

- **Current Version**: 6.7.0
- **Flutter Compatibility**: Flutter 3.x+
- **iOS Requirements**: iOS 11.0+
- **Android Requirements**: API level 21+

## Quick Start

Get started with flutter_inapp_purchase in minutes:

```bash
flutter pub add flutter_inapp_purchase
```

```dart
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

// Initialize connection
await FlutterInappPurchase.instance.initConnection();

// Fetch product details
final products = await FlutterInappPurchase.instance.fetchProducts(
  skus: ['product_id'],
  type: PurchaseType.inapp,
);

// Build a platform-aware purchase request
final purchaseRequest = RequestPurchase(
  ios: RequestPurchaseIOS(sku: 'product_id', quantity: 1),
  android: RequestPurchaseAndroid(skus: ['product_id']),
);

// Request purchase
await FlutterInappPurchase.instance.requestPurchase(
  request: purchaseRequest,
  type: PurchaseType.inapp,
);

// Restore active purchases (include expired iOS receipts if needed)
final purchases = await FlutterInappPurchase.instance.getAvailablePurchases(
  const PurchaseOptions(
    onlyIncludeActiveItemsIOS: true,
  ),
);
```

## What's Next?

<div className="grid grid-cols-1 md:grid-cols-2 gap-4 my-8">
  <div className="card">
    <div className="card-body">
      <h3>Getting Started</h3>
      <p>Learn how to install and configure flutter_inapp_purchase in your project.</p>
      <a href="/docs/getting-started/installation" className="button button--primary">Get Started →</a>
    </div>
  </div>
  
  <div className="card">
    <div className="card-body">
      <h3>Guides</h3>
      <p>Follow step-by-step guides for implementing purchases and subscriptions.</p>
      <a href="/docs/guides/purchases" className="button button--secondary">View Guides →</a>
    </div>
  </div>
  
  <div className="card">
    <div className="card-body">
      <h3>API Reference</h3>
      <p>Comprehensive API documentation with examples and type definitions.</p>
      <a href="/docs/api/" className="button button--secondary">API Docs →</a>
    </div>
  </div>
  
  <div className="card">
    <div className="card-body">
      <h3>Examples</h3>
      <p>Real-world examples and implementation patterns.</p>
      <a href="/docs/examples/basic-store" className="button button--secondary">See Examples →</a>
    </div>
  </div>
</div>

## Community & Support

This project is maintained by [hyochan](https://github.com/hyochan).

- **GitHub Issues**: [Report bugs and feature requests](https://github.com/hyochan/flutter_inapp_purchase/issues)
- **Discussions**: [Join community discussions](https://github.com/hyochan/flutter_inapp_purchase/discussions)
- **Contributing**: [Contribute to the project](https://github.com/hyochan/flutter_inapp_purchase/blob/main/CONTRIBUTING.md)

---

Ready to implement in-app purchases in your Flutter app? Let's [get started](/docs/getting-started/installation)!
