import 'package:game_engine/game_engine.dart';
import 'package:test/test.dart';

import '../fixtures/cards.dart';

ClashStats stats(Rarity rarity, Set<CardClass> classes, int power) =>
    ClashStats(rarity: rarity, classes: classes, power: power);

void main() {
  group('ClashStats.applyModifiers', () {
    test('without modifiers, nothing changes', () {
      final result = stats(Rarity.rare, {wild}, 3).applyModifiers([]);

      expect(result.rarity, Rarity.rare);
      expect(result.classes, {wild});
      expect(result.power, 3);
    });

    test('adds power only to creatures that match the filter', () {
      // Closet Building: "Your Economic creatures get +3".
      final modifier = StatModifier(
        target: AbilityTarget.own,
        filter: CreatureFilter(classes: {economic}),
        powerDelta: 3,
      );

      expect(
        stats(Rarity.common, {economic}, 2).applyModifiers([modifier]).power,
        5,
      );
      expect(
        stats(Rarity.common, {wild}, 2).applyModifiers([modifier]).power,
        2,
      );
    });

    test('an enemy modifier can subtract power, even below zero', () {
      // "Enemy creatures get -3".
      final modifier = StatModifier(
        target: AbilityTarget.enemy,
        powerDelta: -3,
      );

      expect(
        stats(Rarity.common, {wild}, 2).applyModifiers([modifier]).power,
        -1,
      );
    });

    test('an own rarity never makes the creature worse', () {
      final epic = StatModifier(target: AbilityTarget.own, rarity: Rarity.epic);

      expect(
        stats(Rarity.common, {wild}, 1).applyModifiers([epic]).rarity,
        Rarity.epic,
      );
      expect(
        stats(Rarity.legendary, {wild}, 1).applyModifiers([epic]).rarity,
        Rarity.legendary,
      );
    });

    test('an enemy rarity replaces it, even if it is lower', () {
      // "Enemy Wild and Social creatures get Common".
      final modifier = StatModifier(
        target: AbilityTarget.enemy,
        filter: CreatureFilter(classes: {wild, social}),
        rarity: Rarity.common,
      );

      expect(
        stats(Rarity.legendary, {wild}, 8).applyModifiers([modifier]).rarity,
        Rarity.common,
      );
    });

    test('rarities are applied in the order they were played', () {
      final ownLegendary = StatModifier(
        target: AbilityTarget.own,
        rarity: Rarity.legendary,
      );
      final enemyCommon = StatModifier(
        target: AbilityTarget.enemy,
        rarity: Rarity.common,
      );
      final base = stats(Rarity.rare, {wild}, 1);

      expect(
        base.applyModifiers([ownLegendary, enemyCommon]).rarity,
        Rarity.common,
      );
      expect(
        base.applyModifiers([enemyCommon, ownLegendary]).rarity,
        Rarity.legendary,
      );
    });

    test('an added class keeps the original one', () {
      // "Your creatures get Builder".
      final modifier = StatModifier(
        target: AbilityTarget.own,
        addedClass: builder,
      );

      expect(
        stats(Rarity.common, {wild}, 1).applyModifiers([modifier]).classes,
        {wild, builder},
      );
    });

    test('an added class counts for the other filters', () {
      final getBuilder = StatModifier(
        target: AbilityTarget.own,
        addedClass: builder,
      );
      final builderPlusTwo = StatModifier(
        target: AbilityTarget.own,
        filter: CreatureFilter(classes: {builder}),
        powerDelta: 2,
      );

      expect(
        stats(Rarity.common, {
          wild,
        }, 1).applyModifiers([builderPlusTwo, getBuilder]).power,
        3,
      );
    });

    test('a rarity condition is checked before changing the rarity', () {
      // Classroom Cleaning: "Your Smart and Social Common creatures get
      // Uncommon".
      final modifier = classroomCleaning.abilities.single as StatModifier;

      expect(
        stats(Rarity.common, {smart}, 1).applyModifiers([modifier]).rarity,
        Rarity.uncommon,
      );
      expect(
        stats(Rarity.rare, {smart}, 1).applyModifiers([modifier]).rarity,
        Rarity.rare,
      );
    });

    test('one modifier can change class, rarity and power at once', () {
      // "Your creatures get Cosmic, Rare and +1".
      final modifier = StatModifier(
        target: AbilityTarget.own,
        addedClass: cosmic,
        rarity: Rarity.rare,
        powerDelta: 1,
      );

      final result = stats(Rarity.common, {wild}, 4).applyModifiers([modifier]);

      expect(result.classes, {wild, cosmic});
      expect(result.rarity, Rarity.rare);
      expect(result.power, 5);
    });
  });
}
