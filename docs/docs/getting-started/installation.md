---
title: Installation & Setup
sidebar_label: Installation
sidebar_position: 1
---

import IapKitBanner from "@site/src/uis/IapKitBanner";

# Installation & Setup

<IapKitBanner />

Learn how to install and configure flutter_inapp_purchase in your Flutter project.

## Prerequisites

Before installing flutter_inapp_purchase, ensure you have:

- Flutter SDK 2.0.0 or higher
- Dart SDK 2.12.0 or higher
- Active Apple Developer account (for iOS)
- Active Google Play Developer account (for Android)
- Physical device for testing (simulators/emulators have limited support)

## Package Installation

Add flutter_inapp_purchase to your project:

```bash
flutter pub add flutter_inapp_purchase
```

Or add it manually to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_inapp_purchase: ^8.2.0
```

Then run:

```bash
flutter pub get
```

## Platform Configuration

### iOS Configuration

#### Enable In-App Purchase Capability

1. Open your project in Xcode
2. Select your project in the navigator
3. Select your target
4. Go to **Signing & Capabilities** tab
5. Click **+ Capability** and add **In-App Purchase**

#### Configure Info.plist (iOS 14+)

Add the following to your `ios/Runner/Info.plist`:

```xml
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>itms-apps</string>
</array>
```

#### StoreKit Configuration (Optional)

For testing with StoreKit 2, create a `.storekit` configuration file:

1. In Xcode, go to **File** → **New** → **File**
2. Choose **StoreKit Configuration File**
3. Add your products for testing

### Android Configuration

#### Update build.gradle

Ensure your `android/app/build.gradle` has the minimum SDK version and platform configuration:

**For Groovy (build.gradle):**
```gradle
android {
    compileSdkVersion 34

    defaultConfig {
        minSdkVersion 21  // Required minimum
        targetSdkVersion 34

        // Required for v7.1.14+: Select Google Play platform
        missingDimensionStrategy 'platform', 'play'
    }
}
```

**For Kotlin DSL (build.gradle.kts):**
```kotlin
android {
    compileSdkVersion(34)

    defaultConfig {
        minSdkVersion(21)  // Required minimum
        targetSdkVersion(34)

        // Required for v7.1.14+: Select Google Play platform
        missingDimensionStrategy("platform", "play")
    }
}
```

:::info
The `missingDimensionStrategy` configuration is required since v7.1.14 due to product flavor support for Meta Horizon OS. For Meta Quest support, see the [Horizon OS Setup Guide](./setup-horizon).
:::

#### Enable ProGuard Rules (if using ProGuard)

Add to your `android/app/proguard-rules.pro`:

```proguard
# In-App Purchase
-keep class com.amazon.** {*;}
-keep class dev.hyo.** { *; }
-keep class com.android.vending.billing.**
-dontwarn com.amazon.**
-keepattributes *Annotation*
```

#### Permissions

The plugin automatically adds the required billing permission to your manifest.

## Configuration

### App Store Connect (iOS)

1. Sign in to [App Store Connect](https://appstoreconnect.apple.com)
2. Select your app
3. Navigate to **Monetization** → **In-App Purchases**
4. Create your products:

   - **Consumable**: Can be purchased multiple times
   - **Non-Consumable**: One-time purchase
   - **Auto-Renewable Subscription**: Recurring payments
   - **Non-Renewing Subscription**: Fixed duration

5. Fill in required fields:

   - Reference Name (internal use)
   - Product ID (used in code)
   - Pricing
   - Localizations

6. Submit for review with your app

### Google Play Console (Android)

1. Sign in to [Google Play Console](https://play.google.com/console)
2. Select your app
3. Navigate to **Monetization** → **In-app products**
4. Create products:

   - **One-time products**: Consumable or non-consumable
   - **Subscriptions**: Recurring payments

5. Configure product details:

   - Product ID (used in code)
   - Name and description
   - Price
   - Status (Active)

6. Save and activate products

## Verification

### Initialize the Plugin

You have two options for managing IAP instances:

#### Option 1: Create Your Own Instance

```dart
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final FlutterInappPurchase iap = FlutterInappPurchase();

  @override
  void initState() {
    super.initState();
    _initializeIAP();
  }

  Future<void> _initializeIAP() async {
    try {
      await iap.initConnection();
      print('IAP connection initialized successfully');
    } catch (e) {
      print('Failed to initialize IAP connection: $e');
    }
  }

  @override
  void dispose() {
    iap.endConnection();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(),
    );
  }
}
```

#### Option 2: Use Singleton Instance

```dart
class _MyAppState extends State<MyApp> {
  final iap = FlutterInappPurchase.instance;

  Future<void> _initializeIAP() async {
    await iap.initConnection();
  }
}
```

### Test Connection

Test your setup with this verification code:

```dart
Future<void> _testConnection() async {
  final iap = FlutterInappPurchase(); // or FlutterInappPurchase.instance
  try {
    final bool connected = await iap.initConnection();
    print('Connection result: $connected');

    // Test product fetching
    final result = await iap.fetchProducts(
      skus: ['test_product_id'],
      type: ProductQueryType.InApp,
    );
    print('Found ${result.value.length} products');

  } catch (e) {
    print('Connection test failed: $e');
  }
}
```

## Next Steps

Now that you have flutter_inapp_purchase installed and configured:

- [**Basic Setup Guide**](/guides/basic-setup) - Learn the fundamentals
- [**Platform Specific Setup**](/getting-started/android-setup) - Android specific configuration
- [**Platform Specific Setup**](/getting-started/ios-setup) - iOS specific configuration

## Troubleshooting

### iOS Common Issues

**Permission Denied**

- Ensure In-App Purchase capability is enabled
- Verify your Apple Developer account has active agreements
- Check that products are configured in App Store Connect

**Products Not Loading**

- Products must be submitted for review (at least once)
- Wait 24 hours after creating products
- Verify product IDs match exactly

### Android Common Issues

**Billing Unavailable**

- Test on a real device (not emulator)
- Ensure Google Play is installed and up-to-date
- Verify app is signed with the same key as uploaded to Play Console

**Products Not Found**

- Products must be active in Play Console
- App must be published (at least to internal testing)
- Wait 2-3 hours after creating products

---

Need help? Check our [migration guide](/migration/from-v5) or [open an issue](https://github.com/hyochan/flutter_inapp_purchase/issues) on GitHub.
