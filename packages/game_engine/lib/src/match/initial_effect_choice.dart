import 'match_card.dart';

/// Lo que elige un jugador al usar la habilidad activa de su Initial
/// Effect.
///
/// Es `sealed`: un `switch` sobre una elección obliga a contemplar todos
/// los tipos. Cada habilidad espera el tipo que le corresponde; si recibe
/// otro, la partida rechaza la jugada.
sealed class InitialEffectChoice {
  const InitialEffectChoice();
}

/// La habilidad no necesita que el jugador elija nada.
final class NoChoice extends InitialEffectChoice {
  /// Crea la elección vacía.
  const NoChoice();
}

/// El jugador reordena las cartas superiores de los Decks (Honesty).
///
/// Cada lista es la nueva disposición de las cartas que se revelaron del
/// Deck correspondiente. La primera queda como carta superior.
final class ReorderChoice extends InitialEffectChoice {
  /// Crea la elección con el nuevo orden de ambos Decks.
  const ReorderChoice({required this.own, required this.enemy});

  /// Nuevo orden de las cartas superiores del Deck propio.
  final List<MatchCard> own;

  /// Nuevo orden de las cartas superiores del Deck del rival.
  final List<MatchCard> enemy;
}

/// El jugador elige una carta, por ejemplo la Creature que Recycle devuelve
/// al Deck.
final class CardChoice extends InitialEffectChoice {
  /// Crea la elección de [card].
  const CardChoice(this.card);

  /// Carta elegida.
  final MatchCard card;
}
