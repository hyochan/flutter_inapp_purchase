---
title: Installation & Setup
sidebar_label: Installation
sidebar_position: 1
---

# 📦 Installation & Setup

Learn how to install and configure flutter_inapp_purchase in your Flutter project.

## 🚀 Quick Installation

Add flutter_inapp_purchase to your project:

```bash
flutter pub add flutter_inapp_purchase
```

Or add it manually to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_inapp_purchase: ^6.0.0
```

Then run:

```bash
flutter pub get
```

## 📱 Platform Configuration

### iOS Configuration

#### 1. Enable In-App Purchase Capability

1. Open your project in Xcode
2. Select your project in the navigator
3. Select your target
4. Go to **Signing & Capabilities** tab
5. Click **+ Capability** and add **In-App Purchase**

#### 2. Configure Info.plist (iOS 14+)

Add the following to your `ios/Runner/Info.plist`:

```xml
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>itms-apps</string>
</array>
```

#### 3. StoreKit Configuration (Optional)

For testing with StoreKit 2, create a `.storekit` configuration file:

1. In Xcode, go to **File** → **New** → **File**
2. Choose **StoreKit Configuration File**
3. Add your products for testing

### Android Configuration

#### 1. Update build.gradle

Ensure your `android/app/build.gradle` has the minimum SDK version:

```gradle
android {
    compileSdkVersion 34

    defaultConfig {
        minSdkVersion 21  // Required minimum
        targetSdkVersion 34
    }
}
```

#### 2. Enable ProGuard Rules (if using ProGuard)

Add to your `android/app/proguard-rules.pro`:

```proguard
# In-App Purchase
-keep class com.amazon.** {*;}
-keep class dev.hyo.** { *; }
-keep class com.android.vending.billing.**
-dontwarn com.amazon.**
-keepattributes *Annotation*
```

#### 3. Permissions

The plugin automatically adds the required billing permission to your manifest.

## 🔧 Basic Setup

### Initialize the Plugin

```dart
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _initializeIAP();
  }

  Future<void> _initializeIAP() async {
    try {
      await FlutterInappPurchase.instance.initConnection();
      print('IAP connection initialized successfully');
    } catch (e) {
      print('Failed to initialize IAP connection: $e');
    }
  }

  @override
  void dispose() {
    FlutterInappPurchase.instance.endConnection();
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

## 🧪 Testing Setup

### iOS Testing

#### 1. Sandbox Testing

1. Create a sandbox tester account in App Store Connect:

   - **Users and Roles** → **Sandbox Testers**
   - Add a test account with unique email

2. Sign out of your Apple ID in Settings on your test device
3. When prompted during purchase, sign in with sandbox account

#### 2. StoreKit Testing (iOS 14+)

1. In Xcode, go to **Product** → **Scheme** → **Edit Scheme**
2. Select **Run** → **Options**
3. Choose your StoreKit Configuration File

### Android Testing

#### 1. Internal Testing

1. Upload a signed APK to Google Play Console
2. Create an **Internal Testing** release
3. Add test users via email
4. Install the app from the Play Console testing link

#### 2. License Testing

Add test accounts in Google Play Console:

- **Setup** → **License Testing**
- Add email addresses of testers

## ⚠️ Common Issues

### iOS Issues

:::warning Permission Denied
If you get permission errors, ensure:

- In-App Purchase capability is enabled
- Your Apple Developer account has active agreements
- Products are configured in App Store Connect
  :::

### Android Issues

:::warning Billing Unavailable
If billing is unavailable:

- Ensure you're testing on a real device (not emulator)
- Check that Google Play is installed and up-to-date
- Verify your app is signed with the same key as uploaded to Play Console
  :::

## ✅ Verification

Test your setup with this simple verification:

```dart
Future<void> _testConnection() async {
  try {
    final String? result = await FlutterInappPurchase.instance.initConnection();
    print('Connection result: $result');

    // Test product fetching
    final products = await FlutterInappPurchase.instance.getProducts(['test_product_id']);
    print('Found ${products.length} products');

  } catch (e) {
    print('Connection test failed: $e');
  }
}
```

## 🎯 Next Steps

Now that you have flutter_inapp_purchase installed and configured:

- [📖 **Basic Setup Guide**](/guides/basic-setup) - Learn the fundamentals
- [🛒 **Your First Purchase**](/guides/first-purchase) - Implement your first purchase
- [📱 **Platform Differences**](/guides/platform-differences) - iOS vs Android specifics

---

Need help? Check our [troubleshooting guide](/guides/troubleshooting) or [open an issue](https://github.com/hyochan/flutter_inapp_purchase/issues) on GitHub.
