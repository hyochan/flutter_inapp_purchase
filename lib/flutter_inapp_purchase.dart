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
export 'builders.dart';
export 'utils.dart';
export 'enums.dart' hide IapPlatform, ErrorCode, PurchaseState;
export 'errors.dart' show getCurrentPlatform;

// ---------------------------------------------------------------------------
// Legacy compatibility helpers (kept for existing example/tests)
// ---------------------------------------------------------------------------

extension PurchaseLegacyCompat on iap_types.Purchase {
  String? get transactionId => id.isEmpty ? null : id;

  int? get purchaseStateAndroid {
    if (this is iap_types.PurchaseAndroid) {
      final state = (this as iap_types.PurchaseAndroid).purchaseState;
      switch (state) {
        case iap_types.PurchaseState.Purchased:
          return AndroidPurchaseState.Purchased.value;
        case iap_types.PurchaseState.Pending:
          return AndroidPurchaseState.Pending.value;
        default:
          return AndroidPurchaseState.Unknown.value;
      }
    }
    return null;
  }

  TransactionState? get transactionStateIOS {
    switch (purchaseState) {
      case iap_types.PurchaseState.Purchased:
        return TransactionState.purchased;
      case iap_types.PurchaseState.Pending:
        return TransactionState.purchasing;
      case iap_types.PurchaseState.Failed:
        return TransactionState.failed;
      case iap_types.PurchaseState.Deferred:
        return TransactionState.deferred;
      case iap_types.PurchaseState.Restored:
        return TransactionState.restored;
      case iap_types.PurchaseState.Unknown:
        return TransactionState.purchasing;
    }
  }

  bool? get isAcknowledgedAndroid => this is iap_types.PurchaseAndroid
      ? (this as iap_types.PurchaseAndroid).isAcknowledgedAndroid
      : null;

  bool? get autoRenewingAndroid => this is iap_types.PurchaseAndroid
      ? (this as iap_types.PurchaseAndroid).autoRenewingAndroid
      : null;

  String? get dataAndroid => this is iap_types.PurchaseAndroid
      ? (this as iap_types.PurchaseAndroid).dataAndroid
      : null;

  String? get signatureAndroid => this is iap_types.PurchaseAndroid
      ? (this as iap_types.PurchaseAndroid).signatureAndroid
      : null;

  String? get packageNameAndroid => this is iap_types.PurchaseAndroid
      ? (this as iap_types.PurchaseAndroid).packageNameAndroid
      : null;

  String? get obfuscatedAccountIdAndroid => this is iap_types.PurchaseAndroid
      ? (this as iap_types.PurchaseAndroid).obfuscatedAccountIdAndroid
      : null;

  String? get obfuscatedProfileIdAndroid => this is iap_types.PurchaseAndroid
      ? (this as iap_types.PurchaseAndroid).obfuscatedProfileIdAndroid
      : null;

  String? get orderIdAndroid => null;

  int? get quantityIOS => this is iap_types.PurchaseIOS
      ? (this as iap_types.PurchaseIOS).quantityIOS
      : null;

  String? get originalTransactionIdentifierIOS => this is iap_types.PurchaseIOS
      ? (this as iap_types.PurchaseIOS).originalTransactionIdentifierIOS
      : null;

  double? get originalTransactionDateIOS => this is iap_types.PurchaseIOS
      ? (this as iap_types.PurchaseIOS).originalTransactionDateIOS
      : null;

  String? get environmentIOS => this is iap_types.PurchaseIOS
      ? (this as iap_types.PurchaseIOS).environmentIOS
      : null;

  String? get transactionReceipt => purchaseToken;
}

extension ProductCommonLegacyCompat on iap_types.ProductCommon {
  String get localizedPrice => displayPrice;

  iap_types.IapPlatform get platformEnum => platform;

  List<iap_types.DiscountIOS>? get discountsIOS {
    if (this is iap_types.ProductSubscriptionIOS) {
      return (this as iap_types.ProductSubscriptionIOS).discountsIOS;
    }
    return null;
  }

  String? get signatureAndroid => null;

  String? get iconUrl => null;
}

extension ProductSubscriptionLegacyCompat on iap_types.ProductSubscription {
  String? get subscriptionPeriodAndroid => null;

  String? get subscriptionPeriodUnitIOS {
    if (this is iap_types.ProductSubscriptionIOS) {
      return (this as iap_types.ProductSubscriptionIOS)
          .subscriptionPeriodUnitIOS
          ?.toJson();
    }
    return null;
  }

  String? get subscriptionPeriodNumberIOS {
    if (this is iap_types.ProductSubscriptionIOS) {
      return (this as iap_types.ProductSubscriptionIOS)
          .subscriptionPeriodNumberIOS;
    }
    return null;
  }

  String? get introductoryPriceNumberOfPeriodsIOS {
    if (this is iap_types.ProductSubscriptionIOS) {
      return (this as iap_types.ProductSubscriptionIOS)
          .introductoryPriceNumberOfPeriodsIOS;
    }
    return null;
  }

  String? get introductoryPriceSubscriptionPeriodIOS {
    if (this is iap_types.ProductSubscriptionIOS) {
      return (this as iap_types.ProductSubscriptionIOS)
          .introductoryPriceSubscriptionPeriodIOS
          ?.toJson();
    }
    return null;
  }

  List<iap_types.DiscountIOS>? get discountsIOS {
    if (this is iap_types.ProductSubscriptionIOS) {
      return (this as iap_types.ProductSubscriptionIOS).discountsIOS;
    }
    return null;
  }

  List<iap_types.AndroidSubscriptionOfferInput>? get subscriptionOffersAndroid {
    if (this is iap_types.ProductSubscriptionAndroid) {
      final details = (this as iap_types.ProductSubscriptionAndroid)
          .subscriptionOfferDetailsAndroid;
      return details
          .map((offer) => iap_types.AndroidSubscriptionOfferInput(
                offerToken: offer.offerToken,
                sku: offer.basePlanId,
              ))
          .toList();
    }
    return null;
  }

  iap_types.SubscriptionInfoIOS? get subscriptionInfoIOS =>
      this is iap_types.ProductSubscriptionIOS
          ? (this as iap_types.ProductSubscriptionIOS).subscriptionInfoIOS
          : null;

  dynamic get subscription => subscriptionInfoIOS;

  List<iap_types.AndroidSubscriptionOfferInput>?
      get subscriptionOfferDetailsAndroid => subscriptionOffersAndroid;
}

extension ProductCommonMapCompat on iap_types.ProductCommon {
  Map<String, dynamic> toLegacyJson() {
    if (this is iap_types.ProductAndroid) {
      return (this as iap_types.ProductAndroid).toJson();
    }
    if (this is iap_types.ProductIOS) {
      return (this as iap_types.ProductIOS).toJson();
    }
    return {};
  }
}

extension PurchaseErrorLegacyCompat on iap_types.PurchaseError {
  iap_types.IapPlatform? get platform => null;
  int? get responseCode => null;
}

typedef SubscriptionOfferAndroid = iap_types.AndroidSubscriptionOfferInput;

/// Legacy purchase request container (pre-generated API).
class RequestPurchase {
  RequestPurchase({
    this.android,
    this.ios,
    iap_types.ProductType? type,
  }) : type = type ??
            (android is RequestSubscriptionAndroid
                ? iap_types.ProductType.Subs
                : iap_types.ProductType.InApp);

  final RequestPurchaseAndroid? android;
  final RequestPurchaseIOS? ios;
  final iap_types.ProductType type;

  iap_types.RequestPurchaseProps toProps() {
    if (type == iap_types.ProductType.InApp) {
      return iap_types.RequestPurchaseProps.inApp(
        request: iap_types.RequestPurchasePropsByPlatforms(
          android: android?.toInAppProps(),
          ios: ios?.toInAppProps(),
        ),
      );
    }

    return iap_types.RequestPurchaseProps.subs(
      request: iap_types.RequestSubscriptionPropsByPlatforms(
        android: (android is RequestSubscriptionAndroid)
            ? (android as RequestSubscriptionAndroid).toSubscriptionProps()
            : null,
        ios: ios?.toSubscriptionProps(),
      ),
    );
  }
}

class RequestPurchaseAndroid {
  RequestPurchaseAndroid({
    required this.skus,
    this.obfuscatedAccountIdAndroid,
    this.obfuscatedProfileIdAndroid,
    this.isOfferPersonalized,
  });

  List<String> skus;
  String? obfuscatedAccountIdAndroid;
  String? obfuscatedProfileIdAndroid;
  bool? isOfferPersonalized;

  iap_types.RequestPurchaseAndroidProps toInAppProps() {
    return iap_types.RequestPurchaseAndroidProps(
      skus: skus,
      obfuscatedAccountIdAndroid: obfuscatedAccountIdAndroid,
      obfuscatedProfileIdAndroid: obfuscatedProfileIdAndroid,
      isOfferPersonalized: isOfferPersonalized,
    );
  }

  iap_types.RequestSubscriptionAndroidProps toSubscriptionProps() {
    return iap_types.RequestSubscriptionAndroidProps(
      skus: skus,
      isOfferPersonalized: isOfferPersonalized,
      obfuscatedAccountIdAndroid: obfuscatedAccountIdAndroid,
      obfuscatedProfileIdAndroid: obfuscatedProfileIdAndroid,
      purchaseTokenAndroid: null,
      replacementModeAndroid: null,
      subscriptionOffers: null,
    );
  }
}

class RequestSubscriptionAndroid extends RequestPurchaseAndroid {
  RequestSubscriptionAndroid({
    required super.skus,
    this.purchaseTokenAndroid,
    this.replacementModeAndroid,
    this.subscriptionOffers,
    super.obfuscatedAccountIdAndroid,
    super.obfuscatedProfileIdAndroid,
    super.isOfferPersonalized,
  });

  final String? purchaseTokenAndroid;
  final int? replacementModeAndroid;
  final List<iap_types.AndroidSubscriptionOfferInput>? subscriptionOffers;

  @override
  iap_types.RequestSubscriptionAndroidProps toSubscriptionProps() {
    return iap_types.RequestSubscriptionAndroidProps(
      skus: skus,
      isOfferPersonalized: isOfferPersonalized,
      obfuscatedAccountIdAndroid: obfuscatedAccountIdAndroid,
      obfuscatedProfileIdAndroid: obfuscatedProfileIdAndroid,
      purchaseTokenAndroid: purchaseTokenAndroid,
      replacementModeAndroid: replacementModeAndroid,
      subscriptionOffers: subscriptionOffers,
    );
  }
}

class RequestPurchaseIOS {
  RequestPurchaseIOS({
    required this.sku,
    this.quantity,
    this.appAccountToken,
    this.withOffer,
    this.andDangerouslyFinishTransactionAutomatically,
  });

  final String sku;
  final int? quantity;
  final String? appAccountToken;
  final iap_types.DiscountOfferInputIOS? withOffer;
  final bool? andDangerouslyFinishTransactionAutomatically;

  iap_types.RequestPurchaseIosProps toInAppProps() {
    return iap_types.RequestPurchaseIosProps(
      sku: sku,
      quantity: quantity,
      appAccountToken: appAccountToken,
      andDangerouslyFinishTransactionAutomatically:
          andDangerouslyFinishTransactionAutomatically,
      withOffer: withOffer,
    );
  }

  iap_types.RequestSubscriptionIosProps toSubscriptionProps() {
    return iap_types.RequestSubscriptionIosProps(
      sku: sku,
      quantity: quantity,
      appAccountToken: appAccountToken,
      andDangerouslyFinishTransactionAutomatically:
          andDangerouslyFinishTransactionAutomatically,
      withOffer: withOffer,
    );
  }
}

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

  StreamController<PurchaseResult?>? _purchaseErrorController;
  Stream<PurchaseResult?> get purchaseError {
    _purchaseErrorController ??= StreamController<PurchaseResult?>.broadcast();
    return _purchaseErrorController!.stream;
  }

  StreamController<ConnectionResult>? _connectionController;
  Stream<ConnectionResult> get connectionUpdated {
    _connectionController ??= StreamController<ConnectionResult>.broadcast();
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
  @override
  bool get isIOS => _platform.isIOS;
  @override
  bool get isAndroid => _platform.isAndroid;
  @override
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
      throw const iap_types.PurchaseError(
        code: iap_types.ErrorCode.AlreadyPrepared,
        message: 'IAP connection already initialized',
      );
    }

    try {
      await _setPurchaseListener();
      await _channel.invokeMethod('initConnection');
      _isInitialized = true;
      return true;
    } catch (error) {
      throw iap_types.PurchaseError(
        code: iap_types.ErrorCode.NotPrepared,
        message: 'Failed to initialize IAP connection: ${error.toString()}',
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
        code: iap_types.ErrorCode.ServiceError,
        message: 'Failed to end IAP connection: ${e.toString()}',
      );
    }
  }

  /// Request purchase (flutter IAP compatible)
  Future<void> requestPurchase({
    iap_types.RequestPurchaseProps? props,
    @Deprecated('Use props parameter') RequestPurchase? request,
    @Deprecated('Use props parameter') iap_types.ProductType? type,
  }) async {
    if (!_isInitialized) {
      throw const iap_types.PurchaseError(
        code: iap_types.ErrorCode.NotPrepared,
        message: 'IAP connection not initialized',
      );
    }

    final effectiveProps = props ?? request?.toProps();
    if (effectiveProps == null) {
      throw ArgumentError('RequestPurchaseProps are required.');
    }

    if (type != null) {
      final expected = type == iap_types.ProductType.InApp
          ? iap_types.ProductQueryType.InApp
          : iap_types.ProductQueryType.Subs;
      if (effectiveProps.type != expected) {
        debugPrint(
          '[flutter_inapp_purchase] Warning: ignoring deprecated type argument in requestPurchase. '
          'props.type=${effectiveProps.type}, provided type=$type',
        );
      }
    }

    final requestVariant = effectiveProps.request;
    final isSubscription =
        requestVariant is iap_types.RequestPurchasePropsRequestSubscription;

    try {
      if (_platform.isIOS) {
        if (isSubscription) {
          final iosRequest = (requestVariant).value.ios;
          if (iosRequest == null) {
            throw const iap_types.PurchaseError(
              code: iap_types.ErrorCode.DeveloperError,
              message: 'Missing iOS subscription parameters',
            );
          }

          if (iosRequest.withOffer != null) {
            await _channel.invokeMethod('requestProductWithOfferIOS', {
              'sku': iosRequest.sku,
              'forUser': iosRequest.appAccountToken ?? '',
              'withOffer': iosRequest.withOffer!.toJson(),
            });
          } else if (iosRequest.quantity != null && iosRequest.quantity! > 1) {
            await _channel.invokeMethod(
              'requestProductWithQuantityIOS',
              {
                'sku': iosRequest.sku,
                'quantity': iosRequest.quantity!.toString(),
              },
            );
          } else {
            // ignore: deprecated_member_use_from_same_package
            await requestSubscription(iosRequest.sku);
          }
        } else {
          final iosRequest =
              (requestVariant as iap_types.RequestPurchasePropsRequestPurchase)
                  .value
                  .ios;
          if (iosRequest == null) {
            throw const iap_types.PurchaseError(
              code: iap_types.ErrorCode.DeveloperError,
              message: 'Missing iOS purchase parameters',
            );
          }

          if (iosRequest.withOffer != null) {
            await _channel.invokeMethod('requestProductWithOfferIOS', {
              'sku': iosRequest.sku,
              'forUser': iosRequest.appAccountToken ?? '',
              'withOffer': iosRequest.withOffer!.toJson(),
            });
          } else if (iosRequest.quantity != null && iosRequest.quantity! > 1) {
            await _channel.invokeMethod(
              'requestProductWithQuantityIOS',
              {
                'sku': iosRequest.sku,
                'quantity': iosRequest.quantity!.toString(),
              },
            );
          } else {
            await _channel.invokeMethod('requestPurchase', {
              'sku': iosRequest.sku,
              'appAccountToken': iosRequest.appAccountToken,
            });
          }
        }
      } else if (_platform.isAndroid) {
        if (isSubscription) {
          final androidRequest = (requestVariant).value.android;
          if (androidRequest == null) {
            throw const iap_types.PurchaseError(
              code: iap_types.ErrorCode.DeveloperError,
              message: 'Missing Android subscription parameters',
            );
          }

          final sku =
              androidRequest.skus.isNotEmpty ? androidRequest.skus.first : '';

          if (androidRequest.replacementModeAndroid != null &&
              androidRequest.replacementModeAndroid != -1 &&
              (androidRequest.purchaseTokenAndroid == null ||
                  androidRequest.purchaseTokenAndroid!.isEmpty)) {
            throw const iap_types.PurchaseError(
              code: iap_types.ErrorCode.DeveloperError,
              message:
                  'purchaseTokenAndroid is required when using replacementModeAndroid (proration mode). '
                  'You need the purchase token from the existing subscription to upgrade/downgrade.',
            );
          }

          await _channel.invokeMethod('requestPurchase', {
            'type': TypeInApp.subs.name,
            'skus': androidRequest.skus,
            'productId': sku,
            if (androidRequest.obfuscatedAccountIdAndroid != null)
              'obfuscatedAccountId': androidRequest.obfuscatedAccountIdAndroid,
            if (androidRequest.obfuscatedProfileIdAndroid != null)
              'obfuscatedProfileId': androidRequest.obfuscatedProfileIdAndroid,
            if (androidRequest.isOfferPersonalized != null)
              'isOfferPersonalized': androidRequest.isOfferPersonalized,
            if (androidRequest.purchaseTokenAndroid != null)
              'purchaseToken': androidRequest.purchaseTokenAndroid,
            if (androidRequest.replacementModeAndroid != null)
              'replacementMode': androidRequest.replacementModeAndroid,
            if (androidRequest.subscriptionOffers != null &&
                androidRequest.subscriptionOffers!.isNotEmpty)
              'subscriptionOffers': androidRequest.subscriptionOffers!
                  .map((offer) => offer.toJson())
                  .toList(),
          });
        } else {
          final androidRequest =
              (requestVariant as iap_types.RequestPurchasePropsRequestPurchase)
                  .value
                  .android;
          if (androidRequest == null) {
            throw const iap_types.PurchaseError(
              code: iap_types.ErrorCode.DeveloperError,
              message: 'Missing Android purchase parameters',
            );
          }

          final sku =
              androidRequest.skus.isNotEmpty ? androidRequest.skus.first : '';

          await _channel.invokeMethod('requestPurchase', {
            'type': TypeInApp.inapp.name,
            'skus': [sku],
            'productId': sku,
            if (androidRequest.obfuscatedAccountIdAndroid != null)
              'obfuscatedAccountId': androidRequest.obfuscatedAccountIdAndroid,
            if (androidRequest.obfuscatedProfileIdAndroid != null)
              'obfuscatedProfileId': androidRequest.obfuscatedProfileIdAndroid,
            if (androidRequest.isOfferPersonalized != null)
              'isOfferPersonalized': androidRequest.isOfferPersonalized,
          });
        }
      }
    } catch (error) {
      if (error is iap_types.PurchaseError) {
        rethrow;
      }
      throw iap_types.PurchaseError(
        code: iap_types.ErrorCode.ServiceError,
        message: 'Failed to request purchase: ${error.toString()}',
      );
    }
  }

  /// DSL-like request purchase method with builder pattern
  /// Provides a more intuitive and type-safe way to build purchase requests
  ///
  /// Example:
  /// ```dart
  /// await iap.requestPurchaseWithBuilder(
  ///   build: (r) => r
  ///     ..type = ProductType.InApp
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
    final props = builder.build();

    await requestPurchase(props: props);
  }

  /// DSL-like request subscription method with builder pattern
  // requestSubscriptionWithBuilder removed in 6.6.0 (use requestPurchaseWithBuilder)

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
      throw const iap_types.PurchaseError(
        code: iap_types.ErrorCode.NotPrepared,
        message: 'IAP connection not initialized',
      );
    }

    try {
      if (_platform.isAndroid) {
        // Android unified available items
        final dynamic result = await _channel.invokeMethod('getAvailableItems');
        final items = extractPurchases(result) ?? [];
        // Filter out incomplete purchases (must have productId and either purchaseToken or transactionId)
        return items
            .where((p) =>
                p.productId.isNotEmpty &&
                (p.purchaseToken != null && p.purchaseToken!.isNotEmpty))
            .toList();
      } else if (_platform.isIOS) {
        // On iOS, pass both iOS-specific options to native method
        final args = options?.toJson() ?? <String, dynamic>{};

        dynamic result = await _channel.invokeMethod('getAvailableItems', args);
        final items = extractPurchases(json.encode(result)) ?? [];
        return items
            .where((p) =>
                p.productId.isNotEmpty &&
                (p.purchaseToken != null && p.purchaseToken!.isNotEmpty))
            .toList();
      }
      return [];
    } catch (e) {
      throw iap_types.PurchaseError(
        code: iap_types.ErrorCode.ServiceError,
        message: 'Failed to get available purchases: ${e.toString()}',
      );
    }
  }

  /// iOS specific: Get storefront
  Future<String> getStorefrontIOS() async {
    if (!_platform.isIOS) {
      throw const iap_types.PurchaseError(
        code: iap_types.ErrorCode.IapNotAvailable,
        message: 'Storefront is only available on iOS',
      );
    }

    try {
      final result = await channel.invokeMethod<Map<dynamic, dynamic>>(
        'getStorefrontIOS',
      );
      if (result != null && result['countryCode'] != null) {
        return result['countryCode'] as String;
      }
      throw const iap_types.PurchaseError(
        code: iap_types.ErrorCode.ServiceError,
        message: 'Failed to get storefront country code',
      );
    } catch (e) {
      if (e is iap_types.PurchaseError) {
        rethrow;
      }
      throw iap_types.PurchaseError(
        code: iap_types.ErrorCode.ServiceError,
        message: 'Failed to get storefront: ${e.toString()}',
      );
    }
  }

  String _resolveProductType(Object type) {
    if (type is String) {
      return type;
    }
    if (type is TypeInApp) {
      return type.name;
    }
    if (type is iap_types.ProductType) {
      return type == iap_types.ProductType.InApp
          ? TypeInApp.inapp.name
          : TypeInApp.subs.name;
    }
    if (type is iap_types.ProductQueryType) {
      switch (type) {
        case iap_types.ProductQueryType.InApp:
          return TypeInApp.inapp.name;
        case iap_types.ProductQueryType.Subs:
          return TypeInApp.subs.name;
        case iap_types.ProductQueryType.All:
          return 'all';
      }
    }
    return TypeInApp.inapp.name;
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
        code: iap_types.ErrorCode.ServiceError,
        message: 'Failed to present code redemption sheet: ${e.toString()}',
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
        code: iap_types.ErrorCode.ServiceError,
        message: 'Failed to show manage subscriptions: ${e.toString()}',
      );
    }
  }

  // Android-specific deep link helper removed in 6.6.0

  iap_types.ProductCommon _parseProductFromNative(
    Map<String, dynamic> json,
    String type,
  ) {
    // Determine platform from JSON data if available, otherwise use heuristics, then runtime
    iap_types.IapPlatform platform;
    final dynamic platformRaw = json['platform'];
    if (platformRaw is String) {
      final v = platformRaw.toLowerCase();
      platform = (v == 'android')
          ? iap_types.IapPlatform.Android
          : iap_types.IapPlatform.IOS;
    } else if (platformRaw is iap_types.IapPlatform) {
      platform = platformRaw;
    } else {
      // Heuristics based on well-known platform-specific fields
      final looksAndroid =
          json.containsKey('oneTimePurchaseOfferDetailsAndroid') ||
              json.containsKey('subscriptionOfferDetailsAndroid') ||
              json.containsKey('nameAndroid');
      final looksIOS = json.containsKey('subscriptionGroupIdIOS') ||
          json.containsKey('jsonRepresentationIOS') ||
          json.containsKey('environmentIOS');
      if (looksAndroid && !looksIOS) {
        platform = iap_types.IapPlatform.Android;
      } else if (looksIOS && !looksAndroid) {
        platform = iap_types.IapPlatform.IOS;
      } else {
        // Fallback to current runtime platform
        platform = _platform.isIOS
            ? iap_types.IapPlatform.IOS
            : iap_types.IapPlatform.Android;
      }
    }

    final productId = (json['id']?.toString() ??
            json['productId']?.toString() ??
            json['sku']?.toString() ??
            json['productIdentifier']?.toString() ??
            '')
        .trim();
    final title = json['title']?.toString() ?? productId;
    final description = json['description']?.toString() ?? '';
    final currency = json['currency']?.toString() ?? '';
    final displayPrice = json['displayPrice']?.toString() ??
        json['localizedPrice']?.toString() ??
        '0';
    final priceValue = _parsePrice(json['price']);
    final productType = _parseProductType(type);

    if (productType == iap_types.ProductType.Subs) {
      if (platform == iap_types.IapPlatform.IOS) {
        return iap_types.ProductSubscriptionIOS(
          currency: currency,
          description: description,
          displayNameIOS: json['displayNameIOS']?.toString() ?? title,
          displayPrice: displayPrice,
          id: productId,
          isFamilyShareableIOS: json['isFamilyShareableIOS'] as bool? ?? false,
          jsonRepresentationIOS:
              json['jsonRepresentationIOS']?.toString() ?? '{}',
          platform: platform,
          title: title,
          type: productType,
          typeIOS: _parseProductTypeIOS(json['typeIOS']?.toString()),
          debugDescription: json['debugDescription']?.toString(),
          discountsIOS:
              _parseDiscountsIOS(json['discountsIOS'] ?? json['discounts']),
          displayName: json['displayName']?.toString(),
          introductoryPriceAsAmountIOS:
              json['introductoryPriceAsAmountIOS']?.toString(),
          introductoryPriceIOS: json['introductoryPriceIOS']?.toString(),
          introductoryPriceNumberOfPeriodsIOS:
              json['introductoryPriceNumberOfPeriodsIOS']?.toString(),
          introductoryPricePaymentModeIOS:
              _parsePaymentMode(json['introductoryPricePaymentModeIOS']),
          introductoryPriceSubscriptionPeriodIOS: _parseSubscriptionPeriod(
              json['introductoryPriceSubscriptionPeriodIOS']),
          price: priceValue,
          subscriptionInfoIOS: _parseSubscriptionInfoIOS(
            json['subscriptionInfoIOS'] ?? json['subscription'],
          ),
          subscriptionPeriodNumberIOS:
              json['subscriptionPeriodNumberIOS']?.toString(),
          subscriptionPeriodUnitIOS:
              _parseSubscriptionPeriod(json['subscriptionPeriodUnitIOS']),
        );
      }

      final subscriptionOffers = _parseOfferDetails(
        json['subscriptionOfferDetailsAndroid'],
      );

      return iap_types.ProductSubscriptionAndroid(
        currency: currency,
        description: description,
        displayPrice: displayPrice,
        id: productId,
        nameAndroid: json['nameAndroid']?.toString() ?? productId,
        platform: platform,
        subscriptionOfferDetailsAndroid: subscriptionOffers,
        title: title,
        type: productType,
        debugDescription: json['debugDescription']?.toString(),
        displayName: json['displayName']?.toString(),
        oneTimePurchaseOfferDetailsAndroid: _parseOneTimePurchaseOfferDetail(
            json['oneTimePurchaseOfferDetailsAndroid']),
        price: priceValue,
      );
    }

    if (platform == iap_types.IapPlatform.IOS) {
      return iap_types.ProductIOS(
        currency: currency,
        description: description,
        displayNameIOS: json['displayNameIOS']?.toString() ?? title,
        displayPrice: displayPrice,
        id: productId,
        isFamilyShareableIOS: json['isFamilyShareableIOS'] as bool? ?? false,
        jsonRepresentationIOS:
            json['jsonRepresentationIOS']?.toString() ?? '{}',
        platform: platform,
        title: title,
        type: productType,
        typeIOS: _parseProductTypeIOS(json['typeIOS']?.toString()),
        debugDescription: json['debugDescription']?.toString(),
        displayName: json['displayName']?.toString(),
        price: priceValue,
        subscriptionInfoIOS: _parseSubscriptionInfoIOS(
          json['subscriptionInfoIOS'] ?? json['subscription'],
        ),
      );
    }

    final androidOffers = _parseOfferDetails(
      json['subscriptionOfferDetailsAndroid'],
    );

    return iap_types.ProductAndroid(
      currency: currency,
      description: description,
      displayPrice: displayPrice,
      id: productId,
      nameAndroid: json['nameAndroid']?.toString() ?? productId,
      platform: platform,
      title: title,
      type: productType,
      debugDescription: json['debugDescription']?.toString(),
      displayName: json['displayName']?.toString(),
      oneTimePurchaseOfferDetailsAndroid: _parseOneTimePurchaseOfferDetail(
          json['oneTimePurchaseOfferDetailsAndroid']),
      price: priceValue,
      subscriptionOfferDetailsAndroid:
          androidOffers.isEmpty ? null : androidOffers,
    );
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

  List<iap_types.ProductSubscriptionAndroidOfferDetails> _parseOfferDetails(
    dynamic json,
  ) {
    if (json == null) {
      return const <iap_types.ProductSubscriptionAndroidOfferDetails>[];
    }

    // Handle both List and String (JSON string from Android)
    List<dynamic> list;
    if (json is String) {
      // Parse JSON string from Android
      try {
        final parsed = jsonDecode(json);
        if (parsed is! List) {
          return const <iap_types.ProductSubscriptionAndroidOfferDetails>[];
        }
        list = parsed;
      } catch (e) {
        return const <iap_types.ProductSubscriptionAndroidOfferDetails>[];
      }
    } else if (json is List) {
      list = json;
    } else {
      return const <iap_types.ProductSubscriptionAndroidOfferDetails>[];
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

          return iap_types.ProductSubscriptionAndroidOfferDetails(
            basePlanId: e['basePlanId'] as String? ?? '',
            offerId: e['offerId'] as String?,
            offerToken: e['offerToken'] as String? ?? '',
            offerTags: (e['offerTags'] as List<dynamic>?)
                    ?.map((tag) => tag.toString())
                    .toList() ??
                const <String>[],
            pricingPhases: _parsePricingPhases(e['pricingPhases']),
          );
        })
        .whereType<iap_types.ProductSubscriptionAndroidOfferDetails>()
        .toList();
  }

  iap_types.PricingPhasesAndroid _parsePricingPhases(dynamic json) {
    if (json == null) {
      return const iap_types.PricingPhasesAndroid(pricingPhaseList: []);
    }

    // Handle nested structure from Android
    List<dynamic>? list;
    if (json is Map && json['pricingPhaseList'] != null) {
      list = json['pricingPhaseList'] as List<dynamic>?;
    } else if (json is List) {
      list = json;
    }

    if (list == null) {
      return const iap_types.PricingPhasesAndroid(pricingPhaseList: []);
    }

    final phases = list
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

          final priceAmountMicros = e['priceAmountMicros'];
          final recurrenceMode = e['recurrenceMode'];

          return iap_types.PricingPhaseAndroid(
            billingCycleCount: (e['billingCycleCount'] as num?)?.toInt() ?? 0,
            billingPeriod: e['billingPeriod']?.toString() ?? '',
            formattedPrice: e['formattedPrice']?.toString() ?? '0',
            priceAmountMicros: priceAmountMicros?.toString() ?? '0',
            priceCurrencyCode: e['priceCurrencyCode']?.toString() ?? 'USD',
            recurrenceMode: recurrenceMode is int ? recurrenceMode : 0,
          );
        })
        .whereType<iap_types.PricingPhaseAndroid>()
        .toList();

    return iap_types.PricingPhasesAndroid(pricingPhaseList: phases);
  }

  iap_types.PurchaseState _parsePurchaseStateIOS(dynamic value) {
    if (value is iap_types.PurchaseState) return value;
    if (value is String) {
      switch (value.toLowerCase()) {
        case 'purchasing':
        case 'pending':
          return iap_types.PurchaseState.Pending;
        case 'purchased':
        case 'restored':
          return iap_types.PurchaseState.Purchased;
        case 'failed':
          return iap_types.PurchaseState.Failed;
        case 'deferred':
          return iap_types.PurchaseState.Deferred;
        default:
          return iap_types.PurchaseState.Unknown;
      }
    }
    if (value is num) {
      switch (value.toInt()) {
        case 0:
          return iap_types.PurchaseState.Pending;
        case 1:
          return iap_types.PurchaseState.Purchased;
        case 2:
          return iap_types.PurchaseState.Failed;
        case 3:
          return iap_types.PurchaseState.Purchased;
        case 4:
          return iap_types.PurchaseState.Deferred;
      }
    }
    return iap_types.PurchaseState.Unknown;
  }

  iap_types.PurchaseState _mapAndroidPurchaseState(int stateValue) {
    final state = androidPurchaseStateFromValue(stateValue);
    switch (state) {
      case AndroidPurchaseState.Purchased:
        return iap_types.PurchaseState.Purchased;
      case AndroidPurchaseState.Pending:
        return iap_types.PurchaseState.Pending;
      case AndroidPurchaseState.Unknown:
        return iap_types.PurchaseState.Unknown;
    }
  }

  iap_types.Purchase _convertFromLegacyPurchase(
    Map<String, dynamic> itemJson, [
    Map<String, dynamic>? originalJson,
  ]) {
    final productId = itemJson['productId']?.toString() ?? '';
    final transactionId =
        itemJson['transactionId']?.toString() ?? itemJson['id']?.toString();
    final quantity = (itemJson['quantity'] as num?)?.toInt() ?? 1;

    final String? purchaseId = (transactionId?.isNotEmpty ?? false)
        ? transactionId
        : (productId.isNotEmpty ? productId : null);

    if (purchaseId == null || purchaseId.isEmpty) {
      debugPrint(
        '[flutter_inapp_purchase] Skipping purchase with missing identifiers: $itemJson',
      );
      throw const FormatException('Missing purchase identifier');
    }

    double transactionDate = 0;
    final transactionDateValue = itemJson['transactionDate'];
    if (transactionDateValue is num) {
      transactionDate = transactionDateValue.toDouble();
    } else if (transactionDateValue is String) {
      final parsedDate = DateTime.tryParse(transactionDateValue);
      if (parsedDate != null) {
        transactionDate = parsedDate.millisecondsSinceEpoch.toDouble();
      }
    }

    if (_platform.isAndroid) {
      final stateValue = itemJson['purchaseStateAndroid'] as int? ??
          itemJson['purchaseState'] as int? ??
          1;
      final purchaseState = _mapAndroidPurchaseState(stateValue).toJson();

      final map = <String, dynamic>{
        'id': purchaseId,
        'productId': productId,
        'platform': iap_types.IapPlatform.Android.toJson(),
        'isAutoRenewing': itemJson['isAutoRenewing'] as bool? ??
            itemJson['autoRenewingAndroid'] as bool? ??
            false,
        'purchaseState': purchaseState,
        'quantity': quantity,
        'transactionDate': transactionDate,
        'purchaseToken': itemJson['purchaseToken']?.toString(),
        'autoRenewingAndroid': itemJson['autoRenewingAndroid'] as bool?,
        'dataAndroid': itemJson['originalJsonAndroid']?.toString(),
        'developerPayloadAndroid':
            itemJson['developerPayloadAndroid']?.toString(),
        'ids': (itemJson['ids'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList(),
        'isAcknowledgedAndroid': itemJson['isAcknowledgedAndroid'] as bool?,
        'obfuscatedAccountIdAndroid':
            itemJson['obfuscatedAccountIdAndroid']?.toString() ??
                originalJson?['obfuscatedAccountIdAndroid']?.toString(),
        'obfuscatedProfileIdAndroid':
            itemJson['obfuscatedProfileIdAndroid']?.toString() ??
                originalJson?['obfuscatedProfileIdAndroid']?.toString(),
        'packageNameAndroid': itemJson['packageNameAndroid']?.toString(),
        'signatureAndroid': itemJson['signatureAndroid']?.toString(),
      };

      return iap_types.PurchaseAndroid.fromJson(map);
    }

    final stateIOS = _parsePurchaseStateIOS(
      itemJson['purchaseState'] ?? itemJson['transactionStateIOS'],
    ).toJson();

    double? originalTransactionDateIOS;
    final originalTransactionDateValue =
        itemJson['originalTransactionDateIOS'] ??
            originalJson?['originalTransactionDateIOS'];
    if (originalTransactionDateValue is num) {
      originalTransactionDateIOS = originalTransactionDateValue.toDouble();
    } else if (originalTransactionDateValue is String) {
      final parsed = DateTime.tryParse(originalTransactionDateValue);
      if (parsed != null) {
        originalTransactionDateIOS = parsed.millisecondsSinceEpoch.toDouble();
      }
    }

    final map = <String, dynamic>{
      'id': purchaseId,
      'productId': productId,
      'platform': iap_types.IapPlatform.IOS.toJson(),
      'isAutoRenewing': itemJson['isAutoRenewing'] as bool? ?? false,
      'purchaseState': stateIOS,
      'quantity': quantity,
      'transactionDate': transactionDate,
      'purchaseToken': itemJson['transactionReceipt']?.toString() ??
          itemJson['purchaseToken']?.toString(),
      'ids': (itemJson['ids'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      'appAccountToken': itemJson['appAccountToken']?.toString(),
      'appBundleIdIOS': itemJson['appBundleIdIOS']?.toString(),
      'countryCodeIOS': itemJson['countryCodeIOS']?.toString(),
      'currencyCodeIOS': itemJson['currencyCodeIOS']?.toString(),
      'currencySymbolIOS': itemJson['currencySymbolIOS']?.toString(),
      'environmentIOS': itemJson['environmentIOS']?.toString(),
      'expirationDateIOS':
          (originalJson?['expirationDateIOS'] as num?)?.toDouble(),
      'originalTransactionIdentifierIOS':
          itemJson['originalTransactionIdentifierIOS']?.toString(),
      'originalTransactionDateIOS': originalTransactionDateIOS,
      'subscriptionGroupIdIOS': itemJson['subscriptionGroupIdIOS']?.toString(),
      'transactionReasonIOS': itemJson['transactionReasonIOS']?.toString(),
      'webOrderLineItemIdIOS': itemJson['webOrderLineItemIdIOS']?.toString(),
      'offerIOS': originalJson?['offerIOS'],
      'priceIOS': (originalJson?['priceIOS'] as num?)?.toDouble(),
      'revocationDateIOS':
          (originalJson?['revocationDateIOS'] as num?)?.toDouble(),
      'revocationReasonIOS': originalJson?['revocationReasonIOS']?.toString(),
    };

    return iap_types.PurchaseIOS.fromJson(map);
  }

  iap_types.PurchaseError _convertToPurchaseError(
    PurchaseResult result,
  ) {
    iap_types.ErrorCode code = iap_types.ErrorCode.Unknown;

    // Prefer OpenIAP string codes when present (works cross-platform)
    if (result.code != null && result.code!.isNotEmpty) {
      final detected = iap_err.ErrorCodeUtils.fromPlatformCode(
        result.code!,
        _platform.isIOS
            ? iap_types.IapPlatform.IOS
            : iap_types.IapPlatform.Android,
      );
      if (detected != iap_types.ErrorCode.Unknown) {
        code = detected;
      }
    }

    // Map error codes
    // Fallback to legacy numeric response codes when string code is absent
    if (code == iap_types.ErrorCode.Unknown) {
      switch (result.responseCode) {
        case 0:
          code = iap_types.ErrorCode.Unknown;
          break;
        case 1:
          code = iap_types.ErrorCode.UserCancelled;
          break;
        case 2:
          code = iap_types.ErrorCode.ServiceError;
          break;
        case 3:
          code = iap_types.ErrorCode.BillingUnavailable;
          break;
        case 4:
          code = iap_types.ErrorCode.ItemUnavailable;
          break;
        case 5:
          code = iap_types.ErrorCode.DeveloperError;
          break;
        case 6:
          code = iap_types.ErrorCode.Unknown;
          break;
        case 7:
          code = iap_types.ErrorCode.AlreadyOwned;
          break;
        case 8:
          code = iap_types.ErrorCode.PurchaseError;
          break;
      }
    }

    return iap_types.PurchaseError(
      code: code,
      message: result.message ?? 'Unknown error',
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

  // getStore removed in 6.6.0

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
  /* removed in 6.6.0 */ Future<dynamic> requestSubscription(
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
          code: iap_types.ErrorCode.DeveloperError,
          message:
              'purchaseTokenAndroid is required when using replacement mode (replacementModeAndroid: $effectiveReplacementMode). '
              'Replacement modes are only for upgrading/downgrading EXISTING subscriptions. '
              'For NEW subscriptions, do not set replacementModeAndroid or set it to -1. '
              'To upgrade/downgrade, provide the purchaseToken from getAvailablePurchases().',
        );
      }

      return await _channel.invokeMethod('requestPurchase', <String, dynamic>{
        'type': TypeInApp.subs.name,
        'skus': [productId],
        'productId': productId,
        if (obfuscatedAccountIdAndroid != null)
          'obfuscatedAccountId': obfuscatedAccountIdAndroid,
        if (obfuscatedProfileIdAndroid != null)
          'obfuscatedProfileId': obfuscatedProfileIdAndroid,
        if (offerTokenIndex != null) 'offerTokenIndex': offerTokenIndex,
        if (purchaseTokenAndroid != null) 'purchaseToken': purchaseTokenAndroid,
        if (effectiveReplacementMode != null)
          'replacementMode': effectiveReplacementMode,
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
  Future<iap_types.VoidResult> consumePurchaseAndroid({
    required String purchaseToken,
  }) async {
    if (!_platform.isAndroid) {
      throw const iap_types.PurchaseError(
        code: iap_types.ErrorCode.IapNotAvailable,
        message: 'consumePurchaseAndroid is only available on Android',
      );
    }

    try {
      final response = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'consumePurchaseAndroid',
        {'purchaseToken': purchaseToken},
      );
      if (response == null) {
        return const iap_types.VoidResult(success: false);
      }
      return iap_types.VoidResult.fromJson(
        Map<String, dynamic>.from(response),
      );
    } catch (error) {
      debugPrint('Error consuming purchase: $error');
      return const iap_types.VoidResult(success: false);
    }
  }

  /// Finish a transaction using Purchase object (OpenIAP compliant)
  Future<void> finishTransaction(
    iap_types.Purchase purchase, {
    bool isConsumable = false,
  }) async {
    // Use purchase.id (OpenIAP standard) if available, fallback to transactionId for backward compatibility
    final transactionId = purchase.id;

    if (_platform.isAndroid) {
      final androidPurchase = purchase as iap_types.PurchaseAndroid;

      if (isConsumable) {
        debugPrint(
          '[FlutterInappPurchase] Android: Consuming product with token: ${androidPurchase.purchaseToken}',
        );
        final result = await _channel.invokeMethod(
          'consumePurchaseAndroid',
          <String, dynamic>{'purchaseToken': androidPurchase.purchaseToken},
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
        if (androidPurchase.isAcknowledgedAndroid == true) {
          if (kDebugMode) {
            debugPrint(
              '[FlutterInappPurchase] Android: Purchase already acknowledged',
            );
          }
          return;
        } else {
          if (kDebugMode) {
            final maskedToken =
                (androidPurchase.purchaseToken ?? '').replaceAllMapped(
              RegExp(r'.(?=.{4})'),
              (m) => '*',
            );
            debugPrint(
              '[FlutterInappPurchase] Android: Acknowledging purchase with token: $maskedToken',
            );
          }
          // Subscriptions use legacy acknowledgePurchase for compatibility
          final methodName = androidPurchase.autoRenewingAndroid == true
              ? 'acknowledgePurchase'
              : 'acknowledgePurchaseAndroid';
          final result = await _channel.invokeMethod(
            methodName,
            <String, dynamic>{
              'purchaseToken': androidPurchase.purchaseToken,
            },
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

  /// Finish a transaction using legacy PurchasedItem JSON (legacy compatibility)
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
      throw const iap_types.PurchaseError(
        code: iap_types.ErrorCode.IapNotAvailable,
        message: 'Receipt validation is only available on iOS',
      );
    }

    if (!_isInitialized) {
      throw const iap_types.PurchaseError(
        code: iap_types.ErrorCode.NotPrepared,
        message: 'IAP connection not initialized',
      );
    }

    if (sku.trim().isEmpty) {
      throw const iap_types.PurchaseError(
        code: iap_types.ErrorCode.DeveloperError,
        message: 'sku cannot be empty',
      );
    }

    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'validateReceiptIOS',
        {'sku': sku}, // iOS only needs the SKU
      );

      if (result == null) {
        throw const iap_types.PurchaseError(
          code: iap_types.ErrorCode.ServiceError,
          message: 'No validation result received from native platform',
        );
      }

      // Convert Map<dynamic, dynamic> to Map<String, dynamic>
      final Map<String, dynamic> validationResult = Map<String, dynamic>.from(
        result,
      );

      // Parse latestTransaction if present
      final latestTransactionMap = validationResult['latestTransaction'];
      final latestTransaction = latestTransactionMap is Map
          ? iap_types.Purchase.fromJson(
              Map<String, dynamic>.from(latestTransactionMap),
            )
          : null;

      return iap_types.ReceiptValidationResultIOS(
        isValid: validationResult['isValid'] as bool? ?? false,
        jwsRepresentation:
            validationResult['jwsRepresentation']?.toString() ?? '',
        receiptData: validationResult['receiptData']?.toString() ?? '',
        latestTransaction: latestTransaction,
      );
    } on PlatformException catch (e) {
      throw iap_types.PurchaseError(
        code: iap_types.ErrorCode.ServiceError,
        message:
            'Failed to validate receipt [${e.code}]: ${e.message ?? e.details}',
      );
    } catch (e) {
      throw iap_types.PurchaseError(
        code: iap_types.ErrorCode.ServiceError,
        message: 'Failed to validate receipt: ${e.toString()}',
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
      throw const iap_types.PurchaseError(
        code: iap_types.ErrorCode.IapNotAvailable,
        message: 'Platform not supported for receipt validation',
      );
    }
  }

  /// Internal Android validation implementation
  Future<iap_types.ReceiptValidationResult> _validateReceiptAndroid({
    required iap_types.ReceiptValidationProps options,
  }) async {
    throw const iap_types.PurchaseError(
      code: iap_types.ErrorCode.IapNotAvailable,
      message: 'Android receipt validation is not supported',
    );
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
          final purchaseResult = PurchaseResult.fromJSON(result);
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
            ConnectionResult.fromJSON(Map<String, dynamic>.from(result)),
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

  // flutter IAP compatible methods

  /// OpenIAP: fetch products or subscriptions
  Future<List<T>> fetchProducts<T extends iap_types.ProductCommon>({
    required List<String> skus,
    Object type = TypeInApp.inapp,
  }) async {
    if (!_isInitialized) {
      throw const iap_types.PurchaseError(
        code: iap_types.ErrorCode.NotPrepared,
        message: 'IAP connection not initialized',
      );
    }

    try {
      final resolvedType = _resolveProductType(type);
      debugPrint(
          '[flutter_inapp_purchase] fetchProducts called with skus: $skus, type: $resolvedType');

      // Get raw data from native platform
      final List<dynamic> merged = [];
      if (_platform.isIOS) {
        // iOS supports 'all' at native layer
        final raw = await _channel.invokeMethod('fetchProducts', {
          'skus': skus,
          'type': resolvedType,
        });
        if (raw is String) {
          merged.addAll(jsonDecode(raw) as List<dynamic>? ?? []);
        } else if (raw is List) {
          merged.addAll(raw);
        }
      } else {
        // Android: unified fetchProducts(type, skus)
        final raw = await _channel.invokeMethod('fetchProducts', {
          'skus': skus,
          'type': resolvedType,
        });
        if (raw is String) {
          merged.addAll(jsonDecode(raw) as List<dynamic>? ?? []);
        } else if (raw is List) {
          merged.addAll(raw);
        }
      }

      final result = merged;

      debugPrint(
        '[flutter_inapp_purchase] Received ${result.length} items from native',
      );

      // Convert directly to Product/Subscription without intermediate IapItem
      final List<iap_types.ProductCommon> products = [];
      for (final item in result) {
        try {
          // Handle different Map types from iOS and Android
          final Map<String, dynamic> itemMap;
          if (item is Map<String, dynamic>) {
            itemMap = item;
          } else if (item is Map) {
            // Convert Map<Object?, Object?> to Map<String, dynamic>
            itemMap = Map<String, dynamic>.from(item);
          } else {
            debugPrint(
                '[flutter_inapp_purchase] Skipping unexpected item type: ${item.runtimeType}');
            continue;
          }
          // When 'all', native item contains its own type; pass through using detected type
          final detectedType = (resolvedType == 'all')
              ? (itemMap['type']?.toString() ?? 'in-app')
              : resolvedType;
          final parsed = _parseProductFromNative(itemMap, detectedType);
          products.add(parsed);
        } catch (e) {
          debugPrint(
              '[flutter_inapp_purchase] Skipping product due to parse error: $e');
        }
      }

      // Return as the expected generic type when possible
      // Using whereType<T>() avoids runtime type errors (e.g., ProductIOS vs Product)
      final typed = products.whereType<T>().toList();
      if (typed.length != products.length) {
        debugPrint(
            '[flutter_inapp_purchase] Filtered ${products.length - typed.length} items not matching <$T>');
      }
      return typed;
    } catch (e) {
      throw iap_types.PurchaseError(
        code: iap_types.ErrorCode.ServiceError,
        message: 'Failed to fetch products: ${e.toString()}',
      );
    }
  }

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

  /// Get all active subscriptions with detailed information (OpenIAP compliant)
  /// Returns an array of active subscriptions. If subscriptionIds is not provided,
  /// returns all active subscriptions. Platform-specific fields are populated based
  /// on the current platform.
  Future<List<iap_types.ActiveSubscription>> getActiveSubscriptions({
    List<String>? subscriptionIds,
  }) async {
    if (!_isInitialized) {
      throw const iap_types.PurchaseError(
        code: iap_types.ErrorCode.NotPrepared,
        message: 'IAP connection not initialized',
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

        if (purchase is iap_types.PurchaseAndroid) {
          final bool isSubscription = purchase.autoRenewingAndroid ?? false;
          final bool isActive = isSubscription &&
              purchase.purchaseState == iap_types.PurchaseState.Purchased;

          if (isSubscription && isActive) {
            activeSubscriptions.add(
              iap_types.ActiveSubscription(
                productId: purchase.productId,
                isActive: true,
                autoRenewingAndroid: purchase.autoRenewingAndroid ?? false,
                transactionDate: purchase.transactionDate,
                transactionId: purchase.id,
                purchaseToken: purchase.purchaseToken,
              ),
            );
          }
        } else if (purchase is iap_types.PurchaseIOS) {
          final receipt = purchase.purchaseToken;
          final bool isSubscription =
              receipt != null || purchase.productId.contains('sub');
          final bool isActive = (purchase.purchaseState ==
                      iap_types.PurchaseState.Purchased ||
                  purchase.purchaseState == iap_types.PurchaseState.Restored) &&
              isSubscription;

          if (isSubscription && isActive) {
            activeSubscriptions.add(
              iap_types.ActiveSubscription(
                productId: purchase.productId,
                isActive: true,
                expirationDateIOS: purchase.expirationDateIOS,
                environmentIOS: purchase.environmentIOS,
                purchaseToken: purchase.purchaseToken,
                transactionDate: purchase.transactionDate,
                transactionId: purchase.id,
              ),
            );
          }
        }
      }

      return activeSubscriptions;
    } catch (e) {
      if (e is iap_types.PurchaseError) {
        rethrow;
      }
      throw iap_types.PurchaseError(
        code: iap_types.ErrorCode.ServiceError,
        message: 'Failed to get active subscriptions: ${e.toString()}',
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
      // For Android, also call native with explicit type for parity/logging
      if (_platform.isAndroid) {
        try {
          await _channel.invokeMethod('getAvailableItems', <String, dynamic>{
            'type': TypeInApp.subs.name,
          });
        } catch (_) {
          // Ignore; this is for logging/compatibility only
        }
      }
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

    final purchases = <iap_types.Purchase>[];
    for (final dynamic product in list) {
      try {
        final map = Map<String, dynamic>.from(product as Map);
        final original = Map<String, dynamic>.from(product);
        purchases.add(_convertFromLegacyPurchase(map, original));
      } catch (error) {
        debugPrint(
          '[flutter_inapp_purchase] Skipping purchase due to parse error: $error',
        );
      }
    }

    return purchases;
  }

  double? _parsePrice(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  iap_types.ProductType _parseProductType(dynamic value) {
    if (value is iap_types.ProductType) return value;
    final rawUpper = value?.toString().toUpperCase() ?? 'IN_APP';
    final normalized = rawUpper == 'INAPP' ? 'IN_APP' : rawUpper;
    try {
      return iap_types.ProductType.fromJson(normalized);
    } catch (_) {
      return normalized.contains('SUB')
          ? iap_types.ProductType.Subs
          : iap_types.ProductType.InApp;
    }
  }

  iap_types.ProductTypeIOS _parseProductTypeIOS(String? value) {
    final rawUpper = value?.toString().toUpperCase() ?? 'NON_CONSUMABLE';
    final normalized =
        rawUpper == 'NONCONSUMABLE' ? 'NON_CONSUMABLE' : rawUpper;
    try {
      return iap_types.ProductTypeIOS.fromJson(normalized);
    } catch (_) {
      switch (normalized) {
        case 'CONSUMABLE':
          return iap_types.ProductTypeIOS.Consumable;
        case 'AUTO_RENEWABLE_SUBSCRIPTION':
        case 'SUBS':
        case 'SUBSCRIPTION':
          return iap_types.ProductTypeIOS.AutoRenewableSubscription;
        case 'NON_RENEWING_SUBSCRIPTION':
          return iap_types.ProductTypeIOS.NonRenewingSubscription;
        default:
          return iap_types.ProductTypeIOS.NonConsumable;
      }
    }
  }

  iap_types.SubscriptionInfoIOS? _parseSubscriptionInfoIOS(dynamic value) {
    if (value is Map<String, dynamic>) {
      return iap_types.SubscriptionInfoIOS.fromJson(value);
    }
    if (value is Map) {
      return iap_types.SubscriptionInfoIOS.fromJson(
        Map<String, dynamic>.from(value),
      );
    }
    if (value is List && value.isNotEmpty) {
      final first = value.first;
      if (first is Map) {
        return iap_types.SubscriptionInfoIOS.fromJson(
          Map<String, dynamic>.from(first),
        );
      }
    }
    return null;
  }

  iap_types.SubscriptionPeriodIOS? _parseSubscriptionPeriod(dynamic value) {
    if (value == null) return null;
    final raw = value.toString().toUpperCase();
    try {
      return iap_types.SubscriptionPeriodIOS.fromJson(raw);
    } catch (_) {
      return null;
    }
  }

  iap_types.PaymentModeIOS? _parsePaymentMode(dynamic value) {
    if (value == null) return null;
    final raw = value.toString().toUpperCase();
    try {
      return iap_types.PaymentModeIOS.fromJson(raw);
    } catch (_) {
      return null;
    }
  }

  iap_types.ProductAndroidOneTimePurchaseOfferDetail?
      _parseOneTimePurchaseOfferDetail(dynamic value) {
    if (value is Map<String, dynamic>) {
      return iap_types.ProductAndroidOneTimePurchaseOfferDetail(
        formattedPrice: value['formattedPrice']?.toString() ?? '0',
        priceAmountMicros: value['priceAmountMicros']?.toString() ?? '0',
        priceCurrencyCode: value['priceCurrencyCode']?.toString() ?? 'USD',
      );
    }
    if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      return iap_types.ProductAndroidOneTimePurchaseOfferDetail(
        formattedPrice: map['formattedPrice']?.toString() ?? '0',
        priceAmountMicros: map['priceAmountMicros']?.toString() ?? '0',
        priceCurrencyCode: map['priceCurrencyCode']?.toString() ?? 'USD',
      );
    }
    return null;
  }
}

List<PurchaseResult>? extractResult(dynamic result) {
  // Handle both JSON string and already decoded List
  List<dynamic> list;
  if (result is String) {
    list = json.decode(result) as List<dynamic>;
  } else if (result is List) {
    list = result;
  } else {
    list = json.decode(result.toString()) as List<dynamic>;
  }

  final decoded = list
      .map<PurchaseResult>(
        (dynamic product) => PurchaseResult.fromJSON(
          Map<String, dynamic>.from(product as Map),
        ),
      )
      .toList();

  return decoded;
}

class PurchaseResult {
  PurchaseResult({
    this.responseCode,
    this.debugMessage,
    this.code,
    this.message,
    this.purchaseTokenAndroid,
  });

  final int? responseCode;
  final String? debugMessage;
  final String? code;
  final String? message;
  final String? purchaseTokenAndroid;

  factory PurchaseResult.fromJSON(Map<String, dynamic> json) {
    return PurchaseResult(
      responseCode: json['responseCode'] as int?,
      debugMessage: json['debugMessage']?.toString(),
      code: json['code']?.toString(),
      message: json['message']?.toString(),
      purchaseTokenAndroid: json['purchaseTokenAndroid']?.toString(),
    );
  }
}

class ConnectionResult {
  ConnectionResult({this.msg});

  final String? msg;

  factory ConnectionResult.fromJSON(Map<String, dynamic> json) {
    return ConnectionResult(msg: json['msg']?.toString());
  }
}
