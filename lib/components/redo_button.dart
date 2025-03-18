import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../game/number_puzzle_game.dart';

class RedoButton extends PositionComponent with TapCallbacks, HoverCallbacks {
  final NumberPuzzleGame game;
  bool isHovered = false;
  final Paint _buttonPaint = Paint()..color = Colors.blue.shade800;
  final Paint _inactivePaint = Paint()..color = Colors.grey.shade600;
  final Paint _hoverPaint = Paint()..color = Colors.blue.shade600;
  late final TextComponent _buttonText;

  RedoButton(this.game) : super(size: Vector2(80, 40));

  @override
  Future<void> onLoad() async {
    _buttonText = TextComponent(
      text: "Redo",
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 20,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    _buttonText.position = size / 2;
    _buttonText.anchor = Anchor.center;
    add(_buttonText);
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        size.toRect(),
        const Radius.circular(8),
      ),
      game.canRedo()
          ? (isHovered ? _hoverPaint : _buttonPaint)
          : _inactivePaint,
    );
    super.render(canvas);
  }

  @override
  bool onTapDown(TapDownEvent event) {
    game.redo();
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
