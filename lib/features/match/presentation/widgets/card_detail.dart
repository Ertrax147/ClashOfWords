import 'package:flutter/material.dart';
import 'package:game_engine/game_engine.dart';

import '../../../catalog/domain/card_catalog.dart';
import '../card_text.dart';
import 'card_view.dart';

/// Muestra la vista ampliada de [card]: su imagen grande y sus datos en
/// inglés (RF-05).
void showCardDetail(BuildContext context, GameCard card, CardCatalog catalog) {
  showDialog<void>(
    context: context,
    builder: (context) => _CardDetailDialog(card: card, catalog: catalog),
  );
}

class _CardDetailDialog extends StatelessWidget {
  const _CardDetailDialog({required this.card, required this.catalog});

  final GameCard card;
  final CardCatalog catalog;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    return Dialog(
      backgroundColor: const Color(0xFF111A27),
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 780, maxHeight: height * 0.92),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: Center(
                  child: AspectRatio(
                    aspectRatio: cardAspectRatio,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        catalog.imageOf(card),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(flex: 6, child: _CardInfo(card: card)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardInfo extends StatelessWidget {
  const _CardInfo({required this.card});

  final GameCard card;

  @override
  Widget build(BuildContext context) {
    final facts = cardFacts(card);
    final abilities = cardAbilityLines(card);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                card.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Close',
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          children: [
            Chip(label: Text(cardTypeLabel(card))),
            Chip(label: Text(cardRarityLabel(card))),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (label, value) in facts)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '$label: ',
                            style: const TextStyle(color: Colors.white54),
                          ),
                          TextSpan(
                            text: value,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                if (abilities.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Ability',
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                  for (final line in abilities)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        line,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Todavía no hay audios de pronunciación (RF-06): el botón queda como
        // marcador de dónde irá.
        OutlinedButton.icon(
          onPressed: null,
          style: OutlinedButton.styleFrom(
            disabledForegroundColor: Colors.white54,
            side: const BorderSide(color: Colors.white24),
          ),
          icon: const Icon(Icons.volume_up),
          label: const Text('Listen (audio coming soon)'),
        ),
      ],
    );
  }
}
