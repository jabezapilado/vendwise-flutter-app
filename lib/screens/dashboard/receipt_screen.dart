import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vendwise/services/receipt_store.dart';
import 'package:vendwise/utils/app_haptics.dart';
import 'package:vendwise/widgets/app_navigation_drawer.dart';
import 'package:vendwise/widgets/app_overlays.dart';
import 'package:vendwise/widgets/primary_app_bar.dart';

class ReceiptScreen extends StatelessWidget {
  const ReceiptScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PrimaryAppBar(
        title: 'Process Payment',
        section: AppSection.transactions,
      ),
      drawer: AppNavigationDrawer(
        current: AppSection.transactions,
        rootContext: context,
      ),
      backgroundColor: const Color(0xFFF7F8FB),
      body: SafeArea(
        child: ValueListenableBuilder<TransactionReceipt?>(
          valueListenable: ReceiptStore.instance.currentReceipt,
          builder: (context, receipt, _) {
            if (receipt == null) {
              return _EmptyReceiptState(
                onReturn: () => Navigator.of(context).pop(),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BackBreadcrumb(onPressed: () => Navigator.of(context).pop()),
                  const SizedBox(height: 8),
                  const Text(
                    'Receipt',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _ReceiptCard(receipt: receipt),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        AppHaptics.selectionChanged();
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF111C51),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Back to Transaction',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ReceiptCard extends StatelessWidget {
  const _ReceiptCard({required this.receipt});

  final TransactionReceipt receipt;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en_PH', symbol: '₱');
    final timestamp = DateFormat(
      'MMM d, yyyy • h:mm a',
    ).format(receipt.timestamp.toLocal());
    final customerName = (receipt.customerName ?? '').trim().isEmpty
        ? 'Walk-in customer'
        : receipt.customerName!;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Vend Wise',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '#1 Holy Angels Street, 2009',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Inter', fontSize: 12),
            ),
            const Text(
              'Pampanga',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Inter', fontSize: 12),
            ),
            const SizedBox(height: 12),
            Text(
              'Receipt #${receipt.id}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
            Text(
              timestamp,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 16),
            const _DottedDivider(),
            const SizedBox(height: 16),
            const Text(
              'CASH RECEIPT',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const _DottedDivider(),
            const SizedBox(height: 16),
            _KeyValueRow(label: 'Customer', value: customerName),
            const SizedBox(height: 16),
            const _SectionHeader(),
            ...receipt.items.map(
              (item) => _ReceiptLineRow(
                description: item.quantity > 1
                    ? '${item.name} ×${item.quantity}'
                    : item.name,
                amount: currency.format(item.lineTotal),
              ),
            ),
            if (receipt.addons.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Add-ons',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              ...receipt.addons.map(
                (addon) => _ReceiptLineRow(
                  description: addon.name,
                  amount: currency.format(addon.price),
                ),
              ),
            ],
            const SizedBox(height: 16),
            const _DottedDivider(),
            const SizedBox(height: 12),
            _ReceiptTotalRow(
              label: 'Subtotal',
              amount: currency.format(receipt.subtotal),
            ),
            _ReceiptTotalRow(
              label: 'Tax (12%)',
              amount: currency.format(receipt.tax),
            ),
            const Divider(color: Colors.black87, thickness: 1),
            _ReceiptTotalRow(
              label: 'Total',
              amount: currency.format(receipt.total),
              emphasize: true,
            ),
            const SizedBox(height: 8),
            _ReceiptTotalRow(
              label: 'Cash',
              amount: currency.format(receipt.cashTendered),
            ),
            _ReceiptTotalRow(
              label: 'Change',
              amount: currency.format(receipt.change),
            ),
            const SizedBox(height: 16),
            const _DottedDivider(),
            const SizedBox(height: 16),
            const Text(
              'THANK YOU!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackBreadcrumb extends StatelessWidget {
  const _BackBreadcrumb({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        AppHaptics.selectionChanged();
        onPressed();
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.arrow_back_ios_new, color: Color(0xFFADADAD), size: 20),
          SizedBox(width: 4),
          Text(
            'Back',
            style: TextStyle(
              color: Color(0xFFADADAD),
              fontSize: 16,
              fontWeight: FontWeight.w500,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: const [
        Text(
          'Description',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          'Price',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ReceiptLineRow extends StatelessWidget {
  const _ReceiptLineRow({required this.description, required this.amount});

  final String description;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              description,
              style: const TextStyle(fontFamily: 'Inter', fontSize: 12),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            amount,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ReceiptTotalRow extends StatelessWidget {
  const _ReceiptTotalRow({
    required this.label,
    required this.amount,
    this.emphasize = false,
  });

  final String label;
  final String amount;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontFamily: 'Inter',
      fontSize: 12,
      fontWeight: emphasize ? FontWeight.w700 : FontWeight.w600,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(amount, style: style),
        ],
      ),
    );
  }
}

class _DottedDivider extends StatelessWidget {
  const _DottedDivider();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dashWidth = 4.0;
        final dashHeight = 1.4;
        final dashCount = (constraints.maxWidth / (dashWidth * 2)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.black87),
              ),
            );
          }),
        );
      },
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  const _KeyValueRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$label:',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyReceiptState extends StatelessWidget {
  const _EmptyReceiptState({required this.onReturn});

  final VoidCallback onReturn;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.receipt_long, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No receipt to show',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Complete a transaction to generate a receipt.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onReturn,
              child: const Text('Back to transaction'),
            ),
          ],
        ),
      ),
    );
  }
}
