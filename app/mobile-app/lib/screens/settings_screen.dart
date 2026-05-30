import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../core/theme.dart';
import '../state/app_state.dart';
import '../widgets/brand_logo.dart';
import '../widgets/glass_card.dart';
import '../widgets/primary_button.dart';
import '../widgets/status_pill.dart';

/// Ajustes: configuración de la URL del backend y atajos útiles.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _ctrl;
  bool _testing = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: context.read<AppState>().baseUrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final state = context.read<AppState>();
    setState(() => _testing = true);
    await state.setBaseUrl(_ctrl.text);
    if (!mounted) return;
    setState(() => _testing = false);
    final ok = state.conn == ConnState.online;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? '✓ Conectado correctamente al backend'
            : 'Guardado, pero no se pudo conectar. Revisa la URL.'),
        backgroundColor: ok ? AppColors.success : AppColors.danger,
      ),
    );
  }

  void _useSuggestion(String url) {
    _ctrl.text = url;
    _ctrl.selection =
        TextSelection.collapsed(offset: _ctrl.text.length);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isModal = Navigator.of(context).canPop();

    final body = ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Ajustes', style: Theme.of(context).textTheme.headlineSmall),
            StatusPill(onTap: () => state.refreshHealth()),
          ],
        ),
        const SizedBox(height: 20),

        // Servidor
        Text('Conexión con el backend',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('URL del servidor',
                  style: TextStyle(
                      color: AppColors.textMid,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
              const SizedBox(height: 10),
              TextField(
                controller: _ctrl,
                keyboardType: TextInputType.url,
                autocorrect: false,
                style: const TextStyle(color: AppColors.textHi),
                decoration: InputDecoration(
                  hintText: 'http://192.168.1.10:8000',
                  hintStyle: const TextStyle(color: AppColors.textLow),
                  prefixIcon:
                      const Icon(Icons.link_rounded, color: AppColors.textMid),
                  filled: true,
                  fillColor: AppColors.surfaceAlt,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    borderSide: const BorderSide(color: AppColors.stroke),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              PrimaryButton(
                label: 'Guardar y probar conexión',
                icon: Icons.wifi_tethering_rounded,
                loading: _testing,
                onPressed: _save,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Sugerencias rápidas
        Text('Atajos según tu entorno',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        _Suggestion(
          icon: Icons.android_rounded,
          title: 'Emulador Android',
          subtitle: 'http://10.0.2.2:8000',
          onTap: () => _useSuggestion('http://10.0.2.2:8000'),
        ),
        _Suggestion(
          icon: Icons.phone_iphone_rounded,
          title: 'Simulador iOS / Escritorio',
          subtitle: 'http://localhost:8000',
          onTap: () => _useSuggestion('http://localhost:8000'),
        ),
        _Suggestion(
          icon: Icons.wifi_rounded,
          title: 'Dispositivo físico (LAN)',
          subtitle: 'http://TU_IP_LOCAL:8000',
          onTap: () => _useSuggestion('http://192.168.1.100:8000'),
        ),
        const SizedBox(height: 24),

        // Acerca de
        GlassCard(
          child: Row(
            children: [
              const BrandLogo(size: 48),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: 'Fisura',
                            style: TextStyle(
                              color: AppColors.textHi,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                          TextSpan(
                            text: 'Scan',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${AppConstants.tagline} · v1.0.0',
                      style: const TextStyle(
                          color: AppColors.textMid, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (!isModal) return body;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Ajustes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(child: body),
    );
  }
}

class _Suggestion extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _Suggestion({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: AppColors.textHi,
                          fontWeight: FontWeight.w600)),
                  Text(subtitle,
                      style: const TextStyle(
                          color: AppColors.textLow, fontSize: 12.5)),
                ],
              ),
            ),
            const Icon(Icons.arrow_outward_rounded,
                color: AppColors.textMid, size: 18),
          ],
        ),
      ),
    );
  }
}
