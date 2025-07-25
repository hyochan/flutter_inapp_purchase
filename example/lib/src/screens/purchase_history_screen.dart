import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import '../iap_provider.dart';

class PurchaseHistoryScreen extends StatefulWidget {
  const PurchaseHistoryScreen({Key? key}) : super(key: key);

  @override
  State<PurchaseHistoryScreen> createState() => _PurchaseHistoryScreenState();
}

class _PurchaseHistoryScreenState extends State<PurchaseHistoryScreen> {
  List<PurchasedItem>? _purchaseHistory;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Load purchase history after a delay to ensure provider is ready
    Future<void>.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _loadPurchaseHistory();
      }
    });
  }

  Future<void> _loadPurchaseHistory() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final iapProvider = IapProvider.of(context);
      if (iapProvider == null || !iapProvider.connected) {
        // Wait a bit for connection to establish
        await Future<void>.delayed(const Duration(seconds: 1));
        if (!mounted) return;
      }

      if (iapProvider != null && iapProvider.connected) {
        final history = await iapProvider.getPurchaseHistory();
        if (mounted) {
          setState(() {
            _purchaseHistory = history;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = 'Store not connected';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final iapProvider = IapProvider.of(context);

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
          'Purchase History',
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.refresh, color: Colors.black),
            onPressed: _isLoading ? null : _loadPurchaseHistory,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadPurchaseHistory,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Connection Status
                  _buildConnectionStatus(iapProvider),
                  const SizedBox(height: 20),

                  // Error Message
                  if (_error != null) _buildErrorMessage(_error!),

                  // Purchase History
                  if (_purchaseHistory == null || _purchaseHistory!.isEmpty)
                    _buildEmptyState()
                  else
                    ..._purchaseHistory!.map((purchase) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildPurchaseCard(purchase),
                        )),
                ],
              ),
            ),
    );
  }

  Widget _buildConnectionStatus(IapProvider? iapProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: (iapProvider?.connected ?? false)
            ? const Color(0xFFE8F5E9)
            : const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            (iapProvider?.connected ?? false)
                ? CupertinoIcons.checkmark_circle_fill
                : CupertinoIcons.xmark_circle_fill,
            color: (iapProvider?.connected ?? false)
                ? const Color(0xFF4CAF50)
                : const Color(0xFFF44336),
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            (iapProvider?.connected ?? false)
                ? 'Store Connected'
                : 'Store Disconnected',
            style: TextStyle(
              color: (iapProvider?.connected ?? false)
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFFF44336),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage(String error) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFCDD2)),
      ),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.exclamationmark_circle_fill,
            color: Color(0xFFF44336),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(
                color: Color(0xFFF44336),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            CupertinoIcons.clock,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Purchase History',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your past purchases will appear here',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPurchaseCard(PurchasedItem purchase) {
    final productId = purchase.productId ?? 'Unknown Product';
    final transactionId = purchase.transactionId ?? '';
    final transactionDate = purchase.transactionDate;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    CupertinoIcons.checkmark_circle_fill,
                    color: Color(0xFF2196F3),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        productId,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      if (transactionDate != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(transactionDate),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (transactionId.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Text(
                      'Transaction ID: ',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Expanded(
                      child: Text(
                        transactionId,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF1A1A1A),
                          fontFamily: 'monospace',
                        ),
                        overflow: TextOverflow.ellipsis,
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

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
