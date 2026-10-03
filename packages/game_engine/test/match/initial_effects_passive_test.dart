import 'package:game_engine/game_engine.dart';
import 'package:test/test.dart';

import '../fixtures/cards.dart';
import '../fixtures/match_helpers.dart';

/// Partida en la que el jugador uno tiene el Initial Effect [kind].
GameMatch matchWith(
  InitialEffectKind kind,
  List<GameCard> one,
  List<GameCard> two, {
  InitialEffectKind? rivalKind,
}) => matchOf(
  one,
  two,
  oneEffect: initialEffectOf(kind),
  twoEffect: rivalKind == null ? null : initialEffectOf(rivalKind),
);

void main() {
  group('Diversity', () {
    test('the first creature of each class gets +2; the next ones do not', () {
      final match = matchWith(
        InitialEffectKind.diversity,
        [common('First Wild', wild, 3), common('Second Wild', wild, 3)],
        [common('Rock', warrior, 1), common('Stone', warrior, 1)],
      );

      match.revealCreatures();
      expect(match.statsOf(Player.one)!.power, 5);

      match.resolveClash();
      match.revealCreatures();
      expect(match.statsOf(Player.one)!.power, 3);
    });
  });

  group('Tolerance', () {
    test('the first 3 defeated creatures go to their own discard stack', () {
      // Unicorn Queen (Legendary, Duration 4) vence a 4 Creatures Common del
      // jugador dos, que tiene Tolerance.
      final match = matchOf(
        [unicornQueen],
        [
          flagsJacket,
          common('Bag', traveler, 1),
          common('Second', traveler, 1),
          common('Third', traveler, 1),
          common('Fourth', traveler, 1),
        ],
        twoEffect: initialEffectOf(InitialEffectKind.tolerance),
      )..revealCreatures();
      match.equipItem(Player.two, itemInHand(match, Player.two));
      match.resolveClash();
      playClash(match);
      playClash(match);
      playClash(match);

      expect(names(match.area(Player.two).discardStack), [
        'Bag',
        'Flags Jacket',
        'Second',
        'Third',
      ]);
      expect(names(match.area(Player.one).trophyStack), ['Fourth']);
    });
  });

  group('Responsibility', () {
    test('a creature can carry several items', () {
      final match = matchWith(
        InitialEffectKind.responsibility,
        [fireAxe, diamondSword, meditatingBrush],
        [pumpkinPlanet],
      )..revealCreatures();

      match.equipItem(Player.one, itemInHand(match, Player.one));
      match.equipItem(Player.one, itemInHand(match, Player.one));

      final stats = match.statsOf(Player.one)!;
      expect(stats.power, 2 + 5 + 9);
      expect(stats.rarity, Rarity.legendary);
      expect(match.area(Player.one).creatureInPlay!.items, hasLength(2));
    });
  });

  group('Respect', () {
    test('a tie by class is won by the creature with more power', () {
      // Light Phoenix (7) y Elder Angel (0): ambas Legendary y Magical.
      final match = matchWith(
        InitialEffectKind.respect,
        [lightPhoenix],
        [elderAngel],
      );

      expect(
        playClash(match),
        const ClashWin(ClashSide.first, WinReason.power),
      );
    });

    test('it does not help the creature with less power', () {
      final match = matchOf([lightPhoenix], [elderAngel], twoEffect: respect);

      expect(playClash(match), const ClashTie(TieReason.sameClass));
    });

    test('with the same power it is still a tie', () {
      final match = matchWith(
        InitialEffectKind.respect,
        [spearStatue],
        [spearStatue],
      );

      expect(playClash(match), isA<ClashTie>());
    });
  });

  group('Justice', () {
    test('+1 for each clash lost since the last win', () {
      final match = matchWith(
        InitialEffectKind.justice,
        [
          common('Weak', wild, 1),
          common('Weak Again', wild, 1),
          common('Strong', wild, 9),
          common('Weak Once More', wild, 1),
        ],
        [for (var i = 0; i < 4; i++) common('Builder $i', builder, 5)],
      );

      match.revealCreatures();
      expect(match.statsOf(Player.one)!.power, 1);
      match.resolveClash();

      match.revealCreatures();
      expect(match.statsOf(Player.one)!.power, 1 + 1);
      match.resolveClash();

      match.revealCreatures();
      expect(match.statsOf(Player.one)!.power, 9 + 2);
      match.resolveClash();

      // Ganó el Clash anterior: el contador vuelve a cero.
      match.revealCreatures();
      expect(match.statsOf(Player.one)!.power, 1);
    });
  });

  group('Friendship', () {
    test('+3 only in the clash after a tie', () {
      final match = matchWith(
        InitialEffectKind.friendship,
        [lightPhoenix, common('Wolf', wild, 2), common('Fox', wild, 2)],
        [elderAngel, common('Brick', builder, 4), common('Wall', builder, 4)],
      );
      expect(playClash(match), isA<ClashTie>());

      match.revealCreatures();
      expect(match.statsOf(Player.one)!.power, 2 + 3);
      expect(
        match.resolveClash(),
        const ClashWin(ClashSide.first, WinReason.power),
      );

      match.revealCreatures();
      expect(match.statsOf(Player.one)!.power, 2);
    });
  });

  group('Excellence', () {
    test('+1 in the clash after a win', () {
      final match = matchWith(
        InitialEffectKind.excellence,
        [spearStatue, common('Wolf', wild, 3)],
        [common('Brick', builder, 1), common('Wall', builder, 3)],
      );
      playClash(match);

      match.revealCreatures();

      expect(match.statsOf(Player.one)!.power, 3 + 1);
    });
  });

  group('Empathy', () {
    test('copies the passive ability of the rival initial effect', () {
      final match = matchWith(
        InitialEffectKind.empathy,
        [lightPhoenix],
        [elderAngel],
        rivalKind: InitialEffectKind.respect,
      );

      expect(match.hasPassive(Player.one, InitialEffectKind.respect), isTrue);
      expect(
        playClash(match),
        const ClashWin(ClashSide.first, WinReason.power),
      );
    });

    test('two players with Empathy copy nothing', () {
      final match = matchWith(
        InitialEffectKind.empathy,
        [lightPhoenix],
        [elderAngel],
        rivalKind: InitialEffectKind.empathy,
      );

      expect(match.hasPassive(Player.one, InitialEffectKind.respect), isFalse);
      expect(playClash(match), isA<ClashTie>());
    });
  });
}
