import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('audit log saved and loaded', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final audit = [
      {
        'id': 'inv-1',
        'quantity': 5,
        'status': 'queued',
        'timestamp': DateTime.now().toIso8601String(),
      },
    ];

    final raw = jsonEncode(audit);
    final ok = await prefs.setString('inventory_update_audit', raw);
    expect(ok, isTrue);

    final loaded = prefs.getString('inventory_update_audit');
    expect(loaded, isNotNull);
    final decoded = jsonDecode(loaded!);
    expect(decoded, isA<List>());
    expect(decoded[0]['id'], equals('inv-1'));
  });
}
