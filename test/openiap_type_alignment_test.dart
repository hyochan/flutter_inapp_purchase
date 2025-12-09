// ignore_for_file: prefer_const_constructors

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_inapp_purchase/types.dart';

void main() {
  group('Generated type smoke tests', () {
    test('ProductAndroid exposes core pricing fields', () {
      const product = ProductAndroid(
        currency: 'USD',
        description: 'Monthly access',
        displayPrice: '\$9.99',
        id: 'monthly_access',
        nameAndroid: 'Monthly Access',
        platform: IapPlatform.Android,
        price: 9.99,
        title: 'Monthly Access',
        type: ProductType.InApp,
      );

      expect(product.id, 'monthly_access');
      expect(product.platform, IapPlatform.Android);
      expect(product.price, 9.99);
    });

    test('ProductIOS exposes StoreKit metadata', () {
      const product = ProductIOS(
        currency: 'USD',
        description: 'Premium upgrade',
        displayNameIOS: 'Premium',
        displayPrice: '\$4.99',
        id: 'premium_upgrade',
        isFamilyShareableIOS: true,
        jsonRepresentationIOS: '{}',
        platform: IapPlatform.IOS,
        title: 'Premium Upgrade',
        type: ProductType.Subs,
        typeIOS: ProductTypeIOS.AutoRenewableSubscription,
      );

      expect(product.type, ProductType.Subs);
      expect(product.typeIOS, ProductTypeIOS.AutoRenewableSubscription);
      expect(product.platform, IapPlatform.IOS);
    });

    test('PurchaseAndroid stores purchase token and platform data', () {
      const purchase = PurchaseAndroid(
        id: 'txn_android',
        isAutoRenewing: true,
        platform: IapPlatform.Android,
        productId: 'monthly_access',
        purchaseState: PurchaseState.Purchased,
        purchaseToken: 'token_123',
        quantity: 1,
        store: IapStore.Google,
        transactionDate: 1700000000,
      );

      expect(purchase.id, 'txn_android');
      expect(purchase.purchaseToken, 'token_123');
      expect(purchase.platform, IapPlatform.Android);
    });

    test('PurchaseIOS stores StoreKit specific fields', () {
      final purchase = PurchaseIOS(
        id: 'txn_ios',
        isAutoRenewing: false,
        platform: IapPlatform.IOS,
        productId: 'premium_upgrade',
        purchaseState: PurchaseState.Purchased,
        quantity: 1,
        store: IapStore.Apple,
        transactionDate: 1700000100,
        transactionId: 'txn_ios',
        environmentIOS: 'Sandbox',
        quantityIOS: 1,
      );

      expect(purchase.environmentIOS, 'Sandbox');
      expect(purchase.quantityIOS, 1);
      expect(purchase.platform, IapPlatform.IOS);
    });

    test('PricingPhasesAndroid round-trips through JSON', () {
      const phases = PricingPhasesAndroid(
        pricingPhaseList: [
          PricingPhaseAndroid(
            billingCycleCount: 3,
            billingPeriod: 'P1M',
            formattedPrice: '\$0.99',
            priceAmountMicros: '990000',
            priceCurrencyCode: 'USD',
            recurrenceMode: 1,
          ),
        ],
      );

      final json = phases.toJson();
      final restored = PricingPhasesAndroid.fromJson({
        'pricingPhaseList': json['pricingPhaseList'] as List<dynamic>,
      });

      expect(restored.pricingPhaseList.length, 1);
      expect(restored.pricingPhaseList.first.priceCurrencyCode, 'USD');
    });
  });
}
