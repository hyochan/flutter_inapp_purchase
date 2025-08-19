import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Proration Mode Validation Tests', () {
    test(
        'requestSubscription throws error when using deferred proration without purchaseToken',
        () {
      // Test that using deferred proration mode without purchaseToken throws an error
      expect(
        () => RequestSubscriptionAndroid(
          skus: ['test_subscription'],
          replacementModeAndroid: 4, // DEFERRED mode
          subscriptionOffers: [],
          // Missing purchaseTokenAndroid - should trigger assert in debug mode
        ),
        throwsAssertionError,
      );
    });

    test('requestSubscription allows deferred proration with purchaseToken',
        () {
      // Test that using deferred proration mode with purchaseToken works
      final request = RequestSubscriptionAndroid(
        skus: ['test_subscription'],
        replacementModeAndroid: 4, // DEFERRED mode
        purchaseTokenAndroid: 'valid_purchase_token',
        subscriptionOffers: [],
      );

      expect(request.skus, ['test_subscription']);
      expect(request.replacementModeAndroid, 4);
      expect(request.purchaseTokenAndroid, 'valid_purchase_token');
    });

    test('requestSubscription works without proration mode', () {
      // Test that normal subscription request without proration works
      final request = RequestSubscriptionAndroid(
        skus: ['test_subscription'],
        subscriptionOffers: [],
      );

      expect(request.skus, ['test_subscription']);
      expect(request.replacementModeAndroid, null);
      expect(request.purchaseTokenAndroid, null);
    });

    test('requestSubscription works with proration mode -1 (default)', () {
      // Test that using default value (-1) doesn't require purchaseToken
      final request = RequestSubscriptionAndroid(
        skus: ['test_subscription'],
        replacementModeAndroid: -1,
        subscriptionOffers: [],
      );

      expect(request.skus, ['test_subscription']);
      expect(request.replacementModeAndroid, -1);
    });

    test(
        'requestSubscription throws for all proration modes without purchaseToken',
        () {
      // Test all Android proration modes that require purchaseToken
      final prorationModes = [
        1, // IMMEDIATE_WITH_TIME_PRORATION
        2, // IMMEDIATE_WITHOUT_PRORATION
        3, // IMMEDIATE_AND_CHARGE_PRORATED_PRICE
        4, // DEFERRED
        5, // IMMEDIATE_AND_CHARGE_FULL_PRICE
      ];

      for (final mode in prorationModes) {
        expect(
          () => RequestSubscriptionAndroid(
            skus: ['test_subscription'],
            replacementModeAndroid: mode,
            subscriptionOffers: [],
            // Missing purchaseTokenAndroid
          ),
          throwsAssertionError,
          reason: 'Proration mode $mode should require purchaseToken',
        );
      }
    });

    test('requestSubscription works for all proration modes with purchaseToken',
        () {
      // Test all Android proration modes work with purchaseToken
      final prorationModes = [
        1, // IMMEDIATE_WITH_TIME_PRORATION
        2, // IMMEDIATE_WITHOUT_PRORATION
        3, // IMMEDIATE_AND_CHARGE_PRORATED_PRICE
        4, // DEFERRED
        5, // IMMEDIATE_AND_CHARGE_FULL_PRICE
      ];

      for (final mode in prorationModes) {
        final request = RequestSubscriptionAndroid(
          skus: ['test_subscription'],
          replacementModeAndroid: mode,
          purchaseTokenAndroid: 'valid_token',
          subscriptionOffers: [],
        );

        expect(request.replacementModeAndroid, mode);
        expect(request.purchaseTokenAndroid, 'valid_token');
      }
    });
  });
}
