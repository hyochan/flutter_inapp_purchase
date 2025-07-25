import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../iap_provider.dart';

class RedeemCodeScreen extends StatefulWidget {
  const RedeemCodeScreen({Key? key}) : super(key: key);

  @override
  State<RedeemCodeScreen> createState() => _RedeemCodeScreenState();
}

class _RedeemCodeScreenState extends State<RedeemCodeScreen> {
  bool _isLoading = false;
  String? _result;
  String? _error;

  Future<void> _presentRedeemCode() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _result = null;
    });

    try {
      final iapProvider = IapProvider.of(context);
      if (iapProvider == null || !iapProvider.connected) {
        setState(() {
          _error = 'Store not connected';
          _isLoading = false;
        });
        return;
      }

      await iapProvider.presentCodeRedemption();
      if (mounted) {
        setState(() {
          _result = 'Redeem code sheet presented successfully';
          _isLoading = false;
        });
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
          'Redeem Code',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Connection Status
          _buildConnectionStatus(),
          const SizedBox(height: 20),

          // Main Content
          _buildRedeemCard(),
          const SizedBox(height: 20),
          _buildInstructions(),

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

  Widget _buildRedeemCard() {
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
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                CupertinoIcons.gift_fill,
                color: Color(0xFF4CAF50),
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Redeem Promo Code',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter your promo code to unlock content',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: CupertinoButton(
                color: const Color(0xFF4CAF50),
                borderRadius: BorderRadius.circular(12),
                padding: const EdgeInsets.symmetric(vertical: 16),
                onPressed: _isLoading ? null : _presentRedeemCode,
                child: _isLoading
                    ? const CupertinoActivityIndicator(color: Colors.white)
                    : const Text(
                        'Enter Code',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F8FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                CupertinoIcons.lightbulb_fill,
                color: Color(0xFF007AFF),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'How to redeem',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF007AFF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInstructionStep('1', 'Tap the "Enter Code" button above'),
          _buildInstructionStep(
              '2', 'Enter your promo code in the system dialog'),
          _buildInstructionStep(
              '3', 'Follow the on-screen instructions to complete'),
          _buildInstructionStep(
              '4', 'Your content will be unlocked automatically'),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFF007AFF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
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
