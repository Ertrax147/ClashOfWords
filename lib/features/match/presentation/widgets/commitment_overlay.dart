import 'package:flutter/material.dart';
import 'package:game_engine/game_engine.dart';

import '../../../catalog/domain/card_catalog.dart';
import '../ability_text.dart';
import '../match_controller.dart';
import 'card_view.dart';

/// Pantalla de decisión de Commitment: el estudiante perdió un Clash y elige
/// si usa la habilidad o la rechaza.
///
/// El Clash todavía no se aplicó. Si el estudiante tiene Creatures en su
/// Trophy Stack, debe elegir cuál mandar al Discard Stack del rival.
class CommitmentOverlay extends StatefulWidget {
  /// Crea la pantalla para el Clash pendiente de [match].
  const CommitmentOverlay({
    super.key,
    required this.match,
    required this.catalog,
    required this.onUse,
    required this.onDecline,
  });

  /// Partida en la fase posterior al Clash.
  final GameMatch match;

  /// Catálogo, para mostrar las cartas.
  final CardCatalog catalog;

  /// El estudiante usa Commitment con la elección dada.
  final void Function(InitialEffectChoice choice) onUse;

  /// El estudiante rechaza usarlo.
  final VoidCallback onDecline;

  @override
  State<CommitmentOverlay> createState() => _CommitmentOverlayState();
}

class _CommitmentOverlayState extends State<CommitmentOverlay> {
  MatchCard? _selected;

  String _describeClash() {
    final match = widget.match;
    String describe(Player player) {
      final name = match.area(player).creatureInPlay?.creature.card.name;
      final stats = match.statsOf(player);
      if (stats == null) return '$name';
      final rarity = stats.rarity.name;
      return '$name (${rarity[0].toUpperCase()}${rarity.substring(1)}, '
          'Power ${stats.power})';
    }

    return 'Your ${describe(humanPlayer)} lost against your '
        "opponent's ${describe(systemPlayer)}.";
  }

  @override
  Widget build(BuildContext context) {
    final options = widget.match.activeOptions(humanPlayer);
    final canUse = options.isEmpty || _selected != null;
    return Material(
      color: Colors.black54,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Card(
            margin: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'You lost the Clash',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(_describeClash()),
                  const SizedBox(height: 12),
                  Text(
                    'Commitment: '
                    '${activeAbilityText(InitialEffectKind.commitment)}',
                  ),
                  const SizedBox(height: 12),
                  if (options.isEmpty)
                    const Text(
                      'You have no Creatures in your Trophy Stack to send, '
                      'so you only win the Clash.',
                    )
                  else ...[
                    Text(pickCardText(InitialEffectKind.commitment)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final card in options)
                          CardView(
                            card: card.card,
                            catalog: widget.catalog,
                            height: 130,
                            highlighted: card == _selected,
                            dimmed: _selected != null && card != _selected,
                            onTap: () => setState(() => _selected = card),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  const Text(
                    'You can only use Commitment once per match. If you '
                    'decline now, you can use it in another Clash.',
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: widget.onDecline,
                        child: const Text('Decline'),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: canUse
                            ? () => widget.onUse(
                                options.isEmpty
                                    ? const NoChoice()
                                    : CardChoice(_selected!),
                              )
                            : null,
                        child: const Text('Use Commitment'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
