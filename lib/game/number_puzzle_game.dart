import 'dart:math';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_number_puzzle/components/restart_button.dart';
import 'package:flutter_number_puzzle/components/surrender_button.dart';
import 'package:flutter_number_puzzle/components/tile.dart';
import 'package:flutter_number_puzzle/theme/app_theme.dart';

class NumberPuzzleGame extends FlameGame {
  final int gridSize;
  final double tileGap = 10.0;
  List<Tile> tiles = [];
  int moves = 0;
  bool _isGameStarted = false;
  bool _isSolving = false;
  bool _isAnyTileAnimating = false; // Add this line
  late TextComponent _movesText;
  late TextComponent _instructionsText;
  Function? onGameComplete;
  Function(int)? onMovesUpdated;
  Function? onShowSurrenderConfirmation;

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

    _movesText = TextComponent(
      text: "Moves: 0",
      position: Vector2(20, 50),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 20,
          color: AppTheme.textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );

    add(_instructionsText);
    add(_movesText);
    add(RestartButton(this)..position = Vector2(20, size.y - 60));
    add(SurrenderButton(this));

    _initializeTiles();
  }

  void _initializeTiles() {
    tiles.clear();
    removeWhere((component) => component is Tile);

    double tileSize = _calculateTileSize();

    for (int i = 0; i < gridSize * gridSize; i++) {
      final tile = Tile(i + 1, this);
      tile.size = Vector2.all(tileSize);
      tiles.add(tile);
      add(tile);
    }
    _positionTiles();
  }

  double _calculateTileSize() {
    double minDimension = min(size.x, size.y - 140); // Account for UI elements
    return (minDimension - (gridSize + 1) * tileGap) / gridSize;
  }

  void _positionTiles() {
    double tileSize = _calculateTileSize();
    double startX =
        (size.x - (tileSize * gridSize + tileGap * (gridSize - 1))) / 2;
    double startY = 100; // Adjusted to account for text components

    for (int i = 0; i < tiles.length; i++) {
      int row = i ~/ gridSize;
      int col = i % gridSize;
      tiles[i].position = Vector2(
        startX + col * (tileSize + tileGap),
        startY + row * (tileSize + tileGap),
      );
    }
  }

  @override
  void onGameResize(Vector2 gameSize) {
    super.onGameResize(gameSize);
    if (tiles.isNotEmpty) {
      double tileSize = _calculateTileSize();
      for (var tile in tiles) {
        tile.size = Vector2.all(tileSize);
      }
      _positionTiles();
    }
  }

  void shuffleTiles() {
    if (_isSolving) return;

    final random = Random();
    for (int i = tiles.length - 1; i > 0; i--) {
      int j = random.nextInt(i + 1);
      _swapTiles(i, j);
    }

    // Ensure puzzle is solvable
    if (!_isSolvable()) {
      int index1 = 0;
      int index2 = 1;
      _swapTiles(index1, index2);
    }

    moves = 0;
    _updateMovesText();
    _isGameStarted = true;
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
    if (!_isGameStarted || _isSolving || _isAnyTileAnimating)
      return false; // Add _isAnyTileAnimating check
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
    moves++;
    _updateMovesText();

    if (_isComplete() && !_isSolving) {
      onGameComplete?.call();
    }

    return targetPos;
  }

  void _updateMovesText() {
    _movesText.text = "Moves: $moves";
    onMovesUpdated?.call(moves);
  }

  bool _isComplete() {
    for (int i = 0; i < tiles.length; i++) {
      if (tiles[i].number != i + 1) return false;
    }
    return true;
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
          tiles.indexWhere((t) => t.number == gridSize * gridSize) ~/ gridSize;
      return (inversions + emptyTileRow) % 2 == 1;
    }
  }

  void restart() {
    if (_isSolving) return;
    _isGameStarted = false;
    shuffleTiles();
  }

  void showSurrenderConfirmation() {
    if (!_isGameStarted || _isSolving) return;
    onShowSurrenderConfirmation?.call();
  }

  Future<void> surrender() async {
    if (!_isGameStarted || _isSolving) return;
    _isSolving = true;

    // Animate solution
    while (!_isComplete()) {
      await _moveTowardsSolution();
      await Future.delayed(const Duration(milliseconds: 300));
    }

    _isSolving = false;
    onGameComplete?.call();
  }

  Future<void> _moveTowardsSolution() async {
    // Find the next tile that's out of place
    for (int targetPos = 0; targetPos < tiles.length; targetPos++) {
      int targetNumber = targetPos + 1;
      if (targetNumber == gridSize * gridSize) continue; // Skip empty tile

      int currentIndex = tiles.indexWhere((t) => t.number == targetNumber);
      if (currentIndex != targetPos) {
        // This tile needs to move
        int emptyIndex =
            tiles.indexWhere((t) => t.number == gridSize * gridSize);

        // If empty tile is not adjacent to the target tile
        while (!_areAdjacent(currentIndex, emptyIndex)) {
          // Move empty tile towards the target
          int emptyRow = emptyIndex ~/ gridSize;
          int emptyCol = emptyIndex % gridSize;
          int targetRow = currentIndex ~/ gridSize;
          int targetCol = currentIndex % gridSize;

          // Decide which direction to move the empty tile
          int moveIndex;
          if (emptyRow != targetRow) {
            moveIndex =
                emptyIndex + (emptyRow < targetRow ? gridSize : -gridSize);
          } else {
            moveIndex = emptyIndex + (emptyCol < targetCol ? 1 : -1);
          }

          // Move the tile into the empty space
          if (canMoveTile(tiles[moveIndex])) {
            await tiles[moveIndex].animateMove();
            return; // Return after one move
          }
        }

        // Move the target tile if it's adjacent to empty space
        if (canMoveTile(tiles[currentIndex])) {
          await tiles[currentIndex].animateMove();
          return; // Return after one move
        }
      }
    }
  }

  bool _areAdjacent(int index1, int index2) {
    int row1 = index1 ~/ gridSize;
    int col1 = index1 % gridSize;
    int row2 = index2 ~/ gridSize;
    int col2 = index2 % gridSize;

    return (row1 == row2 && (col1 - col2).abs() == 1) ||
        (col1 == col2 && (row1 - row2).abs() == 1);
  }

  void restartGame() => restart();

  void resetGame() {
    _isGameStarted = false;
    moves = 0;
    _updateMovesText();
    _initializeTiles();
  }

  void startGame() {
    if (!_isGameStarted) {
      shuffleTiles();
    }
  }

  // Add these methods to manage animation state
  void setTileAnimating(bool isAnimating) {
    _isAnyTileAnimating = isAnimating;
  }
}
