---
sidebar_position: 8
title: Offer Code Redemption
---

<<<<<<< HEAD
<<<<<<< HEAD
# Offer Code Redemption

Guide to implementing promotional offer codes and subscription management with flutter_inapp_purchase v6.0.0, covering iOS and Android platforms.

## Overview

This plugin provides native support for:

- **iOS**: Offer code redemption sheet and subscription management (iOS 14+)
- **Android**: Deep linking to subscription management
- **Cross-platform**: Introductory offer eligibility checking

## iOS Offer Code Redemption

### Present Code Redemption Sheet
=======
# Promotional Offer Code Guide
=======
# Offer Code Redemption
>>>>>>> 40157f9 (docs: Update guides and examples content)

Guide to implementing promotional offer codes and subscription management with flutter_inapp_purchase v6.0.0, covering iOS and Android platforms.

## Overview

This plugin provides native support for:

- **iOS**: Offer code redemption sheet and subscription management (iOS 14+)
- **Android**: Deep linking to subscription management
- **Cross-platform**: Introductory offer eligibility checking

## iOS Offer Code Redemption

<<<<<<< HEAD
### Understanding iOS Promotional Offers

iOS supports several types of promotional offers:

1. **Introductory Offers** - New subscribers only (free trial, discounted price)
2. **Promotional Offers** - Existing/lapsed subscribers (win-back campaigns)
3. **Offer Codes** - Redeemable codes for any eligible user
4. **Subscription Offers** - Custom offers with specific pricing

### Implementing Offer Code Redemption
>>>>>>> 5e86ee0 (docs: Update community links and fix configuration)
=======
### Present Code Redemption Sheet
>>>>>>> 40157f9 (docs: Update guides and examples content)

```dart
import 'dart:io';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

<<<<<<< HEAD
<<<<<<< HEAD
class OfferCodeHandler {
  final _iap = FlutterInappPurchase.instance;
  
  /// Present iOS system offer code redemption sheet (iOS 16+)
  Future<void> presentOfferCodeRedemption() async {
    if (!Platform.isIOS) {
      debugPrint('Offer code redemption is only available on iOS');
=======
class IOSOfferCodeHandler {
=======
class OfferCodeHandler {
>>>>>>> 40157f9 (docs: Update guides and examples content)
  final _iap = FlutterInappPurchase.instance;
  
  /// Present iOS system offer code redemption sheet (iOS 16+)
  Future<void> presentOfferCodeRedemption() async {
    if (!Platform.isIOS) {
<<<<<<< HEAD
      print('Offer code redemption is only available on iOS');
>>>>>>> 5e86ee0 (docs: Update community links and fix configuration)
=======
      debugPrint('Offer code redemption is only available on iOS');
>>>>>>> 40157f9 (docs: Update guides and examples content)
      return;
    }
    
    try {
      // Present the system offer code redemption sheet
      await _iap.presentCodeRedemptionSheet();
<<<<<<< HEAD
<<<<<<< HEAD
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
  
  void _handleRedeemedPurchase(PurchasedItem purchase) {
    // Process the redeemed purchase
    // Verify receipt, deliver content, etc.
=======
=======
      debugPrint('Offer code redemption sheet presented');
>>>>>>> 40157f9 (docs: Update guides and examples content)
      
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
  
<<<<<<< HEAD
  PromotionalOfferSignature({
    required this.nonce,
    required this.signature,
    required this.timestamp,
    required this.keyIdentifier,
  });
  
  factory PromotionalOfferSignature.fromJson(Map<String, dynamic> json) {
    return PromotionalOfferSignature(
      nonce: json['nonce'],
      signature: json['signature'],
      timestamp: json['timestamp'],
      keyIdentifier: json['keyIdentifier'],
    );
>>>>>>> 5e86ee0 (docs: Update community links and fix configuration)
=======
  void _handleRedeemedPurchase(PurchasedItem purchase) {
    // Process the redeemed purchase
    // Verify receipt, deliver content, etc.
>>>>>>> 40157f9 (docs: Update guides and examples content)
  }
}
```

### Introductory Offers

```dart
class IntroductoryOfferHandler {
  final _iap = FlutterInappPurchase.instance;
  
<<<<<<< HEAD
<<<<<<< HEAD
  /// Check if user is eligible for introductory offer (iOS only)
=======
  // Check introductory offer eligibility
>>>>>>> 5e86ee0 (docs: Update community links and fix configuration)
=======
  /// Check if user is eligible for introductory offer (iOS only)
>>>>>>> 40157f9 (docs: Update guides and examples content)
  Future<bool> isEligibleForIntroductoryOffer(String productId) async {
    if (!Platform.isIOS) return false;
    
    try {
<<<<<<< HEAD
<<<<<<< HEAD
      final isEligible = await _iap.isEligibleForIntroOfferIOS(productId);
      debugPrint('Intro offer eligibility for $productId: $isEligible');
      return isEligible;
    } catch (e) {
      debugPrint('Failed to check intro offer eligibility: $e');
=======
      // Load subscription products
      final products = await _iap.getSubscriptions([productId]);
      
      if (products.isEmpty) {
        print('Product not found: $productId');
        return false;
      }
      
      final product = products.first;
      
      // Check if product has introductory offer
      if (product.introductoryPrice == null) {
        print('No introductory offer available');
        return false;
      }
      
      // Check user eligibility (iOS handles this automatically)
      // The offer will only be applied if user is eligible
      return true;
      
    } catch (e) {
      print('Failed to check intro offer eligibility: $e');
>>>>>>> 5e86ee0 (docs: Update community links and fix configuration)
=======
      final isEligible = await _iap.isEligibleForIntroOfferIOS(productId);
      debugPrint('Intro offer eligibility for $productId: $isEligible');
      return isEligible;
    } catch (e) {
      debugPrint('Failed to check intro offer eligibility: $e');
>>>>>>> 40157f9 (docs: Update guides and examples content)
      return false;
    }
  }
  
<<<<<<< HEAD
<<<<<<< HEAD
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
=======
  // Display introductory offer details
  String formatIntroductoryOffer(IAPItem product) {
    if (product.introductoryPrice == null) {
      return 'No introductory offer';
    }
    
    final intro = product.introductoryPrice!;
    final cycles = intro['subscriptionPeriodNumberIOS'] ?? 1;
    final period = intro['subscriptionPeriodUnitIOS'] ?? '';
    final price = intro['priceString'] ?? 'Free';
    
    // Format based on period type
    switch (period) {
      case 'DAY':
        return '$price for $cycles ${cycles > 1 ? "days" : "day"}';
      case 'WEEK':
        return '$price for $cycles ${cycles > 1 ? "weeks" : "week"}';
      case 'MONTH':
        return '$price for $cycles ${cycles > 1 ? "months" : "month"}';
      case 'YEAR':
        return '$price for $cycles ${cycles > 1 ? "years" : "year"}';
      default:
        return price;
>>>>>>> 5e86ee0 (docs: Update community links and fix configuration)
=======
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
>>>>>>> 40157f9 (docs: Update guides and examples content)
    }
  }
}
```

<<<<<<< HEAD
<<<<<<< HEAD
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
=======
## Android Promo Codes
=======
## Subscription Management
>>>>>>> 40157f9 (docs: Update guides and examples content)

### iOS Subscription Management

```dart
class SubscriptionManager {
  final _iap = FlutterInappPurchase.instance;
  
<<<<<<< HEAD
  // Redeem promo code through Google Play
  Future<void> redeemPromoCode(String code) async {
    if (!Platform.isAndroid) {
      print('Promo code redemption is only available on Android');
>>>>>>> 5e86ee0 (docs: Update community links and fix configuration)
=======
  /// Show iOS subscription management screen (iOS 15+)
  Future<void> showManageSubscriptions() async {
    if (!Platform.isIOS) {
      debugPrint('Subscription management is only available on iOS');
>>>>>>> 40157f9 (docs: Update guides and examples content)
      return;
    }
    
    try {
<<<<<<< HEAD
<<<<<<< HEAD
      // Deep link to subscription management in Play Store
      await _iap.deepLinkToSubscriptionsAndroid(sku: productId);
      debugPrint('Opened Android subscription management');
    } catch (e) {
      debugPrint('Failed to open subscription management: $e');
    }
  }
  
  /// Get Android billing connection state
  Future<String?> getConnectionState() async {
    if (!Platform.isAndroid) return null;
    
    try {
      final state = await _iap.getConnectionStateAndroid();
      debugPrint('Android connection state: $state');
      return state;
    } catch (e) {
      debugPrint('Failed to get connection state: $e');
      return null;
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
=======
      // Launch Google Play promo code redemption
      final url = 'https://play.google.com/redeem?code=$code';
      
      if (await canLaunchUrlString(url)) {
        await launchUrlString(
          url,
          mode: LaunchMode.externalApplication,
        );
        
        print('Opened Play Store for code redemption');
        
        // Monitor for purchase updates
        _monitorRedemptionResult();
        
      } else {
        throw Exception('Could not launch Play Store');
      }
      
=======
      await _iap.showManageSubscriptions();
      debugPrint('Subscription management screen presented');
>>>>>>> 40157f9 (docs: Update guides and examples content)
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
  
<<<<<<< HEAD
  void _monitorRedemptionResult() {
    // Set up a temporary listener for redemption results
    Timer(Duration(seconds: 2), () async {
      // Check for new purchases
      await _checkForRedeemedPurchases();
>>>>>>> 5e86ee0 (docs: Update community links and fix configuration)
=======
  /// Get Android billing connection state
  Future<String?> getConnectionState() async {
    if (!Platform.isAndroid) return null;
    
    try {
      final state = await _iap.getConnectionStateAndroid();
      debugPrint('Android connection state: $state');
      return state;
    } catch (e) {
      debugPrint('Failed to get connection state: $e');
      return null;
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
>>>>>>> 40157f9 (docs: Update guides and examples content)
    });
  }
}
```

<<<<<<< HEAD
<<<<<<< HEAD
## Additional Features

### App Store Information (iOS)

```dart
class AppStoreInfo {
  final _iap = FlutterInappPurchase.instance;
  
  /// Get App Store country code (iOS only)
  Future<String?> getAppStoreCountry() async {
    if (!Platform.isIOS) return null;
    
    try {
      final country = await _iap.getAppStoreCountryIOS();
      debugPrint('App Store country: $country');
      return country;
    } catch (e) {
      debugPrint('Failed to get App Store country: $e');
      return null;
    }
  }
  
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
=======
### Subscription Promo Codes
=======
## Additional Features

### App Store Information (iOS)
>>>>>>> 40157f9 (docs: Update guides and examples content)

```dart
class AppStoreInfo {
  final _iap = FlutterInappPurchase.instance;
  
  /// Get App Store country code (iOS only)
  Future<String?> getAppStoreCountry() async {
    if (!Platform.isIOS) return null;
    
    try {
      final country = await _iap.getAppStoreCountryIOS();
      debugPrint('App Store country: $country');
      return country;
    } catch (e) {
      debugPrint('Failed to get App Store country: $e');
      return null;
    }
  }
  
<<<<<<< HEAD
  // Check if user has redeemed a promo for this subscription
  Future<bool> hasRedeemedPromo(String productId) async {
    final redeemedPromos = await _storage.getRedeemedPromos();
    return redeemedPromos.any((promo) => promo.productId == productId);
  }
  
  // Get promo details from purchase
  PromoDetails? getPromoDetailsFromPurchase(PurchasedItem purchase) {
    if (purchase.dataAndroid == null) return null;
    
    final data = purchase.dataAndroid!;
    
    // Check for promo indicators in purchase data
    if (data['promotionCode'] != null) {
      return PromoDetails(
        code: data['promotionCode'],
        type: data['promotionType'] ?? 'unknown',
        discount: data['promotionDiscount'],
      );
    }
    
    return null;
  }
}

class PromoDetails {
  final String code;
  final String type;
  final dynamic discount;
  
  PromoDetails({
    required this.code,
    required this.type,
    this.discount,
  });
}
```

## Cross-Platform Implementation

### Unified Promo Code Handler

```dart
class UnifiedPromoCodeHandler {
  final _iap = FlutterInappPurchase.instance;
  final _analytics = AnalyticsService();
  
  // Cross-platform promo code redemption
  Future<void> redeemCode({String? code}) async {
    try {
      if (Platform.isIOS) {
        // iOS: Present system redemption sheet
        await _redeemIOSOfferCode();
      } else if (Platform.isAndroid) {
        // Android: Handle code redemption
        if (code != null) {
          await _redeemAndroidPromoCode(code);
        } else {
          await _showAndroidCodeEntry();
        }
      }
      
      // Track redemption attempt
      _analytics.track('promo_code_redemption_started', {
        'platform': Platform.operatingSystem,
        'has_code': code != null,
      });
      
    } catch (e) {
      print('Code redemption failed: $e');
      _handleRedemptionError(e);
    }
  }
  
  Future<void> _redeemIOSOfferCode() async {
    await _iap.presentCodeRedemptionSheet();
    
    // Set up listener for redemption result
    _listenForRedemptionResult();
  }
  
  Future<void> _redeemAndroidPromoCode(String code) async {
    // Format code if needed
    final formattedCode = _formatPromoCode(code);
    
    // Validate before redemption
    if (!_isValidCode(formattedCode)) {
      throw PromoCodeException('Invalid code format');
    }
    
    // Open Play Store for redemption
    final url = 'https://play.google.com/redeem?code=$formattedCode';
    await launchUrlString(url, mode: LaunchMode.externalApplication);
    
    // Monitor for result
    _listenForRedemptionResult();
  }
  
  String _formatPromoCode(String code) {
    // Remove spaces and convert to uppercase
    String formatted = code.replaceAll(RegExp(r'\s+'), '').toUpperCase();
    
    // Add dashes if missing (Android format)
    if (Platform.isAndroid && formatted.length == 20 && !formatted.contains('-')) {
      formatted = formatted.replaceAllMapped(
        RegExp(r'(.{4})'),
        (match) => '${match.group(0)}-',
      ).trimRight().replaceAll(RegExp(r'-$'), '');
    }
    
    return formatted;
  }
  
  bool _isValidCode(String code) {
    if (Platform.isIOS) {
      // iOS codes are typically alphanumeric, varying length
      return RegExp(r'^[A-Z0-9]+$').hasMatch(code);
    } else {
      // Android codes follow specific format
      return RegExp(r'^[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$')
          .hasMatch(code);
>>>>>>> 5e86ee0 (docs: Update community links and fix configuration)
    }
  }
}
```

<<<<<<< HEAD
## Usage Examples

### In a Flutter App

```dart
class OfferRedemptionPage extends StatelessWidget {
  final _offerHandler = CrossPlatformOfferHandler();
=======
### Redemption Result Handling

```dart
class RedemptionResultHandler {
  final _iap = FlutterInappPurchase.instance;
  StreamSubscription<PurchasedItem?>? _redemptionListener;
  
  void listenForRedemptionResults() {
    // Cancel existing listener
    _redemptionListener?.cancel();
    
    // Set up temporary listener for redemption
    _redemptionListener = FlutterInappPurchase.purchaseUpdated
        .timeout(Duration(minutes: 5))
        .listen(
          _handleRedemptionUpdate,
          onError: _handleRedemptionError,
          onDone: () {
            print('Redemption timeout');
            _redemptionListener?.cancel();
          },
        );
  }
  
  void _handleRedemptionUpdate(PurchasedItem? purchase) {
    if (purchase == null) return;
    
    // Check if this is a promo redemption
    if (_isPromoRedemption(purchase)) {
      print('Promo code redeemed: ${purchase.productId}');
      
      // Process the redeemed purchase
      _processRedeemedPurchase(purchase);
      
      // Cancel listener
      _redemptionListener?.cancel();
      
      // Notify user
      _showRedemptionSuccess(purchase);
    }
  }
  
  bool _isPromoRedemption(PurchasedItem purchase) {
    // Check for promo indicators
    if (Platform.isIOS) {
      // iOS: Check transaction type or price
      return purchase.priceAmountMicros == 0 || 
             purchase.isPromo == true;
    } else {
      // Android: Check purchase data
      final data = purchase.dataAndroid;
      return data?['promotionCode'] != null ||
             data?['promoApplied'] == true;
    }
  }
  
  void _processRedeemedPurchase(PurchasedItem purchase) {
    // 1. Verify the purchase
    _verifyRedeemedPurchase(purchase);
    
    // 2. Deliver content
    _deliverRedeemedContent(purchase);
    
    // 3. Track redemption
    _trackRedemption(purchase);
    
    // 4. Finish transaction
    _finishRedeemedTransaction(purchase);
  }
}
```

## Testing Offer Codes

### iOS Testing

```dart
class IOSOfferCodeTesting {
  // Test offer codes in sandbox
  static const testOfferCodes = {
    'TEST_FREE_MONTH': 'One month free trial',
    'TEST_50_PERCENT': '50% off first month',
    'TEST_3_MONTHS': '3 months for price of 1',
  };
  
  Future<void> testOfferCodeRedemption() async {
    if (!kDebugMode) {
      print('Test mode only');
      return;
    }
    
    // Present redemption sheet in sandbox
    try {
      await FlutterInappPurchase.instance.presentCodeRedemptionSheet();
      
      // Use sandbox test account
      print('Enter test offer code in sandbox environment');
      
    } catch (e) {
      print('Test redemption failed: $e');
    }
  }
  
  // Generate test promotional offer
  Future<void> testPromotionalOffer() async {
    // Test signature generation
    final signature = await _generateTestSignature(
      productId: 'test_subscription',
      offerIdentifier: 'test_offer',
    );
    
    // Test purchase with offer
    await _purchaseWithTestOffer(signature);
  }
}
```

### Android Testing

```dart
class AndroidPromoCodeTesting {
  // Test promo codes from Play Console
  static const testPromoCodes = [
    'TEST-CODE-1234-5678-90AB',
    'DEMO-SUBS-FREE-MONT-H123',
    'DISC-OUNT-FIFTY-PERC-ENT1',
  ];
  
  Future<void> testPromoCodeRedemption(String testCode) async {
    if (!kDebugMode) {
      print('Test mode only');
      return;
    }
=======
  /// Get promoted product (iOS only)
  Future<String?> getPromotedProduct() async {
    if (!Platform.isIOS) return null;
>>>>>>> 40157f9 (docs: Update guides and examples content)
    
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
<<<<<<< HEAD
class PromoCodeEntryScreen extends StatefulWidget {
  @override
  _PromoCodeEntryScreenState createState() => _PromoCodeEntryScreenState();
}

class _PromoCodeEntryScreenState extends State<PromoCodeEntryScreen> {
  final _controller = TextEditingController();
  final _promoHandler = UnifiedPromoCodeHandler();
  bool _isLoading = false;
  String? _errorMessage;
>>>>>>> 5e86ee0 (docs: Update community links and fix configuration)
=======
class OfferRedemptionPage extends StatelessWidget {
  final _offerHandler = CrossPlatformOfferHandler();
>>>>>>> 40157f9 (docs: Update guides and examples content)
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
<<<<<<< HEAD
<<<<<<< HEAD
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
=======
        title: Text('Redeem Code'),
=======
        title: Text('Redeem Offers'),
>>>>>>> 40157f9 (docs: Update guides and examples content)
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
<<<<<<< HEAD
            ElevatedButton(
              onPressed: _isLoading ? null : _redeemCode,
              child: Text(Platform.isIOS ? 'Redeem Offer' : 'Redeem Code'),
            ),
            if (Platform.isIOS) ...[
              SizedBox(height: 8),
              Text(
                'You will be redirected to the App Store to complete redemption',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
>>>>>>> 5e86ee0 (docs: Update community links and fix configuration)
=======
            if (Platform.isAndroid) ...[
              ElevatedButton(
                onPressed: () async {
                  await _offerHandler.handleOfferRedemption();
                },
                child: Text('Manage Subscriptions'),
>>>>>>> 40157f9 (docs: Update guides and examples content)
              ),
            ],
          ],
        ),
      ),
    );
  }
<<<<<<< HEAD
<<<<<<< HEAD
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
=======
  
  Future<void> _redeemCode() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      if (Platform.isIOS) {
        // iOS: Present system sheet
        await _promoHandler.redeemCode();
      } else {
        // Android: Validate and redeem
        final code = _controller.text.trim();
        
        if (code.isEmpty) {
          throw Exception('Please enter a promo code');
        }
        
        await _promoHandler.redeemCode(code: code);
      }
      
      // Show success or wait for result
      if (mounted) {
        _showRedemptionInProgress();
      }
      
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _showRedemptionInProgress() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Processing redemption...'),
          ],
        ),
      ),
    );
    
    // Auto-dismiss after timeout
    Future.delayed(Duration(seconds: 30), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }
}

// Custom formatter for Android promo codes
class PromoCodeFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.toUpperCase().replaceAll('-', '');
    final buffer = StringBuffer();
    
    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0 && i != text.length) {
        buffer.write('-');
      }
      buffer.write(text[i]);
    }
    
    final formatted = buffer.toString();
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
=======
>>>>>>> 40157f9 (docs: Update guides and examples content)
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

<<<<<<< HEAD
### Troubleshooting Guide

1. **Code Not Working**
   - Verify code format
   - Check expiration date
   - Ensure user eligibility
   - Validate on server

2. **Redemption Sheet Not Appearing (iOS)**
   - Check iOS version (14.0+)
   - Verify store connection
   - Check entitlements

3. **Play Store Not Opening (Android)**
   - Check URL format
   - Verify Play Store installed
   - Check package name

4. **Purchase Not Completing**
   - Monitor purchase streams
   - Check for pending transactions
   - Verify receipt validation

## Next Steps

- Implement server-side validation for security
- Set up analytics tracking for redemption metrics
- Test with real promo codes in production
- Review the [Troubleshooting Guide](./troubleshooting.md) for common issues
>>>>>>> 5e86ee0 (docs: Update community links and fix configuration)
=======
1. Always check platform before calling platform-specific methods
2. Handle errors gracefully as native dialogs may fail
3. Listen to purchase streams when presenting offer code redemption
4. Use subscription management for user convenience
>>>>>>> 40157f9 (docs: Update guides and examples content)
