import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import '../../features/parser/transaction_parser.dart';
import '../../models/transaction_model.dart';
import '../../repositories/cloud_transaction_repository.dart';
import '../../repositories/transaction_repository.dart';
import '../ingestion/ingestion_source.dart';
import '../ingestion/raw_txn_signal.dart';
import '../storage/raw_signal_log.dart';

class ScanResult {
  final int raw;
  final int parsed;
  final int inserted;

  const ScanResult({
    required this.raw,
    required this.parsed,
    required this.inserted,
  });
}

/// Source-agnostic ingestion engine.
///
/// Subscribes to one or more [IngestionSource]s and pushes every signal
/// through: raw-log append → parser → local repo → cloud repo.
///
/// Replaces the old SMS polling loop entirely.
class ScanService {
  static final List<StreamSubscription<RawTxnSignal>> _subs = [];
  static int? _lastSignalAt;

  /// Last time *any* signal arrived from any source. Used by the
  /// connection-status widget on the dashboard.
  static int? get lastSignalAt => _lastSignalAt;

  /// Subscribe to the provided sources. Idempotent — safe to call once
  /// at app boot.
  static void start(List<IngestionSource> sources) {
    if (_subs.isNotEmpty) return;
    for (final src in sources) {
      _subs.add(src.stream().listen(_handleSignal,
          onError: (Object e, StackTrace s) {
        FirebaseCrashlytics.instance
            .recordError(e, s, reason: 'ingestion stream error');
      }));
    }
  }

  static Future<void> stop() async {
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
  }

  /// Reprocess every signal currently in [RawSignalLog] through the
  /// parser. Useful after a parser upgrade or after the user adds a new
  /// rule via the review queue.
  static Future<ScanResult> reprocess() async {
    final signals = RawSignalLog.all();
    int parsed = 0;
    int inserted = 0;
    for (final s in signals) {
      final result = await _processSignal(s, persistRawLog: false);
      if (result.parsed > 0) parsed += result.parsed;
      if (result.inserted > 0) inserted += result.inserted;
    }
    return ScanResult(
      raw: signals.length,
      parsed: parsed,
      inserted: inserted,
    );
  }

  static Future<void> _handleSignal(RawTxnSignal signal) async {
    _lastSignalAt = DateTime.now().millisecondsSinceEpoch;
    await _processSignal(signal, persistRawLog: true);
  }

  static Future<ScanResult> _processSignal(
    RawTxnSignal signal, {
    required bool persistRawLog,
  }) async {
    try {
      if (persistRawLog) {
        await RawSignalLog.append(signal);
      }

      final txn = TransactionParser.parseSignal(signal);

      if (txn == null) {
        await RawSignalLog.markOutcome(signal.id, 'rejected');
        return const ScanResult(raw: 1, parsed: 0, inserted: 0);
      }

      final repo = TransactionRepository();
      final newTxns = await repo.saveAllReturningNew([txn]);

      await RawSignalLog.markOutcome(
        signal.id,
        txn.needsReview ? 'review' : 'ok',
        txn.id,
      );

      if (newTxns.isNotEmpty) {
        try {
          await CloudTransactionRepository().upsertMany(newTxns);
        } catch (e, stack) {
          FirebaseCrashlytics.instance
              .recordError(e, stack, reason: 'cloud sync failed');
        }
      }

      return ScanResult(
        raw: 1,
        parsed: 1,
        inserted: newTxns.length,
      );
    } catch (e, stack) {
      FirebaseCrashlytics.instance
          .recordError(e, stack, reason: 'signal processing failed');
      return const ScanResult(raw: 1, parsed: 0, inserted: 0);
    }
  }

  /// Legacy entry point used by the dashboard "Sync" / "Rebuild" buttons.
  /// In the notification-driven world there's no SMS history to pull, so
  /// this just reprocesses what's in the raw signal log.
  static Future<ScanResult> scan() => reprocess();

  /// Push a synthetic signal through the same pipeline. Used by manual
  /// entries; equivalent to ManualSource.push(...) but available
  /// statically for callers that don't hold the ManualSource instance.
  static Future<TransactionModel?> ingestManual(RawTxnSignal signal) async {
    _lastSignalAt = DateTime.now().millisecondsSinceEpoch;
    await RawSignalLog.append(signal);
    final txn = TransactionParser.parseSignal(signal);
    if (txn == null) {
      await RawSignalLog.markOutcome(signal.id, 'rejected');
      return null;
    }
    final repo = TransactionRepository();
    final newTxns = await repo.saveAllReturningNew([txn]);
    await RawSignalLog.markOutcome(
      signal.id,
      txn.needsReview ? 'review' : 'ok',
      txn.id,
    );
    if (newTxns.isNotEmpty) {
      try {
        await CloudTransactionRepository().upsertMany(newTxns);
      } catch (e, stack) {
        FirebaseCrashlytics.instance
            .recordError(e, stack, reason: 'cloud sync failed');
      }
    }
    return txn;
  }
}
