import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../game/number_puzzle_game.dart';

class SurrenderButton extends PositionComponent
    with TapCallbacks, HoverCallbacks {
  final NumberPuzzleGame game;
  bool isHovered = false;
  final Paint _buttonPaint = Paint()..color = Colors.red.shade800;
  final Paint _hoverPaint = Paint()..color = Colors.red.shade600;
  late final TextComponent _buttonText;

  SurrenderButton(this.game) : super(size: Vector2(120, 40)) {
    _buttonText = TextComponent(
      text: "Surrender",
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 20,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  void onMount() {
    super.onMount();
    _buttonText.position = size / 2;
    _buttonText.anchor = Anchor.center;
    add(_buttonText);
  }

  @override
  void onGameResize(Vector2 gameSize) {
    super.onGameResize(gameSize);
    position = Vector2(
      gameSize.x - size.x - 20,
      20,
    );
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        size.toRect(),
        const Radius.circular(8),
      ),
      isHovered ? _hoverPaint : _buttonPaint,
    );
    super.render(canvas);
  }

  @override
  bool onTapDown(TapDownEvent event) {
    game.showSurrenderConfirmation();
    return true;
  }

  @override
  bool onHoverEnter() {
    isHovered = true;
    return true;
  }

  @override
  bool onHoverExit() {
    isHovered = false;
    return true;
  }
}
