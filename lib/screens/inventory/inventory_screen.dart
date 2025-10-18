import 'dart:async';
import 'dart:convert';

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
import 'package:vendwise/utils/timezone_utils.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'dart:io';

enum InventoryFilter { all, lowStock, outOfStock, toExpire, expired }

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({
    super.key,
    this.initialFilter = InventoryFilter.all,
    this.repository,
    this.initialOnline,
  });

  final InventoryFilter initialFilter;
  // Optional repository for testing/injection. Falls back to global `appRepository`.
  final AppRepository? repository;
  // Optional initial online state for tests.
  final bool? initialOnline;

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final TextEditingController productsearch = TextEditingController();
  final TextEditingController suppliersearch = TextEditingController();
  List<Inventorymodel> inventory = [];
  List<Suppliermodel> supplier = [];
  final Set<String> _updating = <String>{};
  bool _isLoading = false;
  late bool _isOnline;
  late InventoryFilter _activeFilter;
  // repeating removed: no long-press repeat behavior
  final List<Map<String, dynamic>> _pendingUpdates = [];
  final List<Map<String, dynamic>> _failedUpdates = [];
  final Map<String, int> _attempts = {};
  final List<Map<String, dynamic>> _auditLog = [];
  // queued count for UI
  int get _queuedCount => _pendingUpdates.length;
  Timer? _retryTimer;
  StreamSubscription<dynamic>? _connectivitySub;
  // Separate sort state for product and supplier tables so their
  // sorting controls don't interfere with each other.
  String? _productSortColumn;
  bool _productSortAscending = true;

  String? _supplierSortColumn;
  bool _supplierSortAscending = true;

  List<Inventorymodel> get _filteredInventory {
    final now = toPhilippineTime(DateTime.now());
    const lowStockThreshold = 25;
    const toExpireDays = 10;

    Iterable<Inventorymodel> list = inventory;

    switch (_activeFilter) {
      case InventoryFilter.lowStock:
        list = list.where(
          (inv) => inv.quantity > 0 && inv.quantity <= lowStockThreshold,
        );
        break;
      case InventoryFilter.outOfStock:
        list = list.where((inv) => inv.quantity <= 0);
        break;
      case InventoryFilter.toExpire:
        list = list.where((inv) {
          final expiry = inv.expiryDate;
          if (expiry == null) return false;
          final e = toPhilippineTime(expiry);
          return !e.isBefore(now) &&
              e.isBefore(now.add(Duration(days: toExpireDays)));
        });
        break;
      case InventoryFilter.expired:
        list = list.where(
          (inv) =>
              inv.expiryDate != null &&
              toPhilippineTime(inv.expiryDate!).isBefore(now),
        );
        break;
      case InventoryFilter.all:
        break;
    }

    final query = productsearch.text.trim();
    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      list = list.where(
        (inv) =>
            inv.productName.toLowerCase().contains(q) ||
            (inv.supplierName ?? '').toLowerCase().contains(q),
      );
    }

    return list.toList();
  }

  List<Suppliermodel> get _filteredSuppliers {
    final query = suppliersearch.text.trim();
    if (query.isEmpty) return supplier;
    final q = query.toLowerCase();
    return supplier
        .where(
          (s) =>
              s.supplierName.toLowerCase().contains(q) ||
              (s.email ?? '').toLowerCase().contains(q) ||
              (s.contactNum?.toString() ?? '').contains(q),
        )
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _isOnline = widget.initialOnline ?? true;
    _activeFilter = widget.initialFilter;
    _subscribeConnectivity();
    // make searches dynamic: update UI as user types
    productsearch.addListener(() {
      setState(() {});
    });
    suppliersearch.addListener(() {
      setState(() {});
    });

    _loadPendingUpdates().then((_) => _loadData());
  }

  @override
  void dispose() {
    productsearch.dispose();
    suppliersearch.dispose();
    // no repeat timers to cancel (long-press repeat removed)
    _connectivitySub?.cancel();
    _retryTimer?.cancel();
    super.dispose();
  }

  void _subscribeConnectivity() async {
    try {
      final raw = await Connectivity().checkConnectivity();
      final resolved = _toConnectivityResult(raw);
      _updateConnectivity(resolved);
    } catch (_) {}

    _connectivitySub = Connectivity().onConnectivityChanged.listen((raw) {
      final resolved = _toConnectivityResult(raw);
      _updateConnectivity(resolved);
    });
  }

  AppRepository get _repo => widget.repository ?? appRepository;

  ConnectivityResult _toConnectivityResult(dynamic raw) {
    if (raw is ConnectivityResult) return raw;
    if (raw is List && raw.isNotEmpty && raw.first is ConnectivityResult) {
      return raw.first as ConnectivityResult;
    }
    return ConnectivityResult.none;
  }

  void _updateConnectivity(ConnectivityResult result) {
    final nowOnline = result != ConnectivityResult.none;
    if (_isOnline == nowOnline) return;
    setState(() {
      _isOnline = nowOnline;
    });
    if (_isOnline) {
      // try processing any queued updates immediately
      _processQueue();
    }
  }

  Duration _computeBackoffDelay() {
    // compute max attempts for pending entries
    var maxAttempts = 0;
    for (final e in _pendingUpdates) {
      final key = '${e['id']}::${e['quantity']}';
      final a = _attempts[key] ?? 0;
      if (a > maxAttempts) maxAttempts = a;
    }
    if (maxAttempts <= 0) return const Duration(seconds: 5);
    // exponential backoff: 5s * 2^(attempts-1), capped at 60s
    final secsNum = (5 * (1 << (maxAttempts - 1))).clamp(5, 60);
    final secs = secsNum.toInt();
    return Duration(seconds: secs);
  }

  void _scheduleRetryTimer() {
    _retryTimer?.cancel();
    if (_pendingUpdates.isEmpty) {
      _retryTimer = null;
      return;
    }
    final delay = _computeBackoffDelay();
    _retryTimer = Timer(delay, () async {
      if (!_isOnline) return;
      await _processQueue();
    });
  }

  Future<void> _processQueue() async {
    if (_pendingUpdates.isEmpty) {
      _retryTimer?.cancel();
      _retryTimer = null;
      return;
    }

    // attempt to flush queued updates sequentially
    final pending = List<Map<String, dynamic>>.from(_pendingUpdates);
    for (final entry in pending) {
      final id = entry['id'] as String;
      final qty = entry['quantity'] as int;
      final key = '$id::$qty';
      try {
        final updated = await _repo.updateInventoryQuantity(id, qty);
        if (!mounted) return;
        setState(() {
          final idx = inventory.indexWhere((i) => i.id == id);
          if (idx != -1) inventory[idx] = updated;
          _pendingUpdates.removeWhere(
            (e) => e['id'] == id && e['quantity'] == qty,
          );
          // audit success
          _auditLog.add({
            'id': id,
            'quantity': qty,
            'status': 'committed',
            'timestamp': DateTime.now().toIso8601String(),
          });
          _savePendingUpdates();
          // clear attempts for successful entry
          _attempts.remove(key);
        });
      } catch (_) {
        // increment attempt count and move to failed if too many attempts
        final a = (_attempts[key] ?? 0) + 1;
        _attempts[key] = a;
        if (a >= 3) {
          if (!mounted) return;
          setState(() {
            _pendingUpdates.removeWhere(
              (e) => e['id'] == id && e['quantity'] == qty,
            );
            _failedUpdates.add({'id': id, 'quantity': qty, 'attempts': a});
            _auditLog.add({
              'id': id,
              'quantity': qty,
              'status': 'failed',
              'attempts': a,
              'timestamp': DateTime.now().toIso8601String(),
            });
            _savePendingUpdates();
          });
        }
      }
    }
    if (_pendingUpdates.isEmpty) {
      _retryTimer?.cancel();
      _retryTimer = null;
    }
  }

  Future<void> _manualRetry() async {
    try {
      final raw = await Connectivity().checkConnectivity();
      final resolved = _toConnectivityResult(raw);
      _updateConnectivity(resolved);
      if (_isOnline) await _processQueue();
    } catch (_) {}
  }

  void _showUndoSnackbar(String id, int quantity) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Queued update for $quantity saved'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              _pendingUpdates.removeWhere(
                (e) => e['id'] == id && e['quantity'] == quantity,
              );
              _auditLog.add({
                'id': id,
                'quantity': quantity,
                'status': 'undo',
                'timestamp': DateTime.now().toIso8601String(),
              });
              _savePendingUpdates();
            });
          },
        ),
      ),
    );
  }

  Future<void> _showFailedUpdatesDialog() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Failed queued updates'),
          content: SizedBox(
            width: double.maxFinite,
            child: _failedUpdates.isEmpty
                ? const Text('No failed queued updates.')
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _failedUpdates.length,
                    itemBuilder: (_, i) {
                      final e = _failedUpdates[i];
                      return ListTile(
                        title: Text('ID: ${e['id'] ?? ''}'),
                        subtitle: Text(
                          'Qty: ${e['quantity'] ?? ''} • Attempts: ${e['attempts'] ?? ''}',
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadPendingUpdates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('pending_inventory_updates');
      if (raw == null || raw.isEmpty) return;
      final list = jsonDecode(raw) as List<dynamic>;
      _pendingUpdates.clear();
      for (final item in list) {
        if (item is Map) {
          _pendingUpdates.add(Map<String, dynamic>.from(item));
        } else if (item is Map<String, dynamic>) {
          _pendingUpdates.add(item);
        }
      }
      // load failed updates
      final rawFailed = prefs.getString('failed_inventory_updates');
      if (rawFailed != null && rawFailed.isNotEmpty) {
        final list2 = jsonDecode(rawFailed) as List<dynamic>;
        _failedUpdates.clear();
        for (final item in list2) {
          if (item is Map) _failedUpdates.add(Map<String, dynamic>.from(item));
        }
      }
      // load audit log
      final rawAudit = prefs.getString('inventory_update_audit');
      if (rawAudit != null && rawAudit.isNotEmpty) {
        final a = jsonDecode(rawAudit) as List<dynamic>;
        _auditLog.clear();
        for (final item in a) {
          if (item is Map) _auditLog.add(Map<String, dynamic>.from(item));
        }
      }
      // attempt immediate flush if online
      if (_isOnline) {
        await _processQueue();
      }
    } catch (_) {
      // ignore errors and continue
    }
  }

  Future<void> _savePendingUpdates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode(_pendingUpdates);
      await prefs.setString('pending_inventory_updates', raw);
      // also persist failed and audit
      final rawFailed = jsonEncode(_failedUpdates);
      await prefs.setString('failed_inventory_updates', rawFailed);
      final rawAudit = jsonEncode(_auditLog);
      await prefs.setString('inventory_update_audit', rawAudit);
    } catch (_) {
      // ignore errors
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final fetchedInventory = await appRepository.fetchInventory();
      final fetchedSuppliers = await appRepository.fetchSuppliers();

      if (!mounted) return;

      setState(() {
        inventory = fetchedInventory;
        supplier = fetchedSuppliers;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PrimaryAppBar(
        title: 'Inventory',
        section: AppSection.inventory,
        trailingActions: [
          IconButton(
            tooltip: 'Audit',
            icon: const Icon(Icons.history, color: Colors.white),
            onPressed: _showAuditDialog,
          ),
        ],
      ),
      drawer: AppNavigationDrawer(
        current: AppSection.inventory,
        rootContext: context,
      ),
      backgroundColor: const Color(0xFFFFFFFF),
      body: Column(
        children: [
          if (!_isOnline)
            Material(
              color: const Color(0xFFFFF3E0),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 8.0,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.cloud_off, color: Color(0xFFBF360C)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Offline — $_queuedCount update${_queuedCount == 1 ? '' : 's'} queued',
                        style: const TextStyle(color: Color(0xFFBF360C)),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        await _manualRetry();
                      },
                      child: const Text('Retry'),
                    ),
                    if (_failedUpdates.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: _showFailedUpdatesDialog,
                        child: Text('Failed (${_failedUpdates.length})'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              child: _buildScrollableBody(),
            ),
          ),
        ],
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

  void _showInventoryBottomSheet() {
    final list = _filteredInventory;
    if (list.isEmpty) {
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
            itemCount: list.length,
            itemBuilder: (_, index) {
              final item = list[index];
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

  Future<void> _showAuditDialog() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Inventory Audit Log'),
          content: SizedBox(
            width: double.maxFinite,
            child: _auditLog.isEmpty
                ? const Text('No audit entries recorded.')
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _auditLog.length,
                    itemBuilder: (_, idx) {
                      final e = _auditLog[idx];
                      return ListTile(
                        title: Text('${e['status'] ?? ''} - ${e['id'] ?? ''}'),
                        subtitle: Text(
                          'Qty: ${e['quantity'] ?? ''} • ${e['timestamp'] ?? ''}',
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                await _exportAudit();
              },
              child: const Text('Export'),
            ),
            TextButton(
              onPressed: () async {
                // Use the sheet's context only to show the confirmation dialog.
                final confirm = await showDialog<bool?>(
                  context: ctx,
                  builder: (c) => AlertDialog(
                    title: const Text('Clear audit log?'),
                    content: const Text(
                      'This will permanently delete the local audit log.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(c).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(c).pop(true),
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                );

                // After awaiting, ensure the state is still mounted before using
                // the State's context to dismiss the sheet and perform actions.
                if (confirm == true && mounted) {
                  Navigator.of(context).pop();
                  await _clearAudit();
                }
              },
              child: const Text('Clear'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _exportAudit() async {
    try {
      final jsonStr = jsonEncode(_auditLog);
      // copy to clipboard
      await Clipboard.setData(ClipboardData(text: jsonStr));

      // write to app documents directory as a timestamped file
      final dir = await getApplicationDocumentsDirectory();
      final file = File(
        '${dir.path}/inventory_audit_${DateTime.now().toIso8601String().replaceAll(':', '-')}.json',
      );
      await file.writeAsString(jsonStr);
      if (!mounted) return;
      _showSnackbar('Audit exported to ${file.path} and copied to clipboard');
    } catch (e) {
      _showSnackbar('Failed to export audit: ${e.toString()}');
    }
  }

  Future<void> _clearAudit() async {
    setState(() {
      _auditLog.clear();
    });
    await _savePendingUpdates();
    _showSnackbar('Audit log cleared');
  }

  void _showSupplierBottomSheet() {
    final list = _filteredSuppliers;
    if (list.isEmpty) {
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
            itemCount: list.length,
            itemBuilder: (_, index) {
              final item = list[index];
              return ListTile(
                leading: const Icon(Icons.store),
                title: Text(
                  item.supplierSeq != null
                      ? '${item.supplierSeq} • ${item.supplierName}'
                      : item.supplierName,
                ),
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

  // PRODUCT HEADER
  Widget productHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Text(
              'Product',
              style: TextStyle(
                fontFamily: "Inter",
                color: Colors.black,
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 35,
                child: TextField(
                  controller: productsearch,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.all(5),
                    hintText: 'Search Product',
                    hintStyle: const TextStyle(
                      color: Color.fromARGB(255, 173, 172, 172),
                    ),
                    suffixIcon: productsearch.text.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(4.0),
                            child: Icon(Icons.search),
                          )
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => productsearch.clear(),
                          ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
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
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text(
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
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  //PRODUCT TABLE METHOD
  Container productTable() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 1),
        // match backup rounding
        borderRadius: BorderRadius.circular(10),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showExpiry = constraints.maxWidth >= 640;
          // Adjusted spacing: give product more room and shift supplier/price to the right
          final Map<int, TableColumnWidth> cw = showExpiry
              ? const {
                  0: FlexColumnWidth(3), // product (wider)
                  1: FlexColumnWidth(2), // supplier
                  2: FlexColumnWidth(1), // price (compact)
                  3: FlexColumnWidth(1), // expiry
                  4: FlexColumnWidth(2), // quantity
                }
              : const {
                  0: FlexColumnWidth(3), // product (wider)
                  1: FlexColumnWidth(2), // supplier
                  2: FlexColumnWidth(2), // price
                  3: FlexColumnWidth(2), // quantity (roomiest)
                };

          // Fixed header + scrollable body pattern
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header row (fixed)
              Table(
                columnWidths: cw,
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: [
                  TableRow(
                    children: [
                      _buildHeaderCell(
                        'Products',
                        columnKey: 'product',
                        onSort: (k, n) => _sortProductByColumn(k, n),
                        activeSortColumn: _productSortColumn,
                        sortAscending: _productSortAscending,
                      ),
                      _buildHeaderCell(
                        'Supplier',
                        columnKey: 'supplier',
                        onSort: (k, n) => _sortProductByColumn(k, n),
                        activeSortColumn: _productSortColumn,
                        sortAscending: _productSortAscending,
                      ),
                      _buildHeaderCell(
                        'Price',
                        columnKey: 'price',
                        numeric: true,
                        onSort: (k, n) => _sortProductByColumn(k, n),
                        activeSortColumn: _productSortColumn,
                        sortAscending: _productSortAscending,
                      ),
                      if (showExpiry)
                        _buildHeaderCell(
                          'Expiry',
                          columnKey: 'expiry',
                          onSort: (k, n) => _sortProductByColumn(k, n),
                          activeSortColumn: _productSortColumn,
                          sortAscending: _productSortAscending,
                        ),
                      _buildHeaderCell(
                        'Quantity',
                        columnKey: 'quantity',
                        numeric: true,
                        onSort: (k, n) => _sortProductByColumn(k, n),
                        activeSortColumn: _productSortColumn,
                        sortAscending: _productSortAscending,
                      ),
                    ],
                  ),
                ],
              ),
              // Divider between header and body
              const Divider(height: 0, thickness: 1, color: Colors.black),
              // Scrollable body
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: SingleChildScrollView(
                  child: Table(
                    border: TableBorder(
                      horizontalInside: const BorderSide(
                        color: Colors.black,
                        width: 1,
                      ),
                    ),
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    columnWidths: cw,
                    children: _filteredInventory.asMap().entries.map((entry) {
                      final item = entry.value;
                      return TableRow(
                        children: [
                          _buildInventoryTextCell(
                            item.productName,
                            item,
                            onTap: () => _openInventoryUpdate(item),
                            tappableStyle: false,
                          ),
                          _buildInventoryTextCell(
                            item.supplierName ?? 'Unknown Supplier',
                            item,
                          ),
                          _buildInventoryTextCell(
                            '₱${item.price.toString()}',
                            item,
                          ),
                          if (showExpiry) _buildInventoryExpiryCell(item),
                          _buildInventoryQuantityCell(item),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  TableCell _buildInventoryExpiryCell(Inventorymodel item) {
    final expiry = item.expiryDate;
    final now = toPhilippineTime(DateTime.now());
    const toExpireDays = 10;

    Widget content;
    if (expiry == null) {
      content = const Center(
        child: Padding(
          padding: EdgeInsets.all(6.0),
          child: Text('-', textAlign: TextAlign.center),
        ),
      );
    } else {
      final e = toPhilippineTime(expiry);
      final expired = e.isBefore(now);
      final toExpire =
          !expired && e.isBefore(now.add(Duration(days: toExpireDays)));
      final text =
          '${e.day.toString().padLeft(2, '0')}/${e.month.toString().padLeft(2, '0')}/${e.year}';

      if (expired) {
        content = Center(
          child: Padding(
            padding: const EdgeInsets.all(6.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFCDD2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Expired',
                style: TextStyle(
                  color: Color(0xFFD32F2F),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      } else if (toExpire) {
        content = Center(
          child: Padding(
            padding: const EdgeInsets.all(6.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF9C4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Expiring\nsoon',
                style: const TextStyle(
                  color: Color(0xFFF57F17),
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      } else {
        content = Center(
          child: Padding(
            padding: const EdgeInsets.all(6.0),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Inter'),
            ),
          ),
        );
      }
    }

    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: content,
    );
  }

  // expiry column removed from product table per design decision; helper removed

  TableCell _buildHeaderCell(
    String label, {
    String? columnKey,
    bool numeric = false,
    void Function(String, bool)? onSort,
    String? activeSortColumn,
    bool? sortAscending,
  }) {
    // Header: simplified layout without sort arrow icon to match design
    final content = Center(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          label,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: 'Inter',
            color: Colors.black,
            fontSize: 15.0,
            fontWeight: FontWeight.bold,
            decoration: null,
          ),
        ),
      ),
    );

    if (columnKey != null) {
      return TableCell(
        verticalAlignment: TableCellVerticalAlignment.middle,
        child: InkWell(
          onTap: () {
            if (onSort != null) {
              onSort(columnKey, numeric);
            } else {
              _sortByColumn(columnKey, numeric: numeric);
            }
          },
          child: content,
        ),
      );
    }

    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: content,
    );
  }

  void _sortByColumn(String columnKey, {bool numeric = false}) {
    // Legacy: product table sorting should be done by _sortProductByColumn.
    _sortProductByColumn(columnKey, numeric);
  }

  void _sortProductByColumn(String columnKey, bool numeric) {
    setState(() {
      if (_productSortColumn == columnKey) {
        _productSortAscending = !_productSortAscending;
      } else {
        _productSortColumn = columnKey;
        _productSortAscending = numeric ? true : true;
      }

      inventory.sort((a, b) {
        int cmp = 0;
        switch (columnKey) {
          case 'product':
            cmp = (a.productName).compareTo(b.productName);
            break;
          case 'supplier':
            cmp = (a.supplierName ?? '').compareTo(b.supplierName ?? '');
            break;
          case 'price':
            cmp = a.price.compareTo(b.price);
            break;
          case 'expiry':
            final aDate = a.expiryDate ?? DateTime(9999);
            final bDate = b.expiryDate ?? DateTime(9999);
            cmp = aDate.compareTo(bDate);
            break;
          case 'quantity':
            cmp = a.quantity.compareTo(b.quantity);
            break;
          default:
            cmp = 0;
        }
        return _productSortAscending ? cmp : -cmp;
      });
    });
  }

  void _sortSupplierByColumn(String columnKey, bool numeric) {
    setState(() {
      if (_supplierSortColumn == columnKey) {
        _supplierSortAscending = !_supplierSortAscending;
      } else {
        _supplierSortColumn = columnKey;
        _supplierSortAscending = numeric ? true : true;
      }

      supplier.sort((a, b) {
        int cmp = 0;
        switch (columnKey) {
          case 'id':
            // Prefer sorting by supplierSeq (DB-provided numeric sequence) when available.
            if (a.supplierSeq != null && b.supplierSeq != null) {
              cmp = a.supplierSeq!.compareTo(b.supplierSeq!);
            } else {
              // Fallback: if IDs look numeric compare numerically, otherwise string compare
              final aNum = int.tryParse(a.id);
              final bNum = int.tryParse(b.id);
              if (aNum != null && bNum != null) {
                cmp = aNum.compareTo(bNum);
              } else {
                cmp = (a.id).compareTo(b.id);
              }
            }
            break;
          case 'supplier':
            cmp = (a.supplierName).compareTo(b.supplierName);
            break;
          case 'contact':
            cmp = (a.contactNum ?? 0).compareTo(b.contactNum ?? 0);
            break;
          case 'email':
            cmp = (a.email ?? '').compareTo(b.email ?? '');
            break;
          default:
            cmp = 0;
        }
        return _supplierSortAscending ? cmp : -cmp;
      });
    });
  }

  TableCell _buildInventoryTextCell(
    String text,
    Inventorymodel item, {
    VoidCallback? onTap,
    bool tappableStyle = false,
  }) {
    final content = Center(
      child: Padding(
        // tightened body cell padding to better match reference spacing
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Inter',
            color: tappableStyle ? Colors.blue : Colors.black,
            fontSize: 12.0,
            decoration: tappableStyle ? TextDecoration.underline : null,
          ),
          maxLines: 2,
          softWrap: true,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );

    if (onTap != null) {
      return TableCell(
        verticalAlignment: TableCellVerticalAlignment.middle,
        child: InkWell(onTap: onTap, child: content),
      );
    }

    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: content,
    );
  }

  TableCell _buildInventoryQuantityCell(Inventorymodel item) {
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: Center(
        child: Padding(
          // even tighter pill layout: fixed small height to match Figma
          padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 2.0),
          child: Container(
            height: 28,
            // minimal internal padding to minimize pill width
            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
            decoration: BoxDecoration(
              color: const Color(0xFF37474F),
              // smaller radius to reduce pill footprint
              borderRadius: BorderRadius.circular(10),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Decrement with long press repeat
                  GestureDetector(
                    onTap: _updating.contains(item.id)
                        ? null
                        : () {
                            if (!_isOnline) {
                              _pendingUpdates.add({
                                'id': item.id,
                                'quantity': (item.quantity - 1).clamp(
                                  0,
                                  1 << 31,
                                ),
                              });
                              _savePendingUpdates();
                              _showUndoSnackbar(
                                item.id,
                                (item.quantity - 1).clamp(0, 1 << 31),
                              );
                              _scheduleRetryTimer();
                              _showSnackbar('You are offline — update queued');
                              return;
                            }
                            _changeQuantity(item, -1);
                          },
                    child: Padding(
                      // minimal padding while keeping icon tappable
                      padding: const EdgeInsets.all(2.0),
                      child: Icon(
                        Icons.remove_circle,
                        size: 14,
                        color: const Color(0xFFF44336),
                      ),
                    ),
                  ),

                  const SizedBox(width: 4),

                  // Quantity or loading
                  _updating.contains(item.id)
                      ? const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          item.quantity.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'Inter',
                            fontSize: 11.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                  const SizedBox(width: 4),

                  // Increment with long press repeat
                  GestureDetector(
                    onTap: _updating.contains(item.id)
                        ? null
                        : () {
                            if (!_isOnline) {
                              _pendingUpdates.add({
                                'id': item.id,
                                'quantity': (item.quantity + 1),
                              });
                              _savePendingUpdates();
                              _auditLog.add({
                                'id': item.id,
                                'quantity': (item.quantity + 1),
                                'status': 'queued',
                                'timestamp': DateTime.now().toIso8601String(),
                              });
                              _showUndoSnackbar(item.id, (item.quantity + 1));
                              _scheduleRetryTimer();
                              _showSnackbar('You are offline — update queued');
                              return;
                            }
                            _changeQuantity(item, 1);
                          },
                    child: Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: Icon(
                        Icons.add_circle,
                        size: 14,
                        color: const Color(0xFF4CAF50),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // long-press repeating removed; no helper functions remain

  Future<void> _changeQuantity(Inventorymodel item, int delta) async {
    final previousIndex = inventory.indexWhere((i) => i.id == item.id);
    if (previousIndex == -1) return;

    final previous = inventory[previousIndex];
    int newQty = previous.quantity + delta;
    if (newQty < 0) newQty = 0;

    // Optimistic update
    final optimistic = previous.copyWith(quantity: newQty);
    setState(() {
      inventory[previousIndex] = optimistic;
      _updating.add(item.id);
    });

    try {
      if (!_isOnline) {
        // queue the update for later
        _pendingUpdates.add({'id': item.id, 'quantity': newQty});
        _savePendingUpdates();
        _auditLog.add({
          'id': item.id,
          'quantity': newQty,
          'status': 'queued',
          'timestamp': DateTime.now().toIso8601String(),
        });
        _showUndoSnackbar(item.id, newQty);
        _scheduleRetryTimer();
        if (!mounted) return;
        setState(() {
          _updating.remove(item.id);
        });
        _showSnackbar('You are offline — update queued');
        return;
      }

      final updated = await _repo.updateInventoryQuantity(item.id, newQty);
      if (!mounted) return;
      setState(() {
        // replace with authoritative value from backend
        final idx = inventory.indexWhere((i) => i.id == item.id);
        if (idx != -1) inventory[idx] = updated;
        _updating.remove(item.id);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        // revert
        final idx = inventory.indexWhere((i) => i.id == item.id);
        if (idx != -1) inventory[idx] = previous;
        _updating.remove(item.id);
      });
      _showSnackbar('Failed to update quantity: ${e.toString()}');
    }
  }

  //SUPPLIER HEADER
  Row supplierHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
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
                  suffixIcon: suppliersearch.text.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Icon(Icons.search),
                        )
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => suppliersearch.clear(),
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
              _buildHeaderCell(
                'ID',
                columnKey: 'id',
                numeric: true,
                onSort: (k, n) => _sortSupplierByColumn(k, n),
                activeSortColumn: _supplierSortColumn,
                sortAscending: _supplierSortAscending,
              ),
              _buildHeaderCell(
                'Supplier Name',
                columnKey: 'supplier',
                onSort: (k, n) => _sortSupplierByColumn(k, n),
                activeSortColumn: _supplierSortColumn,
                sortAscending: _supplierSortAscending,
              ),
              _buildHeaderCell(
                'Contact Number',
                columnKey: 'contact',
                numeric: true,
                onSort: (k, n) => _sortSupplierByColumn(k, n),
                activeSortColumn: _supplierSortColumn,
                sortAscending: _supplierSortAscending,
              ),
              _buildHeaderCell(
                'Email',
                columnKey: 'email',
                onSort: (k, n) => _sortSupplierByColumn(k, n),
                activeSortColumn: _supplierSortColumn,
                sortAscending: _supplierSortAscending,
              ),
            ],
          ),
          ..._filteredSuppliers.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            // display sequential numeric id starting from 1
            return TableRow(
              children: [
                // Only the ID cell should be tappable to open the supplier update
                // show a sequential 1-based index (based on the current
                // filtered/sorted supplier list) so the ID column behaves like
                // an ordinal row number in the UI. This makes it stable and
                // intuitive for users even after sorting/filtering.
                _buildSupplierTextCell(
                  (item.supplierSeq ?? (idx + 1)).toString(),
                  item,
                  tappableId: true,
                ),
                _buildSupplierTextCell(
                  item.supplierName,
                  item,
                  tappableId: false,
                ),
                _buildSupplierTextCell(
                  item.contactNum?.toString() ?? 'N/A',
                  item,
                  tappableId: false,
                ),
                _buildSupplierTextCell(
                  item.email ?? 'N/A',
                  item,
                  tappableId: false,
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  TableCell _buildSupplierTextCell(
    String text,
    Suppliermodel item, {
    bool tappableId = false,
  }) {
    // If this cell is the ID column and tappableId is true, make it interactive.
    final child = Center(
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 56, maxWidth: 240),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black,
              fontFamily: 'Inter',
              fontSize: 12.0,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );

    if (tappableId) {
      return TableCell(
        verticalAlignment: TableCellVerticalAlignment.middle,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _openSupplierUpdate(item),
          child: child,
        ),
      );
    }

    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: child,
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
