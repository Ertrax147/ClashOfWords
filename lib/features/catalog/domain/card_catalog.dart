import 'package:game_engine/game_engine.dart';

/// Carta del catálogo junto con su imagen.
class CatalogEntry {
  /// Crea una entrada con la [card] y la ruta de su [imageAsset].
  const CatalogEntry({required this.card, required this.imageAsset});

  /// Carta tal como la entiende el motor del juego.
  final GameCard card;

  /// Ruta de la imagen de la carta dentro de los assets de la app.
  final String imageAsset;
}

/// Catálogo de cartas disponible en la app (RF-02).
///
/// Es de solo lectura: el profesor lo modifica desde el panel de
/// administración, no desde la app del estudiante.
class CardCatalog {
  /// Crea el catálogo con sus [entries].
  ///
  /// Lanza un [ArgumentError] si dos cartas tienen el mismo id.
  CardCatalog(List<CatalogEntry> entries)
    : entries = List.unmodifiable(entries),
      _byId = {for (final entry in entries) entry.card.id: entry} {
    if (_byId.length != entries.length) {
      throw ArgumentError('The catalog has repeated card ids');
    }
  }

  /// Todas las cartas, en el orden del catálogo.
  final List<CatalogEntry> entries;

  final Map<String, CatalogEntry> _byId;

  /// Las cartas, sin sus imágenes.
  List<GameCard> get cards => [for (final entry in entries) entry.card];

  /// Las cartas de tipo [T], por ejemplo `cardsOf<Creature>()`.
  List<T> cardsOf<T extends GameCard>() => cards.whereType<T>().toList();

  /// La entrada de la carta con este [id], o `null` si no existe.
  CatalogEntry? byId(String id) => _byId[id];

  /// Ruta de la imagen de [card].
  ///
  /// Lanza un [ArgumentError] si la carta no es del catálogo.
  String imageOf(GameCard card) {
    final entry = _byId[card.id];
    if (entry == null) {
      throw ArgumentError.value(card.id, 'card', 'Not in the catalog');
    }
    return entry.imageAsset;
  }
}
