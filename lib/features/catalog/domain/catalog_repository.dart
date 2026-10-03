import 'card_catalog.dart';

/// Fuente del catálogo de cartas.
///
/// La interfaz depende de este contrato y no de dónde vienen las cartas:
/// hoy se leen desde los assets de la app; más adelante podrán descargarse
/// del servidor y guardarse en el dispositivo (RF-08).
abstract interface class CatalogRepository {
  /// Carga el catálogo completo.
  Future<CardCatalog> loadCatalog();
}
