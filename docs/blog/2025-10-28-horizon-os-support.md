---
slug: horizon-os-support
title: 7.1.13 - Horizon OS Support for Meta Quest Devices
authors: [hyochan]
tags: [release, flutter, in-app-purchase, horizon-os, meta-quest, openiap]
date: 2025-10-28
---

Flutter In-App Purchase now supports Meta Quest devices with Horizon OS billing, enabling seamless in-app purchases in VR applications using Meta's Platform SDK.

[View the release on GitHub →](https://github.com/hyochan/flutter_inapp_purchase/releases/tag/7.1.13)

<!-- truncate -->

## Feature Highlights

With Horizon OS support, you can now:

- Build VR apps for Meta Quest devices (Quest 2, Quest 3, Quest Pro) with in-app purchases
- Use the same Flutter In-App Purchase API for both Google Play and Meta Horizon stores
- Switch between billing platforms with a simple configuration flag
- Distribute apps on both Google Play Store and Meta Horizon Store from a single codebase

## What is Horizon OS?

Horizon OS is Meta's operating system for Quest VR devices. With this update, flutter_inapp_purchase now supports Meta's Platform SDK for billing, allowing developers to monetize their VR applications on the Meta Horizon Store.

## How It Works

The implementation uses OpenIAP's `openiap-google-horizon` wrapper, which provides a unified interface for both Google Play Billing and Meta's Platform SDK. Your existing code remains unchanged - the platform selection happens at build time through product flavors.

## Configuration

### Enable Horizon Mode

Add to your `android/gradle.properties`:

```properties
# Enable Horizon OS billing
horizonEnabled=true
```

### Configure Product Flavors

Update your `android/app/build.gradle`:

```gradle
android {
    flavorDimensions "platform"
    productFlavors {
        // Horizon flavor - Meta Horizon Billing
        horizon {
            dimension "platform"
            versionNameSuffix "-horizon"
            def appId = project.findProperty("EXAMPLE_HORIZON_APP_ID") ?: ""
            manifestPlaceholders = [OCULUS_APP_ID: appId]
            resValue "string", "app_name", "YourApp (Horizon)"
        }
        // Play flavor - Google Play Billing
        play {
            dimension "platform"
            versionNameSuffix "-play"
            manifestPlaceholders = [OCULUS_APP_ID: ""]
            resValue "string", "app_name", "YourApp (Play)"
        }
    }
}
```

### Add Horizon App ID

Configure your Meta Horizon App ID in `android/local.properties`:

```properties
EXAMPLE_HORIZON_APP_ID=your_horizon_app_id_here
```

### Update AndroidManifest.xml

Add the metadata in your `android/app/src/main/AndroidManifest.xml`:

```xml
<application>
    <!-- Meta Horizon App ID - injected by Gradle -->
    <meta-data
        android:name="com.meta.horizon.platform.ovr.OCULUS_APP_ID"
        android:value="${OCULUS_APP_ID}" />
</application>
```

## Getting Started

### Installation

```bash
flutter pub add flutter_inapp_purchase
```

Or add to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_inapp_purchase: ^7.1.13
```

### Build Commands

```bash
# Build for Google Play Store
flutter build apk --flavor play

# Build for Meta Horizon Store
flutter build apk --flavor horizon

# Run on Quest device
flutter run --flavor horizon -d Quest
```

### Code Usage

No code changes required! The API remains identical:

```dart
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

class PurchaseManager {
  final _iap = FlutterInappPurchase.instance;

  Future<void> initialize() async {
    // Works on both platforms!
    await _iap.initConnection();

    // Fetch products
    final products = await _iap.fetchProducts<Product>(
      skus: ['consumable_item', 'premium_unlock'],
      type: ProductQueryType.InApp,
    );

    // Request purchase
    await _iap.requestPurchase(sku: 'consumable_item');
  }
}
```

The implementation automatically detects the build flavor and uses:
- **Google Play Billing** for Play flavor builds
- **Meta Platform SDK** for Horizon flavor builds

## Under the Hood

### Dependency Management

The plugin uses conditional dependencies in `android/build.gradle`:

```gradle
dependencies {
    // Play flavor - Google Play Billing
    add("playImplementation", "io.github.hyochan.openiap:openiap-google:version")

    // Horizon flavor - Meta Platform SDK
    add("horizonImplementation", "io.github.hyochan.openiap:openiap-google-horizon:version")
}
```

### Build System

Product flavors are configured in both the plugin and your app:

**Plugin** (`flutter_inapp_purchase/android/build.gradle`):
```gradle
android {
    flavorDimensions "platform"
    productFlavors {
        play { dimension "platform"; isDefault = true }
        horizon { dimension "platform" }
    }
}
```

**Your App** (`android/app/build.gradle`):
```gradle
android {
    flavorDimensions "platform"
    productFlavors {
        play { /* configuration */ }
        horizon { /* configuration */ }
    }
}
```

## Backward Compatibility

This update is **100% backward compatible**:

- Existing apps using Google Play Billing continue to work without changes
- The default behavior remains Google Play Billing (`play` flavor is default)
- Horizon support is opt-in through configuration
- No API changes or breaking changes

## Testing on Meta Quest

### Prerequisites

1. [Meta Quest Developer Account](https://developer.oculus.com/)
2. Quest device with Developer Mode enabled
3. Test products configured in [Meta Quest Developer Dashboard](https://developer.oculus.com/manage/)

### Steps

1. Enable Developer Mode on your Quest device
2. Connect via ADB: `adb devices`
3. Configure test products in Meta Quest Developer Dashboard
4. Run with Horizon flavor: `flutter run --flavor horizon -d Quest`

## Example App

Check out the updated example app which demonstrates:

- Product flavor configuration for both Play and Horizon
- VS Code launch configurations for easy testing
- Gradle build commands
- Identical API usage across platforms

```bash
# Clone the repository
git clone https://github.com/hyochan/flutter_inapp_purchase.git
cd flutter_inapp_purchase/example

# Configure Horizon App ID in android/local.properties
echo "EXAMPLE_HORIZON_APP_ID=your_app_id" >> android/local.properties

# Run on Quest
flutter run --flavor horizon -d Quest
```

## Platform Support Comparison

| Feature | Google Play | Meta Horizon |
|---------|-------------|--------------|
| One-time purchases | ✅ | ✅ |
| Consumables | ✅ | ✅ |
| Subscriptions | ✅ | ✅ |
| Purchase verification | ✅ | ✅ |
| Purchase restoration | ✅ | ✅ |
| Subscription offers | ✅ | ✅ |
| Promo codes | ✅ | ✅ |
| Alternative billing | ✅ | N/A |
| Deferred payments | ✅ | ❌ |

## Documentation

Complete documentation for Horizon OS setup:

- [Horizon OS Setup Guide](https://hyochan.github.io/flutter_inapp_purchase/docs/getting-started/setup-horizon) - Complete setup instructions
- [Quick Start](https://hyochan.github.io/flutter_inapp_purchase/docs/getting-started/quickstart) - Getting started guide
- [Purchases Guide](https://hyochan.github.io/flutter_inapp_purchase/docs/guides/purchases) - Purchase implementation
- [Example App README](https://github.com/hyochan/flutter_inapp_purchase/blob/main/example/README.md) - Example configuration

## OpenIAP Ecosystem

This feature is powered by the OpenIAP ecosystem:

- [openiap-google-horizon](https://github.com/hyodotdev/openiap/tree/main/packages/google-horizon) - Horizon billing wrapper
- [OpenIAP Specification](https://openiap.dev) - Unified IAP specification
- Cross-platform support: Flutter, React Native, Expo

The Horizon implementation follows the same OpenIAP specification used across all platforms, ensuring consistent behavior and developer experience.

## Credits

This implementation builds on the work done for react-native-iap Horizon OS support. Thanks to the OpenIAP community for standardizing in-app purchase APIs across platforms.

Special thanks to Meta for providing the Platform SDK and supporting VR developers.

## What's Next?

We continue to expand platform support and improve developer experience:

- Enhanced testing tools for VR development
- Better error messages for Horizon-specific issues
- Additional documentation and examples
- Performance optimizations

## Feedback

Try out Horizon OS support and let us know your feedback! If you encounter any issues or have suggestions:

- [GitHub Issues](https://github.com/hyochan/flutter_inapp_purchase/issues) - Report bugs
- [GitHub Discussions](https://github.com/hyochan/flutter_inapp_purchase/discussions) - Ask questions
- [OpenIAP Discussions](https://github.com/hyodotdev/openiap/discussions) - Spec discussions

Build amazing VR experiences with seamless in-app purchases on Meta Quest!

```yaml
dependencies:
  flutter_inapp_purchase: ^7.1.13
```
