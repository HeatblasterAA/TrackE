import 'raw_txn_signal.dart';

/// Source-agnostic stream of canonical transaction signals.
///
/// Implementations:
///   - [NotificationSource] — Android notification listener
///   - [ManualSource]       — manual add UI
abstract class IngestionSource {
  Stream<RawTxnSignal> stream();
}
