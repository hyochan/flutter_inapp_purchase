---
title: Android Setup
sidebar_label: Android Setup
sidebar_position: 3
---

import IapKitBanner from "@site/src/uis/IapKitBanner";

# Android Setup

<IapKitBanner />

For complete Android setup instructions including Google Play Console configuration, app setup, and testing guidelines, please visit:

👉 **[Android Setup Guide - openiap.dev](https://openiap.dev/docs/android-setup)**

The guide covers:

- Google Play Console configuration
- App bundle setup and signing
- Testing with internal testing tracks
- Common troubleshooting steps

## Required Configuration (v7.1.14+)

:::info Required for v7.1.14+
Since version 7.1.14, the plugin uses product flavors to support both Google Play and Meta Horizon OS. You must configure the platform dimension in your app's build.gradle file.
:::

Add the following to your `android/app/build.gradle.kts` (or `build.gradle` for Groovy) inside the `defaultConfig` block:

**For Kotlin DSL (build.gradle.kts):**
```kotlin
android {
    defaultConfig {
        // ... other configuration ...

        // Required: Select Google Play platform
        missingDimensionStrategy("platform", "play")
    }
}
```

**For Groovy (build.gradle):**
```groovy
android {
    defaultConfig {
        // ... other configuration ...

        // Required: Select Google Play platform
        missingDimensionStrategy 'platform', 'play'
    }
}
```

This configuration tells Gradle to use the Google Play flavor of the plugin. If you need Meta Quest/Horizon OS support instead, see the [Horizon OS Setup Guide](./setup-horizon).

## Code Examples

For implementation examples, see:

- [Purchase Flow](../examples/purchase-flow)
- [Subscription Flow](../examples/subscription-flow)
- [Available Purchases](../examples/available-purchases)

## Common Issues

### Build Failed: Could not determine dependencies (v7.1.14+)

**Problem**: Gradle build fails with error about ambiguous variants (horizonReleaseRuntimeElements / playReleaseRuntimeElements)

**Error message:**
```
Could not determine the dependencies of task ':app:mergeReleaseNativeLibs'.
> Could not resolve all dependencies for configuration ':app:releaseRuntimeClasspath'.
   > The consumer was configured to find a library... However we cannot choose between the following variants...
```

**Solution**: Add `missingDimensionStrategy` to your app's build.gradle file. See the [Required Configuration](#required-configuration-v7114) section above.

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

## Meta Quest / Horizon OS

For Meta Quest devices using Horizon OS billing, see:

- [Horizon OS Setup Guide](./setup-horizon) - Flutter-specific configuration for Meta Quest

## Next Steps

- [Learn about getting started guide](./quickstart)
- [Explore iOS setup](./ios-setup)
- [Understand error codes](../api/error-codes)
