/// Rareza de una carta.
///
/// La Rarity es lo primero que se compara en un Clash: gana la Creature con
/// mayor Rarity (RF-04). Los valores están declarados de menor a mayor, así
/// que el orden de declaración es también el orden competitivo:
/// `common < uncommon < rare < epic < legendary`.
///
/// Los Initial Effects tienen una Rarity propia, *Value*, que nunca compite
/// en un Clash; por eso no forma parte de este enum.
enum Rarity implements Comparable<Rarity> {
  common,
  uncommon,
  rare,
  epic,
  legendary;

  /// Compara dos Rarity según su orden competitivo.
  ///
  /// Devuelve un número negativo si esta Rarity es menor que [other], cero si
  /// son iguales y un número positivo si es mayor.
  @override
  int compareTo(Rarity other) => index - other.index;

  /// Indica si esta Rarity le gana a [other] en un Clash.
  bool isHigherThan(Rarity other) => compareTo(other) > 0;

  /// Devuelve la mayor entre esta Rarity y [other].
  ///
  /// Se usa cuando un Item, Effect o Initial Effect le otorga una Rarity a
  /// una Creature: la Creature conserva la mayor, así que una Rarity
  /// otorgada nunca la empeora.
  Rarity max(Rarity other) => isHigherThan(other) ? this : other;
}
