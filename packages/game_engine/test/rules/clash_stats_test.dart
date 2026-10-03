import 'package:game_engine/game_engine.dart';
import 'package:test/test.dart';

import '../fixtures/cards.dart';

void main() {
  group('ClashStats.of', () {
    test('without an item, uses the values printed on the creature', () {
      final stats = ClashStats.of(unicornQueen);

      expect(stats.rarity, Rarity.legendary);
      expect(stats.classes, {wild});
      expect(stats.power, 8);
    });

    test('adds the item power bonus', () {
      final stats = ClashStats.of(writingTractor, item: diamondSword);

      expect(stats.power, 5 + 9);
    });

    test('takes the rarity granted by the item when it is higher', () {
      final stats = ClashStats.of(meditatingBrush, item: fireAxe);

      expect(stats.rarity, Rarity.epic);
    });

    test('keeps the creature rarity when the item grants a lower one', () {
      // Fire Axe otorga Epic, pero Unicorn Queen ya es Legendary.
      final stats = ClashStats.of(unicornQueen, item: fireAxe);

      expect(stats.rarity, Rarity.legendary);
    });

    test('keeps the creature class, not the item classes', () {
      // Invisible Coat es Magical y Secret; la Creature sigue siendo Magical.
      final stats = ClashStats.of(lightPhoenix, item: invisibleCoat);

      expect(stats.classes, {magical});
    });

    test('rejects an item that cannot be equipped to the creature', () {
      // Invisible Coat es Magical y Secret; Unicorn Queen es Wild.
      expect(
        () => ClashStats.of(unicornQueen, item: invisibleCoat),
        throwsArgumentError,
      );
    });
  });
}
