import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Product Type Tests', () {
    test('Product should be created with basic fields', () {
      final product = Product(
        id: 'test_product',
        title: 'Test Product',
        description: 'Test Description',
        price: 9.99,
        localizedPrice: '\$9.99',
        currency: 'USD',
        platformEnum: IapPlatform.ios,
      );

      expect(product.id, 'test_product');
      expect(product.title, 'Test Product');
      expect(product.description, 'Test Description');
      expect(product.price, 9.99);
      expect(product.localizedPrice, '\$9.99');
      expect(product.currency, 'USD');
    });

    test('Product should handle iOS-specific fields', () {
      final product = Product(
        id: 'test_product',
        title: 'Test Product',
        description: 'Test Description',
        price: 9.99,
        localizedPrice: '\$9.99',
        currency: 'USD',
        platformEnum: IapPlatform.ios,
        discountsIOS: [],
        subscription: null,
      );

      expect(product.discountsIOS, isNotNull);
      expect(product.discountsIOS, isEmpty);
    });

    test('Subscription should extend ProductCommon', () {
      final subscription = ProductSubscription(
        id: 'test_subscription',
        title: 'Test Subscription',
        description: 'Test Subscription Description',
        price: '4.99',
        localizedPrice: '\$4.99',
        currency: 'USD',
        platform: IapPlatform.ios,
        subscriptionPeriodAndroid: 'P1M',
        subscriptionGroupIdIOS: 'test_group',
      );

      expect(subscription, isA<ProductCommon>());
      expect(subscription.id, 'test_subscription');
      expect(subscription.subscriptionPeriodAndroid, 'P1M');
      expect(subscription.subscriptionGroupIdIOS, 'test_group');
    });
  });

  group('Purchase Type Tests', () {
    test('Purchase should be created with required fields', () {
      final purchase = Purchase(
        productId: 'test_product',
        transactionId: 'transaction_123',
        transactionDate: 1234567890,
        transactionReceipt: 'receipt_data',
        purchaseToken: 'token_123',
        platform: IapPlatform.android,
      );

      expect(purchase.productId, 'test_product');
      expect(purchase.transactionId, 'transaction_123');
      expect(purchase.id, 'transaction_123'); // id should return transactionId
      expect(purchase.transactionDate, 1234567890);
      expect(purchase.transactionReceipt, 'receipt_data');
      expect(purchase.purchaseToken, 'token_123');
      expect(purchase.platform, IapPlatform.android);
    });

    test('Purchase should handle Android-specific fields', () {
      final purchase = Purchase(
        productId: 'test_product',
        transactionId: 'transaction_123',
        transactionDate: 1234567890,
        transactionReceipt: 'receipt_data',
        purchaseToken: 'token_123',
        platform: IapPlatform.android,
        isAcknowledgedAndroid: true,
        purchaseStateAndroid: 1,
        originalJson: '{"test": "data"}',
        signatureAndroid: 'signature_123',
        packageNameAndroid: 'com.example.app',
        autoRenewingAndroid: false,
      );

      expect(purchase.isAcknowledgedAndroid, true);
      expect(purchase.purchaseStateAndroid, 1);
      expect(purchase.originalJson, '{"test": "data"}');
      expect(purchase.signatureAndroid, 'signature_123');
      expect(purchase.packageNameAndroid, 'com.example.app');
      expect(purchase.autoRenewingAndroid, false);
    });

    test('Purchase should handle iOS-specific fields', () {
      final purchase = Purchase(
        productId: 'test_product',
        transactionId: 'transaction_123',
        transactionDate: 1234567890,
        transactionReceipt: 'receipt_data',
        purchaseToken: 'token_123',
        platform: IapPlatform.ios,
        transactionStateIOS: TransactionState.purchased,
        originalTransactionIdentifierIOS: 'original_123',
        originalTransactionDateIOS: '1234567890',
        quantityIOS: 2,
      );

      expect(purchase.transactionStateIOS, TransactionState.purchased);
      expect(purchase.originalTransactionIdentifierIOS, 'original_123');
      expect(purchase.originalTransactionDateIOS, '1234567890');
      expect(purchase.quantityIOS, 2);
    });

    test('Purchase should be created correctly', () {
      final purchase = Purchase(
        productId: 'test_product',
        transactionId: 'transaction_123',
        transactionDate: 1234567890,
        transactionReceipt: 'receipt_data',
        purchaseToken: 'token_123',
        platform: IapPlatform.android,
      );

      expect(purchase.productId, 'test_product');
      expect(purchase.transactionId, 'transaction_123');
      expect(purchase.transactionDate, 1234567890);
      expect(purchase.transactionReceipt, 'receipt_data');
      expect(purchase.purchaseToken, 'token_123');
      expect(purchase.platform, IapPlatform.android);
    });

    test('Purchase fields should be accessible', () {
      final purchase = Purchase(
        productId: 'test_product',
        transactionId: 'transaction_123',
        transactionDate: 1234567890,
        transactionReceipt: 'receipt_data',
        purchaseToken: 'token_123',
        platform: IapPlatform.ios,
        isAcknowledged: true,
        purchaseState: PurchaseState.purchased,
      );

      expect(purchase.productId, 'test_product');
      expect(purchase.transactionId, 'transaction_123');
      expect(purchase.transactionDate, 1234567890);
      expect(purchase.transactionReceipt, 'receipt_data');
      expect(purchase.purchaseToken, 'token_123');
      expect(purchase.platform, IapPlatform.ios);
      expect(purchase.isAcknowledged, true);
      expect(purchase.purchaseState, PurchaseState.purchased);
    });
  });

  group('PurchaseState Tests', () {
    test('PurchaseState enum values should be correct', () {
      expect(PurchaseState.pending.name, 'pending');
      expect(PurchaseState.purchased.name, 'purchased');
      expect(PurchaseState.unspecified.name, 'unspecified');
    });
  });

  group('TransactionState Tests', () {
    test('TransactionState enum values should be correct', () {
      expect(TransactionState.purchasing.index, 0);
      expect(TransactionState.purchased.index, 1);
      expect(TransactionState.failed.index, 2);
      expect(TransactionState.restored.index, 3);
      expect(TransactionState.deferred.index, 4);
    });
  });

  group('AndroidPurchaseState Tests', () {
    test('AndroidPurchaseState values should be correct', () {
      expect(AndroidPurchaseState.unspecified.value, 0);
      expect(AndroidPurchaseState.purchased.value, 1);
      expect(AndroidPurchaseState.pending.value, 2);
    });

    test('AndroidPurchaseState fromValue should work correctly', () {
      expect(
        AndroidPurchaseState.fromValue(0),
        AndroidPurchaseState.unspecified,
      );
      expect(AndroidPurchaseState.fromValue(1), AndroidPurchaseState.purchased);
      expect(AndroidPurchaseState.fromValue(2), AndroidPurchaseState.pending);
      expect(
        AndroidPurchaseState.fromValue(99),
        AndroidPurchaseState.unspecified,
      );
    });
  });

  group('ValidationResult Tests', () {
    test('ValidationResult should be created correctly', () {
      final result = ValidationResult(
        isValid: true,
        errorMessage: null,
        receipt: {'status': 0},
        parsedReceipt: {'product_id': 'test'},
      );

      expect(result.isValid, true);
      expect(result.errorMessage, isNull);
      expect(result.receipt, isNotNull);
      expect(result.parsedReceipt, isNotNull);
    });

    test('ValidationResult fromJson should deserialize correctly', () {
      final json = {
        'isValid': false,
        'errorMessage': 'Invalid receipt',
        'receipt': {'status': 21007},
      };

      final result = ValidationResult.fromJson(json);

      expect(result.isValid, false);
      expect(result.errorMessage, 'Invalid receipt');
      expect(result.receipt?['status'], 21007);
    });
  });
}
