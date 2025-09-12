import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

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

  /// Presents the code redemption sheet (iOS 14+)
  Future<void> presentCodeRedemptionSheetIOS() async {
    if (!isIOS) {
      throw PlatformException(
        code: operatingSystem,
        message: 'presentCodeRedemptionSheetIOS is only supported on iOS',
      );
    }

    await channel.invokeMethod('presentCodeRedemptionSheetIOS');
  }

  /// Clear pending transactions (iOS only)
  Future<void> clearTransactionIOS() async {
    if (!isIOS) return;
    await channel.invokeMethod('clearTransactionIOS');
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
  Future<void> requestPurchaseOnPromotedProductIOS() async {
    if (!isIOS) return;
    await channel.invokeMethod('requestPurchaseOnPromotedProductIOS');
  }

  /// Shows manage subscriptions screen (iOS)
  Future<void> showManageSubscriptionsIOS() async {
    if (!isIOS) {
      throw PlatformException(
        code: operatingSystem,
        message: 'showManageSubscriptionsIOS is only supported on iOS',
      );
    }

    await channel.invokeMethod('showManageSubscriptionsIOS');
  }

  /// Gets the iOS app transaction (iOS 18.4+)
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
