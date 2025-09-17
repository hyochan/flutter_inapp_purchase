// ignore_for_file: prefer_const_constructors

import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('types additions', () {
    test('AppTransaction json roundtrip', () {
      final tx = AppTransaction(
        appId: 123,
        appVersion: '1.0.0',
        appVersionId: 456,
        bundleId: 'com.example',
        deviceVerification: 'signature',
        deviceVerificationNonce: 'nonce',
        environment: 'Sandbox',
        originalAppVersion: '1.0.0',
        originalPurchaseDate: 1700000000,
        signedDate: 1700000020,
      );
      final map = tx.toJson();
      final back = AppTransaction.fromJson(map);
      expect(back.bundleId, 'com.example');
      expect(back.environment, 'Sandbox');
      expect(back.appVersion, '1.0.0');
    });

    test('ActiveSubscription toJson includes optional fields', () {
      final sub = ActiveSubscription(
        isActive: true,
        productId: 'sub',
        purchaseToken: 'token',
        transactionDate: 1700000100,
        transactionId: 't1',
        environmentIOS: 'Sandbox',
        expirationDateIOS: 1700001000,
        willExpireSoon: true,
      );

      final json = sub.toJson();
      expect(json['productId'], 'sub');
      expect(json['environmentIOS'], 'Sandbox');
      expect(json['willExpireSoon'], true);
    });

    test('PurchaseIOS holds expirationDateIOS seconds', () {
      final p = PurchaseIOS(
        id: 't',
        productId: 'p',
        isAutoRenewing: false,
        platform: IapPlatform.IOS,
        purchaseState: PurchaseState.Purchased,
        quantity: 1,
        transactionDate: 1700000000,
        expirationDateIOS: 1700005000,
      );
      expect(p.expirationDateIOS, 1700005000);
      expect(p.platform, IapPlatform.IOS);
    });
  });
}
