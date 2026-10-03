import 'dart:async';

import 'package:flutter/material.dart';

import '../../../catalog/domain/card_catalog.dart';
import '../match_controller.dart';
import 'card_view.dart';

/// Muestra en grande una carta que acaba de pasar por la mesa (revelada o
/// jugada por el rival), con una frase que explica qué pasó.
///
/// Cubre toda la pantalla para que los eventos se vean de a uno y no se
/// pueda seguir jugando mientras tanto. Se cierra sola después de
/// [displayTime] o al tocarla.
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

  /// Evento a mostrar.
  final MatchEvent event;

  /// Catálogo con las imágenes.
  final CardCatalog catalog;

  /// Acción al cerrarse.
  final VoidCallback onDone;

  @override
  State<EventOverlay> createState() => _EventOverlayState();
}

class _EventOverlayState extends State<EventOverlay> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(EventOverlay.displayTime, _close);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _close() {
    _timer?.cancel();
    _timer = null;
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
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
              CardView(
                card: widget.event.card,
                catalog: widget.catalog,
                height: height,
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
}
