import 'package:flutter/material.dart';
import 'package:vendwise/models/productmodel.dart';
import 'package:vendwise/screens/add_product_screen.dart';
import 'package:vendwise/screens/dashboard_screen.dart';
import 'package:vendwise/screens/inventory_screen.dart';
import 'package:vendwise/screens/sales_report.dart';
import 'package:vendwise/screens/transaction_screen.dart';
import 'package:vendwise/screens/update_product_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final int _selectedIndex = 2;
  TextEditingController productsearch = TextEditingController();
  TextEditingController suppliersearch = TextEditingController();
  List<Productmodel> product = [];

  void getProduct() {
  setState(() {
    product = Productmodel.getProduct();
  });
}

 @override
void initState() {
  super.initState();
  getProduct();
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
    } else if (index == 2) {}
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
    backgroundColor: const Color(0xFFFFFFFF),
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 5),
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
        const SizedBox(height: 5),
        Padding(
          padding: const EdgeInsets.only(left: 10, right: 10),
          child: productHeaderTop(),
        ),
        const SizedBox(height: 5),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 0, horizontal: 25.0),
          child: const Text(
            'Browse, add, update, and delete products',
            style: TextStyle(
              fontFamily: "Inter",
              color: Colors.black,
              fontSize: 11.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.only(left: 10, right: 10),
          child: productHeaderBot(),
        ),
        const SizedBox(height: 10),
        productList(),
      ],
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
        'Products',
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

  Row productHeaderTop() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Products',
          style: TextStyle(
            fontFamily: "Inter",
            color: Colors.black,
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(
          height: 30,
          child: Container(
            decoration: BoxDecoration(
              color: Color(0xFF26347C),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(2.0),
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddProductScreen(),
                    ),
                  );
                },
                child: Text(
                  'Add Product',
                  style: TextStyle(
                    fontFamily: "Inter",
                    color: Colors.white,
                    fontSize: 11.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Row productHeaderBot() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 30,
          child: Container(
            decoration: BoxDecoration(
              color: Color(0xFF146533),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(1.0),
              child: TextButton(
                onPressed: () {},
                child: Row(
                   mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'ALL ITEMS',
                      style: TextStyle(
                        fontFamily: "Inter",
                        color: Colors.white,
                        fontSize: 11.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                     const SizedBox(width: 4),
                    Icon(Icons.arrow_drop_down, size: 24, color: Colors.black,)
                  ],
                ),
              ),
            ),
          ),
        ),
        Flexible(
          child: SizedBox(
            height: 30,
            child: Container(
              margin: EdgeInsets.only(left: 10, right: 10),
              width: 180,
              child: TextField(
                controller: productsearch,
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                  hintText: 'Search Product',
                  hintStyle: TextStyle(color: Color.fromARGB(255, 173, 172, 172)),
                  suffixIcon: SizedBox(
                    width: 50,
                    child: IntrinsicHeight(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          VerticalDivider(
                            color: Colors.black,
                            thickness: 1,
                            indent: 10,
                            endIndent: 10,
                          ),
                          Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Icon(Icons.search),
                          ),
                        ],
                      ),
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Expanded productList() {
    return Expanded(
      child: ListView.builder(
        itemCount: product.length,
        itemBuilder: (context, index) {
          return Card(
            color: Color(0xFFFFFFFF),
            margin: const EdgeInsets.all(8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(
                color: Colors.black, 
                width: 1.5,
              ),
              ),
              child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.black, width: 3),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                      child: Image.asset(
                        product[index].prodImage,
                        width: double.infinity,
                        height: MediaQuery.of(context).size.width * 0.4,
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          product[index].productName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFF0F9972),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UpdateProductScreen(),
                  ),
                );
                          },
                          child: const Text(
                            'Update Product',
                            style: TextStyle(
                              fontFamily: "Inter",
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: 250,
                        child: Text(
                          product[index].productDesc,
                          style: const TextStyle(
                            fontFamily: "Inter",
                            color: Colors.black87,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "₱${product[index].priceM.toStringAsFixed(0)} (M) | "
                          "₱${product[index].priceL.toStringAsFixed(0)} (L)",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFFE43B3B),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {},
                          child: const Text(
                            'Delete Product',
                            style: TextStyle(
                              fontFamily: "Inter",
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
  }


}
