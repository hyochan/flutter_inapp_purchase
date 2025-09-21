---
sidebar_position: 8
title: Offer Code Redemption
---

# Offer Code Redemption

Guide to implementing promotional offer codes and subscription management with flutter_inapp_purchase v6.8.0, covering iOS and Android platforms.

## Overview

This plugin provides native support for:

- **iOS**: Offer code redemption sheet and subscription management (iOS 14+)
- **Android**: Deep linking to subscription management
- **Cross-platform**: Introductory offer eligibility checking

## iOS Offer Code Redemption

### Present Code Redemption Sheet

```dart
import 'dart:io';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

class OfferCodeHandler {
  final _iap = FlutterInappPurchase.instance;
  
  /// Present iOS system offer code redemption sheet (iOS 16+)
  Future<void> presentOfferCodeRedemption() async {
    if (!Platform.isIOS) {
      debugPrint('Offer code redemption is only available on iOS');
      return;
    }
    
    try {
      // Present the system offer code redemption sheet
      await _iap.presentCodeRedemptionSheet();
      debugPrint('Offer code redemption sheet presented');
      
      // Results will come through purchaseUpdated stream
      _listenForRedemptionResults();
      
    } catch (e) {
      debugPrint('Failed to present offer code sheet: $e');
    }
  }
  
  /// Alternative method for iOS 14+ compatibility
  Future<void> presentOfferCodeRedemptionIOS() async {
    if (!Platform.isIOS) return;
    
    try {
      await _iap.presentCodeRedemptionSheetIOS();
      debugPrint('iOS offer code redemption sheet presented');
    } catch (e) {
      debugPrint('Failed to present iOS offer code sheet: $e');
    }
  }
  
  void _listenForRedemptionResults() {
    FlutterInappPurchase.purchaseUpdated.listen((purchase) {
      if (purchase != null) {
        debugPrint('Offer code redeemed: ${purchase.productId}');
        // Handle successful redemption
        _handleRedeemedPurchase(purchase);
      }
    });
  }
  
  void _handleRedeemedPurchase(Purchase purchase) {
    // Process the redeemed purchase
    // Verify receipt, deliver content, etc.
  }
}
```

### Introductory Offers

```dart
class IntroductoryOfferHandler {
  final _iap = FlutterInappPurchase.instance;
  
  /// Check if user is eligible for introductory offer (iOS only)
  Future<bool> isEligibleForIntroductoryOffer(String productId) async {
    if (!Platform.isIOS) return false;
    
    try {
      final isEligible = await _iap.isEligibleForIntroOfferIOS(productId);
      debugPrint('Intro offer eligibility for $productId: $isEligible');
      return isEligible;
    } catch (e) {
      debugPrint('Failed to check intro offer eligibility: $e');
      return false;
    }
  }
  
  /// Get subscription status for a specific product
  Future<Map<String, dynamic>?> getSubscriptionStatus(String productId) async {
    if (!Platform.isIOS) return null;
    
    try {
      final status = await _iap.getSubscriptionStatusIOS(productId);
      debugPrint('Subscription status for $productId: $status');
      return status;
    } catch (e) {
      debugPrint('Failed to get subscription status: $e');
      return null;
    }
  }
}
```

## Subscription Management

### iOS Subscription Management

```dart
class SubscriptionManager {
  final _iap = FlutterInappPurchase.instance;
  
  /// Show iOS subscription management screen (iOS 15+)
  Future<void> showManageSubscriptions() async {
    if (!Platform.isIOS) {
      debugPrint('Subscription management is only available on iOS');
      return;
    }
    
    try {
      await _iap.showManageSubscriptions();
      debugPrint('Subscription management screen presented');
    } catch (e) {
      debugPrint('Failed to show subscription management: $e');
    }
  }
  
  /// Alternative method for iOS-specific subscription management
  Future<void> showManageSubscriptionsIOS() async {
    if (!Platform.isIOS) return;
    
    try {
      await _iap.showManageSubscriptionsIOS();
      debugPrint('iOS subscription management screen presented');
    } catch (e) {
      debugPrint('Failed to show iOS subscription management: $e');
    }
  }
  
  /// Get subscription group information (iOS only)
  Future<String?> getSubscriptionGroup(String productId) async {
    if (!Platform.isIOS) return null;
    
    try {
      final group = await _iap.getSubscriptionGroupIOS(productId);
      debugPrint('Subscription group for $productId: $group');
      return group;
    } catch (e) {
      debugPrint('Failed to get subscription group: $e');
      return null;
    }
  }
}
```

## Android Subscription Management

### Deep Linking to Subscriptions

```dart
class AndroidSubscriptionManager {
  final _iap = FlutterInappPurchase.instance;
  
  /// Open Android subscription management (deep link to Play Store)
  Future<void> openSubscriptionManagement([String? productId]) async {
    if (!Platform.isAndroid) {
      debugPrint('Android subscription management is only available on Android');
      return;
    }
    
    try {
      // Deep link to subscription management in Play Store
      await _iap.deepLinkToSubscriptionsAndroid(sku: productId);
      debugPrint('Opened Android subscription management');
    } catch (e) {
      debugPrint('Failed to open subscription management: $e');
    }
  }
}
```

## Complete Implementation Example

### Cross-Platform Offer Handler

```dart
class CrossPlatformOfferHandler {
  final _iap = FlutterInappPurchase.instance;
  
  /// Present offer code redemption (iOS) or subscription management (Android)
  Future<void> handleOfferRedemption() async {
    try {
      if (Platform.isIOS) {
        // iOS: Present code redemption sheet
        await _iap.presentCodeRedemptionSheet();
        debugPrint('iOS offer code redemption sheet presented');
        _listenForPurchases();
      } else if (Platform.isAndroid) {
        // Android: Open subscription management
        await _iap.deepLinkToSubscriptionsAndroid();
        debugPrint('Android subscription management opened');
      }
    } catch (e) {
      debugPrint('Failed to handle offer redemption: $e');
    }
  }
  
  /// Check introductory offer eligibility (iOS only)
  Future<bool> checkIntroOfferEligibility(String productId) async {
    if (!Platform.isIOS) return false;
    
    try {
      return await _iap.isEligibleForIntroOfferIOS(productId);
    } catch (e) {
      debugPrint('Failed to check intro offer eligibility: $e');
      return false;
    }
  }
  
  void _listenForPurchases() {
    FlutterInappPurchase.purchaseUpdated.listen((purchase) {
      if (purchase != null) {
        debugPrint('Purchase received: ${purchase.productId}');
        // Handle the purchase
      }
    });
  }
}
```

## Additional Features

### App Store Information (iOS)

```dart
class AppStoreInfo {
  final _iap = FlutterInappPurchase.instance;
  /// Get promoted product (iOS only)
  Future<String?> getPromotedProduct() async {
    if (!Platform.isIOS) return null;
    
    try {
      final productId = await _iap.getPromotedProduct();
      debugPrint('Promoted product: $productId');
      return productId;
    } catch (e) {
      debugPrint('Failed to get promoted product: $e');
      return null;
    }
  }
}
```

## Usage Examples

### In a Flutter App

```dart
class OfferRedemptionPage extends StatelessWidget {
  final _offerHandler = CrossPlatformOfferHandler();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Redeem Offers'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (Platform.isIOS) ...[
              ElevatedButton(
                onPressed: () async {
                  await _offerHandler.handleOfferRedemption();
                },
                child: Text('Redeem Offer Code'),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  final eligible = await _offerHandler.checkIntroOfferEligibility('your_product_id');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Eligible for intro offer: $eligible')),
                  );
                },
                child: Text('Check Intro Offer Eligibility'),
              ),
            ],
            if (Platform.isAndroid) ...[
              ElevatedButton(
                onPressed: () async {
                  await _offerHandler.handleOfferRedemption();
                },
                child: Text('Manage Subscriptions'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

## Important Notes

### Platform Differences

- **iOS**: Full support for offer code redemption through system sheet (iOS 14+)
- **Android**: No direct promo code API - users must redeem through Play Store
- **Subscription Management**: Both platforms support opening native subscription management

### Requirements

- **iOS**: Minimum iOS 14.0 for offer code redemption
- **iOS**: Minimum iOS 15.0 for subscription management  
- **Android**: Requires Google Play Billing Library 5.x+

### Best Practices

1. Always check platform before calling platform-specific methods
2. Handle errors gracefully as native dialogs may fail
3. Listen to purchase streams when presenting offer code redemption
4. Use subscription management for user convenience
