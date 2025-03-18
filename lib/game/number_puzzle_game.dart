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
  late TextComponent _instructionsText;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Initialize board position
    final tileSize = 80.0;
    final boardSize = (tileSize + padding) * gridSize - padding;
    boardPosition = Vector2((size.x - boardSize) / 2, (size.y - boardSize) / 2);

    // Create and shuffle tiles
    initializeTiles();

    // Add instructions
    _instructionsText = TextComponent(
      text:
          "Tap tiles next to the empty space to move them.\nArrange numbers from 1-15 in order!",
      position: Vector2(size.x / 2, 80),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 20,
          color: Color(0xFF1565C0),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    add(_instructionsText);

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
    _updateMovesText();
  }

  void initializeTiles() {
    // Create tiles in solved state first
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

    // Shuffle tiles until we get a solvable configuration
    do {
      shuffleTiles();
    } while (!isSolvable());

    // Add all tiles to game
    tiles.forEach(add);
  }

  void shuffleTiles() {
    final random = Random();
    // Fisher-Yates shuffle, excluding the empty tile
    for (int i = tiles.length - 2; i > 0; i--) {
      final j = random.nextInt(i + 1);
      if (j != tiles.length - 1) {
        // Don't move empty tile during shuffle
        final tempPos = tiles[i].position;
        tiles[i].position = tiles[j].position;
        tiles[j].position = tempPos;

        final temp = tiles[i];
        tiles[i] = tiles[j];
        tiles[j] = temp;
      }
    }
  }

  bool isSolvable() {
    int inversions = 0;
    int emptyTileRow = 0;

    // Create flat list of numbers for counting inversions
    List<int> numbers = [];
    for (int i = 0; i < tiles.length; i++) {
      if (!tiles[i].isEmpty) {
        numbers.add(tiles[i].number);
      } else {
        emptyTileRow = i ~/ gridSize;
      }
    }

    // Count inversions
    for (int i = 0; i < numbers.length - 1; i++) {
      for (int j = i + 1; j < numbers.length; j++) {
        if (numbers[i] > numbers[j]) {
          inversions++;
        }
      }
    }

    // For a 4x4 puzzle:
    // If empty tile is on even row from bottom and inversions odd, solvable
    // If empty tile is on odd row from bottom and inversions even, solvable
    final emptyTileRowFromBottom = gridSize - 1 - emptyTileRow;
    return (emptyTileRowFromBottom % 2 == 0 && inversions % 2 == 1) ||
        (emptyTileRowFromBottom % 2 == 1 && inversions % 2 == 0);
  }

  void onTileTapped(Tile tile) {
    if (!canMoveTile(tile)) return;

    final tileIndex = tiles.indexOf(tile);
    final emptyIndex = tiles.indexWhere((t) => t.isEmpty);

    // Swap positions
    final tilePos = tile.position.clone();
    tile.position = tiles[emptyIndex].position.clone();
    tiles[emptyIndex].position = tilePos;

    // Update tiles list
    final temp = tiles[tileIndex];
    tiles[tileIndex] = tiles[emptyIndex];
    tiles[emptyIndex] = temp;

    moves++;
    _updateMovesText();

    checkCompletion(); // Fixed method name here
  }

  bool canMoveTile(Tile tile) {
    final tileIndex = tiles.indexOf(tile);
    final emptyIndex = tiles.indexWhere((t) => t.isEmpty);

    // Check if tile is adjacent to empty space
    final row = tileIndex ~/ gridSize;
    final col = tileIndex % gridSize;
    final emptyRow = emptyIndex ~/ gridSize;
    final emptyCol = emptyIndex % gridSize;

    return (row == emptyRow && (col - emptyCol).abs() == 1) ||
        (col == emptyCol && (row - emptyRow).abs() == 1);
  }

  void checkCompletion() {
    bool completed = true;
    for (int i = 0; i < tiles.length - 1; i++) {
      final row = i ~/ gridSize;
      final col = i % gridSize;
      final tileAtPosition = tiles.firstWhere(
        (t) =>
            t.position ==
            Vector2(
              boardPosition.x + col * (tiles[0].size.x + padding),
              boardPosition.y + row * (tiles[0].size.y + padding),
            ),
      );

      if (!tileAtPosition.isEmpty && tileAtPosition.number != i + 1) {
        completed = false;
        break;
      }
    }

    // Check if empty tile is in the last position
    final lastTile = tiles.firstWhere(
      (t) =>
          t.position ==
          Vector2(
            boardPosition.x + (gridSize - 1) * (tiles[0].size.x + padding),
            boardPosition.y + (gridSize - 1) * (tiles[0].size.y + padding),
          ),
    );
    completed = completed && lastTile.isEmpty;

    isComplete = completed;
    if (completed) {
      add(_completionText);
    }
  }

  void _updateMovesText() {
    _movesText.text = "Moves: $moves";
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
