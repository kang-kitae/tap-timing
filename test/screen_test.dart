import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tap_timing/game.dart';
import 'package:tap_timing/main.dart';

void main() {
  Future<void> tapScreen(WidgetTester tester) async {
    await tester.tap(find.byType(GestureDetector));
    await tester.pump();
  }

  // 시작 후 마커가 목표 위치 pos에 처음 오기까지의 시간.
  Duration timeTo(Game g, double pos) =>
      Duration(microseconds: (pos * g.period / 2 * 1e6).round());

  testWidgets('shows start prompt, and a tap starts the game', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final game = Game(random: Random(3));
    await tester.pumpWidget(MaterialApp(home: GameScreen(game: game)));
    await tester.pump();

    expect(find.text('탭하여 시작'), findsOneWidget);
    await tapScreen(tester);
    expect(game.phase, Phase.playing);
    expect(find.text('탭하여 시작'), findsNothing);
  });

  testWidgets('a miss shows game over and persists the new best', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final game = Game(random: Random(3));
    await tester.pumpWidget(MaterialApp(home: GameScreen(game: game)));
    await tester.pump();
    await tapScreen(tester); // start

    await tester.pump(timeTo(game, game.zoneCenter));
    await tapScreen(tester); // hit
    expect(game.score, 1);

    await tester.pump(game.zoneCenter > 0.5 ? Duration.zero : timeTo(game, 1));
    await tapScreen(tester); // miss
    expect(game.phase, Phase.over);
    expect(find.text('게임 오버'), findsOneWidget);
    expect(find.textContaining('BEST 1'), findsOneWidget);
    expect((await SharedPreferences.getInstance()).getInt('best'), 1);
  });

  testWidgets('judges the tap at finger down, not at release', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final game = Game(random: Random(3));
    await tester.pumpWidget(MaterialApp(home: GameScreen(game: game)));
    await tester.pump();
    await tapScreen(tester); // start

    await tester.pump(timeTo(game, game.zoneCenter)); // 마커가 구간 중심에 있을 때 누름
    final finger = await tester.startGesture(
      tester.getCenter(find.byType(GestureDetector)),
    );
    await tester.pump(const Duration(milliseconds: 300)); // 누른 채 300ms → 마커는 구간 밖
    await finger.up();
    await tester.pump();

    expect(game.score, 1);
    expect(game.phase, Phase.playing);
  });
}
