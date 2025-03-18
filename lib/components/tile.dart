import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../game/number_puzzle_game.dart';

class Tile extends PositionComponent with TapCallbacks, HoverCallbacks {
  final int number;
  final Paint _paint = Paint()..color = const Color(0xFF1565C0);
  final Paint _textBgPaint = Paint()..color = const Color(0xFFBBDEFB);
  final Paint _hoverPaint = Paint()..color = const Color(0xFF2196F3);
  late final TextComponent _numberText;
  final NumberPuzzleGame game;
  bool isEmpty;
  bool isHovered = false;

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
  }

  @override
  Future<void> onLoad() async {
    _numberText.position = size / 2;
    _numberText.anchor = Anchor.center;
    add(_numberText);
  }

  @override
  bool onTapDown(TapDownEvent event) {
    if (!isEmpty) {
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

    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));

    // Draw tile background
    canvas.drawRRect(
      rrect,
      isHovered && game.canMoveTile(this) ? _hoverPaint : _paint,
    );

    // Draw inner background
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
