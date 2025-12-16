import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

class OfferCodeScreen extends StatefulWidget {
  const OfferCodeScreen({Key? key}) : super(key: key);

  @override
  State<OfferCodeScreen> createState() => _OfferCodeScreenState();
}

class _OfferCodeScreenState extends State<OfferCodeScreen> {
  final FlutterInappPurchase _iap = FlutterInappPurchase.instance;
  final TextEditingController _codeController = TextEditingController();

  bool _loading = false;
  bool _connected = false;
  String? _statusMessage;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _initConnection();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _iap.endConnection();
    super.dispose();
  }

  Future<void> _initConnection() async {
    setState(() {
      _loading = true;
    });

    try {
      await _iap.initConnection();
      setState(() {
        _connected = true;
      });
    } catch (e) {
      debugPrint('Failed to initialize IAP connection: $e');
      setState(() {
        _statusMessage = 'Failed to connect to store';
        _isSuccess = false;
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _presentCodeRedemptionSheet() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
      setState(() {
        _statusMessage = 'Offer codes are only available on iOS';
        _isSuccess = false;
      });
      return;
    }

    setState(() {
      _loading = true;
      _statusMessage = null;
    });

    try {
      await _iap.presentCodeRedemptionSheetIOS();
      setState(() {
        _statusMessage =
            'Redemption sheet presented. Complete the redemption in the system dialog.';
        _isSuccess = true;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Failed to present redemption sheet: $e';
        _isSuccess = false;
      });
      debugPrint('Error presenting code redemption sheet: $e');
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isIOS = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

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
          'Offer Code Redemption',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Platform Warning for Android
                if (!isIOS) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange[700]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Offer code redemption is only available on iOS devices',
                            style: TextStyle(color: Colors.orange[700]),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

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
                const SizedBox(height: 24),

                // Info Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue[700]),
                            const SizedBox(width: 8),
                            const Text(
                              'About Offer Codes',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Offer codes allow you to provide free or discounted subscriptions to your users. They can be used for:',
                          style: TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '• Promotional campaigns\n'
                          '• Customer retention\n'
                          '• Win-back campaigns\n'
                          '• Special partnerships',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Redemption Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Redeem Offer Code',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isIOS
                              ? 'Tap the button below to open the iOS redemption sheet where you can enter your offer code.'
                              : 'Offer code redemption is not available on Android. Please use an iOS device.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Redemption Button
                        ElevatedButton.icon(
                          onPressed: (isIOS && _connected && !_loading)
                              ? _presentCodeRedemptionSheet
                              : null,
                          icon: const Icon(Icons.card_giftcard),
                          label: const Text('Open Redemption Sheet'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF3B30),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 48),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Status Message
                if (_statusMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isSuccess ? Colors.green[50] : Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color:
                            _isSuccess ? Colors.green[200]! : Colors.red[200]!,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isSuccess ? Icons.check_circle : Icons.error_outline,
                          color:
                              _isSuccess ? Colors.green[700] : Colors.red[700],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _statusMessage!,
                            style: TextStyle(
                              color: _isSuccess
                                  ? Colors.green[700]
                                  : Colors.red[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // How to Get Offer Codes Section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.help_outline, color: Colors.purple[700]),
                            const SizedBox(width: 8),
                            const Text(
                              'How to Get Offer Codes',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '1. Go to App Store Connect\n'
                          '2. Navigate to your app\n'
                          '3. Select "Subscriptions" or "In-App Purchases"\n'
                          '4. Choose "Offer Codes"\n'
                          '5. Create and configure your offer\n'
                          '6. Generate codes for distribution',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
