/// Event types for flutter_inapp_purchase (OpenIAP compliant)
library;

import 'types.dart';

/// Event types enum (OpenIAP compliant)
enum IapEvent {
  /// Purchase successful or updated
  purchaseUpdated,

  /// Purchase failed or cancelled
  purchaseError,

  /// Promoted product clicked (iOS)
  promotedProductIos,
}

/// Purchase updated event payload
class PurchaseUpdatedEvent {
  final Purchase purchase;

  PurchaseUpdatedEvent({required this.purchase});
}

/// Purchase error event payload
class PurchaseErrorEvent {
  final PurchaseError error;

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
