import 'package:app/core/storage/hive_service.dart';
import 'package:app/models/transaction_model.dart';

class TransactionRepository {
  final box = HiveService.transactionBox;

  Future<int> saveAllIfNew(
    List<TransactionModel> transactions,
  ) async {
    int inserted = 0;

    for (final txn in transactions) {
      if (box.containsKey(txn.id)) {
        continue;
      }

      await box.put(
        txn.id,
        txn.toMap(),
      );

      inserted++;
    }

    return inserted;
  }
  Future<void> replaceAll(
  List<Map<String, dynamic>> txns,
) async {
  await box.clear();

  for (final txn in txns) {
    await box.put(txn['id'], txn);
  }
}

  List<Map> getAll() {
    return box.values.toList()
      ..sort(
        (a, b) =>
            (b['timestamp'] as int).compareTo(
          a['timestamp'] as int,
        ),
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
          (b['timestamp'] as int).compareTo(
        a['timestamp'] as int,
      ),
    );
}
}