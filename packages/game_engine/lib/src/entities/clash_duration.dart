/// Cantidad de Clashes que dura algo en juego.
///
/// Una Creature sin Duration dura un Clash ([ClashDuration.one]). Algunas
/// Creatures traen una Duration mayor, y los Items, Effects e Initial
/// Effects pueden otorgarla, incluso infinita ([ClashDuration.infinite]),
/// como el Item Gift of Eternity.
///
/// Se llama `ClashDuration` y no `Duration` para no confundirse con la clase
/// `Duration` de Dart, que mide tiempo.
final class ClashDuration {
  /// Crea una Duration de [clashes] Clashes.
  ///
  /// Lanza un [ArgumentError] si [clashes] es menor que 1.
  factory ClashDuration(int clashes) {
    if (clashes < 1) {
      throw ArgumentError.value(
        clashes,
        'clashes',
        'A duration must last at least one clash',
      );
    }
    return ClashDuration._(clashes);
  }

  const ClashDuration._(this.clashes);

  /// Duration de un solo Clash: la de cualquier Creature sin Duration.
  static const ClashDuration one = ClashDuration._(1);

  /// Duration infinita: dura hasta que la Creature pierda o termine la
  /// partida.
  static const ClashDuration infinite = ClashDuration._(null);

  /// Cantidad de Clashes, o `null` si la Duration es infinita.
  final int? clashes;

  /// Indica si la Duration es infinita.
  bool get isInfinite => clashes == null;

  /// Indica si esta Duration dura más que [other].
  bool isLongerThan(ClashDuration other) {
    if (isInfinite) return !other.isInfinite;
    if (other.isInfinite) return false;
    return clashes! > other.clashes!;
  }

  /// Devuelve la mayor entre esta Duration y [other].
  ///
  /// Se usa cuando una Creature recibe una Duration de un Item, Effect o
  /// Initial Effect: conserva la mayor, así que una Duration otorgada nunca
  /// la empeora.
  ClashDuration max(ClashDuration other) => isLongerThan(other) ? this : other;

  @override
  bool operator ==(Object other) =>
      other is ClashDuration && other.clashes == clashes;

  @override
  int get hashCode => clashes.hashCode;

  @override
  String toString() =>
      isInfinite ? 'ClashDuration(infinite)' : 'ClashDuration($clashes)';
}
