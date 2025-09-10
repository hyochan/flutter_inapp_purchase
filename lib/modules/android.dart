import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../types.dart';

/// Android-specific IAP functionality as a mixin
mixin FlutterInappPurchaseAndroid {
  MethodChannel get channel;
  bool get isAndroid;

  /// Deep links to subscriptions screen on Android devices
  /// @param sku - The SKU of the subscription to deep link to
  Future<void> deepLinkToSubscriptionsAndroid({String? sku}) async {
    if (!isAndroid) {
      debugPrint('deepLinkToSubscriptionsAndroid is only supported on Android');
      return;
    }

    try {
      await channel.invokeMethod('manageSubscription', {
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
  Future<Map<String, dynamic>?> validateReceiptAndroid({
    required String packageName,
    required String productId,
    required String productToken,
    required String accessToken,
    required bool isSub,
  }) async {
    if (!isAndroid) {
      return null;
    }

    try {
      final result = await channel
          .invokeMethod<Map<dynamic, dynamic>>('validateReceiptAndroid', {
        'packageName': packageName,
        'productId': productId,
        'productToken': productToken,
        'accessToken': accessToken,
        'isSub': isSub,
      });
      return result?.cast<String, dynamic>();
    } catch (error) {
      debugPrint('Error validating receipt: $error');
      return null;
    }
  }

  /// Consumes a purchase on Android (for consumable products)
  /// @param purchaseToken - The purchase token to consume
  Future<bool> consumePurchaseAndroid({required String purchaseToken}) async {
    if (!isAndroid) {
      return false;
    }

    try {
      final result = await channel.invokeMethod<bool>('consumePurchase', {
        'purchaseToken': purchaseToken,
      });
      return result ?? false;
    } catch (error) {
      debugPrint('Error consuming purchase: $error');
      return false;
    }
  }

  /// Gets in-app messages for Android
  Future<List<InAppMessage>> getInAppMessagesAndroid() async {
    if (!isAndroid) {
      return [];
    }

    try {
      final result = await channel.invokeMethod<String>('getInAppMessages');
      if (result == null) return [];

      final List<dynamic> messages = json.decode(result) as List<dynamic>;
      return messages
          .map(
            (message) => InAppMessage.fromMap(message as Map<String, dynamic>),
          )
          .toList();
    } catch (error) {
      debugPrint('Error getting in-app messages: $error');
      return [];
    }
  }

  /// Shows in-app messages for Android
  /// @param messageType - The type of message to show
  Future<bool> showInAppMessagesAndroid({
    InAppMessageType messageType = InAppMessageType.generic,
  }) async {
    if (!isAndroid) {
      return false;
    }

    try {
      final result = await channel.invokeMethod<bool>('showInAppMessages', {
        'messageType': messageType.index,
      });
      return result ?? false;
    } catch (error) {
      debugPrint('Error showing in-app messages: $error');
      return false;
    }
  }

  /// Validates a receipt on Google Play (server-side)
  /// @param packageName - The package name
  /// @param productId - The product ID
  /// @param productToken - The purchase token
  /// @param accessToken - The access token
  /// @param isSub - Whether this is a subscription
  Future<PurchaseResult?> validateReceiptAndroidInGooglePlay({
    required String packageName,
    required String productId,
    required String productToken,
    required String accessToken,
    required bool isSub,
  }) async {
    final type = isSub ? 'subscriptions' : 'products';
    final url =
        'https://androidpublisher.googleapis.com/androidpublisher/v3/applications/$packageName/purchases/$type/$productId/tokens/$productToken?access_token=$accessToken';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return PurchaseResult.fromJSON({
          'responseCode': 0,
          'purchaseData': data,
        });
      } else {
        return PurchaseResult.fromJSON({
          'responseCode': response.statusCode,
          'debugMessage': response.body,
        });
      }
    } catch (error) {
      return PurchaseResult.fromJSON({
        'responseCode': -1,
        'debugMessage': error.toString(),
      });
    }
  }

  /// Gets the Play Store connection state
  Future<BillingClientState> getConnectionStateAndroid() async {
    if (!isAndroid) {
      return BillingClientState.disconnected;
    }

    try {
      final result = await channel.invokeMethod<int>('getConnectionState');
      switch (result) {
        case 0:
          return BillingClientState.disconnected;
        case 1:
          return BillingClientState.connecting;
        case 2:
          return BillingClientState.connected;
        case 3:
          return BillingClientState.closed;
        default:
          return BillingClientState.disconnected;
      }
    } catch (error) {
      debugPrint('Error getting connection state: $error');
      return BillingClientState.disconnected;
    }
  }
}

/// In-app message model for Android
class InAppMessage {
  final String messageId;
  final String campaignName;
  final InAppMessageType messageType;

  InAppMessage({
    required this.messageId,
    required this.campaignName,
    required this.messageType,
  });

  factory InAppMessage.fromMap(Map<String, dynamic> map) {
    return InAppMessage(
      messageId: map['messageId'] as String,
      campaignName: map['campaignName'] as String,
      messageType: InAppMessageType.values[map['messageType'] as int],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'campaignName': campaignName,
      'messageType': messageType.index,
    };
  }
}
