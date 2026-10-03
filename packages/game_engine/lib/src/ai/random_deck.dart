import 'dart:math';

import '../entities/game_card.dart';
import '../match/game_match.dart';

/// Reglas de tamaño de un mazo (RF-03).
abstract final class DeckRules {
  /// Cantidad mínima de cartas en el Deck, sin contar el Initial Effect.
  static const int minCards = 20;

  /// Cantidad máxima de cartas en el Deck, sin contar el Initial Effect.
  static const int maxCards = 25;

  /// Copias máximas de una misma carta.
  static const int maxCopies = 3;
}

/// Arma un mazo al azar con las cartas de [pool], para el rival en nivel
/// Fácil (RF-15) y para el jugador mientras no exista el Deck Builder.
///
/// Cumple las reglas de RF-03: entre [DeckRules.minCards] y
/// [DeckRules.maxCards] cartas, como máximo [DeckRules.maxCopies] copias de
/// cada una y un único Initial Effect. No considera si las Class de Items,
/// Effects y Creatures coinciden.
///
/// Para que la partida dure, la mitad del mazo (redondeada hacia arriba) son
/// Creatures; el resto son Items y Effects.
///
/// Lanza un [ArgumentError] si [pool] no tiene suficientes cartas de algún
/// tipo para armar el mazo.
PlayerDeck randomDeck(List<GameCard> pool, Random random) {
  final creatures = pool.whereType<Creature>().toList();
  final others = [...pool.whereType<Item>(), ...pool.whereType<Effect>()];
  final initialEffects = pool.whereType<InitialEffect>().toList();
  if (initialEffects.isEmpty) {
    throw ArgumentError('The pool has no initial effects');
  }

  final size =
      DeckRules.minCards +
      random.nextInt(DeckRules.maxCards - DeckRules.minCards + 1);
  final creatureCount = (size + 1) ~/ 2;
  final cards = [
    ..._pick(creatures, creatureCount, random),
    ..._pick(others, size - creatureCount, random),
  ]..shuffle(random);

  return PlayerDeck(
    cards: cards,
    initialEffect: initialEffects[random.nextInt(initialEffects.length)],
  );
}

/// Elige [count] cartas al azar de [options], sin pasar de
/// [DeckRules.maxCopies] copias de cada una.
List<GameCard> _pick(List<GameCard> options, int count, Random random) {
  if (options.length * DeckRules.maxCopies < count) {
    throw ArgumentError('Not enough different cards to build a deck');
  }
  final copies = <GameCard, int>{};
  final picked = <GameCard>[];
  while (picked.length < count) {
    final card = options[random.nextInt(options.length)];
    final used = copies[card] ?? 0;
    if (used < DeckRules.maxCopies) {
      copies[card] = used + 1;
      picked.add(card);
    }
  }
  return picked;
}
