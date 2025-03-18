import 'dart:math';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(GameWidget(game: ShapeTapGame()));
}

class Square extends PositionComponent with TapCallbacks {
  static final Random _random = Random();
  late Paint _paint;
  bool isAlive = true;
  final ShapeTapGame game;

  Square(this.game) : super(size: Vector2.all(50)) {
    _paint =
        Paint()
          ..color = Color.fromRGBO(
            _random.nextInt(256),
            _random.nextInt(256),
            _random.nextInt(256),
            1,
          );
  }

  @override
  void onMount() {
    super.onMount();
    position = Vector2(
      _random.nextDouble() * (game.size.x - size.x),
      _random.nextDouble() * (game.size.y - size.y),
    );
  }

  @override
  bool onTapDown(TapDownEvent event) {
    isAlive = false;
    game.score++;
    return true;
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), _paint);
  }
}

class ShapeTapGame extends FlameGame with TapCallbacks {
  int score = 0;
  double spawnTimer = 0;
  final double spawnInterval = 1.0;
  final TextPaint textPaint = TextPaint(
    style: const TextStyle(fontSize: 24.0, color: Colors.white),
  );

  @override
  void update(double dt) {
    super.update(dt);
    spawnTimer += dt;
    if (spawnTimer >= spawnInterval) {
      spawnTimer = 0;
      add(Square(this));
    }

    // Remove squares that have been tapped
    children.whereType<Square>().forEach((square) {
      if (!square.isAlive) {
        remove(square);
      }
    });
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    textPaint.render(canvas, 'Score: $score', Vector2(10, 10));
  }
}
