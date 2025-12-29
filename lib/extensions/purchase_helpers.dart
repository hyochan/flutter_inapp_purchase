import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

extension PurchaseHelpers on Purchase {
  String? get transactionIdFor {
    if (this is PurchaseIOS) {
      final value = (this as PurchaseIOS).transactionId;
      if (value.isNotEmpty) {
        return value;
      }
    } else if (this is PurchaseAndroid) {
      final value = (this as PurchaseAndroid).transactionId;
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }

    return id.isEmpty ? null : id;
  }

  int? get androidPurchaseStateValue {
    if (this is! PurchaseAndroid) {
      return null;
    }
    switch ((this as PurchaseAndroid).purchaseState) {
      case PurchaseState.Purchased:
        return AndroidPurchaseState.Purchased.value;
      case PurchaseState.Pending:
        return AndroidPurchaseState.Pending.value;
      case PurchaseState.Unknown:
        return AndroidPurchaseState.Unknown.value;
    }
  }

  TransactionState? get iosTransactionState {
    if (this is! PurchaseIOS) {
      return null;
    }
    switch ((this as PurchaseIOS).purchaseState) {
      case PurchaseState.Purchased:
        return TransactionState.purchased;
      case PurchaseState.Pending:
        return TransactionState.purchasing;
      case PurchaseState.Unknown:
        return TransactionState.purchasing;
    }
  }

  bool? get androidIsAcknowledged => this is PurchaseAndroid
      ? (this as PurchaseAndroid).isAcknowledgedAndroid
      : null;

  int? get iosQuantity =>
      this is PurchaseIOS ? (this as PurchaseIOS).quantityIOS : null;

  String? get iosOriginalTransactionId => this is PurchaseIOS
      ? (this as PurchaseIOS).originalTransactionIdentifierIOS
      : null;
}
