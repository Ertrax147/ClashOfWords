import 'package:clash_of_words/features/catalog/data/asset_catalog_repository.dart';
import 'package:clash_of_words/features/catalog/domain/card_catalog.dart';
import 'package:clash_of_words/features/match/presentation/match_controller.dart';
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

  Creature creature(Rarity rarity, [int skip = 0]) =>
      creatureOf(catalog, rarity, skip);

  /// Partida sin barajar en la que el estudiante tiene [humanKind] y el
  /// sistema [systemKind]. Las Creatures salen en el orden dado.
  ({ProviderContainer container, MatchController controller}) start({
    required List<GameCard> human,
    required List<GameCard> system,
    required InitialEffectKind humanKind,
    InitialEffectKind systemKind = InitialEffectKind.respect,
  }) {
    final container = startGame(
      catalog,
      human: human,
      system: system,
      humanKind: humanKind,
      systemKind: systemKind,
    );
    return (container: container, controller: controllerOf(container));
  }

  group('using the active ability', () {
    test('is rejected outside the play phase, with a message', () {
      final game = start(
        human: [creature(Rarity.uncommon)],
        system: [creature(Rarity.common)],
        humanKind: InitialEffectKind.leadership,
      );

      expect(
        game.controller.useInitialEffect(),
        'You can only play cards during a Clash.',
      );
    });

    test('Leadership keeps the creature for 3 Clashes and is logged', () {
      final game = start(
        human: [creature(Rarity.uncommon)],
        system: [creature(Rarity.common), creature(Rarity.common, 1)],
        humanKind: InitialEffectKind.leadership,
      );
      game.controller.reveal();

      expect(game.controller.useInitialEffect(), isNull);

      final view = viewOf(game.container);
      expect(view.match.hasUsedActive(humanPlayer), isTrue);
      expect(
        view.match.area(humanPlayer).creatureInPlay!.remaining,
        ClashDuration(3),
      );
      expect(view.log.last, startsWith('You used Leadership'));
      expect(game.controller.useInitialEffect(), isNotNull);
    });

    test('Kindness shows the stolen card and puts it in the trophy stack', () {
      final game = start(
        human: [creature(Rarity.uncommon)],
        system: [
          creature(Rarity.common),
          creature(Rarity.common, 1),
          creature(Rarity.common, 2),
        ],
        humanKind: InitialEffectKind.kindness,
      );
      game.controller.reveal();
      final stolen = viewOf(game.container).match.area(systemPlayer).deck.first;

      expect(game.controller.useInitialEffect(), isNull);

      final view = viewOf(game.container);
      expect(view.match.area(humanPlayer).trophyStack, [stolen]);
      expect(view.events.last.card, stolen.card);
      expect(view.log.last, contains('you took ${stolen.card.name}'));
    });

    test('Recycle brings the chosen creature back to the deck', () {
      final game = start(
        human: [creature(Rarity.uncommon), creature(Rarity.uncommon, 1)],
        system: [creature(Rarity.common), creature(Rarity.common, 1)],
        humanKind: InitialEffectKind.recycle,
      );
      game.controller
        ..reveal()
        ..clash()
        ..reveal();
      final match = viewOf(game.container).match;
      final options = match.activeOptions(humanPlayer);
      expect(options, hasLength(1));

      expect(
        game.controller.useInitialEffect(CardChoice(options.single)),
        null,
      );

      final after = viewOf(game.container).match;
      expect(after.area(humanPlayer).deck, [options.single]);
      expect(
        viewOf(game.container).log.last,
        contains('goes back to your Deck'),
      );
    });

    test('is rejected with a message when there is nothing to act on', () {
      final game = start(
        human: [creature(Rarity.uncommon)],
        system: [creature(Rarity.common)],
        humanKind: InitialEffectKind.recycle,
      );
      game.controller.reveal();

      // Sin Creatures en el Discard Stack, Recycle no tiene sobre qué actuar.
      expect(
        game.controller.useInitialEffect(),
        'There is nothing to use it on.',
      );
    });

    test('Responsibility brings the chosen item back to the deck', () {
      final fireAxe = catalog.cardsOf<Item>().firstWhere(
        (item) => item.name == 'Fire Axe',
      );
      final game = start(
        human: [
          fireAxe,
          creature(Rarity.uncommon),
          creature(Rarity.uncommon, 1),
        ],
        system: [creature(Rarity.common), creature(Rarity.common, 1)],
        humanKind: InitialEffectKind.responsibility,
      );
      game.controller.reveal();
      final axe = viewOf(game.container).match.area(humanPlayer).hand.single;
      expect(game.controller.playCard(axe), isNull);
      game.controller
        ..clash()
        ..reveal();
      final options = viewOf(game.container).match.activeOptions(humanPlayer);
      expect(options, [axe]);

      expect(game.controller.useInitialEffect(CardChoice(axe)), isNull);

      final view = viewOf(game.container);
      expect(view.match.area(humanPlayer).deck, [axe]);
      expect(view.log.last, contains('Fire Axe goes back to your Deck'));
    });

    test('Loyalty brings a lost creature back to the discard stack', () {
      final game = start(
        human: [creature(Rarity.common), creature(Rarity.common, 1)],
        system: [creature(Rarity.rare), creature(Rarity.rare, 1)],
        humanKind: InitialEffectKind.loyalty,
      );
      game.controller
        ..reveal()
        ..clash()
        ..reveal();
      final lost = viewOf(game.container).match.activeOptions(humanPlayer);
      expect(lost, hasLength(1));

      expect(game.controller.useInitialEffect(CardChoice(lost.single)), null);

      final match = viewOf(game.container).match;
      expect(match.area(humanPlayer).discardStack, lost);
      expect(match.area(systemPlayer).trophyStack, isEmpty);
      expect(viewOf(game.container).log.last, contains('returns to your'));
    });

    test('Creativity plays the chosen creature from the deck', () {
      final game = start(
        human: [
          creature(Rarity.common),
          creature(Rarity.uncommon),
          creature(Rarity.rare),
        ],
        system: [creature(Rarity.common, 1)],
        humanKind: InitialEffectKind.creativity,
      );
      game.controller.reveal();
      final options = viewOf(game.container).match.activeOptions(humanPlayer);
      expect(options, hasLength(2));
      final chosen = options.last;

      expect(game.controller.useInitialEffect(CardChoice(chosen)), isNull);

      final view = viewOf(game.container);
      expect(view.match.area(humanPlayer).creatureInPlay!.creature, chosen);
      expect(view.log.last, contains('replaces your Creature'));
    });

    test('Generosity takes an item from the rival hand', () {
      // El rival equipa lo que puede apenas se revela; este Item no puede
      // equiparlo por su Class, así que se queda en su Hand.
      final rival = creature(Rarity.common);
      final item = catalog.cardsOf<Item>().firstWhere(
        (item) =>
            item.classes.isNotEmpty &&
            item.forbiddenRarities.isEmpty &&
            !item.canBeEquippedTo(rival),
      );
      final game = start(
        human: [creature(Rarity.uncommon)],
        system: [item, rival],
        humanKind: InitialEffectKind.generosity,
      );
      game.controller.reveal();
      final options = viewOf(game.container).match.activeOptions(humanPlayer);
      expect(options, hasLength(1));

      expect(
        game.controller.useInitialEffect(CardChoice(options.single)),
        null,
      );

      final match = viewOf(game.container).match;
      expect(match.area(humanPlayer).hand, options);
      expect(match.area(systemPlayer).hand, isEmpty);
      expect(
        viewOf(game.container).log.last,
        contains("from your opponent's hand"),
      );
    });
  });

  group('Commitment', () {
    // El estudiante tiene Common y el sistema Legendary: pierde por Rarity.
    ({ProviderContainer container, MatchController controller}) lostClash() {
      final game = start(
        human: [creature(Rarity.common), creature(Rarity.common, 1)],
        system: [creature(Rarity.rare), creature(Rarity.rare, 1)],
        humanKind: InitialEffectKind.commitment,
      );
      game.controller
        ..reveal()
        ..clash();
      return game;
    }

    test('waits for the student when the Clash is lost', () {
      final game = lostClash();

      final view = viewOf(game.container);
      expect(view.awaitingCommitment, isTrue);
      expect(view.match.phase, MatchPhase.afterClash);
      expect(view.match.area(systemPlayer).creatureInPlay, isNotNull);
      expect(view.lastResult, isNull);
    });

    test('using it wins the Clash and says so', () {
      final game = lostClash();

      expect(game.controller.useInitialEffect(), isNull);

      final view = viewOf(game.container);
      expect(view.awaitingCommitment, isFalse);
      expect(view.match.phase, MatchPhase.reveal);
      expect(
        view.lastResult,
        const ClashWin(ClashSide.first, WinReason.commitment),
      );
      expect(view.log, contains('You used Commitment: you win the Clash.'));
      expect(view.log.last, 'You win the Clash thanks to Commitment.');
      expect(view.match.area(humanPlayer).trophyStack, hasLength(1));
    });

    test('declining applies the Clash and keeps the ability for later', () {
      final game = lostClash();

      game.controller.declineCommitment();

      var view = viewOf(game.container);
      expect(view.awaitingCommitment, isFalse);
      expect(
        view.lastResult,
        const ClashWin(ClashSide.second, WinReason.rarity),
      );
      expect(view.match.hasUsedActive(humanPlayer), isFalse);

      // En el Clash siguiente vuelve a perder y la decisión se abre otra vez.
      game.controller
        ..reveal()
        ..clash();
      view = viewOf(game.container);
      expect(view.awaitingCommitment, isTrue);
    });

    test('a loss of the system with Commitment is applied without asking', () {
      final game = start(
        human: [creature(Rarity.rare)],
        system: [creature(Rarity.common)],
        humanKind: InitialEffectKind.respect,
        systemKind: InitialEffectKind.commitment,
      );
      game.controller
        ..reveal()
        ..clash();

      final view = viewOf(game.container);
      expect(view.awaitingCommitment, isFalse);
      expect(view.match.phase, MatchPhase.reveal);
      expect(
        view.lastResult,
        const ClashWin(ClashSide.first, WinReason.rarity),
      );
    });
  });
}
