---
sidebar_position: 4
title: Horizon OS
---

# Horizon OS Setup

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

### 1. Enable Horizon Mode

Add to `android/gradle.properties`:

```properties
horizonEnabled=true
```

### 2. Configure Horizon App ID

Add to `android/local.properties`:

```properties
EXAMPLE_HORIZON_APP_ID=your_horizon_app_id_here
```

### 3. Add Product Flavors

Update `android/app/build.gradle`:

```gradle
android {
    flavorDimensions "platform"
    productFlavors {
        horizon {
            dimension "platform"
            def appId = project.findProperty("EXAMPLE_HORIZON_APP_ID") ?: ""
            manifestPlaceholders = [OCULUS_APP_ID: appId]
        }
        play {
            dimension "platform"
            manifestPlaceholders = [OCULUS_APP_ID: ""]
        }
    }
}
```

### 4. Update AndroidManifest.xml

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<application>
    <meta-data
        android:name="com.meta.horizon.platform.ovr.OCULUS_APP_ID"
        android:value="${OCULUS_APP_ID}" />
</application>
```

### 5. Build for Horizon

```bash
# Build APK for Meta Quest
flutter build apk --flavor horizon

# Run on Quest device
flutter run --flavor horizon -d Quest
```

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
