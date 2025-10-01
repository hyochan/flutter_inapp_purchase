---
sidebar_position: 2
title: Migration from expo-iap
---

# Migration from expo-iap

This guide helps you migrate from expo-iap to flutter_inapp_purchase, highlighting key differences and providing migration strategies.

## Key Differences

### Architecture

**expo-iap (React Native/Expo):**

- Hook-based architecture (`useIAP`)
- Built for Expo/React Native ecosystem
- JavaScript/TypeScript

**flutter_inapp_purchase (Flutter):**

- Stream-based architecture
- Built for Flutter ecosystem
- Dart language

## API Comparison

### Initialization

**expo-iap:**

```typescript
import { useIAP } from "expo-iap";

function MyStore() {
  const { connected, products, getProducts } = useIAP();

  useEffect(() => {
    if (connected) {
      getProducts(productIds);
    }
  }, [connected]);
}
```

**flutter_inapp_purchase:**

```dart
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

class MyStore extends StatefulWidget {
  @override
  _MyStoreState createState() => _MyStoreState();
}

class _MyStoreState extends State<MyStore> {
  List<ProductCommon> products = [];

  @override
  void initState() {
    super.initState();
    _initializeStore();
  }

  Future<void> _initializeStore() async {
    await FlutterInappPurchase.instance.initConnection();
    final result = await FlutterInappPurchase.instance.fetchProducts(
      ProductRequest(
        skus: productIds,
        type: ProductQueryType.InApp,
      ),
    );
    products = result.value;
    setState(() {});
  }
}
```

### Product Fetching

**expo-iap:**

```typescript
// Returns array directly
const products = await getProducts({
  skus: ["product1", "product2"],
  type: "inapp",
});

// Returns array directly
const subscriptions = await getProducts({
  skus: ["sub1", "sub2"],
  type: "subs",
});
```

**flutter_inapp_purchase:**

```dart
// Returns FetchProductsResult object, access .value for array
final inAppResult = await FlutterInappPurchase.instance.fetchProducts(
  ProductRequest(
    skus: ['product1', 'product2'],
    type: ProductQueryType.InApp,
  ),
);
final products = inAppResult.value ?? []; // Array of products

// Same pattern for subscriptions
final subResult = await FlutterInappPurchase.instance.fetchProducts(
  ProductRequest(
    skus: ['sub1', 'sub2'],
    type: ProductQueryType.Subs,
  ),
);
final subscriptions = subResult.value ?? []; // Array of subscriptions
```

**Key Difference:**

- **expo-iap**: `getProducts()` returns an array directly
- **flutter_inapp_purchase**: `fetchProducts()` returns a `FetchProductsResult` object with `.value` property containing the array (nullable)

### Purchase Flow

**expo-iap:**

```typescript
const { requestPurchase, currentPurchase, finishTransaction } = useIAP();

// Request purchase
await requestPurchase({
  request: {
    sku: "product1",
  },
  type: "inapp",
});

// Handle purchase completion
useEffect(() => {
  if (currentPurchase) {
    const completePurchase = async () => {
      // Deliver content
      await deliverProduct(currentPurchase);

      // Finish transaction
      await finishTransaction({
        purchase: currentPurchase,
        isConsumable: true,
      });
    };

    completePurchase();
  }
}, [currentPurchase]);
```

**flutter_inapp_purchase:**

```dart
StreamSubscription? _purchaseSubscription;

@override
void initState() {
  super.initState();

  // Listen to purchase updates
  _purchaseSubscription = FlutterInappPurchase.instance
      .purchaseUpdated.listen((productItem) {
    if (productItem != null) {
      _handlePurchaseUpdate(productItem);
    }
  });
}

// Request purchase
Future<void> _requestPurchase(String productId) async {
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
}

// Handle purchase completion
void _handlePurchaseUpdate(Purchase item) async {
  // Deliver content
  await _deliverProduct(item);

  // Finish transaction
  if (Platform.isIOS) {
    await FlutterInappPurchase.instance.finishTransaction(
      purchase: item,
      isConsumable: true, // Set based on product type
    );
  } else {
    // Android - consume or acknowledge
    await FlutterInappPurchase.instance.consumePurchaseAndroid(
      purchaseToken: item.purchaseToken!,
    );
  }
}
```

## Data Model Mapping

### Product Information

**expo-iap Product:**

```typescript
interface Product {
  id: string;
  title: string;
  description: string;
  displayPrice: string;
  currency: string;
  type: "inapp" | "subs";
}
```

**flutter_inapp_purchase Product:**

```dart
class Product {
  String id;              // maps to id
  String title;           // same
  String description;     // same
  String displayPrice;    // same as displayPrice
  String currency;        // same
  ProductType type;       // InApp or Subs
}
```

### Purchase Information

**expo-iap Purchase:**

```typescript
interface Purchase {
  id: string;
  transactionId: string;
  transactionDate: number;
  transactionReceipt: string;
  platform: "ios" | "android";
}
```

**flutter_inapp_purchase Purchase:**

```dart
class Purchase {
  String? productId;           // maps to id
  String? transactionId;       // same
  int? transactionDate;        // same (timestamp)
  String? transactionReceipt;  // same
  // Platform determined by Platform.isIOS/isAndroid
}
```

## Migration Strategy

### Phase 1: Setup Flutter Environment

1. **Install Flutter SDK**
2. **Create new Flutter project**
3. **Add flutter_inapp_purchase dependency**

### Phase 2: Port Core Logic

1. **Convert hooks to StatefulWidget**
2. **Replace useEffect with initState/lifecycle methods**
3. **Convert async/await patterns**

### Phase 3: Migrate Purchase Flow

Here's a step-by-step migration of a typical store component:

**expo-iap Store Component:**

```typescript
import React, { useEffect } from "react";
import { useIAP } from "expo-iap";

export default function Store() {
  const {
    connected,
    products,
    getProducts,
    requestPurchase,
    currentPurchase,
    finishTransaction,
  } = useIAP();

  const productIds = ["coins_100", "remove_ads"];

  useEffect(() => {
    if (connected) {
      getProducts({ skus: productIds, type: "inapp" });
    }
  }, [connected]);

  useEffect(() => {
    if (currentPurchase) {
      handlePurchase();
    }
  }, [currentPurchase]);

  const handlePurchase = async () => {
    // Verify and deliver
    await finishTransaction({
      purchase: currentPurchase,
      isConsumable: currentPurchase.id === "coins_100",
    });
  };

  const buyProduct = async (productId: string) => {
    await requestPurchase({
      request: { sku: productId },
      type: "inapp",
    });
  };

  return (
    <div>
      {products.map((product) => (
        <button key={product.id} onClick={() => buyProduct(product.id)}>
          {product.title} - {product.displayPrice}
        </button>
      ))}
    </div>
  );
}
```

**Equivalent Flutter Widget:**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

class Store extends StatefulWidget {
  @override
  _StoreState createState() => _StoreState();
}

class _StoreState extends State<Store> {
  StreamSubscription? _purchaseSubscription;
  List<ProductCommon> products = [];
  bool connected = false;

  final List<String> productIds = ['coins_100', 'remove_ads'];

  @override
  void initState() {
    super.initState();
    _initializeStore();
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeStore() async {
    try {
      await FlutterInappPurchase.instance.initConnection();
      connected = true;

      _purchaseSubscription = FlutterInappPurchase.instance
          .purchaseUpdated.listen(_handlePurchase);

      await _loadProducts();
    } catch (e) {
      print('Store initialization failed: $e');
    }
  }

  Future<void> _loadProducts() async {
    if (connected) {
      try {
        final result = await FlutterInappPurchase.instance.fetchProducts(
          ProductRequest(
            skus: productIds,
            type: ProductQueryType.InApp,
          ),
        );
        setState(() {
          products = result.value;
        });
      } catch (e) {
        print('Failed to get products: $e');
      }
    }
  }

  void _handlePurchase(Purchase? item) async {
    if (item == null) return;

    try {
      // Verify and deliver content here

      // Finish transaction
      if (Platform.isIOS) {
        await FlutterInappPurchase.instance.finishTransaction(
          purchase: item,
          isConsumable: item.productId == 'coins_100',
        );
      } else {
        // Determine if consumable
        bool isConsumable = item.productId == 'coins_100';

        if (isConsumable) {
          await FlutterInappPurchase.instance.consumePurchaseAndroid(
            purchaseToken: item.purchaseToken!,
          );
        } else {
          await FlutterInappPurchase.instance.acknowledgePurchaseAndroid(
            purchaseToken: item.purchaseToken!,
          );
        }
      }
    } catch (e) {
      print('Failed to handle purchase: $e');
    }
  }

  Future<void> _buyProduct(String productId) async {
    try {
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
    } catch (e) {
      print('Purchase failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Store')),
      body: ListView.builder(
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return ListTile(
            title: Text(product.title),
            subtitle: Text(product.displayPrice),
            onTap: () => _buyProduct(product.id),
          );
        },
      ),
    );
  }
}
```

## Platform-Specific Considerations

### iOS Differences

**expo-iap:**

- Handles StoreKit automatically
- Receipt validation built-in

**flutter_inapp_purchase:**

- Must call `finishTransaction` for all purchases
- Manual receipt validation setup

### Android Differences

**expo-iap:**

- Auto-acknowledgment handling
- Simplified billing flow

**flutter_inapp_purchase:**

- Manual consume/acknowledge required
- More granular control over billing

## Common Migration Challenges

### 1. State Management

**Challenge:** Converting React hooks to Flutter state
**Solution:** Use StatefulWidget or state management solutions like Provider

### 2. Async Patterns

**Challenge:** Different async handling between JS and Dart
**Solution:** Use Flutter's Future/Stream patterns consistently

### 3. Platform Handling

**Challenge:** More explicit platform handling required
**Solution:** Use Platform.isIOS/isAndroid checks

### 4. Error Handling

**Challenge:** Different error structures
**Solution:** Implement comprehensive try-catch blocks

## Testing Migration

1. **Unit Tests:** Test individual purchase functions
2. **Integration Tests:** Test complete purchase flows
3. **Platform Tests:** Test on both iOS and Android
4. **Store Tests:** Test with sandbox/test environments

## Benefits of Migration

1. **Native Performance:** Flutter's native compilation
2. **Single Codebase:** Write once, run on both platforms
3. **Rich UI:** Flutter's comprehensive widget system
4. **Growing Ecosystem:** Active Flutter community

## Migration Checklist

- [ ] Set up Flutter development environment
- [ ] Create new Flutter project structure
- [ ] Convert React components to Flutter widgets
- [ ] Migrate purchase logic to stream-based approach
- [ ] Implement platform-specific transaction handling
- [ ] Set up proper error handling
- [ ] Test purchase flows on both platforms
- [ ] Implement receipt validation
- [ ] Test with sandbox accounts
- [ ] Performance testing and optimization

## Need Help?

- [flutter_inapp_purchase Examples](../examples/basic-store)
- [API Documentation](../api/overview)
- [GitHub Issues](https://github.com/hyochan/flutter_inapp_purchase/issues)
- [Flutter Community](https://flutter.dev/community)
