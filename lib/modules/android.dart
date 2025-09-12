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

  /// Consumes a purchase on Android (for consumable products)
  /// @param purchaseToken - The purchase token to consume
  Future<bool> consumePurchaseAndroid({required String purchaseToken}) async {
    if (!isAndroid) {
      return false;
    }

    try {
      final result = await channel.invokeMethod<bool>('consumePurchaseAndroid', {
        'purchaseToken': purchaseToken,
      });
      return result ?? false;
    } catch (error) {
      debugPrint('Error consuming purchase: $error');
      return false;
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
