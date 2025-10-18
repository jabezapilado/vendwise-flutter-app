import 'package:flutter/material.dart';
import 'package:vendwise/backend/app_repository.dart';
import 'package:vendwise/models/productmodel.dart';
import 'package:vendwise/models/transactionmodel.dart';
import 'package:vendwise/screens/dashboard/dashboard_screen.dart';
import 'package:vendwise/screens/dashboard/receipt_screen.dart';
import 'package:vendwise/screens/dashboard/sales_report.dart';
import 'package:vendwise/screens/inventory/inventory_screen.dart';
import 'package:vendwise/screens/products/add_product_screen.dart';
import 'package:vendwise/screens/products/products_screen.dart';
import 'package:vendwise/utils/app_haptics.dart';
import 'package:vendwise/utils/navigation_helpers.dart';
import 'package:vendwise/widgets/app_navigation_drawer.dart';
import 'package:vendwise/widgets/app_overlays.dart';
import 'package:vendwise/widgets/primary_app_bar.dart';
import 'package:vendwise/widgets/product_image.dart';
import 'package:vendwise/services/receipt_store.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  final int _selectedIndex = 3;
  final TextEditingController productsearch = TextEditingController();
  final TextEditingController customernamesearch = TextEditingController();
  List<Productmodel> products = [];
  List<CartItem> cartItems = [];
  final Map<String, ScrollController> _controllers = {};
  static const String _allItemsLabel = 'All Items';
  static const List<String> _categoryFilters = <String>[
    _allItemsLabel,
    'Drinks',
    'Foods',
    'Add-ons',
  ];
  static const List<String> _primaryCategoryOrder = <String>[
    'Drinks',
    'Foods',
    'Add-ons',
  ];
  static const String _uncategorizedLabel = 'Uncategorized';
  String _selectedCategory = _allItemsLabel;

  Future<void> _loadProducts() async {
    try {
      final fetchedProducts = await appRepository.fetchProducts();
      if (!mounted) return;
      setState(() {
        products = fetchedProducts;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        products = const <Productmodel>[];
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    productsearch.dispose();
    customernamesearch.dispose();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onItemTapped(int index) {
    AppHaptics.selectionChanged();
    if (index == _selectedIndex) return;

    if (index == 0) {
      pushWithSlide<void>(context, const DashboardScreen());
    } else if (index == 1) {
      pushWithSlide<void>(context, const InventoryScreen());
    } else if (index == 2) {
      pushWithSlide<void>(context, const ProductsScreen());
    } else if (index == 4) {
      pushWithSlide<void>(context, const SalesReport());
    }
  }

  void addToCart(Productmodel product) {
    AppHaptics.lightImpact();
    setState(() {
      final existingIndex = cartItems.indexWhere(
        (item) => item.product.productName == product.productName,
      );
      if (existingIndex >= 0) {
        cartItems[existingIndex].quantity++;
      } else {
        cartItems.add(CartItem(product: product, quantity: 1));
      }
    });
  }

  void removeFromCart(int index) {
    if (index < 0 || index >= cartItems.length) return;
    AppHaptics.mediumImpact();
    setState(() {
      cartItems.removeAt(index);
    });
  }

  void incrementQuantity(int index) {
    if (index < 0 || index >= cartItems.length) return;
    AppHaptics.selectionChanged();
    setState(() {
      cartItems[index].quantity++;
    });
  }

  void decrementQuantity(int index) {
    if (index < 0 || index >= cartItems.length) return;
    AppHaptics.selectionChanged();
    setState(() {
      if (cartItems[index].quantity > 1) {
        cartItems[index].quantity--;
      } else {
        removeFromCart(index);
      }
    });
  }

  double getSubtotal() {
    return cartItems.fold(
      0,
      (sum, item) => sum + (item.product.priceM * item.quantity),
    );
  }

  double getTax() {
    return getSubtotal() * 0.12; // 12% tax
  }

  double getTotal() {
    return getSubtotal() + getTax();
  }

  @override
  Widget build(BuildContext context) {
    final searchTerm = productsearch.text.trim().toLowerCase();
    final filteredProducts = products.where((product) {
      final category = _normalizeCategory(product.prodType);
      final matchesCategory =
          _selectedCategory == _allItemsLabel || category == _selectedCategory;
      final matchesSearch = searchTerm.isEmpty
          ? true
          : product.productName.toLowerCase().contains(searchTerm);
      return matchesCategory && matchesSearch;
    }).toList();

    final Map<String, List<Productmodel>> groupedProducts = {};
    for (final product in filteredProducts) {
      final category = _normalizeCategory(product.prodType);
      groupedProducts
          .putIfAbsent(category, () => <Productmodel>[])
          .add(product);
    }

    final orderedGroupedProducts = <String, List<Productmodel>>{};
    for (final category in _primaryCategoryOrder) {
      final items = groupedProducts.remove(category);
      if (items != null && items.isNotEmpty) {
        orderedGroupedProducts[category] = items;
      }
    }
    for (final entry in groupedProducts.entries) {
      orderedGroupedProducts[entry.key] = entry.value;
    }

    final hasProducts = products.isNotEmpty;
    final hasMatches = orderedGroupedProducts.isNotEmpty;

    return Scaffold(
      appBar: const PrimaryAppBar(
        title: 'Transaction',
        section: AppSection.transactions,
      ),
      drawer: AppNavigationDrawer(
        current: AppSection.transactions,
        rootContext: context,
      ),
      backgroundColor: const Color(0xFFFFFFFF),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  productHeaderTop(),
                  const SizedBox(height: 12),
                  const Text(
                    'Process customer purchases',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildSearchField(),
                  const SizedBox(height: 12),
                  _buildFilterButton(),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  if (!hasMatches)
                    _buildEmptyState(hasProducts: hasProducts)
                  else
                    productGrid(orderedGroupedProducts),
                  const SizedBox(height: 16),
                  currentSaleSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({required bool hasProducts}) {
    final title = hasProducts
        ? 'No products match your filters'
        : 'No products available yet';
    final subtitle = hasProducts
        ? 'Try a different category or search term.'
        : 'Add your first product to start a transaction.';
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 48),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey.shade100,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.shopping_bag_outlined, size: 42, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return SizedBox(
      height: 42,
      child: TextField(
        controller: productsearch,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 10,
            horizontal: 12,
          ),
          hintText: 'Search product',
          hintStyle: const TextStyle(color: Color(0xFFA0A0A0), fontSize: 13),
          suffixIcon: const Padding(
            padding: EdgeInsets.all(10),
            child: Icon(Icons.search, size: 18),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF26347C), width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterButton() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Builder(
        builder: (buttonContext) {
          return FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF146533),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            onPressed: () {
              AppHaptics.selectionChanged();
              _showCategoryMenu(buttonContext);
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _selectedCategory,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.arrow_drop_down,
                  size: 22,
                  color: Colors.white,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showCategoryMenu(BuildContext buttonContext) async {
    final buttonRenderObject = buttonContext.findRenderObject();
    if (buttonRenderObject is! RenderBox) {
      return;
    }
    final RenderBox button = buttonRenderObject;

    // Use the buttonContext when looking up the overlay to avoid
    // referring to a deactivated ancestor.
    final overlayState = Overlay.of(buttonContext);
    final overlayRenderObject = overlayState.context.findRenderObject();
    if (overlayRenderObject is! RenderBox) {
      return;
    }
    final RenderBox overlayBox = overlayRenderObject;

    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlayBox),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero),
          ancestor: overlayBox,
        ),
      ),
      Offset.zero & overlayBox.size,
    );

    final String? selected = await showMenu<String>(
      context: context,
      position: position,
      items: _categoryFilters
          .map(
            (category) => CheckedPopupMenuItem<String>(
              value: category,
              checked: category == _selectedCategory,
              child: Text(category),
            ),
          )
          .toList(),
    );

    if (!mounted || selected == null || selected == _selectedCategory) {
      return;
    }

    AppHaptics.selectionChanged();
    setState(() {
      _selectedCategory = selected;
    });
  }

  String _normalizeCategory(String rawCategory) {
    final String trimmed = rawCategory.trim();
    if (trimmed.isEmpty) {
      return _uncategorizedLabel;
    }

    final String lower = trimmed.toLowerCase();
    if (lower == 'drink' || lower == 'drinks') {
      return 'Drinks';
    }
    if (lower == 'food' || lower == 'foods') {
      return 'Foods';
    }
    if (lower == 'add-ons' ||
        lower == 'add-on' ||
        lower == 'addons' ||
        lower == 'add ons' ||
        lower == 'addon') {
      return 'Add-ons';
    }

    return trimmed;
  }

  Widget currentSaleSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current Sale',
            style: TextStyle(
              fontFamily: 'Inter',
              color: Colors.black,
              fontSize: 18,
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
                  vertical: 10,
                  horizontal: 12,
                ),
                hintText: 'Customer name (optional)',
                hintStyle: const TextStyle(
                  color: Color(0xFFA0A0A0),
                  fontSize: 12,
                ),
                suffixIcon: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(Icons.person_search_outlined, size: 18),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 160,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: cartItems.isEmpty
                ? const Center(
                    child: Text(
                      'No items in cart',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  )
                : ListView.separated(
                    itemCount: cartItems.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: Colors.grey.shade200),
                    itemBuilder: (context, index) {
                      final cartItem = cartItems[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        child: Row(
                          children: [
                            ProductImage(
                              imageUrl: cartItem.product.prodImage,
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cartItem.product.productName,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '₱${cartItem.product.priceM.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 12,
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
                                  icon: const Icon(
                                    Icons.remove_circle_outline,
                                    size: 20,
                                  ),
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
                                  icon: const Icon(
                                    Icons.add_circle_outline,
                                    size: 20,
                                  ),
                                  onPressed: () => incrementQuantity(index),
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
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
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal:', style: TextStyle(fontSize: 14)),
              Text(
                '₱${getSubtotal().toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tax:', style: TextStyle(fontSize: 14)),
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
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: cartItems.isEmpty ? null : _processPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF26347C),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Process payment',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processPayment() async {
    AppHaptics.mediumImpact();
    final total = getTotal();
    final subtotal = getSubtotal();
    final tax = getTax();
    final cashController = TextEditingController(
      text: total.toStringAsFixed(2),
    );
    String? errorText;

    final receivedCash = await showDialog<double>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Process payment'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Amount due: ₱${total.toStringAsFixed(2)}'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: cashController,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: false,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Cash received',
                      prefixText: '₱',
                      errorText: errorText,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF26347C),
                  ),
                  onPressed: () {
                    final parsed = _parseCashAmount(cashController.text);
                    if (parsed == null) {
                      setDialogState(() {
                        errorText = 'Enter a valid amount';
                      });
                      return;
                    }
                    if (parsed + 0.009 < total) {
                      setDialogState(() {
                        errorText = 'Amount is less than total due';
                      });
                      return;
                    }

                    Navigator.of(dialogContext).pop(parsed);
                  },
                  child: const Text('Complete'),
                ),
              ],
            );
          },
        );
      },
    );

    // cashController is intentionally not disposed here because it is
    // still referenced by the dialog's widget tree during lifecycle.
    // Disposing it here caused "used after disposed" exceptions.

    if (receivedCash == null) {
      return;
    }

    final items = cartItems
        .map(
          (item) => ReceiptItem(
            name: item.product.productName,
            quantity: item.quantity,
            unitPrice: item.product.priceM,
          ),
        )
        .toList();

    final trimmedName = customernamesearch.text.trim();
    final customerName = trimmedName.isEmpty ? 'Walk-in customer' : trimmedName;
    final itemCount = cartItems.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );
    final timestamp = DateTime.now();
    final draft = TransactionDraft(
      customerName: customerName,
      itemCount: itemCount,
      totalAmount: total,
      timePurchased: timestamp,
    );

    try {
      await appRepository.createTransaction(draft);
    } catch (error, stackTrace) {
      debugPrint('Failed to record transaction: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to record transaction. Please try again.'),
          ),
        );
      }
      return;
    }

    final change = receivedCash - total;
    final receipt = TransactionReceipt(
      id: timestamp.millisecondsSinceEpoch.toString(),
      customerName: customerName,
      items: items,
      subtotal: subtotal,
      tax: tax,
      total: total,
      cashTendered: receivedCash,
      change: change > 0 ? change : 0,
      timestamp: timestamp,
    );

    ReceiptStore.instance.record(receipt);

    if (!mounted) return;
    pushWithSlide<void>(context, const ReceiptScreen());

    setState(() {
      cartItems.clear();
      customernamesearch.clear();
    });
  }

  double? _parseCashAmount(String input) {
    final cleaned = input.replaceAll(RegExp(r'[^0-9.]'), '');
    if (cleaned.isEmpty) {
      return null;
    }
    return double.tryParse(cleaned);
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
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_rounded),
              label: 'Inventory',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart_rounded),
              label: 'Products',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_edu_rounded),
              label: 'Transactions',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart),
              label: 'Reports',
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
        if (constraints.maxWidth < 420) {
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

  Text _buildHeaderTitle() {
    return const Text(
      'Transaction',
      style: TextStyle(
        fontFamily: 'Inter',
        color: Colors.black,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildAddProductButton() {
    return FilledButton.icon(
      icon: const Icon(Icons.add, size: 18),
      label: const Text(
        'Add product',
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
          await _loadProducts();
        }
      },
    );
  }

  Widget productGrid(Map<String, List<Productmodel>> groupedProducts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: groupedProducts.entries.map((entry) {
        final category = entry.key;
        final items = entry.value;
        final controller = _controllers.putIfAbsent(
          category,
          () => ScrollController(),
        );
        final hasMultipleItems = items.length > 1;
        final itemWidth = MediaQuery.of(context).size.width * 0.42;

        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  category,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
                child: Row(
                  children: [
                    _buildScrollArrow(
                      icon: Icons.arrow_left_sharp,
                      visible: hasMultipleItems,
                      controller: controller,
                      onTap: () => _scrollCategory(controller, -itemWidth),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: controller,
                        scrollDirection: Axis.horizontal,
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final product = items[index];
                          return GestureDetector(
                            onTap: () => addToCart(product),
                            child: Container(
                              width: itemWidth,
                              margin: const EdgeInsets.symmetric(horizontal: 6),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Card(
                                clipBehavior: Clip.antiAlias,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: ProductImage(
                                        imageUrl: product.prodImage,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            product.productName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '₱${product.priceM.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontSize: 13,
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
                    _buildScrollArrow(
                      icon: Icons.arrow_right_sharp,
                      visible: hasMultipleItems,
                      controller: controller,
                      onTap: () => _scrollCategory(controller, itemWidth),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildScrollArrow({
    required IconData icon,
    required bool visible,
    required ScrollController controller,
    required VoidCallback onTap,
  }) {
    if (!visible) {
      return const SizedBox(width: 8);
    }

    final bool isActive;
    if (!controller.hasClients) {
      isActive = true;
    } else if (icon == Icons.arrow_left_sharp) {
      isActive = controller.offset > controller.position.minScrollExtent + 2;
    } else {
      isActive = controller.offset < controller.position.maxScrollExtent - 2;
    }

    return SizedBox(
      width: 40,
      child: Center(
        child: IconButton(
          splashRadius: 22,
          padding: EdgeInsets.zero,
          icon: Icon(icon, color: isActive ? Colors.black87 : Colors.grey),
          onPressed: isActive ? onTap : null,
        ),
      ),
    );
  }

  Future<void> _scrollCategory(
    ScrollController controller,
    double delta,
  ) async {
    if (!controller.hasClients) return;
    AppHaptics.selectionChanged();
    final min = controller.position.minScrollExtent;
    final max = controller.position.maxScrollExtent;
    final target = (controller.offset + delta).clamp(min, max);
    await controller.animateTo(
      target,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );
    setState(() {});
  }
}

class CartItem {
  CartItem({required this.product, required this.quantity});

  final Productmodel product;
  int quantity;
}
