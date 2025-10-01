---
sidebar_position: 1
title: Migration from v5.x
---

# Migration from v5.x to v6.8+

This guide helps you migrate from flutter_inapp_purchase v5.x to the latest v6.8+ version.

## Overview

Version 6.8+ is a **major update** with significant breaking changes to align with the OpenIAP specification and support modern platform APIs.

## Key Changes Summary

- ✅ **OpenIAP Compliance** - Full alignment with OpenIAP specification
- ✅ **StoreKit 2 Support** for iOS 15.0+
- ✅ **Billing Client v8** for Android
- ✅ **Improved Type Safety** with refined APIs
- ✅ **Better Error Handling** with standardized error codes
- ⚠️ **Breaking Changes** in error codes, method signatures, and data models

## Major Breaking Changes

### 1. Error Code Format (CRITICAL)

The most significant breaking change is the error code enum format.

**v5.x (Old):**

```dart
// SCREAMING_SNAKE_CASE with E_ prefix
ErrorCode.E_USER_CANCELLED
ErrorCode.E_NETWORK_ERROR
ErrorCode.E_ITEM_UNAVAILABLE
ErrorCode.E_ALREADY_OWNED
ErrorCode.E_DEVELOPER_ERROR
```

**v6.8+ (New):**

```dart
// PascalCase format (OpenIAP standard)
ErrorCode.UserCancelled
ErrorCode.NetworkError
ErrorCode.ItemUnavailable
ErrorCode.AlreadyOwned
ErrorCode.DeveloperError
```

**Migration:**

```dart
// Before
if (error.code == ErrorCode.E_USER_CANCELLED) { ... }

// After
if (error.code == ErrorCode.UserCancelled) { ... }
```

### 2. Data Models

**v5.x:**

- `IAPItem` for products
- String-based product IDs
- Nullable fields everywhere

**v6.8+:**

- `Product` / `ProductCommon` for products
- Strongly typed with required fields
- Better null safety

```dart
// Before (v5.x)
class IAPItem {
  String? productId;
  String? price;
  String? currency;
  String? localizedPrice;
}

// After (v6.8+)
class Product {
  String id;              // Required
  double? price;          // Numeric
  String currency;        // Required
  String displayPrice;    // Required (localized)
  ProductType type;       // Required
}
```

### 3. fetchProducts API

**v5.x:**

```dart
// Old approach
List<IAPItem> items = await FlutterInappPurchase.instance
    .fetchProducts(skus: _productIds, type: 'inapp');
```

**v6.8+:**

```dart
// New OpenIAP-compliant approach
final result = await FlutterInappPurchase.instance.fetchProducts(
  ProductRequest(
    skus: _productIds,
    type: ProductQueryType.InApp,
  ),
);
final products = result.value;
```

### 4. requestPurchase API

**v5.x:**

```dart
// Simple string-based request
String msg = await FlutterInappPurchase.instance
    .requestPurchase(item.productId);
```

**v6.8+:**

```dart
// Structured request with platform-specific options
final requestProps = RequestPurchaseProps.inApp(
  request: RequestPurchasePropsByPlatforms(
    ios: RequestPurchaseIosProps(
      sku: productId,
      quantity: 1,
    ),
    android: RequestPurchaseAndroidProps(
      skus: [productId],
    ),
  ),
);

await FlutterInappPurchase.instance.requestPurchase(requestProps);
```

### 5. finishTransaction API

**v5.x:**

```dart
// iOS only, simple call
await FlutterInappPurchase.instance.finishTransaction(item);
```

**v6.8+:**

```dart
// Cross-platform with explicit consumable flag
await FlutterInappPurchase.instance.finishTransaction(
  purchase: item,
  isConsumable: true, // Required parameter
);
```

### 6. Stream Access

**v5.x:**

```dart
// Direct static stream access
FlutterInappPurchase.iapUpdated.listen(...);
```

**v6.8+:**

```dart
// Instance-based stream access
FlutterInappPurchase.instance.purchaseUpdated.listen(...);
FlutterInappPurchase.instance.purchaseError.listen(...);
```

### 7. Android Methods

**v5.x:**

```dart
await FlutterInappPurchase.instance.consumePurchase(
  purchaseToken: token,
);
await FlutterInappPurchase.instance.acknowledgePurchase(
  purchaseToken: token,
);
```

**v6.8+:**

```dart
// Explicit Android suffix for clarity
await FlutterInappPurchase.instance.consumePurchaseAndroid(
  purchaseToken: token,
);
await FlutterInappPurchase.instance.acknowledgePurchaseAndroid(
  purchaseToken: token,
);
```

## Step-by-Step Migration

### Step 1: Update Dependencies

Update your `pubspec.yaml`:

```yaml
dependencies:
  flutter_inapp_purchase: ^6.8.0
```

Run:

```bash
flutter pub get
```

### Step 2: Update Error Code Handling

Find and replace all error code references:

**Search for:**

```dart
ErrorCode.E_USER_CANCELLED
ErrorCode.E_NETWORK_ERROR
ErrorCode.E_ITEM_UNAVAILABLE
ErrorCode.E_ALREADY_OWNED
```

**Replace with:**

```dart
ErrorCode.UserCancelled
ErrorCode.NetworkError
ErrorCode.ItemUnavailable
ErrorCode.AlreadyOwned
```

### Step 3: Update Stream Listeners

**Before:**

```dart
_purchaseUpdatedSubscription = FlutterInappPurchase.iapUpdated.listen((data) {
  print('purchase-updated: $data');
});

_purchaseErrorSubscription = FlutterInappPurchase.iapUpdated.listen((data) {
  print('purchase-error: $data');
});
```

**After:**

```dart
_purchaseUpdatedSubscription = FlutterInappPurchase.instance
    .purchaseUpdated.listen((purchase) {
  if (purchase != null) {
    print('purchase-updated: ${purchase.productId}');
    _handlePurchaseUpdate(purchase);
  }
});

_purchaseErrorSubscription = FlutterInappPurchase.instance
    .purchaseError.listen((error) {
  print('purchase-error: ${error?.message}');
  _handlePurchaseError(error);
});
```

### Step 4: Update Product Fetching

**Before:**

```dart
Future<void> _getProducts() async {
  List<IAPItem> items = await FlutterInappPurchase.instance
      .fetchProducts(skus: _productIds, type: 'inapp');
  setState(() {
    _items = items;
  });
}
```

**After:**

```dart
Future<void> _getProducts() async {
  final result = await FlutterInappPurchase.instance.fetchProducts(
    ProductRequest(
      skus: _productIds,
      type: ProductQueryType.InApp,
    ),
  );
  setState(() {
    _items = result.value;
  });
}
```

### Step 5: Update Purchase Requests

**Before:**

```dart
void _requestPurchase(IAPItem item) {
  FlutterInappPurchase.instance.requestPurchase(item.productId);
}
```

**After:**

```dart
Future<void> _requestPurchase(ProductCommon item) async {
  final requestProps = RequestPurchaseProps.inApp(
    request: RequestPurchasePropsByPlatforms(
      ios: RequestPurchaseIosProps(
        sku: item.id,
        quantity: 1,
      ),
      android: RequestPurchaseAndroidProps(
        skus: [item.id],
      ),
    ),
  );

  await FlutterInappPurchase.instance.requestPurchase(requestProps);
}
```

### Step 6: Update Transaction Completion

**Before:**

```dart
// iOS
await FlutterInappPurchase.instance.finishTransaction(item);

// Android
await FlutterInappPurchase.instance.consumePurchase(
  purchaseToken: item.purchaseToken!,
);
```

**After:**

```dart
// iOS
await FlutterInappPurchase.instance.finishTransaction(
  purchase: item,
  isConsumable: true,
);

// Android
await FlutterInappPurchase.instance.consumePurchaseAndroid(
  purchaseToken: item.purchaseToken!,
);
```

### Step 7: Update Field Access

**Before:**

```dart
final id = product.productId;
final price = product.localizedPrice;
```

**After:**

```dart
final id = product.id;
final price = product.displayPrice;
```

## Complete Migration Example

### Before (v5.x)

```dart
class _MyStoreState extends State<MyStore> {
  StreamSubscription? _purchaseSubscription;
  List<IAPItem> _items = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await FlutterInappPurchase.instance.initConnection();

    _purchaseSubscription = FlutterInappPurchase.iapUpdated.listen((data) {
      print('purchase: $data');
      _finishTransaction(data);
    });

    final items = await FlutterInappPurchase.instance
        .fetchProducts(skus: _productIds, type: 'inapp');

    setState(() {
      _items = items;
    });
  }

  void _buy(IAPItem item) {
    FlutterInappPurchase.instance.requestPurchase(item.productId);
  }

  void _finishTransaction(Purchase item) {
    FlutterInappPurchase.instance.finishTransaction(item);
  }
}
```

### After (v6.8+)

```dart
class _MyStoreState extends State<MyStore> {
  StreamSubscription? _purchaseSubscription;
  List<ProductCommon> _items = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await FlutterInappPurchase.instance.initConnection();

    _purchaseSubscription = FlutterInappPurchase.instance
        .purchaseUpdated.listen((purchase) {
      if (purchase != null) {
        print('purchase: ${purchase.productId}');
        _finishTransaction(purchase);
      }
    });

    final result = await FlutterInappPurchase.instance.fetchProducts(
      ProductRequest(
        skus: _productIds,
        type: ProductQueryType.InApp,
      ),
    );

    setState(() {
      _items = result.value;
    });
  }

  Future<void> _buy(ProductCommon item) async {
    final requestProps = RequestPurchaseProps.inApp(
      request: RequestPurchasePropsByPlatforms(
        ios: RequestPurchaseIosProps(
          sku: item.id,
          quantity: 1,
        ),
        android: RequestPurchaseAndroidProps(
          skus: [item.id],
        ),
      ),
    );

    await FlutterInappPurchase.instance.requestPurchase(requestProps);
  }

  Future<void> _finishTransaction(Purchase item) async {
    await FlutterInappPurchase.instance.finishTransaction(
      purchase: item,
      isConsumable: true,
    );
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    super.dispose();
  }
}
```

## Testing Checklist

After migration, test the following:

- [ ] App compiles without errors
- [ ] IAP connection initializes successfully
- [ ] Products load correctly
- [ ] Purchase flow completes
- [ ] Transactions finish properly
- [ ] Error handling works (test by cancelling a purchase)
- [ ] Restore purchases works
- [ ] Both iOS and Android platforms tested

## Common Migration Issues

### Issue 1: "ErrorCode.E_USER_CANCELLED not found"

**Solution:** Update to new PascalCase format:

```dart
ErrorCode.UserCancelled
```

### Issue 2: "productId doesn't exist"

**Solution:** Change to `id`:

```dart
// Before
item.productId

// After
item.id
```

### Issue 3: "localizedPrice doesn't exist"

**Solution:** Change to `displayPrice`:

```dart
// Before
item.localizedPrice

// After
item.displayPrice
```

### Issue 4: "type argument required"

**Solution:** Add ProductQueryType:

```dart
ProductRequest(
  skus: ['product_id'],
  type: ProductQueryType.InApp, // Required
)
```

## Benefits of v6.8+

- **OpenIAP Standard**: Full compliance with OpenIAP specification
- **Better Type Safety**: Strongly typed APIs with fewer runtime errors
- **Improved Error Handling**: Clearer error codes and messages
- **Modern Platform Support**: Latest iOS StoreKit 2 and Android Billing v8
- **Better Documentation**: Comprehensive guides aligned with OpenIAP
- **Cross-Platform Consistency**: Unified API across iOS and Android

## Need Help?

If you encounter issues during migration:

1. Check the [Troubleshooting Guide](../troubleshooting)
2. Review the [API Documentation](../api/overview)
3. Look at the [Examples](../examples/basic-store)
4. [Open an issue](https://github.com/hyochan/flutter_inapp_purchase/issues) on GitHub
5. Join our [Discord Community](https://discord.gg/hyo)

## Related Documentation

- [OpenIAP Specification](https://www.openiap.dev)
- [Quick Start Guide](../getting-started/quickstart)
- [Error Handling Guide](../guides/error-handling)
- [Products Guide](../guides/products)
- [Purchases Guide](../guides/purchases)
