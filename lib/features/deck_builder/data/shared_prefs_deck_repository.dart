import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/deck_repository.dart';
import '../domain/saved_deck.dart';

/// Guarda los mazos en la tablet con `shared_preferences`, sin conexión.
class SharedPrefsDeckRepository implements DeckRepository {
  /// Crea el repositorio.
  const SharedPrefsDeckRepository();

  static const _key = 'saved_decks';
  static const _activeKey = 'active_deck_id';

  @override
  Future<List<SavedDeck>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return const [];
    try {
      return [
        for (final json in jsonDecode(raw) as List<dynamic>)
          _fromJson(json as Map<String, dynamic>),
      ];
    } on Object {
      // Datos dañados: se parte de cero en vez de dejar la app sin mazos.
      return const [];
    }
  }

  @override
  Future<void> save(SavedDeck deck) async {
    final decks = await loadAll();
    final index = decks.indexWhere((saved) => saved.id == deck.id);
    await _write([
      for (var i = 0; i < decks.length; i++) i == index ? deck : decks[i],
      if (index == -1) deck,
    ]);
  }

  @override
  Future<void> delete(String id) async {
    final decks = await loadAll();
    await _write([
      for (final deck in decks)
        if (deck.id != id) deck,
    ]);
    if (await loadActiveId() == id) await saveActiveId(null);
  }

  @override
  Future<String?> loadActiveId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_activeKey);
  }

  @override
  Future<void> saveActiveId(String? id) async {
    final prefs = await SharedPreferences.getInstance();
    if (id == null) {
      await prefs.remove(_activeKey);
    } else {
      await prefs.setString(_activeKey, id);
    }
  }

  Future<void> _write(List<SavedDeck> decks) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(decks.map(_toJson).toList()));
  }

  Map<String, dynamic> _toJson(SavedDeck deck) => {
    'id': deck.id,
    'name': deck.name,
    'copies': deck.copies,
    'initialEffectId': deck.initialEffectId,
  };

  SavedDeck _fromJson(Map<String, dynamic> json) => SavedDeck(
    id: json['id'] as String,
    name: json['name'] as String? ?? '',
    copies: (json['copies'] as Map<String, dynamic>).map(
      (id, count) => MapEntry(id, count as int),
    ),
    initialEffectId: json['initialEffectId'] as String?,
  );
}
