import 'clash_stats.dart';

/// Lado de un Clash: la primera o la segunda Creature enfrentada.
enum ClashSide {
  first,
  second;

  /// El lado contrario.
  ClashSide get opponent => this == first ? second : first;
}

/// Motivo por el que una Creature gana un Clash.
enum WinReason {
  /// Tenía mayor Rarity.
  rarity,

  /// Tenían igual Rarity y distinta Class, y tenía mayor Power.
  power,
}

/// Motivo por el que un Clash termina en Tie.
enum TieReason {
  /// Tenían igual Rarity y compartían una Class.
  sameClass,

  /// Tenían igual Rarity, distinta Class e igual Power.
  samePower,
}

/// Resultado de un Clash: una victoria ([ClashWin]) o un empate
/// ([ClashTie]).
///
/// Además de quién gana, guarda el motivo, para que la interfaz pueda
/// explicarle al estudiante por qué ganó o perdió.
sealed class ClashResult {
  const ClashResult();
}

/// Un Clash con ganador.
final class ClashWin extends ClashResult {
  /// Crea una victoria de [winner] por el motivo [reason].
  const ClashWin(this.winner, this.reason);

  /// Lado que ganó el Clash.
  final ClashSide winner;

  /// Por qué ganó.
  final WinReason reason;

  /// Lado que perdió el Clash.
  ClashSide get loser => winner.opponent;

  @override
  bool operator ==(Object other) =>
      other is ClashWin && other.winner == winner && other.reason == reason;

  @override
  int get hashCode => Object.hash(winner, reason);

  @override
  String toString() => 'ClashWin(${winner.name} by ${reason.name})';
}

/// Un Clash que termina en Tie.
///
/// El Tie se resuelve con un nuevo Clash cuyo resultado define el anterior
/// (RF-04); eso lo maneja la partida, no esta función.
final class ClashTie extends ClashResult {
  /// Crea un empate por el motivo [reason].
  const ClashTie(this.reason);

  /// Por qué empataron.
  final TieReason reason;

  @override
  bool operator ==(Object other) => other is ClashTie && other.reason == reason;

  @override
  int get hashCode => reason.hashCode;

  @override
  String toString() => 'ClashTie(${reason.name})';
}

/// Resuelve un Clash entre [first] y [second] según RF-04 y CU-01.
///
/// Orden de resolución:
/// 1. Si tienen distinta Rarity, gana la mayor.
/// 2. Si tienen igual Rarity y la misma Class (por ejemplo, Wild contra
///    Wild), hay Tie, sin importar el Power. Si un Effect les agregó Class,
///    basta con que compartan una.
/// 3. Si tienen igual Rarity y distinta Class, gana el mayor Power; con
///    igual Power, hay Tie.
///
/// Recibe los valores efectivos ([ClashStats]), así que los modificadores
/// de Items, Effects e Initial Effects ya deben estar aplicados.
ClashResult resolveClash(ClashStats first, ClashStats second) {
  if (first.rarity != second.rarity) {
    final winner = first.rarity.isHigherThan(second.rarity)
        ? ClashSide.first
        : ClashSide.second;
    return ClashWin(winner, WinReason.rarity);
  }

  if (first.sharesClassWith(second)) {
    return const ClashTie(TieReason.sameClass);
  }

  if (first.power == second.power) {
    return const ClashTie(TieReason.samePower);
  }

  final winner = first.power > second.power
      ? ClashSide.first
      : ClashSide.second;
  return ClashWin(winner, WinReason.power);
}
