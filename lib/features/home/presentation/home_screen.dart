import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../catalog/catalog_providers.dart';
import '../../match/presentation/match_controller.dart';
import '../../match/presentation/match_screen.dart';

/// Pantalla inicial: por ahora solo permite jugar contra el sistema.
class HomeScreen extends ConsumerWidget {
  /// Crea la pantalla inicial.
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(catalogProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1B2636),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Clash of Words',
              style: TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            catalog.when(
              loading: () => const CircularProgressIndicator(),
              error: (error, _) => Text(
                'Could not load the cards: $error',
                style: const TextStyle(color: Colors.redAccent),
              ),
              data: (catalog) => FilledButton.icon(
                icon: const Icon(Icons.smart_toy_outlined),
                label: const Text('Play vs System (Easy)'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 20,
                  ),
                  textStyle: const TextStyle(fontSize: 20),
                ),
                onPressed: () {
                  ref
                      .read(matchControllerProvider.notifier)
                      .startMatch(catalog);
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const MatchScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
