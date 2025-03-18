import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:flutter_number_puzzle/game/number_puzzle_game.dart';
import 'package:flutter_number_puzzle/theme/app_theme.dart';

class Tile extends RectangleComponent with TapCallbacks {
  final int number;
  final NumberPuzzleGame game;
  late TextComponent _textComponent;
  bool _isAnimating = false;

  Tile(this.number, this.game)
      : super(
            paint: Paint()
              ..color = number == game.gridSize * game.gridSize
                  ? Colors.transparent
                  : AppTheme.tileColor,
            children: []);

  @override
  Future<void> onLoad() async {
    if (number < game.gridSize * game.gridSize) {
      _textComponent = TextComponent(
        text: number.toString(),
        textRenderer: TextPaint(
          style: const TextStyle(
            fontSize: 32,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
      add(_textComponent);
    }
  }

  @override
  void onMount() {
    super.onMount();
    if (number < game.gridSize * game.gridSize) {
      _textComponent.position = size / 2;
      _textComponent.anchor = Anchor.center;
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    double tileSize =
        (game.size.x - (game.gridSize + 1) * game.tileGap) / game.gridSize;
    this.size = Vector2.all(tileSize);

    if (number < game.gridSize * game.gridSize && _textComponent.isMounted) {
      _textComponent.position = this.size / 2;
      _textComponent.anchor = Anchor.center;
    }
  }

  @override
  bool onTapDown(TapDownEvent event) {
    if (!_isAnimating && game.canMoveTile(this)) {
      _animateMove();
    }
    return false;
  }

  void _animateMove() {
    _isAnimating = true;
    Vector2 targetPosition = game.getTargetPosition(this);
    double moveSpeed = 600; // pixels per second
    double distance = position.distanceTo(targetPosition);
    double duration = distance / moveSpeed;

    add(
      MoveToEffect(
        targetPosition,
        EffectController(duration: duration),
        onComplete: () {
          _isAnimating = false;
          game.onTileMoved();
        },
      ),
    );
  }

  @override
  void render(Canvas canvas) {
    if (number < game.gridSize * game.gridSize) {
      final rect = Rect.fromLTWH(0, 0, size.x, size.y);
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(12));

      // Draw shadow
      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawRRect(rrect.shift(const Offset(0, 2)), shadowPaint);

      // Draw tile background
      final bgPaint = Paint()..color = AppTheme.tileColor;
      canvas.drawRRect(rrect, bgPaint);
    }
  }
}
