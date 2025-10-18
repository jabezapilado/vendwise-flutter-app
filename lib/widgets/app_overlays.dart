import 'dart:math';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vendwise/backend/app_repository.dart';
import 'package:vendwise/backend/bootstrap.dart';
import 'package:vendwise/models/app_user.dart';
import 'package:vendwise/models/inventorymodel.dart';
import 'package:vendwise/screens/auth/login_screen.dart';
import 'package:vendwise/screens/settings/account_settings_screen.dart';
import 'package:vendwise/screens/dashboard/dashboard_screen.dart';
import 'package:vendwise/screens/inventory/inventory_screen.dart';
import 'package:vendwise/screens/products/products_screen.dart';
import 'package:vendwise/screens/dashboard/sales_report.dart';
import 'package:vendwise/screens/dashboard/transaction_screen.dart';
import 'package:vendwise/services/app_session.dart';
import 'package:vendwise/utils/app_haptics.dart';
import 'package:vendwise/utils/navigation_helpers.dart';
import 'package:vendwise/utils/timezone_utils.dart';

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
                signOutAndReturnToLogin(context);
              },
            ),
          ],
        ),
      );
    },
  );
}

Future<void> signOutAndReturnToLogin(BuildContext context) async {
  AppHaptics.mediumImpact();
  final navigator = Navigator.of(context);
  final prefs = await SharedPreferences.getInstance();
  final remember = prefs.getBool('login_remember_me') ?? false;
  if (!remember) {
    await prefs.setBool('login_remember_me', false);
    await prefs.remove('login_username');
    await prefs.remove('login_password');
  }

  await AppSession.instance.clearUser();

  if (supabaseRepositoryActive) {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {
      // Ignore sign-out failures; the user will still return to the login screen.
    }
  }

  if (!navigator.mounted) {
    return;
  }
  navigator.pushAndRemoveUntil(
    MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
    (route) => false,
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
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: ValueListenableBuilder<AppUser?>(
              valueListenable: AppSession.instance.currentUser,
              builder: (_, __, ___) {
                return Text(
                  AppSession.instance.greeting(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
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
  List<_NotificationItem> _notifications = const [];
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
    // Persist clearing by marking all current notifications as dismissed.
    () async {
      final ids = <String>{};
      ids.addAll(_notifications.map((n) => n.id));
      final existing = await _loadDismissedIds();
      final merged = existing..addAll(ids);
      await _persistDismissedIds(merged);
      if (!mounted) return;
      setState(() {
        _notifications = const [];
      });
      showQuickMessage(context, 'Notifications cleared');
    }();
  }

  Future<void> _dismissAt(int index) async {
    AppHaptics.selectionChanged();
    if (index < 0 || index >= _notifications.length) return;
    final removed = _notifications[index];
    try {
      final existing = await _loadDismissedIds();
      final merged = existing..add(removed.id);
      await _persistDismissedIds(merged);
    } catch (_) {
      // Ignore persistence failures; still remove from UI optimistically.
    }
    if (!mounted) return;
    setState(() {
      final updated = List<_NotificationItem>.of(_notifications)
        ..removeAt(index);
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
                      final item = notifications[index];
                      return Dismissible(
                        key: ValueKey(item.id),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) async => await _dismissAt(index),
                        background: Container(
                          color: Colors.red.withValues(alpha: 0.1),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const Icon(Icons.delete, color: Colors.red),
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.notifications),
                          title: Text(
                            item.message,
                            style: const TextStyle(fontSize: 14),
                          ),
                          trailing: IconButton(
                            tooltip: 'Dismiss',
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () async => await _dismissAt(index),
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

class _NotificationItem {
  const _NotificationItem({required this.id, required this.message});

  final String id;
  final String message;
}

class _NotificationPayload {
  const _NotificationPayload({required this.messages, required this.error});

  final List<_NotificationItem> messages;
  final String? error;
}

const String _dismissedNotificationsKey = 'dismissed_notifications_v1';

String _computeId(String message) {
  // Stable identifier for a notification based on its content.
  // Use hashCode + length to reduce accidental collisions across runs.
  return '${message.hashCode}_${message.length}';
}

Future<Set<String>> _loadDismissedIds() async {
  final prefs = await SharedPreferences.getInstance();
  final list = prefs.getStringList(_dismissedNotificationsKey) ?? <String>[];
  return list.toSet();
}

Future<void> _persistDismissedIds(Set<String> ids) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setStringList(_dismissedNotificationsKey, ids.toList());
}

Future<_NotificationPayload> _loadNotifications() async {
  try {
    final inventory = await appRepository.fetchInventory();
    final transactions = await appRepository.fetchTransactions();
    // additional sources for notifications
    final products = await appRepository.fetchProducts();
    final suppliers = await appRepository.fetchSuppliers();
    final users = await appRepository.fetchAppUsers();
    final now = DateTime.now();
    final startOfDay = startOfPhilippineDay(now);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final todaysTransactions = transactions.where((txn) {
      final timestamp = toPhilippineTime(txn.timePurchased);
      return !timestamp.isBefore(startOfDay) && timestamp.isBefore(endOfDay);
    }).toList();
    final nowPhilippines = toPhilippineTime(now);
    final messages = <_NotificationItem>[];

    // Inventory summary message (In stock, Low stock, Out of stock, To expire, Expired)
    const lowStockThreshold = 25;
    const toExpireDays = 10;

    final expiredCount = inventory.where((inv) {
      final expiry = inv.expiryDate;
      if (expiry == null) return false;
      return toPhilippineTime(expiry).isBefore(nowPhilippines);
    }).length;

    final outOfStockCount = inventory.where((inv) => inv.quantity <= 0).length;

    final toExpireCount = inventory.where((inv) {
      final expiry = inv.expiryDate;
      if (expiry == null) return false;
      final e = toPhilippineTime(expiry);
      return !e.isBefore(nowPhilippines) &&
          e.isBefore(nowPhilippines.add(Duration(days: toExpireDays)));
    }).length;

    final lowStockCount = inventory.where((inv) {
      final qty = inv.quantity;
      return qty > 0 && qty <= lowStockThreshold;
    }).length;

    final inStockCount = inventory.where((inv) {
      final qty = inv.quantity;
      final expiry = inv.expiryDate;
      final expired =
          expiry != null && toPhilippineTime(expiry).isBefore(nowPhilippines);
      return qty > 0 && !expired;
    }).length;

    messages.add(
      _NotificationItem(
        id: _computeId(
          'inventory_summary|$inStockCount|$lowStockCount|$outOfStockCount|$toExpireCount|$expiredCount',
        ),
        message:
            'Inventory: $inStockCount in stock • $lowStockCount low • $outOfStockCount out • $toExpireCount to expire • $expiredCount expired',
      ),
    );

    // Per-item alerts (use stable ids where possible so dismissals persist)
    messages.addAll(_buildLowStockItems(inventory));
    messages.addAll(_buildOutOfStockItems(inventory));
    messages.addAll(_buildToExpireItems(inventory, nowPhilippines, 10));
    messages.addAll(_buildExpiredItems(inventory, nowPhilippines));

    // Recent product and supplier activity
    messages.addAll(_buildRecentProductItems(products, nowPhilippines));
    messages.addAll(_buildRecentSupplierItems(suppliers, nowPhilippines));

    // Recent app user changes (new accounts or updates)
    messages.addAll(_buildUserAccountItems(users, nowPhilippines));

    if (todaysTransactions.isNotEmpty) {
      final totalSales = todaysTransactions.fold<double>(
        0,
        (sum, txn) => sum + txn.totalAmount,
      );
      final formatter = NumberFormat.currency(symbol: '₱', decimalDigits: 2);
      messages.add(
        _NotificationItem(
          id: _computeId(
            'transactions_summary|${todaysTransactions.length}|${totalSales.toStringAsFixed(2)}',
          ),
          message:
              '${todaysTransactions.length} '
              'transaction${todaysTransactions.length == 1 ? '' : 's'} '
              'logged today totaling ${formatter.format(totalSales)}.',
        ),
      );
    }

    final recentRestocks = inventory.where((item) {
      final timestamp = item.updatedAt ?? item.createdAt;
      if (timestamp == null) {
        return false;
      }
      final restockTime = toPhilippineTime(timestamp);
      return nowPhilippines.difference(restockTime).inHours <= 24;
    }).toList();

    if (recentRestocks.isNotEmpty) {
      final sample = recentRestocks.first.productName;
      final remaining = recentRestocks.length - 1;
      final tail = remaining > 0
          ? ' and $remaining other item${remaining > 1 ? 's' : ''}'
          : '';
      final msg = 'Recently updated stock: $sample$tail in the last 24h.';
      messages.add(_NotificationItem(id: _computeId(msg), message: msg));
    }

    // Filter out dismissed notification ids (persisted in SharedPreferences).
    try {
      final dismissed = await _loadDismissedIds();
      final filtered = messages
          .where((m) => !dismissed.contains(m.id))
          .toList();
      return _NotificationPayload(messages: filtered, error: null);
    } catch (_) {
      return _NotificationPayload(messages: messages, error: null);
    }
  } catch (error, stackTrace) {
    developer.log(
      'Failed to load notifications',
      name: 'NotificationsSheet',
      error: error,
      stackTrace: stackTrace,
    );
    return _NotificationPayload(
      messages: const <_NotificationItem>[],
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

Iterable<String> _buildOutOfStockAlerts(List<Inventorymodel> inventory) {
  if (inventory.isEmpty) return const <String>[];

  final outOfStock = inventory.where((item) => item.quantity <= 0).toList()
    ..sort((a, b) => a.productName.compareTo(b.productName));

  if (outOfStock.isEmpty) return const <String>[];

  return outOfStock.take(5).map((item) {
    final supplier = item.supplierName != null && item.supplierName!.isNotEmpty
        ? ' (${item.supplierName})'
        : '';
    return 'Out of stock: ${item.productName}$supplier — please restock.';
  });
}

Iterable<String> _buildToExpireAlerts(
  List<Inventorymodel> inventory,
  DateTime now,
  int days,
) {
  if (inventory.isEmpty) return const <String>[];

  final threshold = now.add(Duration(days: days));
  final toExpire = inventory.where((item) {
    final expiry = item.expiryDate;
    if (expiry == null) return false;
    final e = toPhilippineTime(expiry);
    return !e.isBefore(now) && e.isBefore(threshold);
  }).toList()..sort((a, b) => a.expiryDate!.compareTo(b.expiryDate!));

  if (toExpire.isEmpty) return const <String>[];

  return toExpire.take(5).map((item) {
    final daysLeft = toPhilippineTime(item.expiryDate!).difference(now).inDays;
    final supplier = item.supplierName != null && item.supplierName!.isNotEmpty
        ? ' (${item.supplierName})'
        : '';
    return 'Expiring soon: ${item.productName}$supplier expires in $daysLeft day${daysLeft == 1 ? '' : 's'}.';
  });
}

Iterable<String> _buildExpiredAlerts(
  List<Inventorymodel> inventory,
  DateTime now,
) {
  if (inventory.isEmpty) return const <String>[];

  final expired =
      inventory.where((item) {
        final expiry = item.expiryDate;
        if (expiry == null) return false;
        return toPhilippineTime(expiry).isBefore(now);
      }).toList()..sort(
        (a, b) => toPhilippineTime(
          a.expiryDate!,
        ).compareTo(toPhilippineTime(b.expiryDate!)),
      );

  if (expired.isEmpty) return const <String>[];

  return expired.take(5).map((item) {
    final supplier = item.supplierName != null && item.supplierName!.isNotEmpty
        ? ' (${item.supplierName})'
        : '';
    return 'Expired: ${item.productName}$supplier has expired — remove or mark as unsellable.';
  });
}

Iterable<String> _buildRecentProductAlerts(
  List<dynamic> products,
  DateTime now,
) {
  if (products.isEmpty) return const <String>[];

  final recent = products.where((p) {
    final created = (p as dynamic).createdAt as DateTime?;
    final updated = (p as dynamic).updatedAt as DateTime?;
    if (created != null &&
        toPhilippineTime(created).difference(now).inHours.abs() <= 24) {
      return true;
    }
    if (updated != null &&
        toPhilippineTime(updated).difference(now).inHours.abs() <= 24) {
      return true;
    }
    return false;
  }).toList();

  if (recent.isEmpty) return const <String>[];

  return recent.take(5).map((p) {
    final name = (p as dynamic).productName as String? ?? 'Product';
    return 'Product updated: $name changed in the last 24h.';
  });
}

Iterable<String> _buildRecentSupplierAlerts(
  List<dynamic> suppliers,
  DateTime now,
) {
  if (suppliers.isEmpty) return const <String>[];

  final recent = suppliers.where((s) {
    final created = (s as dynamic).createdAt as DateTime?;
    final updated = (s as dynamic).updatedAt as DateTime?;
    if (created != null &&
        toPhilippineTime(created).difference(now).inHours.abs() <= 24) {
      return true;
    }
    if (updated != null &&
        toPhilippineTime(updated).difference(now).inHours.abs() <= 24) {
      return true;
    }
    return false;
  }).toList();

  if (recent.isEmpty) return const <String>[];

  return recent.take(5).map((s) {
    final dyn = s as dynamic;
    final seq = (dyn.supplierSeq as int?) != null
        ? (dyn.supplierSeq as int)
        : null;
    final name = dyn.supplierName as String? ?? 'Supplier';
    final label = seq != null ? '$seq • $name' : name;
    return 'Supplier updated: $label changed in the last 24h.';
  });
}

Iterable<String> _buildUserAccountAlerts(List<AppUser> users, DateTime now) {
  if (users.isEmpty) return const <String>[];

  final recent = users.where((u) {
    final created = u.createdAt;
    final updated = u.updatedAt;
    if (created != null &&
        toPhilippineTime(created).difference(now).inHours.abs() <= 24) {
      return true;
    }
    if (updated != null &&
        toPhilippineTime(updated).difference(now).inHours.abs() <= 24) {
      return true;
    }
    return false;
  }).toList();

  if (recent.isEmpty) return const <String>[];

  return recent.take(5).map((u) {
    final who = u.fullName ?? u.username;
    return 'Account activity: $who was created/updated in the last 24h.';
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

// --- Per-entity notification builders (stable ids) -----------------------

List<_NotificationItem> _buildLowStockItems(List<Inventorymodel> inventory) {
  final items = <_NotificationItem>[];
  for (final item in _buildLowStockAlerts(inventory)) {
    // Try to extract product id from the message if present, otherwise fall back to message hash
    // Our Inventorymodel has an `id` and `productName` so prefer entity-based id when possible
    final matching = inventory.firstWhere(
      (inv) => item.contains(inv.productName),
      orElse: () =>
          Inventorymodel(id: '', productName: '', price: 0, quantity: 0),
    );
    final id = matching.id.isNotEmpty
        ? 'lowstock:${matching.id}'
        : _computeId(item);
    items.add(_NotificationItem(id: id, message: item));
  }
  return items;
}

List<_NotificationItem> _buildOutOfStockItems(List<Inventorymodel> inventory) {
  return _buildOutOfStockAlerts(inventory).map((m) {
    final matching = inventory.firstWhere(
      (inv) => m.contains(inv.productName),
      orElse: () =>
          Inventorymodel(id: '', productName: '', price: 0, quantity: 0),
    );
    final id = matching.id.isNotEmpty
        ? 'outofstock:${matching.id}'
        : _computeId(m);
    return _NotificationItem(id: id, message: m);
  }).toList();
}

List<_NotificationItem> _buildToExpireItems(
  List<Inventorymodel> inventory,
  DateTime now,
  int days,
) {
  return _buildToExpireAlerts(inventory, now, days).map((m) {
    final matching = inventory.firstWhere(
      (inv) => m.contains(inv.productName),
      orElse: () =>
          Inventorymodel(id: '', productName: '', price: 0, quantity: 0),
    );
    final id = matching.id.isNotEmpty
        ? 'toexpire:${matching.id}'
        : _computeId(m);
    return _NotificationItem(id: id, message: m);
  }).toList();
}

List<_NotificationItem> _buildExpiredItems(
  List<Inventorymodel> inventory,
  DateTime now,
) {
  return _buildExpiredAlerts(inventory, now).map((m) {
    final matching = inventory.firstWhere(
      (inv) => m.contains(inv.productName),
      orElse: () =>
          Inventorymodel(id: '', productName: '', price: 0, quantity: 0),
    );
    final id = matching.id.isNotEmpty
        ? 'expired:${matching.id}'
        : _computeId(m);
    return _NotificationItem(id: id, message: m);
  }).toList();
}

List<_NotificationItem> _buildRecentProductItems(
  List<dynamic> products,
  DateTime now,
) {
  return _buildRecentProductAlerts(products, now).map((m) {
    // attempt to extract product name and match a product id if present
    final nameMatch = RegExp(r'Product updated: (.+) changed').firstMatch(m);
    final name = nameMatch?.group(1);
    final id = name != null ? 'product:${name.toLowerCase()}' : _computeId(m);
    return _NotificationItem(id: id, message: m);
  }).toList();
}

List<_NotificationItem> _buildRecentSupplierItems(
  List<dynamic> suppliers,
  DateTime now,
) {
  return _buildRecentSupplierAlerts(suppliers, now).map((m) {
    final nameMatch = RegExp(r'Supplier updated: (.+) changed').firstMatch(m);
    final name = nameMatch?.group(1);
    final id = name != null ? 'supplier:${name.toLowerCase()}' : _computeId(m);
    return _NotificationItem(id: id, message: m);
  }).toList();
}

List<_NotificationItem> _buildUserAccountItems(
  List<AppUser> users,
  DateTime now,
) {
  return _buildUserAccountAlerts(users, now).map((m) {
    final whoMatch = RegExp(r'Account activity: (.+) was').firstMatch(m);
    final who = whoMatch?.group(1);
    final id = who != null ? 'user:${who.toLowerCase()}' : _computeId(m);
    return _NotificationItem(id: id, message: m);
  }).toList();
}
