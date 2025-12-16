import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

/// Billing Programs API Demo (Android 8.2.0+)
///
/// Demonstrates the new Billing Programs API for Google Play Billing 8.2.0+:
/// - isBillingProgramAvailableAndroid: Check if billing program is available
/// - launchExternalLinkAndroid: Launch external link for payment
/// - createBillingProgramReportingDetailsAndroid: Get reporting token
///
/// Available programs:
/// - ExternalOffer: External offers in approved regions
/// - ExternalContentLink: External content linking
///
/// This is separate from the legacy Alternative Billing API.
class BillingProgramsScreen extends StatefulWidget {
  const BillingProgramsScreen({super.key});

  @override
  State<BillingProgramsScreen> createState() => _BillingProgramsScreenState();
}

class _BillingProgramsScreenState extends State<BillingProgramsScreen> {
  final TextEditingController _urlController =
      TextEditingController(text: 'https://openiap.dev');

  BillingProgramAndroid _selectedProgram = BillingProgramAndroid.ExternalOffer;
  ExternalLinkLaunchModeAndroid _launchMode =
      ExternalLinkLaunchModeAndroid.LaunchInExternalBrowserOrApp;
  ExternalLinkTypeAndroid _linkType =
      ExternalLinkTypeAndroid.LinkToDigitalContentOffer;

  bool _isConnected = false;
  bool _isProcessing = false;
  String _statusMessage = '';
  List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _initConnection();
  }

  @override
  void dispose() {
    _urlController.dispose();
    FlutterInappPurchase.instance.endConnection().catchError((e) {
      debugPrint('[BillingPrograms] Error ending connection: $e');
    });
    super.dispose();
  }

  void _addLog(String message) {
    setState(() {
      _logs.insert(0, '[${DateTime.now().toIso8601String()}] $message');
      if (_logs.length > 20) {
        _logs.removeLast();
      }
    });
  }

  Future<void> _initConnection() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      setState(() {
        _statusMessage = 'Billing Programs API is Android-only';
      });
      return;
    }

    try {
      await FlutterInappPurchase.instance.initConnection();
      if (!mounted) return;
      setState(() {
        _isConnected = true;
        _statusMessage = 'Connected to Play Store';
      });
      _addLog('Connection established');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusMessage = 'Failed to connect: $e';
      });
      _addLog('Connection failed: $e');
    }
  }

  Future<void> _checkAvailability() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      _showPlatformWarning();
      return;
    }

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Checking availability...';
    });
    _addLog('Checking ${_selectedProgram.toJson()} availability');

    try {
      final result = await FlutterInappPurchase.instance
          .isBillingProgramAvailableAndroid(_selectedProgram);

      if (!mounted) return;
      setState(() {
        _statusMessage = result.isAvailable
            ? '${_selectedProgram.toJson()} is AVAILABLE'
            : '${_selectedProgram.toJson()} is NOT available';
      });
      _addLog(
        'Result: ${result.billingProgram.toJson()} - '
        'Available: ${result.isAvailable}',
      );

      if (!result.isAvailable && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Billing program not available.\n'
              'This may require approval from Google.',
            ),
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusMessage = 'Error: $e';
      });
      _addLog('Error checking availability: $e');
    } finally {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _launchExternalLink() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      _showPlatformWarning();
      return;
    }

    final url = _urlController.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid URL')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Launching external link...';
    });
    _addLog('Launching external link: $url');

    try {
      final params = LaunchExternalLinkParamsAndroid(
        billingProgram: _selectedProgram,
        launchMode: _launchMode,
        linkType: _linkType,
        linkUri: url,
      );

      final success =
          await FlutterInappPurchase.instance.launchExternalLinkAndroid(params);

      if (!mounted) return;
      setState(() {
        _statusMessage = success
            ? 'External link launched successfully'
            : 'Failed to launch external link';
      });
      _addLog('Launch result: $success');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusMessage = 'Error: $e';
      });
      _addLog('Error launching external link: $e');
    } finally {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _createReportingDetails() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      _showPlatformWarning();
      return;
    }

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Creating reporting details...';
    });
    _addLog('Creating reporting details for ${_selectedProgram.toJson()}');

    try {
      final details = await FlutterInappPurchase.instance
          .createBillingProgramReportingDetailsAndroid(_selectedProgram);

      if (!mounted) return;
      final tokenPreview = details.externalTransactionToken.length > 20
          ? '${details.externalTransactionToken.substring(0, 20)}...'
          : details.externalTransactionToken;

      setState(() {
        _statusMessage = 'Token created: $tokenPreview';
      });
      _addLog(
        'Reporting details created:\n'
        '  Program: ${details.billingProgram.toJson()}\n'
        '  Token: $tokenPreview',
      );

      if (mounted) {
        showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Reporting Token Created'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'External Transaction Token:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  details.externalTransactionToken,
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Report this token to Google Play backend '
                  'within 24 hours after external payment.',
                  style: TextStyle(fontSize: 12, color: Colors.orange),
                ),
              ],
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
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusMessage = 'Error: $e';
      });
      _addLog('Error creating reporting details: $e');
    } finally {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showPlatformWarning() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Billing Programs API is Android-only (8.2.0+)'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Billing Programs API'),
        backgroundColor: Colors.deepPurple,
      ),
      body: kIsWeb || defaultTargetPlatform != TargetPlatform.android
          ? _buildPlatformNotSupported()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildInfoCard(),
                  const SizedBox(height: 16),
                  _buildConnectionStatus(),
                  const SizedBox(height: 16),
                  _buildProgramSelector(),
                  const SizedBox(height: 16),
                  _buildAvailabilitySection(),
                  const SizedBox(height: 16),
                  _buildExternalLinkSection(),
                  const SizedBox(height: 16),
                  _buildReportingSection(),
                  const SizedBox(height: 16),
                  _buildLogsSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildPlatformNotSupported() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.android, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Android Only',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Billing Programs API is only available on Android '
              'with Google Play Billing 8.2.0+',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      color: const Color(0xFFEDE7F6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Billing Programs API (8.2.0+)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'The new Billing Programs API provides:\n'
              '1. isBillingProgramAvailableAndroid - Check availability\n'
              '2. launchExternalLinkAndroid - Open external payment\n'
              '3. createBillingProgramReportingDetailsAndroid - Get token\n\n'
              'This replaces the deprecated Alternative Billing API.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Requires Google Play approval for your app',
                style: TextStyle(fontSize: 12, color: Colors.deepOrange),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionStatus() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              _isConnected ? Icons.check_circle : Icons.error,
              color: _isConnected ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isConnected ? 'Connected' : 'Disconnected',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _isConnected ? Colors.green : Colors.red,
                    ),
                  ),
                  Text(
                    _statusMessage,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            if (_isProcessing)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgramSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Billing Program',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<BillingProgramAndroid>(
              value: _selectedProgram,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: [
                DropdownMenuItem(
                  value: BillingProgramAndroid.ExternalOffer,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('ExternalOffer'),
                      Text(
                        'External offers in approved regions',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: BillingProgramAndroid.ExternalContentLink,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('ExternalContentLink'),
                      Text(
                        'External content linking',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedProgram = value;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailabilitySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Step 1: Check Availability',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Check if the selected billing program is available '
              'for the current user/device.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed:
                  _isProcessing || !_isConnected ? null : _checkAvailability,
              icon: const Icon(Icons.search),
              label: const Text('Check Availability'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExternalLinkSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Step 2: Launch External Link',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Open an external link for the user to complete payment.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'External URL',
                hintText: 'https://your-payment-site.com/checkout',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<ExternalLinkLaunchModeAndroid>(
                    value: _launchMode,
                    decoration: const InputDecoration(
                      labelText: 'Launch Mode',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: ExternalLinkLaunchModeAndroid
                            .LaunchInExternalBrowserOrApp,
                        child: Text('Browser', style: TextStyle(fontSize: 13)),
                      ),
                      DropdownMenuItem(
                        value:
                            ExternalLinkLaunchModeAndroid.CallerWillLaunchLink,
                        child: Text('Caller', style: TextStyle(fontSize: 13)),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _launchMode = value;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<ExternalLinkTypeAndroid>(
                    value: _linkType,
                    decoration: const InputDecoration(
                      labelText: 'Link Type',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value:
                            ExternalLinkTypeAndroid.LinkToDigitalContentOffer,
                        child: Text('Content', style: TextStyle(fontSize: 13)),
                      ),
                      DropdownMenuItem(
                        value: ExternalLinkTypeAndroid.LinkToAppDownload,
                        child: Text('Download', style: TextStyle(fontSize: 13)),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _linkType = value;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed:
                  _isProcessing || !_isConnected ? null : _launchExternalLink,
              icon: const Icon(Icons.open_in_browser),
              label: const Text('Launch External Link'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportingSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Step 3: Create Reporting Token',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'After user completes external payment, create a token '
              'to report to Google Play within 24 hours.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isProcessing || !_isConnected
                  ? null
                  : _createReportingDetails,
              icon: const Icon(Icons.token),
              label: const Text('Create Reporting Token'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Logs',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () => setState(() => _logs.clear()),
                  child: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              height: 200,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: _logs.isEmpty
                  ? const Center(
                      child: Text(
                        'No logs yet',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _logs.length,
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          _logs[index],
                          style: const TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
