---
title: Core Methods
sidebar_position: 3
---

import IapKitBanner from "@site/src/uis/IapKitBanner";
import IapKitLink from "@site/src/uis/IapKitLink";

# Core Methods

<IapKitBanner />

Essential methods for implementing in-app purchases with flutter_inapp_purchase v7.0. All methods follow the OpenIAP specification and support both iOS and Android platforms.

All methods are available through the singleton instance:

```dart
final iap = FlutterInappPurchase.instance;
```

## Event Streams

### purchaseUpdatedListener

Stream that emits successful purchases.

```dart
Stream<Purchase> get purchaseUpdatedListener
```

**Example**:

```dart
StreamSubscription? _purchaseUpdatedSubscription;

_purchaseUpdatedSubscription = iap.purchaseUpdatedListener.listen(
  (purchase) {
    debugPrint('Purchase received: ${purchase.productId}');
    _handlePurchase(purchase);
  },
);

// Don't forget to cancel in dispose
@override
void dispose() {
  _purchaseUpdatedSubscription?.cancel();
  super.dispose();
}
```

### purchaseErrorListener

Stream that emits purchase errors.

```dart
Stream<PurchaseError> get purchaseErrorListener
```

**Example**:

```dart
StreamSubscription? _purchaseErrorSubscription;

_purchaseErrorSubscription = iap.purchaseErrorListener.listen(
  (error) {
    debugPrint('Purchase error: ${error.code} - ${error.message}');
    _handleError(error);
  },
);
```

## Connection Management

### initConnection()

Initializes the connection to the platform store.

```dart
Future<bool> initConnection({
  AlternativeBillingModeAndroid? alternativeBillingModeAndroid,
}) async
```

**Parameters**:
- `alternativeBillingModeAndroid` - Android alternative billing mode (optional)

**Returns**: `true` if initialization successful

**Example**:

```dart
try {
  await iap.initConnection();
  debugPrint('IAP connection initialized');
} catch (e) {
  debugPrint('Failed to initialize IAP: $e');
}
```

**Platform Differences**:
- **iOS**: Connects to StoreKit 2 (iOS 15+) or StoreKit 1 (fallback)
- **Android**: Connects to Google Play Billing Library v6+

### endConnection()

Ends the connection to the platform store.

```dart
Future<bool> endConnection() async
```

**Returns**: `true` if connection ended successfully

**Example**:

```dart
await iap.endConnection();
```

## Product Loading

### fetchProducts()

Loads product information from the store.

```dart
Future<FetchProductsResult> fetchProducts({
  required List<String> skus,
  ProductQueryType? type,
}) async
```

**Parameters**:
- `skus` - List of product identifiers
- `type` - Optional `ProductQueryType.InApp` or `ProductQueryType.Subs`

**Returns**: `FetchProductsResult` - union type containing either products or subscriptions

**Example**:

```dart
final result = await iap.fetchProducts(
  skus: ['product_1', 'premium_upgrade'],
  type: ProductQueryType.InApp,
);

if (result is FetchProductsResultProducts) {
  for (final product in result.products) {
    if (product is ProductIOS) {
      debugPrint('iOS Product: ${product.displayName} - ${product.displayPrice}');
    } else if (product is ProductAndroid) {
      debugPrint('Android Product: ${product.title}');
    }
  }
}
```

## Purchase Processing

### requestPurchase()

Initiates a purchase request.

```dart
Future<RequestPurchaseResult> requestPurchase(
  RequestPurchaseProps params,
) async
```

**Parameters**:
- `params` - Purchase request props (use `RequestPurchaseProps.inApp()` or `RequestPurchaseProps.subs()`)

**Example (In-App Purchase)**:

```dart
await iap.requestPurchase(
  RequestPurchaseProps.inApp((
    ios: RequestPurchaseIosProps(sku: 'product_id'),
    android: RequestPurchaseAndroidProps(skus: ['product_id']),
  )),
);
```

**Example (Subscription)**:

```dart
await iap.requestPurchase(
  RequestPurchaseProps.subs(
    request: RequestPurchasePropsByPlatforms(
      ios: RequestPurchaseIosProps(sku: 'subscription_id'),
      android: RequestPurchaseAndroidProps(skus: ['subscription_id']),
    ),
  ),
);
```

**Important**: Results are delivered via `purchaseUpdatedListener` and `purchaseErrorListener`, not as a return value.

### requestPurchaseWithBuilder()

Builder-style purchase request (alternative API).

```dart
Future<RequestPurchaseResult> requestPurchaseWithBuilder({
  required RequestPurchaseBuilder Function(RequestPurchaseBuilder) build,
}) async
```

**Example**:

```dart
await iap.requestPurchaseWithBuilder(
  build: (builder) => builder
    ..type = ProductType.InApp
    ..withIOS((ios) => ios..sku = 'product_id')
    ..withAndroid((android) => android..skus = ['product_id']),
);
```

## Transaction Management

### finishTransaction()

Completes a transaction after successful purchase processing.

```dart
Future<String?> finishTransaction({
  required Purchase purchase,
  bool isConsumable = false,
}) async
```

**Parameters**:
- `purchase` - The purchase to finish
- `isConsumable` - Whether the product is consumable (consumes on Android, finishes on iOS)

**Example**:

```dart
iap.purchaseUpdatedListener.listen((purchase) async {
  // Verify purchase on server
  final isValid = await verifyPurchaseOnServer(purchase);

  if (!isValid) return;

  // Deliver content
  await deliverContent(purchase.productId);

  // Finish transaction
  await iap.finishTransaction(
    purchase: purchase,
    isConsumable: true, // For consumable products
  );
});
```

**Platform Behavior**:
- **iOS**: Calls `finishTransaction` on the transaction
- **Android**: Calls `consumePurchase` (if `isConsumable: true`) or `acknowledgePurchase` (if `isConsumable: false`)

## Purchase Verification

### verifyPurchase()

Verifies a purchase using the native platform's local verification.

```dart
Future<VerifyPurchaseResult> verifyPurchase({
  required String sku,
  VerifyPurchaseAndroidOptions? androidOptions,
}) async
```

**Parameters**:
- `sku` - The product SKU to verify
- `androidOptions` - Android-specific options for Google Play Developer API verification (required on Android)

**Returns**: `VerifyPurchaseResult` - Either `VerifyPurchaseResultIOS` or `VerifyPurchaseResultAndroid`

**Example (iOS)**:

```dart
final result = await iap.verifyPurchase(sku: 'premium_upgrade');

if (result is VerifyPurchaseResultIOS && result.isValid) {
  debugPrint('Purchase verified locally');
  debugPrint('JWS: ${result.jwsRepresentation}');
}
```

**Example (Android)**:

```dart
final result = await iap.verifyPurchase(
  sku: 'premium_upgrade',
  androidOptions: VerifyPurchaseAndroidOptions(
    accessToken: 'your-google-access-token',
    packageName: 'com.your.app',
    productToken: purchase.purchaseToken,
  ),
);

if (result is VerifyPurchaseResultAndroid) {
  debugPrint('Product ID: ${result.productId}');
  debugPrint('Purchase Date: ${result.purchaseDate}');
}
```

**Platform Behavior**:
- **iOS**: Uses StoreKit 2's built-in verification. Returns JWS representation and validity status.
- **Android**: Requires Google Play Developer API credentials. Returns detailed purchase information.

### verifyPurchaseWithProvider()

Verifies purchases using external verification services like IAPKit. This provides additional validation and security beyond local device verification.

```dart
Future<VerifyPurchaseWithProviderResult> verifyPurchaseWithProvider(
  VerifyPurchaseWithProviderProps props,
) async
```

**Parameters**:
- `props` - Configuration object containing:
  - `provider` - The verification provider to use (`VerifyPurchaseProvider.iapkit`)
  - `iapkit` - IAPKit-specific configuration including API key and platform tokens

**Returns**: `VerifyPurchaseWithProviderResult` containing verification results

**Example**:

```dart
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

Future<void> verifyWithIAPKit(Purchase purchase) async {
  final result = await iap.verifyPurchaseWithProvider(
    VerifyPurchaseWithProviderProps(
      provider: VerifyPurchaseProvider.iapkit,
      iapkit: RequestVerifyPurchaseWithIapkitProps(
        apiKey: 'your-iapkit-api-key',
        apple: RequestVerifyPurchaseWithIapkitAppleProps(jws: purchase.purchaseToken),
        google: RequestVerifyPurchaseWithIapkitGoogleProps(
            purchaseToken: purchase.purchaseToken),
      ),
    ),
  );

  if (result.iapkit case final iapkit? when iapkit.isValid) {
    debugPrint('Is Valid: ${iapkit.isValid}');
    debugPrint('State: ${iapkit.state}'); // 'entitled', 'expired', etc.
    debugPrint('Store: ${iapkit.store}'); // 'apple', 'google', or 'horizon'
  }
}
```

**Result Types**:

```dart
class VerifyPurchaseWithProviderResult {
  final VerifyPurchaseProvider provider;
  final VerifyPurchaseWithIapkitResult? iapkit;
}

class VerifyPurchaseWithIapkitResult {
  final bool isValid;
  final IapkitPurchaseState state;
  final IapStore store;
}

enum IapkitPurchaseState {
  Pending,
  Unknown,
  Entitled,
  PendingAcknowledgment,
  Canceled,
  Expired,
  ReadyToConsume,
  Consumed,
  Inauthentic,
}

enum IapStore {
  unknown,
  apple,
  google,
  horizon,
}
```

See [IAPKit Purchase States](https://www.openiap.dev/docs/apis#iapkit-purchase-states) for detailed state descriptions.

**Platform Behavior**:
- **iOS**: Sends the JWS (JSON Web Signature) token to IAPKit for server-side verification. The `purchaseToken` field contains the JWS representation on iOS.
- **Android**: Sends the purchase token for verification. The `purchaseToken` field contains the Google Play purchase token.

Both platforms use the unified `purchaseToken` field from the Purchase object. See [OpenIAP Purchase Common Types](https://www.openiap.dev/docs/types#purchase-common) for details.

**Use Cases**:
- Server-side receipt validation without maintaining your own validation infrastructure
- Cross-platform purchase verification with a unified API
- Enhanced security through external verification services

**Note**: You need an IAPKit API key to use this feature. Visit <IapKitLink>iapkit.com</IapKitLink> to get started.

**Error Handling**: See [Verification Error Handling](https://www.openiap.dev/docs/apis#verification-error-handling) for best practices on handling verification errors.

**Purchase Identifier Usage**:

After verifying purchases, use the appropriate identifiers for content delivery and purchase tracking:

**iOS Identifiers**:

| Product Type | Primary Identifier | Usage |
|:---|:---|:---|
| Consumable | `transactionId` | Track each purchase individually for content delivery |
| Non-consumable | `transactionId` | Single purchase tracking (equals `originalTransactionIdentifierIOS`) |
| Subscription | `originalTransactionIdentifierIOS` | Track subscription ownership across renewals |

**Android Identifiers**:

| Product Type | Primary Identifier | Usage |
|:---|:---|:---|
| Consumable | `purchaseToken` | Track each purchase for content delivery |
| Non-consumable | `purchaseToken` | Track ownership status |
| Subscription | `purchaseToken` | Track current subscription status (each renewal has same token on Android) |

**Key Points**:
- **Idempotency**: Use `transactionId` (iOS) or `purchaseToken` (Android) to prevent duplicate content delivery
- **iOS Subscriptions**: Each renewal creates a new `transactionId`, but `originalTransactionIdentifier` remains constant
- **Android Subscriptions**: The `purchaseToken` remains the same across normal renewals

## Purchase History

### getAvailablePurchases()

Gets available purchases with optional filtering.

```dart
Future<List<Purchase>> getAvailablePurchases({
  bool? onlyIncludeActiveItemsIOS,
  bool? alsoPublishToEventListenerIOS,
}) async
```

**Parameters**:
- `onlyIncludeActiveItemsIOS` - When `true` (default), excludes expired subscriptions (iOS only)
- `alsoPublishToEventListenerIOS` - When `true`, replays purchases through `purchaseUpdatedListener` (iOS only)

**Returns**: List of available purchases

**Example**:

```dart
// Get only active purchases (default)
final purchases = await iap.getAvailablePurchases();

// Include expired subscriptions (iOS)
final allPurchases = await iap.getAvailablePurchases(
  onlyIncludeActiveItemsIOS: false,
);
```

### restorePurchases()

Restores previous purchases.

```dart
Future<List<Purchase>> restorePurchases() async
```

**Returns**: List of restored purchases

**Example**:

```dart
final restored = await iap.restorePurchases();
debugPrint('Restored ${restored.length} purchases');

for (final purchase in restored) {
  await deliverContent(purchase.productId);
}
```

## Subscription Management

### getActiveSubscriptions()

Gets lightweight subscription status (recommended for quick checks).

```dart
Future<List<ActiveSubscription>> getActiveSubscriptions(
  List<String> skus,
) async
```

**Parameters**:
- `skus` - List of subscription product IDs to check

**Returns**: List of `ActiveSubscription` objects (lightweight)

**Example**:

```dart
final subscriptions = await iap.getActiveSubscriptions([
  'monthly_sub',
  'yearly_sub',
]);

for (final sub in subscriptions) {
  debugPrint('${sub.productId}: active=${sub.isActive}');
}
```

**Use Case**: Quick subscription status checks without full purchase details.

### hasActiveSubscriptions()

Checks if user has any active subscriptions.

```dart
Future<bool> hasActiveSubscriptions(List<String> skus) async
```

**Parameters**:
- `skus` - List of subscription product IDs to check

**Returns**: `true` if any subscription is active

**Example**:

```dart
final hasActive = await iap.hasActiveSubscriptions([
  'monthly_sub',
  'yearly_sub',
]);

if (hasActive) {
  // Show premium content
}
```

## Platform-Specific Methods

### iOS-Specific Methods

#### presentCodeRedemptionSheetIOS()

Presents the App Store code redemption sheet.

```dart
Future<void> presentCodeRedemptionSheetIOS() async
```

**Example**:

```dart
if (Platform.isIOS) {
  await iap.presentCodeRedemptionSheetIOS();
}
```

**Requirements**: iOS 14.0+

#### showManageSubscriptionsIOS()

Shows the subscription management interface.

```dart
Future<void> showManageSubscriptionsIOS({
  String? productId,
}) async
```

**Example**:

```dart
if (Platform.isIOS) {
  await iap.showManageSubscriptionsIOS(
    productId: 'subscription_id', // Optional
  );
}
```

#### isEligibleForIntroOfferIOS()

Checks if user is eligible for introductory offer.

```dart
Future<bool> isEligibleForIntroOfferIOS(String productId) async
```

**Example**:

```dart
if (Platform.isIOS) {
  final eligible = await iap.isEligibleForIntroOfferIOS('subscription_id');
  debugPrint('Eligible for intro offer: $eligible');
}
```

#### subscriptionStatusIOS()

Gets detailed subscription status (iOS only).

```dart
Future<List<SubscriptionStatusIOS>> subscriptionStatusIOS(
  List<String> productIds,
) async
```

**Example**:

```dart
if (Platform.isIOS) {
  final statuses = await iap.subscriptionStatusIOS(['subscription_id']);
  for (final status in statuses) {
    debugPrint('Status: ${status.state}');
  }
}
```

### Android-Specific Methods

#### deepLinkToSubscriptions()

Opens the Google Play subscription management page.

```dart
Future<void> deepLinkToSubscriptions({
  DeepLinkOptions? options,
}) async
```

**Example**:

```dart
if (Platform.isAndroid) {
  await iap.deepLinkToSubscriptions(
    options: DeepLinkOptions(productId: 'subscription_id'),
  );
}
```

#### acknowledgePurchaseAndroid()

Acknowledges a purchase on Android.

```dart
Future<void> acknowledgePurchaseAndroid({
  required String purchaseToken,
}) async
```

**Example**:

```dart
if (Platform.isAndroid) {
  await iap.acknowledgePurchaseAndroid(
    purchaseToken: purchase.purchaseToken,
  );
}
```

**Note**: Use `finishTransaction()` for cross-platform compatibility.

#### consumePurchaseAndroid()

Consumes a purchase on Android.

```dart
Future<void> consumePurchaseAndroid({
  required String purchaseToken,
}) async
```

**Example**:

```dart
if (Platform.isAndroid) {
  await iap.consumePurchaseAndroid(
    purchaseToken: purchase.purchaseToken,
  );
}
```

**Note**: Use `finishTransaction(isConsumable: true)` for cross-platform compatibility.

## Best Practices

### 1. Always Set Up Listeners First

```dart
@override
void initState() {
  super.initState();
  _setupIAP();
}

Future<void> _setupIAP() async {
  // Set up listeners BEFORE initConnection
  _purchaseUpdatedSubscription = iap.purchaseUpdatedListener.listen(
    (purchase) => _handlePurchase(purchase),
  );

  _purchaseErrorSubscription = iap.purchaseErrorListener.listen(
    (error) => _handleError(error),
  );

  // Then initialize
  await iap.initConnection();
}
```

### 2. Handle Purchase Results in Listeners

```dart
// ❌ Wrong: Expecting result from requestPurchase
final result = await iap.requestPurchase(...); // Returns immediately

// ✅ Correct: Handle in listener
iap.purchaseUpdatedListener.listen((purchase) {
  // Purchase succeeded
  _handlePurchase(purchase);
});

iap.purchaseErrorListener.listen((error) {
  // Purchase failed
  _handleError(error);
});
```

### 3. Always Verify Purchases Server-Side

```dart
Future<void> _handlePurchase(Purchase purchase) async {
  // 1. Verify on server
  final isValid = await verifyPurchaseOnServer(purchase);

  if (!isValid) {
    debugPrint('Invalid purchase');
    return;
  }

  // 2. Deliver content
  await deliverContent(purchase.productId);

  // 3. Finish transaction
  await iap.finishTransaction(
    purchase: purchase,
    isConsumable: false,
  );
}
```

### 4. Cancel Subscriptions in Dispose

```dart
@override
void dispose() {
  _purchaseUpdatedSubscription?.cancel();
  _purchaseErrorSubscription?.cancel();
  super.dispose();
}
```

## Alternative Billing Methods

### iOS External Purchase Methods

#### presentExternalPurchaseLinkIOS()

Open an external purchase link in Safari to redirect users to your website for purchase. Requires iOS 16.0+.

```dart
Future<ExternalPurchaseLinkResultIOS> presentExternalPurchaseLinkIOS(String url)
```

**Parameters:**

- `url` (String): The external purchase URL to open

**Returns:** `Future<ExternalPurchaseLinkResultIOS>`

```dart
class ExternalPurchaseLinkResultIOS {
  final String? error;
  final bool success;
}
```

**Example:**

```dart
final result = await FlutterInappPurchase.instance
    .presentExternalPurchaseLinkIOS('https://your-site.com/checkout');

if (result.error != null) {
  print('Failed to open link: ${result.error}');
} else if (result.success) {
  print('User redirected to external purchase website');
}
```

**Platform:** iOS 16.0+

**Requirements:**

- Requires Apple approval and proper provisioning profile with external purchase entitlements
- URLs must be configured in your app's Info.plist
- Deep linking recommended to return users to your app after purchase

**Important Notes:**

- Purchase listeners will NOT fire when using external URLs
- You must handle purchase validation on your backend
- Implement deep linking to return users to your app

**See also:**

- [StoreKit External Purchase documentation](https://developer.apple.com/documentation/storekit/external-purchase)
- [Alternative Billing Guide](../guides/alternative-billing)

### Android Alternative Billing Methods

#### checkAlternativeBillingAvailabilityAndroid()

Check if alternative billing is available for the current user. This must be called before showing the alternative billing dialog.

```dart
Future<bool> checkAlternativeBillingAvailabilityAndroid()
```

**Returns:** `Future<bool>`

**Example:**

```dart
final isAvailable = await FlutterInappPurchase.instance
    .checkAlternativeBillingAvailabilityAndroid();

if (isAvailable) {
  print('Alternative billing is available');
} else {
  print('Alternative billing not available for this user');
}
```

**Platform:** Android

**Requirements:**

- Must initialize connection with alternative billing mode
- User must be eligible for alternative billing (determined by Google)

**See also:** [Google Play Alternative Billing documentation](https://developer.android.com/google/play/billing/alternative)

#### showAlternativeBillingDialogAndroid()

Show Google's required information dialog to inform users about alternative billing. This must be called after checking availability and before processing payment.

```dart
Future<bool> showAlternativeBillingDialogAndroid()
```

**Returns:** `Future<bool>` - Returns `true` if user accepted, `false` if declined

**Example:**

```dart
final userAccepted = await FlutterInappPurchase.instance
    .showAlternativeBillingDialogAndroid();

if (userAccepted) {
  print('User accepted alternative billing');
  // Proceed with your payment flow
} else {
  print('User declined alternative billing');
}
```

**Platform:** Android

**Note:** This dialog is required by Google Play's alternative billing policy. You must show this before redirecting users to your payment system.

#### createAlternativeBillingTokenAndroid()

Generate a reporting token after successfully processing payment through your payment system. This token must be reported to Google Play within 24 hours.

```dart
Future<String?> createAlternativeBillingTokenAndroid()
```

**Returns:** `Future<String?>` - Returns the token or `null` if creation failed

**Example:**

```dart
// After successfully processing payment in your system
final token = await FlutterInappPurchase.instance
    .createAlternativeBillingTokenAndroid();

if (token != null) {
  print('Token created: $token');
  // Send this token to your backend to report to Google
  await reportTokenToGooglePlay(token);
} else {
  print('Failed to create token');
}
```

**Platform:** Android

**Important:**

- Token must be reported to Google Play backend within 24 hours
- Requires server-side integration with Google Play Developer API
- Failure to report will result in refund and possible account suspension

#### Alternative Billing Configuration

```dart
// Initialize with alternative billing mode
await FlutterInappPurchase.instance.initConnection(
  alternativeBillingModeAndroid: AlternativeBillingModeAndroid.UserChoice,
  // or AlternativeBillingModeAndroid.AlternativeOnly
);

// To change mode, reinitialize
await FlutterInappPurchase.instance.endConnection();
await FlutterInappPurchase.instance.initConnection(
  alternativeBillingModeAndroid: AlternativeBillingModeAndroid.AlternativeOnly,
);
```

**Billing Modes:**

```dart
enum AlternativeBillingModeAndroid {
  None,              // Default - no alternative billing
  UserChoice,        // Users choose between Google Play or your payment system
  AlternativeOnly,   // Only your payment system is available
}
```

**Complete Flow Example:**

```dart
Future<void> purchaseWithAlternativeBilling(String productId) async {
  // Step 1: Check availability
  final isAvailable = await FlutterInappPurchase.instance
      .checkAlternativeBillingAvailabilityAndroid();

  if (!isAvailable) {
    throw Exception('Alternative billing not available');
  }

  // Step 2: Show required dialog
  final userAccepted = await FlutterInappPurchase.instance
      .showAlternativeBillingDialogAndroid();

  if (!userAccepted) {
    throw Exception('User declined alternative billing');
  }

  // Step 3: Process payment in your system
  final paymentResult = await processPaymentInYourSystem(productId);
  if (!paymentResult.success) {
    throw Exception('Payment failed');
  }

  // Step 4: Create reporting token
  final token = await FlutterInappPurchase.instance
      .createAlternativeBillingTokenAndroid();

  if (token == null) {
    throw Exception('Failed to create token');
  }

  // Step 5: Report to Google (must be done within 24 hours)
  await reportToGooglePlayBackend(token, productId, paymentResult);

  print('Alternative billing completed successfully');
}
```

**See also:**

- [Google Play Alternative Billing documentation](https://developer.android.com/google/play/billing/alternative)
- [Alternative Billing Guide](../guides/alternative-billing)
- [Alternative Billing Example](../examples/alternative-billing)

## See Also

- [Types](./types) - Type definitions
- [Error Codes](./types/error-codes) - Error handling
- [Purchase Lifecycle](../guides/lifecycle) - Complete purchase flow
- [Subscription Guide](../guides/subscription-validation) - Subscription management
- [Alternative Billing Guide](../guides/alternative-billing) - Alternative billing implementation
