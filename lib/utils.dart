import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Parse Android JSON response and log the result
void parseAndLogAndroidResponse(
  dynamic result, {
  required String successLog,
  required String failureLog,
}) {
  if (result == null || result is! String) {
    return;
  }

  try {
    final response = jsonDecode(result) as Map<String, dynamic>;
    if (kDebugMode) {
      debugPrint('$successLog. Response code: ${response['responseCode']}');
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('$failureLog: $e');
    }
  }
}
