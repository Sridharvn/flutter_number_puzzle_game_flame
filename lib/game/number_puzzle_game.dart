import 'dart:math';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../components/tile.dart';

class NumberPuzzleGame extends FlameGame {
  static const int gridSize = 4;
  static const double padding = 10.0;
  late List<Tile> tiles;
  late Vector2 boardPosition;
  int moves = 0;
  bool isComplete = false;
  final Paint _borderPaint =
      Paint()
        ..color = const Color(0xFF0D47A1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0;

  late TextComponent _movesText;
  late TextComponent _completionText;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Initialize board position
    final tileSize = 80.0;
    final boardSize = (tileSize + padding) * gridSize - padding;
    boardPosition = Vector2((size.x - boardSize) / 2, (size.y - boardSize) / 2);

    // Create and shuffle tiles
    initializeTiles();

    // Add moves counter
    _movesText = TextComponent(
      position: Vector2(20, 40),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 24,
          color: Color(0xFF1565C0),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    add(_movesText);

    // Add completion text (hidden initially)
    _completionText = TextComponent(
      text: "Puzzle Completed!",
      position: Vector2(size.x / 2, size.y - 100),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 32,
          color: Color(0xFF1565C0),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    add(_completionText);
    _completionText.removeFromParent(); // Hide initially
  }

  void initializeTiles() {
    tiles = List.generate(gridSize * gridSize, (index) {
      final tile = Tile(
        index + 1,
        this,
        isEmpty: index == gridSize * gridSize - 1,
      );

      final row = index ~/ gridSize;
      final col = index % gridSize;
      tile.position = Vector2(
        boardPosition.x + col * (tile.size.x + padding),
        boardPosition.y + row * (tile.size.y + padding),
      );

      return tile;
    });

    // Shuffle tiles
    final random = Random();
    for (int i = tiles.length - 2; i > 0; i--) {
      final j = random.nextInt(i + 1);
      if (j != tiles.length - 1 && i != tiles.length - 1) {
        final tempPos = tiles[i].position;
        tiles[i].position = tiles[j].position;
        tiles[j].position = tempPos;

        final temp = tiles[i];
        tiles[i] = tiles[j];
        tiles[j] = temp;
      }
    }

    // Add all tiles to game
    tiles.forEach(add);
  }

  void onTileTapped(Tile tile) {
    final emptyTile = tiles.firstWhere((t) => t.isEmpty);
    final tileIndex = tiles.indexOf(tile);
    final emptyIndex = tiles.indexOf(emptyTile);

    if (canMove(tileIndex, emptyIndex)) {
      // Swap positions
      final tempPos = tile.position;
      tile.position = emptyTile.position;
      emptyTile.position = tempPos;

      // Update tiles list
      tiles[tileIndex] = emptyTile;
      tiles[emptyIndex] = tile;

      moves++;
      checkCompletion();
    }
  }

  bool canMove(int tileIndex, int emptyIndex) {
    final tileRow = tileIndex ~/ gridSize;
    final tileCol = tileIndex % gridSize;
    final emptyRow = emptyIndex ~/ gridSize;
    final emptyCol = emptyIndex % gridSize;

    return (tileRow == emptyRow && (tileCol - emptyCol).abs() == 1) ||
        (tileCol == emptyCol && (tileRow - emptyRow).abs() == 1);
  }

  void checkCompletion() {
    bool completed = true;
    for (int i = 0; i < tiles.length - 1; i++) {
      if (tiles[i].number != i + 1) {
        completed = false;
        break;
      }
    }

    isComplete = completed;
    if (completed) {
      add(_completionText);
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Draw board border
    final boardSize = (80.0 + padding) * gridSize - padding;
    final rect = Rect.fromLTWH(
      boardPosition.x - padding,
      boardPosition.y - padding,
      boardSize + padding * 2,
      boardSize + padding * 2,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(12)),
      _borderPaint,
    );

    // Update moves text
    _movesText.text = "Moves: $moves";
  }
}
