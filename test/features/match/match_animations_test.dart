import 'package:clash_of_words/features/catalog/data/asset_catalog_repository.dart';
import 'package:clash_of_words/features/catalog/domain/card_catalog.dart';
import 'package:clash_of_words/features/match/presentation/match_screen.dart';
import 'package:clash_of_words/features/match/presentation/widgets/event_overlay.dart';
import 'package:clash_of_words/features/match/presentation/widgets/move_layer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_engine/game_engine.dart';

import 'match_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CardCatalog catalog;

  setUpAll(() async {
    catalog = await AssetCatalogRepository().loadCatalog();
  });

  /// Partida en la que el estudiante gana el primer Clash por Rarity.
  ProviderContainer winningMatch() => startGame(
    catalog,
    human: [creatureOf(catalog, Rarity.uncommon)],
    system: [creatureOf(catalog, Rarity.common)],
    humanKind: InitialEffectKind.leadership,
  );

  Future<void> showMatch(
    WidgetTester tester,
    ProviderContainer container,
  ) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: MatchScreen()),
      ),
    );
  }

  group('the cards of a Clash', () {
    testWidgets('are shown with the result and then sent to their piles', (
      tester,
    ) async {
      final container = winningMatch();
      controllerOf(container).reveal();
      skipEvents(container);
      await showMatch(tester, container);

      controllerOf(container).clash();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(MoveLayer), findsOne);
      // Las cartas siguen a la vista mientras se muestra el resultado.
      await tester.pump(const Duration(milliseconds: 600));
      expect(
        find.descendant(
          of: find.byType(MoveLayer),
          matching: find.text('You win the Clash by Rarity.'),
        ),
        findsOne,
      );
      // La mesa de fondo todavía no cuenta lo que pasó: sin trofeos, sin
      // el resultado en el medio ni en el registro.
      expect(find.text('No trophies'), findsNWidgets(2));
      expect(find.text('You win the Clash by Rarity.'), findsOne);

      await tester.pumpAndSettle();

      expect(find.byType(MoveLayer), findsNothing);
      expect(viewOf(container).moves, isNull);
      // Cuando las cartas llegan, la mesa y el registro lo cuentan.
      expect(find.text('No trophies'), findsOne);
      expect(find.text('You win the Clash by Rarity.'), findsNWidgets(2));
    });

    testWidgets('block the buttons until they arrive', (tester) async {
      final container = winningMatch();
      controllerOf(container).reveal();
      skipEvents(container);
      await showMatch(tester, container);
      controllerOf(container).clash();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Reveal'), warnIfMissed: false);
      await tester.pump();

      expect(viewOf(container).match.phase, MatchPhase.reveal);
      expect(viewOf(container).events, isEmpty);

      await tester.pumpAndSettle();
      await tester.tap(find.text('Reveal'));
      await tester.pump();
      expect(viewOf(container).match.phase, isNot(MatchPhase.reveal));
    });

    testWidgets('are not animated when the system turns animations off', (
      tester,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final container = winningMatch();
      controllerOf(container).reveal();
      skipEvents(container);
      await showMatch(tester, container);

      controllerOf(container).clash();
      await tester.pump();
      await tester.pump();

      expect(viewOf(container).moves, isNull);
      expect(find.byType(MoveLayer), findsNothing);
    });
  });

  group('a revealed card', () {
    testWidgets('travels to its place when the notice closes', (tester) async {
      final container = winningMatch();
      controllerOf(container).reveal();
      expect(viewOf(container).events, isNotEmpty);
      await showMatch(tester, container);
      // Hasta que aterrizan, las Creatures reveladas no están en la mesa.
      expect(find.text('Creature'), findsNWidgets(2));

      await tester.tap(find.byType(EventOverlay));
      await tester.pump(const Duration(milliseconds: 200));
      // Mientras viaja, el aviso sigue en pantalla.
      expect(viewOf(container).events, isNotEmpty);

      // Cada aviso se cierra solo al pasar su tiempo.
      for (var i = 0; i < 20 && viewOf(container).events.isNotEmpty; i++) {
        await tester.pump(EventOverlay.displayTime);
        await tester.pumpAndSettle();
      }

      expect(viewOf(container).events, isEmpty);
      expect(find.byType(EventOverlay), findsNothing);
      expect(find.text('Creature'), findsNothing);
    });
  });
}
