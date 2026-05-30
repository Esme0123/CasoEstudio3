import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/theme.dart';
import '../models/prediction.dart';
import '../widgets/confidence_ring.dart';
import '../widgets/gradient_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/probability_bar.dart';

/// Pantalla de resultado de un análisis.
class ResultScreen extends StatefulWidget {
  final Uint8List imageBytes;
  final Prediction prediction;

  /// Data URI PNG del Grad-CAM (opcional).
  final String? gradcamDataUri;

  const ResultScreen({
    super.key,
    required this.imageBytes,
    required this.prediction,
    this.gradcamDataUri,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _showHeatmap = true;
  double _blend = 1.0; // 0 = original, 1 = heatmap

  Uint8List? get _gradcamBytes {
    final uri = widget.gradcamDataUri;
    if (uri == null) return null;
    final comma = uri.indexOf(',');
    final b64 = comma >= 0 ? uri.substring(comma + 1) : uri;
    try {
      return base64Decode(b64);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.prediction;
    final hasCrack = p.hasCrack;
    final gradcam = _gradcamBytes;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Resultado'),
        centerTitle: true,
      ),
      body: GradientBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            children: [
              // Veredicto
              _Verdict(prediction: p),
              const SizedBox(height: 24),

              // Anillo de confianza
              Center(
                child: ConfidenceRing(
                  value: p.confidence,
                  hasCrack: hasCrack,
                  label: p.labelEs,
                  size: 210,
                ),
              ),
              const SizedBox(height: 28),

              // Imagen / Grad-CAM
              if (gradcam != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Mapa de calor Grad-CAM',
                        style: Theme.of(context).textTheme.titleMedium),
                    Switch(
                      value: _showHeatmap,
                      activeThumbColor: AppColors.primary,
                      onChanged: (v) => setState(() => _showHeatmap = v),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Las zonas cálidas (rojo/amarillo) son las que más influyeron en la decisión.',
                  style: TextStyle(color: AppColors.textLow, fontSize: 12.5),
                ),
                const SizedBox(height: 12),
                _HeatmapView(
                  original: widget.imageBytes,
                  heatmap: gradcam,
                  showHeatmap: _showHeatmap,
                  blend: _blend,
                ),
                if (_showHeatmap) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Original',
                          style: TextStyle(
                              color: AppColors.textLow, fontSize: 12)),
                      Expanded(
                        child: SliderTheme(
                          data: SliderThemeData(
                            activeTrackColor: AppColors.primary,
                            inactiveTrackColor: AppColors.stroke,
                            thumbColor: AppColors.primary,
                            overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 14),
                          ),
                          child: Slider(
                            value: _blend,
                            onChanged: (v) => setState(() => _blend = v),
                          ),
                        ),
                      ),
                      const Text('Calor',
                          style: TextStyle(
                              color: AppColors.textLow, fontSize: 12)),
                    ],
                  ),
                ],
              ] else ...[
                Text('Imagen analizada',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  child: Image.memory(widget.imageBytes,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 260),
                ),
              ],
              const SizedBox(height: 28),

              // Probabilidades
              Text('Distribución de probabilidades',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              GlassCard(
                child: Column(
                  children: [
                    for (int i = 0; i < p.probabilities.length; i++) ...[
                      ProbabilityBar(
                        item: p.probabilities[i],
                        highlight: p.probabilities[i].label == p.label,
                      ),
                      if (i != p.probabilities.length - 1)
                        const SizedBox(height: 18),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Metadatos
              _MetaCard(prediction: p),
            ],
          ),
        ),
      ),
    );
  }
}

class _Verdict extends StatelessWidget {
  final Prediction prediction;
  const _Verdict({required this.prediction});

  @override
  Widget build(BuildContext context) {
    final hasCrack = prediction.hasCrack;
    final color = hasCrack ? AppColors.danger : AppColors.success;
    final soft = hasCrack ? AppColors.dangerSoft : AppColors.successSoft;
    return GlassCard(
      color: soft,
      borderColor: color.withValues(alpha: 0.4),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              hasCrack
                  ? Icons.warning_amber_rounded
                  : Icons.verified_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasCrack ? 'Grieta detectada' : 'Superficie sin grietas',
                  style: const TextStyle(
                    color: AppColors.textHi,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasCrack
                      ? 'Se recomienda revisión estructural.'
                      : 'No se observan fisuras relevantes.',
                  style: const TextStyle(
                      color: AppColors.textMid, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeatmapView extends StatelessWidget {
  final Uint8List original;
  final Uint8List heatmap;
  final bool showHeatmap;
  final double blend;

  const _HeatmapView({
    required this.original,
    required this.heatmap,
    required this.showHeatmap,
    required this.blend,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: AspectRatio(
        aspectRatio: 1,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.memory(original, fit: BoxFit.cover),
            if (showHeatmap)
              Opacity(
                opacity: blend,
                child: Image.memory(heatmap, fit: BoxFit.cover),
              ),
          ],
        ),
      ),
    );
  }
}

class _MetaCard extends StatelessWidget {
  final Prediction prediction;
  const _MetaCard({required this.prediction});

  @override
  Widget build(BuildContext context) {
    final modelName = prediction.model == ModelIds.mobilenet
        ? 'MobileNetV3 (transfer learning)'
        : 'CNN Baseline (desde cero)';
    return GlassCard(
      child: Column(
        children: [
          _row(Icons.memory_rounded, 'Modelo', modelName),
          const Divider(color: AppColors.stroke, height: 22),
          _row(
            prediction.weightsLoaded
                ? Icons.check_circle_rounded
                : Icons.error_outline_rounded,
            'Pesos entrenados',
            prediction.weightsLoaded ? 'Cargados' : 'No cargados',
            valueColor:
                prediction.weightsLoaded ? AppColors.success : AppColors.warning,
          ),
          const Divider(color: AppColors.stroke, height: 22),
          _row(Icons.label_rounded, 'Clase interna', prediction.label),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, String value, {Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textMid),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: AppColors.textMid)),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: valueColor ?? AppColors.textHi,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
