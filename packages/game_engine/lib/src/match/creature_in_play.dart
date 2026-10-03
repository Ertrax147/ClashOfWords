import 'package:meta/meta.dart';

import '../entities/clash_duration.dart';
import '../entities/game_card.dart';
import '../rules/clash_stats.dart';
import 'match_card.dart';

/// Creature que está en la mesa, con su Item equipado y la Duration que le
/// queda.
///
/// Una Creature entra en juego con la Duration impresa en su carta y la
/// descuenta en cada Clash en que participa. Mientras le queden Clashes,
/// sigue en la mesa y enfrenta a la siguiente Creature del rival.
final class CreatureInPlay {
  /// Pone en juego a [creature], sin Item y con su Duration impresa.
  ///
  /// [order] indica en qué momento de la partida entró, para aplicar sus
  /// habilidades en orden junto con los Effects.
  @internal
  CreatureInPlay(this.creature, {this.order = 0})
    : _remaining = creature.card.duration;

  /// Copia de la Creature que está en juego.
  final MatchCard<Creature> creature;

  /// Momento de la partida en que entró en juego.
  final int order;

  final List<MatchCard<Item>> _items = [];
  ClashDuration? _remaining;

  /// Items equipados, en el orden en que se equiparon. Normalmente es uno
  /// como máximo; con el Initial Effect Responsibility pueden ser varios.
  List<MatchCard<Item>> get items => List.unmodifiable(_items);

  /// Clashes que le quedan en juego, contando el próximo.
  ///
  /// Es `null` cuando ya agotó su Duration y debe dejar la mesa.
  ClashDuration? get remaining => _remaining;

  /// Indica si ya agotó su Duration.
  bool get isExhausted => _remaining == null;

  /// Valores de la Creature con sus Items aplicados, sin Effects ni otras
  /// habilidades. Los valores finales del Clash los calcula la partida
  /// ([GameMatch.statsOf]).
  ClashStats get stats => ClashStats.equipped(creature.card, [
    for (final item in _items) item.card,
  ]);

  /// Equipa [item] a la Creature.
  ///
  /// Si el Item otorga una Duration, la Creature conserva la mayor entre lo
  /// que le quedaba y lo que otorga el Item. Por ejemplo, a una Creature con
  /// 2 Clashes restantes, Ancient Pan ("Duration: 3 clashes") la deja con 3.
  ///
  /// No valida las reglas: eso lo hace la partida antes de llamar a este
  /// método.
  @internal
  void equip(MatchCard<Item> item) {
    _items.add(item);
    final granted = item.card.grantedDuration;
    if (granted != null) grantDuration(granted);
  }

  /// Le otorga [duration] a la Creature, contando el Clash actual.
  ///
  /// Conserva la mayor entre lo que le quedaba y [duration]: una Duration
  /// otorgada nunca la empeora.
  @internal
  void grantDuration(ClashDuration duration) {
    final remaining = _remaining;
    if (remaining != null) _remaining = remaining.max(duration);
  }

  /// Descuenta un Clash de su Duration.
  ///
  /// Se llama después de cada Clash en que participa, gane o empate.
  @internal
  void spendClash() {
    final remaining = _remaining;
    if (remaining != null) _remaining = remaining.afterClash();
  }
}
