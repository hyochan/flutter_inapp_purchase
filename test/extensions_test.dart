import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_inapp_purchase/types.dart';

void main() {
  group('Product and Purchase Type Tests', () {
    group('Product Tests', () {
      test('Product should be created correctly for Android', () {
        final product = Product(
          productId: 'android_product',
          title: 'Test Product',
          description: 'Test Description',
          price: 9.99,
          localizedPrice: '\$9.99',
          currency: 'USD',
          nameAndroid: 'Android Product',
        );

        expect(product.productId, 'android_product');
        expect(product.title, 'Test Product');
        expect(product.description, 'Test Description');
        expect(product.price, 9.99);
        expect(product.localizedPrice, '\$9.99');
        expect(product.currency, 'USD');
        expect(product.nameAndroid, 'Android Product');
      });

      test('Product should be created correctly for iOS', () {
        final product = Product(
          productId: 'ios_product',
          title: 'iOS Product',
          description: 'iOS Description',
          price: 4.99,
          localizedPrice: '\$4.99',
          currency: 'USD',
        );

        expect(product.productId, 'ios_product');
        expect(product.title, 'iOS Product');
        expect(product.price, 4.99);
      });
    });

    group('Subscription Tests', () {
      test('Subscription should be created correctly for Android', () {
        final subscription = Subscription(
          productId: 'android_sub',
          title: 'Premium Subscription',
          description: 'Premium features',
          price: '9.99',
          localizedPrice: '\$9.99',
          currency: 'USD',
          subscriptionPeriodAndroid: 'P1M',
          platform: IapPlatform.android,
        );

        expect(subscription.productId, 'android_sub');
        expect(subscription.subscriptionPeriodAndroid, 'P1M');
        expect(subscription.platform, IapPlatform.android);
      });

      test('Subscription should be created correctly for iOS', () {
        final subscription = Subscription(
          productId: 'ios_sub',
          title: 'Premium',
          description: 'Premium subscription',
          price: '9.99',
          localizedPrice: '\$9.99',
          currency: 'USD',
          subscriptionGroupIdIOS: 'group_123',
          platform: IapPlatform.ios,
        );

        expect(subscription.productId, 'ios_sub');
        expect(subscription.subscriptionGroupIdIOS, 'group_123');
        expect(subscription.platform, IapPlatform.ios);
      });
    });

    group('Purchase Tests', () {
      test('Purchase should be created correctly for Android', () {
        final purchase = Purchase(
          productId: 'android_product',
          transactionId: 'trans_123',
          transactionDate: 1234567890,
          purchaseToken: 'token_123',
          platform: IapPlatform.android,
          isAcknowledgedAndroid: true,
          purchaseStateAndroid: 1,
        );

        expect(purchase.productId, 'android_product');
        expect(purchase.transactionId, 'trans_123');
        expect(purchase.id, 'trans_123');
        expect(purchase.platform, IapPlatform.android);
        expect(purchase.isAcknowledgedAndroid, true);
        expect(purchase.purchaseStateAndroid, 1);
      });

      test('Purchase should be created correctly for iOS', () {
        final purchase = Purchase(
          productId: 'ios_product',
          transactionId: 'trans_456',
          transactionDate: 1234567890,
          purchaseToken: 'token_456',
          platform: IapPlatform.ios,
          transactionStateIOS: TransactionState.purchased,
          originalTransactionIdentifierIOS: 'original_123',
        );

        expect(purchase.productId, 'ios_product');
        expect(purchase.transactionId, 'trans_456');
        expect(purchase.platform, IapPlatform.ios);
        expect(purchase.transactionStateIOS, TransactionState.purchased);
        expect(purchase.originalTransactionIdentifierIOS, 'original_123');
      });

      test('Purchase id getter should return transactionId', () {
        final purchase = Purchase(
          productId: 'test_product',
          transactionId: 'test_trans_id',
          platform: IapPlatform.android,
        );

        expect(purchase.id, 'test_trans_id');
      });

      test(
          'Purchase id getter should return empty string when transactionId is null',
          () {
        final purchase = Purchase(
          productId: 'test_product',
          platform: IapPlatform.android,
        );

        expect(purchase.id, '');
      });
    });

    group('SubscriptionPurchase Tests', () {
      test('SubscriptionPurchase should be created correctly', () {
        final subPurchase = SubscriptionPurchase(
          productId: 'sub_123',
          transactionId: 'trans_123',
          transactionDate: DateTime(2024, 1, 1).millisecondsSinceEpoch,
          isActive: true,
          expirationDate: DateTime(2024, 2, 1),
          platform: IapPlatform.android,
        );

        expect(subPurchase.productId, 'sub_123');
        expect(subPurchase.transactionId, 'trans_123');
        expect(subPurchase.isActive, true);
        expect(subPurchase.expirationDate, DateTime(2024, 2, 1));
        expect(subPurchase.platform, IapPlatform.android);
      });

      test('SubscriptionPurchase toJson should serialize correctly', () {
        final subPurchase = SubscriptionPurchase(
          productId: 'sub_123',
          isActive: true,
          expirationDate: DateTime(2024, 2, 1),
          platform: IapPlatform.ios,
        );

        final json = subPurchase.toJson();

        expect(json['productId'], 'sub_123');
        expect(json['isActive'], true);
        expect(json['expirationDate'], contains('2024-02-01'));
        expect(json['platform'], 'ios');
      });
    });

    group('AppTransaction Tests', () {
      test('AppTransaction should be created correctly', () {
        final appTrans = AppTransaction(
          appAppleId: '123456',
          bundleId: 'com.example.app',
          originalAppVersion: '1.0',
          originalPurchaseDate: '2024-01-01',
        );

        expect(appTrans.appAppleId, '123456');
        expect(appTrans.bundleId, 'com.example.app');
        expect(appTrans.originalAppVersion, '1.0');
        expect(appTrans.originalPurchaseDate, '2024-01-01');
      });

      test('AppTransaction fromJson should deserialize correctly', () {
        final json = {
          'appAppleId': '123456',
          'bundleId': 'com.example.app',
          'originalAppVersion': '1.0',
        };

        final appTrans = AppTransaction.fromJson(json);

        expect(appTrans.appAppleId, '123456');
        expect(appTrans.bundleId, 'com.example.app');
        expect(appTrans.originalAppVersion, '1.0');
      });
    });

    group('PurchaseIOS Tests', () {
      test('PurchaseIOS should be created correctly', () {
        final expirationDate = DateTime(2024, 2, 1);
        final purchaseIOS = PurchaseIOS(
          productId: 'ios_product',
          transactionId: 'trans_123',
          transactionDate: 1234567890,
          expirationDateIOS: expirationDate,
          transactionStateIOS: TransactionState.purchased,
        );

        expect(purchaseIOS.productId, 'ios_product');
        expect(purchaseIOS.transactionId, 'trans_123');
        expect(purchaseIOS.expirationDateIOS, expirationDate);
        expect(purchaseIOS.platform, IapPlatform.ios);
        expect(purchaseIOS.transactionStateIOS, TransactionState.purchased);
      });
    });
  });
}
