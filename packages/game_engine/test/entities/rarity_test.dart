import 'package:game_engine/game_engine.dart';
import 'package:test/test.dart';

void main() {
  group('Rarity', () {
    test('is ordered from common to legendary', () {
      expect(Rarity.values, [
        Rarity.common,
        Rarity.uncommon,
        Rarity.rare,
        Rarity.epic,
        Rarity.legendary,
      ]);
    });

    test('a higher rarity beats a lower one', () {
      expect(Rarity.legendary.isHigherThan(Rarity.epic), isTrue);
      expect(Rarity.uncommon.isHigherThan(Rarity.common), isTrue);
      expect(Rarity.common.isHigherThan(Rarity.rare), isFalse);
    });

    test('a rarity does not beat itself', () {
      expect(Rarity.rare.isHigherThan(Rarity.rare), isFalse);
      expect(Rarity.rare.compareTo(Rarity.rare), 0);
    });

    test('sorting a list puts the highest rarity last', () {
      final rarities = [Rarity.epic, Rarity.common, Rarity.legendary]..sort();

      expect(rarities, [Rarity.common, Rarity.epic, Rarity.legendary]);
    });

    test('max keeps the higher rarity, whichever side it is on', () {
      expect(Rarity.common.max(Rarity.epic), Rarity.epic);
      expect(Rarity.legendary.max(Rarity.epic), Rarity.legendary);
      expect(Rarity.rare.max(Rarity.rare), Rarity.rare);
    });
  });
}
