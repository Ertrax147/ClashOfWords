import 'dart:math';

import '../entities/ability.dart';
import '../entities/card_class.dart';
import '../entities/clash_duration.dart';
import '../entities/game_card.dart';
import '../entities/initial_effect_kind.dart';
import '../rules/clash_resolver.dart';
import '../rules/clash_resolver.dart' as rules show resolveClash;
import '../rules/clash_stats.dart';
import 'effect_in_play.dart';
import 'initial_effect_choice.dart';
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

  /// Ninguna Class de la Creature está entre las Class del Item (RF-10).
  classMismatch,

  /// El Item no puede usarlo una Creature de esa Rarity, por ejemplo Gift of
  /// Eternity con una Creature Legendary.
  forbiddenRarity,

  /// Una habilidad del rival lo prohíbe, por ejemplo "Your enemy cannot play
  /// Effects".
  forbiddenByEnemy,

  /// El jugador ya usó la habilidad activa de su Initial Effect: solo se
  /// puede una vez por partida (RF-10).
  alreadyUsed,

  /// El Initial Effect del jugador no tiene una habilidad activa que pueda
  /// usar.
  noActiveAbility,

  /// La habilidad activa no tiene sobre qué actuar, por ejemplo Recycle sin
  /// Creatures en el Discard Stack.
  noValidTarget,

  /// La elección del jugador no corresponde a la habilidad, o no está entre
  /// las opciones ([GameMatch.activeOptions]).
  invalidChoice,
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
/// Si un Clash termina en Tie, las dos Creatures se apartan y se juega un
/// nuevo Clash que define también el empatado (CU-04).
///
/// La partida termina cuando un jugador necesita revelar una Creature y su
/// Deck está vacío. Las Creatures que siguen en la mesa o apartadas por un
/// Tie van al Discard Stack de su dueño y gana quien tenga más trofeos
/// ([result]).
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
    }, random ?? Random());
  }

  GameMatch._(this._areas, this._random);

  final Map<Player, PlayerArea> _areas;

  /// Azar con que se barajan los Decks cuando una habilidad lo pide.
  final Random _random;
  MatchPhase _phase = MatchPhase.reveal;

  /// Contador que marca el orden en que entran en juego Creatures y
  /// Effects, para aplicar sus habilidades en ese orden.
  int _nextOrder = 0;

  // Registro de la partida que necesitan los Initial Effects pasivos.

  /// Class que ya entraron en juego, por jugador (Diversity).
  final Map<Player, Set<CardClass>> _classesSeen = {
    for (final player in Player.values) player: {},
  };

  /// Creatures que fueron las primeras de su Class (Diversity).
  final Set<MatchCard> _firstOfTheirClass = {};

  /// Creatures derrotadas que Tolerance ya salvó, por jugador.
  final Map<Player, int> _toleranceUsed = {
    for (final player in Player.values) player: 0,
  };

  /// Clashes perdidos desde la última victoria, por jugador (Justice).
  final Map<Player, int> _lossesSinceWin = {
    for (final player in Player.values) player: 0,
  };

  /// Jugadores que ya usaron la habilidad activa de su Initial Effect.
  final Set<Player> _activeUsed = {};

  /// Ganador del último Clash, o `null` si fue Tie o aún no hay ninguno
  /// (Excellence).
  Player? _lastWinner;

  /// Si el último Clash terminó en Tie (Friendship).
  bool _lastClashWasTie = false;

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

  /// Indica si [player] cuenta con la habilidad pasiva del Initial Effect
  /// [kind]: porque es el suyo, o porque tiene Empathy y es el del rival.
  ///
  /// Si ambos jugadores tienen Empathy, ninguno copia nada.
  bool hasPassive(Player player, InitialEffectKind kind) {
    final own = area(player).initialEffect.card.kind;
    if (own == kind) return true;
    final rival = area(player.opponent).initialEffect.card.kind;
    return own == InitialEffectKind.empathy && rival == kind;
  }

  /// Initial Effect cuya habilidad activa puede usar [player], o `null` si
  /// no tiene ninguna.
  ///
  /// Es el suyo si tiene habilidad activa. Con Empathy es el del rival, si
  /// también la tiene; si ambos tienen Empathy, no copia nada.
  InitialEffectKind? activeKindOf(Player player) {
    final own = area(player).initialEffect.card.kind;
    if (own.active) return own;
    if (own != InitialEffectKind.empathy) return null;
    final rival = area(player.opponent).initialEffect.card.kind;
    return rival.active ? rival : null;
  }

  /// Indica si [player] ya usó la habilidad activa de su Initial Effect.
  bool hasUsedActive(Player player) => _activeUsed.contains(player);

  /// Cartas entre las que [player] puede elegir al usar su habilidad
  /// activa, para las habilidades que piden elegir una carta.
  ///
  /// - Recycle: las Creatures de su Discard Stack.
  /// - Responsibility: los Items de su Discard Stack.
  ///
  /// Está vacía si la habilidad no pide elegir una carta o no hay opciones.
  /// La interfaz la usa para armar el selector.
  List<MatchCard> activeOptions(Player player) {
    final discard = area(player).discardStack;
    return switch (activeKindOf(player)) {
      InitialEffectKind.recycle =>
        discard.whereType<MatchCard<Creature>>().toList(),
      InitialEffectKind.responsibility =>
        discard.whereType<MatchCard<Item>>().toList(),
      _ => const [],
    };
  }

  /// Indica por qué [player] no puede usar la habilidad activa de su
  /// Initial Effect, o `null` si sí puede.
  ///
  /// Sin [choice] solo comprueba que pueda usarla ahora; sirve para que la
  /// interfaz desactive el botón. Con [choice] comprueba además que la
  /// elección sea válida.
  InvalidPlayReason? checkUseInitialEffect(
    Player player, [
    InitialEffectChoice? choice,
  ]) {
    if (_phase != MatchPhase.play) return InvalidPlayReason.wrongPhase;
    final kind = activeKindOf(player);
    if (kind == null) return InvalidPlayReason.noActiveAbility;
    if (hasUsedActive(player)) return InvalidPlayReason.alreadyUsed;
    switch (kind) {
      case InitialEffectKind.recycle || InitialEffectKind.responsibility:
        final options = activeOptions(player);
        if (options.isEmpty) return InvalidPlayReason.noValidTarget;
        if (choice != null &&
            !(choice is CardChoice && options.contains(choice.card))) {
          return InvalidPlayReason.invalidChoice;
        }
      case InitialEffectKind.leadership:
        if (area(player).creatureInPlay == null) {
          return InvalidPlayReason.noValidTarget;
        }
      case InitialEffectKind.kindness:
        if (area(player.opponent).deck.isEmpty) {
          return InvalidPlayReason.noValidTarget;
        }
      default:
        break;
    }
    return null;
  }

  /// [player] usa la habilidad activa de su Initial Effect (RF-10, CU-09).
  ///
  /// Solo se puede una vez por partida, durante la fase de jugar.
  /// - Recycle: [choice] es la Creature de su Discard Stack que vuelve al
  ///   Deck.
  /// - Responsibility: [choice] es el Item de su Discard Stack que vuelve al
  ///   Deck.
  /// - Leadership: su Creature en la mesa queda con Duration de 3 Clashes,
  ///   contando el actual. Conserva la mayor si ya tenía más.
  /// - Kindness: la carta superior del Deck rival va directo a su Trophy
  ///   Stack. Si era la última, el rival no podrá revelar y la partida
  ///   terminará en el próximo Clash.
  ///
  /// Lanza un [InvalidPlayException] si la jugada no está permitida (ver
  /// [checkUseInitialEffect]).
  void useInitialEffect(
    Player player, [
    InitialEffectChoice choice = const NoChoice(),
  ]) {
    final reason = checkUseInitialEffect(player, choice);
    if (reason != null) throw InvalidPlayException(reason);
    switch (activeKindOf(player)!) {
      case InitialEffectKind.recycle || InitialEffectKind.responsibility:
        // La validación garantiza que es una CardChoice del Discard Stack.
        final card = (choice as CardChoice).card;
        final area = this.area(player);
        area.removeFromDiscard(card);
        area.shuffleIntoDeck(card, _random);
      case InitialEffectKind.leadership:
        area(player).creatureInPlay!.grantDuration(ClashDuration(3));
      case InitialEffectKind.kindness:
        final stolen = area(player.opponent).drawTop()!;
        area(player).addTrophies([stolen]);
      case final kind:
        throw UnimplementedError('Active ability of ${kind.name}');
    }
    _activeUsed.add(player);
  }

  /// Indica si hay un Tie sin resolver: el próximo Clash define también
  /// los Clashes empatados (CU-04).
  bool get hasPendingTie =>
      _areas.values.any((area) => area.tiedCards.isNotEmpty);

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
  /// Items y Effects revelados van a la Hand de su dueño. Si un Effect del
  /// rival saca de la mesa a la Creature revelada (por ejemplo, "Move the
  /// enemy Artist creature to the Discard stack"), va al Discard Stack de su
  /// dueño y se revela otra. Si un jugador necesita revelar y se queda sin
  /// cartas en el Deck, la partida termina.
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
      if (!_fillCreature(player, revealed[player]!)) someoneRanOut = true;
    }

    if (someoneRanOut) {
      _finish();
    } else {
      _phase = MatchPhase.play;
    }
    return revealed;
  }

  /// Valores efectivos con que la Creature de [player] pelearía el Clash
  /// ahora, o `null` si no tiene Creature en la mesa.
  ///
  /// Incluye sus Items, las habilidades en juego de ambos jugadores (Effects
  /// y habilidades de Creatures) y los bonus de los Initial Effects pasivos.
  /// La interfaz puede usarlo para mostrar el Power y la Rarity actuales.
  ClashStats? statsOf(Player player) {
    final inPlay = area(player).creatureInPlay;
    if (inPlay == null) return null;
    final bonus = _passivePowerBonus(player, inPlay.creature);
    return inPlay.stats.applyModifiers([
      ..._modifiersAffecting(player),
      if (bonus != 0)
        StatModifier(target: AbilityTarget.own, powerDelta: bonus),
    ]);
  }

  /// Power que suman los Initial Effects pasivos de [player] a su
  /// [creature] en el próximo Clash.
  ///
  /// - Diversity: +2 si es la primera Creature de su Class.
  /// - Justice: +1 por cada Clash perdido desde la última victoria.
  /// - Friendship: +3 si el último Clash fue Tie.
  /// - Excellence: +1 si ganó el último Clash.
  int _passivePowerBonus(Player player, MatchCard<Creature> creature) {
    var bonus = 0;
    if (hasPassive(player, InitialEffectKind.diversity) &&
        _firstOfTheirClass.contains(creature)) {
      bonus += 2;
    }
    if (hasPassive(player, InitialEffectKind.justice)) {
      bonus += _lossesSinceWin[player]!;
    }
    if (hasPassive(player, InitialEffectKind.friendship) && _lastClashWasTie) {
      bonus += 3;
    }
    if (hasPassive(player, InitialEffectKind.excellence) &&
        _lastWinner == player) {
      bonus += 1;
    }
    return bonus;
  }

  /// Indica por qué [player] no puede equipar [item], o `null` si sí puede.
  ///
  /// La Class y la Rarity se revisan con los valores efectivos de la
  /// Creature: si un Effect le agregó una Class, puede equipar Items de esa
  /// Class. Sirve para que la interfaz desactive las jugadas no permitidas.
  InvalidPlayReason? checkEquipItem(Player player, MatchCard<Item> item) {
    if (_phase != MatchPhase.play) return InvalidPlayReason.wrongPhase;
    final area = this.area(player);
    if (!area.hand.contains(item)) return InvalidPlayReason.notInHand;
    final inPlay = area.creatureInPlay;
    if (inPlay == null) return InvalidPlayReason.noCreatureInPlay;
    if (_enemyForbids(player, items: true)) {
      return InvalidPlayReason.forbiddenByEnemy;
    }
    if (inPlay.items.isNotEmpty &&
        !hasPassive(player, InitialEffectKind.responsibility)) {
      return InvalidPlayReason.creatureAlreadyHasItem;
    }
    final stats = statsOf(player)!;
    if (!item.card.isUniversal &&
        !item.card.classes.any(stats.classes.contains)) {
      return InvalidPlayReason.classMismatch;
    }
    if (item.card.forbiddenRarities.contains(stats.rarity)) {
      return InvalidPlayReason.forbiddenRarity;
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

  /// Indica por qué [player] no puede jugar [effect], o `null` si sí puede.
  InvalidPlayReason? checkPlayEffect(Player player, MatchCard<Effect> effect) {
    if (_phase != MatchPhase.play) return InvalidPlayReason.wrongPhase;
    if (!area(player).hand.contains(effect)) return InvalidPlayReason.notInHand;
    if (_enemyForbids(player, effects: true)) {
      return InvalidPlayReason.forbiddenByEnemy;
    }
    return null;
  }

  /// [player] juega [effect] de su Hand (RF-10).
  ///
  /// El Effect queda en juego desde este Clash y durante los Clashes que
  /// indica su carta. Se pueden jugar varios en un mismo Clash.
  ///
  /// Si el Effect saca de la mesa a la Creature rival, ella y su Item van al
  /// Discard Stack de su dueño y el rival revela otra para este Clash.
  /// Devuelve las cartas que el rival reveló por eso (vacío si no reveló
  /// ninguna). Si el rival se queda sin cartas, la partida termina.
  ///
  /// Lanza un [InvalidPlayException] si la jugada no está permitida (ver
  /// [checkPlayEffect]).
  Map<Player, List<MatchCard>> playEffect(
    Player player,
    MatchCard<Effect> effect,
  ) {
    final reason = checkPlayEffect(player, effect);
    if (reason != null) throw InvalidPlayException(reason);
    final area = this.area(player);
    area.removeFromHand(effect);
    area.addEffectInPlay(EffectInPlay(effect, order: _nextOrder++));

    final revealed = {
      for (final player in Player.values) player: <MatchCard>[],
    };
    final rival = player.opponent;
    if (!_fillCreature(rival, revealed[rival]!)) _finish();
    return revealed;
  }

  /// Resuelve el Clash entre las dos Creatures en la mesa (RF-04, CU-04).
  ///
  /// Si hay ganador:
  /// - La perdedora y su Item van al Trophy Stack del ganador, aunque le
  ///   quedara Duration.
  /// - La ganadora descuenta un Clash. Si agotó su Duration, va con su Item
  ///   al Discard Stack de su dueño; si no, sigue en la mesa.
  /// - Si había Creatures apartadas por un Tie, el ganador también gana esos
  ///   Clashes: las apartadas del perdedor van a su Trophy Stack y las suyas,
  ///   a su Discard Stack.
  ///
  /// Si hay Tie, ambas Creatures se apartan con sus Items, aunque les quede
  /// Duration, y la partida vuelve a la fase de revelar para jugar un nuevo
  /// Clash. Si ese Clash también empata, se siguen acumulando.
  ///
  /// En ambos casos, los Effects en juego descuentan un Clash y los que se
  /// agotan van al Discard Stack de su dueño.
  ///
  /// Los Initial Effects pasivos pueden cambiar el resultado: con Respect,
  /// un Tie por Class lo gana la Creature con más Power; con Tolerance, las
  /// primeras 3 Creatures derrotadas van al Discard Stack de su dueño en vez
  /// de ser trofeos.
  ///
  /// Lanza un [StateError] si la partida no está en la fase
  /// [MatchPhase.play].
  ClashResult resolveClash() {
    _requirePhase(MatchPhase.play);
    final first = statsOf(Player.one)!;
    final second = statsOf(Player.two)!;
    final result = _applyRespect(
      rules.resolveClash(first, second),
      first,
      second,
    );

    switch (result) {
      case ClashWin(:final winner):
        final winnerPlayer = winner == ClashSide.first
            ? Player.one
            : Player.two;
        final loserPlayer = winnerPlayer.opponent;
        final winnerArea = area(winnerPlayer);
        final loserArea = area(loserPlayer);

        _sendDefeated(loserPlayer, [
          ...loserArea.removeFromPlay(),
          ...loserArea.takeTied(),
        ]);
        winnerArea.discard(winnerArea.takeTied());
        final survivor = winnerArea.creatureInPlay!..spendClash();
        if (survivor.isExhausted) {
          winnerArea.discard(winnerArea.removeFromPlay());
        }
        _lossesSinceWin[winnerPlayer] = 0;
        _lossesSinceWin[loserPlayer] = _lossesSinceWin[loserPlayer]! + 1;
        _lastWinner = winnerPlayer;
        _lastClashWasTie = false;
      case ClashTie():
        for (final area in _areas.values) {
          area.setAsideTied();
        }
        _lastWinner = null;
        _lastClashWasTie = true;
    }
    for (final area in _areas.values) {
      area.discard(area.spendEffectsClash());
    }
    _phase = MatchPhase.reveal;
    return result;
  }

  /// Revela cartas de [player] hasta que tenga una Creature en la mesa que
  /// no saquen los Effects del rival. Agrega a [revealed] lo que reveló.
  ///
  /// Devuelve `false` si se quedó sin cartas antes de lograrlo.
  bool _fillCreature(Player player, List<MatchCard> revealed) {
    final area = this.area(player);
    while (true) {
      if (area.creatureInPlay != null) {
        if (!_isDiscardedByEnemy(player)) return true;
        area.discard(area.removeFromPlay());
        continue;
      }
      final card = area.drawTop();
      if (card == null) return false;
      revealed.add(card);
      if (card is MatchCard<Creature>) {
        area.putInPlay(card, order: _nextOrder++);
        if (_classesSeen[player]!.add(card.card.cardClass)) {
          _firstOfTheirClass.add(card);
        }
      } else {
        area.addToHand(card);
      }
    }
  }

  /// Aplica Respect: si el Clash es Tie por Class y la Creature con más
  /// Power es de un jugador con Respect, ese jugador lo gana por Power.
  ClashResult _applyRespect(
    ClashResult result,
    ClashStats first,
    ClashStats second,
  ) {
    if (result case ClashTie(reason: TieReason.sameClass)) {
      if (first.power == second.power) return result;
      final stronger = first.power > second.power ? Player.one : Player.two;
      if (hasPassive(stronger, InitialEffectKind.respect)) {
        return ClashWin(
          stronger == Player.one ? ClashSide.first : ClashSide.second,
          WinReason.power,
        );
      }
    }
    return result;
  }

  /// Envía las cartas derrotadas de [loser] (Creatures seguidas de sus
  /// Items) al Trophy Stack del rival.
  ///
  /// Con Tolerance, las primeras 3 Creatures derrotadas del jugador van a
  /// su propio Discard Stack, con sus Items.
  void _sendDefeated(Player loser, List<MatchCard> cards) {
    final loserArea = area(loser);
    final winnerArea = area(loser.opponent);
    var saved = false;
    for (final card in cards) {
      if (card is MatchCard<Creature>) {
        saved =
            hasPassive(loser, InitialEffectKind.tolerance) &&
            _toleranceUsed[loser]! < 3;
        if (saved) _toleranceUsed[loser] = _toleranceUsed[loser]! + 1;
      }
      if (saved) {
        loserArea.discard([card]);
      } else {
        winnerArea.addTrophies([card]);
      }
    }
  }

  /// Habilidades en juego de [owner], con el momento en que entraron: las de
  /// sus Effects y las de su Creature en la mesa.
  List<(int, Ability)> _abilitiesOf(Player owner) {
    final area = this.area(owner);
    final creature = area.creatureInPlay;
    return [
      for (final effect in area.effectsInPlay)
        for (final ability in effect.effect.card.abilities)
          (effect.order, ability),
      if (creature != null)
        for (final ability in creature.creature.card.abilities)
          (creature.order, ability),
    ];
  }

  /// Modificadores que afectan a la Creature de [player], en el orden en que
  /// entraron en juego: los suyos que apuntan a sus Creatures y los del
  /// rival que apuntan a las Creatures rivales.
  List<StatModifier> _modifiersAffecting(Player player) {
    final entries = [
      for (final (order, ability) in _abilitiesOf(player))
        if (ability is StatModifier && ability.target == AbilityTarget.own)
          (order, ability),
      for (final (order, ability) in _abilitiesOf(player.opponent))
        if (ability is StatModifier && ability.target == AbilityTarget.enemy)
          (order, ability),
    ]..sort((a, b) => a.$1.compareTo(b.$1));
    return [for (final (_, modifier) in entries) modifier];
  }

  /// Indica si una habilidad del rival saca de la mesa a la Creature de
  /// [player].
  bool _isDiscardedByEnemy(Player player) {
    final stats = statsOf(player);
    if (stats == null) return false;
    return _abilitiesOf(player.opponent).any(
      (entry) =>
          entry.$2 is DiscardEnemyCreatures &&
          stats.matches((entry.$2 as DiscardEnemyCreatures).filter),
    );
  }

  /// Indica si una habilidad del rival le prohíbe a [player] equipar Items
  /// ([items]) o jugar Effects ([effects]).
  bool _enemyForbids(
    Player player, {
    bool items = false,
    bool effects = false,
  }) => _abilitiesOf(player.opponent).any(
    (entry) => switch (entry.$2) {
      ForbidEnemyPlays(
        items: final forbidsItems,
        effects: final forbidsEffects,
      ) =>
        (items && forbidsItems) || (effects && forbidsEffects),
      _ => false,
    },
  );

  /// Termina la partida: las Creatures que siguen en la mesa o apartadas
  /// por un Tie vuelven al Discard Stack de su dueño, porque nadie las
  /// venció (CU-04, flujo 2a). Los Effects en juego también van al Discard
  /// Stack.
  void _finish() {
    for (final area in _areas.values) {
      area.discard(area.removeFromPlay());
      area.discard(area.takeTied());
      area.discard(area.takeEffectsInPlay());
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
