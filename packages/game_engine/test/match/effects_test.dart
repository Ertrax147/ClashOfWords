import 'package:game_engine/game_engine.dart';
import 'package:test/test.dart';

import '../fixtures/cards.dart';
import '../fixtures/match_helpers.dart';

/// Primer Effect de la Hand de [player].
MatchCard<Effect> effectInHand(GameMatch match, Player player) =>
    match.area(player).hand.whereType<MatchCard<Effect>>().first;

/// Crea un Effect de prueba con [abilities] y [clashes] de Duration.
Effect testEffect(String name, int clashes, List<Ability> abilities) => Effect(
  id: name,
  name: name,
  rarity: Rarity.common,
  duration: ClashDuration(clashes),
  abilities: abilities,
);

// Effects reales cuyo nombre no alcanzamos a leer en la carta. El nombre
// describe lo que hacen.

/// Rare, Duration 3: "Enemy creatures get -3".
final enemyMinusThree = testEffect('Enemy Minus Three', 3, [
  StatModifier(target: AbilityTarget.enemy, powerDelta: -3),
]);

/// Uncommon, Duration 1: "Enemy Wild and Social creatures get Common".
final enemyWildSocialCommon = testEffect('Enemy Wild Social Common', 1, [
  StatModifier(
    target: AbilityTarget.enemy,
    filter: CreatureFilter(classes: {wild, social}),
    rarity: Rarity.common,
  ),
]);

/// Uncommon, Duration 2: "Move the enemy Smart creatures to the Discard
/// stack".
final discardEnemySmart = testEffect('Discard Enemy Smart', 2, [
  DiscardEnemyCreatures(CreatureFilter(classes: {smart})),
]);

/// Rare, Duration 2: "Your enemy cannot play effects".
final forbidEnemyEffects = testEffect('Forbid Enemy Effects', 2, [
  ForbidEnemyPlays(effects: true),
]);

/// Common, Duration 5: "Your creatures get Builder".
final getBuilder = testEffect('Get Builder', 5, [
  StatModifier(target: AbilityTarget.own, addedClass: builder),
]);

final foodie = CardClass('Foodie');

/// Common, Duration 5: "Your creatures get Foodie".
final getFoodie = testEffect('Get Foodie', 5, [
  StatModifier(target: AbilityTarget.own, addedClass: foodie),
]);

final foodieSnack = Item(
  id: 'foodie-snack',
  name: 'Foodie Snack',
  rarity: Rarity.common,
  classes: {foodie},
  powerBonus: 1,
);

void main() {
  group('playEffect', () {
    test('moves the effect from the hand to play', () {
      final match = matchOf(
        [closetBuilding, common('Piggy Bank', economic, 2)],
        [common('Rival', wild, 4)],
      )..revealCreatures();

      match.playEffect(Player.one, effectInHand(match, Player.one));

      expect(match.area(Player.one).hand, isEmpty);
      expect(
        match.area(Player.one).effectsInPlay.single.effect.card,
        closetBuilding,
      );
    });

    test('rejects playing before the creatures are revealed', () {
      final match = matchOf([closetBuilding, meditatingBrush], [spearStatue]);
      final effect = match
          .area(Player.one)
          .deck
          .whereType<MatchCard<Effect>>()
          .first;

      expect(
        match.checkPlayEffect(Player.one, effect),
        InvalidPlayReason.wrongPhase,
      );
    });
  });

  group('stat modifiers', () {
    test('a power bonus for a class can change the winner', () {
      // Piggy Bank (Economic 2) contra Rival (Wild 4). Con Closet Building
      // ("Your Economic creatures get +3") llega a 5 y gana.
      final match = matchOf(
        [closetBuilding, common('Piggy Bank', economic, 2)],
        [common('Rival', wild, 4)],
      )..revealCreatures();
      match.playEffect(Player.one, effectInHand(match, Player.one));

      expect(match.statsOf(Player.one)!.power, 5);
      expect(
        match.resolveClash(),
        const ClashWin(ClashSide.first, WinReason.power),
      );
    });

    test('an enemy power penalty can change the winner', () {
      final match = matchOf(
        [enemyMinusThree, common('Small', wild, 3)],
        [common('Big', foodie, 5)],
      )..revealCreatures();
      match.playEffect(Player.one, effectInHand(match, Player.one));

      expect(match.statsOf(Player.two)!.power, 2);
      expect(
        match.resolveClash(),
        const ClashWin(ClashSide.first, WinReason.power),
      );
    });

    test('an enemy effect can lower the rival rarity', () {
      // Luminous Mushrooms (Rare, Wild) pasa a Common y pierde contra
      // Writing Tractor (Uncommon).
      final match = matchOf(
        [enemyWildSocialCommon, writingTractor],
        [luminousMushrooms],
      )..revealCreatures();
      match.playEffect(Player.one, effectInHand(match, Player.one));

      expect(match.statsOf(Player.two)!.rarity, Rarity.common);
      expect(
        match.resolveClash(),
        const ClashWin(ClashSide.first, WinReason.rarity),
      );
    });

    test('an own effect can raise the rarity', () {
      // Orange Stars: Meditating Brush (Common) pasa a Legendary.
      final match = matchOf([orangeStars, meditatingBrush], [pumpkinPlanet])
        ..revealCreatures();
      match.playEffect(Player.one, effectInHand(match, Player.one));

      expect(
        match.resolveClash(),
        const ClashWin(ClashSide.first, WinReason.rarity),
      );
    });

    test('a shared added class makes a tie', () {
      // Spear Statue (Warrior 9) le ganaría a Writing Tractor (Builder 5),
      // pero con "Your creatures get Builder" comparten Class: Tie.
      final match = matchOf([getBuilder, spearStatue], [writingTractor])
        ..revealCreatures();
      match.playEffect(Player.one, effectInHand(match, Player.one));

      expect(match.resolveClash(), const ClashTie(TieReason.sameClass));
    });
  });

  group('effect duration', () {
    test('an effect lasts its clashes and then goes to the discard stack', () {
      final match = matchOf(
        [closetBuilding, unicornQueen],
        [meditatingBrush, writingTractor, spearStatue],
      )..revealCreatures();
      match.playEffect(Player.one, effectInHand(match, Player.one));

      match.resolveClash();
      expect(
        match.area(Player.one).effectsInPlay.single.remaining,
        ClashDuration(1),
      );

      playClash(match);
      expect(match.area(Player.one).effectsInPlay, isEmpty);
      expect(names(match.area(Player.one).discardStack), ['Closet Building']);
    });

    test('a tie also spends a clash of the effect', () {
      final match = matchOf(
        [closetBuilding, lightPhoenix, spearStatue],
        [elderAngel, meditatingBrush],
      )..revealCreatures();
      match.playEffect(Player.one, effectInHand(match, Player.one));

      expect(match.resolveClash(), isA<ClashTie>());
      expect(
        match.area(Player.one).effectsInPlay.single.remaining,
        ClashDuration(1),
      );
    });

    test('effects still in play go to the discard stack at the end', () {
      final match = matchOf([orangeStars, meditatingBrush], [pumpkinPlanet])
        ..revealCreatures();
      match.playEffect(Player.one, effectInHand(match, Player.one));
      match.resolveClash();

      match.revealCreatures();

      expect(match.phase, MatchPhase.finished);
      expect(
        names(match.area(Player.one).discardStack),
        contains('Orange Stars'),
      );
    });
  });

  group('discarding enemy creatures', () {
    test('the rival creature goes to its discard stack and is replaced', () {
      final match = matchOf(
        [uglyTheater, meditatingBrush],
        [relaxingMarkers, writingTractor],
      )..revealCreatures();

      final revealed = match.playEffect(
        Player.one,
        effectInHand(match, Player.one),
      );

      expect(names(match.area(Player.two).discardStack), ['Relaxing Markers']);
      expect(names(revealed[Player.two]!), ['Writing Tractor']);
      expect(
        match.area(Player.two).creatureInPlay!.creature.card,
        writingTractor,
      );
      expect(match.area(Player.one).trophyStack, isEmpty);
    });

    test('while it lasts, it also discards newly revealed creatures', () {
      final match = matchOf(
        [discardEnemySmart, unicornQueen],
        [writingTractor, meditatingBrush, spearStatue],
      )..revealCreatures();
      match.playEffect(Player.one, effectInHand(match, Player.one));
      match.resolveClash();

      // Meditating Brush (Smart) sale apenas se revela.
      final revealed = match.revealCreatures();

      expect(names(revealed[Player.two]!), [
        'Meditating Brush',
        'Spear Statue',
      ]);
      expect(names(match.area(Player.two).discardStack), ['Meditating Brush']);
    });

    test('the match ends if the rival runs out of cards', () {
      final match = matchOf([uglyTheater, meditatingBrush], [relaxingMarkers])
        ..revealCreatures();

      match.playEffect(Player.one, effectInHand(match, Player.one));

      expect(match.phase, MatchPhase.finished);
      expect(names(match.area(Player.two).discardStack), ['Relaxing Markers']);
    });
  });

  group('prohibitions', () {
    test("Universe's Eye forbids the rival to play effects", () {
      final match = matchOf(
        [universesEye],
        [closetBuilding, common('Piggy Bank', economic, 2)],
      )..revealCreatures();

      expect(
        match.checkPlayEffect(Player.two, effectInHand(match, Player.two)),
        InvalidPlayReason.forbiddenByEnemy,
      );
    });

    test('Galaxy Dragon forbids the rival to equip items', () {
      final match = matchOf(
        [galaxyDragonWithAbility],
        [fireAxe, meditatingBrush],
      )..revealCreatures();

      expect(
        match.checkEquipItem(Player.two, itemInHand(match, Player.two)),
        InvalidPlayReason.forbiddenByEnemy,
      );
    });

    test('a prohibition does not cancel effects already in play', () {
      final match = matchOf(
        [forbidEnemyEffects, writingTractor],
        [closetBuilding, huggingHospital, common('Piggy Bank', economic, 2)],
      )..revealCreatures();
      match.playEffect(Player.two, effectInHand(match, Player.two));

      match.playEffect(Player.one, effectInHand(match, Player.one));

      // Closet Building sigue sumando +3, pero ya no puede jugar otro Effect.
      expect(match.statsOf(Player.two)!.power, 5);
      expect(
        match.checkPlayEffect(Player.two, effectInHand(match, Player.two)),
        InvalidPlayReason.forbiddenByEnemy,
      );
    });
  });

  group('item restrictions', () {
    test('Gift of Eternity cannot be used by a legendary creature', () {
      final match = matchOf([giftOfEternity, unicornQueen], [pumpkinPlanet])
        ..revealCreatures();

      expect(
        match.checkEquipItem(Player.one, itemInHand(match, Player.one)),
        InvalidPlayReason.forbiddenRarity,
      );
    });

    test('Gift of Eternity gives an infinite duration to other creatures', () {
      final match = matchOf([giftOfEternity, meditatingBrush], [writingTractor])
        ..revealCreatures();
      match.equipItem(Player.one, itemInHand(match, Player.one));

      expect(
        match.area(Player.one).creatureInPlay!.remaining,
        ClashDuration.infinite,
      );
    });

    test('an added class lets the creature equip items of that class', () {
      final match = matchOf(
        [getFoodie, foodieSnack, writingTractor],
        [spearStatue],
      )..revealCreatures();
      final snack = itemInHand(match, Player.one);

      expect(
        match.checkEquipItem(Player.one, snack),
        InvalidPlayReason.classMismatch,
      );

      match.playEffect(Player.one, effectInHand(match, Player.one));

      expect(match.checkEquipItem(Player.one, snack), isNull);
    });
  });
}
