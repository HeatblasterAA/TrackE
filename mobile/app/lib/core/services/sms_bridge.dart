import 'package:flutter/services.dart';

class SmsBridge {
  static const MethodChannel _channel =
      MethodChannel('tracke/sms');

  static Future<List<Map<String, dynamic>>> readSince(
    int since,
  ) async {
    final result = await _channel.invokeMethod(
      'readSmsHistory',
      {
        'since': since,
      },
    );

    final list = List<dynamic>.from(result);

    return list
        .map(
          (e) => Map<String, dynamic>.from(
            Map<dynamic, dynamic>.from(e),
          ),
        )
        .toList();
  }
}