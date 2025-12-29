import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import '../constants.dart';

/// Alternative Billing Example
///
/// Demonstrates alternative billing flows for iOS and Android:
///
/// iOS (Alternative Billing):
/// - Redirects users to external website
/// - No onPurchaseUpdated callback when using external URL
/// - User completes purchase on external website
/// - Must implement deep link to return to app
///
/// Android (Billing Programs API - Recommended for 8.2.0+):
/// - Step 1: Set enableBillingProgramAndroid in InitConnectionConfig
/// - Step 2: Check availability with isBillingProgramAvailableAndroid()
/// - Step 3: Launch external link with launchExternalLinkAndroid()
/// - Step 4: Create reporting token with createBillingProgramReportingDetailsAndroid()
/// - Must report token to Google Play backend within 24 hours
///
/// Android (User Choice Billing - 7.0+):
/// - Set enableBillingProgramAndroid: UserChoiceBilling in InitConnectionConfig
/// - Users choose between Google Play and your payment system
/// - If user selects Google Play: onPurchaseUpdated callback
/// - If user selects alternative: userChoiceBillingListener fires
///
/// Android (External Payments API - 8.3.0+ Japan only):
/// - Set enableBillingProgramAndroid: ExternalPayments in InitConnectionConfig
/// - Call requestPurchase with developerBillingOption
/// - Shows side-by-side choice dialog (Google Play vs Developer billing)
/// - If user selects Google Play: purchaseUpdatedListener fires
/// - If user selects Developer billing: developerProvidedBillingListenerAndroid fires
/// - Must report externalTransactionToken to Google Play within 24 hours
class AlternativeBillingScreen extends StatefulWidget {
  const AlternativeBillingScreen({super.key});

  @override
  State<AlternativeBillingScreen> createState() =>
      _AlternativeBillingScreenState();
}

class _AlternativeBillingScreenState extends State<AlternativeBillingScreen> {
  final TextEditingController _urlController =
      TextEditingController(text: 'https://openiap.dev');

  /// Android billing mode: 'billing-programs' or 'external-payments'
  String _androidBillingMode = 'billing-programs';

  /// Billing program type (when billing-programs mode is selected)
  BillingProgramAndroid _billingProgram = BillingProgramAndroid.ExternalOffer;

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

    FlutterInappPurchase.instance.endConnection().catchError((e) {
      debugPrint('[AlternativeBilling] Error ending connection: $e');
      return false;
    });

    super.dispose();
  }

  Future<void> _initConnection() async {
    try {
      await FlutterInappPurchase.instance.initConnection(
        enableBillingProgramAndroid: _billingProgram,
      );

      if (!mounted) return;
      setState(() => _connected = true);

      _setupListeners();
      await _fetchProducts();
    } catch (e) {
      debugPrint('[AlternativeBilling] Init error: $e');
    }
  }

  void _setupListeners() {
    _purchaseUpdatedSubscription = FlutterInappPurchase
        .instance.purchaseUpdatedListener
        .listen((purchase) async {
      debugPrint(
          '[AlternativeBilling] Purchase successful: ${purchase.productId}');

      setState(() {
        _isProcessing = false;
        _purchaseResult = '''
Purchase successful
Product: ${purchase.productId}
Transaction ID: ${purchase.id}
''';
      });

      // Finish transaction
      try {
        await FlutterInappPurchase.instance.finishTransaction(
          purchase: purchase,
          isConsumable: true,
        );
      } catch (e) {
        debugPrint('[AlternativeBilling] Failed to finish transaction: $e');
      }

      if (mounted) {
        _showAlert('Success', 'Purchase completed!');
      }
    });

    _purchaseErrorSubscription =
        FlutterInappPurchase.instance.purchaseErrorListener.listen((error) {
      debugPrint('[AlternativeBilling] Purchase error: ${error.message}');
      setState(() {
        _isProcessing = false;
        _purchaseResult = 'Error: ${error.message}';
      });
    });

    // Android User Choice Billing listener
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      _userChoiceBillingSubscription = FlutterInappPurchase
          .instance.userChoiceBillingAndroid
          .listen((details) {
        debugPrint('[AlternativeBilling] User selected alternative billing');
        setState(() {
          _isProcessing = false;
          _purchaseResult = '''
User selected alternative billing
Products: ${details.products.join(', ')}
Token: ${details.externalTransactionToken.substring(0, 20)}...

Important:
- Process payment with your system
- Report token to Google within 24h
''';
        });

        _showAlert(
          'Alternative Billing Selected',
          'User selected alternative billing.\n'
              'Process payment with your system.',
        );
      });
    }
  }

  Future<void> _fetchProducts() async {
    try {
      debugPrint(
          '[AlternativeBilling] Fetching products: ${IapConstants.inAppProductIds}');
      final products =
          await FlutterInappPurchase.instance.fetchProducts<Product>(
        skus: IapConstants.inAppProductIds,
        type: ProductQueryType.InApp,
      );

      debugPrint('[AlternativeBilling] Products fetched: ${products.length}');

      if (!mounted) return;
      setState(() => _products = products);
    } catch (e) {
      debugPrint('[AlternativeBilling] Failed to fetch products: $e');
      if (mounted) {
        _showAlert('Error', 'Failed to fetch products');
      }
    }
  }

  Future<void> _reconnectWithBillingProgram(
      BillingProgramAndroid newProgram) async {
    try {
      setState(() {
        _isReconnecting = true;
        _purchaseResult = 'Reconnecting with new billing program...';
      });

      await FlutterInappPurchase.instance.endConnection();
      await Future.delayed(const Duration(milliseconds: 500));

      await FlutterInappPurchase.instance.initConnection(
        enableBillingProgramAndroid: newProgram,
      );

      setState(() {
        _purchaseResult = 'Reconnected with ${newProgram.name} program';
        _isReconnecting = false;
      });

      await _fetchProducts();
    } catch (e) {
      debugPrint('[AlternativeBilling] Reconnection error: $e');
      setState(() {
        _purchaseResult = 'Reconnection failed: $e';
        _isReconnecting = false;
      });
    }
  }

  Future<void> _handleIOSPurchase(Product product) async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      _showAlert('Error', 'Please enter a valid external purchase URL');
      return;
    }

    debugPrint('[iOS] Starting alternative billing: ${product.id}');
    debugPrint('[iOS] External URL: $url');

    setState(() {
      _isProcessing = true;
      _purchaseResult = 'Opening external purchase link...';
    });

    try {
      final result =
          await FlutterInappPurchase.instance.presentExternalPurchaseLinkIOS(
        url,
      );

      debugPrint('[iOS] External purchase link result: $result');

      if (!mounted) return;

      if (result.error != null) {
        setState(() => _purchaseResult = 'Error: ${result.error}');
        _showAlert('Error', result.error!);
      } else if (result.success) {
        setState(() {
          _purchaseResult = '''
External purchase link opened

Product: ${product.id}
URL: $url

User redirected to external website.
''';
        });
        _showAlert('Redirected',
            'User was redirected to your external purchase website.');
      }
    } catch (e) {
      debugPrint('[iOS] Alternative billing error: $e');
      setState(() => _purchaseResult = 'Error: $e');
      _showAlert('Error', e.toString());
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleAndroidBillingPrograms(Product product) async {
    debugPrint('[Android] Starting Billing Programs flow');
    debugPrint('[Android] Billing Program: ${_billingProgram.name}');

    setState(() {
      _isProcessing = true;
      _purchaseResult = 'Checking billing program availability...';
    });

    try {
      // Step 1: Check availability
      final isAvailable = await FlutterInappPurchase.instance
          .checkAlternativeBillingAvailabilityAndroid();

      if (!isAvailable) {
        setState(() {
          _purchaseResult =
              'Billing program "${_billingProgram.name}" not available';
        });
        _showAlert('Not Available',
            'The billing program "${_billingProgram.name}" is not available');
        return;
      }

      setState(() => _purchaseResult = 'Showing dialog...');

      // Step 2: Show information dialog
      final userAccepted = await FlutterInappPurchase.instance
          .showAlternativeBillingDialogAndroid();

      if (!userAccepted) {
        setState(() => _purchaseResult = 'User cancelled');
        return;
      }

      setState(() => _purchaseResult = 'Creating token...');

      // Step 3: Create token
      final token = await FlutterInappPurchase.instance
          .createAlternativeBillingTokenAndroid();

      if (token != null) {
        setState(() {
          _purchaseResult = '''
Billing Programs API completed

Program: ${_billingProgram.name}
URL: ${_urlController.text}
Token: ${token.substring(0, 20)}...

Important:
- User completes purchase externally
- Report token to Google Play within 24h
''';
        });
        _showAlert('Success',
            'External link launched. Complete purchase on external site.');
      }
    } catch (e) {
      debugPrint('[Android] Billing Programs error: $e');
      setState(() => _purchaseResult = 'Error: $e');
      _showAlert('Error', e.toString());
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleAndroidExternalPayments(Product product) async {
    debugPrint('[Android] Starting External Payments flow: ${product.id}');
    debugPrint('[Android] External URL: ${_urlController.text}');

    setState(() {
      _isProcessing = true;
      _purchaseResult = 'Starting External Payments purchase...';
    });

    try {
      // Request purchase with useAlternativeBilling
      await FlutterInappPurchase.instance.requestPurchase(
        RequestPurchaseProps.inApp((
          apple: RequestPurchaseIosProps(sku: product.id),
          google: RequestPurchaseAndroidProps(skus: [product.id]),
          useAlternativeBilling: true,
        )),
      );

      setState(() {
        _purchaseResult = '''
External Payments dialog shown

Product: ${product.id}

Waiting for user choice:
- Google Play -> purchaseUpdatedListener
- Developer billing -> developerProvidedBillingListener
''';
      });
    } catch (e) {
      debugPrint('[Android] External Payments error: $e');
      setState(() {
        _isProcessing = false;
        _purchaseResult = 'Error: $e';
      });
      _showAlert('Error', e.toString());
    }
  }

  Future<void> _handleAndroidUserChoice(Product product) async {
    debugPrint('[Android] Starting User Choice Billing: ${product.id}');

    setState(() {
      _isProcessing = true;
      _purchaseResult = 'Showing user choice dialog...';
    });

    try {
      await FlutterInappPurchase.instance.requestPurchase(
        RequestPurchaseProps.inApp((
          apple: RequestPurchaseIosProps(sku: product.id),
          google: RequestPurchaseAndroidProps(skus: [product.id]),
          useAlternativeBilling: true,
        )),
      );

      setState(() {
        _purchaseResult = '''
User choice dialog shown

Product: ${product.id}

If user selects:
- Google Play: onPurchaseUpdated callback
- Alternative: userChoiceBillingListener fires
''';
      });
    } catch (e) {
      debugPrint('[Android] User choice billing error: $e');
      setState(() => _purchaseResult = 'Error: $e');
      _showAlert('Error', e.toString());
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handlePurchase(Product product) async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      await _handleIOSPurchase(product);
    } else if (_androidBillingMode == 'billing-programs') {
      if (_billingProgram == BillingProgramAndroid.UserChoiceBilling) {
        await _handleAndroidUserChoice(product);
      } else {
        await _handleAndroidBillingPrograms(product);
      }
    } else {
      // external-payments
      await _handleAndroidExternalPayments(product);
    }
  }

  void _showAlert(String title, String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showModeSelector() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Android Billing Mode',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildModeOption(
                title: 'Billing Programs API (7.0+/8.2.0+)',
                description:
                    'Recommended. Includes external-offer, external-content-link, and user-choice-billing.',
                isSelected: _androidBillingMode == 'billing-programs',
                onTap: () {
                  setState(() => _androidBillingMode = 'billing-programs');
                  if (_billingProgram ==
                      BillingProgramAndroid.ExternalPayments) {
                    _billingProgram = BillingProgramAndroid.ExternalOffer;
                    _reconnectWithBillingProgram(_billingProgram);
                  }
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 8),
              _buildModeOption(
                title: 'External Payments (8.3.0+ Japan)',
                description:
                    'Side-by-side choice in purchase dialog. User sees both Google Play and developer billing options.',
                isSelected: _androidBillingMode == 'external-payments',
                onTap: () {
                  setState(() {
                    _androidBillingMode = 'external-payments';
                    _billingProgram = BillingProgramAndroid.ExternalPayments;
                  });
                  _reconnectWithBillingProgram(
                      BillingProgramAndroid.ExternalPayments);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProgramSelector() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Billing Program',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildModeOption(
                title: 'External Offer (8.2.0+)',
                description:
                    'Redirect users to your external payment site. Best for apps with existing payment infrastructure.',
                isSelected:
                    _billingProgram == BillingProgramAndroid.ExternalOffer,
                onTap: () {
                  setState(() =>
                      _billingProgram = BillingProgramAndroid.ExternalOffer);
                  _reconnectWithBillingProgram(
                      BillingProgramAndroid.ExternalOffer);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 8),
              _buildModeOption(
                title: 'External Content Link (8.2.0+)',
                description:
                    'Link to external content offers. Suitable for content-based subscriptions.',
                isSelected: _billingProgram ==
                    BillingProgramAndroid.ExternalContentLink,
                onTap: () {
                  setState(() => _billingProgram =
                      BillingProgramAndroid.ExternalContentLink);
                  _reconnectWithBillingProgram(
                      BillingProgramAndroid.ExternalContentLink);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 8),
              _buildModeOption(
                title: 'User Choice Billing (7.0+)',
                description:
                    'Let users choose between Google Play and your payment system. Shows a selection dialog.',
                isSelected:
                    _billingProgram == BillingProgramAndroid.UserChoiceBilling,
                onTap: () {
                  setState(() => _billingProgram =
                      BillingProgramAndroid.UserChoiceBilling);
                  _reconnectWithBillingProgram(
                      BillingProgramAndroid.UserChoiceBilling);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeOption({
    required String title,
    required String description,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange[50] : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.orange : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.orange[800] : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isIOS = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
    final isAndroid =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alternative Billing'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info Card
            _buildInfoCard(isIOS),
            const SizedBox(height: 16),

            // Mode Selector (Android only)
            if (isAndroid) ...[
              _buildAndroidModeSelector(),
              const SizedBox(height: 16),
            ],

            // URL Input (iOS or Android non-user-choice)
            if (isIOS ||
                (isAndroid &&
                    ((_androidBillingMode == 'billing-programs' &&
                            _billingProgram !=
                                BillingProgramAndroid.UserChoiceBilling) ||
                        _androidBillingMode == 'external-payments')))
              _buildUrlInput(),

            // Connection Status
            _buildStatusCard(),
            const SizedBox(height: 16),

            // Reconnecting Status
            if (_isReconnecting)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber),
                ),
                child: const Text(
                  'Reconnecting with new billing mode...',
                  style: TextStyle(color: Colors.amber),
                  textAlign: TextAlign.center,
                ),
              ),

            // Products Section
            _buildProductsSection(),

            // Purchase Button
            if (_selectedProduct != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed:
                    _isProcessing || !_connected || _selectedProduct == null
                        ? null
                        : () => _handlePurchase(_selectedProduct!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  disabledBackgroundColor: Colors.grey[300],
                ),
                child: Text(
                  _isProcessing
                      ? 'Processing...'
                      : isIOS
                          ? 'Buy (External URL)'
                          : _billingProgram ==
                                  BillingProgramAndroid.UserChoiceBilling
                              ? 'Buy (User Choice)'
                              : 'Buy (${_billingProgram.name})',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],

            // Result Card
            if (_purchaseResult.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildResultCard(),
            ],

            // Instructions
            const SizedBox(height: 16),
            _buildInstructions(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(bool isIOS) {
    String infoText;
    if (isIOS) {
      infoText =
          '- Enter your external purchase URL\n- Tap Purchase on any product\n- User will be redirected to the external URL\n- Complete purchase on your website';
    } else if (_androidBillingMode == 'billing-programs') {
      if (_billingProgram == BillingProgramAndroid.UserChoiceBilling) {
        infoText =
            '- User Choice Billing (7.0+)\n- Users choose between Google Play & your payment\n- If Google Play: purchaseUpdatedListener\n- If alternative: userChoiceBillingListener';
      } else {
        infoText =
            '- Billing Programs API (8.2.0+)\n- Recommended for new implementations\n- Uses external-offer, external-content-link, or user-choice-billing\n- Must report token within 24h';
      }
    } else {
      infoText =
          '- External Payments (8.3.0+ - Japan only)\n- Side-by-side choice in purchase dialog\n- User sees Google Play & your option together\n- Must report token within 24h';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: Colors.orange, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isIOS ? 'iOS External Purchase' : 'Android Alternative Billing',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.orange[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            infoText,
            style: TextStyle(
              fontSize: 13,
              color: Colors.brown[700],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isIOS
                ? 'iOS 16.0+ required\nValid external URL needed'
                : 'Requires approval from Google\nMust report tokens within 24 hours',
            style: TextStyle(
              fontSize: 12,
              color: Colors.deepOrange[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAndroidModeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Android Billing Mode',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _showModeSelector,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _androidBillingMode == 'billing-programs'
                      ? 'Billing Programs API (8.2.0+)'
                      : 'External Payments (8.3.0+ Japan)',
                  style: const TextStyle(fontSize: 14),
                ),
                Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
              ],
            ),
          ),
        ),

        // Program Type Selector (only for billing-programs mode)
        if (_androidBillingMode == 'billing-programs') ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Program Type:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _showProgramSelector,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _billingProgram == BillingProgramAndroid.ExternalOffer
                              ? 'External Offer (8.2.0+)'
                              : _billingProgram ==
                                      BillingProgramAndroid.ExternalContentLink
                                  ? 'External Content Link (8.2.0+)'
                                  : 'User Choice Billing (7.0+)',
                          style: const TextStyle(fontSize: 14),
                        ),
                        Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildUrlInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'External Purchase URL',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _urlController,
          decoration: InputDecoration(
            hintText: 'https://your-payment-site.com/checkout',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: 4),
        Text(
          'This URL will be opened when a user taps Purchase',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildStatusCard() {
    final isAndroid =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Store Connection:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              Text(
                _connected ? 'Connected' : 'Disconnected',
                style: TextStyle(
                  fontSize: 14,
                  color: _connected ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (isAndroid) ...[
            const SizedBox(height: 4),
            Text(
              'Current mode: ${_androidBillingMode == 'billing-programs' ? 'BILLING_PROGRAMS (${_billingProgram.name})' : 'EXTERNAL_PAYMENTS (8.3.0+ Japan)'}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProductsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Select Product (${_products.length})',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_connected)
              TextButton(
                onPressed: _fetchProducts,
                child: const Text('Refresh'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_products.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                'Loading products...',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          )
        else
          ..._products.map((product) => _buildProductCard(product)),
      ],
    );
  }

  Widget _buildProductCard(Product product) {
    final isSelected = _selectedProduct?.id == product.id;

    return InkWell(
      onTap: () => setState(() => _selectedProduct = product),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange[50] : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.orange : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.displayPrice,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[700],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Selected',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
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
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _purchaseResult = ''),
                child: const Text('Dismiss'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _purchaseResult,
            style: const TextStyle(
              fontSize: 13,
              fontFamily: 'monospace',
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Testing Instructions:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.blue[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '1. Select a product from the list\n'
            '2. Tap the purchase button\n'
            '3. Follow the platform-specific flow\n'
            '4. Check the purchase result\n'
            '5. Verify token/URL behavior',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
