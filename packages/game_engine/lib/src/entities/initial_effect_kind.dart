/// Cuál de los 16 Initial Effects del juego es una carta.
///
/// A diferencia de las habilidades de Effects y Creatures, los Initial
/// Effects no se describen como datos: cada uno tiene su propia lógica en la
/// partida. El texto de cada valor es la traducción del manual.
enum InitialEffectKind {
  /// Activa: mueve una Creature desde tu Discard Stack a tu Deck. Luego,
  /// baraja tu Deck.
  recycle(active: true),

  /// Pasiva: tu primera Creature de cada Class obtiene +2 de Power.
  diversity(passive: true),

  /// Pasiva: tus primeras 3 Creatures derrotadas, en vez de ir al Trophy
  /// Stack del enemigo, van a tu Discard Stack.
  tolerance(passive: true),

  /// Pasiva: tus Creatures pueden usar múltiples Items. Activa: mueve un
  /// Item desde tu Discard Stack a tu Deck. Luego, baraja tu Deck.
  responsibility(passive: true, active: true),

  /// Pasiva: gana todos los empates por Class si tu Creature gana por Power.
  respect(passive: true),

  /// Activa: mueve una Creature desde el Trophy Stack del enemigo a tu
  /// Discard Stack.
  loyalty(active: true),

  /// Activa: tu Creature obtiene Duración: 3 Clashes.
  leadership(active: true),

  /// Activa: mueve la carta superior del Deck de tu enemigo directamente a
  /// tu Trophy Stack.
  kindness(active: true),

  /// Pasiva: tu siguiente Creature obtiene +1 por cada Clash perdido
  /// anteriormente (se reinicia al ganar un Clash).
  justice(passive: true),

  /// Activa: revela las 3 cartas superiores de tu Deck y del Deck de tu
  /// enemigo. Luego, vuelve a colocarlas en cualquier orden.
  honesty(active: true),

  /// Activa: toma control de un Item o Effect enemigo (excepto Initial
  /// Effects).
  generosity(active: true),

  /// Pasiva: si empatas, tu siguiente Creature obtiene +3.
  friendship(passive: true),

  /// Pasiva: si ganas un Clash, tu siguiente Creature obtiene +1.
  excellence(passive: true),

  /// Pasiva: copia la habilidad de Initial Effect de tu enemigo.
  empathy(passive: true),

  /// Activa: busca y juega una Creature desde tu Deck. Luego, baraja tu
  /// Deck.
  creativity(active: true),

  /// Activa: gana un Clash perdido. Luego, mueve una Creature desde tu
  /// Trophy Stack al Discard Stack de tu enemigo. Esta habilidad no puede
  /// ser contrarrestada.
  commitment(active: true);

  const InitialEffectKind({this.passive = false, this.active = false});

  /// Si tiene una habilidad pasiva, que actúa toda la partida.
  final bool passive;

  /// Si tiene una habilidad activa, que el jugador usa una vez por partida.
  final bool active;
}
