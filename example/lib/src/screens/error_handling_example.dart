import 'package:flutter/material.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

// Extension methods for PurchaseError
extension PurchaseErrorExtensions on PurchaseError {
  bool get isUserCancelled => code == ErrorCode.UserCancelled;

  bool get isNetworkRelated =>
      code == ErrorCode.NetworkError || code == ErrorCode.RemoteError;

  bool get isRecoverable =>
      code == ErrorCode.NetworkError ||
      code == ErrorCode.ServiceError ||
      code == ErrorCode.RemoteError;

  String get userFriendlyMessage {
    switch (code) {
      case ErrorCode.UserCancelled:
        return 'Purchase was cancelled';
      case ErrorCode.NetworkError:
        return 'Network connection failed. Please check your internet connection.';
      case ErrorCode.ItemUnavailable:
        return 'This item is not available for purchase';
      case ErrorCode.ServiceError:
        return 'Store service is temporarily unavailable. Please try again later.';
      case ErrorCode.AlreadyOwned:
        return 'You already own this item';
      case ErrorCode.DeveloperError:
        return 'Configuration error. Please contact support.';
      default:
        return message;
    }
  }
}

// Extension methods for ErrorCode
extension ErrorCodeExtensions on ErrorCode {
  bool get isUserCancelled => this == ErrorCode.UserCancelled;

  bool get isNetworkRelated =>
      this == ErrorCode.NetworkError || this == ErrorCode.RemoteError;

  bool get isRecoverable =>
      this == ErrorCode.NetworkError ||
      this == ErrorCode.ServiceError ||
      this == ErrorCode.RemoteError;

  String get userFriendlyMessage {
    switch (this) {
      case ErrorCode.UserCancelled:
        return 'Purchase was cancelled';
      case ErrorCode.NetworkError:
        return 'Network connection failed';
      case ErrorCode.ItemUnavailable:
        return 'Item not available';
      case ErrorCode.ServiceError:
        return 'Service temporarily unavailable';
      case ErrorCode.AlreadyOwned:
        return 'Already owned';
      case ErrorCode.DeveloperError:
        return 'Configuration error';
      default:
        return 'Unknown error';
    }
  }
}

// Global utility functions for error handling
bool isUserCancelledError(dynamic error) {
  if (error is PurchaseError) {
    return error.code == ErrorCode.UserCancelled;
  }
  return false;
}

bool isNetworkError(dynamic error) {
  if (error is PurchaseError) {
    return error.code == ErrorCode.NetworkError;
  }
  return false;
}

bool isRecoverableError(dynamic error) {
  if (error is PurchaseError) {
    // Network errors and service errors are often recoverable
    return error.code == ErrorCode.NetworkError ||
        error.code == ErrorCode.ServiceError ||
        error.code == ErrorCode.RemoteError;
  }
  return false;
}

String getUserFriendlyErrorMessage(dynamic error) {
  if (error is PurchaseError) {
    switch (error.code) {
      case ErrorCode.UserCancelled:
        return 'Purchase was cancelled';
      case ErrorCode.NetworkError:
        return 'Network connection failed. Please check your internet connection.';
      case ErrorCode.ItemUnavailable:
        return 'This item is not available for purchase';
      case ErrorCode.ServiceError:
        return 'Store service is temporarily unavailable. Please try again later.';
      case ErrorCode.AlreadyOwned:
        return 'You already own this item';
      case ErrorCode.DeveloperError:
        return 'Configuration error. Please contact support.';
      default:
        return error.message;
    }
  }
  return 'An unexpected error occurred';
}

/// Example demonstrating error handling utilities
class ErrorHandlingExample extends StatelessWidget {
  const ErrorHandlingExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error Handling Examples'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection('Error Type Detection'),
          _buildErrorTypeExamples(),
          const SizedBox(height: 20),
          _buildSection('User-Friendly Messages'),
          _buildUserFriendlyMessageExamples(),
          const SizedBox(height: 20),
          _buildSection('Extension Methods'),
          _buildExtensionMethodExamples(),
        ],
      ),
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildErrorTypeExamples() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User cancelled error
            _buildErrorExample(
              'User Cancelled Error',
              () {
                final error = PurchaseError(
                  code: ErrorCode.UserCancelled,
                  message: 'User cancelled the purchase',
                  platform: IapPlatform.IOS,
                );

                return '''
isUserCancelledError: ${isUserCancelledError(error)}
isNetworkError: ${isNetworkError(error)}
isRecoverableError: ${isRecoverableError(error)}
''';
              },
            ),
            const Divider(),

            // Network error
            _buildErrorExample(
              'Network Error',
              () {
                final error = PurchaseError(
                  code: ErrorCode.NetworkError,
                  message: 'Network connection failed',
                  platform: IapPlatform.Android,
                );

                return '''
isUserCancelledError: ${isUserCancelledError(error)}
isNetworkError: ${isNetworkError(error)}
isRecoverableError: ${isRecoverableError(error)}
''';
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserFriendlyMessageExamples() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildErrorExample(
              'Various Error Messages',
              () {
                final errors = [
                  ErrorCode.UserCancelled,
                  ErrorCode.NetworkError,
                  ErrorCode.AlreadyOwned,
                  ErrorCode.DeferredPayment,
                  ErrorCode.DeveloperError,
                ];

                return errors
                    .map((code) =>
                        '${code.toString().split('.').last}:\n  "${getUserFriendlyErrorMessage(code)}"')
                    .join('\n\n');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExtensionMethodExamples() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildErrorExample(
              'PurchaseError Extensions',
              () {
                final error = PurchaseError(
                  code: ErrorCode.NetworkError,
                  message: 'Network error occurred',
                  platform: IapPlatform.IOS,
                );

                return '''
error.isUserCancelled: ${error.isUserCancelled}
error.isNetworkRelated: ${error.isNetworkRelated}
error.isRecoverable: ${error.isRecoverable}
error.userFriendlyMessage: "${error.userFriendlyMessage}"
''';
              },
            ),
            const Divider(),
            _buildErrorExample(
              'ErrorCode Extensions',
              () {
                const code = ErrorCode.ServiceError;

                return '''
code.isUserCancelled: ${code.isUserCancelled}
code.isNetworkRelated: ${code.isNetworkRelated}
code.isRecoverable: ${code.isRecoverable}
code.userFriendlyMessage: "${code.userFriendlyMessage}"
''';
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorExample(String title, String Function() getResult) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            getResult(),
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

/// Example of using error handling in a real scenario
class PurchaseWithErrorHandling extends StatelessWidget {
  const PurchaseWithErrorHandling({Key? key}) : super(key: key);

  Future<void> _handlePurchase(BuildContext context) async {
    try {
      // Simulate a purchase that might fail
      // ... purchase logic here ...

      // For demo, we'll simulate an error
      throw PurchaseError(
        code: ErrorCode.NetworkError,
        message: 'Failed to connect to store',
        platform: IapPlatform.IOS,
      );
    } catch (error) {
      // Handle the error using our utilities
      if (isUserCancelledError(error)) {
        // User cancelled - no need to show error
        return;
      }

      String message = getUserFriendlyErrorMessage(error);

      if (isRecoverableError(error)) {
        // Show retry option
        showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Purchase Failed'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _handlePurchase(context); // Retry
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      } else {
        // Show error without retry
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase with Error Handling'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _handlePurchase(context),
          child: const Text('Make Purchase'),
        ),
      ),
    );
  }
}
