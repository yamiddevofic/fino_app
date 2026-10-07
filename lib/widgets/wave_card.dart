import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Tarjeta destacada con ondas suaves del color de acento en la parte
/// inferior. Las ondas se desplazan muy despacio (en bucle, sin saltos) y se
/// detienen si el sistema pide reducir animaciones.
class WaveCard extends StatefulWidget {
  const WaveCard({
    super.key,
    required this.accent,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 20, 20, 20 + waveHeight),
  });

  /// Alto de la franja inferior que ocupan las ondas. El relleno por
  /// defecto la deja libre para que no pasen por detrás del contenido.
  static const waveHeight = 40.0;

  final Color accent;
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  State<WaveCard> createState() => _WaveCardState();
}

class _WaveCardState extends State<WaveCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 16),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: TweenAnimationBuilder<Color?>(
                tween: ColorTween(end: widget.accent),
                duration: const Duration(milliseconds: 500),
                builder: (context, color, _) => CustomPaint(
                  painter: _WavePainter(
                    animation: _controller,
                    color: color ?? widget.accent,
                    strength: isDark ? 1.25 : 1.0,
                  ),
                ),
              ),
            ),
          ),
          Padding(padding: widget.padding, child: widget.child),
        ],
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  _WavePainter({
    required this.animation,
    required this.color,
    required this.strength,
  }) : super(repaint: animation);

  final Animation<double> animation;
  final Color color;
  final double strength;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Brillo suave en la esquina superior derecha.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(1.1, -1.2),
          radius: 1.1,
          colors: [
            color.withValues(alpha: 0.10 * strength),
            color.withValues(alpha: 0),
          ],
        ).createShader(rect),
    );

    final t = animation.value * 2 * math.pi;
    // (distancia de la base al borde inferior, amplitud, ondas por ancho,
    // velocidad, opacidad). Las velocidades son enteras para que el bucle no
    // salte.
    const layers = [
      (38.0, 6.0, 1.0, 1, 0.06),
      (27.0, 7.0, 1.5, -1, 0.08),
      (16.0, 5.0, 2.0, 2, 0.11),
    ];
    Path? crest;
    for (final (base, amplitude, waves, speed, alpha) in layers) {
      final path = _wave(size, base, amplitude, waves, t * speed);
      crest ??= path;
      final fill = Path.from(path)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();
      canvas.drawPath(
        fill,
        Paint()..color = color.withValues(alpha: alpha * strength),
      );
    }

    // Trazo fino sobre la onda superior.
    canvas.drawPath(
      crest!,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = color.withValues(alpha: 0.18 * strength),
    );
  }

  Path _wave(
    Size size,
    double fromBottom,
    double amplitude,
    double waves,
    double phase,
  ) {
    final path = Path();
    final y0 = size.height - fromBottom;
    const step = 6.0;
    for (var x = 0.0; x <= size.width + step; x += step) {
      final y =
          y0 +
          amplitude * math.sin((x / size.width) * waves * 2 * math.pi + phase);
      x == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    return path;
  }

  @override
  bool shouldRepaint(_WavePainter old) =>
      old.color != color || old.strength != strength;
}
