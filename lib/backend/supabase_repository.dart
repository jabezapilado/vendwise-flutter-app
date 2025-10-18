import 'dart:developer';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vendwise/backend/app_repository.dart';
import 'package:vendwise/backend/password_hasher.dart';
import 'package:vendwise/models/app_user.dart';
import 'package:vendwise/models/inventorymodel.dart';
import 'package:vendwise/models/productmodel.dart';
import 'package:vendwise/models/suppliermodel.dart';
import 'package:vendwise/models/transactionmodel.dart';

/// Supabase-backed implementation of [AppRepository].
class SupabaseAppRepository implements AppRepository {
  SupabaseClient get _client => Supabase.instance.client;

  static const String _inventoryTable = 'inventory';
  static const String _suppliersTable = 'suppliers';
  static const String _productsTable = 'products';
  static const String _transactionsTable = 'transactions';
  static const String _appUsersTable = 'app_users';

  // INVENTORY ---------------------------------------------------------------
  @override
  Future<List<Inventorymodel>> fetchInventory() async {
    final data = await _perform(() => _client.from(_inventoryTable).select());
    return data.map<Inventorymodel>(_mapInventory).toList();
  }

  @override
  Future<Inventorymodel> createInventory(InventoryDraft draft) async {
    final payload = draft.toMap();
    final data = await _perform(
      () => _client.from(_inventoryTable).insert(payload).select().single(),
    );
    return _mapInventory(data);
  }

  @override
  Future<Inventorymodel> updateInventory(
    String id,
    InventoryDraft draft,
  ) async {
    final payload = draft.toMap();
    final data = await _perform(
      () => _client
          .from(_inventoryTable)
          .update(payload)
          .eq('id', id)
          .select()
          .maybeSingle(),
    );
    if (data == null) {
      throw StateError('Inventory item $id not found');
    }
    return _mapInventory(data);
  }

  @override
  Future<void> deleteInventory(String id) async {
    await _perform(() => _client.from(_inventoryTable).delete().eq('id', id));
  }

  @override
  Future<Inventorymodel> updateInventoryQuantity(
    String id,
    int quantity,
  ) async {
    final data = await _perform(
      () => _client
          .from(_inventoryTable)
          .update({
            'quantity': quantity,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id)
          .select()
          .maybeSingle(),
    );
    if (data == null) {
      throw StateError('Inventory item $id not found');
    }
    return _mapInventory(data);
  }

  // SUPPLIERS ---------------------------------------------------------------
  @override
  Future<List<Suppliermodel>> fetchSuppliers() async {
    final data = await _perform(() => _client.from(_suppliersTable).select());
    return data.map<Suppliermodel>(_mapSupplier).toList();
  }

  @override
  Future<Suppliermodel> createSupplier(SupplierDraft draft) async {
    final payload = draft.toMap();
    final data = await _perform(
      () => _client.from(_suppliersTable).insert(payload).select().single(),
    );
    return _mapSupplier(data);
  }

  @override
  Future<Suppliermodel> updateSupplier(String id, SupplierDraft draft) async {
    final payload = draft.toMap();
    final data = await _perform(
      () => _client
          .from(_suppliersTable)
          .update(payload)
          .eq('id', id)
          .select()
          .maybeSingle(),
    );
    if (data == null) {
      throw StateError('Supplier $id not found');
    }
    return _mapSupplier(data);
  }

  @override
  Future<void> deleteSupplier(String id) async {
    await _perform(() => _client.from(_suppliersTable).delete().eq('id', id));
  }

  // PRODUCTS ----------------------------------------------------------------
  @override
  Future<List<Productmodel>> fetchProducts() async {
    final data = await _perform(() => _client.from(_productsTable).select());
    return data.map<Productmodel>(_mapProduct).toList();
  }

  @override
  Future<Productmodel> createProduct(ProductDraft draft) async {
    final payload = draft.toMap();
    final data = await _perform(
      () => _client.from(_productsTable).insert(payload).select().single(),
    );
    return _mapProduct(data);
  }

  @override
  Future<Productmodel> updateProduct(String id, ProductDraft draft) async {
    final payload = draft.toMap();
    final data = await _perform(
      () => _client
          .from(_productsTable)
          .update(payload)
          .eq('id', id)
          .select()
          .maybeSingle(),
    );
    if (data == null) {
      throw StateError('Product $id not found');
    }
    return _mapProduct(data);
  }

  @override
  Future<void> deleteProduct(String id) async {
    await _perform(() => _client.from(_productsTable).delete().eq('id', id));
  }

  // TRANSACTIONS ------------------------------------------------------------
  @override
  Future<List<Transactionmodel>> fetchTransactions() async {
    final data = await _perform(
      () => _client
          .from(_transactionsTable)
          .select()
          .order('time_purchased', ascending: false),
    );
    return data.map<Transactionmodel>(_mapTransaction).toList();
  }

  @override
  Future<Transactionmodel> createTransaction(TransactionDraft draft) async {
    final payload = draft.toMap();
    final data = await _perform(
      () => _client.from(_transactionsTable).insert(payload).select().single(),
    );
    return _mapTransaction(data);
  }

  @override
  Future<Transactionmodel> updateTransaction(
    String id,
    TransactionDraft draft,
  ) async {
    final payload = draft.toMap();
    final data = await _perform(
      () => _client
          .from(_transactionsTable)
          .update(payload)
          .eq('id', id)
          .select()
          .maybeSingle(),
    );
    if (data == null) {
      throw StateError('Transaction $id not found');
    }
    return _mapTransaction(data);
  }

  @override
  Future<void> deleteTransaction(String id) async {
    await _perform(
      () => _client.from(_transactionsTable).delete().eq('id', id),
    );
  }

  // APP USERS ---------------------------------------------------------------
  @override
  Future<List<AppUser>> fetchAppUsers() async {
    final data = await _perform(() => _client.from(_appUsersTable).select());
    return data.map<AppUser>(_mapAppUser).toList();
  }

  @override
  Future<AppUser?> authenticate(String username, String password) async {
    final trimmed = username.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    Map<String, dynamic>? data;
    final candidates = <String>{trimmed, trimmed.toLowerCase()}
      ..removeWhere((value) => value.isEmpty);

    for (final candidate in candidates) {
      data = await _fetchUserByColumn('username', candidate);
      if (data != null) {
        break;
      }
      data = await _fetchUserByColumn('email', candidate);
      if (data != null) {
        break;
      }
    }

    if (data == null) {
      return null;
    }

    final storedUsername = data['username'] as String?;
    final passwordHash = data['password_hash'] as String?;
    if (storedUsername == null || passwordHash == null) {
      return null;
    }

    final isValid = verifyPasswordHash(storedUsername, password, passwordHash);
    if (!isValid) {
      return null;
    }

    final user = _mapAppUser(data);
    if (!user.isActive) {
      return null;
    }
    return user;
  }

  Future<Map<String, dynamic>?> _fetchUserByColumn(
    String column,
    String value,
  ) {
    return _perform(
      () =>
          _client.from(_appUsersTable).select().eq(column, value).maybeSingle(),
    );
  }

  @override
  Future<AppUser> createAppUser(AppUserDraft draft) async {
    final normalized = draft.username.trim().toLowerCase();
    final existing = await _perform(
      () => _client
          .from(_appUsersTable)
          .select('id')
          .eq('username', normalized)
          .maybeSingle(),
    );
    if (existing != null) {
      throw StateError('Username "${draft.username}" already exists.');
    }
    final hash = derivePasswordHash(draft.username, draft.password);
    final payload = draft.toMap(hash);
    final data = await _perform(
      () => _client.from(_appUsersTable).insert(payload).select().single(),
    );
    return _mapAppUser(data);
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
    final updates = <String, dynamic>{};
    if (username != null) {
      updates['username'] = username.trim().toLowerCase();
    }
    if (fullName != null) {
      updates['full_name'] = fullName;
    }
    if (email != null) {
      updates['email'] = email;
    }
    if (role != null) {
      updates['role'] = role;
    }
    if (isActive != null) {
      updates['is_active'] = isActive;
    }
    if (newPassword != null && newPassword.isNotEmpty) {
      final snapshot = await _perform(
        () => _client
            .from(_appUsersTable)
            .select('username')
            .eq('id', id)
            .maybeSingle(),
      );
      if (snapshot == null) {
        throw StateError('User $id not found');
      }
      final effectiveUsername = username ?? snapshot['username'] as String;
      updates['password_hash'] = derivePasswordHash(
        effectiveUsername,
        newPassword,
      );
    }

    if (updates.isEmpty) {
      final data = await _perform(
        () => _client.from(_appUsersTable).select().eq('id', id).maybeSingle(),
      );
      if (data == null) {
        throw StateError('User $id not found');
      }
      return _mapAppUser(data);
    }

    final data = await _perform(
      () => _client
          .from(_appUsersTable)
          .update(updates)
          .eq('id', id)
          .select()
          .maybeSingle(),
    );
    if (data == null) {
      throw StateError('User $id not found');
    }
    return _mapAppUser(data);
  }

  @override
  Future<void> deleteAppUser(String id) async {
    await _perform(() => _client.from(_appUsersTable).delete().eq('id', id));
  }

  // MAPPERS -----------------------------------------------------------------
  Inventorymodel _mapInventory(dynamic row) {
    final map = Map<String, dynamic>.from(row as Map);
    return Inventorymodel.fromMap(map);
  }

  Suppliermodel _mapSupplier(dynamic row) {
    final map = Map<String, dynamic>.from(row as Map);
    return Suppliermodel.fromMap(map);
  }

  Productmodel _mapProduct(dynamic row) {
    final map = Map<String, dynamic>.from(row as Map);
    return Productmodel.fromMap(map);
  }

  Transactionmodel _mapTransaction(dynamic row) {
    final map = Map<String, dynamic>.from(row as Map);
    return Transactionmodel.fromMap(map);
  }

  AppUser _mapAppUser(dynamic row) {
    final map = Map<String, dynamic>.from(row as Map);
    return AppUser.fromMap(map);
  }

  // HELPERS -----------------------------------------------------------------
  Future<T> _perform<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on PostgrestException catch (error, stackTrace) {
      _logAndThrow(error, stackTrace);
    }
  }

  Never _logAndThrow(PostgrestException error, StackTrace stackTrace) {
    log(
      'Supabase query failed: ${error.message}',
      name: 'SupabaseAppRepository',
      error: error,
      stackTrace: stackTrace,
    );
    throw error;
  }
}
