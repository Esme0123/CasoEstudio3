import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../core/theme.dart';
import '../models/model_info.dart';
import '../state/app_state.dart';
import '../widgets/glass_card.dart';
import '../widgets/status_pill.dart';

/// Pantalla de estado del backend y detalle de los modelos disponibles.
class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final health = state.health;

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      onRefresh: () => state.refreshHealth(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Modelos & Backend',
                  style: Theme.of(context).textTheme.headlineSmall),
              StatusPill(onTap: () => state.refreshHealth()),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Estado del servicio de inferencia y de los dos modelos comparados.',
            style: TextStyle(color: AppColors.textMid),
          ),
          const SizedBox(height: 20),

          // Estado del servicio
          _ServiceCard(state: state),
          const SizedBox(height: 20),

          // Modelos
          Text('Modelos disponibles',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          if (health == null)
            const _NoDataCard()
          else
            for (final m in health.models)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ModelCard(
                  info: m,
                  isDefault: m.name == ModelIds.mobilenet,
                ),
              ),

          const SizedBox(height: 8),
          // Descripción del proyecto
          const _AboutCard(),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final AppState state;
  const _ServiceCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final health = state.health;
    final online = state.conn == ConnState.online;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: (online ? AppColors.success : AppColors.danger)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(
                  online ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                  color: online ? AppColors.success : AppColors.danger,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Servicio de inferencia',
                        style: TextStyle(
                            color: AppColors.textHi,
                            fontWeight: FontWeight.w700)),
                    Text(
                      state.baseUrl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppColors.textLow, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (health != null) ...[
            const Divider(color: AppColors.stroke, height: 26),
            _kv('Versión API', health.version),
            const SizedBox(height: 10),
            _kv('Dispositivo de cómputo', health.device.toUpperCase()),
            const SizedBox(height: 10),
            _kv('Modelos cargados',
                '${health.models.where((m) => m.weightsLoaded).length}/${health.models.length}'),
          ] else if (state.connError != null) ...[
            const Divider(color: AppColors.stroke, height: 26),
            Text(
              state.connError!,
              style: const TextStyle(color: AppColors.danger, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(k, style: const TextStyle(color: AppColors.textMid)),
        Text(v,
            style: const TextStyle(
                color: AppColors.textHi, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _ModelCard extends StatelessWidget {
  final ModelInfo info;
  final bool isDefault;
  const _ModelCard({required this.info, required this.isDefault});

  @override
  Widget build(BuildContext context) {
    final loaded = info.weightsLoaded;
    final isMobile = info.name == ModelIds.mobilenet;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(
                  isMobile ? Icons.bolt_rounded : Icons.grid_view_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          info.name,
                          style: const TextStyle(
                            color: AppColors.textHi,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (isDefault) _badge('por defecto', AppColors.primary),
                      ],
                    ),
                    Text(info.architecture,
                        style: const TextStyle(
                            color: AppColors.textMid, fontSize: 12.5)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(
                loaded ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                size: 16,
                color: loaded ? AppColors.success : AppColors.warning,
              ),
              const SizedBox(width: 8),
              Text(
                loaded
                    ? 'Pesos entrenados cargados'
                    : 'Sin pesos entrenados (resultados poco fiables)',
                style: TextStyle(
                  color: loaded ? AppColors.success : AppColors.warning,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(text,
          style: TextStyle(
              color: color, fontSize: 10.5, fontWeight: FontWeight.w700)),
    );
  }
}

class _NoDataCard extends StatelessWidget {
  const _NoDataCard();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Row(
        children: [
          const Icon(Icons.signal_wifi_connected_no_internet_4_rounded,
              color: AppColors.textLow),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Conéctate al backend para ver los modelos.\nDesliza hacia abajo para reintentar.',
              style: TextStyle(color: AppColors.textMid, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      color: AppColors.primarySoft,
      borderColor: AppColors.primary.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.architecture_rounded, color: AppColors.primary),
              SizedBox(width: 10),
              Text('Sobre el proyecto',
                  style: TextStyle(
                      color: AppColors.textHi,
                      fontWeight: FontWeight.w700,
                      fontSize: 15)),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'FisuraScan compara dos enfoques de visión por computadora para '
            'detectar grietas en superficies de concreto: una CNN entrenada '
            'desde cero (Baseline) y un modelo de transferencia basado en '
            'MobileNetV3. La explicabilidad se aporta con mapas de calor '
            'Grad-CAM generados por el backend.',
            style: TextStyle(color: AppColors.textMid, height: 1.5, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
