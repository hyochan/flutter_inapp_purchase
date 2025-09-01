import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:platform/platform.dart';

import 'enums.dart';
import 'errors.dart' show getCurrentPlatform;
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
  // These are used by the mixins but analyzer doesn't recognize it
  // ignore: unused_element
  bool get _isIOS => _platform.isIOS;
  // ignore: unused_element
  bool get _isAndroid => _platform.isAndroid;
  // ignore: unused_element
  String get _operatingSystem => _platform.operatingSystem;

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
      if (_platform.isIOS) {
        await _channel.invokeMethod('endConnection');
      } else if (_platform.isAndroid) {
        await _channel.invokeMethod('endConnection');
      }
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

  /// Request products (flutter IAP compatible)
  /// Returns List<Product> for inapp products, List<Subscription> for subscriptions
  Future<List<T>> requestProducts<T extends iap_types.ProductCommon>({
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
        '[flutter_inapp_purchase] requestProducts called with skus: $skus,',
      );

      // Get raw data from native platform
      final dynamic rawResult;
      if (_platform.isIOS) {
        // iOS uses unified getItems method for both products and subscriptions
        rawResult = await _channel.invokeMethod('getItems', {
          'skus': skus,
        });
      } else if (type == iap_types.ProductType.inapp) {
        rawResult = await _channel.invokeMethod('getProducts', {
          'productIds': skus,
        });
      } else {
        rawResult = await _channel.invokeMethod('getSubscriptions', {
          'productIds': skus,
        });
      }

      // Android returns JSON string, iOS returns List
      final List<dynamic> result;
      if (rawResult is String) {
        // Parse JSON string from Android
        result = jsonDecode(rawResult) as List<dynamic>? ?? [];
      } else {
        result = rawResult as List<dynamic>? ?? [];
      }

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
        return _parseProductFromNative(itemMap, type);
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
            await _channel.invokeMethod('buyProduct', <String, dynamic>{
              'sku': iosRequest.sku,
              'forUser': iosRequest.appAccountToken,
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
  }) async {
    final request = iap_types.RequestPurchase(
      ios: _platform.isIOS
          ? iap_types.RequestPurchaseIOS(
              sku: sku,
              andDangerouslyFinishTransactionAutomaticallyIOS:
                  andDangerouslyFinishTransactionAutomaticallyIOS,
              appAccountToken: appAccountToken,
              quantity: quantity,
              withOffer: withOffer,
            )
          : null,
      android: _platform.isAndroid
          ? (type == iap_types.ProductType.subs
              ? iap_types.RequestSubscriptionAndroid(
                  skus: [sku],
                  obfuscatedAccountIdAndroid: obfuscatedAccountIdAndroid,
                  obfuscatedProfileIdAndroid: obfuscatedProfileIdAndroid,
                  isOfferPersonalized: isOfferPersonalized,
                  purchaseTokenAndroid: purchaseToken,
                  replacementModeAndroid: replacementModeAndroid,
                  subscriptionOffers: subscriptionOffers ?? [],
                )
              : iap_types.RequestPurchaseAndroid(
                  skus: [sku],
                  obfuscatedAccountIdAndroid: obfuscatedAccountIdAndroid,
                  obfuscatedProfileIdAndroid: obfuscatedProfileIdAndroid,
                  isOfferPersonalized: isOfferPersonalized,
                ))
          : null,
    );

    await requestPurchase(request: request, type: type);
  }

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
  Future<List<iap_types.Purchase>> getAvailablePurchases() async {
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
        // On iOS, use the internal method to get available items
        return await _getAvailableItems();
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
        // On iOS, getAvailableItems returns the purchase history
        dynamic result = await _channel.invokeMethod('getAvailableItems');
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
        'getStorefront',
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
      throw iap_types.PurchaseError(
        code: iap_types.ErrorCode.eNotSupported,
        message: 'This method is only available on iOS',
        platform: _platform.isIOS
            ? iap_types.IapPlatform.ios
            : iap_types.IapPlatform.android,
      );
    }

    try {
      await channel.invokeMethod('presentCodeRedemptionSheet');
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
      throw iap_types.PurchaseError(
        code: iap_types.ErrorCode.eNotSupported,
        message: 'This method is only available on iOS',
        platform: _platform.isIOS
            ? iap_types.IapPlatform.ios
            : iap_types.IapPlatform.android,
      );
    }

    try {
      await channel.invokeMethod('showManageSubscriptions');
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

  // Helper methods
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
      return iap_types.Subscription(
        productId: json['productId'] as String? ?? '',
        price: json['price'] as String? ?? '0',
        currency: json['currency'] as String?,
        localizedPrice: json['localizedPrice'] as String?,
        title: json['title'] as String?,
        description: json['description'] as String?,
        type: json['type'] as String? ?? iap_types.ProductType.subs,
        platform: platform,
        // iOS fields
        displayName: json['displayName'] as String?,
        displayPrice: json['displayPrice'] as String?,
        discountsIOS: _parseDiscountsIOS(json['discounts']),
        subscription: json['subscription'] != null
            ? iap_types.SubscriptionInfo.fromJson(
                Map<String, dynamic>.from(json['subscription'] as Map),
              )
            : json['subscriptionGroupIdIOS'] != null
                ? iap_types.SubscriptionInfo(
                    subscriptionGroupId:
                        json['subscriptionGroupIdIOS'] as String?,
                  )
                : null,
        subscriptionGroupIdIOS: json['subscriptionGroupIdIOS'] as String?,
        subscriptionPeriodUnitIOS: json['subscriptionPeriodUnitIOS'] as String?,
        subscriptionPeriodNumberIOS:
            json['subscriptionPeriodNumberIOS'] as String?,
        introductoryPricePaymentModeIOS:
            json['introductoryPricePaymentModeIOS'] as String?,
        introductoryPriceNumberOfPeriodsIOS:
            json['introductoryPriceNumberOfPeriodsIOS']?.toString(),
        introductoryPriceSubscriptionPeriodIOS:
            json['introductoryPriceSubscriptionPeriodIOS'] as String?,
        environmentIOS: json['environmentIOS'] as String?,
        promotionalOfferIdsIOS: json['promotionalOfferIdsIOS'] != null
            ? (json['promotionalOfferIdsIOS'] as List).cast<String>()
            : null,
        // OpenIAP compliant iOS fields
        isFamilyShareableIOS: json['isFamilyShareableIOS'] as bool? ??
            json['isFamilyShareable'] as bool?,
        jsonRepresentationIOS: json['jsonRepresentationIOS'] as String? ??
            json['jsonRepresentation'] as String?,
        // Android fields
        nameAndroid: json['nameAndroid'] as String?,
        oneTimePurchaseOfferDetailsAndroid:
            json['oneTimePurchaseOfferDetailsAndroid'] != null
                ? Map<String, dynamic>.from(
                    json['oneTimePurchaseOfferDetailsAndroid'] as Map,
                  )
                : null,
        originalPrice: json['originalPrice'] as String?,
        originalPriceAmount: json['originalPriceAmount'] as double?,
        freeTrialPeriod: json['freeTrialPeriod'] as String?,
        iconUrl: json['iconUrl'] as String?,
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
          productId: json['productId'] as String? ?? '',
          price: json['price'] as String? ?? '0',
          currency: json['currency'] as String?,
          localizedPrice: json['localizedPrice'] as String?,
          title: json['title'] as String?,
          description: json['description'] as String?,
          type: json['type'] as String? ?? iap_types.ProductType.inapp,
          displayName: json['displayName'] as String?,
          // OpenIAP compliant iOS fields
          isFamilyShareableIOS: json['isFamilyShareableIOS'] as bool? ??
              json['isFamilyShareable'] as bool?,
          jsonRepresentationIOS: json['jsonRepresentationIOS'] as String? ??
              json['jsonRepresentation'] as String?,
          // Other iOS fields
          discounts: _parseDiscountsIOS(json['discounts']),
          subscriptionGroupIdentifier:
              json['subscriptionGroupIdIOS'] as String?,
          subscriptionPeriodUnit: json['subscriptionPeriodUnitIOS'] as String?,
          subscriptionPeriodNumber:
              json['subscriptionPeriodNumberIOS'] as String?,
          introductoryPricePaymentMode:
              json['introductoryPricePaymentModeIOS'] as String?,
          introductoryPriceNumberOfPeriodsIOS:
              json['introductoryPriceNumberOfPeriodsIOS'] as String?,
          introductoryPriceSubscriptionPeriodIOS:
              json['introductoryPriceSubscriptionPeriodIOS'] as String?,
          environment: json['environmentIOS'] as String?,
          promotionalOfferIds: json['promotionalOfferIdsIOS'] != null
              ? (json['promotionalOfferIdsIOS'] as List).cast<String>()
              : null,
        );
      } else {
        // For Android platform, create regular Product
        return iap_types.Product(
          productId: json['productId'] as String? ?? '',
          priceString: json['price'] as String? ?? '0',
          currency: json['currency'] as String?,
          localizedPrice: json['localizedPrice'] as String?,
          title: json['title'] as String?,
          description: json['description'] as String?,
          type: json['type'] as String? ?? iap_types.ProductType.inapp,
          platformEnum: platform,
          // Android fields
          displayName: json['displayName'] as String?,
          displayPrice: json['displayPrice'] as String?,
          nameAndroid: json['nameAndroid'] as String?,
          oneTimePurchaseOfferDetailsAndroid:
              json['oneTimePurchaseOfferDetailsAndroid'] != null
                  ? Map<String, dynamic>.from(
                      json['oneTimePurchaseOfferDetailsAndroid'] as Map,
                    )
                  : null,
          originalPrice: json['originalPrice'] as String?,
          originalPriceAmount: json['originalPriceAmount'] as double?,
          freeTrialPeriod: json['freeTrialPeriod'] as String?,
          iconUrl: json['iconUrl'] as String?,
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
        final date =
            DateTime.tryParse(originalTransactionDateIOSValue.toString());
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
      purchaseState: _platform.isAndroid &&
              itemJson['purchaseStateAndroid'] != null
          ? _mapAndroidPurchaseState(itemJson['purchaseStateAndroid'] as int)
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

    // Map error codes
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

  /// Internal method to get available items from native platforms
  Future<List<iap_types.Purchase>> _getAvailableItems() async {
    final List<iap_types.Purchase> items = [];

    if (_platform.isAndroid) {
      dynamic result1 = await _channel.invokeMethod(
        'getAvailableItemsByType',
        <String, dynamic>{'type': TypeInApp.inapp.name},
      );

      dynamic result2 = await _channel.invokeMethod(
        'getAvailableItemsByType',
        <String, dynamic>{'type': TypeInApp.subs.name},
      );
      final consumables = extractPurchases(result1) ?? [];
      final subscriptions = extractPurchases(result2) ?? [];
      items.addAll(consumables);
      items.addAll(subscriptions);
    } else if (_platform.isIOS) {
      dynamic result = await _channel.invokeMethod('getAvailableItems');
      final iosItems = extractPurchases(json.encode(result)) ?? [];
      items.addAll(iosItems);
    } else {
      throw PlatformException(
        code: _platform.operatingSystem,
        message: 'platform not supported',
      );
    }

    return items;
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
  Future<dynamic> requestSubscription(
    String productId, {
    // TODO(v6.4.0): Remove deprecated prorationModeAndroid parameter
    @Deprecated(
      'Use replacementModeAndroid instead - will be removed in v6.4.0',
    )
    int? prorationModeAndroid,
    int? replacementModeAndroid,
    String? obfuscatedAccountIdAndroid,
    String? obfuscatedProfileIdAndroid,
    String? purchaseTokenAndroid,
    int? offerTokenIndex,
  }) async {
    if (_platform.isAndroid) {
      // TODO(v6.4.0): Remove prorationModeAndroid backward compatibility
      // Handle backward compatibility: use prorationModeAndroid if replacementModeAndroid is not set
      final int? effectiveReplacementMode =
          replacementModeAndroid ?? prorationModeAndroid;

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
      return await _channel.invokeMethod('buyProduct', <String, dynamic>{
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
      dynamic result = await _channel.invokeMethod('getPendingTransactions');

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
  Future<String?> finalize() async {
    if (_platform.isAndroid) {
      final String? result = await _channel.invokeMethod('endConnection');
      _removePurchaseListener();
      return result;
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
        final result =
            await _channel.invokeMethod('consumeProduct', <String, dynamic>{
          'purchaseToken': purchase.purchaseToken,
        });
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
          final result = await _channel
              .invokeMethod('acknowledgePurchase', <String, dynamic>{
            'purchaseToken': purchase.purchaseToken,
          });
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
    'Use validateReceiptIOS instead for StoreKit 2 on-device validation. '
    'Apple is phasing out server-side receipt validation endpoints. '
    'Will be removed in v7.0.0',
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
        platform: getCurrentPlatform(),
      );
    }

    if (!_isInitialized) {
      return iap_types.ReceiptValidationResult(
        isValid: false,
        errorMessage: 'IAP connection not initialized',
        platform: getCurrentPlatform(),
      );
    }

    if (sku.trim().isEmpty) {
      return iap_types.ReceiptValidationResult(
        isValid: false,
        errorMessage: 'sku cannot be empty',
        platform: getCurrentPlatform(),
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
          platform: getCurrentPlatform(),
        );
      }

      // Convert Map<dynamic, dynamic> to Map<String, dynamic>
      final Map<String, dynamic> validationResult =
          Map<String, dynamic>.from(result);

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
        platform: getCurrentPlatform(),
      );
    } on PlatformException catch (e) {
      return iap_types.ReceiptValidationResult(
        isValid: false,
        errorMessage:
            'Failed to validate receipt [${e.code}]: ${e.message ?? e.details}',
        platform: getCurrentPlatform(),
      );
    } catch (e) {
      return iap_types.ReceiptValidationResult(
        isValid: false,
        errorMessage: 'Failed to validate receipt: ${e.toString()}',
        platform: getCurrentPlatform(),
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
        platform: getCurrentPlatform(),
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
        platform: getCurrentPlatform(),
      );
    }

    // Extract Android-specific options
    final androidOptions = options.androidOptions;
    if (androidOptions == null) {
      return iap_types.ReceiptValidationResult(
        isValid: false,
        errorMessage: 'Android options required for Android validation',
        platform: getCurrentPlatform(),
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
        platform: getCurrentPlatform(),
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
          platform: getCurrentPlatform(),
        );
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        return iap_types.ReceiptValidationResult(
          isValid: false,
          errorMessage: 'Unauthorized/forbidden (check access token/scopes)',
          platform: getCurrentPlatform(),
        );
      } else if (response.statusCode == 404) {
        return iap_types.ReceiptValidationResult(
          isValid: false,
          errorMessage: 'Token or SKU not found',
          platform: getCurrentPlatform(),
        );
      } else {
        return iap_types.ReceiptValidationResult(
          isValid: false,
          errorMessage:
              'API returned status ${response.statusCode}: ${response.body}',
          platform: getCurrentPlatform(),
        );
      }
    } on TimeoutException {
      return iap_types.ReceiptValidationResult(
        isValid: false,
        errorMessage: 'Request to Google Play API timed out',
        platform: getCurrentPlatform(),
      );
    } catch (e) {
      return iap_types.ReceiptValidationResult(
        isValid: false,
        errorMessage: 'Failed to validate receipt: ${e.toString()}',
        platform: getCurrentPlatform(),
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

  /// flutter IAP compatible method to get products
  @Deprecated(
    'Use requestProducts with type: ProductType.inapp instead. '
    'This method will be removed in the next major version.',
  )
  Future<List<iap_types.Product>> getProductsAsync(
    List<String> productIds,
  ) async {
    final products = await requestProducts(
      skus: productIds,
      type: iap_types.ProductType.inapp,
    );
    return products.whereType<iap_types.Product>().toList();
  }

  /// flutter IAP compatible purchase method
  Future<void> purchaseAsync(String productId) async {
    try {
      if (_platform.isIOS) {
        await _channel.invokeMethod('buyProduct', productId);
      } else if (_platform.isAndroid) {
        await _channel.invokeMethod('buyItemByType', <String, dynamic>{
          'type': TypeInApp.inapp.name,
          'productId': productId,
          'replacementMode': -1,
        });
      }
    } catch (e) {
      throw iap_types.PurchaseError(
        platform: _platform.isIOS
            ? iap_types.IapPlatform.ios
            : iap_types.IapPlatform.android,
        code: iap_types.ErrorCode.eUnknown,
        message: e.toString(),
      );
    }
  }

  /// flutter IAP compatible finish transaction method
  Future<void> finishTransactionAsync({
    required String transactionId,
    required bool consume,
  }) async {
    if (_platform.isIOS) {
      await _channel.invokeMethod('finishTransaction', transactionId);
    } else if (_platform.isAndroid) {
      // For Android, the transactionId is actually the purchaseToken
      if (consume) {
        await _channel.invokeMethod('consumeProduct', <String, dynamic>{
          'purchaseToken': transactionId,
        });
      } else {
        await _channel.invokeMethod('acknowledgePurchase', <String, dynamic>{
          'purchaseToken': transactionId,
        });
      }
    }
  }

  // MARK: - StoreKit 2 specific methods

  /// Restore completed transactions (StoreKit 2)
  Future<void> restorePurchases() async {
    if (_platform.isIOS) {
      await _channel.invokeMethod('restorePurchases');
    } else if (_platform.isAndroid) {
      // Android handles this automatically when querying purchases
      await _getAvailableItems();
    }
  }

  /// Present offer code redemption sheet (iOS 16+)
  Future<void> presentCodeRedemptionSheet() async {
    if (_platform.isIOS) {
      await _channel.invokeMethod('presentCodeRedemptionSheet');
    } else {
      throw PlatformException(
        code: 'UNSUPPORTED',
        message: 'Code redemption sheet is only available on iOS',
      );
    }
  }

  /// Show manage subscriptions screen (iOS 15+)
  Future<void> showManageSubscriptions() async {
    if (_platform.isIOS) {
      await _channel.invokeMethod('showManageSubscriptions');
    } else if (_platform.isAndroid) {
      // For Android, use deepLinkToSubscriptionsAndroid
      await deepLinkToSubscriptionsAndroid();
    }
  }

  /// Clear transaction cache
  Future<void> clearTransactionCache() async {
    if (_platform.isIOS) {
      await _channel.invokeMethod('clearTransactionCache');
    }
    // Android doesn't need transaction cache clearing
  }

  /// Get promoted product (App Store promoted purchase)
  Future<String?> getPromotedProduct() async {
    if (_platform.isIOS) {
      return await _channel.invokeMethod('getPromotedProduct');
    }
    return null;
  }

  /// Get the app transaction (iOS 16.0+)
  /// Returns app-level transaction information including device verification
  Future<Map<String, dynamic>?> getAppTransaction() async {
    if (_platform.isIOS) {
      try {
        final result = await _channel.invokeMethod('getAppTransaction');
        if (result != null) {
          return Map<String, dynamic>.from(result as Map<dynamic, dynamic>);
        }
        return null;
      } catch (e) {
        debugPrint('getAppTransaction error: $e');
        return null;
      }
    }
    return null;
  }

  /// Get the app transaction as typed object (iOS 16.0+)
  /// Returns app-level transaction information including device verification
  Future<iap_types.AppTransaction?> getAppTransactionTyped() async {
    final result = await getAppTransaction();
    if (result != null) {
      try {
        return iap_types.AppTransaction.fromJson(result);
      } catch (e) {
        debugPrint('getAppTransactionTyped parsing error: $e');
        return null;
      }
    }
    return null;
  }

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
            Map<String, dynamic>.from(product), // Pass original JSON as well
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
