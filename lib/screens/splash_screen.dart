import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/theme_service.dart';
import 'dashboard_screen.dart';

/// Splash mở app — crystal + glow, theo theme, rồi vào Dashboard.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _fade = CurvedAnimation(parent: _c, curve: const Interval(0, 0.5, curve: Curves.easeOut));
    _scale = Tween(begin: 0.86, end: 1.0).animate(
      CurvedAnimation(parent: _c, curve: const Interval(0, 0.7, curve: Curves.easeOutBack)),
    );
    _c.forward();
    Future.delayed(const Duration(milliseconds: 1600), _go);
  }

  void _go() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const DashboardScreen(),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = themeController.service;
    final accent = Color(s.seedColor);
    final bg = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bg,
      body: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.2),
                radius: 1.1,
                colors: [
                  accent.withOpacity(0.22),
                  bg,
                  bg,
                ],
              ),
            ),
            child: FadeTransition(
              opacity: _fade,
              child: ScaleTransition(
                scale: _scale,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(96, 96),
                      painter: _CrystalPainter(accent),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Kính',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: Theme.of(context).colorScheme.onSurface,
                        shadows: [
                          Shadow(color: accent.withOpacity(0.5), blurRadius: 16),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Dashboard · Browser · AI',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.55),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CrystalPainter extends CustomPainter {
  final Color accent;
  _CrystalPainter(this.accent);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.42;
    final path = Path();
    for (var i = 0; i < 6; i++) {
      final a = (math.pi / 3) * i - math.pi / 6;
      final x = cx + r * math.cos(a);
      final y = cy + r * math.sin(a);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    final glow = Paint()
      ..color = accent.withOpacity(0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawPath(path, glow);

    final fill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.lerp(Colors.white, accent, 0.3)!,
          accent,
          Color.lerp(accent, Colors.black, 0.35)!,
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));
    canvas.drawPath(path, fill);

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Colors.white.withOpacity(0.35);
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant _CrystalPainter oldDelegate) =>
      oldDelegate.accent != accent;
}
