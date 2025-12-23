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
        store: IapStore.Apple,
        transactionDate: 1700000000,
        transactionId: 't',
        expirationDateIOS: 1700005000,
      );
      expect(p.expirationDateIOS, 1700005000);
      expect(p.platform, IapPlatform.IOS);
    });

    test('RequestPurchasePropsByPlatforms supports google field', () {
      // Test parsing with 'google' field (new recommended way)
      final propsWithGoogle = RequestPurchasePropsByPlatforms.fromJson({
        'google': {
          'skus': ['com.example.product'],
        },
      });
      expect(propsWithGoogle.google, isNotNull);
      expect(propsWithGoogle.google!.skus, ['com.example.product']);
      expect(propsWithGoogle.android, isNull);

      // Test parsing with 'android' field (deprecated)
      final propsWithAndroid = RequestPurchasePropsByPlatforms.fromJson({
        'android': {
          'skus': ['com.example.legacy'],
        },
      });
      expect(propsWithAndroid.android, isNotNull);
      expect(propsWithAndroid.android!.skus, ['com.example.legacy']);
      expect(propsWithAndroid.google, isNull);

      // Test toJson includes both fields
      final propsBoth = RequestPurchasePropsByPlatforms(
        google: RequestPurchaseAndroidProps(skus: ['sku1']),
        android: RequestPurchaseAndroidProps(skus: ['sku2']),
      );
      final json = propsBoth.toJson();
      expect(json['google'], isNotNull);
      expect(json['android'], isNotNull);
    });

    test('RequestPurchaseIosProps supports advancedCommerceData', () {
      final props = RequestPurchaseIosProps(
        sku: 'com.example.product',
        advancedCommerceData: 'campaign_token_123',
      );

      expect(props.advancedCommerceData, 'campaign_token_123');

      final json = props.toJson();
      expect(json['advancedCommerceData'], 'campaign_token_123');

      // Test fromJson
      final parsed = RequestPurchaseIosProps.fromJson({
        'sku': 'com.example.product',
        'advancedCommerceData': 'parsed_token',
      });
      expect(parsed.advancedCommerceData, 'parsed_token');
    });

    test('RequestSubscriptionIosProps supports advancedCommerceData', () {
      final props = RequestSubscriptionIosProps(
        sku: 'com.example.subscription',
        advancedCommerceData: 'sub_campaign_token',
      );

      expect(props.advancedCommerceData, 'sub_campaign_token');

      final json = props.toJson();
      expect(json['advancedCommerceData'], 'sub_campaign_token');
    });
  });
}
