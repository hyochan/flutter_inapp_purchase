# IapProvider

The `IapProvider` is a Flutter widget that provides In-App Purchase functionality throughout your app using the InheritedWidget pattern. It manages the IAP connection and provides methods to interact with the store, with method names matching expo-iap's useIAP hook for consistency.

## Basic Usage

```dart
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

// Wrap your app with IapProviderWidget
void main() {
  runApp(
    IapProviderWidget(
      child: MyApp(),
    ),
  );
}

// Access IAP functionality in your widgets
class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final iapProvider = IapProvider.of(context);
    
    if (iapProvider == null) {
      return Text('IAP not available');
    }
    
    return Column(
      children: [
        Text('Connected: ${iapProvider.connected}'),
        Text('Products: ${iapProvider.products.length}'),
        // ... use other IAP features
      ],
    );
  }
}
```

## Properties

| Property | Type | Description |
|----------|------|-------------|
| `connected` | `bool` | Whether the store connection is established |
| `products` | `List<IAPItem>` | Available products |
| `promotedProductsIOS` | `List<PurchasedItem>` | iOS promoted products |
| `promotedProductIdIOS` | `String?` | Current iOS promoted product ID |
| `subscriptions` | `List<IAPItem>` | Available subscriptions |
| `purchaseHistories` | `List<PurchasedItem>` | Purchase history |
| `availablePurchases` | `List<PurchasedItem>` | Available purchases to restore |
| `currentPurchase` | `PurchasedItem?` | Current purchase being processed |
| `currentPurchaseError` | `PurchaseResult?` | Current purchase error |
| `promotedProductIOS` | `IAPItem?` | Current iOS promoted product |

## Methods

### Core Methods

#### `requestProducts`
Load products or subscriptions from the store.

```dart
await iapProvider.requestProducts(
  skus: ['product1', 'product2'],
  type: 'inapp', // or 'subs' for subscriptions
);
```

#### `requestPurchase`
Request a purchase for a product or subscription.

```dart
await iapProvider.requestPurchase(
  request: RequestPurchase(
    ios: RequestPurchaseIOS(sku: 'product1'),
    android: RequestPurchaseAndroid(skus: ['product1']),
  ),
  type: 'inapp', // or 'subs'
);
```

#### `finishTransaction`
Finish a transaction after delivering the product.

```dart
await iapProvider.finishTransaction(
  purchase: purchasedItem,
  isConsumable: true,
);
```

### Purchase Management

#### `getAvailablePurchases`
Get available purchases (restored purchases).

```dart
await iapProvider.getAvailablePurchases(['sku1', 'sku2']);
```

#### `getPurchaseHistories`
Get purchase history.

```dart
await iapProvider.getPurchaseHistories(['sku1', 'sku2']);
```

#### `restorePurchases`
Restore previous purchases.

```dart
await iapProvider.restorePurchases();
```

### State Management

#### `clearCurrentPurchase`
Clear the current purchase state.

```dart
iapProvider.clearCurrentPurchase();
```

#### `clearCurrentPurchaseError`
Clear the current purchase error state.

```dart
iapProvider.clearCurrentPurchaseError();
```

### iOS Specific

#### `getPromotedProductIOS`
Get promoted product on iOS.

```dart
final promoted = await iapProvider.getPromotedProductIOS();
```

#### `buyPromotedProductIOS`
Buy the promoted product on iOS.

```dart
await iapProvider.buyPromotedProductIOS();
```

### Deprecated Methods

These methods are maintained for backward compatibility but will be removed in version 3.0.0:

- `getProducts(skus)` - Use `requestProducts({ skus, type: 'inapp' })` instead
- `getSubscriptions(skus)` - Use `requestProducts({ skus, type: 'subs' })` instead

## Example: Complete Purchase Flow

```dart
class ProductScreen extends StatefulWidget {
  @override
  _ProductScreenState createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  StreamSubscription<PurchasedItem?>? _purchaseSubscription;
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    final iapProvider = IapProvider.of(context);
    if (iapProvider != null) {
      // Listen to purchase updates
      _purchaseSubscription = iapProvider.purchaseUpdated.listen((purchase) {
        if (purchase != null) {
          _handlePurchaseUpdate(purchase);
        }
      });
      
      // Load products
      _loadProducts();
    }
  }
  
  Future<void> _loadProducts() async {
    final iapProvider = IapProvider.of(context);
    await iapProvider?.requestProducts(
      skus: ['product1', 'product2'],
      type: 'inapp',
    );
  }
  
  Future<void> _handlePurchaseUpdate(PurchasedItem purchase) async {
    final iapProvider = IapProvider.of(context);
    
    // Deliver the product
    await _deliverProduct(purchase);
    
    // Finish the transaction
    await iapProvider?.finishTransaction(
      purchase: purchase,
      isConsumable: true,
    );
  }
  
  Future<void> _purchaseProduct(String sku) async {
    final iapProvider = IapProvider.of(context);
    
    await iapProvider?.requestPurchase(
      request: RequestPurchase(
        ios: RequestPurchaseIOS(sku: sku),
        android: RequestPurchaseAndroid(skus: [sku]),
      ),
      type: 'inapp',
    );
  }
  
  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final iapProvider = IapProvider.of(context);
    
    return ListView.builder(
      itemCount: iapProvider?.products.length ?? 0,
      itemBuilder: (context, index) {
        final product = iapProvider!.products[index];
        return ListTile(
          title: Text(product.title ?? ''),
          subtitle: Text(product.localizedPrice ?? ''),
          trailing: ElevatedButton(
            onPressed: () => _purchaseProduct(product.productId ?? ''),
            child: Text('Buy'),
          ),
        );
      },
    );
  }
}
```

## Migration from expo-iap

The IapProvider API is designed to match expo-iap's useIAP hook closely. Key differences:

1. **Widget-based**: Uses Flutter's InheritedWidget pattern instead of React hooks
2. **Access pattern**: Use `IapProvider.of(context)` instead of `useIAP()`
3. **Lifecycle**: Wrap your app with `IapProviderWidget` to manage the connection lifecycle automatically

## See Also

- [Purchase Flow Guide](../guides/purchases.md)
- [Subscription Management](../guides/subscriptions.md)
- [Error Handling](../guides/error-handling.md)