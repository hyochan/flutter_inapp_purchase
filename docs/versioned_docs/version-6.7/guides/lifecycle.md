---
sidebar_position: 7
title: Lifecycle
---

# Lifecycle

For complete understanding of the in-app purchase lifecycle, flow diagrams, and state management, please visit:

👉 **[Lifecycle Documentation - openiap.dev](https://openiap.dev/docs/lifecycle)**

![Purchase Flow](https://openiap.dev/purchase-flow.png)

The Open IAP specification provides detailed documentation on:

- Complete purchase flow
- State transitions and management
- Connection lifecycle
- Error recovery patterns
- Platform-specific considerations

## Lifecycle Overview

The in-app purchase lifecycle consists of several key phases:

1. **Store Connection** - Establishing connection with platform stores
2. **Product Loading** - Fetching available products and pricing
3. **Purchase Initiation** - User-triggered purchase requests
4. **Transaction Processing** - Platform-handled payment flow
5. **Purchase Completion** - Successful transaction receipt
6. **Content Delivery** - Providing purchased content to user
7. **Transaction Finalization** - Consuming/acknowledging purchases

Each phase has its own requirements and potential failure modes that need proper handling.

## Connection Management

### Connection States

Monitor connection states to provide appropriate user feedback:

```dart
enum ConnectionState {
  disconnected,
  connecting,
  connected,
  error,
}

class ConnectionManager {
  ConnectionState _state = ConnectionState.disconnected;
  String? _errorMessage;

  ConnectionState get state => _state;
  String? get errorMessage => _errorMessage;

  Future<void> connect() async {
    _setState(ConnectionState.connecting);

    try {
      await FlutterInappPurchase.instance.initConnection();
      _setState(ConnectionState.connected);
    } catch (e) {
      _setState(ConnectionState.error, e.toString());
    }
  }

  void _setState(ConnectionState newState, [String? error]) {
    _state = newState;
    _errorMessage = error;
    // Notify listeners of state change
    notifyListeners();
  }
}
```

## Component Lifecycle Integration

### Class Components

Integrate IAP lifecycle with Flutter widget lifecycle:

```dart
class PurchaseScreen extends StatefulWidget {
  @override
  _PurchaseScreenState createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen>
    with WidgetsBindingObserver {

  StreamSubscription<Purchase?>? _purchaseSubscription;
  StreamSubscription<PurchaseResult?>? _errorSubscription;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupPurchaseListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _purchaseSubscription?.cancel();
    _errorSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // App resumed - check for pending purchases
        _checkPendingPurchases();
        break;
      case AppLifecycleState.paused:
        // App paused - save any pending state
        _savePendingState();
        break;
      case AppLifecycleState.detached:
        // App closing - cleanup resources
        _cleanup();
        break;
      default:
        break;
    }
  }

  void _setupPurchaseListeners() {
    _purchaseSubscription = FlutterInappPurchase.purchaseUpdated.listen(
      (purchase) {
        if (purchase != null && mounted) {
          setState(() => _isProcessing = false);
          _handlePurchaseSuccess(purchase);
        }
      },
    );

    _errorSubscription = FlutterInappPurchase.purchaseError.listen(
      (error) {
        if (error != null && mounted) {
          setState(() => _isProcessing = false);
          _handlePurchaseError(error);
        }
      },
    );
  }
}
```

## Best Practices

### ✅ Do

- **Initialize connections early** in your app lifecycle
- **Set up purchase listeners** before making any purchase requests
- **Handle app state changes** (background/foreground transitions)
- **Implement retry logic** for failed connections
- **Clean up resources** properly in dispose methods
- **Check for pending purchases** when app resumes
- **Validate purchases server-side** for security
- **Provide user feedback** during purchase processing
- **Handle network interruptions** gracefully
- **Test on different devices** and OS versions

```dart
// Good: Comprehensive lifecycle management
class GoodPurchaseManager extends WidgetsBindingObserver {
  void initialize() {
    WidgetsBinding.instance.addObserver(this);
    _setupListeners();
    _ensureConnection();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPendingTransactions();
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cleanup();
  }
}
```

### ❌ Don't

- **Make purchases without listeners** set up first
- **Ignore connection state** when making requests
- **Block UI indefinitely** during purchase processing
- **Store sensitive data** in local storage
- **Trust client-side validation** alone
- **Forget to handle edge cases** (network issues, app backgrounding)
- **Leave connections open** when not needed
- **Assume purchases complete immediately**
- **Skip testing** in sandbox environments
- **Ignore platform differences**

```dart
// Bad: No lifecycle management
class BadPurchaseManager {
  void makePurchase(String productId) {
    // Bad: No connection check
    // Bad: No listeners set up
    // Bad: No error handling
    FlutterInappPurchase.instance.requestPurchase(/*...*/);
  }
}
```

## Purchase Flow Best Practices

### Receipt Validation and Security

Always validate purchases server-side:

```dart
class SecurePurchaseValidator {
  static Future<bool> validatePurchase(Purchase purchase) async {
    try {
      if (Platform.isIOS) {
        // iOS receipt validation
        final result = await FlutterInappPurchase.instance.validateReceiptIos(
          receiptBody: {
            'receipt-data': purchase.transactionReceipt,
            'password': 'your-shared-secret',
          },
          isTest: false, // Set based on environment
        );

        return result != null && result['status'] == 0;
      } else if (Platform.isAndroid) {
        // Android purchase validation
        final result = await FlutterInappPurchase.instance.validateReceiptAndroid(
          packageName: 'your.package.name',
          productId: purchase.productId!,
          productToken: purchase.purchaseToken!,
          accessToken: 'your-access-token',
          isSubscription: false,
        );

        return result != null;
      }

      return false;
    } catch (e) {
      debugPrint('Validation failed: $e');
      return false;
    }
  }
}
```

### Purchase State Management

Track purchase states throughout the lifecycle:

```dart
enum PurchaseState {
  idle,
  loading,
  processing,
  validating,
  delivering,
  completed,
  error,
}

class PurchaseStateManager {
  PurchaseState _state = PurchaseState.idle;
  String? _currentProductId;
  String? _errorMessage;

  PurchaseState get state => _state;
  String? get currentProductId => _currentProductId;
  String? get errorMessage => _errorMessage;

  Future<void> initiatePurchase(String productId) async {
    _updateState(PurchaseState.loading, productId);

    try {
      // Check connection
      final connected = await _ensureConnection();
      if (!connected) {
        throw Exception('Store connection failed');
      }

      _updateState(PurchaseState.processing, productId);

      await FlutterInappPurchase.instance.requestPurchase(
        request: RequestPurchase(
          ios: RequestPurchaseIOS(sku: productId),
          android: RequestPurchaseAndroid(skus: [productId]),
        ),
        type: PurchaseType.inapp,
      );

    } catch (e) {
      _updateState(PurchaseState.error, productId, e.toString());
    }
  }

  void _updateState(PurchaseState newState, [String? productId, String? error]) {
    _state = newState;
    _currentProductId = productId;
    _errorMessage = error;
    notifyListeners();
  }
}
```

## Error Handling and User Experience

### Comprehensive Error Handling

```dart
class PurchaseErrorHandler {
  static void handlePurchaseError(PurchaseResult error, BuildContext context) {
    String userMessage;
    bool shouldRetry = false;

    switch (error.responseCode) {
      case 1: // User cancelled
        userMessage = 'Purchase was cancelled';
        break;
      case 2: // Network error
        userMessage = 'Network error. Please check your connection and try again.';
        shouldRetry = true;
        break;
      case 3: // Billing unavailable
        userMessage = 'Purchases are not available on this device';
        break;
      case 4: // Item unavailable
        userMessage = 'This item is currently unavailable';
        break;
      case 5: // Developer error
        userMessage = 'Configuration error. Please try again later.';
        break;
      case 7: // Item already owned
        userMessage = 'You already own this item';
        _handleAlreadyOwned(error);
        return;
      default:
        userMessage = 'Purchase failed: ${error.message ?? 'Unknown error'}';
    }

    _showErrorDialog(context, userMessage, shouldRetry);
  }

  static void _showErrorDialog(BuildContext context, String message, bool showRetry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Purchase Error'),
        content: Text(message),
        actions: [
          if (showRetry)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Implement retry logic
              },
              child: Text('Retry'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}
```

## Testing and Development

### Development Environment Setup

```dart
class DevelopmentHelpers {
  static bool get isDebugMode => kDebugMode;

  static Future<void> setupTestEnvironment() async {
    if (!isDebugMode) return;

    // Clear any existing transactions in debug mode
    try {
      await FlutterInappPurchase.instance.clearTransactionCache();
      debugPrint('Cleared transaction cache for testing');
    } catch (e) {
      debugPrint('Failed to clear transaction cache: $e');
    }
  }

  static void logPurchaseState(String state, [Map<String, dynamic>? data]) {
    if (!isDebugMode) return;

    debugPrint('Purchase State: $state');
    if (data != null) {
      data.forEach((key, value) {
        debugPrint('  $key: $value');
      });
    }
  }
}
```

## Common Pitfalls and Solutions

### Transaction Management Issues

**Problem**: Purchases getting stuck in pending state

```dart
// Solution: Implement proper transaction cleanup
class TransactionCleanup {
  static Future<void> cleanupPendingTransactions() async {
    try {
      // Restore purchases to get all pending transactions
      await FlutterInappPurchase.instance.restorePurchases();

      // Get available purchases
      final purchases = await FlutterInappPurchase.instance.getAvailablePurchases();

      // Process each pending purchase
      for (final purchase in purchases) {
        await _finalizePurchase(purchase);
      }
    } catch (e) {
      debugPrint('Error cleaning up transactions: $e');
    }
  }

  static Future<void> _finalizePurchase(Purchase purchase) async {
    // Validate and deliver content first
    final isValid = await _validatePurchase(purchase);
    if (!isValid) return;

    await _deliverContent(purchase);

    // Then finalize the transaction
    if (Platform.isAndroid) {
      await FlutterInappPurchase.instance.consumePurchaseAndroid(
        purchaseToken: purchase.purchaseToken!,
      );
    } else if (Platform.isIOS) {
      await FlutterInappPurchase.instance.finishTransactionIOS(
        purchase,
        isConsumable: _isConsumable(purchase.productId),
      );
    }
  }
}
```

### Security Issues

**Problem**: Client-side only validation

```dart
// Solution: Always validate server-side
class SecurityBestPractices {
  static Future<bool> secureValidation(Purchase purchase) async {
    // 1. Client-side basic checks
    if (purchase.productId == null || purchase.transactionReceipt == null) {
      return false;
    }

    // 2. Server-side validation (critical)
    final serverValid = await _validateWithServer(purchase);
    if (!serverValid) return false;

    // 3. Business logic validation
    final businessValid = await _validateBusinessRules(purchase);

    return businessValid;
  }
}
```

### Development and Testing Issues

**Problem**: Different behavior in sandbox vs production

```dart
// Solution: Environment-aware configuration
class EnvironmentConfig {
  static bool get isProduction => !kDebugMode && _isProductionBuild();
  static bool get isSandbox => kDebugMode || _isSandboxBuild();

  static String get validationEndpoint => isProduction
    ? 'https://buy.itunes.apple.com/verifyReceipt'
    : 'https://sandbox.itunes.apple.com/verifyReceipt';

  static bool _isProductionBuild() {
    // Add your production detection logic
    return false;
  }

  static bool _isSandboxBuild() {
    // Add your sandbox detection logic
    return true;
  }
}
```

### App Lifecycle Issues

**Problem**: Purchases interrupted by app backgrounding

```dart
// Solution: Implement proper app lifecycle handling
class LifecycleAwarePurchaseManager extends WidgetsBindingObserver {
  Map<String, PurchaseState> _pendingPurchases = {};

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _resumePendingPurchases();
        break;
      case AppLifecycleState.paused:
        _savePendingPurchases();
        break;
      default:
        break;
    }
  }

  void _resumePendingPurchases() {
    // Check for any purchases that completed while app was backgrounded
    FlutterInappPurchase.instance.restorePurchases();
  }

  void _savePendingPurchases() {
    // Persist pending purchase state
    // This helps recover from app kills during purchase
  }
}
```

### Connection Management Issues

**Problem**: Connection drops during purchase flow

```dart
// Solution: Implement connection resilience
class ResilientConnectionManager {
  static Future<bool> ensureConnectionWithRetry() async {
    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        await FlutterInappPurchase.instance.initConnection();
        return true;
      } catch (e) {
        debugPrint('Connection attempt $attempt failed: $e');

        if (attempt < 3) {
          await Future.delayed(Duration(seconds: attempt * 2));
        }
      }
    }

    return false;
  }
}
```

## Next Steps

After implementing proper lifecycle management:

1. **Test thoroughly** in both sandbox and production environments
2. **Monitor purchase analytics** to identify lifecycle issues
3. **Implement proper logging** for debugging purchase flows
4. **Set up alerts** for purchase failures and anomalies
5. **Review and optimize** purchase success rates
6. **Consider advanced features** like promotional offers and subscription management

For more detailed guidance on specific purchase flows, see:

- [Purchases Guide](./purchases.md) - Complete purchase implementation
- [Offer Code Redemption](./offer-code-redemption.md) - Promotional offers
- [Troubleshooting](./troubleshooting.md) - Common issues and solutions
