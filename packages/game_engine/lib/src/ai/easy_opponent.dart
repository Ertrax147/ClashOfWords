import '../entities/game_card.dart';
import '../match/game_match.dart';
import '../match/match_card.dart';
import '../match/player.dart';

/// Jugada que hizo el rival del sistema, para mostrarla en la interfaz.
sealed class OpponentPlay {
  const OpponentPlay(this.card);

  /// Carta que jugó.
  final MatchCard card;
}

/// El rival equipó un Item a su Creature.
final class EquippedItem extends OpponentPlay {
  /// Crea la jugada de equipar [card].
  const EquippedItem(super.card);
}

/// El rival jugó un Effect.
final class PlayedEffect extends OpponentPlay {
  /// Crea la jugada de jugar [card].
  const PlayedEffect(super.card);
}

/// Rival del sistema en nivel Fácil (RF-15).
///
/// Usa sus Items y Effects cada vez que puede, sin estrategia: en cada
/// Clash equipa los Items que le permitan las reglas y juega todos sus
/// Effects. Todavía no usa las habilidades activas de su Initial Effect.
final class EasyOpponent {
  /// Crea el rival que controla al jugador [player].
  const EasyOpponent(this.player);

  /// Jugador que controla el sistema.
  final Player player;

  /// Juega las cartas de su Hand en el Clash actual de [match].
  ///
  /// Debe llamarse en la fase [MatchPhase.play]. Devuelve las jugadas que
  /// hizo, en orden. Si un Effect termina la partida (por ejemplo, porque el
  /// rival se queda sin Creatures), deja de jugar.
  List<OpponentPlay> playTurn(GameMatch match) {
    final plays = <OpponentPlay>[];
    for (final card in match.area(player).hand) {
      if (match.phase != MatchPhase.play) break;
      switch (card) {
        case MatchCard<Item>() when match.checkEquipItem(player, card) == null:
          match.equipItem(player, card);
          plays.add(EquippedItem(card));
        case MatchCard<Effect>()
            when match.checkPlayEffect(player, card) == null:
          match.playEffect(player, card);
          plays.add(PlayedEffect(card));
        default:
          break;
      }
    }
    return plays;
  }
}
