import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../models/analysis_record.dart';
import '../models/prediction.dart';
import '../services/api_service.dart';
import '../state/app_state.dart';
import '../widgets/brand_logo.dart';
import '../widgets/glass_card.dart';
import '../widgets/model_selector.dart';
import '../widgets/primary_button.dart';
import '../widgets/status_pill.dart';
import 'result_screen.dart';
import 'settings_screen.dart';

/// Pantalla de captura y análisis de imágenes.
class AnalyzeScreen extends StatefulWidget {
  const AnalyzeScreen({super.key});

  @override
  State<AnalyzeScreen> createState() => _AnalyzeScreenState();
}

class _AnalyzeScreenState extends State<AnalyzeScreen> {
  final _picker = ImagePicker();
  XFile? _picked;
  Uint8List? _bytes;
  bool _withGradcam = true;
  bool _loading = false;

  Future<void> _pick(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1280,
        imageQuality: 90,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      setState(() {
        _picked = file;
        _bytes = bytes;
      });
    } catch (e) {
      if (!mounted) return;
      _snack('No se pudo acceder a la imagen: $e', error: true);
    }
  }

  Future<void> _analyze() async {
    final state = context.read<AppState>();
    final bytes = _bytes;
    final picked = _picked;
    if (bytes == null || picked == null) return;

    setState(() => _loading = true);
    try {
      final api = state.api;
      final model = state.model;
      Prediction prediction;
      String? gradcam;

      if (_withGradcam) {
        final res = await api.predictGradcam(
          bytes: bytes,
          filename: picked.name,
          model: model,
          mimeType: picked.mimeType,
        );
        prediction = res.prediction;
        gradcam = res.gradcamDataUri;
      } else {
        prediction = await api.predict(
          bytes: bytes,
          filename: picked.name,
          model: model,
          mimeType: picked.mimeType,
        );
      }

      // Guarda en historial con miniatura.
      final record = AnalysisRecord(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        timestamp: DateTime.now(),
        prediction: prediction,
        thumbnailB64: base64Encode(bytes),
      );
      await state.addRecord(record);

      if (!mounted) return;
      setState(() => _loading = false);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            imageBytes: bytes,
            prediction: prediction,
            gradcamDataUri: gradcam,
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _snack(e.message, error: true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _snack('Error inesperado: $e', error: true);
    }
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? AppColors.danger : AppColors.textHi,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final hasImage = _bytes != null;
    final offline = state.conn == ConnState.offline;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      children: [
        // Cabecera
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const BrandWordmark(),
              StatusPill(onTap: () => state.refreshHealth()),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Inspecciona una superficie',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        const Text(
          'Toma o elige una foto del concreto y la IA detectará si hay grietas.',
          style: TextStyle(color: AppColors.textMid, height: 1.4),
        ),
        const SizedBox(height: 20),

        // Banner offline
        if (offline) _OfflineBanner(onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          );
        }),
        if (offline) const SizedBox(height: 16),

        // Zona de imagen
        _ImageDropzone(
          bytes: _bytes,
          onCamera: () => _pick(ImageSource.camera),
          onGallery: () => _pick(ImageSource.gallery),
          onClear: hasImage
              ? () => setState(() {
                    _picked = null;
                    _bytes = null;
                  })
              : null,
        ),
        const SizedBox(height: 20),

        // Selector de modelo
        Row(
          children: [
            const Icon(Icons.memory_rounded, size: 18, color: AppColors.textMid),
            const SizedBox(width: 8),
            Text('Modelo de inferencia',
                style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 10),
        const ModelSelector(),
        const SizedBox(height: 16),

        // Toggle Grad-CAM
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _withGradcam,
            activeThumbColor: AppColors.primary,
            onChanged: (v) => setState(() => _withGradcam = v),
            title: const Text(
              'Mapa de calor Grad-CAM',
              style: TextStyle(
                  color: AppColors.textHi, fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'Resalta las zonas que la red usó para decidir.',
              style: TextStyle(color: AppColors.textLow, fontSize: 12.5),
            ),
            secondary: const Icon(Icons.local_fire_department_rounded,
                color: AppColors.warning),
          ),
        ),
        const SizedBox(height: 24),

        // Botón analizar
        PrimaryButton(
          label: hasImage ? 'Analizar imagen' : 'Elige una imagen primero',
          icon: Icons.auto_awesome_rounded,
          loading: _loading,
          onPressed: hasImage ? _analyze : null,
        ),
        if (state.currentModelInfo != null &&
            !(state.currentModelInfo!.weightsLoaded)) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  size: 15, color: AppColors.warning),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Este modelo no tiene pesos entrenados cargados; los resultados serán poco fiables.',
                  style: TextStyle(
                      color: AppColors.warning.withValues(alpha: 0.9),
                      fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ImageDropzone extends StatelessWidget {
  final Uint8List? bytes;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback? onClear;

  const _ImageDropzone({
    required this.bytes,
    required this.onCamera,
    required this.onGallery,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 4 / 3,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: bytes == null ? AppColors.stroke : AppColors.primary,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: bytes == null
                ? _Placeholder(onCamera: onCamera, onGallery: onGallery)
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.memory(bytes!, fit: BoxFit.cover),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: _CircleBtn(
                          icon: Icons.close_rounded,
                          onTap: onClear,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SourceButton(
                icon: Icons.photo_camera_rounded,
                label: 'Cámara',
                onTap: onCamera,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SourceButton(
                icon: Icons.photo_library_rounded,
                label: 'Galería',
                onTap: onGallery,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Placeholder extends StatelessWidget {
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  const _Placeholder({required this.onCamera, required this.onGallery});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onGallery,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add_a_photo_rounded,
                color: AppColors.primary, size: 28),
          ),
          const SizedBox(height: 14),
          const Text(
            'Añade una imagen',
            style: TextStyle(
                color: AppColors.textHi, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          const Text(
            'Cámara o galería',
            style: TextStyle(color: AppColors.textLow, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}

class _SourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SourceButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.stroke),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 19, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                    color: AppColors.textHi, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _CircleBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: AppColors.textHi),
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _OfflineBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderColor: AppColors.danger.withValues(alpha: 0.45),
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_rounded, color: AppColors.danger),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sin conexión con el backend',
                    style: TextStyle(
                        color: AppColors.textHi,
                        fontWeight: FontWeight.w700)),
                SizedBox(height: 2),
                Text('Toca para configurar la URL del servidor',
                    style:
                        TextStyle(color: AppColors.textMid, fontSize: 12.5)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMid),
        ],
      ),
    );
  }
}
