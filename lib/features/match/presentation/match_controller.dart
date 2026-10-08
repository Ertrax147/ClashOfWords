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

/// Algo que pasó en la mesa y que la pantalla muestra con calma, una carta
/// a la vez: una carta revelada o una carta que jugó el rival.
class MatchEvent {
  /// Crea el evento de [card] con su [caption] en inglés.
  const MatchEvent({required this.card, required this.caption});

  /// Carta que se muestra en grande.
  final GameCard card;

  /// Frase que explica qué pasó, por ejemplo "You revealed Farm Drugstore".
  final String caption;
}

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
    this.events = const [],
  });

  /// Eventos que la pantalla todavía no termina de mostrar, en orden. Mientras
  /// haya alguno, los botones de la partida esperan.
  final List<MatchEvent> events;

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
    final events = <MatchEvent>[];

    final revealed = match.revealCreatures();
    for (final player in Player.values) {
      for (final card in revealed[player]!) {
        events.add(_revealEvent(player, card));
      }
    }
    if (match.phase == MatchPhase.play) {
      for (final play in _opponent.playTurn(match)) {
        events.add(switch (play) {
          EquippedItem(:final card) => MatchEvent(
            card: card.card,
            caption: 'Opponent equipped ${card.card.name}',
          ),
          PlayedEffect(:final card) => MatchEvent(
            card: card.card,
            caption: 'Opponent played ${card.card.name}',
          ),
        });
      }
    }
    _update([
      for (final event in events) '${event.caption}.',
      if (match.phase == MatchPhase.finished) _endMessage(match),
    ], newEvents: events);
  }

  /// Marca como visto el primer evento de la cola.
  void dismissEvent() {
    final current = state;
    if (current == null || current.events.isEmpty) return;
    state = MatchViewState(
      match: current.match,
      catalog: current.catalog,
      log: current.log,
      revision: current.revision + 1,
      lastResult: current.lastResult,
      events: current.events.sublist(1),
    );
  }

  MatchEvent _revealEvent(Player player, MatchCard card) {
    final destination = switch (card) {
      MatchCard<Creature>() => 'to the Clash',
      _ => player == humanPlayer ? 'to your hand' : "to the opponent's hand",
    };
    return MatchEvent(
      card: card.card,
      caption: '${_who(player)} revealed ${card.card.name} → $destination',
    );
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
    final events = <MatchEvent>[];

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
          final event = _revealEvent(systemPlayer, replacement);
          events.add(event);
          messages.add('${event.caption}.');
        }
        if (match.phase == MatchPhase.finished) {
          messages.add(_endMessage(match));
        }
      default:
        return 'This card cannot be played.';
    }
    _update(messages, newEvents: events);
    return null;
  }

  /// Resuelve el Clash actual.
  ///
  /// Si el perdedor tiene Tolerance y sus Creatures derrotadas vuelven a su
  /// Discard Stack en vez de ser trofeos, lo explica en el registro: si no,
  /// parecería que el ganador no recibió nada.
  void clash() {
    final current = state;
    if (current == null) return;
    final match = current.match;
    final discardsBefore = {
      for (final player in Player.values)
        player: match.area(player).discardStack.length,
    };

    final result = match.resolveClash();
    // Todavía no hay pantalla para decidir si se usa Commitment: por ahora
    // el Clash se aplica tal como se resolvió.
    if (match.phase == MatchPhase.afterClash) match.declineCommitment();
    final messages = [describe(result)];
    if (result case ClashWin(:final winner)) {
      final loser = winner == ClashSide.first ? Player.two : Player.one;
      if (match.hasPassive(loser, InitialEffectKind.tolerance)) {
        final saved = match
            .area(loser)
            .discardStack
            .skip(discardsBefore[loser]!)
            .whereType<MatchCard<Creature>>()
            .map((card) => card.card.name)
            .toList();
        if (saved.isNotEmpty) {
          final whose = loser == humanPlayer ? 'Your' : "Opponent's";
          final where = loser == humanPlayer
              ? 'your Discard Stack instead of the Trophy Stack'
              : "their Discard Stack instead of your Trophy Stack";
          messages.add('$whose Tolerance sends ${saved.join(', ')} to $where.');
        }
      }
    }
    _update(messages, lastResult: result);
  }

  void _update(
    List<String> messages, {
    ClashResult? lastResult,
    List<MatchEvent> newEvents = const [],
  }) {
    final current = state!;
    state = MatchViewState(
      match: current.match,
      catalog: current.catalog,
      log: [...current.log, ...messages],
      revision: current.revision + 1,
      lastResult: lastResult ?? current.lastResult,
      events: [...current.events, ...newEvents],
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
  InvalidPlayReason.alreadyUsed => 'You already used your Initial Effect.',
  InvalidPlayReason.noActiveAbility =>
    'Your Initial Effect has no ability to activate.',
  InvalidPlayReason.noValidTarget => 'There is nothing to use it on.',
  InvalidPlayReason.invalidChoice => 'That is not a valid choice.',
};

/// Describe en inglés el resultado de un Clash, visto por el estudiante.
String describe(ClashResult result) => switch (result) {
  ClashWin(:final winner, :final reason) =>
    '${winner == ClashSide.first ? 'You win' : 'You lose'} the Clash '
        '${switch (reason) {
          WinReason.rarity => 'by Rarity',
          WinReason.power => 'by Power',
          WinReason.commitment => 'thanks to Commitment',
        }}.',
  ClashTie(:final reason) =>
    "Tie! ${reason == TieReason.sameClass ? 'Same Class' : 'Same Power'}. "
        'The next Clash decides it.',
};

/// Partida en curso de la pantalla de juego.
final matchControllerProvider =
    NotifierProvider<MatchController, MatchViewState?>(MatchController.new);
