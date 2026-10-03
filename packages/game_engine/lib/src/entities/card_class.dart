/// Categoría temática de una carta, como Wild, Smart o Cosmic.
///
/// La Class decide qué Items puede equipar una Creature (RF-10) y, en un
/// Clash entre Creatures de igual Rarity, si hay Tie (misma Class) o se
/// compara el Power (distinta Class) (RF-04).
///
/// No es un enum porque las Class vienen del catálogo de cartas: así el
/// profesor puede agregar Class nuevas sin publicar otra versión de la app
/// (RF-02). Dos Class son iguales si tienen el mismo nombre.
final class CardClass {
  /// Crea una Class con el nombre [name], sin espacios al inicio ni al final.
  ///
  /// Lanza un [ArgumentError] si el nombre queda vacío.
  CardClass(String name) : name = name.trim() {
    if (this.name.isEmpty) {
      throw ArgumentError.value(name, 'name', 'A class name cannot be empty');
    }
  }

  /// Nombre de la Class tal como aparece en la carta, por ejemplo `Wild`.
  final String name;

  @override
  bool operator ==(Object other) => other is CardClass && other.name == name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => 'CardClass($name)';
}
