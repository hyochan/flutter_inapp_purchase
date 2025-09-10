import 'package:flutter_inapp_purchase/utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parseAndLogAndroidResponse handles valid/invalid JSON', () {
    // Valid JSON string
    parseAndLogAndroidResponse(
      '{"responseCode":0,"debugMessage":"ok"}',
      successLog: 'success',
      failureLog: 'fail',
    );

    // Invalid JSON string should not throw
    parseAndLogAndroidResponse(
      '{invalid',
      successLog: 'success',
      failureLog: 'fail',
    );

    // Null / non-string are ignored
    parseAndLogAndroidResponse(
      null,
      successLog: 'success',
      failureLog: 'fail',
    );
    parseAndLogAndroidResponse(
      42,
      successLog: 'success',
      failureLog: 'fail',
    );
  });
}

