import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../core/theme.dart';
import '../state/app_state.dart';

/// Selector segmentado entre los dos modelos del backend.
class ModelSelector extends StatelessWidget {
  const ModelSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Row(
        children: [
          _Segment(
            title: 'MobileNet',
            subtitle: 'Transfer learning',
            icon: Icons.bolt_rounded,
            selected: state.model == ModelIds.mobilenet,
            onTap: () => state.setModel(ModelIds.mobilenet),
          ),
          _Segment(
            title: 'Baseline',
            subtitle: 'CNN desde cero',
            icon: Icons.grid_view_rounded,
            selected: state.model == ModelIds.baseline,
            onTap: () => state.setModel(ModelIds.baseline),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _Segment({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : AppColors.textMid;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Column(
            children: [
              Icon(icon, color: fg, size: 22),
              const SizedBox(height: 6),
              Text(
                title,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.textHi,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                style: TextStyle(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.85)
                      : AppColors.textLow,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
