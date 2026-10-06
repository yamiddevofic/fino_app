import 'dart:math' as math;

import 'package:fino_app/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Fondo con dos halos de color que se desplazan muy despacio.
///
/// El halo principal toma el color de acento de la sección actual y cambia
/// con un fundido. Respeta la opción del sistema de reducir animaciones.
class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({
    super.key,
    required this.accent,
    required this.child,
  });

  final Color accent;
  final Widget child;

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 28),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: TweenAnimationBuilder<Color?>(
              tween: ColorTween(end: widget.accent),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOut,
              builder: (context, accent, _) => CustomPaint(
                painter: _HaloPainter(
                  animation: _controller,
                  background: tokens.background,
                  accent: accent ?? widget.accent,
                  secondary: tokens.brand,
                  strength: isDark ? 0.16 : 0.13,
                ),
              ),
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _HaloPainter extends CustomPainter {
  _HaloPainter({
    required this.animation,
    required this.background,
    required this.accent,
    required this.secondary,
    required this.strength,
  }) : super(repaint: animation);

  final Animation<double> animation;
  final Color background;
  final Color accent;
  final Color secondary;
  final double strength;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = background);

    final t = animation.value * 2 * math.pi;
    final r = math.max(size.width, size.height * 0.6);

    _halo(
      canvas,
      Offset(
        size.width * (0.85 + 0.08 * math.sin(t)),
        size.height * (0.08 + 0.05 * math.cos(t)),
      ),
      r * 0.75,
      accent,
    );
    _halo(
      canvas,
      Offset(
        size.width * (0.1 + 0.08 * math.cos(t + 1.3)),
        size.height * (0.62 + 0.06 * math.sin(t + 1.3)),
      ),
      r * 0.6,
      secondary,
    );
  }

  void _halo(Canvas canvas, Offset center, double radius, Color color) {
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: strength),
            color.withValues(alpha: 0),
          ],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_HaloPainter old) =>
      old.accent != accent ||
      old.background != background ||
      old.secondary != secondary ||
      old.strength != strength;
}
