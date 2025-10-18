import 'package:flutter_test/flutter_test.dart';
import 'package:vendwise/models/inventorymodel.dart';

void main() {
  group('InventoryDraft.toMap', () {
    test('omits expiry_date when expiryDate is null', () {
      final draft = InventoryDraft(
        productName: 'Test Product',
        supplierName: 'Test Supplier',
        price: 10.0,
        quantity: 5,
        contactNum: 1234567890,
        email: 'test@example.com',
        expiryDate: null,
      );

      final map = draft.toMap();
      expect(map.containsKey('expiry_date'), isFalse);
      expect(map['product_name'], 'Test Product');
    });

    test('includes expiry_date when expiryDate is set', () {
      final dt = DateTime.utc(2025, 12, 31);
      final draft = InventoryDraft(
        productName: 'Test Product',
        supplierName: 'Test Supplier',
        price: 10.0,
        quantity: 5,
        contactNum: 1234567890,
        email: 'test@example.com',
        expiryDate: dt,
      );

      final map = draft.toMap();
      expect(map.containsKey('expiry_date'), isTrue);
      expect(map['expiry_date'], dt.toIso8601String());
    });
  });
}
