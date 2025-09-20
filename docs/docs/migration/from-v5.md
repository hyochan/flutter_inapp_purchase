---
sidebar_position: 1
title: Migration Guide
---

# Migration Guide

This guide helps you migrate your existing flutter_inapp_purchase implementation to the latest version.

## Version Support

- **v6.7.0** (Current) - Latest version with simplified APIs and platform compliance updates
- **v6.3.x - 6.6.x** - Previous stable releases with transitional APIs

## Migration from v6.3.x to v6.7.0 (Current)

### Breaking Changes

#### Simplified fetchProducts API

The `fetchProducts` method now accepts direct parameters instead of a wrapper object:

**Before (v6.3.x):**

```dart
final products = await iap.fetchProducts(
  RequestProductsParams(
    skus: ['product_id'],
    type: PurchaseType.inapp,
  ),
);
```

**After (v6.7.0):**

```dart
final products = await iap.fetchProducts(
  skus: ['product_id'],
  type: PurchaseType.inapp,  // Optional, defaults to PurchaseType.inapp
);
```

The `RequestProductsParams` class has been removed to simplify the API.

## Migration from v5.x to v6.0.0

### Overview

Version 6.0.0 is a **major release** with breaking changes to support modern platform APIs and improve developer experience.

### Key Changes Summary

- ✅ **StoreKit 2 Support** for iOS 15.0+
- ✅ **Billing Client v8** for Android
- ✅ **Improved Error Handling** with better error codes
- ✅ **Enhanced Type Safety** with refined APIs
- ⚠️ **Breaking Changes** in error codes and some method signatures

### Breaking Changes

#### 1. Error Code Enum Changes (CRITICAL)

The most significant breaking change is the error code enum format.

**v5.x (Old):**

```dart
// SCREAMING_SNAKE_CASE format
ErrorCode.E_USER_CANCELLED
ErrorCode.E_NETWORK_ERROR
ErrorCode.E_ITEM_UNAVAILABLE
ErrorCode.E_ALREADY_OWNED
ErrorCode.E_DEVELOPER_ERROR
```

**v6.0 (New):**

```dart
// PascalCase format
ErrorCode.UserCancelled
ErrorCode.NetworkError
ErrorCode.ItemUnavailable
ErrorCode.AlreadyOwned
ErrorCode.DeveloperError
```

**Before (v5.x):**

```dart
Future<List<IAPItem>> legacyProductLoader(List<String> skus) async
Future<String> requestPurchase(String sku) async
```

**After (v6.x):**

```dart
Future<FetchProductsResult> fetchProducts(ProductRequest request) async
Future<void> requestPurchase(RequestPurchaseProps params) async
```

### 2. Method Return Types

Several methods now return `void` instead of `String`:

```dart
// Old
String result = await FlutterInappPurchase.instance.requestPurchase(sku);

// New
await FlutterInappPurchase.instance.requestPurchase(sku);
// Result comes through purchaseUpdated stream
```

### 3. Stream Names

Purchase streams have been renamed for clarity:

**Before:**

```dart
FlutterInappPurchase.connectionUpdated.listen(...);
FlutterInappPurchase.iapUpdated.listen(...);
```

**After:**

```dart
FlutterInappPurchase.purchaseUpdated.listen(...);
FlutterInappPurchase.purchaseError.listen(...);
```

## Step-by-Step Migration

### Step 1: Update Dependencies

Update your `pubspec.yaml`:

```yaml
dependencies:
  flutter_inapp_purchase: ^6.7.0 # Updated version
```

Run:

```bash
flutter pub get
```

### Step 2: Enable Null Safety

If you haven't already, migrate your project to null safety:

```bash
dart migrate
```

### Step 3: Update Initialization

**Before:**

```dart
Future<void> initPlatformState() async {
  try {
    await FlutterInappPurchase.instance.initConnection();
    print('IAP connection initialized');
  } on PlatformException catch (e) {
    print('Failed to initialize connection: $e');
  }
}
```

**After:**

```dart
Future<void> initPlatformState() async {
  try {
    await FlutterInappPurchase.instance.initConnection();
    print('IAP connection initialized');
  } catch (e) {
    print('Failed to initialize IAP: $e');
  }
}
```

### Step 4: Update Stream Listeners

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
_purchaseUpdatedSubscription = FlutterInappPurchase.purchaseUpdated.listen((productItem) {
  if (productItem != null) {
    print('purchase-updated: ${productItem.productId}');
    _handlePurchaseUpdate(productItem);
  }
});

_purchaseErrorSubscription = FlutterInappPurchase.purchaseError.listen((productItem) {
  print('purchase-error: ${productItem?.productId}');
  _handlePurchaseError(productItem);
});
```

### Step 5: Update Purchase Methods

**Before:**

```dart
try {
  String msg = await FlutterInappPurchase.instance.requestPurchase(item.productId);
  print('requestPurchase: $msg');
} catch (error) {
  print('requestPurchase error: $error');
}
```

**After:**

```dart
try {
  await FlutterInappPurchase.instance.requestPurchase(item.productId!);
  // Success/failure will be delivered via streams
} catch (error) {
  print('requestPurchase error: $error');
}
```

### Step 6: Update Data Model Access

**Before:**

```dart
// Accessing properties without null checks
String productId = item.productId;
String price = item.localizedPrice;
```

**After:**

```dart
// Null-safe property access
String? productId = item.productId;
String? price = item.localizedPrice;

// With null coalescing
String displayPrice = item.localizedPrice ?? 'N/A';
```

### Step 7: Update Transaction Completion

**Before:**

```dart
try {
  String msg = await FlutterInappPurchase.instance.finishTransaction(item);
} catch (err) {
  print('finishTransaction error: $err');
}
```

**After:**

```dart
try {
  String? result = await FlutterInappPurchase.instance.finishTransaction(item);
  print('Transaction finished: $result');
} catch (err) {
  print('finishTransaction error: $err');
}
```

## Complete Migration Example

Here's a complete before/after example:

### Before (v5.x)

```dart
class _MyAppState extends State<MyApp> {
  StreamSubscription _purchaseUpdatedSubscription;
  StreamSubscription _purchaseErrorSubscription;
  List<ProductCommon> _items = [];
  List<Purchase> _purchases = [];

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    await FlutterInappPurchase.instance.initConnection();

    _purchaseUpdatedSubscription = FlutterInappPurchase.iapUpdated.listen((data) {
      print('purchase-updated: $data');
      setState(() {
        _purchases.add(data);
      });
    });

    _purchaseErrorSubscription = FlutterInappPurchase.iapUpdated.listen((data) {
      print('purchase-error: $data');
    });

    _getProduct();
  }

  void _requestPurchase(IAPItem item) {
    FlutterInappPurchase.instance.requestPurchase(item.productId);
  }

  Future _getProduct() async {
    List<IAPItem> items = await FlutterInappPurchase.instance.fetchProducts(skus: _kProductIds, type: 'inapp');
    setState(() {
      _items = items;
    });
  }
}
```

### After (v6.x)

```dart
class _MyAppState extends State<MyApp> {
  StreamSubscription? _purchaseUpdatedSubscription;
  StreamSubscription? _purchaseErrorSubscription;
  List<ProductCommon> _items = [];
  List<Purchase> _purchases = [];

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    try {
      await FlutterInappPurchase.instance.initConnection();
      print('IAP connection initialized');
    } catch (e) {
      print('Failed to initialize: $e');
    }

    _purchaseUpdatedSubscription = FlutterInappPurchase
        .purchaseUpdated.listen((productItem) {
      if (productItem != null) {
        print('purchase-updated: ${productItem.productId}');
        setState(() {
          _purchases.add(productItem);
        });
        // Finish the transaction
        _finishTransaction(productItem);
      }
    });

    _purchaseErrorSubscription = FlutterInappPurchase
        .purchaseError.listen((result) {
      print('purchase-error: ${result?.message}');
      // Handle error
    });

    _getProduct();
  }

  void _requestPurchase(IapItem item) async {
    try {
      await FlutterInappPurchase.instance.requestPurchase(item.productId!);
    } catch (e) {
      print('Purchase request failed: $e');
    }
  }

  Future<void> _finishTransaction(Purchase item) async {
    try {
      await FlutterInappPurchase.instance.finishTransaction(item);
    } catch (e) {
      print('Failed to finish transaction: $e');
    }
  }

  Future<void> _getProduct() async {
    try {
      final result = await FlutterInappPurchase.instance.fetchProducts(
        ProductRequest(
          skus: _kProductIds,
          type: ProductQueryType.InApp,
        ),
      );
      final items = result.inAppProducts();
      setState(() {
        _items = items;
      });
    } catch (e) {
      print('Failed to get products: $e');
    }
  }

  @override
  void dispose() {
    _purchaseUpdatedSubscription?.cancel();
    _purchaseErrorSubscription?.cancel();
    super.dispose();
  }
}
```

## Testing Your Migration

1. **Compile Check:** Ensure your code compiles without errors
2. **Initialize Test:** Verify IAP initialization works
3. **Product Loading:** Test product fetching
4. **Purchase Flow:** Test complete purchase flow
5. **Stream Handling:** Verify purchase update streams work
6. **Transaction Completion:** Test finishing transactions

## Benefits of v6.x

- **Null Safety:** Better type safety and fewer runtime errors
- **Improved Error Handling:** More precise error information
- **Better Stream API:** Clearer separation of success and error streams
- **Updated Dependencies:** Latest Android and iOS billing libraries
- **Performance Improvements:** Optimized native code

## Need Help?

If you encounter issues during migration:

1. Check the [Troubleshooting Guide](../troubleshooting)
2. Review the [API Documentation](../api/overview)
3. Look at the [Examples](../examples/basic-store)
4. [Open an issue](https://github.com/hyochan/flutter_inapp_purchase/issues) on GitHub
