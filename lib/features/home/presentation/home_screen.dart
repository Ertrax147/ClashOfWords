import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../catalog/catalog_providers.dart';
import '../../catalog/domain/card_catalog.dart';
import '../../catalog/presentation/catalog_screen.dart';
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
                  data: (catalog) =>
                      _buildButtons(context, ref, catalog, compact),
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
          ref.read(matchControllerProvider.notifier).startMatch(catalog);
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
