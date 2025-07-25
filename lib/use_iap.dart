import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'flutter_inapp_purchase.dart';

/// Options for configuring the IAP hook
class UseIAPOptions {
  final void Function(Purchase purchase)? onPurchaseSuccess;
  final void Function(PurchaseError error)? onPurchaseError;
  final void Function(Object error)? onSyncError;
  final bool shouldAutoSyncPurchases;

  const UseIAPOptions({
    this.onPurchaseSuccess,
    this.onPurchaseError,
    this.onSyncError,
    this.shouldAutoSyncPurchases = true,
  });
}

/// Return type for useIAP hook
class UseIAPReturn {
  final bool connected;
  final List<Product> products;
  final List<ProductPurchaseIos> promotedProductsIOS;
  final List<Subscription> subscriptions;
  final List<Purchase> purchaseHistories;
  final List<Purchase> availablePurchases;
  final Purchase? currentPurchase;
  final PurchaseError? currentPurchaseError;
  final void Function() clearCurrentPurchase;
  final void Function() clearCurrentPurchaseError;
  final Future<void> Function({
    required Purchase purchase,
    bool isConsumable,
  }) finishTransaction;
  final Future<void> Function() getAvailablePurchases;
  final Future<void> Function() getPurchaseHistories;
  final Future<void> Function(List<String> skus) getProducts;
  final Future<void> Function(List<String> skus) getSubscriptions;
  final Future<void> Function({
    required List<String> skus,
    PurchaseType type,
  }) requestProducts;
  final Future<void> Function({
    required RequestPurchase request,
    PurchaseType type,
  }) requestPurchase;
  final Future<dynamic> Function(
    String sku, {
    String? packageName,
    String? productToken,
    String? accessToken,
    bool? isSub,
  }) validateReceipt;
  final Future<void> Function() restorePurchases;

  const UseIAPReturn({
    required this.connected,
    required this.products,
    required this.promotedProductsIOS,
    required this.subscriptions,
    required this.purchaseHistories,
    required this.availablePurchases,
    required this.clearCurrentPurchase,
    required this.clearCurrentPurchaseError,
    required this.finishTransaction,
    required this.getAvailablePurchases,
    required this.getPurchaseHistories,
    required this.getProducts,
    required this.getSubscriptions,
    required this.requestProducts,
    required this.requestPurchase,
    required this.validateReceipt,
    required this.restorePurchases,
    this.currentPurchase,
    this.currentPurchaseError,
  });
}

/// Main useIAP hook
UseIAPReturn useIAP([UseIAPOptions? options]) {
  final iap = useMemoized(() => FlutterInappPurchase.instance);
  final optionsRef = useRef<UseIAPOptions?>(options);

  // State management
  final connected = useState<bool>(false);
  final products = useState<List<Product>>([]);
  final promotedProductsIOS = useState<List<ProductPurchaseIos>>([]);
  final subscriptions = useState<List<Subscription>>([]);
  final purchaseHistories = useState<List<Purchase>>([]);
  final availablePurchases = useState<List<Purchase>>([]);
  final currentPurchase = useState<Purchase?>(null);
  final currentPurchaseError = useState<PurchaseError?>(null);

  // Subscriptions ref
  final subscriptionsRef = useRef<Map<String, StreamSubscription<dynamic>>>({});
  final subscriptionsRefState = useRef<List<Subscription>>([]);

  // Update refs when values change
  useEffect(() {
    optionsRef.value = options;
    return null;
  }, [options]);

  useEffect(() {
    subscriptionsRefState.value = subscriptions.value;
    return null;
  }, [subscriptions.value]);

  // Helper function to merge arrays with duplicate checking
  List<T> mergeWithDuplicateCheck<T>(
    List<T> existingItems,
    List<T> newItems,
    String Function(T) getKey,
  ) {
    final merged = [...existingItems];
    for (final newItem in newItems) {
      final isDuplicate = merged.any(
        (existingItem) => getKey(existingItem) == getKey(newItem),
      );
      if (!isDuplicate) {
        merged.add(newItem);
      }
    }
    return merged;
  }

  // Clear functions
  final clearCurrentPurchase = useCallback(() {
    currentPurchase.value = null;
  }, []);

  final clearCurrentPurchaseError = useCallback(() {
    currentPurchaseError.value = null;
  }, []);

  // Get products
  final getProductsInternal = useCallback((List<String> skus) async {
    try {
      final params = RequestProductsParams(
        skus: skus,
        type: PurchaseType.inapp,
      );
      final result = await iap.requestProducts(params);
      final productList = result.whereType<Product>().toList();

      products.value = mergeWithDuplicateCheck(
        products.value,
        productList,
        (product) => product.productId,
      );
    } catch (error) {
      debugPrint('Error fetching products: $error');
      rethrow;
    }
  }, [iap]);

  // Get subscriptions
  final getSubscriptionsInternal = useCallback((List<String> skus) async {
    try {
      final params = RequestProductsParams(
        skus: skus,
        type: PurchaseType.subs,
      );
      final result = await iap.requestProducts(params);
      final subscriptionList = result.whereType<Subscription>().toList();

      subscriptions.value = mergeWithDuplicateCheck(
        subscriptions.value,
        subscriptionList,
        (subscription) => subscription.productId,
      );
    } catch (error) {
      debugPrint('Error fetching subscriptions: $error');
      rethrow;
    }
  }, [iap]);

  // Request products (combined)
  final requestProductsInternal = useCallback(({
    required List<String> skus,
    PurchaseType type = PurchaseType.inapp,
  }) async {
    try {
      final params = RequestProductsParams(skus: skus, type: type);
      final result = await iap.requestProducts(params);

      if (type == PurchaseType.subs) {
        final subscriptionList = result.whereType<Subscription>().toList();
        subscriptions.value = mergeWithDuplicateCheck(
          subscriptions.value,
          subscriptionList,
          (subscription) => subscription.productId,
        );
      } else {
        final productList = result.whereType<Product>().toList();
        products.value = mergeWithDuplicateCheck(
          products.value,
          productList,
          (product) => product.productId,
        );
      }
    } catch (error) {
      debugPrint('Error fetching products: $error');
      rethrow;
    }
  }, [iap]);

  // Get available purchases
  final getAvailablePurchasesInternal = useCallback(() async {
    try {
      final result = await iap.getAvailablePurchases();
      availablePurchases.value = result;
    } catch (error) {
      debugPrint('Error fetching available purchases: $error');
      rethrow;
    }
  }, [iap]);

  // Get purchase histories
  final getPurchaseHistoriesInternal = useCallback(() async {
    try {
      final result = await iap.getPurchaseHistories();
      purchaseHistories.value = result;
    } catch (error) {
      debugPrint('Error fetching purchase histories: $error');
      rethrow;
    }
  }, [iap]);

  // Finish transaction
  final finishTransactionInternal = useCallback(({
    required Purchase purchase,
    bool isConsumable = false,
  }) async {
    try {
      await iap.finishTransaction(purchase, isConsumable: isConsumable);

      // Clear current purchase if it matches
      if (purchase.productId == currentPurchase.value?.productId) {
        clearCurrentPurchase();
      }
      if (purchase.productId == currentPurchaseError.value?.productId) {
        clearCurrentPurchaseError();
      }
    } catch (error) {
      rethrow;
    }
  }, [iap, clearCurrentPurchase, clearCurrentPurchaseError]);

  // Request purchase
  final requestPurchaseInternal = useCallback(({
    required RequestPurchase request,
    PurchaseType type = PurchaseType.inapp,
  }) async {
    clearCurrentPurchase();
    clearCurrentPurchaseError();

    try {
      await iap.requestPurchase(request: request, type: type);
    } catch (error) {
      rethrow;
    }
  }, [iap, clearCurrentPurchase, clearCurrentPurchaseError]);

  // Refresh subscription status
  final refreshSubscriptionStatus = useCallback((String productId) async {
    try {
      if (subscriptionsRefState.value
          .any((sub) => sub.productId == productId)) {
        await getSubscriptionsInternal([productId]);
        await getAvailablePurchasesInternal();
      }
    } catch (error) {
      debugPrint('Failed to refresh subscription status: $error');
    }
  }, [getAvailablePurchasesInternal, getSubscriptionsInternal]);

  // Restore purchases
  final restorePurchasesInternal = useCallback(() async {
    try {
      if (Platform.isIOS) {
        await iap.restorePurchases();
      }
      await getAvailablePurchasesInternal();
    } catch (error) {
      if (optionsRef.value?.onSyncError != null) {
        optionsRef.value!.onSyncError!(error);
      } else {
        debugPrint('Error restoring purchases: $error');
      }
      rethrow;
    }
  }, [iap, getAvailablePurchasesInternal]);

  // Validate receipt
  final validateReceiptInternal = useCallback((
    String sku, {
    String? packageName,
    String? productToken,
    String? accessToken,
    bool? isSub,
  }) async {
    if (Platform.isIOS) {
      // iOS validation would be implemented here
      throw UnimplementedError('iOS receipt validation not implemented');
    } else if (Platform.isAndroid) {
      if (packageName == null || productToken == null || accessToken == null) {
        throw ArgumentError(
          'Android validation requires packageName, productToken, and accessToken',
        );
      }
      // Android validation would be implemented here
      throw UnimplementedError('Android receipt validation not implemented');
    } else {
      throw UnsupportedError('Platform not supported');
    }
  }, []);

  // Initialize connection and set up listeners
  useEffect(() {
    Future<void> initConnection() async {
      try {
        await iap.initConnection();
        connected.value = true;

        // Set up purchase update listener
        subscriptionsRef.value['purchaseUpdate'] =
            iap.purchaseUpdatedListener.listen((purchase) async {
          currentPurchaseError.value = null;
          currentPurchase.value = purchase;

          // Refresh subscription status if it's a subscription
          if (purchase.expirationDate != null) {
            await refreshSubscriptionStatus(purchase.productId);
          }

          // Call success callback
          if (optionsRef.value?.onPurchaseSuccess != null) {
            optionsRef.value!.onPurchaseSuccess!(purchase);
          }
        });

        // Set up purchase error listener
        subscriptionsRef.value['purchaseError'] =
            iap.purchaseErrorListener.listen((error) {
          currentPurchase.value = null;
          currentPurchaseError.value = error;

          // Call error callback
          if (optionsRef.value?.onPurchaseError != null) {
            optionsRef.value!.onPurchaseError!(error);
          }
        });

        // iOS promoted products handling
        if (Platform.isIOS) {
          // For now, we'll skip promoted products handling as it requires
          // a separate API or casting logic
          // This would need to be implemented with proper type checking
        }
      } catch (error) {
        connected.value = false;
        debugPrint('Failed to initialize IAP connection: $error');
      }
    }

    initConnection();

    // Cleanup function
    return () {
      // Cancel all subscriptions
      subscriptionsRef.value.forEach((key, subscription) {
        subscription.cancel();
      });
      subscriptionsRef.value.clear();

      // End connection
      iap.endConnection().catchError((dynamic error) {
        debugPrint('Error ending connection: $error');
      });

      connected.value = false;
    };
  }, [iap, refreshSubscriptionStatus]);

  return UseIAPReturn(
    connected: connected.value,
    products: products.value,
    promotedProductsIOS: promotedProductsIOS.value,
    subscriptions: subscriptions.value,
    purchaseHistories: purchaseHistories.value,
    availablePurchases: availablePurchases.value,
    currentPurchase: currentPurchase.value,
    currentPurchaseError: currentPurchaseError.value,
    clearCurrentPurchase: clearCurrentPurchase,
    clearCurrentPurchaseError: clearCurrentPurchaseError,
    finishTransaction: finishTransactionInternal,
    getAvailablePurchases: getAvailablePurchasesInternal,
    getPurchaseHistories: getPurchaseHistoriesInternal,
    getProducts: getProductsInternal,
    getSubscriptions: getSubscriptionsInternal,
    requestProducts: requestProductsInternal,
    requestPurchase: requestPurchaseInternal,
    validateReceipt: validateReceiptInternal,
    restorePurchases: restorePurchasesInternal,
  );
}
