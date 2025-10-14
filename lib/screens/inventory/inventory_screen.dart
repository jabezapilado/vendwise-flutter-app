import 'package:flutter/material.dart';
import 'package:vendwise/backend/app_repository.dart';
import 'package:vendwise/models/inventorymodel.dart';
import 'package:vendwise/models/suppliermodel.dart';
import 'package:vendwise/screens/inventory/add_inventory_screen.dart';
import 'package:vendwise/screens/suppliers/add_supplier_screen.dart';
import 'package:vendwise/screens/inventory/update_inventory_screen.dart';
import 'package:vendwise/screens/suppliers/update_supplier_screen.dart';
import 'package:vendwise/utils/navigation_helpers.dart';
import 'package:vendwise/widgets/app_navigation_drawer.dart';
import 'package:vendwise/widgets/app_overlays.dart';
import 'package:vendwise/widgets/primary_app_bar.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  TextEditingController productsearch = TextEditingController();
  TextEditingController suppliersearch = TextEditingController();
  List<Inventorymodel> inventory = [];
  List<Suppliermodel> supplier = [];
  bool _isLoading = false;

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final fetchedInventory = await appRepository.fetchInventory();
    final fetchedSuppliers = await appRepository.fetchSuppliers();

    if (!mounted) return;

    setState(() {
      inventory = fetchedInventory;
      supplier = fetchedSuppliers;
      _isLoading = false;
    });
  }

  void _showSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openInventoryUpdate(Inventorymodel item) async {
    final bool? refresh = await pushWithSlide<bool?>(
      context,
      UpdateInventoryScreen(inventory: item),
    );

    if (refresh == true) {
      await _loadData();
      if (!mounted) return;
      _showSnackbar('Inventory list refreshed.');
    }
  }

  Future<void> _openSupplierUpdate(Suppliermodel item) async {
    final bool? refresh = await pushWithSlide<bool?>(
      context,
      UpdateSupplierScreen(supplier: item),
    );

    if (refresh == true) {
      await _loadData();
      if (!mounted) return;
      _showSnackbar('Supplier list refreshed.');
    }
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PrimaryAppBar(
        title: 'Inventory',
        section: AppSection.inventory,
      ),
      drawer: AppNavigationDrawer(
        current: AppSection.inventory,
        rootContext: context,
      ),
      backgroundColor: const Color(0xFFFFFFFF),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _buildScrollableBody(),
      ),
    );
  }

  Widget _buildScrollableBody() {
    if (_isLoading && inventory.isEmpty && supplier.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(
            height: 240,
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          ..._buildSection(
            header: productHeader(),
            table: productTable(),
            onViewMore: _showInventoryBottomSheet,
          ),
          const SizedBox(height: 30),
          ..._buildSection(
            header: supplierHeader(),
            table: supplierTable(),
            onViewMore: _showSupplierBottomSheet,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  List<Widget> _buildSection({
    required Widget header,
    required Widget table,
    required VoidCallback onViewMore,
    EdgeInsetsGeometry headerPadding = const EdgeInsets.symmetric(
      horizontal: 10,
    ),
    EdgeInsetsGeometry tablePadding = const EdgeInsets.all(8.0),
  }) {
    return [
      Padding(padding: headerPadding, child: header),
      const SizedBox(height: 20),
      Padding(padding: tablePadding, child: table),
      const SizedBox(height: 5),
      _buildViewMoreButton(onViewMore),
    ];
  }

  @override
  void dispose() {
    productsearch.dispose();
    suppliersearch.dispose();
    super.dispose();
  }

  //METHODS----------------------------------------------------

  void _showInventoryBottomSheet() {
    if (inventory.isEmpty) {
      showQuickMessage(context, 'No inventory records yet.');
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: inventory.length,
            itemBuilder: (_, index) {
              final item = inventory[index];
              return ListTile(
                leading: const Icon(Icons.inventory_2),
                title: Text(item.productName),
                subtitle: Text('Supplier: ${item.supplierName ?? 'Unknown'}'),
                trailing: Text('Qty ${item.quantity}'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _openInventoryUpdate(item);
                },
              );
            },
          ),
        );
      },
    );
  }

  void _showSupplierBottomSheet() {
    if (supplier.isEmpty) {
      showQuickMessage(context, 'No supplier records yet.');
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: supplier.length,
            itemBuilder: (_, index) {
              final item = supplier[index];
              return ListTile(
                leading: const Icon(Icons.store),
                title: Text(item.supplierName),
                subtitle: Text(item.email ?? 'No email provided'),
                trailing: Text(item.contactNum?.toString() ?? 'N/A'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _openSupplierUpdate(item);
                },
              );
            },
          ),
        );
      },
    );
  }

  //PRODUCT HEADER
  Row productHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Product',
          style: TextStyle(
            fontFamily: "Inter",
            color: Colors.black,
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        Expanded(
          child: Container(
            margin: EdgeInsets.only(left: 10, right: 10),
            child: SizedBox(
              height: 35,
              child: TextField(
                controller: productsearch,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.all(5),
                  hintText: 'Search Product',
                  hintStyle: TextStyle(
                    color: Color.fromARGB(255, 173, 172, 172),
                  ),
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
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          ),
        ),

        Expanded(
          child: SizedBox(
            height: 35,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF26347C),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onPressed: () async {
                final bool? refresh = await pushWithSlide<bool?>(
                  context,
                  const AddInventoryScreen(),
                );

                if (refresh == true) {
                  await _loadData();
                }
              },
              child: const Text(
                'Add Product',
                style: TextStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  //PRODUCT TABLE METHOD
  Container productTable() {
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
          0: FlexColumnWidth(2),
          1: FlexColumnWidth(2),
          2: FlexColumnWidth(2),
          3: FlexColumnWidth(3),
        },
        children: [
          TableRow(
            children: [
              _buildHeaderCell('Products'),
              _buildHeaderCell('Supplier'),
              _buildHeaderCell('Price'),
              _buildHeaderCell('Quantity'),
            ],
          ),
          ...inventory.map((item) {
            return TableRow(
              children: [
                _buildInventoryTextCell(item.productName, item),
                _buildInventoryTextCell(
                  item.supplierName ?? 'Unknown Supplier',
                  item,
                ),
                _buildInventoryTextCell('₱${item.price.toString()}', item),
                _buildInventoryQuantityCell(item),
              ],
            );
          }),
        ],
      ),
    );
  }

  TableCell _buildHeaderCell(String label) {
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: Colors.black,
              fontSize: 15.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  TableCell _buildInventoryTextCell(String text, Inventorymodel item) {
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _openInventoryUpdate(item),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(6.0),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black,
                fontFamily: 'Inter',
                fontSize: 12.0,
              ),
              maxLines: 2,
              softWrap: true,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }

  TableCell _buildInventoryQuantityCell(Inventorymodel item) {
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _openInventoryUpdate(item),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 18.0,
              vertical: 8.0,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF37474F),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(Icons.add_circle, color: Color(0xFF4CAF50)),
                  const SizedBox(width: 6),
                  Text(
                    item.quantity.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Inter',
                      fontSize: 10.0,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.remove_circle, color: Color(0xFFF44336)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  //SUPPLIER HEADER
  Row supplierHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Supplier',
          style: TextStyle(
            fontFamily: 'Inter',
            color: Colors.black,
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(left: 10, right: 10),
            child: SizedBox(
              height: 35,
              child: TextField(
                controller: suppliersearch,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.all(5),
                  hintText: 'Search Supplier',
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
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: SizedBox(
            height: 35,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF822222),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onPressed: () async {
                final bool? refresh = await pushWithSlide<bool?>(
                  context,
                  const AddSupplierScreen(),
                );

                if (refresh == true) {
                  await _loadData();
                }
              },
              child: const Text(
                'Add Supplier',
                style: TextStyle(
                  fontSize: 11.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  //SUPPLIER TABLE METHOD
  Container supplierTable() {
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
          0: FlexColumnWidth(1),
          1: FlexColumnWidth(2),
          2: FlexColumnWidth(2),
          3: FlexColumnWidth(2),
        },
        children: [
          TableRow(
            children: [
              _buildHeaderCell('ID'),
              _buildHeaderCell('Supplier Name'),
              _buildHeaderCell('Contact Number'),
              _buildHeaderCell('Email'),
            ],
          ),
          ...supplier.map((item) {
            return TableRow(
              children: [
                _buildSupplierTextCell(item.id.toString(), item),
                _buildSupplierTextCell(item.supplierName, item),
                _buildSupplierTextCell(
                  item.contactNum?.toString() ?? 'N/A',
                  item,
                ),
                _buildSupplierTextCell(item.email ?? 'N/A', item),
              ],
            );
          }),
        ],
      ),
    );
  }

  TableCell _buildSupplierTextCell(String text, Suppliermodel item) {
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _openSupplierUpdate(item),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(6.0),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black,
                fontFamily: 'Inter',
                fontSize: 12.0,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildViewMoreButton(VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.only(left: 10),
      child: TextButton(
        style: TextButton.styleFrom(
          backgroundColor: const Color(0xFF146533),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onPressed: onPressed,
        child: const Text(
          'View More',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
