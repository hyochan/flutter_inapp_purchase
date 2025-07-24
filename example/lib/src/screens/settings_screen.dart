import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
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

  @override
  Widget build(BuildContext context) {
    // Connection status handled via iap_provider

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
    // For now, assume connected status is true
    final isConnected = true;
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
