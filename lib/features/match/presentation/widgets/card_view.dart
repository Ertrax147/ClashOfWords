import 'package:flutter/material.dart';
import 'package:game_engine/game_engine.dart';

import '../../../catalog/domain/card_catalog.dart';

/// Proporción ancho/alto de las cartas impresas.
const cardAspectRatio = 1000 / 1415;

/// Imagen de una carta del catálogo.
///
/// Un toque llama a [onTap]; una pulsación larga la muestra en grande, para
/// leer bien su texto (vista ampliada, RF-05).
class CardView extends StatelessWidget {
  /// Crea la carta [card] con la altura [height].
  const CardView({
    super.key,
    required this.card,
    required this.catalog,
    required this.height,
    this.onTap,
    this.dimmed = false,
    this.highlighted = false,
  });

  /// Carta a mostrar.
  final GameCard card;

  /// Catálogo con las imágenes.
  final CardCatalog catalog;

  /// Altura de la carta; el ancho sale de la proporción de las cartas.
  final double height;

  /// Acción al tocarla, o `null` si no se puede tocar.
  final VoidCallback? onTap;

  /// Si se muestra atenuada, por ejemplo porque no se puede jugar ahora.
  final bool dimmed;

  /// Si se resalta con un borde, por ejemplo porque se puede jugar.
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final image = catalog.imageOf(card);
    return GestureDetector(
      onTap: onTap,
      onLongPress: () => showCardZoom(context, image),
      child: Opacity(
        opacity: dimmed ? 0.45 : 1,
        child: Container(
          height: height,
          width: height * cardAspectRatio,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(height * 0.04),
            border: highlighted
                ? Border.all(color: Colors.amberAccent, width: 3)
                : null,
            boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black45)],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(height * 0.04),
            child: Image.asset(image, fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }
}

/// Espacio vacío del tamaño de una carta, para cuando no hay ninguna.
class EmptyCardSlot extends StatelessWidget {
  /// Crea el espacio con la altura [height] y un [label] opcional.
  const EmptyCardSlot({super.key, required this.height, this.label});

  /// Altura del espacio.
  final double height;

  /// Texto que se muestra dentro, por ejemplo "No creature".
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: height * cardAspectRatio,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(height * 0.04),
        border: Border.all(color: Colors.white24, width: 2),
      ),
      child: label == null
          ? null
          : Text(
              label!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white38),
            ),
    );
  }
}

/// Muestra la imagen [image] de una carta en grande.
void showCardZoom(BuildContext context, String image) {
  showDialog<void>(
    context: context,
    builder: (context) => GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: AspectRatio(
          aspectRatio: cardAspectRatio,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(image, fit: BoxFit.contain),
          ),
        ),
      ),
    ),
  );
}
