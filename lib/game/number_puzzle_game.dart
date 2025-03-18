import 'dart:math';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_number_puzzle/components/tile.dart';
import 'package:flutter_number_puzzle/theme/app_theme.dart';

class NumberPuzzleGame extends FlameGame {
  final int gridSize;
  final double tileGap = 10.0;
  List<Tile> tiles = [];
  int moves = 0;
  bool _isGameStarted = false;
  late TextComponent _movesText;
  late TextComponent _instructionsText;
  late TextComponent _completionText;
  Function? onGameComplete;
  Function(int)? onMovesUpdated;

  NumberPuzzleGame({this.gridSize = 3});

  @override
  Color backgroundColor() => AppTheme.backgroundColor;

  @override
  Future<void> onLoad() async {
    _instructionsText = TextComponent(
      text: "Tap tiles to move them",
      position: Vector2(20, 20),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 20,
          color: AppTheme.textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
    add(_instructionsText);

    _movesText = TextComponent(
      position: Vector2(20, 40),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 24,
          color: AppTheme.textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    add(_movesText);

    _completionText = TextComponent(
      text: "Puzzle Completed!",
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 32,
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void startGame() {
    _isGameStarted = true;
    initializeTiles();
    shuffleTiles();
    _updateMovesText();
  }

  void initializeTiles() {
    tiles.clear();
    removeWhere((component) => component is Tile);

    double tileSize = (size.x - (gridSize + 1) * tileGap) / gridSize;
    for (int i = 0; i < gridSize * gridSize; i++) {
      final tile = Tile(i + 1, this);
      tile.size = Vector2.all(tileSize);
      tiles.add(tile);
      add(tile);
    }
    _positionTiles();
  }

  void _positionTiles() {
    double startX = tileGap;
    double startY = 80; // Adjusted to account for text components
    double tileSize = (size.x - (gridSize + 1) * tileGap) / gridSize;

    for (int i = 0; i < tiles.length; i++) {
      int row = i ~/ gridSize;
      int col = i % gridSize;
      tiles[i].position = Vector2(
        startX + col * (tileSize + tileGap),
        startY + row * (tileSize + tileGap),
      );
    }
  }

  void shuffleTiles() {
    final random = Random();
    for (int i = tiles.length - 1; i > 0; i--) {
      int j = random.nextInt(i + 1);
      _swapTiles(i, j);
    }

    // Ensure puzzle is solvable
    if (!_isSolvable()) {
      int index1 = 0;
      int index2 = 1;
      if (tiles[index1].number != gridSize * gridSize &&
          tiles[index2].number != gridSize * gridSize) {
        _swapTiles(index1, index2);
      }
    }
  }

  bool _isSolvable() {
    int inversions = 0;
    for (int i = 0; i < tiles.length - 1; i++) {
      for (int j = i + 1; j < tiles.length; j++) {
        if (tiles[i].number != gridSize * gridSize &&
            tiles[j].number != gridSize * gridSize &&
            tiles[i].number > tiles[j].number) {
          inversions++;
        }
      }
    }

    if (gridSize % 2 == 1) {
      return inversions % 2 == 0;
    } else {
      int emptyTileRow =
          tiles.indexWhere((tile) => tile.number == gridSize * gridSize) ~/
              gridSize;
      return (inversions + emptyTileRow) % 2 == 0;
    }
  }

  void _swapTiles(int i, int j) {
    final tempPos = tiles[i].position.clone();
    tiles[i].position = tiles[j].position;
    tiles[j].position = tempPos;

    final temp = tiles[i];
    tiles[i] = tiles[j];
    tiles[j] = temp;
  }

  bool canMoveTile(Tile tile) {
    if (!_isGameStarted) return false;

    int emptyIndex = tiles.indexWhere((t) => t.number == gridSize * gridSize);
    int tileIndex = tiles.indexOf(tile);

    int emptyRow = emptyIndex ~/ gridSize;
    int emptyCol = emptyIndex % gridSize;
    int tileRow = tileIndex ~/ gridSize;
    int tileCol = tileIndex % gridSize;

    return (emptyRow == tileRow && (emptyCol - tileCol).abs() == 1) ||
        (emptyCol == tileCol && (emptyRow - tileRow).abs() == 1);
  }

  Vector2 getTargetPosition(Tile tile) {
    int tileIndex = tiles.indexOf(tile);
    int emptyIndex = tiles.indexWhere((t) => t.number == gridSize * gridSize);
    Vector2 targetPos = tiles[emptyIndex].position.clone();

    _swapTiles(tileIndex, emptyIndex);
    return targetPos;
  }

  void onTileMoved() {
    moves++;
    _updateMovesText();
    onMovesUpdated?.call(moves);

    if (_isPuzzleSolved()) {
      _showCompletionText();
      onGameComplete?.call();
    }
  }

  void _updateMovesText() {
    _movesText.text = 'Moves: $moves';
  }

  void _showCompletionText() {
    _completionText.position = Vector2(size.x / 2, size.y - 100);
    add(_completionText);
  }

  bool _isPuzzleSolved() {
    for (int i = 0; i < tiles.length; i++) {
      if (tiles[i].number != i + 1) return false;
    }
    return true;
  }

  void resetGame() {
    moves = 0;
    _isGameStarted = false;
    removeWhere(
        (component) => component is Tile || component == _completionText);
    startGame();
  }
}
