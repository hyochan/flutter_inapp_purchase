import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:flutter_inapp_purchase/types.dart' as types;

void main() {
  test('parse subscription info ios from dynamic map', () {
    final Map<String, dynamic> raw = <String, dynamic>{
      'id': 'dev.hyo.martie.premium',
      'title': 'Premium',
      'description': 'Martie Premium',
      'currency': 'KRW',
      'displayName': 'Premium',
      'displayNameIOS': 'Premium',
      'displayPrice': '₩14,000',
      'price': 14000,
      'type': 'subs',
      'typeIOS': 'auto-renewable-subscription',
      'isFamilyShareableIOS': false,
      'jsonRepresentationIOS': '{}',
      'platform': 'ios',
      'subscriptionPeriodUnitIOS': 'month',
      'subscriptionInfoIOS': <dynamic, dynamic>{
        'subscriptionPeriod': <dynamic, dynamic>{
          'value': 1,
          'unit': 'month',
        },
        'subscriptionGroupId': '21686373',
      },
    };

    final product = parseProductFromNative(
      raw,
      'subs',
      fallbackIsIOS: true,
    );

    expect(product, isA<types.ProductSubscriptionIOS>());
    final subscription = product as types.ProductSubscriptionIOS;
    expect(subscription.subscriptionInfoIOS, isNotNull);
    expect(subscription.subscriptionInfoIOS!.subscriptionGroupId, '21686373');
    expect(
      subscription.subscriptionInfoIOS!.subscriptionPeriod.unit,
      types.SubscriptionPeriodIOS.Month,
    );
  });
}
