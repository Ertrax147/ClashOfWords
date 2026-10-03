import 'dart:math';

import '../entities/game_card.dart';
import '../rules/clash_resolver.dart';
import '../rules/clash_resolver.dart' as rules show resolveClash;
import 'match_card.dart';
import 'player.dart';
import 'player_area.dart';

/// Fase en que está una partida.
enum MatchPhase {
  /// Hay que revelar Creatures para el próximo Clash
  /// ([GameMatch.revealCreatures]).
  reveal,

  /// Ambas Creatures están en la mesa. Los jugadores pueden jugar cartas
  /// antes de resolver el Clash ([GameMatch.resolveClash]).
  play,

  /// El último Clash terminó en Tie. Su resolución se implementa en una
  /// etapa posterior del motor.
  tie,

  /// La partida terminó y tiene resultado ([GameMatch.result]).
  finished,
}

/// Mazo con el que un jugador entra a la partida.
final class PlayerDeck {
  /// Crea un mazo con sus [cards] y su [initialEffect].
  ///
  /// Lanza un [ArgumentError] si [cards] incluye algún Initial Effect: cada
  /// jugador tiene uno solo y va aparte, no dentro del Deck.
  PlayerDeck({required List<GameCard> cards, required this.initialEffect})
    : cards = List.unmodifiable(cards) {
    if (cards.any((card) => card is InitialEffect)) {
      throw ArgumentError.value(
        cards,
        'cards',
        'The initial effect goes apart, not inside the deck',
      );
    }
  }

  /// Cartas del Deck: Creatures, Items y Effects.
  final List<GameCard> cards;

  /// Initial Effect del jugador.
  final InitialEffect initialEffect;
}

/// Motivo por el que una jugada no está permitida.
enum InvalidPlayReason {
  /// La partida no está en la fase de jugar cartas.
  wrongPhase,

  /// La carta no está en la Hand del jugador.
  notInHand,

  /// El jugador no tiene una Creature en la mesa.
  noCreatureInPlay,

  /// La Creature ya tiene un Item equipado. Solo puede llevar uno (RF-10).
  creatureAlreadyHasItem,

  /// La Class de la Creature no está entre las Class del Item (RF-10).
  classMismatch,
}

/// Error que se produce al intentar una jugada no permitida.
final class InvalidPlayException implements Exception {
  /// Crea el error con el motivo [reason].
  const InvalidPlayException(this.reason);

  /// Por qué la jugada no está permitida.
  final InvalidPlayReason reason;

  @override
  String toString() => 'InvalidPlayException(${reason.name})';
}

/// Resultado final de una partida.
final class MatchResult {
  /// Crea el resultado a partir de los trofeos de cada jugador.
  MatchResult({required this.trophiesOfOne, required this.trophiesOfTwo});

  /// Cantidad de cartas en el Trophy Stack del jugador uno.
  final int trophiesOfOne;

  /// Cantidad de cartas en el Trophy Stack del jugador dos.
  final int trophiesOfTwo;

  /// Ganador de la partida, o `null` si hubo empate.
  ///
  /// Gana quien tenga más cartas en su Trophy Stack, contando Creatures e
  /// Items (RF-04).
  Player? get winner {
    if (trophiesOfOne == trophiesOfTwo) return null;
    return trophiesOfOne > trophiesOfTwo ? Player.one : Player.two;
  }

  /// Indica si la partida terminó en empate.
  bool get isDraw => winner == null;
}

/// Partida de Clash of Words entre dos jugadores (RF-04, CU-03).
///
/// No hay turnos: cada ronda sigue los pasos del manual.
/// 1. [revealCreatures]: cada jugador sin Creature en la mesa revela cartas
///    hasta que aparezca una Creature. Los Items y Effects van a su Hand.
/// 2. Los jugadores juegan cartas de su Hand, por ejemplo [equipItem].
/// 3. [resolveClash]: se resuelve el Clash y las cartas van a su pila.
///
/// La partida termina cuando un jugador necesita revelar una Creature y su
/// Deck está vacío. Las Creatures que siguen en la mesa van al Discard Stack
/// de su dueño y gana quien tenga más trofeos ([result]).
final class GameMatch {
  /// Crea una partida con los mazos de ambos jugadores.
  ///
  /// Los Decks se barajan con [random]. Con [shuffle] en `false` se respeta
  /// el orden dado (la primera carta es la superior), lo que sirve para los
  /// tests y para reproducir partidas.
  factory GameMatch({
    required PlayerDeck playerOne,
    required PlayerDeck playerTwo,
    bool shuffle = true,
    Random? random,
  }) {
    var nextId = 0;
    PlayerArea areaFor(Player owner, PlayerDeck deck) {
      final cards = [
        for (final card in deck.cards) _matchCardOf(nextId++, card, owner),
      ];
      if (shuffle) cards.shuffle(random);
      return PlayerArea(
        deck: cards,
        initialEffect: MatchCard(
          id: nextId++,
          card: deck.initialEffect,
          owner: owner,
        ),
      );
    }

    return GameMatch._({
      Player.one: areaFor(Player.one, playerOne),
      Player.two: areaFor(Player.two, playerTwo),
    });
  }

  GameMatch._(this._areas);

  final Map<Player, PlayerArea> _areas;
  MatchPhase _phase = MatchPhase.reveal;

  /// Crea la copia de [card] con el tipo exacto de la carta, para que el
  /// motor pueda distinguir Creatures, Items y Effects.
  static MatchCard _matchCardOf(int id, GameCard card, Player owner) =>
      switch (card) {
        Creature() => MatchCard<Creature>(id: id, card: card, owner: owner),
        Item() => MatchCard<Item>(id: id, card: card, owner: owner),
        Effect() => MatchCard<Effect>(id: id, card: card, owner: owner),
        InitialEffect() => MatchCard<InitialEffect>(
          id: id,
          card: card,
          owner: owner,
        ),
      };

  /// Fase actual de la partida.
  MatchPhase get phase => _phase;

  /// Zona de juego de [player]: sus pilas y su Creature en la mesa.
  PlayerArea area(Player player) => _areas[player]!;

  /// Resultado de la partida.
  ///
  /// Lanza un [StateError] si la partida no ha terminado.
  MatchResult get result {
    _requirePhase(MatchPhase.finished);
    return MatchResult(
      trophiesOfOne: area(Player.one).trophyStack.length,
      trophiesOfTwo: area(Player.two).trophyStack.length,
    );
  }

  /// Revela cartas hasta que cada jugador tenga una Creature en la mesa.
  ///
  /// Un jugador cuya Creature sigue en juego por su Duration no revela. Los
  /// Items y Effects revelados van a la Hand de su dueño. Si un jugador
  /// necesita revelar y se queda sin cartas en el Deck, la partida termina.
  ///
  /// Devuelve las cartas que reveló cada jugador, en orden, para que la
  /// interfaz pueda mostrarlas. Lanza un [StateError] si la partida no está
  /// en la fase [MatchPhase.reveal].
  Map<Player, List<MatchCard>> revealCreatures() {
    _requirePhase(MatchPhase.reveal);
    final revealed = {
      for (final player in Player.values) player: <MatchCard>[],
    };
    var someoneRanOut = false;

    for (final player in Player.values) {
      final area = this.area(player);
      while (area.creatureInPlay == null) {
        final card = area.drawTop();
        if (card == null) {
          someoneRanOut = true;
          break;
        }
        revealed[player]!.add(card);
        if (card is MatchCard<Creature>) {
          area.putInPlay(card);
        } else {
          area.addToHand(card);
        }
      }
    }

    if (someoneRanOut) {
      _finish();
    } else {
      _phase = MatchPhase.play;
    }
    return revealed;
  }

  /// Indica por qué [player] no puede equipar [item], o `null` si sí puede.
  ///
  /// Sirve para que la interfaz desactive las jugadas no permitidas.
  InvalidPlayReason? checkEquipItem(Player player, MatchCard<Item> item) {
    if (_phase != MatchPhase.play) return InvalidPlayReason.wrongPhase;
    final area = this.area(player);
    if (!area.hand.contains(item)) return InvalidPlayReason.notInHand;
    final inPlay = area.creatureInPlay;
    if (inPlay == null) return InvalidPlayReason.noCreatureInPlay;
    if (inPlay.item != null) return InvalidPlayReason.creatureAlreadyHasItem;
    if (!item.card.canBeEquippedTo(inPlay.creature.card)) {
      return InvalidPlayReason.classMismatch;
    }
    return null;
  }

  /// [player] equipa [item] de su Hand a su Creature en la mesa (RF-10).
  ///
  /// Lanza un [InvalidPlayException] si la jugada no está permitida (ver
  /// [checkEquipItem]).
  void equipItem(Player player, MatchCard<Item> item) {
    final reason = checkEquipItem(player, item);
    if (reason != null) throw InvalidPlayException(reason);
    final area = this.area(player);
    area.removeFromHand(item);
    area.creatureInPlay!.equip(item);
  }

  /// Resuelve el Clash entre las dos Creatures en la mesa (RF-04).
  ///
  /// Si hay ganador:
  /// - La perdedora y su Item van al Trophy Stack del ganador, aunque le
  ///   quedara Duration.
  /// - La ganadora descuenta un Clash. Si agotó su Duration, va con su Item
  ///   al Discard Stack de su dueño; si no, sigue en la mesa.
  ///
  /// Si hay Tie, la partida pasa a la fase [MatchPhase.tie].
  ///
  /// Lanza un [StateError] si la partida no está en la fase
  /// [MatchPhase.play].
  ClashResult resolveClash() {
    _requirePhase(MatchPhase.play);
    final first = area(Player.one).creatureInPlay!;
    final second = area(Player.two).creatureInPlay!;
    final result = rules.resolveClash(first.stats, second.stats);

    switch (result) {
      case ClashWin(:final winner):
        final winnerPlayer = winner == ClashSide.first
            ? Player.one
            : Player.two;
        final winnerArea = area(winnerPlayer);
        final loserArea = area(winnerPlayer.opponent);

        winnerArea.addTrophies(loserArea.removeFromPlay());
        final survivor = winnerArea.creatureInPlay!..spendClash();
        if (survivor.isExhausted) {
          winnerArea.discard(winnerArea.removeFromPlay());
        }
        _phase = MatchPhase.reveal;
      case ClashTie():
        _phase = MatchPhase.tie;
    }
    return result;
  }

  /// Termina la partida: las Creatures que siguen en la mesa vuelven al
  /// Discard Stack de su dueño, porque nadie las venció.
  void _finish() {
    for (final area in _areas.values) {
      area.discard(area.removeFromPlay());
    }
    _phase = MatchPhase.finished;
  }

  void _requirePhase(MatchPhase expected) {
    if (_phase != expected) {
      throw StateError(
        'Expected phase ${expected.name}, but it is ${_phase.name}',
      );
    }
  }
}
