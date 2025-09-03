import 'types.dart';
import 'enums.dart';

// ============================================================================
// ADDITIONAL TYPES
// ============================================================================

/// App Transaction information (iOS 16.0+)
class AppTransaction {
  final String? appAppleId;
  final String? bundleId;
  final String? originalAppVersion;
  final String? originalPurchaseDate;
  final String? deviceVerification;
  final String? deviceVerificationNonce;

  AppTransaction({
    this.appAppleId,
    this.bundleId,
    this.originalAppVersion,
    this.originalPurchaseDate,
    this.deviceVerification,
    this.deviceVerificationNonce,
  });

  factory AppTransaction.fromJson(Map<String, dynamic> json) {
    return AppTransaction(
      appAppleId: json['appAppleId'] as String?,
      bundleId: json['bundleId'] as String?,
      originalAppVersion: json['originalAppVersion'] as String?,
      originalPurchaseDate: json['originalPurchaseDate'] as String?,
      deviceVerification: json['deviceVerification'] as String?,
      deviceVerificationNonce: json['deviceVerificationNonce'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (appAppleId != null) 'appAppleId': appAppleId,
      if (bundleId != null) 'bundleId': bundleId,
      if (originalAppVersion != null) 'originalAppVersion': originalAppVersion,
      if (originalPurchaseDate != null)
        'originalPurchaseDate': originalPurchaseDate,
      if (deviceVerification != null) 'deviceVerification': deviceVerification,
      if (deviceVerificationNonce != null)
        'deviceVerificationNonce': deviceVerificationNonce,
    };
  }
}

/// Subscription purchase information
class SubscriptionPurchase extends Purchase {
  final bool isActive;
  final DateTime? expirationDate;
  final String? subscriptionGroupId;
  final bool? isInTrialPeriod;
  final bool? isInIntroOfferPeriod;
  final String? subscriptionPeriod;

  SubscriptionPurchase({
    required super.productId,
    required this.isActive, // Platform
    required super.platform,
    super.transactionId,
    super.transactionDate,
    super.transactionReceipt,
    super.purchaseToken,
    this.expirationDate,
    this.subscriptionGroupId,
    this.isInTrialPeriod,
    this.isInIntroOfferPeriod,
    this.subscriptionPeriod,
    // iOS specific
    super.transactionStateIOS,
    super.originalTransactionIdentifierIOS,
    super.originalTransactionDateIOS,
    super.quantityIOS,
    super.environmentIOS,
    super.expirationDateIOS,
    // Android specific
    super.isAcknowledgedAndroid,
    super.purchaseStateAndroid,
    super.signatureAndroid,
    super.originalJson,
    super.packageNameAndroid,
    super.autoRenewingAndroid,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'productId': productId,
      'isActive': isActive,
      if (transactionId != null) 'transactionId': transactionId,
      if (transactionDate != null) 'transactionDate': transactionDate,
      if (transactionReceipt != null) 'transactionReceipt': transactionReceipt,
      if (purchaseToken != null) 'purchaseToken': purchaseToken,
      if (expirationDate != null)
        'expirationDate': expirationDate!.toIso8601String(),
      if (subscriptionGroupId != null)
        'subscriptionGroupId': subscriptionGroupId,
      if (isInTrialPeriod != null) 'isInTrialPeriod': isInTrialPeriod,
      if (isInIntroOfferPeriod != null)
        'isInIntroOfferPeriod': isInIntroOfferPeriod,
      if (subscriptionPeriod != null) 'subscriptionPeriod': subscriptionPeriod,
      'platform': platform.name,
    };
    return json;
  }
}

/// Active subscription information (OpenIAP compliant)
/// Used by getActiveSubscriptions() and hasActiveSubscriptions()
class ActiveSubscription {
  /// Product identifier
  final String productId;

  /// Always true for active subscriptions
  final bool isActive;

  /// Subscription expiration date (iOS only)
  final DateTime? expirationDateIOS;

  /// Auto-renewal status (Android only)
  final bool? autoRenewingAndroid;

  /// Environment: 'Sandbox' | 'Production' (iOS only)
  final String? environmentIOS;

  /// True if subscription expires within 7 days
  final bool? willExpireSoon;

  /// Days remaining until expiration (iOS only)
  final int? daysUntilExpirationIOS;

  ActiveSubscription({
    required this.productId,
    required this.isActive,
    this.expirationDateIOS,
    this.autoRenewingAndroid,
    this.environmentIOS,
    this.willExpireSoon,
    this.daysUntilExpirationIOS,
  });

  /// Creates ActiveSubscription from a Purchase or SubscriptionPurchase
  factory ActiveSubscription.fromPurchase(Purchase purchase) {
    DateTime? expirationDate;
    bool? willExpireSoon;
    int? daysUntilExpiration;

    // Get expiration date for iOS
    if (purchase.platform == IapPlatform.ios) {
      expirationDate = purchase.expirationDateIOS;

      // Calculate days until expiration and willExpireSoon
      if (expirationDate != null) {
        final now = DateTime.now();
        final difference = expirationDate.difference(now);
        daysUntilExpiration = difference.inDays;
        willExpireSoon = daysUntilExpiration <= 7;
      }
    }

    return ActiveSubscription(
      productId: purchase.productId,
      isActive: true, // Only active subscriptions are returned
      expirationDateIOS: expirationDate,
      autoRenewingAndroid: purchase.autoRenewingAndroid,
      environmentIOS: purchase.environmentIOS,
      willExpireSoon: willExpireSoon,
      daysUntilExpirationIOS: daysUntilExpiration,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'isActive': isActive,
      if (expirationDateIOS != null)
        'expirationDateIOS': expirationDateIOS!.toIso8601String(),
      if (autoRenewingAndroid != null)
        'autoRenewingAndroid': autoRenewingAndroid,
      if (environmentIOS != null) 'environmentIOS': environmentIOS,
      if (willExpireSoon != null) 'willExpireSoon': willExpireSoon,
      if (daysUntilExpirationIOS != null)
        'daysUntilExpirationIOS': daysUntilExpirationIOS,
    };
  }
}

/// iOS-specific purchase class
class PurchaseIOS extends Purchase {
  @override
  final DateTime? expirationDateIOS;

  PurchaseIOS({
    required super.productId,
    super.transactionId,
    super.transactionDate,
    super.transactionReceipt,
    super.purchaseToken,
    this.expirationDateIOS,
    // Add other fields from Purchase parent class
    super.transactionStateIOS,
    super.originalTransactionIdentifierIOS,
    super.originalTransactionDateIOS,
    super.quantityIOS,
  }) : super(platform: IapPlatform.ios);
}
