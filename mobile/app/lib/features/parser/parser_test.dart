import 'mock_notifications.dart';
import 'transaction_parser.dart';

/// In-app smoke runner. Not a flutter_test — call ParserTest.run() from
/// a debug action when tuning the parser.
class ParserTest {
  static void run() {
    int passed = 0;
    int failed = 0;
    int needsReview = 0;

    for (final signal in mockNotifications) {
      final parsed = TransactionParser.parseSignal(signal);

      if (parsed != null) {
        passed++;
        if (parsed.needsReview) needsReview++;
        // ignore: avoid_print
        print(
          'OK  conf=${parsed.confidence.toStringAsFixed(2)} '
          'review=${parsed.needsReview} ${parsed.toMap()}',
        );
      } else {
        failed++;
        // ignore: avoid_print
        print('REJECT  ${signal.sender}  ${signal.body}');
      }

      // ignore: avoid_print
      print('----------------');
    }

    // ignore: avoid_print
    print('passed: $passed   failed: $failed   needsReview: $needsReview');
  }
}
