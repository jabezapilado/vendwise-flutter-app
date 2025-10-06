class Inventorymodel {
  String productName;
  String supplierName;
  double price;
  int quantity;
  int id = 0;
  int contactNum;
  String email;

  Inventorymodel({
    required this.productName,
    required this.supplierName,
    required this.price,
    required this.quantity,
    required this.contactNum,
    required this.email,
  });

  static List<Inventorymodel> getInventory() {
    List<Inventorymodel> inventory = [
       Inventorymodel(
        productName: 'Almond Milk',
        supplierName: 'Dairy Supplier Inc',
        price: 100.00,
        quantity: 1000,
        contactNum: 2225555666,
        email: 'dairy@supplier.com',
      ),
       Inventorymodel(
        productName: 'Almond Milk',
        supplierName: 'Dairy Supplier Inc',
        price: 100.00,
        quantity: 1000,
        contactNum: 2225555666,
        email: 'dairy@supplier.com',
      ),
       Inventorymodel(
        productName: 'Almond Milk',
        supplierName: 'Dairy Supplier Inc',
        price: 100.00,
        quantity: 1000,
        contactNum: 2225555666,
        email: 'dairy@supplier.com',
      ),
       Inventorymodel(
        productName: 'Almond Milk',
        supplierName: 'Dairy Supplier Inc',
        price: 100.00,
        quantity: 1000,
        contactNum: 2225555666,
        email: 'dairy@supplier.com',
      ),
       Inventorymodel(
        productName: 'Almond Milk',
        supplierName: 'Dairy Supplier Inc',
        price: 100.00,
        quantity: 1000,
        contactNum: 2225555666,
        email: 'dairy@supplier.com',
      ),
    ];

    return inventory;
  }
}
