import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:platform/platform.dart';

import 'enums.dart';
import 'errors.dart' as iap_err;
import 'types.dart' as iap_types;
import 'modules/ios.dart';
import 'modules/android.dart';
import 'builders.dart';
import 'utils.dart';

export 'types.dart';
export 'enums.dart';
export 'errors.dart';
export 'events.dart';
export 'builders.dart';
export 'utils.dart';

// Enums moved to enums.dart

// MARK: - Classes from modules.dart

// MARK: - Main FlutterInappPurchase class

class FlutterInappPurchase
    with FlutterInappPurchaseIOS, FlutterInappPurchaseAndroid {
  // Singleton instance
  static FlutterInappPurchase? _instance;

  /// Get the singleton instance
  static FlutterInappPurchase get instance {
    _instance ??= FlutterInappPurchase();
    return _instance!;
  }

  // Instance-level stream controllers
  StreamController<iap_types.Purchase?>? _purchaseController;
  Stream<iap_types.Purchase?> get purchaseUpdated {
    _purchaseController ??= StreamController<iap_types.Purchase?>.broadcast();
    return _purchaseController!.stream;
  }

  StreamController<iap_types.PurchaseResult?>? _purchaseErrorController;
  Stream<iap_types.PurchaseResult?> get purchaseError {
    _purchaseErrorController ??=
        StreamController<iap_types.PurchaseResult?>.broadcast();
    return _purchaseErrorController!.stream;
  }

  StreamController<iap_types.ConnectionResult>? _connectionController;
  Stream<iap_types.ConnectionResult> get connectionUpdated {
    _connectionController ??=
        StreamController<iap_types.ConnectionResult>.broadcast();
    return _connectionController!.stream;
  }

  StreamController<String?>? _purchasePromotedController;
  Stream<String?> get purchasePromoted {
    _purchasePromotedController ??= StreamController<String?>.broadcast();
    return _purchasePromotedController!.stream;
  }

  StreamController<int?>? _onInAppMessageController;
  Stream<int?> get inAppMessageAndroid {
    _onInAppMessageController ??= StreamController<int?>.broadcast();
    return _onInAppMessageController!.stream;
  }

  /// Defining the [MethodChannel] for Flutter_Inapp_Purchase
  final MethodChannel _channel = const MethodChannel('flutter_inapp');

  @override
  MethodChannel get channel => _channel;

  Platform get _platform => _pf;
  // Public getters used by platform mixins
  bool get isIOS => _platform.isIOS;
  bool get isAndroid => _platform.isAndroid;
  String get operatingSystem => _platform.operatingSystem;

  final Platform _pf;
  late final http.Client _httpClient;

  http.Client get _client => _httpClient;

  FlutterInappPurchase({Platform? platform, http.Client? client})
      : _pf = platform ?? const LocalPlatform(),
        _httpClient = client ?? http.Client();

  @visibleForTesting
  FlutterInappPurchase.private(Platform platform, {http.Client? client})
      : _pf = platform,
        _httpClient = client ?? http.Client();

  // Implement the missing method from iOS mixin
  @override
  List<iap_types.Purchase>? extractPurchasedItems(dynamic result) {
    return extractPurchases(result);
  }

  // Purchase event streams
  final StreamController<iap_types.Purchase> _purchaseUpdatedListener =
      StreamController<iap_types.Purchase>.broadcast();
  final StreamController<iap_types.PurchaseError> _purchaseErrorListener =
      StreamController<iap_types.PurchaseError>.broadcast();

  /// Purchase updated event stream
  Stream<iap_types.Purchase> get purchaseUpdatedListener =>
      _purchaseUpdatedListener.stream;

  /// Purchase error event stream
  Stream<iap_types.PurchaseError> get purchaseErrorListener =>
      _purchaseErrorListener.stream;

  bool _isInitialized = false;

  /// Initialize connection (flutter IAP compatible)
  Future<bool> initConnection() async {
    if (_isInitialized) {
      throw iap_types.PurchaseError(
        code: iap_types.ErrorCode.eAlreadyInitialized,
        message: 'IAP connection already initialized',
        platform: _platform.isIOS
            ? iap_types.IapPlatform.ios
            : iap_types.IapPlatform.android,
      );
    }

    try {
      // For flutter IAP compatibility, call initConnection directly
      await _setPurchaseListener();
      if (_platform.isIOS) {
        await _channel.invokeMethod('initConnection');
      } else if (_platform.isAndroid) {
        await _channel.invokeMethod('initConnection');
      }
      _isInitialized = true;
      return true;
    } catch (e) {
      throw iap_types.PurchaseError(
        code: iap_types.ErrorCode.eNotInitialized,
        message: 'Failed to initialize IAP connection: ${e.toString()}',
        platform: _platform.isIOS
            ? iap_types.IapPlatform.ios
            : iap_types.IapPlatform.android,
      );
    }
  }

  /// End connection (flutter IAP compatible)
  Future<bool> endConnection() async {
    if (!_isInitialized) {
      return false;
    }

    try {
      // For flutter IAP compatibility, call endConnection directly
      await _channel.invokeMethod('endConnection');

      _isInitialized = false;
      return true;
    } catch (e) {
      throw iap_types.PurchaseError(
        code: iap_types.ErrorCode.eServiceError,
        message: 'Failed to end IAP connection: ${e.toString()}',
        platform: _platform.isIOS
            ? iap_types.IapPlatform.ios
            : iap_types.IapPlatform.android,
      );
    }
  }

  /// Request products (flutter IAP compatible) — DEPRECATED
  @Deprecated('Removed in 6.6.0. Use fetchProducts().')
  Future<List<T>> requestProducts<T extends iap_types.ProductCommon>({
    required List<String> skus,
    String type = iap_types.ProductType.inapp,
  }) async =>
      throw UnsupportedError(
        'requestProducts() was removed in 6.6.0. Use fetchProducts().',
      );

  /// Request purchase (flutter IAP compatible)
  Future<void> requestPurchase({
    required iap_types.RequestPurchase request,
    required String type,
  }) async {
    if (!_isInitialized) {
      throw iap_types.PurchaseError(
        code: iap_types.ErrorCode.eNotInitialized,
        message: 'IAP connection not initialized',
        platform: _platform.isIOS
            ? iap_types.IapPlatform.ios
            : iap_types.IapPlatform.android,
      );
    }

    try {
      if (_platform.isIOS) {
        final iosRequest = request.ios;
        if (iosRequest == null) {
          throw iap_types.PurchaseError(
            code: iap_types.ErrorCode.eDeveloperError,
            message: 'iOS request parameters are required for iOS platform',
            platform: _platform.isIOS
                ? iap_types.IapPlatform.ios
                : iap_types.IapPlatform.android,
          );
        }

        if (iosRequest.withOffer != null) {
          await _channel
              .invokeMethod('requestProductWithOfferIOS', <String, dynamic>{
            'sku': iosRequest.sku,
            'forUser': iosRequest.appAccountToken ?? '',
            'withOffer': iosRequest.withOffer!.toJson(),
          });
        } else if (iosRequest.quantity != null && iosRequest.quantity! > 1) {
          await _channel.invokeMethod(
            'requestProductWithQuantityIOS',
            <String, dynamic>{
              'sku': iosRequest.sku,
              'quantity': iosRequest.quantity!.toString(),
            },
          );
        } else {
          if (type == iap_types.ProductType.subs) {
            await requestSubscription(iosRequest.sku);
          } else {
            await _channel.invokeMethod('requestPurchase', <String, dynamic>{
              'sku': iosRequest.sku,
              'appAccountToken': iosRequest.appAccountToken,
            });
          }
        }
      } else if (_platform.isAndroid) {
        final androidRequest = request.android;
        if (androidRequest == null) {
          throw iap_types.PurchaseError(
            code: iap_types.ErrorCode.eDeveloperError,
            message:
                'Android request parameters are required for Android platform',
            platform: _platform.isIOS
                ? iap_types.IapPlatform.ios
                : iap_types.IapPlatform.android,
          );
        }

        final sku =
            androidRequest.skus.isNotEmpty ? androidRequest.skus.first : '';
        if (type == iap_types.ProductType.subs) {
          // Check if this is a RequestSubscriptionAndroid
          if (androidRequest is iap_types.RequestSubscriptionAndroid) {
            // Validate proration mode requirements before calling requestSubscription
            if (androidRequest.replacementModeAndroid != null &&
                androidRequest.replacementModeAndroid != -1 &&
                (androidRequest.purchaseTokenAndroid == null ||
                    androidRequest.purchaseTokenAndroid!.isEmpty)) {
              throw iap_types.PurchaseError(
                code: iap_types.ErrorCode.eDeveloperError,
                message:
                    'purchaseTokenAndroid is required when using replacementModeAndroid (proration mode). '
                    'You need the purchase token from the existing subscription to upgrade/downgrade.',
                platform: iap_types.IapPlatform.android,
              );
            }

            await requestSubscription(
              sku,
              obfuscatedAccountIdAndroid:
                  androidRequest.obfuscatedAccountIdAndroid,
              obfuscatedProfileIdAndroid:
                  androidRequest.obfuscatedProfileIdAndroid,
              purchaseTokenAndroid: androidRequest.purchaseTokenAndroid,
              replacementModeAndroid: androidRequest.replacementModeAndroid,
            );
          } else {
            await requestSubscription(
              sku,
              obfuscatedAccountIdAndroid:
                  androidRequest.obfuscatedAccountIdAndroid,
              obfuscatedProfileIdAndroid:
                  androidRequest.obfuscatedProfileIdAndroid,
            );
          }
        } else {
          await _channel.invokeMethod('buyItemByType', <String, dynamic>{
            'type': TypeInApp.inapp.name,
            'productId': sku,
            'replacementMode': -1,
            'obfuscatedAccountId': androidRequest.obfuscatedAccountIdAndroid,
            'obfuscatedProfileId': androidRequest.obfuscatedProfileIdAndroid,
          });
        }
      }
    } catch (e) {
      if (e is iap_types.PurchaseError) {
        rethrow;
      }
      throw iap_types.PurchaseError(
        code: iap_types.ErrorCode.eServiceError,
        message: 'Failed to request purchase: ${e.toString()}',
        platform: _platform.isIOS
            ? iap_types.IapPlatform.ios
            : iap_types.IapPlatform.android,
      );
    }
  }

  /// Request purchase with automatic platform detection
  /// This method simplifies the purchase request by automatically detecting the platform
  /// and using the appropriate parameters from the RequestPurchase object
  @Deprecated('Removed in 6.6.0. Use requestPurchase() instead.')
  Future<void> requestPurchaseAuto({
    required String sku,
    required String type,
    // iOS-specific optional parameters
    bool? andDangerouslyFinishTransactionAutomaticallyIOS,
    String? appAccountToken,
    int? quantity,
    iap_types.PaymentDiscount? withOffer,
    // Android-specific optional parameters
    String? obfuscatedAccountIdAndroid,
    String? obfuscatedProfileIdAndroid,
    bool? isOfferPersonalized,
    String? purchaseToken,
    int? offerTokenIndex,
    @Deprecated('Use replacementMode instead') int? prorationMode,
    int? replacementMode,
    // Android subscription-specific
    int? replacementModeAndroid,
    List<iap_types.SubscriptionOfferAndroid>? subscriptionOffers,
  }) async =>
      throw UnsupportedError(
        'requestPurchaseAuto() was removed in 6.6.0. Use requestPurchase() with explicit parameters.',
      );

  /// DSL-like request purchase method with builder pattern
  /// Provides a more intuitive and type-safe way to build purchase requests
  ///
  /// Example:
  /// ```dart
  /// await iap.requestPurchaseWithBuilder(
  ///   build: (r) => r
  ///     ..type = ProductType.inapp
  ///     ..withIOS((i) => i
  ///       ..sku = 'product_id'
  ///       ..quantity = 1)
  ///     ..withAndroid((a) => a
  ///       ..skus = ['product_id']),
  /// );
  /// ```
  Future<void> requestPurchaseWithBuilder({
    required RequestBuilder build,
  }) async {
    final builder = RequestPurchaseBuilder();
    build(builder);
    final request = builder.build();
    await requestPurchase(request: request, type: builder.type);
  }

  /// DSL-like request subscription method with builder pattern
  @Deprecated(
      'Use requestPurchaseWithBuilder() instead. Will be removed in 6.6.0')

  /// Provides a more intuitive and type-safe way to build subscription requests
  ///
  /// Example:
  /// ```dart
  /// await iap.requestSubscriptionWithBuilder(
  ///   build: (r) => r
  ///     ..withIOS((i) => i
  ///       ..sku = 'subscription_id')
  ///     ..withAndroid((a) => a
  ///       ..skus = ['subscription_id']
  ///       ..replacementModeAndroid = AndroidReplacementMode.withTimeProration.value
  ///       ..purchaseTokenAndroid = existingToken),
  /// );
  /// ```
  /// DSL-like request subscription method with builder pattern
  /// Provides a more intuitive and type-safe way to build subscription requests
  ///
  /// Example:
  /// ```dart
  /// await iap.requestSubscriptionWithBuilder(
  ///   build: (r) => r
  ///     ..withIOS((i) => i..sku = 'subscription_id')
  ///     ..withAndroid((a) => a
  ///       ..skus = ['subscription_id']
  ///       ..replacementModeAndroid = AndroidReplacementMode.withTimeProration.value
  ///       ..purchaseTokenAndroid = existingToken),
  /// );
  /// ```
  Future<void> requestSubscriptionWithBuilder({
    required SubscriptionBuilder build,
  }) async {
    final builder = RequestSubscriptionBuilder();
    build(builder);
    final request = builder.build();
    await requestPurchase(request: request, type: iap_types.ProductType.subs);
  }

  /// Get all available purchases (OpenIAP standard)
  /// Returns non-consumed purchases that are still pending acknowledgment or consumption
  ///
  /// [options] - Optional configuration for the method behavior
  /// - onlyIncludeActiveItemsIOS: Whether to only include active items (default: true)
  ///   Set to false to include expired subscriptions
  Future<List<iap_types.Purchase>> getAvailablePurchases([
    iap_types.PurchaseOptions? options,
  ]) async {
    if (!_isInitialized) {
      throw iap_types.PurchaseError(
        code: iap_types.ErrorCode.eNotInitialized,
        message: 'IAP connection not initialized',
        platform: _platform.isIOS
            ? iap_types.IapPlatform.ios
            : iap_types.IapPlatform.android,
      );
    }

    try {
      if (_platform.isAndroid) {
        // Get both consumable and subscription purchases on Android
        final List<iap_types.Purchase> allPurchases = [];

        // Get consumable purchases
        dynamic result1 = await _channel.invokeMethod(
          'getAvailableItemsByType',
          <String, dynamic>{'type': TypeInApp.inapp.name},
        );
        final consumables = extractPurchases(result1) ?? [];
        allPurchases.addAll(consumables);

        // Get subscription purchases
        dynamic result2 = await _channel.invokeMethod(
          'getAvailableItemsByType',
          <String, dynamic>{'type': TypeInApp.subs.name},
        );
        final subscriptions = extractPurchases(result2) ?? [];
        allPurchases.addAll(subscriptions);

        return allPurchases;
      } else if (_platform.isIOS) {
        // On iOS, pass both iOS-specific options to native method
        final args = options?.toMap() ?? <String, dynamic>{};

        dynamic result = await _channel.invokeMethod('getAvailableItems', args);
        final items = extractPurchases(json.encode(result)) ?? [];
        return items;
      }
      return [];
    } catch (e) {
      throw iap_types.PurchaseError(
        code: iap_types.ErrorCode.eServiceError,
        message: 'Failed to get available purchases: ${e.toString()}',
        platform: _platform.isIOS
            ? iap_types.IapPlatform.ios
            : iap_types.IapPlatform.android,
      );
    }
  }

  /// Get complete purchase histories
  /// Returns all purchases including consumed and finished ones
  ///
  /// @deprecated - Use getAvailablePurchases with PurchaseOptions instead
  /// To get expired subscriptions on iOS, use:
  /// ```dart
  /// getAvailablePurchases(PurchaseOptions(onlyIncludeActiveItemsIOS: false))
  /// ```
  @Deprecated(
    'Use getAvailablePurchases with PurchaseOptions instead. '
    'Will be removed in 6.6.0',
  )
  Future<List<iap_types.Purchase>> getPurchaseHistories() async {
    if (!_isInitialized) {
      throw iap_types.PurchaseError(
        code: iap_types.ErrorCode.eNotInitialized,
        message: 'IAP connection not initialized',
        platform: _platform.isIOS
            ? iap_types.IapPlatform.ios
            : iap_types.IapPlatform.android,
      );
    }

    try {
      final List<iap_types.Purchase> history = [];

      if (_platform.isAndroid) {
        // Get purchase history for consumables
        final dynamic inappHistory = await _channel.invokeMethod(
          'getPurchaseHistoryByType',
          <String, dynamic>{'type': TypeInApp.inapp.name},
        );
        final inappItems = extractPurchases(inappHistory) ?? [];
        history.addAll(inappItems);

        // Get purchase history for subscriptions
        final dynamic subsHistory = await _channel.invokeMethod(
          'getPurchaseHistoryByType',
          <String, dynamic>{'type': TypeInApp.subs.name},
        );
        final subsItems = extractPurchases(subsHistory) ?? [];
        history.addAll(subsItems);
      } else if (_platform.isIOS) {
        // On iOS, use getPurchaseHistoriesIOS to get ALL transactions including expired ones
        dynamic result = await _channel.invokeMethod('getPurchaseHistoriesIOS');
        final items = extractPurchases(json.encode(result)) ?? [];
        history.addAll(items);
      }

      return history;
    } catch (e) {
      throw iap_types.PurchaseError(
        code: iap_types.ErrorCode.eServiceError,
        message: 'Failed to get purchase history: ${e.toString()}',
        platform: _platform.isIOS
            ? iap_types.IapPlatform.ios
            : iap_types.IapPlatform.android,
      );
    }
  }

  /// iOS specific: Get storefront
  Future<String> getStorefrontIOS() async {
    if (!_platform.isIOS) {
      throw iap_types.PurchaseError(
        code: iap_types.ErrorCode.eIapNotAvailable,
        message: 'Storefront is only available on iOS',
        platform: _platform.isIOS
            ? iap_types.IapPlatform.ios
            : iap_types.IapPlatform.android,
      );
    }

    try {
      final result = await channel.invokeMethod<Map<dynamic, dynamic>>(
        'getStorefrontIOS',
      );
      if (result != null && result['countryCode'] != null) {
        return result['countryCode'] as String;
      }
      throw iap_types.PurchaseError(
        code: iap_types.ErrorCode.eServiceError,
        message: 'Failed to get storefront country code',
        platform: _platform.isIOS
            ? iap_types.IapPlatform.ios
            : iap_types.IapPlatform.android,
      );
    } catch (e) {
      if (e is iap_types.PurchaseError) {
        rethrow;
      }
      throw iap_types.PurchaseError(
        code: iap_types.ErrorCode.eServiceError,
        message: 'Failed to get storefront: ${e.toString()}',
        platform: _platform.isIOS
            ? iap_types.IapPlatform.ios
            : iap_types.IapPlatform.android,
      );
    }
  }

  /// iOS specific: Present code redemption sheet
  @override
  Future<void> presentCodeRedemptionSheetIOS() async {
    if (!_platform.isIOS) {
      throw PlatformException(
        code: 'platform',
        message: 'presentCodeRedemptionSheetIOS is only supported on iOS',
      );
    }

    try {
      await channel.invokeMethod('presentCodeRedemptionSheetIOS');
    } catch (e) {
      throw iap_types.PurchaseError(
        code: iap_types.ErrorCode.eServiceError,
        message: 'Failed to present code redemption sheet: ${e.toString()}',
        platform: _platform.isIOS
            ? iap_types.IapPlatform.ios
            : iap_types.IapPlatform.android,
      );
    }
  }

  /// iOS specific: Show manage subscriptions
  @override
  Future<void> showManageSubscriptionsIOS() async {
    if (!_platform.isIOS) {
      throw PlatformException(
        code: 'platform',
        message: 'showManageSubscriptionsIOS is only supported on iOS',
      );
    }

    try {
      await channel.invokeMethod('showManageSubscriptionsIOS');
    } catch (e) {
      throw iap_types.PurchaseError(
        code: iap_types.ErrorCode.eServiceError,
        message: 'Failed to show manage subscriptions: ${e.toString()}',
        platform: _platform.isIOS
            ? iap_types.IapPlatform.ios
            : iap_types.IapPlatform.android,
      );
    }
  }

  /// Android specific: Deep link to subscriptions
  @override
  @Deprecated('Not part of the unified API. Will be removed in 6.6.0')
  Future<void> deepLinkToSubscriptionsAndroid({String? sku}) async {
    if (!_platform.isAndroid) {
      debugPrint('deepLinkToSubscriptionsAndroid is only supported on Android');
      return;
    }

    try {
      await channel.invokeMethod('manageSubscription', {
        if (sku != null) 'sku': sku,
      });
    } catch (error) {
      debugPrint('Error deep linking to subscriptions: $error');
      rethrow;
    }
  }

  iap_types.ProductCommon _parseProductFromNative(
    Map<String, dynamic> json,
    String type,
  ) {
    // Determine platform from JSON data if available, otherwise use current device
    final platform = json.containsKey('platform')
        ? (json['platform'] == 'android'
            ? iap_types.IapPlatform.android
            : iap_types.IapPlatform.ios)
        : (_platform.isIOS
            ? iap_types.IapPlatform.ios
            : iap_types.IapPlatform.android);

    if (type == iap_types.ProductType.subs) {
      return iap_types.ProductSubscription(
        id: json['id']?.toString() ?? '',
        productId: json['productId']?.toString() ?? '',
        price: json['price']?.toString() ?? '0',
        currency: json['currency']?.toString(),
        localizedPrice: json['localizedPrice']?.toString(),
        title: json['title']?.toString(),
        description: json['description']?.toString(),
        type: json['type']?.toString() ?? iap_types.ProductType.subs,
        platform: platform,
        // iOS fields
        displayName: json['displayName']?.toString(),
        displayPrice: json['displayPrice']?.toString(),
        discountsIOS: _parseDiscountsIOS(json['discounts']),
        subscription: json['subscription'] != null
            ? iap_types.SubscriptionInfo.fromJson(
                Map<String, dynamic>.from(json['subscription'] as Map),
              )
            : json['subscriptionGroupIdIOS'] != null
                ? iap_types.SubscriptionInfo(
                    subscriptionGroupId:
                        json['subscriptionGroupIdIOS']?.toString(),
                  )
                : null,
        subscriptionGroupIdIOS: json['subscriptionGroupIdIOS']?.toString(),
        subscriptionPeriodUnitIOS:
            json['subscriptionPeriodUnitIOS']?.toString(),
        subscriptionPeriodNumberIOS:
            json['subscriptionPeriodNumberIOS']?.toString(),
        introductoryPricePaymentModeIOS:
            json['introductoryPricePaymentModeIOS']?.toString(),
        introductoryPriceNumberOfPeriodsIOS:
            json['introductoryPriceNumberOfPeriodsIOS']?.toString(),
        introductoryPriceSubscriptionPeriodIOS:
            json['introductoryPriceSubscriptionPeriodIOS']?.toString(),
        environmentIOS: json['environmentIOS']?.toString(),
        promotionalOfferIdsIOS: json['promotionalOfferIdsIOS'] != null
            ? (json['promotionalOfferIdsIOS'] as List)
                .map((e) => e.toString())
                .toList()
            : null,
        // OpenIAP compliant iOS fields
        isFamilyShareableIOS: json['isFamilyShareableIOS'] as bool? ??
            (json['isFamilyShareable'] as bool?),
        jsonRepresentationIOS: json['jsonRepresentationIOS']?.toString() ??
            json['jsonRepresentation']?.toString(),
        // Android fields
        nameAndroid: json['nameAndroid']?.toString(),
        oneTimePurchaseOfferDetailsAndroid:
            json['oneTimePurchaseOfferDetailsAndroid'] != null
                ? Map<String, dynamic>.from(
                    json['oneTimePurchaseOfferDetailsAndroid'] as Map,
                  )
                : null,
        originalPrice: json['originalPrice']?.toString(),
        originalPriceAmount: (json['originalPriceAmount'] as num?)?.toDouble(),
        freeTrialPeriod: json['freeTrialPeriod']?.toString(),
        iconUrl: json['iconUrl']?.toString(),
        subscriptionOfferDetailsAndroid: _parseOfferDetails(
          json['subscriptionOfferDetailsAndroid'],
        ),
        subscriptionOffersAndroid: json['subscriptionOffersAndroid'] != null
            ? (json['subscriptionOffersAndroid'] as List)
                .map((item) {
                  final Map<String, dynamic> offer;
                  if (item is Map<String, dynamic>) {
                    offer = item;
                  } else if (item is Map) {
                    offer = Map<String, dynamic>.from(item);
                  } else {
                    return null;
                  }
                  return iap_types.SubscriptionOfferAndroid.fromJson(offer);
                })
                .whereType<iap_types.SubscriptionOfferAndroid>()
                .toList()
            : null,
      );
    } else {
      // For iOS platform, create ProductIOS instance to capture iOS-specific fields
      if (platform == iap_types.IapPlatform.ios) {
        return iap_types.ProductIOS(
          productId:
              json['productId']?.toString() ?? json['id']?.toString() ?? '',
          price: json['price']?.toString() ?? '0',
          currency: json['currency']?.toString(),
          localizedPrice: json['localizedPrice']?.toString(),
          title: json['title']?.toString(),
          description: json['description']?.toString(),
          type: json['type']?.toString() ?? iap_types.ProductType.inapp,
          displayName: json['displayName']?.toString(),
          // OpenIAP compliant iOS fields
          isFamilyShareableIOS: json['isFamilyShareableIOS'] as bool? ??
              (json['isFamilyShareable'] as bool?),
          jsonRepresentationIOS: json['jsonRepresentationIOS']?.toString() ??
              json['jsonRepresentation']?.toString(),
          // Other iOS fields
          discounts: _parseDiscountsIOS(json['discounts']),
          subscriptionGroupIdentifier:
              json['subscriptionGroupIdIOS']?.toString(),
          subscriptionPeriodUnit: json['subscriptionPeriodUnitIOS']?.toString(),
          subscriptionPeriodNumber:
              json['subscriptionPeriodNumberIOS']?.toString(),
          introductoryPricePaymentMode:
              json['introductoryPricePaymentModeIOS']?.toString(),
          introductoryPriceNumberOfPeriodsIOS:
              json['introductoryPriceNumberOfPeriodsIOS']?.toString(),
          introductoryPriceSubscriptionPeriodIOS:
              json['introductoryPriceSubscriptionPeriodIOS']?.toString(),
          environment: json['environmentIOS']?.toString(),
          promotionalOfferIds: json['promotionalOfferIdsIOS'] != null
              ? (json['promotionalOfferIdsIOS'] as List)
                  .map((e) => e.toString())
                  .toList()
              : null,
        );
      } else {
        // For Android platform, create regular Product
        return iap_types.Product(
          id: json['id']?.toString() ?? '',
          productId: json['productId']?.toString() ?? '',
          priceString: json['price']?.toString() ?? '0',
          currency: json['currency']?.toString(),
          localizedPrice: json['localizedPrice']?.toString(),
          title: json['title']?.toString(),
          description: json['description']?.toString(),
          type: json['type']?.toString() ?? iap_types.ProductType.inapp,
          platformEnum: platform,
          // Android fields
          displayName: json['displayName']?.toString(),
          displayPrice: json['displayPrice']?.toString(),
          nameAndroid: json['nameAndroid']?.toString(),
          oneTimePurchaseOfferDetailsAndroid:
              json['oneTimePurchaseOfferDetailsAndroid'] != null
                  ? Map<String, dynamic>.from(
                      json['oneTimePurchaseOfferDetailsAndroid'] as Map,
                    )
                  : null,
          originalPrice: json['originalPrice']?.toString(),
          originalPriceAmount:
              (json['originalPriceAmount'] as num?)?.toDouble(),
          freeTrialPeriod: json['freeTrialPeriod']?.toString(),
          iconUrl: json['iconUrl']?.toString(),
        );
      }
    }
  }

  List<iap_types.DiscountIOS>? _parseDiscountsIOS(dynamic json) {
    if (json == null) return null;
    final list = json as List<dynamic>;
    return list
        .map(
          (e) => iap_types.DiscountIOS.fromJson(
            e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList();
  }

  List<iap_types.OfferDetail>? _parseOfferDetails(dynamic json) {
    if (json == null) return null;

    // Handle both List and String (JSON string from Android)
    List<dynamic> list;
    if (json is String) {
      // Parse JSON string from Android
      try {
        final parsed = jsonDecode(json);
        if (parsed is! List) return null;
        list = parsed;
      } catch (e) {
        return null;
      }
    } else if (json is List) {
      list = json;
    } else {
      return null;
    }

    return list
        .map((item) {
          // Convert Map<Object?, Object?> to Map<String, dynamic>
          final Map<String, dynamic> e;
          if (item is Map<String, dynamic>) {
            e = item;
          } else if (item is Map) {
            e = Map<String, dynamic>.from(item);
          } else {
            // Skip invalid items
            return null;
          }

          return iap_types.OfferDetail(
            offerId: e['offerId'] as String?,
            basePlanId: e['basePlanId'] as String? ?? '',
            offerToken: e['offerToken'] as String?,
            pricingPhases: _parsePricingPhases(e['pricingPhases']) ?? [],
            offerTags: (e['offerTags'] as List<dynamic>?)?.cast<String>(),
          );
        })
        .whereType<iap_types.OfferDetail>()
        .toList();
  }

  List<iap_types.PricingPhase>? _parsePricingPhases(dynamic json) {
    if (json == null) return null;

    // Handle nested structure from Android
    List<dynamic>? list;
    if (json is Map && json['pricingPhaseList'] != null) {
      list = json['pricingPhaseList'] as List<dynamic>?;
    } else if (json is List) {
      list = json;
    } else {
      return null;
    }

    if (list == null) return null;

    return list
        .map((item) {
          // Convert Map<Object?, Object?> to Map<String, dynamic>
          final Map<String, dynamic> e;
          if (item is Map<String, dynamic>) {
            e = item;
          } else if (item is Map) {
            e = Map<String, dynamic>.from(item);
          } else {
            // Skip invalid items
            return null;
          }

          // Handle priceAmountMicros as either String or num and scale to currency units
          final priceAmountMicros = e['priceAmountMicros'];
          double priceAmount = 0.0;
          if (priceAmountMicros != null) {
            final double micros = priceAmountMicros is num
                ? priceAmountMicros.toDouble()
                : (priceAmountMicros is String
                    ? double.tryParse(priceAmountMicros) ?? 0.0
                    : 0.0);
            priceAmount =
                micros / 1000000.0; // Convert micros to currency units
          }

          // Map recurrenceMode if present (BillingClient: 1=infinite, 2=finite, 3=non-recurring)
          iap_types.RecurrenceMode? recurrenceMode;
          final rm = e['recurrenceMode'];
          if (rm is int) {
            switch (rm) {
              case 1:
                recurrenceMode = iap_types.RecurrenceMode.infiniteRecurring;
                break;
              case 2:
                recurrenceMode = iap_types.RecurrenceMode.finiteRecurring;
                break;
              case 3:
                recurrenceMode = iap_types.RecurrenceMode.nonRecurring;
                break;
            }
          }

          return iap_types.PricingPhase(
            priceAmount: priceAmount,
            price: e['formattedPrice'] as String? ?? '0',
            currency: e['priceCurrencyCode'] as String? ?? 'USD',
            billingPeriod: e['billingPeriod'] as String?,
            billingCycleCount: e['billingCycleCount'] as int?,
            recurrenceMode: recurrenceMode,
          );
        })
        .whereType<iap_types.PricingPhase>()
        .toList();
  }

  iap_types.PurchaseState _mapAndroidPurchaseState(int stateValue) {
    final state = AndroidPurchaseState.fromValue(stateValue);
    switch (state) {
      case AndroidPurchaseState.purchased:
        return iap_types.PurchaseState.purchased;
      case AndroidPurchaseState.pending:
        return iap_types.PurchaseState.pending;
      case AndroidPurchaseState.unspecified:
        return iap_types.PurchaseState.unspecified;
    }
  }

  iap_types.Purchase _convertFromLegacyPurchase(
    Map<String, dynamic> itemJson, [
    Map<String, dynamic>? originalJson,
  ]) {
    // Map iOS transaction state string to enum
    iap_types.TransactionState? transactionStateIOS;
    final transactionStateIOSValue = itemJson['transactionStateIOS'];
    if (transactionStateIOSValue != null) {
      switch (transactionStateIOSValue) {
        case '0':
        case 'purchasing':
          transactionStateIOS = iap_types.TransactionState.purchasing;
          break;
        case '1':
        case 'purchased':
          transactionStateIOS = iap_types.TransactionState.purchased;
          break;
        case '2':
        case 'failed':
          transactionStateIOS = iap_types.TransactionState.failed;
          break;
        case '3':
        case 'restored':
          transactionStateIOS = iap_types.TransactionState.restored;
          break;
        case '4':
        case 'deferred':
          transactionStateIOS = iap_types.TransactionState.deferred;
          break;
      }
    }

    // Convert transactionDate to timestamp (milliseconds)
    int? transactionDateTimestamp;
    final transactionDateValue = itemJson['transactionDate'];
    if (transactionDateValue != null) {
      if (transactionDateValue is num) {
        transactionDateTimestamp = transactionDateValue.toInt();
      } else if (transactionDateValue is String) {
        final date = DateTime.tryParse(transactionDateValue);
        transactionDateTimestamp = date?.millisecondsSinceEpoch;
      }
    }

    // Parse original transaction date for iOS to integer timestamp
    int? originalTransactionDateIOS;
    final originalTransactionDateIOSValue =
        itemJson['originalTransactionDateIOS'];
    if (originalTransactionDateIOSValue != null) {
      try {
        // Try parsing as ISO string first
        final date = DateTime.tryParse(
          originalTransactionDateIOSValue.toString(),
        );
        if (date != null) {
          originalTransactionDateIOS = date.millisecondsSinceEpoch;
        } else {
          // Try parsing as number string
          originalTransactionDateIOS = int.tryParse(
            originalTransactionDateIOSValue.toString(),
          );
        }
      } catch (e) {
        // Try parsing as number string
        originalTransactionDateIOS = int.tryParse(
          originalTransactionDateIOSValue.toString(),
        );
      }
    }

    // Convert transactionId to string
    final convertedTransactionId =
        itemJson['id']?.toString() ?? itemJson['transactionId']?.toString();

    return iap_types.Purchase(
      productId: itemJson['productId']?.toString() ?? '',
      // Convert transactionId to string for OpenIAP compliance
      // The id getter will return transactionId (OpenIAP compliant)
      transactionId: convertedTransactionId,
      transactionReceipt: itemJson['transactionReceipt']?.toString(),
      purchaseToken: itemJson['purchaseToken']?.toString(),
      // Use timestamp integer for OpenIAP compliance
      transactionDate: transactionDateTimestamp,
      platform: _platform.isIOS
          ? iap_types.IapPlatform.ios
          : iap_types.IapPlatform.android,
      // iOS specific fields
      transactionStateIOS: _platform.isIOS ? transactionStateIOS : null,
      originalTransactionIdentifierIOS: _platform.isIOS
          ? itemJson['originalTransactionIdentifierIOS']?.toString()
          : null,
      originalTransactionDateIOS:
          _platform.isIOS ? originalTransactionDateIOS?.toString() : null,
      quantityIOS:
          _platform.isIOS ? (originalJson?['quantityIOS'] as int? ?? 1) : null,
      // Additional iOS subscription fields from originalJson
      environmentIOS:
          _platform.isIOS ? (originalJson?['environmentIOS'] as String?) : null,
      expirationDateIOS:
          _platform.isIOS && originalJson?['expirationDateIOS'] != null
              ? DateTime.fromMillisecondsSinceEpoch(
                  (originalJson!['expirationDateIOS'] as num).toInt(),
                )
              : null,
      subscriptionGroupIdIOS: _platform.isIOS
          ? (originalJson?['subscriptionGroupIdIOS'] as String?)
          : null,
      productTypeIOS:
          _platform.isIOS ? (originalJson?['productTypeIOS'] as String?) : null,
      transactionReasonIOS:
          _platform.isIOS ? (originalJson?['reasonIOS'] as String?) : null,
      currencyCodeIOS:
          _platform.isIOS ? (originalJson?['currencyIOS'] as String?) : null,
      storeFrontCountryCodeIOS: _platform.isIOS
          ? (originalJson?['storefrontCountryCodeIOS'] as String?)
          : null,
      appBundleIdIOS:
          _platform.isIOS ? (originalJson?['appBundleIdIOS'] as String?) : null,
      isUpgradedIOS:
          _platform.isIOS ? (originalJson?['isUpgradedIOS'] as bool?) : null,
      ownershipTypeIOS: _platform.isIOS
          ? (originalJson?['ownershipTypeIOS'] as String?)
          : null,
      reasonIOS:
          _platform.isIOS ? (originalJson?['reasonIOS'] as String?) : null,
      webOrderLineItemIdIOS: _platform.isIOS
          ? (originalJson?['webOrderLineItemIdIOS'] as String?)
          : null,
      offerIOS: _platform.isIOS && originalJson?['offerIOS'] != null
          ? (originalJson!['offerIOS'] is Map<String, dynamic>
              ? originalJson['offerIOS'] as Map<String, dynamic>
              : Map<String, dynamic>.from(originalJson['offerIOS'] as Map))
          : null,
      priceIOS: _platform.isIOS && originalJson?['priceIOS'] != null
          ? (originalJson!['priceIOS'] as num).toDouble()
          : null,
      revocationDateIOS:
          _platform.isIOS && originalJson?['revocationDateIOS'] != null
              ? DateTime.fromMillisecondsSinceEpoch(
                  (originalJson!['revocationDateIOS'] as num).toInt(),
                )
              : null,
      revocationReasonIOS: _platform.isIOS
          ? (originalJson?['revocationReasonIOS'] as String?)
          : null,
      // Android specific fields
      isAcknowledgedAndroid: _platform.isAndroid
          ? itemJson['isAcknowledgedAndroid'] as bool?
          : null,
      purchaseState:
          _platform.isAndroid && itemJson['purchaseStateAndroid'] != null
              ? _mapAndroidPurchaseState(
                  itemJson['purchaseStateAndroid'] as int,
                )
              : null,
      purchaseStateAndroid:
          _platform.isAndroid ? itemJson['purchaseStateAndroid'] as int? : null,
      originalJson: _platform.isAndroid
          ? itemJson['originalJsonAndroid']?.toString()
          : null,
      dataAndroid: _platform.isAndroid
          ? itemJson['originalJsonAndroid']?.toString()
          : null,
      signatureAndroid:
          _platform.isAndroid ? itemJson['signatureAndroid']?.toString() : null,
      packageNameAndroid: _platform.isAndroid
          ? itemJson['packageNameAndroid']?.toString()
          : null,
      autoRenewingAndroid:
          _platform.isAndroid ? itemJson['autoRenewingAndroid'] as bool? : null,
      developerPayloadAndroid: _platform.isAndroid
          ? itemJson['developerPayloadAndroid']?.toString()
          : null,
      orderIdAndroid:
          _platform.isAndroid ? itemJson['orderId']?.toString() : null,
      obfuscatedAccountIdAndroid: _platform.isAndroid
          ? (originalJson?['obfuscatedAccountIdAndroid'] as String?)
          : null,
      obfuscatedProfileIdAndroid: _platform.isAndroid
          ? (originalJson?['obfuscatedProfileIdAndroid'] as String?)
          : null,
    );
  }

  iap_types.PurchaseError _convertToPurchaseError(
    iap_types.PurchaseResult result,
  ) {
    iap_types.ErrorCode code = iap_types.ErrorCode.eUnknown;

    // Prefer OpenIAP string codes when present (works cross-platform)
    if (result.code != null && result.code!.isNotEmpty) {
      final detected = iap_err.ErrorCodeUtils.fromPlatformCode(
        result.code!,
        _platform.isIOS ? IapPlatform.ios : IapPlatform.android,
      );
      if (detected != iap_types.ErrorCode.eUnknown) {
        code = detected;
      }
    }

    // Map error codes
    // Fallback to legacy numeric response codes when string code is absent
    if (code == iap_types.ErrorCode.eUnknown) {
      switch (result.responseCode) {
        case 0:
          code = iap_types.ErrorCode.eUnknown;
          break;
        case 1:
          code = iap_types.ErrorCode.eUserCancelled;
          break;
        case 2:
          code = iap_types.ErrorCode.eServiceError;
          break;
        case 3:
          code = iap_types.ErrorCode.eBillingUnavailable;
          break;
        case 4:
          code = iap_types.ErrorCode.eItemUnavailable;
          break;
        case 5:
          code = iap_types.ErrorCode.eDeveloperError;
          break;
        case 6:
          code = iap_types.ErrorCode.eUnknown;
          break;
        case 7:
          code = iap_types.ErrorCode.eProductAlreadyOwned;
          break;
        case 8:
          code = iap_types.ErrorCode.ePurchaseNotAllowed;
          break;
      }
    }

    return iap_types.PurchaseError(
      code: code,
      message: result.message ?? 'Unknown error',
      debugMessage: result.debugMessage,
      platform: _platform.isIOS
          ? iap_types.IapPlatform.ios
          : iap_types.IapPlatform.android,
    );
  }

  // Original API methods (with deprecation annotations where needed)

  @Deprecated('Not part of the unified API. Will be removed in 6.6.0')
  Future<bool> isReady() async {
    if (_platform.isAndroid) {
      return (await _channel.invokeMethod<bool?>('isReady')) ?? false;
    }
    if (_platform.isIOS) {
      return Future.value(true);
    }
    throw PlatformException(
      code: _platform.operatingSystem,
      message: 'platform not supported',
    );
  }

  @Deprecated('Not part of the unified API. Will be removed in 6.6.0')
  Future<Store> getStore() async {
    if (_platform.isIOS) {
      return Future.value(Store.appStore);
    }
    if (_platform.isAndroid) {
      final store = await _channel.invokeMethod<String?>('getStore');
      if (store == 'play_store') return Store.playStore;
      if (store == 'amazon') return Store.amazon;
      return Store.none;
    }
    return Future.value(Store.none);
  }

  /// Request a subscription
  ///
  /// For NEW subscriptions:
  /// - Simply call with productId
  /// - Do NOT set replacementModeAndroid (or set it to -1)
  ///
  /// For UPGRADING/DOWNGRADING existing subscriptions (Android only):
  /// - Set replacementModeAndroid to desired mode (1-5)
  /// - MUST provide purchaseTokenAndroid from the existing subscription
  /// - Get the token using getAvailablePurchases()
  ///
  /// Example for new subscription:
  /// ```dart
  /// await requestSubscription('premium_monthly');
  /// ```
  ///
  /// Example for upgrade with proration:
  /// ```dart
  /// final purchases = await getAvailablePurchases();
  /// final existingSub = purchases.firstWhere((p) => p.productId == 'basic_monthly');
  /// await requestSubscription(
  ///   'premium_monthly',
  ///   replacementModeAndroid: AndroidReplacementMode.withTimeProration.value,
  ///   purchaseTokenAndroid: existingSub.purchaseToken,
  /// );
  /// ```
  @Deprecated('Use requestPurchase() instead. Will be removed in 6.6.0')
  Future<dynamic> requestSubscription(
    String productId, {
    int? replacementModeAndroid,
    String? obfuscatedAccountIdAndroid,
    String? obfuscatedProfileIdAndroid,
    String? purchaseTokenAndroid,
    int? offerTokenIndex,
  }) async {
    if (_platform.isAndroid) {
      final int? effectiveReplacementMode = replacementModeAndroid;

      // Validate that purchaseToken is provided when using replacement mode
      // Replacement mode -1 means no replacement (new subscription)
      if (effectiveReplacementMode != null &&
          effectiveReplacementMode != -1 &&
          (purchaseTokenAndroid == null || purchaseTokenAndroid.isEmpty)) {
        throw iap_types.PurchaseError(
          code: iap_types.ErrorCode.eDeveloperError,
          message:
              'purchaseTokenAndroid is required when using replacement mode (replacementModeAndroid: $effectiveReplacementMode). '
              'Replacement modes are only for upgrading/downgrading EXISTING subscriptions. '
              'For NEW subscriptions, do not set replacementModeAndroid or set it to -1. '
              'To upgrade/downgrade, provide the purchaseToken from getAvailablePurchases().',
          platform: iap_types.IapPlatform.android,
        );
      }

      return await _channel.invokeMethod('buyItemByType', <String, dynamic>{
        'type': TypeInApp.subs.name,
        'productId': productId,
        'replacementMode': effectiveReplacementMode ?? -1,
        'obfuscatedAccountId': obfuscatedAccountIdAndroid,
        'obfuscatedProfileId': obfuscatedProfileIdAndroid,
        'purchaseToken': purchaseTokenAndroid,
        'offerTokenIndex': offerTokenIndex,
      });
    } else if (_platform.isIOS) {
      return await _channel.invokeMethod('requestPurchase', <String, dynamic>{
        'sku': productId,
      });
    }
    throw PlatformException(
      code: _platform.operatingSystem,
      message: 'platform not supported',
    );
  }

  Future<List<iap_types.Purchase>?> getPendingTransactionsIOS() async {
    if (_platform.isIOS) {
      dynamic result = await _channel.invokeMethod('getPendingTransactionsIOS');

      return extractPurchases(json.encode(result));
    }
    return [];
  }

  @override
  Future<bool> consumePurchaseAndroid({required String purchaseToken}) async {
    if (!_platform.isAndroid) {
      return false;
    }

    try {
      final result = await channel.invokeMethod<bool>('consumePurchase', {
        'purchaseToken': purchaseToken,
      });
      return result ?? false;
    } catch (error) {
      debugPrint('Error consuming purchase: $error');
      return false;
    }
  }

  /// End connection
  @Deprecated('Use endConnection() instead. Will be removed in 6.6.0')
  Future<String?> finalize() async {
    if (_platform.isAndroid) {
    } else if (_platform.isIOS) {
      final String? result = await _channel.invokeMethod('endConnection');
      _removePurchaseListener();
      return result;
    }
    throw PlatformException(
      code: _platform.operatingSystem,
      message: 'platform not supported',
    );
  }

  /// Finish a transaction using Purchase object (OpenIAP compliant)
  Future<void> finishTransaction(
    iap_types.Purchase purchase, {
    bool isConsumable = false,
  }) async {
    // Use purchase.id (OpenIAP standard) if available, fallback to transactionId for backward compatibility
    final transactionId =
        purchase.id.isNotEmpty ? purchase.id : purchase.transactionId;

    if (_platform.isAndroid) {
      if (isConsumable) {
        debugPrint(
          '[FlutterInappPurchase] Android: Consuming product with token: ${purchase.purchaseToken}',
        );
        final result = await _channel.invokeMethod(
          'consumeProduct',
          <String, dynamic>{'purchaseToken': purchase.purchaseToken},
        );
        parseAndLogAndroidResponse(
          result,
          successLog:
              '[FlutterInappPurchase] Android: Product consumed successfully',
          failureLog:
              '[FlutterInappPurchase] Android: Failed to parse consume response',
        );
        return;
      } else {
        if (purchase.isAcknowledgedAndroid == true) {
          if (kDebugMode) {
            debugPrint(
              '[FlutterInappPurchase] Android: Purchase already acknowledged',
            );
          }
          return;
        } else {
          if (kDebugMode) {
            final maskedToken = (purchase.purchaseToken ?? '').replaceAllMapped(
              RegExp(r'.(?=.{4})'),
              (m) => '*',
            );
            debugPrint(
              '[FlutterInappPurchase] Android: Acknowledging purchase with token: $maskedToken',
            );
          }
          final result = await _channel.invokeMethod(
            'acknowledgePurchase',
            <String, dynamic>{'purchaseToken': purchase.purchaseToken},
          );
          parseAndLogAndroidResponse(
            result,
            successLog:
                '[FlutterInappPurchase] Android: Purchase acknowledged successfully',
            failureLog:
                '[FlutterInappPurchase] Android: Failed to parse acknowledge response',
          );
          return;
        }
      }
    } else if (_platform.isIOS) {
      debugPrint(
        '[FlutterInappPurchase] iOS: Finishing transaction with ID: $transactionId',
      );
      await _channel.invokeMethod('finishTransaction', <String, dynamic>{
        'transactionId': transactionId, // Use OpenIAP compliant id
      });
      return;
    }
    throw PlatformException(
      code: _platform.operatingSystem,
      message: 'platform not supported',
    );
  }

  /// Finish a transaction using PurchasedItem object (legacy compatibility)
  /// @deprecated Use finishTransaction with Purchase object instead
  Future<void> finishTransactionIOS(
    Map<String, dynamic> purchasedItemJson, {
    bool isConsumable = false,
  }) async {
    // Convert legacy JSON to Purchase for modern API
    final purchase = _convertFromLegacyPurchase(purchasedItemJson);
    await finishTransaction(purchase, isConsumable: isConsumable);
  }

  /// Validate receipt in iOS (deprecated - use validateReceiptIOS instead)
  ///
  /// This method uses the legacy Apple verification endpoints which are being phased out.
  /// Please migrate to validateReceiptIOS which uses StoreKit 2 on-device validation.
  @Deprecated(
    'Use validateReceiptIOS for StoreKit 2 on-device validation. '
    'Server-side verifyReceipt remains supported by Apple but is legacy in this plugin. '
    'Will be removed in 6.6.0',
  )
  Future<http.Response> validateReceiptIos({
    required Map<String, String> receiptBody,
    bool isTest = true,
  }) async {
    final String url = isTest
        ? 'https://sandbox.itunes.apple.com/verifyReceipt'
        : 'https://buy.itunes.apple.com/verifyReceipt';
    return await _client.post(
      Uri.parse(url),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: json.encode(receiptBody),
    );
  }

  /// Validate receipt using StoreKit 2 (iOS only) - LOCAL TESTING ONLY
  ///
  /// ⚠️ WARNING: This performs LOCAL validation for TESTING purposes.
  /// For production, send the JWS representation to your server for validation.
  ///
  /// What this method does:
  /// 1. Performs local on-device validation (for testing)
  /// 2. Returns JWS representation (send this to your server)
  /// 3. Provides transaction details for debugging
  ///
  /// Server-side validation guide:
  /// 1. Send `result.jwsRepresentation` to your server
  /// 2. Verify the JWS using Apple's public keys
  /// 3. Decode and validate the transaction on your server
  /// 4. Grant entitlements based on server validation
  ///
  /// Example for LOCAL TESTING:
  /// ```dart
  /// // Step 1: Local validation (testing only)
  /// final result = await FlutterInappPurchase.instance.validateReceiptIOS(
  ///   sku: 'com.example.premium',
  /// );
  ///
  /// if (result.isValid) {
  ///   print('✅ Local validation passed (TEST ONLY)');
  ///
  ///   // Step 2: Send to your server for PRODUCTION validation
  ///   final serverPayload = {
  ///     'purchaseToken': result.purchaseToken,  // Unified field (JWS for iOS)
  ///     'productId': 'com.example.premium',
  ///   };
  ///
  ///   // await yourApi.validateOnServer(serverPayload);
  ///   print('📤 Send purchaseToken to your server for production validation');
  /// }
  /// ```
  ///
  /// Note: This method requires iOS 15.0+ for StoreKit 2 support.
  /// For older iOS versions, the method will return an error.
  Future<iap_types.ReceiptValidationResult> validateReceiptIOS({
    required String sku,
  }) async {
    if (!_platform.isIOS) {
      return iap_types.ReceiptValidationResult(
        isValid: false,
        errorMessage: 'Receipt validation is only available on iOS',
        platform: iap_types.IapPlatform.ios,
      );
    }

    if (!_isInitialized) {
      return iap_types.ReceiptValidationResult(
        isValid: false,
        errorMessage: 'IAP connection not initialized',
        platform: iap_types.IapPlatform.ios,
      );
    }

    if (sku.trim().isEmpty) {
      return iap_types.ReceiptValidationResult(
        isValid: false,
        errorMessage: 'sku cannot be empty',
        platform: iap_types.IapPlatform.ios,
      );
    }

    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'validateReceiptIOS',
        {'sku': sku}, // iOS only needs the SKU
      );

      if (result == null) {
        return iap_types.ReceiptValidationResult(
          isValid: false,
          errorMessage: 'No validation result received from native platform',
          platform: iap_types.IapPlatform.ios, // This is iOS validation
        );
      }

      // Convert Map<dynamic, dynamic> to Map<String, dynamic>
      final Map<String, dynamic> validationResult = Map<String, dynamic>.from(
        result,
      );

      // Parse latestTransaction if present
      Map<String, dynamic>? latestTransaction;
      if (validationResult['latestTransaction'] != null) {
        latestTransaction = Map<String, dynamic>.from(
          validationResult['latestTransaction'] as Map,
        );
      }

      return iap_types.ReceiptValidationResult(
        isValid: validationResult['isValid'] as bool? ?? false,
        errorMessage: validationResult['errorMessage'] as String?,
        receiptData: validationResult['receiptData'] as String?,
        purchaseToken:
            validationResult['purchaseToken'] as String?, // Unified field
        jwsRepresentation: validationResult['jwsRepresentation']
            as String?, // Deprecated, for backward compatibility
        latestTransaction: latestTransaction,
        rawResponse: validationResult,
        platform: iap_types.IapPlatform.ios,
      );
    } on PlatformException catch (e) {
      return iap_types.ReceiptValidationResult(
        isValid: false,
        errorMessage:
            'Failed to validate receipt [${e.code}]: ${e.message ?? e.details}',
        platform: iap_err.getCurrentPlatform(),
      );
    } catch (e) {
      return iap_types.ReceiptValidationResult(
        isValid: false,
        errorMessage: 'Failed to validate receipt: ${e.toString()}',
        platform: iap_err.getCurrentPlatform(),
      );
    }
  }

  /// Validate receipt (OpenIAP compliant) - LOCAL TESTING ONLY
  ///
  /// ⚠️ WARNING: This is for LOCAL TESTING and DEVELOPMENT only!
  /// For production, implement server-side validation.
  ///
  /// iOS: Local StoreKit 2 validation (iOS 15.0+)
  /// - Returns JWS representation → Send to your server
  /// - Local validation for testing only
  ///
  /// Android: Google Play Developer API
  /// - ⚠️ NEVER include access token in production apps
  /// - For production: Send purchase token to your server
  /// - Server validates with Google Play API
  ///
  /// Example iOS (LOCAL TEST):
  /// ```dart
  /// // Local validation for testing
  /// final result = await FlutterInappPurchase.instance.validateReceipt(
  ///   options: ReceiptValidationProps(
  ///     sku: 'com.example.premium',
  ///   ),
  /// );
  ///
  /// // For production: Send to server
  /// if (result.isValid) {
  ///   await yourServer.validate(result.purchaseToken);  // Unified field
  /// }
  /// ```
  ///
  /// Example Android (LOCAL TEST - NEVER USE IN PRODUCTION):
  /// ```dart
  /// // ⚠️ LOCAL TESTING ONLY - Access token exposed!
  /// final result = await FlutterInappPurchase.instance.validateReceipt(
  ///   options: ReceiptValidationProps(
  ///     sku: 'com.example.premium',
  ///     androidOptions: AndroidValidationOptions(
  ///       packageName: 'com.example.app',
  ///       productToken: purchaseToken,
  ///       accessToken: debugAccessToken, // ⚠️ NEVER in production!
  ///       isSub: false,
  ///     ),
  ///   ),
  /// );
  ///
  /// - For PRODUCTION: Send to your server
  /// - await yourServer.validateAndroid(purchaseToken);
  /// ```
  Future<iap_types.ReceiptValidationResult> validateReceipt({
    required iap_types.ReceiptValidationProps options,
  }) async {
    // Route to platform-specific implementation
    if (_platform.isIOS) {
      return validateReceiptIOS(sku: options.sku);
    } else if (_platform.isAndroid) {
      return _validateReceiptAndroid(options: options);
    } else {
      return iap_types.ReceiptValidationResult(
        isValid: false,
        errorMessage: 'Platform not supported for receipt validation',
        platform: null, // Unknown/unsupported platform
      );
    }
  }

  /// Internal Android validation implementation
  Future<iap_types.ReceiptValidationResult> _validateReceiptAndroid({
    required iap_types.ReceiptValidationProps options,
  }) async {
    if (!_platform.isAndroid) {
      return iap_types.ReceiptValidationResult(
        isValid: false,
        errorMessage: 'Receipt validation is only available on Android',
        platform: iap_types.IapPlatform.android,
      );
    }

    // Extract Android-specific options
    final androidOptions = options.androidOptions;
    if (androidOptions == null) {
      return iap_types.ReceiptValidationResult(
        isValid: false,
        errorMessage: 'Android options required for Android validation',
        platform: iap_types.IapPlatform.android,
      );
    }

    final packageName = androidOptions.packageName;
    final productToken = androidOptions.productToken;
    final accessToken = androidOptions.accessToken;
    final isSub = androidOptions.isSub;

    if (packageName.isEmpty || productToken.isEmpty || accessToken.isEmpty) {
      return iap_types.ReceiptValidationResult(
        isValid: false,
        errorMessage:
            'Invalid parameters: packageName, productToken, and accessToken cannot be empty',
        platform: iap_types.IapPlatform.android,
      );
    }

    try {
      final type = isSub ? 'subscriptions' : 'products';
      final url =
          'https://androidpublisher.googleapis.com/androidpublisher/v3/applications'
          '/$packageName/purchases/$type/${options.sku}'
          '/tokens/$productToken';

      final response = await _client.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body) as Map<String, dynamic>;

        bool isValid;
        if (isSub) {
          // Active if not canceled and not expired
          final expiryRaw = responseData['expiryTimeMillis'];
          final cancelReason = responseData['cancelReason'];
          final expiryMs = expiryRaw is String
              ? int.tryParse(expiryRaw)
              : (expiryRaw is num ? expiryRaw.toInt() : null);
          final nowMs = DateTime.now().millisecondsSinceEpoch;
          isValid = (expiryMs != null && expiryMs > nowMs) &&
              (cancelReason == null || cancelReason == 0);
        } else {
          // One-time products: 0 = Purchased, 1 = Canceled
          final purchaseState = responseData['purchaseState'] as int?;
          isValid = purchaseState == 0;
        }

        return iap_types.ReceiptValidationResult(
          isValid: isValid,
          errorMessage: isValid ? null : 'Purchase is not active/valid',
          rawResponse: responseData,
          platform: iap_err.getCurrentPlatform(),
        );
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        return iap_types.ReceiptValidationResult(
          isValid: false,
          errorMessage: 'Unauthorized/forbidden (check access token/scopes)',
          platform: iap_err.getCurrentPlatform(),
        );
      } else if (response.statusCode == 404) {
        return iap_types.ReceiptValidationResult(
          isValid: false,
          errorMessage: 'Token or SKU not found',
          platform: iap_err.getCurrentPlatform(),
        );
      } else {
        return iap_types.ReceiptValidationResult(
          isValid: false,
          errorMessage:
              'API returned status ${response.statusCode}: ${response.body}',
          platform: iap_err.getCurrentPlatform(),
        );
      }
    } on TimeoutException {
      return iap_types.ReceiptValidationResult(
        isValid: false,
        errorMessage: 'Request to Google Play API timed out',
        platform: iap_err.getCurrentPlatform(),
      );
    } catch (e) {
      return iap_types.ReceiptValidationResult(
        isValid: false,
        errorMessage: 'Failed to validate receipt: ${e.toString()}',
        platform: iap_err.getCurrentPlatform(),
      );
    }
  }

  Future<void> _setPurchaseListener() async {
    _purchaseController ??= StreamController.broadcast();
    _purchaseErrorController ??= StreamController.broadcast();
    _connectionController ??= StreamController.broadcast();
    _purchasePromotedController ??= StreamController.broadcast();

    _channel.setMethodCallHandler((MethodCall call) async {
      switch (call.method) {
        case 'purchase-updated':
          try {
            Map<String, dynamic> result =
                jsonDecode(call.arguments as String) as Map<String, dynamic>;

            // Convert directly to Purchase without intermediate PurchasedItem
            final purchase = _convertFromLegacyPurchase(result, result);

            _purchaseController!.add(purchase);
            _purchaseUpdatedListener.add(purchase);
          } catch (e, stackTrace) {
            debugPrint(
              '[flutter_inapp_purchase] ERROR in purchase-updated: $e',
            );
            debugPrint('[flutter_inapp_purchase] Stack trace: $stackTrace');
          }
          break;
        case 'purchase-error':
          debugPrint(
            '[flutter_inapp_purchase] Processing purchase-error event',
          );
          Map<String, dynamic> result =
              jsonDecode(call.arguments as String) as Map<String, dynamic>;
          iap_types.PurchaseResult purchaseResult =
              iap_types.PurchaseResult.fromJSON(result);
          _purchaseErrorController!.add(purchaseResult);
          // Also emit to Open IAP compatible stream
          final error = _convertToPurchaseError(purchaseResult);
          debugPrint(
            '[flutter_inapp_purchase] Emitting error to purchaseErrorListener: $error',
          );
          _purchaseErrorListener.add(error);
          break;
        case 'connection-updated':
          Map<String, dynamic> result =
              jsonDecode(call.arguments as String) as Map<String, dynamic>;
          _connectionController!.add(
            iap_types.ConnectionResult.fromJSON(result),
          );
          break;
        case 'iap-promoted-product':
          String? productId = call.arguments as String?;
          _purchasePromotedController!.add(productId);
          break;
        case 'on-in-app-message':
          final int code = call.arguments as int;
          _onInAppMessageController?.add(code);
          break;
        default:
          throw ArgumentError('Unknown method ${call.method}');
      }
      return Future.value(null);
    });
  }

  Future<dynamic> _removePurchaseListener() async {
    _purchaseController
      ?..add(null)
      ..close();
    _purchaseController = null;

    _purchaseErrorController
      ?..add(null)
      ..close();
    _purchaseErrorController = null;
  }

  // flutter IAP compatible methods

  /// OpenIAP: fetch products or subscriptions
  Future<List<T>> fetchProducts<T extends iap_types.ProductCommon>({
    required List<String> skus,
    String type = iap_types.ProductType.inapp,
  }) async {
    if (!_isInitialized) {
      throw iap_types.PurchaseError(
        code: iap_types.ErrorCode.eNotInitialized,
        message: 'IAP connection not initialized',
        platform: _platform.isIOS
            ? iap_types.IapPlatform.ios
            : iap_types.IapPlatform.android,
      );
    }

    try {
      debugPrint(
          '[flutter_inapp_purchase] fetchProducts called with skus: $skus, type: $type');

      // Get raw data from native platform
      final List<dynamic> merged = [];
      if (_platform.isIOS) {
        // iOS supports 'all' at native layer
        final raw = await _channel.invokeMethod('fetchProducts', {
          'skus': skus,
          'type': type,
        });
        if (raw is String) {
          merged.addAll(jsonDecode(raw) as List<dynamic>? ?? []);
        } else if (raw is List) {
          merged.addAll(raw);
        }
      } else {
        // Android: handle 'all' by fetching both types
        Future<dynamic> fetchInapp() => _channel.invokeMethod('getProducts', {
              'productIds': skus,
            });
        Future<dynamic> fetchSubs() =>
            _channel.invokeMethod('getSubscriptions', {
              'productIds': skus,
            });

        if (type == 'all') {
          final results = await Future.wait([fetchInapp(), fetchSubs()]);
          for (final raw in results) {
            if (raw is String) {
              merged.addAll(jsonDecode(raw) as List<dynamic>? ?? []);
            } else if (raw is List) {
              merged.addAll(raw);
            }
          }
        } else if (type == iap_types.ProductType.inapp) {
          final raw = await fetchInapp();
          if (raw is String) {
            merged.addAll(jsonDecode(raw) as List<dynamic>? ?? []);
          } else if (raw is List) {
            merged.addAll(raw);
          }
        } else {
          final raw = await fetchSubs();
          if (raw is String) {
            merged.addAll(jsonDecode(raw) as List<dynamic>? ?? []);
          } else if (raw is List) {
            merged.addAll(raw);
          }
        }
      }

      final result = merged;

      debugPrint(
        '[flutter_inapp_purchase] Received ${result.length} items from native',
      );

      // Convert directly to Product/Subscription without intermediate IapItem
      final products = result.map((item) {
        // Handle different Map types from iOS and Android
        final Map<String, dynamic> itemMap;
        if (item is Map<String, dynamic>) {
          itemMap = item;
        } else if (item is Map) {
          // Convert Map<Object?, Object?> to Map<String, dynamic>
          itemMap = Map<String, dynamic>.from(item);
        } else {
          throw Exception('Unexpected item type: ${item.runtimeType}');
        }
        // When 'all', native item contains its own type; pass through using detected type
        final detectedType = (type == 'all')
            ? (itemMap['type']?.toString() ?? iap_types.ProductType.inapp)
            : type;
        return _parseProductFromNative(itemMap, detectedType);
      }).toList();

      // Cast to the expected type
      return products.cast<T>();
    } catch (e) {
      throw iap_types.PurchaseError(
        code: iap_types.ErrorCode.eServiceError,
        message: 'Failed to fetch products: ${e.toString()}',
        platform: _platform.isIOS
            ? iap_types.IapPlatform.ios
            : iap_types.IapPlatform.android,
      );
    }
  }

  /// flutter IAP compatible purchase method — DEPRECATED
  @Deprecated('Removed in 6.6.0. Use requestPurchase() instead.')
  Future<void> purchaseAsync(String productId) async => throw UnsupportedError(
        'purchaseAsync() was removed in 6.6.0. Use requestPurchase() instead.',
      );

  // finishTransactionAsync removed in favor of finishTransaction(Purchase).

  // MARK: - StoreKit 2 specific methods

  /// Restore completed transactions (cross-platform behavior)
  ///
  /// iOS: perform a lightweight sync to refresh transactions and ignore sync errors.
  /// Then, fetch available purchases to surface restored items to the app.
  /// Android: simply fetch available purchases (restoration happens via query).
  Future<void> restorePurchases() async {
    try {
      if (_platform.isIOS) {
        try {
          await syncIOS();
        } catch (error) {
          // Soft-fail on sync error; apps can handle via logs
          debugPrint(
              '[flutter_inapp_purchase] Error restoring purchases (iOS sync): $error');
        }
      }
      // Fetch available purchases using the public API
      await getAvailablePurchases();
    } catch (error) {
      debugPrint(
          '[flutter_inapp_purchase] Failed to restore purchases: $error');
    }
  }

  // presentCodeRedemptionSheet removed; use presentCodeRedemptionSheetIOS()

  // showManageSubscriptions removed; use showManageSubscriptionsIOS() on iOS
  // and deepLinkToSubscriptionsAndroid() on Android.

  // clearTransactionCache removed; use clearTransactionIOS() on iOS.

  /// Get promoted product (App Store promoted purchase)
  /// Returns a map with product information on iOS or null if unavailable.
  @Deprecated('Use getPromotedProductIOS() instead. Will be removed in 6.6.0')
  Future<Map<String, dynamic>?> getPromotedProduct() async {
    if (_platform.isIOS) {
      final result = await _channel.invokeMethod('getPromotedProductIOS');
      if (result == null) return null;
      if (result is Map) return Map<String, dynamic>.from(result);
      // Backward compatibility: if native returns string id, wrap it
      if (result is String) return {'productIdentifier': result};
      return null;
    }
    return null;
  }

  // Removed getAppTransaction(); use getAppTransactionIOS() instead.

  // getAppTransactionTyped removed; use getAppTransactionIOS() and map as needed.

  /// Get all active subscriptions with detailed information (OpenIAP compliant)
  /// Returns an array of active subscriptions. If subscriptionIds is not provided,
  /// returns all active subscriptions. Platform-specific fields are populated based
  /// on the current platform.
  Future<List<iap_types.ActiveSubscription>> getActiveSubscriptions({
    List<String>? subscriptionIds,
  }) async {
    if (!_isInitialized) {
      throw iap_types.PurchaseError(
        code: iap_types.ErrorCode.eNotInitialized,
        message: 'IAP connection not initialized',
        platform: _platform.isIOS
            ? iap_types.IapPlatform.ios
            : iap_types.IapPlatform.android,
      );
    }

    try {
      // Get all available purchases (which includes active subscriptions)
      final purchases = await getAvailablePurchases();

      // Filter to only active subscriptions
      final List<iap_types.ActiveSubscription> activeSubscriptions = [];

      for (final purchase in purchases) {
        // Check if this purchase should be included based on subscriptionIds filter
        if (subscriptionIds != null &&
            !subscriptionIds.contains(purchase.productId)) {
          continue;
        }

        // Check if this is a subscription (typically by checking auto-renewing status)
        // or by checking the purchase against known subscription products
        bool isSubscription = false;
        bool isActive = false;

        if (_platform.isAndroid) {
          // On Android, check if it's auto-renewing
          isSubscription = purchase.autoRenewingAndroid ?? false;
          isActive = isSubscription &&
              (purchase.purchaseState == iap_types.PurchaseState.purchased ||
                  purchase.purchaseState == null); // Allow null for test data
        } else if (_platform.isIOS) {
          // On iOS, we need to check the transaction state and receipt
          // For StoreKit 2, subscriptions should have expiration dates in the receipt
          // For testing, also consider it a subscription if it has iOS in the productId
          isSubscription = purchase.transactionReceipt != null ||
              purchase.productId.contains('sub');
          isActive = (purchase.transactionStateIOS ==
                      iap_types.TransactionState.purchased ||
                  purchase.transactionStateIOS ==
                      iap_types.TransactionState.restored ||
                  purchase.transactionStateIOS == null) &&
              isSubscription;
        }

        if (isSubscription && isActive) {
          // Create ActiveSubscription from Purchase
          activeSubscriptions.add(
            iap_types.ActiveSubscription.fromPurchase(purchase),
          );
        }
      }

      return activeSubscriptions;
    } catch (e) {
      if (e is iap_types.PurchaseError) {
        rethrow;
      }
      throw iap_types.PurchaseError(
        code: iap_types.ErrorCode.eServiceError,
        message: 'Failed to get active subscriptions: ${e.toString()}',
        platform: _platform.isIOS
            ? iap_types.IapPlatform.ios
            : iap_types.IapPlatform.android,
      );
    }
  }

  /// Check if the user has any active subscriptions (OpenIAP compliant)
  /// Returns true if the user has at least one active subscription, false otherwise.
  /// If subscriptionIds is provided, only checks for those specific subscriptions.
  Future<bool> hasActiveSubscriptions({List<String>? subscriptionIds}) async {
    try {
      final activeSubscriptions = await getActiveSubscriptions(
        subscriptionIds: subscriptionIds,
      );
      return activeSubscriptions.isNotEmpty;
    } catch (e) {
      // If there's an error getting subscriptions, return false
      debugPrint('Error checking active subscriptions: $e');
      return false;
    }
  }

  List<iap_types.Purchase>? extractPurchases(dynamic result) {
    // Handle both JSON string and already decoded List
    List<dynamic> list;
    if (result is String) {
      list = json.decode(result) as List<dynamic>;
    } else if (result is List) {
      list = result;
    } else {
      list = json.decode(result.toString()) as List<dynamic>;
    }

    List<iap_types.Purchase>? decoded = list
        .map<iap_types.Purchase>(
          (dynamic product) => _convertFromLegacyPurchase(
            Map<String, dynamic>.from(product as Map),
            Map<String, dynamic>.from(
              product,
            ), // Pass original JSON as well
          ),
        )
        .toList();

    return decoded;
  }
}

List<iap_types.PurchaseResult>? extractResult(dynamic result) {
  // Handle both JSON string and already decoded List
  List<dynamic> list;
  if (result is String) {
    list = json.decode(result) as List<dynamic>;
  } else if (result is List) {
    list = result;
  } else {
    list = json.decode(result.toString()) as List<dynamic>;
  }

  List<iap_types.PurchaseResult>? decoded = list
      .map<iap_types.PurchaseResult>(
        (dynamic product) => iap_types.PurchaseResult.fromJSON(
          Map<String, dynamic>.from(product as Map),
        ),
      )
      .toList();

  return decoded;
}
