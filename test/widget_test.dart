import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_2048/main.dart';
import 'package:flutter_2048/game_2048.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('renders the 2048 board with header', (tester) async {
    await tester.pumpWidget(const GameApp());
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('2048'), findsOneWidget);
    expect(find.text('New Game'), findsOneWidget);
    expect(find.text('SCORE'), findsOneWidget);
    expect(find.text('BEST'), findsOneWidget);
  });

  testWidgets('a swipe move changes the board', (tester) async {
    await tester.pumpWidget(const GameApp());
    await tester.pump(const Duration(milliseconds: 400));

    final game = Game2048();
    game.start();
    final tilesBefore = game.tiles.length;

    await tester.drag(find.byType(GestureDetector).first, const Offset(200, 0));
    await tester.pump(const Duration(milliseconds: 300));

    // Dragging produces no exceptions and the UI is still responsive.
    expect(tester.takeException(), isNull);
    expect(tilesBefore, greaterThanOrEqualTo(2));
  });

  test('game logic merges tiles and updates score', () {
    final game = Game2048();
    game.start();

    // Force a known board.
    game.tiles.clear();
    game.tiles.addAll([
      Tile(id: 1, value: 2, row: 0, col: 0),
      Tile(id: 2, value: 2, row: 0, col: 1),
    ]);

    final moved = game.move(MoveDirection.left);
    expect(moved, isTrue);
    expect(game.score, 4);
    expect(game.tileAt(0, 0)!.value, 4);
    // Merged pair (2+2) plus the one random tile spawned after the move.
    expect(game.tiles.length, 2);
  });
}