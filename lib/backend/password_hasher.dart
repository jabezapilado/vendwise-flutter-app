import 'dart:convert';

import 'package:crypto/crypto.dart';

String derivePasswordHash(String username, String password) {
  final normalizedPassword = password.trim();
  final input = 'vendwise::$normalizedPassword';
  final bytes = utf8.encode(input);
  return sha256.convert(bytes).toString();
}

bool verifyPasswordHash(String username, String password, String expectedHash) {
  if (expectedHash.isEmpty) {
    return false;
  }
  final calculated = derivePasswordHash(username, password);
  return calculated == expectedHash;
}
