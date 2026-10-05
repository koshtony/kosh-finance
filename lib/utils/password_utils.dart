import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

String generateSalt([int length = 16]) {
  final rand = Random.secure();
  final bytes = List<int>.generate(length, (_) => rand.nextInt(256));
  return base64UrlEncode(bytes);
}

String hashPassword(String password, String salt) {
  final bytes = utf8.encode('$salt:$password');
  return sha256.convert(bytes).toString();
}

bool verifyPassword(String password, String salt, String expectedHash) {
  return hashPassword(password, salt) == expectedHash;
}
