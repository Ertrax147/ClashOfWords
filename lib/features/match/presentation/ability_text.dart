import 'package:game_engine/game_engine.dart';

/// Nombre en inglés del Initial Effect, tal como aparece en su carta.
String initialEffectName(InitialEffectKind kind) =>
    kind.name[0].toUpperCase() + kind.name.substring(1);

/// Texto en inglés de la habilidad activa de [kind], para explicársela al
/// estudiante antes de usarla.
///
/// Es la traducción al inglés del texto de la carta; la interfaz va
/// íntegramente en inglés.
String activeAbilityText(InitialEffectKind kind) => switch (kind) {
  InitialEffectKind.recycle =>
    'Move a Creature from your Discard Stack to your Deck. '
        'Then shuffle your Deck.',
  InitialEffectKind.responsibility =>
    'Move an Item from your Discard Stack to your Deck. '
        'Then shuffle your Deck.',
  InitialEffectKind.loyalty =>
    "Move a Creature from your opponent's Trophy Stack to your Discard Stack.",
  InitialEffectKind.leadership => 'Your Creature gets Duration: 3 Clashes.',
  InitialEffectKind.kindness =>
    "Move the top card of your opponent's Deck to your Trophy Stack.",
  InitialEffectKind.honesty =>
    "Look at the top 3 cards of your Deck and of your opponent's Deck. "
        'Then put them back in any order.',
  InitialEffectKind.generosity =>
    "Take control of one of your opponent's Items or Effects.",
  InitialEffectKind.creativity =>
    'Search your Deck for a Creature and play it. Then shuffle your Deck.',
  InitialEffectKind.commitment =>
    "Win a Clash you lost. Then move a Creature from your Trophy Stack to "
        "your opponent's Discard Stack. This ability cannot be countered.",
  _ => '',
};

/// Texto del selector de cartas de [kind]: qué carta hay que elegir.
String pickCardText(InitialEffectKind kind) => switch (kind) {
  InitialEffectKind.recycle =>
    'Choose a Creature from your Discard Stack to put back in your Deck.',
  InitialEffectKind.responsibility =>
    'Choose an Item from your Discard Stack to put back in your Deck.',
  InitialEffectKind.loyalty =>
    'Choose one of your Creatures from your opponent\'s Trophy Stack.',
  InitialEffectKind.generosity =>
    "Choose one of your opponent's Items or Effects to take.",
  InitialEffectKind.creativity =>
    'Choose a Creature from your Deck to play instead of yours.',
  InitialEffectKind.commitment =>
    "Choose a Creature from your Trophy Stack to send to your opponent's "
        'Discard Stack.',
  _ => '',
};
