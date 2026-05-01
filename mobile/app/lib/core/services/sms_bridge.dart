import 'package:flutter/services.dart';

class SmsBridge {
  static const MethodChannel _channel =
      MethodChannel('tracke/sms');

  static Future<List<Map<String, dynamic>>> readHistory({
    int days = 90,
  }) async {
    final result = await _channel.invokeMethod(
      'readSmsHistory',
      {
        'days': days,
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