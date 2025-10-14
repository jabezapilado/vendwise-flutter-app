import 'package:flutter/material.dart';
import 'package:vendwise/screens/dashboard/dashboard_screen.dart';
import 'package:vendwise/screens/dashboard/sales_report.dart';
import 'package:vendwise/screens/dashboard/transaction_screen.dart';
import 'package:vendwise/screens/inventory/inventory_screen.dart';
import 'package:vendwise/screens/products/products_screen.dart';
import 'package:vendwise/utils/app_haptics.dart';
import 'package:vendwise/utils/navigation_helpers.dart';
import 'package:vendwise/widgets/app_overlays.dart';

class AppNavigationDrawer extends StatelessWidget {
  const AppNavigationDrawer({
    super.key,
    required this.current,
    required this.rootContext,
  });

  final AppSection current;
  final BuildContext rootContext;

  @override
  Widget build(BuildContext context) {
    final items = <_DrawerItem>[
      _DrawerItem(
        section: AppSection.dashboard,
        icon: Icons.space_dashboard,
        label: 'Dashboard',
        destinationBuilder: () => const DashboardScreen(),
      ),
      _DrawerItem(
        section: AppSection.inventory,
        icon: Icons.inventory_2,
        label: 'Inventory',
        destinationBuilder: () => const InventoryScreen(),
      ),
      _DrawerItem(
        section: AppSection.products,
        icon: Icons.shopping_cart,
        label: 'Products',
        destinationBuilder: () => const ProductsScreen(),
      ),
      _DrawerItem(
        section: AppSection.transactions,
        icon: Icons.history_edu,
        label: 'Transactions',
        destinationBuilder: () => const TransactionScreen(),
      ),
      _DrawerItem(
        section: AppSection.reports,
        icon: Icons.bar_chart,
        label: 'Reports',
        destinationBuilder: () => const SalesReport(),
      ),
    ];

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _DrawerHeader(),
            Expanded(
              child: ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final selected = item.section == current;
                  return ListTile(
                    leading: Icon(
                      item.icon,
                      color: selected ? const Color(0xFFD74848) : null,
                    ),
                    title: Text(
                      item.label,
                      style: TextStyle(
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.normal,
                        color: selected ? const Color(0xFFD74848) : null,
                      ),
                    ),
                    selected: selected,
                    onTap: () {
                      if (selected) {
                        Navigator.of(context).pop();
                        return;
                      }
                      AppHaptics.selectionChanged();
                      Navigator.of(context).pop();
                      pushWithSlide<void>(
                        rootContext,
                        item.destinationBuilder(),
                      );
                    },
                  );
                },
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.account_circle_outlined),
              title: const Text('Account settings'),
              onTap: () {
                Navigator.of(context).pop();
                showAccountSheet(rootContext);
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign out'),
              onTap: () {
                Navigator.of(context).pop();
                signOutAndReturnToLogin(rootContext);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem {
  const _DrawerItem({
    required this.section,
    required this.icon,
    required this.label,
    required this.destinationBuilder,
  });

  final AppSection section;
  final IconData icon;
  final String label;
  final Widget Function() destinationBuilder;
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader();

  @override
  Widget build(BuildContext context) {
    return DrawerHeader(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFD74848), Color(0xFF111C51)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: const [
          Text(
            'Vendwise',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Quick navigation',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}
