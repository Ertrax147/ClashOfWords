import 'package:flutter/material.dart';
import 'package:game_engine/game_engine.dart';

import '../../../catalog/domain/card_catalog.dart';
import 'card_view.dart';

/// Imagen del reverso de las cartas.
const cardBackImage = 'assets/cards/card-back.jpg';

/// Número de cartas sobre una pila, en una esquina.
class CountBadge extends StatelessWidget {
  /// Crea el número [count].
  const CountBadge(this.count, {super.key});

  /// Cantidad a mostrar.
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Deck: el reverso de la carta con la cantidad que queda.
class DeckPile extends StatelessWidget {
  /// Crea el Deck con [count] cartas y la altura [height].
  const DeckPile({super.key, required this.count, required this.height});

  /// Cartas que quedan en el Deck.
  final int count;

  /// Altura de la carta.
  final double height;

  @override
  Widget build(BuildContext context) {
    if (count == 0) return EmptyCardSlot(height: height, label: 'Deck');
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: height,
          width: height * cardAspectRatio,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(height * 0.04),
            boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black45)],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(height * 0.04),
            child: Image.asset(cardBackImage, fit: BoxFit.cover),
          ),
        ),
        Positioned(right: -6, top: -6, child: CountBadge(count)),
      ],
    );
  }
}

/// Discard Stack: la última carta descartada, boca arriba, con la
/// cantidad total.
class DiscardPile extends StatelessWidget {
  /// Crea la pila con sus [cards] y la altura [height].
  const DiscardPile({
    super.key,
    required this.cards,
    required this.catalog,
    required this.height,
  });

  /// Cartas del Discard Stack; la última es la de arriba.
  final List<MatchCard> cards;

  /// Catálogo con las imágenes.
  final CardCatalog catalog;

  /// Altura de la carta.
  final double height;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) return EmptyCardSlot(height: height, label: 'Discard');
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CardView(card: cards.last.card, catalog: catalog, height: height),
        Positioned(right: -6, top: -6, child: CountBadge(cards.length)),
      ],
    );
  }
}

/// Trophy Stack en abanico: las últimas cartas ganadas, una sobre otra,
/// dentro de un recuadro con su título.
class TrophyFan extends StatelessWidget {
  /// Crea el abanico con [title], sus [cards] y la altura de carta
  /// [cardHeight].
  const TrophyFan({
    super.key,
    required this.title,
    required this.cards,
    required this.catalog,
    required this.cardHeight,
    this.titleOnTop = false,
  });

  /// Título, por ejemplo "Trophy Stack".
  final String title;

  /// Cartas del Trophy Stack.
  final List<MatchCard> cards;

  /// Catálogo con las imágenes.
  final CardCatalog catalog;

  /// Altura de cada carta del abanico.
  final double cardHeight;

  /// Si el título va arriba del recuadro (para el rival) o abajo.
  final bool titleOnTop;

  static const _maxShown = 5;

  @override
  Widget build(BuildContext context) {
    final shown = cards.length <= _maxShown
        ? cards
        : cards.sublist(cards.length - _maxShown);
    final box = Container(
      width: cardHeight * 1.5,
      height: cardHeight * 1.25,
      decoration: BoxDecoration(
        color: const Color(0xFF242338),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          if (shown.isEmpty)
            const Text('No trophies', style: TextStyle(color: Colors.white38)),
          for (var i = 0; i < shown.length; i++)
            Transform.rotate(
              angle: (i - (shown.length - 1) / 2) * 0.18,
              child: Transform.translate(
                offset: Offset((i - (shown.length - 1) / 2) * 10, 0),
                child: CardView(
                  card: shown[i].card,
                  catalog: catalog,
                  height: cardHeight,
                ),
              ),
            ),
          if (cards.isNotEmpty)
            Positioned(right: 6, top: 6, child: CountBadge(cards.length)),
        ],
      ),
    );
    final label = Text(
      title,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 18,
        shadows: [Shadow(blurRadius: 4, color: Colors.black)],
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: titleOnTop
          ? [label, const SizedBox(height: 6), box]
          : [box, const SizedBox(height: 6), label],
    );
  }
}
