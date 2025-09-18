import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:platform/platform.dart';

import 'enums.dart';
import 'errors.dart' as iap_err;
import 'types.dart' as gentype;
import 'modules/ios.dart';
import 'modules/android.dart';
import 'builders.dart';
import 'utils.dart';

export 'types.dart';
export 'builders.dart';
export 'utils.dart';
export 'extensions/purchase_helpers.dart';
export 'enums.dart' hide IapPlatform, ErrorCode, PurchaseState;
export 'errors.dart' show getCurrentPlatform;

typedef SubscriptionOfferAndroid = gentype.AndroidSubscriptionOfferInput;

/// Legacy purchase request container (pre-generated API).
class RequestPurchase {
  RequestPurchase({
    this.android,
    this.ios,
    gentype.ProductType? type,
  }) : type = type ??
            (android is RequestSubscriptionAndroid
                ? gentype.ProductType.Subs
                : gentype.ProductType.InApp);

  final RequestPurchaseAndroid? android;
  final RequestPurchaseIOS? ios;
  final gentype.ProductType type;

  gentype.RequestPurchaseProps toProps() {
    if (type == gentype.ProductType.InApp) {
      return gentype.RequestPurchaseProps.inApp(
        request: gentype.RequestPurchasePropsByPlatforms(
          android: android?.toInAppProps(),
          ios: ios?.toInAppProps(),
        ),
      );
    }

    return gentype.RequestPurchaseProps.subs(
      request: gentype.RequestSubscriptionPropsByPlatforms(
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

  gentype.RequestPurchaseAndroidProps toInAppProps() {
    return gentype.RequestPurchaseAndroidProps(
      skus: skus,
      obfuscatedAccountIdAndroid: obfuscatedAccountIdAndroid,
      obfuscatedProfileIdAndroid: obfuscatedProfileIdAndroid,
      isOfferPersonalized: isOfferPersonalized,
    );
  }

  gentype.RequestSubscriptionAndroidProps toSubscriptionProps() {
    return gentype.RequestSubscriptionAndroidProps(
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
  final List<gentype.AndroidSubscriptionOfferInput>? subscriptionOffers;

  @override
  gentype.RequestSubscriptionAndroidProps toSubscriptionProps() {
    return gentype.RequestSubscriptionAndroidProps(
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
  final gentype.DiscountOfferInputIOS? withOffer;
  final bool? andDangerouslyFinishTransactionAutomatically;

  gentype.RequestPurchaseIosProps toInAppProps() {
    return gentype.RequestPurchaseIosProps(
      sku: sku,
      quantity: quantity,
      appAccountToken: appAccountToken,
      andDangerouslyFinishTransactionAutomatically:
          andDangerouslyFinishTransactionAutomatically,
      withOffer: withOffer,
    );
  }

  gentype.RequestSubscriptionIosProps toSubscriptionProps() {
    return gentype.RequestSubscriptionIosProps(
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
  StreamController<gentype.Purchase?>? _purchaseController;
  Stream<gentype.Purchase?> get purchaseUpdated {
    _purchaseController ??= StreamController<gentype.Purchase?>.broadcast();
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
  List<gentype.Purchase>? extractPurchasedItems(dynamic result) {
    return extractPurchases(result);
  }

  // Purchase event streams
  final StreamController<gentype.Purchase> _purchaseUpdatedListener =
      StreamController<gentype.Purchase>.broadcast();
  final StreamController<gentype.PurchaseError> _purchaseErrorListener =
      StreamController<gentype.PurchaseError>.broadcast();

  /// Purchase updated event stream
  Stream<gentype.Purchase> get purchaseUpdatedListener =>
      _purchaseUpdatedListener.stream;

  /// Purchase error event stream
  Stream<gentype.PurchaseError> get purchaseErrorListener =>
      _purchaseErrorListener.stream;

  bool _isInitialized = false;

  /// Initialize connection (flutter IAP compatible)
  gentype.MutationInitConnectionHandler get initConnection => () async {
        if (_isInitialized) {
          return true;
        }

        try {
          await _setPurchaseListener();
          await _channel.invokeMethod('initConnection');
          _isInitialized = true;
          return true;
        } catch (error) {
          throw gentype.PurchaseError(
            code: gentype.ErrorCode.NotPrepared,
            message: 'Failed to initialize IAP connection: ${error.toString()}',
          );
        }
      };

  /// End connection (flutter IAP compatible)
  gentype.MutationEndConnectionHandler get endConnection => () async {
        if (!_isInitialized) {
          return false;
        }

        try {
          // For flutter IAP compatibility, call endConnection directly
          await _channel.invokeMethod('endConnection');

          _isInitialized = false;
          return true;
        } catch (error) {
          throw gentype.PurchaseError(
            code: gentype.ErrorCode.ServiceError,
            message: 'Failed to end IAP connection: ${error.toString()}',
          );
        }
      };

  /// Request purchase (flutter IAP compatible)
  gentype.MutationRequestPurchaseHandler get requestPurchase =>
      (gentype.RequestPurchaseProps params) async {
        if (!_isInitialized) {
          throw const gentype.PurchaseError(
            code: gentype.ErrorCode.NotPrepared,
            message: 'IAP connection not initialized',
          );
        }

        if (params.type == gentype.ProductQueryType.All) {
          throw const gentype.PurchaseError(
            code: gentype.ErrorCode.DeveloperError,
            message:
                'requestPurchase only supports IN_APP or SUBS request types',
          );
        }

        final nativeType = _resolveProductType(params.type);

        try {
          if (_platform.isIOS) {
            final requestVariant = params.request;
            String? sku;
            bool autoFinish = false;
            String? appAccountToken;
            int? quantity;
            gentype.DiscountOfferInputIOS? offer;

            if (requestVariant
                is gentype.RequestPurchasePropsRequestSubscription) {
              final iosProps = requestVariant.value.ios;
              if (iosProps == null) {
                throw const gentype.PurchaseError(
                  code: gentype.ErrorCode.DeveloperError,
                  message: 'Missing iOS purchase parameters',
                );
              }
              sku = iosProps.sku;
              autoFinish =
                  iosProps.andDangerouslyFinishTransactionAutomatically ??
                      false;
              appAccountToken = iosProps.appAccountToken;
              quantity = iosProps.quantity;
              offer = iosProps.withOffer;
            } else if (requestVariant
                is gentype.RequestPurchasePropsRequestPurchase) {
              final iosProps = requestVariant.value.ios;
              if (iosProps == null) {
                throw const gentype.PurchaseError(
                  code: gentype.ErrorCode.DeveloperError,
                  message: 'Missing iOS purchase parameters',
                );
              }
              sku = iosProps.sku;
              autoFinish =
                  iosProps.andDangerouslyFinishTransactionAutomatically ??
                      false;
              appAccountToken = iosProps.appAccountToken;
              quantity = iosProps.quantity;
              offer = iosProps.withOffer;
            }

            if (sku == null || sku.isEmpty) {
              throw const gentype.PurchaseError(
                code: gentype.ErrorCode.DeveloperError,
                message: 'Missing iOS purchase parameters',
              );
            }

            final payload = <String, dynamic>{
              'sku': sku,
              'andDangerouslyFinishTransactionAutomatically': autoFinish,
            };

            if (appAccountToken != null && appAccountToken.isNotEmpty) {
              payload['appAccountToken'] = appAccountToken;
            }

            if (quantity != null) {
              payload['quantity'] = quantity;
            }

            if (offer != null) {
              payload['withOffer'] = {
                'identifier': offer.identifier,
                'keyIdentifier': offer.keyIdentifier,
                'nonce': offer.nonce,
                'signature': offer.signature,
                'timestamp': offer.timestamp.toString(),
              };
            }

            await _channel.invokeMethod('requestPurchase', payload);
            return null;
          }

          if (_platform.isAndroid) {
            final requestVariant = params.request;

            if (requestVariant
                is gentype.RequestPurchasePropsRequestSubscription) {
              final androidProps = requestVariant.value.android;
              if (androidProps == null) {
                throw const gentype.PurchaseError(
                  code: gentype.ErrorCode.DeveloperError,
                  message: 'Missing Android subscription parameters',
                );
              }
              if (androidProps.skus.isEmpty) {
                throw const gentype.PurchaseError(
                  code: gentype.ErrorCode.EmptySkuList,
                  message: 'Android subscription requires at least one SKU',
                );
              }
              if (androidProps.replacementModeAndroid != null &&
                  androidProps.replacementModeAndroid != -1 &&
                  (androidProps.purchaseTokenAndroid == null ||
                      androidProps.purchaseTokenAndroid!.isEmpty)) {
                throw const gentype.PurchaseError(
                  code: gentype.ErrorCode.DeveloperError,
                  message:
                      'purchaseTokenAndroid is required when using replacementModeAndroid (proration mode). '
                      'Use getAvailablePurchases() to obtain the current purchase token.',
                );
              }

              final payload = <String, dynamic>{
                'type': nativeType,
                'skus': androidProps.skus,
                'productId': androidProps.skus.first,
                'isOfferPersonalized':
                    androidProps.isOfferPersonalized ?? false,
              };

              final obfuscatedAccount = androidProps.obfuscatedAccountIdAndroid;
              if (obfuscatedAccount != null) {
                payload['obfuscatedAccountId'] = obfuscatedAccount;
                payload['obfuscatedAccountIdAndroid'] = obfuscatedAccount;
              }

              final obfuscatedProfile = androidProps.obfuscatedProfileIdAndroid;
              if (obfuscatedProfile != null) {
                payload['obfuscatedProfileId'] = obfuscatedProfile;
                payload['obfuscatedProfileIdAndroid'] = obfuscatedProfile;
              }

              final purchaseToken = androidProps.purchaseTokenAndroid;
              if (purchaseToken != null) {
                payload['purchaseToken'] = purchaseToken;
                payload['purchaseTokenAndroid'] = purchaseToken;
              }

              final replacementMode = androidProps.replacementModeAndroid;
              if (replacementMode != null) {
                payload['replacementMode'] = replacementMode;
                payload['replacementModeAndroid'] = replacementMode;
              }

              final offers = androidProps.subscriptionOffers;
              if (offers != null && offers.isNotEmpty) {
                payload['subscriptionOffers'] =
                    offers.map((offer) => offer.toJson()).toList();
              }

              await _channel.invokeMethod('requestPurchase', payload);
              return null;
            }

            final androidProps =
                (requestVariant as gentype.RequestPurchasePropsRequestPurchase)
                    .value
                    .android;
            if (androidProps == null) {
              throw const gentype.PurchaseError(
                code: gentype.ErrorCode.DeveloperError,
                message: 'Missing Android purchase parameters',
              );
            }
            if (androidProps.skus.isEmpty) {
              throw const gentype.PurchaseError(
                code: gentype.ErrorCode.EmptySkuList,
                message: 'Android purchase requires at least one SKU',
              );
            }

            final payload = <String, dynamic>{
              'type': nativeType,
              'skus': androidProps.skus,
              'productId': androidProps.skus.first,
              'isOfferPersonalized': androidProps.isOfferPersonalized ?? false,
            };

            final obfuscatedAccount = androidProps.obfuscatedAccountIdAndroid;
            if (obfuscatedAccount != null) {
              payload['obfuscatedAccountId'] = obfuscatedAccount;
              payload['obfuscatedAccountIdAndroid'] = obfuscatedAccount;
            }

            final obfuscatedProfile = androidProps.obfuscatedProfileIdAndroid;
            if (obfuscatedProfile != null) {
              payload['obfuscatedProfileId'] = obfuscatedProfile;
              payload['obfuscatedProfileIdAndroid'] = obfuscatedProfile;
            }

            await _channel.invokeMethod('requestPurchase', payload);
            return null;
          }

          throw const gentype.PurchaseError(
            code: gentype.ErrorCode.IapNotAvailable,
            message: 'requestPurchase is not supported on this platform',
          );
        } catch (error) {
          if (error is gentype.PurchaseError) {
            rethrow;
          }
          throw gentype.PurchaseError(
            code: gentype.ErrorCode.ServiceError,
            message: 'Failed to request purchase: ${error.toString()}',
          );
        }
      };

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

    await requestPurchase(props);
  }

  /// DSL-like request subscription method with builder pattern
  // requestSubscriptionWithBuilder removed in 6.6.0 (use requestPurchaseWithBuilder)

  /// Get all available purchases (OpenIAP standard)
  /// Returns non-consumed purchases that are still pending acknowledgment or consumption
  ///
  /// [options] - Optional configuration for the method behavior
  /// - onlyIncludeActiveItemsIOS: Whether to only include active items (default: true)
  ///   Set to false to include expired subscriptions
  gentype.QueryGetAvailablePurchasesHandler get getAvailablePurchases =>
      ([gentype.PurchaseOptions? options]) async {
        if (!_isInitialized) {
          throw const gentype.PurchaseError(
            code: gentype.ErrorCode.NotPrepared,
            message: 'IAP connection not initialized',
          );
        }

        try {
          if (_platform.isAndroid) {
            // Android unified available items
            final dynamic result =
                await _channel.invokeMethod('getAvailableItems');
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

            final dynamic result =
                await _channel.invokeMethod('getAvailableItems', args);
            final items = extractPurchases(result) ?? [];
            return items
                .where((p) =>
                    p.productId.isNotEmpty &&
                    (p.purchaseToken != null && p.purchaseToken!.isNotEmpty))
                .toList();
          }
          return const <gentype.Purchase>[];
        } catch (error) {
          throw gentype.PurchaseError(
            code: gentype.ErrorCode.ServiceError,
            message: 'Failed to get available purchases: ${error.toString()}',
          );
        }
      };

  /// iOS specific: Get storefront
  gentype.QueryGetStorefrontIOSHandler get getStorefrontIOS => () async {
        if (!_platform.isIOS) {
          throw const gentype.PurchaseError(
            code: gentype.ErrorCode.IapNotAvailable,
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
          throw const gentype.PurchaseError(
            code: gentype.ErrorCode.ServiceError,
            message: 'Failed to get storefront country code',
          );
        } catch (error) {
          if (error is gentype.PurchaseError) {
            rethrow;
          }
          throw gentype.PurchaseError(
            code: gentype.ErrorCode.ServiceError,
            message: 'Failed to get storefront: ${error.toString()}',
          );
        }
      };

  String _resolveProductType(Object type) {
    if (type is String) {
      return type;
    }
    if (type is TypeInApp) {
      return type.name;
    }
    if (type is gentype.ProductType) {
      return type == gentype.ProductType.InApp
          ? TypeInApp.inapp.name
          : TypeInApp.subs.name;
    }
    if (type is gentype.ProductQueryType) {
      switch (type) {
        case gentype.ProductQueryType.InApp:
          return TypeInApp.inapp.name;
        case gentype.ProductQueryType.Subs:
          return TypeInApp.subs.name;
        case gentype.ProductQueryType.All:
          return 'all';
      }
    }
    return TypeInApp.inapp.name;
  }

  /// iOS specific: Present code redemption sheet
  @override
  gentype.MutationPresentCodeRedemptionSheetIOSHandler
      get presentCodeRedemptionSheetIOS => () async {
            if (!_platform.isIOS) {
              throw PlatformException(
                code: 'platform',
                message:
                    'presentCodeRedemptionSheetIOS is only supported on iOS',
              );
            }

            try {
              await channel.invokeMethod('presentCodeRedemptionSheetIOS');
              return true;
            } catch (error) {
              throw gentype.PurchaseError(
                code: gentype.ErrorCode.ServiceError,
                message:
                    'Failed to present code redemption sheet: ${error.toString()}',
              );
            }
          };

  /// iOS specific: Show manage subscriptions
  @override
  gentype.MutationShowManageSubscriptionsIOSHandler
      get showManageSubscriptionsIOS => () async {
            if (!_platform.isIOS) {
              throw PlatformException(
                code: 'platform',
                message: 'showManageSubscriptionsIOS is only supported on iOS',
              );
            }

            try {
              await channel.invokeMethod('showManageSubscriptionsIOS');
              return const <gentype.PurchaseIOS>[];
            } catch (error) {
              throw gentype.PurchaseError(
                code: gentype.ErrorCode.ServiceError,
                message:
                    'Failed to show manage subscriptions: ${error.toString()}',
              );
            }
          };

  // Android-specific deep link helper removed in 6.6.0

  gentype.ProductCommon _parseProductFromNative(
    Map<String, dynamic> json,
    String type,
  ) {
    // Determine platform from JSON data if available, otherwise use heuristics, then runtime
    gentype.IapPlatform platform;
    final dynamic platformRaw = json['platform'];
    if (platformRaw is String) {
      final v = platformRaw.toLowerCase();
      platform = (v == 'android')
          ? gentype.IapPlatform.Android
          : gentype.IapPlatform.IOS;
    } else if (platformRaw is gentype.IapPlatform) {
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
        platform = gentype.IapPlatform.Android;
      } else if (looksIOS && !looksAndroid) {
        platform = gentype.IapPlatform.IOS;
      } else {
        // Fallback to current runtime platform
        platform = _platform.isIOS
            ? gentype.IapPlatform.IOS
            : gentype.IapPlatform.Android;
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

    if (productType == gentype.ProductType.Subs) {
      if (platform == gentype.IapPlatform.IOS) {
        return gentype.ProductSubscriptionIOS(
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

      return gentype.ProductSubscriptionAndroid(
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

    if (platform == gentype.IapPlatform.IOS) {
      return gentype.ProductIOS(
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

    return gentype.ProductAndroid(
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

  List<gentype.DiscountIOS>? _parseDiscountsIOS(dynamic json) {
    if (json == null) return null;
    final list = json as List<dynamic>;
    return list
        .map(
          (e) => gentype.DiscountIOS.fromJson(
            e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList();
  }

  List<gentype.ProductSubscriptionAndroidOfferDetails> _parseOfferDetails(
    dynamic json,
  ) {
    if (json == null) {
      return const <gentype.ProductSubscriptionAndroidOfferDetails>[];
    }

    // Handle both List and String (JSON string from Android)
    List<dynamic> list;
    if (json is String) {
      // Parse JSON string from Android
      try {
        final parsed = jsonDecode(json);
        if (parsed is! List) {
          return const <gentype.ProductSubscriptionAndroidOfferDetails>[];
        }
        list = parsed;
      } catch (e) {
        return const <gentype.ProductSubscriptionAndroidOfferDetails>[];
      }
    } else if (json is List) {
      list = json;
    } else {
      return const <gentype.ProductSubscriptionAndroidOfferDetails>[];
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

          return gentype.ProductSubscriptionAndroidOfferDetails(
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
        .whereType<gentype.ProductSubscriptionAndroidOfferDetails>()
        .toList();
  }

  gentype.PricingPhasesAndroid _parsePricingPhases(dynamic json) {
    if (json == null) {
      return const gentype.PricingPhasesAndroid(pricingPhaseList: []);
    }

    // Handle nested structure from Android
    List<dynamic>? list;
    if (json is Map && json['pricingPhaseList'] != null) {
      list = json['pricingPhaseList'] as List<dynamic>?;
    } else if (json is List) {
      list = json;
    }

    if (list == null) {
      return const gentype.PricingPhasesAndroid(pricingPhaseList: []);
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

          return gentype.PricingPhaseAndroid(
            billingCycleCount: (e['billingCycleCount'] as num?)?.toInt() ?? 0,
            billingPeriod: e['billingPeriod']?.toString() ?? '',
            formattedPrice: e['formattedPrice']?.toString() ?? '0',
            priceAmountMicros: priceAmountMicros?.toString() ?? '0',
            priceCurrencyCode: e['priceCurrencyCode']?.toString() ?? 'USD',
            recurrenceMode: recurrenceMode is int ? recurrenceMode : 0,
          );
        })
        .whereType<gentype.PricingPhaseAndroid>()
        .toList();

    return gentype.PricingPhasesAndroid(pricingPhaseList: phases);
  }

  gentype.PurchaseState _parsePurchaseStateIOS(dynamic value) {
    if (value is gentype.PurchaseState) return value;
    if (value is String) {
      switch (value.toLowerCase()) {
        case 'purchasing':
        case 'pending':
          return gentype.PurchaseState.Pending;
        case 'purchased':
        case 'restored':
          return gentype.PurchaseState.Purchased;
        case 'failed':
          return gentype.PurchaseState.Failed;
        case 'deferred':
          return gentype.PurchaseState.Deferred;
        default:
          return gentype.PurchaseState.Unknown;
      }
    }
    if (value is num) {
      switch (value.toInt()) {
        case 0:
          return gentype.PurchaseState.Pending;
        case 1:
          return gentype.PurchaseState.Purchased;
        case 2:
          return gentype.PurchaseState.Failed;
        case 3:
          return gentype.PurchaseState.Purchased;
        case 4:
          return gentype.PurchaseState.Deferred;
      }
    }
    return gentype.PurchaseState.Unknown;
  }

  gentype.PurchaseState _mapAndroidPurchaseState(int stateValue) {
    final state = androidPurchaseStateFromValue(stateValue);
    switch (state) {
      case AndroidPurchaseState.Purchased:
        return gentype.PurchaseState.Purchased;
      case AndroidPurchaseState.Pending:
        return gentype.PurchaseState.Pending;
      case AndroidPurchaseState.Unknown:
        return gentype.PurchaseState.Unknown;
    }
  }

  gentype.Purchase _convertFromLegacyPurchase(
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
        'platform': gentype.IapPlatform.Android.toJson(),
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

      return gentype.PurchaseAndroid.fromJson(map);
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
      'platform': gentype.IapPlatform.IOS.toJson(),
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

    return gentype.PurchaseIOS.fromJson(map);
  }

  gentype.PurchaseError _convertToPurchaseError(
    PurchaseResult result,
  ) {
    gentype.ErrorCode code = gentype.ErrorCode.Unknown;

    // Prefer OpenIAP string codes when present (works cross-platform)
    if (result.code != null && result.code!.isNotEmpty) {
      final detected = iap_err.ErrorCodeUtils.fromPlatformCode(
        result.code!,
        _platform.isIOS ? gentype.IapPlatform.IOS : gentype.IapPlatform.Android,
      );
      if (detected != gentype.ErrorCode.Unknown) {
        code = detected;
      }
    }

    // Map error codes
    // Fallback to legacy numeric response codes when string code is absent
    if (code == gentype.ErrorCode.Unknown) {
      switch (result.responseCode) {
        case 0:
          code = gentype.ErrorCode.Unknown;
          break;
        case 1:
          code = gentype.ErrorCode.UserCancelled;
          break;
        case 2:
          code = gentype.ErrorCode.ServiceError;
          break;
        case 3:
          code = gentype.ErrorCode.BillingUnavailable;
          break;
        case 4:
          code = gentype.ErrorCode.ItemUnavailable;
          break;
        case 5:
          code = gentype.ErrorCode.DeveloperError;
          break;
        case 6:
          code = gentype.ErrorCode.Unknown;
          break;
        case 7:
          code = gentype.ErrorCode.AlreadyOwned;
          break;
        case 8:
          code = gentype.ErrorCode.PurchaseError;
          break;
      }
    }

    return gentype.PurchaseError(
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
        throw gentype.PurchaseError(
          code: gentype.ErrorCode.DeveloperError,
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

  gentype.QueryGetPendingTransactionsIOSHandler get getPendingTransactionsIOS =>
      () async {
        if (_platform.isIOS) {
          final dynamic result =
              await _channel.invokeMethod('getPendingTransactionsIOS');
          final purchases = extractPurchases(result) ?? [];
          return purchases
              .whereType<gentype.PurchaseIOS>()
              .toList(growable: false);
        }
        return const <gentype.PurchaseIOS>[];
      };

  /// Typed wrapper that returns both products and subscriptions using generated types.
  Future<gentype.FetchProductsResult> requestProducts({
    required List<String> skus,
    gentype.ProductQueryType type = gentype.ProductQueryType.InApp,
  }) {
    return requestProductsWithParams(
      gentype.ProductRequest(
        skus: skus,
        type: type,
      ),
    );
  }

  /// Request products using a fully typed [ProductRequest].
  Future<gentype.FetchProductsResult> requestProductsWithParams(
    gentype.ProductRequest request,
  ) async {
    final queryType = request.type ?? gentype.ProductQueryType.InApp;

    if (queryType == gentype.ProductQueryType.All) {
      throw const gentype.PurchaseError(
        code: gentype.ErrorCode.DeveloperError,
        message:
            'requestProductsWithParams does not support ProductQueryType.All. '
            'Query in-app products and subscriptions separately.',
      );
    }

    if (queryType == gentype.ProductQueryType.Subs) {
      final subscriptions = await fetchProducts<gentype.ProductSubscription>(
        skus: request.skus,
        type: queryType,
      );
      return gentype.FetchProductsResultSubscriptions(subscriptions);
    }

    final products = await fetchProducts<gentype.Product>(
      skus: request.skus,
      type: queryType,
    );
    return gentype.FetchProductsResultProducts(products);
  }

  @override
  gentype.MutationConsumePurchaseAndroidHandler get consumePurchaseAndroid =>
      (String purchaseToken) async {
        if (!_platform.isAndroid) {
          throw const gentype.PurchaseError(
            code: gentype.ErrorCode.IapNotAvailable,
            message: 'consumePurchaseAndroid is only available on Android',
          );
        }

        try {
          final dynamic response = await _channel.invokeMethod(
            'consumePurchaseAndroid',
            {'purchaseToken': purchaseToken},
          );

          if (response is Map) {
            final map = Map<String, dynamic>.from(response);
            return map['success'] as bool? ?? true;
          }

          if (response is bool) {
            return response;
          }

          return true;
        } catch (error) {
          debugPrint('Error consuming purchase: $error');
          return false;
        }
      };

  /// Finish a transaction using Purchase object (OpenIAP compliant)
  Future<void> finishTransaction(
    gentype.Purchase purchase, {
    bool isConsumable = false,
  }) async {
    // Use purchase.id (OpenIAP standard) if available, fallback to transactionId for backward compatibility
    final transactionId = purchase.id;

    if (_platform.isAndroid) {
      final androidPurchase = purchase as gentype.PurchaseAndroid;

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
  gentype.QueryValidateReceiptIOSHandler get validateReceiptIOS =>
      (gentype.ReceiptValidationProps options) async {
        if (!_platform.isIOS) {
          throw const gentype.PurchaseError(
            code: gentype.ErrorCode.IapNotAvailable,
            message: 'Receipt validation is only available on iOS',
          );
        }

        if (!_isInitialized) {
          throw const gentype.PurchaseError(
            code: gentype.ErrorCode.NotPrepared,
            message: 'IAP connection not initialized',
          );
        }

        final sku = options.sku.trim();
        if (sku.isEmpty) {
          throw const gentype.PurchaseError(
            code: gentype.ErrorCode.DeveloperError,
            message: 'sku cannot be empty',
          );
        }

        try {
          final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
            'validateReceiptIOS',
            {'sku': sku},
          );

          if (result == null) {
            throw const gentype.PurchaseError(
              code: gentype.ErrorCode.ServiceError,
              message: 'No validation result received from native platform',
            );
          }

          final validationResult = Map<String, dynamic>.from(result);
          final latestTransactionMap = validationResult['latestTransaction'];
          final latestTransaction = latestTransactionMap is Map
              ? gentype.Purchase.fromJson(
                  Map<String, dynamic>.from(latestTransactionMap),
                )
              : null;

          return gentype.ReceiptValidationResultIOS(
            isValid: validationResult['isValid'] as bool? ?? false,
            jwsRepresentation:
                validationResult['jwsRepresentation']?.toString() ?? '',
            receiptData: validationResult['receiptData']?.toString() ?? '',
            latestTransaction: latestTransaction,
          );
        } on PlatformException catch (error) {
          throw gentype.PurchaseError(
            code: gentype.ErrorCode.ServiceError,
            message:
                'Failed to validate receipt [${error.code}]: ${error.message ?? error.details}',
          );
        } catch (error) {
          throw gentype.PurchaseError(
            code: gentype.ErrorCode.ServiceError,
            message: 'Failed to validate receipt: ${error.toString()}',
          );
        }
      };
  gentype.MutationValidateReceiptHandler get validateReceipt =>
      (gentype.ReceiptValidationProps options) async {
        if (_platform.isIOS) {
          return await validateReceiptIOS(options);
        }
        if (_platform.isAndroid) {
          return _validateReceiptAndroid(options: options);
        }
        throw const gentype.PurchaseError(
          code: gentype.ErrorCode.IapNotAvailable,
          message: 'Platform not supported for receipt validation',
        );
      };
  Future<gentype.ReceiptValidationResult> _validateReceiptAndroid({
    required gentype.ReceiptValidationProps options,
  }) async {
    throw const gentype.PurchaseError(
      code: gentype.ErrorCode.IapNotAvailable,
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
  Future<List<T>> fetchProducts<T extends gentype.ProductCommon>({
    required List<String> skus,
    Object type = TypeInApp.inapp,
  }) async {
    if (!_isInitialized) {
      throw const gentype.PurchaseError(
        code: gentype.ErrorCode.NotPrepared,
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
      final List<gentype.ProductCommon> products = [];
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
      throw gentype.PurchaseError(
        code: gentype.ErrorCode.ServiceError,
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
  gentype.MutationRestorePurchasesHandler get restorePurchases => () async {
        try {
          if (_platform.isIOS) {
            try {
              await syncIOS();
            } catch (error) {
              // Soft-fail on sync error; apps can handle via logs
              debugPrint(
                '[flutter_inapp_purchase] Error restoring purchases (iOS sync): $error',
              );
            }
          }
          // Fetch available purchases using the public API
          await getAvailablePurchases();
        } catch (error) {
          debugPrint(
            '[flutter_inapp_purchase] Failed to restore purchases: $error',
          );
        }
      };

  /// Get all active subscriptions with detailed information (OpenIAP compliant)
  /// Returns an array of active subscriptions. If subscriptionIds is not provided,
  /// returns all active subscriptions. Platform-specific fields are populated based
  /// on the current platform.
  gentype.QueryGetActiveSubscriptionsHandler get getActiveSubscriptions =>
      ([List<String>? subscriptionIds]) async {
        if (!_isInitialized) {
          throw const gentype.PurchaseError(
            code: gentype.ErrorCode.NotPrepared,
            message: 'IAP connection not initialized',
          );
        }

        try {
          // Get all available purchases (which includes active subscriptions)
          final purchases = await getAvailablePurchases();

          // Filter to only active subscriptions
          final List<gentype.ActiveSubscription> activeSubscriptions = [];

          for (final purchase in purchases) {
            if (subscriptionIds != null &&
                !subscriptionIds.contains(purchase.productId)) {
              continue;
            }

            if (purchase is gentype.PurchaseAndroid) {
              final bool isSubscription = purchase.autoRenewingAndroid ?? false;
              final bool isActive = isSubscription &&
                  purchase.purchaseState == gentype.PurchaseState.Purchased;

              if (isSubscription && isActive) {
                activeSubscriptions.add(
                  gentype.ActiveSubscription(
                    productId: purchase.productId,
                    isActive: true,
                    autoRenewingAndroid: purchase.autoRenewingAndroid ?? false,
                    transactionDate: purchase.transactionDate,
                    transactionId: purchase.id,
                    purchaseToken: purchase.purchaseToken,
                  ),
                );
              }
            } else if (purchase is gentype.PurchaseIOS) {
              final receipt = purchase.purchaseToken;
              final bool isSubscription =
                  receipt != null || purchase.productId.contains('sub');
              final bool isActive =
                  (purchase.purchaseState == gentype.PurchaseState.Purchased ||
                          purchase.purchaseState ==
                              gentype.PurchaseState.Restored) &&
                      isSubscription;

              if (isSubscription && isActive) {
                activeSubscriptions.add(
                  gentype.ActiveSubscription(
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
        } catch (error) {
          if (error is gentype.PurchaseError) {
            rethrow;
          }
          throw gentype.PurchaseError(
            code: gentype.ErrorCode.ServiceError,
            message: 'Failed to get active subscriptions: ${error.toString()}',
          );
        }
      };

  /// Check if the user has any active subscriptions (OpenIAP compliant)
  /// Returns true if the user has at least one active subscription, false otherwise.
  /// If subscriptionIds is provided, only checks for those specific subscriptions.
  gentype.QueryHasActiveSubscriptionsHandler get hasActiveSubscriptions =>
      ([List<String>? subscriptionIds]) async {
        try {
          final activeSubscriptions = await getActiveSubscriptions(
            subscriptionIds,
          );
          // For Android, also call native with explicit type for parity/logging
          if (_platform.isAndroid) {
            try {
              await _channel
                  .invokeMethod('getAvailableItems', <String, dynamic>{
                'type': TypeInApp.subs.name,
              });
            } catch (_) {
              // Ignore; this is for logging/compatibility only
            }
          }
          return activeSubscriptions.isNotEmpty;
        } catch (error) {
          // If there's an error getting subscriptions, return false
          debugPrint('Error checking active subscriptions: $error');
          return false;
        }
      };

  List<gentype.Purchase>? extractPurchases(dynamic result) {
    // Handle both JSON string and already decoded List
    List<dynamic> list;
    if (result is String) {
      list = json.decode(result) as List<dynamic>;
    } else if (result is List) {
      list = result;
    } else {
      list = json.decode(result.toString()) as List<dynamic>;
    }

    final purchases = <gentype.Purchase>[];
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

  gentype.ProductType _parseProductType(dynamic value) {
    if (value is gentype.ProductType) return value;
    final rawUpper = value?.toString().toUpperCase() ?? 'IN_APP';
    final normalized = rawUpper == 'INAPP' ? 'IN_APP' : rawUpper;
    try {
      return gentype.ProductType.fromJson(normalized);
    } catch (_) {
      return normalized.contains('SUB')
          ? gentype.ProductType.Subs
          : gentype.ProductType.InApp;
    }
  }

  gentype.ProductTypeIOS _parseProductTypeIOS(String? value) {
    final rawUpper = value?.toString().toUpperCase() ?? 'NON_CONSUMABLE';
    final normalized =
        rawUpper == 'NONCONSUMABLE' ? 'NON_CONSUMABLE' : rawUpper;
    try {
      return gentype.ProductTypeIOS.fromJson(normalized);
    } catch (_) {
      switch (normalized) {
        case 'CONSUMABLE':
          return gentype.ProductTypeIOS.Consumable;
        case 'AUTO_RENEWABLE_SUBSCRIPTION':
        case 'SUBS':
        case 'SUBSCRIPTION':
          return gentype.ProductTypeIOS.AutoRenewableSubscription;
        case 'NON_RENEWING_SUBSCRIPTION':
          return gentype.ProductTypeIOS.NonRenewingSubscription;
        default:
          return gentype.ProductTypeIOS.NonConsumable;
      }
    }
  }

  gentype.SubscriptionInfoIOS? _parseSubscriptionInfoIOS(dynamic value) {
    if (value is Map<String, dynamic>) {
      return gentype.SubscriptionInfoIOS.fromJson(value);
    }
    if (value is Map) {
      return gentype.SubscriptionInfoIOS.fromJson(
        Map<String, dynamic>.from(value),
      );
    }
    if (value is List && value.isNotEmpty) {
      final first = value.first;
      if (first is Map) {
        return gentype.SubscriptionInfoIOS.fromJson(
          Map<String, dynamic>.from(first),
        );
      }
    }
    return null;
  }

  gentype.SubscriptionPeriodIOS? _parseSubscriptionPeriod(dynamic value) {
    if (value == null) return null;
    final raw = value.toString().toUpperCase();
    try {
      return gentype.SubscriptionPeriodIOS.fromJson(raw);
    } catch (_) {
      return null;
    }
  }

  gentype.PaymentModeIOS? _parsePaymentMode(dynamic value) {
    if (value == null) return null;
    final raw = value.toString().toUpperCase();
    try {
      return gentype.PaymentModeIOS.fromJson(raw);
    } catch (_) {
      return null;
    }
  }

  gentype.ProductAndroidOneTimePurchaseOfferDetail?
      _parseOneTimePurchaseOfferDetail(dynamic value) {
    if (value is Map<String, dynamic>) {
      return gentype.ProductAndroidOneTimePurchaseOfferDetail(
        formattedPrice: value['formattedPrice']?.toString() ?? '0',
        priceAmountMicros: value['priceAmountMicros']?.toString() ?? '0',
        priceCurrencyCode: value['priceCurrencyCode']?.toString() ?? 'USD',
      );
    }
    if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      return gentype.ProductAndroidOneTimePurchaseOfferDetail(
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
