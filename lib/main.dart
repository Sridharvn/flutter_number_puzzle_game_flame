import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'game/number_puzzle_game.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: GameWidget(
          game: NumberPuzzleGame(),
          overlayBuilderMap: {'menu': (context, game) => Container()},
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
