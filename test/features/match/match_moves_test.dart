import 'package:clash_of_words/features/catalog/data/asset_catalog_repository.dart';
import 'package:clash_of_words/features/catalog/domain/card_catalog.dart';
import 'package:clash_of_words/features/match/presentation/match_controller.dart';
import 'package:clash_of_words/features/match/presentation/match_zones.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_engine/game_engine.dart';

import 'match_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CardCatalog catalog;

  setUpAll(() async {
    catalog = await AssetCatalogRepository().loadCatalog();
  });

  /// Los movimientos del lote pendiente, como "nombre: origen -> destino".
  List<String> described(MoveBatch? batch) => [
    for (final move in batch?.moves ?? <MatchMove>[])
      '${move.card.card.name}: ${move.from.player.name} ${move.from.kind.name}'
          ' -> ${move.to.player.name} ${move.to.kind.name}',
  ];

  group('the cards that move after a play', () {
    test(
      'revealing moves nothing: the revealed cards have their own notice',
      () {
        final container = startGame(
          catalog,
          human: [creatureOf(catalog, Rarity.uncommon)],
          system: [creatureOf(catalog, Rarity.common)],
          humanKind: InitialEffectKind.leadership,
        );

        controllerOf(container).reveal();

        expect(viewOf(container).events, isNotEmpty);
        expect(viewOf(container).moves, isNull);
      },
    );

    test('a won Clash sends each creature to its pile, shown as a Clash', () {
      final mine = creatureOf(catalog, Rarity.uncommon);
      final theirs = creatureOf(catalog, Rarity.common);
      final container = startGame(
        catalog,
        human: [mine],
        system: [theirs],
        humanKind: InitialEffectKind.leadership,
      );
      controllerOf(container).reveal();
      skipEvents(container);

      controllerOf(container).clash();

      final batch = viewOf(container).moves!;
      expect(
        batch.clashResult,
        const ClashWin(ClashSide.first, WinReason.rarity),
      );
      expect(described(batch), [
        '${mine.name}: one creature -> one discard',
        '${theirs.name}: two creature -> one trophy',
      ]);
    });

    test('equipping an item moves it from the hand to the creature', () {
      final axe = catalog.cardsOf<Item>().firstWhere(
        (item) => item.name == 'Fire Axe',
      );
      final container = startGame(
        catalog,
        human: [axe, creatureOf(catalog, Rarity.uncommon)],
        system: [creatureOf(catalog, Rarity.common)],
        humanKind: InitialEffectKind.leadership,
      );
      controllerOf(container).reveal();
      skipEvents(container);
      final card = viewOf(container).match.area(humanPlayer).hand.single;

      expect(controllerOf(container).playCard(card), isNull);

      final batch = viewOf(container).moves!;
      expect(described(batch), ['Fire Axe: one hand -> one creature']);
      expect(batch.clashResult, isNull);
    });

    test('finishing the animation clears the pending moves', () {
      final container = startGame(
        catalog,
        human: [creatureOf(catalog, Rarity.uncommon)],
        system: [creatureOf(catalog, Rarity.common)],
        humanKind: InitialEffectKind.leadership,
      );
      controllerOf(container).reveal();
      skipEvents(container);
      controllerOf(container).clash();
      expect(viewOf(container).moves, isNotNull);

      controllerOf(container).finishMoves();

      expect(viewOf(container).moves, isNull);
    });

    test('Commitment moves cards only once the student decides', () {
      final container = startGame(
        catalog,
        human: [creatureOf(catalog, Rarity.common)],
        system: [creatureOf(catalog, Rarity.rare)],
        humanKind: InitialEffectKind.commitment,
      );
      controllerOf(container).reveal();
      skipEvents(container);

      controllerOf(container).clash();
      expect(viewOf(container).moves, isNull);

      controllerOf(container).useInitialEffect();
      final batch = viewOf(container).moves!;
      expect(
        batch.clashResult,
        const ClashWin(ClashSide.first, WinReason.commitment),
      );
      expect(described(batch), hasLength(2));
    });

    test('Kindness animates only through its notice', () {
      final container = startGame(
        catalog,
        human: [creatureOf(catalog, Rarity.uncommon)],
        system: [
          creatureOf(catalog, Rarity.common),
          creatureOf(catalog, Rarity.common, 1),
        ],
        humanKind: InitialEffectKind.kindness,
      );
      controllerOf(container).reveal();
      skipEvents(container);

      controllerOf(container).useInitialEffect();

      final view = viewOf(container);
      expect(view.moves, isNull);
      expect(
        view.events.single.destination,
        const Zone(humanPlayer, ZoneKind.trophy),
      );
    });
  });

  group('what the table shows while cards are still on their way', () {
    test('hides the moving cards and the revealed ones until they arrive', () {
      final mine = creatureOf(catalog, Rarity.uncommon);
      final theirs = creatureOf(catalog, Rarity.common);
      final container = startGame(
        catalog,
        human: [mine],
        system: [theirs],
        humanKind: InitialEffectKind.leadership,
      );

      controllerOf(container).reveal();
      final revealing = viewOf(container);
      expect(revealing.animating, isTrue);
      expect(revealing.hiddenCardIds, hasLength(2));

      skipEvents(container);
      expect(viewOf(container).animating, isFalse);
      expect(viewOf(container).hiddenCardIds, isEmpty);

      controllerOf(container).clash();
      final clashing = viewOf(container);
      expect(clashing.animating, isTrue);
      expect(clashing.hiddenCardIds, hasLength(2));

      controllerOf(container).finishMoves();
      expect(viewOf(container).hiddenCardIds, isEmpty);
    });

    test('the log waits for the cards before telling what happened', () {
      final container = startGame(
        catalog,
        human: [creatureOf(catalog, Rarity.uncommon)],
        system: [creatureOf(catalog, Rarity.common)],
        humanKind: InitialEffectKind.leadership,
      );
      controllerOf(container).reveal();
      skipEvents(container);
      final before = viewOf(container).log.length;

      controllerOf(container).clash();

      final clashing = viewOf(container);
      expect(clashing.log.length, greaterThan(before));
      expect(clashing.visibleLog, hasLength(before));

      controllerOf(container).finishMoves();
      expect(viewOf(container).visibleLog, viewOf(container).log);
    });
  });

  group('diffZones', () {
    test('ignores cards that stay in the same place', () {
      final container = startGame(
        catalog,
        human: [creatureOf(catalog, Rarity.uncommon)],
        system: [creatureOf(catalog, Rarity.common)],
        humanKind: InitialEffectKind.leadership,
      );
      final match = viewOf(container).match;

      expect(diffZones(snapshotZones(match), snapshotZones(match)), isEmpty);
    });

    test('does not include the initial effects', () {
      final container = startGame(
        catalog,
        human: [creatureOf(catalog, Rarity.uncommon)],
        system: [creatureOf(catalog, Rarity.common)],
        humanKind: InitialEffectKind.leadership,
      );
      final match = viewOf(container).match;

      final names = [
        for (final entry in snapshotZones(match).values) entry.card.card.name,
      ];
      expect(names, isNot(contains('Leadership')));
    });
  });
}
