class Inventorymodel {
  const Inventorymodel({
    required this.id,
    required this.productName,
    this.supplierName,
    required this.price,
    required this.quantity,
    this.contactNum,
    this.email,
    this.createdAt,
    this.updatedAt,
    this.expiryDate,
  });

  final String id;
  final String productName;
  final String? supplierName;
  final double price;
  final int quantity;
  final int? contactNum;
  final String? email;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? expiryDate;

  Inventorymodel copyWith({
    String? id,
    String? productName,
    String? supplierName,
    double? price,
    int? quantity,
    int? contactNum,
    String? email,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? expiryDate,
  }) {
    return Inventorymodel(
      id: id ?? this.id,
      productName: productName ?? this.productName,
      supplierName: supplierName ?? this.supplierName,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      contactNum: contactNum ?? this.contactNum,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      expiryDate: expiryDate ?? this.expiryDate,
    );
  }

  factory Inventorymodel.fromMap(Map<String, dynamic> map) {
    return Inventorymodel(
      id: map['id']?.toString() ?? '',
      productName: (map['product_name'] ?? '') as String,
      supplierName: map['supplier_name'] as String?,
      price: _parseNum(map['price']).toDouble(),
      quantity: _parseNum(map['quantity']).toInt(),
      contactNum: map['contact_number'] != null
          ? _parseNum(map['contact_number']).toInt()
          : null,
      email: map['email'] as String?,
      createdAt: _tryParseDate(map['created_at']),
      updatedAt: _tryParseDate(map['updated_at']),
      expiryDate: _tryParseDate(map['expiry_date']),
    );
  }

  static num _parseNum(dynamic value) {
    if (value == null) {
      return 0;
    }
    if (value is num) {
      return value;
    }
    return num.tryParse(value.toString()) ?? 0;
  }

  static DateTime? _tryParseDate(dynamic value) {
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}

class InventoryDraft {
  const InventoryDraft({
    required this.productName,
    this.supplierName,
    required this.price,
    required this.quantity,
    this.contactNum,
    this.email,
    this.expiryDate,
  });

  final String productName;
  final String? supplierName;
  final double price;
  final int quantity;
  final int? contactNum;
  final String? email;
  final DateTime? expiryDate;

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'product_name': productName,
      'supplier_name': supplierName,
      'price': price,
      'quantity': quantity,
      'contact_number': contactNum,
      'email': email,
    }..removeWhere((key, value) => value == null);

    if (expiryDate != null) {
      map['expiry_date'] = expiryDate!.toIso8601String();
    }

    return map;
  }

  factory InventoryDraft.fromModel(Inventorymodel model) {
    return InventoryDraft(
      productName: model.productName,
      supplierName: model.supplierName,
      price: model.price,
      quantity: model.quantity,
      contactNum: model.contactNum,
      email: model.email,
      expiryDate: model.expiryDate,
    );
  }
}
