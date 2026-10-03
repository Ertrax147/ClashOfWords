import 'dart:math';

import 'package:game_engine/game_engine.dart';
import 'package:test/test.dart';

import '../fixtures/cards.dart';
import '../fixtures/match_helpers.dart';

/// Partida en la que cada jugador tiene el Initial Effect indicado.
GameMatch matchWith(InitialEffectKind one, InitialEffectKind two) => matchOf(
  [common('Wolf', wild, 3)],
  [common('Rock', warrior, 1)],
  oneEffect: initialEffectOf(one),
  twoEffect: initialEffectOf(two),
);

void main() {
  group('active ability of the Initial Effect', () {
    test('is the own one when the card has an active ability', () {
      final match = matchWith(
        InitialEffectKind.leadership,
        InitialEffectKind.diversity,
      );

      expect(match.activeKindOf(Player.one), InitialEffectKind.leadership);
      expect(match.activeKindOf(Player.two), isNull);
    });

    test('Responsibility has both a passive and an active ability', () {
      final match = matchWith(
        InitialEffectKind.responsibility,
        InitialEffectKind.respect,
      );

      expect(match.activeKindOf(Player.one), InitialEffectKind.responsibility);
    });

    test('Empathy copies the active ability of the rival', () {
      final match = matchWith(
        InitialEffectKind.empathy,
        InitialEffectKind.kindness,
      );

      expect(match.activeKindOf(Player.one), InitialEffectKind.kindness);
      expect(match.activeKindOf(Player.two), InitialEffectKind.kindness);
    });

    test('Empathy copies nothing if the rival has only a passive ability', () {
      final match = matchWith(
        InitialEffectKind.empathy,
        InitialEffectKind.justice,
      );

      expect(match.activeKindOf(Player.one), isNull);
    });

    test('Empathy copies nothing if both players have Empathy', () {
      final match = matchWith(
        InitialEffectKind.empathy,
        InitialEffectKind.empathy,
      );

      expect(match.activeKindOf(Player.one), isNull);
      expect(match.activeKindOf(Player.two), isNull);
    });
  });

  group('checkUseInitialEffect', () {
    test('allows it during the play phase', () {
      final match = matchWith(
        InitialEffectKind.leadership,
        InitialEffectKind.diversity,
      )..revealCreatures();

      expect(match.checkUseInitialEffect(Player.one), isNull);
      expect(match.hasUsedActive(Player.one), isFalse);
    });

    test('rejects it outside the play phase', () {
      final match = matchWith(
        InitialEffectKind.leadership,
        InitialEffectKind.diversity,
      );

      expect(
        match.checkUseInitialEffect(Player.one),
        InvalidPlayReason.wrongPhase,
      );
    });

    test('rejects it if the card has no active ability', () {
      final match = matchWith(
        InitialEffectKind.leadership,
        InitialEffectKind.diversity,
      )..revealCreatures();

      expect(
        match.checkUseInitialEffect(Player.two),
        InvalidPlayReason.noActiveAbility,
      );
    });
  });

  group('Recycle', () {
    /// Partida en la que Wolf (Power 5) ya venció a Rock y está en el
    /// Discard Stack del jugador uno, que usa [kind]. Queda en la fase de
    /// jugar el segundo Clash.
    GameMatch afterWolfWon(InitialEffectKind kind, {InitialEffectKind? rival}) {
      final match = matchOf(
        [common('Wolf', wild, 5), common('Pup', wild, 1)],
        [common('Rock', warrior, 1), common('Stone', warrior, 1)],
        oneEffect: initialEffectOf(kind),
        twoEffect: rival == null ? null : initialEffectOf(rival),
      );
      playClash(match);
      match.revealCreatures();
      return match;
    }

    test('is not usable while the discard stack has no creatures', () {
      final match = matchWith(
        InitialEffectKind.recycle,
        InitialEffectKind.diversity,
      )..revealCreatures();

      expect(
        match.checkUseInitialEffect(Player.one),
        InvalidPlayReason.noValidTarget,
      );
    });

    test('offers the creatures of the own discard stack', () {
      final match = afterWolfWon(InitialEffectKind.recycle);

      expect(names(match.activeOptions(Player.one)), ['Wolf']);
      expect(match.activeOptions(Player.two), isEmpty);
    });

    test('moves the chosen creature from the discard stack to the deck', () {
      final match = afterWolfWon(InitialEffectKind.recycle);
      final wolf = match.activeOptions(Player.one).single;

      match.useInitialEffect(Player.one, CardChoice(wolf));

      final area = match.area(Player.one);
      expect(area.discardStack, isEmpty);
      expect(area.deck, contains(wolf));
      expect(area.deck, hasLength(1));
      expect(match.hasUsedActive(Player.one), isTrue);
    });

    test('can only be used once per game', () {
      final match = afterWolfWon(InitialEffectKind.recycle);
      final wolf = match.activeOptions(Player.one).single;
      match.useInitialEffect(Player.one, CardChoice(wolf));

      expect(
        match.checkUseInitialEffect(Player.one),
        InvalidPlayReason.alreadyUsed,
      );
      expect(
        () => match.useInitialEffect(Player.one, CardChoice(wolf)),
        throwsA(
          isA<InvalidPlayException>().having(
            (e) => e.reason,
            'reason',
            InvalidPlayReason.alreadyUsed,
          ),
        ),
      );
    });

    test('rejects a choice that is not an option', () {
      final match = afterWolfWon(InitialEffectKind.recycle);
      final pup = match.area(Player.one).creatureInPlay!.creature;

      expect(
        match.checkUseInitialEffect(Player.one, CardChoice(pup)),
        InvalidPlayReason.invalidChoice,
      );
      expect(
        match.checkUseInitialEffect(Player.one, const NoChoice()),
        InvalidPlayReason.invalidChoice,
      );
      expect(match.hasUsedActive(Player.one), isFalse);
    });

    test('works for a player with Empathy facing Recycle', () {
      final match = afterWolfWon(
        InitialEffectKind.empathy,
        rival: InitialEffectKind.recycle,
      );
      final wolf = match.activeOptions(Player.one).single;

      match.useInitialEffect(Player.one, CardChoice(wolf));

      expect(match.area(Player.one).deck, contains(wolf));
      expect(match.hasUsedActive(Player.two), isFalse);
    });

    test('the deck is shuffled with the match random', () {
      // Con un Deck grande, el orden resultante depende del Random: dos
      // partidas con la misma semilla dejan el mismo orden.
      List<String> deckAfterRecycle() {
        final match = GameMatch(
          playerOne: PlayerDeck(
            cards: [
              common('Wolf', wild, 5),
              for (var i = 0; i < 8; i++) common('Pup $i', wild, 1),
            ],
            initialEffect: initialEffectOf(InitialEffectKind.recycle),
          ),
          playerTwo: PlayerDeck(
            cards: [for (var i = 0; i < 9; i++) common('Rock $i', warrior, 1)],
            initialEffect: loyalty,
          ),
          shuffle: false,
          random: Random(7),
        );
        playClash(match);
        match.revealCreatures();
        final wolf = match.activeOptions(Player.one).single;
        match.useInitialEffect(Player.one, CardChoice(wolf));
        return names(match.area(Player.one).deck);
      }

      final order = deckAfterRecycle();
      expect(order, hasLength(8));
      expect(order, contains('Wolf'));
      expect(deckAfterRecycle(), order);
    });
  });

  group('Responsibility active ability', () {
    /// Partida en la que Bag, con Flags Jacket, venció a Rock y ambas
    /// cartas están en el Discard Stack del jugador uno. Queda en la fase de
    /// jugar el segundo Clash.
    GameMatch afterJacketWon() {
      final match = matchOf(
        [flagsJacket, common('Bag', traveler, 1), common('Second', wild, 1)],
        [common('Rock', warrior, 1), common('Stone', warrior, 1)],
        oneEffect: initialEffectOf(InitialEffectKind.responsibility),
      )..revealCreatures();
      match.equipItem(Player.one, itemInHand(match, Player.one));
      match.resolveClash();
      match.revealCreatures();
      return match;
    }

    test('offers only the items of the discard stack', () {
      final match = afterJacketWon();

      expect(names(match.area(Player.one).discardStack), [
        'Bag',
        'Flags Jacket',
      ]);
      expect(names(match.activeOptions(Player.one)), ['Flags Jacket']);
    });

    test('moves the chosen item from the discard stack to the deck', () {
      final match = afterJacketWon();
      final jacket = match.activeOptions(Player.one).single;

      match.useInitialEffect(Player.one, CardChoice(jacket));

      final area = match.area(Player.one);
      expect(names(area.discardStack), ['Bag']);
      expect(area.deck, [jacket]);
    });

    test('rejects a creature of the discard stack', () {
      final match = afterJacketWon();
      final bag = match.area(Player.one).discardStack.first;

      expect(
        match.checkUseInitialEffect(Player.one, CardChoice(bag)),
        InvalidPlayReason.invalidChoice,
      );
    });
  });
}
