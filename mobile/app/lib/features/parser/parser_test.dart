import 'mock_sms.dart';
import 'transaction_parser.dart';

class ParserTest {
  static void run() {
    int passed = 0;
    int failed = 0;

    for (final sms in mockSms) {
      final parsed =
          TransactionParser.parse(sms);

      if (parsed != null) {
        passed++;

        print('✅ ${parsed.toMap()}');
      } else {
        failed++;

        print('❌ rejected');
        print(sms['body']);
      }

      print('----------------');
    }

    print('passed: $passed');
    print('failed: $failed');
  }
}