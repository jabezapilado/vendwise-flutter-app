import 'package:flutter/material.dart';
import 'package:vendwise/models/productmodel.dart';
import 'package:vendwise/screens/add_product_screen.dart';
import 'package:vendwise/screens/dashboard_screen.dart';
import 'package:vendwise/screens/inventory_screen.dart';
import 'package:vendwise/screens/products_screen.dart';
import 'package:vendwise/screens/receipt_screen.dart';
import 'package:vendwise/screens/sales_report.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  final int _selectedIndex = 3;
  TextEditingController productsearch = TextEditingController();
  TextEditingController customernamesearch = TextEditingController();
  List<Productmodel> products = [];
  List<CartItem> cartItems = [];
  final Map<String, ScrollController> _controllers = {};

  void getProduct() {
    setState(() {
      products = Productmodel.getProduct();
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
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProductsScreen()),
      );
    } else if (index == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SalesReport()),
      );
    }
  }

  void addToCart(Productmodel product) {
    setState(() {
      final existingIndex = cartItems.indexWhere((item) => item.product.productName == product.productName);
      if (existingIndex >= 0) {
        cartItems[existingIndex].quantity++;
      } else {
        cartItems.add(CartItem(product: product, quantity: 1));
      }
    });
  }

  void removeFromCart(int index) {
    setState(() {
      cartItems.removeAt(index);
    });
  }

  void incrementQuantity(int index) {
    setState(() {
      cartItems[index].quantity++;
    });
  }

  void decrementQuantity(int index) {
    setState(() {
      if (cartItems[index].quantity > 1) {
        cartItems[index].quantity--;
      } else {
        removeFromCart(index);
      }
    });
  }

  double getSubtotal() {
    return cartItems.fold(0, (sum, item) => sum + (item.product.priceM * item.quantity));
  }

  double getTax() {
    return getSubtotal() * 0.12; // 12% tax
  }

  double getTotal() {
    return getSubtotal() + getTax();
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, List<Productmodel>> groupedProducts = {};
    for (var p in products) {
      groupedProducts.putIfAbsent(p.prodType, () => []).add(p);
    }

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
              'Process customer purchases',
              style: TextStyle(
                fontFamily: "Inter",
                color: Colors.black,
                fontSize: 11.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: 5,),
          Center(
            child: SizedBox(
              height: 30,
              child: Container(
                margin: const EdgeInsets.only(left: 10, right: 10),
                width: 180,
                child: TextField(
                  controller: productsearch,
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                    hintText: 'Search Product',
                    hintStyle: const TextStyle(
                      color: Color.fromARGB(255, 173, 172, 172),
                    ),
                    suffixIcon: SizedBox(
                      width: 50,
                      child: IntrinsicHeight(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: const [
                            VerticalDivider(
                              color: Colors.black,
                              thickness: 1,
                              indent: 10,
                              endIndent: 10,
                            ),
                            Padding(
                              padding: EdgeInsets.all(4.0),
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
          const SizedBox(height: 10),
          SizedBox(
            height: 30,
            child: Padding(
              padding: const EdgeInsets.only(left: 10, right: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF146533),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(1.0),
                  child: TextButton(
                    onPressed: () {},
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          'ALL ITEMS',
                          style: TextStyle(
                            fontFamily: "Inter",
                            color: Colors.white,
                            fontSize: 11.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_drop_down,
                          size: 24,
                          color: Colors.black,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: groupedProducts.length * 180.0,
                    child: productGrid(groupedProducts),
                  ),
                  const SizedBox(height: 10),
                  currentSaleSection(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: buttonNav(),
    );
  }

  Widget currentSaleSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current Sale',
            style: TextStyle(
              fontFamily: "Inter",
              color: Colors.black,
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 45,
            child: TextField(
              controller: customernamesearch,
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                hintText: 'Customer Name (Optional)',
                hintStyle: const TextStyle(
                  color: Color.fromARGB(255, 173, 172, 172),
                  fontSize: 12,
                ),
                suffixIcon: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(Icons.search, size: 20),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade400),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade400),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 150,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: cartItems.isEmpty
                ? const Center(
                    child: Text(
                      'No items in cart',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final cartItem = cartItems[index];
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                cartItem.product.prodImage,
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cartItem.product.productName,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '₱${cartItem.product.priceM.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: const Icon(Icons.remove_circle_outline, size: 20),
                                  onPressed: () => decrementQuantity(index),
                                ),
                                Text(
                                  '${cartItem.quantity}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: const Icon(Icons.add_circle_outline, size: 20),
                                  onPressed: () => incrementQuantity(index),
                                ),
                              ],
                            ),
                            Text(
                              '₱${(cartItem.product.priceM * cartItem.quantity).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Subtotal:',
                style: TextStyle(
                  fontSize: 14,
                ),
              ),
              Text(
                '₱${getSubtotal().toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tax:',
                style: TextStyle(
                  fontSize: 14,
                ),
              ),
              Text(
                '₱${getTax().toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(height: 20, thickness: 1),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '₱${getTotal().toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: cartItems.isEmpty
                  ? null
                  : () {
                      // Process payment logic here
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Process Payment'),
                          content: Text('Total: ₱${getTotal().toStringAsFixed(2)}'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                 Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ReceiptScreen(),
                                  ),
                                );
                                setState(() {
                                  cartItems.clear();
                                });
                              },
                              child: const Text('Complete'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                          ],
                        ),
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF26347C),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Process Payment',
                style: TextStyle(
                  fontFamily: "Inter",
                  color: Colors.white,
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
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
        'Transaction',
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
        const Text(
          'Transaction',
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
              color: const Color(0xFF26347C),
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
                child: const Text(
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

  ListView productGrid(Map<String, List<dynamic>> groupedProducts) {
    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: groupedProducts.entries.map((entry) {
        final category = entry.key;
        final items = entry.value;

        _controllers.putIfAbsent(category, () => ScrollController());

        final itemWidth = MediaQuery.of(context).size.width / 3.5;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                category,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            SizedBox(
              height: 140, 
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_left_sharp),
                    onPressed: () {
                      _controllers[category]!.animateTo(
                        _controllers[category]!.offset - itemWidth,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: _controllers[category],
                      scrollDirection: Axis.horizontal,
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final product = items[index];
                        return GestureDetector(
                          onTap: () => addToCart(product),
                          child: Container(
                            width: itemWidth,
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            child: Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(12),
                                      ),
                                      child: Image.asset(
                                        product.prodImage,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: Column(
                                      children: [
                                        Text(
                                          product.productName,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          "₱${product.priceM}",
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Right arrow
                  IconButton(
                    icon: const Icon(Icons.arrow_right_sharp),
                    onPressed: () {
                      _controllers[category]!.animateTo(
                        _controllers[category]!.offset + itemWidth,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class CartItem {
  final Productmodel product;
  int quantity;

  CartItem({required this.product, required this.quantity});
}