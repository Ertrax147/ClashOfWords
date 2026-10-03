import 'package:game_engine/game_engine.dart';

import 'cards.dart';

/// Conjunto de cartas variado para armar mazos al azar en los tests: tiene
/// Creatures de todas las Rarity, Items, Effects con todos los tipos de
/// habilidad e Initial Effects pasivos.
final List<GameCard> cardPool = [
  meditatingBrush,
  writingTractor,
  spearStatue,
  raspberryGrenade,
  luminousMushrooms,
  pumpkinPlanet,
  unicornQueen,
  elderAngel,
  lightPhoenix,
  galaxyDragonWithAbility,
  universesEye,
  relaxingMarkers,
  invisibleCoat,
  fireAxe,
  diamondSword,
  ancientPan,
  flagsJacket,
  giftOfEternity,
  huggingHospital,
  closetBuilding,
  uglyTheater,
  orangeStars,
  classroomCleaning,
  for (final kind in InitialEffectKind.values) initialEffectOf(kind),
];
