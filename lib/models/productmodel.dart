class Productmodel {
  const Productmodel({
    required this.id,
    required this.productName,
    required this.productDesc,
    required this.priceM,
    required this.priceL,
    required this.prodType,
    this.prodImage,
    this.createdAt,
    this.updatedAt,
    this.quantity = 0,
  });

  final String id;
  final String productName;
  final String productDesc;
  final double priceM;
  final double priceL;
  final String prodType;
  final String? prodImage;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int quantity;

  Productmodel copyWith({
    String? id,
    String? productName,
    String? productDesc,
    double? priceM,
    double? priceL,
    String? prodType,
    String? prodImage,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? quantity,
  }) {
    return Productmodel(
      id: id ?? this.id,
      productName: productName ?? this.productName,
      productDesc: productDesc ?? this.productDesc,
      priceM: priceM ?? this.priceM,
      priceL: priceL ?? this.priceL,
      prodType: prodType ?? this.prodType,
      prodImage: prodImage ?? this.prodImage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      quantity: quantity ?? this.quantity,
    );
  }

  factory Productmodel.fromMap(Map<String, dynamic> map) {
    return Productmodel(
      id: map['id']?.toString() ?? '',
      productName: (map['product_name'] ?? '') as String,
      productDesc: (map['product_desc'] ?? '') as String,
      priceM: _parseNum(map['price_m']).toDouble(),
      priceL: _parseNum(map['price_l']).toDouble(),
      prodType: (map['prod_type'] ?? '') as String,
      prodImage: map['image_url'] as String?,
      createdAt: _tryParseDate(map['created_at']),
      updatedAt: _tryParseDate(map['updated_at']),
    );
  }
}

class ProductDraft {
  const ProductDraft({
    required this.productName,
    required this.productDesc,
    required this.priceM,
    required this.priceL,
    required this.prodType,
    this.prodImage,
    this.clearImage = false,
  });

  final String productName;
  final String productDesc;
  final double priceM;
  final double priceL;
  final String prodType;
  final String? prodImage;
  final bool clearImage;

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'product_name': productName,
      'product_desc': productDesc,
      'price_m': priceM,
      'price_l': priceL,
      'prod_type': prodType,
      'image_url': prodImage,
    };
    if (clearImage) {
      map['image_url'] = null;
    } else if (prodImage == null) {
      map.remove('image_url');
    }
    return map;
  }

  factory ProductDraft.fromModel(Productmodel model) {
    return ProductDraft(
      productName: model.productName,
      productDesc: model.productDesc,
      priceM: model.priceM,
      priceL: model.priceL,
      prodType: model.prodType,
      prodImage: model.prodImage,
      clearImage: false,
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
