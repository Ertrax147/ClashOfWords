import 'dart:math';

import 'package:meta/meta.dart';

import '../entities/game_card.dart';
import 'creature_in_play.dart';
import 'effect_in_play.dart';
import 'match_card.dart';

/// Zona de juego de un jugador: sus pilas, su Initial Effect, su Creature
/// en juego y sus Effects en juego.
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
  final List<MatchCard> _tiedCards = [];
  final List<EffectInPlay> _effectsInPlay = [];
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

  /// Creatures apartadas por un Tie sin resolver, con sus Items. Siguen en
  /// juego hasta que un nuevo Clash defina a quién le corresponden (CU-04).
  List<MatchCard> get tiedCards => List.unmodifiable(_tiedCards);

  /// Effects que el jugador jugó y siguen en juego, en el orden en que se
  /// jugaron.
  List<EffectInPlay> get effectsInPlay => List.unmodifiable(_effectsInPlay);

  /// Saca la carta superior del Deck, o devuelve `null` si está vacío.
  @internal
  MatchCard? drawTop() => _deck.isEmpty ? null : _deck.removeAt(0);

  /// Pone a [creature] en la mesa. [order] indica en qué momento de la
  /// partida entró.
  @internal
  void putInPlay(MatchCard<Creature> creature, {int order = 0}) =>
      _creatureInPlay = CreatureInPlay(creature, order: order);

  /// Pone en juego a [effect], que ya salió de la Hand.
  @internal
  void addEffectInPlay(EffectInPlay effect) => _effectsInPlay.add(effect);

  /// Descuenta un Clash a cada Effect en juego y devuelve las cartas de los
  /// que se agotaron, que dejan de estar en juego.
  @internal
  List<MatchCard> spendEffectsClash() {
    for (final effect in _effectsInPlay) {
      effect.spendClash();
    }
    final exhausted = _effectsInPlay.where((effect) => effect.isExhausted);
    final cards = [for (final effect in exhausted) effect.effect];
    _effectsInPlay.removeWhere((effect) => effect.isExhausted);
    return cards;
  }

  /// Saca todos los Effects en juego y devuelve sus cartas.
  @internal
  List<MatchCard> takeEffectsInPlay() {
    final cards = [for (final effect in _effectsInPlay) effect.effect];
    _effectsInPlay.clear();
    return cards;
  }

  /// Saca de la mesa a la Creature en juego y devuelve sus cartas: la
  /// Creature y su Item, si tiene.
  @internal
  List<MatchCard> removeFromPlay() {
    final inPlay = _creatureInPlay;
    _creatureInPlay = null;
    if (inPlay == null) return [];
    return [inPlay.creature, ...inPlay.items];
  }

  /// Aparta a la Creature en juego y su Item por un Tie.
  @internal
  void setAsideTied() => _tiedCards.addAll(removeFromPlay());

  /// Saca las cartas apartadas por un Tie y las devuelve, para moverlas a
  /// la pila que corresponda.
  @internal
  List<MatchCard> takeTied() {
    final cards = List.of(_tiedCards);
    _tiedCards.clear();
    return cards;
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

  /// Quita [card] del Discard Stack. Devuelve `false` si no estaba ahí.
  @internal
  bool removeFromDiscard(MatchCard card) => _discardStack.remove(card);

  /// Pone [card] en el Deck y lo baraja con [random].
  @internal
  void shuffleIntoDeck(MatchCard card, Random random) {
    _deck
      ..add(card)
      ..shuffle(random);
  }

  /// Agrega [cards] al Trophy Stack.
  @internal
  void addTrophies(Iterable<MatchCard> cards) => _trophyStack.addAll(cards);
}
