import 'package:game_engine/game_engine.dart';
import 'package:test/test.dart';

// Cartas reales del juego, usadas como ejemplos en los tests.
final wild = CardClass('Wild');
final magical = CardClass('Magical');
final secret = CardClass('Secret');

Creature unicornQueen() => Creature(
  id: 'unicorn-queen',
  name: 'Unicorn Queen',
  rarity: Rarity.legendary,
  cardClass: wild,
  power: 8,
  duration: ClashDuration(4),
);

Creature lightPhoenix() => Creature(
  id: 'light-phoenix',
  name: 'Light Phoenix',
  rarity: Rarity.legendary,
  cardClass: magical,
  power: 7,
  duration: ClashDuration(4),
);

Item invisibleCoat() => Item(
  id: 'invisible-coat',
  name: 'Invisible Coat',
  rarity: Rarity.rare,
  classes: {magical, secret},
  powerBonus: 0,
  grantedRarity: Rarity.rare,
  grantedDuration: ClashDuration(3),
);

Item diamondSword() => Item(
  id: 'diamond-sword',
  name: 'Diamond Sword',
  rarity: Rarity.legendary,
  powerBonus: 9,
  grantedRarity: Rarity.legendary,
  grantedDuration: ClashDuration(2),
);

void main() {
  group('GameCard', () {
    test('an empty id or name is rejected', () {
      const kind = InitialEffectKind.loyalty;
      expect(
        () => InitialEffect(id: ' ', name: 'Loyalty', kind: kind),
        throwsArgumentError,
      );
      expect(
        () => InitialEffect(id: 'loyalty', name: '', kind: kind),
        throwsArgumentError,
      );
    });

    test('a switch over GameCard covers the four card types', () {
      String typeOf(GameCard card) => switch (card) {
        Creature() => 'Creature',
        Item() => 'Item',
        Effect() => 'Effect',
        InitialEffect() => 'Initial Effect',
      };

      expect(typeOf(unicornQueen()), 'Creature');
      expect(typeOf(diamondSword()), 'Item');
      expect(
        typeOf(
          Effect(
            id: 'orange-stars',
            name: 'Orange Stars',
            rarity: Rarity.legendary,
            duration: ClashDuration(4),
          ),
        ),
        'Effect',
      );
      expect(
        typeOf(
          InitialEffect(
            id: 'loyalty',
            name: 'Loyalty',
            kind: InitialEffectKind.loyalty,
          ),
        ),
        'Initial Effect',
      );
    });
  });

  group('Creature', () {
    test('keeps the attributes printed on the card', () {
      final creature = unicornQueen();

      expect(creature.name, 'Unicorn Queen');
      expect(creature.rarity, Rarity.legendary);
      expect(creature.cardClass, wild);
      expect(creature.power, 8);
      expect(creature.duration, ClashDuration(4));
    });

    test('lasts one clash when the card has no duration', () {
      final creature = Creature(
        id: 'meditating-brush',
        name: 'Meditating Brush',
        rarity: Rarity.common,
        cardClass: CardClass('Smart'),
        power: 2,
      );

      expect(creature.duration, ClashDuration.one);
    });

    test('accepts power 0, as printed on Elder Angel', () {
      final creature = Creature(
        id: 'elder-angel',
        name: 'Elder Angel',
        rarity: Rarity.legendary,
        cardClass: magical,
        power: 0,
        duration: ClashDuration(5),
      );

      expect(creature.power, 0);
    });

    test('rejects power outside 0 to 9', () {
      Creature withPower(int power) => Creature(
        id: 'test',
        name: 'Test',
        rarity: Rarity.common,
        cardClass: wild,
        power: power,
      );

      expect(() => withPower(-1), throwsArgumentError);
      expect(() => withPower(10), throwsArgumentError);
    });
  });

  group('Item', () {
    test('keeps what it grants to its creature', () {
      final item = diamondSword();

      expect(item.powerBonus, 9);
      expect(item.grantedRarity, Rarity.legendary);
      expect(item.grantedDuration, ClashDuration(2));
    });

    test('grants nothing extra when the card only adds power', () {
      final item = Item(
        id: 'flags-jacket',
        name: 'Flags Jacket',
        rarity: Rarity.uncommon,
        classes: {CardClass('Traveler'), CardClass('Usual')},
        powerBonus: 4,
      );

      expect(item.grantedRarity, isNull);
      expect(item.grantedDuration, isNull);
    });

    test('rejects a negative power bonus', () {
      expect(
        () => Item(
          id: 'test',
          name: 'Test',
          rarity: Rarity.common,
          classes: {wild},
          powerBonus: -1,
        ),
        throwsArgumentError,
      );
    });

    test('an item without classes is universal', () {
      expect(diamondSword().isUniversal, isTrue);
      expect(invisibleCoat().isUniversal, isFalse);
    });

    test('a universal item can be equipped to any creature', () {
      expect(diamondSword().canBeEquippedTo(unicornQueen()), isTrue);
      expect(diamondSword().canBeEquippedTo(lightPhoenix()), isTrue);
    });

    test('an item with classes needs a creature of one of them', () {
      // Invisible Coat es Magical y Secret.
      expect(invisibleCoat().canBeEquippedTo(lightPhoenix()), isTrue);
      expect(invisibleCoat().canBeEquippedTo(unicornQueen()), isFalse);
    });

    test('its classes cannot be modified after creation', () {
      expect(() => invisibleCoat().classes.add(wild), throwsUnsupportedError);
    });
  });
}
