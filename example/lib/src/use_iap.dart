import 'package:flutter/widgets.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'iap_provider.dart';

/// Hook to access IAP functionality
/// Similar to React's useContext pattern
class UseIap {
  final BuildContext context;
  late final IapProvider? _provider;

  UseIap(this.context) {
    _provider = IapProvider.of(context);
  }

  bool get connected => _provider?.connected ?? false;
  List<IAPItem> get products => _provider?.products ?? [];
  List<IAPItem> get subscriptions => _provider?.subscriptions ?? [];
  List<PurchasedItem> get purchases => _provider?.purchases ?? [];
  List<PurchasedItem> get availableItems => _provider?.availableItems ?? [];
  String? get error => _provider?.error;
  bool get loading => _provider?.loading ?? false;

  Future<void> initConnection() async {
    await _provider?.initConnection();
  }

  Future<void> endConnection() async {
    await _provider?.endConnection();
  }

  /// Request products from the store (flutter IAP compatible)
  Future<List<IAPItem>> requestProducts({
    required List<String> skus,
    PurchaseType type = PurchaseType.inapp,
  }) async {
    if (type == PurchaseType.subs) {
      return await _provider?.getSubscriptions(skus) ?? [];
    } else {
      return await _provider?.getProducts(skus) ?? [];
    }
  }

  @Deprecated(
      'Use requestProducts with skus parameter instead. Will be removed in 6.1.0')
  Future<List<IAPItem>> getProducts(List<String> skus) async {
    return await requestProducts(skus: skus, type: PurchaseType.inapp);
  }

  @Deprecated(
      'Use requestProducts with type: PurchaseType.subs instead. Will be removed in 6.1.0')
  Future<List<IAPItem>> getSubscriptions(List<String> skus) async {
    return await requestProducts(skus: skus, type: PurchaseType.subs);
  }

  Future<List<PurchasedItem>?> getAvailableItems() async {
    return await _provider?.getAvailableItems();
  }

  Future<List<PurchasedItem>?> getPurchaseHistory() async {
    return await _provider?.getPurchaseHistory();
  }

  Future<void> requestPurchase(String sku,
      {PurchaseType type = PurchaseType.inapp}) async {
    if (type == PurchaseType.subs) {
      await _provider?.requestSubscription(sku);
    } else {
      await _provider?.requestPurchase(sku);
    }
  }

  @Deprecated(
      'Use requestPurchase with type: PurchaseType.subs instead. Will be removed in 6.1.0')
  Future<void> requestSubscription(String sku) async {
    await requestPurchase(sku, type: PurchaseType.subs);
  }

  Future<void> finishTransaction(PurchasedItem purchase,
      {bool isConsumable = true}) async {
    await _provider?.finishTransaction(purchase, isConsumable: isConsumable);
  }

  Future<void> restorePurchases() async {
    await _provider?.restorePurchases();
  }

  Future<void> presentCodeRedemption() async {
    await _provider?.presentCodeRedemption();
  }

  Future<void> showManageSubscriptions() async {
    await _provider?.showManageSubscriptions();
  }

  Future<void> clearTransactionCache() async {
    await _provider?.clearTransactionCache();
  }
}

/// Helper function to use IAP in widgets
UseIap useIap(BuildContext context) {
  return UseIap(context);
}
