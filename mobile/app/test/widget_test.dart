import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/app.dart';

void main() {
  testWidgets('TrackE app renders', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: TrackEApp(),
      ),
    );

    expect(find.text('TrackE'), findsOneWidget);
  });
}