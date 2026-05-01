import 'dart:convert';
import 'package:crypto/crypto.dart';

class HashUtil {
  static String smsHash(
    Map<String, dynamic> sms,
  ) {
    final sender =
        (sms['sender'] ?? '').toString();

    final body =
        (sms['body'] ?? '').toString();

    final timestamp =
        (sms['timestamp'] ?? '').toString();

    final raw =
        '$sender|$body|$timestamp';

    return sha256.convert(
      utf8.encode(raw),
    ).toString();
  }
}