---
title: flutter_inapp_purchase
sidebar_label: Introduction
sidebar_position: 1
---

import AdFitTopFixed from "@site/src/uis/AdFitTopFixed";
import Link from "@docusaurus/Link";

# flutter_inapp_purchase

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
  <iframe
    title="openiap-sponsor"
    src="https://ads.as.criteo.com/delivery/r/afr.php?z=up3WzS8Vkro4evgkPwGduw&u=%7C0739geO7I8towJ9tri5oCTiTmgX649oG34AhnPZq7c0%3D%7C&c1=0n2XosTo5ckbeNFvq0zVIcsyhyT3WKD0h8x1vhtYGkSkO0b8TwGJzvgWDUyB9U9Fk9ZEPKD72VQWkqPVpMQYPy2yS9pZ-gO7OSDPnT0hb1ilv1ey6SSH6LJIl4QhQltdlxZES-dRiryXmM58JoKZL8qIs-2JRvoDEk9wRGVWsaUskSiD7vkrBEvDeFkuD_lJ6oyxWcaW1EMCDtGleGpKNgE3Dn-r9IM1goBLqdz0EkvWQoN1vn9NJJ8N1AOaiKSa9QZfnvEbVTqv9Q47PJcA-Md9Fz5TUzSHAK3qqyQSVJqoKjmRVMm2a-sfm8V9KF8OUbcQQKnuvGlv8_ExxTj2k7ChvMfnEwWlrg3WI25BmwtEDwN4mHS5pdF4rQBPWdIuLGI2TeLZP6FmgryAnySUen9oCKaR3Qh_PCybMGtMZnmCiiPggRcJkTkBE0DdW3FBIXuqm_7kCiM8GLFkLy7KzaRt-uukAcAMFeCMlWK7cbx2mzh1Pjv_xs9rTqmpTQzs0gaTmtfheLGe1NAsPL4uPzodz94erRDVCgKA8BINzmc4aiE3suo5ySeylvtliNfez823Dtz0YTo6dWqfFdR1SCx93598rM2EY9rxboOW1hSASyCq2vjfu1a-8Pux_LW8BIwJSuq-KSq18JOld4sFJiSEs0a0JRv04pZWyr8urC_qUdHkkRU0PLM9tmnaFwAgOBjYirzo1W-fe-q3Z_SRP6dm2PGSgvqp6In3zHR2e0M&ct0=https%3A%2F%2Fkaat.daum.net%2Fad%2Fclick_thirdparty%3Bkyson_version%3D1.0%3Brequest_id%3Df03d71b0-2c6c-4d16-b1b4-281ae42a06b8-j0zr%3Badunit_id%3DDAN-YTmjDwlbcP42HBg6%3Btemplate_seq%3D%3Bsdk_type%3Dweb%3Bmed_dsp_id%3DCRITEO_NEW%3Bbid_id%3D68d015bc19f77f7b967055c069c00000%3Bdsp_id%3DCRITEO%3Bhratio%3D%3Bnetwork_type%3DGENERAL%3Bwratio%3D%3Bsdk_version%3D4.34.1%3Bad_type%3DBanner%3Bw%3D320%3Bh%3D100%3Bssp_id%3DKAKAO%3Bdevice_type%3DPC%3Bis_test%3Dfalse%3Bdummy%3D"
    width="320"
    height="100"
    frameBorder="0"
    scrolling="no"
    style={{border: 'none'}}
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
flutter pub add flutter_inapp_purchase:^6.8.0
```

```dart
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

// Initialize connection
await FlutterInappPurchase.instance.initConnection();

// Fetch product details with explicit type annotation
final List<Product> products = await FlutterInappPurchase.instance.fetchProducts(
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
