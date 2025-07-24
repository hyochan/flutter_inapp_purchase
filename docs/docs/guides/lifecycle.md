---
sidebar_position: 7
<<<<<<< HEAD
<<<<<<< HEAD
title: Lifecycle
---

# Lifecycle

Understanding and managing the in-app purchase lifecycle is crucial for creating robust and reliable purchase experiences.

![Purchase Lifecycle](https://expo-iap.hyo.dev/assets/images/lifecycle-882aa01ea00089e05a08f19581d9b349.svg)

The purchase lifecycle involves multiple interconnected states and transitions, from initial store connection through purchase completion and transaction finalization. Understanding this flow helps you build resilient purchase systems that handle edge cases gracefully.

While this diagram is from expo-iap, flutter_inapp_purchase follows the exact same design patterns and flow, making this lifecycle representation identical for both libraries.

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

## Connection Management with useIAP

### Automatic Connection

The flutter_inapp_purchase plugin manages connections automatically through the `IapProvider`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

class IapProviderWidget extends StatefulWidget {
  final Widget child;

  const IapProviderWidget({required this.child, Key? key}) : super(key: key);

  @override
  State<IapProviderWidget> createState() => _IapProviderWidgetState();
}

class _IapProviderWidgetState extends State<IapProviderWidget> {
  final FlutterInappPurchase _iap = FlutterInappPurchase.instance;
  
  bool _connected = false;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Automatically initialize connection when provider is created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initConnection();
    });
  }

  Future<void> _initConnection() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _iap.initConnection();
      
      // Set up purchase listeners
      _setupPurchaseListeners();
      
      setState(() {
        _connected = true;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
        _connected = false;
      });
    }
  }

  @override
  void dispose() {
    _endConnection();
    super.dispose();
  }

  Future<void> _endConnection() async {
    try {
      await _iap.finalize();
      setState(() {
        _connected = false;
      });
    } catch (e) {
      debugPrint('Error ending connection: $e');
    }
=======
title: Lifecycle Management
=======
title: Lifecycle
>>>>>>> 40157f9 (docs: Update guides and examples content)
---

# Lifecycle

Understanding and managing the in-app purchase lifecycle is crucial for creating robust and reliable purchase experiences.

![Purchase Lifecycle](https://expo-iap.hyo.dev/assets/images/lifecycle-882aa01ea00089e05a08f19581d9b349.svg)

The purchase lifecycle involves multiple interconnected states and transitions, from initial store connection through purchase completion and transaction finalization. Understanding this flow helps you build resilient purchase systems that handle edge cases gracefully.

While this diagram is from expo-iap, flutter_inapp_purchase follows the exact same design patterns and flow, making this lifecycle representation identical for both libraries.

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

## Connection Management with useIAP

### Automatic Connection

The flutter_inapp_purchase plugin manages connections automatically through the `IapProvider`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

class IapProviderWidget extends StatefulWidget {
  final Widget child;

  const IapProviderWidget({required this.child, Key? key}) : super(key: key);

  @override
  State<IapProviderWidget> createState() => _IapProviderWidgetState();
}

class _IapProviderWidgetState extends State<IapProviderWidget> {
  final FlutterInappPurchase _iap = FlutterInappPurchase.instance;
  
  bool _connected = false;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Automatically initialize connection when provider is created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initConnection();
    });
  }

  Future<void> _initConnection() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _iap.initConnection();
      
      // Set up purchase listeners
      _setupPurchaseListeners();
      
      setState(() {
        _connected = true;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
        _connected = false;
      });
    }
  }

  @override
  void dispose() {
    _endConnection();
<<<<<<< HEAD
>>>>>>> 5e86ee0 (docs: Update community links and fix configuration)
=======
    super.dispose();
  }

  Future<void> _endConnection() async {
    try {
      await _iap.finalize();
      setState(() {
        _connected = false;
      });
    } catch (e) {
      debugPrint('Error ending connection: $e');
    }
>>>>>>> 40157f9 (docs: Update guides and examples content)
  }
}
```

<<<<<<< HEAD
<<<<<<< HEAD
### Connection States

Monitor connection states to provide appropriate user feedback:

```dart
=======
### Connection State Management

```dart
class ConnectionManager {
  final _iap = FlutterInappPurchase.instance;
  final _connectionStateController = StreamController<ConnectionState>.broadcast();
  
  ConnectionState _currentState = ConnectionState.disconnected;
  DateTime? _lastConnectionTime;
  
  Stream<ConnectionState> get connectionState => _connectionStateController.stream;
  ConnectionState get currentState => _currentState;
  
  Future<void> initializeConnection() async {
    if (_currentState == ConnectionState.connected) {
      print('Already connected');
      return;
    }
    
    _updateState(ConnectionState.connecting);
    
    try {
      await _iap.initConnection();
      _lastConnectionTime = DateTime.now();
      _updateState(ConnectionState.connected);
      
      // Setup purchase listeners after connection
      _setupPurchaseListeners();
      
      // Check connection health periodically
      _startConnectionHealthCheck();
      
    } catch (e) {
      print('Connection failed: $e');
      _updateState(ConnectionState.error);
      
      // Retry with exponential backoff
      _scheduleConnectionRetry();
    }
  }
  
  void _updateState(ConnectionState newState) {
    _currentState = newState;
    _connectionStateController.add(newState);
  }
  
  void _startConnectionHealthCheck() {
    Timer.periodic(Duration(minutes: 5), (timer) async {
      if (_currentState != ConnectionState.connected) {
        timer.cancel();
        return;
      }
      
      try {
        // Verify connection is still active
        await _iap.getProducts(['health_check']);
      } catch (e) {
        print('Connection health check failed');
        _updateState(ConnectionState.error);
        timer.cancel();
        
        // Attempt reconnection
        await initializeConnection();
      }
    });
  }
}

>>>>>>> 5e86ee0 (docs: Update community links and fix configuration)
=======
### Connection States

Monitor connection states to provide appropriate user feedback:

```dart
>>>>>>> 40157f9 (docs: Update guides and examples content)
enum ConnectionState {
  disconnected,
  connecting,
  connected,
  error,
}
<<<<<<< HEAD
<<<<<<< HEAD

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
=======
```
=======
>>>>>>> 40157f9 (docs: Update guides and examples content)

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
  
<<<<<<< HEAD
  void _handlePurchaseUpdate(PurchasedItem? purchase) {
    if (purchase == null) return;
    
    final productId = purchase.productId;
    if (productId == null) return;
    
    // Update transaction state based on purchase state
    if (Platform.isAndroid) {
      switch (purchase.purchaseStateAndroid) {
        case 0: // Unspecified
          _transactionTracker.trackTransaction(productId, 'processing');
          break;
        case 1: // Purchased
          _transactionTracker.trackTransaction(productId, 'purchased');
          _processPurchasedItem(purchase);
          break;
        case 2: // Pending
          _transactionTracker.trackTransaction(productId, 'pending');
          _handlePendingPurchase(purchase);
          break;
      }
    } else {
      // iOS purchases
      _transactionTracker.trackTransaction(productId, 'purchased');
      _processPurchasedItem(purchase);
    }
  }
  
  void _handlePurchaseError(PurchaseResult? error) {
    if (error == null) return;
    
    // Extract product ID from error if possible
    final productId = _extractProductIdFromError(error);
    if (productId != null) {
      _transactionTracker.trackTransaction(productId, 'failed');
    }
    
    // Clean up failed transaction
    _cleanupFailedTransaction(productId);
  }
  
  Future<void> _processPurchasedItem(PurchasedItem purchase) async {
    final productId = purchase.productId!;
    
    try {
      // 1. Verify purchase
      final isValid = await _verifyPurchase(purchase);
      if (!isValid) {
        throw Exception('Invalid purchase');
      }
      
      // 2. Deliver content
      await _deliverContent(purchase);
      
      // 3. Finish transaction
      await _finishTransaction(purchase);
      
      // 4. Update state
      _transactionTracker.trackTransaction(productId, 'finished');
      
      // 5. Clean up
      await _cleanupCompletedTransaction(productId);
      
    } catch (e) {
      print('Failed to process purchase: $e');
      // Don't finish transaction on error
      // User can retry or restore
    }
  }
  
  Future<void> _finishTransaction(PurchasedItem purchase) async {
    final isConsumable = _isConsumableProduct(purchase.productId);
    
    await _iap.finishTransactionIOS(
      purchase,
      isConsumable: isConsumable,
    );
>>>>>>> 5e86ee0 (docs: Update community links and fix configuration)
=======
  void _setState(ConnectionState newState, [String? error]) {
    _state = newState;
    _errorMessage = error;
    // Notify listeners of state change
    notifyListeners();
>>>>>>> 40157f9 (docs: Update guides and examples content)
  }
}
```

<<<<<<< HEAD
<<<<<<< HEAD

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
  
  StreamSubscription<PurchasedItem?>? _purchaseSubscription;
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
=======
## State Restoration
=======
>>>>>>> 40157f9 (docs: Update guides and examples content)

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
  
  StreamSubscription<PurchasedItem?>? _purchaseSubscription;
  StreamSubscription<PurchaseResult?>? _errorSubscription;
  bool _isProcessing = false;
  
<<<<<<< HEAD
  Future<void> addTransaction(TransactionRequest request) async {
    // Add to queue
    _queue.add(request);
    
    // Persist queue state
    await _saveQueueState();
    
    // Process queue
    _processQueue();
  }
  
  Future<void> restoreQueue() async {
    // Load persisted queue
    final savedQueue = await _storage.loadTransactionQueue();
    
    for (final request in savedQueue) {
      if (!request.isExpired) {
        _queue.add(request);
      }
    }
    
    // Start processing
    if (_queue.isNotEmpty) {
      _processQueue();
    }
  }
  
  Future<void> _processQueue() async {
    if (_isProcessing || _queue.isEmpty) return;
    
    _isProcessing = true;
    
    while (_queue.isNotEmpty) {
      final request = _queue.first;
      
      try {
        print('Processing queued transaction: ${request.productId}');
        
        // Process the transaction
        await _processTransaction(request);
        
        // Remove from queue on success
        _queue.removeFirst();
        await _saveQueueState();
        
      } catch (e) {
        print('Failed to process transaction: $e');
        
        if (request.retryCount < 3) {
          // Retry with backoff
          request.retryCount++;
          await Future.delayed(
            Duration(seconds: math.pow(2, request.retryCount).toInt()),
          );
        } else {
          // Max retries reached, remove from queue
          _queue.removeFirst();
          await _saveQueueState();
          
          // Notify user
          _notifyTransactionFailed(request);
        }
      }
    }
    
    _isProcessing = false;
  }
  
  Future<void> _saveQueueState() async {
    await _storage.saveTransactionQueue(_queue.toList());
  }
}

class TransactionRequest {
  final String productId;
  final String type;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;
  int retryCount;
  
  TransactionRequest({
    required this.productId,
    required this.type,
    required this.metadata,
    this.retryCount = 0,
  }) : timestamp = DateTime.now();
  
  bool get isExpired => 
      DateTime.now().difference(timestamp) > Duration(days: 7);
  
  Map<String, dynamic> toJson() => {
    'productId': productId,
    'type': type,
    'timestamp': timestamp.toIso8601String(),
    'metadata': metadata,
    'retryCount': retryCount,
  };
  
  factory TransactionRequest.fromJson(Map<String, dynamic> json) {
    return TransactionRequest(
      productId: json['productId'],
      type: json['type'],
      metadata: json['metadata'],
      retryCount: json['retryCount'] ?? 0,
>>>>>>> 5e86ee0 (docs: Update community links and fix configuration)
    );
  }
}
```

<<<<<<< HEAD
### Functional Components

Using hooks or similar patterns for functional components:

```dart
// Custom hook for IAP lifecycle management
class IapHook {
  late StreamSubscription<PurchasedItem?>? _purchaseSubscription;
  late StreamSubscription<PurchaseResult?>? _errorSubscription;
  
  void initialize(
    Function(PurchasedItem) onPurchase,
    Function(PurchaseResult) onError,
  ) {
    _purchaseSubscription = FlutterInappPurchase.purchaseUpdated.listen(
      (purchase) {
        if (purchase != null) {
          onPurchase(purchase);
        }
      },
    );
    
    _errorSubscription = FlutterInappPurchase.purchaseError.listen(
      (error) {
        if (error != null) {
          onError(error);
        }
      },
    );
  }
  
  void dispose() {
    _purchaseSubscription?.cancel();
    _errorSubscription?.cancel();
=======
## Background Purchase Handling

### iOS Background Transactions

```dart
class IOSBackgroundPurchaseHandler {
  final _iap = FlutterInappPurchase.instance;
  final _notificationService = LocalNotificationService();
  
  void setupBackgroundHandling() {
    if (!Platform.isIOS) return;
    
    // Listen for transactions that complete in background
    _setupTransactionObserver();
  }
  
  void _setupTransactionObserver() {
    // Check for pending transactions on app launch
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _checkPendingTransactions();
    });
  }
  
  Future<void> _checkPendingTransactions() async {
    try {
      // Get all unfinished transactions
      final pending = await _iap.getAvailableItemsIOS();
      
      if (pending != null && pending.isNotEmpty) {
        print('Found ${pending.length} pending transactions');
        
        for (final transaction in pending) {
          if (_isBackgroundTransaction(transaction)) {
            await _handleBackgroundTransaction(transaction);
          }
        }
      }
    } catch (e) {
      print('Error checking pending transactions: $e');
    }
  }
  
  bool _isBackgroundTransaction(PurchasedItem item) {
    // Check if transaction was initiated while app was in background
    final transactionDate = item.transactionDate != null
        ? DateTime.fromMillisecondsSinceEpoch(item.transactionDate!)
        : null;
    
    if (transactionDate == null) return false;
    
    // Compare with app launch time
    final appLaunchTime = AppLifecycleTracker.lastLaunchTime;
    return transactionDate.isBefore(appLaunchTime);
  }
  
  Future<void> _handleBackgroundTransaction(PurchasedItem transaction) async {
    print('Processing background transaction: ${transaction.productId}');
    
    // 1. Verify the purchase
    final isValid = await _verifyPurchase(transaction);
    if (!isValid) {
      print('Invalid background transaction');
      return;
    }
    
    // 2. Deliver content
    await _deliverContent(transaction);
    
    // 3. Notify user
    await _notifyUserOfBackgroundPurchase(transaction);
    
    // 4. Finish transaction
    await _finishTransaction(transaction);
  }
  
  Future<void> _notifyUserOfBackgroundPurchase(PurchasedItem purchase) async {
    await _notificationService.showNotification(
      title: 'Purchase Complete',
      body: 'Your purchase of ${purchase.title} has been processed.',
      payload: json.encode({
        'type': 'background_purchase',
        'productId': purchase.productId,
        'transactionId': purchase.transactionId,
      }),
    );
  }
}
```

### Android Pending Purchases

```dart
class AndroidPendingPurchaseHandler {
  final _iap = FlutterInappPurchase.instance;
  Timer? _pendingCheckTimer;
  
  void initialize() {
    if (!Platform.isAndroid) return;
    
    // Enable pending purchases
    _enablePendingPurchases();
    
    // Setup periodic check for pending purchases
    _startPendingPurchaseCheck();
  }
  
  void _enablePendingPurchases() {
    // Pending purchases are automatically enabled in newer versions
    // This is handled by the plugin
  }
  
  void _startPendingPurchaseCheck() {
    // Check every 30 minutes for pending purchases
    _pendingCheckTimer = Timer.periodic(Duration(minutes: 30), (_) async {
      await _checkForPendingPurchases();
    });
  }
  
  Future<void> _checkForPendingPurchases() async {
    try {
      // Query purchases to check for pending state
      final purchases = await _iap.getPurchaseHistory();
      
      for (final purchase in purchases ?? []) {
        if (purchase.purchaseStateAndroid == 2) { // Pending state
          await _handlePendingPurchase(purchase);
        }
      }
    } catch (e) {
      print('Error checking pending purchases: $e');
    }
  }
  
  Future<void> _handlePendingPurchase(PurchasedItem purchase) async {
    print('Found pending purchase: ${purchase.productId}');
    
    // Store pending purchase info
    await _storePendingPurchaseInfo(purchase);
    
    // Notify user
    _notifyUserOfPendingPurchase(purchase);
    
    // The purchase will complete through the normal purchase flow
    // when payment is confirmed
  }
  
  void dispose() {
    _pendingCheckTimer?.cancel();
  }
}
```

## Connection Recovery

### Automatic Reconnection

```dart
class ConnectionRecoveryManager {
  final _iap = FlutterInappPurchase.instance;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  
  static const maxReconnectAttempts = 5;
  static const baseReconnectDelay = 2; // seconds
  
  Future<void> handleConnectionLoss() async {
    print('Connection lost - initiating recovery');
    
    // Cancel any existing reconnect timer
    _reconnectTimer?.cancel();
    
    // Start reconnection process
    _attemptReconnection();
  }
  
  void _attemptReconnection() {
    if (_reconnectAttempts >= maxReconnectAttempts) {
      print('Max reconnection attempts reached');
      _notifyConnectionFailure();
      return;
    }
    
    _reconnectAttempts++;
    
    // Calculate delay with exponential backoff
    final delay = baseReconnectDelay * math.pow(2, _reconnectAttempts - 1);
    
    print('Reconnection attempt $_reconnectAttempts in ${delay}s');
    
    _reconnectTimer = Timer(Duration(seconds: delay.toInt()), () async {
      try {
        // Attempt to reconnect
        await _iap.initConnection();
        
        print('Reconnection successful');
        _reconnectAttempts = 0;
        
        // Restore state after reconnection
        await _restoreAfterReconnection();
        
      } catch (e) {
        print('Reconnection failed: $e');
        
        // Try again
        _attemptReconnection();
      }
    });
  }
  
  Future<void> _restoreAfterReconnection() async {
    // 1. Re-setup listeners
=======
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
>>>>>>> 40157f9 (docs: Update guides and examples content)
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

### Functional Components

Using hooks or similar patterns for functional components:

```dart
// Custom hook for IAP lifecycle management
class IapHook {
  late StreamSubscription<PurchasedItem?>? _purchaseSubscription;
  late StreamSubscription<PurchaseResult?>? _errorSubscription;
  
  void initialize(
    Function(PurchasedItem) onPurchase,
    Function(PurchaseResult) onError,
  ) {
    _purchaseSubscription = FlutterInappPurchase.purchaseUpdated.listen(
      (purchase) {
        if (purchase != null) {
          onPurchase(purchase);
        }
      },
    );
<<<<<<< HEAD
>>>>>>> 5e86ee0 (docs: Update community links and fix configuration)
=======
    
    _errorSubscription = FlutterInappPurchase.purchaseError.listen(
      (error) {
        if (error != null) {
          onError(error);
        }
      },
    );
  }
  
  void dispose() {
    _purchaseSubscription?.cancel();
    _errorSubscription?.cancel();
>>>>>>> 40157f9 (docs: Update guides and examples content)
  }
}
```

## Best Practices

<<<<<<< HEAD
<<<<<<< HEAD
### ✅ Do:

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

### ❌ Don't:

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
  static Future<bool> validatePurchase(PurchasedItem purchase) async {
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
  
  static Future<void> _finalizePurchase(PurchasedItem purchase) async {
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
  static Future<bool> secureValidation(PurchasedItem purchase) async {
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
=======
### Lifecycle Management Checklist
=======
### ✅ Do:
>>>>>>> 40157f9 (docs: Update guides and examples content)

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

### ❌ Don't:

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
  static Future<bool> validatePurchase(PurchasedItem purchase) async {
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
  
<<<<<<< HEAD
  // Test background purchase
  static Future<void> testBackgroundPurchase() async {
    // 1. Initiate purchase
    // 2. Background app
    // 3. Complete purchase externally
    // 4. Resume app
    // 5. Verify purchase processed
>>>>>>> 5e86ee0 (docs: Update community links and fix configuration)
=======
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
  
  static Future<void> _finalizePurchase(PurchasedItem purchase) async {
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
  static Future<bool> secureValidation(PurchasedItem purchase) async {
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
>>>>>>> 40157f9 (docs: Update guides and examples content)
  }
}
```

## Next Steps

<<<<<<< HEAD
<<<<<<< HEAD
=======
>>>>>>> 40157f9 (docs: Update guides and examples content)
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
<<<<<<< HEAD
- [Troubleshooting](./troubleshooting.md) - Common issues and solutions
=======
- Implement comprehensive error handling (see [Error Handling Guide](./error-handling.md))
- Setup purchase verification (see [Receipt Validation Guide](./receipt-validation.md))
- Handle promotional offers (see [Offer Code Redemption Guide](./offer-code-redemption.md))
- Review common issues (see [Troubleshooting Guide](./troubleshooting.md))
>>>>>>> 5e86ee0 (docs: Update community links and fix configuration)
=======
- [Troubleshooting](./troubleshooting.md) - Common issues and solutions
>>>>>>> 40157f9 (docs: Update guides and examples content)
