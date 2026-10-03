import 'dart:convert';

import 'package:crypto/crypto.dart';

String anonymiseUserId(String rawUserId) {
  final digest = sha256.convert(utf8.encode(rawUserId)).bytes;
  return digest
      .take(16)
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();
}
