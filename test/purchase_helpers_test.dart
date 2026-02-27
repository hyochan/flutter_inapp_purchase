import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PurchaseHelpers extension', () {
    group('transactionIdFor', () {
      test(
        'returns transactionId for PurchaseIOS when not empty',
        () {
          const purchase = PurchaseIOS(
            id: 'ios-id',
            isAutoRenewing: false,
            platform: IapPlatform.IOS,
            productId: 'com.example.product',
            purchaseState: PurchaseState.Purchased,
            quantity: 1,
            store: IapStore.Apple,
            transactionDate: 1000.0,
            transactionId: 'txn-123',
          );
          expect(purchase.transactionIdFor, 'txn-123');
        },
      );

      test(
        'returns id for PurchaseIOS when transactionId is empty',
        () {
          const purchase = PurchaseIOS(
            id: 'ios-id',
            isAutoRenewing: false,
            platform: IapPlatform.IOS,
            productId: 'com.example.product',
            purchaseState: PurchaseState.Purchased,
            quantity: 1,
            store: IapStore.Apple,
            transactionDate: 1000.0,
            transactionId: '',
          );
          expect(purchase.transactionIdFor, 'ios-id');
        },
      );

      test(
        'returns transactionId for PurchaseAndroid when not empty',
        () {
          const purchase = PurchaseAndroid(
            id: 'android-id',
            isAutoRenewing: false,
            platform: IapPlatform.Android,
            productId: 'com.example.product',
            purchaseState: PurchaseState.Purchased,
            quantity: 1,
            store: IapStore.Google,
            transactionDate: 1000.0,
            transactionId: 'txn-456',
          );
          expect(purchase.transactionIdFor, 'txn-456');
        },
      );

      test(
        'returns id for PurchaseAndroid when transactionId is null',
        () {
          const purchase = PurchaseAndroid(
            id: 'android-id',
            isAutoRenewing: false,
            platform: IapPlatform.Android,
            productId: 'com.example.product',
            purchaseState: PurchaseState.Purchased,
            quantity: 1,
            store: IapStore.Google,
            transactionDate: 1000.0,
          );
          expect(purchase.transactionIdFor, 'android-id');
        },
      );

      test(
        'returns id for PurchaseAndroid when transactionId is empty',
        () {
          const purchase = PurchaseAndroid(
            id: 'android-id',
            isAutoRenewing: false,
            platform: IapPlatform.Android,
            productId: 'com.example.product',
            purchaseState: PurchaseState.Purchased,
            quantity: 1,
            store: IapStore.Google,
            transactionDate: 1000.0,
            transactionId: '',
          );
          expect(purchase.transactionIdFor, 'android-id');
        },
      );

      test(
        'returns null when id is also empty',
        () {
          const purchase = PurchaseIOS(
            id: '',
            isAutoRenewing: false,
            platform: IapPlatform.IOS,
            productId: 'com.example.product',
            purchaseState: PurchaseState.Purchased,
            quantity: 1,
            store: IapStore.Apple,
            transactionDate: 1000.0,
            transactionId: '',
          );
          expect(purchase.transactionIdFor, isNull);
        },
      );
    });

    group('androidPurchaseStateValue', () {
      test('returns null for PurchaseIOS', () {
        const purchase = PurchaseIOS(
          id: 'ios-id',
          isAutoRenewing: false,
          platform: IapPlatform.IOS,
          productId: 'com.example.product',
          purchaseState: PurchaseState.Purchased,
          quantity: 1,
          store: IapStore.Apple,
          transactionDate: 1000.0,
          transactionId: 'txn',
        );
        expect(purchase.androidPurchaseStateValue, isNull);
      });

      test('returns 1 for Purchased state', () {
        const purchase = PurchaseAndroid(
          id: 'id',
          isAutoRenewing: false,
          platform: IapPlatform.Android,
          productId: 'product',
          purchaseState: PurchaseState.Purchased,
          quantity: 1,
          store: IapStore.Google,
          transactionDate: 1000.0,
        );
        expect(
          purchase.androidPurchaseStateValue,
          AndroidPurchaseState.Purchased.value,
        );
      });

      test('returns 2 for Pending state', () {
        const purchase = PurchaseAndroid(
          id: 'id',
          isAutoRenewing: false,
          platform: IapPlatform.Android,
          productId: 'product',
          purchaseState: PurchaseState.Pending,
          quantity: 1,
          store: IapStore.Google,
          transactionDate: 1000.0,
        );
        expect(
          purchase.androidPurchaseStateValue,
          AndroidPurchaseState.Pending.value,
        );
      });

      test('returns 0 for Unknown state', () {
        const purchase = PurchaseAndroid(
          id: 'id',
          isAutoRenewing: false,
          platform: IapPlatform.Android,
          productId: 'product',
          purchaseState: PurchaseState.Unknown,
          quantity: 1,
          store: IapStore.Google,
          transactionDate: 1000.0,
        );
        expect(
          purchase.androidPurchaseStateValue,
          AndroidPurchaseState.Unknown.value,
        );
      });
    });

    group('iosTransactionState', () {
      test('returns null for PurchaseAndroid', () {
        const purchase = PurchaseAndroid(
          id: 'id',
          isAutoRenewing: false,
          platform: IapPlatform.Android,
          productId: 'product',
          purchaseState: PurchaseState.Purchased,
          quantity: 1,
          store: IapStore.Google,
          transactionDate: 1000.0,
        );
        expect(purchase.iosTransactionState, isNull);
      });

      test('returns purchased for Purchased state', () {
        const purchase = PurchaseIOS(
          id: 'id',
          isAutoRenewing: false,
          platform: IapPlatform.IOS,
          productId: 'product',
          purchaseState: PurchaseState.Purchased,
          quantity: 1,
          store: IapStore.Apple,
          transactionDate: 1000.0,
          transactionId: 'txn',
        );
        expect(
          purchase.iosTransactionState,
          TransactionState.purchased,
        );
      });

      test('returns purchasing for Pending state', () {
        const purchase = PurchaseIOS(
          id: 'id',
          isAutoRenewing: false,
          platform: IapPlatform.IOS,
          productId: 'product',
          purchaseState: PurchaseState.Pending,
          quantity: 1,
          store: IapStore.Apple,
          transactionDate: 1000.0,
          transactionId: 'txn',
        );
        expect(
          purchase.iosTransactionState,
          TransactionState.purchasing,
        );
      });

      test('returns purchasing for Unknown state', () {
        const purchase = PurchaseIOS(
          id: 'id',
          isAutoRenewing: false,
          platform: IapPlatform.IOS,
          productId: 'product',
          purchaseState: PurchaseState.Unknown,
          quantity: 1,
          store: IapStore.Apple,
          transactionDate: 1000.0,
          transactionId: 'txn',
        );
        expect(
          purchase.iosTransactionState,
          TransactionState.purchasing,
        );
      });
    });

    group('androidIsAcknowledged', () {
      test('returns null for PurchaseIOS', () {
        const purchase = PurchaseIOS(
          id: 'id',
          isAutoRenewing: false,
          platform: IapPlatform.IOS,
          productId: 'product',
          purchaseState: PurchaseState.Purchased,
          quantity: 1,
          store: IapStore.Apple,
          transactionDate: 1000.0,
          transactionId: 'txn',
        );
        expect(purchase.androidIsAcknowledged, isNull);
      });

      test('returns true when acknowledged', () {
        const purchase = PurchaseAndroid(
          id: 'id',
          isAutoRenewing: false,
          platform: IapPlatform.Android,
          productId: 'product',
          purchaseState: PurchaseState.Purchased,
          quantity: 1,
          store: IapStore.Google,
          transactionDate: 1000.0,
          isAcknowledgedAndroid: true,
        );
        expect(purchase.androidIsAcknowledged, true);
      });
    });

    group('iosQuantity', () {
      test('returns null for PurchaseAndroid', () {
        const purchase = PurchaseAndroid(
          id: 'id',
          isAutoRenewing: false,
          platform: IapPlatform.Android,
          productId: 'product',
          purchaseState: PurchaseState.Purchased,
          quantity: 1,
          store: IapStore.Google,
          transactionDate: 1000.0,
        );
        expect(purchase.iosQuantity, isNull);
      });

      test('returns quantity for PurchaseIOS', () {
        const purchase = PurchaseIOS(
          id: 'id',
          isAutoRenewing: false,
          platform: IapPlatform.IOS,
          productId: 'product',
          purchaseState: PurchaseState.Purchased,
          quantity: 1,
          quantityIOS: 3,
          store: IapStore.Apple,
          transactionDate: 1000.0,
          transactionId: 'txn',
        );
        expect(purchase.iosQuantity, 3);
      });
    });

    group('iosOriginalTransactionId', () {
      test('returns null for PurchaseAndroid', () {
        const purchase = PurchaseAndroid(
          id: 'id',
          isAutoRenewing: false,
          platform: IapPlatform.Android,
          productId: 'product',
          purchaseState: PurchaseState.Purchased,
          quantity: 1,
          store: IapStore.Google,
          transactionDate: 1000.0,
        );
        expect(purchase.iosOriginalTransactionId, isNull);
      });

      test('returns originalTransactionIdentifierIOS for PurchaseIOS', () {
        const purchase = PurchaseIOS(
          id: 'id',
          isAutoRenewing: false,
          platform: IapPlatform.IOS,
          productId: 'product',
          purchaseState: PurchaseState.Purchased,
          quantity: 1,
          store: IapStore.Apple,
          transactionDate: 1000.0,
          transactionId: 'txn',
          originalTransactionIdentifierIOS: 'orig-txn-123',
        );
        expect(
          purchase.iosOriginalTransactionId,
          'orig-txn-123',
        );
      });
    });
  });
}
