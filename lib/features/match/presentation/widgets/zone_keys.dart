import 'package:flutter/material.dart';

import '../match_zones.dart';

/// Llaves de las zonas de la mesa, para saber dónde está cada una en la
/// pantalla y animar cartas que viajan entre ellas.
class ZoneKeys {
  final Map<Zone, GlobalKey> _keys = {};

  /// Las Creatures apartadas por un Tie se dibujan donde la Creature en la
  /// mesa.
  Zone _canonical(Zone zone) =>
      zone.kind == ZoneKind.tied ? Zone(zone.player, ZoneKind.creature) : zone;

  /// Llave de [zone], que la zona usa en su widget.
  GlobalKey keyFor(Zone zone) {
    final canonical = _canonical(zone);
    return _keys.putIfAbsent(
      canonical,
      () => GlobalKey(debugLabel: canonical.toString()),
    );
  }

  /// Rectángulo de [zone] en la pantalla, o `null` si todavía no se dibujó.
  Rect? rectOf(Zone zone) {
    final box = keyFor(zone).currentContext?.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    // Con la transformación completa, vale también dentro de un FittedBox.
    return MatrixUtils.transformRect(
      box.getTransformTo(null),
      Offset.zero & box.size,
    );
  }
}

/// Entrega a la pantalla de partida sus [ZoneKeys].
class ZoneKeyScope extends StatefulWidget {
  /// Crea el ámbito que rodea a la pantalla de partida.
  const ZoneKeyScope({super.key, required this.child});

  /// Pantalla de partida.
  final Widget child;

  /// Las llaves de las zonas de la pantalla que rodea a [context].
  static ZoneKeys of(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<_ZoneKeysInherited>();
    assert(scope != null, 'There is no ZoneKeyScope above this widget');
    return scope!.keys;
  }

  @override
  State<ZoneKeyScope> createState() => _ZoneKeyScopeState();
}

class _ZoneKeyScopeState extends State<ZoneKeyScope> {
  final _keys = ZoneKeys();

  @override
  Widget build(BuildContext context) =>
      _ZoneKeysInherited(keys: _keys, child: widget.child);
}

class _ZoneKeysInherited extends InheritedWidget {
  const _ZoneKeysInherited({required this.keys, required super.child});

  final ZoneKeys keys;

  @override
  bool updateShouldNotify(_ZoneKeysInherited oldWidget) => false;
}

/// Marca a [child] como la zona [zone] de la mesa.
class ZoneMarker extends StatelessWidget {
  /// Marca [child] como [zone].
  const ZoneMarker({super.key, required this.zone, required this.child});

  /// Zona que representa.
  final Zone zone;

  /// Contenido de la zona.
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      KeyedSubtree(key: ZoneKeyScope.of(context).keyFor(zone), child: child);
}
