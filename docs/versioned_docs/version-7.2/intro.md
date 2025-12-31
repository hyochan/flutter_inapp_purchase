---
title: flutter_inapp_purchase
sidebar_label: Introduction
sidebar_position: 1
slug: /
---

import Link from "@docusaurus/Link";
import IapKitBanner from "@site/src/uis/IapKitBanner";

# flutter_inapp_purchase

<IapKitBanner />

A comprehensive Flutter plugin for implementing in-app purchases that **conforms to the [Open IAP specification](https://openiap.dev)**.

<div
  style={{
    display: 'flex',
    justifyContent: 'center',
    alignItems: 'center',
    gap: '2rem',
    margin: '2rem 0',
    flexWrap: 'wrap',
  }}
>
  <img
    src={require("@site/static/img/logo.png").default}
    alt="flutter_inapp_purchase Logo"
    style={{maxWidth: '280px', width: '60%', height: 'auto'}}
  />
</div>

## What is flutter_inapp_purchase?

This is an **In App Purchase** plugin for Flutter. This project has been **forked** from [react-native-iap](https://github.com/hyochan/react-native-iap). We are trying to share same experience of **in-app-purchase** in **flutter** as in **react-native**.

We will keep working on it as time goes by just like we did in **react-native-iap**.

## What this plugin does

- **Product Management**: Fetch and manage consumable and non-consumable products
- **Purchase Flow**: Handle complete purchase workflows with proper error handling
- **Subscription Support**: Full subscription lifecycle management
- **Receipt Validation**: Validate purchases on both platforms
- **Store Communication**: Direct communication with App Store and Google Play
- **Error Recovery**: Comprehensive error handling and recovery mechanisms

## Quick Start

Get started with flutter_inapp_purchase in minutes:

```bash
flutter pub add flutter_inapp_purchase
```

```dart
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

// Initialize connection
await FlutterInappPurchase.instance.initConnection();

// Fetch product details with explicit type parameter
final products = await FlutterInappPurchase.instance.fetchProducts<Product>(
  skus: ['product_id'],
  type: ProductQueryType.InApp,
);

// Request purchase
final requestProps = RequestPurchaseProps.inApp(
  request: RequestPurchasePropsByPlatforms(
    ios: RequestPurchaseIosProps(
      sku: 'product_id',
      quantity: 1,
    ),
    android: RequestPurchaseAndroidProps(
      skus: ['product_id'],
    ),
  ),
);

await FlutterInappPurchase.instance.requestPurchase(requestProps);

// Restore active purchases (include expired iOS receipts if needed)
final purchases = await FlutterInappPurchase.instance.getAvailablePurchases(
  PurchaseOptions(
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
      <Link to="/docs/getting-started/installation" className="button button--primary">Get Started →</Link>
    </div>
  </div>
  
  <div className="card">
    <div className="card-body">
      <h3>Guides</h3>
      <p>Follow step-by-step guides for implementing purchases and subscriptions.</p>
      <Link to="/docs/guides/purchases" className="button button--secondary">View Guides →</Link>
    </div>
  </div>
  
  <div className="card">
    <div className="card-body">
      <h3>API Reference</h3>
      <p>Comprehensive API documentation with examples and type definitions.</p>
      <Link to="/docs/api/" className="button button--secondary">API Docs →</Link>
    </div>
  </div>
  
  <div className="card">
    <div className="card-body">
      <h3>Examples</h3>
      <p>Real-world examples and implementation patterns.</p>
      <Link to="/docs/examples/basic-store" className="button button--secondary">See Examples →</Link>
    </div>
  </div>
</div>

Ready to implement in-app purchases in your Flutter app? Let's <Link to="/docs/getting-started/installation">get started</Link>!

## Sponsors & Community Support

We're building the OpenIAP ecosystem—defining the spec at
[openiap.dev](https://www.openiap.dev), maintaining
[openiap](https://github.com/hyodotdev/openiap) for the shared type
system, and shipping native SDKs such as
[openiap-apple](https://github.com/hyodotdev/openiap-apple) and
[openiap-google](https://github.com/hyodotdev/openiap-google). These modules
power [expo-iap](https://github.com/hyochan/expo-iap),
[flutter_inapp_purchase](https://github.com/hyochan/flutter_inapp_purchase), [kmp-iap](https://github.com/hyochan/kmp-iap), and [react-native-iap](https://github.com/hyochan/react-native-iap). After
simplifying fragmented APIs, the next milestone is a streamlined purchase flow:
`initConnection → fetchProducts → requestPurchase → (server receipt validation) → finishTransaction`.

Your sponsorship keeps this work moving—ensuring more developers across
platforms, OS, and frameworks can implement IAPs without headaches while we
expand to additional plugins and payment systems. Sponsors receive shout-outs
in each release and, depending on tier, can request tailored support. If you’re
interested—or have rollout feedback to share—you can view sponsorship options at
[openiap.dev/sponsors](https://www.openiap.dev/sponsors).

This project is maintained by [hyochan](https://github.com/hyochan).

- **GitHub Issues**: [Report bugs and feature requests](https://github.com/hyochan/flutter_inapp_purchase/issues)
- **Discussions**: [Join community discussions](https://github.com/hyochan/flutter_inapp_purchase/discussions)
- **Slack**: [Join the real-time chat](http://hyo.dev/joinSlack)
- **Contributing**: [Contribute to the project](https://github.com/hyochan/flutter_inapp_purchase/blob/main/CONTRIBUTING.md)
