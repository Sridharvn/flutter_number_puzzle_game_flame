import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../game/number_puzzle_game.dart';

class Tile extends PositionComponent with TapCallbacks, HoverCallbacks {
  final int number;
  final Paint _paint = Paint()..color = const Color(0xFF1565C0);
  final Paint _textBgPaint = Paint()..color = const Color(0xFFBBDEFB);
  late final TextComponent _numberText;
  final NumberPuzzleGame game;
  bool isEmpty;
  bool isHovered = false;
  Vector2 targetPosition = Vector2.zero();
  bool isMoving = false;
  static const double moveDuration = 0.2; // Movement duration in seconds
  double moveProgress = 0.0;
  Vector2 startPosition = Vector2.zero();

  Tile(this.number, this.game, {this.isEmpty = false})
    : super(size: Vector2.all(80)) {
    _numberText = TextComponent(
      text: isEmpty ? '' : number.toString(),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 32,
          color: Color(0xFF0D47A1),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    targetPosition = position.clone();
    startPosition = position.clone();
  }

  @override
  void onMount() {
    super.onMount();
    _numberText.position = size / 2;
    _numberText.anchor = Anchor.center;
    add(_numberText);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (position != targetPosition) {
      isMoving = true;
      moveProgress = (moveProgress + dt / moveDuration).clamp(0.0, 1.0);

      // Use ease out for smooth deceleration
      final t = _easeOutCubic(moveProgress);
      final lerpVector = startPosition + (targetPosition - startPosition) * t;
      position.setFrom(lerpVector);

      if (moveProgress >= 1.0) {
        position.setFrom(targetPosition);
        isMoving = false;
        moveProgress = 0.0;
      }
    }
  }

  double _easeOutCubic(double t) {
    final t1 = t - 1.0;
    return t1 * t1 * t1 + 1.0;
  }

  void moveTo(Vector2 newPosition) {
    if (position != newPosition) {
      startPosition = position.clone();
      targetPosition = newPosition.clone();
      moveProgress = 0.0;
    }
  }

  @override
  bool onTapDown(TapDownEvent event) {
    if (!isEmpty && !isMoving && game.canMoveTile(this)) {
      game.onTileTapped(this);
    }
    return true;
  }

  @override
  void onHoverEnter() {
    if (!isEmpty && game.canMoveTile(this)) {
      isHovered = true;
    }
  }

  @override
  void onHoverExit() {
    isHovered = false;
  }

  @override
  void render(Canvas canvas) {
    final rect = size.toRect();
    if (!isEmpty) {
      // Draw tile background with shadow
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect.deflate(2), const Radius.circular(8)),
        _paint,
      );

      // Draw the inner background for number
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect.deflate(4), const Radius.circular(6)),
        _textBgPaint,
      );

      // Draw movement indicator if the tile can be moved
      if (game.canMoveTile(this)) {
        final indicatorPaint =
            Paint()
              ..color = const Color(0xFF4CAF50)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3;

        canvas.drawRRect(
          RRect.fromRectAndRadius(rect.deflate(2), const Radius.circular(7)),
          indicatorPaint,
        );
      }
    }
  }
}
