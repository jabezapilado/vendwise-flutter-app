import 'package:flutter/material.dart';
import 'package:vendwise/backend/app_repository.dart';
import 'package:vendwise/models/productmodel.dart';
import 'package:vendwise/screens/products/add_product_screen.dart';
import 'package:vendwise/screens/dashboard/dashboard_screen.dart';
import 'package:vendwise/screens/inventory/inventory_screen.dart';
import 'package:vendwise/screens/dashboard/sales_report.dart';
import 'package:vendwise/screens/dashboard/transaction_screen.dart';
import 'package:vendwise/screens/products/update_product_screen.dart';
import 'package:vendwise/utils/app_haptics.dart';
import 'package:vendwise/utils/navigation_helpers.dart';
import 'package:vendwise/widgets/app_overlays.dart';
import 'package:vendwise/widgets/primary_app_bar.dart';
import 'package:vendwise/widgets/product_image.dart';

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
  bool _isLoading = false;
  String _selectedCategory = 'all';
  String _searchTerm = '';

  List<Productmodel> get _visibleProducts {
    return product.where((item) {
      final category = item.prodType.toLowerCase().trim();
      final matchesCategory =
          _selectedCategory == 'all' || category == _selectedCategory;
      final query = _searchTerm.trim().toLowerCase();
      final matchesSearch =
          query.isEmpty ||
          item.productName.toLowerCase().contains(query) ||
          item.productDesc.toLowerCase().contains(query);
      return matchesCategory && matchesSearch;
    }).toList();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
    });

    final fetchedProducts = await appRepository.fetchProducts();

    if (!mounted) return;

    setState(() {
      product = fetchedProducts;
      _isLoading = false;
    });
  }

  Future<void> _confirmDeleteProduct(Productmodel target) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete product'),
          content: Text(
            'Are you sure you want to remove "${target.productName}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    try {
      AppHaptics.mediumImpact();
      await appRepository.deleteProduct(target.id);
      await _loadProducts();
      if (!mounted) return;
      showQuickMessage(context, 'Product deleted.');
    } catch (error) {
      if (!mounted) return;
      showQuickMessage(context, 'Failed to delete product: $error');
    }
  }

  void _openCategorySheet() {
    if (product.isEmpty) {
      showQuickMessage(context, 'Add products to enable filtering.');
      return;
    }

    final categories = <String>{
      for (final item in product) item.prodType.toLowerCase().trim(),
    }.toList()..sort();

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                leading: const Icon(Icons.apps),
                title: const Text('All items'),
                trailing: _selectedCategory == 'all'
                    ? const Icon(Icons.check)
                    : null,
                onTap: () {
                  AppHaptics.selectionChanged();
                  Navigator.of(sheetContext).pop();
                  setState(() {
                    _selectedCategory = 'all';
                  });
                },
              ),
              for (final category in categories)
                ListTile(
                  leading: const Icon(Icons.label),
                  title: Text(_formatCategoryLabel(category)),
                  trailing: _selectedCategory == category
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () {
                    AppHaptics.selectionChanged();
                    Navigator.of(sheetContext).pop();
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  String _formatCategoryLabel(String value) {
    if (value.isEmpty) {
      return 'Uncategorized';
    }
    return value
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          final lower = word.toLowerCase();
          return lower[0].toUpperCase() + lower.substring(1);
        })
        .join(' ');
  }

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  void _onItemTapped(int index) {
    if (index == 0) {
      pushWithSlide<void>(context, const DashboardScreen());
    } else if (index == 1) {
      pushWithSlide<void>(context, const InventoryScreen());
    } else if (index == 2) {
    } else if (index == 3) {
      pushWithSlide<void>(context, const TransactionScreen());
    } else if (index == 4) {
      pushWithSlide<void>(context, const SalesReport());
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pageContent = [
      const SizedBox(height: 5),
      GestureDetector(
        onTap: () {
          Navigator.of(context).pop();
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.arrow_back_ios_new, color: Color(0xFFADADAD), size: 20),
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
    ];

    final Widget scrollContent = ListView(
      padding: EdgeInsets.zero,
      children: pageContent,
    );

    return Scaffold(
      appBar: const PrimaryAppBar(
        title: 'Products',
        section: AppSection.products,
      ),
      backgroundColor: const Color(0xFFFFFFFF),
      body: RefreshIndicator(
        onRefresh: _loadProducts,
        child: _isLoading && product.isEmpty
            ? ListView(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.5,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                ],
              )
            : scrollContent,
      ),
      bottomNavigationBar: buttonNav(),
    );
  }

  @override
  void dispose() {
    productsearch.dispose();
    suppliersearch.dispose();
    super.dispose();
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

  Widget productHeaderTop() {
    final addButton = _buildAddProductButton();
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 400) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderTitle(),
              const SizedBox(height: 8),
              addButton,
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: _buildHeaderTitle()),
            const SizedBox(width: 12),
            addButton,
          ],
        );
      },
    );
  }

  Widget productHeaderBot() {
    final categoryButton = _buildCategoryButton();
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 480) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              categoryButton,
              const SizedBox(height: 12),
              SizedBox(
                height: 40,
                width: double.infinity,
                child: _buildSearchField(),
              ),
            ],
          );
        }

        return Row(
          children: [
            categoryButton,
            const SizedBox(width: 12),
            Expanded(child: SizedBox(height: 40, child: _buildSearchField())),
          ],
        );
      },
    );
  }

  Text _buildHeaderTitle() {
    return const Text(
      'Products',
      style: TextStyle(
        fontFamily: 'Inter',
        color: Colors.black,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildAddProductButton() {
    return FilledButton.icon(
      icon: const Icon(Icons.add, size: 18),
      label: const Text(
        'Add Product',
        style: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF26347C),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: () async {
        AppHaptics.lightImpact();
        final bool? refresh = await pushWithSlide<bool?>(
          context,
          const AddProductScreen(),
        );

        if (refresh == true) {
          AppHaptics.selectionChanged();
          await _loadProducts();
        }
      },
    );
  }

  Widget _buildCategoryButton() {
    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF146533),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      onPressed: () {
        AppHaptics.lightImpact();
        _openCategorySheet();
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _selectedCategory == 'all'
                ? 'ALL ITEMS'
                : _selectedCategory.toUpperCase(),
            style: const TextStyle(
              fontFamily: 'Inter',
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 6),
          const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 18,
            color: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: productsearch,
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 10,
          horizontal: 14,
        ),
        hintText: 'Search Product',
        hintStyle: const TextStyle(color: Color.fromARGB(255, 173, 172, 172)),
        suffixIcon: SizedBox(
          width: 44,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: const [
              VerticalDivider(
                color: Colors.black54,
                thickness: 1,
                indent: 10,
                endIndent: 10,
              ),
              Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(Icons.search, size: 18),
              ),
            ],
          ),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Colors.black54),
        ),
      ),
      onChanged: (value) {
        setState(() {
          _searchTerm = value;
        });
      },
    );
  }

  Widget productList() {
    if (product.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'No products available yet.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    final items = _visibleProducts;
    if (items.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'No products match your filters yet.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final currentProduct = items[index];
        return Card(
          color: const Color(0xFFFFFFFF),
          margin: const EdgeInsets.all(8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Colors.black, width: 1.5),
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
                  child: ProductImage(
                    imageUrl: currentProduct.prodImage,
                    width: double.infinity,
                    height: MediaQuery.of(context).size.width * 0.4,
                    fit: BoxFit.cover,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      currentProduct.productName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFF0F9972),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () async {
                        AppHaptics.selectionChanged();
                        final bool? refresh = await pushWithSlide<bool?>(
                          context,
                          UpdateProductScreen(product: currentProduct),
                        );

                        if (refresh == true) {
                          AppHaptics.selectionChanged();
                          await _loadProducts();
                        }
                      },
                      child: const Text(
                        'Update Product',
                        style: TextStyle(
                          fontFamily: 'Inter',
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
                    width: double.infinity,
                    child: Text(
                      currentProduct.productDesc,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: Colors.black87,
                        fontSize: 12,
                      ),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '₱${currentProduct.priceM.toStringAsFixed(0)} (M) | '
                      '₱${currentProduct.priceL.toStringAsFixed(0)} (L)',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFFE43B3B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () {
                        AppHaptics.lightImpact();
                        _confirmDeleteProduct(currentProduct);
                      },
                      child: const Text(
                        'Delete Product',
                        style: TextStyle(
                          fontFamily: 'Inter',
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
    );
  }
}
