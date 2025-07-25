import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Flutter IAP Demo',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'StoreKit 2 Example',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 32),

                // Menu Items
                _buildMenuItem(
                  context,
                  icon: CupertinoIcons.shopping_cart,
                  title: 'Products',
                  subtitle: 'View and purchase products',
                  color: const Color(0xFF007AFF),
                  onTap: () => Navigator.pushNamed(context, '/products'),
                ),
                const SizedBox(height: 16),

                _buildMenuItem(
                  context,
                  icon: CupertinoIcons.creditcard,
                  title: 'Subscriptions',
                  subtitle: 'Manage your subscriptions',
                  color: const Color(0xFF34C759),
                  onTap: () => Navigator.pushNamed(context, '/subscriptions'),
                ),
                const SizedBox(height: 16),

                _buildMenuItem(
                  context,
                  icon: CupertinoIcons.clock,
                  title: 'Purchase History',
                  subtitle: 'View past purchases',
                  color: const Color(0xFF5856D6),
                  onTap: () => Navigator.pushNamed(context, '/history'),
                ),
                const SizedBox(height: 16),

                if (Platform.isIOS) ...[
                  _buildMenuItem(
                    context,
                    icon: CupertinoIcons.gift,
                    title: 'Redeem Code',
                    subtitle: 'Enter promotional codes',
                    color: const Color(0xFFFF3B30),
                    onTap: () => Navigator.pushNamed(context, '/redeem'),
                  ),
                  const SizedBox(height: 16),
                ],

                _buildMenuItem(
                  context,
                  icon: CupertinoIcons.settings,
                  title: 'Settings',
                  subtitle: 'Debug options and info',
                  color: const Color(0xFF8E8E93),
                  onTap: () => Navigator.pushNamed(context, '/settings'),
                ),
                const SizedBox(height: 16),

                if (Platform.isAndroid) ...[
                  _buildMenuItem(
                    context,
                    icon: CupertinoIcons.exclamationmark_triangle,
                    title: 'Debug Purchases',
                    subtitle: 'View and consume pending purchases',
                    color: Colors.orange,
                    onTap: () =>
                        Navigator.pushNamed(context, '/debug-purchases'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
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
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
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
                      fontSize: 18,
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
            Icon(
              CupertinoIcons.chevron_right,
              color: Colors.grey[400],
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
