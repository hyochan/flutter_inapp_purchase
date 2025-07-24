import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import '../types.dart';

/// iOS-specific IAP functionality as a mixin
mixin FlutterInappPurchaseIOS {
  MethodChannel get channel;
  bool get _isIOS;
  String get _operatingSystem;

  /// Sync purchases that are not finished yet to be finished.
  /// Returns true if successful, false if running on Android
  Future<bool> syncIOS() async {
    if (!_isIOS) {
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
    if (!_isIOS) {
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
    if (!_isIOS) {
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

  /// Gets the subscription group for a given SKU
  Future<String?> getSubscriptionGroupIOS(String sku) async {
    if (!_isIOS) {
      return null;
    }

    try {
      return await channel.invokeMethod<String>(
        'getSubscriptionGroup',
        {'sku': sku},
      );
    } catch (error) {
      debugPrint('Error getting subscription group: $error');
      return null;
    }
  }

  /// Requests a purchase with offer (iOS 12.2+)
  @Deprecated(
      'Use requestPurchase() with RequestPurchase object. Will be removed in 6.0.0')
  Future<void> requestProductWithOfferIOS(
    String sku,
    String appAccountToken,
    Map<String, dynamic> withOffer,
  ) async {
    if (!_isIOS) {
      throw PlatformException(
        code: _operatingSystem,
        message: 'requestProductWithOfferIOS is only supported on iOS',
      );
    }

    await channel.invokeMethod('requestProductWithOfferIOS', <String, dynamic>{
      'sku': sku,
      'appAccountToken': appAccountToken,
      'withOffer': withOffer,
    });
  }

  /// Requests a purchase with quantity (iOS)
  @Deprecated(
      'Use requestPurchase() with RequestPurchase object. Will be removed in 6.0.0')
  Future<void> requestPurchaseWithQuantityIOS(String sku, int quantity) async {
    if (!_isIOS) {
      throw PlatformException(
        code: _operatingSystem,
        message: 'requestPurchaseWithQuantityIOS is only supported on iOS',
      );
    }

    await channel
        .invokeMethod('requestPurchaseWithQuantityIOS', <String, dynamic>{
      'sku': sku,
      'quantity': quantity,
    });
  }

  /// Gets the iOS app store country code
  Future<String?> getAppStoreCountryIOS() async {
    if (!_isIOS) {
      return null;
    }

    try {
      return await channel.invokeMethod<String>('getAppStoreCountry');
    } catch (error) {
      debugPrint('Error getting App Store country: $error');
      return null;
    }
  }

  /// Presents the code redemption sheet (iOS 14+)
  Future<void> presentCodeRedemptionSheetIOS() async {
    if (!_isIOS) {
      throw PlatformException(
        code: _operatingSystem,
        message: 'presentCodeRedemptionSheetIOS is only supported on iOS',
      );
    }

    await channel.invokeMethod('presentCodeRedemptionSheet');
  }

  /// Shows manage subscriptions screen (iOS)
  Future<void> showManageSubscriptionsIOS() async {
    if (!_isIOS) {
      throw PlatformException(
        code: _operatingSystem,
        message: 'showManageSubscriptionsIOS is only supported on iOS',
      );
    }

    await channel.invokeMethod('showManageSubscriptions');
  }

  /// Gets available items (iOS)
  Future<List<PurchasedItem>?> getAvailableItemsIOS() async {
    if (!_isIOS) {
      return null;
    }

    try {
      final result = await channel.invokeMethod<String>('getAvailableItems');
      if (result == null) return null;

      return extractPurchasedItems(result);
    } catch (error) {
      debugPrint('Error getting available items: $error');
      return null;
    }
  }

  /// Gets the iOS app transaction (iOS 18.4+)
  Future<Map<String, dynamic>?> getAppTransactionIOS() async {
    if (!_isIOS) {
      return null;
    }

    try {
      final result = await channel
          .invokeMethod<Map<dynamic, dynamic>>('getAppTransaction');
      return result?.cast<String, dynamic>();
    } catch (error) {
      debugPrint('Error getting app transaction: $error');
      return null;
    }
  }

  /// Gets the typed iOS app transaction (iOS 18.4+)
  Future<AppTransaction?> getAppTransactionTypedIOS() async {
    final transactionMap = await getAppTransactionIOS();
    if (transactionMap != null) {
      try {
        return AppTransaction.fromMap(transactionMap);
      } catch (e) {
        debugPrint('getAppTransactionTyped parsing error: $e');
        return null;
      }
    }
    return null;
  }

  /// iOS-specific utility function
  List<PurchasedItem>? extractPurchasedItems(dynamic result);
}

/// iOS App Transaction model (iOS 18.4+)
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
