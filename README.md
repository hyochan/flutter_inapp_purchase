# flutter_inapp_purchase

[![Pub Version](https://img.shields.io/pub/v/flutter_inapp_purchase.svg?style=flat-square)](https://pub.dartlang.org/packages/flutter_inapp_purchase)
[![Flutter CI](https://github.com/hyochan/flutter_inapp_purchase/actions/workflows/ci.yml/badge.svg)](https://github.com/hyochan/flutter_inapp_purchase/actions/workflows/ci.yml)
[![Coverage Status](https://codecov.io/gh/hyochan/flutter_inapp_purchase/branch/main/graph/badge.svg?token=WXBlKvRB2G)](https://codecov.io/gh/hyochan/flutter_inapp_purchase)
![License](https://img.shields.io/badge/license-MIT-blue.svg)

A comprehensive Flutter plugin for implementing in-app purchases on iOS and Android platforms.

## 📚 Documentation

For comprehensive documentation, installation guides, API reference, and examples, visit:

**🌐 [flutter-inapp-purchase.hyo.dev](https://flutter-inapp-purchase.hyo.dev)**

## 📦 Installation

```yaml
dependencies:
  flutter_inapp_purchase: ^6.0.0-rc.1
```

## 🔧 Quick Start

```dart
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

// Initialize connection
await FlutterInappPurchase.instance.initConnection();

// Get products
final products = await FlutterInappPurchase.instance.getProducts(['product_id']);

// Request purchase
await FlutterInappPurchase.instance.requestPurchase(
  RequestPurchase(
    ios: RequestPurchaseIosProps(sku: 'product_id'),
    android: RequestPurchaseAndroidProps(skus: ['product_id']),
  ),
  PurchaseType.inapp,
);
```

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.