import 'package:flutter/material.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:flutter_inapp_purchase/extensions/purchase_helpers.dart';

class PurchaseDisplayField {
  const PurchaseDisplayField({required this.label, required this.value});

  final String label;
  final String value;
}

class PurchaseDisplaySection {
  const PurchaseDisplaySection({required this.title, required this.fields});

  final String title;
  final List<PurchaseDisplayField> fields;
}

extension PurchaseDisplayMapping on Purchase {
  List<PurchaseDisplaySection> toDisplaySections() {
    final sections = <PurchaseDisplaySection>[];

    final commonFields = <PurchaseDisplayField>[
      PurchaseDisplayField(label: 'id', value: id.isEmpty ? 'null' : id),
      PurchaseDisplayField(
          label: 'productId', value: productId.isEmpty ? 'null' : productId),
      PurchaseDisplayField(label: 'ids', value: _formatList(ids)),
      PurchaseDisplayField(
        label: 'transactionDate',
        value: _formatTimestamp(transactionDate),
      ),
      PurchaseDisplayField(
        label: 'purchaseToken',
        value: purchaseToken == null || purchaseToken!.isEmpty
            ? 'null'
            : purchaseToken!,
      ),
      PurchaseDisplayField(
        label: 'platform',
        value: platform.toJson().toLowerCase(),
      ),
      PurchaseDisplayField(label: 'quantity', value: quantity.toString()),
      PurchaseDisplayField(
        label: 'purchaseState',
        value: purchaseState.name,
      ),
      PurchaseDisplayField(
        label: 'isAutoRenewing',
        value: isAutoRenewing.toString(),
      ),
    ];

    sections.add(
      PurchaseDisplaySection(title: 'Common Fields', fields: commonFields),
    );

    if (this is PurchaseIOS) {
      final ios = this as PurchaseIOS;
      final iosFields = <PurchaseDisplayField>[
        PurchaseDisplayField(
          label: 'quantityIOS',
          value: ios.quantityIOS?.toString() ?? 'null',
        ),
        PurchaseDisplayField(
          label: 'originalTransactionDateIOS',
          value: _formatTimestamp(ios.originalTransactionDateIOS),
        ),
        PurchaseDisplayField(
          label: 'originalTransactionIdentifierIOS',
          value: _formatOptionalString(ios.originalTransactionIdentifierIOS),
        ),
        PurchaseDisplayField(
          label: 'appAccountToken',
          value: _formatOptionalString(ios.appAccountToken),
        ),
        PurchaseDisplayField(
          label: 'expirationDateIOS',
          value: _formatTimestamp(ios.expirationDateIOS),
        ),
        PurchaseDisplayField(
          label: 'webOrderLineItemIdIOS',
          value: _formatNumericLikeString(ios.webOrderLineItemIdIOS),
        ),
        PurchaseDisplayField(
          label: 'environmentIOS',
          value: _formatOptionalString(ios.environmentIOS),
        ),
        PurchaseDisplayField(
          label: 'storefrontCountryCodeIOS',
          value: _formatOptionalString(ios.storefrontCountryCodeIOS),
        ),
        PurchaseDisplayField(
          label: 'appBundleIdIOS',
          value: _formatOptionalString(ios.appBundleIdIOS),
        ),
        PurchaseDisplayField(
          label: 'subscriptionGroupIdIOS',
          value: _formatOptionalString(ios.subscriptionGroupIdIOS),
        ),
        PurchaseDisplayField(
          label: 'isUpgradedIOS',
          value: ios.isUpgradedIOS?.toString() ?? 'null',
        ),
        PurchaseDisplayField(
          label: 'ownershipTypeIOS',
          value: _formatOptionalString(ios.ownershipTypeIOS),
        ),
        PurchaseDisplayField(
          label: 'reasonIOS',
          value: _formatOptionalString(ios.reasonIOS),
        ),
        PurchaseDisplayField(
          label: 'reasonStringRepresentationIOS',
          value: _formatOptionalString(ios.reasonStringRepresentationIOS),
        ),
        PurchaseDisplayField(
          label: 'transactionReasonIOS',
          value: _formatOptionalString(ios.transactionReasonIOS),
        ),
        PurchaseDisplayField(
          label: 'revocationDateIOS',
          value: _formatTimestamp(ios.revocationDateIOS),
        ),
        PurchaseDisplayField(
          label: 'revocationReasonIOS',
          value: _formatOptionalString(ios.revocationReasonIOS),
        ),
        PurchaseDisplayField(
          label: 'currencyCodeIOS',
          value: _formatOptionalString(ios.currencyCodeIOS),
        ),
        PurchaseDisplayField(
          label: 'currencySymbolIOS',
          value: _formatOptionalString(ios.currencySymbolIOS),
        ),
        PurchaseDisplayField(
          label: 'countryCodeIOS',
          value: _formatOptionalString(ios.countryCodeIOS),
        ),
      ];

      final offer = ios.offerIOS;
      if (offer != null) {
        iosFields.addAll(
          [
            PurchaseDisplayField(label: 'offerIOS.id', value: offer.id),
            PurchaseDisplayField(label: 'offerIOS.type', value: offer.type),
            PurchaseDisplayField(
              label: 'offerIOS.paymentMode',
              value: offer.paymentMode,
            ),
          ],
        );
      }

      sections.add(
        PurchaseDisplaySection(title: 'iOS Fields', fields: iosFields),
      );
    }

    if (this is PurchaseAndroid) {
      final android = this as PurchaseAndroid;
      final androidFields = <PurchaseDisplayField>[
        PurchaseDisplayField(
          label: 'dataAndroid',
          value: _formatOptionalString(android.dataAndroid),
        ),
        PurchaseDisplayField(
          label: 'transactionId',
          value: transactionIdFor ?? 'null',
        ),
        PurchaseDisplayField(
          label: 'signatureAndroid',
          value: _formatOptionalString(android.signatureAndroid),
        ),
        PurchaseDisplayField(
          label: 'autoRenewingAndroid',
          value: android.autoRenewingAndroid?.toString() ?? 'null',
        ),
        PurchaseDisplayField(
          label: 'isAcknowledgedAndroid',
          value: android.isAcknowledgedAndroid?.toString() ?? 'null',
        ),
        PurchaseDisplayField(
          label: 'packageNameAndroid',
          value: _formatOptionalString(android.packageNameAndroid),
        ),
        PurchaseDisplayField(
          label: 'developerPayloadAndroid',
          value: _formatOptionalString(android.developerPayloadAndroid),
        ),
        PurchaseDisplayField(
          label: 'obfuscatedAccountIdAndroid',
          value: _formatOptionalString(android.obfuscatedAccountIdAndroid),
        ),
        PurchaseDisplayField(
          label: 'obfuscatedProfileIdAndroid',
          value: _formatOptionalString(android.obfuscatedProfileIdAndroid),
        ),
      ];

      sections.add(
        PurchaseDisplaySection(title: 'Android Fields', fields: androidFields),
      );
    }

    return sections;
  }
}

class PurchaseDataView extends StatelessWidget {
  const PurchaseDataView({
    required this.purchase,
    this.statusLabel,
    this.statusColor,
    this.sectionSpacing = 16,
    this.fieldSpacing = 8,
    Key? key,
  }) : super(key: key);

  final Purchase purchase;
  final String? statusLabel;
  final Color? statusColor;
  final double sectionSpacing;
  final double fieldSpacing;

  @override
  Widget build(BuildContext context) {
    final sections = purchase.toDisplaySections();
    final theme = Theme.of(context);
    final chips = <Widget>[
      _buildInfoChip(
        context,
        label: 'State: ${purchase.purchaseState.name}',
      ),
      _buildInfoChip(
        context,
        label: 'Platform: ${purchase.platform.toJson().toLowerCase()}',
      ),
      _buildInfoChip(
        context,
        label: 'Quantity: ${purchase.quantity}',
      ),
      _buildInfoChip(
        context,
        label: 'Auto renew: ${purchase.isAutoRenewing}',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                purchase.productId.isEmpty
                    ? 'Unknown product'
                    : purchase.productId,
                style: theme.textTheme.titleMedium,
              ),
            ),
            if (statusLabel != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (statusColor ?? theme.colorScheme.primary)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: statusColor ?? theme.colorScheme.primary),
                ),
                child: Text(
                  statusLabel!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: statusColor ?? theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: chips,
        ),
        SizedBox(height: sectionSpacing),
        for (final section in sections) ...[
          Text(
            section.title,
            style: theme.textTheme.bodyLarge
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: fieldSpacing / 2),
          ...section.fields.map(
            (field) => Padding(
              padding: EdgeInsets.only(bottom: fieldSpacing),
              child: _FieldRow(label: field.label, value: field.value),
            ),
          ),
          SizedBox(height: sectionSpacing),
        ],
      ],
    );
  }

  Widget _buildInfoChip(BuildContext context, {required String label}) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style:
            theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class PurchaseDataCard extends StatelessWidget {
  const PurchaseDataCard({
    required this.purchase,
    this.statusLabel,
    this.statusColor,
    Key? key,
  }) : super(key: key);

  final Purchase purchase;
  final String? statusLabel;
  final Color? statusColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: PurchaseDataView(
          purchase: purchase,
          statusLabel: statusLabel,
          statusColor: statusColor,
        ),
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.textTheme.bodySmall?.color?.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 4),
        SelectableText(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontFamily: value.contains('\n') ? 'monospace' : null,
          ),
        ),
      ],
    );
  }
}

String _formatList(List<String>? values) {
  if (values == null) return 'null';
  if (values.isEmpty) return '[]';
  return '[${values.join(', ')}]';
}

String _formatOptionalString(String? value) {
  if (value == null) return 'null';
  if (value.isEmpty) return '""';
  return value;
}

String _formatNumericLikeString(String? value) {
  if (value == null || value.isEmpty) {
    return 'null';
  }
  final numeric = int.tryParse(value);
  if (numeric != null) {
    return numeric.toString();
  }
  return value;
}

String _formatTimestamp(double? value) {
  if (value == null || value <= 0) {
    return 'null';
  }
  final milliseconds = value.round();
  final date = DateTime.fromMillisecondsSinceEpoch(milliseconds);
  final isoString = date.toIso8601String();
  return '$milliseconds ($isoString)';
}
