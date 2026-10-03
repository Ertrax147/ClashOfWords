import 'card_class.dart';
import 'clash_duration.dart';
import 'rarity.dart';

/// Carta del catálogo de Clash of Words.
///
/// Es la base común de los cuatro tipos de carta: [Creature], [Item],
/// [Effect] e [InitialEffect]. Es `sealed`, así que un `switch` sobre una
/// [GameCard] obliga a contemplar los cuatro tipos.
///
/// Estas clases describen la carta tal como está impresa (sus atributos
/// fijos). Las habilidades se agregan en una etapa posterior del motor.
///
/// Se llama `GameCard` y no `Card` para no chocar con el widget `Card` de
/// Flutter en las pantallas que importen ambos.
sealed class GameCard {
  /// Crea una carta con su identificador [id] y su nombre [name].
  ///
  /// Lanza un [ArgumentError] si alguno de los dos está vacío.
  GameCard({required this.id, required this.name}) {
    if (id.trim().isEmpty) {
      throw ArgumentError.value(id, 'id', 'A card id cannot be empty');
    }
    if (name.trim().isEmpty) {
      throw ArgumentError.value(name, 'name', 'A card name cannot be empty');
    }
  }

  /// Identificador único de la carta en el catálogo.
  final String id;

  /// Nombre de la carta en inglés, por ejemplo `Unicorn Queen`.
  final String name;
}

/// Carta que se enfrenta a otra en un Clash (RF-04).
///
/// En un Clash se compara primero la Rarity ([rarity]), luego la Class
/// ([cardClass]) y por último el Power ([power]). Una Creature permanece en
/// juego durante [duration] Clashes mientras siga ganando.
final class Creature extends GameCard {
  /// Crea una Creature.
  ///
  /// Lanza un [ArgumentError] si [power] está fuera del rango de [minPower]
  /// a [maxPower].
  Creature({
    required super.id,
    required super.name,
    required this.rarity,
    required this.cardClass,
    required this.power,
    this.duration = ClashDuration.one,
  }) {
    if (power < minPower || power > maxPower) {
      throw ArgumentError.value(
        power,
        'power',
        'Power must be between $minPower and $maxPower',
      );
    }
  }

  /// Power mínimo impreso en una Creature (por ejemplo, Elder Angel tiene 0).
  static const int minPower = 0;

  /// Power máximo impreso en una Creature.
  static const int maxPower = 9;

  /// Rarity de la Creature.
  final Rarity rarity;

  /// Class de la Creature. Cada Creature tiene exactamente una; los Items,
  /// en cambio, pueden tener varias.
  final CardClass cardClass;

  /// Power impreso en la carta, sin modificadores de Items ni Effects.
  final int power;

  /// Cuántos Clashes permanece en juego. Por defecto, uno.
  final ClashDuration duration;
}

/// Carta que se equipa a una Creature para mejorarla (RF-10).
///
/// Un Item puede sumar Power, otorgar una Rarity y otorgar una Duration a su
/// Creature. Sus modificadores valen mientras esté equipado, y la Creature
/// conserva siempre la mayor Rarity y la mayor Duration.
final class Item extends GameCard {
  /// Crea un Item.
  ///
  /// Si [classes] está vacío, el Item es universal (ver [isUniversal]).
  /// Lanza un [ArgumentError] si [powerBonus] es negativo.
  Item({
    required super.id,
    required super.name,
    required this.rarity,
    Set<CardClass> classes = const {},
    required this.powerBonus,
    this.grantedRarity,
    this.grantedDuration,
  }) : classes = Set.unmodifiable(classes) {
    if (powerBonus < 0) {
      throw ArgumentError.value(
        powerBonus,
        'powerBonus',
        'The power bonus cannot be negative',
      );
    }
  }

  /// Rarity del Item. Determina su probabilidad en los sobres, no compite en
  /// el Clash.
  final Rarity rarity;

  /// Class del Item. Vacío si es universal.
  final Set<CardClass> classes;

  /// Power que suma a su Creature, por ejemplo `+9` en Diamond Sword.
  final int powerBonus;

  /// Rarity que otorga a su Creature, o `null` si no otorga ninguna.
  ///
  /// Por ejemplo, Fire Axe: "Your creature gets Epic".
  final Rarity? grantedRarity;

  /// Duration que otorga a su Creature, o `null` si no otorga ninguna.
  ///
  /// Es la Duration de la Creature, no la del Item. Por ejemplo, Ancient
  /// Pan: "Your creature get Duration: 3 clashes".
  final ClashDuration? grantedDuration;

  /// Indica si el Item puede equiparse a cualquier Creature.
  ///
  /// Los Items sin Class son universales; en las cartas actuales son los
  /// Epic y Legendary.
  bool get isUniversal => classes.isEmpty;

  /// Indica si este Item puede equiparse a [creature] según su Class.
  ///
  /// Un Item universal sirve para cualquier Creature. Si no, la Class de la
  /// Creature debe estar entre las Class del Item (RF-10). Por ejemplo,
  /// Invisible Coat (Magical y Secret) sirve para una Creature Magical.
  ///
  /// Solo revisa la Class: que la Creature no tenga ya otro Item equipado y
  /// las restricciones de las habilidades se validan durante la partida.
  bool canBeEquippedTo(Creature creature) =>
      isUniversal || classes.contains(creature.cardClass);
}

/// Carta que cambia las reglas del juego durante algunos Clashes (RF-10).
///
/// Se juega desde la mano durante un Clash y, al terminar su [duration], va
/// al Discard Stack de su dueño.
final class Effect extends GameCard {
  /// Crea un Effect.
  Effect({
    required super.id,
    required super.name,
    required this.rarity,
    required this.duration,
  });

  /// Rarity del Effect. Determina su probabilidad en los sobres, no compite
  /// en el Clash.
  final Rarity rarity;

  /// Cuántos Clashes permanece en juego.
  final ClashDuration duration;
}

/// Carta única de cada jugador que permanece en juego toda la partida
/// (RF-10).
///
/// Su Rarity es siempre *Value* y no tiene Power, porque nunca se enfrenta
/// en un Clash. Sus habilidades pasivas actúan toda la partida y las activas
/// se usan una vez por partida.
final class InitialEffect extends GameCard {
  /// Crea un Initial Effect.
  InitialEffect({required super.id, required super.name});
}
