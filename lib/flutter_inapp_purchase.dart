import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:platform/platform.dart';

import 'enums.dart';
import 'types.dart' as gentype;
import 'builders.dart';
import 'helpers.dart';
import 'utils.dart';
import 'errors.dart' as errors;

export 'types.dart' hide PurchaseError;
export 'builders.dart';
export 'utils.dart';
export 'helpers.dart' hide PurchaseResult, ConnectionResult;
export 'extensions/purchase_helpers.dart';
export 'enums.dart' hide IapPlatform, PurchaseState;
export 'errors.dart'
    show
        getCurrentPlatform,
        PurchaseError,
        ErrorCodeUtils,
        PurchaseResult,
        ConnectionResult,
        getUserFriendlyErrorMessage;

typedef PurchaseError = errors.PurchaseError;
typedef SubscriptionOfferAndroid = gentype.AndroidSubscriptionOfferInput;

class FlutterInappPurchase with RequestPurchaseBuilderApi {
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

  final Map<String, bool> _acknowledgedAndroidPurchaseTokens = <String, bool>{};

  /// Defining the [MethodChannel] for Flutter_Inapp_Purchase
  final MethodChannel _channel = const MethodChannel('flutter_inapp');

  MethodChannel get channel => _channel;

  Platform get _platform => _pf;
  // Public getters used by platform mixins
  bool get isIOS => _platform.isIOS;
  bool get isAndroid => _platform.isAndroid;
  String get operatingSystem => _platform.operatingSystem;

  final Platform _pf;

  FlutterInappPurchase({Platform? platform})
      : _pf = platform ?? const LocalPlatform();

  @visibleForTesting
  FlutterInappPurchase.private(Platform platform) : _pf = platform;

  // Purchase event streams
  final StreamController<gentype.Purchase> _purchaseUpdatedListener =
      StreamController<gentype.Purchase>.broadcast();
  final StreamController<PurchaseError> _purchaseErrorListener =
      StreamController<PurchaseError>.broadcast();

  /// Purchase updated event stream
  Stream<gentype.Purchase> get purchaseUpdatedListener =>
      _purchaseUpdatedListener.stream;

  /// Purchase error event stream
  Stream<PurchaseError> get purchaseErrorListener =>
      _purchaseErrorListener.stream;

  bool _isInitialized = false;

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
            final purchase = convertToPurchase(
              result,
              originalJson: result,
              platformIsAndroid: _platform.isAndroid,
              platformIsIOS: _platform.isIOS,
              acknowledgedAndroidPurchaseTokens:
                  _acknowledgedAndroidPurchaseTokens,
            );

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
          final error = convertToPurchaseError(
            purchaseResult,
            platform: _platform.isIOS
                ? gentype.IapPlatform.IOS
                : gentype.IapPlatform.Android,
          );
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
        default:
          throw ArgumentError('Unknown method ${call.method}');
      }
      return Future.value(null);
    });
  }

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
          throw PurchaseError(
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
          throw PurchaseError(
            code: gentype.ErrorCode.ServiceError,
            message: 'Failed to end IAP connection: ${error.toString()}',
          );
        }
      };

  /// Request purchase (flutter IAP compatible)
  @override
  gentype.MutationRequestPurchaseHandler get requestPurchase => (params) async {
        if (!_isInitialized) {
          throw PurchaseError(
            code: gentype.ErrorCode.NotPrepared,
            message: 'IAP connection not initialized',
          );
        }

        if (params.type == gentype.ProductQueryType.All) {
          throw PurchaseError(
            code: gentype.ErrorCode.DeveloperError,
            message:
                'requestPurchase only supports IN_APP or SUBS request types',
          );
        }

        final nativeType = resolveProductType(params.type);

        try {
          if (_platform.isIOS) {
            final requestVariant = params.request;

            Map<String, dynamic>? payload;

            if (requestVariant
                is gentype.RequestPurchasePropsRequestSubscription) {
              payload = _buildIosPurchasePayload(
                nativeType,
                requestVariant.value.ios,
              );
            } else if (requestVariant
                is gentype.RequestPurchasePropsRequestPurchase) {
              payload = _buildIosPurchasePayload(
                nativeType,
                requestVariant.value.ios,
              );
            }

            if (payload == null) {
              throw PurchaseError(
                code: gentype.ErrorCode.DeveloperError,
                message: 'Missing iOS purchase parameters',
              );
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
                throw PurchaseError(
                  code: gentype.ErrorCode.DeveloperError,
                  message: 'Missing Android subscription parameters',
                );
              }
              if (androidProps.skus.isEmpty) {
                throw PurchaseError(
                  code: gentype.ErrorCode.EmptySkuList,
                  message: 'Android subscription requires at least one SKU',
                );
              }
              if (androidProps.replacementModeAndroid != null &&
                  androidProps.replacementModeAndroid != -1 &&
                  (androidProps.purchaseTokenAndroid == null ||
                      androidProps.purchaseTokenAndroid!.isEmpty)) {
                throw PurchaseError(
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
              throw PurchaseError(
                code: gentype.ErrorCode.DeveloperError,
                message: 'Missing Android purchase parameters',
              );
            }
            if (androidProps.skus.isEmpty) {
              throw PurchaseError(
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

          throw PurchaseError(
            code: gentype.ErrorCode.IapNotAvailable,
            message: 'requestPurchase is not supported on this platform',
          );
        } catch (error) {
          if (error is PurchaseError) {
            rethrow;
          }
          throw PurchaseError(
            code: gentype.ErrorCode.ServiceError,
            message: 'Failed to request purchase: ${error.toString()}',
          );
        }
      };

  /// DSL-like request subscription method with builder pattern
  // requestSubscriptionWithBuilder removed in 6.6.0 (use requestPurchaseWithBuilder)

  /// Get all available purchases (OpenIAP standard)
  /// Returns non-consumed purchases that are still pending acknowledgment or consumption
  ///
  /// [options] - Optional configuration for the method behavior
  /// - onlyIncludeActiveItemsIOS: Whether to only include active items (default: true)
  ///   Set to false to include expired subscriptions
  gentype.QueryGetAvailablePurchasesHandler get getAvailablePurchases =>
      ([options]) async {
        if (!_isInitialized) {
          throw PurchaseError(
            code: gentype.ErrorCode.NotPrepared,
            message: 'IAP connection not initialized',
          );
        }

        try {
          final normalizedOptions = gentype.PurchaseOptions(
            alsoPublishToEventListenerIOS:
                options?.alsoPublishToEventListenerIOS ?? false,
            onlyIncludeActiveItemsIOS:
                options?.onlyIncludeActiveItemsIOS ?? true,
          );

          bool hasResolvableIdentifier(gentype.Purchase purchase) {
            final token = purchase.purchaseToken;
            if (token != null && token.isNotEmpty) {
              return true;
            }
            if (purchase is gentype.PurchaseIOS) {
              return purchase.transactionId.isNotEmpty;
            }
            if (purchase is gentype.PurchaseAndroid) {
              return purchase.transactionId?.isNotEmpty ?? false;
            }
            return purchase.id.isNotEmpty;
          }

          Future<List<gentype.Purchase>> resolvePurchases() async {
            List<gentype.Purchase> raw = const <gentype.Purchase>[];

            if (_platform.isIOS) {
              final args = <String, dynamic>{
                'alsoPublishToEventListenerIOS':
                    normalizedOptions.alsoPublishToEventListenerIOS ?? false,
                'onlyIncludeActiveItemsIOS':
                    normalizedOptions.onlyIncludeActiveItemsIOS ?? true,
              };
              final dynamic result =
                  await _channel.invokeMethod('getAvailableItems', args);
              raw = extractPurchases(
                result,
                platformIsAndroid: false,
                platformIsIOS: true,
                acknowledgedAndroidPurchaseTokens:
                    _acknowledgedAndroidPurchaseTokens,
              );
            } else if (_platform.isAndroid) {
              final dynamic result =
                  await _channel.invokeMethod('getAvailableItems');
              raw = extractPurchases(
                result,
                platformIsAndroid: true,
                platformIsIOS: false,
                acknowledgedAndroidPurchaseTokens:
                    _acknowledgedAndroidPurchaseTokens,
              );
            }

            return raw
                .where((purchase) => purchase.productId.isNotEmpty)
                .where(hasResolvableIdentifier)
                .toList(growable: false);
          }

          return await resolvePurchases();
        } catch (error) {
          throw PurchaseError(
            code: gentype.ErrorCode.ServiceError,
            message: 'Failed to get available purchases: ${error.toString()}',
          );
        }
      };

  Map<String, dynamic>? _buildIosPurchasePayload(
    String nativeType,
    Object? iosProps,
  ) {
    if (iosProps == null) {
      return null;
    }

    Map<String, dynamic> propsJson;
    if (iosProps is gentype.RequestPurchaseIosProps) {
      propsJson = iosProps.toJson();
    } else if (iosProps is gentype.RequestSubscriptionIosProps) {
      propsJson = iosProps.toJson();
    } else {
      return null;
    }

    final String? sku = propsJson['sku'] as String?;
    if (sku == null || sku.isEmpty) {
      return null;
    }

    final payload = <String, dynamic>{
      'sku': sku,
      'type': nativeType,
      'andDangerouslyFinishTransactionAutomatically':
          (propsJson['andDangerouslyFinishTransactionAutomatically']
                  as bool?) ??
              false,
    };

    final String? appAccountToken = propsJson['appAccountToken'] as String?;
    if (appAccountToken != null && appAccountToken.isNotEmpty) {
      payload['appAccountToken'] = appAccountToken;
    }

    final dynamic quantityValue = propsJson['quantity'];
    if (quantityValue is int) {
      payload['quantity'] = quantityValue;
    } else if (quantityValue is num) {
      payload['quantity'] = quantityValue.toInt();
    }

    final dynamic offerValue = propsJson['withOffer'];
    if (offerValue is Map) {
      payload['withOffer'] = offerValue.map<String, dynamic>(
          (key, value) => MapEntry(key.toString(), value));
    }

    payload.removeWhere((_, value) => value == null);
    return payload;
  }

  /// iOS specific: Get storefront
  gentype.QueryGetStorefrontIOSHandler get getStorefrontIOS => () async {
        if (!_platform.isIOS) {
          throw PurchaseError(
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
          throw PurchaseError(
            code: gentype.ErrorCode.ServiceError,
            message: 'Failed to get storefront country code',
          );
        } catch (error) {
          if (error is PurchaseError) {
            rethrow;
          }
          throw PurchaseError(
            code: gentype.ErrorCode.ServiceError,
            message: 'Failed to get storefront: ${error.toString()}',
          );
        }
      };

  gentype.MutationSyncIOSHandler get syncIOS => () async {
        if (!_platform.isIOS) {
          debugPrint('syncIOS is only supported on iOS');
          return false;
        }

        try {
          await _channel.invokeMethod('endConnection');
          await _channel.invokeMethod('initConnection');
          return true;
        } catch (error) {
          debugPrint('Error syncing iOS purchases: $error');
          rethrow;
        }
      };

  gentype.QueryIsEligibleForIntroOfferIOSHandler
      get isEligibleForIntroOfferIOS => (groupId) async {
            if (!_platform.isIOS) {
              return false;
            }

            try {
              final result = await _channel.invokeMethod<bool>(
                'isEligibleForIntroOffer',
                {'productId': groupId},
              );
              return result ?? false;
            } catch (error) {
              debugPrint('Error checking intro offer eligibility: $error');
              return false;
            }
          };

  gentype.QuerySubscriptionStatusIOSHandler get subscriptionStatusIOS =>
      (sku) async {
        if (!_platform.isIOS) {
          return <gentype.SubscriptionStatusIOS>[];
        }

        try {
          final dynamic result = await _channel.invokeMethod(
            'getSubscriptionStatus',
            {'sku': sku},
          );

          if (result == null) {
            return <gentype.SubscriptionStatusIOS>[];
          }

          List<dynamic> asList;
          if (result is String) {
            asList = json.decode(result) as List<dynamic>;
          } else if (result is List) {
            asList = result;
          } else if (result is Map) {
            asList = [result];
          } else {
            return <gentype.SubscriptionStatusIOS>[];
          }

          final statuses = <gentype.SubscriptionStatusIOS>[];
          for (final entry in asList) {
            if (entry is Map) {
              final normalized = entry.map<String, dynamic>(
                  (key, value) => MapEntry(key.toString(), value));
              statuses.add(
                gentype.SubscriptionStatusIOS.fromJson(normalized),
              );
            }
          }
          return statuses;
        } catch (error) {
          debugPrint('Error getting subscription status: $error');
          return <gentype.SubscriptionStatusIOS>[];
        }
      };

  gentype.MutationClearTransactionIOSHandler get clearTransactionIOS =>
      () async {
        if (!_platform.isIOS) {
          return false;
        }

        try {
          await _channel.invokeMethod('clearTransactionIOS');
          return true;
        } catch (error) {
          debugPrint('Error clearing pending transactions: $error');
          return false;
        }
      };

  gentype.QueryGetPromotedProductIOSHandler get getPromotedProductIOS =>
      () async {
        if (!_platform.isIOS) {
          return null;
        }

        try {
          final dynamic result = await _channel.invokeMethod(
            'getPromotedProductIOS',
          );
          if (result == null) {
            return null;
          }

          if (result is Map) {
            return gentype.ProductIOS.fromJson(
              result.map<String, dynamic>(
                  (key, value) => MapEntry(key.toString(), value)),
            );
          }

          if (result is String) {
            return null;
          }

          return null;
        } catch (error) {
          debugPrint('Error getting promoted product: $error');
          return null;
        }
      };

  gentype.MutationRequestPurchaseOnPromotedProductIOSHandler
      get requestPurchaseOnPromotedProductIOS => () async {
            if (!_platform.isIOS) {
              return false;
            }

            try {
              await _channel
                  .invokeMethod('requestPurchaseOnPromotedProductIOS');
              return true;
            } catch (error) {
              debugPrint(
                'Error requesting promoted product purchase: $error',
              );
              return false;
            }
          };

  Future<List<gentype.Purchase>?> getAvailableItemsIOS() async {
    if (!_platform.isIOS) {
      return null;
    }

    try {
      final dynamic result = await _channel.invokeMethod('getAvailableItems');
      final items = extractPurchases(
        result,
        platformIsAndroid: false,
        platformIsIOS: true,
        acknowledgedAndroidPurchaseTokens: _acknowledgedAndroidPurchaseTokens,
      );
      return items;
    } catch (error) {
      debugPrint('Error getting available items (iOS): $error');
      return null;
    }
  }

  gentype.QueryGetAppTransactionIOSHandler get getAppTransactionIOS =>
      () async {
        if (!_platform.isIOS) {
          return null;
        }

        try {
          final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
            'getAppTransaction',
          );
          if (result == null) {
            return null;
          }

          final map = result.map<String, dynamic>(
              (key, value) => MapEntry(key.toString(), value));
          return gentype.AppTransaction.fromJson(map);
        } catch (error) {
          debugPrint('Error getting app transaction: $error');
          return null;
        }
      };

  Future<gentype.AppTransaction?> getAppTransactionTypedIOS() async {
    return await getAppTransactionIOS();
  }

  Future<List<gentype.Purchase>> getPurchaseHistoriesIOS() async {
    if (!_platform.isIOS) {
      return <gentype.Purchase>[];
    }

    try {
      final dynamic result =
          await _channel.invokeMethod('getPurchaseHistoriesIOS');
      final items = extractPurchases(
        result,
        platformIsAndroid: false,
        platformIsIOS: true,
        acknowledgedAndroidPurchaseTokens: _acknowledgedAndroidPurchaseTokens,
      );
      return items;
    } catch (error) {
      debugPrint('Error getting purchase histories (iOS): $error');
      return <gentype.Purchase>[];
    }
  }

  /// iOS specific: Present code redemption sheet
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
              throw PurchaseError(
                code: gentype.ErrorCode.ServiceError,
                message:
                    'Failed to present code redemption sheet: ${error.toString()}',
              );
            }
          };

  /// iOS specific: Show manage subscriptions
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
              throw PurchaseError(
                code: gentype.ErrorCode.ServiceError,
                message:
                    'Failed to show manage subscriptions: ${error.toString()}',
              );
            }
          };

  // Original API methods (with deprecation annotations where needed)

  gentype.QueryGetPendingTransactionsIOSHandler get getPendingTransactionsIOS =>
      () async {
        if (_platform.isIOS) {
          final dynamic result =
              await _channel.invokeMethod('getPendingTransactionsIOS');
          final purchases = extractPurchases(
            result,
            platformIsAndroid: _platform.isAndroid,
            platformIsIOS: _platform.isIOS,
            acknowledgedAndroidPurchaseTokens:
                _acknowledgedAndroidPurchaseTokens,
          );
          return purchases
              .whereType<gentype.PurchaseIOS>()
              .toList(growable: false);
        }
        return const <gentype.PurchaseIOS>[];
      };

  gentype.MutationAcknowledgePurchaseAndroidHandler
      get acknowledgePurchaseAndroid => (purchaseToken) async {
            if (!_platform.isAndroid) {
              throw PurchaseError(
                code: gentype.ErrorCode.IapNotAvailable,
                message:
                    'acknowledgePurchaseAndroid is only available on Android',
              );
            }

            try {
              final dynamic response = await _channel.invokeMethod(
                'acknowledgePurchaseAndroid',
                {'purchaseToken': purchaseToken},
              );

              parseAndLogAndroidResponse(
                response,
                successLog:
                    '[FlutterInappPurchase] Android: Purchase acknowledged successfully',
                failureLog:
                    '[FlutterInappPurchase] Android: Failed to parse acknowledge response',
              );

              if (response is bool) {
                return response;
              }

              if (response is String) {
                final parsed = json.decode(response) as Map<String, dynamic>;
                final code = parsed['responseCode'] as int? ?? 0;
                final success = parsed['success'] as bool? ?? false;
                return code == 0 || success;
              }

              if (response is Map) {
                final parsed = response.map<String, dynamic>(
                    (key, value) => MapEntry(key.toString(), value));
                final code = parsed['responseCode'] as int? ?? 0;
                final success = parsed['success'] as bool? ?? false;
                return code == 0 || success;
              }

              return true;
            } catch (error) {
              debugPrint('Error acknowledging purchase: $error');
              return false;
            }
          };

  gentype.MutationConsumePurchaseAndroidHandler get consumePurchaseAndroid =>
      (purchaseToken) async {
        if (!_platform.isAndroid) {
          throw PurchaseError(
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
            final map = response.map<String, dynamic>(
                (key, value) => MapEntry(key.toString(), value));
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

  gentype.MutationDeepLinkToSubscriptionsHandler get deepLinkToSubscriptions =>
      ([options]) async {
        if (!_platform.isAndroid) {
          throw PurchaseError(
            code: gentype.ErrorCode.IapNotAvailable,
            message:
                'deepLinkToSubscriptionsAndroid is only available on Android',
          );
        }

        final args = <String, dynamic>{};
        final opts = options;
        if (opts?.packageNameAndroid != null &&
            opts!.packageNameAndroid!.isNotEmpty) {
          args['packageNameAndroid'] = opts.packageNameAndroid;
          args['packageName'] = opts.packageNameAndroid;
        }
        if (opts?.skuAndroid != null && opts!.skuAndroid!.isNotEmpty) {
          args['skuAndroid'] = opts.skuAndroid;
          args['sku'] = opts.skuAndroid;
        }

        await _channel.invokeMethod('deepLinkToSubscriptionsAndroid', args);
      };

  /// Finish a transaction using OpenIAP generated handler signature
  gentype.MutationFinishTransactionHandler get finishTransaction => ({
        required purchase,
        bool? isConsumable,
      }) async {
        final bool consumable = isConsumable ?? false;
        final transactionId = purchase.id;

        if (_platform.isAndroid) {
          final purchaseToken = purchase.purchaseToken;
          if (purchaseToken == null || purchaseToken.isEmpty) {
            throw PurchaseError(
              code: gentype.ErrorCode.PurchaseError,
              message:
                  'Purchase token is required to finish Android transactions.',
            );
          }

          if (consumable) {
            debugPrint(
              '[FlutterInappPurchase] Android: Consuming product with token: $purchaseToken',
            );
            final result = await _channel.invokeMethod(
              'consumePurchaseAndroid',
              <String, dynamic>{'purchaseToken': purchaseToken},
            );
            parseAndLogAndroidResponse(
              result,
              successLog:
                  '[FlutterInappPurchase] Android: Product consumed successfully',
              failureLog:
                  '[FlutterInappPurchase] Android: Failed to parse consume response',
            );
            _acknowledgedAndroidPurchaseTokens.remove(purchaseToken);
            return;
          }

          final alreadyAcknowledged =
              _acknowledgedAndroidPurchaseTokens[purchaseToken] ?? false;
          if (alreadyAcknowledged) {
            if (kDebugMode) {
              debugPrint(
                '[FlutterInappPurchase] Android: Purchase already acknowledged (cached)',
              );
            }
            return;
          }

          final maskedToken = purchaseToken.replaceAllMapped(
            RegExp(r'.(?=.{4})'),
            (m) => '*',
          );

          if (kDebugMode) {
            debugPrint(
              '[FlutterInappPurchase] Android: Acknowledging purchase with token: $maskedToken',
            );
          }

          // Subscriptions require acknowledgePurchase for compatibility
          final methodName = purchase.isAutoRenewing
              ? 'acknowledgePurchase'
              : 'acknowledgePurchaseAndroid';

          final result = await _channel.invokeMethod(
            methodName,
            <String, dynamic>{
              'purchaseToken': purchaseToken,
            },
          );
          bool didAcknowledgeSucceed(dynamic response) {
            if (response == null) {
              return false;
            }

            if (response is bool) {
              return response;
            }

            Map<String, dynamic>? parsed;

            if (response is String) {
              try {
                final dynamic decoded = jsonDecode(response);
                if (decoded is Map<String, dynamic>) {
                  parsed = decoded;
                } else {
                  return false;
                }
              } catch (_) {
                return false;
              }
            } else if (response is Map<dynamic, dynamic>) {
              parsed = response.map<String, dynamic>(
                  (key, value) => MapEntry(key.toString(), value));
            }

            if (parsed != null) {
              final dynamic code = parsed['responseCode'];
              if (code is num && code == 0) {
                return true;
              }
              if (code is String && int.tryParse(code) == 0) {
                return true;
              }

              final bool? success = parsed['success'] as bool?;
              if (success != null) {
                return success;
              }
            }

            return false;
          }

          final didAcknowledge = didAcknowledgeSucceed(result);
          parseAndLogAndroidResponse(
            result,
            successLog:
                '[FlutterInappPurchase] Android: Purchase acknowledged successfully',
            failureLog:
                '[FlutterInappPurchase] Android: Failed to parse acknowledge response',
          );
          if (didAcknowledge) {
            _acknowledgedAndroidPurchaseTokens[purchaseToken] = true;
          } else if (kDebugMode) {
            debugPrint(
              '[FlutterInappPurchase] Android: Acknowledge response indicated failure; will retry later ($maskedToken)',
            );
          }
          return;
        }

        if (_platform.isIOS) {
          debugPrint(
            '[FlutterInappPurchase] iOS: Finishing transaction with ID: $transactionId',
          );
          final payload = <String, dynamic>{
            'transactionId': transactionId,
            'purchase': purchase.toJson(),
            'isConsumable': consumable,
          };
          await _channel.invokeMethod('finishTransaction', payload);
          return;
        }

        throw PlatformException(
          code: _platform.operatingSystem,
          message: 'platform not supported',
        );
      };

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
      (options) async {
        if (!_platform.isIOS) {
          throw errors.PurchaseError(
            code: errors.ErrorCode.IapNotAvailable,
            message: 'Receipt validation is only available on iOS',
          );
        }

        if (!_isInitialized) {
          throw errors.PurchaseError(
            code: errors.ErrorCode.NotPrepared,
            message: 'IAP connection not initialized',
          );
        }

        final sku = options.sku.trim();
        if (sku.isEmpty) {
          throw PurchaseError(
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
            throw PurchaseError(
              code: gentype.ErrorCode.ServiceError,
              message: 'No validation result received from native platform',
            );
          }

          final validationResult = result.map<String, dynamic>(
              (key, value) => MapEntry(key.toString(), value));
          final latestTransactionMap = validationResult['latestTransaction'];
          final latestTransaction = latestTransactionMap is Map
              ? gentype.Purchase.fromJson(
                  latestTransactionMap.map<String, dynamic>(
                      (key, value) => MapEntry(key.toString(), value)),
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
          throw PurchaseError(
            code: gentype.ErrorCode.ServiceError,
            message:
                'Failed to validate receipt [${error.code}]: ${error.message ?? error.details}',
          );
        } catch (error) {
          throw PurchaseError(
            code: gentype.ErrorCode.ServiceError,
            message: 'Failed to validate receipt: ${error.toString()}',
          );
        }
      };
  gentype.MutationValidateReceiptHandler get validateReceipt =>
      (options) async {
        if (_platform.isIOS) {
          return await validateReceiptIOS(options);
        }
        if (_platform.isAndroid) {
          throw PurchaseError(
            code: gentype.ErrorCode.IapNotAvailable,
            message: 'Android receipt validation is not supported',
          );
        }
        throw PurchaseError(
          code: gentype.ErrorCode.IapNotAvailable,
          message: 'Platform not supported for receipt validation',
        );
      };

  // flutter IAP compatible methods

  gentype.QueryFetchProductsHandler get fetchProducts => (options) async {
        final skus = options.skus;
        final queryType = options.type ?? gentype.ProductQueryType.InApp;

        if (!_isInitialized) {
          throw PurchaseError(
            code: gentype.ErrorCode.NotPrepared,
            message: 'IAP connection not initialized',
          );
        }

        if (queryType == gentype.ProductQueryType.All) {
          throw PurchaseError(
            code: gentype.ErrorCode.DeveloperError,
            message: 'fetchProducts does not support ProductQueryType.All. '
                'Query in-app products and subscriptions separately.',
          );
        }

        try {
          final resolvedType = resolveProductType(queryType);
          debugPrint(
            '[flutter_inapp_purchase] fetchProducts called with skus: $skus, type: $resolvedType',
          );

          final List<dynamic> merged = [];
          final raw = await _channel.invokeMethod('fetchProducts', {
            'skus': skus,
            'type': resolvedType,
          });

          if (raw is String) {
            merged.addAll(jsonDecode(raw) as List<dynamic>? ?? []);
          } else if (raw is List) {
            merged.addAll(raw);
          }

          debugPrint(
            '[flutter_inapp_purchase] Received ${merged.length} items from native',
          );

          final products = <gentype.ProductCommon>[];
          for (final item in merged) {
            try {
              final Map<String, dynamic> itemMap;
              if (item is Map) {
                final normalized = normalizeDynamicMap(item);
                if (normalized == null) {
                  debugPrint(
                    '[flutter_inapp_purchase] Skipping product with null map after normalization: ${item.runtimeType}',
                  );
                  continue;
                }
                itemMap = normalized;
              } else {
                debugPrint(
                  '[flutter_inapp_purchase] Skipping unexpected item type: ${item.runtimeType}',
                );
                continue;
              }

              final detectedType = resolvedType == 'all'
                  ? (itemMap['type']?.toString() ?? 'in-app')
                  : resolvedType;
              final parsed = parseProductFromNative(
                itemMap,
                detectedType,
                fallbackIsIOS: _platform.isIOS,
              );
              products.add(parsed);
            } catch (error) {
              debugPrint(
                '[flutter_inapp_purchase] Skipping product due to parse error: $error',
              );
              debugPrint(
                  '[flutter_inapp_purchase] Item runtimeType: ${item.runtimeType}');
              debugPrint(
                  '[flutter_inapp_purchase] Item values: ${jsonEncode(item)}');
            }
          }

          if (queryType == gentype.ProductQueryType.Subs) {
            final subscriptions = products
                .whereType<gentype.ProductSubscription>()
                .toList(growable: false);
            if (subscriptions.length != products.length) {
              debugPrint(
                '[flutter_inapp_purchase] Filtered ${products.length - subscriptions.length} items not matching <ProductSubscription>',
              );
            }
            return gentype.FetchProductsResultSubscriptions(subscriptions);
          }

          final inApps =
              products.whereType<gentype.Product>().toList(growable: false);
          if (inApps.length != products.length) {
            debugPrint(
              '[flutter_inapp_purchase] Filtered ${products.length - inApps.length} items not matching <Product>',
            );
          }
          return gentype.FetchProductsResultProducts(inApps);
        } catch (error) {
          throw PurchaseError(
            code: gentype.ErrorCode.ServiceError,
            message: 'Failed to fetch products: ${error.toString()}',
          );
        }
      };

  // MARK: - StoreKit 2 specific methods

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
      ([subscriptionIds]) async {
        if (!_isInitialized) {
          throw PurchaseError(
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
          if (error is PurchaseError) {
            rethrow;
          }
          throw PurchaseError(
            code: gentype.ErrorCode.ServiceError,
            message: 'Failed to get active subscriptions: ${error.toString()}',
          );
        }
      };

  /// Check if the user has any active subscriptions (OpenIAP compliant)
  /// Returns true if the user has at least one active subscription, false otherwise.
  /// If subscriptionIds is provided, only checks for those specific subscriptions.
  gentype.QueryHasActiveSubscriptionsHandler get hasActiveSubscriptions =>
      ([subscriptionIds]) async {
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

  gentype.QueryHandlers get queryHandlers => gentype.QueryHandlers(
        fetchProducts: fetchProducts,
        getActiveSubscriptions: getActiveSubscriptions,
        getAppTransactionIOS: getAppTransactionIOS,
        getAvailablePurchases: getAvailablePurchases,
        getPendingTransactionsIOS: getPendingTransactionsIOS,
        getPromotedProductIOS: getPromotedProductIOS,
        getStorefrontIOS: getStorefrontIOS,
        hasActiveSubscriptions: hasActiveSubscriptions,
        isEligibleForIntroOfferIOS: isEligibleForIntroOfferIOS,
        subscriptionStatusIOS: subscriptionStatusIOS,
        validateReceiptIOS: validateReceiptIOS,
      );

  gentype.MutationHandlers get mutationHandlers => gentype.MutationHandlers(
        acknowledgePurchaseAndroid: acknowledgePurchaseAndroid,
        consumePurchaseAndroid: consumePurchaseAndroid,
        deepLinkToSubscriptions: deepLinkToSubscriptions,
        endConnection: endConnection,
        finishTransaction: finishTransaction,
        initConnection: initConnection,
        presentCodeRedemptionSheetIOS: presentCodeRedemptionSheetIOS,
        requestPurchase: requestPurchase,
        requestPurchaseOnPromotedProductIOS:
            requestPurchaseOnPromotedProductIOS,
        restorePurchases: restorePurchases,
        showManageSubscriptionsIOS: showManageSubscriptionsIOS,
        syncIOS: syncIOS,
        validateReceipt: validateReceipt,
        clearTransactionIOS: clearTransactionIOS,
      );

  gentype.SubscriptionHandlers get subscriptionHandlers =>
      gentype.SubscriptionHandlers(
        promotedProductIOS: () async {
          final value = await purchasePromoted.firstWhere(
            (element) => element != null,
          );
          return value ?? '';
        },
        purchaseError: () async =>
            await purchaseErrorListener.first as gentype.PurchaseError,
        purchaseUpdated: () async => await purchaseUpdatedListener.first,
      );
}
