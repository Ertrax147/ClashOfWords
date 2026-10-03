import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_engine/game_engine.dart';

import 'match_controller.dart';
import 'widgets/card_piles.dart';
import 'widgets/card_view.dart';
import 'widgets/wood_background.dart';

/// Pantalla de una partida contra el sistema (RF-04, RF-15).
///
/// Reproduce la disposición del manual sobre una mesa de madera: el rival
/// arriba y el estudiante abajo, en espejo, con las Creatures frente a
/// frente. Cada lado tiene la fila Discard Stack, Deck y Creature, y más
/// afuera la fila Initial Effect y Effects. Los Trophy Stacks van a la
/// izquierda y, a la derecha, las Hands, los botones y el registro.
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
      body: WoodBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              const middleStrip = 40.0;
              const gap = 8.0;
              final cardHeight =
                  ((constraints.maxHeight - middleStrip - 5 * gap) / 4).clamp(
                    60.0,
                    240.0,
                  );
              return Row(
                children: [
                  _TrophyColumn(view: view, cardHeight: cardHeight * 0.7),
                  Expanded(
                    child: _Board(
                      view: view,
                      cardHeight: cardHeight,
                      gap: gap,
                      middleStrip: middleStrip,
                    ),
                  ),
                  SizedBox(
                    width: 340,
                    child: _SidePanel(view: view, cardHeight: cardHeight),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

const _textColor = Colors.white;
const _mutedColor = Colors.white70;
const _shadow = [Shadow(blurRadius: 4, color: Colors.black)];

/// Columna izquierda: el Trophy Stack del rival arriba y el del estudiante
/// abajo.
class _TrophyColumn extends StatelessWidget {
  const _TrophyColumn({required this.view, required this.cardHeight});

  final MatchViewState view;
  final double cardHeight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TrophyFan(
            title: "Opponent's\nTrophy Stack",
            cards: view.match.area(systemPlayer).trophyStack,
            catalog: view.catalog,
            cardHeight: cardHeight,
          ),
          TrophyFan(
            title: 'Trophy Stack',
            cards: view.match.area(humanPlayer).trophyStack,
            catalog: view.catalog,
            cardHeight: cardHeight,
            titleOnTop: true,
          ),
        ],
      ),
    );
  }
}

/// Mesa central con las zonas de ambos jugadores en espejo.
class _Board extends StatelessWidget {
  const _Board({
    required this.view,
    required this.cardHeight,
    required this.gap,
    required this.middleStrip,
  });

  final MatchViewState view;
  final double cardHeight;
  final double gap;
  final double middleStrip;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _outerRow(systemPlayer),
        SizedBox(height: gap),
        _innerRow(systemPlayer),
        SizedBox(
          height: middleStrip,
          child: Center(child: _middleText()),
        ),
        _innerRow(humanPlayer),
        SizedBox(height: gap),
        _outerRow(humanPlayer),
      ],
    );
  }

  double get _cardWidth => cardHeight * cardAspectRatio;

  /// Fila Discard Stack · Deck · Creature.
  Widget _innerRow(Player player) {
    final area = view.match.area(player);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _cell(
          DiscardPile(
            cards: area.discardStack,
            catalog: view.catalog,
            height: cardHeight,
          ),
        ),
        _cell(DeckPile(count: area.deck.length, height: cardHeight)),
        _CreatureSlot(view: view, player: player, height: cardHeight),
      ],
    );
  }

  /// Fila Initial Effect · Effects en juego (con una celda vacía bajo el
  /// Discard Stack, como en el manual).
  Widget _outerRow(Player player) {
    final area = view.match.area(player);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _cell(SizedBox(height: cardHeight)),
        _cell(
          CardView(
            card: area.initialEffect.card,
            catalog: view.catalog,
            height: cardHeight,
          ),
        ),
        SizedBox(
          width: _creatureSlotWidth,
          height: cardHeight,
          child: area.effectsInPlay.isEmpty
              ? Align(
                  alignment: Alignment.centerLeft,
                  child: EmptyCardSlot(height: cardHeight, label: 'Effects'),
                )
              : ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final effect in area.effectsInPlay)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            CardView(
                              card: effect.effect.card,
                              catalog: view.catalog,
                              height: cardHeight,
                            ),
                            Positioned(
                              left: 4,
                              bottom: 4,
                              child: _Tag(_remainingText(effect.remaining)),
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

  double get _creatureSlotWidth => _cardWidth + 170;

  Widget _cell(Widget child) => Padding(
    padding: const EdgeInsets.only(right: 16),
    child: SizedBox(
      width: _cardWidth,
      child: Align(alignment: Alignment.center, child: child),
    ),
  );

  Widget _middleText() {
    final match = view.match;
    final tied = Player.values
        .map((player) => match.area(player).tiedCards.length)
        .reduce((a, b) => a + b);
    final text = match.hasPendingTie
        ? 'Tie pending: $tied cards wait for the next Clash'
        : view.lastResult == null
        ? ''
        : describe(view.lastResult!);
    return Text(
      text,
      style: const TextStyle(
        color: Colors.amberAccent,
        fontSize: 18,
        fontWeight: FontWeight.bold,
        shadows: _shadow,
      ),
    );
  }
}

/// Creature en la mesa con sus Items asomando por detrás y sus valores al
/// lado.
class _CreatureSlot extends StatelessWidget {
  const _CreatureSlot({
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
    const peek = 14.0;

    return SizedBox(
      width: height * cardAspectRatio + 170,
      child: Row(
        children: [
          if (inPlay == null)
            EmptyCardSlot(height: height, label: 'Creature')
          else
            SizedBox(
              height: height,
              width: height * cardAspectRatio + peek * inPlay.items.length,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  for (var i = 0; i < inPlay.items.length; i++)
                    Positioned(
                      left: peek * (inPlay.items.length - i),
                      top: -peek * (inPlay.items.length - i),
                      child: CardView(
                        card: inPlay.items[i].card,
                        catalog: view.catalog,
                        height: height,
                      ),
                    ),
                  Positioned(
                    left: 0,
                    top: 0,
                    child: CardView(
                      card: inPlay.creature.card,
                      catalog: view.catalog,
                      height: height,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(width: 10),
          if (inPlay != null && stats != null)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Power ${stats.power}',
                    style: const TextStyle(
                      color: _textColor,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      shadows: _shadow,
                    ),
                  ),
                  Text(
                    _capitalize(stats.rarity.name),
                    style: const TextStyle(color: _textColor, shadows: _shadow),
                  ),
                  Text(
                    stats.classes.map((c) => c.name).join(', '),
                    style: const TextStyle(
                      color: _mutedColor,
                      shadows: _shadow,
                    ),
                  ),
                  Text(
                    _remainingText(inPlay.remaining),
                    style: const TextStyle(
                      color: _mutedColor,
                      shadows: _shadow,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Panel derecho: Hand del rival, botón de la acción siguiente, registro y
/// Hand del estudiante.
class _SidePanel extends ConsumerWidget {
  const _SidePanel({required this.view, required this.cardHeight});

  final MatchViewState view;
  final double cardHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(matchControllerProvider.notifier);
    final match = view.match;
    final canPlay = match.phase == MatchPhase.play;

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
        'Play cards from your hand, then Clash!',
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
          _handRow(
            context,
            ref,
            title: "Opponent's hand",
            player: systemPlayer,
            height: cardHeight * 0.55,
            interactive: false,
          ),
          const SizedBox(height: 8),
          Text(hint, style: const TextStyle(color: _textColor, fontSize: 15)),
          const SizedBox(height: 6),
          FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(label, style: const TextStyle(fontSize: 18)),
          ),
          if (match.phase == MatchPhase.finished)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Back to menu'),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(8),
              ),
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
          ),
          const SizedBox(height: 8),
          _handRow(
            context,
            ref,
            title: canPlay ? 'Your hand: tap a card to play it' : 'Your hand',
            player: humanPlayer,
            height: cardHeight * 0.9,
            interactive: canPlay,
          ),
          const Text(
            'Long press any card to see it bigger.',
            style: TextStyle(color: _mutedColor, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _handRow(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required Player player,
    required double height,
    required bool interactive,
  }) {
    final match = view.match;
    final hand = match.area(player).hand;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$title (${hand.length})',
          style: const TextStyle(color: _mutedColor, fontSize: 13),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: height + 6,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(top: 3),
            children: [
              for (final card in hand)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: CardView(
                    card: card.card,
                    catalog: view.catalog,
                    height: height,
                    highlighted: interactive && _isPlayable(match, card),
                    dimmed: interactive && !_isPlayable(match, card),
                    onTap: interactive ? () => _play(context, ref, card) : null,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  bool _isPlayable(GameMatch match, MatchCard card) => switch (card) {
    MatchCard<Item>() => match.checkEquipItem(humanPlayer, card) == null,
    MatchCard<Effect>() => match.checkPlayEffect(humanPlayer, card) == null,
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

/// Etiqueta pequeña sobre una carta, por ejemplo los Clashes que le quedan.
class _Tag extends StatelessWidget {
  const _Tag(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 11),
      ),
    );
  }
}

String _remainingText(ClashDuration? remaining) => switch (remaining) {
  null => 'Leaving play',
  ClashDuration(isInfinite: true) => 'Stays forever',
  ClashDuration(:final clashes) when clashes == 1 => '1 clash left',
  ClashDuration(:final clashes) => '$clashes clashes left',
};

String _capitalize(String text) => text[0].toUpperCase() + text.substring(1);
