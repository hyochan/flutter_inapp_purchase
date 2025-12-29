import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/all_products_screen.dart';
import 'screens/purchase_flow_screen.dart';
import 'screens/subscription_flow_screen.dart';
import 'screens/available_purchases_screen.dart';
import 'screens/offer_code_screen.dart';
import 'screens/builder_demo_screen.dart';
import 'screens/alternative_billing_screen.dart';

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
        '/all-products': (context) => const AllProductsScreen(),
        '/purchase-flow': (context) => const PurchaseFlowScreen(),
        '/subscription-flow': (context) => const SubscriptionFlowScreen(),
        '/available-purchases': (context) => const AvailablePurchasesScreen(),
        '/offer-code': (context) => const OfferCodeScreen(),
        '/builder-demo': (context) => const BuilderDemoScreen(),
        '/alternative-billing': (context) => const AlternativeBillingScreen(),
      },
    );
  }
}
