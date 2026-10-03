import 'package:game_engine/game_engine.dart';

import 'cards.dart';

// Funciones de apoyo para los tests de partidas.

/// Crea una partida sin barajar: la primera carta de cada lista es la
/// superior del Deck.
GameMatch matchOf(List<GameCard> one, List<GameCard> two) => GameMatch(
  playerOne: PlayerDeck(cards: one, initialEffect: loyalty),
  playerTwo: PlayerDeck(cards: two, initialEffect: respect),
  shuffle: false,
);

/// Creature Common de prueba, para completar mazos.
Creature common(String name, CardClass cardClass, int power) => Creature(
  id: name,
  name: name,
  rarity: Rarity.common,
  cardClass: cardClass,
  power: power,
);

/// Primer Item de la Hand de [player].
MatchCard<Item> itemInHand(GameMatch match, Player player) =>
    match.area(player).hand.whereType<MatchCard<Item>>().first;

/// Nombres de las cartas de [cards], para comparar fácilmente.
List<String> names(List<MatchCard> cards) => [
  for (final card in cards) card.card.name,
];

/// Revela y resuelve un Clash completo.
ClashResult playClash(GameMatch match) {
  match.revealCreatures();
  return match.resolveClash();
}

final traveler = CardClass('Traveler');
