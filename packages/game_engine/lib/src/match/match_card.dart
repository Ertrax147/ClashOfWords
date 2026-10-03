import '../entities/game_card.dart';
import 'player.dart';

/// Copia concreta de una carta dentro de una partida.
///
/// Un mazo puede tener hasta 3 copias de la misma carta del catálogo, así
/// que el motor necesita distinguirlas: cada [MatchCard] tiene un [id] único
/// en la partida, aunque dos copias compartan la misma [card].
///
/// También guarda a su dueño ([owner]), que no cambia aunque la carta
/// termine en el Trophy Stack del rival. Esto sirve para el intercambio de
/// cartas al final de la partida (RF-13).
final class MatchCard<T extends GameCard> {
  /// Crea la copia [id] de [card], que pertenece a [owner].
  const MatchCard({required this.id, required this.card, required this.owner});

  /// Identificador único de esta copia dentro de la partida.
  final int id;

  /// Carta del catálogo de la que es copia.
  final T card;

  /// Jugador dueño de la carta.
  final Player owner;

  /// Dos [MatchCard] son iguales si son la misma copia (mismo [id]).
  @override
  bool operator ==(Object other) => other is MatchCard && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'MatchCard($id, ${card.name})';
}
