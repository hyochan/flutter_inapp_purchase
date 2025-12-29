import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:flutter_inapp_purchase/types.dart' as types;
import 'package:platform/platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('flutter_inapp');
  const codec = StandardMethodCodec();

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('billing programs', () {
    test('isBillingProgramAvailableAndroid returns parsed result', () async {
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        calls.add(call);
        if (call.method == 'isBillingProgramAvailableAndroid') {
          return jsonEncode(
            <String, dynamic>{
              'billingProgram': 'external-offer',
              'isAvailable': true,
            },
          );
        }
        return null;
      });

      final iap = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'android'),
      );

      final result = await iap.isBillingProgramAvailableAndroid(
        types.BillingProgramAndroid.ExternalOffer,
      );

      expect(result.billingProgram, types.BillingProgramAndroid.ExternalOffer);
      expect(result.isAvailable, isTrue);

      final call = calls.singleWhere(
        (MethodCall call) => call.method == 'isBillingProgramAvailableAndroid',
      );
      expect(
        call.arguments,
        <String, dynamic>{'program': 'external-offer'},
      );
    });

    test(
        'createBillingProgramReportingDetailsAndroid returns external token on Android',
        () async {
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        calls.add(call);
        if (call.method == 'createBillingProgramReportingDetailsAndroid') {
          return jsonEncode(
            <String, dynamic>{
              'billingProgram': 'external-offer',
              'externalTransactionToken': 'ext-token-123',
            },
          );
        }
        return null;
      });

      final iap = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'android'),
      );

      final result = await iap.createBillingProgramReportingDetailsAndroid(
        types.BillingProgramAndroid.ExternalOffer,
      );

      expect(
        result.billingProgram,
        types.BillingProgramAndroid.ExternalOffer,
      );
      expect(result.externalTransactionToken, 'ext-token-123');

      final call = calls.singleWhere(
        (MethodCall call) =>
            call.method == 'createBillingProgramReportingDetailsAndroid',
      );
      expect(
        call.arguments,
        <String, dynamic>{'program': 'external-offer'},
      );
    });

    test('initConnection passes enableBillingProgramAndroid to native channel',
        () async {
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        calls.add(call);
        if (call.method == 'initConnection') {
          return true;
        }
        return null;
      });

      final iap = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'android'),
      );

      await iap.initConnection(
        enableBillingProgramAndroid:
            types.BillingProgramAndroid.ExternalPayments,
      );

      final call = calls.singleWhere(
        (MethodCall call) => call.method == 'initConnection',
      );
      final args = call.arguments as Map<dynamic, dynamic>?;
      expect(args, isNotNull);
      expect(args!['enableBillingProgramAndroid'], 'external-payments');
    });

    test(
        'initConnection passes both alternativeBillingMode and enableBillingProgram',
        () async {
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        calls.add(call);
        if (call.method == 'initConnection') {
          return true;
        }
        return null;
      });

      final iap = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'android'),
      );

      await iap.initConnection(
        alternativeBillingModeAndroid:
            types.AlternativeBillingModeAndroid.UserChoice,
        enableBillingProgramAndroid:
            types.BillingProgramAndroid.ExternalPayments,
      );

      final call = calls.singleWhere(
        (MethodCall call) => call.method == 'initConnection',
      );
      final args = call.arguments as Map<dynamic, dynamic>?;
      expect(args, isNotNull);
      expect(args!['alternativeBillingModeAndroid'], 'user-choice');
      expect(args['enableBillingProgramAndroid'], 'external-payments');
    });

    test('isBillingProgramAvailableAndroid handles ExternalPayments program',
        () async {
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        calls.add(call);
        if (call.method == 'isBillingProgramAvailableAndroid') {
          return jsonEncode(
            <String, dynamic>{
              'billingProgram': 'external-payments',
              'isAvailable': true,
            },
          );
        }
        return null;
      });

      final iap = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'android'),
      );

      final result = await iap.isBillingProgramAvailableAndroid(
        types.BillingProgramAndroid.ExternalPayments,
      );

      expect(
          result.billingProgram, types.BillingProgramAndroid.ExternalPayments);
      expect(result.isAvailable, isTrue);

      final call = calls.singleWhere(
        (MethodCall call) => call.method == 'isBillingProgramAvailableAndroid',
      );
      expect(
        call.arguments,
        <String, dynamic>{'program': 'external-payments'},
      );
    });

    test('isBillingProgramAvailableAndroid handles UserChoiceBilling program',
        () async {
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        calls.add(call);
        if (call.method == 'isBillingProgramAvailableAndroid') {
          return jsonEncode(
            <String, dynamic>{
              'billingProgram': 'user-choice-billing',
              'isAvailable': true,
            },
          );
        }
        return null;
      });

      final iap = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'android'),
      );

      final result = await iap.isBillingProgramAvailableAndroid(
        types.BillingProgramAndroid.UserChoiceBilling,
      );

      expect(
          result.billingProgram, types.BillingProgramAndroid.UserChoiceBilling);
      expect(result.isAvailable, isTrue);

      final call = calls.singleWhere(
        (MethodCall call) => call.method == 'isBillingProgramAvailableAndroid',
      );
      expect(
        call.arguments,
        <String, dynamic>{'program': 'user-choice-billing'},
      );
    });

    test('initConnection passes enableBillingProgramAndroid UserChoiceBilling',
        () async {
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        calls.add(call);
        if (call.method == 'initConnection') {
          return true;
        }
        return null;
      });

      final iap = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'android'),
      );

      await iap.initConnection(
        enableBillingProgramAndroid:
            types.BillingProgramAndroid.UserChoiceBilling,
      );

      final call = calls.singleWhere(
        (MethodCall call) => call.method == 'initConnection',
      );
      final args = call.arguments as Map<dynamic, dynamic>?;
      expect(args, isNotNull);
      expect(args!['enableBillingProgramAndroid'], 'user-choice-billing');
    });
  });

  group('launchExternalLinkAndroid', () {
    test('sends correct payload to native channel', () async {
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        calls.add(call);
        if (call.method == 'launchExternalLinkAndroid') {
          return true;
        }
        return null;
      });

      final iap = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'android'),
      );

      const params = types.LaunchExternalLinkParamsAndroid(
        billingProgram: types.BillingProgramAndroid.ExternalOffer,
        launchMode:
            types.ExternalLinkLaunchModeAndroid.LaunchInExternalBrowserOrApp,
        linkType: types.ExternalLinkTypeAndroid.LinkToDigitalContentOffer,
        linkUri: 'https://example.com/offer',
      );

      final result = await iap.launchExternalLinkAndroid(params);
      expect(result, isTrue);

      final methodCall = calls.singleWhere(
          (MethodCall call) => call.method == 'launchExternalLinkAndroid');
      final payload = Map<String, dynamic>.from(
          methodCall.arguments as Map<dynamic, dynamic>);
      expect(payload, params.toJson());
    });
  });

  group('requestPurchase', () {
    test('throws when connection not initialized', () async {
      final iap = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'ios'),
      );

      await expectLater(
        iap.requestPurchase(
          const types.RequestPurchaseProps.inApp((
            apple: types.RequestPurchaseIosProps(sku: 'demo.sku'),
            google: null,
            useAlternativeBilling: null,
          )),
        ),
        throwsA(
          isA<PurchaseError>().having(
            (error) => error.code,
            'code',
            types.ErrorCode.NotPrepared,
          ),
        ),
      );
    });

    test('sends expected payload for iOS purchases', () async {
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        calls.add(call);
        switch (call.method) {
          case 'initConnection':
            return true;
          case 'requestPurchase':
            return null;
        }
        return null;
      });

      final iap = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'ios'),
      );

      await iap.initConnection();

      const props = types.RequestPurchaseProps.inApp((
        apple: types.RequestPurchaseIosProps(
          sku: 'ios.sku',
          appAccountToken: 'app-token',
          quantity: 3,
          andDangerouslyFinishTransactionAutomatically: null,
          withOffer: types.DiscountOfferInputIOS(
            identifier: 'offer-id',
            keyIdentifier: 'key-id',
            nonce: 'nonce',
            signature: 'signature',
            timestamp: 123456.0,
          ),
        ),
        google: null,
        useAlternativeBilling: null,
      ));

      await iap.requestPurchase(props);

      final requestCall =
          calls.singleWhere((MethodCall c) => c.method == 'requestPurchase');
      final payload = Map<String, dynamic>.from(
          requestCall.arguments as Map<dynamic, dynamic>);

      expect(payload['sku'], 'ios.sku');
      expect(payload['type'], 'inapp');
      expect(payload['appAccountToken'], 'app-token');
      expect(payload['quantity'], 3);
      expect(
        payload['andDangerouslyFinishTransactionAutomatically'],
        isFalse,
      );
      final offer = Map<String, dynamic>.from(
          payload['withOffer'] as Map<dynamic, dynamic>);
      expect(offer['identifier'], 'offer-id');
      expect(offer['keyIdentifier'], 'key-id');
      expect(offer['nonce'], 'nonce');
      expect(offer['signature'], 'signature');
      expect(offer['timestamp'], 123456.0);
    });

    test('sends advancedCommerceData in iOS purchase payload', () async {
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        calls.add(call);
        switch (call.method) {
          case 'initConnection':
            return true;
          case 'requestPurchase':
            return null;
        }
        return null;
      });

      final iap = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'ios'),
      );

      await iap.initConnection();

      const props = types.RequestPurchaseProps.inApp((
        apple: types.RequestPurchaseIosProps(
          sku: 'ios.sku',
          advancedCommerceData: 'campaign_summer_2025',
        ),
        google: null,
        useAlternativeBilling: null,
      ));

      await iap.requestPurchase(props);

      final requestCall =
          calls.singleWhere((MethodCall c) => c.method == 'requestPurchase');
      final payload = Map<String, dynamic>.from(
          requestCall.arguments as Map<dynamic, dynamic>);

      expect(payload['sku'], 'ios.sku');
      expect(payload['advancedCommerceData'], 'campaign_summer_2025');
    });

    test('initConnection memoizes after first call', () async {
      int initCount = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        if (call.method == 'initConnection') {
          initCount += 1;
          return true;
        }
        return null;
      });

      final iap = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'ios'),
      );

      expect(await iap.initConnection(), isTrue);
      expect(await iap.initConnection(), isTrue);
      expect(initCount, 1);
    });

    test('endConnection forwards to native channel when initialized', () async {
      int endCount = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        switch (call.method) {
          case 'initConnection':
            return true;
          case 'endConnection':
            endCount += 1;
            return true;
        }
        return null;
      });

      final iap = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'ios'),
      );

      expect(await iap.initConnection(), isTrue);
      expect(await iap.endConnection(), isTrue);
      expect(endCount, 1);
    });

    test('endConnection returns false when not initialized', () async {
      bool endCalled = false;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        if (call.method == 'endConnection') {
          endCalled = true;
        }
        return null;
      });

      final iap = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'ios'),
      );

      expect(await iap.endConnection(), isFalse);
      expect(endCalled, isFalse);
    });

    test('initConnection wraps platform exception with PurchaseError',
        () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        if (call.method == 'initConnection') {
          throw PlatformException(code: 'platform', message: 'boom');
        }
        return null;
      });

      final iap = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'ios'),
      );

      await expectLater(
        iap.initConnection(),
        throwsA(
          isA<PurchaseError>().having(
            (error) => error.code,
            'code',
            types.ErrorCode.NotPrepared,
          ),
        ),
      );
    });

    test('endConnection throws PurchaseError when native layer fails',
        () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        if (call.method == 'initConnection') {
          return true;
        }
        if (call.method == 'endConnection') {
          throw PlatformException(code: 'platform', message: 'end failed');
        }
        return null;
      });

      final iap = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'ios'),
      );

      expect(await iap.initConnection(), isTrue);
      await expectLater(
        iap.endConnection(),
        throwsA(
          isA<PurchaseError>().having(
            (error) => error.code,
            'code',
            types.ErrorCode.ServiceError,
          ),
        ),
      );
    });

    // Note: Android subscription proration (purchaseTokenAndroid, replacementModeAndroid)
    // is not supported in RequestPurchaseAndroidProps. These fields only exist in
    // RequestSubscriptionAndroidProps which is used in specialized subscription APIs.
    test('sends subscription request without proration fields', () async {
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        calls.add(call);
        if (call.method == 'initConnection') {
          return true;
        }
        if (call.method == 'requestPurchase') {
          return null;
        }
        return null;
      });

      final iap = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'android'),
      );

      await iap.initConnection();

      const props = types.RequestPurchaseProps.subs((
        apple: null,
        google: types.RequestSubscriptionAndroidProps(
          skus: <String>['sub.premium'],
        ),
        useAlternativeBilling: null,
      ));

      await iap.requestPurchase(props);

      final requestCall =
          calls.singleWhere((MethodCall c) => c.method == 'requestPurchase');
      final payload = Map<String, dynamic>.from(
          requestCall.arguments as Map<dynamic, dynamic>);

      expect(payload['type'], 'subs');
      expect(payload['productId'], 'sub.premium');
      expect(payload['skus'], <String>['sub.premium']);
      // Proration fields should not be present
      expect(payload.containsKey('purchaseToken'), isFalse);
      expect(payload.containsKey('replacementMode'), isFalse);
    });

    test('sends expected payload for Android subscriptions', () async {
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        calls.add(call);
        switch (call.method) {
          case 'initConnection':
            return true;
          case 'requestPurchase':
            return null;
        }
        return null;
      });

      final iap = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'android'),
      );

      await iap.initConnection();

      const props = types.RequestPurchaseProps.subs((
        apple: null,
        google: types.RequestSubscriptionAndroidProps(
          skus: <String>['sub.premium'],
          isOfferPersonalized: true,
          obfuscatedAccountIdAndroid: 'acc-id',
          obfuscatedProfileIdAndroid: 'profile-id',
        ),
        useAlternativeBilling: null,
      ));

      await iap.requestPurchase(props);

      final requestCall =
          calls.singleWhere((MethodCall c) => c.method == 'requestPurchase');
      final payload = Map<String, dynamic>.from(
          requestCall.arguments as Map<dynamic, dynamic>);

      expect(payload['type'], 'subs');
      expect(payload['productId'], 'sub.premium');
      expect(payload['skus'], <String>['sub.premium']);
      expect(payload['isOfferPersonalized'], isTrue);
      expect(payload['obfuscatedAccountId'], 'acc-id');
      expect(payload['obfuscatedAccountIdAndroid'], 'acc-id');
      expect(payload['obfuscatedProfileId'], 'profile-id');
      expect(payload['obfuscatedProfileIdAndroid'], 'profile-id');
      // Note: purchaseToken, replacementMode, and subscriptionOffers
      // are not in RequestPurchaseAndroidProps
      // They only exist in RequestSubscriptionAndroidProps
      expect(payload.containsKey('purchaseToken'), isFalse);
      expect(payload.containsKey('replacementMode'), isFalse);
      expect(payload.containsKey('subscriptionOffers'), isFalse);
    });

    test('sends developerBillingOption for External Payments on Android',
        () async {
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        calls.add(call);
        switch (call.method) {
          case 'initConnection':
            return true;
          case 'requestPurchase':
            return null;
        }
        return null;
      });

      final iap = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'android'),
      );

      await iap.initConnection();

      const props = types.RequestPurchaseProps.inApp((
        apple: null,
        google: types.RequestPurchaseAndroidProps(
          skus: <String>['product.premium'],
          developerBillingOption: types.DeveloperBillingOptionParamsAndroid(
            billingProgram: types.BillingProgramAndroid.ExternalPayments,
            launchMode: types
                .DeveloperBillingLaunchModeAndroid.LaunchInExternalBrowserOrApp,
            linkUri: 'https://example.com/checkout',
          ),
        ),
        useAlternativeBilling: null,
      ));

      await iap.requestPurchase(props);

      final requestCall =
          calls.singleWhere((MethodCall c) => c.method == 'requestPurchase');
      final payload = Map<String, dynamic>.from(
          requestCall.arguments as Map<dynamic, dynamic>);

      expect(payload['type'], 'inapp');
      expect(payload['skus'], <String>['product.premium']);
      expect(payload.containsKey('developerBillingOption'), isTrue);

      final developerBillingOption = Map<String, dynamic>.from(
          payload['developerBillingOption'] as Map<dynamic, dynamic>);
      expect(developerBillingOption['billingProgram'], 'external-payments');
      expect(developerBillingOption['launchMode'],
          'launch-in-external-browser-or-app');
      expect(developerBillingOption['linkUri'], 'https://example.com/checkout');
    });

    test(
        'sends developerBillingOption for External Payments on subscription Android',
        () async {
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        calls.add(call);
        switch (call.method) {
          case 'initConnection':
            return true;
          case 'requestPurchase':
            return null;
        }
        return null;
      });

      final iap = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'android'),
      );

      await iap.initConnection();

      const props = types.RequestPurchaseProps.subs((
        apple: null,
        google: types.RequestSubscriptionAndroidProps(
          skus: <String>['sub.premium.monthly'],
          developerBillingOption: types.DeveloperBillingOptionParamsAndroid(
            billingProgram: types.BillingProgramAndroid.ExternalPayments,
            launchMode:
                types.DeveloperBillingLaunchModeAndroid.CallerWillLaunchLink,
            linkUri: 'https://example.com/subscribe',
          ),
          subscriptionOffers: [
            types.AndroidSubscriptionOfferInput(
              sku: 'sub.premium.monthly',
              offerToken: 'monthly-intro-offer-token',
            ),
          ],
        ),
        useAlternativeBilling: true,
      ));

      await iap.requestPurchase(props);

      final requestCall =
          calls.singleWhere((MethodCall c) => c.method == 'requestPurchase');
      final payload = Map<String, dynamic>.from(
          requestCall.arguments as Map<dynamic, dynamic>);

      expect(payload['type'], 'subs');
      expect(payload['skus'], <String>['sub.premium.monthly']);
      expect(payload['useAlternativeBilling'], isTrue);
      expect(payload.containsKey('developerBillingOption'), isTrue);

      final developerBillingOption = Map<String, dynamic>.from(
          payload['developerBillingOption'] as Map<dynamic, dynamic>);
      expect(developerBillingOption['billingProgram'], 'external-payments');
      expect(developerBillingOption['launchMode'], 'caller-will-launch-link');
      expect(
          developerBillingOption['linkUri'], 'https://example.com/subscribe');

      // Verify subscription offers are included
      expect(payload.containsKey('subscriptionOffers'), isTrue);
      final offers = payload['subscriptionOffers'] as List;
      expect(offers.length, 1);
    });

    test('sends developerBillingOption with CallerWillLaunchLink mode',
        () async {
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        calls.add(call);
        switch (call.method) {
          case 'initConnection':
            return true;
          case 'requestPurchase':
            return null;
        }
        return null;
      });

      final iap = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'android'),
      );

      await iap.initConnection();

      const props = types.RequestPurchaseProps.inApp((
        apple: null,
        google: types.RequestPurchaseAndroidProps(
          skus: <String>['product.coins'],
          developerBillingOption: types.DeveloperBillingOptionParamsAndroid(
            billingProgram: types.BillingProgramAndroid.ExternalPayments,
            launchMode:
                types.DeveloperBillingLaunchModeAndroid.CallerWillLaunchLink,
            linkUri: 'https://example.com/buy-coins',
          ),
        ),
        useAlternativeBilling: null,
      ));

      await iap.requestPurchase(props);

      final requestCall =
          calls.singleWhere((MethodCall c) => c.method == 'requestPurchase');
      final payload = Map<String, dynamic>.from(
          requestCall.arguments as Map<dynamic, dynamic>);

      final developerBillingOption = Map<String, dynamic>.from(
          payload['developerBillingOption'] as Map<dynamic, dynamic>);
      expect(developerBillingOption['launchMode'], 'caller-will-launch-link');
    });
  });

  group('requestPurchase validation', () {
    test('throws developer error when iOS props missing', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        if (call.method == 'initConnection') {
          return true;
        }
        if (call.method == 'requestPurchase') {
          fail('requestPurchase should not be invoked when payload is invalid');
        }
        return null;
      });

      final iap = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'ios'),
      );

      await iap.initConnection();

      await expectLater(
        () => iap.requestPurchase(
          const types.RequestPurchaseProps.inApp((
            apple: null,
            google: types.RequestPurchaseAndroidProps(
              skus: <String>['android-only'],
            ),
            useAlternativeBilling: null,
          )),
        ),
        throwsA(
          isA<PurchaseError>().having(
            (error) => error.code,
            'code',
            types.ErrorCode.DeveloperError,
          ),
        ),
      );
    });

    test('throws when platform is not supported', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        if (call.method == 'initConnection') {
          return true;
        }
        if (call.method == 'requestPurchase') {
          fail(
              'requestPurchase should not reach native layer on unsupported platforms');
        }
        return null;
      });

      final iap = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'linux'),
      );

      await iap.initConnection();

      await expectLater(
        () => iap.requestPurchase(
          const types.RequestPurchaseProps.inApp((
            apple: types.RequestPurchaseIosProps(sku: 'ignored'),
            google: null,
            useAlternativeBilling: null,
          )),
        ),
        throwsA(
          isA<PurchaseError>().having(
            (error) => error.code,
            'code',
            types.ErrorCode.IapNotAvailable,
          ),
        ),
      );
    });
  });

  group('requestPurchase Android in-app', () {
    test('sends payload including obfuscated identifiers', () async {
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        calls.add(call);
        switch (call.method) {
          case 'initConnection':
            return true;
          case 'requestPurchase':
            return null;
        }
        return null;
      });

      final iap = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'android'),
      );

      await iap.initConnection();

      await iap.requestPurchase(
        const types.RequestPurchaseProps.inApp((
          apple: null,
          google: types.RequestPurchaseAndroidProps(
            skus: <String>['coin.pack'],
            isOfferPersonalized: true,
            obfuscatedAccountIdAndroid: 'account-1',
            obfuscatedProfileIdAndroid: 'profile-1',
          ),
          useAlternativeBilling: null,
        )),
      );

      final requestCall =
          calls.singleWhere((MethodCall c) => c.method == 'requestPurchase');
      final payload = Map<String, dynamic>.from(
        requestCall.arguments as Map<dynamic, dynamic>,
      );

      expect(payload['type'], 'inapp');
      expect(payload['productId'], 'coin.pack');
      expect(payload['skus'], <String>['coin.pack']);
      expect(payload['isOfferPersonalized'], isTrue);
      expect(payload['obfuscatedAccountId'], 'account-1');
      expect(payload['obfuscatedAccountIdAndroid'], 'account-1');
      expect(payload['obfuscatedProfileId'], 'profile-1');
      expect(payload['obfuscatedProfileIdAndroid'], 'profile-1');
      expect(payload.containsKey('purchaseToken'), isFalse);
    });
  });

  group('getAvailablePurchases', () {
    test('forwards iOS options to native channel and filters invalid entries',
        () async {
      final capturedArguments = <dynamic>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        switch (call.method) {
          case 'initConnection':
            return true;
          case 'getAvailableItems':
            capturedArguments.add(call.arguments);
            return <Map<String, dynamic>>[
              <String, dynamic>{
                'platform': 'ios',
                'store': 'apple',
                'productId': 'iap.premium',
                'transactionId': 'txn-123',
                'purchaseToken': 'receipt-data',
                'purchaseState': 'PURCHASED',
                'transactionDate': 1700000000000,
              },
              <String, dynamic>{
                'platform': 'ios',
                'store': 'apple',
                'productId': '',
                'transactionId': null,
              },
            ];
        }
        return null;
      });

      final iap = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'ios'),
      );

      await iap.initConnection();

      final purchases = await iap.getAvailablePurchases(
        onlyIncludeActiveItemsIOS: false,
        alsoPublishToEventListenerIOS: true,
      );

      final args = Map<String, dynamic>.from(
        capturedArguments.single as Map<dynamic, dynamic>,
      );

      expect(args['onlyIncludeActiveItemsIOS'], isFalse);
      expect(args['alsoPublishToEventListenerIOS'], isTrue);
      expect(purchases, hasLength(1));
      expect(purchases.single.productId, 'iap.premium');
    });

    test('throws when connection is not initialized', () async {
      final iap = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'android'),
      );

      await expectLater(
        () => iap.getAvailablePurchases(),
        throwsA(
          isA<PurchaseError>().having(
            (error) => error.code,
            'code',
            types.ErrorCode.NotPrepared,
          ),
        ),
      );
    });

    test('filters Android purchases missing identifiers', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        switch (call.method) {
          case 'initConnection':
            return true;
          case 'getAvailableItems':
            return <Map<String, dynamic>>[
              <String, dynamic>{
                'platform': 'android',
                'store': 'google',
                'productId': 'coins.100',
                'transactionId': 'txn-android',
                'purchaseToken': 'token-android',
                'purchaseStateAndroid': 1,
              },
              <String, dynamic>{
                'platform': 'android',
                'store': 'google',
                'productId': '',
              },
            ];
        }
        return null;
      });

      final iap = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'android'),
      );

      await iap.initConnection();

      final purchases = await iap.getAvailablePurchases();
      expect(purchases, hasLength(1));
      expect(purchases.single.productId, 'coins.100');
    });

    test('wraps native errors as PurchaseError', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        if (call.method == 'initConnection') {
          return true;
        }
        if (call.method == 'getAvailableItems') {
          throw PlatformException(code: 'platform', message: 'failure');
        }
        return null;
      });

      final iap = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'android'),
      );

      await iap.initConnection();

      await expectLater(
        iap.getAvailablePurchases(),
        throwsA(
          isA<PurchaseError>().having(
            (error) => error.code,
            'code',
            types.ErrorCode.ServiceError,
          ),
        ),
      );
    });
  });

  group('method channel listeners', () {
    test('purchase-updated emits events on both streams', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        if (call.method == 'initConnection') {
          return true;
        }
        return null;
      });

      final iap = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'ios'),
      );

      final purchaseFuture = iap.purchaseUpdated.first;
      final listenerFuture = iap.purchaseUpdatedListener.first;

      await iap.initConnection();

      final purchasePayload = <String, dynamic>{
        'platform': 'ios',
        'store': 'apple',
        'productId': 'iap.premium',
        'transactionId': 'txn-456',
        'purchaseState': 'PURCHASED',
        'transactionReceipt': 'receipt-data',
        'transactionDate': 1700000000000,
      };

      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
        channel.name,
        codec.encodeMethodCall(
          MethodCall('purchase-updated', jsonEncode(purchasePayload)),
        ),
        (_) {},
      );

      final purchase = await purchaseFuture;
      final listenerPurchase = await listenerFuture;

      expect(purchase, isNotNull);
      expect(purchase!.productId, 'iap.premium');
      expect(listenerPurchase.productId, 'iap.premium');
    });

    test('purchase-error emits results to both error streams', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        if (call.method == 'initConnection') {
          return true;
        }
        return null;
      });

      final iap = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'ios'),
      );

      final purchaseErrorFuture = iap.purchaseError.first;
      final listenerErrorFuture = iap.purchaseErrorListener.first;

      await iap.initConnection();

      final errorPayload = <String, dynamic>{
        'responseCode': 5,
        'code': 'DEVELOPER_ERROR',
        'message': 'Validation failed',
      };

      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
        channel.name,
        codec.encodeMethodCall(
          MethodCall('purchase-error', jsonEncode(errorPayload)),
        ),
        (_) {},
      );

      final purchaseError = await purchaseErrorFuture;
      final listenerError = await listenerErrorFuture;

      expect(purchaseError, isNotNull);
      expect(purchaseError!.message, 'Validation failed');
      expect(listenerError.code, types.ErrorCode.DeveloperError);
      expect(listenerError.message, 'Validation failed');
    });

    test('connection-updated emits ConnectionResult', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        if (call.method == 'initConnection') {
          return true;
        }
        return null;
      });

      final iap = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'android'),
      );

      final connectionFuture = iap.connectionUpdated.first;

      await iap.initConnection();

      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
        channel.name,
        codec.encodeMethodCall(
          MethodCall(
              'connection-updated',
              jsonEncode(<String, dynamic>{
                'msg': 'connected',
              })),
        ),
        (_) {},
      );

      final result = await connectionFuture;
      expect(result.msg, 'connected');
    });

    test('iap-promoted-product emits the productId', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        if (call.method == 'initConnection') {
          return true;
        }
        return null;
      });

      final iap = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'ios'),
      );

      final promotedFuture = iap.purchasePromoted.first;

      await iap.initConnection();

      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
        channel.name,
        codec.encodeMethodCall(
          const MethodCall('iap-promoted-product', 'promo.product'),
        ),
        (_) {},
      );

      final productId = await promotedFuture;
      expect(productId, 'promo.product');
    });

    test('developer-provided-billing-android emits details to stream',
        () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        if (call.method == 'initConnection') {
          return true;
        }
        return null;
      });

      final iap = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'android'),
      );

      final developerBillingFuture = iap.developerProvidedBillingAndroid.first;

      await iap.initConnection();

      final payload = <String, dynamic>{
        'externalTransactionToken': 'ext-token-abc123',
      };

      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
        channel.name,
        codec.encodeMethodCall(
          MethodCall('developer-provided-billing-android', jsonEncode(payload)),
        ),
        (_) {},
      );

      final details = await developerBillingFuture;
      expect(details.externalTransactionToken, 'ext-token-abc123');
    });
  });

  group('sync and restore helpers', () {
    test('restorePurchases triggers sync and fetch on iOS', () async {
      int initCalls = 0;
      int endCalls = 0;
      int availableCalls = 0;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        switch (call.method) {
          case 'initConnection':
            initCalls += 1;
            return true;
          case 'endConnection':
            endCalls += 1;
            return true;
          case 'getAvailableItems':
            availableCalls += 1;
            return <Map<String, dynamic>>[];
        }
        return null;
      });

      final iap = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'ios'),
      );

      expect(await iap.initConnection(), isTrue);
      await iap.restorePurchases();

      expect(endCalls, greaterThanOrEqualTo(1));
      expect(initCalls, greaterThanOrEqualTo(2));
      expect(availableCalls, 1);
    });

    test('restorePurchases swallows sync errors and still fetches', () async {
      int availableCalls = 0;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        if (call.method == 'initConnection') {
          return true;
        }
        if (call.method == 'endConnection') {
          throw PlatformException(code: '500', message: 'boom');
        }
        if (call.method == 'getAvailableItems') {
          availableCalls += 1;
          return <Map<String, dynamic>>[];
        }
        return null;
      });

      final iap = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'ios'),
      );

      expect(await iap.initConnection(), isTrue);
      await iap.restorePurchases();

      expect(availableCalls, 1);
    });

    test('restorePurchases fetches purchases directly on Android', () async {
      int availableCalls = 0;
      int endCalls = 0;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        if (call.method == 'initConnection') {
          return true;
        }
        if (call.method == 'endConnection') {
          endCalls += 1;
          return true;
        }
        if (call.method == 'getAvailableItems') {
          availableCalls += 1;
          return <Map<String, dynamic>>[];
        }
        return null;
      });

      final iap = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'android'),
      );

      expect(await iap.initConnection(), isTrue);
      await iap.restorePurchases();

      expect(availableCalls, 1);
      expect(endCalls, 0);
    });

    test('syncIOS returns true when native calls succeed', () async {
      int endCalls = 0;
      int initCalls = 0;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        if (call.method == 'endConnection') {
          endCalls += 1;
          return true;
        }
        if (call.method == 'initConnection') {
          initCalls += 1;
          return true;
        }
        return null;
      });

      final iap = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'ios'),
      );

      expect(await iap.syncIOS(), isTrue);
      expect(endCalls, 1);
      expect(initCalls, 1);
    });

    test('syncIOS rethrows platform exceptions', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        if (call.method == 'endConnection') {
          throw PlatformException(code: '500', message: 'boom');
        }
        if (call.method == 'initConnection') {
          return true;
        }
        return null;
      });

      final iap = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'ios'),
      );

      await expectLater(
        iap.syncIOS(),
        throwsA(isA<PlatformException>()),
      );
    });

    test('syncIOS returns false on unsupported platforms', () async {
      final iap = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'android'),
      );

      expect(await iap.syncIOS(), isFalse);
    });
  });

  group('verifyPurchase', () {
    test('throws when connection not initialized', () async {
      final iap = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'ios'),
      );

      await expectLater(
        iap.verifyPurchase(
          apple: const types.VerifyPurchaseAppleOptions(sku: 'test.sku'),
        ),
        throwsA(
          isA<PurchaseError>().having(
            (error) => error.code,
            'code',
            types.ErrorCode.NotPrepared,
          ),
        ),
      );
    });

    test('sends correct payload for iOS verification', () async {
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        calls.add(call);
        switch (call.method) {
          case 'initConnection':
            return true;
          case 'verifyPurchase':
            return {
              '__typename': 'VerifyPurchaseResultIOS',
              'isValid': true,
              'jwsRepresentation': 'test-jws-representation',
              'receiptData': 'test-receipt-data',
            };
        }
        return null;
      });

      final iap = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'ios'),
      );

      await iap.initConnection();

      final result = await iap.verifyPurchase(
        apple: const types.VerifyPurchaseAppleOptions(sku: 'premium.upgrade'),
      );

      final verifyCall =
          calls.singleWhere((MethodCall c) => c.method == 'verifyPurchase');
      final payload = Map<String, dynamic>.from(
          verifyCall.arguments as Map<dynamic, dynamic>);

      expect(payload['apple'], isNotNull);
      final appleOptions =
          Map<String, dynamic>.from(payload['apple'] as Map<dynamic, dynamic>);
      expect(appleOptions['sku'], 'premium.upgrade');

      expect(result, isA<types.VerifyPurchaseResultIOS>());
      final iosResult = result as types.VerifyPurchaseResultIOS;
      expect(iosResult.isValid, true);
      expect(iosResult.jwsRepresentation, 'test-jws-representation');
    });

    test('sends correct payload for Android verification', () async {
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        calls.add(call);
        switch (call.method) {
          case 'initConnection':
            return true;
          case 'verifyPurchase':
            return {
              '__typename': 'VerifyPurchaseResultAndroid',
              'productId': 'premium.upgrade',
              'productType': 'inapp',
              'purchaseDate': 1705315800000.0,
              'autoRenewing': false,
              'betaProduct': false,
              'freeTrialEndDate': 0.0,
              'gracePeriodEndDate': 0.0,
              'parentProductId': '',
              'quantity': 1,
              'receiptId': 'test-receipt-id',
              'renewalDate': 0.0,
              'term': '',
              'termSku': '',
              'testTransaction': false,
            };
        }
        return null;
      });

      final iap = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'android'),
      );

      await iap.initConnection();

      final result = await iap.verifyPurchase(
        google: const types.VerifyPurchaseGoogleOptions(
          sku: 'premium.upgrade',
          accessToken: 'test-access-token',
          packageName: 'com.example.app',
          purchaseToken: 'test-purchase-token',
        ),
      );

      final verifyCall =
          calls.singleWhere((MethodCall c) => c.method == 'verifyPurchase');
      final payload = Map<String, dynamic>.from(
          verifyCall.arguments as Map<dynamic, dynamic>);

      expect(payload['google'], isNotNull);
      final googleOptions =
          Map<String, dynamic>.from(payload['google'] as Map<dynamic, dynamic>);
      expect(googleOptions['sku'], 'premium.upgrade');
      expect(googleOptions['accessToken'], 'test-access-token');
      expect(googleOptions['packageName'], 'com.example.app');
      expect(googleOptions['purchaseToken'], 'test-purchase-token');

      expect(result, isA<types.VerifyPurchaseResultAndroid>());
      final androidResult = result as types.VerifyPurchaseResultAndroid;
      expect(androidResult.productId, 'premium.upgrade');
      expect(androidResult.productType, 'inapp');
      expect(androidResult.autoRenewing, false);
    });

    test('throws PurchaseError on platform exception', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        switch (call.method) {
          case 'initConnection':
            return true;
          case 'verifyPurchase':
            throw PlatformException(
              code: 'VERIFICATION_FAILED',
              message: 'Purchase verification failed',
            );
        }
        return null;
      });

      final iap = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'ios'),
      );

      await iap.initConnection();

      await expectLater(
        iap.verifyPurchase(
          apple: const types.VerifyPurchaseAppleOptions(sku: 'test.sku'),
        ),
        throwsA(isA<PurchaseError>()),
      );
    });

    test('throws when native returns null', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        switch (call.method) {
          case 'initConnection':
            return true;
          case 'verifyPurchase':
            return null;
        }
        return null;
      });

      final iap = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'ios'),
      );

      await iap.initConnection();

      await expectLater(
        iap.verifyPurchase(
          apple: const types.VerifyPurchaseAppleOptions(sku: 'test.sku'),
        ),
        throwsA(
          isA<PurchaseError>().having(
            (error) => error.code,
            'code',
            types.ErrorCode.PurchaseVerificationFailed,
          ),
        ),
      );
    });
  });

  group('verifyPurchaseWithProvider', () {
    test('throws when connection not initialized', () async {
      final iap = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'ios'),
      );

      await expectLater(
        iap.verifyPurchaseWithProvider(
          provider: types.PurchaseVerificationProvider.Iapkit,
          iapkit: const types.RequestVerifyPurchaseWithIapkitProps(
            apiKey: 'test-key',
            apple: types.RequestVerifyPurchaseWithIapkitAppleProps(
              jws: 'test-jws',
            ),
          ),
        ),
        throwsA(
          isA<PurchaseError>().having(
            (error) => error.code,
            'code',
            types.ErrorCode.NotPrepared,
          ),
        ),
      );
    });

    test('sends correct payload for iOS verification', () async {
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        calls.add(call);
        switch (call.method) {
          case 'initConnection':
            return true;
          case 'verifyPurchaseWithProvider':
            return {
              'provider': 'iapkit',
              'iapkit': {
                'isValid': true,
                'state': 'entitled',
                'store': 'apple',
              },
            };
        }
        return null;
      });

      final iap = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'ios'),
      );

      await iap.initConnection();

      final result = await iap.verifyPurchaseWithProvider(
        provider: types.PurchaseVerificationProvider.Iapkit,
        iapkit: const types.RequestVerifyPurchaseWithIapkitProps(
          apiKey: 'test-api-key',
          apple: types.RequestVerifyPurchaseWithIapkitAppleProps(
            jws: 'test-jws-token',
          ),
        ),
      );

      final verifyCall = calls.singleWhere(
          (MethodCall c) => c.method == 'verifyPurchaseWithProvider');
      final payload = Map<String, dynamic>.from(
          verifyCall.arguments as Map<dynamic, dynamic>);

      expect(payload['provider'], 'iapkit');
      expect(payload['iapkit'], isNotNull);
      final iapkitPayload =
          Map<String, dynamic>.from(payload['iapkit'] as Map<dynamic, dynamic>);
      expect(iapkitPayload['apiKey'], 'test-api-key');
      expect(iapkitPayload['apple'], isNotNull);
      final applePayload = Map<String, dynamic>.from(
          iapkitPayload['apple'] as Map<dynamic, dynamic>);
      expect(applePayload['jws'], 'test-jws-token');

      expect(result.provider, types.PurchaseVerificationProvider.Iapkit);
      expect(result.iapkit, isNotNull);
      expect(result.iapkit!.isValid, true);
      expect(result.iapkit!.state, types.IapkitPurchaseState.Entitled);
      expect(result.iapkit!.store, types.IapStore.Apple);
    });

    test('sends correct payload for Android verification', () async {
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        calls.add(call);
        switch (call.method) {
          case 'initConnection':
            return true;
          case 'verifyPurchaseWithProvider':
            return jsonEncode({
              'provider': 'iapkit',
              'iapkit': {
                'isValid': true,
                'state': 'pending-acknowledgment',
                'store': 'google',
              },
            });
        }
        return null;
      });

      final iap = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'android'),
      );

      await iap.initConnection();

      final result = await iap.verifyPurchaseWithProvider(
        provider: types.PurchaseVerificationProvider.Iapkit,
        iapkit: const types.RequestVerifyPurchaseWithIapkitProps(
          apiKey: 'test-api-key',
          google: types.RequestVerifyPurchaseWithIapkitGoogleProps(
            purchaseToken: 'test-purchase-token',
          ),
        ),
      );

      final verifyCall = calls.singleWhere(
          (MethodCall c) => c.method == 'verifyPurchaseWithProvider');
      final payload = Map<String, dynamic>.from(
          verifyCall.arguments as Map<dynamic, dynamic>);

      expect(payload['provider'], 'iapkit');
      final iapkitPayload =
          Map<String, dynamic>.from(payload['iapkit'] as Map<dynamic, dynamic>);
      expect(iapkitPayload['google'], isNotNull);
      final googlePayload = Map<String, dynamic>.from(
          iapkitPayload['google'] as Map<dynamic, dynamic>);
      expect(googlePayload['purchaseToken'], 'test-purchase-token');

      expect(result.iapkit, isNotNull);
      expect(result.iapkit!.isValid, true);
      expect(result.iapkit!.state,
          types.IapkitPurchaseState.PendingAcknowledgment);
      expect(result.iapkit!.store, types.IapStore.Google);
    });

    test('throws PurchaseError on platform exception', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        switch (call.method) {
          case 'initConnection':
            return true;
          case 'verifyPurchaseWithProvider':
            throw PlatformException(
              code: 'E_PURCHASE_VERIFICATION_FAILED',
              message: 'Verification failed',
            );
        }
        return null;
      });

      final iap = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'ios'),
      );

      await iap.initConnection();

      await expectLater(
        iap.verifyPurchaseWithProvider(
          provider: types.PurchaseVerificationProvider.Iapkit,
          iapkit: const types.RequestVerifyPurchaseWithIapkitProps(
            apiKey: 'test-key',
            apple: types.RequestVerifyPurchaseWithIapkitAppleProps(
              jws: 'invalid-jws',
            ),
          ),
        ),
        throwsA(
          isA<PurchaseError>().having(
            (error) => error.code,
            'code',
            types.ErrorCode.PurchaseVerificationFailed,
          ),
        ),
      );
    });

    test('handles null iapkit response', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        switch (call.method) {
          case 'initConnection':
            return true;
          case 'verifyPurchaseWithProvider':
            return {
              'provider': 'iapkit',
              // iapkit is null/missing
            };
        }
        return null;
      });

      final iap = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'ios'),
      );

      await iap.initConnection();

      final result = await iap.verifyPurchaseWithProvider(
        provider: types.PurchaseVerificationProvider.Iapkit,
        iapkit: const types.RequestVerifyPurchaseWithIapkitProps(
          apiKey: 'test-api-key',
          apple: types.RequestVerifyPurchaseWithIapkitAppleProps(
            jws: 'test-jws-token',
          ),
        ),
      );

      expect(result.provider, types.PurchaseVerificationProvider.Iapkit);
      expect(result.iapkit, isNull);
    });

    test('handles errors in response', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        switch (call.method) {
          case 'initConnection':
            return true;
          case 'verifyPurchaseWithProvider':
            return {
              'provider': 'iapkit',
              'iapkit': {
                'isValid': false,
                'state': 'expired',
                'store': 'apple',
              },
              'errors': [
                {
                  'code': 'INVALID_RECEIPT',
                  'message': 'The receipt is invalid',
                },
                {
                  'code': 'EXPIRED',
                  'message': 'Subscription has expired',
                },
              ],
            };
        }
        return null;
      });

      final iap = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'ios'),
      );

      await iap.initConnection();

      final result = await iap.verifyPurchaseWithProvider(
        provider: types.PurchaseVerificationProvider.Iapkit,
        iapkit: const types.RequestVerifyPurchaseWithIapkitProps(
          apiKey: 'test-api-key',
          apple: types.RequestVerifyPurchaseWithIapkitAppleProps(
            jws: 'test-jws-token',
          ),
        ),
      );

      expect(result.provider, types.PurchaseVerificationProvider.Iapkit);
      expect(result.iapkit, isNotNull);
      expect(result.iapkit!.isValid, false);
      expect(result.errors, isNotNull);
      expect(result.errors!.length, 2);
      expect(result.errors![0].code, 'INVALID_RECEIPT');
      expect(result.errors![0].message, 'The receipt is invalid');
      expect(result.errors![1].code, 'EXPIRED');
      expect(result.errors![1].message, 'Subscription has expired');
    });

    test('handles iapkit as non-Map gracefully', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        switch (call.method) {
          case 'initConnection':
            return true;
          case 'verifyPurchaseWithProvider':
            return {
              'provider': 'iapkit',
              'iapkit': 'invalid-data', // Not a Map
            };
        }
        return null;
      });

      final iap = FlutterInappPurchase.private(
        FakePlatform(operatingSystem: 'ios'),
      );

      await iap.initConnection();

      final result = await iap.verifyPurchaseWithProvider(
        provider: types.PurchaseVerificationProvider.Iapkit,
        iapkit: const types.RequestVerifyPurchaseWithIapkitProps(
          apiKey: 'test-api-key',
          apple: types.RequestVerifyPurchaseWithIapkitAppleProps(
            jws: 'test-jws-token',
          ),
        ),
      );

      // Should handle gracefully with default values
      expect(result.provider, types.PurchaseVerificationProvider.Iapkit);
      expect(result.iapkit, isNotNull);
      expect(result.iapkit!.isValid, false); // Default value
    });
  });
}
