// ============================================================================
// AUTO-GENERATED TYPES — DO NOT EDIT DIRECTLY
// Run `npm run generate` after updating any *.graphql schema file.
// ============================================================================

// ignore_for_file: unused_element, unused_field

import 'dart:async';

// MARK: - Enums

/// Alternative billing mode for Android
/// Controls which billing system is used
/// @deprecated Use enableBillingProgramAndroid with BillingProgramAndroid instead.
/// Use USER_CHOICE_BILLING for user choice billing, EXTERNAL_OFFER for alternative only.
enum AlternativeBillingModeAndroid {
  /// Standard Google Play billing (default)
  None('none'),
  /// User choice billing - user can select between Google Play or alternative
  /// Requires Google Play Billing Library 7.0+
  /// @deprecated Use BillingProgramAndroid.USER_CHOICE_BILLING instead
  UserChoice('user-choice'),
  /// Alternative billing only - no Google Play billing option
  /// Requires Google Play Billing Library 6.2+
  /// @deprecated Use BillingProgramAndroid.EXTERNAL_OFFER instead
  AlternativeOnly('alternative-only');

  const AlternativeBillingModeAndroid(this.value);
  final String value;

  factory AlternativeBillingModeAndroid.fromJson(String value) {
    switch (value) {
      case 'none':
      case 'NONE':
        return AlternativeBillingModeAndroid.None;
      case 'user-choice':
      case 'USER_CHOICE':
        return AlternativeBillingModeAndroid.UserChoice;
      case 'alternative-only':
      case 'ALTERNATIVE_ONLY':
        return AlternativeBillingModeAndroid.AlternativeOnly;
    }
    throw ArgumentError('Unknown AlternativeBillingModeAndroid value: $value');
  }

  String toJson() => value;
}

/// Billing program types for external content links, external offers, and external payments (Android)
/// Available in Google Play Billing Library 8.2.0+, EXTERNAL_PAYMENTS added in 8.3.0
enum BillingProgramAndroid {
  /// Unspecified billing program. Do not use.
  Unspecified('unspecified'),
  /// User Choice Billing program.
  /// User can select between Google Play Billing or alternative billing.
  /// Available in Google Play Billing Library 7.0+
  UserChoiceBilling('user-choice-billing'),
  /// External Content Links program.
  /// Allows linking to external content outside the app.
  /// Available in Google Play Billing Library 8.2.0+
  ExternalContentLink('external-content-link'),
  /// External Offers program.
  /// Allows offering digital content purchases outside the app.
  /// Available in Google Play Billing Library 8.2.0+
  ExternalOffer('external-offer'),
  /// External Payments program (Japan only).
  /// Allows presenting a side-by-side choice between Google Play Billing and developer's external payment option.
  /// Users can choose to complete the purchase on the developer's website.
  /// Available in Google Play Billing Library 8.3.0+
  ExternalPayments('external-payments');

  const BillingProgramAndroid(this.value);
  final String value;

  factory BillingProgramAndroid.fromJson(String value) {
    switch (value) {
      case 'unspecified':
      case 'UNSPECIFIED':
        return BillingProgramAndroid.Unspecified;
      case 'user-choice-billing':
      case 'USER_CHOICE_BILLING':
        return BillingProgramAndroid.UserChoiceBilling;
      case 'external-content-link':
      case 'EXTERNAL_CONTENT_LINK':
        return BillingProgramAndroid.ExternalContentLink;
      case 'external-offer':
      case 'EXTERNAL_OFFER':
        return BillingProgramAndroid.ExternalOffer;
      case 'external-payments':
      case 'EXTERNAL_PAYMENTS':
        return BillingProgramAndroid.ExternalPayments;
    }
    throw ArgumentError('Unknown BillingProgramAndroid value: $value');
  }

  String toJson() => value;
}

/// Launch mode for developer billing option (Android)
/// Determines how the external payment URL is launched
/// Available in Google Play Billing Library 8.3.0+
enum DeveloperBillingLaunchModeAndroid {
  /// Unspecified launch mode. Do not use.
  Unspecified('unspecified'),
  /// Google Play will launch the link in an external browser or eligible app.
  /// Use this when you want Play to handle launching the external payment URL.
  LaunchInExternalBrowserOrApp('launch-in-external-browser-or-app'),
  /// The caller app will launch the link after Play returns control.
  /// Use this when you want to handle launching the external payment URL yourself.
  CallerWillLaunchLink('caller-will-launch-link');

  const DeveloperBillingLaunchModeAndroid(this.value);
  final String value;

  factory DeveloperBillingLaunchModeAndroid.fromJson(String value) {
    switch (value) {
      case 'unspecified':
      case 'UNSPECIFIED':
        return DeveloperBillingLaunchModeAndroid.Unspecified;
      case 'launch-in-external-browser-or-app':
      case 'LAUNCH_IN_EXTERNAL_BROWSER_OR_APP':
        return DeveloperBillingLaunchModeAndroid.LaunchInExternalBrowserOrApp;
      case 'caller-will-launch-link':
      case 'CALLER_WILL_LAUNCH_LINK':
        return DeveloperBillingLaunchModeAndroid.CallerWillLaunchLink;
    }
    throw ArgumentError('Unknown DeveloperBillingLaunchModeAndroid value: $value');
  }

  String toJson() => value;
}

enum ErrorCode {
  Unknown('unknown'),
  UserCancelled('user-cancelled'),
  UserError('user-error'),
  ItemUnavailable('item-unavailable'),
  RemoteError('remote-error'),
  NetworkError('network-error'),
  ServiceError('service-error'),
  ReceiptFailed('receipt-failed'),
  ReceiptFinished('receipt-finished'),
  ReceiptFinishedFailed('receipt-finished-failed'),
  PurchaseVerificationFailed('purchase-verification-failed'),
  PurchaseVerificationFinished('purchase-verification-finished'),
  PurchaseVerificationFinishFailed('purchase-verification-finish-failed'),
  NotPrepared('not-prepared'),
  NotEnded('not-ended'),
  AlreadyOwned('already-owned'),
  DeveloperError('developer-error'),
  BillingResponseJsonParseError('billing-response-json-parse-error'),
  DeferredPayment('deferred-payment'),
  Interrupted('interrupted'),
  IapNotAvailable('iap-not-available'),
  PurchaseError('purchase-error'),
  SyncError('sync-error'),
  TransactionValidationFailed('transaction-validation-failed'),
  ActivityUnavailable('activity-unavailable'),
  AlreadyPrepared('already-prepared'),
  Pending('pending'),
  ConnectionClosed('connection-closed'),
  InitConnection('init-connection'),
  ServiceDisconnected('service-disconnected'),
  QueryProduct('query-product'),
  SkuNotFound('sku-not-found'),
  SkuOfferMismatch('sku-offer-mismatch'),
  ItemNotOwned('item-not-owned'),
  BillingUnavailable('billing-unavailable'),
  FeatureNotSupported('feature-not-supported'),
  EmptySkuList('empty-sku-list');

  const ErrorCode(this.value);
  final String value;

  factory ErrorCode.fromJson(String value) {
    switch (value) {
      case 'unknown':
      case 'UNKNOWN':
      case 'Unknown':
        return ErrorCode.Unknown;
      case 'user-cancelled':
      case 'USER_CANCELLED':
      case 'UserCancelled':
        return ErrorCode.UserCancelled;
      case 'user-error':
      case 'USER_ERROR':
      case 'UserError':
        return ErrorCode.UserError;
      case 'item-unavailable':
      case 'ITEM_UNAVAILABLE':
      case 'ItemUnavailable':
        return ErrorCode.ItemUnavailable;
      case 'remote-error':
      case 'REMOTE_ERROR':
      case 'RemoteError':
        return ErrorCode.RemoteError;
      case 'network-error':
      case 'NETWORK_ERROR':
      case 'NetworkError':
        return ErrorCode.NetworkError;
      case 'service-error':
      case 'SERVICE_ERROR':
      case 'ServiceError':
        return ErrorCode.ServiceError;
      case 'receipt-failed':
      case 'RECEIPT_FAILED':
      case 'ReceiptFailed':
        return ErrorCode.ReceiptFailed;
      case 'receipt-finished':
      case 'RECEIPT_FINISHED':
      case 'ReceiptFinished':
        return ErrorCode.ReceiptFinished;
      case 'receipt-finished-failed':
      case 'RECEIPT_FINISHED_FAILED':
      case 'ReceiptFinishedFailed':
        return ErrorCode.ReceiptFinishedFailed;
      case 'purchase-verification-failed':
      case 'PURCHASE_VERIFICATION_FAILED':
      case 'PurchaseVerificationFailed':
        return ErrorCode.PurchaseVerificationFailed;
      case 'purchase-verification-finished':
      case 'PURCHASE_VERIFICATION_FINISHED':
      case 'PurchaseVerificationFinished':
        return ErrorCode.PurchaseVerificationFinished;
      case 'purchase-verification-finish-failed':
      case 'PURCHASE_VERIFICATION_FINISH_FAILED':
      case 'PurchaseVerificationFinishFailed':
        return ErrorCode.PurchaseVerificationFinishFailed;
      case 'not-prepared':
      case 'NOT_PREPARED':
      case 'NotPrepared':
        return ErrorCode.NotPrepared;
      case 'not-ended':
      case 'NOT_ENDED':
      case 'NotEnded':
        return ErrorCode.NotEnded;
      case 'already-owned':
      case 'ALREADY_OWNED':
      case 'AlreadyOwned':
        return ErrorCode.AlreadyOwned;
      case 'developer-error':
      case 'DEVELOPER_ERROR':
      case 'DeveloperError':
        return ErrorCode.DeveloperError;
      case 'billing-response-json-parse-error':
      case 'BILLING_RESPONSE_JSON_PARSE_ERROR':
      case 'BillingResponseJsonParseError':
        return ErrorCode.BillingResponseJsonParseError;
      case 'deferred-payment':
      case 'DEFERRED_PAYMENT':
      case 'DeferredPayment':
        return ErrorCode.DeferredPayment;
      case 'interrupted':
      case 'INTERRUPTED':
      case 'Interrupted':
        return ErrorCode.Interrupted;
      case 'iap-not-available':
      case 'IAP_NOT_AVAILABLE':
      case 'IapNotAvailable':
        return ErrorCode.IapNotAvailable;
      case 'purchase-error':
      case 'PURCHASE_ERROR':
      case 'PurchaseError':
        return ErrorCode.PurchaseError;
      case 'sync-error':
      case 'SYNC_ERROR':
      case 'SyncError':
        return ErrorCode.SyncError;
      case 'transaction-validation-failed':
      case 'TRANSACTION_VALIDATION_FAILED':
      case 'TransactionValidationFailed':
        return ErrorCode.TransactionValidationFailed;
      case 'activity-unavailable':
      case 'ACTIVITY_UNAVAILABLE':
      case 'ActivityUnavailable':
        return ErrorCode.ActivityUnavailable;
      case 'already-prepared':
      case 'ALREADY_PREPARED':
      case 'AlreadyPrepared':
        return ErrorCode.AlreadyPrepared;
      case 'pending':
      case 'PENDING':
      case 'Pending':
        return ErrorCode.Pending;
      case 'connection-closed':
      case 'CONNECTION_CLOSED':
      case 'ConnectionClosed':
        return ErrorCode.ConnectionClosed;
      case 'init-connection':
      case 'INIT_CONNECTION':
      case 'InitConnection':
        return ErrorCode.InitConnection;
      case 'service-disconnected':
      case 'SERVICE_DISCONNECTED':
      case 'ServiceDisconnected':
        return ErrorCode.ServiceDisconnected;
      case 'query-product':
      case 'QUERY_PRODUCT':
      case 'QueryProduct':
        return ErrorCode.QueryProduct;
      case 'sku-not-found':
      case 'SKU_NOT_FOUND':
      case 'SkuNotFound':
        return ErrorCode.SkuNotFound;
      case 'sku-offer-mismatch':
      case 'SKU_OFFER_MISMATCH':
      case 'SkuOfferMismatch':
        return ErrorCode.SkuOfferMismatch;
      case 'item-not-owned':
      case 'ITEM_NOT_OWNED':
      case 'ItemNotOwned':
        return ErrorCode.ItemNotOwned;
      case 'billing-unavailable':
      case 'BILLING_UNAVAILABLE':
      case 'BillingUnavailable':
        return ErrorCode.BillingUnavailable;
      case 'feature-not-supported':
      case 'FEATURE_NOT_SUPPORTED':
      case 'FeatureNotSupported':
        return ErrorCode.FeatureNotSupported;
      case 'empty-sku-list':
      case 'EMPTY_SKU_LIST':
      case 'EmptySkuList':
        return ErrorCode.EmptySkuList;
    }
    throw ArgumentError('Unknown ErrorCode value: $value');
  }

  String toJson() => value;
}

/// Launch mode for external link flow (Android)
/// Determines how the external URL is launched
/// Available in Google Play Billing Library 8.2.0+
enum ExternalLinkLaunchModeAndroid {
  /// Unspecified launch mode. Do not use.
  Unspecified('unspecified'),
  /// Play will launch the URL in an external browser or eligible app
  LaunchInExternalBrowserOrApp('launch-in-external-browser-or-app'),
  /// Play will not launch the URL. The app handles launching the URL after Play returns control.
  CallerWillLaunchLink('caller-will-launch-link');

  const ExternalLinkLaunchModeAndroid(this.value);
  final String value;

  factory ExternalLinkLaunchModeAndroid.fromJson(String value) {
    switch (value) {
      case 'unspecified':
      case 'UNSPECIFIED':
        return ExternalLinkLaunchModeAndroid.Unspecified;
      case 'launch-in-external-browser-or-app':
      case 'LAUNCH_IN_EXTERNAL_BROWSER_OR_APP':
        return ExternalLinkLaunchModeAndroid.LaunchInExternalBrowserOrApp;
      case 'caller-will-launch-link':
      case 'CALLER_WILL_LAUNCH_LINK':
        return ExternalLinkLaunchModeAndroid.CallerWillLaunchLink;
    }
    throw ArgumentError('Unknown ExternalLinkLaunchModeAndroid value: $value');
  }

  String toJson() => value;
}

/// Link type for external link flow (Android)
/// Specifies the type of external link destination
/// Available in Google Play Billing Library 8.2.0+
enum ExternalLinkTypeAndroid {
  /// Unspecified link type. Do not use.
  Unspecified('unspecified'),
  /// The link will direct users to a digital content offer
  LinkToDigitalContentOffer('link-to-digital-content-offer'),
  /// The link will direct users to download an app
  LinkToAppDownload('link-to-app-download');

  const ExternalLinkTypeAndroid(this.value);
  final String value;

  factory ExternalLinkTypeAndroid.fromJson(String value) {
    switch (value) {
      case 'unspecified':
      case 'UNSPECIFIED':
        return ExternalLinkTypeAndroid.Unspecified;
      case 'link-to-digital-content-offer':
      case 'LINK_TO_DIGITAL_CONTENT_OFFER':
        return ExternalLinkTypeAndroid.LinkToDigitalContentOffer;
      case 'link-to-app-download':
      case 'LINK_TO_APP_DOWNLOAD':
        return ExternalLinkTypeAndroid.LinkToAppDownload;
    }
    throw ArgumentError('Unknown ExternalLinkTypeAndroid value: $value');
  }

  String toJson() => value;
}

/// User actions on external purchase notice sheet (iOS 18.2+)
enum ExternalPurchaseNoticeAction {
  /// User chose to continue to external purchase
  Continue('continue'),
  /// User dismissed the notice sheet
  Dismissed('dismissed');

  const ExternalPurchaseNoticeAction(this.value);
  final String value;

  factory ExternalPurchaseNoticeAction.fromJson(String value) {
    switch (value) {
      case 'continue':
      case 'CONTINUE':
      case 'Continue':
        return ExternalPurchaseNoticeAction.Continue;
      case 'dismissed':
      case 'DISMISSED':
      case 'Dismissed':
        return ExternalPurchaseNoticeAction.Dismissed;
    }
    throw ArgumentError('Unknown ExternalPurchaseNoticeAction value: $value');
  }

  String toJson() => value;
}

enum IapEvent {
  PurchaseUpdated('purchase-updated'),
  PurchaseError('purchase-error'),
  PromotedProductIOS('promoted-product-ios'),
  UserChoiceBillingAndroid('user-choice-billing-android'),
  /// Fired when user selects developer-provided billing option in external payments flow.
  /// Available on Android with Google Play Billing Library 8.3.0+
  DeveloperProvidedBillingAndroid('developer-provided-billing-android');

  const IapEvent(this.value);
  final String value;

  factory IapEvent.fromJson(String value) {
    switch (value) {
      case 'purchase-updated':
      case 'PURCHASE_UPDATED':
      case 'PurchaseUpdated':
        return IapEvent.PurchaseUpdated;
      case 'purchase-error':
      case 'PURCHASE_ERROR':
      case 'PurchaseError':
        return IapEvent.PurchaseError;
      case 'promoted-product-ios':
      case 'PROMOTED_PRODUCT_IOS':
      case 'PromotedProductIOS':
        return IapEvent.PromotedProductIOS;
      case 'user-choice-billing-android':
      case 'USER_CHOICE_BILLING_ANDROID':
      case 'UserChoiceBillingAndroid':
        return IapEvent.UserChoiceBillingAndroid;
      case 'developer-provided-billing-android':
      case 'DEVELOPER_PROVIDED_BILLING_ANDROID':
      case 'DeveloperProvidedBillingAndroid':
        return IapEvent.DeveloperProvidedBillingAndroid;
    }
    throw ArgumentError('Unknown IapEvent value: $value');
  }

  String toJson() => value;
}

/// Unified purchase states from IAPKit verification response.
enum IapkitPurchaseState {
  /// User is entitled to the product (purchase is complete and active).
  Entitled('entitled'),
  /// Receipt is valid but still needs server acknowledgment.
  PendingAcknowledgment('pending-acknowledgment'),
  /// Purchase is in progress or awaiting confirmation.
  Pending('pending'),
  /// Purchase was cancelled or refunded.
  Canceled('canceled'),
  /// Subscription or entitlement has expired.
  Expired('expired'),
  /// Consumable purchase is ready to be fulfilled.
  ReadyToConsume('ready-to-consume'),
  /// Consumable item has been fulfilled/consumed.
  Consumed('consumed'),
  /// Purchase state could not be determined.
  Unknown('unknown'),
  /// Purchase receipt is not authentic (fraudulent or tampered).
  Inauthentic('inauthentic');

  const IapkitPurchaseState(this.value);
  final String value;

  factory IapkitPurchaseState.fromJson(String value) {
    switch (value) {
      case 'entitled':
      case 'ENTITLED':
        return IapkitPurchaseState.Entitled;
      case 'pending-acknowledgment':
      case 'PENDING_ACKNOWLEDGMENT':
        return IapkitPurchaseState.PendingAcknowledgment;
      case 'pending':
      case 'PENDING':
        return IapkitPurchaseState.Pending;
      case 'canceled':
      case 'CANCELED':
        return IapkitPurchaseState.Canceled;
      case 'expired':
      case 'EXPIRED':
        return IapkitPurchaseState.Expired;
      case 'ready-to-consume':
      case 'READY_TO_CONSUME':
        return IapkitPurchaseState.ReadyToConsume;
      case 'consumed':
      case 'CONSUMED':
        return IapkitPurchaseState.Consumed;
      case 'unknown':
      case 'UNKNOWN':
        return IapkitPurchaseState.Unknown;
      case 'inauthentic':
      case 'INAUTHENTIC':
        return IapkitPurchaseState.Inauthentic;
    }
    throw ArgumentError('Unknown IapkitPurchaseState value: $value');
  }

  String toJson() => value;
}

enum IapPlatform {
  IOS('ios'),
  Android('android');

  const IapPlatform(this.value);
  final String value;

  factory IapPlatform.fromJson(String value) {
    switch (value) {
      case 'ios':
      case 'IOS':
        return IapPlatform.IOS;
      case 'android':
      case 'ANDROID':
      case 'Android':
        return IapPlatform.Android;
    }
    throw ArgumentError('Unknown IapPlatform value: $value');
  }

  String toJson() => value;
}

enum IapStore {
  Unknown('unknown'),
  Apple('apple'),
  Google('google'),
  Horizon('horizon');

  const IapStore(this.value);
  final String value;

  factory IapStore.fromJson(String value) {
    switch (value) {
      case 'unknown':
      case 'UNKNOWN':
      case 'Unknown':
        return IapStore.Unknown;
      case 'apple':
      case 'APPLE':
      case 'Apple':
        return IapStore.Apple;
      case 'google':
      case 'GOOGLE':
      case 'Google':
        return IapStore.Google;
      case 'horizon':
      case 'HORIZON':
      case 'Horizon':
        return IapStore.Horizon;
    }
    throw ArgumentError('Unknown IapStore value: $value');
  }

  String toJson() => value;
}

enum PaymentModeIOS {
  Empty('empty'),
  FreeTrial('free-trial'),
  PayAsYouGo('pay-as-you-go'),
  PayUpFront('pay-up-front');

  const PaymentModeIOS(this.value);
  final String value;

  factory PaymentModeIOS.fromJson(String value) {
    switch (value) {
      case 'empty':
      case 'EMPTY':
      case 'Empty':
        return PaymentModeIOS.Empty;
      case 'free-trial':
      case 'FREE_TRIAL':
      case 'FreeTrial':
        return PaymentModeIOS.FreeTrial;
      case 'pay-as-you-go':
      case 'PAY_AS_YOU_GO':
      case 'PayAsYouGo':
        return PaymentModeIOS.PayAsYouGo;
      case 'pay-up-front':
      case 'PAY_UP_FRONT':
      case 'PayUpFront':
        return PaymentModeIOS.PayUpFront;
    }
    throw ArgumentError('Unknown PaymentModeIOS value: $value');
  }

  String toJson() => value;
}

enum ProductQueryType {
  InApp('in-app'),
  Subs('subs'),
  All('all');

  const ProductQueryType(this.value);
  final String value;

  factory ProductQueryType.fromJson(String value) {
    switch (value) {
      case 'in-app':
      case 'IN_APP':
      case 'InApp':
        return ProductQueryType.InApp;
      case 'subs':
      case 'SUBS':
      case 'Subs':
        return ProductQueryType.Subs;
      case 'all':
      case 'ALL':
      case 'All':
        return ProductQueryType.All;
    }
    throw ArgumentError('Unknown ProductQueryType value: $value');
  }

  String toJson() => value;
}

enum ProductType {
  InApp('in-app'),
  Subs('subs');

  const ProductType(this.value);
  final String value;

  factory ProductType.fromJson(String value) {
    switch (value) {
      case 'in-app':
      case 'IN_APP':
      case 'InApp':
        return ProductType.InApp;
      case 'subs':
      case 'SUBS':
      case 'Subs':
        return ProductType.Subs;
    }
    throw ArgumentError('Unknown ProductType value: $value');
  }

  String toJson() => value;
}

enum ProductTypeIOS {
  Consumable('consumable'),
  NonConsumable('non-consumable'),
  AutoRenewableSubscription('auto-renewable-subscription'),
  NonRenewingSubscription('non-renewing-subscription');

  const ProductTypeIOS(this.value);
  final String value;

  factory ProductTypeIOS.fromJson(String value) {
    switch (value) {
      case 'consumable':
      case 'CONSUMABLE':
      case 'Consumable':
        return ProductTypeIOS.Consumable;
      case 'non-consumable':
      case 'NON_CONSUMABLE':
      case 'NonConsumable':
        return ProductTypeIOS.NonConsumable;
      case 'auto-renewable-subscription':
      case 'AUTO_RENEWABLE_SUBSCRIPTION':
      case 'AutoRenewableSubscription':
        return ProductTypeIOS.AutoRenewableSubscription;
      case 'non-renewing-subscription':
      case 'NON_RENEWING_SUBSCRIPTION':
      case 'NonRenewingSubscription':
        return ProductTypeIOS.NonRenewingSubscription;
    }
    throw ArgumentError('Unknown ProductTypeIOS value: $value');
  }

  String toJson() => value;
}

enum PurchaseState {
  Pending('pending'),
  Purchased('purchased'),
  Unknown('unknown');

  const PurchaseState(this.value);
  final String value;

  factory PurchaseState.fromJson(String value) {
    switch (value) {
      case 'pending':
      case 'PENDING':
      case 'Pending':
        return PurchaseState.Pending;
      case 'purchased':
      case 'PURCHASED':
      case 'Purchased':
        return PurchaseState.Purchased;
      case 'unknown':
      case 'UNKNOWN':
      case 'Unknown':
        return PurchaseState.Unknown;
    }
    throw ArgumentError('Unknown PurchaseState value: $value');
  }

  String toJson() => value;
}

enum PurchaseVerificationProvider {
  Iapkit('iapkit');

  const PurchaseVerificationProvider(this.value);
  final String value;

  factory PurchaseVerificationProvider.fromJson(String value) {
    switch (value) {
      case 'iapkit':
      case 'IAPKIT':
      case 'Iapkit':
        return PurchaseVerificationProvider.Iapkit;
    }
    throw ArgumentError('Unknown PurchaseVerificationProvider value: $value');
  }

  String toJson() => value;
}

enum SubscriptionOfferTypeIOS {
  Introductory('introductory'),
  Promotional('promotional');

  const SubscriptionOfferTypeIOS(this.value);
  final String value;

  factory SubscriptionOfferTypeIOS.fromJson(String value) {
    switch (value) {
      case 'introductory':
      case 'INTRODUCTORY':
      case 'Introductory':
        return SubscriptionOfferTypeIOS.Introductory;
      case 'promotional':
      case 'PROMOTIONAL':
      case 'Promotional':
        return SubscriptionOfferTypeIOS.Promotional;
    }
    throw ArgumentError('Unknown SubscriptionOfferTypeIOS value: $value');
  }

  String toJson() => value;
}

enum SubscriptionPeriodIOS {
  Day('day'),
  Week('week'),
  Month('month'),
  Year('year'),
  Empty('empty');

  const SubscriptionPeriodIOS(this.value);
  final String value;

  factory SubscriptionPeriodIOS.fromJson(String value) {
    switch (value) {
      case 'day':
      case 'DAY':
      case 'Day':
        return SubscriptionPeriodIOS.Day;
      case 'week':
      case 'WEEK':
      case 'Week':
        return SubscriptionPeriodIOS.Week;
      case 'month':
      case 'MONTH':
      case 'Month':
        return SubscriptionPeriodIOS.Month;
      case 'year':
      case 'YEAR':
      case 'Year':
        return SubscriptionPeriodIOS.Year;
      case 'empty':
      case 'EMPTY':
      case 'Empty':
        return SubscriptionPeriodIOS.Empty;
    }
    throw ArgumentError('Unknown SubscriptionPeriodIOS value: $value');
  }

  String toJson() => value;
}

/// Replacement mode for subscription changes (Android)
/// These modes determine how the subscription replacement affects billing.
/// Available in Google Play Billing Library 8.1.0+
enum SubscriptionReplacementModeAndroid {
  /// Unknown replacement mode. Do not use.
  UnknownReplacementMode('unknown-replacement-mode'),
  /// Replacement takes effect immediately, and the new expiration time will be prorated.
  WithTimeProration('with-time-proration'),
  /// Replacement takes effect immediately, and the billing cycle remains the same.
  ChargeProratedPrice('charge-prorated-price'),
  /// Replacement takes effect immediately, and the user is charged full price immediately.
  ChargeFullPrice('charge-full-price'),
  /// Replacement takes effect when the old plan expires.
  WithoutProration('without-proration'),
  /// Replacement takes effect when the old plan expires, and the user is not charged.
  Deferred('deferred'),
  /// Keep the existing payment schedule unchanged for the item (8.1.0+)
  KeepExisting('keep-existing');

  const SubscriptionReplacementModeAndroid(this.value);
  final String value;

  factory SubscriptionReplacementModeAndroid.fromJson(String value) {
    switch (value) {
      case 'unknown-replacement-mode':
      case 'UNKNOWN_REPLACEMENT_MODE':
        return SubscriptionReplacementModeAndroid.UnknownReplacementMode;
      case 'with-time-proration':
      case 'WITH_TIME_PRORATION':
        return SubscriptionReplacementModeAndroid.WithTimeProration;
      case 'charge-prorated-price':
      case 'CHARGE_PRORATED_PRICE':
        return SubscriptionReplacementModeAndroid.ChargeProratedPrice;
      case 'charge-full-price':
      case 'CHARGE_FULL_PRICE':
        return SubscriptionReplacementModeAndroid.ChargeFullPrice;
      case 'without-proration':
      case 'WITHOUT_PRORATION':
        return SubscriptionReplacementModeAndroid.WithoutProration;
      case 'deferred':
      case 'DEFERRED':
        return SubscriptionReplacementModeAndroid.Deferred;
      case 'keep-existing':
      case 'KEEP_EXISTING':
        return SubscriptionReplacementModeAndroid.KeepExisting;
    }
    throw ArgumentError('Unknown SubscriptionReplacementModeAndroid value: $value');
  }

  String toJson() => value;
}

// MARK: - Interfaces

abstract class ProductCommon {
  String get currency;
  String? get debugDescription;
  String get description;
  String? get displayName;
  String get displayPrice;
  String get id;
  IapPlatform get platform;
  double? get price;
  String get title;
  ProductType get type;
}

abstract class PurchaseCommon {
  /// The current plan identifier. This is:
  /// - On Android: the basePlanId (e.g., "premium", "premium-year")
  /// - On iOS: the productId (e.g., "com.example.premium_monthly", "com.example.premium_yearly")
  /// This provides a unified way to identify which specific plan/tier the user is subscribed to.
  String? get currentPlanId;
  String get id;
  List<String>? get ids;
  bool get isAutoRenewing;
  IapPlatform get platform;
  String get productId;
  PurchaseState get purchaseState;
  /// Unified purchase token (iOS JWS, Android purchaseToken)
  String? get purchaseToken;
  int get quantity;
  /// Store where purchase was made
  IapStore get store;
  double get transactionDate;
}

// MARK: - Objects

class ActiveSubscription {
  const ActiveSubscription({
    this.autoRenewingAndroid,
    this.basePlanIdAndroid,
    this.currentPlanId,
    this.daysUntilExpirationIOS,
    this.environmentIOS,
    this.expirationDateIOS,
    required this.isActive,
    required this.productId,
    this.purchaseToken,
    this.purchaseTokenAndroid,
    this.renewalInfoIOS,
    required this.transactionDate,
    required this.transactionId,
    this.willExpireSoon,
  });

  final bool? autoRenewingAndroid;
  final String? basePlanIdAndroid;
  /// The current plan identifier. This is:
  /// - On Android: the basePlanId (e.g., "premium", "premium-year")
  /// - On iOS: the productId (e.g., "com.example.premium_monthly", "com.example.premium_yearly")
  /// This provides a unified way to identify which specific plan/tier the user is subscribed to.
  final String? currentPlanId;
  final double? daysUntilExpirationIOS;
  final String? environmentIOS;
  final double? expirationDateIOS;
  final bool isActive;
  final String productId;
  final String? purchaseToken;
  /// Required for subscription upgrade/downgrade on Android
  final String? purchaseTokenAndroid;
  /// Renewal information from StoreKit 2 (iOS only). Contains details about subscription renewal status,
  /// pending upgrades/downgrades, and auto-renewal preferences.
  final RenewalInfoIOS? renewalInfoIOS;
  final double transactionDate;
  final String transactionId;
  /// @deprecated iOS only - use daysUntilExpirationIOS instead.
  /// Whether the subscription will expire soon (within 7 days).
  /// Consider using daysUntilExpirationIOS for more precise control.
  final bool? willExpireSoon;

  factory ActiveSubscription.fromJson(Map<String, dynamic> json) {
    return ActiveSubscription(
      autoRenewingAndroid: json['autoRenewingAndroid'] as bool?,
      basePlanIdAndroid: json['basePlanIdAndroid'] as String?,
      currentPlanId: json['currentPlanId'] as String?,
      daysUntilExpirationIOS: (json['daysUntilExpirationIOS'] as num?)?.toDouble(),
      environmentIOS: json['environmentIOS'] as String?,
      expirationDateIOS: (json['expirationDateIOS'] as num?)?.toDouble(),
      isActive: json['isActive'] as bool,
      productId: json['productId'] as String,
      purchaseToken: json['purchaseToken'] as String?,
      purchaseTokenAndroid: json['purchaseTokenAndroid'] as String?,
      renewalInfoIOS: json['renewalInfoIOS'] != null ? RenewalInfoIOS.fromJson(json['renewalInfoIOS'] as Map<String, dynamic>) : null,
      transactionDate: (json['transactionDate'] as num).toDouble(),
      transactionId: json['transactionId'] as String,
      willExpireSoon: json['willExpireSoon'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '__typename': 'ActiveSubscription',
      'autoRenewingAndroid': autoRenewingAndroid,
      'basePlanIdAndroid': basePlanIdAndroid,
      'currentPlanId': currentPlanId,
      'daysUntilExpirationIOS': daysUntilExpirationIOS,
      'environmentIOS': environmentIOS,
      'expirationDateIOS': expirationDateIOS,
      'isActive': isActive,
      'productId': productId,
      'purchaseToken': purchaseToken,
      'purchaseTokenAndroid': purchaseTokenAndroid,
      'renewalInfoIOS': renewalInfoIOS?.toJson(),
      'transactionDate': transactionDate,
      'transactionId': transactionId,
      'willExpireSoon': willExpireSoon,
    };
  }
}

class AppTransaction {
  const AppTransaction({
    required this.appId,
    this.appTransactionId,
    required this.appVersion,
    required this.appVersionId,
    required this.bundleId,
    required this.deviceVerification,
    required this.deviceVerificationNonce,
    required this.environment,
    required this.originalAppVersion,
    this.originalPlatform,
    required this.originalPurchaseDate,
    this.preorderDate,
    required this.signedDate,
  });

  final double appId;
  final String? appTransactionId;
  final String appVersion;
  final double appVersionId;
  final String bundleId;
  final String deviceVerification;
  final String deviceVerificationNonce;
  final String environment;
  final String originalAppVersion;
  final String? originalPlatform;
  final double originalPurchaseDate;
  final double? preorderDate;
  final double signedDate;

  factory AppTransaction.fromJson(Map<String, dynamic> json) {
    return AppTransaction(
      appId: (json['appId'] as num).toDouble(),
      appTransactionId: json['appTransactionId'] as String?,
      appVersion: json['appVersion'] as String,
      appVersionId: (json['appVersionId'] as num).toDouble(),
      bundleId: json['bundleId'] as String,
      deviceVerification: json['deviceVerification'] as String,
      deviceVerificationNonce: json['deviceVerificationNonce'] as String,
      environment: json['environment'] as String,
      originalAppVersion: json['originalAppVersion'] as String,
      originalPlatform: json['originalPlatform'] as String?,
      originalPurchaseDate: (json['originalPurchaseDate'] as num).toDouble(),
      preorderDate: (json['preorderDate'] as num?)?.toDouble(),
      signedDate: (json['signedDate'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '__typename': 'AppTransaction',
      'appId': appId,
      'appTransactionId': appTransactionId,
      'appVersion': appVersion,
      'appVersionId': appVersionId,
      'bundleId': bundleId,
      'deviceVerification': deviceVerification,
      'deviceVerificationNonce': deviceVerificationNonce,
      'environment': environment,
      'originalAppVersion': originalAppVersion,
      'originalPlatform': originalPlatform,
      'originalPurchaseDate': originalPurchaseDate,
      'preorderDate': preorderDate,
      'signedDate': signedDate,
    };
  }
}

/// Result of checking billing program availability (Android)
/// Available in Google Play Billing Library 8.2.0+
class BillingProgramAvailabilityResultAndroid {
  const BillingProgramAvailabilityResultAndroid({
    required this.billingProgram,
    required this.isAvailable,
  });

  /// The billing program that was checked
  final BillingProgramAndroid billingProgram;
  /// Whether the billing program is available for the user
  final bool isAvailable;

  factory BillingProgramAvailabilityResultAndroid.fromJson(Map<String, dynamic> json) {
    return BillingProgramAvailabilityResultAndroid(
      billingProgram: BillingProgramAndroid.fromJson(json['billingProgram'] as String),
      isAvailable: json['isAvailable'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '__typename': 'BillingProgramAvailabilityResultAndroid',
      'billingProgram': billingProgram.toJson(),
      'isAvailable': isAvailable,
    };
  }
}

/// Reporting details for transactions made outside of Google Play Billing (Android)
/// Contains the external transaction token needed for reporting
/// Available in Google Play Billing Library 8.2.0+
class BillingProgramReportingDetailsAndroid {
  const BillingProgramReportingDetailsAndroid({
    required this.billingProgram,
    required this.externalTransactionToken,
  });

  /// The billing program that the reporting details are associated with
  final BillingProgramAndroid billingProgram;
  /// External transaction token used to report transactions made outside of Google Play Billing.
  /// This token must be used when reporting the external transaction to Google.
  final String externalTransactionToken;

  factory BillingProgramReportingDetailsAndroid.fromJson(Map<String, dynamic> json) {
    return BillingProgramReportingDetailsAndroid(
      billingProgram: BillingProgramAndroid.fromJson(json['billingProgram'] as String),
      externalTransactionToken: json['externalTransactionToken'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '__typename': 'BillingProgramReportingDetailsAndroid',
      'billingProgram': billingProgram.toJson(),
      'externalTransactionToken': externalTransactionToken,
    };
  }
}

/// Details provided when user selects developer billing option (Android)
/// Received via DeveloperProvidedBillingListener callback
/// Available in Google Play Billing Library 8.3.0+
class DeveloperProvidedBillingDetailsAndroid {
  const DeveloperProvidedBillingDetailsAndroid({
    required this.externalTransactionToken,
  });

  /// External transaction token used to report transactions made through developer billing.
  /// This token must be used when reporting the external transaction to Google Play.
  /// Must be reported within 24 hours of the transaction.
  final String externalTransactionToken;

  factory DeveloperProvidedBillingDetailsAndroid.fromJson(Map<String, dynamic> json) {
    return DeveloperProvidedBillingDetailsAndroid(
      externalTransactionToken: json['externalTransactionToken'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '__typename': 'DeveloperProvidedBillingDetailsAndroid',
      'externalTransactionToken': externalTransactionToken,
    };
  }
}

/// Discount amount details for one-time purchase offers (Android)
/// Available in Google Play Billing Library 7.0+
class DiscountAmountAndroid {
  const DiscountAmountAndroid({
    required this.discountAmountMicros,
    required this.formattedDiscountAmount,
  });

  /// Discount amount in micro-units (1,000,000 = 1 unit of currency)
  final String discountAmountMicros;
  /// Formatted discount amount with currency sign (e.g., "$4.99")
  final String formattedDiscountAmount;

  factory DiscountAmountAndroid.fromJson(Map<String, dynamic> json) {
    return DiscountAmountAndroid(
      discountAmountMicros: json['discountAmountMicros'] as String,
      formattedDiscountAmount: json['formattedDiscountAmount'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '__typename': 'DiscountAmountAndroid',
      'discountAmountMicros': discountAmountMicros,
      'formattedDiscountAmount': formattedDiscountAmount,
    };
  }
}

/// Discount display information for one-time purchase offers (Android)
/// Available in Google Play Billing Library 7.0+
class DiscountDisplayInfoAndroid {
  const DiscountDisplayInfoAndroid({
    this.discountAmount,
    this.percentageDiscount,
  });

  /// Absolute discount amount details
  /// Only returned for fixed amount discounts
  final DiscountAmountAndroid? discountAmount;
  /// Percentage discount (e.g., 33 for 33% off)
  /// Only returned for percentage-based discounts
  final int? percentageDiscount;

  factory DiscountDisplayInfoAndroid.fromJson(Map<String, dynamic> json) {
    return DiscountDisplayInfoAndroid(
      discountAmount: json['discountAmount'] != null ? DiscountAmountAndroid.fromJson(json['discountAmount'] as Map<String, dynamic>) : null,
      percentageDiscount: json['percentageDiscount'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '__typename': 'DiscountDisplayInfoAndroid',
      'discountAmount': discountAmount?.toJson(),
      'percentageDiscount': percentageDiscount,
    };
  }
}

class DiscountIOS {
  const DiscountIOS({
    required this.identifier,
    this.localizedPrice,
    required this.numberOfPeriods,
    required this.paymentMode,
    required this.price,
    required this.priceAmount,
    required this.subscriptionPeriod,
    required this.type,
  });

  final String identifier;
  final String? localizedPrice;
  final int numberOfPeriods;
  final PaymentModeIOS paymentMode;
  final String price;
  final double priceAmount;
  final String subscriptionPeriod;
  final String type;

  factory DiscountIOS.fromJson(Map<String, dynamic> json) {
    return DiscountIOS(
      identifier: json['identifier'] as String,
      localizedPrice: json['localizedPrice'] as String?,
      numberOfPeriods: json['numberOfPeriods'] as int,
      paymentMode: PaymentModeIOS.fromJson(json['paymentMode'] as String),
      price: json['price'] as String,
      priceAmount: (json['priceAmount'] as num).toDouble(),
      subscriptionPeriod: json['subscriptionPeriod'] as String,
      type: json['type'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '__typename': 'DiscountIOS',
      'identifier': identifier,
      'localizedPrice': localizedPrice,
      'numberOfPeriods': numberOfPeriods,
      'paymentMode': paymentMode.toJson(),
      'price': price,
      'priceAmount': priceAmount,
      'subscriptionPeriod': subscriptionPeriod,
      'type': type,
    };
  }
}

class DiscountOfferIOS {
  const DiscountOfferIOS({
    required this.identifier,
    required this.keyIdentifier,
    required this.nonce,
    required this.signature,
    required this.timestamp,
  });

  /// Discount identifier
  final String identifier;
  /// Key identifier for validation
  final String keyIdentifier;
  /// Cryptographic nonce
  final String nonce;
  /// Signature for validation
  final String signature;
  /// Timestamp of discount offer
  final double timestamp;

  factory DiscountOfferIOS.fromJson(Map<String, dynamic> json) {
    return DiscountOfferIOS(
      identifier: json['identifier'] as String,
      keyIdentifier: json['keyIdentifier'] as String,
      nonce: json['nonce'] as String,
      signature: json['signature'] as String,
      timestamp: (json['timestamp'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '__typename': 'DiscountOfferIOS',
      'identifier': identifier,
      'keyIdentifier': keyIdentifier,
      'nonce': nonce,
      'signature': signature,
      'timestamp': timestamp,
    };
  }
}

class EntitlementIOS {
  const EntitlementIOS({
    required this.jsonRepresentation,
    required this.sku,
    required this.transactionId,
  });

  final String jsonRepresentation;
  final String sku;
  final String transactionId;

  factory EntitlementIOS.fromJson(Map<String, dynamic> json) {
    return EntitlementIOS(
      jsonRepresentation: json['jsonRepresentation'] as String,
      sku: json['sku'] as String,
      transactionId: json['transactionId'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '__typename': 'EntitlementIOS',
      'jsonRepresentation': jsonRepresentation,
      'sku': sku,
      'transactionId': transactionId,
    };
  }
}

/// External offer availability result (Android)
/// @deprecated Use BillingProgramAvailabilityResultAndroid with isBillingProgramAvailableAsync instead
/// Available in Google Play Billing Library 6.2.0+, deprecated in 8.2.0
class ExternalOfferAvailabilityResultAndroid {
  const ExternalOfferAvailabilityResultAndroid({
    required this.isAvailable,
  });

  /// Whether external offers are available for the user
  final bool isAvailable;

  factory ExternalOfferAvailabilityResultAndroid.fromJson(Map<String, dynamic> json) {
    return ExternalOfferAvailabilityResultAndroid(
      isAvailable: json['isAvailable'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '__typename': 'ExternalOfferAvailabilityResultAndroid',
      'isAvailable': isAvailable,
    };
  }
}

/// External offer reporting details (Android)
/// @deprecated Use BillingProgramReportingDetailsAndroid with createBillingProgramReportingDetailsAsync instead
/// Available in Google Play Billing Library 6.2.0+, deprecated in 8.2.0
class ExternalOfferReportingDetailsAndroid {
  const ExternalOfferReportingDetailsAndroid({
    required this.externalTransactionToken,
  });

  /// External transaction token for reporting external offer transactions
  final String externalTransactionToken;

  factory ExternalOfferReportingDetailsAndroid.fromJson(Map<String, dynamic> json) {
    return ExternalOfferReportingDetailsAndroid(
      externalTransactionToken: json['externalTransactionToken'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '__typename': 'ExternalOfferReportingDetailsAndroid',
      'externalTransactionToken': externalTransactionToken,
    };
  }
}

/// Result of presenting an external purchase link (iOS 18.2+)
class ExternalPurchaseLinkResultIOS {
  const ExternalPurchaseLinkResultIOS({
    this.error,
    required this.success,
  });

  /// Optional error message if the presentation failed
  final String? error;
  /// Whether the user completed the external purchase flow
  final bool success;

  factory ExternalPurchaseLinkResultIOS.fromJson(Map<String, dynamic> json) {
    return ExternalPurchaseLinkResultIOS(
      error: json['error'] as String?,
      success: json['success'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '__typename': 'ExternalPurchaseLinkResultIOS',
      'error': error,
      'success': success,
    };
  }
}

/// Result of presenting external purchase notice sheet (iOS 18.2+)
class ExternalPurchaseNoticeResultIOS {
  const ExternalPurchaseNoticeResultIOS({
    this.error,
    required this.result,
  });

  /// Optional error message if the presentation failed
  final String? error;
  /// Notice result indicating user action
  final ExternalPurchaseNoticeAction result;

  factory ExternalPurchaseNoticeResultIOS.fromJson(Map<String, dynamic> json) {
    return ExternalPurchaseNoticeResultIOS(
      error: json['error'] as String?,
      result: ExternalPurchaseNoticeAction.fromJson(json['result'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '__typename': 'ExternalPurchaseNoticeResultIOS',
      'error': error,
      'result': result.toJson(),
    };
  }
}

abstract class FetchProductsResult {
  const FetchProductsResult();
}

class FetchProductsResultAll extends FetchProductsResult {
  const FetchProductsResultAll(this.value);
  final List<ProductOrSubscription>? value;
}

class FetchProductsResultProducts extends FetchProductsResult {
  const FetchProductsResultProducts(this.value);
  final List<Product>? value;
}

class FetchProductsResultSubscriptions extends FetchProductsResult {
  const FetchProductsResultSubscriptions(this.value);
  final List<ProductSubscription>? value;
}

/// Limited quantity information for one-time purchase offers (Android)
/// Available in Google Play Billing Library 7.0+
class LimitedQuantityInfoAndroid {
  const LimitedQuantityInfoAndroid({
    required this.maximumQuantity,
    required this.remainingQuantity,
  });

  /// Maximum quantity a user can purchase
  final int maximumQuantity;
  /// Remaining quantity the user can still purchase
  final int remainingQuantity;

  factory LimitedQuantityInfoAndroid.fromJson(Map<String, dynamic> json) {
    return LimitedQuantityInfoAndroid(
      maximumQuantity: json['maximumQuantity'] as int,
      remainingQuantity: json['remainingQuantity'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '__typename': 'LimitedQuantityInfoAndroid',
      'maximumQuantity': maximumQuantity,
      'remainingQuantity': remainingQuantity,
    };
  }
}

/// Pre-order details for one-time purchase products (Android)
/// Available in Google Play Billing Library 8.1.0+
class PreorderDetailsAndroid {
  const PreorderDetailsAndroid({
    required this.preorderPresaleEndTimeMillis,
    required this.preorderReleaseTimeMillis,
  });

  /// Pre-order presale end time in milliseconds since epoch.
  /// This is when the presale period ends and the product will be released.
  final String preorderPresaleEndTimeMillis;
  /// Pre-order release time in milliseconds since epoch.
  /// This is when the product will be available to users who pre-ordered.
  final String preorderReleaseTimeMillis;

  factory PreorderDetailsAndroid.fromJson(Map<String, dynamic> json) {
    return PreorderDetailsAndroid(
      preorderPresaleEndTimeMillis: json['preorderPresaleEndTimeMillis'] as String,
      preorderReleaseTimeMillis: json['preorderReleaseTimeMillis'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '__typename': 'PreorderDetailsAndroid',
      'preorderPresaleEndTimeMillis': preorderPresaleEndTimeMillis,
      'preorderReleaseTimeMillis': preorderReleaseTimeMillis,
    };
  }
}

class PricingPhaseAndroid {
  const PricingPhaseAndroid({
    required this.billingCycleCount,
    required this.billingPeriod,
    required this.formattedPrice,
    required this.priceAmountMicros,
    required this.priceCurrencyCode,
    required this.recurrenceMode,
  });

  final int billingCycleCount;
  final String billingPeriod;
  final String formattedPrice;
  final String priceAmountMicros;
  final String priceCurrencyCode;
  final int recurrenceMode;

  factory PricingPhaseAndroid.fromJson(Map<String, dynamic> json) {
    return PricingPhaseAndroid(
      billingCycleCount: json['billingCycleCount'] as int,
      billingPeriod: json['billingPeriod'] as String,
      formattedPrice: json['formattedPrice'] as String,
      priceAmountMicros: json['priceAmountMicros'] as String,
      priceCurrencyCode: json['priceCurrencyCode'] as String,
      recurrenceMode: json['recurrenceMode'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '__typename': 'PricingPhaseAndroid',
      'billingCycleCount': billingCycleCount,
      'billingPeriod': billingPeriod,
      'formattedPrice': formattedPrice,
      'priceAmountMicros': priceAmountMicros,
      'priceCurrencyCode': priceCurrencyCode,
      'recurrenceMode': recurrenceMode,
    };
  }
}

class PricingPhasesAndroid {
  const PricingPhasesAndroid({
    required this.pricingPhaseList,
  });

  final List<PricingPhaseAndroid> pricingPhaseList;

  factory PricingPhasesAndroid.fromJson(Map<String, dynamic> json) {
    return PricingPhasesAndroid(
      pricingPhaseList: (json['pricingPhaseList'] as List<dynamic>).map((e) => PricingPhaseAndroid.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '__typename': 'PricingPhasesAndroid',
      'pricingPhaseList': pricingPhaseList.map((e) => e.toJson()).toList(),
    };
  }
}

class ProductAndroid extends Product implements ProductCommon {
  const ProductAndroid({
    required this.currency,
    this.debugDescription,
    required this.description,
    this.displayName,
    required this.displayPrice,
    required this.id,
    required this.nameAndroid,
    this.oneTimePurchaseOfferDetailsAndroid,
    this.platform = IapPlatform.Android,
    this.price,
    this.subscriptionOfferDetailsAndroid,
    required this.title,
    this.type = ProductType.InApp,
  });

  final String currency;
  final String? debugDescription;
  final String description;
  final String? displayName;
  final String displayPrice;
  final String id;
  final String nameAndroid;
  /// One-time purchase offer details including discounts (Android)
  /// Returns all eligible offers. Available in Google Play Billing Library 7.0+
  final List<ProductAndroidOneTimePurchaseOfferDetail>? oneTimePurchaseOfferDetailsAndroid;
  final IapPlatform platform;
  final double? price;
  final List<ProductSubscriptionAndroidOfferDetails>? subscriptionOfferDetailsAndroid;
  final String title;
  final ProductType type;

  factory ProductAndroid.fromJson(Map<String, dynamic> json) {
    return ProductAndroid(
      currency: json['currency'] as String,
      debugDescription: json['debugDescription'] as String?,
      description: json['description'] as String,
      displayName: json['displayName'] as String?,
      displayPrice: json['displayPrice'] as String,
      id: json['id'] as String,
      nameAndroid: json['nameAndroid'] as String,
      oneTimePurchaseOfferDetailsAndroid: (json['oneTimePurchaseOfferDetailsAndroid'] as List<dynamic>?) == null ? null : (json['oneTimePurchaseOfferDetailsAndroid'] as List<dynamic>?)!.map((e) => ProductAndroidOneTimePurchaseOfferDetail.fromJson(e as Map<String, dynamic>)).toList(),
      platform: IapPlatform.fromJson(json['platform'] as String),
      price: (json['price'] as num?)?.toDouble(),
      subscriptionOfferDetailsAndroid: (json['subscriptionOfferDetailsAndroid'] as List<dynamic>?) == null ? null : (json['subscriptionOfferDetailsAndroid'] as List<dynamic>?)!.map((e) => ProductSubscriptionAndroidOfferDetails.fromJson(e as Map<String, dynamic>)).toList(),
      title: json['title'] as String,
      type: ProductType.fromJson(json['type'] as String),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      '__typename': 'ProductAndroid',
      'currency': currency,
      'debugDescription': debugDescription,
      'description': description,
      'displayName': displayName,
      'displayPrice': displayPrice,
      'id': id,
      'nameAndroid': nameAndroid,
      'oneTimePurchaseOfferDetailsAndroid': oneTimePurchaseOfferDetailsAndroid == null ? null : oneTimePurchaseOfferDetailsAndroid!.map((e) => e.toJson()).toList(),
      'platform': platform.toJson(),
      'price': price,
      'subscriptionOfferDetailsAndroid': subscriptionOfferDetailsAndroid == null ? null : subscriptionOfferDetailsAndroid!.map((e) => e.toJson()).toList(),
      'title': title,
      'type': type.toJson(),
    };
  }
}

/// One-time purchase offer details (Android)
/// Available in Google Play Billing Library 7.0+
class ProductAndroidOneTimePurchaseOfferDetail {
  const ProductAndroidOneTimePurchaseOfferDetail({
    this.discountDisplayInfo,
    required this.formattedPrice,
    this.fullPriceMicros,
    this.limitedQuantityInfo,
    this.offerId,
    required this.offerTags,
    required this.offerToken,
    this.preorderDetailsAndroid,
    required this.priceAmountMicros,
    required this.priceCurrencyCode,
    this.rentalDetailsAndroid,
    this.validTimeWindow,
  });

  /// Discount display information
  /// Only available for discounted offers
  final DiscountDisplayInfoAndroid? discountDisplayInfo;
  final String formattedPrice;
  /// Full (non-discounted) price in micro-units
  /// Only available for discounted offers
  final String? fullPriceMicros;
  /// Limited quantity information
  final LimitedQuantityInfoAndroid? limitedQuantityInfo;
  /// Offer ID
  final String? offerId;
  /// List of offer tags
  final List<String> offerTags;
  /// Offer token for use in BillingFlowParams when purchasing
  final String offerToken;
  /// Pre-order details for products available for pre-order
  /// Available in Google Play Billing Library 8.1.0+
  final PreorderDetailsAndroid? preorderDetailsAndroid;
  final String priceAmountMicros;
  final String priceCurrencyCode;
  /// Rental details for rental offers
  final RentalDetailsAndroid? rentalDetailsAndroid;
  /// Valid time window for the offer
  final ValidTimeWindowAndroid? validTimeWindow;

  factory ProductAndroidOneTimePurchaseOfferDetail.fromJson(Map<String, dynamic> json) {
    return ProductAndroidOneTimePurchaseOfferDetail(
      discountDisplayInfo: json['discountDisplayInfo'] != null ? DiscountDisplayInfoAndroid.fromJson(json['discountDisplayInfo'] as Map<String, dynamic>) : null,
      formattedPrice: json['formattedPrice'] as String,
      fullPriceMicros: json['fullPriceMicros'] as String?,
      limitedQuantityInfo: json['limitedQuantityInfo'] != null ? LimitedQuantityInfoAndroid.fromJson(json['limitedQuantityInfo'] as Map<String, dynamic>) : null,
      offerId: json['offerId'] as String?,
      offerTags: (json['offerTags'] as List<dynamic>).map((e) => e as String).toList(),
      offerToken: json['offerToken'] as String,
      preorderDetailsAndroid: json['preorderDetailsAndroid'] != null ? PreorderDetailsAndroid.fromJson(json['preorderDetailsAndroid'] as Map<String, dynamic>) : null,
      priceAmountMicros: json['priceAmountMicros'] as String,
      priceCurrencyCode: json['priceCurrencyCode'] as String,
      rentalDetailsAndroid: json['rentalDetailsAndroid'] != null ? RentalDetailsAndroid.fromJson(json['rentalDetailsAndroid'] as Map<String, dynamic>) : null,
      validTimeWindow: json['validTimeWindow'] != null ? ValidTimeWindowAndroid.fromJson(json['validTimeWindow'] as Map<String, dynamic>) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '__typename': 'ProductAndroidOneTimePurchaseOfferDetail',
      'discountDisplayInfo': discountDisplayInfo?.toJson(),
      'formattedPrice': formattedPrice,
      'fullPriceMicros': fullPriceMicros,
      'limitedQuantityInfo': limitedQuantityInfo?.toJson(),
      'offerId': offerId,
      'offerTags': offerTags.map((e) => e).toList(),
      'offerToken': offerToken,
      'preorderDetailsAndroid': preorderDetailsAndroid?.toJson(),
      'priceAmountMicros': priceAmountMicros,
      'priceCurrencyCode': priceCurrencyCode,
      'rentalDetailsAndroid': rentalDetailsAndroid?.toJson(),
      'validTimeWindow': validTimeWindow?.toJson(),
    };
  }
}

class ProductIOS extends Product implements ProductCommon {
  const ProductIOS({
    required this.currency,
    this.debugDescription,
    required this.description,
    this.displayName,
    required this.displayNameIOS,
    required this.displayPrice,
    required this.id,
    required this.isFamilyShareableIOS,
    required this.jsonRepresentationIOS,
    this.platform = IapPlatform.IOS,
    this.price,
    this.subscriptionInfoIOS,
    required this.title,
    this.type = ProductType.InApp,
    required this.typeIOS,
  });

  final String currency;
  final String? debugDescription;
  final String description;
  final String? displayName;
  final String displayNameIOS;
  final String displayPrice;
  final String id;
  final bool isFamilyShareableIOS;
  final String jsonRepresentationIOS;
  final IapPlatform platform;
  final double? price;
  final SubscriptionInfoIOS? subscriptionInfoIOS;
  final String title;
  final ProductType type;
  final ProductTypeIOS typeIOS;

  factory ProductIOS.fromJson(Map<String, dynamic> json) {
    return ProductIOS(
      currency: json['currency'] as String,
      debugDescription: json['debugDescription'] as String?,
      description: json['description'] as String,
      displayName: json['displayName'] as String?,
      displayNameIOS: json['displayNameIOS'] as String,
      displayPrice: json['displayPrice'] as String,
      id: json['id'] as String,
      isFamilyShareableIOS: json['isFamilyShareableIOS'] as bool,
      jsonRepresentationIOS: json['jsonRepresentationIOS'] as String,
      platform: IapPlatform.fromJson(json['platform'] as String),
      price: (json['price'] as num?)?.toDouble(),
      subscriptionInfoIOS: json['subscriptionInfoIOS'] != null ? SubscriptionInfoIOS.fromJson(json['subscriptionInfoIOS'] as Map<String, dynamic>) : null,
      title: json['title'] as String,
      type: ProductType.fromJson(json['type'] as String),
      typeIOS: ProductTypeIOS.fromJson(json['typeIOS'] as String),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      '__typename': 'ProductIOS',
      'currency': currency,
      'debugDescription': debugDescription,
      'description': description,
      'displayName': displayName,
      'displayNameIOS': displayNameIOS,
      'displayPrice': displayPrice,
      'id': id,
      'isFamilyShareableIOS': isFamilyShareableIOS,
      'jsonRepresentationIOS': jsonRepresentationIOS,
      'platform': platform.toJson(),
      'price': price,
      'subscriptionInfoIOS': subscriptionInfoIOS?.toJson(),
      'title': title,
      'type': type.toJson(),
      'typeIOS': typeIOS.toJson(),
    };
  }
}

class ProductSubscriptionAndroid extends ProductSubscription implements ProductCommon {
  const ProductSubscriptionAndroid({
    required this.currency,
    this.debugDescription,
    required this.description,
    this.displayName,
    required this.displayPrice,
    required this.id,
    required this.nameAndroid,
    this.oneTimePurchaseOfferDetailsAndroid,
    this.platform = IapPlatform.Android,
    this.price,
    required this.subscriptionOfferDetailsAndroid,
    required this.title,
    this.type = ProductType.Subs,
  });

  final String currency;
  final String? debugDescription;
  final String description;
  final String? displayName;
  final String displayPrice;
  final String id;
  final String nameAndroid;
  /// One-time purchase offer details including discounts (Android)
  /// Returns all eligible offers. Available in Google Play Billing Library 7.0+
  final List<ProductAndroidOneTimePurchaseOfferDetail>? oneTimePurchaseOfferDetailsAndroid;
  final IapPlatform platform;
  final double? price;
  final List<ProductSubscriptionAndroidOfferDetails> subscriptionOfferDetailsAndroid;
  final String title;
  final ProductType type;

  factory ProductSubscriptionAndroid.fromJson(Map<String, dynamic> json) {
    return ProductSubscriptionAndroid(
      currency: json['currency'] as String,
      debugDescription: json['debugDescription'] as String?,
      description: json['description'] as String,
      displayName: json['displayName'] as String?,
      displayPrice: json['displayPrice'] as String,
      id: json['id'] as String,
      nameAndroid: json['nameAndroid'] as String,
      oneTimePurchaseOfferDetailsAndroid: (json['oneTimePurchaseOfferDetailsAndroid'] as List<dynamic>?) == null ? null : (json['oneTimePurchaseOfferDetailsAndroid'] as List<dynamic>?)!.map((e) => ProductAndroidOneTimePurchaseOfferDetail.fromJson(e as Map<String, dynamic>)).toList(),
      platform: IapPlatform.fromJson(json['platform'] as String),
      price: (json['price'] as num?)?.toDouble(),
      subscriptionOfferDetailsAndroid: (json['subscriptionOfferDetailsAndroid'] as List<dynamic>).map((e) => ProductSubscriptionAndroidOfferDetails.fromJson(e as Map<String, dynamic>)).toList(),
      title: json['title'] as String,
      type: ProductType.fromJson(json['type'] as String),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      '__typename': 'ProductSubscriptionAndroid',
      'currency': currency,
      'debugDescription': debugDescription,
      'description': description,
      'displayName': displayName,
      'displayPrice': displayPrice,
      'id': id,
      'nameAndroid': nameAndroid,
      'oneTimePurchaseOfferDetailsAndroid': oneTimePurchaseOfferDetailsAndroid == null ? null : oneTimePurchaseOfferDetailsAndroid!.map((e) => e.toJson()).toList(),
      'platform': platform.toJson(),
      'price': price,
      'subscriptionOfferDetailsAndroid': subscriptionOfferDetailsAndroid.map((e) => e.toJson()).toList(),
      'title': title,
      'type': type.toJson(),
    };
  }
}

class ProductSubscriptionAndroidOfferDetails {
  const ProductSubscriptionAndroidOfferDetails({
    required this.basePlanId,
    this.offerId,
    required this.offerTags,
    required this.offerToken,
    required this.pricingPhases,
  });

  final String basePlanId;
  final String? offerId;
  final List<String> offerTags;
  final String offerToken;
  final PricingPhasesAndroid pricingPhases;

  factory ProductSubscriptionAndroidOfferDetails.fromJson(Map<String, dynamic> json) {
    return ProductSubscriptionAndroidOfferDetails(
      basePlanId: json['basePlanId'] as String,
      offerId: json['offerId'] as String?,
      offerTags: (json['offerTags'] as List<dynamic>).map((e) => e as String).toList(),
      offerToken: json['offerToken'] as String,
      pricingPhases: PricingPhasesAndroid.fromJson(json['pricingPhases'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '__typename': 'ProductSubscriptionAndroidOfferDetails',
      'basePlanId': basePlanId,
      'offerId': offerId,
      'offerTags': offerTags.map((e) => e).toList(),
      'offerToken': offerToken,
      'pricingPhases': pricingPhases.toJson(),
    };
  }
}

class ProductSubscriptionIOS extends ProductSubscription implements ProductCommon {
  const ProductSubscriptionIOS({
    required this.currency,
    this.debugDescription,
    required this.description,
    this.discountsIOS,
    this.displayName,
    required this.displayNameIOS,
    required this.displayPrice,
    required this.id,
    this.introductoryPriceAsAmountIOS,
    this.introductoryPriceIOS,
    this.introductoryPriceNumberOfPeriodsIOS,
    required this.introductoryPricePaymentModeIOS,
    this.introductoryPriceSubscriptionPeriodIOS,
    required this.isFamilyShareableIOS,
    required this.jsonRepresentationIOS,
    this.platform = IapPlatform.IOS,
    this.price,
    this.subscriptionInfoIOS,
    this.subscriptionPeriodNumberIOS,
    this.subscriptionPeriodUnitIOS,
    required this.title,
    this.type = ProductType.Subs,
    required this.typeIOS,
  });

  final String currency;
  final String? debugDescription;
  final String description;
  final List<DiscountIOS>? discountsIOS;
  final String? displayName;
  final String displayNameIOS;
  final String displayPrice;
  final String id;
  final String? introductoryPriceAsAmountIOS;
  final String? introductoryPriceIOS;
  final String? introductoryPriceNumberOfPeriodsIOS;
  final PaymentModeIOS introductoryPricePaymentModeIOS;
  final SubscriptionPeriodIOS? introductoryPriceSubscriptionPeriodIOS;
  final bool isFamilyShareableIOS;
  final String jsonRepresentationIOS;
  final IapPlatform platform;
  final double? price;
  final SubscriptionInfoIOS? subscriptionInfoIOS;
  final String? subscriptionPeriodNumberIOS;
  final SubscriptionPeriodIOS? subscriptionPeriodUnitIOS;
  final String title;
  final ProductType type;
  final ProductTypeIOS typeIOS;

  factory ProductSubscriptionIOS.fromJson(Map<String, dynamic> json) {
    return ProductSubscriptionIOS(
      currency: json['currency'] as String,
      debugDescription: json['debugDescription'] as String?,
      description: json['description'] as String,
      discountsIOS: (json['discountsIOS'] as List<dynamic>?) == null ? null : (json['discountsIOS'] as List<dynamic>?)!.map((e) => DiscountIOS.fromJson(e as Map<String, dynamic>)).toList(),
      displayName: json['displayName'] as String?,
      displayNameIOS: json['displayNameIOS'] as String,
      displayPrice: json['displayPrice'] as String,
      id: json['id'] as String,
      introductoryPriceAsAmountIOS: json['introductoryPriceAsAmountIOS'] as String?,
      introductoryPriceIOS: json['introductoryPriceIOS'] as String?,
      introductoryPriceNumberOfPeriodsIOS: json['introductoryPriceNumberOfPeriodsIOS'] as String?,
      introductoryPricePaymentModeIOS: PaymentModeIOS.fromJson(json['introductoryPricePaymentModeIOS'] as String),
      introductoryPriceSubscriptionPeriodIOS: json['introductoryPriceSubscriptionPeriodIOS'] != null ? SubscriptionPeriodIOS.fromJson(json['introductoryPriceSubscriptionPeriodIOS'] as String) : null,
      isFamilyShareableIOS: json['isFamilyShareableIOS'] as bool,
      jsonRepresentationIOS: json['jsonRepresentationIOS'] as String,
      platform: IapPlatform.fromJson(json['platform'] as String),
      price: (json['price'] as num?)?.toDouble(),
      subscriptionInfoIOS: json['subscriptionInfoIOS'] != null ? SubscriptionInfoIOS.fromJson(json['subscriptionInfoIOS'] as Map<String, dynamic>) : null,
      subscriptionPeriodNumberIOS: json['subscriptionPeriodNumberIOS'] as String?,
      subscriptionPeriodUnitIOS: json['subscriptionPeriodUnitIOS'] != null ? SubscriptionPeriodIOS.fromJson(json['subscriptionPeriodUnitIOS'] as String) : null,
      title: json['title'] as String,
      type: ProductType.fromJson(json['type'] as String),
      typeIOS: ProductTypeIOS.fromJson(json['typeIOS'] as String),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      '__typename': 'ProductSubscriptionIOS',
      'currency': currency,
      'debugDescription': debugDescription,
      'description': description,
      'discountsIOS': discountsIOS == null ? null : discountsIOS!.map((e) => e.toJson()).toList(),
      'displayName': displayName,
      'displayNameIOS': displayNameIOS,
      'displayPrice': displayPrice,
      'id': id,
      'introductoryPriceAsAmountIOS': introductoryPriceAsAmountIOS,
      'introductoryPriceIOS': introductoryPriceIOS,
      'introductoryPriceNumberOfPeriodsIOS': introductoryPriceNumberOfPeriodsIOS,
      'introductoryPricePaymentModeIOS': introductoryPricePaymentModeIOS.toJson(),
      'introductoryPriceSubscriptionPeriodIOS': introductoryPriceSubscriptionPeriodIOS?.toJson(),
      'isFamilyShareableIOS': isFamilyShareableIOS,
      'jsonRepresentationIOS': jsonRepresentationIOS,
      'platform': platform.toJson(),
      'price': price,
      'subscriptionInfoIOS': subscriptionInfoIOS?.toJson(),
      'subscriptionPeriodNumberIOS': subscriptionPeriodNumberIOS,
      'subscriptionPeriodUnitIOS': subscriptionPeriodUnitIOS?.toJson(),
      'title': title,
      'type': type.toJson(),
      'typeIOS': typeIOS.toJson(),
    };
  }
}

class PurchaseAndroid extends Purchase implements PurchaseCommon {
  const PurchaseAndroid({
    this.autoRenewingAndroid,
    this.currentPlanId,
    this.dataAndroid,
    this.developerPayloadAndroid,
    required this.id,
    this.ids,
    this.isAcknowledgedAndroid,
    required this.isAutoRenewing,
    this.isSuspendedAndroid,
    this.obfuscatedAccountIdAndroid,
    this.obfuscatedProfileIdAndroid,
    this.packageNameAndroid,
    required this.platform,
    required this.productId,
    required this.purchaseState,
    this.purchaseToken,
    required this.quantity,
    this.signatureAndroid,
    required this.store,
    required this.transactionDate,
    this.transactionId,
    this.isAlternativeBilling,
  });

  final bool? autoRenewingAndroid;
  final String? currentPlanId;
  final String? dataAndroid;
  final String? developerPayloadAndroid;
  final String id;
  final List<String>? ids;
  final bool? isAcknowledgedAndroid;
  final bool isAutoRenewing;
  /// Whether the subscription is suspended (Android)
  /// A suspended subscription means the user's payment method failed and they need to fix it.
  /// Users should be directed to the subscription center to resolve the issue.
  /// Do NOT grant entitlements for suspended subscriptions.
  /// Available in Google Play Billing Library 8.1.0+
  final bool? isSuspendedAndroid;
  final String? obfuscatedAccountIdAndroid;
  final String? obfuscatedProfileIdAndroid;
  final String? packageNameAndroid;
  final IapPlatform platform;
  final String productId;
  final PurchaseState purchaseState;
  final String? purchaseToken;
  final int quantity;
  final String? signatureAndroid;
  /// Store where purchase was made
  final IapStore store;
  final double transactionDate;
  final String? transactionId;
  final bool? isAlternativeBilling;

  factory PurchaseAndroid.fromJson(Map<String, dynamic> json) {
    return PurchaseAndroid(
      autoRenewingAndroid: json['autoRenewingAndroid'] as bool?,
      currentPlanId: json['currentPlanId'] as String?,
      dataAndroid: json['dataAndroid'] as String?,
      developerPayloadAndroid: json['developerPayloadAndroid'] as String?,
      id: json['id'] as String,
      ids: (json['ids'] as List<dynamic>?) == null ? null : (json['ids'] as List<dynamic>?)!.map((e) => e as String).toList(),
      isAcknowledgedAndroid: json['isAcknowledgedAndroid'] as bool?,
      isAutoRenewing: json['isAutoRenewing'] as bool,
      isSuspendedAndroid: json['isSuspendedAndroid'] as bool?,
      obfuscatedAccountIdAndroid: json['obfuscatedAccountIdAndroid'] as String?,
      obfuscatedProfileIdAndroid: json['obfuscatedProfileIdAndroid'] as String?,
      packageNameAndroid: json['packageNameAndroid'] as String?,
      platform: IapPlatform.fromJson(json['platform'] as String),
      productId: json['productId'] as String,
      purchaseState: PurchaseState.fromJson(json['purchaseState'] as String),
      purchaseToken: json['purchaseToken'] as String?,
      quantity: json['quantity'] as int,
      signatureAndroid: json['signatureAndroid'] as String?,
      store: IapStore.fromJson(json['store'] as String),
      transactionDate: (json['transactionDate'] as num).toDouble(),
      transactionId: json['transactionId'] as String?,
      isAlternativeBilling: json['isAlternativeBilling'] as bool?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      '__typename': 'PurchaseAndroid',
      'autoRenewingAndroid': autoRenewingAndroid,
      'currentPlanId': currentPlanId,
      'dataAndroid': dataAndroid,
      'developerPayloadAndroid': developerPayloadAndroid,
      'id': id,
      'ids': ids == null ? null : ids!.map((e) => e).toList(),
      'isAcknowledgedAndroid': isAcknowledgedAndroid,
      'isAutoRenewing': isAutoRenewing,
      'isSuspendedAndroid': isSuspendedAndroid,
      'obfuscatedAccountIdAndroid': obfuscatedAccountIdAndroid,
      'obfuscatedProfileIdAndroid': obfuscatedProfileIdAndroid,
      'packageNameAndroid': packageNameAndroid,
      'platform': platform.toJson(),
      'productId': productId,
      'purchaseState': purchaseState.toJson(),
      'purchaseToken': purchaseToken,
      'quantity': quantity,
      'signatureAndroid': signatureAndroid,
      'store': store.toJson(),
      'transactionDate': transactionDate,
      'transactionId': transactionId,
      'isAlternativeBilling': isAlternativeBilling,
    };
  }
}

class PurchaseError {
  const PurchaseError({
    required this.code,
    required this.message,
    this.productId,
  });

  final ErrorCode code;
  final String message;
  final String? productId;

  factory PurchaseError.fromJson(Map<String, dynamic> json) {
    return PurchaseError(
      code: ErrorCode.fromJson(json['code'] as String),
      message: json['message'] as String,
      productId: json['productId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '__typename': 'PurchaseError',
      'code': code.toJson(),
      'message': message,
      'productId': productId,
    };
  }
}

class PurchaseIOS extends Purchase implements PurchaseCommon {
  const PurchaseIOS({
    this.appAccountToken,
    this.appBundleIdIOS,
    this.countryCodeIOS,
    this.currencyCodeIOS,
    this.currencySymbolIOS,
    this.currentPlanId,
    this.environmentIOS,
    this.expirationDateIOS,
    required this.id,
    this.ids,
    required this.isAutoRenewing,
    this.isUpgradedIOS,
    this.offerIOS,
    this.originalTransactionDateIOS,
    this.originalTransactionIdentifierIOS,
    this.ownershipTypeIOS,
    required this.platform,
    required this.productId,
    required this.purchaseState,
    this.purchaseToken,
    required this.quantity,
    this.quantityIOS,
    this.reasonIOS,
    this.reasonStringRepresentationIOS,
    this.renewalInfoIOS,
    this.revocationDateIOS,
    this.revocationReasonIOS,
    required this.store,
    this.storefrontCountryCodeIOS,
    this.subscriptionGroupIdIOS,
    required this.transactionDate,
    required this.transactionId,
    this.transactionReasonIOS,
    this.webOrderLineItemIdIOS,
    this.isAlternativeBilling,
  });

  final String? appAccountToken;
  final String? appBundleIdIOS;
  final String? countryCodeIOS;
  final String? currencyCodeIOS;
  final String? currencySymbolIOS;
  final String? currentPlanId;
  final String? environmentIOS;
  final double? expirationDateIOS;
  final String id;
  final List<String>? ids;
  final bool isAutoRenewing;
  final bool? isUpgradedIOS;
  final PurchaseOfferIOS? offerIOS;
  final double? originalTransactionDateIOS;
  final String? originalTransactionIdentifierIOS;
  final String? ownershipTypeIOS;
  final IapPlatform platform;
  final String productId;
  final PurchaseState purchaseState;
  final String? purchaseToken;
  final int quantity;
  final int? quantityIOS;
  final String? reasonIOS;
  final String? reasonStringRepresentationIOS;
  final RenewalInfoIOS? renewalInfoIOS;
  final double? revocationDateIOS;
  final String? revocationReasonIOS;
  /// Store where purchase was made
  final IapStore store;
  final String? storefrontCountryCodeIOS;
  final String? subscriptionGroupIdIOS;
  final double transactionDate;
  final String transactionId;
  final String? transactionReasonIOS;
  final String? webOrderLineItemIdIOS;
  final bool? isAlternativeBilling;

  factory PurchaseIOS.fromJson(Map<String, dynamic> json) {
    return PurchaseIOS(
      appAccountToken: json['appAccountToken'] as String?,
      appBundleIdIOS: json['appBundleIdIOS'] as String?,
      countryCodeIOS: json['countryCodeIOS'] as String?,
      currencyCodeIOS: json['currencyCodeIOS'] as String?,
      currencySymbolIOS: json['currencySymbolIOS'] as String?,
      currentPlanId: json['currentPlanId'] as String?,
      environmentIOS: json['environmentIOS'] as String?,
      expirationDateIOS: (json['expirationDateIOS'] as num?)?.toDouble(),
      id: json['id'] as String,
      ids: (json['ids'] as List<dynamic>?) == null ? null : (json['ids'] as List<dynamic>?)!.map((e) => e as String).toList(),
      isAutoRenewing: json['isAutoRenewing'] as bool,
      isUpgradedIOS: json['isUpgradedIOS'] as bool?,
      offerIOS: json['offerIOS'] != null ? PurchaseOfferIOS.fromJson(json['offerIOS'] as Map<String, dynamic>) : null,
      originalTransactionDateIOS: (json['originalTransactionDateIOS'] as num?)?.toDouble(),
      originalTransactionIdentifierIOS: json['originalTransactionIdentifierIOS'] as String?,
      ownershipTypeIOS: json['ownershipTypeIOS'] as String?,
      platform: IapPlatform.fromJson(json['platform'] as String),
      productId: json['productId'] as String,
      purchaseState: PurchaseState.fromJson(json['purchaseState'] as String),
      purchaseToken: json['purchaseToken'] as String?,
      quantity: json['quantity'] as int,
      quantityIOS: json['quantityIOS'] as int?,
      reasonIOS: json['reasonIOS'] as String?,
      reasonStringRepresentationIOS: json['reasonStringRepresentationIOS'] as String?,
      renewalInfoIOS: json['renewalInfoIOS'] != null ? RenewalInfoIOS.fromJson(json['renewalInfoIOS'] as Map<String, dynamic>) : null,
      revocationDateIOS: (json['revocationDateIOS'] as num?)?.toDouble(),
      revocationReasonIOS: json['revocationReasonIOS'] as String?,
      store: IapStore.fromJson(json['store'] as String),
      storefrontCountryCodeIOS: json['storefrontCountryCodeIOS'] as String?,
      subscriptionGroupIdIOS: json['subscriptionGroupIdIOS'] as String?,
      transactionDate: (json['transactionDate'] as num).toDouble(),
      transactionId: json['transactionId'] as String,
      transactionReasonIOS: json['transactionReasonIOS'] as String?,
      webOrderLineItemIdIOS: json['webOrderLineItemIdIOS'] as String?,
      isAlternativeBilling: json['isAlternativeBilling'] as bool?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      '__typename': 'PurchaseIOS',
      'appAccountToken': appAccountToken,
      'appBundleIdIOS': appBundleIdIOS,
      'countryCodeIOS': countryCodeIOS,
      'currencyCodeIOS': currencyCodeIOS,
      'currencySymbolIOS': currencySymbolIOS,
      'currentPlanId': currentPlanId,
      'environmentIOS': environmentIOS,
      'expirationDateIOS': expirationDateIOS,
      'id': id,
      'ids': ids == null ? null : ids!.map((e) => e).toList(),
      'isAutoRenewing': isAutoRenewing,
      'isUpgradedIOS': isUpgradedIOS,
      'offerIOS': offerIOS?.toJson(),
      'originalTransactionDateIOS': originalTransactionDateIOS,
      'originalTransactionIdentifierIOS': originalTransactionIdentifierIOS,
      'ownershipTypeIOS': ownershipTypeIOS,
      'platform': platform.toJson(),
      'productId': productId,
      'purchaseState': purchaseState.toJson(),
      'purchaseToken': purchaseToken,
      'quantity': quantity,
      'quantityIOS': quantityIOS,
      'reasonIOS': reasonIOS,
      'reasonStringRepresentationIOS': reasonStringRepresentationIOS,
      'renewalInfoIOS': renewalInfoIOS?.toJson(),
      'revocationDateIOS': revocationDateIOS,
      'revocationReasonIOS': revocationReasonIOS,
      'store': store.toJson(),
      'storefrontCountryCodeIOS': storefrontCountryCodeIOS,
      'subscriptionGroupIdIOS': subscriptionGroupIdIOS,
      'transactionDate': transactionDate,
      'transactionId': transactionId,
      'transactionReasonIOS': transactionReasonIOS,
      'webOrderLineItemIdIOS': webOrderLineItemIdIOS,
      'isAlternativeBilling': isAlternativeBilling,
    };
  }
}

class PurchaseOfferIOS {
  const PurchaseOfferIOS({
    required this.id,
    required this.paymentMode,
    required this.type,
  });

  final String id;
  final String paymentMode;
  final String type;

  factory PurchaseOfferIOS.fromJson(Map<String, dynamic> json) {
    return PurchaseOfferIOS(
      id: json['id'] as String,
      paymentMode: json['paymentMode'] as String,
      type: json['type'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '__typename': 'PurchaseOfferIOS',
      'id': id,
      'paymentMode': paymentMode,
      'type': type,
    };
  }
}

class RefundResultIOS {
  const RefundResultIOS({
    this.message,
    required this.status,
  });

  final String? message;
  final String status;

  factory RefundResultIOS.fromJson(Map<String, dynamic> json) {
    return RefundResultIOS(
      message: json['message'] as String?,
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '__typename': 'RefundResultIOS',
      'message': message,
      'status': status,
    };
  }
}

/// Subscription renewal information from Product.SubscriptionInfo.RenewalInfo
/// https://developer.apple.com/documentation/storekit/product/subscriptioninfo/renewalinfo
class RenewalInfoIOS {
  const RenewalInfoIOS({
    this.autoRenewPreference,
    this.expirationReason,
    this.gracePeriodExpirationDate,
    this.isInBillingRetry,
    this.jsonRepresentation,
    this.pendingUpgradeProductId,
    this.priceIncreaseStatus,
    this.renewalDate,
    this.renewalOfferId,
    this.renewalOfferType,
    required this.willAutoRenew,
  });

  final String? autoRenewPreference;
  /// When subscription expires due to cancellation/billing issue
  /// Possible values: "VOLUNTARY", "BILLING_ERROR", "DID_NOT_AGREE_TO_PRICE_INCREASE", "PRODUCT_NOT_AVAILABLE", "UNKNOWN"
  final String? expirationReason;
  /// Grace period expiration date (milliseconds since epoch)
  /// When set, subscription is in grace period (billing issue but still has access)
  final double? gracePeriodExpirationDate;
  /// True if subscription failed to renew due to billing issue and is retrying
  /// Note: Not directly available in RenewalInfo, available in Status
  final bool? isInBillingRetry;
  final String? jsonRepresentation;
  /// Product ID that will be used on next renewal (when user upgrades/downgrades)
  /// If set and different from current productId, subscription will change on expiration
  final String? pendingUpgradeProductId;
  /// User's response to subscription price increase
  /// Possible values: "AGREED", "PENDING", null (no price increase)
  final String? priceIncreaseStatus;
  /// Expected renewal date (milliseconds since epoch)
  /// For active subscriptions, when the next renewal/charge will occur
  final double? renewalDate;
  /// Offer ID applied to next renewal (promotional offer, subscription offer code, etc.)
  final String? renewalOfferId;
  /// Type of offer applied to next renewal
  /// Possible values: "PROMOTIONAL", "SUBSCRIPTION_OFFER_CODE", "WIN_BACK", etc.
  final String? renewalOfferType;
  final bool willAutoRenew;

  factory RenewalInfoIOS.fromJson(Map<String, dynamic> json) {
    return RenewalInfoIOS(
      autoRenewPreference: json['autoRenewPreference'] as String?,
      expirationReason: json['expirationReason'] as String?,
      gracePeriodExpirationDate: (json['gracePeriodExpirationDate'] as num?)?.toDouble(),
      isInBillingRetry: json['isInBillingRetry'] as bool?,
      jsonRepresentation: json['jsonRepresentation'] as String?,
      pendingUpgradeProductId: json['pendingUpgradeProductId'] as String?,
      priceIncreaseStatus: json['priceIncreaseStatus'] as String?,
      renewalDate: (json['renewalDate'] as num?)?.toDouble(),
      renewalOfferId: json['renewalOfferId'] as String?,
      renewalOfferType: json['renewalOfferType'] as String?,
      willAutoRenew: json['willAutoRenew'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '__typename': 'RenewalInfoIOS',
      'autoRenewPreference': autoRenewPreference,
      'expirationReason': expirationReason,
      'gracePeriodExpirationDate': gracePeriodExpirationDate,
      'isInBillingRetry': isInBillingRetry,
      'jsonRepresentation': jsonRepresentation,
      'pendingUpgradeProductId': pendingUpgradeProductId,
      'priceIncreaseStatus': priceIncreaseStatus,
      'renewalDate': renewalDate,
      'renewalOfferId': renewalOfferId,
      'renewalOfferType': renewalOfferType,
      'willAutoRenew': willAutoRenew,
    };
  }
}

/// Rental details for one-time purchase products that can be rented (Android)
/// Available in Google Play Billing Library 7.0+
class RentalDetailsAndroid {
  const RentalDetailsAndroid({
    this.rentalExpirationPeriod,
    required this.rentalPeriod,
  });

  /// Rental expiration period in ISO 8601 format
  /// Time after rental period ends when user can still extend
  final String? rentalExpirationPeriod;
  /// Rental period in ISO 8601 format (e.g., P7D for 7 days)
  final String rentalPeriod;

  factory RentalDetailsAndroid.fromJson(Map<String, dynamic> json) {
    return RentalDetailsAndroid(
      rentalExpirationPeriod: json['rentalExpirationPeriod'] as String?,
      rentalPeriod: json['rentalPeriod'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '__typename': 'RentalDetailsAndroid',
      'rentalExpirationPeriod': rentalExpirationPeriod,
      'rentalPeriod': rentalPeriod,
    };
  }
}

abstract class RequestPurchaseResult {
  const RequestPurchaseResult();
}

class RequestPurchaseResultPurchase extends RequestPurchaseResult {
  const RequestPurchaseResultPurchase(this.value);
  final Purchase? value;
}

class RequestPurchaseResultPurchases extends RequestPurchaseResult {
  const RequestPurchaseResultPurchases(this.value);
  final List<Purchase>? value;
}

class RequestVerifyPurchaseWithIapkitResult {
  const RequestVerifyPurchaseWithIapkitResult({
    required this.isValid,
    required this.state,
    required this.store,
  });

  /// Whether the purchase is valid (not falsified).
  final bool isValid;
  /// The current state of the purchase.
  final IapkitPurchaseState state;
  final IapStore store;

  factory RequestVerifyPurchaseWithIapkitResult.fromJson(Map<String, dynamic> json) {
    return RequestVerifyPurchaseWithIapkitResult(
      isValid: json['isValid'] as bool,
      state: IapkitPurchaseState.fromJson(json['state'] as String),
      store: IapStore.fromJson(json['store'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '__typename': 'RequestVerifyPurchaseWithIapkitResult',
      'isValid': isValid,
      'state': state.toJson(),
      'store': store.toJson(),
    };
  }
}

class SubscriptionInfoIOS {
  const SubscriptionInfoIOS({
    this.introductoryOffer,
    this.promotionalOffers,
    required this.subscriptionGroupId,
    required this.subscriptionPeriod,
  });

  final SubscriptionOfferIOS? introductoryOffer;
  final List<SubscriptionOfferIOS>? promotionalOffers;
  final String subscriptionGroupId;
  final SubscriptionPeriodValueIOS subscriptionPeriod;

  factory SubscriptionInfoIOS.fromJson(Map<String, dynamic> json) {
    return SubscriptionInfoIOS(
      introductoryOffer: json['introductoryOffer'] != null ? SubscriptionOfferIOS.fromJson(json['introductoryOffer'] as Map<String, dynamic>) : null,
      promotionalOffers: (json['promotionalOffers'] as List<dynamic>?) == null ? null : (json['promotionalOffers'] as List<dynamic>?)!.map((e) => SubscriptionOfferIOS.fromJson(e as Map<String, dynamic>)).toList(),
      subscriptionGroupId: json['subscriptionGroupId'] as String,
      subscriptionPeriod: SubscriptionPeriodValueIOS.fromJson(json['subscriptionPeriod'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '__typename': 'SubscriptionInfoIOS',
      'introductoryOffer': introductoryOffer?.toJson(),
      'promotionalOffers': promotionalOffers == null ? null : promotionalOffers!.map((e) => e.toJson()).toList(),
      'subscriptionGroupId': subscriptionGroupId,
      'subscriptionPeriod': subscriptionPeriod.toJson(),
    };
  }
}

class SubscriptionOfferIOS {
  const SubscriptionOfferIOS({
    required this.displayPrice,
    required this.id,
    required this.paymentMode,
    required this.period,
    required this.periodCount,
    required this.price,
    required this.type,
  });

  final String displayPrice;
  final String id;
  final PaymentModeIOS paymentMode;
  final SubscriptionPeriodValueIOS period;
  final int periodCount;
  final double price;
  final SubscriptionOfferTypeIOS type;

  factory SubscriptionOfferIOS.fromJson(Map<String, dynamic> json) {
    return SubscriptionOfferIOS(
      displayPrice: json['displayPrice'] as String,
      id: json['id'] as String,
      paymentMode: PaymentModeIOS.fromJson(json['paymentMode'] as String),
      period: SubscriptionPeriodValueIOS.fromJson(json['period'] as Map<String, dynamic>),
      periodCount: json['periodCount'] as int,
      price: (json['price'] as num).toDouble(),
      type: SubscriptionOfferTypeIOS.fromJson(json['type'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '__typename': 'SubscriptionOfferIOS',
      'displayPrice': displayPrice,
      'id': id,
      'paymentMode': paymentMode.toJson(),
      'period': period.toJson(),
      'periodCount': periodCount,
      'price': price,
      'type': type.toJson(),
    };
  }
}

class SubscriptionPeriodValueIOS {
  const SubscriptionPeriodValueIOS({
    required this.unit,
    required this.value,
  });

  final SubscriptionPeriodIOS unit;
  final int value;

  factory SubscriptionPeriodValueIOS.fromJson(Map<String, dynamic> json) {
    return SubscriptionPeriodValueIOS(
      unit: SubscriptionPeriodIOS.fromJson(json['unit'] as String),
      value: json['value'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '__typename': 'SubscriptionPeriodValueIOS',
      'unit': unit.toJson(),
      'value': value,
    };
  }
}

class SubscriptionStatusIOS {
  const SubscriptionStatusIOS({
    this.renewalInfo,
    required this.state,
  });

  final RenewalInfoIOS? renewalInfo;
  final String state;

  factory SubscriptionStatusIOS.fromJson(Map<String, dynamic> json) {
    return SubscriptionStatusIOS(
      renewalInfo: json['renewalInfo'] != null ? RenewalInfoIOS.fromJson(json['renewalInfo'] as Map<String, dynamic>) : null,
      state: json['state'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '__typename': 'SubscriptionStatusIOS',
      'renewalInfo': renewalInfo?.toJson(),
      'state': state,
    };
  }
}

/// User Choice Billing event details (Android)
/// Fired when a user selects alternative billing in the User Choice Billing dialog
class UserChoiceBillingDetails {
  const UserChoiceBillingDetails({
    required this.externalTransactionToken,
    required this.products,
  });

  /// Token that must be reported to Google Play within 24 hours
  final String externalTransactionToken;
  /// List of product IDs selected by the user
  final List<String> products;

  factory UserChoiceBillingDetails.fromJson(Map<String, dynamic> json) {
    return UserChoiceBillingDetails(
      externalTransactionToken: json['externalTransactionToken'] as String,
      products: (json['products'] as List<dynamic>).map((e) => e as String).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '__typename': 'UserChoiceBillingDetails',
      'externalTransactionToken': externalTransactionToken,
      'products': products.map((e) => e).toList(),
    };
  }
}

/// Valid time window for when an offer is available (Android)
/// Available in Google Play Billing Library 7.0+
class ValidTimeWindowAndroid {
  const ValidTimeWindowAndroid({
    required this.endTimeMillis,
    required this.startTimeMillis,
  });

  /// End time in milliseconds since epoch
  final String endTimeMillis;
  /// Start time in milliseconds since epoch
  final String startTimeMillis;

  factory ValidTimeWindowAndroid.fromJson(Map<String, dynamic> json) {
    return ValidTimeWindowAndroid(
      endTimeMillis: json['endTimeMillis'] as String,
      startTimeMillis: json['startTimeMillis'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '__typename': 'ValidTimeWindowAndroid',
      'endTimeMillis': endTimeMillis,
      'startTimeMillis': startTimeMillis,
    };
  }
}

class VerifyPurchaseResultAndroid extends VerifyPurchaseResult {
  const VerifyPurchaseResultAndroid({
    required this.autoRenewing,
    required this.betaProduct,
    this.cancelDate,
    this.cancelReason,
    this.deferredDate,
    this.deferredSku,
    required this.freeTrialEndDate,
    required this.gracePeriodEndDate,
    required this.parentProductId,
    required this.productId,
    required this.productType,
    required this.purchaseDate,
    required this.quantity,
    required this.receiptId,
    required this.renewalDate,
    required this.term,
    required this.termSku,
    required this.testTransaction,
  });

  final bool autoRenewing;
  final bool betaProduct;
  final double? cancelDate;
  final String? cancelReason;
  final double? deferredDate;
  final String? deferredSku;
  final double freeTrialEndDate;
  final double gracePeriodEndDate;
  final String parentProductId;
  final String productId;
  final String productType;
  final double purchaseDate;
  final int quantity;
  final String receiptId;
  final double renewalDate;
  final String term;
  final String termSku;
  final bool testTransaction;

  factory VerifyPurchaseResultAndroid.fromJson(Map<String, dynamic> json) {
    return VerifyPurchaseResultAndroid(
      autoRenewing: json['autoRenewing'] as bool,
      betaProduct: json['betaProduct'] as bool,
      cancelDate: (json['cancelDate'] as num?)?.toDouble(),
      cancelReason: json['cancelReason'] as String?,
      deferredDate: (json['deferredDate'] as num?)?.toDouble(),
      deferredSku: json['deferredSku'] as String?,
      freeTrialEndDate: (json['freeTrialEndDate'] as num).toDouble(),
      gracePeriodEndDate: (json['gracePeriodEndDate'] as num).toDouble(),
      parentProductId: json['parentProductId'] as String,
      productId: json['productId'] as String,
      productType: json['productType'] as String,
      purchaseDate: (json['purchaseDate'] as num).toDouble(),
      quantity: json['quantity'] as int,
      receiptId: json['receiptId'] as String,
      renewalDate: (json['renewalDate'] as num).toDouble(),
      term: json['term'] as String,
      termSku: json['termSku'] as String,
      testTransaction: json['testTransaction'] as bool,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      '__typename': 'VerifyPurchaseResultAndroid',
      'autoRenewing': autoRenewing,
      'betaProduct': betaProduct,
      'cancelDate': cancelDate,
      'cancelReason': cancelReason,
      'deferredDate': deferredDate,
      'deferredSku': deferredSku,
      'freeTrialEndDate': freeTrialEndDate,
      'gracePeriodEndDate': gracePeriodEndDate,
      'parentProductId': parentProductId,
      'productId': productId,
      'productType': productType,
      'purchaseDate': purchaseDate,
      'quantity': quantity,
      'receiptId': receiptId,
      'renewalDate': renewalDate,
      'term': term,
      'termSku': termSku,
      'testTransaction': testTransaction,
    };
  }
}

/// Result from Meta Horizon verify_entitlement API.
/// Returns verification status and grant time for the entitlement.
class VerifyPurchaseResultHorizon extends VerifyPurchaseResult {
  const VerifyPurchaseResultHorizon({
    this.grantTime,
    required this.success,
  });

  /// Unix timestamp (seconds) when the entitlement was granted.
  final double? grantTime;
  /// Whether the entitlement verification succeeded.
  final bool success;

  factory VerifyPurchaseResultHorizon.fromJson(Map<String, dynamic> json) {
    return VerifyPurchaseResultHorizon(
      grantTime: (json['grantTime'] as num?)?.toDouble(),
      success: json['success'] as bool,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      '__typename': 'VerifyPurchaseResultHorizon',
      'grantTime': grantTime,
      'success': success,
    };
  }
}

class VerifyPurchaseResultIOS extends VerifyPurchaseResult {
  const VerifyPurchaseResultIOS({
    required this.isValid,
    required this.jwsRepresentation,
    this.latestTransaction,
    required this.receiptData,
  });

  /// Whether the receipt is valid
  final bool isValid;
  /// JWS representation
  final String jwsRepresentation;
  /// Latest transaction if available
  final Purchase? latestTransaction;
  /// Receipt data string
  final String receiptData;

  factory VerifyPurchaseResultIOS.fromJson(Map<String, dynamic> json) {
    return VerifyPurchaseResultIOS(
      isValid: json['isValid'] as bool,
      jwsRepresentation: json['jwsRepresentation'] as String,
      latestTransaction: json['latestTransaction'] != null ? Purchase.fromJson(json['latestTransaction'] as Map<String, dynamic>) : null,
      receiptData: json['receiptData'] as String,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      '__typename': 'VerifyPurchaseResultIOS',
      'isValid': isValid,
      'jwsRepresentation': jwsRepresentation,
      'latestTransaction': latestTransaction?.toJson(),
      'receiptData': receiptData,
    };
  }
}

class VerifyPurchaseWithProviderError {
  const VerifyPurchaseWithProviderError({
    this.code,
    required this.message,
  });

  final String? code;
  final String message;

  factory VerifyPurchaseWithProviderError.fromJson(Map<String, dynamic> json) {
    return VerifyPurchaseWithProviderError(
      code: json['code'] as String?,
      message: json['message'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '__typename': 'VerifyPurchaseWithProviderError',
      'code': code,
      'message': message,
    };
  }
}

class VerifyPurchaseWithProviderResult {
  const VerifyPurchaseWithProviderResult({
    this.errors,
    this.iapkit,
    required this.provider,
  });

  /// Error details if verification failed
  final List<VerifyPurchaseWithProviderError>? errors;
  /// IAPKit verification result
  final RequestVerifyPurchaseWithIapkitResult? iapkit;
  final PurchaseVerificationProvider provider;

  factory VerifyPurchaseWithProviderResult.fromJson(Map<String, dynamic> json) {
    return VerifyPurchaseWithProviderResult(
      errors: (json['errors'] as List<dynamic>?) == null ? null : (json['errors'] as List<dynamic>?)!.map((e) => VerifyPurchaseWithProviderError.fromJson(e as Map<String, dynamic>)).toList(),
      iapkit: json['iapkit'] != null ? RequestVerifyPurchaseWithIapkitResult.fromJson(json['iapkit'] as Map<String, dynamic>) : null,
      provider: PurchaseVerificationProvider.fromJson(json['provider'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '__typename': 'VerifyPurchaseWithProviderResult',
      'errors': errors == null ? null : errors!.map((e) => e.toJson()).toList(),
      'iapkit': iapkit?.toJson(),
      'provider': provider.toJson(),
    };
  }
}

typedef VoidResult = void;

// MARK: - Input Objects

class AndroidSubscriptionOfferInput {
  const AndroidSubscriptionOfferInput({
    required this.offerToken,
    required this.sku,
  });

  /// Offer token
  final String offerToken;
  /// Product SKU
  final String sku;

  factory AndroidSubscriptionOfferInput.fromJson(Map<String, dynamic> json) {
    return AndroidSubscriptionOfferInput(
      offerToken: json['offerToken'] as String,
      sku: json['sku'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'offerToken': offerToken,
      'sku': sku,
    };
  }
}

class DeepLinkOptions {
  const DeepLinkOptions({
    this.packageNameAndroid,
    this.skuAndroid,
  });

  /// Android package name to target (required on Android)
  final String? packageNameAndroid;
  /// Android SKU to open (required on Android)
  final String? skuAndroid;

  factory DeepLinkOptions.fromJson(Map<String, dynamic> json) {
    return DeepLinkOptions(
      packageNameAndroid: json['packageNameAndroid'] as String?,
      skuAndroid: json['skuAndroid'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'packageNameAndroid': packageNameAndroid,
      'skuAndroid': skuAndroid,
    };
  }
}

/// Parameters for developer billing option in purchase flow (Android)
/// Used with BillingFlowParams to enable external payments flow
/// Available in Google Play Billing Library 8.3.0+
class DeveloperBillingOptionParamsAndroid {
  const DeveloperBillingOptionParamsAndroid({
    required this.billingProgram,
    required this.launchMode,
    required this.linkUri,
  });

  /// The billing program (should be EXTERNAL_PAYMENTS for external payments flow)
  final BillingProgramAndroid billingProgram;
  /// The launch mode for the external payment link
  final DeveloperBillingLaunchModeAndroid launchMode;
  /// The URI where the external payment will be processed
  final String linkUri;

  factory DeveloperBillingOptionParamsAndroid.fromJson(Map<String, dynamic> json) {
    return DeveloperBillingOptionParamsAndroid(
      billingProgram: BillingProgramAndroid.fromJson(json['billingProgram'] as String),
      launchMode: DeveloperBillingLaunchModeAndroid.fromJson(json['launchMode'] as String),
      linkUri: json['linkUri'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'billingProgram': billingProgram.toJson(),
      'launchMode': launchMode.toJson(),
      'linkUri': linkUri,
    };
  }
}

class DiscountOfferInputIOS {
  const DiscountOfferInputIOS({
    required this.identifier,
    required this.keyIdentifier,
    required this.nonce,
    required this.signature,
    required this.timestamp,
  });

  /// Discount identifier
  final String identifier;
  /// Key identifier for validation
  final String keyIdentifier;
  /// Cryptographic nonce
  final String nonce;
  /// Signature for validation
  final String signature;
  /// Timestamp of discount offer
  final double timestamp;

  factory DiscountOfferInputIOS.fromJson(Map<String, dynamic> json) {
    return DiscountOfferInputIOS(
      identifier: json['identifier'] as String,
      keyIdentifier: json['keyIdentifier'] as String,
      nonce: json['nonce'] as String,
      signature: json['signature'] as String,
      timestamp: (json['timestamp'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'identifier': identifier,
      'keyIdentifier': keyIdentifier,
      'nonce': nonce,
      'signature': signature,
      'timestamp': timestamp,
    };
  }
}

/// Connection initialization configuration
class InitConnectionConfig {
  const InitConnectionConfig({
    this.alternativeBillingModeAndroid,
    this.enableBillingProgramAndroid,
  });

  /// Alternative billing mode for Android
  /// If not specified, defaults to NONE (standard Google Play billing)
  /// @deprecated Use enableBillingProgramAndroid instead.
  /// Use USER_CHOICE_BILLING for user choice billing, EXTERNAL_OFFER for alternative only.
  final AlternativeBillingModeAndroid? alternativeBillingModeAndroid;
  /// Enable a specific billing program for Android (7.0+)
  /// When set, enables the specified billing program for external transactions.
  /// - USER_CHOICE_BILLING: User can select between Google Play or alternative (7.0+)
  /// - EXTERNAL_CONTENT_LINK: Link to external content (8.2.0+)
  /// - EXTERNAL_OFFER: External offers for digital content (8.2.0+)
  /// - EXTERNAL_PAYMENTS: Developer provided billing, Japan only (8.3.0+)
  final BillingProgramAndroid? enableBillingProgramAndroid;

  factory InitConnectionConfig.fromJson(Map<String, dynamic> json) {
    return InitConnectionConfig(
      alternativeBillingModeAndroid: json['alternativeBillingModeAndroid'] != null ? AlternativeBillingModeAndroid.fromJson(json['alternativeBillingModeAndroid'] as String) : null,
      enableBillingProgramAndroid: json['enableBillingProgramAndroid'] != null ? BillingProgramAndroid.fromJson(json['enableBillingProgramAndroid'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'alternativeBillingModeAndroid': alternativeBillingModeAndroid?.toJson(),
      'enableBillingProgramAndroid': enableBillingProgramAndroid?.toJson(),
    };
  }
}

/// Parameters for launching an external link (Android)
/// Used with launchExternalLink to initiate external offer or app install flows
/// Available in Google Play Billing Library 8.2.0+
class LaunchExternalLinkParamsAndroid {
  const LaunchExternalLinkParamsAndroid({
    required this.billingProgram,
    required this.launchMode,
    required this.linkType,
    required this.linkUri,
  });

  /// The billing program (EXTERNAL_CONTENT_LINK or EXTERNAL_OFFER)
  final BillingProgramAndroid billingProgram;
  /// The external link launch mode
  final ExternalLinkLaunchModeAndroid launchMode;
  /// The type of the external link
  final ExternalLinkTypeAndroid linkType;
  /// The URI where the content will be accessed from
  final String linkUri;

  factory LaunchExternalLinkParamsAndroid.fromJson(Map<String, dynamic> json) {
    return LaunchExternalLinkParamsAndroid(
      billingProgram: BillingProgramAndroid.fromJson(json['billingProgram'] as String),
      launchMode: ExternalLinkLaunchModeAndroid.fromJson(json['launchMode'] as String),
      linkType: ExternalLinkTypeAndroid.fromJson(json['linkType'] as String),
      linkUri: json['linkUri'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'billingProgram': billingProgram.toJson(),
      'launchMode': launchMode.toJson(),
      'linkType': linkType.toJson(),
      'linkUri': linkUri,
    };
  }
}

class ProductRequest {
  const ProductRequest({
    required this.skus,
    this.type,
  });

  final List<String> skus;
  final ProductQueryType? type;

  factory ProductRequest.fromJson(Map<String, dynamic> json) {
    return ProductRequest(
      skus: (json['skus'] as List<dynamic>).map((e) => e as String).toList(),
      type: json['type'] != null ? ProductQueryType.fromJson(json['type'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'skus': skus.map((e) => e).toList(),
      'type': type?.toJson(),
    };
  }
}

typedef PurchaseInput = Purchase;

class PurchaseOptions {
  const PurchaseOptions({
    this.alsoPublishToEventListenerIOS,
    this.onlyIncludeActiveItemsIOS,
  });

  /// Also emit results through the iOS event listeners
  final bool? alsoPublishToEventListenerIOS;
  /// Limit to currently active items on iOS
  final bool? onlyIncludeActiveItemsIOS;

  factory PurchaseOptions.fromJson(Map<String, dynamic> json) {
    return PurchaseOptions(
      alsoPublishToEventListenerIOS: json['alsoPublishToEventListenerIOS'] as bool?,
      onlyIncludeActiveItemsIOS: json['onlyIncludeActiveItemsIOS'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'alsoPublishToEventListenerIOS': alsoPublishToEventListenerIOS,
      'onlyIncludeActiveItemsIOS': onlyIncludeActiveItemsIOS,
    };
  }
}

class RequestPurchaseAndroidProps {
  const RequestPurchaseAndroidProps({
    this.developerBillingOption,
    this.isOfferPersonalized,
    this.obfuscatedAccountIdAndroid,
    this.obfuscatedProfileIdAndroid,
    required this.skus,
  });

  /// Developer billing option parameters for external payments flow (8.3.0+).
  /// When provided, the purchase flow will show a side-by-side choice between
  /// Google Play Billing and the developer's external payment option.
  final DeveloperBillingOptionParamsAndroid? developerBillingOption;
  /// Personalized offer flag
  final bool? isOfferPersonalized;
  /// Obfuscated account ID
  final String? obfuscatedAccountIdAndroid;
  /// Obfuscated profile ID
  final String? obfuscatedProfileIdAndroid;
  /// List of product SKUs
  final List<String> skus;

  factory RequestPurchaseAndroidProps.fromJson(Map<String, dynamic> json) {
    return RequestPurchaseAndroidProps(
      developerBillingOption: json['developerBillingOption'] != null ? DeveloperBillingOptionParamsAndroid.fromJson(json['developerBillingOption'] as Map<String, dynamic>) : null,
      isOfferPersonalized: json['isOfferPersonalized'] as bool?,
      obfuscatedAccountIdAndroid: json['obfuscatedAccountIdAndroid'] as String?,
      obfuscatedProfileIdAndroid: json['obfuscatedProfileIdAndroid'] as String?,
      skus: (json['skus'] as List<dynamic>).map((e) => e as String).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'developerBillingOption': developerBillingOption?.toJson(),
      'isOfferPersonalized': isOfferPersonalized,
      'obfuscatedAccountIdAndroid': obfuscatedAccountIdAndroid,
      'obfuscatedProfileIdAndroid': obfuscatedProfileIdAndroid,
      'skus': skus.map((e) => e).toList(),
    };
  }
}

class RequestPurchaseIosProps {
  const RequestPurchaseIosProps({
    this.advancedCommerceData,
    this.andDangerouslyFinishTransactionAutomatically,
    this.appAccountToken,
    this.quantity,
    required this.sku,
    this.withOffer,
  });

  /// Advanced commerce data token (iOS 15+).
  /// Used with StoreKit 2's Product.PurchaseOption.custom API for passing
  /// campaign tokens, affiliate IDs, or other attribution data.
  /// The data is formatted as JSON: {"signatureInfo": {"token": "<value>"}}
  final String? advancedCommerceData;
  /// Auto-finish transaction (dangerous)
  final bool? andDangerouslyFinishTransactionAutomatically;
  /// App account token for user tracking
  final String? appAccountToken;
  /// Purchase quantity
  final int? quantity;
  /// Product SKU
  final String sku;
  /// Discount offer to apply
  final DiscountOfferInputIOS? withOffer;

  factory RequestPurchaseIosProps.fromJson(Map<String, dynamic> json) {
    return RequestPurchaseIosProps(
      advancedCommerceData: json['advancedCommerceData'] as String?,
      andDangerouslyFinishTransactionAutomatically: json['andDangerouslyFinishTransactionAutomatically'] as bool?,
      appAccountToken: json['appAccountToken'] as String?,
      quantity: json['quantity'] as int?,
      sku: json['sku'] as String,
      withOffer: json['withOffer'] != null ? DiscountOfferInputIOS.fromJson(json['withOffer'] as Map<String, dynamic>) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'advancedCommerceData': advancedCommerceData,
      'andDangerouslyFinishTransactionAutomatically': andDangerouslyFinishTransactionAutomatically,
      'appAccountToken': appAccountToken,
      'quantity': quantity,
      'sku': sku,
      'withOffer': withOffer?.toJson(),
    };
  }
}

sealed class RequestPurchaseProps {
  const RequestPurchaseProps._();

  const factory RequestPurchaseProps.inApp(({
    RequestPurchaseIosProps? apple,
    RequestPurchaseAndroidProps? google,
    bool? useAlternativeBilling,
  }) props) = _InAppPurchase;

  const factory RequestPurchaseProps.subs(({
    RequestSubscriptionIosProps? apple,
    RequestSubscriptionAndroidProps? google,
    bool? useAlternativeBilling,
  }) props) = _SubsPurchase;

  Map<String, dynamic> toJson();
}

class _InAppPurchase extends RequestPurchaseProps {
  const _InAppPurchase(this.props) : super._();
  final ({
    RequestPurchaseIosProps? apple,
    RequestPurchaseAndroidProps? google,
    bool? useAlternativeBilling,
  }) props;

  @override
  Map<String, dynamic> toJson() {
    return {
      'requestPurchase': {
        if (props.apple != null) 'ios': props.apple!.toJson(),
        if (props.google != null) 'android': props.google!.toJson(),
      },
      'type': ProductQueryType.InApp.toJson(),
      if (props.useAlternativeBilling != null) 'useAlternativeBilling': props.useAlternativeBilling,
    };
  }
}

class _SubsPurchase extends RequestPurchaseProps {
  const _SubsPurchase(this.props) : super._();
  final ({
    RequestSubscriptionIosProps? apple,
    RequestSubscriptionAndroidProps? google,
    bool? useAlternativeBilling,
  }) props;

  @override
  Map<String, dynamic> toJson() {
    return {
      'requestSubscription': {
        if (props.apple != null) 'ios': props.apple!.toJson(),
        if (props.google != null) 'android': props.google!.toJson(),
      },
      'type': ProductQueryType.Subs.toJson(),
      if (props.useAlternativeBilling != null) 'useAlternativeBilling': props.useAlternativeBilling,
    };
  }
}

/// Platform-specific purchase request parameters.
/// 
/// Note: "Platforms" refers to the SDK/OS level (apple, google), not the store.
/// - apple: Always targets App Store
/// - google: Targets Play Store by default, or Horizon when built with horizon flavor
///   (determined at build time, not runtime)
class RequestPurchasePropsByPlatforms {
  const RequestPurchasePropsByPlatforms({
    this.android,
    this.apple,
    this.google,
    this.ios,
  });

  /// @deprecated Use google instead
  final RequestPurchaseAndroidProps? android;
  /// Apple-specific purchase parameters
  final RequestPurchaseIosProps? apple;
  /// Google-specific purchase parameters
  final RequestPurchaseAndroidProps? google;
  /// @deprecated Use apple instead
  final RequestPurchaseIosProps? ios;

  factory RequestPurchasePropsByPlatforms.fromJson(Map<String, dynamic> json) {
    return RequestPurchasePropsByPlatforms(
      android: json['android'] != null ? RequestPurchaseAndroidProps.fromJson(json['android'] as Map<String, dynamic>) : null,
      apple: json['apple'] != null ? RequestPurchaseIosProps.fromJson(json['apple'] as Map<String, dynamic>) : null,
      google: json['google'] != null ? RequestPurchaseAndroidProps.fromJson(json['google'] as Map<String, dynamic>) : null,
      ios: json['ios'] != null ? RequestPurchaseIosProps.fromJson(json['ios'] as Map<String, dynamic>) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'android': android?.toJson(),
      'apple': apple?.toJson(),
      'google': google?.toJson(),
      'ios': ios?.toJson(),
    };
  }
}

class RequestSubscriptionAndroidProps {
  const RequestSubscriptionAndroidProps({
    this.developerBillingOption,
    this.isOfferPersonalized,
    this.obfuscatedAccountIdAndroid,
    this.obfuscatedProfileIdAndroid,
    this.purchaseTokenAndroid,
    this.replacementModeAndroid,
    required this.skus,
    this.subscriptionOffers,
    this.subscriptionProductReplacementParams,
  });

  /// Developer billing option parameters for external payments flow (8.3.0+).
  /// When provided, the purchase flow will show a side-by-side choice between
  /// Google Play Billing and the developer's external payment option.
  final DeveloperBillingOptionParamsAndroid? developerBillingOption;
  /// Personalized offer flag
  final bool? isOfferPersonalized;
  /// Obfuscated account ID
  final String? obfuscatedAccountIdAndroid;
  /// Obfuscated profile ID
  final String? obfuscatedProfileIdAndroid;
  /// Purchase token for upgrades/downgrades
  final String? purchaseTokenAndroid;
  /// Replacement mode for subscription changes
  /// @deprecated Use subscriptionProductReplacementParams instead for item-level replacement (8.1.0+)
  final int? replacementModeAndroid;
  /// List of subscription SKUs
  final List<String> skus;
  /// Subscription offers
  final List<AndroidSubscriptionOfferInput>? subscriptionOffers;
  /// Product-level replacement parameters (8.1.0+)
  /// Use this instead of replacementModeAndroid for item-level replacement
  final SubscriptionProductReplacementParamsAndroid? subscriptionProductReplacementParams;

  factory RequestSubscriptionAndroidProps.fromJson(Map<String, dynamic> json) {
    return RequestSubscriptionAndroidProps(
      developerBillingOption: json['developerBillingOption'] != null ? DeveloperBillingOptionParamsAndroid.fromJson(json['developerBillingOption'] as Map<String, dynamic>) : null,
      isOfferPersonalized: json['isOfferPersonalized'] as bool?,
      obfuscatedAccountIdAndroid: json['obfuscatedAccountIdAndroid'] as String?,
      obfuscatedProfileIdAndroid: json['obfuscatedProfileIdAndroid'] as String?,
      purchaseTokenAndroid: json['purchaseTokenAndroid'] as String?,
      replacementModeAndroid: json['replacementModeAndroid'] as int?,
      skus: (json['skus'] as List<dynamic>).map((e) => e as String).toList(),
      subscriptionOffers: (json['subscriptionOffers'] as List<dynamic>?) == null ? null : (json['subscriptionOffers'] as List<dynamic>?)!.map((e) => AndroidSubscriptionOfferInput.fromJson(e as Map<String, dynamic>)).toList(),
      subscriptionProductReplacementParams: json['subscriptionProductReplacementParams'] != null ? SubscriptionProductReplacementParamsAndroid.fromJson(json['subscriptionProductReplacementParams'] as Map<String, dynamic>) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'developerBillingOption': developerBillingOption?.toJson(),
      'isOfferPersonalized': isOfferPersonalized,
      'obfuscatedAccountIdAndroid': obfuscatedAccountIdAndroid,
      'obfuscatedProfileIdAndroid': obfuscatedProfileIdAndroid,
      'purchaseTokenAndroid': purchaseTokenAndroid,
      'replacementModeAndroid': replacementModeAndroid,
      'skus': skus.map((e) => e).toList(),
      'subscriptionOffers': subscriptionOffers == null ? null : subscriptionOffers!.map((e) => e.toJson()).toList(),
      'subscriptionProductReplacementParams': subscriptionProductReplacementParams?.toJson(),
    };
  }
}

class RequestSubscriptionIosProps {
  const RequestSubscriptionIosProps({
    this.advancedCommerceData,
    this.andDangerouslyFinishTransactionAutomatically,
    this.appAccountToken,
    this.quantity,
    required this.sku,
    this.withOffer,
  });

  /// Advanced commerce data token (iOS 15+).
  /// Used with StoreKit 2's Product.PurchaseOption.custom API for passing
  /// campaign tokens, affiliate IDs, or other attribution data.
  /// The data is formatted as JSON: {"signatureInfo": {"token": "<value>"}}
  final String? advancedCommerceData;
  final bool? andDangerouslyFinishTransactionAutomatically;
  final String? appAccountToken;
  final int? quantity;
  final String sku;
  final DiscountOfferInputIOS? withOffer;

  factory RequestSubscriptionIosProps.fromJson(Map<String, dynamic> json) {
    return RequestSubscriptionIosProps(
      advancedCommerceData: json['advancedCommerceData'] as String?,
      andDangerouslyFinishTransactionAutomatically: json['andDangerouslyFinishTransactionAutomatically'] as bool?,
      appAccountToken: json['appAccountToken'] as String?,
      quantity: json['quantity'] as int?,
      sku: json['sku'] as String,
      withOffer: json['withOffer'] != null ? DiscountOfferInputIOS.fromJson(json['withOffer'] as Map<String, dynamic>) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'advancedCommerceData': advancedCommerceData,
      'andDangerouslyFinishTransactionAutomatically': andDangerouslyFinishTransactionAutomatically,
      'appAccountToken': appAccountToken,
      'quantity': quantity,
      'sku': sku,
      'withOffer': withOffer?.toJson(),
    };
  }
}

/// Platform-specific subscription request parameters.
/// 
/// Note: "Platforms" refers to the SDK/OS level (apple, google), not the store.
/// - apple: Always targets App Store
/// - google: Targets Play Store by default, or Horizon when built with horizon flavor
///   (determined at build time, not runtime)
class RequestSubscriptionPropsByPlatforms {
  const RequestSubscriptionPropsByPlatforms({
    this.android,
    this.apple,
    this.google,
    this.ios,
  });

  /// @deprecated Use google instead
  final RequestSubscriptionAndroidProps? android;
  /// Apple-specific subscription parameters
  final RequestSubscriptionIosProps? apple;
  /// Google-specific subscription parameters
  final RequestSubscriptionAndroidProps? google;
  /// @deprecated Use apple instead
  final RequestSubscriptionIosProps? ios;

  factory RequestSubscriptionPropsByPlatforms.fromJson(Map<String, dynamic> json) {
    return RequestSubscriptionPropsByPlatforms(
      android: json['android'] != null ? RequestSubscriptionAndroidProps.fromJson(json['android'] as Map<String, dynamic>) : null,
      apple: json['apple'] != null ? RequestSubscriptionIosProps.fromJson(json['apple'] as Map<String, dynamic>) : null,
      google: json['google'] != null ? RequestSubscriptionAndroidProps.fromJson(json['google'] as Map<String, dynamic>) : null,
      ios: json['ios'] != null ? RequestSubscriptionIosProps.fromJson(json['ios'] as Map<String, dynamic>) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'android': android?.toJson(),
      'apple': apple?.toJson(),
      'google': google?.toJson(),
      'ios': ios?.toJson(),
    };
  }
}

class RequestVerifyPurchaseWithIapkitAppleProps {
  const RequestVerifyPurchaseWithIapkitAppleProps({
    required this.jws,
  });

  /// The JWS token returned with the purchase response.
  final String jws;

  factory RequestVerifyPurchaseWithIapkitAppleProps.fromJson(Map<String, dynamic> json) {
    return RequestVerifyPurchaseWithIapkitAppleProps(
      jws: json['jws'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'jws': jws,
    };
  }
}

class RequestVerifyPurchaseWithIapkitGoogleProps {
  const RequestVerifyPurchaseWithIapkitGoogleProps({
    required this.purchaseToken,
  });

  /// The token provided to the user's device when the product or subscription was purchased.
  final String purchaseToken;

  factory RequestVerifyPurchaseWithIapkitGoogleProps.fromJson(Map<String, dynamic> json) {
    return RequestVerifyPurchaseWithIapkitGoogleProps(
      purchaseToken: json['purchaseToken'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'purchaseToken': purchaseToken,
    };
  }
}

/// Platform-specific verification parameters for IAPKit.
/// 
/// - apple: Verifies via App Store (JWS token)
/// - google: Verifies via Play Store (purchase token)
class RequestVerifyPurchaseWithIapkitProps {
  const RequestVerifyPurchaseWithIapkitProps({
    this.apiKey,
    this.apple,
    this.google,
  });

  /// API key used for the Authorization header (Bearer {apiKey}).
  final String? apiKey;
  /// Apple App Store verification parameters.
  final RequestVerifyPurchaseWithIapkitAppleProps? apple;
  /// Google Play Store verification parameters.
  final RequestVerifyPurchaseWithIapkitGoogleProps? google;

  factory RequestVerifyPurchaseWithIapkitProps.fromJson(Map<String, dynamic> json) {
    return RequestVerifyPurchaseWithIapkitProps(
      apiKey: json['apiKey'] as String?,
      apple: json['apple'] != null ? RequestVerifyPurchaseWithIapkitAppleProps.fromJson(json['apple'] as Map<String, dynamic>) : null,
      google: json['google'] != null ? RequestVerifyPurchaseWithIapkitGoogleProps.fromJson(json['google'] as Map<String, dynamic>) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'apiKey': apiKey,
      'apple': apple?.toJson(),
      'google': google?.toJson(),
    };
  }
}

/// Product-level subscription replacement parameters (Android)
/// Used with setSubscriptionProductReplacementParams in BillingFlowParams.ProductDetailsParams
/// Available in Google Play Billing Library 8.1.0+
class SubscriptionProductReplacementParamsAndroid {
  const SubscriptionProductReplacementParamsAndroid({
    required this.oldProductId,
    required this.replacementMode,
  });

  /// The old product ID that needs to be replaced
  final String oldProductId;
  /// The replacement mode for this product change
  final SubscriptionReplacementModeAndroid replacementMode;

  factory SubscriptionProductReplacementParamsAndroid.fromJson(Map<String, dynamic> json) {
    return SubscriptionProductReplacementParamsAndroid(
      oldProductId: json['oldProductId'] as String,
      replacementMode: SubscriptionReplacementModeAndroid.fromJson(json['replacementMode'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'oldProductId': oldProductId,
      'replacementMode': replacementMode.toJson(),
    };
  }
}

/// Apple App Store verification parameters.
/// Used for server-side receipt validation via App Store Server API.
class VerifyPurchaseAppleOptions {
  const VerifyPurchaseAppleOptions({
    required this.sku,
  });

  /// Product SKU to validate
  final String sku;

  factory VerifyPurchaseAppleOptions.fromJson(Map<String, dynamic> json) {
    return VerifyPurchaseAppleOptions(
      sku: json['sku'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sku': sku,
    };
  }
}

/// Google Play Store verification parameters.
/// Used for server-side receipt validation via Google Play Developer API.
/// 
/// ⚠️ SECURITY: Contains sensitive tokens (accessToken, purchaseToken). Do not log or persist this data.
class VerifyPurchaseGoogleOptions {
  const VerifyPurchaseGoogleOptions({
    required this.accessToken,
    this.isSub,
    required this.packageName,
    required this.purchaseToken,
    required this.sku,
  });

  /// Google OAuth2 access token for API authentication.
  /// ⚠️ Sensitive: Do not log this value.
  final String accessToken;
  /// Whether this is a subscription purchase (affects API endpoint used)
  final bool? isSub;
  /// Android package name (e.g., com.example.app)
  final String packageName;
  /// Purchase token from the purchase response.
  /// ⚠️ Sensitive: Do not log this value.
  final String purchaseToken;
  /// Product SKU to validate
  final String sku;

  factory VerifyPurchaseGoogleOptions.fromJson(Map<String, dynamic> json) {
    return VerifyPurchaseGoogleOptions(
      accessToken: json['accessToken'] as String,
      isSub: json['isSub'] as bool?,
      packageName: json['packageName'] as String,
      purchaseToken: json['purchaseToken'] as String,
      sku: json['sku'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'isSub': isSub,
      'packageName': packageName,
      'purchaseToken': purchaseToken,
      'sku': sku,
    };
  }
}

/// Meta Horizon (Quest) verification parameters.
/// Used for server-side entitlement verification via Meta's S2S API.
/// POST https://graph.oculus.com/$APP_ID/verify_entitlement
/// 
/// ⚠️ SECURITY: Contains sensitive token (accessToken). Do not log or persist this data.
class VerifyPurchaseHorizonOptions {
  const VerifyPurchaseHorizonOptions({
    required this.accessToken,
    required this.sku,
    required this.userId,
  });

  /// Access token for Meta API authentication (OC|$APP_ID|$APP_SECRET or User Access Token).
  /// ⚠️ Sensitive: Do not log this value.
  final String accessToken;
  /// The SKU for the add-on item, defined in Meta Developer Dashboard
  final String sku;
  /// The user ID of the user whose purchase you want to verify
  final String userId;

  factory VerifyPurchaseHorizonOptions.fromJson(Map<String, dynamic> json) {
    return VerifyPurchaseHorizonOptions(
      accessToken: json['accessToken'] as String,
      sku: json['sku'] as String,
      userId: json['userId'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'sku': sku,
      'userId': userId,
    };
  }
}

/// Platform-specific purchase verification parameters.
/// 
/// - apple: Verifies via App Store Server API
/// - google: Verifies via Google Play Developer API
/// - horizon: Verifies via Meta's S2S API (verify_entitlement endpoint)
class VerifyPurchaseProps {
  const VerifyPurchaseProps({
    this.apple,
    this.google,
    this.horizon,
  });

  /// Apple App Store verification parameters.
  final VerifyPurchaseAppleOptions? apple;
  /// Google Play Store verification parameters.
  final VerifyPurchaseGoogleOptions? google;
  /// Meta Horizon (Quest) verification parameters.
  final VerifyPurchaseHorizonOptions? horizon;

  factory VerifyPurchaseProps.fromJson(Map<String, dynamic> json) {
    return VerifyPurchaseProps(
      apple: json['apple'] != null ? VerifyPurchaseAppleOptions.fromJson(json['apple'] as Map<String, dynamic>) : null,
      google: json['google'] != null ? VerifyPurchaseGoogleOptions.fromJson(json['google'] as Map<String, dynamic>) : null,
      horizon: json['horizon'] != null ? VerifyPurchaseHorizonOptions.fromJson(json['horizon'] as Map<String, dynamic>) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'apple': apple?.toJson(),
      'google': google?.toJson(),
      'horizon': horizon?.toJson(),
    };
  }
}

class VerifyPurchaseWithProviderProps {
  const VerifyPurchaseWithProviderProps({
    this.iapkit,
    required this.provider,
  });

  final RequestVerifyPurchaseWithIapkitProps? iapkit;
  final PurchaseVerificationProvider provider;

  factory VerifyPurchaseWithProviderProps.fromJson(Map<String, dynamic> json) {
    return VerifyPurchaseWithProviderProps(
      iapkit: json['iapkit'] != null ? RequestVerifyPurchaseWithIapkitProps.fromJson(json['iapkit'] as Map<String, dynamic>) : null,
      provider: PurchaseVerificationProvider.fromJson(json['provider'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'iapkit': iapkit?.toJson(),
      'provider': provider.toJson(),
    };
  }
}

// MARK: - Unions

sealed class Product implements ProductCommon {
  const Product();

  factory Product.fromJson(Map<String, dynamic> json) {
    final typeName = json['__typename'] as String?;
    switch (typeName) {
      case 'ProductAndroid':
        return ProductAndroid.fromJson(json);
      case 'ProductIOS':
        return ProductIOS.fromJson(json);
    }
    throw ArgumentError('Unknown __typename for Product: $typeName');
  }

  @override
  String get currency;
  @override
  String? get debugDescription;
  @override
  String get description;
  @override
  String? get displayName;
  @override
  String get displayPrice;
  @override
  String get id;
  @override
  IapPlatform get platform;
  @override
  double? get price;
  @override
  String get title;
  @override
  ProductType get type;

  Map<String, dynamic> toJson();
}

sealed class ProductOrSubscription {
  const ProductOrSubscription();

  factory ProductOrSubscription.fromJson(Map<String, dynamic> json) {
    final typeName = json['__typename'] as String?;
    switch (typeName) {
      case 'ProductAndroid':
        return ProductOrSubscriptionProduct(Product.fromJson(json));
      case 'ProductIOS':
        return ProductOrSubscriptionProduct(Product.fromJson(json));
      case 'ProductSubscriptionAndroid':
        return ProductOrSubscriptionProductSubscription(ProductSubscription.fromJson(json));
      case 'ProductSubscriptionIOS':
        return ProductOrSubscriptionProductSubscription(ProductSubscription.fromJson(json));
    }
    throw ArgumentError('Unknown __typename for ProductOrSubscription: $typeName');
  }

  Map<String, dynamic> toJson();
}

class ProductOrSubscriptionProduct extends ProductOrSubscription {
  const ProductOrSubscriptionProduct(this.value);
  final Product value;

  @override
  Map<String, dynamic> toJson() => value.toJson();
}

class ProductOrSubscriptionProductSubscription extends ProductOrSubscription {
  const ProductOrSubscriptionProductSubscription(this.value);
  final ProductSubscription value;

  @override
  Map<String, dynamic> toJson() => value.toJson();
}

sealed class ProductSubscription implements ProductCommon {
  const ProductSubscription();

  factory ProductSubscription.fromJson(Map<String, dynamic> json) {
    final typeName = json['__typename'] as String?;
    switch (typeName) {
      case 'ProductSubscriptionAndroid':
        return ProductSubscriptionAndroid.fromJson(json);
      case 'ProductSubscriptionIOS':
        return ProductSubscriptionIOS.fromJson(json);
    }
    throw ArgumentError('Unknown __typename for ProductSubscription: $typeName');
  }

  @override
  String get currency;
  @override
  String? get debugDescription;
  @override
  String get description;
  @override
  String? get displayName;
  @override
  String get displayPrice;
  @override
  String get id;
  @override
  IapPlatform get platform;
  @override
  double? get price;
  @override
  String get title;
  @override
  ProductType get type;

  Map<String, dynamic> toJson();
}

sealed class Purchase implements PurchaseCommon {
  const Purchase();

  factory Purchase.fromJson(Map<String, dynamic> json) {
    final typeName = json['__typename'] as String?;
    switch (typeName) {
      case 'PurchaseAndroid':
        return PurchaseAndroid.fromJson(json);
      case 'PurchaseIOS':
        return PurchaseIOS.fromJson(json);
    }
    throw ArgumentError('Unknown __typename for Purchase: $typeName');
  }

  /// The current plan identifier. This is:
  /// - On Android: the basePlanId (e.g., "premium", "premium-year")
  /// - On iOS: the productId (e.g., "com.example.premium_monthly", "com.example.premium_yearly")
  /// This provides a unified way to identify which specific plan/tier the user is subscribed to.
  @override
  String? get currentPlanId;
  @override
  String get id;
  @override
  List<String>? get ids;
  @override
  bool get isAutoRenewing;
  @override
  IapPlatform get platform;
  @override
  String get productId;
  @override
  PurchaseState get purchaseState;
  /// Unified purchase token (iOS JWS, Android purchaseToken)
  @override
  String? get purchaseToken;
  @override
  int get quantity;
  /// Store where purchase was made
  @override
  IapStore get store;
  @override
  double get transactionDate;

  Map<String, dynamic> toJson();
}

sealed class VerifyPurchaseResult {
  const VerifyPurchaseResult();

  factory VerifyPurchaseResult.fromJson(Map<String, dynamic> json) {
    final typeName = json['__typename'] as String?;
    switch (typeName) {
      case 'VerifyPurchaseResultAndroid':
        return VerifyPurchaseResultAndroid.fromJson(json);
      case 'VerifyPurchaseResultHorizon':
        return VerifyPurchaseResultHorizon.fromJson(json);
      case 'VerifyPurchaseResultIOS':
        return VerifyPurchaseResultIOS.fromJson(json);
    }
    throw ArgumentError('Unknown __typename for VerifyPurchaseResult: $typeName');
  }

  Map<String, dynamic> toJson();
}

// MARK: - Root Operations

/// GraphQL root mutation operations.
abstract class MutationResolver {
  /// Acknowledge a non-consumable purchase or subscription
  Future<bool> acknowledgePurchaseAndroid(String purchaseToken);
  /// Initiate a refund request for a product (iOS 15+)
  Future<String?> beginRefundRequestIOS(String sku);
  /// Check if alternative billing is available for this user/device
  /// Step 1 of alternative billing flow
  /// 
  /// Returns true if available, false otherwise
  /// Throws OpenIapError.NotPrepared if billing client not ready
  Future<bool> checkAlternativeBillingAvailabilityAndroid();
  /// Clear pending transactions from the StoreKit payment queue
  Future<bool> clearTransactionIOS();
  /// Consume a purchase token so it can be repurchased
  Future<bool> consumePurchaseAndroid(String purchaseToken);
  /// Create external transaction token for Google Play reporting
  /// Step 3 of alternative billing flow
  /// Must be called AFTER successful payment in your payment system
  /// Token must be reported to Google Play backend within 24 hours
  /// 
  /// Returns token string, or null if creation failed
  /// Throws OpenIapError.NotPrepared if billing client not ready
  Future<String?> createAlternativeBillingTokenAndroid();
  /// Create reporting details for a billing program
  /// Replaces the deprecated createExternalOfferReportingDetailsAsync API
  /// 
  /// Available in Google Play Billing Library 8.2.0+
  /// Returns external transaction token needed for reporting external transactions
  /// Throws OpenIapError.NotPrepared if billing client not ready
  Future<BillingProgramReportingDetailsAndroid> createBillingProgramReportingDetailsAndroid(BillingProgramAndroid program);
  /// Open the native subscription management surface
  Future<void> deepLinkToSubscriptions({
    String? packageNameAndroid,
    String? skuAndroid,
  });
  /// Close the platform billing connection
  Future<bool> endConnection();
  /// Finish a transaction after validating receipts
  Future<void> finishTransaction({
    required PurchaseInput purchase,
    bool? isConsumable,
  });
  /// Establish the platform billing connection
  Future<bool> initConnection({
    AlternativeBillingModeAndroid? alternativeBillingModeAndroid,
    BillingProgramAndroid? enableBillingProgramAndroid,
  });
  /// Check if a billing program is available for the current user
  /// Replaces the deprecated isExternalOfferAvailableAsync API
  /// 
  /// Available in Google Play Billing Library 8.2.0+
  /// Returns availability result with isAvailable flag
  /// Throws OpenIapError.NotPrepared if billing client not ready
  Future<BillingProgramAvailabilityResultAndroid> isBillingProgramAvailableAndroid(BillingProgramAndroid program);
  /// Launch external link flow for external billing programs
  /// Replaces the deprecated showExternalOfferInformationDialog API
  /// 
  /// Available in Google Play Billing Library 8.2.0+
  /// Shows Play Store dialog and optionally launches external URL
  /// Throws OpenIapError.NotPrepared if billing client not ready
  Future<bool> launchExternalLinkAndroid({
    required BillingProgramAndroid billingProgram,
    required ExternalLinkLaunchModeAndroid launchMode,
    required ExternalLinkTypeAndroid linkType,
    required String linkUri,
  });
  /// Present the App Store code redemption sheet
  Future<bool> presentCodeRedemptionSheetIOS();
  /// Present external purchase custom link with StoreKit UI (iOS 18.2+)
  Future<ExternalPurchaseLinkResultIOS> presentExternalPurchaseLinkIOS(String url);
  /// Present external purchase notice sheet (iOS 18.2+)
  Future<ExternalPurchaseNoticeResultIOS> presentExternalPurchaseNoticeSheetIOS();
  /// Initiate a purchase flow; rely on events for final state
  Future<RequestPurchaseResult?> requestPurchase(RequestPurchaseProps params);
  /// Purchase the promoted product surfaced by the App Store.
  /// 
  /// @deprecated Use promotedProductListenerIOS to receive the productId,
  /// then call requestPurchase with that SKU instead. In StoreKit 2,
  /// promoted products can be purchased directly via the standard purchase flow.
  Future<bool> requestPurchaseOnPromotedProductIOS();
  /// Restore completed purchases across platforms
  Future<void> restorePurchases();
  /// Show alternative billing information dialog to user
  /// Step 2 of alternative billing flow
  /// Must be called BEFORE processing payment in your payment system
  /// 
  /// Returns true if user accepted, false if user canceled
  /// Throws OpenIapError.NotPrepared if billing client not ready
  Future<bool> showAlternativeBillingDialogAndroid();
  /// Open subscription management UI and return changed purchases (iOS 15+)
  Future<List<PurchaseIOS>> showManageSubscriptionsIOS();
  /// Force a StoreKit sync for transactions (iOS 15+)
  Future<bool> syncIOS();
  /// Validate purchase receipts with the configured providers
  Future<VerifyPurchaseResult> validateReceipt({
    VerifyPurchaseAppleOptions? apple,
    VerifyPurchaseGoogleOptions? google,
    VerifyPurchaseHorizonOptions? horizon,
  });
  /// Verify purchases with the configured providers
  Future<VerifyPurchaseResult> verifyPurchase({
    VerifyPurchaseAppleOptions? apple,
    VerifyPurchaseGoogleOptions? google,
    VerifyPurchaseHorizonOptions? horizon,
  });
  /// Verify purchases with a specific provider (e.g., IAPKit)
  Future<VerifyPurchaseWithProviderResult> verifyPurchaseWithProvider({
    RequestVerifyPurchaseWithIapkitProps? iapkit,
    required PurchaseVerificationProvider provider,
  });
}

/// GraphQL root query operations.
abstract class QueryResolver {
  /// Check if external purchase notice sheet can be presented (iOS 18.2+)
  Future<bool> canPresentExternalPurchaseNoticeIOS();
  /// Get current StoreKit 2 entitlements (iOS 15+)
  Future<PurchaseIOS?> currentEntitlementIOS(String sku);
  /// Retrieve products or subscriptions from the store
  Future<FetchProductsResult> fetchProducts({
    required List<String> skus,
    ProductQueryType? type,
  });
  /// Get active subscriptions (filters by subscriptionIds when provided)
  Future<List<ActiveSubscription>> getActiveSubscriptions([List<String>? subscriptionIds]);
  /// Fetch the current app transaction (iOS 16+)
  Future<AppTransaction?> getAppTransactionIOS();
  /// Get all available purchases for the current user
  Future<List<Purchase>> getAvailablePurchases({
    bool? alsoPublishToEventListenerIOS,
    bool? onlyIncludeActiveItemsIOS,
  });
  /// Retrieve all pending transactions in the StoreKit queue
  Future<List<PurchaseIOS>> getPendingTransactionsIOS();
  /// Get the currently promoted product (iOS 11+)
  Future<ProductIOS?> getPromotedProductIOS();
  /// Get base64-encoded receipt data for validation
  Future<String?> getReceiptDataIOS();
  /// Get the current storefront country code
  Future<String> getStorefront();
  /// Get the current App Store storefront country code
  Future<String> getStorefrontIOS();
  /// Get the transaction JWS (StoreKit 2)
  Future<String?> getTransactionJwsIOS(String sku);
  /// Check whether the user has active subscriptions
  Future<bool> hasActiveSubscriptions([List<String>? subscriptionIds]);
  /// Check introductory offer eligibility for a subscription group
  Future<bool> isEligibleForIntroOfferIOS(String groupID);
  /// Verify a StoreKit 2 transaction signature
  Future<bool> isTransactionVerifiedIOS(String sku);
  /// Get the latest transaction for a product using StoreKit 2
  Future<PurchaseIOS?> latestTransactionIOS(String sku);
  /// Get StoreKit 2 subscription status details (iOS 15+)
  Future<List<SubscriptionStatusIOS>> subscriptionStatusIOS(String sku);
  /// Validate a receipt for a specific product
  Future<VerifyPurchaseResultIOS> validateReceiptIOS({
    VerifyPurchaseAppleOptions? apple,
    VerifyPurchaseGoogleOptions? google,
    VerifyPurchaseHorizonOptions? horizon,
  });
}

/// GraphQL root subscription operations.
abstract class SubscriptionResolver {
  /// Fires when a user selects developer billing in the External Payments flow (Android only)
  /// Triggered when the user chooses to pay via the developer's external payment option
  /// instead of Google Play Billing in the side-by-side choice dialog.
  /// Contains the externalTransactionToken needed to report the transaction.
  /// Available in Google Play Billing Library 8.3.0+
  Future<DeveloperProvidedBillingDetailsAndroid> developerProvidedBillingAndroid();
  /// Fires when the App Store surfaces a promoted product (iOS only)
  Future<String> promotedProductIOS();
  /// Fires when a purchase fails or is cancelled
  Future<PurchaseError> purchaseError();
  /// Fires when a purchase completes successfully or a pending purchase resolves
  Future<Purchase> purchaseUpdated();
  /// Fires when a user selects alternative billing in the User Choice Billing dialog (Android only)
  /// Only triggered when the user selects alternative billing instead of Google Play billing
  Future<UserChoiceBillingDetails> userChoiceBillingAndroid();
}

// MARK: - Root Operation Helpers

// MARK: - Mutation Helpers

typedef MutationAcknowledgePurchaseAndroidHandler = Future<bool> Function(String purchaseToken);
typedef MutationBeginRefundRequestIOSHandler = Future<String?> Function(String sku);
typedef MutationCheckAlternativeBillingAvailabilityAndroidHandler = Future<bool> Function();
typedef MutationClearTransactionIOSHandler = Future<bool> Function();
typedef MutationConsumePurchaseAndroidHandler = Future<bool> Function(String purchaseToken);
typedef MutationCreateAlternativeBillingTokenAndroidHandler = Future<String?> Function();
typedef MutationCreateBillingProgramReportingDetailsAndroidHandler = Future<BillingProgramReportingDetailsAndroid> Function(BillingProgramAndroid program);
typedef MutationDeepLinkToSubscriptionsHandler = Future<void> Function({
  String? packageNameAndroid,
  String? skuAndroid,
});
typedef MutationEndConnectionHandler = Future<bool> Function();
typedef MutationFinishTransactionHandler = Future<void> Function({
  required PurchaseInput purchase,
  bool? isConsumable,
});
typedef MutationInitConnectionHandler = Future<bool> Function({
  AlternativeBillingModeAndroid? alternativeBillingModeAndroid,
  BillingProgramAndroid? enableBillingProgramAndroid,
});
typedef MutationIsBillingProgramAvailableAndroidHandler = Future<BillingProgramAvailabilityResultAndroid> Function(BillingProgramAndroid program);
typedef MutationLaunchExternalLinkAndroidHandler = Future<bool> Function({
  required BillingProgramAndroid billingProgram,
  required ExternalLinkLaunchModeAndroid launchMode,
  required ExternalLinkTypeAndroid linkType,
  required String linkUri,
});
typedef MutationPresentCodeRedemptionSheetIOSHandler = Future<bool> Function();
typedef MutationPresentExternalPurchaseLinkIOSHandler = Future<ExternalPurchaseLinkResultIOS> Function(String url);
typedef MutationPresentExternalPurchaseNoticeSheetIOSHandler = Future<ExternalPurchaseNoticeResultIOS> Function();
typedef MutationRequestPurchaseHandler = Future<RequestPurchaseResult?> Function(RequestPurchaseProps params);
typedef MutationRequestPurchaseOnPromotedProductIOSHandler = Future<bool> Function();
typedef MutationRestorePurchasesHandler = Future<void> Function();
typedef MutationShowAlternativeBillingDialogAndroidHandler = Future<bool> Function();
typedef MutationShowManageSubscriptionsIOSHandler = Future<List<PurchaseIOS>> Function();
typedef MutationSyncIOSHandler = Future<bool> Function();
typedef MutationValidateReceiptHandler = Future<VerifyPurchaseResult> Function({
  VerifyPurchaseAppleOptions? apple,
  VerifyPurchaseGoogleOptions? google,
  VerifyPurchaseHorizonOptions? horizon,
});
typedef MutationVerifyPurchaseHandler = Future<VerifyPurchaseResult> Function({
  VerifyPurchaseAppleOptions? apple,
  VerifyPurchaseGoogleOptions? google,
  VerifyPurchaseHorizonOptions? horizon,
});
typedef MutationVerifyPurchaseWithProviderHandler = Future<VerifyPurchaseWithProviderResult> Function({
  RequestVerifyPurchaseWithIapkitProps? iapkit,
  required PurchaseVerificationProvider provider,
});

class MutationHandlers {
  const MutationHandlers({
    this.acknowledgePurchaseAndroid,
    this.beginRefundRequestIOS,
    this.checkAlternativeBillingAvailabilityAndroid,
    this.clearTransactionIOS,
    this.consumePurchaseAndroid,
    this.createAlternativeBillingTokenAndroid,
    this.createBillingProgramReportingDetailsAndroid,
    this.deepLinkToSubscriptions,
    this.endConnection,
    this.finishTransaction,
    this.initConnection,
    this.isBillingProgramAvailableAndroid,
    this.launchExternalLinkAndroid,
    this.presentCodeRedemptionSheetIOS,
    this.presentExternalPurchaseLinkIOS,
    this.presentExternalPurchaseNoticeSheetIOS,
    this.requestPurchase,
    this.requestPurchaseOnPromotedProductIOS,
    this.restorePurchases,
    this.showAlternativeBillingDialogAndroid,
    this.showManageSubscriptionsIOS,
    this.syncIOS,
    this.validateReceipt,
    this.verifyPurchase,
    this.verifyPurchaseWithProvider,
  });

  final MutationAcknowledgePurchaseAndroidHandler? acknowledgePurchaseAndroid;
  final MutationBeginRefundRequestIOSHandler? beginRefundRequestIOS;
  final MutationCheckAlternativeBillingAvailabilityAndroidHandler? checkAlternativeBillingAvailabilityAndroid;
  final MutationClearTransactionIOSHandler? clearTransactionIOS;
  final MutationConsumePurchaseAndroidHandler? consumePurchaseAndroid;
  final MutationCreateAlternativeBillingTokenAndroidHandler? createAlternativeBillingTokenAndroid;
  final MutationCreateBillingProgramReportingDetailsAndroidHandler? createBillingProgramReportingDetailsAndroid;
  final MutationDeepLinkToSubscriptionsHandler? deepLinkToSubscriptions;
  final MutationEndConnectionHandler? endConnection;
  final MutationFinishTransactionHandler? finishTransaction;
  final MutationInitConnectionHandler? initConnection;
  final MutationIsBillingProgramAvailableAndroidHandler? isBillingProgramAvailableAndroid;
  final MutationLaunchExternalLinkAndroidHandler? launchExternalLinkAndroid;
  final MutationPresentCodeRedemptionSheetIOSHandler? presentCodeRedemptionSheetIOS;
  final MutationPresentExternalPurchaseLinkIOSHandler? presentExternalPurchaseLinkIOS;
  final MutationPresentExternalPurchaseNoticeSheetIOSHandler? presentExternalPurchaseNoticeSheetIOS;
  final MutationRequestPurchaseHandler? requestPurchase;
  final MutationRequestPurchaseOnPromotedProductIOSHandler? requestPurchaseOnPromotedProductIOS;
  final MutationRestorePurchasesHandler? restorePurchases;
  final MutationShowAlternativeBillingDialogAndroidHandler? showAlternativeBillingDialogAndroid;
  final MutationShowManageSubscriptionsIOSHandler? showManageSubscriptionsIOS;
  final MutationSyncIOSHandler? syncIOS;
  final MutationValidateReceiptHandler? validateReceipt;
  final MutationVerifyPurchaseHandler? verifyPurchase;
  final MutationVerifyPurchaseWithProviderHandler? verifyPurchaseWithProvider;
}

// MARK: - Query Helpers

typedef QueryCanPresentExternalPurchaseNoticeIOSHandler = Future<bool> Function();
typedef QueryCurrentEntitlementIOSHandler = Future<PurchaseIOS?> Function(String sku);
typedef QueryFetchProductsHandler = Future<FetchProductsResult> Function({
  required List<String> skus,
  ProductQueryType? type,
});
typedef QueryGetActiveSubscriptionsHandler = Future<List<ActiveSubscription>> Function([List<String>? subscriptionIds]);
typedef QueryGetAppTransactionIOSHandler = Future<AppTransaction?> Function();
typedef QueryGetAvailablePurchasesHandler = Future<List<Purchase>> Function({
  bool? alsoPublishToEventListenerIOS,
  bool? onlyIncludeActiveItemsIOS,
});
typedef QueryGetPendingTransactionsIOSHandler = Future<List<PurchaseIOS>> Function();
typedef QueryGetPromotedProductIOSHandler = Future<ProductIOS?> Function();
typedef QueryGetReceiptDataIOSHandler = Future<String?> Function();
typedef QueryGetStorefrontHandler = Future<String> Function();
typedef QueryGetStorefrontIOSHandler = Future<String> Function();
typedef QueryGetTransactionJwsIOSHandler = Future<String?> Function(String sku);
typedef QueryHasActiveSubscriptionsHandler = Future<bool> Function([List<String>? subscriptionIds]);
typedef QueryIsEligibleForIntroOfferIOSHandler = Future<bool> Function(String groupID);
typedef QueryIsTransactionVerifiedIOSHandler = Future<bool> Function(String sku);
typedef QueryLatestTransactionIOSHandler = Future<PurchaseIOS?> Function(String sku);
typedef QuerySubscriptionStatusIOSHandler = Future<List<SubscriptionStatusIOS>> Function(String sku);
typedef QueryValidateReceiptIOSHandler = Future<VerifyPurchaseResultIOS> Function({
  VerifyPurchaseAppleOptions? apple,
  VerifyPurchaseGoogleOptions? google,
  VerifyPurchaseHorizonOptions? horizon,
});

class QueryHandlers {
  const QueryHandlers({
    this.canPresentExternalPurchaseNoticeIOS,
    this.currentEntitlementIOS,
    this.fetchProducts,
    this.getActiveSubscriptions,
    this.getAppTransactionIOS,
    this.getAvailablePurchases,
    this.getPendingTransactionsIOS,
    this.getPromotedProductIOS,
    this.getReceiptDataIOS,
    this.getStorefront,
    this.getStorefrontIOS,
    this.getTransactionJwsIOS,
    this.hasActiveSubscriptions,
    this.isEligibleForIntroOfferIOS,
    this.isTransactionVerifiedIOS,
    this.latestTransactionIOS,
    this.subscriptionStatusIOS,
    this.validateReceiptIOS,
  });

  final QueryCanPresentExternalPurchaseNoticeIOSHandler? canPresentExternalPurchaseNoticeIOS;
  final QueryCurrentEntitlementIOSHandler? currentEntitlementIOS;
  final QueryFetchProductsHandler? fetchProducts;
  final QueryGetActiveSubscriptionsHandler? getActiveSubscriptions;
  final QueryGetAppTransactionIOSHandler? getAppTransactionIOS;
  final QueryGetAvailablePurchasesHandler? getAvailablePurchases;
  final QueryGetPendingTransactionsIOSHandler? getPendingTransactionsIOS;
  final QueryGetPromotedProductIOSHandler? getPromotedProductIOS;
  final QueryGetReceiptDataIOSHandler? getReceiptDataIOS;
  final QueryGetStorefrontHandler? getStorefront;
  final QueryGetStorefrontIOSHandler? getStorefrontIOS;
  final QueryGetTransactionJwsIOSHandler? getTransactionJwsIOS;
  final QueryHasActiveSubscriptionsHandler? hasActiveSubscriptions;
  final QueryIsEligibleForIntroOfferIOSHandler? isEligibleForIntroOfferIOS;
  final QueryIsTransactionVerifiedIOSHandler? isTransactionVerifiedIOS;
  final QueryLatestTransactionIOSHandler? latestTransactionIOS;
  final QuerySubscriptionStatusIOSHandler? subscriptionStatusIOS;
  final QueryValidateReceiptIOSHandler? validateReceiptIOS;
}

// MARK: - Subscription Helpers

typedef SubscriptionDeveloperProvidedBillingAndroidHandler = Future<DeveloperProvidedBillingDetailsAndroid> Function();
typedef SubscriptionPromotedProductIOSHandler = Future<String> Function();
typedef SubscriptionPurchaseErrorHandler = Future<PurchaseError> Function();
typedef SubscriptionPurchaseUpdatedHandler = Future<Purchase> Function();
typedef SubscriptionUserChoiceBillingAndroidHandler = Future<UserChoiceBillingDetails> Function();

class SubscriptionHandlers {
  const SubscriptionHandlers({
    this.developerProvidedBillingAndroid,
    this.promotedProductIOS,
    this.purchaseError,
    this.purchaseUpdated,
    this.userChoiceBillingAndroid,
  });

  final SubscriptionDeveloperProvidedBillingAndroidHandler? developerProvidedBillingAndroid;
  final SubscriptionPromotedProductIOSHandler? promotedProductIOS;
  final SubscriptionPurchaseErrorHandler? purchaseError;
  final SubscriptionPurchaseUpdatedHandler? purchaseUpdated;
  final SubscriptionUserChoiceBillingAndroidHandler? userChoiceBillingAndroid;
}
