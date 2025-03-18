import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_number_puzzle/components/game_over_overlay.dart';
import 'package:flutter_number_puzzle/components/game_start_overlay.dart';
import 'package:flutter_number_puzzle/game/number_puzzle_game.dart';
import 'package:flutter_number_puzzle/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) => runApp(const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Number Puzzle',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppTheme.primaryColor),
        useMaterial3: true,
      ),
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late NumberPuzzleGame game;
  bool showStartOverlay = true;
  bool showGameOverOverlay = false;
  int moves = 0;

  @override
  void initState() {
    super.initState();
    game = NumberPuzzleGame(gridSize: 3);
    game.onGameComplete = () {
      setState(() {
        showGameOverOverlay = true;
      });
    };
    game.onMovesUpdated = (newMoves) {
      setState(() {
        moves = newMoves;
      });
    };
    game.onShowSurrenderConfirmation = () {
      _showSurrenderConfirmation();
    };
  }

  void _showSurrenderConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Surrender?'),
          content: const Text(
              'Are you sure you want to give up? The solution will be shown.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Surrender'),
              onPressed: () {
                Navigator.of(context).pop();
                game.surrender();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          SafeArea(
            child: GameWidget(
              game: game,
              overlayBuilderMap: {
                'start': (context, game) =>
                    GameStartOverlay(game: game as NumberPuzzleGame),
                'gameOver': (context, game) => GameOverOverlay(
                      game: game as NumberPuzzleGame,
                      moves: moves,
                    ),
              },
              initialActiveOverlays: const ['start'],
            ),
          ),
        ],
      ),
    );
  }
}
