class Suppliermodel {
  const Suppliermodel({
    required this.id,
    required this.supplierName,
    this.contactNum,
    this.email,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String supplierName;
  final int? contactNum;
  final String? email;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Suppliermodel copyWith({
    String? id,
    String? supplierName,
    int? contactNum,
    String? email,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Suppliermodel(
      id: id ?? this.id,
      supplierName: supplierName ?? this.supplierName,
      contactNum: contactNum ?? this.contactNum,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Suppliermodel.fromMap(Map<String, dynamic> map) {
    return Suppliermodel(
      id: map['id']?.toString() ?? '',
      supplierName: (map['supplier_name'] ?? '') as String,
      contactNum: map['contact_number'] != null
          ? _parseNum(map['contact_number']).toInt()
          : null,
      email: map['email'] as String?,
      createdAt: _tryParseDate(map['created_at']),
      updatedAt: _tryParseDate(map['updated_at']),
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

class SupplierDraft {
  const SupplierDraft({
    required this.supplierName,
    this.contactNum,
    this.email,
  });

  final String supplierName;
  final int? contactNum;
  final String? email;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'supplier_name': supplierName,
      'contact_number': contactNum,
      'email': email,
    }..removeWhere((key, value) => value == null);
  }

  factory SupplierDraft.fromModel(Suppliermodel model) {
    return SupplierDraft(
      supplierName: model.supplierName,
      contactNum: model.contactNum,
      email: model.email,
    );
  }
}
