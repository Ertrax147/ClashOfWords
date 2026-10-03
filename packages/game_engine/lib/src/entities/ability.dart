import 'card_class.dart';
import 'rarity.dart';

/// A quién afecta una habilidad, visto desde el dueño de la carta.
enum AbilityTarget {
  /// Las Creatures del dueño de la carta ("Your creatures...").
  own,

  /// Las Creatures del rival ("Enemy creatures...").
  enemy,
}

/// Condición que debe cumplir una Creature para que una habilidad la
/// afecte, por ejemplo "Your Smart and Social Common creatures".
///
/// Un conjunto vacío no filtra: [CreatureFilter.any] afecta a todas.
final class CreatureFilter {
  /// Crea un filtro por Class y Rarity.
  ///
  /// La Creature debe tener al menos una de las [classes] (si hay) y una de
  /// las [rarities] (si hay).
  CreatureFilter({
    Set<CardClass> classes = const {},
    Set<Rarity> rarities = const {},
  }) : classes = Set.unmodifiable(classes),
       rarities = Set.unmodifiable(rarities);

  /// Filtro que acepta cualquier Creature.
  static final CreatureFilter any = CreatureFilter();

  /// Class aceptadas. Vacío si acepta cualquiera.
  final Set<CardClass> classes;

  /// Rarity aceptadas. Vacío si acepta cualquiera.
  final Set<Rarity> rarities;

  /// Indica si una Creature con estas [creatureClasses] y esta
  /// [creatureRarity] cumple el filtro.
  bool matches(Set<CardClass> creatureClasses, Rarity creatureRarity) =>
      (classes.isEmpty || classes.any(creatureClasses.contains)) &&
      (rarities.isEmpty || rarities.contains(creatureRarity));
}

/// Habilidad de una carta.
///
/// Las habilidades se describen como datos, así el catálogo puede crear
/// cartas nuevas de estos tipos sin cambiar el código. Es `sealed`: un
/// `switch` sobre una [Ability] obliga a contemplar todos los tipos.
sealed class Ability {
  const Ability();
}

/// Cambia los valores de combate de las Creatures que cumplen el [filter].
///
/// Ejemplos:
/// - "Your Economic creatures get +3": `own`, Class Economic, `powerDelta: 3`.
/// - "Enemy creatures get -3": `enemy`, `powerDelta: -3`.
/// - "Your creatures get Builder": `own`, `addedClass: Builder`.
/// - "Your creatures get Cosmic, Rare and +1": las tres cosas a la vez.
///
/// Lo que se le da a las Creatures propias nunca las empeora: conservan la
/// mayor Rarity. Lo que apunta al rival sí puede empeorarlas: su Rarity pasa
/// a ser [rarity] aunque sea menor.
final class StatModifier extends Ability {
  /// Crea un modificador.
  ///
  /// Lanza un [ArgumentError] si no cambia nada.
  StatModifier({
    required this.target,
    CreatureFilter? filter,
    this.powerDelta = 0,
    this.rarity,
    this.addedClass,
  }) : filter = filter ?? CreatureFilter.any {
    if (powerDelta == 0 && rarity == null && addedClass == null) {
      throw ArgumentError('A stat modifier must change something');
    }
  }

  /// A quién afecta.
  final AbilityTarget target;

  /// Qué Creatures afecta.
  final CreatureFilter filter;

  /// Power que suma (o resta, si es negativo).
  final int powerDelta;

  /// Rarity que otorga, o `null` si no la cambia.
  final Rarity? rarity;

  /// Class que agrega, o `null` si no agrega ninguna. La Creature conserva
  /// su Class original.
  final CardClass? addedClass;
}

/// Saca de la mesa a las Creatures rivales que cumplen el [filter], por
/// ejemplo "Move the enemy Artist creature to the Discard stack".
///
/// La Creature y su Item van al Discard Stack de su dueño (no son trofeos) y
/// el rival revela otra. Mientras dure la carta, se aplica también a las
/// Creatures que el rival revele.
final class DiscardEnemyCreatures extends Ability {
  /// Crea la habilidad para las Creatures rivales que cumplen [filter].
  const DiscardEnemyCreatures(this.filter);

  /// Qué Creatures rivales saca de la mesa.
  final CreatureFilter filter;
}

/// Impide que el rival juegue cierto tipo de carta, por ejemplo "Your enemy
/// cannot play Effects".
///
/// Solo impide jugar cartas nuevas: no cancela las que ya están en juego.
final class ForbidEnemyPlays extends Ability {
  /// Crea la prohibición.
  ///
  /// Lanza un [ArgumentError] si no prohíbe nada.
  ForbidEnemyPlays({this.items = false, this.effects = false}) {
    if (!items && !effects) {
      throw ArgumentError('A prohibition must forbid something');
    }
  }

  /// Si el rival no puede equipar Items.
  final bool items;

  /// Si el rival no puede jugar Effects.
  final bool effects;
}
