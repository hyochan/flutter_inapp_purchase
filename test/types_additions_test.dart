import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('types additions', () {
    test('AppTransaction json roundtrip', () {
      final tx = AppTransaction(
        appAppleId: '123',
        bundleId: 'com.example',
        originalAppVersion: '1.0',
        originalPurchaseDate: '2024-01-01',
        deviceVerification: 'ver',
        deviceVerificationNonce: 'nonce',
      );
      final map = tx.toJson();
      final back = AppTransaction.fromJson(map);
      expect(back.bundleId, 'com.example');
      expect(back.originalAppVersion, '1.0');
    });

    test('ActiveSubscription.fromPurchase sets iOS fields', () {
      final now = DateTime.now();
      final p = Purchase(
        productId: 'sub',
        transactionId: 't1',
        platform: IapPlatform.ios,
        expirationDateIOS: now.add(const Duration(days: 3)),
        environmentIOS: 'Sandbox',
      );

      final active = ActiveSubscription.fromPurchase(p);
      expect(active.productId, 'sub');
      expect(active.isActive, true);
      expect(active.environmentIOS, 'Sandbox');
      expect(active.willExpireSoon, true);
      expect(active.daysUntilExpirationIOS, isNonNegative);
      final json = active.toJson();
      expect(json['productId'], 'sub');
    });

    test('PurchaseIOS holds expirationDateIOS', () {
      final exp = DateTime.now().add(const Duration(days: 10));
      final p = PurchaseIOS(
        productId: 'p',
        transactionId: 't',
        expirationDateIOS: exp,
      );
      expect(p.expirationDateIOS, exp);
      expect(p.platform, IapPlatform.ios);
    });
  });
}
