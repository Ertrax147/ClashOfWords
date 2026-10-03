import 'dart:convert';

import 'package:game_engine/game_engine.dart';

import '../../domain/card_catalog.dart';

/// Versión del formato de `cards.json` que entiende la app.
const catalogFormatVersion = 1;

/// Lee el catálogo completo desde el texto de `cards.json`.
///
/// Las imágenes se buscan en [imageFolder], con el id de cada carta como
/// nombre de archivo (`<id>.jpg`). Lanza un [FormatException] si el formato
/// no es válido.
CardCatalog parseCatalog(String source, {required String imageFolder}) {
  final json = jsonDecode(source);
  if (json is! Map<String, dynamic>) {
    throw const FormatException('The catalog must be a JSON object');
  }
  if (json['version'] != catalogFormatVersion) {
    throw FormatException('Unsupported catalog version: ${json['version']}');
  }
  final cards = json['cards'];
  if (cards is! List) {
    throw const FormatException('The catalog must have a list of cards');
  }
  return CardCatalog([
    for (final card in cards)
      CardModel.fromJson(card as Map<String, dynamic>).toEntry(imageFolder),
  ]);
}

/// Carta tal como viene en `cards.json`, convertida a una carta del motor.
///
/// Es la capa de datos de clean architecture: sabe leer el formato del
/// archivo. El motor solo recibe la [GameCard] ya construida.
class CardModel {
  const CardModel._(this.card);

  /// Lee una carta desde su objeto JSON.
  ///
  /// Lanza un [FormatException] con el id de la carta si algún campo falta
  /// o no es válido.
  factory CardModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    try {
      return CardModel._(_cardFrom(json));
    } on FormatException catch (error) {
      throw FormatException('Card "$id": ${error.message}');
    } on ArgumentError catch (error) {
      throw FormatException('Card "$id": ${error.message}');
    } on TypeError {
      throw FormatException('Card "$id": a field has the wrong type');
    }
  }

  /// Carta del motor.
  final GameCard card;

  /// Entrada del catálogo con la imagen que corresponde en [imageFolder].
  CatalogEntry toEntry(String imageFolder) =>
      CatalogEntry(card: card, imageAsset: '$imageFolder/${card.id}.jpg');

  static GameCard _cardFrom(Map<String, dynamic> json) {
    final id = json['id'] as String;
    final name = json['name'] as String;
    return switch (json['type']) {
      'creature' => Creature(
        id: id,
        name: name,
        rarity: _rarity(json['rarity']),
        cardClass: CardClass(json['class'] as String),
        power: json['power'] as int,
        duration: _duration(json['duration']) ?? ClashDuration.one,
        abilities: _abilities(json['abilities']),
      ),
      'item' => Item(
        id: id,
        name: name,
        rarity: _rarity(json['rarity']),
        classes: _classes(json['classes']),
        powerBonus: json['powerBonus'] as int,
        grantedRarity: _optionalRarity(json['grantedRarity']),
        grantedDuration: _duration(json['grantedDuration']),
        forbiddenRarities: {
          for (final rarity in (json['forbiddenRarities'] as List?) ?? [])
            _rarity(rarity),
        },
      ),
      'effect' => Effect(
        id: id,
        name: name,
        rarity: _rarity(json['rarity']),
        duration: _duration(json['duration'])!,
        abilities: _abilities(json['abilities']),
      ),
      'initialEffect' => InitialEffect(
        id: id,
        name: name,
        kind: InitialEffectKind.values.byName(json['kind'] as String),
      ),
      final type => throw FormatException('Unknown card type: $type'),
    };
  }

  static Rarity _rarity(Object? value) => Rarity.values.byName(value as String);

  static Rarity? _optionalRarity(Object? value) =>
      value == null ? null : _rarity(value);

  /// Lee una Duration: un número de Clashes o `"infinite"`.
  static ClashDuration? _duration(Object? value) => switch (value) {
    null => null,
    'infinite' => ClashDuration.infinite,
    final int clashes => ClashDuration(clashes),
    _ => throw FormatException('Invalid duration: $value'),
  };

  static Set<CardClass> _classes(Object? value) => {
    for (final name in (value as List?) ?? []) CardClass(name as String),
  };

  static List<Ability> _abilities(Object? value) => [
    for (final ability in (value as List?) ?? [])
      _ability(ability as Map<String, dynamic>),
  ];

  static Ability _ability(Map<String, dynamic> json) {
    CreatureFilter filter() => CreatureFilter(
      classes: _classes(json['classes']),
      rarities: {
        for (final rarity in (json['rarities'] as List?) ?? []) _rarity(rarity),
      },
    );

    return switch (json['type']) {
      'statModifier' => StatModifier(
        target: AbilityTarget.values.byName(json['target'] as String),
        filter: filter(),
        powerDelta: (json['power'] as int?) ?? 0,
        rarity: _optionalRarity(json['rarity']),
        addedClass: json['addedClass'] == null
            ? null
            : CardClass(json['addedClass'] as String),
      ),
      'discardEnemyCreatures' => DiscardEnemyCreatures(filter()),
      'forbidEnemyPlays' => ForbidEnemyPlays(
        items: (json['items'] as bool?) ?? false,
        effects: (json['effects'] as bool?) ?? false,
      ),
      final type => throw FormatException('Unknown ability type: $type'),
    };
  }
}
