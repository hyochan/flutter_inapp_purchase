---
sidebar_position: 4
title: Horizon OS
---

import IapKitBanner from "@site/src/uis/IapKitBanner";

# Horizon OS Setup

<IapKitBanner />

Setup guide for Meta Quest devices running Horizon OS with Meta's Platform SDK for in-app purchases.

For complete Horizon OS setup instructions including Meta Quest Developer Dashboard configuration, app setup, and testing guidelines, please visit:

👉 **[Horizon OS Setup Guide - openiap.dev](https://openiap.dev/docs/horizon-setup)**

The guide covers:

- Meta Quest Developer Dashboard configuration
- Horizon App ID setup
- Product configuration
- Testing with Meta Quest devices
- Common troubleshooting steps

## Flutter-Specific Configuration

### 1. Add to AndroidManifest.xml

Add inside `<application>` tag in `android/app/src/main/AndroidManifest.xml`:

```xml
<!-- Meta Horizon App ID - injected by Gradle -->
<meta-data
    android:name="com.meta.horizon.platform.ovr.HORIZON_APP_ID"
    android:value="${HORIZON_APP_ID}" />
```

### 2. Configure Platform Selection

Add to `android/app/build.gradle` inside `defaultConfig`:

```gradle
android {
    defaultConfig {
        // ... other configuration ...

        // Read horizonEnabled flag from gradle.properties (default: false)
        def horizonEnabled = project.findProperty('horizonEnabled')?.toBoolean() ?: false
        def flavor = horizonEnabled ? 'horizon' : 'play'

        // Select platform flavor from plugin
        missingDimensionStrategy 'platform', flavor

        // Configure Horizon App ID if enabled
        def localProperties = new Properties()
        def localPropertiesFile = rootProject.file('local.properties')
        if (localPropertiesFile.exists()) {
            localPropertiesFile.withInputStream { localProperties.load(it) }
        }
        def horizonAppId = horizonEnabled ? (localProperties.getProperty("HORIZON_APP_ID") ?: "") : ""
        manifestPlaceholders = [HORIZON_APP_ID: horizonAppId]
    }
}
```

### 3. Enable Horizon (Optional)

**For Google Play (default)**: No configuration needed! Just build and run normally.

**For Meta Quest**: Add to `android/gradle.properties`:

```properties
horizonEnabled=true
```

And add your Horizon App ID to `android/local.properties`:

```properties
HORIZON_APP_ID=your_horizon_app_id_here
```

### 4. Build & Run

```bash
# Google Play (default - no configuration needed)
flutter run
flutter build apk --release

# Meta Quest (after enabling horizonEnabled=true)
flutter run -d Quest
flutter build apk --release
```

**No flavor specification needed!** The plugin automatically selects the correct billing platform based on `horizonEnabled`.

## Code Usage

No code changes required! Use the same API:

```dart
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

// Initialize connection
await FlutterInappPurchase.instance.initConnection();

// Fetch products (works on both Play and Horizon)
final products = await FlutterInappPurchase.instance.fetchProducts<Product>(
  skus: ['consumable_item'],
  type: ProductQueryType.InApp,
);

// Request purchase
await FlutterInappPurchase.instance.requestPurchase(sku: 'consumable_item');
```

## Testing on Meta Quest

1. Enable Developer Mode on Quest device
2. Connect via ADB: `adb devices`
3. Configure test products in Meta Quest Developer Dashboard
4. Run with Horizon flavor: `flutter run --flavor horizon -d Quest`

## Common Issues

### Products Not Loading

**Problem**: `fetchProducts()` returns empty list on Quest

**Solutions**:
- Verify Horizon App ID is correctly configured
- Ensure products are active in Meta Quest Developer Dashboard
- Check that SKUs match exactly
- Confirm you're testing with the correct build flavor

### Build Errors

**Problem**: Build fails with flavor errors

**Solutions**:
```bash
# Clean and rebuild
flutter clean
cd android && ./gradlew clean
cd ..
flutter build apk --flavor horizon
```

### Wrong Billing System

**Problem**: App uses Google Play instead of Horizon

**Solutions**:
- Verify `horizonEnabled=true` in `android/gradle.properties`
- Confirm building with `--flavor horizon`
- Check flavor configuration in `build.gradle`

## Next Steps

- [Quick Start Guide](./quickstart) - Basic implementation
- [Android Setup](./android-setup) - General Android configuration
- [Purchases Guide](../guides/purchases) - Purchase implementation
- [OpenIAP Horizon Docs](https://openiap.dev/docs/horizon-setup) - Complete setup guide
