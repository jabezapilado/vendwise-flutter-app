import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vendwise/widgets/app_overlays.dart';

/// A reusable gradient app bar that keeps the navigation drawer, notifications,
/// and account actions consistent across every screen.
class PrimaryAppBar extends StatelessWidget implements PreferredSizeWidget {
  const PrimaryAppBar({
    super.key,
    required this.title,
    required this.section,
    this.trailingActions = const <Widget>[],
  });

  final String title;
  final AppSection section;
  final List<Widget> trailingActions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      systemOverlayStyle: SystemUiOverlayStyle.light,
      leading: Builder(
        builder: (buttonContext) {
          return IconButton(
            tooltip: 'Menu',
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () {
              final scaffoldState = Scaffold.maybeOf(buttonContext);
              if (scaffoldState != null && scaffoldState.hasDrawer) {
                scaffoldState.openDrawer();
              } else {
                showNavigationSheet(buttonContext, section);
              }
            },
          );
        },
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Inter',
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          tooltip: 'Notifications',
          icon: const Icon(Icons.notifications, color: Colors.white),
          onPressed: () => showNotificationsSheet(context),
        ),
        IconButton(
          tooltip: 'Account',
          icon: const Icon(Icons.account_circle, color: Colors.white),
          onPressed: () => showAccountSheet(context),
        ),
        ...trailingActions,
      ],
      flexibleSpace: const _GradientBackground(),
    );
  }
}

class _GradientBackground extends StatelessWidget {
  const _GradientBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFD74848), Color(0xFF111C51)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
    );
  }
}
