/// Uno de los dos jugadores de una partida.
enum Player {
  one,
  two;

  /// El jugador rival.
  Player get opponent => this == one ? two : one;
}
