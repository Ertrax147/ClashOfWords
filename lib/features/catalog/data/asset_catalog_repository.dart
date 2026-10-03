import 'package:flutter/services.dart';

import '../domain/card_catalog.dart';
import '../domain/catalog_repository.dart';
import 'models/card_model.dart';

/// Lee el catálogo desde los assets incluidos en la app.
///
/// Funciona sin conexión (RF-08). Es la fuente del prototipo; más adelante
/// el catálogo se descargará del servidor.
class AssetCatalogRepository implements CatalogRepository {
  /// Crea el repositorio. [bundle] permite usar otros assets en los tests.
  AssetCatalogRepository({AssetBundle? bundle})
    : _bundle = bundle ?? rootBundle;

  /// Ruta del archivo del catálogo.
  static const catalogPath = 'assets/catalog/cards.json';

  /// Carpeta de las imágenes de las cartas.
  static const imageFolder = 'assets/cards';

  final AssetBundle _bundle;

  @override
  Future<CardCatalog> loadCatalog() async {
    final source = await _bundle.loadString(catalogPath);
    return parseCatalog(source, imageFolder: imageFolder);
  }
}
