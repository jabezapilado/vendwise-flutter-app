import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math';

import 'package:path/path.dart' as p;
import 'package:vendwise/backend/password_hasher.dart';
import 'package:vendwise/models/app_user.dart';
import 'package:vendwise/models/inventorymodel.dart';
import 'package:vendwise/models/productmodel.dart';
import 'package:vendwise/models/suppliermodel.dart';
import 'package:vendwise/models/transactionmodel.dart';
import 'package:vendwise/constants/remote_assets.dart';

/// Contract that hides the concrete data source so the UI can
/// switch from mock data to Supabase with minimal changes.
abstract class AppRepository {
  // Inventory ---------------------------------------------------------------
  Future<List<Inventorymodel>> fetchInventory();
  Future<Inventorymodel> createInventory(InventoryDraft draft);
  Future<Inventorymodel> updateInventory(String id, InventoryDraft draft);
  Future<void> deleteInventory(String id);

  /// Update only the quantity field for an inventory item.
  Future<Inventorymodel> updateInventoryQuantity(String id, int quantity);

  // Suppliers ---------------------------------------------------------------
  Future<List<Suppliermodel>> fetchSuppliers();
  Future<Suppliermodel> createSupplier(SupplierDraft draft);
  Future<Suppliermodel> updateSupplier(String id, SupplierDraft draft);
  Future<void> deleteSupplier(String id);

  // Products ----------------------------------------------------------------
  Future<List<Productmodel>> fetchProducts();
  Future<Productmodel> createProduct(ProductDraft draft);
  Future<Productmodel> updateProduct(String id, ProductDraft draft);
  Future<void> deleteProduct(String id);

  // Transactions ------------------------------------------------------------
  Future<List<Transactionmodel>> fetchTransactions();
  Future<Transactionmodel> createTransaction(TransactionDraft draft);
  Future<Transactionmodel> updateTransaction(String id, TransactionDraft draft);
  Future<void> deleteTransaction(String id);

  // App users (authentication) ---------------------------------------------
  Future<List<AppUser>> fetchAppUsers();
  Future<AppUser?> authenticate(String username, String password);
  Future<AppUser> createAppUser(AppUserDraft draft);
  Future<AppUser> updateAppUser(
    String id, {
    String? username,
    String? fullName,
    String? email,
    String? role,
    bool? isActive,
    String? newPassword,
  });
  Future<void> deleteAppUser(String id);
}

class MockAppRepository implements AppRepository {
  MockAppRepository() {
    _seedData();
  }

  final Random _random = Random();
  final List<Inventorymodel> _inventory = <Inventorymodel>[];
  final List<Suppliermodel> _suppliers = <Suppliermodel>[];
  final List<Productmodel> _products = <Productmodel>[];
  final List<Transactionmodel> _transactions = <Transactionmodel>[];
  final List<_MockUserRecord> _users = <_MockUserRecord>[];

  @override
  Future<List<Inventorymodel>> fetchInventory() async {
    return List<Inventorymodel>.unmodifiable(_inventory);
  }

  @override
  Future<Inventorymodel> createInventory(InventoryDraft draft) async {
    final now = DateTime.now();
    final item = Inventorymodel(
      id: _generateId('inv'),
      productName: draft.productName,
      supplierName: draft.supplierName,
      price: draft.price,
      quantity: draft.quantity,
      contactNum: draft.contactNum,
      email: draft.email,
      createdAt: now,
      updatedAt: now,
      expiryDate: draft.expiryDate,
    );
    _inventory.add(item);
    return item;
  }

  @override
  Future<Inventorymodel> updateInventory(
    String id,
    InventoryDraft draft,
  ) async {
    final index = _inventory.indexWhere((element) => element.id == id);
    if (index == -1) {
      throw StateError('Inventory item $id not found');
    }
    final updated = _inventory[index].copyWith(
      productName: draft.productName,
      supplierName: draft.supplierName,
      price: draft.price,
      quantity: draft.quantity,
      contactNum: draft.contactNum,
      email: draft.email,
      updatedAt: DateTime.now(),
      expiryDate: draft.expiryDate,
    );
    _inventory[index] = updated;
    return updated;
  }

  @override
  Future<Inventorymodel> updateInventoryQuantity(
    String id,
    int quantity,
  ) async {
    final index = _inventory.indexWhere((element) => element.id == id);
    if (index == -1) {
      throw StateError('Inventory item $id not found');
    }
    final updated = _inventory[index].copyWith(
      quantity: quantity,
      updatedAt: DateTime.now(),
    );
    _inventory[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteInventory(String id) async {
    _inventory.removeWhere((element) => element.id == id);
  }

  @override
  Future<List<Suppliermodel>> fetchSuppliers() async {
    return List<Suppliermodel>.unmodifiable(_suppliers);
  }

  @override
  Future<Suppliermodel> createSupplier(SupplierDraft draft) async {
    final now = DateTime.now();
    final supplier = Suppliermodel(
      id: _generateId('sup'),
      // Provide a mock sequential supplierSeq for local/testing purposes.
      supplierSeq: _suppliers.length + 1,
      supplierName: draft.supplierName,
      contactNum: draft.contactNum,
      email: draft.email,
      createdAt: now,
      updatedAt: now,
    );
    _suppliers.add(supplier);
    return supplier;
  }

  @override
  Future<Suppliermodel> updateSupplier(String id, SupplierDraft draft) async {
    final index = _suppliers.indexWhere((element) => element.id == id);
    if (index == -1) {
      throw StateError('Supplier $id not found');
    }
    final updated = _suppliers[index].copyWith(
      supplierName: draft.supplierName,
      contactNum: draft.contactNum,
      email: draft.email,
      updatedAt: DateTime.now(),
    );
    _suppliers[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteSupplier(String id) async {
    _suppliers.removeWhere((element) => element.id == id);
  }

  @override
  Future<List<Productmodel>> fetchProducts() async {
    return List<Productmodel>.unmodifiable(_products);
  }

  @override
  Future<Productmodel> createProduct(ProductDraft draft) async {
    final now = DateTime.now();
    final product = Productmodel(
      id: _generateId('prod'),
      productName: draft.productName,
      productDesc: draft.productDesc,
      priceM: draft.priceM,
      priceL: draft.priceL,
      prodType: draft.prodType,
      prodImage: draft.clearImage ? null : draft.prodImage,
      createdAt: now,
      updatedAt: now,
    );
    _products.add(product);
    return product;
  }

  @override
  Future<Productmodel> updateProduct(String id, ProductDraft draft) async {
    final index = _products.indexWhere((element) => element.id == id);
    if (index == -1) {
      throw StateError('Product $id not found');
    }
    final current = _products[index];
    final updated = _products[index].copyWith(
      productName: draft.productName,
      productDesc: draft.productDesc,
      priceM: draft.priceM,
      priceL: draft.priceL,
      prodType: draft.prodType,
      prodImage: draft.clearImage
          ? null
          : (draft.prodImage ?? current.prodImage),
      updatedAt: DateTime.now(),
    );
    _products[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteProduct(String id) async {
    _products.removeWhere((element) => element.id == id);
  }

  @override
  Future<List<Transactionmodel>> fetchTransactions() async {
    return List<Transactionmodel>.unmodifiable(_transactions);
  }

  @override
  Future<Transactionmodel> createTransaction(TransactionDraft draft) async {
    final now = DateTime.now();
    final transaction = Transactionmodel(
      id: _generateId('txn'),
      customerName: draft.customerName,
      itemCount: draft.itemCount,
      totalAmount: draft.totalAmount,
      timePurchased: draft.timePurchased,
      createdAt: now,
      updatedAt: now,
    );
    _transactions.add(transaction);
    return transaction;
  }

  @override
  Future<Transactionmodel> updateTransaction(
    String id,
    TransactionDraft draft,
  ) async {
    final index = _transactions.indexWhere((element) => element.id == id);
    if (index == -1) {
      throw StateError('Transaction $id not found');
    }
    final updated = Transactionmodel(
      id: _transactions[index].id,
      customerName: draft.customerName,
      itemCount: draft.itemCount,
      totalAmount: draft.totalAmount,
      timePurchased: draft.timePurchased,
      createdAt: _transactions[index].createdAt,
      updatedAt: DateTime.now(),
    );
    _transactions[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteTransaction(String id) async {
    _transactions.removeWhere((element) => element.id == id);
  }

  @override
  Future<List<AppUser>> fetchAppUsers() async {
    return List<AppUser>.unmodifiable(_users.map((record) => record.user));
  }

  @override
  Future<AppUser?> authenticate(String username, String password) async {
    final identifier = username.trim();
    if (identifier.isEmpty) {
      return null;
    }
    final normalized = identifier.toLowerCase();
    final record = _users.firstWhere((entry) {
      final storedUsername = entry.user.username.trim().toLowerCase();
      final storedEmail = entry.user.email?.trim().toLowerCase();
      return storedUsername == normalized || storedEmail == normalized;
    }, orElse: () => _MockUserRecord.empty);
    if (record == _MockUserRecord.empty) {
      return null;
    }
    final isValid = verifyPasswordHash(
      record.user.username,
      password,
      record.passwordHash,
    );
    if (!isValid || !record.user.isActive) {
      return null;
    }
    return record.user;
  }

  @override
  Future<AppUser> createAppUser(AppUserDraft draft) async {
    final normalized = draft.username.trim().toLowerCase();
    if (_users.any(
      (element) => element.user.username.trim().toLowerCase() == normalized,
    )) {
      throw StateError('Username "${draft.username}" already exists.');
    }
    final now = DateTime.now();
    final user = AppUser(
      id: _generateId('usr'),
      username: draft.username,
      fullName: draft.fullName,
      email: draft.email,
      role: draft.role,
      isActive: draft.isActive,
      createdAt: now,
      updatedAt: now,
    );
    final hash = derivePasswordHash(draft.username, draft.password);
    _users.add(_MockUserRecord(user: user, passwordHash: hash));
    return user;
  }

  @override
  Future<AppUser> updateAppUser(
    String id, {
    String? username,
    String? fullName,
    String? email,
    String? role,
    bool? isActive,
    String? newPassword,
  }) async {
    final index = _users.indexWhere((element) => element.user.id == id);
    if (index == -1) {
      throw StateError('User $id not found');
    }

    final existing = _users[index];
    var updatedUser = existing.user.copyWith(
      username: username ?? existing.user.username,
      fullName: fullName ?? existing.user.fullName,
      email: email ?? existing.user.email,
      role: role ?? existing.user.role,
      isActive: isActive ?? existing.user.isActive,
      updatedAt: DateTime.now(),
    );

    var passwordHash = existing.passwordHash;
    if (newPassword != null && newPassword.isNotEmpty) {
      passwordHash = derivePasswordHash(updatedUser.username, newPassword);
    }

    _users[index] = _MockUserRecord(
      user: updatedUser,
      passwordHash: passwordHash,
    );
    return updatedUser;
  }

  @override
  Future<void> deleteAppUser(String id) async {
    _users.removeWhere((element) => element.user.id == id);
  }

  String _generateId(String prefix) {
    final randomValue = _random.nextInt(1 << 20);
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    return '$prefix-$timestamp-$randomValue';
  }

  void _seedData() {
    final now = DateTime.now();
    final manifestLoaded = RemoteAssets.loadFromFile(
      p.join('build', 'migrated_assets.json'),
    );
    if (!manifestLoaded) {
      developer.log(
        'Remote asset manifest not found or invalid. Seeded products will use placeholders.',
        name: 'MockAppRepository',
      );
    }

    _suppliers.addAll(<Suppliermodel>[
      Suppliermodel(
        id: _generateId('sup'),
        supplierName: 'Dairy Supplier Inc',
        contactNum: 2225555666,
        email: 'dairy@supplier.com',
        createdAt: now,
        updatedAt: now,
      ),
      Suppliermodel(
        id: _generateId('sup'),
        supplierName: 'Tea Importers',
        contactNum: 2225555999,
        email: 'tea@supplier.com',
        createdAt: now,
        updatedAt: now,
      ),
      Suppliermodel(
        id: _generateId('sup'),
        supplierName: 'Fresh Fruits Ltd',
        contactNum: 1114444777,
        email: 'fruits@supplier.com',
        createdAt: now,
        updatedAt: now,
      ),
      Suppliermodel(
        id: _generateId('sup'),
        supplierName: 'Sweet Toppings',
        contactNum: 8887776666,
        email: 'toppings@supplier.com',
        createdAt: now,
        updatedAt: now,
      ),
    ]);

    _inventory.addAll(<Inventorymodel>[
      Inventorymodel(
        id: _generateId('inv'),
        productName: 'Almond Milk',
        supplierName: 'Dairy Supplier Inc',
        price: 100,
        quantity: 1000,
        contactNum: 2225555666,
        email: 'dairy@supplier.com',
        createdAt: now,
        updatedAt: now,
      ),
      Inventorymodel(
        id: _generateId('inv'),
        productName: 'Thai Tea Base',
        supplierName: 'Tea Importers',
        price: 320,
        quantity: 250,
        contactNum: 2225555999,
        email: 'tea@supplier.com',
        createdAt: now,
        updatedAt: now,
      ),
      Inventorymodel(
        id: _generateId('inv'),
        productName: 'Tapioca Pearls',
        supplierName: 'Sweet Toppings',
        price: 80,
        quantity: 750,
        contactNum: 8887776666,
        email: 'toppings@supplier.com',
        createdAt: now,
        updatedAt: now,
      ),
      Inventorymodel(
        id: _generateId('inv'),
        productName: 'Gardenia Bread',
        supplierName: 'Fresh Fruits Ltd',
        price: 60,
        quantity: 180,
        contactNum: 1114444777,
        email: 'fruits@supplier.com',
        createdAt: now,
        updatedAt: now,
      ),
    ]);

    String resolveProductImage(String fileName) {
      return RemoteAssets.getUrl(fileName) ??
          p.join('assets', 'images', fileName);
    }

    _products.addAll(<Productmodel>[
      Productmodel(
        id: _generateId('prod'),
        productName: 'Classic Milk Tea',
        productDesc: 'The timeless blend of black tea and creamy milk.',
        priceM: 90.0,
        priceL: 110.0,
        prodType: 'Drinks',
        prodImage: resolveProductImage('Classic_Milk_Tea.jpg'),
        createdAt: now,
        updatedAt: now,
      ),
      Productmodel(
        id: _generateId('prod'),
        productName: 'Wintermelon Milk Tea',
        productDesc: 'Refreshing sweet tea with a creamy finish.',
        priceM: 95.0,
        priceL: 115.0,
        prodType: 'Drinks',
        prodImage: resolveProductImage('Wintermelon_Milk_Tea.jpg'),
        createdAt: now,
        updatedAt: now,
      ),
      Productmodel(
        id: _generateId('prod'),
        productName: 'Gardenia Bread',
        productDesc: 'Freshly baked loaf perfect for sandwiches and toast.',
        priceM: 120.0,
        priceL: 0.0,
        prodType: 'Foods',
        prodImage: resolveProductImage('Gardenia_Bread.jpg'),
        createdAt: now,
        updatedAt: now,
      ),
      Productmodel(
        id: _generateId('prod'),
        productName: 'Fries',
        productDesc: 'Crispy fries with savory seasoning.',
        priceM: 35.0,
        priceL: 0.0,
        prodType: 'Foods',
        prodImage: resolveProductImage('French_fries.jpg'),
        createdAt: now,
        updatedAt: now,
      ),
    ]);

    _transactions.addAll(<Transactionmodel>[
      Transactionmodel(
        id: _generateId('txn'),
        customerName: 'Louis',
        itemCount: 3,
        totalAmount: 230.0,
        timePurchased: now.subtract(const Duration(hours: 2)),
        createdAt: now,
        updatedAt: now,
      ),
      Transactionmodel(
        id: _generateId('txn'),
        customerName: 'Maurice',
        itemCount: 5,
        totalAmount: 500.0,
        timePurchased: now.subtract(const Duration(minutes: 90)),
        createdAt: now,
        updatedAt: now,
      ),
      Transactionmodel(
        id: _generateId('txn'),
        customerName: 'Rafael',
        itemCount: 2,
        totalAmount: 170.0,
        timePurchased: now.subtract(const Duration(minutes: 45)),
        createdAt: now,
        updatedAt: now,
      ),
      Transactionmodel(
        id: _generateId('txn'),
        customerName: 'Jabez',
        itemCount: 10,
        totalAmount: 800.0,
        timePurchased: now.subtract(const Duration(minutes: 10)),
        createdAt: now,
        updatedAt: now,
      ),
    ]);

    _users.addAll(<_MockUserRecord>[
      _MockUserRecord(
        user: AppUser(
          id: _generateId('usr'),
          username: 'admin',
          fullName: 'VendWise Admin',
          email: 'admin@vendwise.com',
          role: 'admin',
          isActive: true,
          createdAt: now,
          updatedAt: now,
        ),
        passwordHash: derivePasswordHash('admin', 'admin123'),
      ),
      _MockUserRecord(
        user: AppUser(
          id: _generateId('usr'),
          username: 'cashier',
          fullName: 'Counter Cashier',
          email: 'cashier@vendwise.com',
          role: 'staff',
          isActive: true,
          createdAt: now,
          updatedAt: now,
        ),
        passwordHash: derivePasswordHash('cashier', 'cashier123'),
      ),
      _MockUserRecord(
        user: AppUser(
          id: _generateId('usr'),
          username: 'manager',
          fullName: 'Store Manager',
          email: 'manager@vendwise.com',
          role: 'manager',
          isActive: true,
          createdAt: now,
          updatedAt: now,
        ),
        passwordHash: derivePasswordHash('manager', 'manager123'),
      ),
    ]);
  }
}

AppRepository appRepository = MockAppRepository();

void setAppRepository(AppRepository repository) {
  appRepository = repository;
}

class _MockUserRecord {
  const _MockUserRecord({required this.user, required this.passwordHash});

  final AppUser user;
  final String passwordHash;

  static final _MockUserRecord empty = _MockUserRecord(
    user: AppUser(id: '', username: '', role: 'staff', isActive: false),
    passwordHash: '',
  );
}
