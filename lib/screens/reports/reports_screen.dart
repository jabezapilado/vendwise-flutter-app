import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:vendwise/backend/app_repository.dart';
import 'package:vendwise/models/transactionmodel.dart';
import 'package:vendwise/utils/timezone_utils.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    Future<void> showAllTransactions(
      BuildContext ctx,
      List<Transactionmodel> list,
    ) async {
      await showModalBottomSheet(
        context: ctx,
        isScrollControlled: true,
        builder: (_) {
          return DraggableScrollableSheet(
            expand: false,
            maxChildSize: 0.95,
            builder: (context, controller) {
              return ListView.separated(
                controller: controller,
                padding: const EdgeInsets.all(8),
                itemCount: list.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final t = list[index];
                  return ListTile(
                    leading: const Icon(Icons.receipt_long),
                    title: Text(t.customerName),
                    subtitle: Text('${t.itemCount} items • ${t.formattedTime}'),
                    trailing: Text('₱ ${t.totalAmount.toStringAsFixed(2)}'),
                  );
                },
              );
            },
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        backgroundColor: Colors.deepPurple,
      ),
      body: FutureBuilder<List<Transactionmodel>>(
        future: appRepository.fetchTransactions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final transactions = snapshot.data ?? [];
          final now = DateTime.now();
          final todayPH = startOfPhilippineDay(now);
          final todaysTransactions = transactions.where((t) {
            final tPH = startOfPhilippineDay(t.timePurchased);
            return tPH == todayPH;
          }).toList();
          final todaysSales = todaysTransactions.fold<double>(
            0,
            (sum, t) => sum + t.totalAmount,
          );
          final todaysOrders = todaysTransactions.length;

          List<FlSpot> salesTrend = List.generate(7, (i) {
            final day = todayPH.subtract(Duration(days: 6 - i));
            final daySales = transactions
                .where((t) => startOfPhilippineDay(t.timePurchased) == day)
                .fold<double>(0, (sum, t) => sum + t.totalAmount);
            return FlSpot(i.toDouble(), daySales);
          });

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Sales Reports',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('Analyze your business performance'),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      FilterChip(
                        label: const Text('Daily'),
                        selected: true,
                        onSelected: (_) {},
                      ),
                      FilterChip(
                        label: const Text('Weekly'),
                        selected: false,
                        onSelected: (_) {},
                      ),
                      FilterChip(
                        label: const Text('Monthly'),
                        selected: false,
                        onSelected: (_) {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Card(
                          color: Colors.green[50],
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                const Text(
                                  "Today's Sales",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '₱ ${todaysSales.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    color: Colors.green,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Icon(
                                  Icons.show_chart,
                                  color: Colors.green,
                                  size: 32,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Card(
                          color: Colors.red[50],
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                const Text(
                                  'Orders Today',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '$todaysOrders',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    color: Colors.red,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Icon(
                                  Icons.receipt_long,
                                  color: Colors.red,
                                  size: 32,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Sales Trend Analysis - Total Losses',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 200,
                            child: LineChart(
                              LineChartData(
                                gridData: FlGridData(show: true),
                                titlesData: FlTitlesData(
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: true),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        int idx = value.toInt();
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            top: 8.0,
                                          ),
                                          child: Text(
                                            idx >= 0 && idx < days.length
                                                ? days[idx]
                                                : '',
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  rightTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  topTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                ),
                                borderData: FlBorderData(show: true),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: salesTrend,
                                    isCurved: true,
                                    color: Colors.blue,
                                    barWidth: 3,
                                    dotData: FlDotData(show: true),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Recent Transactions',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Column(
                      children: [
                        ...transactions
                            .take(10)
                            .map(
                              (t) => ListTile(
                                leading: const Icon(Icons.person),
                                title: Text(t.customerName),
                                subtitle: Text('${t.itemCount} items'),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '₱ ${t.totalAmount.toStringAsFixed(2)}',
                                    ),
                                    Text(
                                      t.formattedTime,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        if (transactions.length > 10)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () =>
                                  showAllTransactions(context, transactions),
                              child: const Text('View More'),
                            ),
                          ),
                      ],
                    ),
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
