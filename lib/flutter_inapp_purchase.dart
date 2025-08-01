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
export 'use_iap.dart';
export 'utils/error_mapping.dart';

// Enums moved to enums.dart

// MARK: - Classes from modules.dart

// MARK: - Main FlutterInappPurchase class

class FlutterInappPurchase
    with FlutterInappPurchaseIOS, FlutterInappPurchaseAndroid {
  static FlutterInappPurchase instance =
      FlutterInappPurchase(FlutterInappPurchase.private(const LocalPlatform()));

  static StreamController<iap_types.PurchasedItem?>? _purchaseController;
  static Stream<iap_types.PurchasedItem?> get purchaseUpdated {
    _purchaseController ??=
        StreamController<iap_types.PurchasedItem?>.broadcast();
    return _purchaseController!.stream;
  }

  static StreamController<iap_types.PurchaseResult?>? _purchaseErrorController;
  static Stream<iap_types.PurchaseResult?> get purchaseError {
    _purchaseErrorController ??=
        StreamController<iap_types.PurchaseResult?>.broadcast();
    return _purchaseErrorController!.stream;
  }

  static StreamController<iap_types.ConnectionResult>? _connectionController;
  static Stream<iap_types.ConnectionResult> get connectionUpdated {
    _connectionController ??=
        StreamController<iap_types.ConnectionResult>.broadcast();
    return _connectionController!.stream;
  }

  static StreamController<String?>? _purchasePromotedController;
  static Stream<String?> get purchasePromoted {
    _purchasePromotedController ??= StreamController<String?>.broadcast();
    return _purchasePromotedController!.stream;
  }

  static StreamController<int?>? _onInAppMessageController;
  static Stream<int?> get inAppMessageAndroid {
    _onInAppMessageController ??= StreamController<int?>.broadcast();
    return _onInAppMessageController!.stream;
  }

  /// Defining the [MethodChannel] for Flutter_Inapp_Purchase
  static final MethodChannel _channel = const MethodChannel('flutter_inapp');
  static MethodChannel get staticChannel => _channel;

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
  late http.Client _httpClient;

  static http.Client get _client => instance._httpClient;

  factory FlutterInappPurchase(FlutterInappPurchase _instance) {
    instance = _instance;
    return instance;
  }

  @visibleForTesting
  FlutterInappPurchase.private(Platform platform, {http.Client? client})
      : _pf = platform,
        _httpClient = client ?? http.Client();

  // Implement the missing method from iOS mixin
  @override
  List<iap_types.PurchasedItem>? extractPurchasedItems(dynamic result) {
    return extractPurchased(result);
  }

  // New flutter IAP compatible event controllers
  final StreamController<iap_types.Purchase> _purchaseUpdatedController =
      StreamController<iap_types.Purchase>.broadcast();
  final StreamController<iap_types.PurchaseError>
      _expoIAPPurchaseErrorController =
      StreamController<iap_types.PurchaseError>.broadcast();

  /// Purchase updated event stream (flutter IAP compatible)
  Stream<iap_types.Purchase> get purchaseUpdatedListener =>
      _purchaseUpdatedController.stream;

  /// Purchase error event stream (flutter IAP compatible)
  Stream<iap_types.PurchaseError> get purchaseErrorListener =>
      _expoIAPPurchaseErrorController.stream;

  bool _isInitialized = false;

  /// Initialize connection (flutter IAP compatible)
  Future<void> initConnection() async {
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
    } catch (e) {
      throw iap_types.PurchaseError(
        code: iap_types.ErrorCode.eNotInitialized,
        message: 'Failed to initialize IAP connection: ${e.toString()}',
        platform: iap_types.getCurrentPlatform(),
      );
    }
  }

  /// End connection (flutter IAP compatible)
  Future<void> endConnection() async {
    if (!_isInitialized) {
      return;
    }

    try {
      // For flutter IAP compatibility, call endConnection directly
      if (_platform.isIOS) {
        await _channel.invokeMethod('endConnection');
      } else if (_platform.isAndroid) {
        await _channel.invokeMethod('endConnection');
      }
      _isInitialized = false;
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
          '[flutter_inapp_purchase] requestProducts called with skus: ${params.skus}');
      List<iap_types.IAPItem> items;
      if (params.type == iap_types.PurchaseType.inapp) {
        items = await getProducts(params.skus);
      } else {
        items = await getSubscriptions(params.skus);
      }
      print(
          '[flutter_inapp_purchase] Received ${items.length} items from native');
      for (var item in items) {
        print(
            '[flutter_inapp_purchase] Item: ${item.productId} - ${item.localizedPrice}');
      }

      return items.map((item) => _convertToProduct(item, params.type)).toList();
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

        final sku = androidRequest.skus.first;
        if (type == iap_types.PurchaseType.subs) {
          await requestSubscription(
            sku,
            prorationModeAndroid: androidRequest.prorationMode,
            obfuscatedAccountIdAndroid:
                androidRequest.obfuscatedAccountIdAndroid,
            obfuscatedProfileIdAndroid:
                androidRequest.obfuscatedProfileIdAndroid,
            purchaseTokenAndroid: androidRequest.purchaseToken,
            offerTokenIndex: androidRequest.offerTokenIndex,
          );
        } else {
          await _requestPurchaseOld(
            sku,
            obfuscatedAccountId: androidRequest.obfuscatedAccountIdAndroid,
            purchaseTokenAndroid: androidRequest.purchaseToken,
            obfuscatedProfileIdAndroid:
                androidRequest.obfuscatedProfileIdAndroid,
            offerTokenIndex: androidRequest.offerTokenIndex,
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
                  purchaseToken: purchaseToken,
                  offerTokenIndex: offerTokenIndex,
                  prorationMode: prorationMode,
                  replacementModeAndroid: replacementModeAndroid,
                  subscriptionOffers: subscriptionOffers,
                )
              : iap_types.RequestPurchaseAndroid(
                  skus: [sku],
                  obfuscatedAccountIdAndroid: obfuscatedAccountIdAndroid,
                  obfuscatedProfileIdAndroid: obfuscatedProfileIdAndroid,
                  isOfferPersonalized: isOfferPersonalized,
                  purchaseToken: purchaseToken,
                  offerTokenIndex: offerTokenIndex,
                  prorationMode: prorationMode,
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
      final purchases = await getAvailableItemsIOS();
      return purchases?.map((item) => _convertToPurchase(item)).toList() ?? [];
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
  Future<iap_types.AppStoreInfo?> getStorefrontIOS() async {
    if (!_platform.isIOS) {
      return null;
    }

    try {
      final result =
          await channel.invokeMethod<Map<dynamic, dynamic>>('getStorefront');
      if (result != null) {
        return iap_types.AppStoreInfo(
          storefrontCountryCode: result['countryCode'] as String?,
          identifier: result['identifier'] as String?,
        );
      }
      return null;
    } catch (e) {
      throw iap_types.PurchaseError(
        code: iap_types.ErrorCode.eServiceError,
        message: 'Failed to get storefront: ${e.toString()}',
        platform: iap_types.getCurrentPlatform(),
      );
    }
  }

  /// iOS specific: Present code redemption sheet
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
  iap_types.BaseProduct _convertToProduct(
      iap_types.IAPItem item, iap_types.PurchaseType type) {
    final platform = iap_types.getCurrentPlatform();

    if (type == iap_types.PurchaseType.subs) {
      return iap_types.Subscription(
        productId: item.productId ?? '',
        price: item.price ?? '0',
        currency: item.currency,
        localizedPrice: item.localizedPrice,
        title: item.title,
        description: item.description,
        platform: platform,
        subscriptionPeriodAndroid: item.subscriptionPeriodAndroid,
        subscriptionPeriodUnitIOS: item.subscriptionPeriodUnitIOS,
        subscriptionPeriodNumberIOS: item.subscriptionPeriodNumberIOS != null
            ? int.tryParse(item.subscriptionPeriodNumberIOS!)
            : null,
      );
    } else {
      return iap_types.Product(
        productId: item.productId ?? '',
        price: item.price ?? '0',
        currency: item.currency,
        localizedPrice: item.localizedPrice,
        title: item.title,
        description: item.description,
        platform: platform,
      );
    }
  }

  iap_types.Purchase _convertToPurchase(iap_types.PurchasedItem item) {
    return iap_types.Purchase(
      productId: item.productId ?? '',
      transactionId: item.transactionId,
      transactionReceipt: item.transactionReceipt,
      purchaseToken: item.purchaseToken,
      transactionDate: item.transactionDate,
      platform: iap_types.getCurrentPlatform(),
      isAcknowledgedAndroid: item.isAcknowledgedAndroid,
      purchaseStateAndroid: item.purchaseStateAndroid?.toString(),
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

  /// Consumes all items on `Android`.
  @Deprecated('Not available in flutter IAP. Will be removed in 6.0.0')
  Future<dynamic> consumeAll() async {
    if (_platform.isAndroid) {
      return await _channel.invokeMethod('consumeAllItems');
    } else if (_platform.isIOS) {
      return 'no-ops in ios';
    }
    throw PlatformException(
        code: _platform.operatingSystem, message: 'platform not supported');
  }

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
  Future<String?> finishTransaction(iap_types.Purchase purchase,
      {bool isConsumable = false}) async {
    final purchasedItem = iap_types.PurchasedItem.fromJSON({
      'productId': purchase.productId,
      'transactionId': purchase.transactionId,
      'transactionReceipt': purchase.transactionReceipt,
      'purchaseToken': purchase.purchaseToken,
      'transactionDate': purchase.transactionDate?.millisecondsSinceEpoch,
      'isAcknowledgedAndroid': purchase.isAcknowledgedAndroid,
    });

    return await finishTransactionIOS(purchasedItem,
        isConsumable: isConsumable);
  }

  /// Finish a transaction
  Future<String?> finishTransactionIOS(iap_types.PurchasedItem purchasedItem,
      {bool isConsumable = false}) async {
    if (_platform.isAndroid) {
      if (isConsumable) {
        return await _channel.invokeMethod('consumeProduct', <String, dynamic>{
          'purchaseToken': purchasedItem.purchaseToken,
        });
      } else {
        if (purchasedItem.isAcknowledgedAndroid == true) {
          return Future.value(null);
        } else {
          return await _channel
              .invokeMethod('acknowledgePurchase', <String, dynamic>{
            'purchaseToken': purchasedItem.purchaseToken,
          });
        }
      }
    } else if (_platform.isIOS) {
      return await _channel.invokeMethod('finishTransaction', <String, dynamic>{
        'transactionIdentifier': purchasedItem.transactionId,
      });
    }
    throw PlatformException(
        code: _platform.operatingSystem, message: 'platform not supported');
  }

  @Deprecated('Not available in flutter IAP. Will be removed in 6.0.0')
  Future<String?> clearTransactionIOS() async {
    if (_platform.isAndroid) {
      return 'no-ops in android.';
    } else if (_platform.isIOS) {
      return await _channel.invokeMethod('clearTransaction');
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

  Future<dynamic> _setPurchaseListener() async {
    _purchaseController ??= StreamController.broadcast();
    _purchaseErrorController ??= StreamController.broadcast();
    _connectionController ??= StreamController.broadcast();
    _purchasePromotedController ??= StreamController.broadcast();

    _channel.setMethodCallHandler((MethodCall call) {
      switch (call.method) {
        case 'purchase-updated':
          Map<String, dynamic> result =
              jsonDecode(call.arguments as String) as Map<String, dynamic>;
          iap_types.PurchasedItem item =
              iap_types.PurchasedItem.fromJSON(result);
          _purchaseController!.add(item);
          // Also emit to flutter IAP compatible stream
          _purchaseUpdatedController.add(_convertToPurchase(item));
          break;
        case 'purchase-error':
          Map<String, dynamic> result =
              jsonDecode(call.arguments as String) as Map<String, dynamic>;
          iap_types.PurchaseResult purchaseResult =
              iap_types.PurchaseResult.fromJSON(result);
          _purchaseErrorController!.add(purchaseResult);
          // Also emit to flutter IAP compatible stream
          _expoIAPPurchaseErrorController
              .add(_convertToPurchaseError(purchaseResult));
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

// Global instance (flutter IAP compatible)
final expoIAP = FlutterInappPurchase.instance;

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
