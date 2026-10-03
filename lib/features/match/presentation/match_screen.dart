import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_engine/game_engine.dart';

import 'match_controller.dart';
import 'widgets/card_view.dart';

/// Pantalla de una partida contra el sistema (RF-04, RF-15).
///
/// Arriba está la zona del rival, al centro la mesa con las Creatures del
/// Clash y abajo la zona del estudiante con su Hand. A la derecha están los
/// botones y el registro de lo que pasó.
class MatchScreen extends ConsumerWidget {
  /// Crea la pantalla. La partida ya debe estar empezada en
  /// [matchControllerProvider].
  const MatchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(matchControllerProvider);
    if (view == null) {
      return const Scaffold(body: Center(child: Text('No match started.')));
    }
    return Scaffold(
      backgroundColor: const Color(0xFF1B2636),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final unit = constraints.maxHeight / 5;
            return Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _PlayerZone(
                        view: view,
                        player: systemPlayer,
                        cardHeight: unit * 0.85,
                      ),
                      Expanded(
                        child: _Battlefield(view: view, cardHeight: unit * 1.6),
                      ),
                      _PlayerZone(
                        view: view,
                        player: humanPlayer,
                        cardHeight: unit * 1.05,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 280, child: _ControlPanel(view: view)),
              ],
            );
          },
        ),
      ),
    );
  }
}

const _textColor = Colors.white;
const _mutedColor = Colors.white60;

/// Zona de un jugador: sus pilas, su Initial Effect, sus Effects en juego y
/// su Hand. Solo la Hand del estudiante se puede tocar.
class _PlayerZone extends ConsumerWidget {
  const _PlayerZone({
    required this.view,
    required this.player,
    required this.cardHeight,
  });

  final MatchViewState view;
  final Player player;
  final double cardHeight;

  bool get _isHuman => player == humanPlayer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final match = view.match;
    final area = match.area(player);
    final canPlay = _isHuman && match.phase == MatchPhase.play;

    return Container(
      height: cardHeight + 28,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      color: Colors.black26,
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isHuman ? 'You' : 'Opponent',
                  style: const TextStyle(
                    color: _textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                _pileText('Deck', area.deck.length),
                _pileText('Discard', area.discardStack.length),
                _pileText('Trophies', area.trophyStack.length),
              ],
            ),
          ),
          _labeled(
            'Initial Effect',
            CardView(
              card: area.initialEffect.card,
              catalog: view.catalog,
              height: cardHeight,
            ),
          ),
          const SizedBox(width: 12),
          if (area.effectsInPlay.isNotEmpty)
            for (final effect in area.effectsInPlay)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _labeled(
                  'In play · ${_remainingText(effect.remaining)}',
                  CardView(
                    card: effect.effect.card,
                    catalog: view.catalog,
                    height: cardHeight,
                  ),
                ),
              ),
          const VerticalDivider(color: Colors.white24),
          Expanded(
            child: _labeled(
              'Hand (${area.hand.length})',
              SizedBox(
                height: cardHeight,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final card in area.hand)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: CardView(
                          card: card.card,
                          catalog: view.catalog,
                          height: cardHeight,
                          highlighted: canPlay && _isPlayable(match, card),
                          dimmed: canPlay && !_isPlayable(match, card),
                          onTap: canPlay
                              ? () => _play(context, ref, card)
                              : null,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isPlayable(GameMatch match, MatchCard card) => switch (card) {
    MatchCard<Item>() => match.checkEquipItem(player, card) == null,
    MatchCard<Effect>() => match.checkPlayEffect(player, card) == null,
    _ => false,
  };

  void _play(BuildContext context, WidgetRef ref, MatchCard card) {
    final error = ref.read(matchControllerProvider.notifier).playCard(card);
    if (error != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Widget _pileText(String label, int count) =>
      Text('$label: $count', style: const TextStyle(color: _mutedColor));
}

/// Mesa central: la Creature del rival contra la del estudiante, con sus
/// valores efectivos.
class _Battlefield extends StatelessWidget {
  const _Battlefield({required this.view, required this.cardHeight});

  final MatchViewState view;
  final double cardHeight;

  @override
  Widget build(BuildContext context) {
    final match = view.match;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (match.hasPendingTie)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              'Tie pending: ${_tiedCount(match)} cards are waiting for the '
              'next Clash',
              style: const TextStyle(color: Colors.amberAccent),
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _CreatureSide(view: view, player: humanPlayer, height: cardHeight),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'VS',
                style: TextStyle(
                  color: Colors.amberAccent,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _CreatureSide(view: view, player: systemPlayer, height: cardHeight),
          ],
        ),
      ],
    );
  }

  int _tiedCount(GameMatch match) => Player.values
      .map((player) => match.area(player).tiedCards.length)
      .reduce((a, b) => a + b);
}

/// Creature en la mesa de un jugador, con sus Items y sus valores.
class _CreatureSide extends StatelessWidget {
  const _CreatureSide({
    required this.view,
    required this.player,
    required this.height,
  });

  final MatchViewState view;
  final Player player;
  final double height;

  @override
  Widget build(BuildContext context) {
    final match = view.match;
    final inPlay = match.area(player).creatureInPlay;
    final stats = match.statsOf(player);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (inPlay == null)
          EmptyCardSlot(height: height, label: 'No creature')
        else
          CardView(
            card: inPlay.creature.card,
            catalog: view.catalog,
            height: height,
          ),
        const SizedBox(width: 8),
        SizedBox(
          width: 150,
          child: inPlay == null || stats == null
              ? const SizedBox()
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Power ${stats.power}',
                      style: const TextStyle(
                        color: _textColor,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _capitalize(stats.rarity.name),
                      style: const TextStyle(color: _textColor),
                    ),
                    Text(
                      stats.classes.map((c) => c.name).join(', '),
                      style: const TextStyle(color: _mutedColor),
                    ),
                    Text(
                      _remainingText(inPlay.remaining),
                      style: const TextStyle(color: _mutedColor),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      children: [
                        for (final item in inPlay.items)
                          CardView(
                            card: item.card,
                            catalog: view.catalog,
                            height: height * 0.45,
                          ),
                      ],
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

/// Panel derecho: qué hacer ahora, el resultado del último Clash y el
/// registro de la partida.
class _ControlPanel extends ConsumerWidget {
  const _ControlPanel({required this.view});

  final MatchViewState view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(matchControllerProvider.notifier);
    final match = view.match;

    final (
      String hint,
      String label,
      VoidCallback onPressed,
    ) = switch (match.phase) {
      MatchPhase.reveal => (
        'Reveal the next Creatures.',
        'Reveal',
        controller.reveal,
      ),
      MatchPhase.play => (
        'Play Items or Effects from your hand, then Clash!',
        'Clash!',
        controller.clash,
      ),
      MatchPhase.finished => (
        _finalText(match),
        'Play again',
        () => controller.startMatch(view.catalog),
      ),
    };

    return Container(
      color: Colors.black38,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(hint, style: const TextStyle(color: _textColor, fontSize: 16)),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(label, style: const TextStyle(fontSize: 18)),
          ),
          if (match.phase == MatchPhase.finished)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Back to menu'),
            ),
          const SizedBox(height: 12),
          if (view.lastResult != null)
            Text(
              describe(view.lastResult!),
              style: const TextStyle(
                color: Colors.amberAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          const Divider(color: Colors.white24),
          const Text('Log', style: TextStyle(color: _mutedColor)),
          Expanded(
            child: ListView(
              reverse: true,
              children: [
                for (final message in view.log.reversed)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      message,
                      style: const TextStyle(color: _textColor, fontSize: 13),
                    ),
                  ),
              ],
            ),
          ),
          const Text(
            'Tip: long press a card to see it bigger.',
            style: TextStyle(color: _mutedColor, fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _finalText(GameMatch match) {
    final result = match.result;
    final outcome = switch (result.winner) {
      null => "It's a draw!",
      humanPlayer => 'You win!',
      _ => 'You lose.',
    };
    return '$outcome Trophies: ${result.trophiesOfOne} - '
        '${result.trophiesOfTwo}';
  }
}

Widget _labeled(String label, Widget child) => Column(
  mainAxisAlignment: MainAxisAlignment.center,
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text(label, style: const TextStyle(color: _mutedColor, fontSize: 12)),
    const SizedBox(height: 2),
    child,
  ],
);

String _remainingText(ClashDuration? remaining) => switch (remaining) {
  null => 'Leaving play',
  ClashDuration(isInfinite: true) => 'Stays forever',
  ClashDuration(:final clashes) when clashes == 1 => '1 clash left',
  ClashDuration(:final clashes) => '$clashes clashes left',
};

String _capitalize(String text) => text[0].toUpperCase() + text.substring(1);
