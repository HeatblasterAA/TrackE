

import 'package:app/core/services/sms_bridge.dart';
import 'package:app/core/storage/local_storage.dart';
import 'package:app/features/parser/transaction_parser.dart';
import 'package:app/models/transaction_model.dart';
import 'package:app/repositories/cloud_transaction_repository.dart';
import 'package:app/repositories/transaction_repository.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

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

class ScanService {
  static bool _running = false;


static Future<ScanResult> scan() async {
  if (_running) {
    return const ScanResult(
      raw: 0,
      parsed: 0,
      inserted: 0,
    );
  }

  _running = true;

  FirebaseCrashlytics.instance.log(
    'scan started',
  );

  try {
    final lastScan =
        await LocalStorage.getLastScanAt() ??
        0;

    final messages =
        await SmsBridge.readSince(lastScan);

    FirebaseCrashlytics.instance.log(
      'raw=${messages.length}',
    );

    final parsed = messages
        .map(TransactionParser.parse)
        .whereType<TransactionModel>()
        .toList();

    FirebaseCrashlytics.instance.log(
      'parsed=${parsed.length}',
    );

    final localRepo =
        TransactionRepository();

    final newTxns =
        await localRepo.saveAllReturningNew(
          parsed,
        );

    FirebaseCrashlytics.instance.log(
      'inserted=${newTxns.length}',
    );

    try {
      await CloudTransactionRepository()
          .upsertMany(newTxns);
    } catch (e, stack) {
      FirebaseCrashlytics.instance
          .recordError(
            e,
            stack,
            reason:
                'cloud sync failed',
          );
    }

    if (parsed.isNotEmpty) {
      final newest = parsed
          .map((e) => e.timestamp)
          .reduce(
            (a, b) => a > b ? a : b,
          );

      await LocalStorage.setLastScanAt(
        newest - 120000,
      );
    }

    return ScanResult(
      raw: messages.length,
      parsed: parsed.length,
      inserted: newTxns.length,
    );
  } catch (e, stack) {
    FirebaseCrashlytics.instance
        .recordError(
          e,
          stack,
          reason: 'scan failed',
        );

    return const ScanResult(
      raw: 0,
      parsed: 0,
      inserted: 0,
    );
  } finally {
    _running = false;
  }
}
}