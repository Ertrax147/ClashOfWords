import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_engine/game_engine.dart';

import '../../catalog/domain/card_catalog.dart';
import '../domain/saved_deck.dart';

/// Mazo que el estudiante está armando en el Deck Builder (RF-03).
///
/// No deja pasar de [DeckRules.maxCopies] copias de una carta ni de
/// [DeckRules.maxCards] cartas, y explica por qué; lo que falta para llegar
/// al mínimo se explica en la pantalla, y guardar solo se permite con un mazo
/// válido.
class DeckBuilderController extends Notifier<SavedDeck> {
  @override
  SavedDeck build() => SavedDeck(id: _newId());

  /// Agrega una copia de [card]. Si es un Initial Effect, pasa a ser el del
  /// mazo en vez de entrar al Deck.
  ///
  /// Devuelve un mensaje en inglés si no se pudo agregar, para mostrárselo al
  /// estudiante; `null` si se agregó.
  String? add(GameCard card) {
    if (card is InitialEffect) {
      state = state.copyWith(initialEffectId: card.id);
      return null;
    }
    if (state.copiesOf(card.id) >= DeckRules.maxCopies) {
      return 'You can have at most ${DeckRules.maxCopies} copies of '
          '${card.name}.';
    }
    if (state.cardCount >= DeckRules.maxCards) {
      return 'Your deck is full: it can have at most ${DeckRules.maxCards} '
          'cards. Remove one to add another.';
    }
    state = state.withCopies(card.id, state.copiesOf(card.id) + 1);
    return null;
  }

  /// Quita una copia de [card]. Si es un Initial Effect, lo quita del mazo.
  void remove(GameCard card) {
    if (card is InitialEffect) {
      if (state.initialEffectId == card.id) {
        state = state.copyWith(clearInitialEffect: true);
      }
      return;
    }
    state = state.withCopies(card.id, state.copiesOf(card.id) - 1);
  }

  /// Cambia el nombre del mazo.
  void rename(String name) => state = state.copyWith(name: name);

  /// Sigue armando un mazo que ya estaba guardado.
  void load(SavedDeck deck) => state = deck;

  /// Reemplaza el mazo en construcción por un mazo inicial al azar (ver
  /// [starterDeck]), que el estudiante puede seguir editando.
  void loadStarter(CardCatalog catalog, Random random) =>
      state = starterSavedDeck(catalog, random, _newId());

  /// Empieza un mazo vacío.
  void clear() => state = SavedDeck(id: _newId());

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();
}

/// Mazo en construcción del Deck Builder.
final deckBuilderProvider = NotifierProvider<DeckBuilderController, SavedDeck>(
  DeckBuilderController.new,
);

/// Explica en inglés, para el estudiante, qué regla del mazo no se cumple.
String explainDeckIssue(DeckIssue issue) => switch (issue) {
  TooFewCards(:final count, :final missing) =>
    'Your deck has $count cards. It needs at least ${DeckRules.minCards}: '
        'add $missing more.',
  TooManyCards(:final count, :final excess) =>
    'Your deck has $count cards. It can have at most ${DeckRules.maxCards}: '
        'remove $excess.',
  TooManyCopies(:final card, :final copies) =>
    'You can have at most ${DeckRules.maxCopies} copies of ${card.name} '
        '(you have $copies).',
  MissingInitialEffect() => 'Choose an Initial Effect.',
};
