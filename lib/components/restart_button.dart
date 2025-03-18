import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../game/number_puzzle_game.dart';

class RestartButton extends PositionComponent
    with TapCallbacks, HoverCallbacks {
  final NumberPuzzleGame game;
  bool isHovered = false;
  final Paint _buttonPaint = Paint()..color = const Color(0xFF1565C0);
  final Paint _hoverPaint = Paint()..color = const Color(0xFF1976D2);
  late final TextComponent _buttonText;

  RestartButton(this.game) : super(size: Vector2(120, 40)) {
    _buttonText = TextComponent(
      text: "Restart",
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
  bool onTapDown(TapDownEvent event) {
    game.restartGame();
    return true;
  }

  @override
  void onHoverEnter() {
    isHovered = true;
  }

  @override
  void onHoverExit() {
    isHovered = false;
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(size.toRect(), const Radius.circular(8)),
      isHovered ? _hoverPaint : _buttonPaint,
    );
  }
}
