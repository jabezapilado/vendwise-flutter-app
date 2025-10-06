import 'package:flutter/material.dart';
import 'package:vendwise/models/inventorymodel.dart';
import 'package:vendwise/models/transactionmodel.dart';
import 'package:vendwise/screens/inventory_screen.dart';
import 'package:vendwise/screens/products_screen.dart';
import 'package:vendwise/screens/sales_report.dart';
import 'package:vendwise/screens/transaction_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Transactionmodel> transaction = [];
  List<Inventorymodel> inventory = [];
  final int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    getTransaction();
    getInventory();
  }

  void getInventory() {
    setState(() {
      inventory = Inventorymodel.getInventory();
    });
  }

  void getTransaction() {
    setState(() {
      transaction = Transactionmodel.getTransaction();
    });
  }

  void _onItemTapped(int index) {
    if (index == 0) {
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
    getInventory();
    getTransaction();
    return Scaffold(
      appBar: appbar(),
      backgroundColor: Color(0xFFFFFFFF),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.only(left: 10, right: 10),
              child: Text(
                'Overview',
                style: TextStyle(
                  fontFamily: "Inter",
                  color: Colors.black,
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 5),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 0, horizontal: 25.0),
              child: const Text(
                "Quick summary of your store's performance",
                style: TextStyle(
                  fontFamily: "Inter",
                  color: Colors.black,
                  fontSize: 11.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    //TODAY'S SALE
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.9,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black, width: 1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    "Today's Sales",
                                    style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    "₱10,000",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Image.asset(
                                'assets/images/bargrowth.png',
                                width: 40,
                                height: 40,
                                fit: BoxFit.contain,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    //ORDERS TODAY
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.9,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black, width: 1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    "Orders Today",
                                    style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    "39",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Image.asset(
                                'assets/images/checklist.png',
                                width: 40,
                                height: 40,
                                fit: BoxFit.contain,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    //INVENTORY SUMNMARY
                    inventorySummary(context),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,

              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Text(
                    'Recent Transaction',
                    style: TextStyle(
                      fontFamily: "Inter",
                      color: Colors.black,
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: TextButton(
                    onPressed: () {},
                    child: Text(
                      'View More',
                      style: TextStyle(
                        fontFamily: "Inter",
                        color: Color(0xFFB4AAAA),
                        fontSize: 15.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),
            Center(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SingleChildScrollView(child: transactionTable()),
                ),
              ),
            ),
            const SizedBox(height: 15),
          ],
        ),
      ),
      bottomNavigationBar: buttonNav(),
    );
  }

  SizedBox inventorySummary(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.9,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(9.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Inventory Summary",
                style: TextStyle(fontStyle: FontStyle.italic, fontSize: 14),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: 2, right: 2),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.inventory,
                          color: Colors.black,
                          size: 30,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          inventory.length.toString(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text("In stock", style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 2, right: 2),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.inventory,
                          color: Colors.black,
                          size: 30,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '0',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text("Low stock", style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 2, right: 2),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.inventory,
                          color: Colors.black,
                          size: 30,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '0',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          "Out of stock",
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 2, right: 2),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.inventory,
                          color: Colors.black,
                          size: 30,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '0',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text("To expire", style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 2, right: 2),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.inventory,
                          color: Colors.black,
                          size: 30,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '0',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text("Expired", style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  //METHODS----------------------------------------------------
  AppBar appbar() {
    return AppBar(
      leading: IconButton(
        onPressed: () {},
        icon: const Icon(Icons.menu, color: Colors.white),
      ),
      title: const Text(
        'Dashboard',
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

  Container transactionTable() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Table(
        border: TableBorder(
          horizontalInside: const BorderSide(color: Colors.black, width: 1),
        ),
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        columnWidths: const {
          0: FlexColumnWidth(3), // Customer
          1: FlexColumnWidth(2), // Item Count
          2: FlexColumnWidth(2), // TotalAmount
          3: FlexColumnWidth(2), // Time
        },
        children: [
          TableRow(
            children: [
              TableCell(
                verticalAlignment: TableCellVerticalAlignment.middle,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Customer',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: "Inter",
                        color: Colors.black,
                        fontSize: 15.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              TableCell(
                verticalAlignment: TableCellVerticalAlignment.middle,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Items',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: "Inter",
                        color: Colors.black,
                        fontSize: 15.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              TableCell(
                verticalAlignment: TableCellVerticalAlignment.middle,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Total',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: "Inter",
                        color: Colors.black,
                        fontSize: 15.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              TableCell(
                verticalAlignment: TableCellVerticalAlignment.middle,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Time',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: "Inter",
                        color: Colors.black,
                        fontSize: 15.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          ...List.generate(
            transaction.length,
            (index) => TableRow(
              children: [
                TableCell(
                  verticalAlignment: TableCellVerticalAlignment.middle,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        transaction[index].customerName,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black,
                          fontFamily: "Inter",
                          fontSize: 12.0,
                        ),
                      ),
                    ),
                  ),
                ),
                TableCell(
                  verticalAlignment: TableCellVerticalAlignment.middle,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        transaction[index].itemCount.toString(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black,
                          fontFamily: "Inter",
                          fontSize: 12.0,
                        ),
                      ),
                    ),
                  ),
                ),
                TableCell(
                  verticalAlignment: TableCellVerticalAlignment.middle,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        "₱${transaction[index].totalAmount.toString()} ",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black,
                          fontFamily: "Inter",
                          fontSize: 12.0,
                        ),
                      ),
                    ),
                  ),
                ),
                TableCell(
                  verticalAlignment: TableCellVerticalAlignment.middle,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        transaction[index].formattedTime,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black,
                          fontFamily: "Inter",
                          fontSize: 12.0,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
