import 'package:clash_of_words/features/catalog/data/models/card_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_engine/game_engine.dart';

GameCard parse(Map<String, dynamic> json) => CardModel.fromJson(json).card;

void main() {
  group('CardModel.fromJson', () {
    test('reads a creature with its duration and abilities', () {
      final card = parse({
        'id': 'universes-eye',
        'type': 'creature',
        'name': "Universe's Eye",
        'rarity': 'legendary',
        'class': 'Cosmic',
        'power': 9,
        'duration': 2,
        'abilities': [
          {'type': 'forbidEnemyPlays', 'effects': true},
        ],
      });

      expect(card, isA<Creature>());
      final creature = card as Creature;
      expect(creature.rarity, Rarity.legendary);
      expect(creature.cardClass, CardClass('Cosmic'));
      expect(creature.power, 9);
      expect(creature.duration, ClashDuration(2));
      expect((creature.abilities.single as ForbidEnemyPlays).effects, isTrue);
    });

    test('a creature without duration lasts one clash', () {
      final creature =
          parse({
                'id': 'meditating-brush',
                'type': 'creature',
                'name': 'Meditating Brush',
                'rarity': 'common',
                'class': 'Smart',
                'power': 2,
              })
              as Creature;

      expect(creature.duration, ClashDuration.one);
      expect(creature.abilities, isEmpty);
    });

    test('reads an item with an infinite duration and a forbidden rarity', () {
      final item =
          parse({
                'id': 'gift-of-eternity',
                'type': 'item',
                'name': 'Gift of Eternity',
                'rarity': 'legendary',
                'powerBonus': 0,
                'grantedDuration': 'infinite',
                'forbiddenRarities': ['legendary'],
              })
              as Item;

      expect(item.isUniversal, isTrue);
      expect(item.grantedDuration, ClashDuration.infinite);
      expect(item.forbiddenRarities, {Rarity.legendary});
    });

    test('reads an effect with a filtered stat modifier', () {
      final effect =
          parse({
                'id': 'classroom-cleaning',
                'type': 'effect',
                'name': 'Classroom Cleaning',
                'rarity': 'uncommon',
                'duration': 3,
                'abilities': [
                  {
                    'type': 'statModifier',
                    'target': 'own',
                    'classes': ['Smart', 'Social'],
                    'rarities': ['common'],
                    'rarity': 'uncommon',
                  },
                ],
              })
              as Effect;

      final modifier = effect.abilities.single as StatModifier;
      expect(modifier.target, AbilityTarget.own);
      expect(modifier.filter.classes, {
        CardClass('Smart'),
        CardClass('Social'),
      });
      expect(modifier.filter.rarities, {Rarity.common});
      expect(modifier.rarity, Rarity.uncommon);
      expect(modifier.powerDelta, 0);
    });

    test('reads an initial effect by its kind', () {
      final initialEffect =
          parse({
                'id': 'respect',
                'type': 'initialEffect',
                'name': 'Respect',
                'kind': 'respect',
              })
              as InitialEffect;

      expect(initialEffect.kind, InitialEffectKind.respect);
    });

    test('an invalid card reports its id', () {
      expect(
        () => parse({
          'id': 'broken-card',
          'type': 'creature',
          'name': 'Broken',
          'rarity': 'common',
          'class': 'Wild',
          'power': 12,
        }),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('broken-card'),
          ),
        ),
      );
    });

    test('an unknown card type is rejected', () {
      expect(
        () => parse({'id': 'x', 'type': 'spell', 'name': 'X'}),
        throwsFormatException,
      );
    });
  });

  group('parseCatalog', () {
    test('rejects an unsupported version', () {
      expect(
        () => parseCatalog('{"version": 99, "cards": []}', imageFolder: 'x'),
        throwsFormatException,
      );
    });

    test('builds the image path from the card id', () {
      final catalog = parseCatalog(
        '{"version": 1, "cards": [{"id": "loyalty", "type": "initialEffect",'
        ' "name": "Loyalty", "kind": "loyalty"}]}',
        imageFolder: 'assets/cards',
      );

      expect(catalog.byId('loyalty')!.imageAsset, 'assets/cards/loyalty.jpg');
    });
  });
}
