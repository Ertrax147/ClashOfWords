import 'dart:math';

import 'package:game_engine/game_engine.dart';

import '../../catalog/domain/card_catalog.dart';
import '../../deck_builder/domain/saved_deck.dart';

/// Semillas del modo demostración con orden fijo: las partidas se repiten
/// igual mientras se elijan los mismos mazos.
const demoPlayerSeed = 1;

/// Semilla del mazo al azar del rival en el modo demostración.
const demoRivalSeed = 2;

/// Semilla del azar de la partida (habilidades que barajan el Deck).
const demoMatchSeed = 3;

/// Initial Effects que se pueden elegir en la demostración.
List<InitialEffect> selectableInitialEffects(CardCatalog catalog) => [
  for (final effect in catalog.cardsOf<InitialEffect>())
    if (isSelectableInitialEffect(effect)) effect,
];

/// Arma el mazo de un jugador para la demostración.
///
/// Con [deck] usa ese mazo guardado, que debe cumplir las reglas; sin él, arma
/// uno al azar con [random], sin Initial Effects sin decisión. Con
/// [initialEffect] reemplaza el Initial Effect del mazo.
PlayerDeck buildDemoDeck(
  CardCatalog catalog,
  Random random, {
  SavedDeck? deck,
  InitialEffect? initialEffect,
}) {
  if (deck != null) {
    final own = deck.initialEffectIn(catalog);
    final chosen = initialEffect ?? own;
    if (chosen == null) {
      throw ArgumentError.value(deck, 'deck', 'The deck has no Initial Effect');
    }
    return PlayerDeck(cards: deck.cardsIn(catalog), initialEffect: chosen);
  }

  final pool = [
    for (final card in catalog.cards)
      if (card is! InitialEffect || isSelectableInitialEffect(card)) card,
  ];
  final randomized = randomDeck(pool, random);
  return initialEffect == null
      ? randomized
      : PlayerDeck(cards: randomized.cards, initialEffect: initialEffect);
}
