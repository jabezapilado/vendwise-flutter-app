import 'package:flutter/material.dart';
import 'package:vendwise/models/suppliermodel.dart';
import 'package:vendwise/screens/dashboard_screen.dart';
import 'package:vendwise/screens/inventory_screen.dart';
import 'package:vendwise/screens/products_screen.dart';
import 'package:vendwise/screens/sales_report.dart';
import 'package:vendwise/screens/transaction_screen.dart';
import 'package:file_picker/file_picker.dart';

class AddInventoryScreen extends StatefulWidget {
  const AddInventoryScreen({super.key});

  @override
  State<AddInventoryScreen> createState() => _AddInventoryScreenState();
}

class _AddInventoryScreenState extends State<AddInventoryScreen> {
  final int _selectedIndex = 1;
  final _formKey = GlobalKey<FormState>();
  TextEditingController productName = TextEditingController();
  TextEditingController productPrice = TextEditingController();
  TextEditingController productQuantity = TextEditingController();
  TextEditingController productExpiry = TextEditingController();
  TextEditingController productSupplier = TextEditingController();
  String? fileName;
  List<String> dropdownItems = <String>['Drinks', 'Food', 'Add-ons'];
  String? selectedItem;
  List<Suppliermodel> supplier = [];
  String? selectedSupplierName;

  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      setState(() {
        fileName = result.files.single.name;
      });
    }
  }

  void getSupplier() {
    setState(() {
      supplier = Suppliermodel.getSupplier();
    });
  }

  @override
  void initState() {
    super.initState();
    getSupplier();
  }
  // List<Inventorymodel> inventory = [];

  // void getInventory() {
  //   setState(() {
  //     inventory = Inventorymodel.getInventory();
  //   });

  // }

  // void initstate() {
  //   super.initState();
  //   getInventory();
  // }

  void _onItemTapped(int index) {
    if (index == 0) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    } else if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const InventoryScreen()),
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProductsScreen()),
      );
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const TransactionScreen()),
      );
    } else if (index == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SalesReport()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    getSupplier();
    return Scaffold(
      appBar: appbar(),
      backgroundColor: Color(0xFFFFFFFF),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DashboardScreen(),
                        ),
                      );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.arrow_back_ios_new,
                          color: Color(0xFFADADAD),
                          size: 20,
                        ),
                        SizedBox(width: 1),
                        Text(
                          "Back",
                          style: TextStyle(
                            color: Color(0xFFADADAD),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            fontFamily: "Inter",
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Image.asset('assets/images/logo_black.png', height: 90),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(width: 1, color: Colors.black),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: addForm(),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: buttonNav(),
    );
  }

  //methods
  AppBar appbar() {
    return AppBar(
      leading: IconButton(
        onPressed: () {},
        icon: const Icon(Icons.menu, color: Colors.white),
      ),
      title: const Text(
        'Add Product',
        style: TextStyle(
          fontFamily: "Inter",
          color: Colors.white,
          fontSize: 20.0,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.notifications, color: Colors.white),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.account_circle, color: Colors.white),
        ),
      ],
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFD74848), Color(0xFF111C51)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
      ),
    );
  }

  Container buttonNav() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFD74848), Color(0xFF111C51)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(5.0),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.white,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.space_dashboard_sharp),
              label: "Dashboard",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_rounded),
              label: "Inventory",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart_rounded),
              label: "Products",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_edu_rounded),
              label: "Transactions",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart),
              label: "Reports",
            ),
          ],
        ),
      ),
    );
  }

  Form addForm() {
    return Form(
      key: _formKey,
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              //INVENTORY TYPE HEADER
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 10.0),
                  child: const Text(
                    'Type',
                    style: TextStyle(
                      fontFamily: "Inter",
                      fontSize: 14.0,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4D0202),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 40,
              child: DropdownButtonFormField<String>(
                initialValue: selectedItem,
                style: const TextStyle(fontSize: 14),
                hint: const Text(
                  'Select a Type',
                  style: TextStyle(fontSize: 14, color: Colors.black),
                ),
                items: dropdownItems.map<DropdownMenuItem<String>>((
                  String value,
                ) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black,
                        fontFamily: "Inter",
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  selectedItem = newValue;
                },
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a type.';
                  }
                  return null;
                },
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
            ),

            Row(
              //INVENTORY PRODUCT NAME HEADER
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 10.0),
                  child: const Text(
                    'Product Name',
                    style: TextStyle(
                      fontFamily: "Inter",
                      fontSize: 14.0,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4D0202),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            SizedBox(
              height: 40,
              child: TextFormField(
                controller: productName,
                decoration: const InputDecoration(
                  hintText: 'Product Name',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                keyboardType: TextInputType.name,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter product name';
                  }
                  return null;
                },
              ),
            ),
            Row(
              //INVENTORY PRICE HEADER
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 10.0),
                  child: const Text(
                    'Price (₱)',
                    style: TextStyle(
                      fontFamily: "Inter",
                      fontSize: 14.0,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4D0202),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            SizedBox(
              height: 40,
              child: TextFormField(
                controller: productPrice,
                decoration: const InputDecoration(
                  hintText: 'Price',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter price';
                  }
                  return null;
                },
                keyboardType: TextInputType.number,
              ),
            ),
            Row(
              //INVENTORY QUANTITY HEADER
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 10.0),
                  child: const Text(
                    'Quantity',
                    style: TextStyle(
                      fontFamily: "Inter",
                      fontSize: 14.0,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4D0202),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            SizedBox(
              height: 40,
              child: TextFormField(
                controller: productQuantity,
                decoration: const InputDecoration(
                  hintText: 'Quantity',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the quantity';
                  }
                  if (int.tryParse(value.trim()) == null) {
                    return 'Please enter a valid quantity number';
                  }
                  int? amount = int.tryParse(value.trim());
                  if (amount != null && amount < 0) {
                    return 'quantity cannot be negative';
                  }
                  return null;
                },
              ),
            ),
            Row(
              //INVENTORY EXPIRY DATE HEADER
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 10.0),
                  child: const Text(
                    'Expiry Date',
                    style: TextStyle(
                      fontFamily: "Inter",
                      fontSize: 14.0,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4D0202),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            SizedBox(
              height: 40,
              child: TextFormField(
                controller: productSupplier,
                decoration: const InputDecoration(
                  hintText: 'dd/mm/yyyy',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                keyboardType: TextInputType.datetime,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter expiry date';
                  }
                  return null;
                },
              ),
            ),
            Row(
              //INVENTORY TYPE HEADER
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 10.0),
                  child: const Text(
                    'Supplier',
                    style: TextStyle(
                      fontFamily: "Inter",
                      fontSize: 14.0,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4D0202),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 40,
              child: DropdownButtonFormField<String>(
                initialValue: selectedSupplierName,
                style: const TextStyle(fontSize: 14),
                hint: const Text(
                  'Select a supplier',
                  style: TextStyle(fontSize: 14, color: Colors.black),
                ),
                items: supplier.map((Suppliermodel s) {
                  return DropdownMenuItem<String>(
                    value: s.supplierName,
                    child: Text(
                      s.supplierName,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black,
                        fontFamily: "Inter",
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedSupplierName = newValue;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a supplier.';
                  }
                  return null;
                },
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
            ),

            Row(
              //INVENTORY IMAGE HEADER
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 10.0),
                  child: const Text(
                    'Upload Your File Here:',
                    style: TextStyle(
                      fontFamily: "Inter",
                      fontSize: 14.0,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4D0202),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            GestureDetector(
              onTap: pickFile,
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: fileName == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.image, size: 50, color: Colors.grey),
                            SizedBox(height: 8),
                            Text(
                              "Tap to Upload",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        )
                      : Text(
                          "Uploaded: $fileName",
                          style: const TextStyle(color: Colors.black),
                        ),
                ),
              ),
            ),

            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: SizedBox(
                    height: 35,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF26347C),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const InventoryScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Add Product',
                        style: TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 35,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF822222),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const InventoryScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
