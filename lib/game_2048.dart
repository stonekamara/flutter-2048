import 'dart:math';

/// A single tile on the board.
class Tile {
  Tile({
    required this.id,
    required this.value,
    required this.row,
    required this.col,
    this.isNew = false,
    this.justMerged = false,
  });

  final int id;
  int value;
  int row;
  int col;

  /// True right after the tile is spawned (used to play the appear animation).
  bool isNew;

  /// True right after the tile was created by a merge (used for the pop effect).
  bool justMerged;
}

/// Direction of a swipe / keyboard move.
enum MoveDirection { up, down, left, right }

/// Pure game logic for 2048, kept separate from the UI.
class Game2048 {
  static const int size = 4;
  static const int winningValue = 2048;

  final Random _rng = Random();

  final List<Tile> tiles = [];
  int score = 0;
  bool gameOver = false;
  bool won = false;

  int _nextId = 0;

  /// Initializes a fresh board with two random tiles.
  void start() {
    tiles.clear();
    score = 0;
    gameOver = false;
    won = false;
    _addRandomTile();
    _addRandomTile();
  }

  /// Attempts a move in [direction].
  ///
  /// Returns true if the board changed. Tiles keep their identity across a
  /// move so the UI can animate them smoothly; merged tiles produce a new
  /// tile carrying [Tile.justMerged] == true.
  bool move(MoveDirection direction) {
    if (gameOver) return false;

    final moved = _slide(direction);
    if (!moved) return false;

    _addRandomTile();
    gameOver = !_canMove();
    return true;
  }

  /// Returns the tile at (row, col), or null.
  Tile? tileAt(int row, int col) {
    for (final t in tiles) {
      if (t.row == row && t.col == col) return t;
    }
    return null;
  }

  void _addRandomTile() {
    final empty = <(int, int)>[];
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        if (tileAt(r, c) == null) empty.add((r, c));
      }
    }
    if (empty.isEmpty) return;

    final (r, c) = empty[_rng.nextInt(empty.length)];
    tiles.add(Tile(
      id: _nextId++,
      value: _rng.nextDouble() < 0.9 ? 2 : 4,
      row: r,
      col: c,
      isNew: true,
    ));
  }

  /// Slides and merges all tiles along [direction].
  bool _slide(MoveDirection direction) {
    final rows = <int>[];
    final cols = <int>[];
    for (var i = 0; i < size; i++) {
      rows.add(i);
      cols.add(i);
    }

    final dr = switch (direction) {
      MoveDirection.up => -1,
      MoveDirection.down => 1,
      _ => 0,
    };
    final dc = switch (direction) {
      MoveDirection.left => -1,
      MoveDirection.right => 1,
      _ => 0,
    };

    // Process lines from the edge the tiles move towards.
    final rOrder = dr == 1 ? rows.reversed.toList() : rows;
    final cOrder = dc == 1 ? cols.reversed.toList() : cols;

    var moved = false;

    for (final r in rOrder) {
      for (final c in cOrder) {
        final tile = tileAt(r, c);
        if (tile == null) continue;

        var nr = r;
        var nc = c;
        var merged = false;

        while (true) {
          final tr = nr + dr;
          final tc = nc + dc;
          if (tr < 0 || tr >= size || tc < 0 || tc >= size) break;

          final blocker = tileAt(tr, tc);
          if (blocker == null) {
            nr = tr;
            nc = tc;
            continue;
          }
          if (blocker.value == tile.value && !blocker.justMerged) {
            // Merge: the blocking tile is replaced by a doubled new tile.
            tiles.remove(blocker);
            tile.value *= 2;
            tile.row = tr;
            tile.col = tc;
            tile.justMerged = true;
            score += tile.value;
            if (tile.value >= winningValue) won = true;
            merged = true;
            nr = tr;
            nc = tc;
          }
          break;
        }

        if (nr != r || nc != c) {
          tile.row = nr;
          tile.col = nc;
          moved = true;
        }
        if (merged) moved = true;
      }
    }

    return moved;
  }

  /// True if at least one move is possible.
  bool _canMove() {
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        final tile = tileAt(r, c);
        if (tile == null) return true;
        if (r + 1 < size &&
            tileAt(r + 1, c)!.value == tile.value) {
          return true;
        }
        if (c + 1 < size &&
            tileAt(r, c + 1)!.value == tile.value) {
          return true;
        }
      }
    }
    return false;
  }

  /// Clears transient animation flags after the move animations complete.
  /// Called by the UI once the tiles have finished moving.
  void refreshFlags() {
    for (final t in tiles) {
      t.isNew = false;
      t.justMerged = false;
    }
  }
}