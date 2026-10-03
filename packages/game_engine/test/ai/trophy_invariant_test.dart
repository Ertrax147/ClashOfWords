import 'dart:math';

import 'package:game_engine/game_engine.dart';
import 'package:test/test.dart';

import '../fixtures/card_pool.dart';

void main() {
  test('every won clash gives trophies to the winner, unless the loser has '
      'Tolerance', () {
    for (var seed = 0; seed < 300; seed++) {
      final random = Random(seed);
      final match = GameMatch(
        playerOne: randomDeck(cardPool, random),
        playerTwo: randomDeck(cardPool, random),
        random: random,
      );
      const players = [EasyOpponent(Player.one), EasyOpponent(Player.two)];

      while (match.phase != MatchPhase.finished) {
        match.revealCreatures();
        for (final opponent in players) {
          if (match.phase == MatchPhase.play) opponent.playTurn(match);
        }
        if (match.phase != MatchPhase.play) continue;

        final before = {
          for (final player in Player.values)
            player: match.area(player).trophyStack.length,
        };
        final result = match.resolveClash();
        if (result case ClashWin(:final winner)) {
          final winnerPlayer = winner == ClashSide.first
              ? Player.one
              : Player.two;
          final loser = winnerPlayer.opponent;
          final gained =
              match.area(winnerPlayer).trophyStack.length -
              before[winnerPlayer]!;
          if (!match.hasPassive(loser, InitialEffectKind.tolerance)) {
            expect(
              gained,
              greaterThan(0),
              reason: 'seed $seed: ${winnerPlayer.name} won without trophies',
            );
          }
          expect(
            match.area(loser).trophyStack.length,
            before[loser],
            reason: 'seed $seed: the loser got trophies',
          );
        }
      }
    }
  });
}
