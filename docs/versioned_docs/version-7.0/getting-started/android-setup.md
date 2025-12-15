---
title: Android Setup
sidebar_label: Android Setup
sidebar_position: 3
---

# Android Setup

For complete Android setup instructions including Google Play Console configuration, app setup, and testing guidelines, please visit:

👉 **[Android Setup Guide - openiap.dev](https://openiap.dev/docs/android-setup)**

The guide covers:

- Google Play Console configuration
- App bundle setup and signing
- Testing with internal testing tracks
- Common troubleshooting steps

## Code Examples

For implementation examples, see:

- [Purchase Flow](../examples/purchase-flow)
- [Subscription Flow](../examples/subscription-flow)
- [Available Purchases](../examples/available-purchases)

## Common Issues

### Products Not Found

**Problem**: `fetchProducts()` returns empty list
**Solutions**:

- Products must be active in Google Play Console
- App must be published to at least internal testing track
- Wait 2-3 hours after creating products
- Verify product IDs match exactly

### Billing Unavailable

**Problem**: "Billing is not available" error
**Solutions**:

- Test on real device, not emulator
- Ensure Google Play Store is installed and updated
- App must be signed with the same certificate uploaded to Play Console
- Check that your Google Play Developer account is active

### Pending Purchases

**Problem**: Purchases stuck in pending state
**Solutions**:

- This is normal for payment methods requiring additional verification
- Inform users their purchase is being processed
- Store pending purchases and check again later
- Implement proper handling for `PurchaseState.Pending`

### Subscription Changes

**Problem**: Upgrade/downgrade not working
**Solutions**:

- Use proper replacement mode (immediate, deferred, etc.)
- Provide the old purchase token when upgrading
- Verify proration settings in Play Console
- Test upgrade/downgrade flows in internal testing

## Next Steps

- [Learn about getting started guide](./quickstart)
- [Explore iOS setup](./ios-setup)
- [Understand error codes](../api/error-codes)
