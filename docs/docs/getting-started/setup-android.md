---
sidebar_position: 3
---

# Android Setup

This guide covers the complete setup process for implementing in-app purchases on Android.

## Prerequisites

- Google Play Developer account
- Android Studio
- Minimum Android SDK 21 (Android 5.0)

## Step 1: Configure Google Play Console

### Create In-App Products

1. Log in to [Google Play Console](https://play.google.com/console)
2. Select your application
3. Navigate to **Monetize** → **In-app products**
4. Click **Create product**

### Product Types

- **One-time products**: Consumable or non-consumable items
- **Subscriptions**: Recurring purchases

### Product Configuration

For each product:

1. **Product ID**: Unique identifier (e.g., `premium_upgrade`)
2. **Name**: Display name for users
3. **Description**: Product details
4. **Price**: Set pricing for each country/region
5. **Status**: Set to **Active**

## Step 2: Configure Your App

### Add Billing Permission

Add to your `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="com.android.vending.BILLING" />
    
    <application
        android:label="@string/app_name"
        android:icon="@mipmap/ic_launcher">
        <!-- Your activities -->
    </application>
</manifest>
```

### Configure Build Settings

Ensure your `android/app/build.gradle` has the correct configuration:

```gradle
android {
    compileSdkVersion 33
    
    defaultConfig {
        applicationId "com.yourcompany.yourapp"
        minSdkVersion 21
        targetSdkVersion 33
        versionCode 1
        versionName "1.0"
    }
}
```

> **Important**: The `applicationId` must match exactly with Google Play Console.

## Step 3: Upload Your App

### Initial Release

Products won't be available until your app is uploaded:

1. Build a signed APK or App Bundle
2. Upload to **Internal Testing**, **Closed Testing**, or **Production**
3. Complete store listing information
4. Submit for review (for production)

### Testing Tracks

- **Internal Testing**: Instant availability, up to 100 testers
- **Closed Testing**: Requires review, unlimited testers
- **Open Testing**: Public beta
- **Production**: Full release

## Step 4: Set Up Test Accounts

### Add License Testers

1. In Google Play Console, go to **Setup** → **License testing**
2. Add tester email addresses
3. Set **License response** to "RESPOND_NORMALLY"

### Testing Best Practices

- Use Google accounts added as license testers
- Test accounts need to accept testing invitation
- Clear Google Play Store cache between tests
- Test on real devices (not emulators)

## Step 5: Testing In-App Purchases

### Enable Test Purchases

License testers can make test purchases without charges:

1. Products show with **(Test)** suffix
2. No actual charges are made
3. Test purchases auto-refund after 14 days

### Test Card Requirements

For testing subscriptions with test cards:
- The device must have a valid payment method
- Test cards are only for license testers
- Real charges won't occur

## Step 6: Handle Android-Specific Features

### Acknowledge Purchases

Android requires acknowledging purchases within 3 days:

```dart
// Acknowledge a purchase
await FlutterInappPurchase.instance.acknowledgePurchase(
  purchaseToken: purchase.purchaseToken!,
);
```

### Consume Purchases

For consumable products:

```dart
// Consume a purchase
await FlutterInappPurchase.instance.consumePurchase(
  purchaseToken: purchase.purchaseToken!,
);
```

### Handle Pending Purchases

Some payment methods create pending purchases:

```dart
// Check purchase state
if (purchase.purchaseStateAndroid == PurchaseState.pending) {
  // Handle pending purchase
  showPendingUI();
}
```

## Common Issues and Solutions

### Products Not Loading

1. **Check Product Status**: Must be "Active" in Play Console
2. **App Not Published**: Upload to at least Internal Testing
3. **Package Name Mismatch**: Verify applicationId matches
4. **Cache Issues**: Clear Play Store cache and data
5. **Wait Time**: Products may take 24+ hours to propagate

### Purchase Failures

1. **Not Signed In**: Ensure Google account is signed in
2. **Country Restrictions**: Check product availability by country
3. **Payment Method**: Add valid payment method to account
4. **Version Code**: Uploaded APK version must be >= installed version

### Testing Issues

1. **Not a Tester**: Add account to license testers
2. **Wrong Account**: Ensure testing with correct Google account
3. **Emulator Issues**: Use real devices for testing
4. **Network Issues**: Check internet connectivity

## Debugging Tips

### Enable Debug Logging

```dart
// Enable debug mode
FlutterInappPurchase.instance.setDebugMode(true);
```

### Check Error Codes

```dart
try {
  await FlutterInappPurchase.instance.requestPurchase(productId);
} catch (e) {
  if (e.code == 'E_USER_CANCELLED') {
    // User cancelled the purchase
  } else if (e.code == 'E_ITEM_UNAVAILABLE') {
    // Product not available
  }
  // Handle other errors
}
```

## Testing Checklist

- [ ] Products created and active in Play Console
- [ ] BILLING permission added to manifest
- [ ] App uploaded to testing track
- [ ] License testers configured
- [ ] Test on real device with test account
- [ ] Test purchase flow
- [ ] Test acknowledgment/consumption
- [ ] Test restore purchases
- [ ] Test error scenarios
- [ ] Test pending purchases

## Production Checklist

- [ ] Remove debug logging
- [ ] Implement server-side receipt validation
- [ ] Handle all error cases
- [ ] Test with production builds
- [ ] Monitor crash reports
- [ ] Set up purchase analytics

## Next Steps

- [Learn about iOS setup](./setup-ios)
- [Explore getting started guide](./quickstart)
- [Understand error codes](../api/error-codes)