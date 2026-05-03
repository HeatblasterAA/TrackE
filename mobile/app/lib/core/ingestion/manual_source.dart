import 'dart:async';

import 'ingestion_source.dart';
import 'raw_txn_signal.dart';

/// Manual entry feeds the same pipeline as notifications.
///
/// The manual-add page calls [push] with a synthesized [RawTxnSignal]
/// whose `body` is shaped like a notification body so the parser layers
/// can treat it identically.
class ManualSource implements IngestionSource {
  ManualSource._();

  static final ManualSource instance = ManualSource._();

  final _controller = StreamController<RawTxnSignal>.broadcast();

  @override
  Stream<RawTxnSignal> stream() => _controller.stream;

  void push(RawTxnSignal signal) {
    _controller.add(signal);
  }

  void dispose() {
    _controller.close();
  }
}
