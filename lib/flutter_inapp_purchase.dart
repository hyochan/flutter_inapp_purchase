import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:platform/platform.dart';

import 'enums.dart';
import 'types.dart' as iap_types;
import 'modules/ios.dart';
import 'modules/android.dart';

export 'types.dart';
export 'enums.dart';
export 'errors.dart';
export 'events.dart';

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
  StreamController<iap_types.PurchasedItem?>? _purchaseController;
  Stream<iap_types.PurchasedItem?> get purchaseUpdated {
    _purchaseController ??=
        StreamController<iap_types.PurchasedItem?>.broadcast();
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
  List<iap_types.PurchasedItem>? extractPurchasedItems(dynamic result) {
    return extractPurchased(result);
  }

  // New Open IAP compatible event controllers
  final StreamController<iap_types.Purchase> _purchaseUpdatedController =
      StreamController<iap_types.Purchase>.broadcast();
  final StreamController<iap_types.PurchaseError>
      _purchaseErrorListenerController =
      StreamController<iap_types.PurchaseError>.broadcast();

  /// Purchase updated event stream (Open IAP compatible)
  Stream<iap_types.Purchase> get purchaseUpdatedListener =>
      _purchaseUpdatedController.stream;

  /// Purchase error event stream (Open IAP compatible)
  Stream<iap_types.PurchaseError> get purchaseErrorListener =>
      _purchaseErrorListenerController.stream;

  bool _isInitialized = false;

  /// Initialize connection (flutter IAP compatible)
  Future<bool> initConnection() async {
    if (_isInitialized) {
      throw iap_types.PurchaseError(
        code: iap_types.ErrorCode.eAlreadyInitialized,
        message: 'IAP connection already initialized',
        platform: iap_types.getCurrentPlatform(),
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
        platform: iap_types.getCurrentPlatform(),
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
        platform: iap_types.getCurrentPlatform(),
      );
    }
  }

  /// Request products (flutter IAP compatible)
  Future<List<iap_types.BaseProduct>> requestProducts(
      iap_types.RequestProductsParams params) async {
    if (!_isInitialized) {
      throw iap_types.PurchaseError(
        code: iap_types.ErrorCode.eNotInitialized,
        message: 'IAP connection not initialized',
        platform: iap_types.getCurrentPlatform(),
      );
    }

    try {
      print(
          '[flutter_inapp_purchase] requestProducts called with productIds: ${params.productIds}');

      // Get raw data from native platform
      final dynamic rawResult;
      if (params.type == iap_types.PurchaseType.inapp) {
        rawResult =
            await _channel.invokeMethod('getProducts', params.productIds);
      } else {
        rawResult =
            await _channel.invokeMethod('getSubscriptions', params.productIds);
      }

      final List<dynamic> result = rawResult as List<dynamic>? ?? [];

      print(
          '[flutter_inapp_purchase] Received ${result.length} items from native');

      // Convert directly to Product/Subscription without intermediate IAPItem
      return result
          .map((item) => _parseProductFromNative(
              item as Map<String, dynamic>, params.type))
          .toList();
    } catch (e) {
      throw iap_types.PurchaseError(
        code: iap_types.ErrorCode.eServiceError,
        message: 'Failed to fetch products: ${e.toString()}',
        platform: iap_types.getCurrentPlatform(),
      );
    }
  }

  /// Request purchase (flutter IAP compatible)
  Future<void> requestPurchase({
    required iap_types.RequestPurchase request,
    required iap_types.PurchaseType type,
  }) async {
    if (!_isInitialized) {
      throw iap_types.PurchaseError(
        code: iap_types.ErrorCode.eNotInitialized,
        message: 'IAP connection not initialized',
        platform: iap_types.getCurrentPlatform(),
      );
    }

    try {
      if (_platform.isIOS) {
        final iosRequest = request.ios;
        if (iosRequest == null) {
          throw iap_types.PurchaseError(
            code: iap_types.ErrorCode.eDeveloperError,
            message: 'iOS request parameters are required for iOS platform',
            platform: iap_types.getCurrentPlatform(),
          );
        }

        if (iosRequest.withOffer != null) {
          await requestProductWithOfferIOS(
            iosRequest.sku,
            iosRequest.appAccountToken ?? '',
            iosRequest.withOffer!.toJson(),
          );
        } else if (iosRequest.quantity != null && iosRequest.quantity! > 1) {
          await requestPurchaseWithQuantityIOS(
            iosRequest.sku,
            iosRequest.quantity!,
          );
        } else {
          if (type == iap_types.PurchaseType.subs) {
            await requestSubscription(iosRequest.sku);
          } else {
            await _requestPurchaseOld(
              iosRequest.sku,
              obfuscatedAccountId: iosRequest.appAccountToken,
            );
          }
        }
      } else if (_platform.isAndroid) {
        final androidRequest = request.android;
        if (androidRequest == null) {
          throw iap_types.PurchaseError(
            code: iap_types.ErrorCode.eDeveloperError,
            message:
                'Android request parameters are required for Android platform',
            platform: iap_types.getCurrentPlatform(),
          );
        }

        final sku =
            androidRequest.skus.isNotEmpty ? androidRequest.skus.first : '';
        if (type == iap_types.PurchaseType.subs) {
          await requestSubscription(
            sku,
            obfuscatedAccountIdAndroid:
                androidRequest.obfuscatedAccountIdAndroid,
            obfuscatedProfileIdAndroid:
                androidRequest.obfuscatedProfileIdAndroid,
          );
        } else {
          await _requestPurchaseOld(
            sku,
            obfuscatedAccountId: androidRequest.obfuscatedAccountIdAndroid,
            obfuscatedProfileIdAndroid:
                androidRequest.obfuscatedProfileIdAndroid,
          );
        }
      }
    } catch (e) {
      if (e is iap_types.PurchaseError) {
        rethrow;
      }
      throw iap_types.PurchaseError(
        code: iap_types.ErrorCode.eServiceError,
        message: 'Failed to request purchase: ${e.toString()}',
        platform: iap_types.getCurrentPlatform(),
      );
    }
  }

  /// Request purchase with automatic platform detection
  /// This method simplifies the purchase request by automatically detecting the platform
  /// and using the appropriate parameters from the RequestPurchase object
  Future<void> requestPurchaseAuto({
    required String sku,
    required iap_types.PurchaseType type,
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
    int? prorationMode,
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
          ? (type == iap_types.PurchaseType.subs
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

  /// Get available purchases (flutter IAP compatible)
  Future<List<iap_types.Purchase>> getAvailablePurchases() async {
    if (!_isInitialized) {
      throw iap_types.PurchaseError(
        code: iap_types.ErrorCode.eNotInitialized,
        message: 'IAP connection not initialized',
        platform: iap_types.getCurrentPlatform(),
      );
    }

    try {
      if (_platform.isAndroid) {
        // Get both consumable and subscription purchases on Android
        final List<iap_types.PurchasedItem> allPurchases = [];

        // Get consumable purchases
        dynamic result1 = await _channel.invokeMethod(
          'getAvailableItemsByType',
          <String, dynamic>{
            'type': TypeInApp.inapp.name,
          },
        );
        final consumables = extractPurchased(result1) ?? [];
        allPurchases.addAll(consumables);

        // Get subscription purchases
        dynamic result2 = await _channel.invokeMethod(
          'getAvailableItemsByType',
          <String, dynamic>{
            'type': TypeInApp.subs.name,
          },
        );
        final subscriptions = extractPurchased(result2) ?? [];
        allPurchases.addAll(subscriptions);

        return allPurchases.map((item) => _convertToPurchase(item)).toList();
      } else if (_platform.isIOS) {
        final purchases = await getAvailableItemsIOS();
        return purchases?.map((item) => _convertToPurchase(item)).toList() ??
            [];
      }
      return [];
    } catch (e) {
      throw iap_types.PurchaseError(
        code: iap_types.ErrorCode.eServiceError,
        message: 'Failed to get available purchases: ${e.toString()}',
        platform: iap_types.getCurrentPlatform(),
      );
    }
  }

  /// Get purchase histories (flutter IAP compatible)
  Future<List<iap_types.Purchase>> getPurchaseHistories() async {
    if (!_isInitialized) {
      throw iap_types.PurchaseError(
        code: iap_types.ErrorCode.eNotInitialized,
        message: 'IAP connection not initialized',
        platform: iap_types.getCurrentPlatform(),
      );
    }

    try {
      final history = await getPurchaseHistory();
      return history?.map((item) => _convertToPurchase(item)).toList() ?? [];
    } catch (e) {
      throw iap_types.PurchaseError(
        code: iap_types.ErrorCode.eServiceError,
        message: 'Failed to get purchase history: ${e.toString()}',
        platform: iap_types.getCurrentPlatform(),
      );
    }
  }

  /// iOS specific: Get storefront
  Future<String> getStorefrontIOS() async {
    if (!_platform.isIOS) {
      throw iap_types.PurchaseError(
        code: iap_types.ErrorCode.eIapNotAvailable,
        message: 'Storefront is only available on iOS',
        platform: iap_types.getCurrentPlatform(),
      );
    }

    try {
      final result =
          await channel.invokeMethod<Map<dynamic, dynamic>>('getStorefront');
      if (result != null && result['countryCode'] != null) {
        return result['countryCode'] as String;
      }
      throw iap_types.PurchaseError(
        code: iap_types.ErrorCode.eServiceError,
        message: 'Failed to get storefront country code',
        platform: iap_types.getCurrentPlatform(),
      );
    } catch (e) {
      if (e is iap_types.PurchaseError) {
        rethrow;
      }
      throw iap_types.PurchaseError(
        code: iap_types.ErrorCode.eServiceError,
        message: 'Failed to get storefront: ${e.toString()}',
        platform: iap_types.getCurrentPlatform(),
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
        platform: iap_types.getCurrentPlatform(),
      );
    }

    try {
      await channel.invokeMethod('presentCodeRedemptionSheet');
    } catch (e) {
      throw iap_types.PurchaseError(
        code: iap_types.ErrorCode.eServiceError,
        message: 'Failed to present code redemption sheet: ${e.toString()}',
        platform: iap_types.getCurrentPlatform(),
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
        platform: iap_types.getCurrentPlatform(),
      );
    }

    try {
      await channel.invokeMethod('showManageSubscriptions');
    } catch (e) {
      throw iap_types.PurchaseError(
        code: iap_types.ErrorCode.eServiceError,
        message: 'Failed to show manage subscriptions: ${e.toString()}',
        platform: iap_types.getCurrentPlatform(),
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

  /// Legacy method for backward compatibility
  Future<void> deepLinkToSubscriptionsAndroidLegacy({
    required String sku,
    required String packageName,
  }) async {
    await deepLinkToSubscriptionsAndroid(sku: sku);
  }

  /// Android specific: Acknowledge purchase (flutter IAP compatible)
  @override
  @Deprecated('Use finishTransaction() instead. Will be removed in 6.0.0')
  Future<bool> acknowledgePurchaseAndroid({
    required String purchaseToken,
  }) async {
    if (!_platform.isAndroid) {
      return false;
    }

    try {
      final result = await channel.invokeMethod<bool>(
        'acknowledgePurchase',
        {'purchaseToken': purchaseToken},
      );
      return result ?? false;
    } catch (error) {
      debugPrint('Error acknowledging purchase: $error');
      return false;
    }
  }

  // Helper methods
  iap_types.BaseProduct _parseProductFromNative(
      Map<String, dynamic> json, iap_types.PurchaseType type) {
    final platform = iap_types.getCurrentPlatform();

    if (type == iap_types.PurchaseType.subs) {
      return iap_types.Subscription(
        productId: json['productId'] as String? ?? '',
        price: json['price'] as String? ?? '0',
        currency: json['currency'] as String?,
        localizedPrice: json['localizedPrice'] as String?,
        title: json['title'] as String?,
        description: json['description'] as String?,
        platform: platform,
        // iOS fields
        displayName: json['displayName'] as String?,
        isFamilyShareable: json['isFamilyShareable'] as bool?,
        jsonRepresentation: json['jsonRepresentation'] as String?,
        discountsIOS: _parseDiscountsIOS(json['discounts']),
        subscription: json['subscriptionGroupId'] != null
            ? iap_types.SubscriptionInfo(
                subscriptionGroupId: json['subscriptionGroupId'] as String,
                subscriptionPeriod:
                    json['subscriptionPeriodIOS'] as String? ?? '',
                introductoryPrice: json['introductoryPrice'] as String?,
              )
            : null,
        introductoryPriceNumberOfPeriodsIOS:
            json['introductoryPriceNumberOfPeriodsIOS']?.toString(),
        introductoryPriceSubscriptionPeriodIOS:
            json['introductoryPriceSubscriptionPeriodIOS'] as String?,
        // Android fields
        originalPrice: json['originalPrice'] as String?,
        originalPriceAmount: json['originalPriceAmount'] as double?,
        freeTrialPeriod: json['freeTrialPeriod'] as String?,
        iconUrl: json['iconUrl'] as String?,
        subscriptionOfferDetails:
            _parseOfferDetails(json['subscriptionOfferDetails']),
      );
    } else {
      return iap_types.Product(
        productId: json['productId'] as String? ?? '',
        price: json['price'] as String? ?? '0',
        currency: json['currency'] as String?,
        localizedPrice: json['localizedPrice'] as String?,
        title: json['title'] as String?,
        description: json['description'] as String?,
        platform: platform,
        // iOS specific
        displayName: json['displayName'] as String?,
        isFamilyShareable: json['isFamilyShareable'] as bool?,
        jsonRepresentation: json['jsonRepresentation'] as String?,
        discountsIOS: _parseDiscountsIOS(json['discounts']),
        // Android specific
        originalPrice: json['originalPrice'] as String?,
        originalPriceAmount: json['originalPriceAmount'] as double?,
        freeTrialPeriod: json['freeTrialPeriod'] as String?,
        iconUrl: json['iconUrl'] as String?,
        subscriptionOfferDetails:
            _parseOfferDetails(json['subscriptionOfferDetails']),
      );
    }
  }

  List<iap_types.DiscountIOS>? _parseDiscountsIOS(dynamic json) {
    if (json == null) return null;
    final list = json as List<dynamic>;
    return list
        .map((e) => iap_types.DiscountIOS.fromJSON(e as Map<String, dynamic>))
        .toList();
  }

  List<iap_types.OfferDetail>? _parseOfferDetails(dynamic json) {
    if (json == null) return null;
    final list = json as List<dynamic>;
    return list
        .map((e) => iap_types.OfferDetail(
              offerId: e['offerId'] as String?,
              basePlanId: e['basePlanId'] as String? ?? '',
              offerToken: e['offerToken'] as String?,
              pricingPhases: _parsePricingPhases(e['pricingPhases']) ?? [],
              offerTags: (e['offerTags'] as List<dynamic>?)?.cast<String>(),
            ))
        .toList();
  }

  List<iap_types.PricingPhase>? _parsePricingPhases(dynamic json) {
    if (json == null) return null;
    final list = json as List<dynamic>;
    return list
        .map((e) => iap_types.PricingPhase(
              priceAmount: (e['priceAmountMicros'] as num?)?.toDouble() ?? 0.0,
              price: e['formattedPrice'] as String? ?? '0',
              currency: e['priceCurrencyCode'] as String? ?? 'USD',
              billingPeriod: e['billingPeriod'] as String?,
              billingCycleCount: e['billingCycleCount'] as int?,
            ))
        .toList();
  }

  iap_types.PurchaseState _mapAndroidPurchaseState(int state) {
    // Android purchase states:
    // 0 = PURCHASED
    // 1 = PENDING
    switch (state) {
      case 0:
        return iap_types.PurchaseState.purchased;
      case 1:
        return iap_types.PurchaseState.pending;
      default:
        return iap_types.PurchaseState.purchased;
    }
  }

  iap_types.Purchase _convertToPurchase(iap_types.PurchasedItem item) {
    return iap_types.Purchase(
      productId: item.productId ?? '',
      transactionId: item.transactionId,
      transactionReceipt: item.transactionReceipt,
      purchaseToken: item.purchaseToken,
      transactionDate: item.transactionDate?.toIso8601String(),
      platform: iap_types.getCurrentPlatform(),
      isAcknowledgedAndroid: item.isAcknowledgedAndroid,
      purchaseState: item.purchaseStateAndroid != null
          ? _mapAndroidPurchaseState(item.purchaseStateAndroid!)
          : null,
      originalTransactionIdentifierIOS: item.originalTransactionIdentifierIOS,
      originalJson: null,
    );
  }

  iap_types.PurchaseError _convertToPurchaseError(
      iap_types.PurchaseResult result) {
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
      platform: iap_types.getCurrentPlatform(),
    );
  }

  // Original API methods (with deprecation annotations where needed)

  /// Initializes iap features for both `Android` and `iOS`.
  @Deprecated('Use initConnection() instead. Will be removed in version 7.0.0')
  Future<String?> initialize() async {
    if (_platform.isAndroid) {
      await _setPurchaseListener();
      return await _channel.invokeMethod('initConnection');
    } else if (_platform.isIOS) {
      await _setPurchaseListener();
      final canMakePayments = await _channel.invokeMethod('canMakePayments');
      return canMakePayments.toString();
    }
    throw PlatformException(
        code: _platform.operatingSystem, message: 'platform not supported');
  }

  Future<bool> isReady() async {
    if (_platform.isAndroid) {
      return (await _channel.invokeMethod<bool?>('isReady')) ?? false;
    }
    if (_platform.isIOS) {
      return Future.value(true);
    }
    throw PlatformException(
        code: _platform.operatingSystem, message: 'platform not supported');
  }

  @Deprecated('Not available in flutter IAP. Will be removed in 6.0.0')
  Future<bool> manageSubscription(String sku, String packageName) async {
    if (_platform.isAndroid) {
      return (await _channel.invokeMethod<bool?>(
            'manageSubscription',
            <String, dynamic>{
              'sku': sku,
              'packageName': packageName,
            },
          )) ??
          false;
    }
    throw PlatformException(
        code: _platform.operatingSystem, message: 'platform not supported');
  }

  @Deprecated('Not available in flutter IAP. Will be removed in 6.0.0')
  Future<bool> openPlayStoreSubscriptions() async {
    if (_platform.isAndroid) {
      return (await _channel
              .invokeMethod<bool?>('openPlayStoreSubscriptions')) ??
          false;
    }
    throw PlatformException(
        code: _platform.operatingSystem, message: 'platform not supported');
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

  /// Retrieves a list of products from the store
  Future<List<iap_types.IAPItem>> getProducts(List<String> productIds) async {
    if (_platform.isAndroid) {
      dynamic result = await _channel.invokeMethod(
        'getProducts',
        <String, dynamic>{
          'productIds': productIds.toList(),
        },
      );
      return extractItems(result);
    } else if (_platform.isIOS) {
      print(
          '[flutter_inapp_purchase] Calling native iOS getItems with skus: $productIds');
      try {
        dynamic result = await _channel.invokeMethod(
          'getItems',
          <String, dynamic>{
            'skus': productIds.toList(),
          },
        );
        print('[flutter_inapp_purchase] Native iOS returned result: $result');
        return extractItems(json.encode(result));
      } catch (e) {
        print('[flutter_inapp_purchase] Error calling native iOS getItems: $e');
        rethrow;
      }
    }
    throw PlatformException(
        code: _platform.operatingSystem, message: 'platform not supported');
  }

  /// Retrieves subscriptions
  Future<List<iap_types.IAPItem>> getSubscriptions(
      List<String> productIds) async {
    if (_platform.isAndroid) {
      dynamic result = await _channel.invokeMethod(
        'getSubscriptions',
        <String, dynamic>{
          'productIds': productIds.toList(),
        },
      );
      return extractItems(result);
    } else if (_platform.isIOS) {
      dynamic result = await _channel.invokeMethod(
        'getItems',
        <String, dynamic>{
          'skus': productIds.toList(),
        },
      );
      return extractItems(json.encode(result));
    }
    throw PlatformException(
        code: _platform.operatingSystem, message: 'platform not supported');
  }

  /// Retrieves the user's purchase history
  Future<List<iap_types.PurchasedItem>?> getPurchaseHistory() async {
    if (_platform.isAndroid) {
      final dynamic getInappPurchaseHistory = await _channel.invokeMethod(
        'getPurchaseHistoryByType',
        <String, dynamic>{
          'type': TypeInApp.inapp.name,
        },
      );

      final dynamic getSubsPurchaseHistory = await _channel.invokeMethod(
        'getPurchaseHistoryByType',
        <String, dynamic>{
          'type': TypeInApp.subs.name,
        },
      );

      return extractPurchased(getInappPurchaseHistory)! +
          extractPurchased(getSubsPurchaseHistory)!;
    } else if (_platform.isIOS) {
      dynamic result = await _channel.invokeMethod('getAvailableItems');

      return extractPurchased(json.encode(result));
    }
    throw PlatformException(
        code: _platform.operatingSystem, message: 'platform not supported');
  }

  @Deprecated('Not available in flutter IAP. Will be removed in 6.0.0')
  Future<String?> showInAppMessageAndroid() async {
    if (!_platform.isAndroid) return Future.value('');
    _onInAppMessageController ??= StreamController.broadcast();
    return await _channel.invokeMethod('showInAppMessages');
  }

  /// Get all non-consumed purchases made
  @override
  Future<List<iap_types.PurchasedItem>?> getAvailableItemsIOS() async {
    if (_platform.isAndroid) {
      dynamic result1 = await _channel.invokeMethod(
        'getAvailableItemsByType',
        <String, dynamic>{
          'type': TypeInApp.inapp.name,
        },
      );

      dynamic result2 = await _channel.invokeMethod(
        'getAvailableItemsByType',
        <String, dynamic>{
          'type': TypeInApp.subs.name,
        },
      );
      return extractPurchased(result1)! + extractPurchased(result2)!;
    } else if (_platform.isIOS) {
      dynamic result = await _channel.invokeMethod('getAvailableItems');

      return extractPurchased(json.encode(result));
    }
    throw PlatformException(
        code: _platform.operatingSystem, message: 'platform not supported');
  }

  /// Request a purchase (old API)
  Future<dynamic> _requestPurchaseOld(String productId,
      {String? obfuscatedAccountId,
      String? purchaseTokenAndroid,
      String? obfuscatedProfileIdAndroid,
      int? offerTokenIndex}) async {
    if (_platform.isAndroid) {
      return await _channel.invokeMethod('buyItemByType', <String, dynamic>{
        'type': TypeInApp.inapp.name,
        'productId': productId,
        'prorationMode': -1,
        'obfuscatedAccountId': obfuscatedAccountId,
        'obfuscatedProfileId': obfuscatedProfileIdAndroid,
        'purchaseToken': purchaseTokenAndroid,
        'offerTokenIndex': offerTokenIndex
      });
    } else if (_platform.isIOS) {
      return await _channel.invokeMethod('buyProduct', <String, dynamic>{
        'sku': productId,
        'forUser': obfuscatedAccountId,
      });
    }
    throw PlatformException(
        code: _platform.operatingSystem, message: 'platform not supported');
  }

  /// Request a subscription
  Future<dynamic> requestSubscription(
    String productId, {
    int? prorationModeAndroid,
    String? obfuscatedAccountIdAndroid,
    String? obfuscatedProfileIdAndroid,
    String? purchaseTokenAndroid,
    int? offerTokenIndex,
  }) async {
    if (_platform.isAndroid) {
      return await _channel.invokeMethod('buyItemByType', <String, dynamic>{
        'type': TypeInApp.subs.name,
        'productId': productId,
        'prorationMode': prorationModeAndroid ?? -1,
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
        code: _platform.operatingSystem, message: 'platform not supported');
  }

  @Deprecated('Not available in flutter IAP. Will be removed in 6.0.0')
  Future<String?> getPromotedProductIOS() async {
    if (_platform.isIOS) {
      return await _channel.invokeMethod('getPromotedProduct');
    }
    return null;
  }

  @Deprecated('Not available in flutter IAP. Will be removed in 6.0.0')
  Future<dynamic> requestPromotedProductIOS() async {
    if (_platform.isIOS) {
      return await _channel.invokeMethod('requestPromotedProduct');
    }
    throw PlatformException(
        code: _platform.operatingSystem, message: 'platform not supported');
  }

  @override
  @Deprecated(
      'Use requestPurchase() with RequestPurchase object. Will be removed in 6.0.0')
  Future<dynamic> requestProductWithOfferIOS(
    String sku,
    String forUser,
    Map<String, dynamic> withOffer,
  ) async {
    if (_platform.isIOS) {
      return await _channel
          .invokeMethod('requestProductWithOfferIOS', <String, dynamic>{
        'sku': sku,
        'forUser': forUser,
        'withOffer': withOffer,
      });
    }
    throw PlatformException(
        code: _platform.operatingSystem, message: 'platform not supported');
  }

  @override
  @Deprecated(
      'Use requestPurchase() with RequestPurchase object. Will be removed in 6.0.0')
  Future<dynamic> requestPurchaseWithQuantityIOS(
    String sku,
    int quantity,
  ) async {
    if (_platform.isIOS) {
      return await _channel
          .invokeMethod('requestProductWithQuantityIOS', <String, dynamic>{
        'sku': sku,
        'quantity': quantity.toString(),
      });
    }
    throw PlatformException(
        code: _platform.operatingSystem, message: 'platform not supported');
  }

  Future<List<iap_types.PurchasedItem>?> getPendingTransactionsIOS() async {
    if (_platform.isIOS) {
      dynamic result = await _channel.invokeMethod(
        'getPendingTransactions',
      );

      return extractPurchased(json.encode(result));
    }
    return [];
  }

  // Legacy method for backward compatibility
  @Deprecated('Use finishTransaction() instead. Will be removed in 6.0.0')
  Future<String?> consumePurchaseAndroidLegacy(String token) async {
    if (_platform.isAndroid) {
      return await _channel.invokeMethod('consumeProduct', <String, dynamic>{
        'purchaseToken': token,
      });
    } else if (_platform.isIOS) {
      return 'no-ops in ios';
    }
    throw PlatformException(
        code: _platform.operatingSystem, message: 'platform not supported');
  }

  @override
  Future<bool> consumePurchaseAndroid({
    required String purchaseToken,
  }) async {
    if (!_platform.isAndroid) {
      return false;
    }

    try {
      final result = await channel.invokeMethod<bool>(
        'consumePurchase',
        {'purchaseToken': purchaseToken},
      );
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
        code: _platform.operatingSystem, message: 'platform not supported');
  }

  /// Finish a transaction (flutter IAP compatible)
  Future<void> finishTransaction(iap_types.Purchase purchase,
      {bool isConsumable = false}) async {
    final purchasedItem = iap_types.PurchasedItem.fromJSON({
      'productId': purchase.productId,
      'transactionId': purchase.transactionId,
      'transactionReceipt': purchase.transactionReceipt,
      'purchaseToken': purchase.purchaseToken,
      'transactionDate': purchase.transactionDate != null
          ? DateTime.tryParse(purchase.transactionDate!)?.millisecondsSinceEpoch
          : null,
      'isAcknowledgedAndroid': purchase.isAcknowledgedAndroid,
    });

    await finishTransactionIOS(purchasedItem, isConsumable: isConsumable);
  }

  /// Finish a transaction
  Future<void> finishTransactionIOS(iap_types.PurchasedItem purchasedItem,
      {bool isConsumable = false}) async {
    if (_platform.isAndroid) {
      if (isConsumable) {
        await _channel.invokeMethod('consumeProduct', <String, dynamic>{
          'purchaseToken': purchasedItem.purchaseToken,
        });
        return;
      } else {
        if (purchasedItem.isAcknowledgedAndroid == true) {
          return;
        } else {
          await _channel.invokeMethod('acknowledgePurchase', <String, dynamic>{
            'purchaseToken': purchasedItem.purchaseToken,
          });
          return;
        }
      }
    } else if (_platform.isIOS) {
      await _channel.invokeMethod('finishTransaction', <String, dynamic>{
        'transactionIdentifier': purchasedItem.transactionId,
      });
      return;
    }
    throw PlatformException(
        code: _platform.operatingSystem, message: 'platform not supported');
  }

  @Deprecated('Not available in flutter IAP. Will be removed in 6.0.0')
  Future<void> clearTransactionIOS() async {
    if (_platform.isAndroid) {
      return; // no-ops in android
    } else if (_platform.isIOS) {
      await _channel.invokeMethod('clearTransaction');
      return;
    }
    throw PlatformException(
        code: _platform.operatingSystem, message: 'platform not supported');
  }

  Future<List<iap_types.IAPItem>> getAppStoreInitiatedProducts() async {
    if (_platform.isAndroid) {
      return <iap_types.IAPItem>[];
    } else if (_platform.isIOS) {
      dynamic result =
          await _channel.invokeMethod('getAppStoreInitiatedProducts');

      return extractItems(json.encode(result));
    }
    throw PlatformException(
        code: _platform.operatingSystem, message: 'platform not supported');
  }

  @Deprecated('Not available in flutter IAP. Will be removed in 6.0.0')
  Future<bool> checkSubscribed({
    required String sku,
    Duration duration = const Duration(days: 30),
    Duration grace = const Duration(days: 3),
  }) async {
    if (_platform.isIOS) {
      var history = await getPurchaseHistory();

      if (history == null) {
        return false;
      }

      for (var purchase in history) {
        Duration difference =
            DateTime.now().difference(purchase.transactionDate!);
        if (difference.inMinutes <= (duration + grace).inMinutes &&
            purchase.productId == sku) return true;
      }

      return false;
    } else if (_platform.isAndroid) {
      var purchases = await (getAvailableItemsIOS());

      for (var purchase in purchases ?? []) {
        if (purchase.productId == sku) return true;
      }

      return false;
    }
    throw PlatformException(
        code: _platform.operatingSystem, message: 'platform not supported');
  }

  /// Validate receipt in ios
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

  // Legacy method for backward compatibility
  Future<http.Response> validateReceiptAndroidLegacy({
    required String packageName,
    required String productId,
    required String productToken,
    required String accessToken,
    bool isSubscription = false,
  }) async {
    final String type = isSubscription ? 'subscriptions' : 'products';
    final String url =
        'https://www.googleapis.com/androidpublisher/v3/applications/$packageName/purchases/$type/$productId/tokens/$productToken?access_token=$accessToken';
    return await _client.get(
      Uri.parse(url),
      headers: {
        'Accept': 'application/json',
      },
    );
  }

  @override
  Future<Map<String, dynamic>?> validateReceiptAndroid({
    required String packageName,
    required String productId,
    required String productToken,
    required String accessToken,
    required bool isSub,
  }) async {
    if (!_platform.isAndroid) {
      return null;
    }

    try {
      final result = await channel.invokeMethod<Map<dynamic, dynamic>>(
        'validateReceiptAndroid',
        {
          'packageName': packageName,
          'productId': productId,
          'productToken': productToken,
          'accessToken': accessToken,
          'isSub': isSub,
        },
      );
      return result?.cast<String, dynamic>();
    } catch (error) {
      debugPrint('Error validating receipt: $error');
      return null;
    }
  }

  Future<void> _setPurchaseListener() async {
    _purchaseController ??= StreamController.broadcast();
    _purchaseErrorController ??= StreamController.broadcast();
    _connectionController ??= StreamController.broadcast();
    _purchasePromotedController ??= StreamController.broadcast();

    print('[flutter_inapp_purchase] Setting up method call handler');
    _channel.setMethodCallHandler((MethodCall call) async {
      print('[flutter_inapp_purchase] Received method call: ${call.method}');
      print('[flutter_inapp_purchase] Arguments: ${call.arguments}');

      switch (call.method) {
        case 'purchase-updated':
          print('[flutter_inapp_purchase] Processing purchase-updated event');
          try {
            Map<String, dynamic> result =
                jsonDecode(call.arguments as String) as Map<String, dynamic>;
            print('[flutter_inapp_purchase] Decoded result: $result');

            iap_types.PurchasedItem item =
                iap_types.PurchasedItem.fromJSON(result);
            print('[flutter_inapp_purchase] Created PurchasedItem: $item');

            _purchaseController!.add(item);
            print('[flutter_inapp_purchase] Added to purchaseController');

            // Also emit to flutter IAP compatible stream
            final purchase = _convertToPurchase(item);
            print('[flutter_inapp_purchase] Converted to Purchase: $purchase');
            print(
                '[flutter_inapp_purchase] Emitting purchase to purchaseUpdatedController: $purchase');

            _purchaseUpdatedController.add(purchase);
            print(
                '[flutter_inapp_purchase] Successfully emitted to purchaseUpdatedController');
          } catch (e, stackTrace) {
            print('[flutter_inapp_purchase] ERROR in purchase-updated: $e');
            print('[flutter_inapp_purchase] Stack trace: $stackTrace');
          }
          break;
        case 'purchase-error':
          print('[flutter_inapp_purchase] Processing purchase-error event');
          Map<String, dynamic> result =
              jsonDecode(call.arguments as String) as Map<String, dynamic>;
          iap_types.PurchaseResult purchaseResult =
              iap_types.PurchaseResult.fromJSON(result);
          _purchaseErrorController!.add(purchaseResult);
          // Also emit to Open IAP compatible stream
          final error = _convertToPurchaseError(purchaseResult);
          print(
              '[flutter_inapp_purchase] Emitting error to purchaseErrorListenerController: $error');
          _purchaseErrorListenerController.add(error);
          break;
        case 'connection-updated':
          Map<String, dynamic> result =
              jsonDecode(call.arguments as String) as Map<String, dynamic>;
          _connectionController!
              .add(iap_types.ConnectionResult.fromJSON(result));
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

  @Deprecated('Not available in flutter IAP. Will be removed in 6.0.0')
  Future<String> showPromoCodesIOS() async {
    if (_platform.isIOS) {
      return await _channel.invokeMethod<String>('showRedeemCodesIOS') ?? '';
    }
    throw PlatformException(
        code: _platform.operatingSystem, message: 'platform not supported');
  }

  // flutter IAP compatible methods

  /// flutter IAP compatible method to get products
  Future<List<iap_types.Product>> getProductsAsync(
      List<String> productIds) async {
    final items = await getProducts(productIds);
    return items
        .map((item) => iap_types.Product(
              platform: _platform.isIOS
                  ? iap_types.IAPPlatform.ios
                  : iap_types.IAPPlatform.android,
              productId: item.productId ?? '',
              title: item.title ?? '',
              description: item.description ?? '',
              price: item.price ?? '0',
              currency: item.currency ?? 'USD',
            ))
        .toList();
  }

  /// flutter IAP compatible method to get available purchases
  Future<List<iap_types.Purchase>> getAvailablePurchasesAsync() async {
    final items = await getAvailableItemsIOS();
    return items?.map(_convertToPurchase).toList() ?? [];
  }

  /// flutter IAP compatible purchase method
  Future<void> purchaseAsync(String productId) async {
    try {
      if (_platform.isIOS) {
        await _channel.invokeMethod('buyProduct', productId);
      } else if (_platform.isAndroid) {
        await _requestPurchaseOld(productId);
      }
    } catch (e) {
      throw iap_types.PurchaseError(
        platform: _platform.isIOS
            ? iap_types.IAPPlatform.ios
            : iap_types.IAPPlatform.android,
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
      await getAvailableItemsIOS();
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
}

// Utility functions
List<iap_types.IAPItem> extractItems(dynamic result) {
  List<dynamic> list = json.decode(result.toString()) as List<dynamic>;
  List<iap_types.IAPItem> products = list
      .map<iap_types.IAPItem>(
        (dynamic product) =>
            iap_types.IAPItem.fromJSON(product as Map<String, dynamic>),
      )
      .toList();

  return products;
}

List<iap_types.PurchasedItem>? extractPurchased(dynamic result) {
  List<iap_types.PurchasedItem>? decoded = (json.decode(result.toString())
          as List<dynamic>)
      .map<iap_types.PurchasedItem>(
        (dynamic product) =>
            iap_types.PurchasedItem.fromJSON(product as Map<String, dynamic>),
      )
      .toList();

  return decoded;
}

List<iap_types.PurchaseResult>? extractResult(dynamic result) {
  List<iap_types.PurchaseResult>? decoded = (json.decode(result.toString())
          as List<dynamic>)
      .map<iap_types.PurchaseResult>(
        (dynamic product) =>
            iap_types.PurchaseResult.fromJSON(product as Map<String, dynamic>),
      )
      .toList();

  return decoded;
}
