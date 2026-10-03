import 'package:game_engine/game_engine.dart';
import 'package:test/test.dart';

import '../fixtures/cards.dart';

/// Resuelve un Clash entre dos Creatures, cada una con su Item opcional.
ClashResult clash(
  Creature first,
  Creature second, {
  Item? firstItem,
  Item? secondItem,
}) => resolveClash(
  ClashStats.of(first, item: firstItem),
  ClashStats.of(second, item: secondItem),
);

void main() {
  group('resolveClash by rarity', () {
    test('the higher rarity wins even with less power', () {
      // Unicorn Queen: Legendary 8. Pumpkin Planet: Epic 9.
      expect(
        clash(unicornQueen, pumpkinPlanet),
        const ClashWin(ClashSide.first, WinReason.rarity),
      );
    });

    test('the second side can win too', () {
      expect(
        clash(meditatingBrush, luminousMushrooms),
        const ClashWin(ClashSide.second, WinReason.rarity),
      );
    });

    test('a rarity granted by an item can change the winner', () {
      // Meditating Brush (Common) con Fire Axe pasa a Epic y vence a
      // Luminous Mushrooms (Rare).
      expect(
        clash(meditatingBrush, luminousMushrooms, firstItem: fireAxe),
        const ClashWin(ClashSide.first, WinReason.rarity),
      );
    });
  });

  group('resolveClash with the same rarity', () {
    test('the same class is a tie, whatever the power', () {
      // Light Phoenix (7) y Elder Angel (0): ambas Legendary y Magical.
      expect(
        clash(lightPhoenix, elderAngel),
        const ClashTie(TieReason.sameClass),
      );
    });

    test('the same class is a tie even when an item adds power', () {
      // Elder Angel con Diamond Sword suma 0 + 9 = 9, más que Light Phoenix
      // (7), pero siguen siendo Legendary y Magical.
      expect(
        clash(lightPhoenix, elderAngel, secondItem: diamondSword),
        const ClashTie(TieReason.sameClass),
      );
    });

    test('with different classes, the higher power wins', () {
      // Spear Statue (Warrior 9) contra Writing Tractor (Builder 5).
      expect(
        clash(spearStatue, writingTractor),
        const ClashWin(ClashSide.first, WinReason.power),
      );
      expect(
        clash(writingTractor, spearStatue),
        const ClashWin(ClashSide.second, WinReason.power),
      );
    });

    test('with different classes and the same power, it is a tie', () {
      // Spear Statue (Warrior 9) contra Raspberry Grenade (Foodie 9).
      expect(
        clash(spearStatue, raspberryGrenade),
        const ClashTie(TieReason.samePower),
      );
    });

    test('the item power bonus counts', () {
      // Unicorn Queen con Fire Axe sigue siendo Legendary y suma 8 + 5 = 13,
      // así que vence a Galaxy Dragon (Legendary, 9).
      expect(
        clash(unicornQueen, galaxyDragon, firstItem: fireAxe),
        const ClashWin(ClashSide.first, WinReason.power),
      );
    });
  });

  group('ClashResult', () {
    test('swapping the sides mirrors the result', () {
      final pairs = [
        (unicornQueen, pumpkinPlanet),
        (spearStatue, writingTractor),
        (spearStatue, raspberryGrenade),
        (lightPhoenix, elderAngel),
      ];

      for (final (a, b) in pairs) {
        final result = clash(a, b);
        final swapped = clash(b, a);

        switch (result) {
          case ClashWin(:final winner, :final reason):
            expect(swapped, ClashWin(winner.opponent, reason));
          case ClashTie():
            expect(swapped, result);
        }
      }
    });

    test('a win knows its loser', () {
      expect(
        const ClashWin(ClashSide.first, WinReason.power).loser,
        ClashSide.second,
      );
    });
  });
}
