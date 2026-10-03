import '../entities/ability.dart';
import '../entities/card_class.dart';
import '../entities/game_card.dart';
import '../entities/rarity.dart';

/// Valores con los que una Creature se enfrenta en un Clash.
///
/// Una Creature no pelea con lo que tiene impreso, sino con sus valores
/// efectivos: los de la carta más los modificadores de su Item, de los
/// Effects y de las habilidades en juego. La resolución del Clash solo mira
/// estos valores, sin importar de dónde salieron.
final class ClashStats {
  /// Crea los valores de combate a partir de valores ya calculados.
  ClashStats({
    required this.rarity,
    required Set<CardClass> classes,
    required this.power,
  }) : classes = Set.unmodifiable(classes);

  /// Calcula los valores de combate de [creature] con su [item] equipado.
  ///
  /// - Power: el de la Creature más el bonus del Item.
  /// - Rarity: la mayor entre la de la Creature y la que otorga el Item.
  /// - Class: la de la Creature.
  ///
  /// Lanza un [ArgumentError] si el Item no puede equiparse a la Creature
  /// por su Class (RF-10).
  factory ClashStats.of(Creature creature, {Item? item}) {
    if (item != null && !item.canBeEquippedTo(creature)) {
      throw ArgumentError.value(
        item.name,
        'item',
        'Cannot be equipped to ${creature.name}: its class does not match',
      );
    }
    return ClashStats.equipped(creature, [?item]);
  }

  /// Calcula los valores de combate de [creature] con sus [items], sin
  /// validar la Class.
  ///
  /// Cada Item suma su Power y la Creature conserva la mayor Rarity. Lo usa
  /// la partida, que valida al equipar con las Class efectivas: una Creature
  /// a la que un Effect le agregó una Class puede equipar Items de esa Class.
  factory ClashStats.equipped(Creature creature, List<Item> items) {
    var rarity = creature.rarity;
    var power = creature.power;
    for (final item in items) {
      final granted = item.grantedRarity;
      if (granted != null) rarity = rarity.max(granted);
      power += item.powerBonus;
    }
    return ClashStats(
      rarity: rarity,
      classes: {creature.cardClass},
      power: power,
    );
  }

  /// Rarity efectiva.
  final Rarity rarity;

  /// Class efectivas: la de la Creature más las que le agreguen los Effects.
  final Set<CardClass> classes;

  /// Power efectivo, con todos los modificadores aplicados. Puede quedar
  /// negativo si el rival le resta Power.
  final int power;

  /// Indica si estos valores comparten al menos una Class con [other].
  ///
  /// En un Clash con igual Rarity, compartir una Class produce un Tie
  /// (RF-04).
  bool sharesClassWith(ClashStats other) => classes.any(other.classes.contains);

  /// Indica si estos valores cumplen el [filter] de una habilidad.
  bool matches(CreatureFilter filter) => filter.matches(classes, rarity);

  /// Aplica [modifiers] en el orden en que se jugaron y devuelve los nuevos
  /// valores.
  ///
  /// Se aplican en tres pasos, para que el resultado no dependa de cómo se
  /// combinan los modificadores dentro de una misma carta:
  /// 1. Class: cada modificador agrega su Class.
  /// 2. Rarity: un modificador propio conserva la mayor; uno del rival
  ///    reemplaza la Rarity, aunque sea menor.
  /// 3. Power: se suman todos los cambios.
  ///
  /// En cada paso, el filtro de cada modificador se revisa con los valores
  /// que hay en ese momento. Por ejemplo, después de que un Effect agregue la
  /// Class Builder, un Effect "Your Builder creatures get +2" sí la afecta.
  ///
  /// [modifiers] debe incluir solo los que afectan a esta Creature: los
  /// propios con objetivo [AbilityTarget.own] y los del rival con objetivo
  /// [AbilityTarget.enemy].
  ClashStats applyModifiers(List<StatModifier> modifiers) {
    final newClasses = {...classes};
    for (final modifier in modifiers) {
      final added = modifier.addedClass;
      if (added != null && modifier.filter.matches(newClasses, rarity)) {
        newClasses.add(added);
      }
    }

    var newRarity = rarity;
    for (final modifier in modifiers) {
      final granted = modifier.rarity;
      if (granted == null || !modifier.filter.matches(newClasses, newRarity)) {
        continue;
      }
      newRarity = modifier.target == AbilityTarget.own
          ? newRarity.max(granted)
          : granted;
    }

    var newPower = power;
    for (final modifier in modifiers) {
      if (modifier.filter.matches(newClasses, newRarity)) {
        newPower += modifier.powerDelta;
      }
    }

    return ClashStats(rarity: newRarity, classes: newClasses, power: newPower);
  }
}
