import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  static const transactionsBox =
      'transactions_box';

  static Future<void> init() async {
    await Hive.initFlutter();

    await Hive.openBox<Map>(
      transactionsBox,
    );
  }

  static Box<Map> get transactionBox =>
      Hive.box<Map>(transactionsBox);
}