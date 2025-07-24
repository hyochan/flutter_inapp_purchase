import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import '../enums.dart';

/// iOS-specific IAP functionality
class IAPiOS {
  static const MethodChannel _channel = 
      MethodChannel('flutter_inapp_purchase');

  /// Sync purchases that are not finished yet to be finished.
  /// Returns true if successful, false if running on Android
  static Future<bool> syncIOS() async {
    if (!Platform.isIOS) {
      debugPrint('syncIOS is only supported on iOS');
      return false;
    }

    try {
      await _channel.invokeMethod('endConnection');
      await _channel.invokeMethod('initConnection');
      return true;
    } catch (error) {
      debugPrint('Error syncing iOS purchases: $error');
      rethrow;
    }
  }

  /// Checks if the current user is eligible for an introductory offer
  /// for a given product ID
  static Future<bool> isEligibleForIntroOfferIOS(String productId) async {
    if (!Platform.isIOS) {
      return false;
    }

    try {
      final result = await _channel.invokeMethod<bool>(
        'isEligibleForIntroOffer',
        {'productId': productId},
      );
      return result ?? false;
    } catch (error) {
      debugPrint('Error checking intro offer eligibility: $error');
      return false;
    }
  }

  /// Gets the subscription status for a specific SKU
  /// Returns null if not iOS or if status cannot be determined
  static Future<SubscriptionState?> subscriptionStatusIOS(String sku) async {
    if (!Platform.isIOS) {
      return null;
    }

    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'getSubscriptionStatus',
        {'sku': sku},
      );

      if (result == null) {
        return null;
      }

      final status = result['status'] as String?;
      if (status == null) {
        return null;
      }

      // Map the status string to SubscriptionState enum
      switch (status) {
        case 'active':
          return SubscriptionState.active;
        case 'expired':
          return SubscriptionState.expired;
        case 'in_billing_retry':
          return SubscriptionState.inBillingRetry;
        case 'in_grace_period':
          return SubscriptionState.inGracePeriod;
        case 'revoked':
          return SubscriptionState.revoked;
        default:
          return null;
      }
    } catch (error) {
      debugPrint('Error getting subscription status: $error');
      return null;
    }
  }

  /// Retrieves the latest App Transaction information
  /// Only available on iOS 18.4+
  static Future<Map<String, dynamic>?> getAppTransactionIOS() async {
    if (!Platform.isIOS) {
      return null;
    }

    try {
      final result = await _channel.invokeMethod('getAppTransaction');
      if (result != null) {
        return Map<String, dynamic>.from(result as Map<dynamic, dynamic>);
      }
      return null;
    } catch (error) {
      debugPrint('getAppTransaction error: $error');
      return null;
    }
  }

  /// Presents the offer code redemption sheet
  /// Returns true if presented successfully
  static Future<bool> presentOfferCodeRedemptionSheetIOS() async {
    if (!Platform.isIOS) {
      return false;
    }

    try {
      final result = await _channel.invokeMethod<bool>(
        'presentCodeRedemptionSheet'
      );
      return result ?? false;
    } catch (error) {
      debugPrint('Error presenting offer code redemption sheet: $error');
      return false;
    }
  }

  /// Shows the manage subscriptions page in App Store
  static Future<void> showManageSubscriptionsIOS() async {
    if (!Platform.isIOS) {
      debugPrint('showManageSubscriptionsIOS is only supported on iOS');
      return;
    }

    try {
      await _channel.invokeMethod('showManageSubscriptions');
    } catch (error) {
      debugPrint('Error showing manage subscriptions: $error');
      rethrow;
    }
  }

  /// Clears all pending transactions
  /// This is useful for testing or when transactions get stuck
  static Future<void> clearTransactionsIOS() async {
    if (!Platform.isIOS) {
      debugPrint('clearTransactionsIOS is only supported on iOS');
      return;
    }

    try {
      await _channel.invokeMethod('clearTransactions');
    } catch (error) {
      debugPrint('Error clearing transactions: $error');
      rethrow;
    }
  }

  /// Processes pending transactions
  /// Returns a list of processed transaction IDs
  static Future<List<String>> processPendingTransactionsIOS() async {
    if (!Platform.isIOS) {
      return [];
    }

    try {
      final result = await _channel.invokeMethod<List<dynamic>>(
        'processPendingTransactions'
      );
      
      if (result == null) {
        return [];
      }

      return result.map((e) => e.toString()).toList();
    } catch (error) {
      debugPrint('Error processing pending transactions: $error');
      return [];
    }
  }

  /// Validates the receipt with Apple's servers
  /// This is for server-side validation and should not be used in production
  /// from the client side
  static Future<Map<String, dynamic>?> validateReceiptIOS({
    required String receiptBody,
    bool isTest = false,
  }) async {
    if (!Platform.isIOS) {
      return null;
    }

    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'validateReceipt',
        {
          'receiptBody': receiptBody,
          'isTest': isTest,
        },
      );

      if (result != null) {
        return Map<String, dynamic>.from(result as Map<dynamic, dynamic>);
      }
      return null;
    } catch (error) {
      debugPrint('Error validating receipt: $error');
      return null;
    }
  }

  /// Gets the current App Store receipt
  /// Returns base64 encoded receipt data
  static Future<String?> getReceiptIOS() async {
    if (!Platform.isIOS) {
      return null;
    }

    try {
      final result = await _channel.invokeMethod<String>('getReceipt');
      return result;
    } catch (error) {
      debugPrint('Error getting receipt: $error');
      return null;
    }
  }

  /// Requests a review prompt using StoreKit
  /// Note: This doesn't guarantee the prompt will be shown
  static Future<void> requestReviewIOS() async {
    if (!Platform.isIOS) {
      debugPrint('requestReviewIOS is only supported on iOS');
      return;
    }

    try {
      await _channel.invokeMethod('requestReview');
    } catch (error) {
      debugPrint('Error requesting review: $error');
    }
  }

  /// Gets promoted products (products promoted in the App Store)
  /// These are products that the App Store is trying to promote to the user
  static Future<List<String>> getPromotedProductsIOS() async {
    if (!Platform.isIOS) {
      return [];
    }

    try {
      final result = await _channel.invokeMethod<List<dynamic>>(
        'getPromotedProducts'
      );
      
      if (result == null) {
        return [];
      }

      return result.map((e) => e.toString()).toList();
    } catch (error) {
      debugPrint('Error getting promoted products: $error');
      return [];
    }
  }

  /// Sets whether a product should be visible in the App Store promotion
  static Future<void> setPromotedProductIOS({
    required String productId,
    required bool visible,
  }) async {
    if (!Platform.isIOS) {
      debugPrint('setPromotedProductIOS is only supported on iOS');
      return;
    }

    try {
      await _channel.invokeMethod('setPromotedProduct', {
        'productId': productId,
        'visible': visible,
      });
    } catch (error) {
      debugPrint('Error setting promoted product: $error');
      rethrow;
    }
  }

  /// Gets the order of promoted products
  static Future<List<String>> getPromotedProductOrderIOS() async {
    if (!Platform.isIOS) {
      return [];
    }

    try {
      final result = await _channel.invokeMethod<List<dynamic>>(
        'getPromotedProductOrder'
      );
      
      if (result == null) {
        return [];
      }

      return result.map((e) => e.toString()).toList();
    } catch (error) {
      debugPrint('Error getting promoted product order: $error');
      return [];
    }
  }

  /// Sets the order of promoted products
  static Future<void> setPromotedProductOrderIOS(List<String> productIds) async {
    if (!Platform.isIOS) {
      debugPrint('setPromotedProductOrderIOS is only supported on iOS');
      return;
    }

    try {
      await _channel.invokeMethod('setPromotedProductOrder', {
        'productIds': productIds,
      });
    } catch (error) {
      debugPrint('Error setting promoted product order: $error');
      rethrow;
    }
  }

  /// Gets pending transactions that need to be finished
  static Future<List<Map<String, dynamic>>> getPendingTransactionsIOS() async {
    if (!Platform.isIOS) {
      return [];
    }

    try {
      final result = await _channel.invokeMethod<List<dynamic>>(
        'getPendingTransactions'
      );
      
      if (result == null) {
        return [];
      }

      return result.map((item) => Map<String, dynamic>.from(item as Map<dynamic, dynamic>)).toList();
    } catch (error) {
      debugPrint('Error getting pending transactions: $error');
      return [];
    }
  }

  /// Finishes all pending transactions
  /// Useful for cleanup and testing
  static Future<void> finishAllTransactionsIOS() async {
    if (!Platform.isIOS) {
      debugPrint('finishAllTransactionsIOS is only supported on iOS');
      return;
    }

    try {
      await _channel.invokeMethod('finishAllTransactions');
    } catch (error) {
      debugPrint('Error finishing all transactions: $error');
      rethrow;
    }
  }

  /// Gets the storefront identifier (country code)
  static Future<String?> getStorefrontIOS() async {
    if (!Platform.isIOS) {
      return null;
    }

    try {
      final result = await _channel.invokeMethod<String>('getStorefront');
      return result;
    } catch (error) {
      debugPrint('Error getting storefront: $error');
      return null;
    }
  }

  /// Checks if the app can make payments
  static Future<bool> canMakePaymentsIOS() async {
    if (!Platform.isIOS) {
      return false;
    }

    try {
      final result = await _channel.invokeMethod<bool>('canMakePayments');
      return result ?? false;
    } catch (error) {
      debugPrint('Error checking if can make payments: $error');
      return false;
    }
  }
}