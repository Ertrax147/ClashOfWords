import 'dart:math';

import '../entities/ability.dart';
import '../entities/card_class.dart';
import '../entities/game_card.dart';
import '../match/game_match.dart';
import 'random_deck.dart';

/// Cartas de cada tipo (Creatures, Items y Effects) en un mazo inicial: 21
/// cartas, la misma cantidad de cada tipo.
const int starterCardsPerType = 7;

/// Arma el mazo inicial de un estudiante con las cartas de [pool].
///
/// Tiene [starterCardsPerType] Creatures, Items y Effects, más un Initial
/// Effect, todos al azar (así también lo es la Rarity). Los Items y Effects
/// van acordes a las Class de las Creatures elegidas: un Item sin Class sirve
/// para cualquiera, y un Effect sin Class específica es neutro. Respeta el
/// máximo de [DeckRules.maxCopies] copias de una misma carta.
///
/// Lanza un [ArgumentError] si [pool] no tiene suficientes cartas de algún
/// tipo.
PlayerDeck starterDeck(List<GameCard> pool, Random random) {
  final initialEffects = pool.whereType<InitialEffect>().toList();
  if (initialEffects.isEmpty) {
    throw ArgumentError('The pool has no initial effects');
  }

  final creatures = _pick(
    pool.whereType<Creature>().toList(),
    starterCardsPerType,
    random,
  );
  final classes = {for (final creature in creatures) creature.cardClass};
  final items = _pick(
    [
      for (final item in pool.whereType<Item>())
        if (item.isUniversal || item.classes.any(classes.contains)) item,
    ],
    starterCardsPerType,
    random,
  );
  final effects = _pick(
    [
      for (final effect in pool.whereType<Effect>())
        if (_fitsClasses(effect, classes)) effect,
    ],
    starterCardsPerType,
    random,
  );

  return PlayerDeck(
    cards: [...creatures, ...items, ...effects]..shuffle(random),
    initialEffect: initialEffects[random.nextInt(initialEffects.length)],
  );
}

/// Si [effect] va acorde a [classes]: no apunta a una Class específica de las
/// Creatures propias, o apunta a alguna de las que hay.
bool _fitsClasses(Effect effect, Set<CardClass> classes) {
  final targeted = [
    for (final ability in effect.abilities)
      if (ability is StatModifier &&
          ability.target == AbilityTarget.own &&
          ability.filter.classes.isNotEmpty)
        ability.filter.classes,
  ];
  return targeted.isEmpty ||
      targeted.any((wanted) => wanted.any(classes.contains));
}

/// Elige [count] cartas al azar de [options], sin pasar de
/// [DeckRules.maxCopies] copias de cada una.
List<T> _pick<T extends GameCard>(List<T> options, int count, Random random) {
  if (options.length * DeckRules.maxCopies < count) {
    throw ArgumentError('Not enough different cards to build a starter deck');
  }
  final copies = <String, int>{};
  final picked = <T>[];
  while (picked.length < count) {
    final card = options[random.nextInt(options.length)];
    final used = copies[card.id] ?? 0;
    if (used < DeckRules.maxCopies) {
      copies[card.id] = used + 1;
      picked.add(card);
    }
  }
  return picked;
}
