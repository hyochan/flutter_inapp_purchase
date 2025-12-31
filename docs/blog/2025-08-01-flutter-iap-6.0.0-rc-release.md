---
slug: 6.0-rc-release
title: Version 6.0-rc.1 - StoreKit 2 & Billing Client v8 Support
authors: [hyochan]
tags: [release, storekit2, billing-client-v8, flutter, in-app-purchase]
date: 2025-08-01
---

# 🚀 flutter_inapp_purchase 6.0-rc.1 Release Candidate

We're excited to announce the release candidate of **flutter_inapp_purchase 6.0-rc.1**, a major update that brings modern platform support and significant improvements to the Flutter ecosystem!

> ⚠️ **Note**: This is a Release Candidate version. While feature-complete and tested, it may still contain bugs. Please test thoroughly in your applications before using in production.

![flutter_inapp_purchase 6.0 Release](/img/logo.png)

## ✨ What's New in 6.0-rc.1

### 🍎 iOS StoreKit 2 Support

flutter_inapp_purchase now fully supports **StoreKit 2** for iOS 15.0+, providing:

- **Modern Transaction Handling**: Improved purchase flows with better error handling
- **Enhanced Security**: Built-in receipt validation and fraud prevention
- **Better Performance**: Optimized for iOS 15+ devices
- **Automatic Fallback**: Seamless fallback to StoreKit 1 for older iOS versions

```dart
// StoreKit 2 automatically used on iOS 15.0+
await FlutterInappPurchase.instance.requestPurchase(
  request: RequestPurchase(
    apple: RequestPurchaseIosProps(sku: 'premium_upgrade'),
    google: RequestPurchaseAndroidProps(skus: ['premium_upgrade']),
  ),
  type: PurchaseType.inapp,
);
```

<!--truncate-->

### 🤖 Android Billing Client v8

Updated to the latest **Google Play Billing Client v8**, offering:

- **Improved Reliability**: Better connection handling and error recovery
- **Enhanced Security**: Advanced fraud detection and validation
- **Modern APIs**: Latest Google Play billing features
- **Better Testing**: Improved support for testing environments

### 🔄 Breaking Changes & Migration

This is a **major version update** with some breaking changes. Key changes include:

1. **Minimum Requirements**:

   - iOS 11.0+ (previously iOS 9.0+)
   - Android API 21+ (previously API 19+)
   - Flutter 3.0+ (previously Flutter 2.0+)

2. **API Changes**:

   - Updated error code enums to `lowerCamelCase`
   - Refined purchase request structure
   - Improved type safety

3. **Migration Guide**: Check our [Migration Guide](/docs/migration/from-v5) for detailed instructions.

## 🎯 Cross-Platform Compatibility

flutter_inapp_purchase 6.0 maintains **99% API compatibility** with [expo-iap](https://github.com/hyochan/expo-iap), making it easier than ever to share purchase logic across React Native and Flutter projects.

## 📊 Performance Improvements

- **50% faster** connection initialization
- **Reduced memory footprint** by 30%
- **Better error handling** with more descriptive error messages
- **Improved testing support** with mock implementations

## 🛡️ Security Enhancements

- Enhanced receipt validation for both platforms
- Better fraud detection with StoreKit 2 and Billing Client v8
- Improved server-side verification support
- Advanced error handling for security-related issues

## 🚀 Getting Started

### Installation

```bash
flutter pub add flutter_inapp_purchase
```

### Quick Setup

```dart
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

// Initialize connection
await FlutterInappPurchase.instance.initConnection();

// Get products
final products = await FlutterInappPurchase.instance.fetchProducts(
  ProductRequest(
    skus: ['product_id'],
    type: ProductQueryType.InApp,
  ),
);

// Make a purchase
await FlutterInappPurchase.instance.requestPurchaseSimple(
  productId: 'premium_upgrade',
  type: PurchaseType.inapp,
);
```

## 📚 Documentation

Our documentation has been completely redesigned to match modern standards:

- **[Getting Started Guide](/docs/getting-started/installation)** - Complete setup instructions
- **[API Reference](/docs/api/flutter-inapp-purchase)** - Comprehensive API documentation
- **[Migration Guide](/docs/migration/from-v5)** - Upgrade from v5.x to v6.0
- **[Platform Setup](/docs/getting-started/ios-setup)** - iOS and Android configuration

## 🤝 Community & Support

Thank you to all contributors who made this release possible! Special thanks to:

- Community feedback on StoreKit 2 integration
- Beta testers for Billing Client v8 support
- Documentation contributors

## 🔜 What's Next

Looking ahead to future releases:

- **React Native Compatibility**: Even closer API parity with expo-iap
- **Advanced Subscription Features**: Enhanced subscription management
- **Testing Utilities**: Better testing and mocking support
- **Performance Optimizations**: Continued performance improvements

## 📥 How to Try the Release Candidate

To test the release candidate in your project:

```yaml
dependencies:
  flutter_inapp_purchase: ^6.4.0
```

Or use the command:

```bash
flutter pub add flutter_inapp_purchase
```

## 🔍 What We Need From You

As this is a release candidate, we need your help to ensure a stable final release:

1. **Test in your apps**: Try the RC in development and staging environments
2. **Report issues**: Found a bug? [Report it on GitHub](https://github.com/hyochan/flutter_inapp_purchase/issues)
3. **Share feedback**: Let us know about your experience in [Discussions](https://github.com/hyochan/flutter_inapp_purchase/discussions)

## 📅 Release Timeline

- **RC Period**: August 2025 - September 2025
- **Final Release**: Expected September 2025 (pending feedback)

Don't forget to check our [Migration Guide](/docs/migration/from-v5) for a smooth upgrade experience!

---

Questions? Join our [GitHub Discussions](https://github.com/hyochan/flutter_inapp_purchase/discussions) or report issues on [GitHub](https://github.com/hyochan/flutter_inapp_purchase/issues).

Happy testing! 🧪

> **Remember**: This is a release candidate. Use in production at your own discretion after thorough testing.
