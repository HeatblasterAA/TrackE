import 'package:app/core/services/sms_bridge.dart';
import 'package:app/features/parser/transaction_parser.dart';
import 'package:app/models/transaction_model.dart';
import 'package:app/repositories/cloud_transaction_repository.dart';
import 'package:app/repositories/transaction_repository.dart';

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
  static Future<ScanResult> scan() async {
    final messages =
        await SmsBridge.readHistory();

    final parsed = messages
        .map(TransactionParser.parse)
        .whereType<TransactionModel>()
        .toList();

    final localRepo =
        TransactionRepository();

    final inserted =
        await localRepo.saveAllIfNew(parsed);

    // upload all parsed (Firestore dedups by doc id)
    await CloudTransactionRepository()
        .upsertMany(parsed);

    return ScanResult(
      raw: messages.length,
      parsed: parsed.length,
      inserted: inserted,
    );
  }
}