import 'saved_deck.dart';

/// Dónde se guardan los mazos del estudiante (RF-03).
abstract interface class DeckRepository {
  /// Todos los mazos guardados, del más antiguo al más nuevo.
  Future<List<SavedDeck>> loadAll();

  /// Guarda [deck]; si ya había un mazo con ese id, lo reemplaza.
  Future<void> save(SavedDeck deck);

  /// Borra el mazo con este [id], si existe. Si era el mazo activo, deja de
  /// serlo.
  Future<void> delete(String id);

  /// Id del mazo activo, el que se usa para jugar, o `null` si no hay.
  Future<String?> loadActiveId();

  /// Marca como activo el mazo con este [id], o deja sin mazo activo con
  /// `null`.
  Future<void> saveActiveId(String? id);
}
