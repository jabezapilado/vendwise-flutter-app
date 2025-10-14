import 'package:intl/intl.dart';

class Transactionmodel {
  const Transactionmodel({
    required this.id,
    required this.customerName,
    required this.itemCount,
    required this.totalAmount,
    required this.timePurchased,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String customerName;
  final int itemCount;
  final double totalAmount;
  final DateTime timePurchased;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get formattedTime {
    return DateFormat('h:mm a').format(timePurchased);
  }

  factory Transactionmodel.fromMap(Map<String, dynamic> map) {
    final timeValue = map['time_purchased'] ?? map['created_at'];
    return Transactionmodel(
      id: map['id']?.toString() ?? '',
      customerName: (map['customer_name'] ?? '') as String,
      itemCount: _parseNum(map['item_count']).toInt(),
      totalAmount: _parseNum(map['total_amount']).toDouble(),
      timePurchased: _tryParseDate(timeValue) ?? DateTime.now(),
      createdAt: _tryParseDate(map['created_at']),
      updatedAt: _tryParseDate(map['updated_at']),
    );
  }
}

class TransactionDraft {
  TransactionDraft({
    required this.customerName,
    required this.itemCount,
    required this.totalAmount,
    DateTime? timePurchased,
  }) : timePurchased = timePurchased ?? DateTime.now();

  final String customerName;
  final int itemCount;
  final double totalAmount;
  final DateTime timePurchased;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'customer_name': customerName,
      'item_count': itemCount,
      'total_amount': totalAmount,
      'time_purchased': timePurchased.toUtc().toIso8601String(),
    };
  }

  factory TransactionDraft.fromModel(Transactionmodel model) {
    return TransactionDraft(
      customerName: model.customerName,
      itemCount: model.itemCount,
      totalAmount: model.totalAmount,
      timePurchased: model.timePurchased,
    );
  }
}

num _parseNum(dynamic value) {
  if (value == null) {
    return 0;
  }
  if (value is num) {
    return value;
  }
  return num.tryParse(value.toString()) ?? 0;
}

DateTime? _tryParseDate(dynamic value) {
  if (value is DateTime) {
    return value;
  }
  if (value is String) {
    return DateTime.tryParse(value);
  }
  return null;
}
