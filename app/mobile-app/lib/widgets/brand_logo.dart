import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Isotipo de FisuraScan: un cuadro de inspección con una "grieta" diagonal
/// cruzada por una línea de escaneo. Dibujado por código (sin assets),
/// con relleno sólido.
class BrandLogo extends StatelessWidget {
  final double size;
  const BrandLogo({super.key, this.size = 64});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(size * 0.26),
      ),
      child: CustomPaint(painter: _CrackPainter()),
    );
  }
}

class _CrackPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final line = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.06
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Grieta en zig-zag
    final crack = Path()
      ..moveTo(w * 0.34, h * 0.2)
      ..lineTo(w * 0.5, h * 0.42)
      ..lineTo(w * 0.4, h * 0.56)
      ..lineTo(w * 0.62, h * 0.8);
    canvas.drawPath(crack, line);

    // Pequeñas ramas de la grieta
    canvas.drawLine(Offset(w * 0.5, h * 0.42), Offset(w * 0.66, h * 0.38), line);
    canvas.drawLine(Offset(w * 0.4, h * 0.56), Offset(w * 0.26, h * 0.62), line);

    // Línea de escaneo horizontal translúcida
    final scan = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..strokeWidth = w * 0.04;
    canvas.drawLine(Offset(w * 0.18, h * 0.5), Offset(w * 0.82, h * 0.5), scan);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

/// Logotipo + nombre en una fila, para cabeceras.
class BrandWordmark extends StatelessWidget {
  final double logoSize;
  const BrandWordmark({super.key, this.logoSize = 38});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        BrandLogo(size: logoSize),
        const SizedBox(width: 12),
        RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'Fisura',
                style: TextStyle(
                  color: AppColors.textHi,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  letterSpacing: -0.4,
                ),
              ),
              TextSpan(
                text: 'Scan',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  letterSpacing: -0.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Variante animada del isotipo para el splash (leve balanceo).
class AnimatedBrandLogo extends StatefulWidget {
  final double size;
  const AnimatedBrandLogo({super.key, this.size = 96});

  @override
  State<AnimatedBrandLogo> createState() => _AnimatedBrandLogoState();
}

class _AnimatedBrandLogoState extends State<AnimatedBrandLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        return Transform.rotate(
          angle: math.sin(_c.value * 2 * math.pi) * 0.03,
          child: child,
        );
      },
      child: BrandLogo(size: widget.size),
    );
  }
}
