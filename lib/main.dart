import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'game.dart';

const _bg = Color(0xFF111318);
const _track = Color(0xFF2A2F3A);
const _zone = Color(0xFF3DDC84);
const _bestKey = 'best';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: GameScreen(),
  ));
}

class GameScreen extends StatefulWidget {
  GameScreen({super.key, Game? game}) : game = game ?? Game();
  final Game game;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  double _t = 0; // 앱 시작 이후 경과 초
  int _best = 0;

  Game get game => widget.game;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(
      (elapsed) => setState(() => _t = elapsed.inMicroseconds / 1e6),
    )..start();
    SharedPreferences.getInstance().then(
      (p) => setState(() => _best = p.getInt(_bestKey) ?? 0),
    );
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onTap() {
    setState(() {
      if (game.phase != Phase.playing) {
        game.start(_t);
        return;
      }
      game.tap(_t);
      if (game.phase == Phase.playing) {
        HapticFeedback.lightImpact();
      } else if (game.score > _best) {
        _best = game.score;
        SharedPreferences.getInstance().then((p) => p.setInt(_bestKey, _best));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: _bg,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _onTap,
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _TrackPainter(game, _t))),
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Text(
                    'SCORE ${game.score}   BEST $_best',
                    style: text.titleLarge?.copyWith(color: Colors.white70),
                  ),
                ),
              ),
            ),
            if (game.phase != Phase.playing)
              Align(
                alignment: const Alignment(0, -0.45),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      game.phase == Phase.ready ? '타이밍 탭' : '게임 오버',
                      style: text.displaySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (game.phase == Phase.over)
                      Text(
                        '점수 ${game.score}',
                        style: text.headlineSmall?.copyWith(color: _zone),
                      ),
                    const SizedBox(height: 12),
                    Text(
                      game.phase == Phase.ready ? '탭하여 시작' : '탭하여 다시',
                      style: text.titleMedium?.copyWith(color: Colors.white54),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TrackPainter extends CustomPainter {
  _TrackPainter(this.game, this.t);
  final Game game;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final left = size.width * 0.08;
    final width = size.width * 0.84;
    final y = size.height * 0.55;
    const h = 28.0;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(left, y - h / 2, width, h),
        const Radius.circular(h / 2),
      ),
      Paint()..color = _track,
    );

    final zl = left + (game.zoneCenter - game.zoneWidth / 2) * width;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(zl, y - h / 2, game.zoneWidth * width, h),
        const Radius.circular(h / 2),
      ),
      Paint()..color = _zone,
    );

    if (game.phase == Phase.playing) {
      final x = left + game.markerAt(t) * width;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, y), width: 6, height: 72),
          const Radius.circular(3),
        ),
        Paint()..color = Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(_TrackPainter old) => true;
}
