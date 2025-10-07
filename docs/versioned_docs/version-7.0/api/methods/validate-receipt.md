---
sidebar_position: 8
title: validateReceipt
---

# validateReceipt()

Validates purchase receipts with platform verification services.

## Overview

Receipt validation is crucial for verifying the authenticity of purchases. This plugin provides methods to validate receipts with Apple's and Google's verification services, though server-side validation is recommended for production apps.

## Methods

### iOS Receipt Validation

```dart
Future<http.Response> validateReceiptIos({
  required Map<String, String> receiptBody,
  bool isTest = true,
})
```

### Android Receipt Validation

```dart
Future<http.Response> validateReceiptAndroid({
  required String packageName,
  required String productId,
  required String productToken,
  required String accessToken,
  bool isSubscription = false,
})
```

## iOS Receipt Validation

### Basic Usage

```dart
import 'dart:convert';

Future<bool> validateIosReceipt(String receiptData) async {
  try {
    final response = await FlutterInappPurchase.instance.validateReceiptIos(
      receiptBody: {
        'receipt-data': receiptData,
        'password': 'your-app-shared-secret', // For subscriptions
      },
      isTest: true, // Use sandbox for testing
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final status = data['status'];
      
      switch (status) {
        case 0:
          print('Receipt is valid');
          return true;
        case 21007:
          // Receipt is from sandbox, retry with sandbox URL
          return validateIosReceipt(receiptData);
        case 21008:
          // Receipt is from production, retry with production URL
          return validateIosReceipt(receiptData);
        default:
          print('Invalid receipt: Status $status');
          return false;
      }
    }
    
    return false;
  } catch (e) {
    print('Receipt validation error: $e');
    return false;
  }
}
```

### Complete iOS Implementation

```dart
class IosReceiptValidator {
  final String sharedSecret;
  
  IosReceiptValidator({required this.sharedSecret});
  
  Future<ReceiptValidationResult> validate(Purchase purchase) async {
    if (purchase.transactionReceipt == null) {
      return ReceiptValidationResult(
        isValid: false,
        error: 'No receipt data',
      );
    }
    
    try {
      // Try production first
      var response = await _validateWithUrl(
        purchase.transactionReceipt!,
        isProduction: true,
      );
      
      var result = _parseResponse(response);
      
      // If sandbox receipt, retry with sandbox
      if (result.status == 21007) {
        response = await _validateWithUrl(
          purchase.transactionReceipt!,
          isProduction: false,
        );
        result = _parseResponse(response);
      }
      
      return result;
      
    } catch (e) {
      return ReceiptValidationResult(
        isValid: false,
        error: e.toString(),
      );
    }
  }
  
  Future<http.Response> _validateWithUrl(
    String receiptData,
    {required bool isProduction}
  ) async {
    return await FlutterInappPurchase.instance.validateReceiptIos(
      receiptBody: {
        'receipt-data': receiptData,
        'password': sharedSecret,
        'exclude-old-transactions': 'true',
      },
      isTest: !isProduction,
    );
  }
  
  ReceiptValidationResult _parseResponse(http.Response response) {
    if (response.statusCode != 200) {
      return ReceiptValidationResult(
        isValid: false,
        error: 'HTTP ${response.statusCode}',
      );
    }
    
    final data = json.decode(response.body);
    final status = data['status'] as int;
    
    if (status == 0) {
      // Extract purchase info
      final receipt = data['receipt'];
      final latestInfo = data['latest_receipt_info'];
      
      return ReceiptValidationResult(
        isValid: true,
        status: status,
        receipt: receipt,
        latestPurchases: latestInfo,
      );
    }
    
    return ReceiptValidationResult(
      isValid: false,
      status: status,
      error: _getErrorMessage(status),
    );
  }
  
  String _getErrorMessage(int status) {
    switch (status) {
      case 21000: return 'App Store could not read the receipt';
      case 21002: return 'Receipt data was malformed';
      case 21003: return 'Receipt could not be authenticated';
      case 21004: return 'Shared secret does not match';
      case 21005: return 'Receipt server is unavailable';
      case 21006: return 'Receipt is valid but subscription expired';
      case 21007: return 'Receipt is from sandbox environment';
      case 21008: return 'Receipt is from production environment';
      default: return 'Unknown error: $status';
    }
  }
}
```

## Android Receipt Validation

### Basic Usage

```dart
Future<bool> validateAndroidReceipt(Purchase purchase) async {
  try {
    // Get access token (implement OAuth 2.0 flow)
    final accessToken = await _getGoogleAccessToken();
    
    final response = await FlutterInappPurchase.instance.validateReceiptAndroid(
      packageName: 'com.example.app',
      productId: purchase.productId!,
      productToken: purchase.purchaseToken!,
      accessToken: accessToken,
      isSubscription: _isSubscription(purchase.productId),
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      // Check purchase state
      final purchaseState = data['purchaseState'];
      if (purchaseState == 0) { // Purchased
        print('Purchase is valid');
        return true;
      }
    }
    
    return false;
  } catch (e) {
    print('Android receipt validation error: $e');
    return false;
  }
}
```

### Complete Android Implementation

```dart
class AndroidReceiptValidator {
  final String packageName;
  final GoogleAuthService authService;
  
  AndroidReceiptValidator({
    required this.packageName,
    required this.authService,
  });
  
  Future<ReceiptValidationResult> validate(Purchase purchase) async {
    if (purchase.purchaseToken == null) {
      return ReceiptValidationResult(
        isValid: false,
        error: 'No purchase token',
      );
    }
    
    try {
      // Get fresh access token
      final accessToken = await authService.getAccessToken();
      
      final response = await FlutterInappPurchase.instance.validateReceiptAndroid(
        packageName: packageName,
        productId: purchase.productId!,
        productToken: purchase.purchaseToken!,
        accessToken: accessToken,
        isSubscription: _isSubscription(purchase.productId),
      );
      
      return _parseResponse(response, purchase);
      
    } catch (e) {
      return ReceiptValidationResult(
        isValid: false,
        error: e.toString(),
      );
    }
  }
  
  ReceiptValidationResult _parseResponse(
    http.Response response,
    Purchase purchase,
  ) {
    if (response.statusCode == 404) {
      return ReceiptValidationResult(
        isValid: false,
        error: 'Purchase not found',
      );
    }
    
    if (response.statusCode == 401) {
      return ReceiptValidationResult(
        isValid: false,
        error: 'Authentication failed',
      );
    }
    
    if (response.statusCode != 200) {
      return ReceiptValidationResult(
        isValid: false,
        error: 'HTTP ${response.statusCode}',
      );
    }
    
    final data = json.decode(response.body);
    
    // For products
    if (!_isSubscription(purchase.productId)) {
      final purchaseState = data['purchaseState'];
      final consumptionState = data['consumptionState'];
      
      return ReceiptValidationResult(
        isValid: purchaseState == 0,
        purchaseState: purchaseState,
        isConsumed: consumptionState == 1,
        originalData: data,
      );
    }
    
    // For subscriptions
    final expiryTime = data['expiryTimeMillis'];
    final isExpired = expiryTime != null && 
      DateTime.fromMillisecondsSinceEpoch(int.parse(expiryTime))
          .isBefore(DateTime.now());
    
    return ReceiptValidationResult(
      isValid: !isExpired,
      expiryDate: expiryTime != null 
          ? DateTime.fromMillisecondsSinceEpoch(int.parse(expiryTime))
          : null,
      originalData: data,
    );
  }
  
  bool _isSubscription(String? productId) {
    // Implement your logic to determine if product is subscription
    return productId?.contains('subscription') ?? false;
  }
}
```

## Server-Side Validation (Recommended)

```dart
class ServerReceiptValidator {
  final String serverUrl;
  final http.Client httpClient;
  
  ServerReceiptValidator({
    required this.serverUrl,
    required this.httpClient,
  });
  
  Future<bool> validate(Purchase purchase) async {
    try {
      final payload = {
        'platform': Platform.isIOS ? 'ios' : 'android',
        'productId': purchase.productId,
        'transactionId': purchase.transactionId,
        'receipt': Platform.isIOS 
            ? purchase.transactionReceipt 
            : purchase.dataAndroid,
        'signature': Platform.isAndroid ? purchase.signatureAndroid : null,
        'purchaseToken': Platform.isAndroid ? purchase.purchaseToken : null,
      };
      
      final response = await httpClient.post(
        Uri.parse('$serverUrl/validate-receipt'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getAuthToken()}',
        },
        body: json.encode(payload),
      );
      
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        return result['valid'] == true;
      }
      
      return false;
      
    } catch (e) {
      print('Server validation error: $e');
      return false;
    }
  }
}
```

## Receipt Validation Flow

```dart
class PurchaseValidator {
  final ServerReceiptValidator serverValidator;
  final IosReceiptValidator iosValidator;
  final AndroidReceiptValidator androidValidator;
  
  Future<void> validatePurchase(Purchase purchase) async {
    try {
      // Always prefer server-side validation
      if (await serverValidator.validate(purchase)) {
        print('Server validation successful');
        await _completePurchase(purchase);
        return;
      }
      
      // Fallback to client-side validation
      print('Server validation failed, trying client-side');
      
      ReceiptValidationResult result;
      if (Platform.isIOS) {
        result = await iosValidator.validate(purchase);
      } else {
        result = await androidValidator.validate(purchase);
      }
      
      if (result.isValid) {
        await _completePurchase(purchase);
      } else {
        print('Validation failed: ${result.error}');
        // Don't complete invalid purchases
      }
      
    } catch (e) {
      print('Validation error: $e');
      // Keep purchase pending for retry
    }
  }
  
  Future<void> _completePurchase(Purchase purchase) async {
    // Deliver content
    await _deliverContent(purchase.productId!);
    
    // Finish transaction
    await FlutterInappPurchase.instance.finishTransactionIOS(
      purchase,
      isConsumable: _isConsumable(purchase.productId),
    );
  }
}
```

## Best Practices

1. **Always Use Server Validation**: Client-side validation can be bypassed
2. **Validate Before Delivery**: Never deliver content before validation
3. **Handle Network Errors**: Implement retry logic for validation failures
4. **Cache Valid Receipts**: Avoid repeated validation of same receipt
5. **Check Expiration**: For subscriptions, verify they're still active
6. **Secure Credentials**: Never hardcode shared secrets or access tokens

## Security Considerations

1. **Shared Secret**: Store iOS shared secret securely on server
2. **Access Tokens**: Use OAuth 2.0 service account for Android
3. **HTTPS Only**: Always use secure connections
4. **Receipt Storage**: Store receipts for audit trail
5. **Fraud Detection**: Implement additional fraud checks server-side

## Related Methods

- [`getAvailablePurchases()`](./get-available-purchases.md) - Get purchases to validate
- [`finishTransaction()`](./finish-transaction.md) - Complete validated purchases
- `getPurchaseHistory()` - Get historical receipts (Android only)
