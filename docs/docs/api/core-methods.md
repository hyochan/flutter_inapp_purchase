---
title: Core Methods
sidebar_position: 3
---

# Core Methods

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
  RequestPurchaseProps.inApp(
    request: RequestPurchasePropsByPlatforms(
      ios: RequestPurchaseIosProps(sku: 'product_id'),
      android: RequestPurchaseAndroidProps(skus: ['product_id']),
    ),
  ),
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

## See Also

- [Types](./types) - Type definitions
- [Error Codes](./types/error-codes) - Error handling
- [Purchase Lifecycle](../guides/lifecycle) - Complete purchase flow
- [Subscription Guide](../guides/subscription-validation) - Subscription management
