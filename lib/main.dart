import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'game_2048.dart';

void main() {
  runApp(const GameApp());
}

class GameApp extends StatelessWidget {
  const GameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '2048',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFFAF8EF),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFBBADA0)),
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
  final Game2048 _game = Game2048();
  int _best = 0;
  bool _winDismissed = false;
  Timer? _flagTimer;

  @override
  void initState() {
    super.initState();
    _game.start();
    _loadBest();
  }

  @override
  void dispose() {
    _flagTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadBest() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _best = prefs.getInt('best_score') ?? 0);
  }

  Future<void> _saveBest() async {
    if (_game.score > _best) {
      setState(() => _best = _game.score);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('best_score', _best);
    }
  }

  void _handleMove(MoveDirection direction) {
    if (_game.move(direction)) {
      setState(() {});
      _saveBest();
      // Clear transient animation flags once the move animations finish.
      _flagTimer?.cancel();
      _flagTimer = Timer(const Duration(milliseconds: 280), () {
        if (mounted) {
          setState(() => _game.refreshFlags());
        }
      });
    }
  }

  void _newGame() {
    setState(() {
      _game.start();
      _winDismissed = false;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    final v = details.velocity.pixelsPerSecond;
    final dx = v.dx.abs();
    final dy = v.dy.abs();
    if (dx < 200 && dy < 200) return;
    if (dx > dy) {
      _handleMove(v.dx > 0 ? MoveDirection.right : MoveDirection.left);
    } else {
      _handleMove(v.dy > 0 ? MoveDirection.down : MoveDirection.up);
    }
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final logical = event.logicalKey;
    final direction = switch (logical) {
      LogicalKeyboardKey.arrowLeft || LogicalKeyboardKey.keyA => MoveDirection.left,
      LogicalKeyboardKey.arrowRight || LogicalKeyboardKey.keyD => MoveDirection.right,
      LogicalKeyboardKey.arrowUp || LogicalKeyboardKey.keyW => MoveDirection.up,
      LogicalKeyboardKey.arrowDown || LogicalKeyboardKey.keyS => MoveDirection.down,
      _ => null,
    };
    if (direction == null) return KeyEventResult.ignored;
    _handleMove(direction);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final maxWidth = screen.width < 520 ? screen.width - 32.0 : 480.0;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SizedBox(
            width: maxWidth,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Board sized to fit both width and available height.
                  const fixedHeight = 172.0;
                  final boardSize = math.max(
                    260.0,
                    math.min(constraints.maxWidth, constraints.maxHeight - fixedHeight),
                  );

                  return Focus(
                    autofocus: true,
                    onKeyEvent: _onKeyEvent,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanEnd: _onPanEnd,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _Header(
                            score: _game.score,
                            best: _best,
                            onNewGame: _newGame,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Join the tiles, get to 2048!',
                            style: TextStyle(
                              color: const Color(0xFF776E65),
                              fontSize: boardSize * 0.03 + 4,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _Board(
                            game: _game,
                            boardSize: boardSize,
                            winDismissed: _winDismissed,
                            onNewGame: _newGame,
                            onWinDismissed: () => setState(() => _winDismissed = true),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Swipe or use arrow keys ⌨️',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: const Color(0xFF776E65).withValues(alpha: 0.7),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Made with Flutter ❤️',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: const Color(0xFF776E65).withValues(alpha: 0.5),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.score, required this.best, required this.onNewGame});

  final int score;
  final int best;
  final VoidCallback onNewGame;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          '2048',
          style: TextStyle(
            fontSize: 46,
            fontWeight: FontWeight.w800,
            color: Color(0xFF776E65),
            height: 1.0,
          ),
        ),
        const Spacer(),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ScoreBox(label: 'SCORE', value: score),
                const SizedBox(width: 8),
                _ScoreBox(label: 'BEST', value: best),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: onNewGame,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF8F7A66),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: const Text('New Game', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ScoreBox extends StatelessWidget {
  const _ScoreBox({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFBBADA0),
        borderRadius: BorderRadius.circular(6),
      ),          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFEEE4DA),
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                '$value',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
    );
  }
}

class _Board extends StatelessWidget {
  const _Board({
    required this.game,
    required this.boardSize,
    required this.winDismissed,
    required this.onNewGame,
    required this.onWinDismissed,
  });

  final Game2048 game;
  final double boardSize;
  final bool winDismissed;
  final VoidCallback onNewGame;
  final VoidCallback onWinDismissed;

  @override
  Widget build(BuildContext context) {
    const gap = 12.0;
    final inner = (boardSize - gap * (Game2048.size - 1)) / Game2048.size;

    return SizedBox(
      width: boardSize,
      height: boardSize,
      child: Stack(
            children: [
              // Background grid.
              Positioned.fill(
                child: Container(
                  padding: const EdgeInsets.all(gap / 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFBBADA0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: List.generate(Game2048.size, (r) {
                      return Expanded(
                        child: Row(
                          children: List.generate(Game2048.size, (c) {
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(gap / 4),
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFCDC1B4),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const SizedBox.expand(),
                                ),
                              ),
                            );
                          }),
                        ),
                      );
                    }),
                  ),
                ),
              ),
              // Tiles.
              for (final tile in game.tiles)
                AnimatedPositioned(
                  key: ValueKey(tile.id),
                  duration: const Duration(milliseconds: 110),
                  curve: Curves.easeOut,
                  left: gap / 2 + tile.col * (inner + gap),
                  top: gap / 2 + tile.row * (inner + gap),
                  width: inner,
                  height: inner,
                  child: _TileView(tile: tile, cellSize: inner),
                ),
              // Overlays.
              if (game.gameOver)
                _Overlay(
                  title: 'Game over!',
                  subtitle: 'Your score: ${game.score}',
                  buttonLabel: 'Try Again',
                  onPressed: onNewGame,
                ),
              if (game.won && !winDismissed)
                _Overlay(
                  title: 'You win! 🎉',
                  subtitle: 'You reached 2048',
                  buttonLabel: 'Keep Going',
                  onPressed: onWinDismissed,
                  onSecondary: onNewGame,
                  secondaryLabel: 'New Game',
                ),
        ],
      ),
    );
  }
}

class _TileView extends StatefulWidget {
  const _TileView({required this.tile, required this.cellSize});

  final Tile tile;
  final double cellSize;

  @override
  State<_TileView> createState() => _TileViewState();
}

class _TileViewState extends State<_TileView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 160),
  );
  late Animation<double> _scale = _appearAnimation();

  Animation<double> _appearAnimation() {
    return Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
  }

  Animation<double> _mergeAnimation() {
    return TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void initState() {
    super.initState();
    if (widget.tile.isNew) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(_TileView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tile.justMerged && !oldWidget.tile.justMerged) {
      _scale = _mergeAnimation();
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.tile.value;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(scale: _scale.value, child: child);
      },
      child: Container(
        decoration: BoxDecoration(
          color: _tileColor(value),
          borderRadius: BorderRadius.circular(6),
          boxShadow: value >= 128
              ? [
                  BoxShadow(
                    color: _tileColor(value).withValues(alpha: 0.45),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          '$value',
          style: TextStyle(
            fontSize: _fontSizeFor(value),
            fontWeight: FontWeight.w800,
            color: value <= 4 ? const Color(0xFF776E65) : Colors.white,
          ),
        ),
      ),
    );
  }

  double _fontSizeFor(int value) {
    final factor = value < 100
        ? 0.46
        : value < 1000
            ? 0.40
            : 0.34;
    return (widget.cellSize * factor).clamp(12.0, 60.0);
  }
}

Color _tileColor(int value) {
  return switch (value) {
    2 => const Color(0xFFEEE4DA),
    4 => const Color(0xFFEDE0C8),
    8 => const Color(0xFFF2B179),
    16 => const Color(0xFFF59563),
    32 => const Color(0xFFF67C5F),
    64 => const Color(0xFFF65E3B),
    128 => const Color(0xFFEDCF72),
    256 => const Color(0xFFEDCC61),
    512 => const Color(0xFFEDC850),
    1024 => const Color(0xFFEDC53F),
    2048 => const Color(0xFFEDC22E),
    _ => const Color(0xFF3C3A32),
  };
}

class _Overlay extends StatelessWidget {
  const _Overlay({
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onPressed,
    this.secondaryLabel,
    this.onSecondary,
  });

  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback onPressed;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: const Color(0xFFFAF8EF).withValues(alpha: 0.65),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF776E65),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF776E65),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (secondaryLabel != null) ...[
                    OutlinedButton(
                      onPressed: onSecondary,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF776E65),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      ),
                      child: Text(secondaryLabel!),
                    ),
                    const SizedBox(width: 12),
                  ],
                  FilledButton(
                    onPressed: onPressed,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF8F7A66),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    ),
                    child: Text(buttonLabel),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}