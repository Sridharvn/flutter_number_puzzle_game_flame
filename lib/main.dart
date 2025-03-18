import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'game/number_puzzle_game.dart';
import 'components/game_start_overlay.dart';
import 'components/game_over_overlay.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: GameWidget<NumberPuzzleGame>(
          game: NumberPuzzleGame(),
          overlayBuilderMap: {
            'start': (context, game) => GameStartOverlay(game: game),
            'gameOver':
                (context, game) =>
                    GameOverOverlay(game: game, moves: game.moves),
          },
          backgroundBuilder:
              (context) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
                  ),
                ),
              ),
        ),
      ),
    ),
  );
}
