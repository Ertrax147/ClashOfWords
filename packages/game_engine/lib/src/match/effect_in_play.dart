import 'package:meta/meta.dart';

import '../entities/clash_duration.dart';
import '../entities/game_card.dart';
import 'match_card.dart';

/// Effect que un jugador jugó y sigue en juego.
///
/// Dura los Clashes que indica su carta, contando el Clash en que se jugó.
/// Al agotarse va al Discard Stack de su dueño.
final class EffectInPlay {
  /// Pone en juego a [effect].
  ///
  /// [order] indica en qué momento de la partida se jugó, para aplicar sus
  /// habilidades en orden.
  @internal
  EffectInPlay(this.effect, {required this.order})
    : _remaining = effect.card.duration;

  /// Copia del Effect que está en juego.
  final MatchCard<Effect> effect;

  /// Momento de la partida en que se jugó.
  final int order;

  ClashDuration? _remaining;

  /// Clashes que le quedan, contando el actual. Es `null` cuando se agotó.
  ClashDuration? get remaining => _remaining;

  /// Indica si ya se agotó.
  bool get isExhausted => _remaining == null;

  /// Descuenta un Clash. Se llama después de resolver cada Clash, incluidos
  /// los Ties.
  @internal
  void spendClash() {
    final remaining = _remaining;
    if (remaining != null) _remaining = remaining.afterClash();
  }
}
