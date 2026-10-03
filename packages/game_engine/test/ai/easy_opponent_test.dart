import 'dart:math';

import 'package:game_engine/game_engine.dart';
import 'package:test/test.dart';

import '../fixtures/card_pool.dart';
import '../fixtures/cards.dart';
import '../fixtures/match_helpers.dart';

/// Todas las cartas de [player] que hay en la partida, estén donde estén.
List<MatchCard> allCardsOf(GameMatch match, Player player) {
  final cards = <MatchCard>[];
  for (final area in Player.values.map(match.area)) {
    final inPlay = area.creatureInPlay;
    cards.addAll([
      ...area.deck,
      ...area.hand,
      ...area.discardStack,
      ...area.trophyStack,
      ...area.tiedCards,
      for (final effect in area.effectsInPlay) effect.effect,
      if (inPlay != null) ...[inPlay.creature, ...inPlay.items],
    ]);
  }
  return cards.where((card) => card.owner == player).toList();
}

void main() {
  group('EasyOpponent.playTurn', () {
    test('equips an item it can use and plays its effects', () {
      final match = matchOf(
        [meditatingBrush],
        [fireAxe, closetBuilding, writingTractor],
      )..revealCreatures();

      final plays = const EasyOpponent(Player.two).playTurn(match);

      expect(plays, hasLength(2));
      expect(plays[0], isA<EquippedItem>());
      expect(plays[1], isA<PlayedEffect>());
      expect(match.area(Player.two).hand, isEmpty);
    });

    test('keeps the items it cannot equip', () {
      // Invisible Coat es Magical y Secret; Writing Tractor es Builder.
      final match = matchOf([meditatingBrush], [invisibleCoat, writingTractor])
        ..revealCreatures();

      final plays = const EasyOpponent(Player.two).playTurn(match);

      expect(plays, isEmpty);
      expect(names(match.area(Player.two).hand), ['Invisible Coat']);
    });
  });

  group('simulated matches', () {
    test('random matches between two easy opponents always end and '
        'never lose or duplicate cards', () {
      for (var seed = 0; seed < 200; seed++) {
        final random = Random(seed);
        final one = randomDeck(cardPool, random);
        final two = randomDeck(cardPool, random);
        final match = GameMatch(playerOne: one, playerTwo: two, random: random);
        const players = [EasyOpponent(Player.one), EasyOpponent(Player.two)];

        var rounds = 0;
        while (match.phase != MatchPhase.finished) {
          expect(rounds++, lessThan(200), reason: 'seed $seed never ends');
          match.revealCreatures();
          for (final opponent in players) {
            if (match.phase == MatchPhase.play) opponent.playTurn(match);
          }
          if (match.phase == MatchPhase.play) match.resolveClash();
        }

        // Cada jugador conserva sus cartas: las de su Deck más el Initial
        // Effect, que no se mueve.
        expect(allCardsOf(match, Player.one), hasLength(one.cards.length));
        expect(allCardsOf(match, Player.two), hasLength(two.cards.length));
        expect(
          match.result.trophiesOfOne + match.result.trophiesOfTwo,
          lessThanOrEqualTo(one.cards.length + two.cards.length),
        );
      }
    });
  });
}
