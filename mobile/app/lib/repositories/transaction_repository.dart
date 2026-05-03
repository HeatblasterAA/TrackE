import 'package:app/core/storage/hive_service.dart';
import 'package:app/models/transaction_model.dart';

class TransactionRepository {
  final box = HiveService.transactionBox;

  Future<List<TransactionModel>> saveAllReturningNew(
    List<TransactionModel> transactions,
  ) async {
    final inserted = <TransactionModel>{};
    final batch = <String, Map<String, dynamic>>{};

    for (final txn in transactions) {
      if (box.containsKey(txn.id)) continue;
      batch[txn.id] = txn.toMap();
      inserted.add(txn);
    }

    if (batch.isNotEmpty) {
      await box.putAll(batch);
    }

    return inserted.toList();
  }

  Future<void> upsert(TransactionModel txn) async {
    await box.put(txn.id, txn.toMap());
  }

  Future<void> replaceAll(
    List<Map<String, dynamic>> txns,
  ) async {
    await box.clear();
    for (final txn in txns) {
      await box.put(txn['id'], txn);
    }
  }

  TransactionModel? getById(String id) {
    final raw = box.get(id);
    if (raw == null) return null;
    return TransactionModel.fromMap(raw);
  }

  List<Map> getAll() {
    return box.values.toList()
      ..sort(
        (a, b) =>
            (b['timestamp'] as int).compareTo(a['timestamp'] as int),
      );
  }

  int count() => box.length;

  Future<void> clear() async {
    await box.clear();
  }

  List<Map<String, dynamic>> getAllTyped() {
    return box.values
        .map(
          (e) => Map<String, dynamic>.from(
            Map<dynamic, dynamic>.from(e),
          ),
        )
        .toList()
      ..sort(
        (a, b) =>
            (b['timestamp'] as int).compareTo(a['timestamp'] as int),
      );
  }

  /// All transactions that the parser flagged as low-confidence and the
  /// user hasn't yet corrected. Newest first.
  List<TransactionModel> getNeedsReview() {
    return box.values
        .map((e) => TransactionModel.fromMap(e))
        .where((t) => t.needsReview)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  int needsReviewCount() {
    var n = 0;
    for (final v in box.values) {
      if ((v['needsReview'] as bool?) == true) n++;
    }
    return n;
  }
}
