import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

class ProductDetailModal extends StatelessWidget {
  final ProductCommon item; // Can be Product or Subscription
  final ProductCommon? product;

  const ProductDetailModal({
    required this.item,
    this.product,
    Key? key,
  }) : super(key: key);

  static void show({
    required BuildContext context,
    required ProductCommon item, // Can be Product or Subscription
    ProductCommon? product,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProductDetailModal(
        item: item,
        product: product,
      ),
    );
  }

  Map<String, dynamic> _serializeItem(ProductCommon item) {
    if (item is Product) {
      return item.toJson();
    }
    if (item is ProductSubscription) {
      return item.toJson();
    }

    return {
      'id': item.id,
      'title': item.title,
      'description': item.description,
      'displayPrice': item.displayPrice,
      'currency': item.currency,
      'price': item.price,
    }..removeWhere((key, value) => value == null);
  }

  Widget _buildSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        content,
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use product.toJson() if available, otherwise fall back to _itemToMap
    final jsonData = product != null && product is Product
        ? (product as Product).toJson()
        : product != null && product is ProductSubscription
            ? (product as ProductSubscription).toJson()
            : _serializeItem(item);
    final jsonString = const JsonEncoder.withIndent('  ').convert(jsonData);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      item.title ?? item.id,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  // Basic Information
                  _buildSection(
                    'Basic Information',
                    Column(
                      children: [
                        _buildDetailRow('Product ID', item.id),
                        _buildDetailRow('Price', item.displayPrice),
                        _buildDetailRow('Currency', item.currency),
                        _buildDetailRow('Description', item.description),
                      ],
                    ),
                  ),

                  // Subscription Information (if applicable)
                  if (item is ProductSubscription) ...[
                    () {
                      final rows = <Widget>[];
                      if (item is ProductSubscriptionIOS) {
                        final ios = item as ProductSubscriptionIOS;
                        if (ios.subscriptionPeriodNumberIOS != null ||
                            ios.subscriptionPeriodUnitIOS != null) {
                          rows.add(
                            _buildDetailRow(
                              'Period (iOS)',
                              '${ios.subscriptionPeriodNumberIOS ?? ''} ${ios.subscriptionPeriodUnitIOS}',
                            ),
                          );
                        }
                        if (ios.introductoryPriceIOS != null) {
                          rows.add(
                            _buildDetailRow(
                              'Intro Price (iOS)',
                              ios.introductoryPriceIOS,
                            ),
                          );
                        }
                      }
                      if (rows.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return _buildSection(
                        'Subscription Details',
                        Column(children: rows),
                      );
                    }(),
                  ],

                  // Android Offers
                  if (item is ProductSubscriptionAndroid) ...[
                    () {
                      final android = item as ProductSubscriptionAndroid;
                      final offers = android.subscriptionOfferDetailsAndroid;
                      if (offers.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return _buildSection(
                        'Android Subscription Offers',
                        Column(
                          children: offers
                              .map<Widget>(
                                (offer) => Card(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildDetailRow(
                                          'Base Plan',
                                          offer.basePlanId,
                                        ),
                                        _buildDetailRow(
                                          'Offer Token',
                                          offer.offerToken.length > 20
                                              ? '${offer.offerToken.substring(0, 20)}...'
                                              : offer.offerToken,
                                        ),
                                        if (offer.offerTags.isNotEmpty)
                                          _buildDetailRow(
                                            'Tags',
                                            offer.offerTags.join(', '),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      );
                    }(),
                  ],

                  // iOS Discounts - for subscription products with offers
                  if (item is ProductSubscriptionIOS) ...[
                    () {
                      final product = item as ProductSubscriptionIOS;
                      if (product.discountsIOS?.isNotEmpty ?? false) {
                        return _buildSection(
                          'iOS Discounts',
                          Column(
                            children: product.discountsIOS!
                                .map<Widget>((discount) => Card(
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 4),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _buildDetailRow('Identifier',
                                                discount.identifier),
                                            _buildDetailRow('Price',
                                                discount.localizedPrice),
                                            _buildDetailRow(
                                                'Type', discount.type),
                                            _buildDetailRow(
                                              'Payment Mode',
                                              discount.paymentMode.toJson(),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ))
                                .toList(),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }(),
                  ],

                  // iOS Discounts - for Subscription
                  if (item is ProductSubscriptionIOS) ...[
                    () {
                      final subscription = item as ProductSubscriptionIOS;
                      if (subscription.discountsIOS?.isNotEmpty ?? false) {
                        return _buildSection(
                          'iOS Discounts',
                          Column(
                            children: subscription.discountsIOS!
                                .map<Widget>((discount) => Card(
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 4),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _buildDetailRow('Identifier',
                                                discount.identifier),
                                            _buildDetailRow('Price',
                                                discount.localizedPrice),
                                            _buildDetailRow(
                                                'Type', discount.type),
                                            _buildDetailRow(
                                              'Payment Mode',
                                              discount.paymentMode.toJson(),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ))
                                .toList(),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }(),
                  ],

                  // Raw JSON Data
                  _buildSection(
                    'Raw Data (JSON)',
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SelectableText(
                              jsonString,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              debugPrint(
                                  '=== Raw JSON Data for ${item.id} ===');
                              debugPrint(jsonString);
                              debugPrint('=== End of Raw JSON Data ===');

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Raw JSON data printed to console'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            icon: const Icon(Icons.print, size: 18),
                            label: const Text('Print to Console'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[700],
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Original Product Data (if available)
                  if (product != null)
                    _buildSection(
                      'Original Product Object',
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue[200]!),
                            ),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SelectableText(
                                product.toString(),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                debugPrint(
                                    '=== Original Product Object for ${item.id} ===');
                                debugPrint('Type: ${product.runtimeType}');
                                debugPrint(product.toString());

                                // Print additional details based on product type
                                final prod =
                                    product!; // We know it's not null in this context
                                if (prod is Product) {
                                  debugPrint(
                                      'Product Type: Product (consumable/non-consumable)');
                                  debugPrint('Platform: ${prod.platform}');
                                } else if (prod is ProductSubscription) {
                                  final subscription = prod;
                                  debugPrint('Product Type: Subscription');
                                  debugPrint(
                                      'Platform: ${subscription.platform}');
                                  if (subscription is ProductSubscriptionIOS) {
                                    debugPrint(
                                        'iOS Discounts: ${subscription.discountsIOS}');
                                  }
                                  if (subscription
                                          is ProductSubscriptionAndroid &&
                                      subscription
                                          .subscriptionOfferDetailsAndroid
                                          .isNotEmpty) {
                                    debugPrint(
                                        'Offer Details: ${subscription.subscriptionOfferDetailsAndroid}');
                                  }
                                }
                                debugPrint(
                                    '=== End of Original Product Object ===');

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Product object printed to console'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.print, size: 18),
                              label: const Text('Print to Console'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[700],
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
