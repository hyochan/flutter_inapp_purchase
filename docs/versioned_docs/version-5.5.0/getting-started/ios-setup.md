---
title: iOS Setup
sidebar_label: iOS Setup
sidebar_position: 2
---

# 🍎 iOS Setup Guide

Complete guide to configure flutter_inapp_purchase for iOS with StoreKit 2 support.

## 📋 Prerequisites

- **iOS 11.0+** (StoreKit 2 requires iOS 15.0+)
- **Xcode 14+** for StoreKit 2 development
- **Apple Developer Account** with valid agreements

## 🔧 Xcode Configuration

### 1. Enable In-App Purchase Capability

1. Open your project in Xcode
2. Select your project in the navigator
3. Select your target under **TARGETS**
4. Go to **Signing & Capabilities** tab
5. Click **+ Capability** and add **In-App Purchase**


### 2. Configure Info.plist

Add the following to your `ios/Runner/Info.plist` for iOS 14+ compatibility:

```xml title="ios/Runner/Info.plist"
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>itms-apps</string>
</array>

<!-- Optional: For subscription management -->
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsLocalNetworking</key>
    <true/>
    <key>NSExceptionDomains</key>
    <dict>
        <key>apps.apple.com</key>
        <dict>
            <key>NSExceptionRequiresForwardSecrecy</key>
            <false/>
            <key>NSIncludesSubdomains</key>
            <true/>
        </dict>
    </dict>
</dict>
```

## 🏪 App Store Connect Setup

### 1. Create Your App

1. Sign in to [App Store Connect](https://appstoreconnect.apple.com)
2. Go to **My Apps** and create your app
3. Fill in the required app information
4. Save your changes

### 2. Configure In-App Purchases

1. In your app, go to **Features** → **In-App Purchases**
2. Click **Create** to add a new in-app purchase
3. Choose your product type:
   - **Consumable**: Can be purchased multiple times (e.g., coins, lives)
   - **Non-Consumable**: One-time purchase (e.g., remove ads, premium features)
   - **Auto-Renewable Subscription**: Recurring subscription
   - **Non-Renewing Subscription**: Fixed-duration subscription

### 3. Product Configuration Example

```
Product ID: com.yourapp.premium_upgrade
Reference Name: Premium Upgrade
Price: $9.99
Localizations:
  - English: "Premium Upgrade" / "Unlock all premium features"
  - Korean: "프리미엄 업그레이드" / "모든 프리미엄 기능 잠금 해제"
```

:::tip Product ID Best Practices
Use reverse domain notation with descriptive names:
- `com.yourapp.remove_ads`
- `com.yourapp.monthly_premium`
- `com.yourapp.coins_pack_large`
:::

## 🧪 StoreKit Configuration (Testing)

### 1. Create StoreKit Configuration File

For **StoreKit 2** testing and development:

1. In Xcode, go to **File** → **New** → **File**
2. Choose **StoreKit Configuration File**
3. Name it (e.g., `Products.storekit`)
4. Add your test products:

```json title="Products.storekit"
{
  "identifier" : "Products",
  "nonRenewingSubscriptions" : [
  ],
  "products" : [
    {
      "displayPrice" : "9.99",
      "familyShareable" : false,
      "identifier" : "com.yourapp.premium_upgrade",
      "localizations" : [
        {
          "description" : "Unlock all premium features",
          "displayName" : "Premium Upgrade",
          "locale" : "en_US"
        }
      ],
      "productID" : "com.yourapp.premium_upgrade",
      "referenceName" : "Premium Upgrade",
      "type" : "NonConsumable"
    }
  ],
  "settings" : {
    "_compatibilityTimeRate" : 1,
    "_storeKitErrors" : [
      {
        "current" : null,
        "enabled" : false,
        "name" : "Load Products"
      }
    ]
  },
  "subscriptionGroups" : [
  ],
  "version" : {
    "major" : 2,
    "minor" : 0
  }
}
```

### 2. Configure Build Scheme

1. In Xcode, go to **Product** → **Scheme** → **Edit Scheme**
2. Select **Run** → **Options**
3. Under **StoreKit Configuration**, choose your `.storekit` file
4. Build and run your app


## 🔐 Sandbox Testing

### 1. Create Sandbox Tester Account

1. In App Store Connect, go to **Users and Roles**
2. Click **Sandbox Testers**
3. Click **+** to create a new tester
4. Use a **unique email address** (not associated with any Apple ID)
5. Choose your test region and complete the form

:::warning Sandbox Account Requirements
- Must use a unique email address
- Cannot be associated with an existing Apple ID
- Should match your app's target regions
:::

### 2. Test on Device

1. **Sign out** of your Apple ID in iOS Settings
2. Install your app from Xcode
3. Attempt to make a purchase
4. When prompted, sign in with your **sandbox tester account**
5. Complete the test purchase

### 3. Verify Sandbox Behavior

```dart title="Testing Example"
// Test connection and products
Future<void> testSandboxPurchase() async {
  try {
    // Initialize connection
    await FlutterInappPurchase.instance.initConnection();
    print('✅ Connection established');
    
    // Get products
    final products = await FlutterInappPurchase.instance.getProducts([
      'com.yourapp.premium_upgrade'
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
    print('❌ Test failed: $e');
  }
}
```

## ⚠️ Common Issues & Solutions

### Issue: "Cannot connect to iTunes Store"

**Solutions:**
- Ensure you're testing on a real device (not simulator)
- Check your internet connection
- Verify your sandbox tester account is set up correctly
- Sign out and back in with your sandbox account

### Issue: Products not loading

**Solutions:**
- Verify products are configured in App Store Connect
- Check that product IDs match exactly
- Ensure your app bundle ID matches App Store Connect
- Wait a few hours after creating products (propagation delay)

### Issue: StoreKit 2 not working

**Solutions:**
- Ensure iOS 15.0+ deployment target
- Use Xcode 14+ for development
- Check StoreKit configuration file is properly set
- Verify capability is added to your target

## 🎯 Next Steps

Once iOS setup is complete:

1. **[Android Setup](/docs/getting-started/android-setup)** - Configure Android billing
2. **[Basic Implementation](/docs/guides/basic-setup)** - Start implementing purchases
3. **[Testing Guide](/docs/guides/testing)** - Test your implementation

---

Need help? Check our [troubleshooting guide](/docs/troubleshooting) or [open an issue](https://github.com/hyochan/flutter_inapp_purchase/issues) on GitHub.