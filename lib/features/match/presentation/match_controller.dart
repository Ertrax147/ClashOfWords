import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_engine/game_engine.dart';

import '../../catalog/domain/card_catalog.dart';
import 'ability_text.dart';
import 'match_zones.dart';

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
  const MatchEvent({
    required this.card,
    required this.caption,
    this.cardId,
    this.destination,
    this.from,
  });

  /// Zona de la que salió la carta, para que el contador de un Deck baje a
  /// medida que se muestran sus cartas, o `null` si no importa.
  final Zone? from;

  /// Carta que se muestra en grande.
  final GameCard card;

  /// Id de la copia de la carta en la partida, para no animarla dos veces.
  final int? cardId;

  /// Zona a la que va la carta cuando el aviso termina, o `null` si no va a
  /// ninguna.
  final Zone? destination;

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
    this.moves,
    this.logVisible,
  });

  /// Cuántos mensajes del registro se muestran mientras hay animaciones
  /// pendientes, o `null` si se muestran todos. Así el registro no cuenta
  /// lo que pasó antes de que las cartas lleguen a su lugar.
  final int? logVisible;

  /// Cartas que acaban de cambiar de zona y la pantalla anima, o `null` si no
  /// hay ninguna animación pendiente.
  final MoveBatch? moves;

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

  /// Si hay avisos o cartas viajando: lo que muestra la mesa todavía no
  /// coincide con el estado real de la partida.
  bool get animating => events.isNotEmpty || moves != null;

  /// Ids de las cartas que todavía no deben verse en su lugar de destino,
  /// porque están por llegar: las de los avisos pendientes y las que viajan.
  Set<int> get hiddenCardIds => {
    for (final event in events)
      if (event.cardId != null) event.cardId!,
    for (final move in moves?.moves ?? <MatchMove>[]) move.card.id,
  };

  /// Cartas que ya salieron del Deck de [player] en la partida pero la
  /// pantalla todavía no muestra: las de los avisos pendientes (sin contar el
  /// que se ve ahora, que ya salió) y las que viajan. Se suman al largo real
  /// del Deck para que el contador baje a medida que salen las cartas.
  int pendingFromDeck(Player player) {
    final deck = Zone(player, ZoneKind.deck);
    final waiting = events.skip(1).where((event) => event.from == deck).length;
    final travelling =
        moves?.moves.where((move) => move.from == deck).length ?? 0;
    return waiting + travelling;
  }

  /// Mensajes del registro que se muestran ahora.
  List<String> get visibleLog {
    final visible = logVisible;
    return visible == null || visible >= log.length
        ? log
        : log.sublist(0, visible);
  }

  /// Copia el estado con los eventos y el lote de movimientos indicados.
  ///
  /// Cuando ya no queda nada animándose, el registro vuelve a mostrarse
  /// completo.
  MatchViewState copyWith({
    List<String>? log,
    ClashResult? lastResult,
    List<MatchEvent>? events,
    MoveBatch? moves,
    bool clearMoves = false,
  }) {
    final newEvents = events ?? this.events;
    final newMoves = clearMoves ? null : (moves ?? this.moves);
    final done = newEvents.isEmpty && newMoves == null;
    return MatchViewState(
      match: match,
      catalog: catalog,
      log: log ?? this.log,
      revision: revision + 1,
      lastResult: lastResult ?? this.lastResult,
      events: newEvents,
      moves: newMoves,
      logVisible: done ? null : logVisible,
    );
  }

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

  /// Dónde estaba cada carta después de la última jugada, para saber qué
  /// cartas se movieron en la siguiente.
  ZoneSnapshot _zones = const {};

  int _lastBatchId = 0;

  /// Cuántos Clashes se han jugado en la partida, para numerar el registro.
  int _clashNumber = 0;

  /// Las Creatures y sus valores en el Clash que se está resolviendo, para
  /// explicarlo en el registro cuando las cartas ya cambiaron de zona.
  _ClashSnapshot? _clashSnapshot;

  @override
  MatchViewState? build() => null;

  /// Empieza una partida nueva con mazos al azar del [catalog] para ambos
  /// jugadores (mientras no exista el Deck Builder).
  ///
  /// [humanDeck] y [systemDeck] permiten elegir los mazos, y [shuffle] en
  /// `false` respeta su orden: sirve para los tests y la demostración.
  /// [random] reemplaza al azar de [matchRandomProvider], para repetir una
  /// partida.
  void startMatch(
    CardCatalog catalog, {
    PlayerDeck? humanDeck,
    PlayerDeck? systemDeck,
    bool shuffle = true,
    Random? random,
  }) {
    final Random matchRandom = random ?? ref.read(matchRandomProvider);
    final match = GameMatch(
      playerOne: humanDeck ?? randomDeck(catalog.cards, matchRandom),
      playerTwo: systemDeck ?? randomDeck(catalog.cards, matchRandom),
      shuffle: shuffle,
      random: matchRandom,
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
    _zones = snapshotZones(match);
    _clashNumber = 0;
    _clashSnapshot = null;
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
            cardId: card.id,
            destination: const Zone(systemPlayer, ZoneKind.creature),
            caption: 'Opponent equipped ${card.card.name}',
          ),
          PlayedEffect(:final card) => MatchEvent(
            card: card.card,
            cardId: card.id,
            destination: const Zone(systemPlayer, ZoneKind.effects),
            caption: 'Opponent played ${card.card.name}',
          ),
        });
      }
    }
    _update([
      for (final event in events) '${event.caption}.',
      if (match.phase == MatchPhase.finished) ..._endMessages(match),
    ], newEvents: events);
  }

  /// Marca como visto el primer evento de la cola.
  void dismissEvent() {
    final current = state;
    if (current == null || current.events.isEmpty) return;
    state = current.copyWith(events: current.events.sublist(1));
  }

  /// Termina la animación de cartas en curso.
  void finishMoves() {
    final current = state;
    if (current == null || current.moves == null) return;
    state = current.copyWith(clearMoves: true);
  }

  MatchEvent _revealEvent(Player player, MatchCard card) {
    final destination = switch (card) {
      MatchCard<Creature>() => 'to the Clash',
      _ => player == humanPlayer ? 'to your hand' : "to the opponent's hand",
    };
    return MatchEvent(
      card: card.card,
      cardId: card.id,
      from: Zone(player, ZoneKind.deck),
      destination: Zone(
        player,
        card is MatchCard<Creature> ? ZoneKind.creature : ZoneKind.hand,
      ),
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
          messages.addAll(_endMessages(match));
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
    _clashSnapshot = _ClashSnapshot.of(match, ++_clashNumber);

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
          cardId: stolen.id,
          from: const Zone(systemPlayer, ZoneKind.deck),
          destination: const Zone(humanPlayer, ZoneKind.trophy),
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
    if (match.phase == MatchPhase.finished) {
      messages.addAll(_endMessages(match));
    }
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
    final snapshot = _clashSnapshot;
    final messages = [
      ...first,
      if (snapshot != null) ...[
        snapshot.header,
        explainClash(result, snapshot.first.stats, snapshot.second.stats),
      ],
      describe(result),
    ];
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
    _update(messages, lastResult: result, clashResult: result);
  }

  void _update(
    List<String> messages, {
    ClashResult? lastResult,
    ClashResult? clashResult,
    List<MatchEvent> newEvents = const [],
  }) {
    final current = state!;
    // Las cartas que cambiaron de zona se animan, salvo las que un aviso ya
    // muestra y lleva a su lugar.
    final after = snapshotZones(current.match);
    final moves = diffZones(
      _zones,
      after,
      ignore: {
        for (final event in newEvents)
          if (event.cardId != null) event.cardId!,
      },
    );
    _zones = after;
    final allEvents = [...current.events, ...newEvents];
    final batch = moves.isEmpty
        ? current.moves
        : MoveBatch(id: ++_lastBatchId, moves: moves, clashResult: clashResult);
    final animating = allEvents.isNotEmpty || batch != null;
    state = MatchViewState(
      match: current.match,
      catalog: current.catalog,
      log: [...current.log, ...messages],
      revision: current.revision + 1,
      lastResult: lastResult ?? current.lastResult,
      events: allEvents,
      moves: batch,
      // El registro espera a que las cartas lleguen antes de contar qué pasó.
      logVisible: animating ? (current.logVisible ?? current.log.length) : null,
    );
  }

  String _who(Player player) => player == humanPlayer ? 'You' : 'Opponent';

  /// Líneas del registro cuando la partida termina: por qué terminó, qué pasa
  /// con las cartas de la mesa y el resultado. La última siempre empieza con
  /// "Match over.".
  List<String> _endMessages(GameMatch match) => [
    endReasonText(match),
    'Creatures still on the table go back to their Discard Stacks without '
        'a Clash.',
    _endMessage(match),
  ];

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

/// Explica en inglés por qué terminó la partida: un jugador se quedó sin
/// cartas para revelar la siguiente Creature.
String endReasonText(GameMatch match) {
  final ranOut = match.ranOutOfCards;
  final who = switch ((
    ranOut.contains(humanPlayer),
    ranOut.contains(systemPlayer),
  )) {
    (true, true) => 'Both of you have',
    (true, false) => 'You have',
    (false, true) => 'Your opponent has',
    (false, false) => 'A player has',
  };
  return 'The match ends: $who no cards left to reveal a Creature.';
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

/// Explica en inglés, para el estudiante, qué regla decidió el Clash entre
/// las Creatures con los valores [first] y [second] (RF-04, CU-01).
String explainClash(ClashResult result, ClashStats first, ClashStats second) {
  String rarity(ClashStats stats) => _capitalize(stats.rarity.name);
  switch (result) {
    case ClashWin(:final winner, :final reason):
      final won = winner == ClashSide.first ? first : second;
      final lost = winner == ClashSide.first ? second : first;
      return switch (reason) {
        WinReason.rarity =>
          '${rarity(won)} beats ${rarity(lost)}: the higher Rarity wins.',
        WinReason.power =>
          'Both are ${rarity(won)} with different Classes, so Power decides: '
              '${won.power} beats ${lost.power}.',
        WinReason.commitment => 'Commitment turns the lost Clash into a win.',
      };
    case ClashTie(:final reason):
      final shared = first.classes
          .where(second.classes.contains)
          .map((c) => c.name)
          .join(', ');
      return switch (reason) {
        TieReason.sameClass =>
          'Both are ${rarity(first)} and share the Class $shared: '
              'it is a Tie, whatever the Power.',
        TieReason.samePower =>
          'Both are ${rarity(first)} with different Classes and the same '
              'Power (${first.power}): it is a Tie.',
      };
  }
}

String _capitalize(String text) =>
    text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);

/// Si [message] del registro es la línea que abre un Clash, para destacarla.
bool isClashHeader(String message) => message.startsWith('Clash ');

/// Una Creature enfrentada en un Clash, con sus valores en ese momento.
class _ClashSide {
  const _ClashSide(this.name, this.stats);

  final String name;
  final ClashStats stats;

  String get label =>
      '$name (${_capitalize(stats.rarity.name)} · Power ${stats.power} · '
      '${stats.classes.map((c) => c.name).join(', ')})';
}

/// Las dos Creatures de un Clash antes de resolverlo.
class _ClashSnapshot {
  const _ClashSnapshot(this.number, this.first, this.second);

  /// Toma las Creatures en la mesa de [match], o `null` si falta alguna.
  static _ClashSnapshot? of(GameMatch match, int number) {
    _ClashSide? sideOf(Player player) {
      final inPlay = match.area(player).creatureInPlay;
      final stats = match.statsOf(player);
      if (inPlay == null || stats == null) return null;
      return _ClashSide(inPlay.creature.card.name, stats);
    }

    final first = sideOf(humanPlayer);
    final second = sideOf(systemPlayer);
    return first == null || second == null
        ? null
        : _ClashSnapshot(number, first, second);
  }

  final int number;
  final _ClashSide first;
  final _ClashSide second;

  /// Línea del registro que dice qué Creatures se enfrentaron.
  String get header =>
      'Clash $number · You: ${first.label} vs Opponent: ${second.label}';
}

/// Partida en curso de la pantalla de juego.
final matchControllerProvider =
    NotifierProvider<MatchController, MatchViewState?>(MatchController.new);
