import 'dart:io';
import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:vendwise/backend/app_repository.dart';
import 'package:vendwise/models/inventorymodel.dart';
import 'package:vendwise/models/transactionmodel.dart';
import 'package:vendwise/utils/timezone_utils.dart';
import 'package:vendwise/widgets/app_navigation_drawer.dart';
import 'package:vendwise/widgets/app_overlays.dart';
import 'package:vendwise/widgets/primary_app_bar.dart';
import 'package:vendwise/screens/inventory/inventory_screen.dart';
import 'package:vendwise/utils/navigation_helpers.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Transactionmodel> transaction = [];
  List<Inventorymodel> inventory = [];
  bool _isLoading = false;
  double _todaySales = 0;
  int _ordersToday = 0;
  bool _offlineDialogShown = false;

  @override
  void initState() {
    super.initState();
    // Load data first, then run connectivity checks on success only. If the
    // initial data load fails (for example during an auth handoff after
    // password reset), skip the connectivity check to avoid a false offline
    // dialog.
    _loadData()
        .then((_) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _checkConnectivityAndNotify();
          });
        })
        .catchError((error) {
          // Intentionally ignore: connectivity check is deferred because the
          // app likely encountered an auth or backend error which should surface
          // as an auth error instead of an offline dialog.
        });
  }

  Future<void> _checkConnectivityAndNotify() async {
    // Check the platform connectivity first
    final dynamic connectivityResultRaw = await Connectivity()
        .checkConnectivity();
    bool hasNetworkInterface = false;
    if (connectivityResultRaw is ConnectivityResult) {
      hasNetworkInterface = connectivityResultRaw != ConnectivityResult.none;
    } else if (connectivityResultRaw is List<ConnectivityResult>) {
      hasNetworkInterface = connectivityResultRaw.any(
        (ConnectivityResult r) => r != ConnectivityResult.none,
      );
    } else {
      // Fallback: assume there is a network interface and rely on DNS tests
      hasNetworkInterface = true;
    }

    // Perform a defensive internet lookup with retries/timeouts so we don't
    // surface a false "No Internet" message immediately after navigation or
    // transient DNS hiccups.
    final bool hasInternet = hasNetworkInterface && await _hasInternetAccess();

    if (!hasInternet && mounted && !_offlineDialogShown) {
      // brief delay then re-check once to avoid flapping caused by quick
      // transient failures that often happen around navigation/auth flows.
      await Future.delayed(const Duration(milliseconds: 500));
      final bool recheck = await _hasInternetAccess();
      if (!recheck) {
        _offlineDialogShown = true;
        _showOfflineDialog();
      }
    }
  }

  Future<bool> _hasInternetAccess() async {
    // Try a couple of well-known hosts with a short timeout. Some networks
    // block specific hosts, so try a small list before concluding we're
    // offline.
    const hosts = ['example.com', 'google.com'];
    for (final host in hosts) {
      try {
        final lookupResult = await InternetAddress.lookup(
          host,
        ).timeout(const Duration(seconds: 3));
        if (lookupResult.isNotEmpty &&
            lookupResult.first.rawAddress.isNotEmpty) {
          return true;
        }
      } on SocketException {
        // try next host
      } on TimeoutException {
        // try next host
      } catch (_) {
        // ignore and try next
      }
    }
    return false;
  }

  void _showOfflineDialog() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('No Internet Connection'),
          content: const Text(
            'Some features may be unavailable until you reconnect to the internet.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final fetchedInventory = await appRepository.fetchInventory();
    final fetchedTransactions = await appRepository.fetchTransactions();

    if (!mounted) return;

    final now = DateTime.now();
    final startOfDay = startOfPhilippineDay(now);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final todaysTransactions = fetchedTransactions.where((txn) {
      final timestamp = toPhilippineTime(txn.timePurchased);
      return !timestamp.isBefore(startOfDay) && timestamp.isBefore(endOfDay);
    }).toList();

    setState(() {
      inventory = fetchedInventory;
      transaction = fetchedTransactions;
      _todaySales = todaysTransactions.fold<double>(
        0,
        (sum, item) => sum + item.totalAmount,
      );
      _ordersToday = todaysTransactions.fold<int>(
        0,
        (sum, item) => sum + item.itemCount,
      );
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bodyContent = _isLoading && transaction.isEmpty && inventory.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
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
                  margin: const EdgeInsets.symmetric(
                    vertical: 0,
                    horizontal: 25.0,
                  ),
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Today's Sales",
                                        style: TextStyle(
                                          fontStyle: FontStyle.italic,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '₱${_todaySales.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Image.asset(
                                    'assets/icons/bargrowth.png',
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Orders Today",
                                        style: TextStyle(
                                          fontStyle: FontStyle.italic,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _ordersToday.toString(),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Image.asset(
                                    'assets/icons/checklist.png',
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
                        onPressed: _showTransactionsBottomSheet,
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
          );

    return Scaffold(
      appBar: const PrimaryAppBar(
        title: 'Dashboard',
        section: AppSection.dashboard,
      ),
      drawer: AppNavigationDrawer(
        current: AppSection.dashboard,
        rootContext: context,
      ),
      backgroundColor: Color(0xFFFFFFFF),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: bodyContent is SingleChildScrollView
            ? bodyContent
            : ListView(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.5,
                    child: bodyContent,
                  ),
                ],
              ),
      ),
    );
  }

  void _showTransactionsBottomSheet() {
    if (transaction.isEmpty) {
      showQuickMessage(context, 'No transactions recorded yet.');
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
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: transaction.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, index) {
              final txn = transaction[index];
              final name = txn.customerName.isEmpty
                  ? 'Walk-in customer'
                  : txn.customerName;
              return ListTile(
                leading: const Icon(Icons.receipt_long),
                title: Text(name),
                subtitle: Text(
                  '${txn.itemCount} items • ₱${txn.totalAmount.toStringAsFixed(2)}',
                ),
                trailing: Text(txn.formattedTime),
              );
            },
          ),
        );
      },
    );
  }

  SizedBox inventorySummary(BuildContext context) {
    // Compute inventory summary counts using Philippine time and requested thresholds
    final nowPhilippine = toPhilippineTime(DateTime.now());
    // Thresholds
    const lowStockThreshold = 25;
    const toExpireDays = 10;

    final expiredCount = inventory.where((inv) {
      final expiry = inv.expiryDate;
      if (expiry == null) return false;
      final e = toPhilippineTime(expiry);
      return e.isBefore(nowPhilippine);
    }).length;

    final outOfStockCount = inventory.where((inv) => inv.quantity <= 0).length;

    final toExpireCount = inventory.where((inv) {
      final expiry = inv.expiryDate;
      if (expiry == null) return false;
      final e = toPhilippineTime(expiry);
      return !e.isBefore(nowPhilippine) &&
          e.isBefore(nowPhilippine.add(Duration(days: toExpireDays)));
    }).length;

    final lowStockCount = inventory.where((inv) {
      final qty = inv.quantity;
      return qty > 0 && qty <= lowStockThreshold;
    }).length;

    final inStockCount = inventory.where((inv) {
      final qty = inv.quantity;
      final expiry = inv.expiryDate;
      final expired =
          expiry != null && toPhilippineTime(expiry).isBefore(nowPhilippine);
      return qty > 0 && !expired;
    }).length;

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
                  GestureDetector(
                    onTap: () => pushWithSlide<void>(
                      context,
                      const InventoryScreen(initialFilter: InventoryFilter.all),
                    ),
                    child: _buildSummaryColumn(
                      Icons.inventory,
                      inStockCount.toString(),
                      'In stock',
                    ),
                  ),
                  // single Low stock column (the tappable one follows)
                  GestureDetector(
                    onTap: () => pushWithSlide<void>(
                      context,
                      const InventoryScreen(
                        initialFilter: InventoryFilter.lowStock,
                      ),
                    ),
                    child: _buildSummaryColumn(
                      Icons.inventory,
                      lowStockCount.toString(),
                      'Low stock',
                    ),
                  ),
                  GestureDetector(
                    onTap: () => pushWithSlide<void>(
                      context,
                      const InventoryScreen(
                        initialFilter: InventoryFilter.outOfStock,
                      ),
                    ),
                    child: _buildSummaryColumn(
                      Icons.inventory,
                      outOfStockCount.toString(),
                      'Out of stock',
                    ),
                  ),
                  GestureDetector(
                    onTap: () => pushWithSlide<void>(
                      context,
                      const InventoryScreen(
                        initialFilter: InventoryFilter.toExpire,
                      ),
                    ),
                    child: _buildSummaryColumn(
                      Icons.inventory,
                      toExpireCount.toString(),
                      'To expire',
                    ),
                  ),
                  GestureDetector(
                    onTap: () => pushWithSlide<void>(
                      context,
                      const InventoryScreen(
                        initialFilter: InventoryFilter.expired,
                      ),
                    ),
                    child: _buildSummaryColumn(
                      Icons.inventory,
                      expiredCount.toString(),
                      'Expired',
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

  // small helper to keep the summary row compact
  Widget _buildSummaryColumn(IconData icon, String count, String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, right: 2),
      child: Column(
        children: [
          Icon(icon, color: Colors.black, size: 30),
          const SizedBox(height: 4),
          Text(
            count,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
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
          ...transaction
              .take(10)
              .map(
                (txn) => TableRow(
                  children: [
                    TableCell(
                      verticalAlignment: TableCellVerticalAlignment.middle,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            txn.customerName,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
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
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            txn.itemCount.toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
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
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            "₱${txn.totalAmount.toStringAsFixed(2)} ",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
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
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            txn.formattedTime,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
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
