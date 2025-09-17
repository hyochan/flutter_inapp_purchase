// Event types for flutter_inapp_purchase (OpenIAP compliant)

import 'types.dart' as types;

/// Alias to the generated event enum so callers keep using the familiar name.
typedef IapEvent = types.IapEvent;

/// Purchase updated event payload
class PurchaseUpdatedEvent {
  final types.Purchase purchase;

  PurchaseUpdatedEvent({required this.purchase});
}

/// Purchase error event payload
class PurchaseErrorEvent {
  final types.PurchaseError error;

  PurchaseErrorEvent({required this.error});
}

/// Promoted product event payload (iOS)
class PromotedProductEvent {
  final String productId;

  PromotedProductEvent({required this.productId});
}

/// Connection state event
class ConnectionStateEvent {
  final bool isConnected;
  final String? message;

  ConnectionStateEvent({required this.isConnected, this.message});
}

/// Event listener subscription
class EventSubscription {
  final void Function() _removeListener;

  EventSubscription(this._removeListener);

  /// Remove this event listener
  void remove() {
    _removeListener();
  }
}
