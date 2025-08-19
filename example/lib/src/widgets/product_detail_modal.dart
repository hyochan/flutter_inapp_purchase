import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

class ProductDetailModal extends StatelessWidget {
  final IAPItem item;
  final BaseProduct? product;

  const ProductDetailModal({
    Key? key,
    required this.item,
    this.product,
  }) : super(key: key);

  static void show({
    required BuildContext context,
    required IAPItem item,
    BaseProduct? product,
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

  Map<String, dynamic> _itemToMap(IAPItem item) {
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
    final jsonString =
        const JsonEncoder.withIndent('  ').convert(_itemToMap(item));

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
                  ),

                  // Original Product Data (if available)
                  if (product != null)
                    _buildSection(
                      'Original Product Object',
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Text(
                          product.toString(),
                          style: const TextStyle(fontSize: 12),
                        ),
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
