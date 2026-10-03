import 'package:game_engine/game_engine.dart';
import 'package:test/test.dart';

import '../fixtures/cards.dart';

void main() {
  group('CreatureFilter', () {
    test('an empty filter matches any creature', () {
      expect(CreatureFilter.any.matches({wild}, Rarity.common), isTrue);
    });

    test('matches if the creature has one of the classes', () {
      // "Your Builder and Economic creatures..."
      final filter = CreatureFilter(classes: {builder, economic});

      expect(filter.matches({economic}, Rarity.rare), isTrue);
      expect(filter.matches({wild}, Rarity.rare), isFalse);
    });

    test('can require both a class and a rarity', () {
      // "Your Smart and Social Common creatures..."
      final filter = CreatureFilter(
        classes: {smart, social},
        rarities: {Rarity.common},
      );

      expect(filter.matches({smart}, Rarity.common), isTrue);
      expect(filter.matches({smart}, Rarity.uncommon), isFalse);
      expect(filter.matches({wild}, Rarity.common), isFalse);
    });
  });

  group('abilities', () {
    test('a stat modifier must change something', () {
      expect(
        () => StatModifier(target: AbilityTarget.own),
        throwsArgumentError,
      );
    });

    test('a prohibition must forbid something', () {
      expect(() => ForbidEnemyPlays(), throwsArgumentError);
    });
  });
}
