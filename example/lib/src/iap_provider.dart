import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

/// The main provider for flutter IAP functionality
/// This provider manages the IAP connection and provides methods to interact with the store
class IapProvider extends InheritedWidget {
  final FlutterInappPurchase iap;
  final bool connected;
  final List<IAPItem> products;
  final List<IAPItem> subscriptions;
  final List<PurchasedItem> purchases;
  final List<PurchasedItem> availableItems;
  final String? error;
  final bool loading;

  // Streams
  final Stream<PurchasedItem?> purchaseUpdated;
  final Stream<PurchaseResult?> purchaseError;

  // Methods
  final Future<void> Function() initConnection;
  final Future<void> Function() endConnection;
  final Future<List<IAPItem>> Function(List<String> skus) getProducts;
  final Future<List<IAPItem>> Function(List<String> skus) getSubscriptions;
  final Future<List<PurchasedItem>?> Function() getAvailableItems;
  final Future<List<PurchasedItem>?> Function() getPurchaseHistory;
  final Future<void> Function(String sku) requestPurchase;
  final Future<void> Function(String sku) requestSubscription;
  final Future<void> Function(PurchasedItem purchase, {bool isConsumable})
      finishTransaction;
  final Future<void> Function() restorePurchases;
  final Future<void> Function() presentCodeRedemption;
  final Future<void> Function() showManageSubscriptions;
  final Future<void> Function() clearTransactionCache;

  const IapProvider({
    required this.iap,
    required this.connected,
    required this.products,
    required this.subscriptions,
    required this.purchases,
    required this.availableItems,
    required this.error,
    required this.loading,
    required this.purchaseUpdated,
    required this.purchaseError,
    required this.initConnection,
    required this.endConnection,
    required this.getProducts,
    required this.getSubscriptions,
    required this.getAvailableItems,
    required this.getPurchaseHistory,
    required this.requestPurchase,
    required this.requestSubscription,
    required this.finishTransaction,
    required this.restorePurchases,
    required this.presentCodeRedemption,
    required this.showManageSubscriptions,
    required this.clearTransactionCache,
    required Widget child,
    Key? key,
  }) : super(key: key, child: child);

  static IapProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<IapProvider>();
  }

  @override
  bool updateShouldNotify(IapProvider oldWidget) {
    return connected != oldWidget.connected ||
        products != oldWidget.products ||
        purchases != oldWidget.purchases ||
        availableItems != oldWidget.availableItems ||
        error != oldWidget.error ||
        loading != oldWidget.loading;
  }
}

/// Widget that provides IAP functionality to its children
class IapProviderWidget extends StatefulWidget {
  final Widget child;

  const IapProviderWidget({
    required this.child,
    Key? key,
  }) : super(key: key);

  @override
  State<IapProviderWidget> createState() => _IapProviderWidgetState();
}

class _IapProviderWidgetState extends State<IapProviderWidget> {
  final FlutterInappPurchase _iap = FlutterInappPurchase.instance;

  bool _connected = false;
  List<IAPItem> _products = [];
  List<IAPItem> _subscriptions = [];
  final List<PurchasedItem> _purchases = [];
  List<PurchasedItem> _availableItems = [];
  String? _error;
  bool _loading = false;

  StreamSubscription<PurchasedItem?>? _purchaseUpdatedSubscription;
  StreamSubscription<PurchaseResult?>? _purchaseErrorSubscription;

  @override
  void initState() {
    super.initState();
    // Initialize connection when provider is created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initConnection();
    });
  }

  @override
  void dispose() {
    _purchaseUpdatedSubscription?.cancel();
    _purchaseErrorSubscription?.cancel();
    _endConnection();
    super.dispose();
  }

  Future<void> _initConnection() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _iap.initConnection();

      // Set up listeners
      _purchaseUpdatedSubscription =
          FlutterInappPurchase.purchaseUpdated.listen((purchase) {
        if (purchase != null) {
          setState(() {
            _purchases.add(purchase);
          });
        }
      });

      _purchaseErrorSubscription =
          FlutterInappPurchase.purchaseError.listen((error) {
        setState(() {
          _error = error?.message ?? 'Unknown error';
        });
      });

      setState(() {
        _connected = true;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
        _connected = false;
      });
    }
  }

  Future<void> _endConnection() async {
    try {
      await _iap.finalize();
      setState(() {
        _connected = false;
      });
    } catch (e) {
      print('Error ending connection: $e');
    }
  }

  Future<List<IAPItem>> _getProducts(List<String> skus) async {
    try {
      final products = await _iap.getProducts(skus);
      setState(() {
        _products = products;
      });
      return products;
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
      return [];
    }
  }

  Future<List<IAPItem>> _getSubscriptions(List<String> skus) async {
    try {
      final subscriptions = await _iap.getSubscriptions(skus);
      setState(() {
        _subscriptions = subscriptions;
      });
      return subscriptions;
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
      return [];
    }
  }

  Future<List<PurchasedItem>?> _getAvailableItems() async {
    try {
      final items = await _iap.getAvailableItemsIOS();
      setState(() {
        _availableItems = items ?? [];
      });
      return items;
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
      return null;
    }
  }

  Future<List<PurchasedItem>?> _getPurchaseHistory() async {
    try {
      // Note: getPurchaseHistory is not available in the current flutter_inapp_purchase
      // You would need to use getAvailableItemsIOS instead
      final history = await _iap.getAvailableItemsIOS();
      return history;
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
      return null;
    }
  }

  Future<void> _requestPurchase(String sku) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _iap.requestPurchase(
        request: RequestPurchase(
          ios: RequestPurchaseIOS(sku: sku),
        ),
        type: PurchaseType.inapp,
      );
      setState(() {
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _requestSubscription(String sku) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _iap.requestPurchase(
        request: RequestPurchase(
          ios: RequestPurchaseIOS(sku: sku),
        ),
        type: PurchaseType.subs,
      );
      setState(() {
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _finishTransaction(PurchasedItem purchase,
      {bool isConsumable = true}) async {
    try {
      await _iap.finishTransactionIOS(purchase, isConsumable: isConsumable);
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  Future<void> _restorePurchases() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _iap.restorePurchases();
      await _getAvailableItems();
      setState(() {
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _presentCodeRedemption() async {
    try {
      await _iap.presentCodeRedemptionSheet();
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  Future<void> _showManageSubscriptions() async {
    try {
      await _iap.showManageSubscriptions();
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  Future<void> _clearTransactionCache() async {
    try {
      await _iap.clearTransactionCache();
      setState(() {
        _purchases.clear();
        _availableItems.clear();
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return IapProvider(
      iap: _iap,
      connected: _connected,
      products: _products,
      subscriptions: _subscriptions,
      purchases: _purchases,
      availableItems: _availableItems,
      error: _error,
      loading: _loading,
      purchaseUpdated: FlutterInappPurchase.purchaseUpdated,
      purchaseError: FlutterInappPurchase.purchaseError,
      initConnection: _initConnection,
      endConnection: _endConnection,
      getProducts: _getProducts,
      getSubscriptions: _getSubscriptions,
      getAvailableItems: _getAvailableItems,
      getPurchaseHistory: _getPurchaseHistory,
      requestPurchase: _requestPurchase,
      requestSubscription: _requestSubscription,
      finishTransaction: _finishTransaction,
      restorePurchases: _restorePurchases,
      presentCodeRedemption: _presentCodeRedemption,
      showManageSubscriptions: _showManageSubscriptions,
      clearTransactionCache: _clearTransactionCache,
      child: widget.child,
    );
  }
}
