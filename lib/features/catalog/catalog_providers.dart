import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/asset_catalog_repository.dart';
import 'domain/card_catalog.dart';
import 'domain/catalog_repository.dart';

/// Repositorio del catálogo que usa la app. Los tests pueden reemplazarlo.
final catalogRepositoryProvider = Provider<CatalogRepository>(
  (ref) => AssetCatalogRepository(),
);

/// Catálogo de cartas, cargado una vez y compartido por toda la app.
final catalogProvider = FutureProvider<CardCatalog>(
  (ref) => ref.watch(catalogRepositoryProvider).loadCatalog(),
);
