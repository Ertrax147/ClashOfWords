import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/shared_prefs_deck_repository.dart';
import 'domain/deck_repository.dart';
import 'domain/saved_deck.dart';

/// Repositorio de mazos que usa la app. Los tests pueden reemplazarlo.
final deckRepositoryProvider = Provider<DeckRepository>(
  (ref) => const SharedPrefsDeckRepository(),
);

/// Id del mazo activo (el que se usa para jugar), o `null` si no hay. Se
/// vuelve a leer con `ref.invalidate` al cambiarlo.
final activeDeckIdProvider = FutureProvider.autoDispose<String?>(
  (ref) => ref.watch(deckRepositoryProvider).loadActiveId(),
);

/// Mazos guardados. Se vuelve a leer con `ref.invalidate` después de guardar
/// o borrar uno.
final savedDecksProvider = FutureProvider.autoDispose<List<SavedDeck>>(
  (ref) => ref.watch(deckRepositoryProvider).loadAll(),
);
