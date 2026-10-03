import 'package:game_engine/game_engine.dart';
import 'package:test/test.dart';

import '../fixtures/cards.dart';
import '../fixtures/match_helpers.dart';

/// Partida en la que cada jugador tiene el Initial Effect indicado.
GameMatch matchWith(InitialEffectKind one, InitialEffectKind two) => matchOf(
  [common('Wolf', wild, 3)],
  [common('Rock', warrior, 1)],
  oneEffect: initialEffectOf(one),
  twoEffect: initialEffectOf(two),
);

void main() {
  group('active ability of the Initial Effect', () {
    test('is the own one when the card has an active ability', () {
      final match = matchWith(
        InitialEffectKind.leadership,
        InitialEffectKind.diversity,
      );

      expect(match.activeKindOf(Player.one), InitialEffectKind.leadership);
      expect(match.activeKindOf(Player.two), isNull);
    });

    test('Responsibility has both a passive and an active ability', () {
      final match = matchWith(
        InitialEffectKind.responsibility,
        InitialEffectKind.respect,
      );

      expect(match.activeKindOf(Player.one), InitialEffectKind.responsibility);
    });

    test('Empathy copies the active ability of the rival', () {
      final match = matchWith(
        InitialEffectKind.empathy,
        InitialEffectKind.kindness,
      );

      expect(match.activeKindOf(Player.one), InitialEffectKind.kindness);
      expect(match.activeKindOf(Player.two), InitialEffectKind.kindness);
    });

    test('Empathy copies nothing if the rival has only a passive ability', () {
      final match = matchWith(
        InitialEffectKind.empathy,
        InitialEffectKind.justice,
      );

      expect(match.activeKindOf(Player.one), isNull);
    });

    test('Empathy copies nothing if both players have Empathy', () {
      final match = matchWith(
        InitialEffectKind.empathy,
        InitialEffectKind.empathy,
      );

      expect(match.activeKindOf(Player.one), isNull);
      expect(match.activeKindOf(Player.two), isNull);
    });
  });

  group('checkUseInitialEffect', () {
    test('allows it during the play phase', () {
      final match = matchWith(
        InitialEffectKind.leadership,
        InitialEffectKind.diversity,
      )..revealCreatures();

      expect(match.checkUseInitialEffect(Player.one), isNull);
      expect(match.hasUsedActive(Player.one), isFalse);
    });

    test('rejects it outside the play phase', () {
      final match = matchWith(
        InitialEffectKind.leadership,
        InitialEffectKind.diversity,
      );

      expect(
        match.checkUseInitialEffect(Player.one),
        InvalidPlayReason.wrongPhase,
      );
    });

    test('rejects it if the card has no active ability', () {
      final match = matchWith(
        InitialEffectKind.leadership,
        InitialEffectKind.diversity,
      )..revealCreatures();

      expect(
        match.checkUseInitialEffect(Player.two),
        InvalidPlayReason.noActiveAbility,
      );
    });
  });
}
