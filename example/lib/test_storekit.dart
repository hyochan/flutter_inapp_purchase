import 'package:flutter/material.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

void main() {
  runApp(TestApp());
}

class TestApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: TestScreen(),
    );
  }
}

class TestScreen extends StatefulWidget {
  @override
  _TestScreenState createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  String _status = 'Not started';

  void _testStoreKit() async {
    setState(() => _status = 'Testing StoreKit...');
    
    try {
      // First run our diagnostic test
      setState(() => _status = 'Running StoreKit diagnostics...');
      final diagnostics = await FlutterInappPurchase.channel.invokeMethod('testStoreKit');
      setState(() => _status = 'Diagnostics: $diagnostics');
      
      // Wait a bit before continuing
      await Future<void>.delayed(const Duration(seconds: 2));
      
      // Test 1: Initialize connection (this will check can make payments internally)
      setState(() => _status = 'Testing if can make payments...');
      final canMake = await FlutterInappPurchase.channel.invokeMethod('canMakePayments');
      setState(() => _status = 'Can make payments: $canMake');
      
      if (canMake != true) {
        setState(() => _status = 'Cannot make payments on this device');
        return;
      }
      
      // Test 2: Initialize connection
      setState(() => _status = 'Initializing connection...');
      await FlutterInappPurchase.instance.initConnection();
      setState(() => _status = 'Connection initialized');
      
      // Test 3: Get simple product
      setState(() => _status = 'Getting products...');
      final products = await FlutterInappPurchase.instance.getProducts(['dev.hyo.martie.10bulbs']);
      setState(() => _status = 'Got ${products.length} products');
      
      if (products.isNotEmpty) {
        final product = products.first;
        setState(() => _status = 'Product: ${product.productId} - ${product.localizedPrice}');
      }
      
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('StoreKit 2 Test')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _status,
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _testStoreKit,
              child: Text('Test StoreKit'),
            ),
          ],
        ),
      ),
    );
  }
}