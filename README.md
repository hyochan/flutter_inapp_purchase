# flutter_inapp_purchase

[![Pub Version](https://img.shields.io/pub/v/flutter_inapp_purchase.svg?style=flat-square)](https://pub.dartlang.org/packages/flutter_inapp_purchase)
[![Flutter CI](https://github.com/hyochan/flutter_inapp_purchase/actions/workflows/ci.yml/badge.svg)](https://github.com/hyochan/flutter_inapp_purchase/actions/workflows/ci.yml)
[![Coverage Status](https://codecov.io/gh/hyochan/flutter_inapp_purchase/branch/main/graph/badge.svg?token=WXBlKvRB2G)](https://codecov.io/gh/hyochan/flutter_inapp_purchase)
![License](https://img.shields.io/badge/license-MIT-blue.svg)

A comprehensive Flutter plugin for implementing in-app purchases on iOS and Android platforms.

## 🚀 Key Features

- **Cross-platform**: Works seamlessly on both iOS and Android
- **StoreKit 2 Support**: Full StoreKit 2 support for iOS 15.0+ with automatic fallback
- **Billing Client v8**: Latest Android Billing Client features
- **Type-safe**: Complete TypeScript-like support with Dart strong typing
- **Comprehensive Error Handling**: Detailed error codes and user-friendly messages
- **Subscription Management**: Advanced subscription handling and validation
- **Receipt Validation**: Built-in receipt validation for both platforms

## 📦 Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_inapp_purchase: ^6.0.0
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

## 📚 Documentation

For comprehensive documentation, guides, API reference, and examples, visit:

**🌐 [flutter-inapp-purchase.hyo.dev](https://flutter-inapp-purchase.hyo.dev)**

### Quick Links

- **[Getting Started](https://flutter-inapp-purchase.hyo.dev/docs/getting-started/installation)** - Installation and setup
- **[Purchase Guide](https://flutter-inapp-purchase.hyo.dev/docs/guides/purchases)** - Complete purchase implementation 
- **[API Reference](https://flutter-inapp-purchase.hyo.dev/docs/api/)** - Full API documentation
- **[Examples](https://flutter-inapp-purchase.hyo.dev/docs/examples/basic-store)** - Working code examples
- **[Migration Guide](https://flutter-inapp-purchase.hyo.dev/docs/migration/from-v5)** - Upgrading from v5.x

## 🎯 Platform Support

| Feature | iOS | Android |
|---------|-----|---------|
| Products & Subscriptions | ✅ | ✅ |
| Purchase Flow | ✅ | ✅ |
| Receipt Validation | ✅ | ✅ |
| Subscription Management | ✅ | ✅ |
| Promotional Offers | ✅ | N/A |
| StoreKit 2 | ✅ | N/A |
| Billing Client v8 | N/A | ✅ |

## 🚨 Breaking Changes in v6.0.0

- ErrorCode enum values changed to lowerCamelCase (e.g., `E_USER_CANCELLED` → `eUserCancelled`)
- Channel access changed from static to instance member
- Platform-specific code now uses mixin architecture

See the [Migration Guide](https://flutter-inapp-purchase.hyo.dev/docs/migration/from-v5) for detailed upgrade instructions.

## 🤝 Community & Support

- **GitHub Issues**: [Report bugs and feature requests](https://github.com/hyochan/flutter_inapp_purchase/issues)
- **Discussions**: [Join community discussions](https://github.com/hyochan/flutter_inapp_purchase/discussions)
- **Stack Overflow**: [Ask questions](https://stackoverflow.com/questions/tagged/flutter-inapp-purchase)
- **Slack**: [Join our community](https://hyo.dev/joinSlack)

## 🔧 ProGuard Configuration

If you have enabled ProGuard, add these rules to your `proguard-rules.pro`:

```
# In app Purchase
-keep class com.amazon.** {*;}
-keep class dev.hyochan.** { *; }
-keep class com.android.vending.billing.**
-dontwarn com.amazon.**
-keepattributes *Annotation*
```

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

## ☕ Support

If this plugin helps you, consider buying me a coffee:

[![Paypal](https://www.paypalobjects.com/webstatic/mktg/Logo/pp-logo-100px.png)](https://paypal.me/dooboolab)
<a href="https://www.buymeacoffee.com/hyochan" target="_blank"><img src="https://www.buymeacoffee.com/assets/img/custom_images/purple_img.png" alt="Buy Me A Coffee" style="height: auto !important;width: auto !important;" ></a>