import 'dart:async';
import 'dart:math';
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../../catalog/domain/card_catalog.dart';
import '../match_controller.dart';
import '../match_zones.dart';
import 'card_view.dart';
import 'zone_keys.dart';

/// Muestra en grande una carta que acaba de pasar por la mesa (revelada o
/// jugada por el rival), con una frase que explica qué pasó.
///
/// Cubre toda la pantalla para que los eventos se vean de a uno y no se
/// pueda seguir jugando mientras tanto. Se cierra sola después de
/// [displayTime] o al tocarla. Al cerrarse, la carta viaja hasta el lugar de
/// la mesa al que va (su Hand, la mesa, un Trophy Stack...), para que se vea
/// dónde queda.
class EventOverlay extends StatefulWidget {
  /// Crea el aviso del [event]. [onDone] se llama al cerrarlo.
  const EventOverlay({
    super.key,
    required this.event,
    required this.catalog,
    required this.onDone,
  });

  /// Tiempo que se muestra cada evento si nadie lo toca.
  static const displayTime = Duration(milliseconds: 1500);

  /// Lo que tarda la carta en llegar a su lugar al cerrarse.
  static const travelTime = Duration(milliseconds: 550);

  /// Pausa antes de mostrar una carta que sale de una Hand, para que se vea
  /// quieta ahí antes de jugarse.
  static const handHold = Duration(milliseconds: 800);

  /// Evento a mostrar.
  final MatchEvent event;

  /// Catálogo con las imágenes.
  final CardCatalog catalog;

  /// Acción al cerrarse.
  final VoidCallback onDone;

  @override
  State<EventOverlay> createState() => _EventOverlayState();
}

class _EventOverlayState extends State<EventOverlay>
    with SingleTickerProviderStateMixin {
  static const _maxLandingHeight = 160.0;

  final _cardKey = GlobalKey();
  late final AnimationController _travel = AnimationController(
    vsync: this,
    duration: EventOverlay.travelTime,
  );
  Timer? _timer;

  /// Si todavía espera, sin mostrar la carta, a que se vea en su Hand.
  late bool _holding = widget.event.from?.kind == ZoneKind.hand;

  /// Dónde está la carta grande y dónde va, mientras viaja.
  Rect? _from;
  Rect? _to;

  @override
  void initState() {
    super.initState();
    _timer = _holding
        ? Timer(EventOverlay.handHold, _endHold)
        : Timer(EventOverlay.displayTime, _close);
  }

  void _endHold() {
    if (!mounted) return;
    setState(() => _holding = false);
    _timer = Timer(EventOverlay.displayTime, _close);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _travel.dispose();
    super.dispose();
  }

  Rect? _localRect(Rect? global) {
    final overlay = context.findRenderObject();
    if (global == null || overlay is! RenderBox) return null;
    return Rect.fromPoints(
      overlay.globalToLocal(global.topLeft),
      overlay.globalToLocal(global.bottomRight),
    );
  }

  void _close() {
    _timer?.cancel();
    _timer = null;
    if (_from != null) return; // Ya está viajando.

    final destination = widget.event.destination;
    final card = _cardKey.currentContext?.findRenderObject();
    Rect? from;
    if (card is RenderBox && card.attached && card.hasSize) {
      from = MatrixUtils.transformRect(
        card.getTransformTo(null),
        Offset.zero & card.size,
      );
    }
    final to = destination == null
        ? null
        : ZoneKeyScope.of(context).rectOf(destination);
    final localFrom = _localRect(from);
    final localTo = _localRect(to);
    if (localFrom == null ||
        localTo == null ||
        MediaQuery.disableAnimationsOf(context)) {
      widget.onDone();
      return;
    }
    setState(() {
      _from = localFrom;
      _to = localTo;
    });
    _travel.forward().whenComplete(() {
      if (mounted) widget.onDone();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Mientras espera, la mesa se ve normal, pero no se puede tocar.
    if (_holding) return const AbsorbPointer(child: SizedBox.expand());

    final from = _from;
    final to = _to;
    if (from != null && to != null) return _travelling(from, to);

    final height = MediaQuery.sizeOf(context).height * 0.55;
    return GestureDetector(
      onTap: _close,
      child: Container(
        color: Colors.black54,
        alignment: Alignment.center,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.6, end: 1),
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutBack,
          builder: (context, scale, child) =>
              Transform.scale(scale: scale, child: child),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              KeyedSubtree(
                key: _cardKey,
                child: CardView(
                  card: widget.event.card,
                  catalog: widget.catalog,
                  height: height,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.event.caption,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(blurRadius: 6, color: Colors.black)],
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Tap to continue',
                style: TextStyle(color: Colors.white60, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// La carta viaja de su lugar en el aviso hasta su destino, mientras el
  /// fondo se aclara.
  Widget _travelling(Rect from, Rect to) {
    return AbsorbPointer(
      child: AnimatedBuilder(
        animation: _travel,
        builder: (context, _) {
          final t = Curves.easeInOutCubic.transform(_travel.value);
          final height = lerpDouble(
            from.height,
            min(to.height, _maxLandingHeight),
            t,
          )!;
          final center = Offset.lerp(from.center, to.center, t)!;
          final width = height * cardAspectRatio;
          return Stack(
            children: [
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black54.withValues(alpha: 0.54 * (1 - t)),
                ),
              ),
              Positioned(
                left: center.dx - width / 2,
                top: center.dy - height / 2,
                width: width,
                height: height,
                child: CardView(
                  card: widget.event.card,
                  catalog: widget.catalog,
                  height: height,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
