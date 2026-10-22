import 'package:game_engine/game_engine.dart';

import 'ability_text.dart';

String _capitalize(String text) =>
    text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);

/// Une [parts] como en inglés: "a", "a and b", "a, b and c".
String _joinList(List<String> parts) => parts.length <= 1
    ? parts.join()
    : '${parts.sublist(0, parts.length - 1).join(', ')} and ${parts.last}';

/// Tipo de la carta, como se muestra en la vista ampliada.
String cardTypeLabel(GameCard card) => switch (card) {
  Creature() => 'Creature',
  Item() => 'Item',
  Effect() => 'Effect',
  InitialEffect() => 'Initial Effect',
};

/// Rarity impresa en la carta. Los Initial Effects son siempre *Value*.
String cardRarityLabel(GameCard card) => switch (card) {
  Creature(:final rarity) => _capitalize(rarity.name),
  Item(:final rarity) => _capitalize(rarity.name),
  Effect(:final rarity) => _capitalize(rarity.name),
  InitialEffect() => 'Value',
};

/// Duration en inglés: "1 Clash", "3 Clashes" o "Infinite".
String durationText(ClashDuration duration) => duration.isInfinite
    ? 'Infinite'
    : duration.clashes == 1
    ? '1 Clash'
    : '${duration.clashes} Clashes';

/// Datos de la carta para la vista ampliada, como pares nombre-valor.
List<(String, String)> cardFacts(GameCard card) => switch (card) {
  Creature(:final cardClass, :final power, :final duration) => [
    ('Class', cardClass.name),
    ('Power', '$power'),
    if (duration != ClashDuration.one) ('Duration', durationText(duration)),
  ],
  Item(:final classes, :final powerBonus) => [
    (
      'Class',
      classes.isEmpty
          ? 'Any'
          : (classes.map((c) => c.name).toList()..sort()).join(', '),
    ),
    if (powerBonus > 0) ('Power', '+$powerBonus'),
  ],
  Effect(:final duration) => [('Duration', durationText(duration))],
  InitialEffect() => const [],
};

/// Texto de la habilidad pasiva de [kind], o vacío si no tiene.
String passiveAbilityText(InitialEffectKind kind) => switch (kind) {
  InitialEffectKind.diversity =>
    'Your first Creature of each Class gets +2 Power.',
  InitialEffectKind.tolerance =>
    'Your first 3 defeated Creatures go to your Discard Stack instead of '
        "your opponent's Trophy Stack.",
  InitialEffectKind.responsibility => 'Your Creatures can use multiple Items.',
  InitialEffectKind.respect =>
    'You win every Class tie if your Creature wins by Power.',
  InitialEffectKind.justice =>
    'Your next Creature gets +1 Power for each Clash you lost before. '
        'It resets when you win a Clash.',
  InitialEffectKind.friendship => 'If you tie, your next Creature gets +3.',
  InitialEffectKind.excellence =>
    'If you win a Clash, your next Creature gets +1.',
  InitialEffectKind.empathy => "Copy your opponent's Initial Effect ability.",
  _ => '',
};

/// Texto en inglés de una habilidad de Creature o Effect.
String abilityText(Ability ability) {
  String creatures(AbilityTarget target, CreatureFilter filter) {
    final qualifier = [
      if (filter.classes.isNotEmpty)
        _joinList((filter.classes.map((c) => c.name).toList()..sort())),
      if (filter.rarities.isNotEmpty)
        _joinList(filter.rarities.map((r) => _capitalize(r.name)).toList()),
    ].join(' ');
    final who = target == AbilityTarget.own ? 'Your' : 'Enemy';
    return [who, if (qualifier.isNotEmpty) qualifier, 'creatures'].join(' ');
  }

  return switch (ability) {
    StatModifier(
      :final target,
      :final filter,
      :final powerDelta,
      :final rarity,
      :final addedClass,
    ) =>
      '${creatures(target, filter)} get ${_joinList([if (powerDelta != 0) '${powerDelta > 0 ? '+' : ''}$powerDelta Power', if (rarity != null) _capitalize(rarity.name), if (addedClass != null) 'the ${addedClass.name} Class'])}.',
    DiscardEnemyCreatures(:final filter) =>
      'Move the ${creatures(AbilityTarget.enemy, filter).toLowerCase()} to '
          'the Discard Stack.',
    ForbidEnemyPlays(:final items, :final effects) =>
      'Your enemy cannot play ${items && effects
          ? 'Items or Effects'
          : items
          ? 'Items'
          : 'Effects'}.',
  };
}

/// Líneas de habilidad de la carta, para la vista ampliada: cada una ya
/// dice si es pasiva, activa o qué hace.
List<String> cardAbilityLines(GameCard card) => switch (card) {
  Creature(:final abilities) => [for (final a in abilities) abilityText(a)],
  Effect(:final abilities) => [for (final a in abilities) abilityText(a)],
  Item(
    :final grantedRarity,
    :final grantedDuration,
    :final forbiddenRarities,
  ) =>
    [
      if (grantedRarity != null)
        'Your Creature gets ${_capitalize(grantedRarity.name)}.',
      if (grantedDuration != null)
        'Your Creature gets Duration: ${durationText(grantedDuration)}.',
      if (forbiddenRarities.isNotEmpty)
        '${_joinList(forbiddenRarities.map((r) => _capitalize(r.name)).toList())} '
            'Creatures cannot use this Item.',
    ],
  InitialEffect(:final kind) => [
    if (passiveAbilityText(kind).isNotEmpty)
      'Passive: ${passiveAbilityText(kind)}',
    if (activeAbilityText(kind).isNotEmpty)
      'Active (once per match): ${activeAbilityText(kind)}',
  ],
};
