import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_engine/game_engine.dart';

import '../../catalog/domain/card_catalog.dart';

/// Jugador que controla la persona en la tablet.
const humanPlayer = Player.one;

/// Jugador que controla el sistema.
const systemPlayer = Player.two;

/// Generador de números al azar de las partidas. Los tests lo reemplazan
/// por uno con semilla fija para que las partidas sean reproducibles.
final matchRandomProvider = Provider<Random>((ref) => Random());

/// Estado de la pantalla de partida.
///
/// [GameMatch] cambia por dentro al jugar, así que cada acción crea un
/// estado nuevo (con [revision] distinto) para que la pantalla se redibuje.
class MatchViewState {
  /// Crea el estado.
  const MatchViewState({
    required this.match,
    required this.catalog,
    required this.log,
    required this.revision,
    this.lastResult,
  });

  /// Partida en curso.
  final GameMatch match;

  /// Catálogo, para mostrar las imágenes de las cartas.
  final CardCatalog catalog;

  /// Mensajes de lo que pasó en la partida, del más antiguo al más nuevo.
  final List<String> log;

  /// Resultado del último Clash, o `null` si aún no hay ninguno.
  final ClashResult? lastResult;

  /// Número que cambia con cada acción.
  final int revision;
}

/// Controla una partida contra el sistema en nivel Fácil (RF-15).
///
/// El estado es `null` mientras no haya una partida empezada.
class MatchController extends Notifier<MatchViewState?> {
  static const _opponent = EasyOpponent(systemPlayer);

  @override
  MatchViewState? build() => null;

  /// Empieza una partida nueva con mazos al azar del [catalog] para ambos
  /// jugadores (mientras no exista el Deck Builder).
  void startMatch(CardCatalog catalog) {
    final random = ref.read(matchRandomProvider);
    final match = GameMatch(
      playerOne: randomDeck(catalog.cards, random),
      playerTwo: randomDeck(catalog.cards, random),
      random: random,
    );
    state = MatchViewState(
      match: match,
      catalog: catalog,
      log: [
        'Match started. Your Initial Effect: '
            '${match.area(humanPlayer).initialEffect.card.name}.',
        "Opponent's Initial Effect: "
            '${match.area(systemPlayer).initialEffect.card.name}.',
      ],
      revision: 0,
    );
  }

  /// Revela las Creatures del próximo Clash. Si la partida sigue, el
  /// sistema juega sus cartas enseguida.
  void reveal() {
    final current = state;
    if (current == null) return;
    final match = current.match;
    final messages = <String>[];

    final revealed = match.revealCreatures();
    for (final player in Player.values) {
      for (final card in revealed[player]!) {
        messages.add('${_who(player)} revealed ${card.card.name}.');
      }
    }
    if (match.phase == MatchPhase.play) {
      for (final play in _opponent.playTurn(match)) {
        messages.add(switch (play) {
          EquippedItem(:final card) => 'Opponent equipped ${card.card.name}.',
          PlayedEffect(:final card) => 'Opponent played ${card.card.name}.',
        });
      }
    }
    if (match.phase == MatchPhase.finished) messages.add(_endMessage(match));
    _update(messages);
  }

  /// Juega [card] de la Hand del jugador: equipa un Item o juega un
  /// Effect.
  ///
  /// Devuelve un mensaje en inglés si la jugada no está permitida, para
  /// mostrárselo al estudiante; `null` si se jugó.
  String? playCard(MatchCard card) {
    final current = state;
    if (current == null) return null;
    final match = current.match;
    final messages = <String>[];

    switch (card) {
      case MatchCard<Item>():
        final reason = match.checkEquipItem(humanPlayer, card);
        if (reason != null) return explain(reason);
        match.equipItem(humanPlayer, card);
        messages.add('You equipped ${card.card.name}.');
      case MatchCard<Effect>():
        final reason = match.checkPlayEffect(humanPlayer, card);
        if (reason != null) return explain(reason);
        final revealed = match.playEffect(humanPlayer, card);
        messages.add('You played ${card.card.name}.');
        for (final replacement in revealed[systemPlayer]!) {
          messages.add('Opponent revealed ${replacement.card.name}.');
        }
        if (match.phase == MatchPhase.finished) {
          messages.add(_endMessage(match));
        }
      default:
        return 'This card cannot be played.';
    }
    _update(messages);
    return null;
  }

  /// Resuelve el Clash actual.
  void clash() {
    final current = state;
    if (current == null) return;
    final result = current.match.resolveClash();
    _update([describe(result)], lastResult: result);
  }

  void _update(List<String> messages, {ClashResult? lastResult}) {
    final current = state!;
    state = MatchViewState(
      match: current.match,
      catalog: current.catalog,
      log: [...current.log, ...messages],
      revision: current.revision + 1,
      lastResult: lastResult ?? current.lastResult,
    );
  }

  String _who(Player player) => player == humanPlayer ? 'You' : 'Opponent';

  String _endMessage(GameMatch match) {
    final result = match.result;
    final mine = humanPlayer == Player.one
        ? result.trophiesOfOne
        : result.trophiesOfTwo;
    final theirs = humanPlayer == Player.one
        ? result.trophiesOfTwo
        : result.trophiesOfOne;
    final outcome = switch (result.winner) {
      null => "It's a draw!",
      humanPlayer => 'You win!',
      _ => 'You lose.',
    };
    return 'Match over. $outcome Trophies: $mine - $theirs.';
  }
}

/// Explica en inglés, para el estudiante, por qué no puede jugar una carta.
String explain(InvalidPlayReason reason) => switch (reason) {
  InvalidPlayReason.wrongPhase => 'You can only play cards during a Clash.',
  InvalidPlayReason.notInHand => 'That card is not in your hand.',
  InvalidPlayReason.noCreatureInPlay => 'You need a Creature in play.',
  InvalidPlayReason.creatureAlreadyHasItem =>
    'Your Creature already has an Item.',
  InvalidPlayReason.classMismatch =>
    "This Item does not match your Creature's Class.",
  InvalidPlayReason.forbiddenRarity =>
    "Your Creature's Rarity cannot use this Item.",
  InvalidPlayReason.forbiddenByEnemy =>
    'Your opponent does not allow you to play this now.',
};

/// Describe en inglés el resultado de un Clash, visto por el estudiante.
String describe(ClashResult result) => switch (result) {
  ClashWin(:final winner, :final reason) =>
    '${winner == ClashSide.first ? 'You win' : 'You lose'} the Clash '
        '${reason == WinReason.rarity ? 'by Rarity' : 'by Power'}.',
  ClashTie(:final reason) =>
    "Tie! ${reason == TieReason.sameClass ? 'Same Class' : 'Same Power'}. "
        'The next Clash decides it.',
};

/// Partida en curso de la pantalla de juego.
final matchControllerProvider =
    NotifierProvider<MatchController, MatchViewState?>(MatchController.new);
