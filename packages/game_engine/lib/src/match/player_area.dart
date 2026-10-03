import 'package:meta/meta.dart';

import '../entities/game_card.dart';
import 'creature_in_play.dart';
import 'match_card.dart';

/// Zona de juego de un jugador: sus pilas, su Initial Effect y su Creature
/// en juego.
///
/// Las listas que expone son de solo lectura. Los métodos que mueven cartas
/// son `@internal`: solo la partida puede usarlos, porque es la que aplica
/// las reglas. Si una pantalla los llama, el analizador lo marca.
final class PlayerArea {
  /// Crea la zona con el [deck] en el orden dado (el primero es la carta
  /// superior) y su [initialEffect].
  @internal
  PlayerArea({required List<MatchCard> deck, required this.initialEffect})
    : _deck = List.of(deck);

  final List<MatchCard> _deck;
  final List<MatchCard> _hand = [];
  final List<MatchCard> _discardStack = [];
  final List<MatchCard> _trophyStack = [];
  CreatureInPlay? _creatureInPlay;

  /// Initial Effect del jugador, en juego desde el inicio de la partida.
  final MatchCard<InitialEffect> initialEffect;

  /// Creature en la mesa, o `null` si no tiene ninguna.
  CreatureInPlay? get creatureInPlay => _creatureInPlay;

  /// Cartas que quedan en el Deck. La primera es la carta superior.
  List<MatchCard> get deck => List.unmodifiable(_deck);

  /// Items y Effects revelados que el jugador puede usar. Son visibles para
  /// ambos jugadores.
  List<MatchCard> get hand => List.unmodifiable(_hand);

  /// Cartas propias que ya ganaron un Clash o ya se usaron.
  List<MatchCard> get discardStack => List.unmodifiable(_discardStack);

  /// Cartas del rival que este jugador venció: sus trofeos.
  List<MatchCard> get trophyStack => List.unmodifiable(_trophyStack);

  /// Saca la carta superior del Deck, o devuelve `null` si está vacío.
  @internal
  MatchCard? drawTop() => _deck.isEmpty ? null : _deck.removeAt(0);

  /// Pone a [creature] en la mesa.
  @internal
  void putInPlay(MatchCard<Creature> creature) =>
      _creatureInPlay = CreatureInPlay(creature);

  /// Saca de la mesa a la Creature en juego y devuelve sus cartas: la
  /// Creature y su Item, si tiene.
  @internal
  List<MatchCard> removeFromPlay() {
    final inPlay = _creatureInPlay;
    _creatureInPlay = null;
    if (inPlay == null) return [];
    return [inPlay.creature, ?inPlay.item];
  }

  /// Agrega [card] a la Hand.
  @internal
  void addToHand(MatchCard card) => _hand.add(card);

  /// Quita [card] de la Hand. Devuelve `false` si no estaba ahí.
  @internal
  bool removeFromHand(MatchCard card) => _hand.remove(card);

  /// Agrega [cards] al Discard Stack.
  @internal
  void discard(Iterable<MatchCard> cards) => _discardStack.addAll(cards);

  /// Agrega [cards] al Trophy Stack.
  @internal
  void addTrophies(Iterable<MatchCard> cards) => _trophyStack.addAll(cards);
}
