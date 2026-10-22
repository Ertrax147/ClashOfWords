import 'package:game_engine/game_engine.dart';

import '../../catalog/domain/card_catalog.dart';

/// Initial Effects que el equipo todavía no decide cómo funcionan (ver
/// `CLAUDE.md`). El Deck Builder no deja elegirlos.
const undecidedInitialEffects = {
  InitialEffectKind.diversity,
  InitialEffectKind.honesty,
  InitialEffectKind.generosity,
  InitialEffectKind.creativity,
};

/// Si el estudiante puede elegir [effect] como Initial Effect de su mazo.
bool isSelectableInitialEffect(InitialEffect effect) =>
    !undecidedInitialEffects.contains(effect.kind);

/// Mazo armado por el estudiante, tal como se guarda en la tablet (RF-03).
///
/// Guarda ids de cartas y no las cartas mismas, para que el catálogo pueda
/// actualizarse sin invalidar los mazos guardados.
class SavedDeck {
  /// Crea un mazo con el identificador [id].
  ///
  /// [copies] dice cuántas copias hay de cada carta, por id, sin contar el
  /// Initial Effect.
  const SavedDeck({
    required this.id,
    this.name = '',
    this.copies = const {},
    this.initialEffectId,
  });

  /// Identificador único del mazo.
  final String id;

  /// Nombre que le puso el estudiante; puede estar vacío.
  final String name;

  /// Copias de cada carta del Deck, por id de carta.
  final Map<String, int> copies;

  /// Id del Initial Effect elegido, o `null` si todavía no hay ninguno.
  final String? initialEffectId;

  /// Cantidad de cartas del Deck, sin contar el Initial Effect.
  int get cardCount => copies.values.fold(0, (sum, count) => sum + count);

  /// Copias que hay de la carta con este [cardId].
  int copiesOf(String cardId) => copies[cardId] ?? 0;

  /// Copia el mazo con otro nombre y otro Initial Effect.
  ///
  /// [clearInitialEffect] quita el Initial Effect.
  SavedDeck copyWith({
    String? name,
    String? initialEffectId,
    bool clearInitialEffect = false,
  }) => SavedDeck(
    id: id,
    name: name ?? this.name,
    copies: copies,
    initialEffectId: clearInitialEffect
        ? null
        : (initialEffectId ?? this.initialEffectId),
  );

  /// Copia el mazo con [count] copias de la carta [cardId]. Con cero o menos
  /// la carta sale del mazo.
  SavedDeck withCopies(String cardId, int count) {
    final updated = Map<String, int>.of(copies);
    if (count <= 0) {
      updated.remove(cardId);
    } else {
      updated[cardId] = count;
    }
    return SavedDeck(
      id: id,
      name: name,
      copies: updated,
      initialEffectId: initialEffectId,
    );
  }

  /// Las cartas del Deck según el [catalog], con las copias repetidas. Las
  /// que ya no están en el catálogo se omiten.
  List<GameCard> cardsIn(CardCatalog catalog) => [
    for (final entry in copies.entries)
      if (catalog.byId(entry.key) case final found?)
        for (var i = 0; i < entry.value; i++) found.card,
  ];

  /// El Initial Effect elegido según el [catalog], o `null` si no hay o ya no
  /// está en el catálogo.
  InitialEffect? initialEffectIn(CardCatalog catalog) {
    final id = initialEffectId;
    if (id == null) return null;
    final card = catalog.byId(id)?.card;
    return card is InitialEffect ? card : null;
  }

  /// Reglas de RF-03 que el mazo no cumple según el [catalog].
  List<DeckIssue> issuesIn(CardCatalog catalog) => validateDeck(
    cards: cardsIn(catalog),
    initialEffect: initialEffectIn(catalog),
  );
}
