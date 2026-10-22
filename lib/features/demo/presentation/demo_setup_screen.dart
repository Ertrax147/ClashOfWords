import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_engine/game_engine.dart';

import '../../catalog/catalog_providers.dart';
import '../../catalog/domain/card_catalog.dart';
import '../../deck_builder/deck_providers.dart';
import '../../deck_builder/domain/saved_deck.dart';
import '../../match/presentation/match_controller.dart';
import '../../match/presentation/match_screen.dart';
import '../../match/presentation/widgets/card_view.dart';
import '../domain/demo_deck.dart';

/// Pantalla para preparar una partida de demostración: mazo e Initial Effect
/// de cada jugador, y si los Decks se barajan o se respeta su orden.
class DemoSetupScreen extends ConsumerStatefulWidget {
  /// Crea la pantalla.
  const DemoSetupScreen({super.key});

  @override
  ConsumerState<DemoSetupScreen> createState() => _DemoSetupScreenState();
}

class _DemoSetupScreenState extends ConsumerState<DemoSetupScreen> {
  String? _playerDeckId;
  String? _playerEffectId;
  String? _rivalDeckId;
  String? _rivalEffectId;
  bool _fixedOrder = false;

  SavedDeck? _deckWithId(List<SavedDeck> decks, String? id) {
    for (final deck in decks) {
      if (deck.id == id) return deck;
    }
    return null;
  }

  InitialEffect? _effectWithId(CardCatalog catalog, String? id) {
    final card = id == null ? null : catalog.byId(id)?.card;
    return card is InitialEffect ? card : null;
  }

  void _start(CardCatalog catalog, List<SavedDeck> decks) {
    final fixed = _fixedOrder;
    final playerDeck = buildDemoDeck(
      catalog,
      fixed ? Random(demoPlayerSeed) : ref.read(matchRandomProvider),
      deck: _deckWithId(decks, _playerDeckId),
      initialEffect: _effectWithId(catalog, _playerEffectId),
    );
    final rivalDeck = buildDemoDeck(
      catalog,
      fixed ? Random(demoRivalSeed) : ref.read(matchRandomProvider),
      deck: _deckWithId(decks, _rivalDeckId),
      initialEffect: _effectWithId(catalog, _rivalEffectId),
    );
    ref
        .read(matchControllerProvider.notifier)
        .startMatch(
          catalog,
          humanDeck: playerDeck,
          systemDeck: rivalDeck,
          shuffle: !fixed,
          random: fixed ? Random(demoMatchSeed) : null,
        );
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const MatchScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final catalogState = ref.watch(catalogProvider);
    final decksState = ref.watch(savedDecksProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1B2636),
      appBar: AppBar(
        title: const Text('Demo mode'),
        backgroundColor: const Color(0xFF111A27),
      ),
      body: switch ((catalogState, decksState)) {
        (AsyncData(value: final catalog), AsyncData(value: final decks)) =>
          _buildSetup(catalog, decks),
        (AsyncError(:final error), _) ||
        (_, AsyncError(:final error)) => Center(
          child: Text(
            'Could not load the demo: $error',
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }

  Widget _buildSetup(CardCatalog catalog, List<SavedDeck> decks) {
    final effects = selectableInitialEffects(catalog);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SidePicker(
                  title: 'You',
                  catalog: catalog,
                  decks: decks,
                  effects: effects,
                  deckId: _playerDeckId,
                  effectId: _playerEffectId,
                  onDeck: (id) => setState(() => _playerDeckId = id),
                  onEffect: (id) => setState(() => _playerEffectId = id),
                ),
                const SizedBox(width: 24),
                _SidePicker(
                  title: 'Opponent',
                  catalog: catalog,
                  decks: decks,
                  effects: effects,
                  deckId: _rivalDeckId,
                  effectId: _rivalEffectId,
                  onDeck: (id) => setState(() => _rivalDeckId = id),
                  onEffect: (id) => setState(() => _rivalEffectId = id),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 520,
              child: SwitchListTile(
                value: _fixedOrder,
                onChanged: (value) => setState(() => _fixedOrder = value),
                title: const Text('Fixed order (do not shuffle)'),
                subtitle: const Text(
                  'Decks keep the order in which you added the cards, and the '
                  'match repeats the same way every time.',
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start demo'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 20,
                ),
                textStyle: const TextStyle(fontSize: 20),
              ),
              onPressed: () => _start(catalog, decks),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mazo e Initial Effect de un lado de la demostración.
class _SidePicker extends StatelessWidget {
  const _SidePicker({
    required this.title,
    required this.catalog,
    required this.decks,
    required this.effects,
    required this.deckId,
    required this.effectId,
    required this.onDeck,
    required this.onEffect,
  });

  final String title;
  final CardCatalog catalog;
  final List<SavedDeck> decks;
  final List<InitialEffect> effects;
  final String? deckId;
  final String? effectId;
  final ValueChanged<String?> onDeck;
  final ValueChanged<String?> onEffect;

  @override
  Widget build(BuildContext context) {
    SavedDeck? chosenDeck;
    for (final deck in decks) {
      if (deck.id == deckId) chosenDeck = deck;
    }
    final shownEffect =
        (effectId == null ? null : catalog.byId(effectId!)?.card) ??
        chosenDeck?.initialEffectIn(catalog);

    return SizedBox(
      width: 248,
      child: Card(
        color: const Color(0xFF111A27),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButton<String?>(
                isExpanded: true,
                value: chosenDeck?.id,
                dropdownColor: const Color(0xFF111A27),
                items: [
                  const DropdownMenuItem(child: Text('Random deck')),
                  for (final deck in decks)
                    DropdownMenuItem(
                      value: deck.id,
                      enabled: deck.issuesIn(catalog).isEmpty,
                      child: Text(
                        _deckLabel(deck, deck.issuesIn(catalog).isEmpty),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: onDeck,
              ),
              DropdownButton<String?>(
                isExpanded: true,
                value: effectId,
                dropdownColor: const Color(0xFF111A27),
                items: [
                  DropdownMenuItem(
                    child: Text(
                      chosenDeck == null
                          ? 'Random Initial Effect'
                          : 'Initial Effect of the deck',
                    ),
                  ),
                  for (final effect in effects)
                    DropdownMenuItem(
                      value: effect.id,
                      child: Text(effect.name),
                    ),
                ],
                onChanged: onEffect,
              ),
              const SizedBox(height: 12),
              Center(
                child: shownEffect == null
                    ? const EmptyCardSlot(height: 150, label: 'Initial\nEffect')
                    : CardView(
                        card: shownEffect,
                        catalog: catalog,
                        height: 150,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _deckLabel(SavedDeck deck, bool valid) {
    final name = deck.name.isEmpty ? 'Untitled' : deck.name;
    return valid ? name : '$name (incomplete)';
  }
}
