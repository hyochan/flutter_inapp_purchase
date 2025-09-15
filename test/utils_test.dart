import 'package:flutter_test/flutter_test.dart';

// Ignore naming lint in test enum for explicit name value expectations
// ignore_for_file: constant_identifier_names
enum _TestEnum { Hoge }

void main() {
  group('utils', () {
    test('EnumUtil.getValueString', () async {
      String value = _TestEnum.Hoge.name;
      expect(value, 'Hoge');
    });
  });
}
