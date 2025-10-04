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
  final StreamController<gentype.UserChoiceBillingDetails>
      _userChoiceBillingAndroidListener =
      StreamController<gentype.UserChoiceBillingDetails>.broadcast();

  /// Purchase updated event stream
  Stream<gentype.Purchase> get purchaseUpdatedListener =>
      _purchaseUpdatedListener.stream;

  /// Purchase error event stream
  Stream<PurchaseError> get purchaseErrorListener =>
      _purchaseErrorListener.stream;

  /// User choice billing Android event stream
  Stream<gentype.UserChoiceBillingDetails> get userChoiceBillingAndroid =>
      _userChoiceBillingAndroidListener.stream;

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
        case 'user-choice-billing-android':
          try {
            Map<String, dynamic> result =
                jsonDecode(call.arguments as String) as Map<String, dynamic>;
            final details = gentype.UserChoiceBillingDetails.fromJson(result);
            _userChoiceBillingAndroidListener.add(details);
          } catch (e, stackTrace) {
            debugPrint(
              '[flutter_inapp_purchase] ERROR in user-choice-billing-android: $e',
            );
            debugPrint('[flutter_inapp_purchase] Stack trace: $stackTrace');
          }
          break;
        default:
          throw ArgumentError('Unknown method ${call.method}');
      }
      return Future.value(null);
    });
  }

  /// Initialize connection (flutter IAP compatible)
  gentype.MutationInitConnectionHandler get initConnection => (
          {gentype.AlternativeBillingModeAndroid?
              alternativeBillingModeAndroid}) async {
        if (_isInitialized) {
          return true;
        }

        try {
          await _setPurchaseListener();

          // Build config map for alternative billing
          final Map<String, dynamic>? config =
              alternativeBillingModeAndroid != null
                  ? {
                      'alternativeBillingModeAndroid':
                          alternativeBillingModeAndroid.toJson()
                    }
                  : null;

          await _channel.invokeMethod('initConnection', config);
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

        // Determine type based on factory constructor used
        final type = params.toJson()['type'] as String;
        final productType = type == 'in-app'
            ? gentype.ProductQueryType.InApp
            : gentype.ProductQueryType.Subs;

        if (productType == gentype.ProductQueryType.All) {
          throw PurchaseError(
            code: gentype.ErrorCode.DeveloperError,
            message:
                'requestPurchase only supports IN_APP or SUBS request types',
          );
        }

        final nativeType = resolveProductType(productType);

        try {
          if (_platform.isIOS) {
            // Extract props from the JSON representation
            final json = params.toJson();
            final requestKey =
                type == 'in-app' ? 'requestPurchase' : 'requestSubscription';
            final requestData = json[requestKey] as Map<String, dynamic>?;

            if (requestData == null) {
              throw PurchaseError(
                code: gentype.ErrorCode.DeveloperError,
                message:
                    'Missing request data. JSON: ${json.toString().substring(0, 200)}',
              );
            }

            final iosData = requestData['ios'] as Map<String, dynamic>?;

            if (iosData == null) {
              throw PurchaseError(
                code: gentype.ErrorCode.DeveloperError,
                message:
                    'Missing iOS purchase parameters. Request data keys: ${requestData.keys.join(", ")}',
              );
            }

            final iosProps = type == 'in-app'
                ? gentype.RequestPurchaseIosProps.fromJson(iosData)
                : gentype.RequestSubscriptionIosProps.fromJson(iosData);

            final payload = buildIosPurchasePayload(
              nativeType,
              iosProps,
            );

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
            // Extract props from the JSON representation
            final json = params.toJson();
            final requestKey =
                type == 'in-app' ? 'requestPurchase' : 'requestSubscription';
            final requestData = json[requestKey] as Map<String, dynamic>?;
            final androidData =
                requestData?['android'] as Map<String, dynamic>?;

            if (androidData == null) {
              throw PurchaseError(
                code: gentype.ErrorCode.DeveloperError,
                message: 'Missing Android purchase parameters',
              );
            }

            // Parse Android props based on type
            final androidProps = type == 'inapp'
                ? gentype.RequestPurchaseAndroidProps.fromJson(androidData)
                : gentype.RequestSubscriptionAndroidProps.fromJson(androidData);

            // Handle both RequestPurchaseAndroidProps and RequestSubscriptionAndroidProps
            final List<String> skus;
            final bool? isOfferPersonalized;
            final String? obfuscatedAccount;
            final String? obfuscatedProfile;
            final String? purchaseToken;
            final int? replacementMode;
            final List<gentype.AndroidSubscriptionOfferInput>?
                subscriptionOffers;

            if (androidProps is gentype.RequestPurchaseAndroidProps) {
              skus = androidProps.skus;
              isOfferPersonalized = androidProps.isOfferPersonalized;
              obfuscatedAccount = androidProps.obfuscatedAccountIdAndroid;
              obfuscatedProfile = androidProps.obfuscatedProfileIdAndroid;
              purchaseToken = null;
              replacementMode = null;
              subscriptionOffers = null;
            } else if (androidProps
                is gentype.RequestSubscriptionAndroidProps) {
              skus = androidProps.skus;
              isOfferPersonalized = androidProps.isOfferPersonalized;
              obfuscatedAccount = androidProps.obfuscatedAccountIdAndroid;
              obfuscatedProfile = androidProps.obfuscatedProfileIdAndroid;
              purchaseToken = androidProps.purchaseTokenAndroid;
              replacementMode = androidProps.replacementModeAndroid;
              subscriptionOffers = androidProps.subscriptionOffers;
            } else {
              throw PurchaseError(
                code: gentype.ErrorCode.DeveloperError,
                message: 'Invalid Android purchase parameters type',
              );
            }

            if (skus.isEmpty) {
              throw PurchaseError(
                code: gentype.ErrorCode.EmptySkuList,
                message: 'Android purchase requires at least one SKU',
              );
            }

            final payload = <String, dynamic>{
              'type': nativeType,
              'skus': skus,
              'productId': skus.first,
              'isOfferPersonalized': isOfferPersonalized ?? false,
            };

            if (obfuscatedAccount != null) {
              payload['obfuscatedAccountId'] = obfuscatedAccount;
              payload['obfuscatedAccountIdAndroid'] = obfuscatedAccount;
            }

            if (obfuscatedProfile != null) {
              payload['obfuscatedProfileId'] = obfuscatedProfile;
              payload['obfuscatedProfileIdAndroid'] = obfuscatedProfile;
            }

            if (purchaseToken != null) {
              payload['purchaseTokenAndroid'] = purchaseToken;
            }

            if (replacementMode != null) {
              payload['replacementModeAndroid'] = replacementMode;
            }

            if (subscriptionOffers != null && subscriptionOffers.isNotEmpty) {
              payload['subscriptionOffers'] =
                  subscriptionOffers.map((offer) => offer.toJson()).toList();
            }

            // Add useAlternativeBilling from the RequestPurchaseProps
            // Include it even if null or false to ensure proper mode switching
            final useAlternativeBilling =
                json['useAlternativeBilling'] as bool?;
            payload['useAlternativeBilling'] = useAlternativeBilling;

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
  gentype.QueryGetAvailablePurchasesHandler get getAvailablePurchases => (
          {bool? alsoPublishToEventListenerIOS,
          bool? onlyIncludeActiveItemsIOS}) async {
        if (!_isInitialized) {
          throw PurchaseError(
            code: gentype.ErrorCode.NotPrepared,
            message: 'IAP connection not initialized',
          );
        }

        try {
          final normalizedOptions = gentype.PurchaseOptions(
            alsoPublishToEventListenerIOS:
                alsoPublishToEventListenerIOS ?? false,
            onlyIncludeActiveItemsIOS: onlyIncludeActiveItemsIOS ?? true,
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

  /// Get the current storefront country code (unified method)
  gentype.QueryGetStorefrontHandler get getStorefront => () async {
        if (!_platform.isIOS && !_platform.isAndroid) {
          return '';
        }

        try {
          final String? storefront = await channel.invokeMethod<String>(
            'getStorefront',
          );
          return storefront ?? '';
        } catch (error) {
          debugPrint(
            '[getStorefront] Failed to get storefront on ${_platform.operatingSystem}: $error',
          );
          throw PurchaseError(
            code: gentype.ErrorCode.ServiceError,
            message: 'Failed to get storefront: ${error.toString()}',
          );
        }
      };

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
      ({String? packageNameAndroid, String? skuAndroid}) async {
        if (!_platform.isAndroid) {
          throw PurchaseError(
            code: gentype.ErrorCode.IapNotAvailable,
            message:
                'deepLinkToSubscriptionsAndroid is only available on Android',
          );
        }

        final args = <String, dynamic>{};
        if (packageNameAndroid != null && packageNameAndroid.isNotEmpty) {
          args['packageNameAndroid'] = packageNameAndroid;
          args['packageName'] = packageNameAndroid;
        }
        if (skuAndroid != null && skuAndroid.isNotEmpty) {
          args['skuAndroid'] = skuAndroid;
          args['sku'] = skuAndroid;
        }

        await _channel.invokeMethod('deepLinkToSubscriptionsAndroid', args);
      };

  /// Finish a transaction using OpenIAP generated handler signature
  gentype.MutationFinishTransactionHandler get finishTransaction => ({
        required gentype.Purchase purchase,
        bool? isConsumable,
      }) async {
        final bool consumable = isConsumable ?? false;
        final transactionId = purchase.id;

        if (_platform.isAndroid) {
          if (purchase.purchaseToken == null ||
              purchase.purchaseToken!.isEmpty) {
            throw PurchaseError(
              code: gentype.ErrorCode.PurchaseError,
              message:
                  'Purchase token is required to finish Android transactions.',
            );
          }

          if (consumable) {
            debugPrint(
              '[FlutterInappPurchase] Android: Consuming product with token: ${purchase.purchaseToken}',
            );
            final result = await _channel.invokeMethod(
              'consumePurchaseAndroid',
              <String, dynamic>{'purchaseToken': purchase.purchaseToken},
            );
            parseAndLogAndroidResponse(
              result,
              successLog:
                  '[FlutterInappPurchase] Android: Product consumed successfully',
              failureLog:
                  '[FlutterInappPurchase] Android: Failed to parse consume response',
            );
            _acknowledgedAndroidPurchaseTokens.remove(purchase.purchaseToken!);
            return;
          }

          final alreadyAcknowledged =
              _acknowledgedAndroidPurchaseTokens[purchase.purchaseToken!] ??
                  false;
          if (alreadyAcknowledged) {
            if (kDebugMode) {
              debugPrint(
                '[FlutterInappPurchase] Android: Purchase already acknowledged (cached)',
              );
            }
            return;
          }

          final maskedToken = purchase.purchaseToken!.replaceAllMapped(
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
              'purchaseToken': purchase.purchaseToken,
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
            _acknowledgedAndroidPurchaseTokens[purchase.purchaseToken!] = true;
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
  gentype.QueryValidateReceiptIOSHandler get validateReceiptIOS => (
          {required String sku,
          gentype.ReceiptValidationAndroidOptions? androidOptions}) async {
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

        final skuTrimmed = sku.trim();
        if (skuTrimmed.isEmpty) {
          throw PurchaseError(
            code: gentype.ErrorCode.DeveloperError,
            message: 'sku cannot be empty',
          );
        }

        try {
          final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
            'validateReceiptIOS',
            {'sku': skuTrimmed},
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
  gentype.MutationValidateReceiptHandler get validateReceipt => (
          {required String sku,
          gentype.ReceiptValidationAndroidOptions? androidOptions}) async {
        if (_platform.isIOS) {
          return await validateReceiptIOS(
              sku: sku, androidOptions: androidOptions);
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

  gentype.QueryFetchProductsHandler get fetchProducts =>
      ({required List<String> skus, gentype.ProductQueryType? type}) async {
        final queryType = type ?? gentype.ProductQueryType.InApp;

        if (!_isInitialized) {
          throw PurchaseError(
            code: gentype.ErrorCode.NotPrepared,
            message: 'IAP connection not initialized',
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

          debugPrint(
            '[flutter_inapp_purchase] Processed ${products.length} products',
          );

          // Handle different query types and return appropriate union type
          if (queryType == gentype.ProductQueryType.All) {
            // For 'All' type, we need to include both Product and ProductSubscription
            // Since FetchProductsResultProducts only accepts List<Product>, we need to
            // safely cast all compatible products
            final allCompatibleProducts = <gentype.Product>[];

            for (final product in products) {
              if (product is gentype.Product) {
                // Direct Product types (ProductIOS, ProductAndroid)
                allCompatibleProducts.add(product);
              } else if (product is gentype.ProductSubscription) {
                // ProductSubscription types need to be converted to Product types
                // Create a compatible Product representation
                if (product is gentype.ProductSubscriptionIOS) {
                  // Convert ProductSubscriptionIOS to ProductIOS
                  final compatibleProduct = gentype.ProductIOS(
                    currency: product.currency,
                    debugDescription: product.debugDescription,
                    description: product.description,
                    displayName: product.displayName,
                    displayNameIOS: product.displayNameIOS,
                    displayPrice: product.displayPrice,
                    id: product.id,
                    isFamilyShareableIOS: product.isFamilyShareableIOS,
                    jsonRepresentationIOS: product.jsonRepresentationIOS,
                    platform: product.platform,
                    price: product.price,
                    subscriptionInfoIOS: product.subscriptionInfoIOS,
                    title: product.title,
                    type: product.type,
                    typeIOS: product.typeIOS,
                  );
                  allCompatibleProducts.add(compatibleProduct);
                } else if (product is gentype.ProductSubscriptionAndroid) {
                  // Convert ProductSubscriptionAndroid to ProductAndroid
                  final compatibleProduct = gentype.ProductAndroid(
                    currency: product.currency,
                    debugDescription: product.debugDescription,
                    description: product.description,
                    displayName: product.displayName,
                    displayPrice: product.displayPrice,
                    id: product.id,
                    nameAndroid: product.nameAndroid,
                    oneTimePurchaseOfferDetailsAndroid:
                        null, // Subscriptions don't have one-time offers
                    platform: product.platform,
                    price: product.price,
                    subscriptionOfferDetailsAndroid:
                        product.subscriptionOfferDetailsAndroid,
                    title: product.title,
                    type: product.type,
                  );
                  allCompatibleProducts.add(compatibleProduct);
                }
              }
            }

            debugPrint(
              '[flutter_inapp_purchase] Type All: returning ${allCompatibleProducts.length} total products (including converted subscriptions)',
            );

            return gentype.FetchProductsResultProducts(allCompatibleProducts);
          } else if (queryType == gentype.ProductQueryType.Subs) {
            // For subscription queries, we need to return converted Product types
            // that originally were ProductSubscription types
            final subscriptionProducts = <gentype.Product>[];

            for (final product in products) {
              if (product is gentype.ProductSubscription) {
                // Convert ProductSubscription to Product (same as in 'All' logic)
                if (product is gentype.ProductSubscriptionIOS) {
                  final compatibleProduct = gentype.ProductIOS(
                    currency: product.currency,
                    debugDescription: product.debugDescription,
                    description: product.description,
                    displayName: product.displayName,
                    displayNameIOS: product.displayNameIOS,
                    displayPrice: product.displayPrice,
                    id: product.id,
                    isFamilyShareableIOS: product.isFamilyShareableIOS,
                    jsonRepresentationIOS: product.jsonRepresentationIOS,
                    platform: product.platform,
                    price: product.price,
                    subscriptionInfoIOS: product.subscriptionInfoIOS,
                    title: product.title,
                    type: product.type,
                    typeIOS: product.typeIOS,
                  );
                  subscriptionProducts.add(compatibleProduct);
                } else if (product is gentype.ProductSubscriptionAndroid) {
                  final compatibleProduct = gentype.ProductAndroid(
                    currency: product.currency,
                    debugDescription: product.debugDescription,
                    description: product.description,
                    displayName: product.displayName,
                    displayPrice: product.displayPrice,
                    id: product.id,
                    nameAndroid: product.nameAndroid,
                    oneTimePurchaseOfferDetailsAndroid: null,
                    platform: product.platform,
                    price: product.price,
                    subscriptionOfferDetailsAndroid:
                        product.subscriptionOfferDetailsAndroid,
                    title: product.title,
                    type: product.type,
                  );
                  subscriptionProducts.add(compatibleProduct);
                }
              }
            }

            return gentype.FetchProductsResultProducts(subscriptionProducts);
          } else {
            // Default to in-app products
            final inApps =
                products.whereType<gentype.Product>().toList(growable: false);
            return gentype.FetchProductsResultProducts(inApps);
          }
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
              // A purchase is an active subscription if it's in Purchased state
              // Note: We don't check isAcknowledgedAndroid because:
              // 1. The purchase might have just been acknowledged but not yet refreshed
              // 2. autoRenewingAndroid can be false for test purchases or non-renewing subs
              // 3. If it's in our purchase list and state is Purchased, it's valid
              final bool isActive =
                  purchase.purchaseState == gentype.PurchaseState.Purchased;

              if (isActive) {
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

  // MARK: - Alternative Billing APIs

  /// Check if alternative billing is available on Android
  gentype.MutationCheckAlternativeBillingAvailabilityAndroidHandler
      get checkAlternativeBillingAvailabilityAndroid => () async {
            if (!_platform.isAndroid) {
              return false;
            }
            try {
              final result = await _channel.invokeMethod<bool>(
                  'checkAlternativeBillingAvailabilityAndroid');
              return result ?? false;
            } catch (error) {
              debugPrint(
                  'checkAlternativeBillingAvailabilityAndroid error: $error');
              return false;
            }
          };

  /// Show alternative billing information dialog on Android
  gentype.MutationShowAlternativeBillingDialogAndroidHandler
      get showAlternativeBillingDialogAndroid => () async {
            if (!_platform.isAndroid) {
              return false;
            }
            try {
              final result = await _channel
                  .invokeMethod<bool>('showAlternativeBillingDialogAndroid');
              return result ?? false;
            } catch (error) {
              debugPrint('showAlternativeBillingDialogAndroid error: $error');
              return false;
            }
          };

  /// Create alternative billing reporting token on Android
  gentype.MutationCreateAlternativeBillingTokenAndroidHandler
      get createAlternativeBillingTokenAndroid => () async {
            if (!_platform.isAndroid) {
              return null;
            }
            try {
              final result = await _channel
                  .invokeMethod<String>('createAlternativeBillingTokenAndroid');
              return result;
            } catch (error) {
              debugPrint('createAlternativeBillingTokenAndroid error: $error');
              return null;
            }
          };

  /// Present external purchase notice sheet on iOS (iOS 18.2+)
  gentype.MutationPresentExternalPurchaseNoticeSheetIOSHandler
      get presentExternalPurchaseNoticeSheetIOS => () async {
            if (!_platform.isIOS) {
              return const gentype.ExternalPurchaseNoticeResultIOS(
                  result: gentype.ExternalPurchaseNoticeAction.Dismissed);
            }
            try {
              final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
                  'presentExternalPurchaseNoticeSheetIOS');
              if (result != null) {
                return gentype.ExternalPurchaseNoticeResultIOS.fromJson(
                    Map<String, dynamic>.from(result));
              }
              return const gentype.ExternalPurchaseNoticeResultIOS(
                  result: gentype.ExternalPurchaseNoticeAction.Dismissed);
            } catch (error) {
              debugPrint('presentExternalPurchaseNoticeSheetIOS error: $error');
              return gentype.ExternalPurchaseNoticeResultIOS(
                  result: gentype.ExternalPurchaseNoticeAction.Dismissed,
                  error: error.toString());
            }
          };

  /// Present external purchase link on iOS (iOS 16.0+)
  gentype.MutationPresentExternalPurchaseLinkIOSHandler
      get presentExternalPurchaseLinkIOS => (String url) async {
            if (!_platform.isIOS) {
              return const gentype.ExternalPurchaseLinkResultIOS(
                  success: false);
            }
            try {
              final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
                  'presentExternalPurchaseLinkIOS', url);
              if (result != null) {
                return gentype.ExternalPurchaseLinkResultIOS.fromJson(
                    Map<String, dynamic>.from(result));
              }
              return const gentype.ExternalPurchaseLinkResultIOS(
                  success: false);
            } catch (error) {
              debugPrint('presentExternalPurchaseLinkIOS error: $error');
              return gentype.ExternalPurchaseLinkResultIOS(
                  success: false, error: error.toString());
            }
          };

  gentype.QueryHandlers get queryHandlers => gentype.QueryHandlers(
        fetchProducts: fetchProducts,
        getActiveSubscriptions: getActiveSubscriptions,
        getAppTransactionIOS: getAppTransactionIOS,
        getAvailablePurchases: getAvailablePurchases,
        getPendingTransactionsIOS: getPendingTransactionsIOS,
        getPromotedProductIOS: getPromotedProductIOS,
        getStorefront: getStorefront,
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
        // Alternative Billing APIs
        checkAlternativeBillingAvailabilityAndroid:
            checkAlternativeBillingAvailabilityAndroid,
        showAlternativeBillingDialogAndroid:
            showAlternativeBillingDialogAndroid,
        createAlternativeBillingTokenAndroid:
            createAlternativeBillingTokenAndroid,
        presentExternalPurchaseNoticeSheetIOS:
            presentExternalPurchaseNoticeSheetIOS,
        presentExternalPurchaseLinkIOS: presentExternalPurchaseLinkIOS,
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
        userChoiceBillingAndroid: () async =>
            await _userChoiceBillingAndroidListener.stream.first,
      );
}
