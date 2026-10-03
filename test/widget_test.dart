import 'package:clash_of_words/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('the home screen loads the cards and offers a match', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: ClashOfWordsApp()));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();

    expect(find.text('Clash of Words'), findsOneWidget);
    expect(find.text('Play vs System (Easy)'), findsOneWidget);
  });
}
