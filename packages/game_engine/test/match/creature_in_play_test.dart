// Los tests usan métodos @internal a propósito: prueban la pieza por sí sola.
// ignore_for_file: invalid_use_of_internal_member

import 'package:game_engine/game_engine.dart';
import 'package:test/test.dart';

import '../fixtures/cards.dart';

MatchCard<Creature> copyOf(Creature creature) =>
    MatchCard(id: 1, card: creature, owner: Player.one);

MatchCard<Item> itemCopy(Item item) =>
    MatchCard(id: 2, card: item, owner: Player.one);

void main() {
  group('CreatureInPlay', () {
    test('enters play with its printed duration and no item', () {
      final inPlay = CreatureInPlay(copyOf(unicornQueen));

      expect(inPlay.remaining, ClashDuration(4));
      expect(inPlay.items, isEmpty);
      expect(inPlay.isExhausted, isFalse);
    });

    test('a creature without duration is exhausted after one clash', () {
      final inPlay = CreatureInPlay(copyOf(meditatingBrush))..spendClash();

      expect(inPlay.isExhausted, isTrue);
    });

    test('spends one clash at a time', () {
      final inPlay = CreatureInPlay(copyOf(unicornQueen))
        ..spendClash()
        ..spendClash();

      expect(inPlay.remaining, ClashDuration(2));
    });

    test('an item duration replaces what is left only if it is longer', () {
      // A Luminous Mushrooms (3) le queda 1 Clash; Ancient Pan otorga 3.
      final shorter = CreatureInPlay(copyOf(luminousMushrooms))
        ..spendClash()
        ..spendClash()
        ..equip(itemCopy(ancientPan));
      expect(shorter.remaining, ClashDuration(3));

      // A Unicorn Queen le quedan 4; Ancient Pan otorga 3, así que conserva 4.
      final longer = CreatureInPlay(copyOf(unicornQueen))
        ..equip(itemCopy(ancientPan));
      expect(longer.remaining, ClashDuration(4));
    });

    test('its stats include the equipped item', () {
      final inPlay = CreatureInPlay(copyOf(meditatingBrush))
        ..equip(itemCopy(fireAxe));

      expect(inPlay.stats.power, 2 + 5);
      expect(inPlay.stats.rarity, Rarity.epic);
    });
  });

  group('ClashDuration.afterClash', () {
    test('counts down until nothing is left', () {
      expect(ClashDuration(3).afterClash(), ClashDuration(2));
      expect(ClashDuration(1).afterClash(), isNull);
    });

    test('an infinite duration never runs out', () {
      expect(ClashDuration.infinite.afterClash(), ClashDuration.infinite);
    });
  });
}
