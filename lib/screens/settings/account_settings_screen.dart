import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vendwise/widgets/app_overlays.dart';

/// Simple account settings page that stores preferences locally.
class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  bool _notificationsEnabled = true;
  bool _analyticsEnabled = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _hydrateFromStorage();
  }

  Future<void> _hydrateFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fullNameController.text = prefs.getString('account_full_name') ?? '';
      _emailController.text = prefs.getString('account_email') ?? '';
      _notificationsEnabled =
          prefs.getBool('account_notifications') ?? _notificationsEnabled;
      _analyticsEnabled =
          prefs.getBool('account_analytics') ?? _analyticsEnabled;
      _loading = false;
    });
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('account_full_name', _fullNameController.text);
    await prefs.setString('account_email', _emailController.text);
    await prefs.setBool('account_notifications', _notificationsEnabled);
    await prefs.setBool('account_analytics', _analyticsEnabled);

    if (!mounted) return;
    showQuickMessage(context, 'Account preferences saved.');
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  TextField(
                    controller: _fullNameController,
                    decoration: const InputDecoration(
                      labelText: 'Full name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email address',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SwitchListTile.adaptive(
                    title: const Text('Enable push notifications'),
                    subtitle: const Text(
                      'Receive alerts about inventory and sales updates.',
                    ),
                    value: _notificationsEnabled,
                    onChanged: (value) => setState(() {
                      _notificationsEnabled = value;
                    }),
                  ),
                  SwitchListTile.adaptive(
                    title: const Text('Share anonymous analytics'),
                    subtitle: const Text(
                      'Help us improve Vendwise by sharing usage data.',
                    ),
                    value: _analyticsEnabled,
                    onChanged: (value) => setState(() {
                      _analyticsEnabled = value;
                    }),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _persist,
                    icon: const Icon(Icons.save),
                    label: const Text('Save changes'),
                  ),
                ],
              ),
            ),
    );
  }
}
