import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:tap_timing/game.dart';

void main() {
  // 시작 직후 첫 반주기 동안 마커는 0→1로 올라가므로, 목표 위치 p 에 도달하는 시각은 t0 + p·period/2.
  double timeAt(Game g, double t0, double pos) => t0 + pos * g.period / 2;

  test('marker follows a triangle wave over one period', () {
    final g = Game(random: Random(1))..start(10);
    final p = g.period;
    expect(g.markerAt(10), closeTo(0, 1e-9));
    expect(g.markerAt(10 + p / 4), closeTo(0.5, 1e-9));
    expect(g.markerAt(10 + p / 2), closeTo(1, 1e-9));
    expect(g.markerAt(10 + 3 * p / 4), closeTo(0.5, 1e-9));
    expect(g.markerAt(10 + p), closeTo(0, 1e-9));
  });

  test('start resets score and difficulty and keeps the zone on the track', () {
    for (var seed = 0; seed < 50; seed++) {
      final g = Game(random: Random(seed))
        ..start(0)
        ..tap(0.01) // 대부분 실패 → over
        ..start(5);
      expect(g.phase, Phase.playing);
      expect(g.score, 0);
      expect(g.zoneWidth, startZoneWidth);
      expect(g.period, startPeriod);
      expect(g.zoneCenter - g.zoneWidth / 2, greaterThanOrEqualTo(0));
      expect(g.zoneCenter + g.zoneWidth / 2, lessThanOrEqualTo(1));
    }
  });

  test('tap inside the zone scores, shrinks zone, speeds up, keeps marker position', () {
    final g = Game(random: Random(3))..start(0);
    final t = timeAt(g, 0, g.zoneCenter);
    final before = g.markerAt(t);
    g.tap(t);
    expect(g.phase, Phase.playing);
    expect(g.score, 1);
    expect(g.zoneWidth, closeTo(startZoneWidth - zoneShrink, 1e-9));
    expect(g.period, closeTo(startPeriod - periodShrink, 1e-9));
    expect(g.markerAt(t), closeTo(before, 1e-9));
  });

  test('tap outside the zone ends the game without scoring', () {
    final g = Game(random: Random(3))..start(0);
    // 구간 반대편 끝(0 또는 1)은 항상 구간 밖: 거리 ≥ 0.5 > 반폭.
    final t = g.zoneCenter > 0.5 ? 0.0 : g.period / 2;
    g.tap(t);
    expect(g.phase, Phase.over);
    expect(g.score, 0);
  });

  test('difficulty never passes its floors', () {
    final g = Game(random: Random(7))..start(0);
    var t = 0.0;
    for (var i = 0; i < 100; i++) {
      // 마커가 현재 구간 중심에 오는 다음 시각으로 점프해서 탭.
      final frac = ((t - g.roundStart) / g.period) % 1.0;
      final target = g.zoneCenter / 2; // 상승 구간에서 중심에 오는 위상
      final dt = ((target - frac) % 1.0) * g.period;
      t += dt;
      g.tap(t);
      expect(g.phase, Phase.playing, reason: 'round $i');
    }
    expect(g.score, 100);
    expect(g.zoneWidth, minZoneWidth);
    expect(g.period, minPeriod);
  });

  test('tap is ignored unless playing', () {
    final g = Game(random: Random(1));
    g.tap(0);
    expect(g.phase, Phase.ready);
    expect(g.score, 0);
  });
}
