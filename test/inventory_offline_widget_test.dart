import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vendwise/backend/app_repository.dart';
import 'package:vendwise/models/inventorymodel.dart';
import 'package:vendwise/screens/inventory/inventory_screen.dart';

class DummyRepo implements AppRepository {
  @override
  Future<List<Inventorymodel>> fetchInventory() async => [
    Inventorymodel(
      id: 'inv-1',
      productName: 'Test Product',
      supplierName: 'Test Supplier',
      price: 10.0,
      quantity: 3,
      contactNum: null,
      email: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      expiryDate: null,
    ),
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('offline tap queues pending update (widget)', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      MaterialApp(
        home: InventoryScreen(repository: DummyRepo(), initialOnline: false),
      ),
    );

    await tester.pumpAndSettle();

    // find the first add icon and tap it
    final add = find.byIcon(Icons.add_circle).first;
    expect(add, findsOneWidget);
    await tester.tap(add);
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('pending_inventory_updates');
    expect(raw, isNotNull);
    final decoded = jsonDecode(raw!);
    expect(decoded, isA<List>());
    expect(decoded.length, greaterThanOrEqualTo(1));
  });
}
