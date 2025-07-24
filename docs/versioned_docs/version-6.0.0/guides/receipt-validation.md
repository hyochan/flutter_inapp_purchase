---
sidebar_position: 4
title: Receipt Validation
---

# Receipt Validation Guide

Comprehensive guide to validating purchase receipts for security and fraud prevention.

## Overview

Receipt validation is crucial for verifying the authenticity of purchases and preventing fraud. This guide covers both client-side and server-side validation approaches for iOS and Android platforms.

## Why Validate Receipts?

1. **Security**: Prevent fraudulent purchases and hacked clients
2. **Accuracy**: Ensure purchase data integrity
3. **Compliance**: Meet platform requirements for purchase verification
4. **Analytics**: Track legitimate purchases for business metrics
5. **Support**: Resolve customer purchase issues

## Validation Approaches

### Client-Side Validation
- Quick verification for immediate feedback
- Can be bypassed by malicious users
- Suitable for non-critical features
- Should be combined with server-side validation

### Server-Side Validation (Recommended)
- Secure and tamper-proof
- Required for premium features
- Enables purchase analytics and support
- Protects against client-side manipulation

## iOS Receipt Validation

### Basic Client-Side Validation

```dart
class IOSReceiptValidator {
  final String sharedSecret;
  
  IOSReceiptValidator({required this.sharedSecret});
  
  Future<ReceiptValidationResult> validateReceipt(String receiptData) async {
    try {
      // Try production first
      var result = await _validateWithApple(receiptData, isProduction: true);
      
      // If sandbox receipt, retry with sandbox
      if (result.status == 21007) {
        result = await _validateWithApple(receiptData, isProduction: false);
      }
      
      return result;
      
    } catch (e) {
      return ReceiptValidationResult(
        isValid: false,
        error: e.toString(),
      );
    }
  }
  
  Future<ReceiptValidationResult> _validateWithApple(
    String receiptData, {
    required bool isProduction,
  }) async {
    final response = await FlutterInappPurchase.instance.validateReceiptIos(
      receiptBody: {
        'receipt-data': receiptData,
        'password': sharedSecret,
        'exclude-old-transactions': 'true',
      },
      isTest: !isProduction,
    );
    
    return _parseAppleResponse(response);
  }
  
  ReceiptValidationResult _parseAppleResponse(http.Response response) {
    if (response.statusCode != 200) {
      return ReceiptValidationResult(
        isValid: false,
        error: 'HTTP ${response.statusCode}',
      );
    }
    
    final data = json.decode(response.body);
    final status = data['status'] as int;
    
    return ReceiptValidationResult(
      isValid: status == 0,
      status: status,
      receipt: data['receipt'],
      latestReceiptInfo: data['latest_receipt_info'],
      pendingRenewalInfo: data['pending_renewal_info'],
      error: status != 0 ? _getAppleErrorMessage(status) : null,
    );
  }
  
  String _getAppleErrorMessage(int status) {
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

### Advanced iOS Validation

```dart
class AdvancedIOSValidator {
  Future<ValidationResult> validatePurchase(PurchasedItem purchase) async {
    if (purchase.transactionReceipt == null) {
      return ValidationResult(isValid: false, error: 'No receipt data');
    }
    
    try {
      final validator = IOSReceiptValidator(
        sharedSecret: await _getSharedSecret(),
      );
      
      final result = await validator.validateReceipt(
        purchase.transactionReceipt!,
      );
      
      if (!result.isValid) {
        return ValidationResult(
          isValid: false,
          error: result.error,
        );
      }
      
      // Verify specific transaction
      final transactionInfo = _findTransaction(
        result.latestReceiptInfo,
        purchase.transactionId,
      );
      
      if (transactionInfo == null) {
        return ValidationResult(
          isValid: false,
          error: 'Transaction not found in receipt',
        );
      }
      
      // Additional validations
      if (!_validateBundleId(result.receipt)) {
        return ValidationResult(
          isValid: false,
          error: 'Bundle ID mismatch',
        );
      }
      
      if (!_validateEnvironment(result.receipt)) {
        return ValidationResult(
          isValid: false,
          error: 'Environment mismatch',
        );
      }
      
      return ValidationResult(
        isValid: true,
        transactionInfo: transactionInfo,
        receiptInfo: result.receipt,
      );
      
    } catch (e) {
      return ValidationResult(
        isValid: false,
        error: e.toString(),
      );
    }
  }
  
  Map<String, dynamic>? _findTransaction(
    List<dynamic>? receiptInfo,
    String? transactionId,
  ) {
    if (receiptInfo == null || transactionId == null) return null;
    
    return receiptInfo
        .cast<Map<String, dynamic>>()
        .firstWhere(
          (transaction) => transaction['transaction_id'] == transactionId,
          orElse: () => null,
        );
  }
  
  bool _validateBundleId(Map<String, dynamic> receipt) {
    final bundleId = receipt['bundle_id'] as String?;
    return bundleId == await _getExpectedBundleId();
  }
  
  bool _validateEnvironment(Map<String, dynamic> receipt) {
    final environment = receipt['environment'] as String?;
    return environment == (kDebugMode ? 'Sandbox' : 'Production');
  }
}
```

## Android Receipt Validation

### Basic Client-Side Validation

```dart
class AndroidReceiptValidator {
  final String packageName;
  final GoogleAuthService authService;
  
  AndroidReceiptValidator({
    required this.packageName,
    required this.authService,
  });
  
  Future<ReceiptValidationResult> validateReceipt(PurchasedItem purchase) async {
    if (purchase.purchaseToken == null) {
      return ReceiptValidationResult(
        isValid: false,
        error: 'No purchase token',
      );
    }
    
    try {
      final accessToken = await authService.getAccessToken();
      
      final response = await FlutterInappPurchase.instance.validateReceiptAndroid(
        packageName: packageName,
        productId: purchase.productId!,
        productToken: purchase.purchaseToken!,
        accessToken: accessToken,
        isSubscription: _isSubscription(purchase.productId),
      );
      
      return _parseGoogleResponse(response, purchase);
      
    } catch (e) {
      return ReceiptValidationResult(
        isValid: false,
        error: e.toString(),
      );
    }
  }
  
  ReceiptValidationResult _parseGoogleResponse(
    http.Response response,
    PurchasedItem purchase,
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
    
    if (_isSubscription(purchase.productId)) {
      return _validateSubscriptionResponse(data);
    } else {
      return _validateProductResponse(data);
    }
  }
  
  ReceiptValidationResult _validateProductResponse(Map<String, dynamic> data) {
    final purchaseState = data['purchaseState'] as int?;
    final consumptionState = data['consumptionState'] as int?;
    
    return ReceiptValidationResult(
      isValid: purchaseState == 0, // Purchased
      purchaseState: purchaseState,
      isConsumed: consumptionState == 1,
      originalData: data,
    );
  }
  
  ReceiptValidationResult _validateSubscriptionResponse(
    Map<String, dynamic> data,
  ) {
    final expiryTimeMillis = data['expiryTimeMillis'] as String?;
    final autoRenewing = data['autoRenewing'] as bool?;
    
    DateTime? expiryDate;
    if (expiryTimeMillis != null) {
      expiryDate = DateTime.fromMillisecondsSinceEpoch(
        int.parse(expiryTimeMillis),
      );
    }
    
    final isExpired = expiryDate?.isBefore(DateTime.now()) ?? true;
    
    return ReceiptValidationResult(
      isValid: !isExpired,
      expiryDate: expiryDate,
      autoRenewing: autoRenewing,
      originalData: data,
    );
  }
  
  bool _isSubscription(String? productId) {
    // Implement your logic to determine if product is subscription
    return productId?.contains('subscription') ?? false;
  }
}
```

### Advanced Android Validation

```dart
class AdvancedAndroidValidator {
  Future<ValidationResult> validatePurchaseWithSignature(
    PurchasedItem purchase,
  ) async {
    // First validate signature locally for quick check
    if (!_validateSignature(purchase)) {
      return ValidationResult(
        isValid: false,
        error: 'Invalid signature',
      );
    }
    
    // Then validate with Google Play API
    final validator = AndroidReceiptValidator(
      packageName: await _getPackageName(),
      authService: GoogleAuthService(),
    );
    
    final result = await validator.validateReceipt(purchase);
    
    if (!result.isValid) {
      return ValidationResult(
        isValid: false,
        error: result.error,
      );
    }
    
    // Additional security checks
    if (!_validatePurchaseTime(purchase, result.originalData)) {
      return ValidationResult(
        isValid: false,
        error: 'Purchase time validation failed',
      );
    }
    
    return ValidationResult(
      isValid: true,
      receiptData: result.originalData,
    );
  }
  
  bool _validateSignature(PurchasedItem purchase) {
    if (purchase.dataAndroid == null || 
        purchase.signatureAndroid == null) {
      return false;
    }
    
    try {
      // Implement signature validation using Google Play's public key
      return SignatureValidator.verify(
        data: purchase.dataAndroid!,
        signature: purchase.signatureAndroid!,
        publicKey: await _getGooglePlayPublicKey(),
      );
    } catch (e) {
      print('Signature validation error: $e');
      return false;
    }
  }
  
  bool _validatePurchaseTime(
    PurchasedItem purchase,
    Map<String, dynamic>? receiptData,
  ) {
    if (receiptData == null) return true;
    
    final purchaseTimeMillis = receiptData['purchaseTimeMillis'] as String?;
    if (purchaseTimeMillis == null) return true;
    
    final receiptTime = DateTime.fromMillisecondsSinceEpoch(
      int.parse(purchaseTimeMillis),
    );
    
    final localTime = purchase.transactionDate;
    if (localTime == null) return true;
    
    // Allow some variance for clock differences
    final timeDifference = receiptTime.difference(localTime).inMinutes.abs();
    return timeDifference <= 5; // 5 minutes tolerance
  }
}
```

## Server-Side Validation (Recommended)

### Server Validation Service

```dart
class ServerValidationService {
  final String baseUrl;
  final http.Client httpClient;
  
  ServerValidationService({
    required this.baseUrl,
    required this.httpClient,
  });
  
  Future<ServerValidationResult> validatePurchase(
    PurchasedItem purchase,
  ) async {
    try {
      final payload = _buildValidationPayload(purchase);
      
      final response = await httpClient.post(
        Uri.parse('$baseUrl/validate-purchase'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getAuthToken()}',
        },
        body: json.encode(payload),
      );
      
      return _parseServerResponse(response);
      
    } catch (e) {
      return ServerValidationResult(
        isValid: false,
        error: e.toString(),
      );
    }
  }
  
  Map<String, dynamic> _buildValidationPayload(PurchasedItem purchase) {
    return {
      'platform': Platform.isIOS ? 'ios' : 'android',
      'productId': purchase.productId,
      'transactionId': purchase.transactionId,
      'purchaseTime': purchase.transactionDate?.millisecondsSinceEpoch,
      
      // iOS specific
      if (Platform.isIOS) ...{
        'receipt': purchase.transactionReceipt,
        'originalTransactionId': purchase.originalTransactionIdentifierIOS,
      },
      
      // Android specific
      if (Platform.isAndroid) ...{
        'purchaseToken': purchase.purchaseToken,
        'purchaseData': purchase.dataAndroid,
        'signature': purchase.signatureAndroid,
        'packageName': await _getPackageName(),
      },
      
      // User identification
      'userId': await _getUserId(),
      'deviceId': await _getDeviceId(),
    };
  }
  
  ServerValidationResult _parseServerResponse(http.Response response) {
    if (response.statusCode != 200) {
      return ServerValidationResult(
        isValid: false,
        error: 'Server error: ${response.statusCode}',
      );
    }
    
    final data = json.decode(response.body);
    
    return ServerValidationResult(
      isValid: data['valid'] == true,
      transactionId: data['transactionId'],
      productId: data['productId'],
      purchaseDate: data['purchaseDate'] != null
          ? DateTime.parse(data['purchaseDate'])
          : null,
      expiryDate: data['expiryDate'] != null
          ? DateTime.parse(data['expiryDate'])
          : null,
      isSubscription: data['isSubscription'] == true,
      originalJson: data['originalReceipt'],
      error: data['error'],
    );
  }
}
```

## Complete Validation Flow

### Unified Validation Manager

```dart
class PurchaseValidationManager {
  final ServerValidationService serverValidator;
  final IOSReceiptValidator iosValidator;
  final AndroidReceiptValidator androidValidator;
  
  PurchaseValidationManager({
    required this.serverValidator,
    required this.iosValidator,
    required this.androidValidator,
  });
  
  Future<bool> validatePurchase(PurchasedItem purchase) async {
    try {
      // Always try server validation first
      final serverResult = await serverValidator.validatePurchase(purchase);
      
      if (serverResult.isValid) {
        print('Server validation successful');
        return true;
      }
      
      print('Server validation failed: ${serverResult.error}');
      
      // Fallback to client-side validation
      return await _fallbackValidation(purchase);
      
    } catch (e) {
      print('Validation error: $e');
      
      // If server is unreachable, use client-side validation
      return await _fallbackValidation(purchase);
    }
  }
  
  Future<bool> _fallbackValidation(PurchasedItem purchase) async {
    print('Using client-side validation as fallback');
    
    try {
      if (Platform.isIOS) {
        final result = await iosValidator.validateReceipt(
          purchase.transactionReceipt ?? '',
        );
        return result.isValid;
      } else {
        final result = await androidValidator.validateReceipt(purchase);
        return result.isValid;
      }
    } catch (e) {
      print('Client-side validation failed: $e');
      return false;
    }
  }
}
```

### Integration with Purchase Flow

```dart
class ValidatedPurchaseHandler {
  final PurchaseValidationManager validator;
  
  ValidatedPurchaseHandler({required this.validator});
  
  Future<void> handlePurchase(PurchasedItem purchase) async {
    try {
      // Show validation in progress
      _showValidationUI();
      
      // Validate the purchase
      final isValid = await validator.validatePurchase(purchase);
      
      if (isValid) {
        // Deliver content
        await _deliverContent(purchase);
        
        // Finish transaction
        await _finishTransaction(purchase);
        
        // Update UI
        _showSuccessUI(purchase);
        
        // Track success
        _trackValidationSuccess(purchase);
        
      } else {
        // Handle invalid purchase
        await _handleInvalidPurchase(purchase);
      }
      
    } catch (e) {
      await _handleValidationError(purchase, e);
    } finally {
      _hideValidationUI();
    }
  }
  
  Future<void> _handleInvalidPurchase(PurchasedItem purchase) async {
    print('Invalid purchase detected: ${purchase.productId}');
    
    // Don't deliver content
    // Don't finish transaction (keep it pending)
    
    // Log for investigation
    _logInvalidPurchase(purchase);
    
    // Show error to user
    _showInvalidPurchaseUI();
  }
  
  Future<void> _handleValidationError(PurchasedItem purchase, dynamic error) async {
    print('Validation error: $error');
    
    // Decide whether to deliver content based on error type
    final shouldDeliver = _shouldDeliverOnValidationError(error);
    
    if (shouldDeliver) {
      // Deliver content but log the issue
      await _deliverContent(purchase);
      await _finishTransaction(purchase);
      _logValidationError(purchase, error);
    } else {
      // Keep transaction pending for manual review
      _logValidationFailure(purchase, error);
    }
  }
  
  bool _shouldDeliverOnValidationError(dynamic error) {
    // Conservative approach: only deliver on network errors
    return error.toString().contains('network') ||
           error.toString().contains('timeout');
  }
}
```

## Receipt Storage and Caching

### Receipt Cache Manager

```dart
class ReceiptCacheManager {
  static const String _cacheKey = 'validated_receipts';
  final SharedPreferences prefs;
  
  ReceiptCacheManager({required this.prefs});
  
  Future<void> cacheValidatedReceipt(
    String transactionId,
    Map<String, dynamic> receiptData,
  ) async {
    final cached = await _getCachedReceipts();
    cached[transactionId] = {
      'receiptData': receiptData,
      'validatedAt': DateTime.now().millisecondsSinceEpoch,
    };
    
    await prefs.setString(_cacheKey, json.encode(cached));
  }
  
  Future<Map<String, dynamic>?> getCachedReceipt(String transactionId) async {
    final cached = await _getCachedReceipts();
    final receipt = cached[transactionId];
    
    if (receipt == null) return null;
    
    // Check if cache is still valid (24 hours)
    final validatedAt = receipt['validatedAt'] as int;
    final age = DateTime.now().millisecondsSinceEpoch - validatedAt;
    
    if (age > Duration(hours: 24).inMilliseconds) {
      // Cache expired
      cached.remove(transactionId);
      await prefs.setString(_cacheKey, json.encode(cached));
      return null;
    }
    
    return receipt['receiptData'];
  }
  
  Future<Map<String, dynamic>> _getCachedReceipts() async {
    final cachedString = prefs.getString(_cacheKey);
    if (cachedString == null) return {};
    
    try {
      return json.decode(cachedString).cast<String, dynamic>();
    } catch (e) {
      return {};
    }
  }
  
  Future<void> clearCache() async {
    await prefs.remove(_cacheKey);
  }
}
```

## Testing Receipt Validation

### Test Receipt Generator

```dart
class TestReceiptGenerator {
  static Map<String, dynamic> generateTestIOSReceipt({
    required String productId,
    required String transactionId,
    bool isValid = true,
  }) {
    return {
      'receipt': {
        'bundle_id': 'com.example.test',
        'application_version': '1.0',
        'environment': 'Sandbox',
        'in_app': [
          {
            'product_id': productId,
            'transaction_id': transactionId,
            'purchase_date_ms': DateTime.now().millisecondsSinceEpoch.toString(),
            'quantity': '1',
          }
        ],
      },
      'status': isValid ? 0 : 21002,
    };
  }
  
  static Map<String, dynamic> generateTestAndroidReceipt({
    required String productId,
    bool isValid = true,
  }) {
    return {
      'purchaseState': isValid ? 0 : 1,
      'consumptionState': 0,
      'developerPayload': '',
      'orderId': 'test_order_${DateTime.now().millisecondsSinceEpoch}',
      'purchaseTimeMillis': DateTime.now().millisecondsSinceEpoch.toString(),
      'purchaseToken': 'test_token_${DateTime.now().millisecondsSinceEpoch}',
    };
  }
}
```

### Validation Testing

```dart
class ValidationTesting {
  static Future<void> testValidationFlow() async {
    final validator = PurchaseValidationManager(
      serverValidator: MockServerValidator(),
      iosValidator: MockIOSValidator(),
      androidValidator: MockAndroidValidator(),
    );
    
    // Test valid purchase
    final validPurchase = _createTestPurchase(isValid: true);
    final result1 = await validator.validatePurchase(validPurchase);
    assert(result1 == true, 'Valid purchase should pass validation');
    
    // Test invalid purchase
    final invalidPurchase = _createTestPurchase(isValid: false);
    final result2 = await validator.validatePurchase(invalidPurchase);
    assert(result2 == false, 'Invalid purchase should fail validation');
    
    print('All validation tests passed');
  }
  
  static PurchasedItem _createTestPurchase({required bool isValid}) {
    return PurchasedItem.fromJSON({
      'productId': 'test_product',
      'transactionId': 'test_transaction',
      'transactionReceipt': isValid ? 'valid_receipt' : 'invalid_receipt',
      'purchaseToken': isValid ? 'valid_token' : 'invalid_token',
    });
  }
}
```

## Best Practices

1. **Always Use Server Validation**: Client-side validation can be bypassed
2. **Validate Before Content Delivery**: Never deliver without validation
3. **Handle Network Failures**: Implement retry logic and offline handling
4. **Cache Valid Receipts**: Avoid repeated validation of same receipt
5. **Log Validation Results**: Track validation patterns for debugging
6. **Secure Credentials**: Never hardcode secrets in client code
7. **Test Edge Cases**: Test with expired, refunded, and tampered receipts
8. **Monitor Validation Rates**: Track validation success/failure rates

## Security Considerations

1. **Shared Secrets**: Store iOS shared secrets securely on server only
2. **Access Tokens**: Use proper OAuth 2.0 flow for Google Play API
3. **Receipt Storage**: Store receipts securely for audit trail
4. **Fraud Detection**: Implement additional fraud checks
5. **Rate Limiting**: Prevent validation API abuse
6. **Environment Validation**: Ensure receipts match expected environment

## Related Documentation

- [Purchases Guide](./purchases.md) - Purchase implementation
- [Error Handling](./error-handling.md) - Handling validation errors
- [API Reference](../api/methods/validate-receipt.md) - Validation API methods