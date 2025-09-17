import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import '../types.dart' as types;
import '../enums.dart' as legacy;

/// Android-specific IAP functionality as a mixin
mixin FlutterInappPurchaseAndroid {
  MethodChannel get channel;
  bool get isAndroid;

  /// Consumes a purchase on Android (for consumable products)
  /// @param purchaseToken - The purchase token to consume
  Future<types.VoidResult> consumePurchaseAndroid(
      {required String purchaseToken}) async {
    if (!isAndroid) {
      throw PlatformException(
        code: 'platform',
        message: 'consumePurchaseAndroid is only supported on Android',
      );
    }

    try {
      final response = await channel.invokeMethod<Map<dynamic, dynamic>>(
        'consumePurchaseAndroid',
        {'purchaseToken': purchaseToken},
      );
      if (response == null) {
        return const types.VoidResult(success: false);
      }
      return types.VoidResult.fromJson(Map<String, dynamic>.from(response));
    } catch (error) {
      debugPrint('Error consuming purchase: $error');
      return const types.VoidResult(success: false);
    }
  }
}

/// In-app message model for Android
class InAppMessage {
  final String messageId;
  final String campaignName;
  final legacy.InAppMessageType messageType;

  InAppMessage({
    required this.messageId,
    required this.campaignName,
    required this.messageType,
  });

  factory InAppMessage.fromMap(Map<String, dynamic> map) {
    return InAppMessage(
      messageId: map['messageId']?.toString() ?? '',
      campaignName: map['campaignName']?.toString() ?? '',
      messageType: legacy
          .InAppMessageType.values[(map['messageType'] as num?)?.toInt() ?? 0],
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
