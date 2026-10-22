import 'saved_deck.dart';

/// Dónde se guardan los mazos del estudiante (RF-03).
abstract interface class DeckRepository {
  /// Todos los mazos guardados, del más antiguo al más nuevo.
  Future<List<SavedDeck>> loadAll();

  /// Guarda [deck]; si ya había un mazo con ese id, lo reemplaza.
  Future<void> save(SavedDeck deck);

  /// Borra el mazo con este [id], si existe.
  Future<void> delete(String id);
}
