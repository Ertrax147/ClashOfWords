import 'dart:convert';
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

  test('the bundled catalog loads every card of cards.json', () {
    final cards =
        (jsonDecode(File('assets/catalog/cards.json').readAsStringSync())
                as Map<String, dynamic>)['cards']
            as List;
    int countOf(String type) =>
        cards.where((card) => card['type'] == type).length;

    expect(catalog.entries, hasLength(cards.length));
    expect(catalog.cardsOf<Creature>(), hasLength(countOf('creature')));
    expect(catalog.cardsOf<Item>(), hasLength(countOf('item')));
    expect(catalog.cardsOf<Effect>(), hasLength(countOf('effect')));
  });

  test('no two cards share an id', () {
    final ids = [for (final entry in catalog.entries) entry.card.id];

    expect(ids.toSet(), hasLength(ids.length));
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
