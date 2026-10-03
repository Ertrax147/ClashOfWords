import 'package:clash_of_words/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('the app starts and shows its title', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: ClashOfWordsApp()));

    expect(find.text('Clash of Words'), findsOneWidget);
  });
}
