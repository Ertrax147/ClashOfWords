import 'package:game_engine/game_engine.dart';

// Cartas reales del juego para usar en los tests. Los valores son los
// impresos en cada carta.

final builder = CardClass('Builder');
final cosmic = CardClass('Cosmic');
final foodie = CardClass('Foodie');
final magical = CardClass('Magical');
final secret = CardClass('Secret');
final smart = CardClass('Smart');
final warrior = CardClass('Warrior');
final wild = CardClass('Wild');

// Creatures

final meditatingBrush = Creature(
  id: 'meditating-brush',
  name: 'Meditating Brush',
  rarity: Rarity.common,
  cardClass: smart,
  power: 2,
);

final writingTractor = Creature(
  id: 'writing-tractor',
  name: 'Writing Tractor',
  rarity: Rarity.uncommon,
  cardClass: builder,
  power: 5,
);

final spearStatue = Creature(
  id: 'spear-statue',
  name: 'Spear Statue',
  rarity: Rarity.uncommon,
  cardClass: warrior,
  power: 9,
);

final raspberryGrenade = Creature(
  id: 'raspberry-grenade',
  name: 'Raspberry Grenade',
  rarity: Rarity.uncommon,
  cardClass: foodie,
  power: 9,
);

final luminousMushrooms = Creature(
  id: 'luminous-mushrooms',
  name: 'Luminous Mushrooms',
  rarity: Rarity.rare,
  cardClass: wild,
  power: 3,
  duration: ClashDuration(3),
);

final pumpkinPlanet = Creature(
  id: 'pumpkin-planet',
  name: 'Pumpkin Planet',
  rarity: Rarity.epic,
  cardClass: cosmic,
  power: 9,
  duration: ClashDuration(2),
);

final unicornQueen = Creature(
  id: 'unicorn-queen',
  name: 'Unicorn Queen',
  rarity: Rarity.legendary,
  cardClass: wild,
  power: 8,
  duration: ClashDuration(4),
);

final elderAngel = Creature(
  id: 'elder-angel',
  name: 'Elder Angel',
  rarity: Rarity.legendary,
  cardClass: magical,
  power: 0,
  duration: ClashDuration(5),
);

final lightPhoenix = Creature(
  id: 'light-phoenix',
  name: 'Light Phoenix',
  rarity: Rarity.legendary,
  cardClass: magical,
  power: 7,
  duration: ClashDuration(4),
);

final galaxyDragon = Creature(
  id: 'galaxy-dragon',
  name: 'Galaxy Dragon',
  rarity: Rarity.legendary,
  cardClass: cosmic,
  power: 9,
  duration: ClashDuration(3),
);

// Items

final invisibleCoat = Item(
  id: 'invisible-coat',
  name: 'Invisible Coat',
  rarity: Rarity.rare,
  classes: {magical, secret},
  powerBonus: 0,
  grantedRarity: Rarity.rare,
  grantedDuration: ClashDuration(3),
);

final fireAxe = Item(
  id: 'fire-axe',
  name: 'Fire Axe',
  rarity: Rarity.epic,
  powerBonus: 5,
  grantedRarity: Rarity.epic,
);

final diamondSword = Item(
  id: 'diamond-sword',
  name: 'Diamond Sword',
  rarity: Rarity.legendary,
  powerBonus: 9,
  grantedRarity: Rarity.legendary,
  grantedDuration: ClashDuration(2),
);

final ancientPan = Item(
  id: 'ancient-pan',
  name: 'Ancient Pan',
  rarity: Rarity.epic,
  powerBonus: 5,
  grantedDuration: ClashDuration(3),
);

final flagsJacket = Item(
  id: 'flags-jacket',
  name: 'Flags Jacket',
  rarity: Rarity.uncommon,
  classes: {CardClass('Traveler'), CardClass('Usual')},
  powerBonus: 4,
);

final economic = CardClass('Economic');
final social = CardClass('Social');
final artist = CardClass('Artist');

final relaxingMarkers = Creature(
  id: 'relaxing-markers',
  name: 'Relaxing Markers',
  rarity: Rarity.common,
  cardClass: artist,
  power: 3,
);

final universesEye = Creature(
  id: 'universes-eye',
  name: "Universe's Eye",
  rarity: Rarity.legendary,
  cardClass: cosmic,
  power: 9,
  duration: ClashDuration(2),
  abilities: [ForbidEnemyPlays(effects: true)],
);

final galaxyDragonWithAbility = Creature(
  id: 'galaxy-dragon',
  name: 'Galaxy Dragon',
  rarity: Rarity.legendary,
  cardClass: cosmic,
  power: 9,
  duration: ClashDuration(3),
  abilities: [ForbidEnemyPlays(items: true)],
);

final giftOfEternity = Item(
  id: 'gift-of-eternity',
  name: 'Gift of Eternity',
  rarity: Rarity.legendary,
  powerBonus: 0,
  grantedDuration: ClashDuration.infinite,
  forbiddenRarities: {Rarity.legendary},
);

// Effects

final huggingHospital = Effect(
  id: 'hugging-hospital',
  name: 'Hugging Hospital',
  rarity: Rarity.rare,
  duration: ClashDuration(5),
  abilities: [StatModifier(target: AbilityTarget.own, powerDelta: 2)],
);

final closetBuilding = Effect(
  id: 'closet-building',
  name: 'Closet Building',
  rarity: Rarity.common,
  duration: ClashDuration(2),
  abilities: [
    StatModifier(
      target: AbilityTarget.own,
      filter: CreatureFilter(classes: {economic}),
      powerDelta: 3,
    ),
  ],
);

final uglyTheater = Effect(
  id: 'ugly-theater',
  name: 'Ugly Theater',
  rarity: Rarity.common,
  duration: ClashDuration(1),
  abilities: [
    DiscardEnemyCreatures(CreatureFilter(classes: {artist})),
  ],
);

final orangeStars = Effect(
  id: 'orange-stars',
  name: 'Orange Stars',
  rarity: Rarity.legendary,
  duration: ClashDuration(4),
  abilities: [
    StatModifier(target: AbilityTarget.own, rarity: Rarity.legendary),
  ],
);

final classroomCleaning = Effect(
  id: 'classroom-cleaning',
  name: 'Classroom Cleaning',
  rarity: Rarity.uncommon,
  duration: ClashDuration(3),
  abilities: [
    StatModifier(
      target: AbilityTarget.own,
      filter: CreatureFilter(
        classes: {smart, social},
        rarities: {Rarity.common},
      ),
      rarity: Rarity.uncommon,
    ),
  ],
);

// Initial Effects

final loyalty = InitialEffect(id: 'loyalty', name: 'Loyalty');
final respect = InitialEffect(id: 'respect', name: 'Respect');
