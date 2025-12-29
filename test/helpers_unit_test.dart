import 'dart:convert';

import 'package:flutter_inapp_purchase/enums.dart';
import 'package:flutter_inapp_purchase/helpers.dart';
import 'package:flutter_inapp_purchase/types.dart' as types;
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('helpers', () {
    test('resolveProductType handles multiple input types', () {
      expect(resolveProductType('subs'), 'subs');
      expect(resolveProductType(types.ProductQueryType.All), 'all');
      expect(resolveProductType(types.ProductType.InApp), 'inapp');
      expect(resolveProductType(TypeInApp.subs), 'subs');
      expect(resolveProductType(Object()), 'inapp');
    });

    test('parseProductFromNative creates iOS subscription product', () {
      final product = parseProductFromNative(
        <String, dynamic>{
          'platform': 'ios',
          'id': 'premium_monthly',
          'title': 'Premium Monthly',
          'description': 'Monthly plan',
          'currency': 'USD',
          'displayPrice': '\$9.99',
          'price': 9.99,
          'isFamilyShareableIOS': true,
          'jsonRepresentationIOS': '{}',
          'typeIOS': 'AUTO_RENEWABLE_SUBSCRIPTION',
        },
        'subs',
        fallbackIsIOS: true,
      );

      expect(product, isA<types.ProductSubscriptionIOS>());
      final subscription = product as types.ProductSubscriptionIOS;
      expect(subscription.id, 'premium_monthly');
      expect(subscription.platform, types.IapPlatform.IOS);
      expect(subscription.isFamilyShareableIOS, isTrue);
      expect(subscription.type, types.ProductType.Subs);
    });

    test(
        'parseProductFromNative creates Android in-app product with string offers',
        () {
      final product = parseProductFromNative(
        <String, dynamic>{
          'id': 'coins_pack',
          'title': 'Coins Pack',
          'description': 'One time coins',
          'currency': 'USD',
          'displayPrice': '\$2.99',
          'price': '2.99',
          'nameAndroid': 'Coins Pack',
          'subscriptionOfferDetailsAndroid':
              jsonEncode(<Map<String, dynamic>>[]),
          'oneTimePurchaseOfferDetailsAndroid': <String, dynamic>{
            'formattedPrice': '\$2.99',
            'priceAmountMicros': '2990000',
            'priceCurrencyCode': 'USD',
          },
        },
        'inapp',
        fallbackIsIOS: false,
      );

      expect(product, isA<types.ProductAndroid>());
      final androidProduct = product as types.ProductAndroid;
      expect(androidProduct.id, 'coins_pack');
      expect(androidProduct.platform, types.IapPlatform.Android);
      expect(androidProduct.price, closeTo(2.99, 0.0001));
      expect(androidProduct.oneTimePurchaseOfferDetailsAndroid, isNotNull);
    });

    test(
        'convertToPurchase handles Android payloads and tracks acknowledgements',
        () {
      final ackTokens = <String, bool>{};
      final purchase = convertToPurchase(
        <String, dynamic>{
          'platform': 'android',
          'store': 'google',
          'productId': 'coins_pack',
          'transactionId': 'txn-123',
          'purchaseStateAndroid': 1,
          'purchaseToken': 'token-android',
          'isAcknowledgedAndroid': true,
          'transactionDate': 1700000000000,
        },
        platformIsAndroid: true,
        platformIsIOS: false,
        acknowledgedAndroidPurchaseTokens: ackTokens,
      );

      expect(purchase, isA<types.PurchaseAndroid>());
      final androidPurchase = purchase as types.PurchaseAndroid;
      expect(androidPurchase.productId, 'coins_pack');
      expect(androidPurchase.purchaseToken, 'token-android');
      expect(ackTokens['token-android'], isTrue);
    });

    test('convertFromLegacyPurchase handles iOS payloads', () {
      final purchase = convertToPurchase(
        <String, dynamic>{
          'platform': 'ios',
          'store': 'apple',
          'productId': 'premium_monthly',
          'transactionId': 'txn-ios',
          'purchaseState': 'PURCHASED',
          'transactionReceipt': 'receipt-data',
          'transactionDate': 1700000000000,
          'quantity': '2',
        },
        platformIsAndroid: false,
        platformIsIOS: true,
        acknowledgedAndroidPurchaseTokens: <String, bool>{},
      );

      expect(purchase, isA<types.PurchaseIOS>());
      final iosPurchase = purchase as types.PurchaseIOS;
      expect(iosPurchase.transactionId, 'txn-ios');
      expect(iosPurchase.purchaseToken, 'receipt-data');
      expect(iosPurchase.quantity, 2);
    });

    test('extractPurchases parses string payload and skips malformed entries',
        () {
      final ackTokens = <String, bool>{};
      final payload = jsonEncode(<dynamic>[
        <String, dynamic>{
          'platform': 'android',
          'store': 'google',
          'productId': 'coins_pack',
          'transactionId': 'txn-1',
          'purchaseToken': 'token-1',
          'purchaseStateAndroid': 1,
        },
        <String, dynamic>{'platform': 'android', 'store': 'google'},
        'unexpected',
      ]);

      final purchases = extractPurchases(
        payload,
        platformIsAndroid: true,
        platformIsIOS: false,
        acknowledgedAndroidPurchaseTokens: ackTokens,
      );

      expect(purchases, hasLength(1));
      expect(purchases.first.productId, 'coins_pack');
      expect(ackTokens['token-1'], isNotNull);
    });

    test('extractPurchases handles maps with non-string keys', () {
      final ackTokens = <String, bool>{};
      // Simulate platform channel returning Map<Object?, Object?> with non-string keys
      final payload = <dynamic>[
        <Object?, Object?>{
          'platform': 'android',
          'store': 'google',
          'productId': 'coins_pack',
          'transactionId': 'txn-1',
          'purchaseToken': 'token-1',
          'purchaseStateAndroid': 1,
        },
      ];

      final purchases = extractPurchases(
        payload,
        platformIsAndroid: true,
        platformIsIOS: false,
        acknowledgedAndroidPurchaseTokens: ackTokens,
      );

      expect(purchases, hasLength(1));
      expect(purchases.first.productId, 'coins_pack');
      expect(ackTokens['token-1'], isNotNull);
    });

    test('convertToPurchaseError maps codes and response fallbacks', () {
      final stringResult = PurchaseResult(
        code: 'E_ALREADY_OWNED',
        message: 'Already owned',
      );

      final stringMapped = convertToPurchaseError(
        stringResult,
        platform: types.IapPlatform.Android,
      );
      expect(stringMapped.code, types.ErrorCode.AlreadyOwned);

      final responseResult = PurchaseResult(
        responseCode: 7,
        message: 'already owned',
      );

      final responseMapped = convertToPurchaseError(
        responseResult,
        platform: types.IapPlatform.Android,
      );
      expect(responseMapped.code, types.ErrorCode.AlreadyOwned);
    });

    test('normalizeDynamicMap coerces keys and nested structures', () {
      final normalized = normalizeDynamicMap(
        <dynamic, dynamic>{
          'key': <String, dynamic>{'inner': 1},
          42: [
            <String, dynamic>{'nested': true},
            'value',
          ],
        },
      );

      expect(normalized, isNotNull);
      expect(normalized!['key'], isA<Map<String, dynamic>>());
      expect(normalized['42'], isA<List<dynamic>>());
    });

    test(
        'parseProductFromNative builds Android subscription with offer details',
        () {
      final product = parseProductFromNative(
        <String, dynamic>{
          'platform': 'android',
          'id': 'premium_yearly',
          'title': 'Premium Yearly',
          'description': 'Yearly access',
          'currency': 'USD',
          'displayPrice': '\$49.99',
          'price': 49.99,
          'subscriptionOfferDetailsAndroid': <Map<String, dynamic>>[
            <String, dynamic>{
              'basePlanId': 'base',
              'offerToken': 'token',
              'offerTags': <String>['tag'],
              'pricingPhases': <String, dynamic>{
                'pricingPhaseList': <Map<String, dynamic>>[
                  <String, dynamic>{
                    'billingCycleCount': 1,
                    'billingPeriod': 'P1Y',
                    'formattedPrice': '\$49.99',
                    'priceAmountMicros': '49990000',
                    'priceCurrencyCode': 'USD',
                    'recurrenceMode': 2,
                  },
                ],
              },
            },
          ],
        },
        'subs',
        fallbackIsIOS: false,
      );

      expect(product, isA<types.ProductSubscriptionAndroid>());
      final subscription = product as types.ProductSubscriptionAndroid;
      expect(subscription.subscriptionOfferDetailsAndroid, isNotNull);
      expect(subscription.subscriptionOfferDetailsAndroid.single.offerToken,
          'token');
    });

    test(
        'parseProductFromNative builds Android in-app with one-time offer list',
        () {
      final product = parseProductFromNative(
        <String, dynamic>{
          'platform': 'android',
          'id': 'coins_pack',
          'title': 'Coins Pack',
          'description': 'Pack of coins',
          'currency': 'USD',
          'displayPrice': '\$1.99',
          'price': 1.99,
          'oneTimePurchaseOfferDetailsAndroid': <Map<String, dynamic>>[
            <String, dynamic>{
              'formattedPrice': '\$1.99',
              'priceAmountMicros': '1990000',
              'priceCurrencyCode': 'USD',
              'offerTags': <String>['launch'],
              'offerToken': 'offer-token',
              'offerId': 'offer-id',
              'fullPriceMicros': '2990000',
              'discountDisplayInfo': <String, dynamic>{
                'discountAmount': <String, dynamic>{
                  'discountAmountMicros': '100000',
                  'formattedDiscountAmount': '\$0.10',
                },
                'percentageDiscount': 20,
              },
              'limitedQuantityInfo': <String, dynamic>{
                'maximumQuantity': 10,
                'remainingQuantity': 4,
              },
              'validTimeWindow': <String, dynamic>{
                'startTimeMillis': '1000',
                'endTimeMillis': '2000',
              },
              'preorderDetailsAndroid': <String, dynamic>{
                'preorderPresaleEndTimeMillis': '3000',
                'preorderReleaseTimeMillis': '4000',
              },
              'rentalDetailsAndroid': <String, dynamic>{
                'rentalPeriod': 'P7D',
                'rentalExpirationPeriod': 'P1D',
              },
            },
          ],
        },
        'inapp',
        fallbackIsIOS: false,
      );

      expect(product, isA<types.ProductAndroid>());
      final android = product as types.ProductAndroid;
      final offers = android.oneTimePurchaseOfferDetailsAndroid;
      expect(offers, isNotNull);
      expect(offers, hasLength(1));
      final offer = offers!.first;
      expect(offer.offerToken, 'offer-token');
      expect(offer.offerTags, contains('launch'));
      expect(offer.discountDisplayInfo?.percentageDiscount, 20);
      expect(offer.fullPriceMicros, '2990000');
      expect(offer.limitedQuantityInfo?.maximumQuantity, 10);
      expect(offer.validTimeWindow?.endTimeMillis, '2000');
      expect(offer.preorderDetailsAndroid?.preorderReleaseTimeMillis, '4000');
      expect(offer.rentalDetailsAndroid?.rentalPeriod, 'P7D');
    });

    test(
        'parseProductFromNative coerces numeric validTimeWindow millis to string',
        () {
      final product = parseProductFromNative(
        <String, dynamic>{
          'platform': 'android',
          'id': 'coins_pack',
          'title': 'Coins Pack',
          'description': 'Pack of coins',
          'currency': 'USD',
          'displayPrice': '\$1.99',
          'price': 1.99,
          'oneTimePurchaseOfferDetailsAndroid': <Map<String, dynamic>>[
            <String, dynamic>{
              'formattedPrice': '\$1.99',
              'priceAmountMicros': 1990000,
              'priceCurrencyCode': 'USD',
              'validTimeWindow': <String, dynamic>{
                'startTimeMillis': 1000, // numeric
                'endTimeMillis': 2000, // numeric
              },
            },
          ],
        },
        'inapp',
        fallbackIsIOS: false,
      );

      expect(product, isA<types.ProductAndroid>());
      final android = product as types.ProductAndroid;
      final offers = android.oneTimePurchaseOfferDetailsAndroid;
      expect(offers, isNotNull);
      final validWindow = offers!.first.validTimeWindow;
      expect(validWindow, isNotNull);
      expect(validWindow!.startTimeMillis, '1000');
      expect(validWindow.endTimeMillis, '2000');
    });

    test('parseProductFromNative creates iOS in-app product', () {
      final product = parseProductFromNative(
        <String, dynamic>{
          'platform': 'ios',
          'id': 'coins_small',
          'title': 'Coins Small',
          'description': 'Small pack',
          'currency': 'USD',
          'displayPrice': '\$0.99',
          'price': 0.99,
          'typeIOS': 'CONSUMABLE',
          'isFamilyShareableIOS': false,
          'jsonRepresentationIOS': '{}',
        },
        'inapp',
        fallbackIsIOS: true,
      );

      expect(product, isA<types.ProductIOS>());
      final iosProduct = product as types.ProductIOS;
      expect(iosProduct.id, 'coins_small');
      expect(iosProduct.type, types.ProductType.InApp);
    });

    test('convertToPurchase handles iOS restored state as Purchased', () {
      final purchase = convertToPurchase(
        <String, dynamic>{
          'platform': 'ios',
          'store': 'apple',
          'productId': 'premium_yearly',
          'transactionId': 'txn-restored',
          'purchaseState': 'restored',
          'transactionReceipt': 'receipt-restored',
          'transactionDate': 1700000000000,
        },
        platformIsAndroid: false,
        platformIsIOS: true,
        acknowledgedAndroidPurchaseTokens: <String, bool>{},
      );

      expect(purchase, isA<types.PurchaseIOS>());
      final iosPurchase = purchase as types.PurchaseIOS;
      expect(iosPurchase.purchaseState, types.PurchaseState.Purchased);
    });

    test(
        'convertToPurchase handles iOS numeric state 3 as Purchased (restored)',
        () {
      final purchase = convertToPurchase(
        <String, dynamic>{
          'platform': 'ios',
          'store': 'apple',
          'productId': 'premium_yearly',
          'transactionId': 'txn-restored-num',
          'purchaseState': 3,
          'transactionReceipt': 'receipt-restored',
          'transactionDate': 1700000000000,
        },
        platformIsAndroid: false,
        platformIsIOS: true,
        acknowledgedAndroidPurchaseTokens: <String, bool>{},
      );

      expect(purchase, isA<types.PurchaseIOS>());
      final iosPurchase = purchase as types.PurchaseIOS;
      expect(iosPurchase.purchaseState, types.PurchaseState.Purchased);
    });

    test('convertToPurchase handles iOS unknown numeric states as Unknown', () {
      final purchase = convertToPurchase(
        <String, dynamic>{
          'platform': 'ios',
          'store': 'apple',
          'productId': 'premium_yearly',
          'transactionId': 'txn-unknown',
          'purchaseState': 99,
          'transactionReceipt': 'receipt-unknown',
          'transactionDate': 1700000000000,
        },
        platformIsAndroid: false,
        platformIsIOS: true,
        acknowledgedAndroidPurchaseTokens: <String, bool>{},
      );

      expect(purchase, isA<types.PurchaseIOS>());
      final iosPurchase = purchase as types.PurchaseIOS;
      expect(iosPurchase.purchaseState, types.PurchaseState.Unknown);
    });

    test(
        'convertToPurchase handles iOS failed/deferred string states as Unknown',
        () {
      // Test 'failed' state
      final failedPurchase = convertToPurchase(
        <String, dynamic>{
          'platform': 'ios',
          'store': 'apple',
          'productId': 'premium',
          'transactionId': 'txn-failed',
          'purchaseState': 'failed',
          'transactionReceipt': 'receipt',
          'transactionDate': 1700000000000,
        },
        platformIsAndroid: false,
        platformIsIOS: true,
        acknowledgedAndroidPurchaseTokens: <String, bool>{},
      );

      expect(failedPurchase, isA<types.PurchaseIOS>());
      expect((failedPurchase as types.PurchaseIOS).purchaseState,
          types.PurchaseState.Unknown);

      // Test 'deferred' state
      final deferredPurchase = convertToPurchase(
        <String, dynamic>{
          'platform': 'ios',
          'store': 'apple',
          'productId': 'premium',
          'transactionId': 'txn-deferred',
          'purchaseState': 'deferred',
          'transactionReceipt': 'receipt',
          'transactionDate': 1700000000000,
        },
        platformIsAndroid: false,
        platformIsIOS: true,
        acknowledgedAndroidPurchaseTokens: <String, bool>{},
      );

      expect(deferredPurchase, isA<types.PurchaseIOS>());
      expect((deferredPurchase as types.PurchaseIOS).purchaseState,
          types.PurchaseState.Unknown);
    });
  });
}
