import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import '../enums.dart';

/// Android-specific IAP functionality
class IAPAndroid {
  static const MethodChannel _channel = MethodChannel('flutter_inapp_purchase');

  /// Deep links to subscriptions screen on Android devices
  /// @param sku - The SKU of the subscription to deep link to
  static Future<void> deepLinkToSubscriptionsAndroid({String? sku}) async {
    if (!Platform.isAndroid) {
      debugPrint('deepLinkToSubscriptionsAndroid is only supported on Android');
      return;
    }

    try {
      await _channel.invokeMethod('manageSubscription', {
        if (sku != null) 'sku': sku,
      });
    } catch (error) {
      debugPrint('Error deep linking to subscriptions: $error');
      rethrow;
    }
  }

  /// Validates a purchase on Android (for server-side validation)
  /// @param packageName - The package name of the app
  /// @param productId - The product ID
  /// @param productToken - The purchase token
  /// @param accessToken - The access token for validation
  /// @param isSub - Whether this is a subscription
  static Future<Map<String, dynamic>?> validateReceiptAndroid({
    required String packageName,
    required String productId,
    required String productToken,
    required String accessToken,
    required bool isSub,
  }) async {
    if (!Platform.isAndroid) {
      return null;
    }

    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'validateReceiptAndroid',
        {
          'packageName': packageName,
          'productId': productId,
          'productToken': productToken,
          'accessToken': accessToken,
          'isSub': isSub,
        },
      );

      if (result != null) {
        return Map<String, dynamic>.from(result);
      }
      return null;
    } catch (error) {
      debugPrint('Error validating Android receipt: $error');
      return null;
    }
  }

  /// Acknowledges a purchase on Android
  /// @param token - The purchase token to acknowledge
  /// @param developerPayload - Optional developer payload
  static Future<PurchaseResult?> acknowledgePurchaseAndroid({
    required String token,
    String? developerPayload,
  }) async {
    if (!Platform.isAndroid) {
      return null;
    }

    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'acknowledgePurchase',
        {
          'token': token,
          if (developerPayload != null) 'developerPayload': developerPayload,
        },
      );

      if (result != null) {
        return PurchaseResult(
          responseCode: (result['responseCode'] as int?) ?? 0,
          debugMessage: result['debugMessage'] as String?,
          code: result['code'] as String?,
          message: result['message'] as String?,
        );
      }
      return null;
    } catch (error) {
      debugPrint('Error acknowledging purchase: $error');
      return null;
    }
  }

  /// Consumes a purchase on Android
  /// @param token - The purchase token to consume
  /// @param developerPayload - Optional developer payload
  static Future<PurchaseResult?> consumePurchaseAndroid({
    required String token,
    String? developerPayload,
  }) async {
    if (!Platform.isAndroid) {
      return null;
    }

    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'consumeProduct',
        {
          'token': token,
          if (developerPayload != null) 'developerPayload': developerPayload,
        },
      );

      if (result != null) {
        return PurchaseResult(
          responseCode: (result['responseCode'] as int?) ?? 0,
          debugMessage: result['debugMessage'] as String?,
          code: result['code'] as String?,
          message: result['message'] as String?,
        );
      }
      return null;
    } catch (error) {
      debugPrint('Error consuming purchase: $error');
      return null;
    }
  }

  /// Flushes any pending purchases
  /// This ensures all purchase events are processed
  static Future<void> flushAndroid() async {
    if (!Platform.isAndroid) {
      debugPrint('flushAndroid is only supported on Android');
      return;
    }

    try {
      await _channel.invokeMethod('flush');
    } catch (error) {
      debugPrint('Error flushing purchases: $error');
      rethrow;
    }
  }

  /// Gets the Play Store connection state
  static Future<bool> getConnectionStateAndroid() async {
    if (!Platform.isAndroid) {
      return false;
    }

    try {
      final result = await _channel.invokeMethod<bool>('isReady');
      return result ?? false;
    } catch (error) {
      debugPrint('Error getting connection state: $error');
      return false;
    }
  }

  /// Checks if billing is supported for the given type
  /// @param type - The purchase type (inapp or subs)
  static Future<bool> isBillingSupportedAndroid(PurchaseType type) async {
    if (!Platform.isAndroid) {
      return false;
    }

    try {
      final result = await _channel.invokeMethod<bool>(
        'isBillingSupported',
        {'type': type == PurchaseType.subs ? 'subs' : 'inapp'},
      );
      return result ?? false;
    } catch (error) {
      debugPrint('Error checking billing support: $error');
      return false;
    }
  }

  /// Gets purchase history for Android
  /// @param type - The type of purchases to retrieve (inapp or subs)
  static Future<List<Map<String, dynamic>>> getPurchaseHistoryAndroid({
    PurchaseType type = PurchaseType.inapp,
  }) async {
    if (!Platform.isAndroid) {
      return [];
    }

    try {
      final result = await _channel.invokeMethod<List<dynamic>>(
        'getPurchaseHistoryByType',
        {'type': type == PurchaseType.subs ? 'subs' : 'inapp'},
      );

      if (result == null) {
        return [];
      }

      return result
          .map((item) =>
              Map<String, dynamic>.from(item as Map<dynamic, dynamic>))
          .toList();
    } catch (error) {
      debugPrint('Error getting purchase history: $error');
      return [];
    }
  }

  /// Gets available items (owned items) on Android
  /// @param type - The type of items to retrieve (inapp or subs)
  static Future<List<Map<String, dynamic>>> getAvailableItemsAndroid({
    PurchaseType type = PurchaseType.inapp,
  }) async {
    if (!Platform.isAndroid) {
      return [];
    }

    try {
      final result = await _channel.invokeMethod<List<dynamic>>(
        'getAvailableItemsByType',
        {'type': type == PurchaseType.subs ? 'subs' : 'inapp'},
      );

      if (result == null) {
        return [];
      }

      return result
          .map((item) =>
              Map<String, dynamic>.from(item as Map<dynamic, dynamic>))
          .toList();
    } catch (error) {
      debugPrint('Error getting available items: $error');
      return [];
    }
  }

  /// Shows the in-app messages for Android
  /// This displays any pending messages from Google Play
  static Future<void> showInAppMessagesAndroid() async {
    if (!Platform.isAndroid) {
      debugPrint('showInAppMessagesAndroid is only supported on Android');
      return;
    }

    try {
      await _channel.invokeMethod('showInAppMessages');
    } catch (error) {
      debugPrint('Error showing in-app messages: $error');
      rethrow;
    }
  }

  /// Gets the installed Google Play Store package info
  static Future<Map<String, dynamic>?> getPlayStorePackageInfoAndroid() async {
    if (!Platform.isAndroid) {
      return null;
    }

    try {
      final result = await _channel
          .invokeMethod<Map<dynamic, dynamic>>('getPlayStorePackageInfo');

      if (result != null) {
        return Map<String, dynamic>.from(result);
      }
      return null;
    } catch (error) {
      debugPrint('Error getting Play Store package info: $error');
      return null;
    }
  }

  /// Checks if the Google Play Store is available
  static Future<bool> isPlayStoreAvailableAndroid() async {
    if (!Platform.isAndroid) {
      return false;
    }

    try {
      final result = await _channel.invokeMethod<bool>('isPlayStoreAvailable');
      return result ?? false;
    } catch (error) {
      debugPrint('Error checking Play Store availability: $error');
      return false;
    }
  }

  /// Gets the billing client version
  static Future<String?> getBillingClientVersionAndroid() async {
    if (!Platform.isAndroid) {
      return null;
    }

    try {
      final result =
          await _channel.invokeMethod<String>('getBillingClientVersion');
      return result;
    } catch (error) {
      debugPrint('Error getting billing client version: $error');
      return null;
    }
  }

  /// Sets obfuscated account ID for purchases
  /// @param accountId - The obfuscated account ID
  static Future<void> setObfuscatedAccountIdAndroid(String accountId) async {
    if (!Platform.isAndroid) {
      debugPrint('setObfuscatedAccountIdAndroid is only supported on Android');
      return;
    }

    try {
      await _channel.invokeMethod('setObfuscatedAccountId', {
        'accountId': accountId,
      });
    } catch (error) {
      debugPrint('Error setting obfuscated account ID: $error');
      rethrow;
    }
  }

  /// Sets obfuscated profile ID for purchases
  /// @param profileId - The obfuscated profile ID
  static Future<void> setObfuscatedProfileIdAndroid(String profileId) async {
    if (!Platform.isAndroid) {
      debugPrint('setObfuscatedProfileIdAndroid is only supported on Android');
      return;
    }

    try {
      await _channel.invokeMethod('setObfuscatedProfileId', {
        'profileId': profileId,
      });
    } catch (error) {
      debugPrint('Error setting obfuscated profile ID: $error');
      rethrow;
    }
  }

  /// Launches the billing flow for a product
  /// @param sku - The SKU to purchase
  /// @param prorationMode - The proration mode for subscription upgrades/downgrades
  /// @param obfuscatedAccountId - Optional obfuscated account ID
  /// @param obfuscatedProfileId - Optional obfuscated profile ID
  /// @param purchaseToken - Optional purchase token for subscription replacement
  static Future<bool> launchBillingFlowAndroid({
    required String sku,
    ProrationMode? prorationMode,
    String? obfuscatedAccountId,
    String? obfuscatedProfileId,
    String? purchaseToken,
  }) async {
    if (!Platform.isAndroid) {
      return false;
    }

    try {
      final result = await _channel.invokeMethod<bool>(
        'launchBillingFlow',
        {
          'sku': sku,
          if (prorationMode != null) 'prorationMode': prorationMode.index,
          if (obfuscatedAccountId != null)
            'obfuscatedAccountId': obfuscatedAccountId,
          if (obfuscatedProfileId != null)
            'obfuscatedProfileId': obfuscatedProfileId,
          if (purchaseToken != null) 'purchaseToken': purchaseToken,
        },
      );
      return result ?? false;
    } catch (error) {
      debugPrint('Error launching billing flow: $error');
      return false;
    }
  }

  /// Gets pending purchases
  static Future<List<Map<String, dynamic>>> getPendingPurchasesAndroid() async {
    if (!Platform.isAndroid) {
      return [];
    }

    try {
      final result =
          await _channel.invokeMethod<List<dynamic>>('getPendingPurchases');

      if (result == null) {
        return [];
      }

      return result
          .map((item) =>
              Map<String, dynamic>.from(item as Map<dynamic, dynamic>))
          .toList();
    } catch (error) {
      debugPrint('Error getting pending purchases: $error');
      return [];
    }
  }
}

/// Purchase result from Android operations
class PurchaseResult {
  final int responseCode;
  final String? debugMessage;
  final String? code;
  final String? message;

  PurchaseResult({
    required this.responseCode,
    this.debugMessage,
    this.code,
    this.message,
  });

  bool get isSuccess => responseCode == 0;
}
