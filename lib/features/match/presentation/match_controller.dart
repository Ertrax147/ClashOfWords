import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_engine/game_engine.dart';

import '../../catalog/domain/card_catalog.dart';
import 'ability_text.dart';

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

  /// Si el estudiante perdió el Clash y debe decidir si usa Commitment.
  ///
  /// Mientras no decida, el Clash no se aplicó: las Creatures siguen en la
  /// mesa.
  bool get awaitingCommitment =>
      match.phase == MatchPhase.afterClash &&
      match.awaitingCommitment == humanPlayer;
}

/// Controla una partida contra el sistema en nivel Fácil (RF-15).
///
/// El estado es `null` mientras no haya una partida empezada.
class MatchController extends Notifier<MatchViewState?> {
  static const _opponent = EasyOpponent(systemPlayer);

  /// Cartas de cada Discard Stack antes del Clash que se está resolviendo,
  /// para explicar qué Creatures salvó Tolerance.
  Map<Player, int> _discardsBeforeClash = const {};

  @override
  MatchViewState? build() => null;

  /// Empieza una partida nueva con mazos al azar del [catalog] para ambos
  /// jugadores (mientras no exista el Deck Builder).
  ///
  /// [humanDeck] y [systemDeck] permiten elegir los mazos, y [shuffle] en
  /// `false` respeta su orden: sirve para los tests.
  void startMatch(
    CardCatalog catalog, {
    PlayerDeck? humanDeck,
    PlayerDeck? systemDeck,
    bool shuffle = true,
  }) {
    final random = ref.read(matchRandomProvider);
    final match = GameMatch(
      playerOne: humanDeck ?? randomDeck(catalog.cards, random),
      playerTwo: systemDeck ?? randomDeck(catalog.cards, random),
      shuffle: shuffle,
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
  /// Si el estudiante pierde y tiene Commitment sin usar, el Clash queda
  /// pendiente hasta que decida ([useInitialEffect] o [declineCommitment]).
  /// El rival del sistema todavía no usa habilidades activas, así que no
  /// usa Commitment.
  void clash() {
    final current = state;
    if (current == null) return;
    final match = current.match;
    _discardsBeforeClash = {
      for (final player in Player.values)
        player: match.area(player).discardStack.length,
    };

    match.resolveClash();
    if (match.phase == MatchPhase.afterClash) {
      if (match.awaitingCommitment == humanPlayer) {
        _update(['You lost the Clash. You can use Commitment to win it.']);
        return;
      }
      match.declineCommitment();
    }
    _finishClash(match);
  }

  /// El estudiante decide no usar Commitment: el Clash se aplica como se
  /// resolvió. Puede usarlo en otro Clash.
  void declineCommitment() {
    final current = state;
    if (current == null) return;
    final match = current.match;
    if (match.phase != MatchPhase.afterClash) return;
    match.declineCommitment();
    _finishClash(match, first: ['You decided not to use Commitment.']);
  }

  /// El estudiante usa la habilidad activa de su Initial Effect con la
  /// elección [choice] (ver [GameMatch.useInitialEffect]).
  ///
  /// Devuelve un mensaje en inglés si no se puede usar, para mostrárselo al
  /// estudiante; `null` si se usó.
  String? useInitialEffect([InitialEffectChoice choice = const NoChoice()]) {
    final current = state;
    if (current == null) return null;
    final match = current.match;
    final reason = match.checkUseInitialEffect(humanPlayer, choice);
    if (reason != null) return explain(reason);

    final kind = match.activeKindOf(humanPlayer)!;
    final name = initialEffectName(kind);
    final chosen = choice is CardChoice ? choice.card : null;
    // Kindness roba una carta que nadie ha visto: se muestra al usarla.
    final stolen = kind == InitialEffectKind.kindness
        ? match.area(systemPlayer).deck.first
        : null;

    final revealed = match.useInitialEffect(humanPlayer, choice);

    if (kind == InitialEffectKind.commitment) {
      _finishClash(
        match,
        first: [
          'You used Commitment: you win the Clash.',
          if (chosen != null)
            "${chosen.card.name} goes to your opponent's Discard Stack.",
        ],
        movedByCommitment: chosen,
      );
      return null;
    }

    final messages = [
      switch (kind) {
        InitialEffectKind.recycle || InitialEffectKind.responsibility =>
          'You used $name: ${chosen!.card.name} goes back to your Deck.',
        InitialEffectKind.leadership =>
          'You used $name: your Creature stays in play for 3 Clashes.',
        InitialEffectKind.kindness =>
          'You used $name: you took ${stolen!.card.name} from your '
              "opponent's Deck.",
        InitialEffectKind.loyalty =>
          'You used $name: ${chosen!.card.name} returns to your Discard '
              'Stack.',
        InitialEffectKind.honesty =>
          'You used $name: you put the top cards back in your order.',
        InitialEffectKind.creativity =>
          'You used $name: ${chosen!.card.name} replaces your Creature.',
        InitialEffectKind.generosity =>
          'You used $name: you took ${chosen!.card.name} from your '
              "opponent's hand.",
        _ => 'You used $name.',
      },
    ];
    final events = <MatchEvent>[
      if (stolen != null)
        MatchEvent(
          card: stolen.card,
          caption: "You took ${stolen.card.name} from your opponent's Deck",
        ),
    ];
    for (final player in Player.values) {
      for (final card in revealed[player]!) {
        final event = _revealEvent(player, card);
        events.add(event);
        messages.add('${event.caption}.');
      }
    }
    if (match.phase == MatchPhase.finished) messages.add(_endMessage(match));
    _update(messages, newEvents: events);
    return null;
  }

  /// Registra cómo terminó el Clash que acaba de aplicarse.
  ///
  /// Si el perdedor tiene Tolerance y sus Creatures derrotadas vuelven a su
  /// Discard Stack en vez de ser trofeos, lo explica en el registro: si no,
  /// parecería que el ganador no recibió nada. [movedByCommitment] es la
  /// Creature que Commitment mandó al Discard Stack del rival, que no la
  /// salvó Tolerance.
  void _finishClash(
    GameMatch match, {
    List<String> first = const [],
    MatchCard? movedByCommitment,
  }) {
    final result = match.lastClashResult!;
    final messages = [...first, describe(result)];
    if (result case ClashWin(:final winner)) {
      final loser = winner == ClashSide.first ? Player.two : Player.one;
      if (match.hasPassive(loser, InitialEffectKind.tolerance)) {
        final saved = match
            .area(loser)
            .discardStack
            .skip(_discardsBeforeClash[loser] ?? 0)
            .whereType<MatchCard<Creature>>()
            .where((card) => card != movedByCommitment)
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
