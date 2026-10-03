import '../entities/card_class.dart';
import '../entities/game_card.dart';
import '../entities/rarity.dart';

/// Valores con los que una Creature se enfrenta en un Clash.
///
/// Una Creature no pelea con lo que tiene impreso, sino con sus valores
/// efectivos: los de la carta más los modificadores de su Item y, más
/// adelante, los de Effects e Initial Effects. La resolución del Clash solo
/// mira estos valores, sin importar de dónde salieron.
final class ClashStats {
  /// Crea los valores de combate a partir de números ya calculados.
  const ClashStats({
    required this.rarity,
    required this.cardClass,
    required this.power,
  });

  /// Calcula los valores de combate de [creature] con su [item] equipado.
  ///
  /// - Power: el de la Creature más el bonus del Item.
  /// - Rarity: la mayor entre la de la Creature y la que otorga el Item.
  /// - Class: la de la Creature.
  ///
  /// Lanza un [ArgumentError] si el Item no puede equiparse a la Creature
  /// por su Class (RF-10).
  factory ClashStats.of(Creature creature, {Item? item}) {
    if (item == null) {
      return ClashStats(
        rarity: creature.rarity,
        cardClass: creature.cardClass,
        power: creature.power,
      );
    }
    if (!item.canBeEquippedTo(creature)) {
      throw ArgumentError.value(
        item.name,
        'item',
        'Cannot be equipped to ${creature.name}: its class does not match',
      );
    }
    final grantedRarity = item.grantedRarity;
    return ClashStats(
      rarity: grantedRarity == null
          ? creature.rarity
          : creature.rarity.max(grantedRarity),
      cardClass: creature.cardClass,
      power: creature.power + item.powerBonus,
    );
  }

  /// Rarity efectiva.
  final Rarity rarity;

  /// Class de la Creature.
  final CardClass cardClass;

  /// Power efectivo, con todos los modificadores aplicados.
  final int power;
}
