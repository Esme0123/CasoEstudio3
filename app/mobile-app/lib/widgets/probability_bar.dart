import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/prediction.dart';

/// Barra de probabilidad animada para una clase (relleno sólido).
class ProbabilityBar extends StatelessWidget {
  final ClassProbability item;
  final bool highlight;

  const ProbabilityBar({
    super.key,
    required this.item,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = item.label == 'Positive';
    final color = isPositive ? AppColors.danger : AppColors.success;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  isPositive
                      ? Icons.warning_amber_rounded
                      : Icons.verified_rounded,
                  size: 17,
                  color: color,
                ),
                const SizedBox(width: 8),
                Text(
                  item.labelEs,
                  style: TextStyle(
                    color: highlight ? AppColors.textHi : AppColors.textMid,
                    fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            Text(
              '${(item.probability * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: item.probability.clamp(0, 1)),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) {
              return Stack(
                children: [
                  Container(height: 9, color: AppColors.surfaceAlt),
                  FractionallySizedBox(
                    widthFactor: v,
                    child: Container(height: 9, color: color),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
