import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:flutter_inapp_purchase/types.dart' as iap_types;
import '../iap_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isRestoring = false;
  bool _isManagingSubscriptions = false;
  bool _isClearingCache = false;
  bool _isConsumingProducts = false;
  String? _result;
  String? _error;

  Future<void> _restorePurchases() async {
    setState(() {
      _isRestoring = true;
      _error = null;
      _result = null;
    });

    try {
      await FlutterInappPurchase.instance.restorePurchases();
      if (mounted) {
        setState(() {
          _result = 'Purchases restored successfully';
          _isRestoring = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isRestoring = false;
        });
      }
    }
  }

  Future<void> _manageSubscriptions() async {
    setState(() {
      _isManagingSubscriptions = true;
      _error = null;
      _result = null;
    });

    try {
      final iapProvider = IapProvider.of(context);
      if (iapProvider == null || !iapProvider.connected) {
        setState(() {
          _error = 'Store not connected';
          _isManagingSubscriptions = false;
        });
        return;
      }

      await iapProvider.showManageSubscriptions();
      if (mounted) {
        setState(() {
          _result = 'Opened subscription management';
          _isManagingSubscriptions = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isManagingSubscriptions = false;
        });
      }
    }
  }

  Future<void> _forceClearAllPurchases() async {
    setState(() {
      _isConsumingProducts = true;
      _error = null;
      _result = null;
    });

    try {
      // Specific product IDs to clear
      final List<String> productIds = [
        'dev.hyo.martie.10bulbs',
        'dev.hyo.martie.30bulbs',
      ];

      debugPrint('=== FORCE CLEAR ALL PURCHASES START ===');

      // First, restore purchases to get all purchase history
      debugPrint('Restoring purchases...');
      await FlutterInappPurchase.instance.restorePurchases();

      // Wait a bit for restoration to complete
      await Future<void>.delayed(const Duration(seconds: 2));

      // Now get all available purchases
      debugPrint('Getting available purchases...');
      final List<iap_types.Purchase> purchases =
          await FlutterInappPurchase.instance.getAvailablePurchases();
      debugPrint('Found ${purchases.length} total purchases');

      int consumedCount = 0;
      List<String> consumedProducts = [];
      List<String> errors = [];

      // Process all purchases
      for (final purchase in purchases) {
        debugPrint(
            '\nPurchase found: ${purchase.productId}, token: ${purchase.purchaseToken?.substring(0, 20)}...');

        // Only process our specific product IDs
        if (productIds.contains(purchase.productId)) {
          if (purchase.purchaseToken != null) {
            debugPrint('Attempting to force consume: ${purchase.productId}');

            // Try multiple times with delay
            bool consumed = false;
            for (int attempt = 0; attempt < 3 && !consumed; attempt++) {
              try {
                await FlutterInappPurchase.instance.consumePurchaseAndroid(
                  purchaseToken: purchase.purchaseToken!,
                );
                consumed = true;
                consumedCount++;
                consumedProducts.add(purchase.productId);
                debugPrint(
                    '✅ Force consumed: ${purchase.productId} (attempt ${attempt + 1})');
              } catch (e) {
                debugPrint('❌ Attempt ${attempt + 1} failed: $e');
                if (attempt < 2) {
                  await Future<void>.delayed(const Duration(milliseconds: 500));
                } else {
                  errors.add('${purchase.productId}: $e');
                }
              }
            }
          } else {
            debugPrint('⚠️ No token for ${purchase.productId}');
          }
        } else {
          debugPrint('Skipping non-target product: ${purchase.productId}');
        }
      }

      // Clear transaction cache to force refresh
      try {
        await FlutterInappPurchase.instance.clearTransactionCache();
        debugPrint('Transaction cache cleared');
      } catch (e) {
        debugPrint('Failed to clear transaction cache: $e');
      }

      if (mounted) {
        setState(() {
          _result = 'Force consumed $consumedCount purchases\n'
              'Products: ${consumedProducts.join(', ')}\n\n'
              '${errors.isNotEmpty ? 'Errors:\n${errors.join('\n')}\n\n' : ''}'
              'If still seeing "already own this item":\n'
              '1. Clear Google Play Store cache & data\n'
              '2. Sign out and back into Google Play\n'
              '3. Wait 5-10 minutes for sync';
          _isConsumingProducts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Force clear failed: $e';
          _isConsumingProducts = false;
        });
      }
    }
  }

  Future<void> _clearTransactionCache() async {
    setState(() {
      _isClearingCache = true;
      _error = null;
      _result = null;
    });

    try {
      final iapProvider = IapProvider.of(context);
      if (iapProvider != null) {
        await iapProvider.clearTransactionCache();
      }
      if (mounted) {
        setState(() {
          _result = 'Transaction cache cleared';
          _isClearingCache = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isClearingCache = false;
        });
      }
    }
  }

  Future<void> _consumeAllProducts() async {
    setState(() {
      _isConsumingProducts = true;
      _error = null;
      _result = null;
    });

    try {
      // First restore purchases to get fresh data
      await FlutterInappPurchase.instance.restorePurchases();

      // Wait for restoration to complete
      await Future<void>.delayed(const Duration(seconds: 1));

      // Get all available purchases (pending transactions)
      final List<iap_types.Purchase> purchases =
          await FlutterInappPurchase.instance.getAvailablePurchases();

      if (purchases.isEmpty) {
        setState(() {
          _result = 'No unfinished transactions found.\n\n'
              'If you\'re still seeing "You already own this item":\n\n'
              'Option 1 - Google Play Console:\n'
              '1. Go to Google Play Console\n'
              '2. Navigate to Order Management\n'
              '3. Find and refund test purchases\n\n'
              'Option 2 - Clear App Data:\n'
              '1. Settings > Apps > Google Play Store\n'
              '2. Storage > Clear Data\n'
              '3. Restart the app\n\n'
              'Option 3 - Use "Force Clear All Purchases" button';
          _isConsumingProducts = false;
        });
        return;
      }

      int consumedCount = 0;
      List<String> consumedProducts = [];
      List<String> errors = [];

      debugPrint('Found ${purchases.length} purchases to process');

      for (final purchase in purchases) {
        try {
          if (Platform.isAndroid) {
            // For Android: directly consume the purchase
            if (purchase.purchaseToken != null) {
              debugPrint(
                  'Processing purchase: ${purchase.productId}, token: ${purchase.purchaseToken}');

              // Try consume first (for consumable products)
              bool processed = false;
              try {
                await FlutterInappPurchase.instance.consumePurchaseAndroid(
                  purchaseToken: purchase.purchaseToken!,
                );
                consumedCount++;
                consumedProducts.add(purchase.productId);
                processed = true;
                debugPrint('✅ Consumed: ${purchase.productId}');
              } catch (e) {
                debugPrint('Consume failed: $e');
                // If consume fails, try to acknowledge
                try {
                  await FlutterInappPurchase.instance
                      .acknowledgePurchaseAndroid(
                    purchaseToken: purchase.purchaseToken!,
                  );
                  consumedCount++;
                  consumedProducts.add('${purchase.productId} (acknowledged)');
                  processed = true;
                  debugPrint('✅ Acknowledged: ${purchase.productId}');
                } catch (e2) {
                  errors.add('${purchase.productId}: $e2');
                  debugPrint(
                      '❌ Failed to consume/acknowledge ${purchase.productId}: $e, $e2');
                }
              }

              if (!processed) {
                errors.add('${purchase.productId}: Could not process');
              }
            } else {
              debugPrint('⚠️ No purchase token for: ${purchase.productId}');
              errors.add('${purchase.productId}: No token');
            }
          } else if (Platform.isIOS) {
            // For iOS: finish transaction
            await FlutterInappPurchase.instance.finishTransaction(purchase);
            consumedCount++;
          }
        } catch (e) {
          debugPrint('Failed to process item ${purchase.productId}: $e');
        }
      }

      // Clear transaction cache after processing
      try {
        await FlutterInappPurchase.instance.clearTransactionCache();
        debugPrint('Transaction cache cleared');
      } catch (e) {
        debugPrint('Failed to clear cache: $e');
      }

      if (mounted) {
        setState(() {
          _result = 'Processed $consumedCount transactions\n'
              '${consumedProducts.isNotEmpty ? '\nConsumed: ${consumedProducts.join(', ')}' : ''}'
              '${errors.isNotEmpty ? '\n\nErrors:\n${errors.join('\n')}' : ''}'
              '\n\nIf still seeing "already own" error:\n'
              '1. Uninstall and reinstall the app\n'
              '2. Clear Google Play Store cache\n'
              '3. Wait 5-10 minutes for sync';
          _isConsumingProducts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isConsumingProducts = false;
        });
      }
    }
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
          'Settings',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Connection Status
          _buildConnectionStatus(),
          const SizedBox(height: 20),

          // Settings Options
          _buildSettingsSection(),

          // Result/Error Messages
          if (_result != null) _buildSuccessMessage(_result!),
          if (_error != null) _buildErrorMessage(_error!),
        ],
      ),
    );
  }

  Widget _buildConnectionStatus() {
    final iapProvider = IapProvider.of(context);
    final isConnected = iapProvider?.connected ?? false;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isConnected ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            isConnected
                ? CupertinoIcons.checkmark_circle_fill
                : CupertinoIcons.xmark_circle_fill,
            color:
                isConnected ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            isConnected ? 'Store Connected' : 'Store Disconnected',
            style: TextStyle(
              color: isConnected
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFFF44336),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
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
      child: Column(
        children: [
          _buildSettingsTile(
            icon: CupertinoIcons.arrow_clockwise_circle_fill,
            iconColor: const Color(0xFF007AFF),
            title: 'Restore Purchases',
            subtitle: 'Restore your previous purchases',
            isLoading: _isRestoring,
            onTap: _isRestoring ? null : _restorePurchases,
          ),
          _buildDivider(),
          _buildSettingsTile(
            icon: CupertinoIcons.calendar_circle_fill,
            iconColor: const Color(0xFF5856D6),
            title: 'Manage Subscriptions',
            subtitle: 'View and manage your active subscriptions',
            isLoading: _isManagingSubscriptions,
            onTap: _isManagingSubscriptions ? null : _manageSubscriptions,
          ),
          _buildDivider(),
          _buildSettingsTile(
            icon: CupertinoIcons.trash_circle_fill,
            iconColor: const Color(0xFFFF9500),
            title: 'Clear Transaction Cache',
            subtitle: 'Clear locally cached transaction data',
            isLoading: _isClearingCache,
            onTap: _isClearingCache ? null : _clearTransactionCache,
          ),
          _buildDivider(),
          _buildSettingsTile(
            icon: CupertinoIcons.checkmark_seal_fill,
            iconColor: const Color(0xFF34C759),
            title: 'Consume All Products (Test)',
            subtitle: 'Consume/acknowledge all unfinished transactions',
            isLoading: _isConsumingProducts,
            onTap: _isConsumingProducts ? null : _consumeAllProducts,
          ),
          if (Platform.isAndroid) ...[
            _buildDivider(),
            _buildSettingsTile(
              icon: CupertinoIcons.arrow_counterclockwise_circle_fill,
              iconColor: const Color(0xFFFF3B30),
              title: 'Force Clear All Purchases',
              subtitle: 'Restore purchases then consume all (Android only)',
              isLoading: _isConsumingProducts,
              onTap: _isConsumingProducts ? null : _forceClearAllPurchases,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isLoading,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isLoading)
              const CupertinoActivityIndicator()
            else
              Icon(
                CupertinoIcons.chevron_forward,
                color: Colors.grey[400],
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(
        height: 1,
        color: Colors.grey[200],
      ),
    );
  }

  Widget _buildSuccessMessage(String message) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC3E6CB)),
      ),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.checkmark_circle_fill,
            color: Color(0xFF4CAF50),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF155724),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage(String error) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
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
}
