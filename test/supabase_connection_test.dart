import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vendwise/backend/bootstrap.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test(
    'Supabase prerequisites are ready',
    () async {
      final result = await initializeBackend();
      expect(result.supabaseReady, isTrue, reason: result.describeIssues());
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );
}
