import 'package:clash_of_words/features/catalog/data/asset_catalog_repository.dart';
import 'package:clash_of_words/features/catalog/domain/card_catalog.dart';
import 'package:clash_of_words/features/match/presentation/match_controller.dart';
import 'package:clash_of_words/features/match/presentation/match_screen.dart';
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

  Future<void> showMatch(
    WidgetTester tester,
    ProviderContainer container, {
    Size size = const Size(1920, 1080),
    double pixelRatio = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = pixelRatio;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: MatchScreen()),
      ),
    );
  }

  /// Revela las Creatures y da por vistos los eventos, para tener la mesa
  /// lista en la fase de jugar.
  void reveal(ProviderContainer container) {
    controllerOf(container).reveal();
    skipEvents(container);
  }

  group('the ability button', () {
    testWidgets('explains why it cannot be used before the Clash', (
      tester,
    ) async {
      final container = startGame(
        catalog,
        human: [creatureOf(catalog, Rarity.uncommon)],
        system: [creatureOf(catalog, Rarity.common)],
        humanKind: InitialEffectKind.leadership,
      );
      await showMatch(tester, container);

      await tester.tap(find.text('Use Leadership'));
      await tester.pump();

      expect(find.text('You can only play cards during a Clash.'), findsOne);
    });

    testWidgets(
      'is not shown for an Initial Effect without an active ability',
      (tester) async {
        final container = startGame(
          catalog,
          human: [creatureOf(catalog, Rarity.uncommon)],
          system: [creatureOf(catalog, Rarity.common)],
          humanKind: InitialEffectKind.justice,
        );
        await showMatch(tester, container);

        expect(find.textContaining('Use '), findsNothing);
      },
    );

    testWidgets('asks for confirmation and then uses Leadership', (
      tester,
    ) async {
      final container = startGame(
        catalog,
        human: [creatureOf(catalog, Rarity.uncommon)],
        system: [
          creatureOf(catalog, Rarity.common),
          creatureOf(catalog, Rarity.common, 1),
        ],
        humanKind: InitialEffectKind.leadership,
      );
      reveal(container);
      await showMatch(tester, container);

      await tester.tap(find.text('Use Leadership'));
      await tester.pumpAndSettle();
      expect(find.text('Use Leadership?'), findsOne);
      await tester.tap(find.widgetWithText(FilledButton, 'Use Leadership'));
      await tester.pumpAndSettle();

      expect(find.text('Leadership (used)'), findsOne);
      expect(find.text('Used'), findsOne);
      expect(viewOf(container).match.hasUsedActive(humanPlayer), isTrue);
    });

    testWidgets('lets the student pick a card for Recycle', (tester) async {
      final container = startGame(
        catalog,
        human: [
          creatureOf(catalog, Rarity.uncommon),
          creatureOf(catalog, Rarity.uncommon, 1),
        ],
        system: [
          creatureOf(catalog, Rarity.common),
          creatureOf(catalog, Rarity.common, 1),
        ],
        humanKind: InitialEffectKind.recycle,
      );
      reveal(container);
      controllerOf(container).clash();
      reveal(container);
      await showMatch(tester, container);

      await tester.tap(find.text('Use Recycle'));
      await tester.pumpAndSettle();
      final useButton = find.widgetWithText(FilledButton, 'Use Recycle');
      expect(tester.widget<FilledButton>(useButton).onPressed, isNull);

      await tester.tap(
        find
            .descendant(
              of: find.byType(AlertDialog),
              matching: find.byType(GestureDetector),
            )
            .first,
      );
      await tester.pump();
      await tester.tap(useButton);
      await tester.pumpAndSettle();

      expect(find.text('Recycle (used)'), findsOne);
      expect(viewOf(container).match.area(humanPlayer).deck, hasLength(1));
    });

    testWidgets('lets the student reorder the cards for Honesty', (
      tester,
    ) async {
      List<GameCard> deck(int skip) => [
        creatureOf(catalog, Rarity.uncommon, skip),
        for (var i = 1; i <= 3; i++)
          creatureOf(catalog, Rarity.common, skip + i),
      ];
      final container = startGame(
        catalog,
        human: deck(0),
        system: deck(10),
        humanKind: InitialEffectKind.honesty,
      );
      reveal(container);
      final before = viewOf(container).match.area(humanPlayer).deck;
      await showMatch(tester, container);

      await tester.tap(find.text('Use Honesty'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Move right').first);
      await tester.pump();
      await tester.tap(find.text('Put them back'));
      await tester.pumpAndSettle();

      final after = viewOf(container).match.area(humanPlayer).deck;
      expect(after.first, before[1]);
      expect(after[1], before.first);
      expect(find.text('Honesty (used)'), findsOne);
    });
  });

  group('on a phone-sized screen', () {
    testWidgets('the side panel fits, with the ability button and the log', (
      tester,
    ) async {
      final container = startGame(
        catalog,
        human: [
          creatureOf(catalog, Rarity.uncommon),
          creatureOf(catalog, Rarity.common, 3),
        ],
        system: [
          creatureOf(catalog, Rarity.common),
          creatureOf(catalog, Rarity.common, 1),
        ],
        humanKind: InitialEffectKind.leadership,
      );
      reveal(container);
      // 800 x 360 píxeles lógicos, como un teléfono en horizontal.
      await showMatch(
        tester,
        container,
        size: const Size(2400, 1080),
        pixelRatio: 3,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Use Leadership'), findsOne);
      expect(find.text('Clash!'), findsOne);
      // El registro sigue teniendo espacio para varias líneas.
      final logFinder = find.byWidgetPredicate(
        (widget) => widget is ListView && widget.reverse,
      );
      final log = tester.getSize(logFinder);
      expect(log.height, greaterThan(60));
    });
  });

  group('the Commitment decision', () {
    ProviderContainer lostClash() {
      final container = startGame(
        catalog,
        human: [
          creatureOf(catalog, Rarity.common),
          creatureOf(catalog, Rarity.common, 1),
        ],
        system: [
          creatureOf(catalog, Rarity.rare),
          creatureOf(catalog, Rarity.rare, 1),
        ],
        humanKind: InitialEffectKind.commitment,
      );
      reveal(container);
      controllerOf(container).clash();
      return container;
    }

    testWidgets('appears when the student loses a Clash', (tester) async {
      final container = lostClash();
      await showMatch(tester, container);

      expect(find.text('You lost the Clash'), findsOne);
      expect(find.text('Decline'), findsOne);
      expect(find.text('Use Commitment'), findsOne);
    });

    testWidgets('using it wins the Clash and closes the decision', (
      tester,
    ) async {
      final container = lostClash();
      await showMatch(tester, container);

      await tester.tap(find.text('Use Commitment'));
      await tester.pump();

      expect(find.text('You lost the Clash'), findsNothing);
      expect(find.text('Commitment (used)'), findsOne);
      expect(
        viewOf(container).lastResult,
        const ClashWin(ClashSide.first, WinReason.commitment),
      );
    });

    testWidgets('declining applies the Clash and keeps the ability', (
      tester,
    ) async {
      final container = lostClash();
      await showMatch(tester, container);

      await tester.tap(find.text('Decline'));
      await tester.pump();

      expect(find.text('You lost the Clash'), findsNothing);
      expect(find.text('Commitment (after losing a Clash)'), findsOne);
      expect(viewOf(container).match.hasUsedActive(humanPlayer), isFalse);
    });
  });
}
