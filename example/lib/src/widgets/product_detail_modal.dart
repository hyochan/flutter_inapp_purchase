import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

class ProductDetailModal extends StatelessWidget {
  final IapItem item;
  final ProductCommon? product;

  const ProductDetailModal({
    required this.item,
    this.product,
    Key? key,
  }) : super(key: key);

  static void show({
    required BuildContext context,
    required IapItem item,
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

  Map<String, dynamic> _itemToMap(IapItem item) {
    final map = <String, dynamic>{
      'productId': item.productId,
      'price': item.price,
      'currency': item.currency,
      'localizedPrice': item.localizedPrice,
      'title': item.title,
      'description': item.description,
      'introductoryPrice': item.introductoryPrice,
      'subscriptionPeriodNumberIOS': item.subscriptionPeriodNumberIOS,
      'subscriptionPeriodUnitIOS': item.subscriptionPeriodUnitIOS,
      'introductoryPriceNumberOfPeriodsIOS':
          item.introductoryPriceNumberOfPeriodsIOS,
      'introductoryPriceSubscriptionPeriodIOS':
          item.introductoryPriceSubscriptionPeriodIOS,
      'discountsIOS': item.discountsIOS
          ?.map((d) => {
                'identifier': d.identifier,
                'type': d.type,
                'numberOfPeriods': d.numberOfPeriods,
                'price': d.price,
                'localizedPrice': d.localizedPrice,
                'paymentMode': d.paymentMode,
                'subscriptionPeriod': d.subscriptionPeriod,
              })
          .toList(),
      'subscriptionPeriodAndroid': item.subscriptionPeriodAndroid,
      'signatureAndroid': item.signatureAndroid,
      'iconUrl': item.iconUrl,
      'originalJson': item.originalJson,
      'originalPrice': item.originalPrice,
      'subscriptionOffersAndroid': item.subscriptionOffersAndroid
          ?.map((o) => {
                'sku': o.sku,
                'offerToken': o.offerToken,
              })
          .toList(),
    };

    // Remove null values for cleaner display
    map.removeWhere((key, value) => value == null);

    return map;
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
        : product != null && product is Subscription
            ? (product as Subscription).toJson()
            : _itemToMap(item);
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
                      item.title ?? item.productId ?? 'Product Details',
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
                        _buildDetailRow('Product ID', item.productId),
                        _buildDetailRow('Price', item.localizedPrice),
                        _buildDetailRow('Currency', item.currency),
                        if (item.originalPrice != null)
                          _buildDetailRow(
                              'Original Price', item.originalPrice.toString()),
                        _buildDetailRow('Description', item.description),
                      ],
                    ),
                  ),

                  // Subscription Information (if applicable)
                  if (item.subscriptionPeriodAndroid != null ||
                      item.subscriptionPeriodUnitIOS != null)
                    _buildSection(
                      'Subscription Details',
                      Column(
                        children: [
                          if (item.subscriptionPeriodAndroid != null)
                            _buildDetailRow('Period (Android)',
                                item.subscriptionPeriodAndroid),
                          if (item.subscriptionPeriodUnitIOS != null)
                            _buildDetailRow(
                              'Period (iOS)',
                              '${item.subscriptionPeriodNumberIOS ?? ''} ${item.subscriptionPeriodUnitIOS}',
                            ),
                          if (item.introductoryPrice != null)
                            _buildDetailRow(
                                'Introductory Price', item.introductoryPrice),
                        ],
                      ),
                    ),

                  // Android Offers
                  if (item.subscriptionOffersAndroid?.isNotEmpty ?? false)
                    _buildSection(
                      'Android Subscription Offers',
                      Column(
                        children: item.subscriptionOffersAndroid!
                            .map((offer) => Card(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildDetailRow('SKU', offer.sku),
                                        _buildDetailRow(
                                          'Token',
                                          offer.offerToken.length > 20
                                              ? '${offer.offerToken.substring(0, 20)}...'
                                              : offer.offerToken,
                                        ),
                                      ],
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ),

                  // iOS Discounts
                  if (item.discountsIOS?.isNotEmpty ?? false)
                    _buildSection(
                      'iOS Discounts',
                      Column(
                        children: item.discountsIOS!
                            .map((discount) => Card(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildDetailRow(
                                            'Identifier', discount.identifier),
                                        _buildDetailRow(
                                            'Price', discount.localizedPrice),
                                        _buildDetailRow('Type', discount.type),
                                        _buildDetailRow('Payment Mode',
                                            discount.paymentMode),
                                      ],
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ),

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
                                  '=== Raw JSON Data for ${item.productId} ===');
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
                                    '=== Original Product Object for ${item.productId} ===');
                                debugPrint('Type: ${product.runtimeType}');
                                debugPrint(product.toString());

                                // Print additional details based on product type
                                final prod =
                                    product!; // We know it's not null in this context
                                if (prod is Product) {
                                  final product = prod;
                                  debugPrint(
                                      'Product Type: Product (consumable/non-consumable)');
                                  debugPrint('Platform: ${product.platform}');
                                  if (product.discountsIOS != null) {
                                    debugPrint(
                                        'iOS Discounts: ${product.discountsIOS}');
                                  }
                                } else if (prod is Subscription) {
                                  final subscription = prod;
                                  debugPrint('Product Type: Subscription');
                                  debugPrint(
                                      'Platform: ${subscription.platform}');
                                  if (subscription.subscription != null) {
                                    debugPrint(
                                        'Subscription Info: ${subscription.subscription}');
                                  }
                                  if (subscription.subscriptionOfferDetails !=
                                      null) {
                                    debugPrint(
                                        'Offer Details: ${subscription.subscriptionOfferDetails}');
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
