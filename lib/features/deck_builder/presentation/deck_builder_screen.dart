import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_engine/game_engine.dart';

import '../../catalog/catalog_providers.dart';
import '../../catalog/domain/card_catalog.dart';
import '../../match/presentation/widgets/card_view.dart';
import '../deck_providers.dart';
import '../domain/saved_deck.dart';
import 'deck_builder_controller.dart';

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

/// Alto de pantalla por debajo del cual el Deck Builder se muestra compacto:
/// los teléfonos en horizontal miden menos de 450 px de alto.
const _compactHeight = 600.0;

String _capitalized(String text) =>
    text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);

/// Pantalla para armar y guardar un mazo (RF-03).
class DeckBuilderScreen extends ConsumerStatefulWidget {
  /// Crea la pantalla.
  const DeckBuilderScreen({super.key});

  @override
  ConsumerState<DeckBuilderScreen> createState() => _DeckBuilderScreenState();
}

class _DeckBuilderScreenState extends ConsumerState<DeckBuilderScreen> {
  _CardType? _type;
  CardClass? _class;
  Rarity? _rarity;
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = ref.read(deckBuilderProvider).name;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool _passesFilters(GameCard card) {
    if (card is InitialEffect && !isSelectableInitialEffect(card)) {
      return false;
    }
    if (_type != null && !_type!.matches(card)) return false;
    if (_class != null && !_hasClass(card, _class!)) return false;
    if (_rarity != null && _rarityOf(card) != _rarity) return false;
    return true;
  }

  /// Muestra [message] abajo, sin tapar el panel del mazo (donde están los
  /// botones de guardar y las reglas).
  void _showMessage(String message) {
    final compact = MediaQuery.sizeOf(context).height < _compactHeight;
    final panelWidth = compact ? 300.0 : 360.0;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.fromLTRB(16, 0, panelWidth + 16, 16),
        ),
      );
  }

  /// Agrega [card] al mazo, o explica por qué no se puede.
  void _add(GameCard card) {
    final reason = ref.read(deckBuilderProvider.notifier).add(card);
    if (reason != null) _showMessage(reason);
  }

  /// Guarda el mazo, o dice qué regla le falta cumplir si todavía no es
  /// válido: el botón no se apaga en silencio.
  void _saveOrExplain(SavedDeck deck, List<DeckIssue> issues) {
    if (issues.isEmpty) {
      _save(deck);
      return;
    }
    final more = issues.length > 1 ? ' (${issues.length - 1} more)' : '';
    _showMessage('Cannot save yet: ${explainDeckIssue(issues.first)}$more');
  }

  Future<void> _save(SavedDeck deck) async {
    final named = deck.name.trim().isEmpty
        ? deck.copyWith(name: 'My deck')
        : deck;
    await ref.read(deckRepositoryProvider).save(named);
    ref.invalidate(savedDecksProvider);
    if (!mounted) return;
    ref.read(deckBuilderProvider.notifier).load(named);
    _showMessage('Saved "${named.name}"');
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(deckBuilderProvider, (_, deck) {
      if (_nameController.text != deck.name) _nameController.text = deck.name;
    });
    final catalogState = ref.watch(catalogProvider);
    final compact = MediaQuery.sizeOf(context).height < _compactHeight;
    final loaded = catalogState.value;

    return Scaffold(
      backgroundColor: const Color(0xFF1B2636),
      appBar: AppBar(
        title: const Text('Deck Builder'),
        backgroundColor: const Color(0xFF111A27),
        toolbarHeight: compact ? 44 : null,
        // En pantallas bajas los botones del mazo van arriba, donde no
        // quitan espacio al panel.
        actions: compact && loaded != null
            ? [..._deckButtons(loaded, compact: true), const SizedBox(width: 8)]
            : null,
      ),
      body: catalogState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(
            'Could not load the cards: $error',
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
        data: (catalog) => Row(
          children: [
            Expanded(child: _buildCatalogPanel(catalog, compact)),
            _buildDeckPanel(catalog, compact),
          ],
        ),
      ),
    );
  }

  /// Botones del mazo: Mis mazos, Nuevo, Mazo inicial y Guardar.
  List<Widget> _deckButtons(CardCatalog catalog, {required bool compact}) {
    final deck = ref.watch(deckBuilderProvider);
    final notifier = ref.read(deckBuilderProvider.notifier);
    final issues = deck.issuesIn(catalog);
    return [
      IconButton(
        tooltip: 'My decks',
        icon: const Icon(Icons.folder_open),
        onPressed: () => showDialog<void>(
          context: context,
          builder: (_) => _SavedDecksDialog(catalog: catalog),
        ),
      ),
      IconButton(
        tooltip: 'New deck',
        icon: const Icon(Icons.note_add_outlined),
        onPressed: notifier.clear,
      ),
      IconButton(
        tooltip: 'Starter deck',
        icon: const Icon(Icons.auto_awesome),
        onPressed: () => notifier.loadStarter(catalog, Random()),
      ),
      if (!compact) const Spacer(),
      FilledButton.icon(
        icon: const Icon(Icons.save),
        label: const Text('Save'),
        onPressed: () => _saveOrExplain(deck, issues),
      ),
    ];
  }

  Widget _buildCatalogPanel(CardCatalog catalog, bool compact) {
    final deck = ref.watch(deckBuilderProvider);
    final classes = {
      for (final card in catalog.cards)
        ...switch (card) {
          Creature(:final cardClass) => [cardClass],
          Item(:final classes) => classes,
          _ => const <CardClass>[],
        },
    }.toList()..sort((a, b) => a.name.compareTo(b.name));
    final cards = catalog.cards.where(_passesFilters).toList();

    final filters = <Widget>[
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
        '${cards.length} cards',
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
                    maxCrossAxisExtent: 150,
                    childAspectRatio: cardAspectRatio,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: cards.length,
                  itemBuilder: (context, index) {
                    final card = cards[index];
                    final count = card is InitialEffect
                        ? (deck.initialEffectId == card.id ? 1 : 0)
                        : deck.copiesOf(card.id);
                    return _GridCard(
                      card: card,
                      catalog: catalog,
                      count: count,
                      onAdd: () => _add(card),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildDeckPanel(CardCatalog catalog, bool compact) {
    final deck = ref.watch(deckBuilderProvider);
    final notifier = ref.read(deckBuilderProvider.notifier);
    final issues = deck.issuesIn(catalog);
    final count = deck.cardCount;
    final sizeOk = count >= DeckRules.minCards && count <= DeckRules.maxCards;
    final initialEffect = deck.initialEffectIn(catalog);
    final entries =
        [
          for (final entry in deck.copies.entries)
            if (catalog.byId(entry.key) case final found?)
              (card: found.card, copies: entry.value),
        ]..sort((a, b) {
          final byType = _typeIndex(a.card).compareTo(_typeIndex(b.card));
          return byType != 0 ? byType : a.card.name.compareTo(b.card.name);
        });

    // En pantallas bajas todo el panel se desplaza, con la lista de cartas
    // incluida, en vez de dejar sin espacio a lo de abajo.
    Widget scroll(List<Widget> children) => compact
        ? SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          );
    final rows = [
      for (final entry in entries)
        _DeckRow(
          card: entry.card,
          copies: entry.copies,
          onAdd: () => _add(entry.card),
          onRemove: () => notifier.remove(entry.card),
        ),
    ];
    final slotHeight = compact ? 56.0 : 88.0;

    return Container(
      width: compact ? 300 : 360,
      color: const Color(0xFF111A27),
      padding: EdgeInsets.all(compact ? 8 : 16),
      child: scroll([
        TextField(
          controller: _nameController,
          onChanged: notifier.rename,
          decoration: const InputDecoration(
            labelText: 'Deck name',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '$count / ${DeckRules.maxCards} cards',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: sizeOk ? Colors.lightGreenAccent : Colors.amberAccent,
          ),
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: (count / DeckRules.maxCards).clamp(0, 1),
          color: sizeOk ? Colors.lightGreenAccent : Colors.amberAccent,
        ),
        // En pantallas bajas la lista de reglas queda al final del panel, así
        // que la primera que falla se ve aquí, junto al contador.
        if (compact && issues.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              explainDeckIssue(issues.first),
              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          ),
        if (!compact) ...[
          const SizedBox(height: 4),
          Text(
            'From ${DeckRules.minCards} to ${DeckRules.maxCards} cards, up '
            'to ${DeckRules.maxCopies} copies of each, plus 1 Initial '
            'Effect.',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            initialEffect == null
                ? EmptyCardSlot(
                    height: slotHeight,
                    label: compact ? null : 'Initial\nEffect',
                  )
                : CardView(
                    card: initialEffect,
                    catalog: catalog,
                    height: slotHeight,
                  ),
            const SizedBox(width: 12),
            Expanded(
              child: initialEffect == null
                  ? const Text(
                      'Pick one with the Initial Effects filter.',
                      style: TextStyle(color: Colors.white70),
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: Text(
                            initialEffect.name,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Remove Initial Effect',
                          icon: const Icon(Icons.close),
                          onPressed: () => notifier.remove(initialEffect),
                        ),
                      ],
                    ),
            ),
          ],
        ),
        const Divider(height: 24),
        if (compact)
          if (entries.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Tap a card to add it.',
                style: TextStyle(color: Colors.white54),
              ),
            )
          else
            ...rows
        else
          Expanded(
            child: entries.isEmpty
                ? const Center(
                    child: Text(
                      'Tap a card to add it.',
                      style: TextStyle(color: Colors.white54),
                    ),
                  )
                : ListView(children: rows),
          ),
        const Divider(height: 24),
        if (issues.isEmpty)
          const Text(
            'This deck follows all the rules.',
            style: TextStyle(color: Colors.lightGreenAccent),
          )
        else
          for (final issue in issues)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                explainDeckIssue(issue),
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
        if (!compact) ...[
          const SizedBox(height: 8),
          Row(children: _deckButtons(catalog, compact: false)),
        ],
      ]),
    );
  }

  int _typeIndex(GameCard card) =>
      _CardType.values.indexWhere((type) => type.matches(card));
}

/// Carta del catálogo en la grilla: un toque la agrega al mazo.
class _GridCard extends StatelessWidget {
  const _GridCard({
    required this.card,
    required this.catalog,
    required this.count,
    required this.onAdd,
  });

  final GameCard card;
  final CardCatalog catalog;
  final int count;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Stack(
        children: [
          CardView(
            card: card,
            catalog: catalog,
            height: constraints.maxHeight,
            highlighted: count > 0,
            onTap: onAdd,
          ),
          if (count > 0)
            Positioned(
              top: 4,
              right: 4,
              child: CircleAvatar(
                radius: 13,
                backgroundColor: Colors.amberAccent,
                child: Text(
                  card is InitialEffect ? '✓' : '$count',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Fila del mazo con los botones para sumar o quitar copias.
class _DeckRow extends StatelessWidget {
  const _DeckRow({
    required this.card,
    required this.copies,
    required this.onAdd,
    required this.onRemove,
  });

  final GameCard card;
  final int copies;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final rarity = _rarityOf(card);
    final tooMany = copies > DeckRules.maxCopies;
    return Row(
      children: [
        Expanded(
          child: Text(
            rarity == null
                ? card.name
                : '${card.name} · ${_capitalized(rarity.name)}',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: tooMany ? Colors.redAccent : Colors.white),
          ),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: onRemove,
        ),
        SizedBox(
          width: 20,
          child: Text(
            '$copies',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: tooMany ? Colors.redAccent : Colors.white,
            ),
          ),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.add_circle_outline),
          onPressed: onAdd,
        ),
      ],
    );
  }
}

/// Lista de mazos guardados, para seguir armando uno o borrarlo.
class _SavedDecksDialog extends ConsumerWidget {
  const _SavedDecksDialog({required this.catalog});

  final CardCatalog catalog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decks = ref.watch(savedDecksProvider);
    return AlertDialog(
      title: const Text('My decks'),
      content: SizedBox(
        width: 420,
        child: decks.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Text('Could not load the decks: $error'),
          data: (decks) => decks.isEmpty
              ? const Text('You have not saved any deck yet.')
              : ListView(
                  shrinkWrap: true,
                  children: [
                    for (final deck in decks)
                      ListTile(
                        title: Text(deck.name.isEmpty ? 'Untitled' : deck.name),
                        subtitle: Text(
                          '${deck.cardCount} cards · '
                          '${deck.initialEffectIn(catalog)?.name ?? 'No Initial Effect'}',
                        ),
                        onTap: () {
                          ref.read(deckBuilderProvider.notifier).load(deck);
                          Navigator.of(context).pop();
                        },
                        trailing: IconButton(
                          tooltip: 'Delete',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            await ref
                                .read(deckRepositoryProvider)
                                .delete(deck.id);
                            ref.invalidate(savedDecksProvider);
                          },
                        ),
                      ),
                  ],
                ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
