import 'package:flutter/material.dart';
import 'iap_provider.dart';
import 'screens/home_screen.dart';
import 'screens/products_screen.dart';
import 'screens/subscriptions_screen.dart';
import 'screens/purchase_history_screen.dart';
import 'screens/redeem_code_screen.dart';
import 'screens/settings_screen.dart';

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IapProviderWidget(
      child: MaterialApp(
        title: 'Flutter IAP Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          fontFamily: 'SF Pro Display',
          scaffoldBackgroundColor: const Color(0xFFF7F8FA),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.black),
            titleTextStyle: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        home: const HomeScreen(),
        routes: {
          '/products': (context) => const ProductsScreen(),
          '/subscriptions': (context) => const SubscriptionsScreen(),
          '/history': (context) => const PurchaseHistoryScreen(),
          '/redeem': (context) => const RedeemCodeScreen(),
          '/settings': (context) => const SettingsScreen(),
        },
      ),
    );
  }
}
