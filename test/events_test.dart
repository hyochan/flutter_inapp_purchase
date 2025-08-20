import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_inapp_purchase/events.dart';
import 'package:flutter_inapp_purchase/types.dart';

void main() {
  group('Events', () {
    test('IapEvent enum should contain expected values', () {
      expect(IapEvent.purchaseUpdated, isA<IapEvent>());
      expect(IapEvent.purchaseError, isA<IapEvent>());
      expect(IapEvent.promotedProductIos, isA<IapEvent>());
    });

    test('PurchaseUpdatedEvent should create correctly', () {
      final event = PurchaseUpdatedEvent(
        purchase: Purchase(
          productId: 'test_product',
          platform: IapPlatform.android,
          transactionId: 'test_transaction',
          purchaseToken: 'test_token',
        ),
      );

      expect(event.purchase.productId, 'test_product');
      expect(event.purchase.transactionId, 'test_transaction');
    });

    test('PurchaseErrorEvent should create correctly', () {
      final event = PurchaseErrorEvent(
        error: PurchaseError(
          code: ErrorCode.eUserCancelled,
          message: 'User cancelled the purchase',
          platform: IapPlatform.android,
        ),
      );

      expect(event.error.code, ErrorCode.eUserCancelled);
      expect(event.error.message, 'User cancelled the purchase');
      expect(event.error.platform, IapPlatform.android);
    });

    test('PromotedProductEvent should create correctly', () {
      final event = PromotedProductEvent(productId: 'promoted_product_123');

      expect(event.productId, 'promoted_product_123');
    });

    test('ConnectionStateEvent should create correctly', () {
      final connectedEvent = ConnectionStateEvent(
          isConnected: true, message: 'Connected successfully');
      expect(connectedEvent.isConnected, true);
      expect(connectedEvent.message, 'Connected successfully');

      final disconnectedEvent = ConnectionStateEvent(
          isConnected: false, message: 'Connection failed');
      expect(disconnectedEvent.isConnected, false);
      expect(disconnectedEvent.message, 'Connection failed');
    });

    test('EventSubscription should work correctly', () {
      bool removed = false;
      final subscription = EventSubscription(() {
        removed = true;
      });

      expect(removed, false);
      subscription.remove();
      expect(removed, true);
    });
  });
}
