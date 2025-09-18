import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

import '../types.dart' as types;

/// iOS-specific IAP functionality as a mixin
mixin FlutterInappPurchaseIOS {
  MethodChannel get channel;
  bool get isIOS;
  String get operatingSystem;

  /// Abstract method that needs to be implemented by the class using this mixin
  List<Purchase>? extractPurchasedItems(dynamic result);

  /// Sync purchases that are not finished yet to be finished.
  /// Returns true if successful, false if running on Android
  Future<bool> syncIOS() async {
    if (!isIOS) {
      debugPrint('syncIOS is only supported on iOS');
      return false;
    }

    try {
      await channel.invokeMethod('endConnection');
      await channel.invokeMethod('initConnection');
      return true;
    } catch (error) {
      debugPrint('Error syncing iOS purchases: $error');
      rethrow;
    }
  }

  /// Checks if the current user is eligible for an introductory offer
  /// for a given product ID
  Future<bool> isEligibleForIntroOfferIOS(String productId) async {
    if (!isIOS) {
      return false;
    }

    try {
      final result = await channel.invokeMethod<bool>(
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
  Future<Map<String, dynamic>?> getSubscriptionStatusIOS(String sku) async {
    if (!isIOS) {
      return null;
    }

    try {
      final result = await channel.invokeMethod<Map<dynamic, dynamic>>(
        'getSubscriptionStatus',
        {'sku': sku},
      );
      return result?.cast<String, dynamic>();
    } catch (error) {
      debugPrint('Error getting subscription status: $error');
      return null;
    }
  }

  /// Gets the subscription group identifier for a given product ID (iOS)
  Future<String?> getSubscriptionGroupIOS(String productId) async {
    if (!isIOS) {
      return null;
    }

    try {
      final result = await channel.invokeMethod<String>(
        'getSubscriptionGroup',
        {'sku': productId},
      );
      return result;
    } catch (error) {
      debugPrint('Error getting subscription group: $error');
      return null;
    }
  }

  /// Gets the user's App Store country code (iOS)
  Future<String?> getAppStoreCountryIOS() async {
    if (!isIOS) {
      return null;
    }

    try {
      final result = await channel.invokeMethod<String>('getAppStoreCountry');
      return result;
    } catch (error) {
      debugPrint('Error getting App Store country: $error');
      return null;
    }
  }

  /// Presents the code redemption sheet (iOS 14+)
  types.MutationPresentCodeRedemptionSheetIOSHandler
      get presentCodeRedemptionSheetIOS => () async {
            if (!isIOS) {
              throw PlatformException(
                code: operatingSystem,
                message:
                    'presentCodeRedemptionSheetIOS is only supported on iOS',
              );
            }

            await channel.invokeMethod('presentCodeRedemptionSheetIOS');
            return true;
          };

  /// Clear pending transactions (iOS only)
  Future<bool> clearTransactionIOS() async {
    if (!isIOS) return false;
    try {
      await channel.invokeMethod('clearTransactionIOS');
      return true;
    } catch (error) {
      debugPrint('Error clearing pending transactions: $error');
      return false;
    }
  }

  /// Get the currently promoted product (iOS 11+)
  Future<Map<String, dynamic>?> getPromotedProductIOS() async {
    if (!isIOS) return null;
    final result = await channel.invokeMethod('getPromotedProductIOS');
    if (result == null) return null;
    if (result is Map) return Map<String, dynamic>.from(result);
    if (result is String) return {'productIdentifier': result};
    return null;
  }

  /// Request purchase on promoted product (iOS 11+)
  Future<bool> requestPurchaseOnPromotedProductIOS() async {
    if (!isIOS) {
      return false;
    }
    try {
      await channel.invokeMethod('requestPurchaseOnPromotedProductIOS');
      return true;
    } catch (error) {
      debugPrint('Error requesting promoted product purchase: $error');
      return false;
    }
  }

  /// Shows manage subscriptions screen (iOS)
  types.MutationShowManageSubscriptionsIOSHandler
      get showManageSubscriptionsIOS => () async {
            if (!isIOS) {
              throw PlatformException(
                code: operatingSystem,
                message: 'showManageSubscriptionsIOS is only supported on iOS',
              );
            }

            await channel.invokeMethod('showManageSubscriptionsIOS');
            return const <PurchaseIOS>[];
          };

  /// Gets available items (iOS-only convenience that parses to typed purchases)
  Future<List<Purchase>?> getAvailableItemsIOS() async {
    if (!isIOS) return null;
    try {
      final dynamic result = await channel.invokeMethod('getAvailableItems');
      return extractPurchasedItems(result);
    } catch (error) {
      debugPrint('Error getting available items (iOS): $error');
      return null;
    }
  }

  /// Gets the iOS app transaction (iOS 15+)
  Future<Map<String, dynamic>?> getAppTransactionIOS() async {
    if (!isIOS) {
      return null;
    }

    try {
      final result = await channel.invokeMethod<Map<dynamic, dynamic>>(
        'getAppTransaction',
      );
      return result?.cast<String, dynamic>();
    } catch (error) {
      debugPrint('Error getting app transaction: $error');
      return null;
    }
  }

  /// Attempts to parse the app transaction into a typed object.
  /// Returns null if essential fields are missing.
  Future<AppTransaction?> getAppTransactionTypedIOS() async {
    final map = await getAppTransactionIOS();
    if (map == null) return null;
    // Validate presence of essential fields for typed parsing
    final requiredKeys = [
      'version',
      'bundleId',
      'originalPurchaseDate',
      'originalTransactionId',
    ];
    for (final k in requiredKeys) {
      if (!map.containsKey(k)) return null;
    }
    try {
      return AppTransaction.fromMap(map);
    } catch (_) {
      return null;
    }
  }

  /// Fetch purchase histories on iOS and decode to typed purchases
  Future<List<Purchase>> getPurchaseHistoriesIOS() async {
    if (!isIOS) return <Purchase>[];
    try {
      final dynamic result =
          await channel.invokeMethod('getPurchaseHistoriesIOS');
      final items = extractPurchasedItems(result) ?? <Purchase>[];
      return items;
    } catch (error) {
      debugPrint('Error getting purchase histories (iOS): $error');
      return <Purchase>[];
    }
  }
}

/// iOS App Transaction model (iOS 15+)
class AppTransaction {
  final int version;
  final String bundleId;
  final String originalPurchaseDate;
  final String originalTransactionId;
  final String deviceVerification;
  final String deviceVerificationNonce;
  final bool preorder;
  final String deviceId;

  AppTransaction({
    required this.version,
    required this.bundleId,
    required this.originalPurchaseDate,
    required this.originalTransactionId,
    required this.deviceVerification,
    required this.deviceVerificationNonce,
    required this.preorder,
    required this.deviceId,
  });

  factory AppTransaction.fromMap(Map<String, dynamic> map) {
    return AppTransaction(
      version: map['version'] as int,
      bundleId: map['bundleId'] as String,
      originalPurchaseDate: map['originalPurchaseDate'] as String,
      originalTransactionId: map['originalTransactionId'] as String,
      deviceVerification: map['deviceVerification'] as String,
      deviceVerificationNonce: map['deviceVerificationNonce'] as String,
      preorder: map['preorder'] as bool,
      deviceId: map['deviceId'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'version': version,
      'bundleId': bundleId,
      'originalPurchaseDate': originalPurchaseDate,
      'originalTransactionId': originalTransactionId,
      'deviceVerification': deviceVerification,
      'deviceVerificationNonce': deviceVerificationNonce,
      'preorder': preorder,
      'deviceId': deviceId,
    };
  }
}
