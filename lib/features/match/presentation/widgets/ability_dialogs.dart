import 'dart:math';

import 'package:flutter/material.dart';
import 'package:game_engine/game_engine.dart';

import '../../../catalog/domain/card_catalog.dart';
import '../ability_text.dart';
import 'card_view.dart';

/// Ancho de los diálogos: el de las cartas que muestran, sin pasarse de la
/// pantalla.
double _dialogWidth(BuildContext context) =>
    min(680, MediaQuery.sizeOf(context).width * 0.8);

/// Pregunta si el estudiante quiere usar una habilidad que no necesita
/// elegir nada (Leadership, Kindness). Solo se puede usar una vez por
/// partida, así que se confirma antes.
Future<bool> confirmAbility(
  BuildContext context,
  InitialEffectKind kind,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Use ${initialEffectName(kind)}?'),
      content: Text(
        '${activeAbilityText(kind)}\n\n'
        'You can only use it once per match.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text('Use ${initialEffectName(kind)}'),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

/// Deja elegir una de las [cards] para la habilidad [kind]. Devuelve la
/// elegida, o `null` si el estudiante cancela.
Future<MatchCard?> pickCard(
  BuildContext context, {
  required InitialEffectKind kind,
  required List<MatchCard> cards,
  required CardCatalog catalog,
}) => showDialog<MatchCard>(
  context: context,
  builder: (context) =>
      _CardPickerDialog(kind: kind, cards: cards, catalog: catalog),
);

class _CardPickerDialog extends StatefulWidget {
  const _CardPickerDialog({
    required this.kind,
    required this.cards,
    required this.catalog,
  });

  final InitialEffectKind kind;
  final List<MatchCard> cards;
  final CardCatalog catalog;

  @override
  State<_CardPickerDialog> createState() => _CardPickerDialogState();
}

class _CardPickerDialogState extends State<_CardPickerDialog> {
  MatchCard? _selected;

  @override
  Widget build(BuildContext context) {
    final name = initialEffectName(widget.kind);
    return AlertDialog(
      title: Text('Use $name'),
      content: SizedBox(
        width: _dialogWidth(context),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(pickCardText(widget.kind)),
              const SizedBox(height: 4),
              const Text(
                'Tap a card to choose it. Long press to see it bigger.',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final card in widget.cards)
                    CardView(
                      card: card.card,
                      catalog: widget.catalog,
                      height: 150,
                      highlighted: card == _selected,
                      dimmed: _selected != null && card != _selected,
                      onTap: () => setState(() => _selected = card),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _selected == null
              ? null
              : () => Navigator.of(context).pop(_selected),
          child: Text('Use $name'),
        ),
      ],
    );
  }
}

/// Deja reordenar las 3 cartas superiores del Deck propio y del Deck del
/// rival (Honesty). Devuelve el nuevo orden, o `null` si el estudiante
/// cancela.
Future<ReorderChoice?> reorderCards(
  BuildContext context, {
  required ({List<MatchCard> own, List<MatchCard> enemy}) cards,
  required CardCatalog catalog,
}) => showDialog<ReorderChoice>(
  context: context,
  builder: (context) => _ReorderDialog(cards: cards, catalog: catalog),
);

class _ReorderDialog extends StatefulWidget {
  const _ReorderDialog({required this.cards, required this.catalog});

  final ({List<MatchCard> own, List<MatchCard> enemy}) cards;
  final CardCatalog catalog;

  @override
  State<_ReorderDialog> createState() => _ReorderDialogState();
}

class _ReorderDialogState extends State<_ReorderDialog> {
  late final List<MatchCard> _own = [...widget.cards.own];
  late final List<MatchCard> _enemy = [...widget.cards.enemy];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Use Honesty'),
      content: SizedBox(
        width: _dialogWidth(context),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(activeAbilityText(InitialEffectKind.honesty)),
              const SizedBox(height: 4),
              const Text(
                'Use the arrows to change the order. The first card is the '
                'top of the Deck.',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 12),
              _OrderRow(
                title: 'Your Deck',
                cards: _own,
                catalog: widget.catalog,
                onChanged: () => setState(() {}),
              ),
              const SizedBox(height: 12),
              _OrderRow(
                title: "Your opponent's Deck",
                cards: _enemy,
                catalog: widget.catalog,
                onChanged: () => setState(() {}),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(
            context,
          ).pop(ReorderChoice(own: _own, enemy: _enemy)),
          child: const Text('Put them back'),
        ),
      ],
    );
  }
}

/// Fila de cartas con flechas para cambiar su orden. Modifica [cards].
class _OrderRow extends StatelessWidget {
  const _OrderRow({
    required this.title,
    required this.cards,
    required this.catalog,
    required this.onChanged,
  });

  final String title;
  final List<MatchCard> cards;
  final CardCatalog catalog;
  final VoidCallback onChanged;

  void _move(int from, int to) {
    cards.insert(to, cards.removeAt(from));
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        if (cards.isEmpty)
          const Text('No cards left in this Deck.')
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < cards.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Column(
                      children: [
                        Text(i == 0 ? '1 (top)' : '${i + 1}'),
                        CardView(
                          card: cards[i].card,
                          catalog: catalog,
                          height: 130,
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Move left',
                              onPressed: i == 0 ? null : () => _move(i, i - 1),
                              icon: const Icon(Icons.arrow_back),
                            ),
                            IconButton(
                              tooltip: 'Move right',
                              onPressed: i == cards.length - 1
                                  ? null
                                  : () => _move(i, i + 1),
                              icon: const Icon(Icons.arrow_forward),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
