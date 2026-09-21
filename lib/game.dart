import 'dart:math';

enum Phase { ready, playing, over }

// 난이도 튠 포인트. 값은 트랙 길이를 1로 본 비율(폭) / 초(주기).
const startZoneWidth = 0.25;
const minZoneWidth = 0.06;
const zoneShrink = 0.01;
const startPeriod = 1.2;
const minPeriod = 0.4;
const periodShrink = 0.03;

/// 순수 게임 로직. 시간 t(초)는 호출자가 넘긴다 → 프레임/플랫폼 무관, 테스트 가능.
class Game {
  Game({Random? random}) : _random = random ?? Random();
  final Random _random;

  Phase phase = Phase.ready;
  int score = 0;
  double zoneCenter = 0.5;
  double zoneWidth = startZoneWidth;
  double period = startPeriod;
  double roundStart = 0;

  /// 삼각파: roundStart에서 0 → period/2에서 1 → period에서 0.
  double markerAt(double t) {
    final x = ((t - roundStart) / period) % 1.0;
    return x < 0.5 ? x * 2 : 2 - x * 2;
  }

  void start(double t) {
    phase = Phase.playing;
    score = 0;
    zoneWidth = startZoneWidth;
    period = startPeriod;
    roundStart = t;
    _placeZone();
  }

  void tap(double t) {
    if (phase != Phase.playing) return;
    if ((markerAt(t) - zoneCenter).abs() > zoneWidth / 2) {
      phase = Phase.over;
      return;
    }
    score++;
    final frac = ((t - roundStart) / period) % 1.0; // 현재 위상
    zoneWidth = max(minZoneWidth, zoneWidth - zoneShrink);
    period = max(minPeriod, period - periodShrink);
    roundStart = t - frac * period; // 주기가 바뀌어도 마커가 튀지 않게 위상 유지
    _placeZone();
  }

  void _placeZone() {
    final half = zoneWidth / 2;
    zoneCenter = half + _random.nextDouble() * (1 - 2 * half);
  }
}
