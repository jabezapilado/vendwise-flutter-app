import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vendwise/backend/app_repository.dart';
import 'package:vendwise/backend/bootstrap.dart';
import 'package:vendwise/models/inventorymodel.dart';
import 'package:vendwise/models/productmodel.dart';
import 'package:vendwise/models/suppliermodel.dart';
import 'package:vendwise/models/transactionmodel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test(
    'Frontend ↔ backend ↔ database smoke test',
    () async {
      final result = await initializeBackend();
      expect(result.supabaseReady, isTrue, reason: result.describeIssues());

      final inventory = await appRepository.fetchInventory();
      final suppliers = await appRepository.fetchSuppliers();
      final products = await appRepository.fetchProducts();
      final transactions = await appRepository.fetchTransactions();

      expect(inventory, isA<List<Inventorymodel>>());
      expect(suppliers, isA<List<Suppliermodel>>());
      expect(products, isA<List<Productmodel>>());
      expect(transactions, isA<List<Transactionmodel>>());
    },
    timeout: const Timeout(Duration(seconds: 45)),
  );
}
