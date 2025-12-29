import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:flutter_inapp_purchase/extensions/purchase_helpers.dart';
import '../widgets/product_detail_modal.dart';
import '../widgets/purchase_detail_view.dart';
import '../constants.dart';

class PurchaseFlowScreen extends StatefulWidget {
  const PurchaseFlowScreen({Key? key}) : super(key: key);

  @override
  State<PurchaseFlowScreen> createState() => _PurchaseFlowScreenState();
}

/// Verification method options
enum VerificationMethod { ignore, local, iapkit }

class _PurchaseFlowScreenState extends State<PurchaseFlowScreen> {
  final FlutterInappPurchase _iap = FlutterInappPurchase.instance;

  // Use product IDs from constants
  final List<String> productIds = IapConstants.inAppProductIds;

  List<ProductCommon> _products = [];
  final Map<String, ProductCommon> _originalProducts =
      {}; // Store original products for detail view
  bool _isProcessing = false;
  bool _connected = false;
  bool _loading = false;
  String? _purchaseResult;
  Purchase? _currentPurchase;
  StreamSubscription<Purchase>? _purchaseUpdatedSubscription;
  StreamSubscription<PurchaseError>? _purchaseErrorSubscription;
  final Set<String> _processedTransactionIds =
      {}; // Track processed transactions
  final Set<String> _processedErrorMessages =
      {}; // Track processed error messages
  VerificationMethod _verificationMethod = VerificationMethod.ignore;

  @override
  void initState() {
    super.initState();
    _initConnection();
  }

  @override
  void dispose() {
    _purchaseUpdatedSubscription?.cancel();
    _purchaseErrorSubscription?.cancel();
    _iap.endConnection();
    super.dispose();
  }

  /// Convert PlatformException to PurchaseError
  PurchaseError? _convertPlatformExceptionToPurchaseError(dynamic error) {
    if (error is! PlatformException) return null;

    final platform = defaultTargetPlatform == TargetPlatform.iOS
        ? IapPlatform.IOS
        : IapPlatform.Android;

    return PurchaseError.fromPlatformError({
      'code': error.code,
      'message': error.message ?? 'Unknown error',
      'details': error.details,
    }, platform);
  }

  Future<void> _initConnection() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
    });

    try {
      // End any existing connection first to reset configuration
      // This ensures we start fresh without alternative billing settings
      try {
        await _iap.endConnection();
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (e) {
        debugPrint('Note: endConnection failed (might not be connected): $e');
      }

      // Initialize with default settings (no alternative billing)
      await _iap.initConnection();
      if (!mounted) return;
      setState(() {
        _connected = true;
      });

      _setupPurchaseListeners();
      await _loadProducts();
    } catch (e) {
      debugPrint('Failed to initialize IAP connection: $e');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _setupPurchaseListeners() {
    debugPrint('Setting up purchase listeners...');

    // Listen to purchase updates (using new purchaseUpdatedListener)
    _purchaseUpdatedSubscription = _iap.purchaseUpdatedListener.listen(
      (purchase) {
        debugPrint('🎉 Purchase update received!');
        debugPrint('ProductId: ${purchase.productId}');
        debugPrint('ID: ${purchase.id}'); // OpenIAP standard
        final txId = purchase.transactionIdFor;
        debugPrint('TransactionId: ${txId ?? 'N/A'}');
        debugPrint('PurchaseToken: ${purchase.purchaseToken}');
        debugPrint('Full purchase data: $purchase');
        _handlePurchaseUpdate(purchase);
      },
      onError: (Object error) {
        debugPrint('❌ Purchase stream error: $error');
      },
      onDone: () {
        debugPrint('Purchase stream closed');
      },
    );

    // Listen to purchase errors (using new purchaseErrorListener)
    _purchaseErrorSubscription = _iap.purchaseErrorListener.listen(
      (purchaseError) {
        debugPrint('❌ Purchase error received!');
        debugPrint('Error code: ${purchaseError.code}');
        debugPrint('Error message: ${purchaseError.message}');

        // Prevent duplicate error handling
        final errorKey = purchaseError.message;
        if (_processedErrorMessages.contains(errorKey)) {
          debugPrint('ℹ️ Error already processed: $errorKey');
          return;
        }
        _processedErrorMessages.add(errorKey);

        _handlePurchaseError(purchaseError);
      },
      onError: (Object error) {
        debugPrint('❌ Error stream error: $error');
      },
    );

    debugPrint('Purchase listeners setup complete');
  }

  Future<void> _handlePurchaseUpdate(Purchase purchase) async {
    debugPrint('🎯 Purchase update received: ${purchase.productId}');
    debugPrint('  Platform: ${purchase.platform}');
    debugPrint('  Purchase state: ${purchase.purchaseState}');
    final transactionId = purchase.transactionIdFor;
    final androidStateValue = purchase.androidPurchaseStateValue;
    final iosTransactionState = purchase.iosTransactionState;
    final acknowledgedAndroid = purchase.androidIsAcknowledged;
    debugPrint('  Purchase state Android (legacy value): $androidStateValue');
    debugPrint('  Transaction state iOS: $iosTransactionState');
    debugPrint('  Is acknowledged Android: $acknowledgedAndroid');
    debugPrint('  Transaction ID: ${transactionId ?? 'N/A'}');
    debugPrint('  Purchase token: ${purchase.purchaseToken}');
    debugPrint('  ID: ${purchase.id} (${purchase.id.runtimeType})');
    debugPrint('  IDs array: ${purchase.ids}');
    if (purchase.platform == IapPlatform.IOS) {
      final quantityIOS = purchase.iosQuantity;
      final originalIdentifier = purchase.iosOriginalTransactionId;
      debugPrint('  quantityIOS: $quantityIOS');
      debugPrint(
        '  originalTransactionIdentifierIOS: $originalIdentifier (${originalIdentifier?.runtimeType})',
      );
    }

    if (!mounted) {
      debugPrint('  ⚠️ Widget not mounted, ignoring update');
      return;
    }

    // Check if we've already processed this transaction
    if (transactionId != null &&
        _processedTransactionIds.contains(transactionId)) {
      debugPrint('⚠️ Transaction already processed: $transactionId');
      return;
    }

    // Determine if purchase is successful using same logic as subscription flow
    bool isPurchased = false;

    if (!kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android &&
        purchase is PurchaseAndroid) {
      // For Android, check multiple conditions since fields can be null
      final bool condition1 = purchase.purchaseState == PurchaseState.Purchased;
      final bool condition2 = acknowledgedAndroid == false &&
          purchase.purchaseToken != null &&
          purchase.purchaseToken!.isNotEmpty &&
          purchase.purchaseState == PurchaseState.Purchased;
      final bool condition3 =
          androidStateValue == AndroidPurchaseState.Purchased.value;

      debugPrint('  Android condition checks:');
      debugPrint('    purchaseState == purchased: $condition1');
      debugPrint('    unacknowledged with token: $condition2');
      debugPrint(
          '    purchaseStateAndroid == AndroidPurchaseState.Purchased: $condition3');

      isPurchased = condition1 || condition2 || condition3;
      debugPrint('  Final isPurchased: $isPurchased');
    } else if (purchase is PurchaseIOS) {
      // For iOS - same logic as subscription flow
      final bool condition1 = iosTransactionState == TransactionState.purchased;
      bool condition2 =
          purchase.purchaseToken != null && purchase.purchaseToken!.isNotEmpty;
      final bool condition3 = transactionId != null;

      debugPrint('  iOS condition checks:');
      debugPrint('    transactionStateIOS == purchased: $condition1');
      debugPrint('    has valid purchaseToken: $condition2');
      debugPrint('    has valid transactionId: $condition3');

      // For iOS, receiving a purchase update usually means success
      isPurchased = condition1 || condition2 || condition3;
      debugPrint('  Final isPurchased: $isPurchased');
    }

    if (!isPurchased) {
      debugPrint('❓ Purchase not detected as successful');
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _purchaseResult = '''
⚠️ Purchase received but state unknown
Platform: ${purchase.platform}
Purchase state: ${purchase.purchaseState}
iOS transaction state: $iosTransactionState
Android purchase state (legacy value): $androidStateValue
Has token: ${purchase.purchaseToken != null && purchase.purchaseToken!.isNotEmpty}
        '''
            .trim();
      });
      return;
    }

    debugPrint('✅ Purchase detected as successful: ${purchase.productId}');
    debugPrint('Purchase token: ${purchase.purchaseToken}');
    debugPrint('ID: ${purchase.id}'); // OpenIAP standard
    debugPrint('Transaction ID: ${transactionId ?? 'N/A'}');

    // Mark this transaction as processed
    if (transactionId != null) {
      _processedTransactionIds.add(transactionId);
    }

    if (!mounted) return;
    setState(() {
      _isProcessing = false;
      _currentPurchase = purchase;

      final truncatedReceipt = purchase.purchaseToken == null
          ? 'N/A'
          : purchase.purchaseToken!.substring(
              0,
              purchase.purchaseToken!.length > 50
                  ? 50
                  : purchase.purchaseToken!.length,
            );
      final truncatedToken = purchase.purchaseToken == null
          ? 'N/A'
          : purchase.purchaseToken!.substring(
              0,
              purchase.purchaseToken!.length > 30
                  ? 30
                  : purchase.purchaseToken!.length,
            );

      // Format purchase result like KMP-IAP
      _purchaseResult = '''
✅ Purchase successful (${defaultTargetPlatform.name})
Product: ${purchase.productId}
ID: ${purchase.id.isNotEmpty ? purchase.id : "N/A"}
Transaction ID: ${transactionId ?? "N/A"}
Date: ${purchase.transactionDate ?? "N/A"}
Receipt: $truncatedReceipt...
Purchase Token: $truncatedToken...
      '''
          .trim();
    });

    // Perform verification based on selected method
    if (_verificationMethod == VerificationMethod.iapkit) {
      await _verifyPurchaseWithIAPKit(purchase);
    } else if (_verificationMethod == VerificationMethod.local) {
      await _verifyPurchaseLocally(purchase);
    }

    // After verification, finish the transaction
    // For consumable products (like bulb packs), set isConsumable to true
    try {
      await _iap.finishTransaction(
        purchase: purchase,
        isConsumable: true,
      );
      debugPrint('Transaction finished successfully');
      if (!mounted) return;
      setState(() {
        _purchaseResult =
            '$_purchaseResult\n\n✅ Transaction finished successfully';
      });
    } catch (e) {
      debugPrint('Error finishing transaction: $e');
      if (!mounted) return;
      setState(() {
        _purchaseResult =
            '$_purchaseResult\n\n❌ Failed to finish transaction: $e';
      });
    }
  }

  void _handlePurchaseError(PurchaseError error) {
    if (!mounted) return;
    setState(() {
      _isProcessing = false;

      _purchaseResult = '''
❌ Purchase Error
Code: ${error.code}
Message: ${error.message}
      '''
          .trim();
    });
  }

  /// Verify purchase using local platform verification
  Future<void> _verifyPurchaseLocally(Purchase purchase) async {
    final productId = purchase.productId;
    if (productId == null || productId.isEmpty) {
      if (!mounted) return;
      setState(() {
        _purchaseResult =
            '$_purchaseResult\n\nLocal verification: No product ID';
      });
      return;
    }

    try {
      debugPrint('Verifying purchase locally for: $productId');

      // Use platform-specific verification options (v8.0.0+ API)
      final VerifyPurchaseResult result;
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        result = await _iap.verifyPurchase(
          apple: VerifyPurchaseAppleOptions(sku: productId),
        );
      } else if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        // Note: Android verification requires accessToken from your backend
        // This is a demo - in production, get accessToken from your server
        final purchaseToken = (purchase as PurchaseAndroid?)?.purchaseToken;
        if (purchaseToken == null) {
          if (!mounted) return;
          setState(() {
            _purchaseResult =
                '$_purchaseResult\n\nAndroid verification: No purchase token';
          });
          return;
        }

        // In production, you would get the accessToken from your backend
        // For demo purposes, we show an error since no real accessToken is configured
        if (!mounted) return;
        setState(() {
          _purchaseResult = '''
$_purchaseResult

[Skipped] Local Verification (Android)
Android verification requires a valid OAuth accessToken from your backend.
In production, implement server-side verification using Google Play Developer API.
          '''
              .trim();
        });
        return;
        // Example of how to call verifyPurchase with real credentials:
        // result = await _iap.verifyPurchase(
        //   google: VerifyPurchaseGoogleOptions(
        //     sku: productId,
        //     accessToken: 'YOUR_OAUTH_ACCESS_TOKEN', // From your backend
        //     packageName: 'io.github.hyochan.flutter_inapp_purchase_example',
        //     purchaseToken: purchaseToken,
        //   ),
        // );
      } else {
        if (!mounted) return;
        setState(() {
          _purchaseResult =
              '$_purchaseResult\n\nLocal verification: Platform not supported';
        });
        return;
      }

      debugPrint('Local verification result: $result');

      if (result is VerifyPurchaseResultIOS) {
        final iosResult = result;
        final statusText = iosResult.isValid ? '[Valid]' : '[Invalid]';
        final jwsPreview = iosResult.jwsRepresentation.length > 50
            ? iosResult.jwsRepresentation.substring(0, 50)
            : iosResult.jwsRepresentation;
        if (!mounted) return;
        setState(() {
          _purchaseResult = '''
$_purchaseResult

$statusText Local Verification (iOS)
Valid: ${iosResult.isValid}
JWS: $jwsPreview...
          '''
              .trim();
        });
      } else if (result is VerifyPurchaseResultAndroid) {
        final androidResult = result;
        if (!mounted) return;
        setState(() {
          _purchaseResult = '''
$_purchaseResult

[Verified] Local Verification (Android)
Product ID: ${androidResult.productId}
Product Type: ${androidResult.productType}
Purchase Date: ${androidResult.purchaseDate}
Auto Renewing: ${androidResult.autoRenewing}
          '''
              .trim();
        });
      }
    } catch (e) {
      debugPrint('Local verification failed: $e');
      if (!mounted) return;
      setState(() {
        _purchaseResult =
            '$_purchaseResult\n\n[Failed] Local verification failed: $e';
      });
    }
  }

  /// Verify purchase with IAPKit provider
  Future<void> _verifyPurchaseWithIAPKit(Purchase purchase) async {
    final apiKey = IapConstants.iapkitApiKey;
    debugPrint('IAPKit API key configured: ${apiKey.isNotEmpty}');

    try {
      debugPrint('Verifying purchase with IAPKit...');
      final jwsOrToken = purchase.purchaseToken ?? '';
      debugPrint(
          'Token for verification: ${jwsOrToken.substring(0, jwsOrToken.length > 50 ? 50 : jwsOrToken.length)}...');

      final result = await _iap.verifyPurchaseWithProvider(
        provider: PurchaseVerificationProvider.Iapkit,
        iapkit: RequestVerifyPurchaseWithIapkitProps(
          apiKey: apiKey.isNotEmpty ? apiKey : null,
          apple: RequestVerifyPurchaseWithIapkitAppleProps(jws: jwsOrToken),
          google: RequestVerifyPurchaseWithIapkitGoogleProps(
              purchaseToken: jwsOrToken),
        ),
      );

      debugPrint('IAPKit verification result: $result');

      if (result.iapkit != null) {
        final iapkitResult = result.iapkit!;
        final statusEmoji = iapkitResult.isValid ? '✅' : '⚠️';
        final stateText = iapkitResult.state.value;

        if (!mounted) return;
        setState(() {
          _purchaseResult = '''
$_purchaseResult

$statusEmoji IAPKit Verification
Valid: ${iapkitResult.isValid}
State: $stateText
Store: ${iapkitResult.store.value}
          '''
              .trim();
        });
      }
    } catch (e) {
      debugPrint('IAPKit verification failed: $e');
      if (!mounted) return;
      setState(() {
        _purchaseResult =
            '$_purchaseResult\n\n❌ IAPKit verification failed: $e';
      });
    }
  }

  void _showVerificationMethodPicker() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  _verificationMethod == VerificationMethod.ignore
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                ),
                title: const Text('Ignore'),
                subtitle: const Text('Skip verification'),
                onTap: () {
                  setState(() {
                    _verificationMethod = VerificationMethod.ignore;
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(
                  _verificationMethod == VerificationMethod.local
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                ),
                title: const Text('Local'),
                subtitle: const Text('Basic local verification'),
                onTap: () {
                  setState(() {
                    _verificationMethod = VerificationMethod.local;
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(
                  _verificationMethod == VerificationMethod.iapkit
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                ),
                title: const Text('IAPKit'),
                subtitle: const Text('Server-side verification via IAPKit'),
                onTap: () {
                  setState(() {
                    _verificationMethod = VerificationMethod.iapkit;
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _getVerificationMethodLabel() {
    switch (_verificationMethod) {
      case VerificationMethod.ignore:
        return 'Ignore';
      case VerificationMethod.local:
        return 'Local';
      case VerificationMethod.iapkit:
        return 'IAPKit';
    }
  }

  Future<void> _loadProducts() async {
    if (!_connected) return;

    try {
      debugPrint('🔍 Loading products for IDs: ${productIds.join(", ")}');
      // Use explicit type parameter for proper type inference
      final inAppProducts = await _iap.fetchProducts<Product>(
        skus: productIds,
        type: ProductQueryType.InApp,
      );

      debugPrint(
          '📦 Received ${inAppProducts.length} products from fetchProducts');

      // Clear and store original products
      _originalProducts.clear();

      // Store original products
      for (final product in inAppProducts) {
        final productKey = product.id;
        _originalProducts[productKey] = product;

        debugPrint('Product: ${product.id} - ${product.title ?? 'No title'}');
        debugPrint('  Price: ${product.price ?? 'No price'}');
        debugPrint('  Currency: ${product.currency ?? 'No currency'}');
        debugPrint('  Description: ${product.description ?? 'No description'}');
      }

      if (!mounted) return;
      setState(() {
        _products = List<ProductCommon>.from(inAppProducts);
      });
    } catch (e) {
      debugPrint('Error loading products: $e');
    }
  }

  Future<void> _handlePurchase(String productId, {int retryCount = 0}) async {
    debugPrint('🛒 Starting purchase for: $productId (retry: $retryCount)');
    debugPrint('📱 Platform: ${defaultTargetPlatform.name}');
    debugPrint('🔗 Connection status: $_connected');

    if (!mounted) return;
    setState(() {
      _isProcessing = true;
      _purchaseResult = null; // Clear previous results
      _processedErrorMessages
          .clear(); // Clear processed errors for new purchase
    });

    try {
      debugPrint('Requesting purchase...');
      debugPrint('Product ID: $productId');

      // Build platform-specific request and call unified requestPurchase
      final requestProps = RequestPurchaseProps.inApp((
        apple: RequestPurchaseIosProps(
          sku: productId,
          quantity: 1,
        ),
        google: RequestPurchaseAndroidProps(
          skus: [productId],
        ),
        useAlternativeBilling: null,
      ));

      await _iap.requestPurchase(requestProps);

      debugPrint('✅ Purchase request sent successfully');
      // Note: The actual purchase result will come through the purchaseUpdatedListener
    } catch (error) {
      setState(() {
        _isProcessing = false;
      });

      // Do not show alert dialog if the user cancelled the purchase
      final errorString = error.toString().toLowerCase();
      final bool isUserCancelled =
          (error is PurchaseError && error.code == ErrorCode.UserCancelled) ||
              errorString.contains('user_cancel') ||
              errorString.contains('user cancelled') ||
              errorString.contains('canceled') ||
              errorString.contains('cancelled');

      if (isUserCancelled) {
        debugPrint('ℹ️ Purchase cancelled by user - suppressing alert');
        return;
      }

      // Check if it's a server error and we haven't exceeded retry limit
      if (error.toString().contains('responseCode: 6') && retryCount < 2) {
        // Show retry dialog for server errors
        if (mounted) {
          final shouldRetry = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Server Error'),
              content: const Text(
                'Google Play server error occurred.\n\n'
                'This is usually temporary. Would you like to retry?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );

          if (shouldRetry == true) {
            // Wait a bit before retrying
            await Future<void>.delayed(const Duration(seconds: 2));
            await _handlePurchase(productId, retryCount: retryCount + 1);
            return;
          }
        }
      }

      // Show error to user
      if (mounted) {
        showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Purchase Failed'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Error: $error'),
                  if (error.toString().contains('responseCode: 6')) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'This is a Google Play server error. Please try:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text('• Wait a few minutes and try again'),
                    const Text('• Clear Google Play Store cache'),
                    const Text('• Check your internet connection'),
                    const Text('• Restart your device'),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _showPurchaseDetails(Purchase purchase) async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.85,
              minChildSize: 0.4,
              maxChildSize: 0.95,
              builder: (context, controller) {
                return SingleChildScrollView(
                  controller: controller,
                  padding: const EdgeInsets.all(16),
                  child: PurchaseDataView(
                    purchase: purchase,
                    statusLabel: 'Latest Purchase',
                    statusColor: Colors.blue.shade600,
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Purchase Flow',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Connection Status
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _connected ? Colors.green[50] : Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _connected ? Icons.check_circle : Icons.error,
                        color: _connected ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _connected ? 'Connected to Store' : 'Not Connected',
                        style: TextStyle(
                          color: _connected ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Verification Method Selector
                if (_connected) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Purchase Verification:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        OutlinedButton(
                          onPressed: _showVerificationMethodPicker,
                          child: Text(_getVerificationMethodLabel()),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Debug/Test Section
                if (_connected) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Debug Tools',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _isProcessing
                                  ? null
                                  : () async {
                                      if (!mounted) return;
                                      setState(() {
                                        _isProcessing = true;
                                        _purchaseResult = null;
                                      });
                                      try {
                                        debugPrint(
                                            'Checking available purchases...');
                                        final purchases =
                                            await _iap.getAvailablePurchases();
                                        if (!mounted) return;
                                        setState(() {
                                          _purchaseResult = '''
📊 Available Purchases: ${purchases.length}
${purchases.map((p) => '- ${p.productId}: ${p.purchaseToken?.substring(0, 20)}...').join('\n')}
                                          '''
                                              .trim();
                                          _isProcessing = false;
                                        });
                                      } catch (e) {
                                        if (!mounted) return;
                                        setState(() {
                                          _purchaseResult =
                                              '❌ Error checking purchases: $e';
                                          _isProcessing = false;
                                        });
                                      }
                                    },
                              icon: const Icon(Icons.history, size: 16),
                              label: const Text('Check Purchases'),
                            ),
                            OutlinedButton.icon(
                              onPressed: _isProcessing
                                  ? null
                                  : () async {
                                      if (!mounted) return;
                                      setState(() {
                                        _isProcessing = true;
                                      });
                                      await _loadProducts();
                                      if (!mounted) return;
                                      setState(() {
                                        _isProcessing = false;
                                      });
                                    },
                              icon: const Icon(Icons.refresh, size: 16),
                              label: const Text('Reload Products'),
                            ),
                            OutlinedButton.icon(
                              onPressed: _isProcessing
                                  ? null
                                  : () async {
                                      if (!mounted) return;
                                      setState(() {
                                        _isProcessing = true;
                                        _purchaseResult = null;
                                      });
                                      try {
                                        // Re-initialize connection
                                        await _iap.endConnection();
                                        await Future<void>.delayed(
                                            const Duration(seconds: 1));
                                        await _initConnection();
                                        if (!mounted) return;
                                        setState(() {
                                          _purchaseResult =
                                              '✅ Connection reinitialized';
                                          _isProcessing = false;
                                        });
                                      } catch (e) {
                                        if (!mounted) return;
                                        setState(() {
                                          _purchaseResult = '❌ Error: $e';
                                          _isProcessing = false;
                                        });
                                      }
                                    },
                              icon: const Icon(Icons.power_settings_new,
                                  size: 16),
                              label: const Text('Re-init Connection'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Purchase Result Card (like KMP-IAP)
                if (_purchaseResult != null) ...[
                  Card(
                    color: _purchaseResult!.contains('✅')
                        ? Colors.green.shade50
                        : _purchaseResult!.contains('❌')
                            ? Colors.red.shade50
                            : _purchaseResult!.contains('⚠️')
                                ? Colors.orange.shade50
                                : Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Purchase Result',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 20),
                                onPressed: () {
                                  setState(() {
                                    _purchaseResult = null;
                                    _currentPurchase = null;
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: SelectableText(
                              _purchaseResult!,
                              style: const TextStyle(
                                fontSize: 12,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                          if (_currentPurchase != null) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    _showPurchaseDetails(_currentPurchase!),
                                icon: const Icon(Icons.receipt_long, size: 18),
                                label: const Text('View Purchase Data'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Products
                if (_products.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('No products available'),
                    ),
                  )
                else
                  ..._products.map((product) => GestureDetector(
                        onTap: () => ProductDetailModal.show(
                          context: context,
                          item: product,
                          product: _originalProducts[product.id],
                        ),
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.title ?? product.id,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  product.description ?? '',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      product.displayPrice,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF007AFF),
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: _isProcessing || !_connected
                                          ? null
                                          : () => _handlePurchase(product.id),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: Text(_isProcessing
                                          ? 'Processing...'
                                          : 'Buy'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      )),
              ],
            ),
    );
  }
}
