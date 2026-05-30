import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../models/analysis_record.dart';
import '../state/app_state.dart';
import '../widgets/glass_card.dart';
import 'result_screen.dart';

/// Historial de análisis realizados (persistido localmente).
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final history = state.history;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Historial', style: Theme.of(context).textTheme.headlineSmall),
            if (history.isNotEmpty)
              TextButton.icon(
                onPressed: () => _confirmClear(context, state),
                icon: const Icon(Icons.delete_sweep_rounded,
                    size: 18, color: AppColors.danger),
                label: const Text('Vaciar',
                    style: TextStyle(color: AppColors.danger)),
              ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Tus análisis recientes se guardan en este dispositivo.',
          style: TextStyle(color: AppColors.textMid),
        ),
        const SizedBox(height: 20),
        if (history.isEmpty)
          const _EmptyHistory()
        else
          for (final r in history)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _HistoryTile(record: r),
            ),
      ],
    );
  }

  void _confirmClear(BuildContext context, AppState state) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Vaciar historial',
            style: TextStyle(color: AppColors.textHi)),
        content: const Text(
          '¿Seguro que quieres eliminar todos los análisis guardados?',
          style: TextStyle(color: AppColors.textMid),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar',
                style: TextStyle(color: AppColors.textMid)),
          ),
          TextButton(
            onPressed: () {
              state.clearHistory();
              Navigator.pop(ctx);
            },
            child: const Text('Eliminar',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final AnalysisRecord record;
  const _HistoryTile({required this.record});

  @override
  Widget build(BuildContext context) {
    final p = record.prediction;
    final color = p.hasCrack ? AppColors.danger : AppColors.success;
    final date = DateFormat("d MMM yyyy · HH:mm", 'es').format(record.timestamp);

    return Dismissible(
      key: ValueKey(record.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppColors.dangerSoft,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: const Icon(Icons.delete_rounded, color: AppColors.danger),
      ),
      onDismissed: (_) =>
          context.read<AppState>().removeRecord(record.id),
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ResultScreen(
                imageBytes: record.thumbnailBytes,
                prediction: p,
              ),
            ),
          );
        },
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Image.memory(
                record.thumbnailBytes,
                width: 58,
                height: 58,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        p.hasCrack
                            ? Icons.warning_amber_rounded
                            : Icons.verified_rounded,
                        size: 16,
                        color: color,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        p.labelEs,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(date,
                      style: const TextStyle(
                          color: AppColors.textLow, fontSize: 12)),
                  const SizedBox(height: 2),
                  Text(
                    '${p.model} · ${(p.confidence * 100).toStringAsFixed(1)}% confianza',
                    style:
                        const TextStyle(color: AppColors.textMid, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textLow),
          ],
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.6),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.stroke),
            ),
            child: const Icon(Icons.inbox_rounded,
                size: 36, color: AppColors.textLow),
          ),
          const SizedBox(height: 18),
          const Text('Aún no hay análisis',
              style: TextStyle(
                  color: AppColors.textHi,
                  fontWeight: FontWeight.w700,
                  fontSize: 16)),
          const SizedBox(height: 6),
          const Text(
            'Analiza tu primera imagen desde la pestaña “Analizar”.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMid),
          ),
        ],
      ),
    );
  }
}
