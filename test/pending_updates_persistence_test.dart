import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('pending updates saved and loaded as JSON string', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final pending = [
      {'id': 'abc-123', 'quantity': 5},
      {'id': 'def-456', 'quantity': 0},
    ];

    final raw = jsonEncode(pending);
    final ok = await prefs.setString('pending_inventory_updates', raw);
    expect(ok, isTrue);

    final loadedRaw = prefs.getString('pending_inventory_updates');
    expect(loadedRaw, isNotNull);

    final decoded = jsonDecode(loadedRaw!);
    expect(decoded, isA<List>());
    expect(decoded.length, equals(2));
    expect(decoded[0]['id'], equals('abc-123'));
    expect(decoded[0]['quantity'], equals(5));
  });
}
