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
