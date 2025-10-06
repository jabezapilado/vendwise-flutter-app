import 'package:flutter/material.dart';
import 'package:vendwise/models/suppliermodel.dart';
import 'package:vendwise/screens/dashboard_screen.dart';
import 'package:vendwise/screens/inventory_screen.dart';
import 'package:vendwise/screens/products_screen.dart';
import 'package:vendwise/screens/sales_report.dart';
import 'package:vendwise/screens/transaction_screen.dart';


class AddSupplierScreen extends StatefulWidget {
  const AddSupplierScreen({super.key});

  @override
  State<AddSupplierScreen> createState() => _AddSupplierScreenState();
}

class _AddSupplierScreenState extends State<AddSupplierScreen> {
  final int _selectedIndex = 1;
  final _formKey = GlobalKey<FormState>();
  TextEditingController supplierName = TextEditingController();
  TextEditingController supplierContact = TextEditingController();
  TextEditingController supplierEmail = TextEditingController();
  TextEditingController supplierAddress = TextEditingController();
  List<Suppliermodel> supplier = [];
  
  void getSupplier() {
    setState(() {
      supplier = Suppliermodel.getSupplier();
    });
  }

  void initstate() {
    super.initState();
    getSupplier();
  }

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
    }
    else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const TransactionScreen()),
      );
    }
    else if (index == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SalesReport()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appbar(),
      backgroundColor: Color(0xFFFFFFFF),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
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
              Image.asset('assets/images/logo_black.png', height: 90,),
              SizedBox(height: 8,),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(width: 1, color: Colors.black),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: addForm(),
                
                ),
                SizedBox(height: 8,),
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
        'Add Supplier',
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
          width: MediaQuery.of(context).size.width * 0.8,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                //INVENTORY SUPPLIER NAME HEADER
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                  margin: const EdgeInsets.only(top: 10.0),
                  child: const Text(
                    'Supplier Name',
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
                  controller: supplierName,
                  decoration: const InputDecoration(
                    hintText: 'Supplier Name',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  keyboardType: TextInputType.name,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter Supplier name';
                    }
                    return null;
                  },
                ),
              ),
              Row(
                //INVENTORY SUPPLIER CONTACT NUMBER HEADER
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 10.0),
                    child: const Text(
                      'Contact Number',
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
                  controller: supplierContact,
                  decoration: const InputDecoration(
                    hintText: 'Contact Number',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter Contact Number';
                    }
                    return null;
                  },
                ),
              ),
              Row(
                //INVENTORY EMAIL HEADER
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 10.0),
                    child: const Text(
                      'Email',
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
                  controller: supplierEmail,
                  decoration: const InputDecoration(
                    hintText: 'Email',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  keyboardType: TextInputType.emailAddress,
                  // validator: (value) {
                  //   if (value == null || value.trim().isEmpty) {
                  //     return 'Please enter the Email';
                  //   }
                  //   if (int.tryParse(value.trim()) == null) {
                  //     return 'Please enter a valid Email';
                  //   }
                  //   int? amount = int.tryParse(value.trim());
                  //   if (amount != null && amount < 0) {
                  //     return 'quantity cannot be negative';
                  //   }
                  //   return null;
                  // },
                  
                ),
              ),Row(
                //INVENTORY ADDRESS HEADER
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 10.0),
                    child: const Text(
                      'Address',
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
                  controller: supplierAddress,
                  decoration: const InputDecoration(
                    hintText: 'Address',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter address';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 20),
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
                          'Save',
                          style: TextStyle(
                            fontSize: 16.0,
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
                        backgroundColor: const Color(0xFF822222) ,
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