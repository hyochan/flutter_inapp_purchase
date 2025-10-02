import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:flutter_inapp_purchase/extensions/purchase_helpers.dart';

import '../widgets/purchase_detail_view.dart';

class AvailablePurchasesScreen extends StatefulWidget {
  const AvailablePurchasesScreen({Key? key}) : super(key: key);

  @override
  State<AvailablePurchasesScreen> createState() =>
      _AvailablePurchasesScreenState();
}

class _AvailablePurchasesScreenState extends State<AvailablePurchasesScreen> {
  final FlutterInappPurchase _iap = FlutterInappPurchase.instance;

  List<Purchase> _availablePurchases = [];
  List<Purchase> _purchaseHistory = [];
  bool _loading = false;
  bool _historyLoading = false;
  bool _connected = false;
  String? _error;
  String? _historyError;

  /// Convert various date formats to milliseconds timestamp
  int _parseTimestamp(dynamic date) {
    if (date == null) return 0;

    if (date is String) {
      // Try to parse as ISO date string first
      final dateTime = DateTime.tryParse(date);
      if (dateTime != null) {
        return dateTime.millisecondsSinceEpoch;
      }
      // Try to parse as milliseconds string
      return int.tryParse(date) ?? 0;
    } else if (date is num) {
      return date.toInt();
    } else if (date is DateTime) {
      return date.millisecondsSinceEpoch;
    }

    return 0;
  }

  /// Remove duplicate purchases by productId, keeping the most recent transaction
  List<Purchase> _deduplicatePurchases(List<Purchase> purchases) {
    final Map<String, Purchase> uniquePurchases = {};

    for (final purchase in purchases) {
      final existingPurchase = uniquePurchases[purchase.productId];
      if (existingPurchase == null) {
        uniquePurchases[purchase.productId] = purchase;
      } else {
        // Keep the most recent transaction
        final existingTimestamp =
            _parseTimestamp(existingPurchase.transactionDate);
        final newTimestamp = _parseTimestamp(purchase.transactionDate);

        if (newTimestamp > existingTimestamp) {
          uniquePurchases[purchase.productId] = purchase;
        }
      }
    }

    return uniquePurchases.values.toList();
  }

  IapPlatform _platformOrDefault() {
    try {
      return getCurrentPlatform();
    } catch (_) {
      return IapPlatform.Android;
    }
  }

  @override
  void initState() {
    super.initState();
    _initConnection();
  }

  @override
  void dispose() {
    _iap.endConnection();
    super.dispose();
  }

  Future<void> _initConnection() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _iap.initConnection();
      setState(() {
        _connected = true;
      });
      await _loadPurchases();
    } catch (e) {
      if (!mounted) {
        debugPrint('Failed to initialize IAP connection: $e');
        return;
      }
      setState(() {
        _error = e.toString();
        _loading = false;
      });
      debugPrint('Failed to initialize IAP connection: $e');
    }
  }

  Future<void> _loadPurchases() async {
    if (!_connected) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Load available purchases (non-consumed / active)
      final availablePurchases = await _iap.getAvailablePurchases(
        onlyIncludeActiveItemsIOS: true,
      );
      debugPrint(
          'Loaded ${availablePurchases.length} available purchases (non-consumed/non-acknowledged)');

      // Remove duplicates by productId, keeping the most recent one
      final deduplicatedPurchases = _deduplicatePurchases(availablePurchases);

      if (!mounted) {
        return;
      }

      setState(() {
        _availablePurchases = deduplicatedPurchases;
        _loading = false;
      });

      debugPrint(
          'After deduplication: ${deduplicatedPurchases.length} unique active purchases');

      if (_platformOrDefault() == IapPlatform.IOS) {
        unawaited(_loadPurchaseHistory());
      } else if (mounted) {
        setState(() {
          _purchaseHistory = [];
        });
      }
    } catch (e) {
      if (!mounted) {
        debugPrint('Error loading purchases: $e');
        return;
      }
      setState(() {
        _error = e.toString();
        _loading = false;
        _historyLoading = false;
      });
      debugPrint('Error loading purchases: $e');
    }
  }

  Future<void> _loadPurchaseHistory() async {
    setState(() {
      _historyLoading = true;
      _historyError = null;
    });

    Timer? warningTimer;
    warningTimer = Timer(const Duration(seconds: 12), () {
      if (!mounted || !_historyLoading || _historyError != null) {
        return;
      }
      setState(() {
        _historyError =
            'Fetching purchase history is taking longer than expected. Still waiting...';
      });
    });

    try {
      final purchaseHistory = await _iap.getAvailablePurchases(
        onlyIncludeActiveItemsIOS: false,
        alsoPublishToEventListenerIOS: false,
      );
      debugPrint('Loaded ${purchaseHistory.length} purchases from history');

      if (!mounted) {
        warningTimer?.cancel();
        return;
      }

      setState(() {
        _purchaseHistory = purchaseHistory;
        _historyError = null;
      });
    } catch (e) {
      debugPrint('Error loading purchase history: $e');
      if (!mounted) {
        warningTimer?.cancel();
        return;
      }
      setState(() {
        _historyError = e.toString();
      });
    } finally {
      warningTimer?.cancel();
      if (!mounted) {
        return;
      }
      setState(() {
        _historyLoading = false;
      });
    }
  }

  Future<void> _restorePurchases() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final restored = await _iap.getAvailablePurchases();

      // Remove duplicates by productId, keeping the most recent one
      final deduplicatedPurchases = _deduplicatePurchases(restored);

      setState(() {
        _availablePurchases = deduplicatedPurchases;
      });

      if (mounted) {
        showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Restore Complete'),
            content: Text(
                'Restored ${_availablePurchases.length} unique purchase(s)'),
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
      setState(() {
        _error = e.toString();
      });
      debugPrint('Error restoring purchases: $e');
    } finally {
      setState(() {
        _loading = false;
      });
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
                    statusLabel: 'Purchase Data',
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

  Widget _buildAvailablePurchase(Purchase purchase) {
    return _buildPurchaseSummaryCard(
      purchase: purchase,
      statusLabel: 'Active',
      statusColor: Colors.green.shade600,
    );
  }

  Widget _buildPurchaseHistoryItem(Purchase item) {
    return _buildPurchaseSummaryCard(
      purchase: item,
      statusLabel: 'History',
      statusColor: Colors.blueGrey.shade600,
    );
  }

  Widget _buildPurchaseSummaryCard({
    required Purchase purchase,
    required String statusLabel,
    required Color statusColor,
  }) {
    final infoChips = <Widget>[
      _infoChip('State: ${purchase.purchaseState.name}')
    ];

    infoChips.add(
        _infoChip('Platform: ${purchase.platform.toJson().toLowerCase()}'));
    infoChips.add(_infoChip('Quantity: ${purchase.quantity}'));
    infoChips.add(_infoChip('Auto renew: ${purchase.isAutoRenewing}'));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    purchase.productId.isEmpty
                        ? 'Unknown product'
                        : purchase.productId,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: infoChips,
            ),
            if (purchase.transactionDate != 0) ...[
              const SizedBox(height: 12),
              Text(
                'Transaction: ${_formatReadableDate(purchase.transactionDate)}',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showPurchaseDetails(purchase),
                icon: const Icon(Icons.receipt_long, size: 18),
                label: const Text('View Purchase Data'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }

  String _formatReadableDate(double timestamp) {
    if (timestamp == 0) {
      return 'Unknown';
    }
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp.round());
    return date.toLocal().toString().split('.').first;
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
          'Available Purchases',
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _loading ? null : _loadPurchases,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadPurchases,
              child: ListView(
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

                  // Restore Button
                  ElevatedButton.icon(
                    onPressed:
                        _loading || !_connected ? null : _restorePurchases,
                    icon: const Icon(Icons.restore),
                    label: const Text('Restore Purchases'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5856D6),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Error Message
                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red[700]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: TextStyle(color: Colors.red[700]),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Available Purchases Section
                  if (_availablePurchases.isNotEmpty) ...[
                    const Text(
                      'Active Purchases',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Non-consumed purchases and active subscriptions',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._availablePurchases
                        .map((purchase) => _buildAvailablePurchase(purchase)),
                    const SizedBox(height: 24),
                  ],

                  // Purchase History Section (iOS only)
                  if (_platformOrDefault() == IapPlatform.IOS) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Expanded(
                          child: Text(
                            'Purchase History',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed:
                              _historyLoading ? null : _loadPurchaseHistory,
                          icon: const Icon(Icons.history),
                          label: Text(
                            _purchaseHistory.isEmpty
                                ? 'Load History'
                                : 'Reload History',
                          ),
                        ),
                      ],
                    ),
                    const Text(
                      'All purchases including consumed items',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_historyLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_historyError != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          _historyError!,
                          style:
                              const TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                    if (_purchaseHistory.isNotEmpty)
                      ..._purchaseHistory
                          .map((item) => _buildPurchaseHistoryItem(item)),
                    const SizedBox(height: 24),
                  ],

                  // Empty State
                  if (_availablePurchases.isEmpty &&
                      _purchaseHistory.isEmpty &&
                      !_historyLoading &&
                      _error == null) ...[
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_bag_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No purchases found',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your purchased items will appear here',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
