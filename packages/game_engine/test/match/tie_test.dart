import 'package:game_engine/game_engine.dart';
import 'package:test/test.dart';

import '../fixtures/cards.dart';
import '../fixtures/match_helpers.dart';

// Light Phoenix y Elder Angel son ambas Legendary y Magical, así que siempre
// empatan. Se usan para provocar un Tie.

void main() {
  group('a tie', () {
    test('sets both creatures aside and asks for new ones', () {
      final match = matchOf(
        [lightPhoenix, spearStatue],
        [elderAngel, meditatingBrush],
      );

      expect(playClash(match), const ClashTie(TieReason.sameClass));

      expect(match.phase, MatchPhase.reveal);
      expect(match.hasPendingTie, isTrue);
      expect(names(match.area(Player.one).tiedCards), ['Light Phoenix']);
      expect(names(match.area(Player.two).tiedCards), ['Elder Angel']);
      expect(match.area(Player.one).creatureInPlay, isNull);
      expect(match.area(Player.two).creatureInPlay, isNull);
    });

    test('sets creatures aside even with duration left', () {
      // Light Phoenix (Duration 4) y Elder Angel (Duration 5) no siguen
      // peleando: ambos jugadores revelan una Creature nueva.
      final match = matchOf(
        [lightPhoenix, spearStatue],
        [elderAngel, meditatingBrush],
      );
      playClash(match);

      final revealed = match.revealCreatures();

      expect(names(revealed[Player.one]!), ['Spear Statue']);
      expect(names(revealed[Player.two]!), ['Meditating Brush']);
    });
  });

  group('the clash after a tie', () {
    test('its winner also wins the tied clash', () {
      // Tie entre Light Phoenix y Elder Angel. Luego Spear Statue
      // (Uncommon) vence a Meditating Brush (Common).
      final match = matchOf(
        [lightPhoenix, spearStatue],
        [elderAngel, meditatingBrush],
      );
      playClash(match);

      expect(
        playClash(match),
        const ClashWin(ClashSide.first, WinReason.rarity),
      );

      expect(names(match.area(Player.one).trophyStack), [
        'Meditating Brush',
        'Elder Angel',
      ]);
      expect(names(match.area(Player.one).discardStack), [
        'Light Phoenix',
        'Spear Statue',
      ]);
      expect(match.area(Player.two).trophyStack, isEmpty);
      expect(match.hasPendingTie, isFalse);
    });

    test('the items of the tied creatures go with them', () {
      // Light Phoenix con Diamond Sword sigue empatando con Elder Angel:
      // misma Rarity y misma Class. Luego gana el jugador dos.
      final match = matchOf(
        [diamondSword, lightPhoenix, meditatingBrush],
        [elderAngel, spearStatue],
      )..revealCreatures();
      match.equipItem(Player.one, itemInHand(match, Player.one));
      match.resolveClash();

      expect(names(match.area(Player.one).tiedCards), [
        'Light Phoenix',
        'Diamond Sword',
      ]);

      playClash(match);

      expect(names(match.area(Player.two).trophyStack), [
        'Meditating Brush',
        'Light Phoenix',
        'Diamond Sword',
      ]);
    });

    test('its winner keeps its own duration', () {
      // Tras el Tie, Unicorn Queen (Duration 4) vence a Pumpkin Planet. Las
      // empatadas se reparten, pero Unicorn Queen sigue en la mesa.
      final match = matchOf(
        [lightPhoenix, unicornQueen],
        [elderAngel, pumpkinPlanet],
      );
      playClash(match);
      playClash(match);

      final inPlay = match.area(Player.one).creatureInPlay!;
      expect(inPlay.creature.card, unicornQueen);
      expect(inPlay.remaining, ClashDuration(3));
      expect(names(match.area(Player.one).discardStack), ['Light Phoenix']);
      expect(names(match.area(Player.one).trophyStack), [
        'Pumpkin Planet',
        'Elder Angel',
      ]);
    });
  });

  group('chained ties', () {
    test('accumulate until a clash has a winner, who takes them all', () {
      final match = matchOf(
        [lightPhoenix, spearStatue, meditatingBrush, unicornQueen],
        [elderAngel, spearStatue, meditatingBrush, writingTractor],
      );

      // Tres Ties seguidos: misma Rarity y misma Class en cada uno.
      for (var i = 0; i < 3; i++) {
        expect(playClash(match), isA<ClashTie>());
        expect(match.hasPendingTie, isTrue);
      }
      expect(match.area(Player.two).tiedCards, hasLength(3));

      // Unicorn Queen (Legendary) vence a Writing Tractor (Uncommon).
      expect(playClash(match), isA<ClashWin>());

      expect(names(match.area(Player.one).trophyStack), [
        'Writing Tractor',
        'Elder Angel',
        'Spear Statue',
        'Meditating Brush',
      ]);
      expect(names(match.area(Player.one).discardStack), [
        'Light Phoenix',
        'Spear Statue',
        'Meditating Brush',
      ]);
      expect(match.hasPendingTie, isFalse);
    });
  });

  group('a tie that cannot be resolved', () {
    test('returns the tied creatures to their owners and ends the match', () {
      final match = matchOf([lightPhoenix], [elderAngel]);
      playClash(match);

      match.revealCreatures();

      expect(match.phase, MatchPhase.finished);
      expect(names(match.area(Player.one).discardStack), ['Light Phoenix']);
      expect(names(match.area(Player.two).discardStack), ['Elder Angel']);
      expect(match.result.isDraw, isTrue);
      expect(match.result.trophiesOfOne, 0);
    });

    test('nobody gets trophies when only one player runs out', () {
      final match = matchOf([lightPhoenix, spearStatue], [elderAngel]);
      playClash(match);

      match.revealCreatures();

      expect(match.phase, MatchPhase.finished);
      expect(
        names(match.area(Player.one).discardStack),
        unorderedEquals(['Light Phoenix', 'Spear Statue']),
      );
      expect(names(match.area(Player.two).discardStack), ['Elder Angel']);
      expect(match.area(Player.one).trophyStack, isEmpty);
      expect(match.area(Player.two).trophyStack, isEmpty);
    });
  });
}
