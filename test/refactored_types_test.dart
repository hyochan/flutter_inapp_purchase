// ignore_for_file: prefer_const_constructors

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_inapp_purchase/types.dart';

void main() {
  group('ActiveSubscription serialization', () {
    test('round-trips iOS metadata', () {
      const subscription = ActiveSubscription(
        isActive: true,
        productId: 'premium_sub',
        transactionDate: 1700000200,
        transactionId: 'txn_123',
        environmentIOS: 'Sandbox',
        expirationDateIOS: 1700001200,
        willExpireSoon: true,
      );

      final json = subscription.toJson();
      final restored = ActiveSubscription.fromJson(json);

      expect(restored.environmentIOS, 'Sandbox');
      expect(restored.productId, 'premium_sub');
      expect(restored.willExpireSoon, isTrue);
    });
  });

  group('Purchase serialization', () {
    test('PurchaseAndroid toJson/fromJson preserves token', () {
      const purchase = PurchaseAndroid(
        id: 'txn_android',
        isAutoRenewing: true,
        platform: IapPlatform.Android,
        productId: 'monthly_access',
        purchaseState: PurchaseState.Purchased,
        purchaseToken: 'android_token',
        quantity: 1,
        store: IapStore.Google,
        transactionDate: 1700000000,
      );

      final json = purchase.toJson();
      final restored = PurchaseAndroid.fromJson(json);

      expect(restored.purchaseToken, 'android_token');
      expect(restored.platform, IapPlatform.Android);
      expect(restored.purchaseState, PurchaseState.Purchased);
    });

    test('PurchaseIOS toJson/fromJson preserves StoreKit data', () {
      final purchase = PurchaseIOS(
        id: 'txn_ios',
        isAutoRenewing: false,
        platform: IapPlatform.IOS,
        productId: 'premium_upgrade',
        purchaseState: PurchaseState.Purchased,
        quantity: 1,
        store: IapStore.Apple,
        transactionDate: 1700000300,
        transactionId: 'txn_ios',
        environmentIOS: 'Production',
        subscriptionGroupIdIOS: 'group_a',
      );

      final json = purchase.toJson();
      final restored = PurchaseIOS.fromJson(json);

      expect(restored.environmentIOS, 'Production');
      expect(restored.subscriptionGroupIdIOS, 'group_a');
      expect(restored.platform, IapPlatform.IOS);
    });
  });

  group('PurchaseError conversions', () {
    test('toJson/fromJson retains code and message', () {
      final error = PurchaseError(
        code: ErrorCode.NetworkError,
        message: 'Network unavailable',
        productId: 'product_a',
      );

      final json = error.toJson();
      final restored = PurchaseError.fromJson(json);

      expect(restored.code, ErrorCode.NetworkError);
      expect(restored.message, 'Network unavailable');
      expect(restored.productId, 'product_a');
    });
  });
}
