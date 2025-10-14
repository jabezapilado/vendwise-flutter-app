import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vendwise/backend/app_repository.dart';
import 'package:vendwise/models/transactionmodel.dart';
import 'package:vendwise/screens/dashboard/dashboard_screen.dart';
import 'package:vendwise/screens/inventory/inventory_screen.dart';
import 'package:vendwise/screens/products/products_screen.dart';
import 'package:vendwise/screens/dashboard/transaction_screen.dart';
import 'package:vendwise/utils/app_haptics.dart';
import 'package:vendwise/utils/navigation_helpers.dart';
import 'package:vendwise/widgets/app_overlays.dart';

class SalesReport extends StatefulWidget {
  const SalesReport({super.key});

  @override
  State<SalesReport> createState() => _SalesReportState();
}

enum _ReportRange { daily, weekly, monthly }

class _SalesReportState extends State<SalesReport> {
  final int _selectedIndex = 4;
  List<Transactionmodel> _allTransactions = [];
  List<Transactionmodel> _filteredTransactions = [];
  bool _isLoading = false;
  double _totalSales = 0;
  int _totalItemsSold = 0;
  _ReportRange _selectedRange = _ReportRange.daily;
  List<DateTime> _chartBuckets = const [];
  List<double> _chartValues = const [];
  final NumberFormat _currencyFormatter = NumberFormat.currency(
    symbol: '₱',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
    });

    final fetchedTransactions = await appRepository.fetchTransactions();

    if (!mounted) return;

    setState(() {
      _allTransactions = fetchedTransactions;
    });
    _applyFilters(range: _selectedRange);
  }

  void _applyFilters({required _ReportRange range}) {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    DateTime start;
    DateTime end;

    switch (range) {
      case _ReportRange.daily:
        start = startOfToday;
        end = startOfToday.add(const Duration(days: 1));
        break;
      case _ReportRange.weekly:
        start = startOfToday.subtract(const Duration(days: 6));
        end = startOfToday.add(const Duration(days: 1));
        break;
      case _ReportRange.monthly:
        start = DateTime(now.year, now.month, 1);
        end = DateTime(now.year, now.month + 1, 1);
        break;
    }

    final filtered = _allTransactions.where((txn) {
      final timestamp = txn.timePurchased;
      return !timestamp.isBefore(start) && timestamp.isBefore(end);
    }).toList()..sort((a, b) => b.timePurchased.compareTo(a.timePurchased));

    final buckets = <DateTime, double>{};
    for (final txn in filtered) {
      final time = txn.timePurchased;
      final bucket = range == _ReportRange.daily
          ? DateTime(time.year, time.month, time.day, time.hour)
          : DateTime(time.year, time.month, time.day);
      buckets[bucket] = (buckets[bucket] ?? 0) + txn.totalAmount;
    }

    final sortedBuckets = buckets.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    if (!mounted) return;
    setState(() {
      _selectedRange = range;
      _filteredTransactions = filtered;
      _totalSales = filtered.fold<double>(
        0,
        (total, txn) => total + txn.totalAmount,
      );
      _totalItemsSold = filtered.fold<int>(
        0,
        (total, txn) => total + txn.itemCount,
      );
      _chartBuckets = sortedBuckets.map((entry) => entry.key).toList();
      _chartValues = sortedBuckets.map((entry) => entry.value).toList();
      _isLoading = false;
    });
  }

  void _onRangeSelected(_ReportRange range) {
    AppHaptics.selectionChanged();
    if (range == _selectedRange) {
      return;
    }
    _applyFilters(range: range);
  }

  String _rangeLabel() {
    switch (_selectedRange) {
      case _ReportRange.daily:
        return "Today's";
      case _ReportRange.weekly:
        return 'This Week\'s';
      case _ReportRange.monthly:
        return 'This Month\'s';
    }
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) {
      AppHaptics.selectionChanged();
      return;
    }

    AppHaptics.selectionChanged();
    if (index == 0) {
      pushWithSlide<void>(context, const DashboardScreen());
    } else if (index == 1) {
      pushWithSlide<void>(context, const InventoryScreen());
    } else if (index == 2) {
      pushWithSlide<void>(context, const ProductsScreen());
    } else if (index == 3) {
      pushWithSlide<void>(context, const TransactionScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget bodyContent = _isLoading && _filteredTransactions.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GestureDetector(
                    onTap: () {
                      AppHaptics.selectionChanged();
                      pushWithSlide<void>(context, const DashboardScreen());
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.arrow_back_ios_new,
                          color: Color(0xFFADADAD),
                          size: 20,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Back',
                          style: TextStyle(
                            color: Color(0xFFADADAD),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Overview',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Analyze your business performance',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: Colors.black,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _buildFilterButtons(context),
                const SizedBox(height: 16),
                _buildMetrics(context),
                const SizedBox(height: 16),
                Center(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.9,
                    child: chart(),
                  ),
                ),
                const SizedBox(height: 24),
                _buildRecentTransactionsHeader(),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.9,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: transactionTable(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );

    return Scaffold(
      appBar: appbar(),
      backgroundColor: const Color(0xFFFFFFFF),
      body: RefreshIndicator(
        onRefresh: _loadTransactions,
        child: bodyContent is SingleChildScrollView
            ? bodyContent
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: bodyContent,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildFilterButtons(BuildContext context) {
    final width = MediaQuery.of(context).size.width * 0.9;
    return Center(
      child: Container(
        width: width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.black, width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Row(
            children: [
              _buildRangeButton(
                label: 'Daily',
                range: _ReportRange.daily,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  bottomLeft: Radius.circular(10),
                ),
              ),
              _buildRangeDivider(),
              _buildRangeButton(label: 'Weekly', range: _ReportRange.weekly),
              _buildRangeDivider(),
              _buildRangeButton(
                label: 'Monthly',
                range: _ReportRange.monthly,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRangeButton({
    required String label,
    required _ReportRange range,
    BorderRadius borderRadius = BorderRadius.zero,
  }) {
    final selected = _selectedRange == range;
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE5E5E5) : Colors.white,
          borderRadius: borderRadius,
        ),
        child: TextButton(
          onPressed: () => _onRangeSelected(range),
          style: TextButton.styleFrom(
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: borderRadius),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              color: selected ? Colors.black54 : Colors.black,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRangeDivider() {
    return Container(width: 1, height: double.infinity, color: Colors.black);
  }

  Widget _buildMetrics(BuildContext context) {
    final rangeLabel = _rangeLabel();
    final averageOrder = _filteredTransactions.isEmpty
        ? 0
        : _totalSales / _filteredTransactions.length;
    return Center(
      child: Column(
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: _buildMetricCard(
              title: '$rangeLabel Sales',
              value: _currencyFormatter.format(_totalSales),
              assetPath: 'assets/icons/bargrowth.png',
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: _buildMetricCard(
              title: '$rangeLabel Orders',
              value: _totalItemsSold.toString(),
              assetPath: 'assets/icons/checklist.png',
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: _buildMetricCard(
              title: '$rangeLabel Avg. Order',
              value: _currencyFormatter.format(averageOrder),
              assetPath: 'assets/icons/alarm.png',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String assetPath,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Image.asset(assetPath, width: 40, height: 40, fit: BoxFit.contain),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactionsHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Recent Transaction',
            style: TextStyle(
              fontFamily: 'Inter',
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextButton(
            onPressed: () {},
            child: const Text(
              'View More',
              style: TextStyle(
                fontFamily: 'Inter',
                color: Color(0xFFB4AAAA),
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  AppBar appbar() {
    return AppBar(
      leading: IconButton(
        onPressed: () {},
        icon: const Icon(Icons.menu, color: Colors.white),
      ),
      title: const Text(
        'Reports',
        style: TextStyle(
          fontFamily: 'Inter',
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {
            AppHaptics.selectionChanged();
            showNotificationsSheet(context);
          },
          icon: const Icon(Icons.notifications, color: Colors.white),
        ),
        IconButton(
          onPressed: () {
            AppHaptics.selectionChanged();
          },
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
        padding: const EdgeInsets.all(5),
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

  Widget transactionTable() {
    if (_filteredTransactions.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 1),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: const Center(
          child: Text(
            'No transactions recorded yet.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

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
          0: FlexColumnWidth(3),
          1: FlexColumnWidth(2),
          2: FlexColumnWidth(2),
          3: FlexColumnWidth(2),
        },
        children: [
          const TableRow(
            children: [
              _TableHeaderCell(label: 'Customer'),
              _TableHeaderCell(label: 'Items'),
              _TableHeaderCell(label: 'Total'),
              _TableHeaderCell(label: 'Time'),
            ],
          ),
          ...List.generate(_filteredTransactions.length, (index) {
            final txn = _filteredTransactions[index];
            return TableRow(
              children: [
                _TableDataCell(value: txn.customerName),
                _TableDataCell(value: txn.itemCount.toString()),
                _TableDataCell(
                  value: _currencyFormatter.format(txn.totalAmount),
                ),
                _TableDataCell(value: txn.formattedTime),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget chart() {
    final spots = _buildChartSpots();
    final hasData = _chartValues.isNotEmpty;
    final maxY = spots.fold<double>(0, (currentMax, spot) {
      if (spot.y > currentMax) return spot.y;
      return currentMax;
    });
    final adjustedMaxY = maxY == 0 ? 10.0 : maxY * 1.2;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'Sales Trend Analysis',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                Icon(Icons.open_in_new, size: 15, color: Colors.grey),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: hasData
                  ? LineChart(
                      LineChartData(
                        minY: 0,
                        maxY: adjustedMaxY,
                        titlesData: FlTitlesData(
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              interval: adjustedMaxY / 4,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  value.toStringAsFixed(0),
                                  style: const TextStyle(fontSize: 10),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 1,
                              getTitlesWidget: (value, meta) {
                                final label = _chartLabel(value.toInt());
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    label,
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: true),
                        gridData: FlGridData(show: true),
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: true,
                            color: Colors.blue,
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: FlDotData(show: true),
                          ),
                        ],
                      ),
                    )
                  : const Center(
                      child: Text(
                        'No sales recorded in this range yet.',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _buildChartSpots() {
    if (_chartValues.isEmpty) {
      return const [FlSpot(0, 0)];
    }

    return List<FlSpot>.generate(
      _chartValues.length,
      (index) => FlSpot(index.toDouble(), _chartValues[index]),
    );
  }

  String _chartLabel(int index) {
    if (index < 0 || index >= _chartBuckets.length) {
      return '';
    }

    final date = _chartBuckets[index];
    if (_selectedRange == _ReportRange.daily) {
      return DateFormat('h a').format(date);
    }
    return DateFormat('M/d').format(date);
  }
}

class _TableHeaderCell extends StatelessWidget {
  const _TableHeaderCell({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: Colors.black,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class _TableDataCell extends StatelessWidget {
  const _TableDataCell({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black,
              fontFamily: 'Inter',
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
