import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vendwise/backend/bootstrap.dart';

/// Integration tests that exercise Supabase end-to-end.
///
/// These tests are guarded by environment variables so they do not run in
/// CI unless you explicitly provide credentials. To run locally set the
/// following environment variables in a `.env` file at the repo root or via
/// your shell:
///
/// SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_EMAIL,
/// SUPABASE_SERVICE_PASSWORD
///
/// The test will be skipped automatically when these are not present.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test(
    'Supabase integration scaffold (guarded)',
    () async {
      // initialize the backend which loads .env and attempts to initialize supabase
      final result = await initializeBackend();

      // If Supabase is not configured, skip
      final configured = result.supabaseConfigured;
      if (!configured) {
        // Skip explicitly with a clear message
        return;
      }

      // Ensure Supabase init succeeded
      expect(result.supabaseInitialized, isTrue);
      expect(
        result.tableIssues.isEmpty,
        isTrue,
        reason: result.describeIssues(),
      );

      // Optional: check presence of service account vars and demonstrate a simple
      // authenticated action when they exist.
      final serviceEmail = supabaseServiceEmail;
      final servicePassword = supabaseServicePassword;
      if (serviceEmail != null && servicePassword != null) {
        final client = Supabase.instance.client;
        await client.auth.signOut();
        final res = await client.auth.signInWithPassword(
          email: serviceEmail,
          password: servicePassword,
        );
        expect(
          res.session,
          isNotNull,
          reason: 'Service account sign-in failed',
        );

        // Example: fetch up to one inventory row to ensure queries work
        final rows = await client.from('inventory').select().limit(1);
        expect(rows, isA<List>());
      }
    },
    timeout: const Timeout(Duration(seconds: 60)),
  );
}
