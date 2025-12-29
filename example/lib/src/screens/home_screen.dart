import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    const Text(
                      'Flutter IAP Demo',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF007AFF),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'In-app purchase example',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              // Menu Items
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildMenuItem(
                        context,
                        icon: CupertinoIcons.square_grid_2x2,
                        title: 'All Products',
                        subtitle: 'View all available products',
                        color: const Color(0xFFFF9500),
                        onTap: () =>
                            Navigator.pushNamed(context, '/all-products'),
                      ),
                      const Divider(height: 1),
                      _buildMenuItem(
                        context,
                        icon: CupertinoIcons.shopping_cart,
                        title: 'Purchase Flow',
                        subtitle: 'Buy consumable products',
                        color: const Color(0xFF007AFF),
                        onTap: () =>
                            Navigator.pushNamed(context, '/purchase-flow'),
                      ),
                      const Divider(height: 1),
                      _buildMenuItem(
                        context,
                        icon: CupertinoIcons.creditcard,
                        title: 'Subscription Flow',
                        subtitle: 'Manage subscriptions',
                        color: const Color(0xFF34C759),
                        onTap: () =>
                            Navigator.pushNamed(context, '/subscription-flow'),
                      ),
                      const Divider(height: 1),
                      _buildMenuItem(
                        context,
                        icon: CupertinoIcons.bag,
                        title: 'Available Purchases',
                        subtitle: 'View and restore purchases',
                        color: const Color(0xFF5856D6),
                        onTap: () => Navigator.pushNamed(
                            context, '/available-purchases'),
                      ),
                      const Divider(height: 1),
                      _buildMenuItem(
                        context,
                        icon: CupertinoIcons.gift,
                        title: 'Redeem Offer Code',
                        subtitle: !kIsWeb &&
                                defaultTargetPlatform == TargetPlatform.iOS
                            ? 'Redeem promotional codes'
                            : 'iOS only feature',
                        color: const Color(0xFFFF3B30),
                        onTap: () =>
                            Navigator.pushNamed(context, '/offer-code'),
                      ),
                      const Divider(height: 1),
                      _buildMenuItem(
                        context,
                        icon: CupertinoIcons.hammer,
                        title: 'Builder Pattern Demo',
                        subtitle: 'DSL-like purchase API',
                        color: const Color(0xFF9B59B6),
                        onTap: () =>
                            Navigator.pushNamed(context, '/builder-demo'),
                      ),
                      const Divider(height: 1),
                      _buildMenuItem(
                        context,
                        icon: CupertinoIcons.money_dollar_circle,
                        title: 'Alternative Billing',
                        subtitle: !kIsWeb &&
                                defaultTargetPlatform == TargetPlatform.android
                            ? 'Google Play alternative billing'
                            : 'External purchase links',
                        color: const Color(0xFFFF9800),
                        onTap: () => Navigator.pushNamed(
                            context, '/alternative-billing'),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Info Section
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    Text(
                      'Platform: ${defaultTargetPlatform.name}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Version: 8.0.0',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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
