import 'dart:io';

import 'package:clash_of_words/features/catalog/data/asset_catalog_repository.dart';
import 'package:clash_of_words/features/catalog/domain/card_catalog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_engine/game_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CardCatalog catalog;

  setUpAll(() async {
    catalog = await AssetCatalogRepository().loadCatalog();
  });

  test('the bundled catalog loads every card', () {
    expect(catalog.entries, hasLength(78));
    expect(catalog.cardsOf<Creature>(), hasLength(30));
    expect(catalog.cardsOf<Item>(), hasLength(12));
    expect(catalog.cardsOf<Effect>(), hasLength(20));
  });

  test('it has the 16 initial effects, one of each kind', () {
    final kinds = {
      for (final effect in catalog.cardsOf<InitialEffect>()) effect.kind,
    };

    expect(kinds, InitialEffectKind.values.toSet());
  });

  test('every card has its image file', () {
    final missing = [
      for (final entry in catalog.entries)
        if (!File(entry.imageAsset).existsSync()) entry.imageAsset,
    ];

    expect(missing, isEmpty);
  });
}
