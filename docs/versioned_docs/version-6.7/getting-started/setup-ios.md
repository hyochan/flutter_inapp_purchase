---
sidebar_position: 2
---

# iOS Setup

This guide covers the complete setup process for implementing in-app purchases on iOS.

## Prerequisites

- Apple Developer account
- Xcode 12.0 or later
- iOS 11.0+ deployment target

## Step 1: Configure App Store Connect

### Create In-App Purchase Products

1. Log in to [App Store Connect](https://appstoreconnect.apple.com)
2. Select your app
3. Navigate to **Features** → **In-App Purchases**
4. Click the **+** button to create a new product

### Product Types

Choose the appropriate product type:

- **Consumable**: Can be purchased multiple times (coins, gems, etc.)
- **Non-Consumable**: Purchased once, permanently available (remove ads, unlock features)
- **Auto-Renewable Subscription**: Recurring subscriptions
- **Non-Renewing Subscription**: Fixed-duration subscriptions

### Product Configuration

For each product:

1. **Reference Name**: Internal name (not visible to users)
2. **Product ID**: Unique identifier (e.g., `com.yourcompany.app.product1`)
3. **Pricing**: Select price tier
4. **Localizations**: Add display name and description for each language

## Step 2: Configure Xcode Project

### Enable In-App Purchase Capability

1. Open your project in Xcode
2. Select your app target
3. Go to **Signing & Capabilities** tab
4. Click **+ Capability**
5. Add **In-App Purchase**

### Configure App Sandbox

For testing, ensure your app uses the sandbox environment:

1. In Xcode, edit your scheme
2. Go to **Run** → **Options**
3. Set **StoreKit Configuration** to your `.storekit` file (optional)

## Step 3: Set Up Agreements

### Banking and Tax Information

1. In App Store Connect, go to **Agreements, Tax, and Banking**
2. Complete all required agreements:
   - Paid Applications Agreement
   - Banking Information
   - Tax Information

> **Note**: Products won't be available for purchase until agreements are active.

## Step 4: Create Sandbox Test Accounts

### Create Test Users

1. In App Store Connect, go to **Users and Access**
2. Select **Sandbox Testers**
3. Click **+** to create new testers
4. Use unique email addresses (can be variations like `test+1@example.com`)

### Testing Best Practices

- Use different sandbox accounts for different test scenarios
- Clear purchase history regularly in Settings → App Store → Sandbox Account
- Test all product types and edge cases

## Step 5: Configure StoreKit Testing (Optional)

### Create StoreKit Configuration File

1. In Xcode, **File** → **New** → **File**
2. Choose **StoreKit Configuration File**
3. Add your products with the same IDs as App Store Connect

### Benefits of StoreKit Testing

- Test without App Store Connect configuration
- Simulate various scenarios (failures, delays)
- Speed up development cycle

## Step 6: Handle iOS-Specific Features

### Promoted In-App Purchases

To handle purchases initiated from the App Store:

```dart
// Listen for promoted purchases
FlutterInappPurchase.instance.getPromotedProduct().then((productId) {
  if (productId != null) {
    // Handle promoted purchase
    handlePromotedPurchase(productId);
  }
});
```

### Receipt Validation

iOS provides a unified receipt containing all purchase information:

```dart
// Get app receipt
String? receiptBody = await FlutterInappPurchase.instance.getReceiptData();

// Validate with your server
validateReceipt(receiptBody);
```

## Common Issues and Solutions

### Products Not Loading

1. **Check Product Status**: Ensure products are "Ready to Submit" or "Approved"
2. **Verify Bundle ID**: Must match exactly with App Store Connect
3. **Wait Time**: New products may take up to 24 hours to propagate
4. **Agreements**: Ensure all agreements are active

### Sandbox Testing Issues

1. **Sign Out**: Sign out of production App Store account
2. **Use Sandbox Account**: Only sign in when prompted during purchase
3. **Clear Cache**: Delete and reinstall app between tests

### Purchase Failures

1. **Network Issues**: Check internet connectivity
2. **Parental Controls**: Ensure IAP is not restricted
3. **Payment Methods**: Sandbox accounts don't need real payment info

## Testing Checklist

- [ ] Products configured in App Store Connect
- [ ] In-App Purchase capability enabled
- [ ] Agreements completed and active
- [ ] Sandbox test accounts created
- [ ] Test all product types
- [ ] Test purchase restoration
- [ ] Test receipt validation
- [ ] Test network error handling
- [ ] Test subscription management

## Next Steps

- [Learn about Android setup](./setup-android)
- [Explore getting started guide](./quickstart)
- [Understand error codes](../api/error-codes)