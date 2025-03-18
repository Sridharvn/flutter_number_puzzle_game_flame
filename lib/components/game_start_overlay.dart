import 'package:flutter/material.dart';
import 'package:flutter_number_puzzle/game/number_puzzle_game.dart';
import 'package:flutter_number_puzzle/theme/app_theme.dart';

class GameStartOverlay extends StatefulWidget {
  final NumberPuzzleGame game;

  const GameStartOverlay({super.key, required this.game});

  @override
  State<GameStartOverlay> createState() => _GameStartOverlayState();
}

class _GameStartOverlayState extends State<GameStartOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        color: Colors.black.withOpacity(0.7),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Number Puzzle',
                  style: AppTheme.headlineStyle,
                ),
                const SizedBox(height: 20),
                Text(
                  'Arrange the numbers in ascending order.\nClick tiles next to the empty space to move them.',
                  textAlign: TextAlign.center,
                  style: AppTheme.bodyStyle,
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    _controller.reverse().then((_) {
                      widget.game.startGame();
                    });
                  },
                  style: AppTheme.primaryButtonStyle,
                  child: Text('Start Game',
                      style: AppTheme.bodyStyle.copyWith(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
