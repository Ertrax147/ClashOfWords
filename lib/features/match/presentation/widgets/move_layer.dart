import 'dart:math';
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:game_engine/game_engine.dart';

import '../../../catalog/domain/card_catalog.dart';
import '../match_controller.dart';
import '../match_zones.dart';
import 'card_view.dart';
import 'zone_keys.dart';

/// Anima las cartas de un [MoveBatch]: cada una viaja desde la zona en que
/// estaba hasta la zona a la que llegó.
///
/// Si el lote es la resolución de un Clash, antes de viajar las cartas se
/// quedan un momento donde estaban, con el ganador resaltado y el resultado
/// escrito, para que se vea qué pasó. Mientras dura, cubre la pantalla y
/// no deja tocar nada. Con las animaciones desactivadas en el sistema, no
/// anima y termina enseguida.
class MoveLayer extends StatefulWidget {
  /// Crea la animación del [batch]. [onDone] se llama al terminar.
  const MoveLayer({
    super.key,
    required this.batch,
    required this.catalog,
    required this.onDone,
  });

  /// Cuánto se muestra un Clash resuelto antes de que las cartas se vayan.
  static const clashHold = Duration(milliseconds: 1300);

  /// Lo que tarda cada carta en llegar a su destino.
  static const travel = Duration(milliseconds: 650);

  /// Espera entre la salida de una carta y la siguiente.
  static const stagger = Duration(milliseconds: 110);

  /// Cartas que se mueven.
  final MoveBatch batch;

  /// Catálogo con las imágenes.
  final CardCatalog catalog;

  /// Acción al terminar.
  final VoidCallback onDone;

  @override
  State<MoveLayer> createState() => _MoveLayerState();
}

/// Una carta que viaja, con su origen y destino ya medidos.
class _Flight {
  const _Flight({
    required this.move,
    required this.from,
    required this.to,
    required this.index,
    required this.stackIndex,
  });

  final MatchMove move;
  final Rect from;
  final Rect to;

  /// Orden de salida entre las cartas del lote.
  final int index;

  /// Posición entre las cartas que salen de la misma zona, para que no se
  /// tapen del todo.
  final int stackIndex;
}

class _MoveLayerState extends State<MoveLayer>
    with SingleTickerProviderStateMixin {
  static const _maxCardHeight = 160.0;

  late final AnimationController _controller = AnimationController(vsync: this);
  List<_Flight> _flights = const [];
  Duration _hold = Duration.zero;
  Duration _total = Duration.zero;

  @override
  void initState() {
    super.initState();
    // Las zonas ya están dibujadas; se miden después de este cuadro.
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _start() {
    if (!mounted) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      widget.onDone();
      return;
    }
    final keys = ZoneKeyScope.of(context);
    final layer = context.findRenderObject() as RenderBox;
    Rect? local(Zone zone) {
      final rect = keys.rectOf(zone);
      if (rect == null) return null;
      return Rect.fromPoints(
        layer.globalToLocal(rect.topLeft),
        layer.globalToLocal(rect.bottomRight),
      );
    }

    final flights = <_Flight>[];
    final perOrigin = <Zone, int>{};
    for (final move in widget.batch.moves) {
      final from = local(move.from);
      final to = local(move.to);
      if (from == null || to == null) continue;
      final stackIndex = perOrigin.update(
        move.from,
        (count) => count + 1,
        ifAbsent: () => 0,
      );
      flights.add(
        _Flight(
          move: move,
          from: from,
          to: to,
          index: flights.length,
          stackIndex: stackIndex,
        ),
      );
    }
    if (flights.isEmpty) {
      widget.onDone();
      return;
    }

    _hold = widget.batch.clashResult == null
        ? Duration.zero
        : MoveLayer.clashHold;
    _total =
        _hold + MoveLayer.travel + MoveLayer.stagger * (flights.length - 1);
    setState(() => _flights = flights);
    _controller.duration = _total;
    _controller.forward().whenComplete(() {
      if (mounted) widget.onDone();
    });
  }

  /// Jugador que ganó el Clash del lote, o `null` si no hay Clash o fue Tie.
  Player? get _winner => switch (widget.batch.clashResult) {
    ClashWin(:final winner) =>
      winner == ClashSide.first ? Player.one : Player.two,
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_flights.isEmpty) return const SizedBox.expand();
          final elapsed = _controller.value * _total.inMilliseconds;
          final result = widget.batch.clashResult;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              const SizedBox.expand(),
              for (final flight in _flights) _ghost(flight, elapsed),
              if (result != null) _banner(result, elapsed),
            ],
          );
        },
      ),
    );
  }

  Widget _ghost(_Flight flight, double elapsed) {
    final startMs =
        _hold.inMilliseconds + MoveLayer.stagger.inMilliseconds * flight.index;
    final t = ((elapsed - startMs) / MoveLayer.travel.inMilliseconds).clamp(
      0.0,
      1.0,
    );
    final eased = Curves.easeInOutCubic.transform(t);
    final startHeight = min(flight.from.height, _maxCardHeight);
    final endHeight = min(flight.to.height, _maxCardHeight);
    final height = lerpDouble(startHeight, endHeight, eased)!;
    final width = height * cardAspectRatio;
    final stackOffset = Offset(
      flight.stackIndex * 12.0,
      -flight.stackIndex * 12.0,
    );
    final center =
        Offset.lerp(
          flight.from.center + stackOffset,
          flight.to.center,
          eased,
        )! +
        Offset(0, -40 * sin(pi * eased));

    // Mientras se muestra el Clash, el ganador se resalta y el perdedor se
    // apaga.
    final waiting = t == 0 && _winner != null;
    final isWinner = flight.move.from.player == _winner;
    return Positioned(
      left: center.dx - width / 2,
      top: center.dy - height / 2,
      width: width,
      height: height,
      child: Opacity(
        opacity: waiting && !isWinner ? 0.65 : 1,
        child: CardView(
          card: flight.move.card.card,
          catalog: widget.catalog,
          height: height,
          highlighted: waiting && isWinner,
        ),
      ),
    );
  }

  Widget _banner(ClashResult result, double elapsed) {
    final visible =
        elapsed < _hold.inMilliseconds + MoveLayer.travel.inMilliseconds * 0.3;
    return Positioned(
      left: 0,
      right: 0,
      top: 16,
      child: IgnorePointer(
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: const Duration(milliseconds: 250),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.amberAccent, width: 2),
              ),
              child: Text(
                describe(result),
                style: const TextStyle(
                  color: Colors.amberAccent,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
