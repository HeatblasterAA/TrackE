import 'package:flutter/services.dart';

import 'ingestion_source.dart';
import 'raw_txn_signal.dart';

/// Wraps the Android `tracke/notifications/stream` EventChannel.
///
/// On non-Android platforms the stream is empty.
class NotificationSource implements IngestionSource {
  static const EventChannel _channel =
      EventChannel('tracke/notifications/stream');

  Stream<RawTxnSignal>? _cached;

  @override
  Stream<RawTxnSignal> stream() {
    return _cached ??= _channel
        .receiveBroadcastStream()
        .map((event) {
          if (event is Map) return RawTxnSignal.fromMap(event);
          return null;
        })
        .where((e) => e != null)
        .cast<RawTxnSignal>();
  }
}
