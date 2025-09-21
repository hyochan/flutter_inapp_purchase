import 'package:flutter_inapp_purchase/enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('androidPurchaseStateFromValue maps integers correctly', () {
    expect(androidPurchaseStateFromValue(1), AndroidPurchaseState.Purchased);
    expect(androidPurchaseStateFromValue(2), AndroidPurchaseState.Pending);
    expect(androidPurchaseStateFromValue(99), AndroidPurchaseState.Unknown);
  });

  test('AndroidPurchaseStateValue extension returns numeric value', () {
    expect(AndroidPurchaseState.Purchased.value, 1);
    expect(AndroidPurchaseState.Pending.value, 2);
    expect(AndroidPurchaseState.Unknown.value, 0);
  });

  test('AndroidReplacementModeValue returns mapped integers', () {
    expect(AndroidReplacementMode.withTimeProration.value, 1);
    expect(AndroidReplacementMode.chargeFullPrice.value, 5);
  });
}
