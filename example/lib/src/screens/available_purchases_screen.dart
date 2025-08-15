import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

class AvailablePurchasesScreen extends StatefulWidget {
  const AvailablePurchasesScreen({Key? key}) : super(key: key);

  @override
  State<AvailablePurchasesScreen> createState() =>
      _AvailablePurchasesScreenState();
}

class _AvailablePurchasesScreenState extends State<AvailablePurchasesScreen> {
  final FlutterInappPurchase _iap = FlutterInappPurchase.instance;

  List<Purchase> _availablePurchases = [];
  List<PurchasedItem> _purchaseHistory = [];
  bool _loading = false;
  bool _connected = false;
  String? _error;

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
      setState(() {
        _error = e.toString();
      });
      debugPrint('Failed to initialize IAP connection: $e');
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _loadPurchases() async {
    if (!_connected) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Load available purchases (non-consumed)
      final availablePurchases = await _iap.getAvailablePurchases();

      // Load purchase history
      final purchaseHistory = await _iap.getPurchaseHistory();

      setState(() {
        _availablePurchases = availablePurchases;
        _purchaseHistory = purchaseHistory ?? [];
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
      debugPrint('Error loading purchases: $e');
    } finally {
      setState(() {
        _loading = false;
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
      setState(() {
        _availablePurchases = restored;
      });

      if (mounted) {
        showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Restore Complete'),
            content: Text('Restored ${_availablePurchases.length} purchase(s)'),
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

  Widget _buildAvailablePurchase(Purchase purchase) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    purchase.productId,
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
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Active',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (purchase.transactionDate != null) ...[
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Purchased: ${DateTime.fromMillisecondsSinceEpoch(
                      int.tryParse(purchase.transactionDate ?? '') ?? 0,
                    ).toLocal().toString().split('.')[0]}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
            if (purchase.transactionId != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.receipt, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Transaction ID: ${purchase.transactionId}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseHistoryItem(PurchasedItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.productId ?? 'Unknown Product',
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
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'History',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (item.transactionDate != null) ...[
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Purchased: ${DateTime.fromMillisecondsSinceEpoch(
                      int.tryParse(item.transactionDate.toString()) ?? 0,
                    ).toLocal().toString().split('.')[0]}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
            if (item.transactionId != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.receipt, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Transaction ID: ${item.transactionId}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
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
                    const SizedBox(height: 8),
                    ..._availablePurchases
                        .map((purchase) => _buildAvailablePurchase(purchase)),
                    const SizedBox(height: 24),
                  ],

                  // Purchase History Section
                  if (_purchaseHistory.isNotEmpty) ...[
                    const Text(
                      'Purchase History',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._purchaseHistory
                        .map((item) => _buildPurchaseHistoryItem(item)),
                  ],

                  // Empty State
                  if (_availablePurchases.isEmpty &&
                      _purchaseHistory.isEmpty &&
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
