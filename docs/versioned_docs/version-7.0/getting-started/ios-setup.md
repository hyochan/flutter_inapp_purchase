---
title: iOS Setup
sidebar_label: iOS Setup
sidebar_position: 2
---

# iOS Setup

For complete iOS setup instructions including App Store Connect configuration, Xcode setup, and testing guidelines, please visit:

👉 **[iOS Setup Guide - openiap.dev](https://openiap.dev/docs/ios-setup)**

The guide covers:

- App Store Connect configuration
- Xcode project setup
- Sandbox testing
- Common troubleshooting steps

## Code Examples

For implementation examples, see:

- [Purchase Flow](../examples/purchase-flow)
- [Subscription Flow](../examples/subscription-flow)
- [Available Purchases](../examples/available-purchases)

## Common Issues

### Products Not Loading

**Problem**: `fetchProducts()` returns empty list or throws error
**Solutions**:

- Verify product IDs match exactly between code and App Store Connect
- Ensure products are **Active** in App Store Connect
- Check that all Apple Developer agreements are signed
- Wait 24 hours after creating products in App Store Connect

### Testing Issues

**Problem**: "Cannot connect to iTunes Store" error
**Solutions**:

- Test on real device, not simulator
- Use proper sandbox tester account
- Sign out of production Apple ID first
- Ensure In-App Purchase capability is enabled in Xcode

### Receipt Validation

**Problem**: Receipt validation failing
**Solutions**:

- Always validate receipts on your server, not client-side
- Use Apple's receipt validation API
- Handle both sandbox and production receipt endpoints
- Implement proper retry logic for network failures

## Next Steps

- [Learn about getting started guide](./quickstart)
- [Explore Android setup](./android-setup)
- [Understand error codes](../api/error-codes)
