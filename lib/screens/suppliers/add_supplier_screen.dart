import 'package:flutter/material.dart';
import 'package:vendwise/backend/app_repository.dart';
import 'package:vendwise/models/suppliermodel.dart';
import 'package:vendwise/screens/dashboard/dashboard_screen.dart';
import 'package:vendwise/screens/inventory/inventory_screen.dart';
import 'package:vendwise/screens/products/products_screen.dart';
import 'package:vendwise/screens/dashboard/sales_report.dart';
import 'package:vendwise/screens/dashboard/transaction_screen.dart';
import 'package:vendwise/utils/navigation_helpers.dart';
import 'package:vendwise/widgets/app_overlays.dart';
import 'package:vendwise/widgets/primary_app_bar.dart';

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
  bool _isSubmitting = false;
  void _onItemTapped(int index) {
    if (index == 0) {
      pushWithSlide<void>(context, const DashboardScreen());
    } else if (index == 1) {
      pushWithSlide<void>(context, const InventoryScreen());
    } else if (index == 2) {
      pushWithSlide<void>(context, const ProductsScreen());
    } else if (index == 3) {
      pushWithSlide<void>(context, const TransactionScreen());
    } else if (index == 4) {
      pushWithSlide<void>(context, const SalesReport());
    }
  }

  @override
  void dispose() {
    supplierName.dispose();
    supplierContact.dispose();
    supplierEmail.dispose();
    supplierAddress.dispose();
    super.dispose();
  }

  Future<void> _submitSupplier() async {
    if (_isSubmitting) return;
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final String contactText = supplierContact.text.trim();
    final int? parsedContact = contactText.isEmpty
        ? null
        : int.tryParse(contactText);

    if (contactText.isNotEmpty && parsedContact == null) {
      _showSnackbar('Please enter a valid contact number.');
      return;
    }

    final draft = SupplierDraft(
      supplierName: supplierName.text.trim(),
      contactNum: parsedContact,
      email: supplierEmail.text.trim().isEmpty
          ? null
          : supplierEmail.text.trim(),
    );

    setState(() {
      _isSubmitting = true;
    });

    try {
      await appRepository.createSupplier(draft);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      _showSnackbar('Failed to save supplier. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PrimaryAppBar(
        title: 'Add Supplier',
        section: AppSection.inventory,
      ),
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
                    onTap: () => Navigator.of(context).pop(),
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
              Image.asset('assets/icons/logo_black.png', height: 90),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(width: 1, color: Colors.black),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: addForm(),
              ),
              SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  //methods
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
                  if (int.tryParse(value.trim()) == null) {
                    return 'Please enter a valid contact number';
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
            ),
            Row(
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
                      onPressed: _isSubmitting ? null : _submitSupplier,
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
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
                        backgroundColor: const Color(0xFF822222),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
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
