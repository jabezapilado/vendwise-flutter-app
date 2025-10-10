import 'dart:math';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vendwise/backend/app_repository.dart';
import 'package:vendwise/models/inventorymodel.dart';
import 'package:vendwise/screens/settings/account_settings_screen.dart';
import 'package:vendwise/screens/dashboard/dashboard_screen.dart';
import 'package:vendwise/screens/inventory/inventory_screen.dart';
import 'package:vendwise/screens/products/products_screen.dart';
import 'package:vendwise/screens/dashboard/sales_report.dart';
import 'package:vendwise/screens/dashboard/transaction_screen.dart';
import 'package:vendwise/utils/navigation_helpers.dart';
import 'package:vendwise/utils/app_haptics.dart';

/// Identifies the high-level section of the app for navigation purposes.
enum AppSection { dashboard, inventory, products, transactions, reports }

/// Displays a bottom sheet with quick navigation shortcuts.
Future<void> showNavigationSheet(
  BuildContext context,
  AppSection current,
) async {
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) {
      return _NavigationSheet(current: current, rootContext: context);
    },
  );
}

/// Shows a notifications panel backed by live repository data.
Future<void> showNotificationsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) {
      return const SafeArea(child: _NotificationsSheet());
    },
  );
}

/// Opens a bottom sheet with account-related actions.
Future<void> showAccountSheet(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Account',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Account settings'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                pushWithSlide<void>(context, const AccountSettingsScreen());
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign out'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sign out feature is coming soon.'),
                  ),
                );
              },
            ),
          ],
        ),
      );
    },
  );
}

/// Convenience helper to show a short snack bar message.
void showQuickMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

class _NavigationSheet extends StatelessWidget {
  const _NavigationSheet({required this.current, required this.rootContext});

  final AppSection current;
  final BuildContext rootContext;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Quick navigation',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
          _NavigationTile(
            label: 'Dashboard',
            icon: Icons.space_dashboard,
            selected: current == AppSection.dashboard,
            onTap: () => _open(rootContext, context, const DashboardScreen()),
          ),
          _NavigationTile(
            label: 'Inventory',
            icon: Icons.inventory_2,
            selected: current == AppSection.inventory,
            onTap: () => _open(rootContext, context, const InventoryScreen()),
          ),
          _NavigationTile(
            label: 'Products',
            icon: Icons.shopping_cart,
            selected: current == AppSection.products,
            onTap: () => _open(rootContext, context, const ProductsScreen()),
          ),
          _NavigationTile(
            label: 'Transactions',
            icon: Icons.history_edu,
            selected: current == AppSection.transactions,
            onTap: () => _open(rootContext, context, const TransactionScreen()),
          ),
          _NavigationTile(
            label: 'Reports',
            icon: Icons.bar_chart,
            selected: current == AppSection.reports,
            onTap: () => _open(rootContext, context, const SalesReport()),
          ),
        ],
      ),
    );
  }

  void _open(
    BuildContext rootContext,
    BuildContext sheetContext,
    Widget destination,
  ) {
    if (selected(destination)) {
      Navigator.of(sheetContext).pop();
      return;
    }

    Navigator.of(sheetContext).pop();
    pushWithSlide<void>(rootContext, destination);
  }

  bool selected(Widget destination) {
    switch (current) {
      case AppSection.dashboard:
        return destination is DashboardScreen;
      case AppSection.inventory:
        return destination is InventoryScreen;
      case AppSection.products:
        return destination is ProductsScreen;
      case AppSection.transactions:
        return destination is TransactionScreen;
      case AppSection.reports:
        return destination is SalesReport;
    }
  }
}

class _NotificationsSheet extends StatefulWidget {
  const _NotificationsSheet();

  @override
  State<_NotificationsSheet> createState() => _NotificationsSheetState();
}

class _NotificationsSheetState extends State<_NotificationsSheet> {
  List<String> _notifications = const [];
  String? _error;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final payload = await _loadNotifications();
    if (!mounted) return;
    setState(() {
      _notifications = payload.messages;
      _error = payload.error;
      _isLoading = false;
    });
  }

  void _clearAll() {
    AppHaptics.mediumImpact();
    setState(() {
      _notifications = const [];
    });
    showQuickMessage(context, 'Notifications cleared');
  }

  void _dismissAt(int index) {
    AppHaptics.selectionChanged();
    setState(() {
      final updated = List<String>.of(_notifications);
      if (index >= 0 && index < updated.length) {
        updated.removeAt(index);
      }
      _notifications = updated;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 220,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final notifications = _notifications;
    final error = _error;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 420),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Notifications',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
                if (notifications.isNotEmpty)
                  TextButton.icon(
                    onPressed: _clearAll,
                    icon: const Icon(Icons.clear_all, size: 18),
                    label: const Text('Clear all'),
                  ),
              ],
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        error,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        AppHaptics.selectionChanged();
                        _refresh();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            if (notifications.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    'You are all caught up!',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              )
            else
              Flexible(
                fit: FlexFit.loose,
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: notifications.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final message = notifications[index];
                      return Dismissible(
                        key: ValueKey('${message.hashCode}-$index'),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) => _dismissAt(index),
                        background: Container(
                          color: Colors.red.withValues(alpha: 0.1),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const Icon(Icons.delete, color: Colors.red),
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.notifications),
                          title: Text(
                            message,
                            style: const TextStyle(fontSize: 14),
                          ),
                          trailing: IconButton(
                            tooltip: 'Dismiss',
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () => _dismissAt(index),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NotificationPayload {
  const _NotificationPayload({required this.messages, required this.error});

  final List<String> messages;
  final String? error;
}

Future<_NotificationPayload> _loadNotifications() async {
  try {
    final inventory = await appRepository.fetchInventory();
    final transactions = await appRepository.fetchTransactions();
    final now = DateTime.now();
    final messages = <String>[];

    messages.addAll(_buildLowStockAlerts(inventory));

    final todaysTransactions = transactions.where((txn) {
      final startOfDay = DateTime(now.year, now.month, now.day);
      return !txn.timePurchased.isBefore(startOfDay);
    });

    if (todaysTransactions.isNotEmpty) {
      final totalSales = todaysTransactions.fold<int>(
        0,
        (sum, txn) => sum + txn.totalAmount,
      );
      final formatter = NumberFormat.currency(symbol: '₱', decimalDigits: 2);
      messages.add(
        '${todaysTransactions.length} '
        'transaction${todaysTransactions.length == 1 ? '' : 's'} '
        'logged today totaling ${formatter.format(totalSales)}.',
      );
    }

    final recentRestocks = inventory.where((item) {
      final timestamp = item.updatedAt ?? item.createdAt;
      if (timestamp == null) {
        return false;
      }
      return now.difference(timestamp).inHours <= 24;
    }).toList();

    if (recentRestocks.isNotEmpty) {
      final sample = recentRestocks.first.productName;
      final remaining = recentRestocks.length - 1;
      final tail = remaining > 0
          ? ' and $remaining other item${remaining > 1 ? 's' : ''}'
          : '';
      messages.add('Recently updated stock: $sample$tail in the last 24h.');
    }

    return _NotificationPayload(messages: messages, error: null);
  } catch (error, stackTrace) {
    developer.log(
      'Failed to load notifications',
      name: 'NotificationsSheet',
      error: error,
      stackTrace: stackTrace,
    );
    return _NotificationPayload(
      messages: const <String>[],
      error:
          'Unable to load notifications. Check your connection and try again.',
    );
  }
}

Iterable<String> _buildLowStockAlerts(List<Inventorymodel> inventory) {
  if (inventory.isEmpty) {
    return const <String>[];
  }

  final totalQuantity = inventory.fold<int>(
    0,
    (sum, item) => sum + item.quantity,
  );
  final averageQuantity = totalQuantity / inventory.length;
  final dynamicThreshold = max(5, (averageQuantity * 0.2).round());

  final lowStockItems =
      inventory.where((item) => item.quantity <= dynamicThreshold).toList()
        ..sort((a, b) => a.quantity.compareTo(b.quantity));

  if (lowStockItems.isEmpty) {
    return const <String>[];
  }

  return lowStockItems.take(5).map((item) {
    final unitsLabel = item.quantity == 1 ? 'unit' : 'units';
    final supplier = item.supplierName != null && item.supplierName!.isNotEmpty
        ? ' (${item.supplierName})'
        : '';
    return 'Low stock: ${item.productName}$supplier has '
        '${item.quantity} $unitsLabel remaining.';
  });
}

class _NavigationTile extends StatelessWidget {
  const _NavigationTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: selected ? const Icon(Icons.check, color: Colors.green) : null,
      onTap: selected ? null : onTap,
    );
  }
}
