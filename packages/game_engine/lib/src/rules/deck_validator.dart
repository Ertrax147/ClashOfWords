import '../ai/random_deck.dart';
import '../entities/game_card.dart';

/// Regla de armado de mazo (RF-03) que un mazo no cumple.
sealed class DeckIssue {
  const DeckIssue();
}

/// El mazo tiene menos de [DeckRules.minCards] cartas.
final class TooFewCards extends DeckIssue {
  /// Crea el problema con la cantidad de cartas que tiene el mazo.
  const TooFewCards(this.count);

  /// Cartas que tiene el mazo.
  final int count;

  /// Cartas que faltan para llegar al mínimo.
  int get missing => DeckRules.minCards - count;
}

/// El mazo tiene más de [DeckRules.maxCards] cartas.
final class TooManyCards extends DeckIssue {
  /// Crea el problema con la cantidad de cartas que tiene el mazo.
  const TooManyCards(this.count);

  /// Cartas que tiene el mazo.
  final int count;

  /// Cartas que sobran para llegar al máximo.
  int get excess => count - DeckRules.maxCards;
}

/// El mazo tiene más de [DeckRules.maxCopies] copias de una misma carta.
final class TooManyCopies extends DeckIssue {
  /// Crea el problema de [card], que está [copies] veces en el mazo.
  const TooManyCopies(this.card, this.copies);

  /// Carta repetida de más.
  final GameCard card;

  /// Copias que tiene el mazo.
  final int copies;
}

/// El mazo no tiene Initial Effect.
final class MissingInitialEffect extends DeckIssue {
  /// Crea el problema.
  const MissingInitialEffect();
}

/// Revisa un mazo contra las reglas de RF-03 y devuelve las que no cumple, en
/// el orden en que se explican al estudiante. Una lista vacía significa que el
/// mazo es válido.
///
/// [cards] son las cartas del Deck, sin el [initialEffect], que va aparte y es
/// único. Las copias se cuentan por id de carta.
List<DeckIssue> validateDeck({
  required List<GameCard> cards,
  required InitialEffect? initialEffect,
}) {
  final copies = <String, int>{};
  final byId = <String, GameCard>{};
  for (final card in cards) {
    copies[card.id] = (copies[card.id] ?? 0) + 1;
    byId[card.id] = card;
  }

  return [
    if (cards.length < DeckRules.minCards) TooFewCards(cards.length),
    if (cards.length > DeckRules.maxCards) TooManyCards(cards.length),
    for (final entry in copies.entries)
      if (entry.value > DeckRules.maxCopies)
        TooManyCopies(byId[entry.key]!, entry.value),
    if (initialEffect == null) const MissingInitialEffect(),
  ];
}
