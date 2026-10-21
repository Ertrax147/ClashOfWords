import 'dart:math';

import 'package:clash_of_words/features/catalog/domain/card_catalog.dart';
import 'package:clash_of_words/features/match/presentation/match_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_engine/game_engine.dart';

/// Creature del catálogo con la [rarity] dada y sin Duration propia. Con
/// Rarity distinta, el Clash lo decide la Rarity y no hay Tie. [skip] elige
/// otra copia distinta de la misma Rarity.
///
/// Las Creatures Epic y Legendary del catálogo traen siempre una Duration,
/// por eso los tests usan Common, Uncommon y Rare.
Creature creatureOf(CardCatalog catalog, Rarity rarity, [int skip = 0]) =>
    catalog
        .cardsOf<Creature>()
        .where((c) => c.rarity == rarity && c.duration == ClashDuration.one)
        .skip(skip)
        .first;

/// Initial Effect del catálogo del tipo [kind].
InitialEffect effectOf(CardCatalog catalog, InitialEffectKind kind) =>
    catalog.cardsOf<InitialEffect>().firstWhere((card) => card.kind == kind);

/// Empieza una partida sin barajar en la que el estudiante tiene [humanKind]
/// y el sistema [systemKind]. Los mazos salen en el orden dado.
ProviderContainer startGame(
  CardCatalog catalog, {
  required List<GameCard> human,
  required List<GameCard> system,
  required InitialEffectKind humanKind,
  InitialEffectKind systemKind = InitialEffectKind.respect,
}) {
  final container = ProviderContainer(
    overrides: [matchRandomProvider.overrideWithValue(Random(1))],
  );
  addTearDown(container.dispose);
  container
      .read(matchControllerProvider.notifier)
      .startMatch(
        catalog,
        humanDeck: PlayerDeck(
          cards: human,
          initialEffect: effectOf(catalog, humanKind),
        ),
        systemDeck: PlayerDeck(
          cards: system,
          initialEffect: effectOf(catalog, systemKind),
        ),
        shuffle: false,
      );
  return container;
}

/// El estado actual de la partida de [container].
MatchViewState viewOf(ProviderContainer container) =>
    container.read(matchControllerProvider)!;

/// El controlador de la partida de [container].
MatchController controllerOf(ProviderContainer container) =>
    container.read(matchControllerProvider.notifier);

/// Da por vistos todos los eventos pendientes (cartas reveladas, etc.),
/// como si el estudiante los hubiera mirado.
void skipEvents(ProviderContainer container) {
  while (viewOf(container).events.isNotEmpty) {
    controllerOf(container).dismissEvent();
  }
}
