import 'dart:math';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import '../components/tile.dart';
import '../components/restart_button.dart';

class NumberPuzzleGame extends FlameGame {
  static const int gridSize = 4;
  static const double padding = 10.0;
  late List<Tile> tiles;
  late Vector2 boardPosition;
  int moves = 0;
  bool isComplete = false;
  bool isMoving = false;
  bool _gameStarted = false;

  // Add move history
  final List<_GameMove> moveHistory = [];

  final Paint _borderPaint =
      Paint()
        ..color = const Color(0xFF0D47A1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0;

  late TextComponent _movesText;
  late TextComponent _completionText;
  late TextComponent _instructionsText;
  late ButtonComponent _undoButton;

  bool get gameStarted => _gameStarted;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Initialize board position
    final tileSize = 80.0;
    final boardSize = (tileSize + padding) * gridSize - padding;
    boardPosition = Vector2((size.x - boardSize) / 2, (size.y - boardSize) / 2);

    // Initialize the game but don't start yet
    initializeGame();

    // Add overlays
    overlays.add('start');
  }

  void startGame() {
    _gameStarted = true;
    overlays.remove('start');
    shuffleTiles();
  }

  void resetGame() {
    _gameStarted = false;
    moves = 0;
    isComplete = false;
    moveHistory.clear();
    initializeGame();
    overlays.remove('gameOver');
    overlays.add('start');
  }

  void initializeGame() {
    initializeTiles();

    // Add restart button
    final restartButton = RestartButton(this)
      ..position = Vector2(size.x - 140, 40);
    add(restartButton);

    // Add undo button
    _undoButton = ButtonComponent(
      button: RectangleComponent(
        size: Vector2(80, 40),
        paint: Paint()..color = const Color(0xFF1565C0),
      ),
      position: Vector2(size.x - 240, 40),
      onPressed: () => undoLastMove(),
      children: [
        TextComponent(
          text: 'Undo',
          position: Vector2(40, 20),
          anchor: Anchor.center,
          textRenderer: TextPaint(
            style: const TextStyle(
              fontSize: 24,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
    add(_undoButton);

    _instructionsText = TextComponent(
      text:
          "Tap tiles next to the empty space to move them.\nArrange numbers from 1-15 in order!",
      position: Vector2(size.x / 2, 120), // Changed from 80 to 120
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
      tile.targetPosition = tile.position.clone();

      return tile;
    });

    do {
      shuffleTiles();
    } while (!isSolvable());

    tiles.forEach(add);
  }

  void shuffleTiles() {
    final random = Random();
    for (int i = tiles.length - 2; i > 0; i--) {
      final j = random.nextInt(i + 1);
      if (j != tiles.length - 1) {
        final tempPos = tiles[i].position.clone();
        tiles[i].position = tiles[j].position.clone();
        tiles[j].position = tempPos;
        tiles[i].targetPosition = tiles[i].position.clone();
        tiles[j].targetPosition = tiles[j].position.clone();

        final temp = tiles[i];
        tiles[i] = tiles[j];
        tiles[j] = temp;
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    isMoving = tiles.any((tile) => tile.isMoving);
  }

  void onTileTapped(Tile tile) {
    if (!canMoveTile(tile) || isMoving) return;

    final tileIndex = tiles.indexOf(tile);
    final emptyIndex = tiles.indexWhere((t) => t.isEmpty);
    final emptyTile = tiles[emptyIndex];

    // Store move in history
    moveHistory.add(
      _GameMove(
        tileNumber: tile.number,
        originalPosition: tile.position.clone(),
        targetPosition: emptyTile.position.clone(),
      ),
    );

    // Store original positions
    final tileOriginalPos = tile.position.clone();

    // Move the tiles
    tile.moveTo(emptyTile.position.clone());
    emptyTile.position = tileOriginalPos;
    emptyTile.targetPosition = tileOriginalPos;
    emptyTile.startPosition = tileOriginalPos;

    // Update tiles list
    tiles[tileIndex] = emptyTile;
    tiles[emptyIndex] = tile;

    moves++;
    _updateMovesText();

    // Wait for movement duration before checking completion
    Future.delayed(
      Duration(milliseconds: (Tile.moveDuration * 1000).toInt()),
      () {
        if (!isComplete) {
          checkCompletion();
        }
      },
    );
  }

  bool canMoveTile(Tile tile) {
    if (isMoving) return false;

    final tileIndex = tiles.indexOf(tile);
    final emptyIndex = tiles.indexWhere((t) => t.isEmpty);

    final row = tileIndex ~/ gridSize;
    final col = tileIndex % gridSize;
    final emptyRow = emptyIndex ~/ gridSize;
    final emptyCol = emptyIndex % gridSize;

    return (row == emptyRow && (col - emptyCol).abs() == 1) ||
        (col == emptyCol && (row - emptyRow).abs() == 1);
  }

  bool isSolvable() {
    int inversions = 0;
    int emptyTileRow = 0;

    List<int> numbers = [];
    for (int i = 0; i < tiles.length; i++) {
      if (!tiles[i].isEmpty) {
        numbers.add(tiles[i].number);
      } else {
        emptyTileRow = i ~/ gridSize;
      }
    }

    for (int i = 0; i < numbers.length - 1; i++) {
      for (int j = i + 1; j < numbers.length; j++) {
        if (numbers[i] > numbers[j]) {
          inversions++;
        }
      }
    }

    final emptyTileRowFromBottom = gridSize - 1 - emptyTileRow;
    return (emptyTileRowFromBottom % 2 == 0 && inversions % 2 == 1) ||
        (emptyTileRowFromBottom % 2 == 1 && inversions % 2 == 0);
  }

  void _updateMovesText() {
    _movesText.text = 'Moves: $moves';
  }

  void checkCompletion() {
    if (isMoving) return;

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

    final lastTile = tiles.firstWhere(
      (t) =>
          t.position ==
          Vector2(
            boardPosition.x + (gridSize - 1) * (tiles[0].size.x + padding),
            boardPosition.y + (gridSize - 1) * (tiles[0].size.y + padding),
          ),
    );

    if (completed && lastTile.isEmpty) {
      isComplete = true;
      add(_completionText);
      overlays.add('gameOver');
    }
  }

  void undoLastMove() {
    if (moveHistory.isEmpty || isMoving || isComplete) return;

    final lastMove = moveHistory.removeLast();

    // Get the tiles involved in the last move
    final tile = tiles.firstWhere((t) => t.number == lastMove.tileNumber);
    final emptyTile = tiles.firstWhere((t) => t.isEmpty);

    // Swap their positions back
    final tileIndex = tiles.indexOf(tile);
    final emptyIndex = tiles.indexOf(emptyTile);

    tile.moveTo(lastMove.originalPosition);
    emptyTile.position = lastMove.targetPosition;
    emptyTile.targetPosition = lastMove.targetPosition;
    emptyTile.startPosition = lastMove.targetPosition;

    // Update tiles list
    tiles[tileIndex] = emptyTile;
    tiles[emptyIndex] = tile;

    moves--;
    _updateMovesText();
  }

  void restartGame() {
    // Remove completion text if present
    if (isComplete) {
      remove(_completionText);
      isComplete = false;
    }

    // Reset moves counter
    moves = 0;
    _updateMovesText();

    // Reset and shuffle tiles
    for (final tile in tiles) {
      tile.removeFromParent();
    }
    initializeTiles();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Draw board border
    final boardSize = (tiles[0].size.x + padding) * gridSize - padding;
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
  }

  void checkGameCompletion() {
    if (!isComplete) {
      bool completed = true;
      for (int i = 0; i < tiles.length - 1; i++) {
        if (tiles[i].number != i + 1) {
          completed = false;
          break;
        }
      }

      if (completed) {
        isComplete = true;
        overlays.add('gameOver');
      }
    }
  }
}

// Add class to store move information
class _GameMove {
  final int tileNumber;
  final Vector2 originalPosition;
  final Vector2 targetPosition;

  _GameMove({
    required this.tileNumber,
    required this.originalPosition,
    required this.targetPosition,
  });
}
