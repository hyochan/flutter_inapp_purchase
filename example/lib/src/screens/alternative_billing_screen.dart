import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import '../constants.dart';

/// Alternative Billing Example
///
/// Demonstrates alternative billing flows for iOS and Android:
///
/// iOS (Alternative Billing):
/// - Redirects users to external website using presentExternalPurchaseLinkIOS
/// - No purchase callback when using external URL
/// - User completes purchase on external website
/// - Must implement deep link to return to app
///
/// Android (Alternative Billing Only):
/// - Step 1: Check availability with checkAlternativeBillingAvailabilityAndroid()
/// - Step 2: Show information dialog with showAlternativeBillingDialogAndroid()
/// - Step 3: Process payment in your payment system
/// - Step 4: Create token with createAlternativeBillingTokenAndroid()
/// - Must report token to Google Play backend within 24 hours
/// - No purchase callback
///
/// Android (User Choice Billing):
/// - Call requestPurchase() normally
/// - Google shows selection dialog automatically
/// - If user selects Google Play: purchaseUpdated callback
/// - If user selects alternative: userChoiceBillingAndroid callback
class AlternativeBillingScreen extends StatefulWidget {
  const AlternativeBillingScreen({super.key});

  @override
  State<AlternativeBillingScreen> createState() =>
      _AlternativeBillingScreenState();
}

class _AlternativeBillingScreenState extends State<AlternativeBillingScreen> {
  final TextEditingController _urlController =
      TextEditingController(text: 'https://openiap.dev');
  AlternativeBillingModeAndroid _billingMode =
      AlternativeBillingModeAndroid.AlternativeOnly;
  List<Product> _products = [];
  Product? _selectedProduct;
  String _purchaseResult = '';
  bool _isProcessing = false;
  bool _isReconnecting = false;
  bool _connected = false;
  StreamSubscription? _purchaseUpdatedSubscription;
  StreamSubscription? _purchaseErrorSubscription;
  StreamSubscription? _userChoiceBillingSubscription;

  @override
  void initState() {
    super.initState();
    _initConnection();
  }

  @override
  void dispose() {
    _purchaseUpdatedSubscription?.cancel();
    _purchaseErrorSubscription?.cancel();
    _userChoiceBillingSubscription?.cancel();
    _urlController.dispose();

    // End connection when leaving this screen
    // This will reset alternative billing settings
    FlutterInappPurchase.instance.endConnection().then((_) {
      debugPrint('[Alternative Billing] Connection ended on dispose');
    }).catchError((e) {
      debugPrint('[Alternative Billing] Error ending connection: $e');
    });

    super.dispose();
  }

  Future<void> _initConnection() async {
    try {
      await FlutterInappPurchase.instance
          .initConnection(alternativeBillingModeAndroid: _billingMode);

      if (!mounted) return;
      setState(() {
        _connected = true;
      });

      _setupListeners();
      await _loadProducts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initialize: $e')),
        );
      }
    }
  }

  void _setupListeners() {
    _purchaseUpdatedSubscription = FlutterInappPurchase
        .instance.purchaseUpdatedListener
        .listen((purchase) async {
      debugPrint('Purchase successful: ${purchase.productId}');

      final transactionDate = purchase.transactionDate;
      int? transactionMillis;
      if (transactionDate is num) {
        transactionMillis = transactionDate.toInt();
      } else if (transactionDate != null) {
        transactionMillis = int.tryParse(transactionDate.toString());
      }
      final transactionDateString = transactionMillis != null
          ? DateTime.fromMillisecondsSinceEpoch(transactionMillis)
              .toLocal()
              .toString()
          : 'unknown';

      setState(() {
        _isProcessing = false;
        _purchaseResult = '''
✅ Purchase successful
Product: ${purchase.productId}
Transaction ID: ${purchase.id}
Date: $transactionDateString
''';
      });

      // Finish transaction
      try {
        await FlutterInappPurchase.instance.finishTransaction(
          purchase: purchase,
          isConsumable: true,
        );
        debugPrint('Transaction finished');
      } catch (error) {
        debugPrint('Failed to finish transaction: $error');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchase completed successfully!')),
        );
      }
    });

    _purchaseErrorSubscription =
        FlutterInappPurchase.instance.purchaseErrorListener.listen((error) {
      debugPrint('Purchase error: ${error.message}');
      setState(() {
        _isProcessing = false;
        _purchaseResult = '❌ Purchase failed: ${error.message}';
      });

      if (error.code != ErrorCode.UserCancelled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    });

    // Android User Choice Billing listener
    if (Platform.isAndroid) {
      _userChoiceBillingSubscription = FlutterInappPurchase
          .instance.userChoiceBillingAndroid
          .listen((details) {
        debugPrint('User choice billing: ${details.products}');
        setState(() {
          _isProcessing = false;
          _purchaseResult = '''
🔔 User selected alternative billing
Products: ${details.products.join(', ')}
Token: ${details.externalTransactionToken.length > 20 ? details.externalTransactionToken.substring(0, 20) : details.externalTransactionToken}...

⚠️ Important:
1. Process payment with your payment system
2. Report token to Google Play backend within 24 hours
3. Validate on your server
''';
        });

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Alternative Billing Selected'),
            content: const Text(
              'User selected alternative billing.\n\n'
              'In production:\n'
              '1. Process payment with your system\n'
              '2. Report token to Google backend\n'
              '3. Validate on your server',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      });
    }
  }

  Future<void> _loadProducts() async {
    try {
      // Use type cast on right side instead of type annotation on left
      final products = await FlutterInappPurchase.instance.fetchProducts(
        skus: IapConstants.inAppProductIds,
        type: ProductQueryType.InApp,
      ) as List<Product>;

      if (!mounted) return;
      setState(() {
        _products = products;
      });
    } catch (e) {
      debugPrint('Failed to load products: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load products')),
        );
      }
    }
  }

  Future<void> _reconnectWithMode(AlternativeBillingModeAndroid newMode) async {
    if (!Platform.isAndroid) return;

    try {
      setState(() {
        _isReconnecting = true;
        _purchaseResult = 'Reconnecting with new billing mode...';
      });

      await FlutterInappPurchase.instance.endConnection();

      // Small delay to allow connection cleanup to complete
      // This prevents race conditions when switching billing modes
      await Future.delayed(const Duration(milliseconds: 300));

      await FlutterInappPurchase.instance
          .initConnection(alternativeBillingModeAndroid: newMode);

      if (!mounted) return;
      setState(() {
        _billingMode = newMode;
        _connected = true;
        _purchaseResult = '''
✅ Reconnected with ${newMode == AlternativeBillingModeAndroid.AlternativeOnly ? 'Alternative Only' : 'User Choice'} mode
''';
      });

      await _loadProducts();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _purchaseResult = '❌ Reconnection failed: $e';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isReconnecting = false;
      });
    }
  }

  Future<void> _handleIOSAlternativeBilling(Product product) async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid external URL')),
      );
      return;
    }

    debugPrint('[iOS] Starting alternative billing purchase: ${product.id}');
    debugPrint('[iOS] External URL: $url');

    setState(() {
      _isProcessing = true;
      _purchaseResult = '🌐 Opening external purchase link...';
    });

    try {
      final result =
          await FlutterInappPurchase.instance.presentExternalPurchaseLinkIOS(
        url,
      );

      debugPrint('[iOS] External purchase link result: $result');

      if (!mounted) return;
      setState(() {
        if (result.error != null) {
          _purchaseResult = '❌ Error: ${result.error}';
        } else if (result.success) {
          _purchaseResult = '''
✅ External purchase link opened successfully

Product: ${product.id}
URL: $url

User was redirected to external website.

Note: Complete purchase on your website and implement server-side validation.
''';
        }
      });

      if (result.error != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.error!)),
          );
        }
      } else if (result.success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Redirected to external purchase website. Complete the purchase there.',
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('[iOS] Alternative billing error: $e');
      if (!mounted) return;
      setState(() {
        _purchaseResult = '❌ Error: $e';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _handleAndroidAlternativeBillingOnly(Product product) async {
    debugPrint(
      '[Android] Starting alternative billing only flow: ${product.id}',
    );

    setState(() {
      _isProcessing = true;
      _purchaseResult = 'Checking alternative billing availability...';
    });

    try {
      // Step 1: Check availability
      final isAvailable = await FlutterInappPurchase.instance
          .checkAlternativeBillingAvailabilityAndroid();

      debugPrint('[Android] Alternative billing available: $isAvailable');

      if (!isAvailable) {
        if (!mounted) return;
        setState(() {
          _purchaseResult = '❌ Alternative billing not available';
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Alternative billing is not available for this user/device',
              ),
            ),
          );
        }
        return;
      }

      if (!mounted) return;
      setState(() {
        _purchaseResult = 'Showing information dialog...';
      });

      // Step 2: Show information dialog
      final userAccepted = await FlutterInappPurchase.instance
          .showAlternativeBillingDialogAndroid();

      debugPrint('[Android] User accepted dialog: $userAccepted');

      if (!userAccepted) {
        if (!mounted) return;
        setState(() {
          _purchaseResult = 'ℹ️ User cancelled';
        });
        return;
      }

      if (!mounted) return;
      setState(() {
        _purchaseResult = 'Creating token...';
      });

      // Step 2.5: In production, process payment here with your payment system
      debugPrint('[Android] ⚠️ Payment processing not implemented (DEMO)');

      // Step 3: Create token (after successful payment)
      final token = await FlutterInappPurchase.instance
          .createAlternativeBillingTokenAndroid();

      debugPrint('[Android] Token created: $token');

      if (!mounted) return;
      setState(() {
        if (token != null) {
          _purchaseResult = '''
✅ Alternative billing completed (DEMO)

Product: ${product.id}
Token: ${token.length > 20 ? token.substring(0, 20) : token}...

⚠️ Important:
1. Process payment with your payment system
2. Report token to Google Play backend within 24 hours
3. No purchase callback
''';
        } else {
          _purchaseResult = '❌ Failed to create reporting token';
        }
      });

      if (mounted && token != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Alternative billing flow completed.\n'
              'In production: Process payment, report token to Google, validate on server',
            ),
            duration: Duration(seconds: 4),
          ),
        );
      } else if (mounted && token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create reporting token')),
        );
      }
    } catch (e) {
      debugPrint('[Android] Alternative billing error: $e');
      if (!mounted) return;
      setState(() {
        _purchaseResult = '❌ Error: $e';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _handleAndroidUserChoiceBilling(Product product) async {
    debugPrint('[Android] Starting user choice billing: ${product.id}');

    setState(() {
      _isProcessing = true;
      _purchaseResult = 'Showing user choice dialog...';
    });

    try {
      await FlutterInappPurchase.instance.requestPurchase(
        RequestPurchaseProps.inApp((
          android: RequestPurchaseAndroidProps(skus: [product.id]),
          ios: null,
          useAlternativeBilling: true,
        )),
      );

      // Google will show selection dialog
      // If user selects Google Play: purchaseUpdatedListener callback
      // If user selects alternative: userChoiceBillingAndroid callback
      if (!mounted) return;
      setState(() {
        _purchaseResult = '''
🔄 User choice dialog shown

Product: ${product.id}

If user selects:
- Google Play: purchaseUpdatedListener callback
- Alternative: userChoiceBillingAndroid callback
''';
      });
    } catch (e) {
      debugPrint('[Android] User choice billing error: $e');
      if (!mounted) return;
      setState(() {
        _purchaseResult = '❌ Error: $e';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _handlePurchase(Product product) async {
    if (Platform.isIOS) {
      await _handleIOSAlternativeBilling(product);
    } else if (Platform.isAndroid) {
      if (_billingMode == AlternativeBillingModeAndroid.AlternativeOnly) {
        await _handleAndroidAlternativeBillingOnly(product);
      } else {
        await _handleAndroidUserChoiceBilling(product);
      }
    }
  }

  void _showModeSelector() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Select Billing Mode',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            _buildModeOption(
              AlternativeBillingModeAndroid.AlternativeOnly,
              'Alternative Billing Only',
              'Only your payment system is available. Users cannot use Google Play.',
            ),
            const SizedBox(height: 10),
            _buildModeOption(
              AlternativeBillingModeAndroid.UserChoice,
              'User Choice Billing',
              'Users can choose between Google Play and your payment system.',
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeOption(
    AlternativeBillingModeAndroid mode,
    String title,
    String description,
  ) {
    final isSelected = _billingMode == mode;
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        _reconnectWithMode(mode);
      },
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.orange : Colors.grey[300]!,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? Colors.orange[50] : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 5),
            Text(
              description,
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alternative Billing'),
        backgroundColor: Colors.orange,
      ),
      body: !_connected
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildInfoCard(),
                  const SizedBox(height: 15),
                  if (Platform.isAndroid) ...[
                    _buildModeSelectorSection(),
                    const SizedBox(height: 15),
                  ],
                  if (Platform.isIOS) ...[
                    _buildUrlInputSection(),
                    const SizedBox(height: 15),
                  ],
                  if (_isReconnecting) ...[
                    const Card(
                      color: Color(0xFFFFF3CD),
                      child: Padding(
                        padding: EdgeInsets.all(15),
                        child: Text(
                          '🔄 Reconnecting with new billing mode...',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF856404),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                  ],
                  _buildStatusCard(),
                  const SizedBox(height: 15),
                  _buildProductsSection(),
                  if (_selectedProduct != null) ...[
                    const SizedBox(height: 15),
                    _buildProductDetailsSection(),
                  ],
                  if (_purchaseResult.isNotEmpty) ...[
                    const SizedBox(height: 15),
                    _buildResultSection(),
                  ],
                  const SizedBox(height: 15),
                  _buildInstructions(),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      color: const Color(0xFFFFF3E0),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ℹ️ How It Works',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFFE65100),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              Platform.isIOS
                  ? '• Enter your external purchase URL\n'
                      '• Tap Purchase on any product\n'
                      '• User will be redirected to the external URL\n'
                      '• Complete purchase on your website\n'
                      '• No purchase callback\n'
                      '• Implement deep link to return to app'
                  : _billingMode ==
                          AlternativeBillingModeAndroid.AlternativeOnly
                      ? '• Alternative Billing Only Mode\n'
                          '• Users CANNOT use Google Play billing\n'
                          '• Only your payment system available\n'
                          '• 3-step manual flow required\n'
                          '• No purchase callback\n'
                          '• Must report to Google within 24h'
                      : '• User Choice Billing Mode\n'
                          '• Users choose between:\n'
                          '  - Google Play (30% fee)\n'
                          '  - Your payment system (lower fee)\n'
                          '• Google shows selection dialog\n'
                          '• If Google Play: purchaseUpdated\n'
                          '• If alternative: Manual flow',
              style: const TextStyle(fontSize: 13, color: Color(0xFF5D4037)),
            ),
            const SizedBox(height: 8),
            Text(
              Platform.isIOS
                  ? '⚠️ iOS 16.0+ required\n'
                      '⚠️ Valid external URL needed\n'
                      '⚠️ useAlternativeBilling: true is set'
                  : '⚠️ Requires approval from Google\n'
                      '⚠️ Must report tokens within 24 hours\n'
                      '⚠️ Backend integration required',
              style: const TextStyle(fontSize: 12, color: Color(0xFFD84315)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSelectorSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Billing Mode',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        InkWell(
          onTap: _showModeSelector,
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _billingMode == AlternativeBillingModeAndroid.AlternativeOnly
                      ? 'Alternative Billing Only'
                      : 'User Choice Billing',
                  style: const TextStyle(fontSize: 14),
                ),
                const Icon(Icons.arrow_drop_down, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUrlInputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'External Purchase URL',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _urlController,
          decoration: const InputDecoration(
            hintText: 'https://your-payment-site.com/checkout',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: 5),
        Text(
          'This URL will be opened when a user taps Purchase',
          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
        ),
      ],
    );
  }

  Widget _buildStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Store Connection:',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 5),
            Text(
              _connected ? '✅ Connected' : '❌ Disconnected',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _connected ? Colors.green : Colors.red,
              ),
            ),
            if (Platform.isAndroid) ...[
              const SizedBox(height: 4),
              Text(
                'Current mode: ${_billingMode == AlternativeBillingModeAndroid.AlternativeOnly ? 'ALTERNATIVE_ONLY' : 'USER_CHOICE'}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProductsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Product',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        if (_products.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: Text('Loading products...')),
            ),
          )
        else
          ..._products.map((product) => _buildProductCard(product)),
      ],
    );
  }

  Widget _buildProductCard(Product product) {
    final isSelected = _selectedProduct?.id == product.id;
    return Card(
      color: isSelected ? Colors.orange[50] : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? Colors.orange : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () => setState(() => _selectedProduct = product),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      product.title ?? product.id,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    product.displayPrice ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                product.description ?? '',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
              if (isSelected) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '✓ Selected',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Product Details',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                _buildDetailRow('ID:', _selectedProduct!.id),
                _buildDetailRow('Title:', _selectedProduct!.title ?? ''),
                _buildDetailRow(
                  'Price:',
                  _selectedProduct!.displayPrice ?? '',
                ),
                _buildDetailRow('Type:', _selectedProduct!.type.toString()),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: _isProcessing || !_connected
              ? null
              : () => _handlePurchase(_selectedProduct!),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            padding: const EdgeInsets.symmetric(vertical: 15),
          ),
          child: Text(
            _isProcessing
                ? 'Processing...'
                : Platform.isIOS
                    ? '🛒 Buy (External URL)'
                    : _billingMode ==
                            AlternativeBillingModeAndroid.AlternativeOnly
                        ? '🛒 Buy (Alternative Only)'
                        : '🛒 Buy (User Choice)',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultSection() {
    return Card(
      color: const Color(0xFFE8F5E9),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Purchase Result',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                TextButton(
                  onPressed: () => setState(() => _purchaseResult = ''),
                  child: const Text(
                    'Dismiss',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              _purchaseResult,
              style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Card(
      color: const Color(0xFFE3F2FD),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Testing Instructions:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1565C0),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '1. Select a product from the list\n'
              '2. Tap the purchase button\n'
              '3. Follow the platform-specific flow\n'
              '4. Check the purchase result\n'
              '5. Verify token/URL behavior',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
