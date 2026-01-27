import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() => runApp(const StroopTestApp());

class StroopTestApp extends StatelessWidget {
  const StroopTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stroop Test',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1A1A2E),
      ),
      home: const StroopTestScreen(),
    );
  }
}

enum GameState { start, playing, gameOver }

class ColorOption {
  final String name;
  final Color displayColor;
  final Color buttonColor;

  const ColorOption({
    required this.name,
    required this.displayColor,
    required this.buttonColor,
  });
}

const List<ColorOption> colorOptions = [
  ColorOption(
    name: 'Red',
    displayColor: Color(0xFFDC3545),
    buttonColor: Color(0xFFDC3545),
  ),
  ColorOption(
    name: 'Green',
    displayColor: Color(0xFF28A745),
    buttonColor: Color(0xFF28A745),
  ),
  ColorOption(
    name: 'Blue',
    displayColor: Color(0xFF007BFF),
    buttonColor: Color(0xFF007BFF),
  ),
  ColorOption(
    name: 'Grey',
    displayColor: Color(0xFF999999),
    buttonColor: Color(0xFF808080),
  ),
  ColorOption(
    name: 'Yellow',
    displayColor: Color(0xFFE6C619),
    buttonColor: Color(0xFFD4A017),
  ),
];

class StroopTestScreen extends StatefulWidget {
  const StroopTestScreen({super.key});

  @override
  State<StroopTestScreen> createState() => _StroopTestScreenState();
}

class _StroopTestScreenState extends State<StroopTestScreen> {
  static const int timeLimitMs = 10000;

  final Random _random = Random();

  GameState _gameState = GameState.start;
  int _wordIndex = 0;
  int _streak = 0;
  int _fillColorIndex = 0;
  String _endMessage = '';
  double _timerFraction = 1.0;
  Timer? _timer;
  int _timerElapsed = 0;

  void _startGame() {
    setState(() {
      _gameState = GameState.playing;
      _wordIndex = 0;
      _streak = 0;
    });
    _nextRound();
  }

  void _nextRound() {
    final wordIdx = _wordIndex % colorOptions.length;
    int fill;
    do {
      fill = _random.nextInt(colorOptions.length);
    } while (fill == wordIdx);

    setState(() {
      _fillColorIndex = fill;
      _timerFraction = 1.0;
      _timerElapsed = 0;
    });
    _wordIndex++;
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    const tick = Duration(milliseconds: 50);
    _timer = Timer.periodic(tick, (t) {
      _timerElapsed += 50;
      if (_timerElapsed >= timeLimitMs) {
        t.cancel();
        _endGame('Time ran out!');
      } else {
        setState(() {
          _timerFraction = 1.0 - (_timerElapsed / timeLimitMs);
        });
      }
    });
  }

  void _handleAnswer(int chosenIndex) {
    if (_gameState != GameState.playing) return;
    _timer?.cancel();

    if (chosenIndex == _fillColorIndex) {
      _streak++;
      _nextRound();
    } else {
      _endGame(
        'The answer was ${colorOptions[_fillColorIndex].name.toUpperCase()}.',
      );
    }
  }

  void _endGame(String reason) {
    _timer?.cancel();
    setState(() {
      _gameState = GameState.gameOver;
      _endMessage = reason;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: switch (_gameState) {
          GameState.start => _buildStartScreen(),
          GameState.playing => _buildGameScreen(),
          GameState.gameOver => _buildEndScreen(),
        },
      ),
    );
  }

  Widget _buildStartScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Stroop Test',
              style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Text.rich(
              TextSpan(
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFFAAAAAA),
                  height: 1.6,
                ),
                children: [
                  const TextSpan(
                    text:
                        'A colour word will appear on screen, but displayed in a ',
                  ),
                  const TextSpan(
                    text: 'different colour',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const TextSpan(text: '.\n\nYour task: identify the '),
                  const TextSpan(
                    text: 'colour of the text',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const TextSpan(text: ', not the word itself.\n\nYou have '),
                  const TextSpan(
                    text: '10 seconds',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const TextSpan(
                    text: ' per round. How long can you keep your streak?',
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            _buildActionButton('Start', _startGame),
          ],
        ),
      ),
    );
  }

  Widget _buildGameScreen() {
    final wordIdx = (_wordIndex - 1) % colorOptions.length;
    final word = colorOptions[wordIdx].name;
    final fillColor = colorOptions[_fillColorIndex].displayColor;
    final isWarning = _timerFraction < 0.4;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          const Spacer(flex: 2),
          Text(
            'WHAT COLOUR IS THE TEXT?',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            word.toUpperCase(),
            style: TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.w900,
              color: fillColor,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _timerFraction,
              minHeight: 8,
              backgroundColor: const Color(0xFF333333),
              valueColor: AlwaysStoppedAnimation<Color>(
                isWarning ? const Color(0xFFE94560) : const Color(0xFF0F3460),
              ),
            ),
          ),
          const Spacer(flex: 3),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              for (int i = 0; i < colorOptions.length; i++)
                _buildColorButton(i),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildColorButton(int index) {
    final option = colorOptions[index];
    return SizedBox(
      width: 110,
      height: 56,
      child: ElevatedButton(
        onPressed: () => _handleAnswer(index),
        style: ElevatedButton.styleFrom(
          backgroundColor: option.buttonColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: Color(0xFF444444), width: 2),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        child: Text(option.name.toUpperCase()),
      ),
    );
  }

  Widget _buildEndScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Game Over',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            _endMessage,
            style: const TextStyle(fontSize: 18, color: Color(0xFFAAAAAA)),
          ),
          const SizedBox(height: 16),
          Text(
            '$_streak',
            style: const TextStyle(
              fontSize: 72,
              fontWeight: FontWeight.w900,
              color: Color(0xFFE94560),
            ),
          ),
          Text(
            'STREAK',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 40),
          _buildActionButton('Play Again', _startGame),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFE94560),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
      ),
      child: Text(label),
    );
  }
}
