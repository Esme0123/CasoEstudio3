import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Anillo de confianza animado: arco de progreso sólido con porcentaje central.
/// El color depende de si hay grieta o no.
class ConfidenceRing extends StatelessWidget {
  final double value; // 0..1
  final bool hasCrack;
  final String label;
  final double size;

  const ConfidenceRing({
    super.key,
    required this.value,
    required this.hasCrack,
    required this.label,
    this.size = 200,
  });

  @override
  Widget build(BuildContext context) {
    final color = hasCrack ? AppColors.danger : AppColors.success;
    final soft = hasCrack ? AppColors.dangerSoft : AppColors.successSoft;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.clamp(0, 1)),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) {
        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _RingPainter(progress: v, color: color),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(v * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: size * 0.2,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textHi,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'confianza',
                    style: TextStyle(
                      fontSize: size * 0.065,
                      color: AppColors.textLow,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: soft,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: color.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: size * 0.07,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.width / 2) - 11;
    const stroke = 14.0;

    // Pista de fondo
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = AppColors.stroke;
    canvas.drawCircle(center, radius, track);

    // Arco de progreso sólido
    const start = -math.pi / 2;
    final sweep = 2 * math.pi * progress;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(rect, start, sweep, false, arc);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}
