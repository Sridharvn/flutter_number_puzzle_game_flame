import 'dart:math' as math;
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
  static const double moveDuration = 0.25; // Slightly longer movement duration
  double moveProgress = 0.0;
  Vector2 startPosition = Vector2.zero();

  Tile(this.number, this.game, {this.isEmpty = false})
    : super(size: Vector2.all(80)) {
    _numberText = TextComponent(
      text: isEmpty ? '' : number.toString(),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 32,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    _numberText.anchor = Anchor.center;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _numberText.position = size / 2;
    add(_numberText);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (position != targetPosition) {
      isMoving = true;
      moveProgress = (moveProgress + dt / moveDuration).clamp(0.0, 1.0);
      final newPos = Vector2.zero();
      newPos.x =
          startPosition.x +
          (targetPosition.x - startPosition.x) * _easeOutElastic(moveProgress);
      newPos.y =
          startPosition.y +
          (targetPosition.y - startPosition.y) * _easeOutElastic(moveProgress);
      position = newPos;

      if (moveProgress >= 1.0) {
        isMoving = false;
        moveProgress = 0.0;
        position = targetPosition.clone();
      }
    }
  }

  // Elastic easing function for more playful movement
  double _easeOutElastic(double t) {
    const c4 = (2.0 * math.pi) / 3.0;
    if (t == 0.0 || t == 1.0) return t;
    return math.pow(2.0, -10.0 * t) * math.sin((t * 10.0 - 0.75) * c4) + 1.0;
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
    if (isEmpty) return;

    final rect = size.toRect();
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));

    // Draw shadow
    final shadowPaint =
        Paint()
          ..color = Colors.black.withOpacity(0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawRRect(rrect.shift(const Offset(0, 2)), shadowPaint);

    // Draw tile with hover effect
    final tilePaint =
        Paint()..color = isHovered ? const Color(0xFF1976D2) : _paint.color;
    canvas.drawRRect(rrect, tilePaint);

    // Draw inner background for number
    final innerRect = rect.deflate(8);
    final innerRRect = RRect.fromRectAndRadius(
      innerRect,
      const Radius.circular(4),
    );
    canvas.drawRRect(innerRRect, _textBgPaint);
  }
}
