import 'package:flutter_test/flutter_test.dart';
import 'package:vendwise/backend/app_repository.dart';
import 'package:vendwise/models/inventorymodel.dart';

void main() {
  test('MockAppRepository updateInventoryQuantity updates quantity', () async {
    final repo = MockAppRepository();

    // create an inventory item using the repo
    final draft = InventoryDraft(
      productName: 'Test Item',
      supplierName: 'Supplier',
      price: 50.0,
      quantity: 10,
    );

    final created = await repo.createInventory(draft);
    expect(created.quantity, 10);

    final updated = await repo.updateInventoryQuantity(created.id, 15);
    expect(updated.quantity, 15);

    // ensure fetch reflects the change
    final list = await repo.fetchInventory();
    final found = list.firstWhere((i) => i.id == created.id);
    expect(found.quantity, 15);
  });
}
