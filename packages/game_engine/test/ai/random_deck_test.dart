import 'dart:math';

import 'package:game_engine/game_engine.dart';
import 'package:test/test.dart';

import '../fixtures/card_pool.dart';

void main() {
  group('randomDeck', () {
    test('follows the deck rules of RF-03', () {
      for (var seed = 0; seed < 50; seed++) {
        final deck = randomDeck(cardPool, Random(seed));

        expect(
          deck.cards.length,
          inInclusiveRange(DeckRules.minCards, DeckRules.maxCards),
        );
        final copies = <GameCard, int>{};
        for (final card in deck.cards) {
          copies[card] = (copies[card] ?? 0) + 1;
        }
        expect(
          copies.values.every((count) => count <= DeckRules.maxCopies),
          isTrue,
        );
        expect(deck.cards.whereType<InitialEffect>(), isEmpty);
      }
    });

    test('half of the deck are creatures', () {
      final deck = randomDeck(cardPool, Random(3));
      final creatures = deck.cards.whereType<Creature>().length;

      expect(creatures, (deck.cards.length + 1) ~/ 2);
    });

    test('the same seed builds the same deck', () {
      final first = randomDeck(cardPool, Random(42));
      final second = randomDeck(cardPool, Random(42));

      expect(first.cards, second.cards);
      expect(first.initialEffect, second.initialEffect);
    });

    test('fails if the pool has no initial effects', () {
      expect(
        () => randomDeck(
          cardPool.where((card) => card is! InitialEffect).toList(),
          Random(1),
        ),
        throwsArgumentError,
      );
    });
  });
}
