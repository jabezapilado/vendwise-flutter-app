import 'package:flutter/foundation.dart';

/// Stores the most recently completed point-of-sale transaction so the receipt
/// screen can render dynamic data without relying on navigation arguments.
class ReceiptStore {
  ReceiptStore._();

  static final ReceiptStore instance = ReceiptStore._();

  final ValueNotifier<TransactionReceipt?> currentReceipt =
      ValueNotifier<TransactionReceipt?>(null);

  void record(TransactionReceipt receipt) {
    currentReceipt.value = receipt;
  }

  void clear() {
    currentReceipt.value = null;
  }
}

class TransactionReceipt {
  const TransactionReceipt({
    required this.id,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.cashTendered,
    required this.change,
    required this.timestamp,
    this.customerName,
    this.addons = const <ReceiptAddon>[],
  });

  final String id;
  final String? customerName;
  final List<ReceiptItem> items;
  final List<ReceiptAddon> addons;
  final double subtotal;
  final double tax;
  final double total;
  final double cashTendered;
  final double change;
  final DateTime timestamp;
}

class ReceiptItem {
  const ReceiptItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
  });

  final String name;
  final int quantity;
  final double unitPrice;

  double get lineTotal => unitPrice * quantity;
}

class ReceiptAddon {
  const ReceiptAddon({required this.name, required this.price});

  final String name;
  final double price;
}
