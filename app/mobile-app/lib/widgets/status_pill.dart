import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../state/app_state.dart';

/// Indicador compacto del estado de conexión con el backend.
class StatusPill extends StatelessWidget {
  final VoidCallback? onTap;
  const StatusPill({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final conn = context.select<AppState, ConnState>((s) => s.conn);

    late final Color color;
    late final String text;
    late final bool pulsing;
    switch (conn) {
      case ConnState.online:
        color = AppColors.success;
        text = 'En línea';
        pulsing = false;
      case ConnState.offline:
        color = AppColors.danger;
        text = 'Sin conexión';
        pulsing = false;
      case ConnState.checking:
        color = AppColors.warning;
        text = 'Conectando';
        pulsing = true;
      case ConnState.unknown:
        color = AppColors.textLow;
        text = 'Desconocido';
        pulsing = false;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: color.withValues(alpha: 0.40)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Dot(color: color, pulsing: pulsing),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  final Color color;
  final bool pulsing;
  const _Dot({required this.color, required this.pulsing});

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(
        color: widget.color,
        shape: BoxShape.circle,
      ),
    );
    if (!widget.pulsing) return dot;
    return FadeTransition(opacity: _c.drive(Tween(begin: 0.35, end: 1)), child: dot);
  }
}
