import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_engine/game_engine.dart';

import '../../catalog/catalog_providers.dart';
import '../../catalog/domain/card_catalog.dart';
import '../../catalog/presentation/catalog_screen.dart';
import '../../deck_builder/deck_providers.dart';
import '../../deck_builder/domain/saved_deck.dart';
import '../../deck_builder/presentation/deck_builder_screen.dart';
import '../../demo/presentation/demo_setup_screen.dart';
import '../../match/presentation/match_controller.dart';
import '../../match/presentation/match_screen.dart';

/// Alto de pantalla por debajo del cual el menú se muestra compacto: los
/// teléfonos en horizontal miden menos de 450 px de alto.
const _compactHeight = 600.0;

/// Pantalla inicial: permite jugar contra el sistema, armar mazos y ver las
/// cartas.
class HomeScreen extends ConsumerWidget {
  /// Crea la pantalla inicial.
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(catalogProvider);
    final compact = MediaQuery.sizeOf(context).height < _compactHeight;
    final decks = ref.watch(savedDecksProvider).value ?? const <SavedDeck>[];
    final activeId = ref.watch(activeDeckIdProvider).value;
    SavedDeck? active;
    for (final deck in decks) {
      if (deck.id == activeId) active = deck;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1B2636),
      body: SafeArea(
        child: Center(
          // Si la pantalla es muy baja, el menú se desplaza en vez de perder
          // opciones.
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Clash of Words',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 32 : 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: compact ? 16 : 32),
                catalog.when(
                  loading: () => const CircularProgressIndicator(),
                  error: (error, _) => Text(
                    'Could not load the cards: $error',
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                  data: (catalog) {
                    // Solo se juega con el mazo activo si cumple las reglas.
                    final playable =
                        active != null && active.issuesIn(catalog).isEmpty
                        ? active
                        : null;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          playable == null
                              ? 'No active deck: you will play with a random '
                                    'deck. Save one in the Deck Builder.'
                              : 'Active deck: ${playable.name} '
                                    '(${playable.cardCount} cards, '
                                    '${playable.initialEffectIn(catalog)!.name})',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white70),
                        ),
                        SizedBox(height: compact ? 8 : 16),
                        _buildButtons(context, ref, catalog, compact, playable),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButtons(
    BuildContext context,
    WidgetRef ref,
    CardCatalog catalog,
    bool compact,
    SavedDeck? activeDeck,
  ) {
    final padding = EdgeInsets.symmetric(
      horizontal: compact ? 20 : 32,
      vertical: compact ? 12 : 20,
    );
    final textStyle = TextStyle(fontSize: compact ? 16 : 20);
    void open(Widget screen) => Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => screen));

    final buttons = <Widget>[
      FilledButton.icon(
        icon: const Icon(Icons.smart_toy_outlined),
        label: const Text('Play vs System (Easy)'),
        style: FilledButton.styleFrom(padding: padding, textStyle: textStyle),
        onPressed: () {
          // Con mazo activo juegas con él; el rival siempre usa uno al azar.
          ref
              .read(matchControllerProvider.notifier)
              .startMatch(
                catalog,
                humanDeck: activeDeck == null
                    ? null
                    : PlayerDeck(
                        cards: activeDeck.cardsIn(catalog),
                        initialEffect: activeDeck.initialEffectIn(catalog)!,
                      ),
              );
          open(const MatchScreen());
        },
      ),
      OutlinedButton.icon(
        icon: const Icon(Icons.slideshow),
        label: const Text('Demo mode'),
        style: OutlinedButton.styleFrom(padding: padding, textStyle: textStyle),
        onPressed: () => open(const DemoSetupScreen()),
      ),
      OutlinedButton.icon(
        icon: const Icon(Icons.style_outlined),
        label: const Text('Deck Builder'),
        style: OutlinedButton.styleFrom(padding: padding, textStyle: textStyle),
        onPressed: () => open(const DeckBuilderScreen()),
      ),
      OutlinedButton.icon(
        icon: const Icon(Icons.collections_bookmark_outlined),
        label: const Text('Card catalog'),
        style: OutlinedButton.styleFrom(padding: padding, textStyle: textStyle),
        onPressed: () => open(const CatalogScreen()),
      ),
    ];

    // En pantallas bajas los botones van de a dos por fila.
    return compact
        ? Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: buttons,
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < buttons.length; i++) ...[
                if (i > 0) const SizedBox(height: 16),
                buttons[i],
              ],
            ],
          );
  }
}
