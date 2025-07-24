---
title: Android Setup
sidebar_label: Android Setup
sidebar_position: 3
---

# 🤖 Android Setup Guide

Complete guide to configure flutter_inapp_purchase for Android with Google Play Billing Client v8.

## 📋 Prerequisites

- **Android API 21+** (Android 5.0+)
- **Google Play Console Account** with billing enabled
- **Android Studio** with Android SDK

## 🔧 Project Configuration

### 1. Update build.gradle

Ensure your `android/app/build.gradle` has the correct configuration:

```gradle title="android/app/build.gradle"
android {
    compileSdkVersion 34
    
    defaultConfig {
        applicationId "com.yourapp.example"
        minSdkVersion 21  // Required minimum for Billing Client v8
        targetSdkVersion 34
        versionCode 1
        versionName "1.0"
    }
    
    buildTypes {
        release {
            // Signing configuration
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
```

### 2. ProGuard Configuration

If using ProGuard/R8, add these rules to `android/app/proguard-rules.pro`:

```proguard title="android/app/proguard-rules.pro"
# Flutter In-App Purchase
<<<<<<< HEAD
-keep class dev.hyo.** { *; }
=======
-keep class com.dooboolab.** { *; }
>>>>>>> 5e86ee0 (docs: Update community links and fix configuration)
-keep class com.android.vending.billing.**
-keep class com.google.android.gms.** { *; }

# Preserve billing client classes
-keep class com.android.billingclient.api.** { *; }
-dontwarn com.android.vending.billing.**
-dontwarn com.google.android.gms.**

# Keep annotation classes
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod
```

### 3. Permissions

The plugin automatically adds the required billing permission to your `AndroidManifest.xml`:

```xml title="android/app/src/main/AndroidManifest.xml"
<!-- This is added automatically by the plugin -->
<uses-permission android:name="com.android.vending.BILLING" />
```

## 🏪 Google Play Console Setup

### 1. Create Your App

1. Sign in to [Google Play Console](https://play.google.com/console)
2. Create a new app or select existing app
3. Complete the app information and store listing
4. Set up your app's content rating and target audience

### 2. Enable In-App Products

1. Go to **Monetize** → **Products** → **In-app products**
2. Click **Create product** to add new products
3. Configure your product details:

```
Product ID: premium_upgrade
Name: Premium Upgrade
Description: Unlock all premium features
Price: $9.99
```

### 3. Product Types

Choose the appropriate product type:

- **Managed Products**: One-time purchases (non-consumable)
- **Consumable Products**: Can be purchased multiple times
- **Subscriptions**: Recurring billing (configured separately)

:::tip Product ID Best Practices
- Use descriptive, consistent naming: `premium_upgrade`, `remove_ads`, `coins_large_pack`
- Avoid special characters and spaces
- Keep IDs consistent across platforms (iOS/Android)
:::

## 🔐 App Signing & Release

### 1. Generate Signing Key

For production releases, you need a signed APK:

```bash
# Generate a new keystore (one-time setup)
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# Or use Android Studio: Build → Generate Signed Bundle/APK
```

### 2. Configure Signing

Create `android/key.properties`:

```properties title="android/key.properties"
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=../upload-keystore.jks
```

Update `android/app/build.gradle`:

```gradle title="android/app/build.gradle"
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

### 3. Upload to Play Console

1. Build a signed app bundle:
   ```bash
   flutter build appbundle --release
   ```

2. Upload `build/app/outputs/bundle/release/app-release.aab` to Play Console

3. Create an **Internal Testing** track for testing in-app purchases

## 🧪 Testing Setup

### 1. Internal Testing

1. In Play Console, go to **Testing** → **Internal testing**
2. Create a new release and upload your signed app bundle
3. Add test users by email addresses
4. Send the testing link to your testers

### 2. License Testing

1. Go to **Setup** → **License testing**
2. Add Gmail accounts that should have testing access
3. These accounts can test purchases without being charged

### 3. Test Accounts Configuration

```dart title="Testing Example"
Future<void> testAndroidPurchase() async {
  try {
    // Check connection state
    final state = await FlutterInappPurchase.instance.getConnectionStateAndroid();
    print('🔗 Connection state: $state');
    
    // Initialize connection
    await FlutterInappPurchase.instance.initConnection();
    print('✅ Billing client connected');
    
    // Get products
    final products = await FlutterInappPurchase.instance.getProducts([
      'premium_upgrade',
      'remove_ads'
    ]);
    print('📦 Found ${products.length} products');
    
    // Test purchase
    if (products.isNotEmpty) {
      await FlutterInappPurchase.instance.requestPurchaseSimple(
        productId: products.first.productId!,
        type: PurchaseType.inapp,
      );
    }
  } catch (e) {
    print('❌ Android test failed: $e');
  }
}
```

## 🔍 Billing Client v8 Features

### Enhanced Error Handling

```dart
FlutterInappPurchase.purchaseError.listen((error) {
  if (error == null) return;
  
  switch (error.code) {
    case ErrorCode.eServiceUnavailable:
      // Google Play services unavailable
      showDialog('Please update Google Play services');
      break;
    case ErrorCode.eBillingUnavailable:
      // Billing API version not supported
      showDialog('In-app purchases not supported on this device');
      break;
    case ErrorCode.eItemUnavailable:
      // Product not found or not available for purchase
      showDialog('This item is currently unavailable');
      break;
    case ErrorCode.eDeveloperError:
      // Invalid arguments provided to the API
      print('Developer error: Check product configuration');
      break;
    default:
      showDialog('Purchase failed: ${error.message}');
  }
});
```

### Connection State Monitoring

```dart
// Monitor connection state
Future<void> checkConnectionHealth() async {
  final state = await FlutterInappPurchase.instance.getConnectionStateAndroid();
  
  switch (state) {
    case BillingClientState.disconnected:
      // Reconnect if needed
      await FlutterInappPurchase.instance.initConnection();
      break;
    case BillingClientState.connected:
      // Ready for purchases
      print('✅ Billing client ready');
      break;
    case BillingClientState.closed:
      // Client was closed, reinitialize
      await FlutterInappPurchase.instance.initConnection();
      break;
  }
}
```

## ⚠️ Common Issues & Solutions

### Issue: "Billing service unavailable"

**Solutions:**
- Test on a real device with Google Play services
- Ensure you're signed in to a Google account
- Check that Google Play is up to date
- Verify your app is properly signed and uploaded

### Issue: Products not loading

**Solutions:**
- Ensure products are active in Play Console
- Verify product IDs match exactly
- Check that your app is published (at least to Internal Testing)
- Wait for product propagation (can take a few hours)

### Issue: "Item unavailable" error

**Solutions:**
- Verify the product exists and is active in Play Console
- Check that your app version includes the product
- Ensure you're testing with the correct account
- Confirm the product is available in your test region

### Issue: Testing with wrong account

**Solutions:**
- Use an account added to License Testing
- Install the app from the Internal Testing link
- Don't use the developer account for testing purchases
- Clear Google Play Store cache if needed

## 🎯 Advanced Configuration

### 1. Obfuscated Account IDs

For enhanced security, use obfuscated account IDs:

```dart
await FlutterInappPurchase.instance.requestPurchaseSimple(
  productId: 'premium_upgrade',
  type: PurchaseType.inapp,
  obfuscatedAccountId: 'user_account_123',
  obfuscatedProfileId: 'profile_456',
);
```

### 2. Purchase Token Validation

Always validate purchases on your server:

```dart
FlutterInappPurchase.purchaseUpdated.listen((purchase) async {
  if (purchase != null) {
    // Send to your server for validation
    final isValid = await validatePurchaseOnServer(purchase);
    
    if (isValid) {
      // Grant the purchased content
      await grantPurchase(purchase);
      
      // Acknowledge the purchase
      await FlutterInappPurchase.instance.finishTransaction(
        purchase,
        isConsumable: false,
      );
    }
  }
});
```

## 🎯 Next Steps

Once Android setup is complete:

1. **[Basic Implementation](/docs/guides/basic-setup)** - Start implementing purchases
2. **[Testing Guide](/docs/guides/testing)** - Test your implementation thoroughly
3. **[Security Best Practices](/docs/guides/security)** - Secure your implementation

---

Need help? Check our [troubleshooting guide](/docs/troubleshooting) or [open an issue](https://github.com/hyochan/flutter_inapp_purchase/issues) on GitHub.