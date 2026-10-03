import 'dart:math';

import 'package:game_engine/game_engine.dart';
import 'package:test/test.dart';

import '../fixtures/cards.dart';
import '../fixtures/match_helpers.dart';

void main() {
  group('setup', () {
    test('the initial effect goes apart from the deck', () {
      final match = matchOf([meditatingBrush], [writingTractor]);

      expect(match.area(Player.one).initialEffect.card, loyalty);
      expect(names(match.area(Player.one).deck), ['Meditating Brush']);
    });

    test('a deck cannot include an initial effect', () {
      expect(
        () => PlayerDeck(
          cards: [meditatingBrush, loyalty],
          initialEffect: respect,
        ),
        throwsArgumentError,
      );
    });

    test('copies of the same card are different match cards', () {
      final match = matchOf(
        [meditatingBrush, meditatingBrush],
        [writingTractor],
      );
      final deck = match.area(Player.one).deck;

      expect(deck[0].card, deck[1].card);
      expect(deck[0], isNot(deck[1]));
    });

    test('shuffling keeps the same cards', () {
      final cards = [meditatingBrush, writingTractor, spearStatue, fireAxe];
      final match = GameMatch(
        playerOne: PlayerDeck(cards: cards, initialEffect: loyalty),
        playerTwo: PlayerDeck(cards: [unicornQueen], initialEffect: respect),
        random: Random(7),
      );

      expect(
        names(match.area(Player.one).deck),
        unorderedEquals(cards.map((card) => card.name)),
      );
    });

    test('every card belongs to the player whose deck it came from', () {
      final match = matchOf([meditatingBrush], [writingTractor]);

      expect(match.area(Player.one).deck.single.owner, Player.one);
      expect(match.area(Player.two).deck.single.owner, Player.two);
    });
  });

  group('revealCreatures', () {
    test('reveals until a creature; items and effects go to the hand', () {
      final match = matchOf(
        [fireAxe, huggingHospital, unicornQueen],
        [pumpkinPlanet],
      );

      final revealed = match.revealCreatures();

      expect(names(revealed[Player.one]!), [
        'Fire Axe',
        'Hugging Hospital',
        'Unicorn Queen',
      ]);
      expect(names(match.area(Player.one).hand), [
        'Fire Axe',
        'Hugging Hospital',
      ]);
      expect(
        match.area(Player.one).creatureInPlay!.creature.card,
        unicornQueen,
      );
      expect(match.phase, MatchPhase.play);
    });

    test('cannot reveal outside the reveal phase', () {
      final match = matchOf([meditatingBrush], [writingTractor])
        ..revealCreatures();

      expect(match.revealCreatures, throwsStateError);
    });
  });

  group('equipItem', () {
    test('moves the item from the hand to the creature', () {
      final match = matchOf([fireAxe, meditatingBrush], [luminousMushrooms])
        ..revealCreatures();

      match.equipItem(Player.one, itemInHand(match, Player.one));

      expect(match.area(Player.one).hand, isEmpty);
      expect(match.area(Player.one).creatureInPlay!.items.single.card, fireAxe);
    });

    test('rejects an item whose class does not match', () {
      // Invisible Coat es Magical y Secret; Unicorn Queen es Wild.
      final match = matchOf([invisibleCoat, unicornQueen], [pumpkinPlanet])
        ..revealCreatures();
      final coat = itemInHand(match, Player.one);

      expect(
        match.checkEquipItem(Player.one, coat),
        InvalidPlayReason.classMismatch,
      );
      expect(
        () => match.equipItem(Player.one, coat),
        throwsA(isA<InvalidPlayException>()),
      );
    });

    test('a creature can carry only one item', () {
      final match = matchOf(
        [fireAxe, diamondSword, meditatingBrush],
        [luminousMushrooms],
      )..revealCreatures();
      match.equipItem(Player.one, itemInHand(match, Player.one));

      expect(
        match.checkEquipItem(Player.one, itemInHand(match, Player.one)),
        InvalidPlayReason.creatureAlreadyHasItem,
      );
    });

    test('rejects an item from the rival hand', () {
      final match = matchOf([meditatingBrush], [fireAxe, lightPhoenix])
        ..revealCreatures();

      expect(
        match.checkEquipItem(Player.one, itemInHand(match, Player.two)),
        InvalidPlayReason.notInHand,
      );
    });

    test('rejects playing before the creatures are revealed', () {
      final match = matchOf([fireAxe, meditatingBrush], [writingTractor]);
      final axe = match
          .area(Player.one)
          .deck
          .whereType<MatchCard<Item>>()
          .first;

      expect(
        match.checkEquipItem(Player.one, axe),
        InvalidPlayReason.wrongPhase,
      );
    });

    test('an equipped item can change the result', () {
      // Meditating Brush (Common) con Fire Axe pasa a Epic y vence a
      // Luminous Mushrooms (Rare).
      final match = matchOf([fireAxe, meditatingBrush], [luminousMushrooms])
        ..revealCreatures();
      match.equipItem(Player.one, itemInHand(match, Player.one));

      expect(
        match.resolveClash(),
        const ClashWin(ClashSide.first, WinReason.rarity),
      );
    });
  });

  group('resolveClash', () {
    test('the loser and its item become trophies of the winner', () {
      final suitcase = common('Suitcase Robot', traveler, 1);
      final match = matchOf([spearStatue], [flagsJacket, suitcase])
        ..revealCreatures();
      match.equipItem(Player.two, itemInHand(match, Player.two));

      match.resolveClash();

      expect(names(match.area(Player.one).trophyStack), [
        'Suitcase Robot',
        'Flags Jacket',
      ]);
      expect(match.area(Player.two).creatureInPlay, isNull);
    });

    test('a winner without duration goes to its discard stack with its item', () {
      final match = matchOf([fireAxe, writingTractor], [pumpkinPlanet])
        ..revealCreatures();
      match.equipItem(Player.one, itemInHand(match, Player.one));

      // Writing Tractor con Fire Axe: Epic, 5 + 5 = 10. Pumpkin Planet: Epic, 9.
      expect(
        match.resolveClash(),
        const ClashWin(ClashSide.first, WinReason.power),
      );
      expect(names(match.area(Player.one).discardStack), [
        'Writing Tractor',
        'Fire Axe',
      ]);
      expect(match.area(Player.one).creatureInPlay, isNull);
      expect(match.phase, MatchPhase.reveal);
    });

    test('a winner with duration stays and faces the next creature', () {
      final match = matchOf([unicornQueen], [meditatingBrush, writingTractor]);
      playClash(match);

      expect(
        match.area(Player.one).creatureInPlay!.remaining,
        ClashDuration(3),
      );

      final revealed = match.revealCreatures();
      expect(revealed[Player.one], isEmpty);
      expect(names(revealed[Player.two]!), ['Writing Tractor']);
    });

    test('a winner leaves play once its duration is spent', () {
      // Luminous Mushrooms (Rare, Duration 3) vence a tres Creatures Common.
      final match = matchOf(
        [luminousMushrooms],
        [
          common('First', traveler, 1),
          common('Second', traveler, 1),
          common('Third', traveler, 1),
          common('Fourth', traveler, 1),
        ],
      );

      playClash(match);
      playClash(match);
      expect(match.area(Player.one).creatureInPlay, isNotNull);

      playClash(match);
      expect(match.area(Player.one).creatureInPlay, isNull);
      expect(names(match.area(Player.one).discardStack), [
        'Luminous Mushrooms',
      ]);
      expect(match.area(Player.one).trophyStack, hasLength(3));
    });

    test('a loser becomes a trophy even with duration left', () {
      final match = matchOf([luminousMushrooms], [unicornQueen]);

      expect(
        playClash(match),
        const ClashWin(ClashSide.second, WinReason.rarity),
      );
      expect(names(match.area(Player.two).trophyStack), ['Luminous Mushrooms']);
    });
  });

  group('end of the match', () {
    test('the last card still fights; the match ends at the next reveal', () {
      final match = matchOf([spearStatue], [meditatingBrush, writingTractor]);

      playClash(match);
      expect(match.phase, MatchPhase.reveal);

      match.revealCreatures();
      expect(match.phase, MatchPhase.finished);
      expect(match.result.winner, Player.one);
      expect(match.result.trophiesOfOne, 1);
    });

    test('creatures still in play go to their owner discard stack', () {
      // Unicorn Queen gana y sigue en juego, pero el rival ya no tiene
      // cartas. Al terminar vuelve al Discard Stack de su dueño.
      final match = matchOf([unicornQueen], [meditatingBrush]);

      playClash(match);
      match.revealCreatures();

      expect(match.phase, MatchPhase.finished);
      expect(names(match.area(Player.one).discardStack), ['Unicorn Queen']);
      expect(match.area(Player.one).creatureInPlay, isNull);
    });

    test(
      'a creature revealed when the rival runs out goes to the discard stack',
      () {
        final match = matchOf([spearStatue], [meditatingBrush, writingTractor]);

        playClash(match);
        match.revealCreatures();

        expect(names(match.area(Player.two).discardStack), ['Writing Tractor']);
      },
    );

    test('equal trophies is a draw', () {
      final match = matchOf(
        [spearStatue, meditatingBrush],
        [meditatingBrush, spearStatue],
      );

      playClash(match);
      playClash(match);
      match.revealCreatures();

      expect(match.result.isDraw, isTrue);
      expect(match.result.winner, isNull);
    });

    test('the result is not available before the end', () {
      final match = matchOf([meditatingBrush], [writingTractor]);

      expect(() => match.result, throwsStateError);
    });
  });
}
