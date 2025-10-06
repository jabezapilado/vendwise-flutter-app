class Suppliermodel {
  String supplierName;
  int id = 0;
  int contactNum;
  String email;

  Suppliermodel({
    required this.supplierName,
    required this.contactNum,
    required this.email,
  });

  static List<Suppliermodel> getSupplier() {
    List<Suppliermodel> supplier = [
       Suppliermodel(
      supplierName: 'Dairy Supplier Inc',
      contactNum: 2225555666,
      email: 'dairy@supplier.com',
    ),
    Suppliermodel(
      supplierName: 'Fresh Fruits Ltd',
      contactNum: 1114444777,
      email: 'fruits@supplier.com',
    ),
    Suppliermodel(
      supplierName: 'Meat Wholesale Co',
      contactNum: 999888777,
      email: 'meat@supplier.com',
    ),
    Suppliermodel(
      supplierName: 'Grain Suppliers',
      contactNum: 666555444,
      email: 'grain@supplier.com',
    ),
    Suppliermodel(
      supplierName: 'Beverage Partners',
      contactNum: 333222111,
      email: 'beverage@supplier.com',
    ),
    ];

    return supplier;
  }
}
