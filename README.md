# flutter_inapp_purchase

<div align="center">
  <img src="https://hyochan.github.io/flutter_inapp_purchase/img/logo.png" width="200" alt="flutter_inapp_purchase logo" />
  
  [![Pub Version](https://img.shields.io/pub/v/flutter_inapp_purchase.svg?style=flat-square)](https://pub.dartlang.org/packages/flutter_inapp_purchase) [![Flutter CI](https://github.com/hyochan/flutter_inapp_purchase/actions/workflows/ci.yml/badge.svg)](https://github.com/hyochan/flutter_inapp_purchase/actions/workflows/ci.yml) [![Coverage Status](https://codecov.io/gh/hyochan/flutter_inapp_purchase/branch/main/graph/badge.svg?token=WXBlKvRB2G)](https://codecov.io/gh/hyochan/flutter_inapp_purchase) ![License](https://img.shields.io/badge/license-MIT-blue.svg)
  
  A comprehensive Flutter plugin for implementing in-app purchases that conforms to the [Open IAP specification](https://openiap.dev)

<a href="https://openiap.dev"><img src="https://openiap.dev/logo.png" alt="Open IAP" height="40" /></a>

</div>

## 📚 Documentation

**[📖 Visit our comprehensive documentation site →](https://hyochan.github.io/flutter_inapp_purchase)**

## 📦 Installation

```yaml
dependencies:
  flutter_inapp_purchase: ^6.8.6
```

## 🔧 Quick Start

### Basic Usage

```dart
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

// Create instance
final iap = FlutterInappPurchase();

// Initialize connection
await iap.initConnection();

// Fetch products
final products = await iap.fetchProducts(
  ProductRequest(
    skus: ['product_id'],
    type: ProductQueryType.InApp,
  ),
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

### iOS Notes

- This plugin uses the OpenIAP Apple native module via CocoaPods (`openiap 1.1.9`).
- After upgrading, run `pod install` in your iOS project (e.g., `example/ios`).
- Minimum iOS deployment target is `15.0` for StoreKit 2 support.

## 🛠️ Development

- Install dependencies: `flutter pub get`
- Run lints: `dart analyze`
- Run tests: `flutter test`
- Enable Git hooks (recommended): `git config core.hooksPath .githooks`
  - The pre-commit hook auto-formats staged Dart files and fails if any file remains unformatted. It also runs tests.
  - Tests: runs changed tests first, then full suite (fail-fast).
  - Env toggles:
    - `SKIP_PRECOMMIT_TESTS=1` to skip tests
    - `PRECOMMIT_TEST_CONCURRENCY=<N>` to control concurrency (default 4)
    - `PRECOMMIT_FAIL_FAST=0` to disable `--fail-fast`
    - `PRECOMMIT_RUN_ALL_TESTS=0` to only run changed tests
    - `ENFORCE_ANALYZE=1` to fail commit on analyzer warnings

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
