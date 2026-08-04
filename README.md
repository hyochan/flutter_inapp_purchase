> [!IMPORTANT]
> **⚠️ This repository has moved to [hyodotdev/openiap](https://github.com/hyodotdev/openiap).** flutter_inapp_purchase is now developed in the monorepo at [`libraries/flutter_inapp_purchase`](https://github.com/hyodotdev/openiap/tree/main/libraries/flutter_inapp_purchase) — this repository is archived and read-only.

<div align="center">

<a href="https://github.com/hyodotdev/openiap">
  <img src="https://raw.githubusercontent.com/hyodotdev/openiap/main/logo.png" alt="OpenIAP" height="56" />
</a>

## 📦 This project now lives in the OpenIAP monorepo

**flutter_inapp_purchase is actively maintained — development simply moved home.**<br/>
This repository is archived and kept read-only as history.

|                    |                                                                                                              |
| ------------------ | ------------------------------------------------------------------------------------------------------------ |
| 🧭 **Source code** | [hyodotdev/openiap → libraries/flutter_inapp_purchase](https://github.com/hyodotdev/openiap/tree/main/libraries/flutter_inapp_purchase)        |
| 🏠 **Monorepo**    | [hyodotdev/openiap](https://github.com/hyodotdev/openiap)                                                    |
| 📚 **Docs**        | [openiap.dev/docs/setup/flutter](https://openiap.dev/docs/setup/flutter) · [legacy docs](https://hyochan.github.io/flutter_inapp_purchase)                                    |
| 🐛 **Issues**      | [hyodotdev/openiap/issues](https://github.com/hyodotdev/openiap/issues)                                      |
| 💬 **Q&A**         | [flutter_inapp_purchase discussions](https://github.com/hyodotdev/openiap/discussions/categories/flutter_inapp_purchase)                       |

The pub.dev package name is unchanged — `flutter pub add flutter_inapp_purchase` keeps working as always.

<sub>Background: [📢 announcement issue](https://github.com/hyochan/flutter_inapp_purchase/issues/633) · [discussion thread](https://github.com/hyochan/flutter_inapp_purchase/discussions/632)</sub>

</div>

---

# flutter_inapp_purchase

<div align="center">
  <img src="https://hyochan.github.io/flutter_inapp_purchase/img/logo.png" width="200" alt="flutter_inapp_purchase logo" />
  
  [![Pub Version](https://img.shields.io/pub/v/flutter_inapp_purchase.svg?style=flat-square)](https://pub.dartlang.org/packages/flutter_inapp_purchase) [![Flutter CI](https://github.com/hyochan/flutter_inapp_purchase/actions/workflows/ci.yml/badge.svg)](https://github.com/hyochan/flutter_inapp_purchase/actions/workflows/ci.yml) [![OpenIAP](https://img.shields.io/badge/OpenIAP-Compliant-green?style=flat-square)](https://openiap.dev) [![Coverage Status](https://codecov.io/gh/hyochan/flutter_inapp_purchase/branch/main/graph/badge.svg?token=WXBlKvRB2G)](https://codecov.io/gh/hyochan/flutter_inapp_purchase) ![License](https://img.shields.io/badge/license-MIT-blue.svg)
  
  A comprehensive Flutter plugin for implementing in-app purchases that conforms to the [Open IAP specification](https://openiap.dev)

<a href="https://openiap.dev"><img src="https://github.com/hyodotdev/openiap/blob/main/logo.png" alt="Open IAP" height="40" /></a>

</div>

## 📚 Documentation

**[📖 Visit the documentation →](https://openiap.dev/docs/setup/flutter)**

## 📦 Installation

```yaml
dependencies:
  flutter_inapp_purchase: ^8.0.0
```

## 🔧 Quick Start

### Basic Usage

```dart
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

// Create instance
final iap = FlutterInappPurchase();

// Initialize connection
await iap.initConnection();

// Fetch products with explicit type
final products = await iap.fetchProducts<Product>(
  skus: ['product_id'],
  type: ProductQueryType.InApp,
);

// Request purchase (builder DSL)
await iap.requestPurchaseWithBuilder(
  build: (builder) {
    builder
      ..type = ProductQueryType.InApp
      ..android.skus = ['product_id']
      ..ios.sku = 'product_id';
  },
);
```

## Using with AI Assistants

flutter_inapp_purchase provides AI-friendly documentation for Cursor, GitHub Copilot, Claude, and ChatGPT.

**[AI Assistants Guide](https://hyochan.github.io/flutter_inapp_purchase/docs/guides/ai-assistants)**

Quick links:
- [llms.txt](https://hyochan.github.io/flutter_inapp_purchase/llms.txt) - Quick reference
- [llms-full.txt](https://hyochan.github.io/flutter_inapp_purchase/llms-full.txt) - Full API reference

## Development

See [CONTRIBUTING.md](CONTRIBUTING.md) for development setup and guidelines.

### Singleton Usage

For global state management or when you need a shared instance:

```dart
// Use singleton instance
final iap = FlutterInappPurchase.instance;
await iap.initConnection();

// The instance is shared across your app
final sameIap = FlutterInappPurchase.instance; // Same instance
```

## Powered by OpenIAP

<a href="https://openiap.dev"><img src="https://github.com/hyodotdev/openiap/blob/main/logo.png" alt="OpenIAP" height="50" /></a>

flutter_inapp_purchase conforms to the **[OpenIAP specification](https://openiap.dev)** — an open, vendor-neutral interoperability standard for in-app purchases. OpenIAP provides:

- **Shared specification** — Common types, error codes, and purchase flows across all platforms
- **Generated type-safe bindings** — Swift, Kotlin, Dart, and GDScript from a single GraphQL schema
- **Platform implementations** — [openiap-apple](https://github.com/hyodotdev/openiap/tree/main/packages/apple) (StoreKit 2) and [openiap-google](https://github.com/hyodotdev/openiap/tree/main/packages/google) (Play Billing 8.x)
- **Verification profiles** — Standardized receipt validation and purchase verification patterns

Other libraries built on OpenIAP: [react-native-iap](https://github.com/hyodotdev/openiap/tree/main/libraries/react-native-iap) · [expo-iap](https://github.com/hyodotdev/openiap/tree/main/libraries/expo-iap) · [kmp-iap](https://github.com/hyodotdev/openiap/tree/main/libraries/kmp-iap) · [maui-iap](https://github.com/hyodotdev/openiap/tree/main/libraries/maui-iap) · [godot-iap](https://github.com/hyodotdev/openiap/tree/main/libraries/godot-iap)

**[Learn more about the OpenIAP standard →](https://openiap.dev/docs/foundation/about)**

## Sponsors

💼 **[View Our Sponsors](https://openiap.dev/sponsors)**

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.
