import 'dart:math';

import 'package:clash_of_words/features/catalog/data/asset_catalog_repository.dart';
import 'package:clash_of_words/features/catalog/domain/card_catalog.dart';
import 'package:clash_of_words/features/match/presentation/match_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_engine/game_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CardCatalog catalog;

  setUpAll(() async {
    catalog = await AssetCatalogRepository().loadCatalog();
  });

  ProviderContainer containerWithSeed(int seed) {
    final container = ProviderContainer(
      overrides: [matchRandomProvider.overrideWithValue(Random(seed))],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('there is no match until one starts', () {
    final container = containerWithSeed(1);

    expect(container.read(matchControllerProvider), isNull);
  });

  test('starting a match deals random decks and logs the initial effects', () {
    final container = containerWithSeed(1);

    container.read(matchControllerProvider.notifier).startMatch(catalog);

    final view = container.read(matchControllerProvider)!;
    expect(view.match.phase, MatchPhase.reveal);
    expect(view.log.first, startsWith('Match started.'));
  });

  test('a full match with the real catalog reaches the end', () {
    for (var seed = 0; seed < 20; seed++) {
      final container = containerWithSeed(seed);
      final controller = container.read(matchControllerProvider.notifier)
        ..startMatch(catalog);

      var steps = 0;
      while (container.read(matchControllerProvider)!.match.phase !=
          MatchPhase.finished) {
        expect(steps++, lessThan(400), reason: 'seed $seed never ends');
        final view = container.read(matchControllerProvider)!;
        if (view.match.phase == MatchPhase.reveal) {
          controller.reveal();
        } else {
          // El estudiante juega todo lo que puede, como el rival.
          for (final card in view.match.area(humanPlayer).hand) {
            if (view.match.phase == MatchPhase.play) controller.playCard(card);
          }
          if (view.match.phase == MatchPhase.play) controller.clash();
        }
      }

      expect(
        container.read(matchControllerProvider)!.log.last,
        startsWith('Match over.'),
      );
    }
  });

  test('revealing queues one event per card, shown one at a time', () {
    final container = containerWithSeed(1);
    final controller = container.read(matchControllerProvider.notifier)
      ..startMatch(catalog)
      ..reveal();

    final view = container.read(matchControllerProvider)!;
    final revealed = view.log.where((line) => line.contains('revealed'));
    expect(view.events.length, greaterThanOrEqualTo(revealed.length));
    expect(view.events.first.caption, contains('revealed'));

    final pending = view.events.length;
    controller.dismissEvent();

    expect(
      container.read(matchControllerProvider)!.events,
      hasLength(pending - 1),
    );
  });

  test('a revealed card says where it goes', () {
    final container = containerWithSeed(1);
    container.read(matchControllerProvider.notifier)
      ..startMatch(catalog)
      ..reveal();

    final captions = container
        .read(matchControllerProvider)!
        .events
        .map((event) => event.caption);

    expect(
      captions.where((caption) => caption.contains('revealed')),
      everyElement(anyOf(contains('to the Clash'), contains('hand'))),
    );
  });

  test('an invalid play explains why in English', () {
    final container = containerWithSeed(1);
    final controller = container.read(matchControllerProvider.notifier)
      ..startMatch(catalog);
    final match = container.read(matchControllerProvider)!.match;
    final card = match.area(humanPlayer).deck.first;

    // Antes de revelar no se puede jugar ninguna carta.
    final message = controller.playCard(card);

    expect(message, isNotNull);
  });

  test('describe and explain read naturally', () {
    expect(
      describe(const ClashWin(ClashSide.first, WinReason.rarity)),
      'You win the Clash by Rarity.',
    );
    expect(
      explain(InvalidPlayReason.classMismatch),
      "This Item does not match your Creature's Class.",
    );
  });
}
