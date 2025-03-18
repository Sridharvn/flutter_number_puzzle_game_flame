import 'dart:math';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_number_puzzle/components/restart_button.dart';
import 'package:flutter_number_puzzle/components/tile.dart';
import 'package:flutter_number_puzzle/theme/app_theme.dart';

class NumberPuzzleGame extends FlameGame {
  final int gridSize;
  final double tileGap = 10.0;
  List<Tile> tiles = [];
  int moves = 0;
  bool _isGameStarted = false;
  bool _isAnyTileAnimating = false;
  late TextComponent _movesText;
  late TextComponent _instructionsText;
  Function? onShowSurrenderConfirmation;
  Function? onGameComplete;
  Function(int)? onMovesUpdated;

  // Undo/redo state
  List<List<int>> _moveHistory = [];
  int _currentMoveIndex = -1;

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

    _initializeTiles();
  }

  void _initializeTiles() {
    tiles.clear();
    removeWhere((component) => component is Tile);
    _moveHistory.clear();
    _currentMoveIndex = -1;

    double tileSize = _calculateTileSize();

    for (int i = 0; i < gridSize * gridSize; i++) {
      final tile = Tile(i + 1, this);
      tile.size = Vector2.all(tileSize);
      tiles.add(tile);
      add(tile);
    }
    _positionTiles();

    // Record initial state
    _moveHistory.add(tiles.map((t) => t.number).toList());
    _currentMoveIndex = 0;
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
    if (!_isGameStarted || _isAnyTileAnimating) return false;
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
    _recordMove();

    if (_isComplete()) {
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
    _isGameStarted = false;
    shuffleTiles();
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

  void _recordMove() {
    moves++;
    _updateMovesText();
    // When making a new move, clear any redo history
    if (_currentMoveIndex < _moveHistory.length - 1) {
      _moveHistory = _moveHistory.sublist(0, _currentMoveIndex + 1);
    }
    _moveHistory.add(tiles.map((t) => t.number).toList());
    _currentMoveIndex = _moveHistory.length - 1;
  }

  bool canUndo() {
    return _currentMoveIndex > 0;
  }

  bool canRedo() {
    return _currentMoveIndex < _moveHistory.length - 1;
  }

  Future<void> undo() async {
    if (!canUndo() || _isAnyTileAnimating) return;

    _currentMoveIndex--;
    List<int> previousState = _moveHistory[_currentMoveIndex];
    await _applyState(previousState);
    moves--;
    _updateMovesText();
  }

  Future<void> redo() async {
    if (!canRedo() || _isAnyTileAnimating) return;

    _currentMoveIndex++;
    List<int> nextState = _moveHistory[_currentMoveIndex];
    await _applyState(nextState);
    moves++;
    _updateMovesText();
  }

  Future<void> _applyState(List<int> state) async {
    for (int i = 0; i < state.length; i++) {
      int currentPos = tiles.indexWhere((t) => t.number == state[i]);
      if (currentPos != i) {
        await tiles[currentPos].moveTo(tiles[i].position);
        var temp = tiles[currentPos];
        tiles[currentPos] = tiles[i];
        tiles[i] = temp;
      }
    }
  }

  void surrender() {
    _isGameStarted = false;
    moves = 0;
    _updateMovesText();
    _initializeTiles();
  }
}
