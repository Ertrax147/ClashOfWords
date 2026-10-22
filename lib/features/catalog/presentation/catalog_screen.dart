import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_engine/game_engine.dart';

import '../../match/presentation/widgets/card_detail.dart';
import '../../match/presentation/widgets/card_view.dart';
import '../catalog_providers.dart';
import '../domain/card_catalog.dart';

enum _CardType {
  creature('Creatures'),
  item('Items'),
  effect('Effects'),
  initialEffect('Initial Effects');

  const _CardType(this.label);

  final String label;

  bool matches(GameCard card) => switch (card) {
    Creature() => this == creature,
    Item() => this == item,
    Effect() => this == effect,
    InitialEffect() => this == initialEffect,
  };
}

Rarity? _rarityOf(GameCard card) => switch (card) {
  Creature(:final rarity) => rarity,
  Item(:final rarity) => rarity,
  Effect(:final rarity) => rarity,
  InitialEffect() => null,
};

bool _hasClass(GameCard card, CardClass cardClass) => switch (card) {
  Creature(cardClass: final own) => own == cardClass,
  Item(:final classes) => classes.contains(cardClass),
  _ => false,
};

String _capitalized(String text) =>
    text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);

/// Visor de solo lectura de todas las cartas del catálogo (RF-02, RF-05).
///
/// Se puede buscar por nombre y filtrar por tipo, Class y Rarity; tocar una
/// carta abre su vista ampliada.
class CatalogScreen extends ConsumerStatefulWidget {
  /// Crea la pantalla.
  const CatalogScreen({super.key});

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  _CardType? _type;
  CardClass? _class;
  Rarity? _rarity;
  String _query = '';

  bool _passesFilters(GameCard card) {
    if (_type != null && !_type!.matches(card)) return false;
    if (_class != null && !_hasClass(card, _class!)) return false;
    if (_rarity != null && _rarityOf(card) != _rarity) return false;
    final query = _query.trim().toLowerCase();
    return query.isEmpty || card.name.toLowerCase().contains(query);
  }

  @override
  Widget build(BuildContext context) {
    final catalogState = ref.watch(catalogProvider);
    return Scaffold(
      backgroundColor: const Color(0xFF1B2636),
      appBar: AppBar(
        title: const Text('Card catalog'),
        backgroundColor: const Color(0xFF111A27),
      ),
      body: catalogState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(
            'Could not load the cards: $error',
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
        data: _buildCatalog,
      ),
    );
  }

  Widget _buildCatalog(CardCatalog catalog) {
    final classes = {
      for (final card in catalog.cards)
        ...switch (card) {
          Creature(:final cardClass) => [cardClass],
          Item(:final classes) => classes,
          _ => const <CardClass>[],
        },
    }.toList()..sort((a, b) => a.name.compareTo(b.name));
    final cards = catalog.cards.where(_passesFilters).toList();

    final compact = MediaQuery.sizeOf(context).height < 600;
    final filters = <Widget>[
      SizedBox(
        width: 220,
        child: TextField(
          onChanged: (value) => setState(() => _query = value),
          decoration: const InputDecoration(
            hintText: 'Search by name',
            prefixIcon: Icon(Icons.search),
            isDense: true,
            border: OutlineInputBorder(),
          ),
        ),
      ),
      ChoiceChip(
        label: const Text('All'),
        selected: _type == null,
        onSelected: (_) => setState(() => _type = null),
      ),
      for (final type in _CardType.values)
        ChoiceChip(
          label: Text(type.label),
          selected: _type == type,
          onSelected: (_) => setState(() => _type = type),
        ),
      DropdownButton<CardClass?>(
        value: _class,
        hint: const Text('Class'),
        dropdownColor: const Color(0xFF111A27),
        items: [
          const DropdownMenuItem(child: Text('Any Class')),
          for (final cardClass in classes)
            DropdownMenuItem(value: cardClass, child: Text(cardClass.name)),
        ],
        onChanged: (value) => setState(() => _class = value),
      ),
      DropdownButton<Rarity?>(
        value: _rarity,
        hint: const Text('Rarity'),
        dropdownColor: const Color(0xFF111A27),
        items: [
          const DropdownMenuItem(child: Text('Any Rarity')),
          for (final rarity in Rarity.values)
            DropdownMenuItem(
              value: rarity,
              child: Text(_capitalized(rarity.name)),
            ),
        ],
        onChanged: (value) => setState(() => _rarity = value),
      ),
      Text(
        '${cards.length} of ${catalog.cards.length} cards',
        style: const TextStyle(color: Colors.white54),
      ),
    ];

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(compact ? 6 : 12),
          // En pantallas bajas los filtros ocupan una sola fila que se
          // desplaza, para dejar espacio a las cartas.
          child: compact
              ? SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final filter in filters)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: filter,
                        ),
                    ],
                  ),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: filters,
                ),
        ),
        Expanded(
          child: cards.isEmpty
              ? const Center(
                  child: Text(
                    'No cards match these filters.',
                    style: TextStyle(color: Colors.white54),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 170,
                    childAspectRatio: cardAspectRatio,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: cards.length,
                  itemBuilder: (context, index) {
                    final card = cards[index];
                    return LayoutBuilder(
                      builder: (context, constraints) => CardView(
                        card: card,
                        catalog: catalog,
                        height: constraints.maxHeight,
                        onTap: () => showCardDetail(context, card, catalog),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
