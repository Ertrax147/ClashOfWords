import 'package:game_engine/game_engine.dart';

/// Lugar de la mesa donde puede estar una carta.
enum ZoneKind {
  /// Deck.
  deck,

  /// Hand (Items y Effects revelados).
  hand,

  /// Creature en la mesa, junto con sus Items.
  creature,

  /// Creatures apartadas por un Tie. Se dibujan en el mismo lugar que la
  /// Creature en la mesa.
  tied,

  /// Effects en juego.
  effects,

  /// Discard Stack.
  discard,

  /// Trophy Stack.
  trophy,
}

/// Una zona de la mesa de un jugador, por ejemplo el Trophy Stack del rival.
///
/// El jugador es el dueño de la zona, no de las cartas que hay en ella: el
/// Trophy Stack de un jugador guarda cartas del rival.
final class Zone {
  /// Crea la zona [kind] del jugador [player].
  const Zone(this.player, this.kind);

  /// Dueño de la zona.
  final Player player;

  /// Qué zona es.
  final ZoneKind kind;

  @override
  bool operator ==(Object other) =>
      other is Zone && other.player == player && other.kind == kind;

  @override
  int get hashCode => Object.hash(player, kind);

  @override
  String toString() => 'Zone(${player.name}, ${kind.name})';
}

/// Una carta que cambió de zona después de una jugada, para animarla.
final class MatchMove {
  /// Crea el movimiento de [card] desde [from] hasta [to].
  const MatchMove({required this.card, required this.from, required this.to});

  /// Carta que se movió.
  final MatchCard card;

  /// Zona de la que salió.
  final Zone from;

  /// Zona a la que llegó.
  final Zone to;

  @override
  String toString() => 'MatchMove(${card.card.name}: $from -> $to)';
}

/// Movimientos que ocurrieron juntos, por ejemplo al resolver un Clash.
final class MoveBatch {
  /// Crea el lote [id] con sus [moves].
  ///
  /// [clashResult] indica que el lote es la resolución de un Clash: las
  /// cartas se muestran un momento, con el ganador resaltado, antes de
  /// irse a sus pilas.
  const MoveBatch({required this.id, required this.moves, this.clashResult});

  /// Número del lote, distinto para cada jugada.
  final int id;

  /// Cartas que se movieron.
  final List<MatchMove> moves;

  /// Resultado del Clash que originó el lote, o `null` si no fue un Clash.
  final ClashResult? clashResult;
}

/// Dónde estaba cada carta de la partida, por el id de su [MatchCard].
typedef ZoneSnapshot = Map<int, ({MatchCard card, Zone zone})>;

/// Registra en qué zona está cada carta de [match] (sin los Initial Effects,
/// que no se mueven).
ZoneSnapshot snapshotZones(GameMatch match) {
  final snapshot = <int, ({MatchCard card, Zone zone})>{};
  void put(Iterable<MatchCard> cards, Player player, ZoneKind kind) {
    for (final card in cards) {
      snapshot[card.id] = (card: card, zone: Zone(player, kind));
    }
  }

  for (final player in Player.values) {
    final area = match.area(player);
    final inPlay = area.creatureInPlay;
    put(area.deck, player, ZoneKind.deck);
    put(area.hand, player, ZoneKind.hand);
    put(area.discardStack, player, ZoneKind.discard);
    put(area.trophyStack, player, ZoneKind.trophy);
    put(area.tiedCards, player, ZoneKind.tied);
    put(
      [for (final effect in area.effectsInPlay) effect.effect],
      player,
      ZoneKind.effects,
    );
    if (inPlay != null) {
      put([inPlay.creature, ...inPlay.items], player, ZoneKind.creature);
    }
  }
  return snapshot;
}

/// Cartas que cambiaron de zona entre [before] y [after].
///
/// No incluye las de [ignore] (los ids de cartas que la pantalla ya muestra
/// de otra forma, por ejemplo las reveladas) ni los cambios dentro del mismo
/// lugar, como barajar el Deck. Salen primero las que dejan la mesa.
List<MatchMove> diffZones(
  ZoneSnapshot before,
  ZoneSnapshot after, {
  Set<int> ignore = const {},
}) {
  final moves = <MatchMove>[];
  for (final entry in after.entries) {
    final old = before[entry.key];
    if (old == null || ignore.contains(entry.key)) continue;
    if (old.zone == entry.value.zone) continue;
    moves.add(
      MatchMove(card: entry.value.card, from: old.zone, to: entry.value.zone),
    );
  }
  moves.sort((a, b) {
    final fromTable = _leavesTable(b).compareTo(_leavesTable(a));
    return fromTable != 0 ? fromTable : a.card.id.compareTo(b.card.id);
  });
  return moves;
}

int _leavesTable(MatchMove move) =>
    move.from.kind == ZoneKind.creature || move.from.kind == ZoneKind.tied
    ? 1
    : 0;
