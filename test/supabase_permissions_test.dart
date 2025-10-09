import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vendwise/backend/app_repository.dart';
import 'package:vendwise/backend/bootstrap.dart';
import 'package:vendwise/models/inventorymodel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test(
    'Supabase service account can create, update, and delete inventory rows',
    () async {
      final result = await initializeBackend();
      expect(result.supabaseReady, isTrue, reason: result.describeIssues());
      expect(
        supabaseRepositoryActive,
        isTrue,
        reason:
            'Supabase repository is inactive — check initializeBackend logs.',
      );

      final email = supabaseServiceEmail;
      final password = supabaseServicePassword;
      expect(email, isNotNull, reason: 'SUPABASE_SERVICE_EMAIL missing (.env)');
      expect(
        password,
        isNotNull,
        reason: 'SUPABASE_SERVICE_PASSWORD missing (.env)',
      );

      final client = Supabase.instance.client;
      await client.auth.signOut();
      final authResponse = await client.auth.signInWithPassword(
        email: email!,
        password: password!,
      );
      expect(authResponse.session, isNotNull, reason: 'Service sign-in failed');

      final uniqueName =
          'diagnostic-${DateTime.now().millisecondsSinceEpoch.toRadixString(16)}';
      Inventorymodel? created;

      try {
        created = await appRepository.createInventory(
          InventoryDraft(
            productName: uniqueName,
            price: 1.0,
            quantity: 1,
            supplierName: 'diagnostic-supplier',
          ),
        );
        expect(created.productName, uniqueName);

        final updated = await appRepository.updateInventory(
          created.id,
          const InventoryDraft(
            productName: 'diagnostic-updated',
            price: 2.0,
            quantity: 3,
            supplierName: 'diagnostic-supplier',
          ),
        );
        expect(updated.productName, 'diagnostic-updated');

        await appRepository.deleteInventory(created.id);
        created = null;

        final remaining = await appRepository.fetchInventory();
        final stillExists = remaining.any(
          (item) => item.productName == 'diagnostic-updated',
        );
        expect(stillExists, isFalse);
      } finally {
        if (created != null) {
          await appRepository.deleteInventory(created.id);
        }
        await client.auth.signOut();
      }
    },
    timeout: const Timeout(Duration(seconds: 60)),
  );
}
