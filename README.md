# flutter_inapp_purchase

<div align="center">
  <img src="https://hyochan.github.io/flutter_inapp_purchase/img/logo.png" width="200" alt="flutter_inapp_purchase logo" />
  
  [![Pub Version](https://img.shields.io/pub/v/flutter_inapp_purchase.svg?style=flat-square)](https://pub.dartlang.org/packages/flutter_inapp_purchase) [![Flutter CI](https://github.com/hyochan/flutter_inapp_purchase/actions/workflows/ci.yml/badge.svg)](https://github.com/hyochan/flutter_inapp_purchase/actions/workflows/ci.yml) [![OpenIAP](https://img.shields.io/badge/OpenIAP-Compliant-green?style=flat-square)](https://openiap.dev) [![Coverage Status](https://codecov.io/gh/hyochan/flutter_inapp_purchase/branch/main/graph/badge.svg?token=WXBlKvRB2G)](https://codecov.io/gh/hyochan/flutter_inapp_purchase) ![License](https://img.shields.io/badge/license-MIT-blue.svg)
  
  A comprehensive Flutter plugin for implementing in-app purchases that conforms to the [Open IAP specification](https://openiap.dev)

<a href="https://openiap.dev"><img src="https://github.com/hyodotdev/openiap/blob/main/logo.png" alt="Open IAP" height="40" /></a>

</div>

## 📚 Documentation

**[📖 Visit our comprehensive documentation site →](https://hyochan.github.io/flutter_inapp_purchase)**

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

## Sponsors

💼 **[View Our Sponsors](https://openiap.dev/sponsors)**

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.
